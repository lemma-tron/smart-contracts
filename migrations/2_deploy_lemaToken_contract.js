require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const MockBEP20 = artifacts.require("MockBEP20");
const LemaToken = artifacts.require("LemaToken");
const TaxHandler = artifacts.require("LemaTaxHandler");
const TreasuryHandlerAlpha = artifacts.require("TreasuryHandlerAlpha");

module.exports = async function (deployer, network, accounts) {
  const treasuryAccount = process.env.ADDRESS_FOR_TREASURY || accounts[6];
  await deployProxy(
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
};
