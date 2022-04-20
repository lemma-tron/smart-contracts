// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "./LemaChefV2.sol";

// Governance contract of Lemmatrom
contract LemaGovernance is LemaChefV2 {
    using SafeMath for uint256;

    // Info of each project.
    struct Project {
        string name;
        string shortDescription;
        string tokenSymbol;
        address tokenContract;
        string preferredDEXPlatform;
        int256 totalLiquidity;
        string projectWebsite;
        string twitterLink;
        string telegramLink;
        string discordLink;
        bool approved;
        address[] validatorVoters;
    }

    // Info of each governance.
    struct Governance {
        uint256 governanceVotingStart;
        uint256 governanceVotingEnd;
        address[] validators;
        address[] voters;
        Project[] projects;
        uint256 mostVotedProjectIndex;
        uint256 winningVoteCount;
    }

    Governance[] public pastGovernances;
    Governance public currentGovernance;

    modifier runningGovernanceOnly() {
        require(
            currentGovernance.governanceVotingEnd == 0 ||
                block.timestamp < currentGovernance.governanceVotingEnd,
            "LemaGovernance: Voting has already ended"
        );
        require(
            block.timestamp >= currentGovernance.governanceVotingStart &&
                currentGovernance.governanceVotingStart != 0,
            "LemaGovernance: Voitng hasn't started yet"
        );
        _;
    }

    constructor(
        uint256 _governanceVotingStart,
        uint256 _governanceVotingEnd,
        LemaToken _lemaToken,
        address _treasury,
        uint256 _startBlock
    ) public LemaChefV2(_lemaToken, _treasury, _startBlock) {
        currentGovernance.governanceVotingStart = _governanceVotingStart;
        currentGovernance.governanceVotingEnd = _governanceVotingEnd;
    }

    function getSlashingParameter() internal view returns (uint256) {
        address[] memory currentValidators = getValidators();
        address[]
            memory offlineValidators = getValidatorsWhoHaveNotCastedVotes();

        uint256 x = offlineValidators.length.mul(100);
        uint256 n = currentValidators.length.mul(100);
        uint256 slashingParameter = x.sub(n.div(50)).mul(4).div(n.div(100));

        if (slashingParameter > 100) {
            slashingParameter = 100;
        }

        return slashingParameter;
    }

    function slashOfflineValidators() internal {
        address[]
            memory offlineValidators = getValidatorsWhoHaveNotCastedVotes();
        uint256 slashingParameter = getSlashingParameter();

        if (slashingParameter > 0) {
            for (uint256 i = 0; i < offlineValidators.length; i++) {
                address user = offlineValidators[i];
                uint256 userStake = getStakedAmountInPool(0, user);
                uint256 toBeSlashedAmount = userStake
                    .mul(7)
                    .mul(slashingParameter)
                    .div(10000);

                safeLEMATransfer(treasury, toBeSlashedAmount);

                UserInfo storage userData = userInfo[0][user];
                userData.amount = userData.amount.sub(toBeSlashedAmount);
            }
        }

        // Reducing multiplier
        for (uint256 i = 0; i < offlineValidators.length; i++) {
            address user = offlineValidators[i];
            UserInfo storage userData = userInfo[0][user];
            userData.multiplier = 5000;
        }

        // Recovering multiplier
        address[] memory onlineValidators = getValidatorsWhoHaveCastedVotes();
        for (uint256 i = 0; i < onlineValidators.length; i++) {
            address user = onlineValidators[i];
            UserInfo storage userData = userInfo[0][user];
            userData.multiplier = 10000;
        }
    }

    function evaluateThreeValidatorsNominatedByNominator() internal {
        address[] memory nominators = getVoters();

        uint256 slashingParameter = getSlashingParameter();

        for (uint256 i = 0; i < nominators.length; i++) {
            address nominator = nominators[i];
            UserInfo storage userData = userInfo[0][nominator];
            address[3]
                memory validatorsNominatedByNominator = getValidatorsNominatedByNominator(
                    nominator
                );

            for (uint256 j = 0; j < 3; j++) {
                address validator = validatorsNominatedByNominator[j];
                if (haveCastedVote(validator)) {
                    userData.multiplier = 10000;

                    if (j != 0) {
                        vestVotesToDifferentValidator(
                            nominator,
                            validatorsNominatedByNominator[0],
                            validator
                        );
                    }

                    return;
                }
            }
            userData.multiplier = 5000;

            if (slashingParameter > 0) {
                uint256 userStake = getStakedAmountInPool(0, nominator);
                uint256 toBeSlashedAmount = userStake
                    .mul(7)
                    .mul(slashingParameter)
                    .div(10000);

                safeLEMATransfer(treasury, toBeSlashedAmount);

                userData.amount = userData.amount.sub(toBeSlashedAmount);
            }
        }
    }

    function startNewGovernance() public onlyOwner {
        slashOfflineValidators();
        evaluateThreeValidatorsNominatedByNominator();
        currentGovernance.validators = getValidators();
        currentGovernance.voters = getVoters();
        pastGovernances.push(currentGovernance);
        delete currentGovernance;
        resetVoters();

        currentGovernance.governanceVotingStart = block.timestamp;
        currentGovernance.governanceVotingEnd = block.timestamp + 7776000; // 90 days
    }

    function getPastGovernances() public view returns (Governance[] memory) {
        return pastGovernances;
    }

    function getProjects() public view returns (Project[] memory) {
        return currentGovernance.projects;
    }

    function addProject(
        string memory _name,
        string memory _description,
        string memory _tokenSymbol,
        address _tokenContract,
        string memory _preferredDEXPlatform,
        int256 _totalLiquidity,
        string memory _projectWebsite,
        string memory _twitterLink,
        string memory _telegramLink,
        string memory _discordLink
    ) public runningGovernanceOnly {
        uint256 index = currentGovernance.projects.length;
        currentGovernance.projects.push();
        Project storage project = currentGovernance.projects[index];
        project.name = _name;
        project.shortDescription = _description;
        project.tokenSymbol = _tokenSymbol;
        project.tokenContract = _tokenContract;
        project.preferredDEXPlatform = _preferredDEXPlatform;
        project.totalLiquidity = _totalLiquidity;
        project.projectWebsite = _projectWebsite;
        project.twitterLink = _twitterLink;
        project.telegramLink = _telegramLink;
        project.discordLink = _discordLink;
    }

    function approveProject(uint256 index)
        public
        runningGovernanceOnly
        onlyOwner
    {
        require(
            index < currentGovernance.projects.length,
            "Project index out of bounds"
        );
        Project storage project = currentGovernance.projects[index];
        project.approved = true;
    }

    function delegateValidator(address validator)
        public
        override
        runningGovernanceOnly
    {
        super.delegateValidator(validator);
    }

    function applyForValidator() public virtual override {
        if (haveDelagatedValidator(msg.sender)) {
            withdrawVotes(getValidatorsNominatedByNominator(msg.sender)[0]); // using 0 index as votes were accumulated with the first validator among the three returned ones

            unDelegateValidator();

            for (
                uint256 index = 0;
                index < currentGovernance.validators.length;
                index++
            ) {
                if (currentGovernance.validators[index] == msg.sender) {
                    currentGovernance.validators[index] = currentGovernance
                        .validators[currentGovernance.validators.length - 1];
                    currentGovernance.validators.pop();
                    break;
                }
            }
        }
        super.applyForValidator();
    }

    function castVote(uint256 index) public validValidatorsOnly {
        require(
            !haveCastedVote(msg.sender),
            "LemaGovernance: You have already voted"
        );
        require(
            index < currentGovernance.projects.length,
            "LemaGovernance: Project index out of bounds"
        );
        Project storage project = currentGovernance.projects[index];
        require(
            project.approved,
            "LemaGovernance: Project is not approved yet"
        );
        project.validatorVoters.push(msg.sender);
        updateCastedVote(true);
    }

    function rewardMostVotedProject() public onlyOwner runningGovernanceOnly {
        uint256 mostVotes = 0;
        uint256 mostVotedIndex = 0;
        for (
            uint256 index = 0;
            index < currentGovernance.projects.length;
            index++
        ) {
            Project storage project = currentGovernance.projects[index];
            if (project.validatorVoters.length > mostVotes) {
                mostVotes = project.validatorVoters.length;
                mostVotedIndex = index;
            }
        }
        currentGovernance.mostVotedProjectIndex = mostVotedIndex;
        currentGovernance.winningVoteCount = mostVotes;
    }
}
