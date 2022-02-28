const PresaleLemaV2 = artifacts.require("PresaleLemaV2");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("PresaleLemaV2", function (accounts) {
  it("should assert true", async () => {
    await PresaleLemaV2.deployed();
    return assert.isTrue(true);
  });

  it("should have 0 tokens raised", async () => {
    const preSale = await PresaleLemaV2.deployed();
    const tokensRaised = await preSale.tokensRaised();
    const busdRaised = await preSale.busdRaised();
    assert.equal(busdRaised.toNumber(), 0);
    return assert.equal(tokensRaised.toNumber(), 0);
  });

  it("should return price", async () => {
    const preSale = await PresaleLemaV2.deployed();
    const price = await preSale.getPrice();
    const startingPrice = await preSale.startingPrice();
    return assert.isTrue(price.toNumber() >= startingPrice.toNumber());
  });

  it("should let tokens to be bought", async () => {
    const preSale = await PresaleLemaV2.deployed();
    // let endDate = new Date();
    // endDate.setUTCHours(0, 0, 0, 0);
    // endDate.setDate(endDate.getDate() + 40);
    // await preSale.setEndDate(parseInt(endDate.getTime() / 1000));
    // let startDate = new Date();
    // startDate.setUTCHours(0, 0, 0, 0);
    // startDate.setDate(startDate.getDate() - 5);
    // await preSale.setStartDate(parseInt(startDate.getTime() / 1000));

    const price = (await preSale.getPrice()).toNumber(); // 50000013108253 as of 28th Feb 2022 with 23rd Feb 2022 as start date
    // console.log("price", price);

    const tokensRaisedInitially = await preSale.tokensRaised();
    await preSale.buyTokensWithBUSD(price, {
      from: accounts[0],
      gas: 1000000,
    });
    const tokensRaisedAfter = await preSale.tokensRaised();
    return assert.isTrue(
      tokensRaisedInitially.toNumber() < tokensRaisedAfter.toNumber()
    );
  });

  it("should assign bought tokens to buyer", async () => {
    const preSale = await PresaleLemaV2.deployed();
    const balance = await preSale.tokenToBeTransferred(accounts[0]);
    return assert.equal(balance.toNumber(), 1);
  });
});
