const PresaleLemaV2 = artifacts.require("PresaleLemaV2");

let presaleLemaV2Instance;

contract("PresaleLemaV2", function (accounts) {
  it("should assert true", async () => {
    presaleLemaV2Instance = await PresaleLemaV2.deployed();
    return assert(presaleLemaV2Instance !== undefined, "PresaleLemaV2 contract should be defined");
  });

  it("should be 0", async () => {
    const busdRaised = await presaleLemaV2Instance.busdRaised();
    assert.equal(busdRaised, 0);
  });
});
