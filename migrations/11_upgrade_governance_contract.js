const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const LemaGovernance = artifacts.require("LemaGovernance");
const LemaGovernanceV2 = artifacts.require("LemaGovernanceV2");

module.exports = async function (deployer, network, accounts) {
  const existing = await LemaGovernance.deployed();
  await upgradeProxy(existing.address, LemaGovernanceV2, { deployer });
};
