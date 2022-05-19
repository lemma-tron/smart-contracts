require("dotenv").config();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const MockBEP20 = artifacts.require("MockBEP20");
const LemaToken = artifacts.require("LemaToken");
const PresaleLemaRefundVault = artifacts.require("PresaleLemaRefundVault");
const PresaleLemaV2 = artifacts.require("PresaleLemaV2");
const LemaChefV2 = artifacts.require("LemaChefV2");
const LemaGovernance = artifacts.require("LemaGovernance");
const LemaTokenVesting = artifacts.require("LemaTokenVesting");
const TaxHandler = artifacts.require("LemaTaxHandler");
const TreasuryHandlerAlpha = artifacts.require("TreasuryHandlerAlpha");

module.exports = async function (deployer, network, accounts) {
  const ownerAccount = accounts[0];
  const addressForInitialLiquidity =
    process.env.ADDRESS_FOR_INITIAL_LIQUIDITY || ownerAccount;
  const addressForPrivateSale =
    process.env.ADDRESS_FOR_PRIVATE_SALE || accounts[1];
  const addressForPublicSale =
    process.env.ADDRESS_FOR_PUBLIC_SALE || accounts[2];
  const addressForMarketing = process.env.ADDRESS_FOR_MARKETING || accounts[3];
  const addressForAdvisor = process.env.ADDRESS_FOR_ADVISOR || accounts[4];
  const addressForTeam = process.env.ADDRESS_FOR_TEAM || accounts[5];
  const treasuryAccount = process.env.ADDRESS_FOR_TREASURY || accounts[6];
  const treasuryCollectionAccount =
    process.env.ADDRESS_FOR_TAX_COLLECTION || accounts[7];
  const whitelistedAddressesList = process.env.WHITELISTED_ADDRESSES
    ? JSON.parse(process.env.WHITELISTED_ADDRESSES)
    : [...accounts.slice(0, 8)];
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
      ownerAccount, // burner address
      "0x0000000000000000000000000000000000000000", // temp treasuryHandler address
      "0x0000000000000000000000000000000000000000", // temp taxHandler address
      "0x0000000000000000000000000000000000000000", // temp lemaTokenVesting address
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

  await lemaTokenInstance.updateTreasuryHandlerAddress(
    treasuryHandlerAlphaInstance.address
  );

  await lemaTokenInstance.updateTaxHandlerAddress(taxHandlerInstance.address);

  const presaleLemaRefundVaultInstance = await deployProxy(
    PresaleLemaRefundVault,
    [ownerAccount, busdAddress],
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
      ownerAccount,
      presaleLemaRefundVaultInstance.address,
    ],
    { deployer, initializer: "initialize" }
  );

  const lemaChefInstance = await deployProxy(
    LemaChefV2,
    [
      lemaTokenInstance.address, // _lemaToken
      treasuryCollectionAccount, // _treasury
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
      whitelistedAddressesList, // _whitelistedAddresses
    ],
    { deployer, initializer: "initialize" }
  );

  await lemaChefInstance.updateLemaGovernanceAddress(
    lemaGovernanceInstance.address
  );

  const lemaTokenVestingInstance = await deployProxy(
    LemaTokenVesting,
    [
      lemaTokenInstance.address, // _lemaToken
      addressForInitialLiquidity, // _initialLiquidity
      addressForPrivateSale, // _privateSale
      addressForPublicSale, // _publicSale
      addressForMarketing, // _marketing
      lemaChefInstance.address, // _stakingIncentiveDiscount
      addressForAdvisor, // _advisor
      addressForTeam, // _team
      treasuryAccount, // _treasury
    ],
    { deployer, initializer: "initialize" }
  );

  await lemaTokenInstance.updateLemaTokenVestingAddress(
    lemaTokenVestingInstance.address
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
