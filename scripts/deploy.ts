import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  const CipherIDFactory = await ethers.getContractFactory("CipherID");
  console.log("Deploying CipherID...");

  const cipherID = await CipherIDFactory.deploy();
  await cipherID.waitForDeployment();

  const address = await cipherID.getAddress();
  console.log("✅ CipherID deployed to:", address);
  console.log("🔗 Sepolia Etherscan:", `https://sepolia.etherscan.io/address/${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
