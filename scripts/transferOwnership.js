const { ethers } = require("hardhat");

const newContractOwnerAddress = "0xA2FaE0d5e2219d425D4787332eDfF75055007710";
const lemaTokenAddress = "0x7DC381F8396FfF9Cb004fEA725cD22cA86D4Ace3";
const lemaGovernanceAddress = "0xEA148833F2AA7Db56558ca8907ccaeeE1fe2f41c";
const lemaChefAddress = "0xC1f046C95d2f39C90657b4AD30ca5a46E0D50B5a";

async function main() {
  const lemaToken = await ethers.getContractAt("LemaToken", lemaTokenAddress);
  await lemaToken.transferOwnership(newContractOwnerAddress);

  const lemaGovernance = await ethers.getContractAt(
    "LemaGovernance",
    lemaGovernanceAddress
  );
  await lemaGovernance.transferOwnership(newContractOwnerAddress);

  const lemaChef = await ethers.getContractAt("LemaChefV2", lemaChefAddress);
  await lemaChef.transferOwnership(newContractOwnerAddress);

  console.log("Ownership transfered");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
