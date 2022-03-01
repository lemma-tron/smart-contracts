const LemaGovernance = artifacts.require("LemaGovernance");
const LemaToken = artifacts.require("LemaToken");

let lemaGovernanceInstance;

contract("LemaGovernance", function (accounts) {
  it("should assert true", async () => {
    lemaGovernanceInstance = await LemaGovernance.deployed();
    return assert(
      lemaGovernanceInstance !== undefined,
      "LemaGovernance contract should be defined"
    );
  });

  it("should have treasury address", async () => {
    const treasuryAddress = await lemaGovernanceInstance.treasury();
    return assert(
      treasuryAddress === accounts[7],
      "Treasury address should be defined"
    );
  });

  // it("should let new governance to be started", async () => {
  //   await lemaGovernanceInstance.startNewGovernance();

  //   const pastGovernances = await lemaGovernanceInstance.getPastGovernances();
  //   return assert(
  //     pastGovernances.length === 1,
  //     "There should be one governance"
  //   );
  // });

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
      await lemaGovernanceInstance.applyForValidator(accounts[1]);
      assert(false, "should have thrown");
    } catch (error) {
      assert.equal(error.reason, "Stake not enough to become validator");
    }
  });

  it("should accept validators", async () => {
    const lemaTokenInstance = await LemaToken.deployed();

    await lemaTokenInstance.mint(accounts[0], 200);
    await lemaTokenInstance.approve(LemaGovernance.address, 200);

    await lemaGovernanceInstance.enterStaking(200);

    await lemaGovernanceInstance.applyForValidator(accounts[0]);

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
      assert.equal(error.reason, "LemaGovernance: Only token holders can vote");
    }
  });

  it("should let token holders delegate a validator", async () => {
    const lemaTokenInstance = await LemaToken.deployed();

    await lemaTokenInstance.mint(accounts[2], 10);

    const validators = await lemaGovernanceInstance.getValidators();

    await lemaGovernanceInstance.delegateValidator(validators[0], {
      from: accounts[2],
    });

    const delegatedValidator =
      await lemaGovernanceInstance.haveDelagatedValidators(accounts[2]);
    assert.equal(delegatedValidator, true);
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

  it("should let validator cast their vote", async () => {
    await lemaGovernanceInstance.castVote(0);

    const haveCastedVote = await lemaGovernanceInstance.haveCastedVotes(
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
