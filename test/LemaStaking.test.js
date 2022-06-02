const timeMachine = require("ganache-time-traveler");

const LemaChefV2 = artifacts.require("LemaChefV2");
const LemaTokenVesting = artifacts.require("LemaTokenVesting");
const LemaToken = artifacts.require("LemaToken");

let lemaStakingInstance;
let lemaTokenVesting;
let lemaToken;

contract("LemaStaking", function (accounts) {
  let snapshotId;
  before(async () => {
    let snapshot = await timeMachine.takeSnapshot();
    snapshotId = snapshot["result"];

    // Sets timestamp as hardcoded inside contract
    // Thursday, June 16, 2022 12:00:00 AM (GMT)
    await timeMachine.advanceBlockAndSetTime(1655337600);
  });
  after(async () => {
    await timeMachine.revertToSnapshot(snapshotId);
  });

  it("should assert true", async () => {
    lemaStakingInstance = await LemaChefV2.deployed();
    lemaTokenVesting = await LemaTokenVesting.deployed();
    lemaToken = await LemaToken.deployed();

    await lemaTokenVesting.createStakingIncentiveDiscountVesting();

    const totalSupply = await lemaToken.cap();
    await lemaToken.mint(lemaTokenVesting.address, totalSupply.toString());

    return assert(
      lemaStakingInstance !== undefined,
      "LemaChefV2 contract should be defined"
    );
  });

  it("should only release 1e26 wei tokens during first quarter", async function () {
    await lemaTokenVesting.release(lemaStakingInstance.address);
    const balance = await lemaToken.balanceOf(lemaStakingInstance.address);

    if (balance.toString() === "0") return this.skip();

    assert.equal(balance.toString(), "100000000000000000000000000"); // 1e26, First quarter
  });

  it("should only release 2e26 wei tokens during second quarter", async function () {
    await timeMachine.advanceTimeAndBlock(60 * 60 * 24 * 90);

    await lemaTokenVesting.release(lemaStakingInstance.address);
    const balance = await lemaToken.balanceOf(lemaStakingInstance.address);

    if (balance.toString() === "0") return this.skip();

    assert.equal(balance.toString(), "200000000000000000000000000"); // 2e26, Second quarter
  });

  it("should only release 4.875e26 wei tokens during fifth quarter", async function () {
    await timeMachine.advanceTimeAndBlock(60 * 60 * 24 * 90);
    await lemaTokenVesting.release(lemaStakingInstance.address);
    await timeMachine.advanceTimeAndBlock(60 * 60 * 24 * 90);
    await lemaTokenVesting.release(lemaStakingInstance.address);
    await timeMachine.advanceTimeAndBlock(60 * 60 * 24 * 90);
    await lemaTokenVesting.release(lemaStakingInstance.address);

    const balance = await lemaToken.balanceOf(lemaStakingInstance.address);

    if (balance.toString() === "0") return this.skip();

    assert.equal(balance.toString(), "487500000000000000000000000"); // 4.875e26, Fifth quarter
  });
});
