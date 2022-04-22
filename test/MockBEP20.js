const MockBEP20 = artifacts.require("MockBEP20");

let mockBEP20Instance;

contract("MockBEP20", function (accounts) {
  it("should assert true", async () => {
    mockBEP20Instance = await MockBEP20.deployed();
    // console.log("Address:", mockBEP20Instance.address);
    return assert(mockBEP20Instance !== undefined, "MockBEP20 contract should be defined");
  });

  it("should have getOwner method defined", async () => {
    const owner = await mockBEP20Instance.getOwner();
    // console.log("Owner:", owner);
    assert.equal(owner, accounts[0]);
  });
});
