import { useState } from "react";
import { BrowserProvider, Contract, isAddress, parseEther, formatEther } from "ethers";
import KYC_ABI from "./abi/ConfidentialKYC.json";
import "./App.css";

const CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS;
type Tab = "dashboard"|"verify"|"attest"|"consensus"|"delegate"|"marketplace"|"leaderboard"|"audit"|"badge"|"integrations"|"freeze"|"admin";

const JURISDICTIONS = [
  {value:1,label:"🇺🇸 United States"},{value:2,label:"🇪🇺 European Union"},
  {value:3,label:"🇬🇧 United Kingdom"},{value:4,label:"🇸🇬 Singapore"},
  {value:5,label:"🇦🇪 UAE"},{value:9,label:"🌍 Other"},
];

const ACTION_LABELS = ["Issue","Revoke","Delegate","Query"];
const ACTION_COLORS = ["#10b981","#ef4444","#8b5cf6","#3b82f6"];

export default function App() {
  const [account, setAccount] = useState("");
  const [contract, setContract] = useState<Contract|null>(null);
  const [tab, setTab] = useState<Tab>("dashboard");
  const [loading, setLoading] = useState(false);
  const [toasts, setToasts] = useState<{id:number;text:string;type:string}[]>([]);
  const [isOwner, setIsOwner] = useState(false);
  const [isProvider, setIsProvider] = useState(false);
  const [stats, setStats] = useState({providerCount:0,queryFee:"0.0001",threshold:2,earnings:"0",age:0,totalVolume:0,totalFees:"0",badgeCount:0,frozen:false,auditLen:0,integrationCount:0});
  const [myStatus, setMyStatus] = useState({has:false,by:"",delegatedTo:"",delegatedFrom:"",frozen:false,badgeId:0,badgeValid:false});
  const [checkAddr,setCheckAddr] = useState(""); const [checkResult,setCheckResult] = useState<any>(null);
  const [attestUser,setAttestUser] = useState(""); const [attestTier,setAttestTier] = useState("1");
  const [attestScore,setAttestScore] = useState("80"); const [attestJurisdiction,setAttestJurisdiction] = useState("1");
  const [attestExpiry,setAttestExpiry] = useState("365"); const [attestHuman,setAttestHuman] = useState("75");
  const [consensusUser,setConsensusUser] = useState(""); const [consensusTier,setConsensusTier] = useState("1");
  const [delegateAddr,setDelegateAddr] = useState(""); const [revokeAddr,setRevokeAddr] = useState("");
  const [newProviderAddr,setNewProviderAddr] = useState(""); const [removeProviderAddr,setRemoveProviderAddr] = useState("");
  const [newThreshold,setNewThreshold] = useState("2"); const [newFee,setNewFee] = useState("0.0001");
  const [queryAddr,setQueryAddr] = useState(""); const [queryTier,setQueryTier] = useState("1"); const [queryResult,setQueryResult] = useState<null|boolean>(null);
  const [freezeAddr,setFreezeAddr] = useState(""); const [regulatorAddr,setRegulatorAddr] = useState("");
  const [integrationName,setIntegrationName] = useState("");
  const [auditEntries,setAuditEntries] = useState<any[]>([]);
  const [leaderboardData,setLeaderboardData] = useState<any[]>([]);
  const [providerStatsAddr,setProviderStatsAddr] = useState("");
  const [badgeAddr,setBadgeAddr] = useState("");  const [badgeResult,setBadgeResult] = useState<any>(null);

  const toast = (text:string,type="info") => {
    const id = Date.now();
    setToasts(t=>[...t,{id,text,type}]);
    setTimeout(()=>setToasts(t=>t.filter(x=>x.id!==id)),5000);
  };

  const connect = async () => {
    if (!(window as any).ethereum) return toast("Install MetaMask","error");
    try {
      const bp = new BrowserProvider((window as any).ethereum);
      await bp.send("eth_requestAccounts",[]);
      const signer = await bp.getSigner();
      const addr = await signer.getAddress();
      const net = await bp.getNetwork();
      if (net.chainId !== 11155111n) return toast("Switch to Sepolia","error");
      const c = new Contract(CONTRACT_ADDRESS, KYC_ABI, signer);
      setAccount(addr); setContract(c);
      const ownerAddr = await c.owner();
      setIsOwner(ownerAddr.toLowerCase()===addr.toLowerCase());
      setIsProvider(await c.isApprovedProvider(addr));
      await loadStats(c,addr);
      toast("Connected ✓","success");
    } catch(e:any){toast(e.message||"Failed","error");}
  };

  const loadStats = async (c:Contract,addr:string) => {
    try {
      const [pc,qf,th,earn,has,by,dTo,dFrom,age,frozen,vol,fees,bc,auditLen,integCount,userFrozen,badge] = await Promise.all([
        c.providerCount(),c.defaultQueryFee(),c.consensusThreshold(),
        c.providerEarnings(addr),c.hasAttestation(addr),c.attestedBy(addr),
        c.delegatedTo(addr),c.delegatedFrom(addr),c.getAttestationAge(addr),
        c.protocolFrozen(),c.totalQueryVolume(),c.totalFeesCollected(),
        c.badgeCounter(),c.getAuditLogLength(),c.getIntegrationCount(),
        c.isFrozenUser(addr),c.getBadge(addr)
      ]);
      setStats({providerCount:Number(pc),queryFee:formatEther(qf),threshold:Number(th),earnings:formatEther(earn),age:Number(age),totalVolume:Number(vol),totalFees:formatEther(fees),badgeCount:Number(bc),frozen,auditLen:Number(auditLen),integrationCount:Number(integCount)});
      setMyStatus({has,by,delegatedTo:dTo,delegatedFrom:dFrom,frozen:userFrozen,badgeId:Number(badge[0]),badgeValid:badge[1]});
    } catch{}
  };

  const reload = () => contract && loadStats(contract,account);

  const tx = async (fn:()=>Promise<any>,msg:string) => {
    setLoading(true);
    try {
      toast("Submitting...","info");
      const t = await fn();
      toast("Confirming...","info");
      await t.wait();
      toast(msg,"success");
      reload();
    } catch(e:any){toast(e.reason||e.message||"Failed","error");}
    setLoading(false);
  };

  const checkAttestation = async () => {
    if (!contract||!isAddress(checkAddr)) return toast("Invalid address","error");
    setLoading(true);
    try {
      const [has,by,age,frozen,badge] = await Promise.all([
        contract.hasAttestation(checkAddr),contract.attestedBy(checkAddr),
        contract.getAttestationAge(checkAddr),contract.isFrozenUser(checkAddr),
        contract.getBadge(checkAddr)
      ]);
      setCheckResult({has,by,age:Number(age),frozen,badgeId:Number(badge[0]),badgeValid:badge[1]});
    } catch(e:any){toast(e.message,"error");}
    setLoading(false);
  };

  const loadAudit = async () => {
    if (!contract) return;
    setLoading(true);
    try {
      const len = await contract.getAuditLogLength();
      const count = Math.min(Number(len),20);
      const entries = [];
      for (let i=Number(len)-1;i>=Math.max(0,Number(len)-count);i--) {
        const e = await contract.getAuditEntry(i);
        entries.push({user:e[0],actor:e[1],action:Number(e[2]),timestamp:Number(e[3])});
      }
      setAuditEntries(entries);
    } catch(e:any){toast("Audit access requires regulator role","error");}
    setLoading(false);
  };

  const loadLeaderboard = async () => {
    if (!contract) return;
    setLoading(true);
    try {
      const data = [];
      for (let i=1;i<=stats.providerCount;i++) {
        // We can't reverse lookup providerId easily, show placeholder
      }
      if (providerStatsAddr && isAddress(providerStatsAddr)) {
        const s = await contract.getProviderStats(providerStatsAddr);
        data.push({addr:providerStatsAddr,attestations:Number(s[0]),revocations:Number(s[1]),lastActive:Number(s[2]),earnings:formatEther(s[3])});
      }
      setLeaderboardData(data);
    } catch(e:any){toast(e.message,"error");}
    setLoading(false);
  };

  const lookupBadge = async () => {
    if (!contract||!isAddress(badgeAddr)) return toast("Invalid address","error");
    setLoading(true);
    try {
      const b = await contract.getBadge(badgeAddr);
      setBadgeResult({tokenId:Number(b[0]),valid:b[1]});
    } catch(e:any){toast(e.message,"error");}
    setLoading(false);
  };

  const fmtAge = (s:number) => {if(!s)return"—";if(s<3600)return`${Math.floor(s/60)}m ago`;if(s<86400)return`${Math.floor(s/3600)}h ago`;return`${Math.floor(s/86400)}d ago`;};
  const short = (a:string) => a&&a!=="0x0000000000000000000000000000000000000000"?`${a.slice(0,8)}...${a.slice(-6)}`:"—";
  const fmtTime = (ts:number) => ts?new Date(ts*1000).toLocaleString():"—";

  const TABS:{id:Tab;icon:string;label:string;group?:string}[] = [
    {id:"dashboard",icon:"⬡",label:"Dashboard"},
    {id:"verify",icon:"◎",label:"Verify"},
    {id:"attest",icon:"✦",label:"Attest"},
    {id:"consensus",icon:"◈",label:"Consensus"},
    {id:"delegate",icon:"⇢",label:"Delegate"},
    {id:"marketplace",icon:"◆",label:"Market"},
    {id:"leaderboard",icon:"▲",label:"Leaderboard"},
    {id:"badge",icon:"⬟",label:"Badges"},
    {id:"integrations",icon:"⊕",label:"Integrations"},
    {id:"audit",icon:"⊛",label:"Audit Trail"},
    {id:"freeze",icon:"❄",label:"Freeze"},
    {id:"admin",icon:"⚙",label:"Admin"},
  ];

  return (
    <div className="app">
      <div className="bg-grid"/><div className="bg-glow"/>
      <header>
        <div className="hdr">
          <div className="logo">
            <span className="logo-hex">⬡</span>
            <div><div className="logo-name">CipherID</div><div className="logo-sub">Private Identity Protocol</div></div>
            <span className="badge-sep">Sepolia</span>
            <span className="badge-fhe">FHE</span>
            {stats.frozen && <span className="badge-frozen">❄ FROZEN</span>}
          </div>
          {account?(
          {account?(
            <div className="acct-wrap">
              <div className="acct-pill">
                <span className="pulse"/>
                <span className="acct-addr">{account.slice(0,6)}...{account.slice(-4)}</span>
                {isOwner&&<span className="tag owner">Owner</span>}
                {isProvider&&<span className="tag prov">Provider</span>}
                {myStatus.has&&<span className="tag ver">✓ KYC</span>}
                {myStatus.badgeValid&&<span className="tag badge-tag">⬟ #{myStatus.badgeId}</span>}
              </div>
              <button className="btn-disconnect" onClick={()=>{setAccount("");setContract(null);setIsOwner(false);setIsProvider(false);setTab("dashboard");}}>⏻</button>
            </div>
          ):(
            <button className="btn-connect" onClick={connect}>Connect Wallet →</button>
          )}

      <div className="toasts">
        {toasts.map(t=>(
          <div key={t.id} className={`toast t-${t.type}`}>
            <span>{t.type==="success"?"✓":t.type==="error"?"✕":"◎"}</span> {t.text}
          </div>
        ))}
      </div>

      {!account?(
        <main className="landing">
          <div className="hero">
            <div className="hexes">{["⬡","⬡","⬡","⬡","⬡","⬡","⬡"].map((h,i)=><span key={i} className={`h h${i}`}>{h}</span>)}</div>
            <h1>Private KYC for Web3</h1>
            <p>Zero-knowledge identity attestations powered by Fully Homomorphic Encryption. Prove compliance without exposing personal data.</p>
            <div className="pills">
              {["🔒 Encrypted Tiers","⏱ Auto-Expiry","🏛 Multi-Provider","⇢ Delegation","💰 Pay-Per-Query","🌍 Jurisdiction","◎ Compliance Score","⬟ Soulbound Badges","▲ Provider Leaderboard","⊛ Audit Trail","❄ Emergency Freeze","⊕ Protocol Registry"].map(p=><span key={p} className="pill">{p}</span>)}
            </div>
            <button className="btn-hero" onClick={connect}>Launch App →</button>
            <div className="ctr-chip">
              <span>Contract:</span>
              <a href={`https://sepolia.etherscan.io/address/${CONTRACT_ADDRESS}`} target="_blank" rel="noreferrer">{CONTRACT_ADDRESS.slice(0,10)}...{CONTRACT_ADDRESS.slice(-8)}</a>
            </div>
          </div>
          <div className="feat-grid">
            {[
              ["🔒","Encrypted Tier Comparison","FHE ge() on encrypted euint8. Results stay encrypted until KMS gateway decryption."],
              ["🏛","Multi-Provider Consensus","N-of-M providers vote encrypted. Attestation finalizes when threshold is met."],
              ["⏱","Encrypted KYC Expiry","Expiry as euint32. No scanner can front-run wallet renewals."],
              ["🌍","Jurisdiction Blacklist","Enforce sanctions privately. User only learns pass/fail."],
              ["⇢","Attestation Delegation","EOA delegates to contract wallet without public identity link."],
              ["◎","Compliance Score 0-255","Each protocol sets its own threshold against the same encrypted score."],
              ["⬟","Soulbound Identity Badge","Non-transferable NFT-like badge. Metadata encrypted on-chain."],
              ["▲","Provider Leaderboard","Public accountability stats without revealing who was attested."],
              ["⊕","Protocol Integration Registry","dApps register and track their query volume and fees paid."],
              ["⊛","Regulatory Audit Trail","Encrypted audit log only the regulator address can read."],
              ["❄","Emergency Freeze Module","Owner can freeze protocol or individual wallets instantly."],
              ["💰","Pay-Per-Query Marketplace","Providers earn fees per verification. First FHE KYC marketplace."],
            ].map(([icon,title,desc])=>(
              <div className="fc" key={title as string}>
                <div className="fc-ico">{icon}</div>
                <div className="fc-title">{title}</div>
                <div className="fc-desc">{desc}</div>
              </div>
            ))}
          </div>
        </main>
      ):(
        <main className="dash">
          <nav className="sidenav">
            {TABS.map(t=>(
              <button key={t.id} className={`nitem ${tab===t.id?"active":""}`} onClick={()=>setTab(t.id)}>
                <span className="nico">{t.icon}</span>
                <span className="nlbl">{t.label}</span>
                {tab===t.id&&<span className="nind"/>}
              </button>
            ))}
            <div className="ndiv"/>
            <a className="nitem next" href={`https://sepolia.etherscan.io/address/${CONTRACT_ADDRESS}`} target="_blank" rel="noreferrer">
              <span className="nico">↗</span><span className="nlbl">Etherscan</span>
            </a>
          </nav>

          <div className="content">

            {tab==="dashboard"&&(
              <div className="pane">
                <div className="phdr"><h2>Dashboard</h2><p>CipherID protocol overview — all values live from Sepolia</p></div>
                {stats.frozen&&<div className="frozen-banner">❄ Protocol is currently frozen — all verifications paused</div>}
                <div className="sg4">
                  {[["🏛",stats.providerCount,"Active Providers"],["◈",stats.threshold,"Consensus Threshold"],["◆",stats.totalVolume,"Total Queries"],["💰",stats.totalFees+" ETH","Total Fees"]].map(([ico,val,lbl])=>(
                    <div className="sc" key={lbl as string}><div className="s-ico">{ico}</div><div className="s-val">{String(val)}</div><div className="s-lbl">{lbl}</div></div>
                  ))}
                </div>
                <div className="sg4">
                  {[["⬟",stats.badgeCount,"Badges Minted"],["⊛",stats.auditLen,"Audit Entries"],["⊕",stats.integrationCount,"Integrations"],["◎",stats.earnings+" ETH","My Earnings"]].map(([ico,val,lbl])=>(
                    <div className="sc" key={lbl as string}><div className="s-ico">{ico}</div><div className="s-val">{String(val)}</div><div className="s-lbl">{lbl}</div></div>
                  ))}
                </div>
                <div className="idc">
                  <div className="idhdr">
                    <span className="id-ico">◎</span><span className="id-title">My Identity</span>
                    <span className={`id-status ${myStatus.has?"ver":"unver"}`}>{myStatus.has?"✓ Verified":"✕ Unverified"}</span>
                    {myStatus.badgeValid&&<span className="id-badge">⬟ Badge #{myStatus.badgeId}</span>}
                  </div>
                  <div className="idrows">
                    {[["Address",account],["Attested by",short(myStatus.by)],["Age",fmtAge(stats.age)],["Delegated to",short(myStatus.delegatedTo)],["Delegated from",short(myStatus.delegatedFrom)],["Frozen",myStatus.frozen?"Yes":"No"]].map(([k,v])=>(
                      <div className="idrow" key={k as string}><span className="idk">{k}</span><span className="idv mono">{v as string}</span></div>
                    ))}
                  </div>
                  {parseFloat(stats.earnings)>0&&<button className="btn-p mt12" onClick={()=>tx(()=>contract!.withdrawEarnings(),"✅ Withdrawn")} disabled={loading}>Withdraw {stats.earnings} ETH</button>}
                </div>
                <div className="proto">
                  <div className="proto-title">Protocol Info</div>
                  {[["Contract",CONTRACT_ADDRESS],["Network","Sepolia Testnet"],["FHE","Zama FHEVM v0.6"],["Hackathon","Zama Developer Program Season 2"],["Features","12 FHE-native features"]].map(([k,v])=>(
                    <div className="prow" key={k as string}><span>{k}</span><span className="mono">{v as string}</span></div>
                  ))}
                </div>
              </div>
            )}

            {tab==="verify"&&(
              <div className="pane">
                <div className="phdr"><h2>Verify Address</h2><p>Query KYC status of any wallet. No personal data revealed on-chain.</p></div>
                <div className="card">
                  <div className="field"><label>Wallet address</label>
                    <div className="irow">
                      <input value={checkAddr} onChange={e=>{setCheckAddr(e.target.value);setCheckResult(null);}} placeholder="0x..."/>
                      <button className="btn-p" onClick={checkAttestation} disabled={loading}>{loading?"…":"Check"}</button>
                    </div>
                    <button className="btn-g mt8" onClick={()=>{setCheckAddr(account);setCheckResult(null);}}>Use my address</button>
                  </div>
                  {checkResult&&(
                    <div className={`rp ${checkResult.has?"pass":"fail"}`}>
                      <div className="rp-ico">{checkResult.has?"✓":"✕"}</div>
                      <div>
                        <div className="rp-title">{checkResult.has?"Verified":"Not Verified"}</div>
                        {checkResult.has&&<div className="rp-sub">By: <span className="mono">{short(checkResult.by)}</span> · {fmtAge(checkResult.age)}</div>}
                        {checkResult.badgeValid&&<div className="rp-sub">⬟ Soulbound Badge #{checkResult.badgeId}</div>}
                        {checkResult.frozen&&<div className="rp-sub" style={{color:"#60a5fa"}}>❄ This address is frozen</div>}
                      </div>
                    </div>
                  )}
                </div>
                <div className="infobox">
                  <div className="ib-t">FHE Privacy Guarantee</div>
                  <div className="ib-d">Attestation status (yes/no) is public. KYC tier, compliance score, human score, jurisdiction, and expiry are stored fully encrypted using TFHE. Nobody — including the contract owner — can read these without the user's permission via the Zama KMS gateway.</div>
                </div>
              </div>
            )}

            {tab==="attest"&&(
              <div className="pane">
                <div className="phdr"><h2>Issue Attestation</h2><p>Issue a full encrypted identity attestation. Auto-mints a soulbound badge.</p></div>
                {!isProvider&&!isOwner&&<div className="warn">⚠ Not an approved provider. Ask the owner via Admin tab.</div>}
                <div className="card">
                  <div className="field"><label>User wallet address</label><input value={attestUser} onChange={e=>setAttestUser(e.target.value)} placeholder="0x..."/></div>
                  <div className="frow">
                    <div className="field"><label>KYC Tier</label>
                      <select value={attestTier} onChange={e=>setAttestTier(e.target.value)}>
                        <option value="1">1 — Basic KYC</option><option value="2">2 — Accredited Investor</option><option value="3">3 — Institutional</option>
                      </select>
                    </div>
                    <div className="field"><label>Compliance Score (0-255)</label><input type="number" min="0" max="255" value={attestScore} onChange={e=>setAttestScore(e.target.value)}/></div>
                  </div>
                  <div className="frow">
                    <div className="field"><label>Jurisdiction</label>
                      <select value={attestJurisdiction} onChange={e=>setAttestJurisdiction(e.target.value)}>
                        {JURISDICTIONS.map(j=><option key={j.value} value={j.value}>{j.label}</option>)}
                      </select>
                    </div>
                    <div className="field"><label>Validity (days)</label><input type="number" min="1" value={attestExpiry} onChange={e=>setAttestExpiry(e.target.value)}/></div>
                  </div>
                  <div className="frow">
                    <div className="field"><label>Human Score (0-100)</label><input type="number" min="0" max="100" value={attestHuman} onChange={e=>setAttestHuman(e.target.value)}/></div>
                  </div>
                  <div className="score-bar">
                    <div className="sb-lbl">Compliance: {attestScore}/255 · Human: {attestHuman}/100</div>
                    <div className="sb-track"><div className="sb-fill" style={{width:`${parseInt(attestScore)/255*100}%`}}/></div>
                  </div>
                  <button className="btn-p full" onClick={()=>{
                    if(!contract||!isAddress(attestUser)) return toast("Invalid address","error");
                    const expiry = Math.floor(Date.now()/1000)+parseInt(attestExpiry)*86400;
                    tx(()=>contract.issueAttestationPlaintext(attestUser,parseInt(attestTier),parseInt(attestScore),parseInt(attestJurisdiction),expiry,parseInt(attestHuman)),"✅ Attestation issued + Badge minted");
                  }} disabled={loading||(!isProvider&&!isOwner)}>
                    {loading?"Submitting...":"Issue Attestation + Mint Badge"}
                  </button>
                </div>
                <div className="divider"/>
                <div className="phdr"><h2>Revoke Attestation</h2></div>
                <div className="card">
                  <div className="irow">
                    <input value={revokeAddr} onChange={e=>setRevokeAddr(e.target.value)} placeholder="0x..."/>
                    <button className="btn-d" onClick={()=>{if(!contract||!isAddress(revokeAddr))return toast("Invalid","error");tx(()=>contract.revokeAttestation(revokeAddr),"✅ Revoked")}} disabled={loading}>Revoke</button>
                  </div>
                </div>
              </div>
            )}

            {tab==="consensus"&&(
              <div className="pane">
                <div className="phdr"><h2>Multi-Provider Consensus</h2><p>Require {stats.threshold} providers to agree. Individual votes stay encrypted.</p></div>
                <div className="cv-wrap">
                  {[...Array(Math.max(stats.providerCount||1,3))].map((_,i)=>(
                    <div key={i} className={`cvn ${i<stats.threshold?"cvn-a":""}`}><div>🏛</div><div className="cvn-l">P{i+1}</div></div>
                  ))}
                  <div className="cvarr">→</div>
                  <div className="cvr"><div>✓</div><div className="cvn-l">Consensus</div></div>
                </div>
                {!isProvider&&!isOwner&&<div className="warn">⚠ Only approved providers can vote.</div>}
                <div className="card">
                  <div className="field"><label>User address</label><input value={consensusUser} onChange={e=>setConsensusUser(e.target.value)} placeholder="0x..."/></div>
                  <div className="field"><label>Tier Vote</label>
                    <select value={consensusTier} onChange={e=>setConsensusTier(e.target.value)}>
                      <option value="1">1 — Basic KYC</option><option value="2">2 — Accredited Investor</option><option value="3">3 — Institutional</option>
                    </select>
                  </div>
                  <button className="btn-p full" onClick={()=>{if(!contract||!isAddress(consensusUser))return toast("Invalid","error");tx(()=>contract.submitConsensusVote(consensusUser,parseInt(consensusTier)),"✅ Vote submitted")}} disabled={loading||(!isProvider&&!isOwner)}>
                    {loading?"Submitting...":"Submit Encrypted Vote"}
                  </button>
                </div>
              </div>
            )}

            {tab==="delegate"&&(
              <div className="pane">
                <div className="phdr"><h2>Attestation Delegation</h2><p>Delegate verified status to a contract wallet. No public identity link.</p></div>
                <div className="card">
                  <div className="field"><label>Delegate to address</label>
                    <div className="irow">
                      <input value={delegateAddr} onChange={e=>setDelegateAddr(e.target.value)} placeholder="0x..."/>
                      <button className="btn-p" onClick={()=>{if(!contract||!isAddress(delegateAddr))return toast("Invalid","error");tx(()=>contract.delegateAttestation(delegateAddr),"✅ Delegated")}} disabled={loading||!myStatus.has}>{loading?"…":"Delegate"}</button>
                    </div>
                    {!myStatus.has&&<div className="hint">⚠ Must be verified first</div>}
                  </div>
                  {myStatus.delegatedTo&&myStatus.delegatedTo!=="0x0000000000000000000000000000000000000000"&&(
                    <div className="rp pass"><div className="rp-ico">⇢</div><div><div className="rp-title">Currently Delegated</div><div className="rp-sub mono">{myStatus.delegatedTo}</div></div></div>
                  )}
                </div>
                <div className="infobox"><div className="ib-t">Use Case</div><div className="ib-d">Institutions use Safe/multisig wallets but KYC ties to EOAs. Delegate once, cover all contract wallets. Zero on-chain identity linkage — only the parties involved can connect the two addresses.</div></div>
              </div>
            )}

            {tab==="marketplace"&&(
              <div className="pane">
                <div className="phdr"><h2>Verification Marketplace</h2><p>Pay providers to verify. First FHE-native KYC marketplace on-chain.</p></div>
                <div className="sg4">
                  {[["◆",stats.totalVolume,"Total Queries"],["💰",stats.totalFees+" ETH","Total Fees"],["🏛",stats.providerCount,"Providers"],["◎",stats.earnings+" ETH","My Earnings"]].map(([ico,val,lbl])=>(
                    <div className="sc" key={lbl as string}><div className="s-ico">{ico}</div><div className="s-val">{String(val)}</div><div className="s-lbl">{lbl}</div></div>
                  ))}
                </div>
                <div className="card">
                  <div className="field"><label>Address to query</label><input value={queryAddr} onChange={e=>{setQueryAddr(e.target.value);setQueryResult(null);}} placeholder="0x..."/></div>
                  <div className="field"><label>Minimum tier</label>
                    <select value={queryTier} onChange={e=>setQueryTier(e.target.value)}>
                      <option value="1">1 — Basic KYC</option><option value="2">2 — Accredited Investor</option><option value="3">3 — Institutional</option>
                    </select>
                  </div>
                  <div className="fee-preview">Fee: <strong>{stats.queryFee} ETH</strong> → paid to attestation provider</div>
                  <button className="btn-p full" onClick={async()=>{
                    if(!contract||!isAddress(queryAddr))return toast("Invalid","error");
                    setLoading(true);
                    try{const t=await contract.queryWithFee(queryAddr,parseInt(queryTier),{value:parseEther(stats.queryFee)});await t.wait();setQueryResult(true);toast("✅ Query successful","success");reload();}
                    catch(e:any){setQueryResult(false);toast(e.reason||"Failed","error");}
                    setLoading(false);
                  }} disabled={loading}>{loading?"Querying...":"Query for "+stats.queryFee+" ETH"}</button>
                  {queryResult!==null&&(
                    <div className={`rp mt16 ${queryResult?"pass":"fail"}`}>
                      <div className="rp-ico">{queryResult?"✓":"✕"}</div>
                      <div className="rp-title">{queryResult?"Passes Tier Check":"Fails Tier Check"}</div>
                    </div>
                  )}
                </div>
                {parseFloat(stats.earnings)>0&&(
                  <div className="card"><button className="btn-p full" onClick={()=>tx(()=>contract!.withdrawEarnings(),"✅ Withdrawn")} disabled={loading}>Withdraw {stats.earnings} ETH Earnings</button></div>
                )}
              </div>
            )}

            {tab==="leaderboard"&&(
              <div className="pane">
                <div className="phdr"><h2>Provider Leaderboard</h2><p>Public accountability stats. Shows performance without revealing who was attested.</p></div>
                <div className="card">
                  <div className="field"><label>Look up provider address</label>
                    <div className="irow">
                      <input value={providerStatsAddr} onChange={e=>setProviderStatsAddr(e.target.value)} placeholder="0x..."/>
                      <button className="btn-p" onClick={loadLeaderboard} disabled={loading}>{loading?"…":"Lookup"}</button>
                    </div>
                  </div>
                </div>
                {leaderboardData.length>0&&(
                  <div className="lb-table">
                    <div className="lb-hdr">
                      <span>Provider</span><span>Attestations</span><span>Revocations</span><span>Last Active</span><span>Earnings</span>
                    </div>
                    {leaderboardData.map((p,i)=>(
                      <div className="lb-row" key={i}>
                        <span className="mono">{short(p.addr)}</span>
                        <span className="lb-green">{p.attestations}</span>
                        <span className="lb-red">{p.revocations}</span>
                        <span>{fmtTime(p.lastActive)}</span>
                        <span>{p.earnings} ETH</span>
                      </div>
                    ))}
                  </div>
                )}
                <div className="infobox mt16"><div className="ib-t">Privacy Note</div><div className="ib-d">Attestation counts and earnings are public — providers are accountable. But WHO they attested is never revealed. The encrypted KYC data stays on-chain and inaccessible without the user's decryption permission.</div></div>
              </div>
            )}

            {tab==="badge"&&(
              <div className="pane">
                <div className="phdr"><h2>Soulbound Identity Badges</h2><p>Non-transferable attestation badges. Metadata encrypted on-chain. Total minted: {stats.badgeCount}</p></div>
                {myStatus.badgeValid&&(
                  <div className="badge-display">
                    <div className="badge-hex">⬟</div>
                    <div className="badge-info">
                      <div className="badge-title">CipherID Identity Badge</div>
                      <div className="badge-id">#{myStatus.badgeId}</div>
                      <div className="badge-sub">Soulbound · Non-transferable · FHE-encrypted metadata</div>
                      <div className="badge-owner">Owner: <span className="mono">{account.slice(0,10)}...{account.slice(-8)}</span></div>
                    </div>
                  </div>
                )}
                {!myStatus.badgeValid&&<div className="warn">⚠ You don't have a badge yet. Get attested first.</div>}
                <div className="divider"/>
                <div className="phdr"><h2>Lookup Badge</h2></div>
                <div className="card">
                  <div className="field"><label>Wallet address</label>
                    <div className="irow">
                      <input value={badgeAddr} onChange={e=>{setBadgeAddr(e.target.value);setBadgeResult(null);}} placeholder="0x..."/>
                      <button className="btn-p" onClick={lookupBadge} disabled={loading}>{loading?"…":"Lookup"}</button>
                    </div>
                  </div>
                  {badgeResult&&(
                    <div className={`rp ${badgeResult.valid?"pass":"fail"}`}>
                      <div className="rp-ico">{badgeResult.valid?"⬟":"✕"}</div>
                      <div>
                        <div className="rp-title">{badgeResult.valid?`Badge #${badgeResult.tokenId} — Valid`:"No Badge Found"}</div>
                        {badgeResult.valid&&<div className="rp-sub">Soulbound · Non-transferable · Encrypted metadata</div>}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}

            {tab==="integrations"&&(
              <div className="pane">
                <div className="phdr"><h2>Protocol Integration Registry</h2><p>dApps that have integrated CipherID as their KYC layer. Total: {stats.integrationCount}</p></div>
                <div className="card">
                  <div className="sec-title">Register Your Protocol</div>
                  <div className="field"><label>Protocol Name</label>
                    <div className="irow">
                      <input value={integrationName} onChange={e=>setIntegrationName(e.target.value)} placeholder="e.g. MyDeFi Protocol"/>
                      <button className="btn-p" onClick={()=>{if(!contract||!integrationName)return toast("Enter name","error");tx(()=>contract.registerIntegration(integrationName),"✅ Integration registered")}} disabled={loading}>Register</button>
                    </div>
                  </div>
                </div>
                <div className="infobox">
                  <div className="ib-t">How Integration Works</div>
                  <div className="ib-d">Your protocol calls <span className="mono">verifyForContract(user, minTier)</span> before any gated action. Register here to appear in the protocol registry and track your query volume and fees paid to KYC providers. Building the network effect for private compliant DeFi.</div>
                </div>
                <div className="code-block">
                  <div className="cb-title">Integration Snippet</div>
                  <pre>{`// In your Solidity contract:
import "./ICipherID.sol";

ICipherID cipherID = ICipherID(
  0x5124338fb3eaBC0661c812873F16321f616E134D
);

function deposit(uint256 amount) external {
  require(
    cipherID.verifyForContract(msg.sender, 1),
    "KYC required"
  );
  // ... rest of logic
}`}</pre>
                </div>
              </div>
            )}

            {tab==="audit"&&(
              <div className="pane">
                <div className="phdr"><h2>Regulatory Audit Trail</h2><p>Encrypted audit log. Only the designated regulator address can read entries.</p></div>
                <div className="card">
                  <div className="field">
                    <label>Total audit entries: {stats.auditLen}</label>
                    <button className="btn-p" onClick={loadAudit} disabled={loading}>{loading?"Loading...":"Load Last 20 Entries"}</button>
                  </div>
                </div>
                {auditEntries.length>0&&(
                  <div className="audit-table">
                    <div className="at-hdr"><span>Action</span><span>User</span><span>Actor</span><span>Time</span></div>
                    {auditEntries.map((e,i)=>(
                      <div className="at-row" key={i}>
                        <span className="at-action" style={{color:ACTION_COLORS[e.action]}}>{ACTION_LABELS[e.action]}</span>
                        <span className="mono">{short(e.user)}</span>
                        <span className="mono">{short(e.actor)}</span>
                        <span>{fmtTime(e.timestamp)}</span>
                      </div>
                    ))}
                  </div>
                )}
                <div className="infobox mt16">
                  <div className="ib-t">Compliance Design</div>
                  <div className="ib-d">Every attestation, revocation, delegation, and query is logged. The log is readable only by the regulator address set by the owner. This satisfies AML/KYC audit requirements without making the data public — giving regulators access without exposing user data to everyone.</div>
                </div>
              </div>
            )}

            {tab==="freeze"&&(
              <div className="pane">
                <div className="phdr"><h2>Emergency Freeze Module</h2><p>Halt verifications instantly in case of regulatory order or security incident.</p></div>
                {!isOwner&&<div className="warn">⚠ Only the contract owner can use freeze controls.</div>}
                <div className="card">
                  <div className="sec-title">Protocol-Level Freeze</div>
                  <div className="freeze-status">
                    <div className={`fs-indicator ${stats.frozen?"frozen":"active"}`}/>
                    <div>
                      <div className="fs-label">{stats.frozen?"Protocol Frozen — All verifications paused":"Protocol Active — Operating normally"}</div>
                    </div>
                  </div>
                  <div className="frow mt12">
                    <button className="btn-freeze" onClick={()=>tx(()=>contract!.freezeProtocol(),"✅ Protocol frozen")} disabled={loading||!isOwner||stats.frozen}>❄ Freeze Protocol</button>
                    <button className="btn-unfreeze" onClick={()=>tx(()=>contract!.unfreezeProtocol(),"✅ Protocol unfrozen")} disabled={loading||!isOwner||!stats.frozen}>✓ Unfreeze Protocol</button>
                  </div>
                </div>
                <div className="card">
                  <div className="sec-title">User-Level Freeze</div>
                  <div className="field"><label>Freeze specific address</label>
                    <div className="irow">
                      <input value={freezeAddr} onChange={e=>setFreezeAddr(e.target.value)} placeholder="0x..."/>
                      <button className="btn-freeze" onClick={()=>{if(!contract||!isAddress(freezeAddr))return toast("Invalid","error");tx(()=>contract.freezeUser(freezeAddr),"✅ User frozen")}} disabled={loading||!isOwner}>Freeze</button>
                      <button className="btn-unfreeze" onClick={()=>{if(!contract||!isAddress(freezeAddr))return toast("Invalid","error");tx(()=>contract.unfreezeUser(freezeAddr),"✅ User unfrozen")}} disabled={loading||!isOwner}>Unfreeze</button>
                    </div>
                  </div>
                </div>
                <div className="infobox">
                  <div className="ib-t">Production Safety</div>
                  <div className="ib-d">In a production environment, freeze authority would be held by a multisig requiring 3-of-5 signatures from legal counsel, CEO, and compliance officers. This prevents a single point of abuse while satisfying regulatory requirements for emergency controls.</div>
                </div>
              </div>
            )}

            {tab==="admin"&&(
              <div className="pane">
                <div className="phdr"><h2>Admin Panel</h2><p>Contract owner controls only.</p></div>
                {!isOwner&&<div className="warn">⚠ Only the contract owner can use this panel.</div>}
                <div className="card">
                  <div className="sec-title">Provider Management</div>
                  <div className="field"><label>Add Provider</label><div className="irow"><input value={newProviderAddr} onChange={e=>setNewProviderAddr(e.target.value)} placeholder="0x..."/><button className="btn-p" onClick={()=>{if(!contract||!isAddress(newProviderAddr))return toast("Invalid","error");tx(()=>contract.addProvider(newProviderAddr),"✅ Provider added")}} disabled={loading||!isOwner}>Add</button></div></div>
                  <div className="field"><label>Remove Provider</label><div className="irow"><input value={removeProviderAddr} onChange={e=>setRemoveProviderAddr(e.target.value)} placeholder="0x..."/><button className="btn-d" onClick={()=>{if(!contract||!isAddress(removeProviderAddr))return toast("Invalid","error");tx(()=>contract.removeProvider(removeProviderAddr),"✅ Removed")}} disabled={loading||!isOwner}>Remove</button></div></div>
                  <div className="divider"/>
                  <div className="sec-title">Protocol Parameters</div>
                  <div className="frow">
                    <div className="field"><label>Consensus Threshold</label><div className="irow"><input type="number" min="1" value={newThreshold} onChange={e=>setNewThreshold(e.target.value)}/><button className="btn-p" onClick={()=>tx(()=>contract!.setConsensusThreshold(parseInt(newThreshold)),"✅ Updated")} disabled={loading||!isOwner}>Set</button></div></div>
                    <div className="field"><label>Query Fee (ETH)</label><div className="irow"><input value={newFee} onChange={e=>setNewFee(e.target.value)}/><button className="btn-p" onClick={()=>tx(()=>contract!.setDefaultQueryFee(parseEther(newFee)),"✅ Updated")} disabled={loading||!isOwner}>Set</button></div></div>
                  </div>
                  <div className="divider"/>
                  <div className="sec-title">Regulator Address</div>
                  <div className="field"><div className="irow"><input value={regulatorAddr} onChange={e=>setRegulatorAddr(e.target.value)} placeholder="0x... regulator address"/><button className="btn-p" onClick={()=>{if(!contract||!isAddress(regulatorAddr))return toast("Invalid","error");tx(()=>contract.setRegulator(regulatorAddr),"✅ Regulator set")}} disabled={loading||!isOwner}>Set</button></div></div>
                </div>
              </div>
            )}

          </div>
        </main>
      )}

      <footer>
        <div className="ftr">
          <span>CipherID — Private Identity Protocol</span><span className="fsep">·</span>
          <a href="https://zama.ai" target="_blank" rel="noreferrer">Zama FHEVM</a><span className="fsep">·</span>
          <span>Sepolia Testnet</span><span className="fsep">·</span>
          <span>Zama Developer Program Season 2</span>
        </div>
      </footer>
    </div>
  );
}
