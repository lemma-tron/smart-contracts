// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./LemaChef.sol";
import "./LemaTokenVesting.sol";

// Governance contract of Lemmatrom
contract LemaGovernance is LemaChef {
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

    // uint256 public minimumTokensRequiredToBeValidator;	// validatorMinStake
    // address[] public validators;
    // mapping(address => bool) public validValidators;	// validatorExists
    mapping(address => bool) public haveCastedVotes;
    mapping(address => bool) public haveDelagatedValidators;

    mapping(address => address[]) public votedToValidators;

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

    modifier validVotersOnly() {
        require(
            lemaToken.balanceOf(msg.sender) > 0,
            "LemaGovernance: Only token holders can vote"
        );
        _;
    }

    modifier validValidatorsOnly() {
        require(
            validatorExists[msg.sender],
            "LemaGovernance: Only validators can cast a vote"
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
    ) public LemaChef(_lemaToken, _treasury, _startBlock) {
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

    function getVoters() public view returns (address[] memory) {
        return currentGovernance.voters;
    }

    function getValidators() public view returns (address[] memory) {
        return listOfValidators();
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
        runningGovernanceOnly
        validVotersOnly
    {
        require(
            !haveDelagatedValidators[msg.sender],
            "LemaGovernance: You have already delegated a validator"
        );
        require(
            validatorExists[validator],
            "LemaGovernance: Validator is not a valid"
        );

        votedToValidators[validator].push(msg.sender);
        haveDelagatedValidators[msg.sender] = true;
        currentGovernance.voters.push(msg.sender);
    }

    function castVote(uint256 index) public validValidatorsOnly {
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
