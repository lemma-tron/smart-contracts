const PresaleLemaV2 = artifacts.require("PresaleLemaV2");
const LemaToken = artifacts.require("LemaToken");
const PresaleLemaRefundVault = artifacts.require("PresaleLemaRefundVault");
const BEP20 = artifacts.require("MockBEP20");
const LemaGovernance = artifacts.require("LemaGovernance");
const LemaTokenVesting = artifacts.require("LemaTokenVesting");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(BEP20, "BUSD", "BUSD", "200000000000000000000000", {
    from: accounts[0],
  });
  await deployer.deploy(LemaToken, accounts[0]);
  await deployer.deploy(PresaleLemaRefundVault, accounts[0], BEP20.address);

  await deployer.deploy(
    PresaleLemaV2,
    LemaToken.address,
    BEP20.address,
    accounts[0],
    PresaleLemaRefundVault.address
  );

  let today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  const startDate = today / 1000;
  const endDate = today.setDate(today.getDate() + 90) / 1000;

  await deployer.deploy(
    LemaGovernance,
    startDate, // _governanceVotingStart
    endDate, // _governanceVotingEnd
    LemaTokenVesting.address, // _lemaTokenVesting
    LemaToken.address, // _lemaToken
    accounts[7], // _treasury
    0 // _startBlock
  );

  await deployer.deploy(
    LemaTokenVesting,
    LemaToken.address, // _lemaToken
    accounts[0], // _initialLiquidity
    accounts[1], // _privateSale
    accounts[2], // _presale
    accounts[3], // _marketing
    LemaGovernance.address, // _stakingIncentiveDiscount
    accounts[5], // _advisor
    accounts[6], // _team
    accounts[7] // _treasury
  );

  const presaleLemaRefundVault = await PresaleLemaRefundVault.deployed();
  const busd = await BEP20.deployed();

  await presaleLemaRefundVault.transferOwnership(PresaleLemaV2.address);

  await busd.approve(
    PresaleLemaRefundVault.address,
    "1000000000000000000000000"
  );
};
