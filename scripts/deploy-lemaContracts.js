require("dotenv").config();
const { ethers, upgrades } = require("hardhat");

async function main() {
  const treasuryAccount =
    process.env.ADDRESS_FOR_TREASURY || process.env.OWNER_ADDRESS;
  const treasuryCollectionAccount =
    process.env.ADDRESS_FOR_TAX_COLLECTION || process.env.OWNER_ADDRESS;

  const LemaToken = await ethers.getContractFactory("LemaToken");
  const lemaToken = await upgrades.deployProxy(LemaToken, [
    treasuryAccount, // burner address
    "0x0000000000000000000000000000000000000000", // temp treasuryHandler address
    "0x0000000000000000000000000000000000000000", // temp taxHandler address
  ]);
  await lemaToken.deployed();
  console.log("LemaToken deployed to:", lemaToken.address);

  const isDev = false;
  const isTestNet = true;
  let busdAddress;
  let routerAddress;
  if (isDev) {
    const MockBEP20 = await ethers.getContractFactory("MockBEP20");
    const mockBEP20 = await upgrades.deployProxy(MockBEP20, [
      "BUSD",
      "BUSD",
      "200000000000000000000000",
    ]);
    await mockBEP20.deployed();
    console.log("MockBEP20 deployed to:", mockBEP20.address);
    busdAddress = mockBEP20.address;
    routerAddress = "0xcf1aecc287027f797b99650b1e020ffa0fb0e248";
  } else if (isTestNet) {
    busdAddress = "0xcf1aecc287027f797b99650b1e020ffa0fb0e248"; // https://testnet.bscscan.com/address/0xcf1aecc287027f797b99650b1e020ffa0fb0e248
    routerAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1"; // https://testnet.bscscan.com/address/0xD99D1c33F9fC3444f8101754aBC46c52416550D1
  } else {
    busdAddress = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"; // https://bscscan.com/address/0xe9e7cea3dedca5984780bafc599bd69add087d56
    routerAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; // https://bscscan.com/address/0x10ED43C718714eb63d5aA57B78B54704E256024E
  }

  const TreasuryHandlerAlpha = await ethers.getContractFactory(
    "TreasuryHandlerAlpha"
  );
  const treasuryHandlerAlpha = await upgrades.deployProxy(
    TreasuryHandlerAlpha,
    [
      treasuryCollectionAccount, // treasury address
      busdAddress, // busd address
      lemaToken.address, // lema token address
      routerAddress, // router address
    ]
  );
  await treasuryHandlerAlpha.deployed();
  console.log(
    "TreasuryHandlerAlpha deployed to:",
    treasuryHandlerAlpha.address
  );
  await lemaToken.updateTreasuryHandlerAddress(treasuryHandlerAlpha.address);

  const TaxHandler = await ethers.getContractFactory("LemaTaxHandler");
  const taxHandler = await upgrades.deployProxy(TaxHandler, [
    500, // 5% for exchanges with exchange pools
    routerAddress, // router address
  ]);
  await taxHandler.deployed();
  console.log("TaxHandler deployed to:", taxHandler.address);
  await lemaToken.updateTaxHandlerAddress(taxHandler.address);

  const LemaChefV2 = await ethers.getContractFactory("LemaChefV2");
  const lemaChefV2 = await upgrades.deployProxy(LemaChefV2, [
    lemaToken.address, // _lemaToken
    process.env.OWNER_ADDRESS, // _treasury
    0, // _startBlock
  ]);
  await lemaChefV2.deployed();
  console.log("LemaChefV2 deployed to:", lemaChefV2.address);

  let today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  const startDate = today / 1000;
  const endDate = today.setDate(today.getDate() + 90) / 1000;

  const LemaGovernance = await ethers.getContractFactory("LemaGovernance");
  const lemaGovernance = await upgrades.deployProxy(LemaGovernance, [
    startDate,
    endDate,
    lemaChefV2.address,
    [process.env.OWNER_ADDRESS],
  ]);
  await lemaGovernance.deployed();
  console.log("LemaGovernance deployed to:", lemaGovernance.address);

  await lemaChefV2.updateLemaGovernanceAddress(lemaGovernance.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
