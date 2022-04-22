const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const BEP20 = artifacts.require("MockERC20");

module.exports = async function (deployer, network, accounts) {
  await deployProxy(BEP20, ["BUSD", "BUSD", 2000000], { deployer, initializer: "initialize" });
};
