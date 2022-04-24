const LemaToken = artifacts.require("LemaToken");

let lemaTokenInstance;

contract("LemaToken", function (accounts) {
  it("should assert true", async () => {
    lemaTokenInstance = await LemaToken.deployed();
    return assert(
      lemaTokenInstance !== undefined,
      "LemaToken contract should be defined"
    );
  });

  it("should have getOwner method defined", async () => {
    const owner = await lemaTokenInstance.getOwner();
    assert.equal(owner, accounts[0]);
  });

  it("should return LemaChef's address", async () => {
    const lemaChef = await lemaTokenInstance.lemaChef();
    assert.equal(lemaChef, "0x0000000000000000000000000000000000000000");
  });

  it("should have cap", async () => {
    const cap = await lemaTokenInstance.cap();
    assert.equal(cap, 1e28);
  });
});
