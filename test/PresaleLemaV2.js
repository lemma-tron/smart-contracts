const PresaleLemaV2 = artifacts.require("PresaleLemaV2");

let preSaleLemaV2Instance;

contract("PresaleLemaV2", function (accounts) {
  it("should assert true", async () => {
    preSaleLemaV2Instance = await PresaleLemaV2.deployed();
    return assert(
      preSaleLemaV2Instance !== undefined,
      "PresaleLemaV2 contract should be defined"
    );
  });

  it("should have 0 tokens raised", async () => {
    const tokensRaised = await preSaleLemaV2Instance.tokensRaised();
    const busdRaised = await preSaleLemaV2Instance.busdRaised();
    assert.equal(busdRaised.toNumber(), 0);
    return assert.equal(tokensRaised.toNumber(), 0);
  });

  it("should return price", async () => {
    const price = await preSaleLemaV2Instance.getPrice();
    const startingPrice = await preSaleLemaV2Instance.startingPrice();
    return assert.isTrue(price.toNumber() >= startingPrice.toNumber());
  });

  it("should let tokens to be bought", async () => {
    // let endDate = new Date();
    // endDate.setUTCHours(0, 0, 0, 0);
    // endDate.setDate(endDate.getDate() + 40);
    // await preSaleLemaV2Instance.setEndDate(parseInt(endDate.getTime() / 1000));
    // let startDate = new Date();
    // startDate.setUTCHours(0, 0, 0, 0);
    // startDate.setDate(startDate.getDate() - 5);
    // await preSaleLemaV2Instance.setStartDate(parseInt(startDate.getTime() / 1000));

    const price = (await preSaleLemaV2Instance.getPrice()).toNumber(); // 50000013108253 as of 28th Feb 2022 with 23rd Feb 2022 as start date
    // console.log("price", price);

    const tokensRaisedInitially = await preSaleLemaV2Instance.tokensRaised();
    await preSaleLemaV2Instance.buyTokensWithBUSD(price, {
      from: accounts[0],
      gas: 1000000,
    });
    const tokensRaisedAfter = await preSaleLemaV2Instance.tokensRaised();
    return assert.isTrue(
      tokensRaisedInitially.toNumber() < tokensRaisedAfter.toNumber()
    );
  });

  it("should assign bought tokens to buyer", async () => {
    const balance = await preSaleLemaV2Instance.tokenToBeTransferred(
      accounts[0]
    );
    return assert.equal(balance.toNumber(), 1);
  });
});
