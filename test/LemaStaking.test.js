const LemaChefV2 = artifacts.require("LemaChefV2");
const LemaTokenVesting = artifacts.require("LemaTokenVesting");
const LemaToken = artifacts.require("LemaToken");

let lemaStakingInstance;

contract("LemaStaking", function (accounts) {
  it("should assert true", async () => {
    lemaStakingInstance = await LemaChefV2.deployed();
    return assert(
      lemaStakingInstance !== undefined,
      "LemaChefV2 contract should be defined"
    );
  });

  it("should have balance", async () => {
    const lemaTokenVesting = await LemaTokenVesting.deployed();
    const lemaToken = await LemaToken.deployed();

    await lemaTokenVesting.createStakingIncentiveDiscountVesting();

    const totalSupply = await lemaToken.cap();

    await lemaToken.mint(lemaTokenVesting.address, totalSupply.toString());

    await lemaTokenVesting.release(lemaStakingInstance.address);
    const balance = await lemaToken.balanceOf(lemaStakingInstance.address);

    assert.equal(balance.toString(), "100000000000000000000000000");
  });

  // it("should have totalAllocPoint", async () => {
  //   await lemaStakingInstance.reallocPoint();

  //   const totalAllocPoint = await lemaStakingInstance.totalAllocPoint();

  //   assert.equal(totalAllocPoint.toString(), "100000000000000000000000000");
  // });
});
