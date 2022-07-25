// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract LemaValidators is OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private validators;
    uint256 private numberOfValidatorAllowed;
    uint256 private validatorMinStake;
    uint256 private castedVoteCount;
    mapping(address => bool) private castedVote;
    mapping(address => uint256) private voteCount;
    mapping(address => uint256) private votingPower;
    EnumerableSetUpgradeable.AddressSet private blocklisted;
    EnumerableSetUpgradeable.AddressSet private whitelisted;
    uint256 private previlegeForValidatorTill;

    modifier validValidatorsOnly() {
        require(
            validators.contains(msg.sender),
            "LemaGovernance: Only validators can cast a vote"
        );
        _;
    }

    modifier previlegedApplied() {
        require(
            block.timestamp > previlegeForValidatorTill ||
                whitelisted.contains(msg.sender),
            "LemaGovernance: You are not previleged for the action. Please wait"
        );
        _;
    }

    function __LemaValidators_init(address[] memory _whitelisted)
        public
        initializer
    {
        __Ownable_init();
        numberOfValidatorAllowed = 10;
        validatorMinStake = 200000000000000000000;

        for (uint256 i = 0; i < _whitelisted.length; i++) {
            whitelisted.add(_whitelisted[i]);
        }

        previlegeForValidatorTill = block.timestamp + 1 weeks;
    }

    function getValidators() public view returns (address[] memory) {
        return validators.values();
    }

    function getVoteCount(address validator) public view returns (uint256) {
        return voteCount[validator];
    }

    function getNumberOfValidatorAllowed() public view returns (uint256) {
        return numberOfValidatorAllowed;
    }

    function getBlockListedAddresses() public view returns (address[] memory) {
        return blocklisted.values();
    }

    function getWhitelistedValidators()
        external
        view
        returns (address[] memory)
    {
        return whitelisted.values();
    }

    function getValidatorsWhoHaveNotCastedVotes()
        internal
        view
        returns (address[] memory)
    {
        uint256 validatorsLength = validators.length();
        address[] memory offlineValidators = new address[](
            validatorsLength - castedVoteCount
        );
        uint256 numberOfOfflineValidators = 0;
        for (uint256 i = 0; i < validatorsLength; i++) {
            if (!castedVote[validators.at(i)]) {
                offlineValidators[numberOfOfflineValidators] = validators.at(i);
                numberOfOfflineValidators++;
            }
        }
        return offlineValidators;
    }

    function getValidatorsWhoHaveCastedVotes()
        internal
        view
        returns (address[] memory)
    {
        address[] memory onlineValidators = new address[](castedVoteCount);
        uint256 numberOfOnlineValidators = 0;
        for (uint256 i = 0; i < validators.length(); i++) {
            if (castedVote[validators.at(i)]) {
                onlineValidators[numberOfOnlineValidators] = validators.at(i);
                numberOfOnlineValidators++;
            }
        }
        return onlineValidators;
    }

    function getValidatorsExists(address _validator)
        public
        view
        returns (bool)
    {
        return validators.contains(_validator);
    }

    function updateCastedVote(bool _castedVote) internal {
        if (_castedVote && !castedVote[msg.sender]) {
            castedVoteCount++;
        } else if (!_castedVote && castedVote[msg.sender]) {
            castedVoteCount--;
        }
        castedVote[msg.sender] = _castedVote;
    }

    function haveCastedVote(address _validator) public view returns (bool) {
        return castedVote[_validator];
    }

    function getValidatorsMinStake() public view returns (uint256) {
        return validatorMinStake;
    }

    // update validator min stake
    function updateValidatorMinStake(uint256 _validatorMinStake)
        public
        onlyOwner
    {
        validatorMinStake = _validatorMinStake;
    }

    // apply for validator
    function applyForValidator() public virtual previlegedApplied {
        require(
            !blocklisted.contains(msg.sender),
            "LemaGovernance: Blocklisted wallet"
        );
        require(
            validators.length() < numberOfValidatorAllowed,
            "Validators allowed exceeded"
        );
        require(
            !validators.contains(msg.sender),
            "LemaGovernance: You are already a validator"
        );

        validators.add(msg.sender);
    }

    function leaveFromValidator() external {
        require(
            validators.remove(msg.sender),
            "LemaGovernance: Only validators can leave from validator"
        );
        require(
            validators.length() > 1,
            "LemaGovernance: At least one validator must be present"
        );

        removeFromValidator(msg.sender);
    }

    // remove for validator
    function removeFromValidatorByIndex(uint256 index) internal {
        uint256 validatorsLength = validators.length();
        require(
            index < validatorsLength,
            "LemaGovernance: Validator index out of bounds"
        );
        validators.remove(validators.at(index));
    }

    function getValidatorIndex(address _validator)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < validators.length(); i++) {
            if (validators.at(i) == _validator) {
                return i;
            }
        }
        return 0;
    }

    function removeFromValidator(address _validator) internal {
        removeFromValidatorByIndex(getValidatorIndex(_validator));
    }

    // update numberOfValidatorAllowed
    function updateNumberOfValidatorAllowed(uint256 _numberOfValidatorAllowed)
        external
        onlyOwner
    {
        numberOfValidatorAllowed = _numberOfValidatorAllowed;
    }

    function addToBlocklist(address _user) external onlyOwner {
        blocklisted.add(_user);
    }

    function removeFromBlocklist(address _user) external onlyOwner {
        blocklisted.remove(_user);
    }

    function vestVotes(address validator, uint256 _votingPower) internal {
        voteCount[validator] += _votingPower;
        votingPower[msg.sender] = _votingPower;
    }

    function withdrawVotes(address validator) internal {
        voteCount[validator] -= votingPower[msg.sender];
    }

    function _vestVotesToDifferentValidator(
        address nominator,
        address previousValidator,
        address newValidator
    ) internal {
        voteCount[previousValidator] -= votingPower[nominator];
        voteCount[newValidator] += votingPower[nominator];
    }
}
