const LemaGovernance = artifacts.require("LemaGovernance");
const LemaToken = artifacts.require("LemaToken");

let lemaGovernanceInstance;
let lemaTokenInstance;

contract.skip("LemaGovernance", function (accounts) {
  it("should assert true", async () => {
    lemaGovernanceInstance = await LemaGovernance.deployed();
    lemaTokenInstance = await LemaToken.deployed();
    assert(lemaTokenInstance !== undefined, "LemaToken contract should be defined");
    return assert(lemaGovernanceInstance !== undefined, "LemaGovernance contract should be defined");
  });

  it("should have treasury address", async () => {
    const treasuryAddress = await lemaGovernanceInstance.treasury();
    return assert(treasuryAddress === accounts[7], "Treasury address should be defined");
  });

  it("should not have any projects", async () => {
    const projects = await lemaGovernanceInstance.getProjects();
    return assert(projects.length === 0, "There should not be any project");
  });

  it("showld accept new projects", async () => {
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
    await lemaTokenInstance.approve(LemaGovernance.address, 200);

    await lemaGovernanceInstance.enterStaking(200);

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
    await lemaTokenInstance.approve(LemaGovernance.address, 10, {
      from: accounts[2],
    });
    await lemaGovernanceInstance.enterStaking(10, { from: accounts[2] });

    const validators = await lemaGovernanceInstance.getValidators();

    await lemaGovernanceInstance.delegateValidator(validators[0], {
      from: accounts[2],
    });

    const delegatedValidator = await lemaGovernanceInstance.haveDelagatedValidator(accounts[2]);
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
      assert.equal(error.reason, "LemaGovernance: You have already delegated a validator");
    }
  });

  it("should not have a validators's votes delegated to other validators", async () => {
    await lemaTokenInstance.mint(accounts[2], 200);
    await lemaTokenInstance.approve(LemaGovernance.address, 200, {
      from: accounts[2],
    });

    await lemaGovernanceInstance.enterStaking(200, { from: accounts[2] });

    await lemaGovernanceInstance.applyForValidator({ from: accounts[2] });

    const validatorExists = await lemaGovernanceInstance.getValidatorsExists(accounts[2]);
    assert.equal(validatorExists, true);

    const delegatedValidator = await lemaGovernanceInstance.haveDelagatedValidator(accounts[2]);
    assert.equal(delegatedValidator, false);
  });

  it("should let validator cast their vote", async () => {
    await lemaGovernanceInstance.castVote(0);

    const haveCastedVote = await lemaGovernanceInstance.haveCastedVote(accounts[0]);
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

contract.skip("LemaGovernance: Slashing", function (accounts) {
  it("should assert true", async () => {
    lemaGovernanceInstance = await LemaGovernance.deployed();
    lemaTokenInstance = await LemaToken.deployed();
    assert(lemaTokenInstance !== undefined, "LemaToken contract should be defined");
    return assert(lemaGovernanceInstance !== undefined, "LemaGovernance contract should be defined");
  });

  it("add a stimulated offline validator", async () => {
    await lemaTokenInstance.mint(accounts[6], 200);
    await lemaTokenInstance.approve(LemaGovernance.address, 200, { from: accounts[6] });

    await lemaGovernanceInstance.enterStaking(200, { from: accounts[6] });

    await lemaGovernanceInstance.applyForValidator({ from: accounts[6] });

    const validators = await lemaGovernanceInstance.getValidators();
    assert(validators.length > 0);

    const haveCastedVote = await lemaGovernanceInstance.haveCastedVote(accounts[6]);
    assert.equal(haveCastedVote, false);

    const initialStakedAmount = await lemaGovernanceInstance.getStakedAmountInPool(0, accounts[6]);
    await lemaGovernanceInstance.startNewGovernance();
    const finalStakedAmount = await lemaGovernanceInstance.getStakedAmountInPool(0, accounts[6]);
    // assert(finalStakedAmount < initialStakedAmount);
    assert.equal(initialStakedAmount.toString(), "200");
    assert.equal(finalStakedAmount.toString(), "186");
  });
});
