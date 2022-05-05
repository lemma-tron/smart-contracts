const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const MockBEP20 = artifacts.require("MockBEP20");
const LemaToken = artifacts.require("LemaToken");
const PresaleLemaRefundVault = artifacts.require("PresaleLemaRefundVault");
const PresaleLemaV2 = artifacts.require("PresaleLemaV2");
const LemaChefV2 = artifacts.require("LemaChefV2");
const LemaGovernance = artifacts.require("LemaGovernance");
const LemaTokenVesting = artifacts.require("LemaTokenVesting");
const LemaTaxHandler = artifacts.require("LemaTaxHandler");
const TreasuryHandlerAlpha = artifacts.require("TreasuryHandlerAlpha");

module.exports = async function (deployer, network, accounts) {
  const isDev = ["develop", "development"].includes(network);
  let busdAddress;
  let busdInstance;
  let treasuryAddress = accounts[7];
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
  } else {
    busdAddress = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"; // https://bscscan.com/address/0xe9e7cea3dedca5984780bafc599bd69add087d56
  }

  const lemaTaxHandlerInstance = await deployProxy(LemaTaxHandler, [500], {
    deployer,
    initializer: "initialize",
  });

  const lemaTokenInstance = await deployProxy(
    LemaToken,
    [
      accounts[0], // burner address
      treasuryAddress, // treasury address
      lemaTaxHandlerInstance.address, // taxHandler address
    ],
    {
      deployer,
      initializer: "initialize",
    }
  );

  if (isDev) {
    // const treasuryHandlerAlphaInstance =
    await deployProxy(
      TreasuryHandlerAlpha,
      [
        treasuryAddress, // treasury address
        busdAddress, // busd address
        lemaTokenInstance.address, // lema token address
        "0x10ED43C718714eb63d5aA57B78B54704E256024E", // router address
        0, // initial liquidity basis points
        0, // initial price impact basis points
      ],
      {
        deployer,
        initializer: "initialize",
      }
    );
  }

  const presaleLemaRefundVaultInstance = await deployProxy(
    PresaleLemaRefundVault,
    [accounts[0], busdAddress],
    {
      deployer,
      initializer: "initialize",
    }
  );
  const presaleLemaInstance = await deployProxy(
    PresaleLemaV2,
    [
      lemaTokenInstance.address,
      busdAddress,
      accounts[0],
      presaleLemaRefundVaultInstance.address,
    ],
    { deployer, initializer: "initialize" }
  );

  const lemaChefInstance = await deployProxy(
    LemaChefV2,
    [
      lemaTokenInstance.address, // _lemaToken
      treasuryAddress, // _treasury
      0, // _startBlock
    ],
    { deployer, initializer: "initialize" }
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
    ],
    { deployer, initializer: "initialize" }
  );

  await lemaChefInstance.updateLemaGovernanceAddress(
    lemaGovernanceInstance.address
  );

  await deployProxy(
    LemaTokenVesting,
    [
      lemaTokenInstance.address, // _lemaToken
      accounts[0], // _initialLiquidity
      accounts[1], // _privateSale
      accounts[2], // _publicSale
      accounts[3], // _marketing
      lemaChefInstance.address, // _stakingIncentiveDiscount
      accounts[5], // _advisor
      accounts[6], // _team
      treasuryAddress, // _treasury
    ],
    { deployer, initializer: "initialize" }
  );

  await presaleLemaRefundVaultInstance.transferOwnership(
    presaleLemaInstance.address
  );

  isDev &&
    (await busdInstance.approve(
      presaleLemaRefundVaultInstance.address,
      "1000000000000000000000000"
    ));
};