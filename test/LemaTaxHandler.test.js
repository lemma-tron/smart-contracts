const LemaTaxHandler = artifacts.require("LemaTaxHandler");

let lemaTaxHandlerInstance;

contract("LemaTaxHandler", function (accounts) {
  it("should assert true", async () => {
    lemaTaxHandlerInstance = await LemaTaxHandler.deployed();
    return assert(
      lemaTaxHandlerInstance !== undefined,
      "LemaToken contract should be defined"
    );
  });

  it("should have initial values", async () => {
    const taxBasisPoints = await lemaTaxHandlerInstance.taxBasisPoints();
    // console.log("taxBasisPoints", taxBasisPoints.toNumber());
    assert.equal(
      taxBasisPoints.toNumber(),
      500,
      "taxBasisPoints should be 500"
    );
    const uniswapTaxBasisPoints =
      await lemaTaxHandlerInstance.uniswapTaxBasisPoints();
    // console.log("uniswapTaxBasisPoints", uniswapTaxBasisPoints.toNumber());
    assert.equal(
      uniswapTaxBasisPoints.toNumber(),
      200,
      "uniswapTaxBasisPoints should be 200"
    );
  });

  it("should let exchange pool to be added", async () => {
    const exchangePoolAddress = accounts[1];
    await lemaTaxHandlerInstance.addExchangePool(exchangePoolAddress);
    const exchangePools =
      await lemaTaxHandlerInstance.getExchangePoolAddresses();
    assert.equal(
      exchangePools[0],
      exchangePoolAddress,
      "exchangePoolAddress should be added"
    );
  });

  it("should return 0% tax on normal transfers", async () => {
    const tax = await lemaTaxHandlerInstance.getTax(
      accounts[0],
      accounts[5],
      100
    );
    return assert.equal(tax.toNumber(), 0, "tax should be 0");
  });

  it("should return 5% tax on transfers to or from exchangePools", async () => {
    const taxTo = await lemaTaxHandlerInstance.getTax(
      accounts[0],
      accounts[1],
      100
    );
    assert.equal(taxTo.toNumber(), 5, "tax should be 5");
    const taxFrom = await lemaTaxHandlerInstance.getTax(
      accounts[1],
      accounts[0],
      100
    );
    // console.log("taxFrom", taxFrom.toNumber());
    return assert.equal(taxFrom.toNumber(), 5, "tax should be 5");
  });
});
