require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const MockBEP20 = artifacts.require("MockBEP20");
const LemaToken = artifacts.require("LemaToken");
const TaxHandler = artifacts.require("LemaTaxHandler");
const TreasuryHandlerAlpha = artifacts.require("TreasuryHandlerAlpha");

module.exports = async function (deployer, network, accounts) {
  const treasuryAccount = process.env.ADDRESS_FOR_TREASURY || accounts[6];
  const treasuryCollectionAccount =
    process.env.ADDRESS_FOR_TAX_COLLECTION || accounts[7];
  const isDev = ["develop", "development"].includes(network);
  const isTestNet = ["testnet"].includes(network);
  let busdAddress;
  let routerAddress;
  let busdInstance;
  if (isDev) {
    busdInstance = await deployProxy(
      MockBEP20,
      ["BUSD", "BUSD", "200000000000000000000000"],
      {
        deployer,
        initializer: "initialize",
      }
    );
    busdAddress = busdInstance.address;
    routerAddress = "0xcf1aecc287027f797b99650b1e020ffa0fb0e248";
  } else if (isTestNet) {
    busdAddress = "0xcf1aecc287027f797b99650b1e020ffa0fb0e248"; // https://testnet.bscscan.com/address/0xcf1aecc287027f797b99650b1e020ffa0fb0e248
    routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // https://testnet.bscscan.com/address/0xD99D1c33F9fC3444f8101754aBC46c52416550D1
  } else {
    busdAddress = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"; // https://bscscan.com/address/0xe9e7cea3dedca5984780bafc599bd69add087d56
    routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // https://bscscan.com/address/0x10ED43C718714eb63d5aA57B78B54704E256024E
  }

  const lemaTokenInstance = await deployProxy(
    LemaToken,
    [
      treasuryAccount, // burner address
      "0x0000000000000000000000000000000000000000", // temp treasuryHandler address
      "0x0000000000000000000000000000000000000000", // temp taxHandler address
    ],
    {
      deployer,
      initializer: "initialize",
    }
  );

  const treasuryHandlerAlphaInstance = await deployProxy(
    TreasuryHandlerAlpha,
    [
      treasuryCollectionAccount, // treasury address
      busdAddress, // busd address
      lemaTokenInstance.address, // lema token address
      routerAddress, // router address
    ],
    {
      deployer,
      initializer: "initialize",
    }
  );
  await lemaTokenInstance.updateTreasuryHandlerAddress(
    treasuryHandlerAlphaInstance.address
  );

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
