const MockERC20 = artifacts.require("MockERC20");
const MockBEP20 = artifacts.require("MockBEP20");

let mockERC20Instance;
let mockBEP20Instance;

contract("MockBEP20 after upgrade", function (accounts) {
  it("should assert true", async () => {
    mockBEP20Instance = await MockBEP20.deployed();
    console.log("Address:", mockBEP20Instance.address);
    return assert(mockBEP20Instance !== undefined, "MockBEP20 contract should be defined");
  });

  it("should have getOwner method defined", async () => {
    const owner = await mockBEP20Instance.getOwner();
    console.log("Owner:", owner);
    assert.equal(owner, accounts[0]);
  });
});
