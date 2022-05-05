const timeMachine = require("ganache-time-traveler");

const LemaGovernance = artifacts.require("LemaGovernance");
const LemaToken = artifacts.require("LemaToken");
const LemaChefV2 = artifacts.require("LemaChefV2");

let lemaGovernanceInstance;
let lemaTokenInstance;
let lemaStakingInstance;

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
    return assert(
      lemaGovernanceInstance !== undefined,
      "LemaGovernance contract should be defined"
    );
  });

  it("should have treasury address", async () => {
    const treasuryAddress = await lemaStakingInstance.treasury();
    return assert(
      treasuryAddress === accounts[7],
      "Treasury address should be defined"
    );
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
    await lemaTokenInstance.mint(accounts[0], 200);
    await lemaTokenInstance.approve(lemaStakingInstance.address, 200);

    await lemaStakingInstance.enterStaking(200);

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
    await lemaTokenInstance.mint(accounts[2], 200);
    await lemaTokenInstance.approve(lemaStakingInstance.address, 200, {
      from: accounts[2],
    });

    await lemaStakingInstance.enterStaking(200, { from: accounts[2] });

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
    await lemaTokenInstance.mint(accounts[6], 200);
    await lemaTokenInstance.approve(lemaStakingInstance.address, 200, {
      from: accounts[6],
    });

    await lemaStakingInstance.enterStaking(200, { from: accounts[6] });

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
    assert.equal(initialStakedAmount.toString(), "200");
    assert.equal(finalStakedAmount.toString(), "186");
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

  // it("should throw error before the start of governance period", async () => {
  //   // await lemaGovernanceInstance.startNewGovernance();
  //   // const { governanceVotingStart, governanceVotingEnd } =
  //   //   await lemaGovernanceInstance.currentGovernance();
  //   // console.log("governanceVotingStart", governanceVotingStart.toString());
  //   // console.log("governanceVotingEnd", governanceVotingEnd.toString());
  //   // console.log(
  //   //   "Governance start timestamp:",
  //   //   new Date(governanceVotingStart.toNumber() * 1000)
  //   // );
  //   // console.log(
  //   //   "Governance end timestamp:",
  //   //   new Date(governanceVotingEnd.toNumber() * 1000)
  //   // );
  //   // console.log(
  //   //   "Trial start timestamp:",
  //   //   new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 30)
  //   // );
  //   // console.log(
  //   //   "Trial end timestamp:",
  //   //   new Date(new Date().getTime() + 1000 * 60 * 60 * 24 * 120)
  //   // );
  //   // // governanceVotingStart 1651536000
  //   // // governanceVotingEnd 1659312000
  //   // // Governance start timestamp: 2022-05-03T00:00:00.000Z
  //   // // Governance end timestamp: 2022-08-01T00:00:00.000Z
  //   // // Trial start timestamp: 2022-04-03T10:29:26.124Z
  //   // // Trial end timestamp: 2022-08-31T10:29:26.124Z
  //   // assert.equal(governanceVotingStart.toString(), "0");

  //   // await timeMachine.advanceBlockAndSetTime(
  //   //   new Date(new Date().getTime() - 1000 * 60 * 60 * 24 * 30).getTime() / 1000
  //   // );

  //   try {
  //     await lemaGovernanceInstance.rewardMostVotedProject();
  //     assert(false, "should have thrown");
  //   } catch (error) {
  //     console.log("Error:", Object.keys(error));
  //     console.log("Message:", error.message);
  //     console.log("Data:", error.data);
  //     console.log("Name:", error.name);
  //     console.log("Reason:", error.reason);
  //     // console.log(Object.values(error.data));
  //     // console.log("hijackedStack:", error.hijackedStack);
  //     // const reason = Object.values(error.data)[0].reason;
  //     // assert.equal(reason, "LemaGovernance: Voitng hasn't started yet");
  //   }
  // });

  it("should throw error after the end of governance period", async () => {
    await timeMachine.advanceTimeAndBlock(60 * 60 * 24 * 120);

    try {
      await lemaGovernanceInstance.rewardMostVotedProject();
      assert(false, "should have thrown");
    } catch (error) {
      const reason = Object.values(error.data)[0].reason;
      assert.equal(reason, "LemaGovernance: Voting has already ended");
    }
  });
});