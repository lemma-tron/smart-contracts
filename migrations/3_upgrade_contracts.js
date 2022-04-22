const { upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const ERC20 = artifacts.require("MockERC20");
const BEP20 = artifacts.require("MockBEP20");

module.exports = async function (deployer, network, accounts) {
  const existing = await ERC20.deployed();
  await upgradeProxy(existing.address, BEP20, { deployer });
};
