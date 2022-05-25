require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const LemaToken = artifacts.require("LemaToken");
const LemaTokenVesting = artifacts.require("LemaTokenVesting");
const LemaChefV2 = artifacts.require("LemaChefV2");
const PresaleLemaV2 = artifacts.require("PresaleLemaV2");

module.exports = async function (deployer, network, accounts) {
  const addressForInitialLiquidity =
    process.env.ADDRESS_FOR_INITIAL_LIQUIDITY || accounts[1];
  const addressForPublicSale =
    process.env.ADDRESS_FOR_PUBLIC_SALE || accounts[2];
  const addressForMarketing = process.env.ADDRESS_FOR_MARKETING || accounts[3];
  const addressForAdvisor = process.env.ADDRESS_FOR_ADVISOR || accounts[4];
  const addressForTeam = process.env.ADDRESS_FOR_TEAM || accounts[5];
  const treasuryAccount = process.env.ADDRESS_FOR_TREASURY || accounts[6];

  const isDev = ["develop", "development"].includes(network);

  const lemaTokenInstance = await LemaToken.deployed();
  const lemaPresaleInstance = await PresaleLemaV2.deployed();
  const lemaChefInstance = await LemaChefV2.deployed();

  const lemaTokenVestingInstance = await deployProxy(
    LemaTokenVesting,
    [
      lemaTokenInstance.address, // _lemaToken
      addressForInitialLiquidity, // _initialLiquidity
      lemaPresaleInstance.address, // _privateSale
      addressForPublicSale, // _publicSale
      addressForMarketing, // _marketing
      lemaChefInstance.address, // _stakingIncentiveDiscount
      addressForAdvisor, // _advisor
      addressForTeam, // _team
      treasuryAccount, // _treasury
    ],
    { deployer, initializer: "initialize" }
  );

  if (!isDev) {
    const totalSupply = await lemaTokenInstance.cap();
    await lemaTokenInstance.mint(
      lemaTokenVestingInstance.address,
      totalSupply.toString()
    );
  }
};
