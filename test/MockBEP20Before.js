const { assert } = require("chai");

const MockERC20 = artifacts.require("MockERC20");
// const MockBEP20 = artifacts.require("MockBEP20");

// let mockERC20Instance;
let mockBEP20Instance;

contract("MockBEP20 before upgrade", function (accounts) {
  it("should assert true", async () => {
    mockBEP20Instance = await MockERC20.deployed();
    console.log("Address:", mockBEP20Instance.address);
    return assert(mockBEP20Instance !== undefined, "MockBEP20 contract should be defined");
  });

  it("should not have getOwner method defined", async () => {
    try {
      const owner = await mockBEP20Instance.getOwner();
      console.log("Owner:", owner);
      assert(false);
    } catch (e) {
      return assert.equal(e.message, "mockBEP20Instance.getOwner is not a function");
    }
  });
});
