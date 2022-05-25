require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const LemaToken = artifacts.require("LemaToken");
const TaxHandler = artifacts.require("LemaTaxHandler");

module.exports = async function (deployer, network) {
  const isDev = ["develop", "development"].includes(network);
  const isTestNet = ["testnet"].includes(network);

  let routerAddress;

  if (isDev) {
    routerAddress = "0xcf1aecc287027f797b99650b1e020ffa0fb0e248";
  } else if (isTestNet) {
    routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // https://testnet.bscscan.com/address/0xD99D1c33F9fC3444f8101754aBC46c52416550D1
  } else {
    routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // https://bscscan.com/address/0x10ED43C718714eb63d5aA57B78B54704E256024E
  }

  const lemaTokenInstance = await LemaToken.deployed();

  const taxHandlerInstance = await deployProxy(
    TaxHandler,
    [
      0, // 0% for rest of exchanges
      routerAddress, // router address
    ],
    {
      deployer,
      initializer: "initialize",
    }
  );
  await lemaTokenInstance.updateTaxHandlerAddress(taxHandlerInstance.address);
};
