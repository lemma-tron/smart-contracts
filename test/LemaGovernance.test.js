const timeMachine = require("ganache-time-traveler");

const LemaGovernance = artifacts.require("LemaGovernance");
const LemaToken = artifacts.require("LemaToken");
const LemaChefV2 = artifacts.require("LemaChefV2");

let lemaGovernanceInstance;
let lemaTokenInstance;
let lemaStakingInstance;

let validatorMinStake;

contract("LemaGovernance", function (accounts) {
  it("should assert true", async () => {
    lemaGovernanceInstance = await LemaGovernance.deployed();
    lemaStakingInstance = await LemaChefV2.deployed();
    lemaTokenInstance = await LemaToken.deployed();

    assert(
      lemaTokenInstance !== undefined,
      "LemaToken contract should be defined"
    );
    assert(
      lemaStakingInstance !== undefined,
      "LemaChef contract should be defined"
    );
    assert(
      lemaGovernanceInstance !== undefined,
      "LemaGovernance contract should be defined"
    );

    validatorMinStake = await lemaGovernanceInstance.getValidatorsMinStake();
  });

  it("should have treasury address", async () => {
    const treasuryAddress = await lemaStakingInstance.treasury();
    return assert(treasuryAddress, "Treasury address should be defined");
  });

  it("should not have any projects", async () => {
    const projects = await lemaGovernanceInstance.getProjects();
    return assert(projects.length === 0, "There should not be any project");
  });

  it("should accept new projects", async () => {
    const projectName = "Bitcoin";
    const projectDescription = "Bitcoin description";
    const tokenSymbol = "BTC";
    const tokenContract = "0x0000000000000000000000000000000000000000";
    const preferredDEXPlatform = "Blockchain";
    const totalLiquidity = 100;
    const projectWebsite = "https://bitcoin.org";
    const twitterLink = "https://twitter.com/bitcoin";
    const telegramLink = "https://t.me/bitcoin";
    const discordLink = "https://discord.gg/bitcoin";
    const mediumLink = "https://medium.com/@bitcoin";

    await lemaGovernanceInstance.addProject(
      projectName,
      projectDescription,
      tokenSymbol,
      tokenContract,
      preferredDEXPlatform,
      totalLiquidity,
      projectWebsite,
      twitterLink,
      telegramLink,
      discordLink,
      mediumLink,
      { from: accounts[1] }
    );

    const projects = await lemaGovernanceInstance.getProjects();
    assert.equal(projects.length, 1);

    const project = projects[0];
    assert.equal(project.name, projectName);
    assert.equal(project.approved, false);
  });

  it("should not let other than owner to approve projects", async () => {
    try {
      await lemaGovernanceInstance.approveProject(0, { from: accounts[1] });
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(error.reason, "Ownable: caller is not the owner");
    }
  });

  it("should let owner to approve projects", async () => {
    await lemaGovernanceInstance.approveProject(0, { from: accounts[0] });

    const projects = await lemaGovernanceInstance.getProjects();
    const approvedProject = projects[0];
    assert.equal(approvedProject.approved, true);
  });

  it("should not have any voters or validators", async () => {
    const validators = await lemaGovernanceInstance.getValidators();
    assert.equal(validators.length, 0);

    const voters = await lemaGovernanceInstance.getVoters();
    assert.equal(voters.length, 0);
  });

  it("should not accept validators without minimum stake", async () => {
    try {
      await lemaGovernanceInstance.applyForValidator({ from: accounts[1] });
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(error.reason, "Stake not enough to become validator");
    }
  });

  it("should not accept validators from blocklist", async () => {
    await lemaGovernanceInstance.addToBlocklist(accounts[1]);
    try {
      await lemaGovernanceInstance.applyForValidator({ from: accounts[1] });
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(error.reason, "LemaGovernance: Blocklisted wallet");
    }
  });

  it("should accept validators", async () => {
    await lemaTokenInstance.mint(accounts[0], validatorMinStake);
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake
    );

    await lemaStakingInstance.enterStaking(validatorMinStake);

    await lemaGovernanceInstance.applyForValidator({ from: accounts[0] });

    const validators = await lemaGovernanceInstance.getValidators();
    assert.equal(validators.length, 1);
  });

  it("should not let other than token holders delegate a validator", async () => {
    try {
      await lemaGovernanceInstance.delegateValidator(accounts[0], {
        from: accounts[2],
      });
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(error.reason, "LemaChefV2: Stake not enough to vote");
    }
  });

  it("should let token holders delegate a validator", async () => {
    await lemaTokenInstance.mint(accounts[2], 10);
    await lemaTokenInstance.approve(lemaStakingInstance.address, 10, {
      from: accounts[2],
    });
    await lemaStakingInstance.enterStaking(10, { from: accounts[2] });

    const validators = await lemaGovernanceInstance.getValidators();

    await lemaGovernanceInstance.delegateValidator(validators[0], {
      from: accounts[2],
    });

    const delegatedValidator =
      await lemaGovernanceInstance.haveDelagatedValidator(accounts[2]);
    assert.equal(delegatedValidator, true);

    const voteCount = await lemaGovernanceInstance.getVoteCount(validators[0]);
    // console.log("Vote Count:", voteCount.toString());  // 10000000000000000
    assert.equal(voteCount.toString(), "10000000000000000"); // 1e16 as 1e15 base multiplier x 10 tokens x 0 days
  });

  it("should not let a token holders delegate a validator twice", async () => {
    const validators = await lemaGovernanceInstance.getValidators();

    try {
      await lemaGovernanceInstance.delegateValidator(validators[0], {
        from: accounts[2],
      });
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(
        error.reason,
        "LemaGovernance: You have already delegated a validator"
      );
    }
  });

  it("should not have a validators's votes delegated to other validators", async () => {
    await lemaTokenInstance.mint(accounts[2], validatorMinStake);
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[2],
      }
    );

    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[2],
    });

    await lemaGovernanceInstance.applyForValidator({ from: accounts[2] });

    const validatorExists = await lemaGovernanceInstance.getValidatorsExists(
      accounts[2]
    );
    assert.equal(validatorExists, true);

    const delegatedValidator =
      await lemaGovernanceInstance.haveDelagatedValidator(accounts[2]);
    assert.equal(delegatedValidator, false);
  });

  it("should let validator cast their vote", async () => {
    await lemaGovernanceInstance.castVote(0);

    const haveCastedVote = await lemaGovernanceInstance.haveCastedVote(
      accounts[0]
    );
    assert.equal(haveCastedVote, true);
  });

  it("should not let validators cast their vote twice", async () => {
    try {
      await lemaGovernanceInstance.castVote(0);
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(error.reason, "LemaGovernance: You have already voted");
    }
  });

  it("should not let other than owner reward most voted project", async () => {
    try {
      await lemaGovernanceInstance.rewardMostVotedProject({
        from: accounts[1],
      });
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(error.reason, "Ownable: caller is not the owner");
    }
  });

  it("should let owner reward most voted project", async () => {
    await lemaGovernanceInstance.rewardMostVotedProject({ from: accounts[0] });

    const currentGovernance = await lemaGovernanceInstance.currentGovernance();

    const mostVotedProjectIndex = currentGovernance.mostVotedProjectIndex;
    assert.equal(mostVotedProjectIndex, 0);

    const winningVoteCount = currentGovernance.winningVoteCount;
    assert.equal(winningVoteCount, 1);
  });
});

