const { time } = require("@openzeppelin/test-helpers");
const timeMachine = require("ganache-time-traveler");

const LemaToken = artifacts.require("LemaToken");
const PresaleLemaV2 = artifacts.require("PresaleLemaV2");
const PresaleLemaRefundVault = artifacts.require("PresaleLemaRefundVault");
const MockBEP20 = artifacts.require("mock/MockBEP20");

let lemaTokenInstance, presaleInstance, presaleVaultInstance, busdInstance;

contract("PresaleLemaV2", function (accounts) {
  let snapshotId;
  beforeEach(async () => {
    let snapshot = await timeMachine.takeSnapshot();
    snapshotId = snapshot["result"];

    lemaTokenInstance = await LemaToken.deployed();
    presaleInstance = await PresaleLemaV2.deployed();
    presaleVaultInstance = await PresaleLemaRefundVault.deployed();

    // preminted LEMA token to Presale
    await lemaTokenInstance.mint(
      presaleInstance.address,
      "3000000000000000000000000"
    );

    busdInstance = await MockBEP20.deployed();

    await busdInstance.transfer(accounts[2], "20000000000000000000000", {
      from: accounts[0],
    });
    await busdInstance.transfer(accounts[3], "20000000000000000000000", {
      from: accounts[0],
    });
    await busdInstance.transfer(accounts[4], "20000000000000000000000", {
      from: accounts[0],
    });
    await busdInstance.transfer(accounts[5], "20000000000000000000000", {
      from: accounts[0],
    });
    await busdInstance.transfer(accounts[6], "20000000000000000000000", {
      from: accounts[0],
    });
    await busdInstance.transfer(accounts[7], "20000000000000000000000", {
      from: accounts[0],
    });
    await busdInstance.transfer(accounts[8], "20000000000000000000000", {
      from: accounts[0],
    });
  });

  afterEach(async () => {
    await timeMachine.revertToSnapshot(snapshotId);
  });

  it("should assert true", async () => {
    assert(
      lemaTokenInstance !== undefined,
      "LemaToken contract should be defined"
    );

    assert(busdInstance !== undefined, "MockBUSD contract should be defined");

    assert(
      presaleVaultInstance !== undefined,
      "PresaleVault contract should be defined"
    );

    return assert(
      presaleInstance !== undefined,
      "PresaleLemaV2 contract should be defined"
    );
  });

  it("should be 0", async () => {
    const busdRaised = await presaleInstance.busdRaised();
    assert.equal(busdRaised, 0);
  });

  describe("[Test Presale Variables]", () => {
    it("should have correct values", async function () {
      var lemaAddress = await presaleInstance.lemaToken();
      assert.equal(
        lemaAddress.toString(),
        lemaTokenInstance.address.toString()
      );

      var busdAddress = await presaleInstance.busd();
      assert.equal(busdAddress.toString(), busdInstance.address.toString());
    });

    it("should update start and end time", async function () {
      var currentTimestamp = Number(await time.latest());
      var updateStartTimestamp = currentTimestamp + 3600;
      await presaleInstance.setStartDate(updateStartTimestamp, {
        from: accounts[0],
      });
      var startTime = await presaleInstance.startTime();
      assert.equal(startTime.toString(), updateStartTimestamp.toString());

      var updateEndTimestamp = updateStartTimestamp + 7200;
      await presaleInstance.setEndDate(updateEndTimestamp, {
        from: accounts[0],
      });
      var endTime = await presaleInstance.endTime();
      assert.equal(endTime.toString(), updateEndTimestamp.toString());
    });
  });

  describe("[Test Presale Buy functionalities]", () => {
    it("should allow buying LEMA token", async function () {
      var currentTimestamp = Number(await time.latest());
      var updateStartTimestamp = currentTimestamp + 1800;
      await presaleInstance.setStartDate(updateStartTimestamp, {
        from: accounts[0],
      });
      var updateEndTimestamp = updateStartTimestamp + 5000;
      await presaleInstance.setEndDate(updateEndTimestamp, {
        from: accounts[0],
      });

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 1000);

      await busdInstance.approve(
        await presaleInstance.vault(),
        "10000000000000000000",
        {
          from: accounts[2],
        }
      );
      await presaleInstance.buyTokensWithBUSD("10000000000000000000", {
        from: accounts[2],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "10000000000000000000"
      );

      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[2] })
        ).toString(),
        "41567942802510876534658"
      );
    });

    it("should end presale and refund if goal not reached", async function () {
      var currentTimestamp = Number(await time.latest());
      var updateStartTimestamp = currentTimestamp + 1800;
      await presaleInstance.setStartDate(updateStartTimestamp, {
        from: accounts[0],
      });
      var updateEndTimestamp = updateStartTimestamp + 5000;
      await presaleInstance.setEndDate(updateEndTimestamp, {
        from: accounts[0],
      });

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 1000);

      await busdInstance.approve(
        await presaleInstance.vault(),
        "10000000000000000000",
        {
          from: accounts[3],
        }
      );
      await presaleInstance.buyTokensWithBUSD("10000000000000000000", {
        from: accounts[3],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "10000000000000000000"
      );

      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[3] })
        ).toString(),
        "41600798735335891508439"
      );

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 5100);

      assert.isNotTrue(
        await presaleInstance.goalReached({ from: accounts[0] })
      );
      assert.isTrue(await presaleInstance.hasEnded({ from: accounts[0] }));

      await presaleInstance.checkCompletedPresale({ from: accounts[3] });

      assert.isTrue(await presaleInstance.isRefunding({ from: accounts[0] }));

      assert.equal(
        (await presaleInstance.busdRaised()).toString(),
        "10000000000000000000"
      );
      await presaleInstance.claimRefund({ from: accounts[3] });
      assert.equal(
        (await presaleInstance.busdRaised()).toString(),
        "0"
      );
      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[3] })
        ).toString(),
        "0"
      );
    });

    it("should end presale, mark goal reached, claim token (overall scenarios)", async function () {
      var currentTimestamp = Number(await time.latest());
      var updateStartTimestamp = currentTimestamp + 2000;
      await presaleInstance.setStartDate(updateStartTimestamp, {
        from: accounts[0],
      });
      var updateEndTimestamp = updateStartTimestamp + 10000;
      await presaleInstance.setEndDate(updateEndTimestamp, {
        from: accounts[0],
      });

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 5000);

      await busdInstance.approve(
        await presaleInstance.vault(),
        "10000000000000000000",
        {
          from: accounts[3],
        }
      );
      await presaleInstance.buyTokensWithBUSD("10000000000000000000", {
        from: accounts[3],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "10000000000000000000"
      );

      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[3] })
        ).toString(),
        "19033842171380751139826"
      );

      await busdInstance.approve(
        await presaleInstance.vault(),
        "10000000000000000000000",
        {
          from: accounts[4],
        }
      );
      await presaleInstance.buyTokensWithBUSD("10000000000000000000000", {
        from: accounts[4],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "10010000000000000000000"
      );
      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[4] })
        ).toString(),
        "400000000000000000000000"
      );

      await busdInstance.approve(
        await presaleInstance.vault(),
        "10000000000000000000000",
        {
          from: accounts[4],
        }
      );
      await presaleInstance.buyTokensWithBUSD("10000000000000000000000", {
        from: accounts[4],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "30000000000000000000000"
      );
      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[4] })
        ).toString(),
        "400000000000000000000000"
      );

      await busdInstance.approve(
        await presaleInstance.vault(),
        "5000000000000000000000",
        {
          from: accounts[5],
        }
      );
      await presaleInstance.buyTokensWithBUSD("5000000000000000000000", {
        from: accounts[5],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "35000000000000000000000"
      );
      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[5] })
        ).toString(),
        "166666666666666666666666"
      );

      await busdInstance.approve(
        await presaleInstance.vault(),
        "10000000000000000000000",
        {
          from: accounts[6],
        }
      );
      await presaleInstance.buyTokensWithBUSD("10000000000000000000000", {
        from: accounts[6],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "45000000000000000000000"
      );
      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[6] })
        ).toString(),
        "285714285714285714285714"
      );

      await busdInstance.approve(
        await presaleInstance.vault(),
        "10000000000000000000000",
        {
          from: accounts[7],
        }
      );
      await presaleInstance.buyTokensWithBUSD("10000000000000000000000", {
        from: accounts[7],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "55000000000000000000000"
      );
      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[7] })
        ).toString(),
        "222222222222222222222222"
      );

      await busdInstance.approve(
        await presaleInstance.vault(),
        "5000000000000000000000",
        {
          from: accounts[8],
        }
      );
      await presaleInstance.buyTokensWithBUSD("5000000000000000000000", {
        from: accounts[8],
      });
      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "60000000000000000000000"
      );
      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[8] })
        ).toString(),
        "100000000000000000000000"
      );

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 11000);

      assert.isTrue(await presaleInstance.goalReached({ from: accounts[0] }));
      assert.isTrue(await presaleInstance.hasEnded({ from: accounts[0] }));

      await presaleInstance.checkCompletedPresale({ from: accounts[2] });

      assert.isNotTrue(
        await presaleInstance.isRefunding({ from: accounts[0] })
      );

      await presaleInstance.setTokenClaimable(true, { from: accounts[0] });
      assert.equal(
        (await lemaTokenInstance.balanceOf(accounts[2])).toString(),
        "0"
      );
      await presaleInstance.claimNenToken({ from: accounts[2] });
      assert.equal(
        (await lemaTokenInstance.balanceOf(accounts[2])).toString(),
        "400000000000000000000000"
      );

      assert.equal((await busdInstance.balanceOf(accounts[1])).toString(), "0");
      await presaleInstance.withdrawBUSDFromVault({ from: accounts[0] });
      assert.equal(
        (await busdInstance.balanceOf(accounts[1])).toString(),
        "60000000000000000000000"
      );
    });
  });
});
