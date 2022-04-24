const LemaTokenVesting = artifacts.require("LemaTokenVesting");

let lemaTokenVestingInstance;

contract("LemaTokenVesting", function (accounts) {
  it("should assert true", async () => {
    lemaTokenVestingInstance = await LemaTokenVesting.deployed();
    return assert(
      lemaTokenVestingInstance !== undefined,
      "LemaTokenVesting contract should be defined"
    );
  });
});
