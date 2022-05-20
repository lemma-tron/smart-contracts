const { assert } = require("chai");
const timeMachine = require("ganache-time-traveler");

const LemaToken = artifacts.require("LemaToken");
const PresaleLemaV2 = artifacts.require("PresaleLemaV2");
const PresaleLemaRefundVault = artifacts.require("PresaleLemaRefundVault");
const MockBEP20 = artifacts.require("mock/MockBEP20");

let lemaTokenInstance, presaleInstance, presaleVaultInstance, busdInstance;
let currentTimestamp;

contract("PresaleLemaV2", function (accounts) {
  before("Deploy Contracts", async () => {
    // May 25th 2022, 12 am (UTC)
    currentTimestamp = 1653436800;

    lemaTokenInstance = await LemaToken.deployed();
    busdInstance = await MockBEP20.deployed();
    presaleInstance = await PresaleLemaV2.deployed();
    presaleVaultInstance = await PresaleLemaRefundVault.deployed();

    // preminted LEMA token to Presale
    await lemaTokenInstance.mint(
      presaleInstance.address,
      "3000000000000000000000000"
    );

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

  beforeEach(async () => {
    await timeMachine.advanceBlockAndSetTime(currentTimestamp);
  });

  describe("[Test Presale Basics]", () => {
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
      var updateStartTimestamp = currentTimestamp + 1800;
      await presaleInstance.setStartDate(updateStartTimestamp, {
        from: accounts[0],
      });
      var updateEndTimestamp = updateStartTimestamp + 5000;
      await presaleInstance.setEndDate(updateEndTimestamp, {
        from: accounts[0],
      });

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 1000);

      assert.equal(
        (await presaleInstance.getPrice()).toString(),
        "239999999999999"
      );

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
    });

    it("should end presale and refund if goal not reached", async function () {
      var updateStartTimestamp = currentTimestamp + 1800;
      await presaleInstance.setStartDate(updateStartTimestamp, {
        from: accounts[0],
      });
      var updateEndTimestamp = updateStartTimestamp + 5000;
      await presaleInstance.setEndDate(updateEndTimestamp, {
        from: accounts[0],
      });

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 1000);

      assert.equal(
        (await presaleInstance.getPrice()).toString(),
        "239999999999999"
      );

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
        "20000000000000000000"
      );

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 5100);

      assert.isTrue(await presaleInstance.hasEnded({ from: accounts[0] }));

      await presaleInstance.checkCompletedPresale({ from: accounts[3] });

      await presaleInstance.enableRefund({ from: accounts[0] });

      assert.isTrue(await presaleInstance.isRefunding({ from: accounts[0] }));

      assert.equal(
        (await presaleInstance.busdRaised()).toString(),
        "20000000000000000000"
      );
      await presaleInstance.claimRefund({ from: accounts[3] });
      assert.equal(
        (await presaleInstance.busdRaised()).toString(),
        "10000000000000000000"
      );
      assert.equal(
        (
          await presaleInstance.tokenToBeClaimed({ from: accounts[3] })
        ).toString(),
        "0"
      );
    });
  });

  xdescribe("[Test Presale Overall Scenario]", () => {
    it("should end presale, mark goal reached, claim token (overall scenarios)", async function () {
      var updateStartTimestamp = currentTimestamp + 1800;
      await presaleInstance.setStartDate(updateStartTimestamp, {
        from: accounts[0],
      });
      var updateEndTimestamp = updateStartTimestamp + 5000;
      await presaleInstance.setEndDate(updateEndTimestamp, {
        from: accounts[0],
      });

      await timeMachine.advanceBlockAndSetTime(updateStartTimestamp + 1000);

      assert.equal(
        (await presaleInstance.getPrice()).toString(),
        "239999999999999"
      );

      await busdInstance.approve(
        await presaleInstance.vault(),
        "10000000000000000000",
        {
          from: accounts[4],
        }
      );

      await presaleInstance.buyTokensWithBUSD("10000000000000000000", {
        from: accounts[4],
      });

      assert.equal(
        (
          await busdInstance.balanceOf(await presaleInstance.vault())
        ).toString(),
        "30000000000000000000"
      );
    });
  });
});
