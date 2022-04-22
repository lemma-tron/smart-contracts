const PresaleLemaRefundVault = artifacts.require("PresaleLemaRefundVault");

let presaleLemaRefundVaultInstance;

contract("PresaleLemaRefundVault", function (accounts) {
  it("should assert true", async () => {
    presaleLemaRefundVaultInstance = await PresaleLemaRefundVault.deployed();
    return assert(presaleLemaRefundVaultInstance !== undefined, "PresaleLemaRefundVault contract should be defined");
  });

  it("should be 0", async () => {
    const totalBUSDDeposited = await presaleLemaRefundVaultInstance.totalBUSDDeposited();
    assert.equal(totalBUSDDeposited, 0);
  });
});
