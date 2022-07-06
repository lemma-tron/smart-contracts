const { ethers, upgrades } = require("hardhat");

const LEMA_CHEF_ADDRESS = "0xC1f046C95d2f39C90657b4AD30ca5a46E0D50B5a";

async function main() {
  const LemaChef = await ethers.getContractFactory("LemaChefV2");
  const lemaChef = await upgrades.upgradeProxy(LEMA_CHEF_ADDRESS, LemaChef);
  console.log("LemaChefV2 upgraded");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
