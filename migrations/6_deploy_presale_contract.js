require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const MockBEP20 = artifacts.require("MockBEP20");
const LemaToken = artifacts.require("LemaToken");
const PresaleLemaRefundVault = artifacts.require("PresaleLemaRefundVault");
const PresaleLemaV2 = artifacts.require("PresaleLemaV2");

module.exports = async function (deployer, network) {
  const isDev = ["develop", "development"].includes(network);
  const isTestNet = ["testnet"].includes(network);

  let busdAddress;

  if (isDev) {
    let busdInstance = await MockBEP20.deployed();
    busdAddress = busdInstance.address;
  } else if (isTestNet) {
    busdAddress = "0xcf1aecc287027f797b99650b1e020ffa0fb0e248"; // https://testnet.bscscan.com/address/0xcf1aecc287027f797b99650b1e020ffa0fb0e248
  } else {
    busdAddress = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"; // https://bscscan.com/address/0xe9e7cea3dedca5984780bafc599bd69add087d56
  }

  const lemaTokenInstance = await LemaToken.deployed();
  const presaleLemaRefundVaultInstance =
    await PresaleLemaRefundVault.deployed();

  const presaleLemaInstance = await deployProxy(
    PresaleLemaV2,
    [
      lemaTokenInstance.address,
      busdAddress,
      presaleLemaRefundVaultInstance.address,
    ],
    { deployer, initializer: "initialize" }
  );

  await presaleLemaRefundVaultInstance.transferOwnership(
    presaleLemaInstance.address
  );
};
