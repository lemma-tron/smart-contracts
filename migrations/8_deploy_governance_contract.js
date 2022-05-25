require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const LemaChefV2 = artifacts.require("LemaChefV2");
const LemaGovernance = artifacts.require("LemaGovernance");

module.exports = async function (deployer, network, accounts) {
  const whitelistedAddressesList = process.env.WHITELISTED_ADDRESSES
    ? JSON.parse(process.env.WHITELISTED_ADDRESSES)
    : [...accounts.slice(0, 8)];

  const lemaChefInstance = await LemaChefV2.deployed();

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
