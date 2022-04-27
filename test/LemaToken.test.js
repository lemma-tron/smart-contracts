const LemaToken = artifacts.require("LemaToken");
const LemaTaxHandler = artifacts.require("LemaTaxHandler");

let lemaTokenInstance;
let lemaTaxHandlerInstance;

contract("LemaToken", function (accounts) {
  it("should assert true", async () => {
    lemaTokenInstance = await LemaToken.deployed();
    lemaTaxHandlerInstance = await LemaTaxHandler.deployed();
    assert(
      lemaTaxHandlerInstance !== undefined,
      "LemaTaxHandler contract should be defined"
    );
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

  it("should deduct 0% tax on transfer", async () => {
    await lemaTokenInstance.mint(accounts[0], 10000);

    const initialTreasuryBalance = (
      await lemaTokenInstance.balanceOf(accounts[7])
    ).toNumber();
    const initialReceiverBalance = (
      await lemaTokenInstance.balanceOf(accounts[4])
    ).toNumber();

    // console.log(
    //   "Initial Balances:",
    //   initialTreasuryBalance,
    //   initialReceiverBalance
    // );
    assert.equal(initialTreasuryBalance, 0);
    assert.equal(initialReceiverBalance, 0);

    await lemaTokenInstance.transfer(accounts[4], 10000);

    const finalTreasuryBalance = (
      await lemaTokenInstance.balanceOf(accounts[7])
    ).toNumber();
    const finalReceiverBalance = (
      await lemaTokenInstance.balanceOf(accounts[4])
    ).toNumber();

    // console.log("Final Balances:", finalTreasuryBalance, finalReceiverBalance);
    assert.equal(finalTreasuryBalance, 0);
    assert.equal(finalReceiverBalance, 10000);
  });

  it("should deduct 2% tax on trade", async () => {
    await lemaTaxHandlerInstance.addExchangePool(accounts[5]);

    await lemaTokenInstance.mint(accounts[0], 10000);

    const initialTreasuryBalance = (
      await lemaTokenInstance.balanceOf(accounts[7])
    ).toNumber();
    const initialReceiverBalance = (
      await lemaTokenInstance.balanceOf(accounts[5])
    ).toNumber();

    // console.log(
    //   "Initial Balances:",
    //   initialTreasuryBalance,
    //   initialReceiverBalance
    // );
    assert.equal(initialTreasuryBalance, 0);
    assert.equal(initialReceiverBalance, 0);

    await lemaTokenInstance.transfer(accounts[5], 10000);

    const finalTreasuryBalance = (
      await lemaTokenInstance.balanceOf(accounts[7])
    ).toNumber();
    const finalReceiverBalance = (
      await lemaTokenInstance.balanceOf(accounts[5])
    ).toNumber();

    // console.log("Final Balances:", finalTreasuryBalance, finalReceiverBalance);
    assert.equal(finalTreasuryBalance, 200);
    assert.equal(finalReceiverBalance, 9800);
  });
});
