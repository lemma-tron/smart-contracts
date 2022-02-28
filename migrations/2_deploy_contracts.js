const PresaleLemaV2 = artifacts.require("PresaleLemaV2");
const LemaToken = artifacts.require("LemaToken");
const PresaleLemaRefundVault = artifacts.require("PresaleLemaRefundVault");
const BEP20 = artifacts.require("MockBEP20");

// const BUSD_ADDRESS = "0x4Fabb145d64652a948d72533023f6E7A623C7C53";

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

  const presaleLemaRefundVault = await PresaleLemaRefundVault.deployed();
  const busd = await BEP20.deployed();

  await presaleLemaRefundVault.transferOwnership(PresaleLemaV2.address);

  await busd.approve(
    PresaleLemaRefundVault.address,
    "1000000000000000000000000"
  );
};