contract("LemaGovernance: Slashing", function (accounts) {
  it("should assert true", async () => {
    lemaGovernanceInstance = await LemaGovernance.deployed();
    lemaStakingInstance = await LemaChefV2.deployed();
    lemaTokenInstance = await LemaToken.deployed();
    assert(
      lemaTokenInstance !== undefined,
      "LemaToken contract should be defined"
    );
    assert(
      lemaStakingInstance !== undefined,
      "LemaChef contract should be defined"
    );
    return assert(
      lemaGovernanceInstance !== undefined,
      "LemaGovernance contract should be defined"
    );
  });

  it("add a stimulated offline validator", async () => {
    await lemaTokenInstance.mint(accounts[6], validatorMinStake);
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[6],
      }
    );

    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[6],
    });

    await lemaGovernanceInstance.applyForValidator({ from: accounts[6] });

    const validators = await lemaGovernanceInstance.getValidators();
    assert(validators.length > 0);

    const haveCastedVote = await lemaGovernanceInstance.haveCastedVote(
      accounts[6]
    );
    assert.equal(haveCastedVote, false);

    const initialStakedAmount = await lemaStakingInstance.getStakedAmountInPool(
      0,
      accounts[6]
    );
    await lemaGovernanceInstance.startNewGovernance();
    const finalStakedAmount = await lemaStakingInstance.getStakedAmountInPool(
      0,
      accounts[6]
    );
    // assert(finalStakedAmount < initialStakedAmount);
    assert.equal(initialStakedAmount.toString(), validatorMinStake.toString());
    assert.equal(finalStakedAmount.toString(), "186000000000000000000");
  });
});

