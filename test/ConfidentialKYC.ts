import { expect } from "chai";
import { ethers } from "hardhat";

describe("ConfidentialKYC", function () {
  let kyc: any;
  let owner: any, provider: any, user: any, other: any;

  beforeEach(async function () {
    [owner, provider, user, other] = await ethers.getSigners();
    const KYCFactory = await ethers.getContractFactory("ConfidentialKYC");
    kyc = await KYCFactory.deploy();
    await kyc.waitForDeployment();
  });

  it("should deploy and set owner correctly", async function () {
    expect(await kyc.owner()).to.equal(owner.address);
  });

  it("should add a KYC provider", async function () {
    await kyc.addProvider(provider.address);
    expect(await kyc.isApprovedProvider(provider.address)).to.equal(true);
  });

  it("should remove a KYC provider", async function () {
    await kyc.addProvider(provider.address);
    await kyc.removeProvider(provider.address);
    expect(await kyc.isApprovedProvider(provider.address)).to.equal(false);
  });

  it("should reject provider management from non-owner", async function () {
    await expect(
      kyc.connect(other).addProvider(provider.address)
    ).to.be.revertedWith("Not owner");
  });

  it("should reject attestation from non-approved provider", async function () {
    const fakeInput = ethers.zeroPadBytes("0x01", 32);
    const fakeProof = ethers.zeroPadBytes("0x01", 32);
    await expect(
      kyc.connect(other).issueAttestation(user.address, fakeInput, fakeProof)
    ).to.be.revertedWith("Not approved provider");
  });

  it("should revert meetsMinTier if no attestation", async function () {
    await expect(
      kyc.meetsMinTier(user.address, 1)
    ).to.be.revertedWith("No attestation found");
  });

  it("should revert revokeAttestation if not authorized", async function () {
    await expect(
      kyc.connect(other).revokeAttestation(user.address)
    ).to.be.revertedWith("Not authorized to revoke");
  });
});
