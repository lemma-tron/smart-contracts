// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../utils/Pausable.sol";

import "../LemaChefV2.sol";
import "./LemaValidators.sol";
import "./LemaVoters.sol";

// Governance contract of Lemmatrom
contract LemaGovernance is
    Initializable,
    OwnableUpgradeable,
    Pausable,
    LemaValidators,
    LemaVoters
{
    using SafeMathUpgradeable for uint256;

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
        string mediumLink;
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
    LemaChefV2 public lemaChef;

    modifier onlyLemaChef() {
        require(
            msg.sender == address(lemaChef),
            "LemaGovernance: Only LemaChef can perform this action"
        );
        _;
    }

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

    function initialize(
        uint256 _governanceVotingStart,
        uint256 _governanceVotingEnd,
        LemaChefV2 _lemaChef,
        address[] memory _whitelisted
    ) public initializer {
        __Ownable_init();
        __PausableUpgradeable_init();
        __LemaValidators_init(_whitelisted);
        currentGovernance.governanceVotingStart = _governanceVotingStart;
        currentGovernance.governanceVotingEnd = _governanceVotingEnd;
        lemaChef = _lemaChef;
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
        uint256 slashingParameter = getSlashingParameter();
        address[]
            memory offlineValidators = getValidatorsWhoHaveNotCastedVotes();
        address[] memory onlineValidators = getValidatorsWhoHaveCastedVotes();

        lemaChef.slashOfflineValidators(
            slashingParameter,
            offlineValidators,
            onlineValidators
        );
    }

    function evaluateThreeValidatorsNominatedByNominator() internal {
        address[] memory nominators = getVoters();
        uint256 slashingParameter = getSlashingParameter();

        lemaChef.evaluateThreeValidatorsNominatedByNominator(
            slashingParameter,
            nominators
        );
    }

    function vestVotesToDifferentValidator(
        address nominator,
        address previousValidator,
        address newValidator
    ) public onlyLemaChef whenNotPaused {
        _vestVotesToDifferentValidator(
            nominator,
            previousValidator,
            newValidator
        );
    }

    // To be called at the end of a Governance period
    function applySlashing() internal onlyOwner {
        slashOfflineValidators();
        evaluateThreeValidatorsNominatedByNominator();
    }

    function startNewGovernance() external onlyOwner whenNotPaused {
        applySlashing();
        currentGovernance.validators = getValidators();
        currentGovernance.voters = getVoters();
        pastGovernances.push(currentGovernance);
        delete currentGovernance;
        resetVoters();

        currentGovernance.governanceVotingStart = block.timestamp;
        currentGovernance.governanceVotingEnd = block.timestamp + 7776000; // 90 days
    }

    function getPastGovernances() external view returns (Governance[] memory) {
        return pastGovernances;
    }

    function getProjects() external view returns (Project[] memory) {
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
        string memory _discordLink,
        string memory _mediumLink
    ) external runningGovernanceOnly whenNotPaused onlyOwner {
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
        project.mediumLink = _mediumLink;
    }

    function delegateValidator(address validator)
        public
        override
        runningGovernanceOnly
        whenNotPaused
    {
        require(
            getValidatorsExists(validator),
            "LemaGovernance: Validator is not a valid"
        );
        super.delegateValidator(validator);

        uint256 votingPower = lemaChef.getVotingPower(msg.sender);
        LemaVoters.vestVotes(votingPower);
        LemaValidators.vestVotes(validator, votingPower);
    }

    function applyForValidator() public virtual override whenNotPaused {
        if (haveDelagatedValidator(msg.sender)) {
            withdrawVotes(getValidatorsNominatedByNominator(msg.sender)[0]); // using 0 index as votes were accumulated with the first validator among the three returned ones

            unDelegateValidator();
        }
        super.applyForValidator();
        uint256 lemaStaked = lemaChef.getStakedAmountInPool(0, msg.sender);
        require(
            lemaStaked >= getValidatorsMinStake(),
            "Stake not enough to become validator"
        );
    }

    function castVote(uint256 index)
        external
        validValidatorsOnly
        whenNotPaused
    {
        require(
            getValidatorsExists(msg.sender),
            "LemaGovernance: Only validators can cast a vote"
        );
        require(
            !haveCastedVote(msg.sender),
            "LemaGovernance: You have already voted"
        );
        require(
            index < currentGovernance.projects.length,
            "LemaGovernance: Project index out of bounds"
        );
        Project storage project = currentGovernance.projects[index];
        project.validatorVoters.push(msg.sender);
        updateCastedVote(true);
    }

    function rewardMostVotedProject()
        external
        onlyOwner
        runningGovernanceOnly
        whenNotPaused
    {
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

    function leftStakingAsValidator(address _validator)
        external
        onlyLemaChef
        whenNotPaused
    {
        removeFromValidator(_validator);
    }
}
