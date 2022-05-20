require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const LemaToken = artifacts.require("LemaToken");
const LemaChefV2 = artifacts.require("LemaChefV2");
const LemaGovernance = artifacts.require("LemaGovernance");
const LemaTokenVesting = artifacts.require("LemaTokenVesting");

module.exports = async function (deployer, network, accounts) {
  const treasuryCollectionAccount =
    process.env.ADDRESS_FOR_TAX_COLLECTION || accounts[7];
  const whitelistedAddressesList = process.env.WHITELISTED_ADDRESSES
    ? JSON.parse(process.env.WHITELISTED_ADDRESSES)
    : [...accounts.slice(0, 8)];

  const lemaTokenInstance = await LemaToken.deployed();
  const lemaTokenVestingInstance = await LemaTokenVesting.deployed();

  const lemaChefInstance = await deployProxy(
    LemaChefV2,
    [
      lemaTokenInstance.address, // _lemaToken
      treasuryCollectionAccount, // _treasury
      0, // _startBlock
    ],
    { deployer, initializer: "initialize" }
  );
  await lemaTokenVestingInstance.updateStakingIncentiveDiscountAddress(
    lemaChefInstance.address
  );

  let today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  const startDate = today / 1000;
  const endDate = today.setDate(today.getDate() + 90) / 1000;

  const lemaGovernanceInstance = await deployProxy(
    LemaGovernance,
    [
      startDate, // _governanceVotingStart
      endDate, // _governanceVotingEnd
      lemaChefInstance.address, // LemaChef address
      whitelistedAddressesList, // _whitelistedAddresses
    ],
    { deployer, initializer: "initialize" }
  );
  await lemaChefInstance.updateLemaGovernanceAddress(
    lemaGovernanceInstance.address
  );
};
