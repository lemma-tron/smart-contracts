const LemaToken = artifacts.require("LemaToken");
const LemaTaxHandler = artifacts.require("LemaTaxHandler");
const TreasuryHandlerAlpha = artifacts.require("TreasuryHandlerAlpha");

let lemaTokenInstance;
let lemaTaxHandlerInstance;
let treasuryHandlerInstance;

contract("LemaToken", function (accounts) {
  it("should assert true", async () => {
    lemaTokenInstance = await LemaToken.deployed();
    lemaTaxHandlerInstance = await LemaTaxHandler.deployed();
    treasuryHandlerInstance = await TreasuryHandlerAlpha.deployed();
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

  it("should deduct 0% tax on normal transfers", async () => {
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

  it("should deduct 5% tax on trade transfers", async () => {
    await lemaTaxHandlerInstance.addExchangePool(accounts[5]);

    await lemaTokenInstance.mint(accounts[0], 10000);

    const treasuryAddress = treasuryHandlerInstance.address;
    const receiverAddress = accounts[5];

    const initialTreasuryBalance = (
      await lemaTokenInstance.balanceOf(treasuryAddress)
    ).toNumber();
    const initialReceiverBalance = (
      await lemaTokenInstance.balanceOf(receiverAddress)
    ).toNumber();

    assert.equal(initialTreasuryBalance, 0);
    assert.equal(initialReceiverBalance, 0);

    await lemaTokenInstance.transfer(receiverAddress, 10000);

    const finalTreasuryBalance = (
      await lemaTokenInstance.balanceOf(treasuryAddress)
    ).toNumber();
    const finalReceiverBalance = (
      await lemaTokenInstance.balanceOf(receiverAddress)
    ).toNumber();

    assert.equal(finalTreasuryBalance, 500);
    assert.equal(finalReceiverBalance, 9500);
  });

  it("should not deduct more than 3% tax on trade transfers with uniswapV2Router", async () => {
    const uniswapV2Router = await lemaTaxHandlerInstance.uniswapV2Router();

    await lemaTokenInstance.mint(accounts[0], 10000);

    const treasuryAddress = treasuryHandlerInstance.address;
    const receiverAddress = uniswapV2Router;

    const initialTreasuryBalance = (
      await lemaTokenInstance.balanceOf(treasuryAddress)
    ).toNumber();
    const initialReceiverBalance = (
      await lemaTokenInstance.balanceOf(receiverAddress)
    ).toNumber();

    assert.equal(initialTreasuryBalance, 500);
    assert.equal(initialReceiverBalance, 0);

    await lemaTokenInstance.transfer(receiverAddress, 10000);

    const finalTreasuryBalance = (
      await lemaTokenInstance.balanceOf(treasuryAddress)
    ).toNumber();
    const finalReceiverBalance = (
      await lemaTokenInstance.balanceOf(receiverAddress)
    ).toNumber();

    assert.equal(finalTreasuryBalance, 800);
    assert.equal(finalReceiverBalance, 9700);
  });

  it("should not deduct tax on trade transfers with wallets added as _exempted", async () => {
    const uniswapV2Router = await lemaTaxHandlerInstance.uniswapV2Router();

    await lemaTaxHandlerInstance.addExemption(accounts[0]);

    await lemaTokenInstance.mint(accounts[0], 10000);

    const treasuryAddress = treasuryHandlerInstance.address;
    const receiverAddress = uniswapV2Router;

    const initialTreasuryBalance = (
      await lemaTokenInstance.balanceOf(treasuryAddress)
    ).toNumber();
    const initialReceiverBalance = (
      await lemaTokenInstance.balanceOf(receiverAddress)
    ).toNumber();

    assert.equal(initialTreasuryBalance, 800);
    assert.equal(initialReceiverBalance, 9700);

    await lemaTokenInstance.transfer(receiverAddress, 10000);

    const finalTreasuryBalance = (
      await lemaTokenInstance.balanceOf(treasuryAddress)
    ).toNumber();
    const finalReceiverBalance = (
      await lemaTokenInstance.balanceOf(receiverAddress)
    ).toNumber();

    assert.equal(finalTreasuryBalance, 800);
    assert.equal(finalReceiverBalance, 19700);
  });
});
