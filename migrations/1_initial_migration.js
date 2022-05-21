var Migrations = artifacts.require("./Migrations.sol");

module.exports = function (deployer, network) {
  const isMainnet = ["bsc"].includes(network);
  if (isMainnet) {
    return; //We don't want a Migrations contract on the mainnet, don't waste gas.
  }
  deployer.deploy(Migrations);
};