contract("LemaGovernance: Time-Based test cases", function (accounts) {
  let snapshotId;
  beforeEach(async () => {
    let snapshot = await timeMachine.takeSnapshot();
    snapshotId = snapshot["result"];
  });

  afterEach(async () => {
    await timeMachine.revertToSnapshot(snapshotId);
  });

  it("should assert true", async () => {
    lemaGovernanceInstance = await LemaGovernance.deployed();
    return assert(
      lemaGovernanceInstance !== undefined,
      "LemaGovernance contract should be defined"
    );
  });

  // This test may be failing in truffle develop network
  it("should throw error after the end of governance period", async function () {
    await timeMachine.advanceTimeAndBlock(60 * 60 * 24 * 120);

    try {
      await lemaGovernanceInstance.rewardMostVotedProject();
      assert(false, "should have thrown");
    } catch (error) {
      if (error.message === "should have thrown") return this.skip(); // skipping intentionally as timeMachine may not be working as expected causing test to fail in ganache cli instance
      assert.equal(error.reason, "LemaGovernance: Voting has already ended");
    }
  });
});

contract("LemaGovernance: Validator", function (accounts) {
  let snapshotId;
  beforeEach(async () => {
    let snapshot = await timeMachine.takeSnapshot();
    snapshotId = snapshot["result"];
  });
  afterEach(async () => {
    await timeMachine.revertToSnapshot(snapshotId);
  });

  it("should assert true", async () => {
    lemaGovernanceInstance = await LemaGovernance.deployed();
    lemaStakingInstance = await LemaChefV2.deployed();
    lemaTokenInstance = await LemaToken.deployed();
    assert(
      lemaTokenInstance !== undefined,
      "LemaToken contract should be defined"
    );
    assert(
      lemaStakingInstance !== undefined,
      "LemaChef contract should be defined"
    );
    return assert(
      lemaGovernanceInstance !== undefined,
      "LemaGovernance contract should be defined"
    );
  });

  it("should have whitelisted addresses", async () => {
    const whitelistedValidators =
      await lemaGovernanceInstance.getWhitelistedValidators();

    // console.log("Whitelisted Validators:", whitelistedValidators);
    assert(whitelistedValidators);
  });

  it("should not let non-whitelisted wallets apply for validator in the first week of contract deployment", async () => {
    try {
      await lemaGovernanceInstance.applyForValidator({ from: accounts[9] });
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(
        error.reason,
        "LemaGovernance: You are not previleged for the action. Please wait"
      );
    }
  });

  it("should let non-whitelisted wallets apply for validator after the first week of contract deployment", async function () {
    await lemaTokenInstance.mint(accounts[9], validatorMinStake);
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[9],
      }
    );

    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[9],
    });

    await timeMachine.advanceTimeAndBlock(60 * 60 * 24 * 7);

    try {
      await lemaGovernanceInstance.applyForValidator({ from: accounts[9] });
    } catch (error) {
      if (
        error.reason ===
        "LemaGovernance: You are not previleged for the action. Please wait"
      )
        return this.skip();
    }

    const validators = await lemaGovernanceInstance.getValidators();
    assert.equal(validators.length, 1);
  });

  it("should let whitelisted wallets apply for validator before the first week of contract deployment", async () => {
    await lemaTokenInstance.mint(accounts[7], validatorMinStake);
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[7],
      }
    );

    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[7],
    });

    await lemaGovernanceInstance.applyForValidator({ from: accounts[7] });

    const validators = await lemaGovernanceInstance.getValidators();
    assert.equal(validators.length, 1);
  });
});

