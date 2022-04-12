// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

abstract contract LemaValidators is Ownable {
    address[] private validators;
    mapping(address => bool) private validatorExists;
    uint256 private numberOfValidatorAllowed = 10;
    uint256 private validatorMinStake = 200;
    mapping(address => bool) private castedVote;
    mapping(address => uint256) private voteCount;
    mapping(address => uint256) private votingPower;
    mapping(address => bool) private blocklisted;

    modifier validValidatorsOnly() {
        require(
            validatorExists[msg.sender],
            "LemaGovernance: Only validators can cast a vote"
        );
        _;
    }

    function getValidators() public view returns (address[] memory) {
        return validators;
    }

    function getVoteCount(address validator) public view returns (uint256) {
        return voteCount[validator];
    }

    function getValidatorsWhoHaveNotCastedVotes()
        internal
        view
        returns (address[] memory)
    {
        address[] memory offlineValidators = new address[](0);
        uint256 numberOfOfflineValidators = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            if (!castedVote[validators[i]]) {
                offlineValidators[numberOfOfflineValidators] = validators[i];
                numberOfOfflineValidators++;
            }
        }
        return offlineValidators;
    }

    function getValidatorsExists(address _validator)
        public
        view
        returns (bool)
    {
        return validatorExists[_validator];
    }

    function updateCastedVote(bool _castedVote) internal {
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
    function applyForValidator() public virtual {
        require(!blocklisted[msg.sender], "LemaGovernance: Blocklisted wallet");
        require(
            validators.length < numberOfValidatorAllowed,
            "Validators allowed exceeded"
        );

        validatorExists[msg.sender] = true;
        validators.push(msg.sender);
    }

    // remove for validator
    function removeFromValidatorByIndex(uint256 index) public onlyOwner {
        require(
            index < validators.length,
            "LemaGovernance: Validator index out of bounds"
        );
        validatorExists[validators[index]] = false;
        validators[index] = validators[validators.length - 1];
        validators.pop();
    }

    function getValidatorIndex(address _validator)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == _validator) {
                return i;
            }
        }
        return 0;
    }

    function removeFromValidator(address _validator) public {
        removeFromValidatorByIndex(getValidatorIndex(_validator));
    }

    // update numberOfValidatorAllowed
    function updateNumberOfValidatorAllowed(uint256 _numberOfValidatorAllowed)
        public
        onlyOwner
    {
        numberOfValidatorAllowed = _numberOfValidatorAllowed;
    }

    function addToBlocklist(address _user) public {
        blocklisted[_user] = true;
    }

    function removeFromBlocklist(address _user) public {
        blocklisted[_user] = false;
    }

    function vestVotes(address validator, uint256 _votingPower) internal {
        voteCount[validator] += _votingPower;
        votingPower[msg.sender] = _votingPower;
    }

    function withdrawVotes(address validator) internal {
        voteCount[validator] -= votingPower[msg.sender];
    }

    // function delegateValidator(address validator) public virtual {
    //     voteCount[validator] += 1;
    // }
}
