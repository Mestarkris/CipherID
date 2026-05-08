// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/config/ZamaFHEVMConfig.sol";

contract CipherID is SepoliaZamaFHEVMConfig {

    // ── Access Control ─────────────────────────────────────
    address public owner;
    address public regulator;
    bool public protocolFrozen;

    // ── Provider Registry ──────────────────────────────────
    mapping(address => bool) public isApprovedProvider;
    mapping(address => uint8) public providerId;
    mapping(address => uint256) public providerAttestationCount;
    mapping(address => uint256) public providerRevocationCount;
    mapping(address => uint256) public providerLastActive;
    uint8 public providerCount;

    // ── Encrypted Identity State ───────────────────────────
    mapping(address => euint8) private _kycTier;
    mapping(address => euint8) private _complianceScore;
    mapping(address => euint8) private _jurisdiction;
    mapping(address => euint32) private _expiry;
    mapping(address => euint8) private _humanScore;
    mapping(address => euint8) private _reputationScore;

    // ── Public Metadata ────────────────────────────────────
    mapping(address => bool) public hasAttestation;
    mapping(address => address) public attestedBy;
    mapping(address => uint256) public attestedAt;
    mapping(address => uint256) public walletAge;
    mapping(address => bool) public isFrozenUser;

    // ── Multi-Provider Consensus ───────────────────────────
    mapping(address => mapping(uint8 => euint8)) private _providerVotes;
    mapping(address => uint8) public voteCount;
    uint8 public consensusThreshold = 2;

    // ── Delegation ─────────────────────────────────────────
    mapping(address => address) public delegatedTo;
    mapping(address => address) public delegatedFrom;

    // ── Query Fees & Marketplace ───────────────────────────
    uint256 public defaultQueryFee = 0.0001 ether;
    mapping(address => uint256) public providerEarnings;
    uint256 public totalQueryVolume;
    uint256 public totalFeesCollected;

    // ── Audit Trail ────────────────────────────────────────
    struct AuditEntry {
        address user;
        address actor;
        uint8 action; // 0=issue,1=revoke,2=delegate,3=query
        uint256 timestamp;
    }
    AuditEntry[] private _auditLog;
    mapping(address => uint256[]) private _userAuditIndices;

    // ── Protocol Registry ──────────────────────────────────
    struct Integration {
        string name;
        address contractAddr;
        uint256 queryCount;
        uint256 totalFeesPaid;
        bool active;
    }
    mapping(address => Integration) public integrations;
    address[] public integrationList;

    // ── Soulbound NFT-like Attestation Badges ──────────────
    mapping(address => uint256) public badgeTokenId;
    mapping(uint256 => address) public badgeOwner;
    uint256 public badgeCounter;

    // ── Events ─────────────────────────────────────────────
    event ProviderAdded(address indexed provider, uint8 id);
    event ProviderRemoved(address indexed provider);
    event AttestationIssued(address indexed user, address indexed provider, uint256 badgeId);
    event AttestationRevoked(address indexed user);
    event ConsensusReached(address indexed user);
    event AttestationDelegated(address indexed from, address indexed to);
    event VerificationQueried(address indexed user, address indexed querier, uint256 fee);
    event ProtocolFrozen(address indexed by);
    event ProtocolUnfrozen(address indexed by);
    event UserFrozen(address indexed user);
    event UserUnfrozen(address indexed user);
    event RegulatorAuditRequested(address indexed user, address indexed regulator);
    event IntegrationRegistered(address indexed protocol, string name);
    event BadgeMinted(address indexed user, uint256 tokenId);

    constructor() {
        owner = msg.sender;
        regulator = msg.sender;
    }

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    modifier onlyRegulator() { require(msg.sender == regulator, "Not regulator"); _; }
    modifier onlyApprovedProvider() { require(isApprovedProvider[msg.sender], "Not approved provider"); _; }
    modifier notFrozen() { require(!protocolFrozen, "Protocol is frozen"); require(!isFrozenUser[msg.sender], "User is frozen"); _; }

    // ── Provider Management ────────────────────────────────
    function addProvider(address provider) external onlyOwner {
        isApprovedProvider[provider] = true;
        providerCount++;
        providerId[provider] = providerCount;
        emit ProviderAdded(provider, providerCount);
    }

    function removeProvider(address provider) external onlyOwner {
        isApprovedProvider[provider] = false;
        emit ProviderRemoved(provider);
    }

    // ── Core: Issue Attestation ────────────────────────────
    function issueAttestationPlaintext(
        address user,
        uint8 tier,
        uint8 score,
        uint8 jurisdiction,
        uint32 expiryTimestamp,
        uint8 humanScore
    ) external onlyApprovedProvider notFrozen {
        euint8 encTier = TFHE.asEuint8(tier);
        euint8 encScore = TFHE.asEuint8(score);
        euint8 encJurisdiction = TFHE.asEuint8(jurisdiction);
        euint32 encExpiry = TFHE.asEuint32(expiryTimestamp);
        euint8 encHuman = TFHE.asEuint8(humanScore);
        euint8 encReputation = TFHE.asEuint8(score / 2);

        _kycTier[user] = encTier;
        _complianceScore[user] = encScore;
        _jurisdiction[user] = encJurisdiction;
        _expiry[user] = encExpiry;
        _humanScore[user] = encHuman;
        _reputationScore[user] = encReputation;

        TFHE.allowThis(encTier); TFHE.allow(encTier, user);
        TFHE.allowThis(encScore); TFHE.allow(encScore, user);
        TFHE.allowThis(encJurisdiction);
        TFHE.allowThis(encExpiry); TFHE.allow(encExpiry, user);
        TFHE.allowThis(encHuman); TFHE.allow(encHuman, user);
        TFHE.allowThis(encReputation); TFHE.allow(encReputation, user);

        hasAttestation[user] = true;
        attestedBy[user] = msg.sender;
        attestedAt[user] = block.timestamp;
        walletAge[user] = block.timestamp;

        providerAttestationCount[msg.sender]++;
        providerLastActive[msg.sender] = block.timestamp;

        // Mint soulbound badge
        badgeCounter++;
        badgeTokenId[user] = badgeCounter;
        badgeOwner[badgeCounter] = user;

        // Audit log
        _addAuditEntry(user, msg.sender, 0);

        emit AttestationIssued(user, msg.sender, badgeCounter);
        emit BadgeMinted(user, badgeCounter);
    }

    // ── Multi-Provider Consensus ───────────────────────────
    function submitConsensusVote(address user, uint8 tier) external onlyApprovedProvider notFrozen {
        uint8 pid = providerId[msg.sender];
        euint8 encVote = TFHE.asEuint8(tier);
        _providerVotes[user][pid] = encVote;
        TFHE.allowThis(encVote);
        voteCount[user]++;
        if (voteCount[user] >= consensusThreshold) {
            euint8 avgTier = TFHE.asEuint8(tier);
            _kycTier[user] = avgTier;
            TFHE.allowThis(avgTier); TFHE.allow(avgTier, user);
            hasAttestation[user] = true;
            attestedBy[user] = msg.sender;
            attestedAt[user] = block.timestamp;
            badgeCounter++;
            badgeTokenId[user] = badgeCounter;
            badgeOwner[badgeCounter] = user;
            emit ConsensusReached(user);
            emit BadgeMinted(user, badgeCounter);
        }
        providerLastActive[msg.sender] = block.timestamp;
    }

    // ── Delegation ─────────────────────────────────────────
    function delegateAttestation(address contractWallet) external notFrozen {
        require(hasAttestation[msg.sender], "Not verified");
        delegatedTo[msg.sender] = contractWallet;
        delegatedFrom[contractWallet] = msg.sender;
        _addAuditEntry(msg.sender, msg.sender, 2);
        emit AttestationDelegated(msg.sender, contractWallet);
    }

    function revokeAttestation(address user) external {
        require(msg.sender == attestedBy[user] || msg.sender == owner, "Not authorized");
        hasAttestation[user] = false;
        delete attestedBy[user];
        providerRevocationCount[msg.sender]++;
        _addAuditEntry(user, msg.sender, 1);
        emit AttestationRevoked(user);
    }

    // ── Queries ────────────────────────────────────────────
    function meetsMinTier(address user, uint8 minTier) external notFrozen returns (ebool) {
        address u = delegatedFrom[user] != address(0) ? delegatedFrom[user] : user;
        require(hasAttestation[u], "No attestation found");
        _addAuditEntry(u, msg.sender, 3);
        emit VerificationQueried(u, msg.sender, 0);
        euint8 min = TFHE.asEuint8(minTier);
        ebool result = TFHE.ge(_kycTier[u], min);
        TFHE.allowTransient(result, msg.sender);
        return result;
    }

    function queryWithFee(address user, uint8 minTier) external payable notFrozen returns (ebool) {
        address u = delegatedFrom[user] != address(0) ? delegatedFrom[user] : user;
        require(hasAttestation[u], "No attestation found");
        require(msg.value >= defaultQueryFee, "Insufficient fee");
        address provider = attestedBy[u];
        providerEarnings[provider] += msg.value;
        totalQueryVolume++;
        totalFeesCollected += msg.value;
        if (address(integrations[msg.sender].contractAddr) != address(0)) {
            integrations[msg.sender].queryCount++;
            integrations[msg.sender].totalFeesPaid += msg.value;
        }
        _addAuditEntry(u, msg.sender, 3);
        emit VerificationQueried(u, msg.sender, msg.value);
        euint8 min = TFHE.asEuint8(minTier);
        ebool result = TFHE.ge(_kycTier[u], min);
        TFHE.allowTransient(result, msg.sender);
        return result;
    }

    function verifyForContract(address user, uint8 minTier) external notFrozen returns (bool) {
        address u = delegatedFrom[user] != address(0) ? delegatedFrom[user] : user;
        if (!hasAttestation[u]) return false;
        emit VerificationQueried(u, msg.sender, 0);
        return true;
    }

    function isExpired(address user) external returns (ebool) {
        require(hasAttestation[user], "No attestation");
        euint32 now32 = TFHE.asEuint32(uint32(block.timestamp));
        ebool expired = TFHE.gt(now32, _expiry[user]);
        TFHE.allowTransient(expired, msg.sender);
        return expired;
    }

    function checkJurisdiction(address user, uint8 allowed) external returns (ebool) {
        require(hasAttestation[user], "No attestation");
        euint8 a = TFHE.asEuint8(allowed);
        ebool match_ = TFHE.eq(_jurisdiction[user], a);
        TFHE.allowTransient(match_, msg.sender);
        return match_;
    }

    // ── Emergency Freeze ───────────────────────────────────
    function freezeProtocol() external onlyOwner {
        protocolFrozen = true;
        emit ProtocolFrozen(msg.sender);
    }

    function unfreezeProtocol() external onlyOwner {
        protocolFrozen = false;
        emit ProtocolUnfrozen(msg.sender);
    }

    function freezeUser(address user) external onlyOwner {
        isFrozenUser[user] = true;
        emit UserFrozen(user);
    }

    function unfreezeUser(address user) external onlyOwner {
        isFrozenUser[user] = false;
        emit UserUnfrozen(user);
    }

    // ── Regulatory Audit Trail ─────────────────────────────
    function setRegulator(address _regulator) external onlyOwner {
        regulator = _regulator;
    }

    function getAuditLogLength() external view returns (uint256) {
        return _auditLog.length;
    }

    function getAuditEntry(uint256 index) external onlyRegulator view returns (
        address user, address actor, uint8 action, uint256 timestamp
    ) {
        AuditEntry memory e = _auditLog[index];
        return (e.user, e.actor, e.action, e.timestamp);
    }

    function getUserAuditCount(address user) external view returns (uint256) {
        return _userAuditIndices[user].length;
    }

    function _addAuditEntry(address user, address actor, uint8 action) internal {
        uint256 idx = _auditLog.length;
        _auditLog.push(AuditEntry(user, actor, action, block.timestamp));
        _userAuditIndices[user].push(idx);
    }

    // ── Protocol Integration Registry ─────────────────────
    function registerIntegration(string calldata name) external {
        integrations[msg.sender] = Integration(name, msg.sender, 0, 0, true);
        integrationList.push(msg.sender);
        emit IntegrationRegistered(msg.sender, name);
    }

    function getIntegrationCount() external view returns (uint256) {
        return integrationList.length;
    }

    function getIntegration(address protocol) external view returns (
        string memory name, uint256 queryCount, uint256 totalFeesPaid, bool active
    ) {
        Integration memory i = integrations[protocol];
        return (i.name, i.queryCount, i.totalFeesPaid, i.active);
    }

    // ── Soulbound Badge ────────────────────────────────────
    function getBadge(address user) external view returns (uint256 tokenId, bool valid) {
        tokenId = badgeTokenId[user];
        valid = hasAttestation[user] && tokenId > 0;
    }

    // ── Provider Leaderboard ───────────────────────────────
    function getProviderStats(address provider) external view returns (
        uint256 attestations, uint256 revocations, uint256 lastActive, uint256 earnings
    ) {
        return (
            providerAttestationCount[provider],
            providerRevocationCount[provider],
            providerLastActive[provider],
            providerEarnings[provider]
        );
    }

    // ── Marketplace ────────────────────────────────────────
    function withdrawEarnings() external {
        uint256 amount = providerEarnings[msg.sender];
        require(amount > 0, "No earnings");
        providerEarnings[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function getMarketStats() external view returns (
        uint256 queryVolume, uint256 feesCollected, uint256 activeProviders
    ) {
        return (totalQueryVolume, totalFeesCollected, providerCount);
    }

    // ── View Helpers ───────────────────────────────────────
    function getAttestationAge(address user) external view returns (uint256) {
        if (!hasAttestation[user]) return 0;
        return block.timestamp - attestedAt[user];
    }

    function setConsensusThreshold(uint8 t) external onlyOwner { consensusThreshold = t; }
    function setDefaultQueryFee(uint256 f) external onlyOwner { defaultQueryFee = f; }
}
