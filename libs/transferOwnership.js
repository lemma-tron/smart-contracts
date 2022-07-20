let lemaTokenAddress;
let lemaGovernanceAddress;
let lemaChefAddress;

async function transferOwnership(newContractOwnerAddress) {
  const {
    ethers,
    hardhatArguments: { network },
  } = hre;

  if (network === "bscTestnet") {
    lemaTokenAddress = "0x7DC381F8396FfF9Cb004fEA725cD22cA86D4Ace3";
    lemaGovernanceAddress = "0xEA148833F2AA7Db56558ca8907ccaeeE1fe2f41c";
    lemaChefAddress = "0xC1f046C95d2f39C90657b4AD30ca5a46E0D50B5a";
  } else {
    console.error(
      "Unimplemented network. Please use the following networks: bscTestnet"
    );
    process.exitCode = 1;
    return;
  }

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

module.exports = (newContractOwnerAddress) =>
  transferOwnership(newContractOwnerAddress).catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