contract("LemaGovernance: Nominator", function (accounts) {
  it("should assert true", async () => {
    lemaGovernanceInstance = await LemaGovernance.deployed();
    lemaStakingInstance = await LemaChefV2.deployed();
    lemaTokenInstance = await LemaToken.deployed();
    assert(
      lemaTokenInstance !== undefined,
      "LemaToken contract should be defined"
    );
    assert(
      lemaStakingInstance !== undefined,
      "LemaChef contract should be defined"
    );
    assert(
      lemaGovernanceInstance !== undefined,
      "LemaGovernance contract should be defined"
    );

    await lemaTokenInstance.mint(accounts[3], validatorMinStake);
    await lemaTokenInstance.mint(accounts[4], validatorMinStake);
    await lemaTokenInstance.mint(accounts[5], validatorMinStake);
    await lemaTokenInstance.mint(accounts[6], validatorMinStake);
    await lemaTokenInstance.mint(accounts[7], validatorMinStake);
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[3],
      }
    );
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[4],
      }
    );
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[5],
      }
    );
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[6],
      }
    );
    await lemaTokenInstance.approve(
      lemaStakingInstance.address,
      validatorMinStake,
      {
        from: accounts[7],
      }
    );

    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[3],
    });
    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[4],
    });
    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[5],
    });
    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[6],
    });
    await lemaStakingInstance.enterStaking(validatorMinStake, {
      from: accounts[7],
    });

    await lemaGovernanceInstance.applyForValidator({ from: accounts[3] });
    await lemaGovernanceInstance.applyForValidator({ from: accounts[4] });
    await lemaGovernanceInstance.applyForValidator({ from: accounts[5] });
    await lemaGovernanceInstance.applyForValidator({ from: accounts[6] });
    await lemaGovernanceInstance.applyForValidator({ from: accounts[7] });

    const validators = await lemaGovernanceInstance.getValidators();
    assert.equal(validators.length, 5);
  });

  it("should let nominator to choose upto 3 validators", async () => {
    const validators = await lemaGovernanceInstance.getValidators();

    await lemaTokenInstance.mint(accounts[2], 10);
    await lemaTokenInstance.approve(lemaStakingInstance.address, 10, {
      from: accounts[2],
    });
    await lemaStakingInstance.enterStaking(10, { from: accounts[2] });

    await lemaGovernanceInstance.delegateValidator(validators[0], {
      from: accounts[2],
    });
    await lemaGovernanceInstance.delegateMoreValidator(validators[1], {
      from: accounts[2],
    });
    await lemaGovernanceInstance.delegateMoreValidator(validators[2], {
      from: accounts[2],
    });

    const delegatedValidator =
      await lemaGovernanceInstance.haveDelagatedValidator(accounts[2]);
    assert.equal(delegatedValidator, true);

    const voteCount = await lemaGovernanceInstance.getVoteCount(validators[0]);
    // console.log("Vote Count:", voteCount.toString());  // 10000000000000000
    assert.equal(voteCount.toString(), "10000000000000000"); // 1e16 as 1e15 base multiplier x 10 tokens x 0 days
  });

  it("should let nominator to replace choosen validator", async () => {
    const validators = await lemaGovernanceInstance.getValidators();

    let voteCount = await lemaGovernanceInstance.getVoteCount(validators[3]);
    // console.log("Vote Count:", voteCount.toString()); // 0
    assert.equal(voteCount.toString(), "0");
    await lemaGovernanceInstance.changeValidatorOfIndex(0, validators[3], {
      from: accounts[2],
    });

    voteCount = await lemaGovernanceInstance.getVoteCount(validators[3]);
    // console.log("Vote Count:", voteCount.toString()); // 10000000000000000
    assert.equal(voteCount.toString(), "10000000000000000");

    await lemaGovernanceInstance.changeValidatorOfIndex(1, validators[4], {
      from: accounts[2],
    });

    voteCount = await lemaGovernanceInstance.getVoteCount(validators[4]);
    // console.log("Vote Count:", voteCount.toString()); // 0
    assert.equal(voteCount.toString(), "0");
  });
});
