// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./LemaChefV2.sol";
import "./LemaTokenVesting.sol";

// Governance contract of Lemmatrom
contract LemaGovernance is LemaChefV2 {
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

    LemaTokenVesting public lemaTokenVesting;

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
        LemaTokenVesting _lemaTokenVesting,
        LemaToken _lemaToken,
        address _treasury,
        uint256 _startBlock
    ) public LemaChefV2(_lemaToken, _treasury, _startBlock) {
        currentGovernance.governanceVotingStart = _governanceVotingStart;
        currentGovernance.governanceVotingEnd = _governanceVotingEnd;
        lemaTokenVesting = _lemaTokenVesting;
    }

    function startNewGovernance() public onlyOwner {
        // require(
        //     currentGovernance.governanceVotingEnd <= block.timestamp &&
        //         currentGovernance.governanceVotingEnd != 0,
        //     "Governance voting hasn't ended yet"
        // );

        currentGovernance.validators = listOfValidators();
        pastGovernances.push(currentGovernance);
        delete currentGovernance;

        currentGovernance.governanceVotingStart = block.timestamp;
        currentGovernance.governanceVotingEnd = block.timestamp + 7776000; // 90 days
    }

    function getPastGovernances() public view returns (Governance[] memory) {
        return pastGovernances;
    }

    function getProjects() public view returns (Project[] memory) {
        return currentGovernance.projects;
    }

    function getVoters()
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        return currentGovernance.voters;
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
        virtual
        override
        runningGovernanceOnly
    {
        super.delegateValidator(validator);
        currentGovernance.voters.push(msg.sender);
    }

    function applyForValidator() public virtual override {
        if (haveDelagatedValidators[msg.sender]) {
            voteCount[votedToValidator[msg.sender]] -= 1;

            delete votedToValidator[msg.sender];
            delete haveDelagatedValidators[msg.sender];

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

    function castVote(uint256 index)
        public
        virtual
        override
        validValidatorsOnly
    {
        require(
            !haveCastedVotes[msg.sender],
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
        haveCastedVotes[msg.sender] = true;
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
