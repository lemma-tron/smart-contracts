require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const LemaToken = artifacts.require("LemaToken");
const LemaChefV2 = artifacts.require("LemaChefV2");

module.exports = async function (deployer, network, accounts) {
  const treasuryCollectionAccount =
    process.env.ADDRESS_FOR_TAX_COLLECTION || accounts[7];
  const lemaTokenInstance = await LemaToken.deployed();

  deployProxy(
    LemaChefV2,
    [
      lemaTokenInstance.address, // _lemaToken
      treasuryCollectionAccount, // _treasury
      0, // _startBlock
    ],
    { deployer, initializer: "initialize" }
  );
};
