const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const LemaToken = artifacts.require("LemaToken");
const LemaTokenV2 = artifacts.require("LemaTokenV2");

module.exports = async function (deployer, network, accounts) {
  const existing = await LemaToken.deployed();
  // await upgradeProxy(existing.address, LemaTokenV2, { deployer });
};
