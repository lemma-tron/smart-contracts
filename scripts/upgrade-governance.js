const { ethers, upgrades } = require("hardhat");

const LEMA_GOVERNANCE_ADDRESS = "0xEA148833F2AA7Db56558ca8907ccaeeE1fe2f41c";

async function main() {
  const LemaGovernance = await ethers.getContractFactory("LemaGovernance");
  const lemaGovernance = await upgrades.upgradeProxy(
    LEMA_GOVERNANCE_ADDRESS,
    LemaGovernance
  );
  console.log("LemaGovernance upgraded");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
