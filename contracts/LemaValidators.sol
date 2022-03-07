// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

abstract contract LemaValidators is Ownable {
    address[] public validators;
    mapping(address => bool) public validatorExists;
    uint256 public numberOfValidators = 0;
    uint256 public numberOfValidatorAllowed = 10;
    uint256 public validatorMinStake = 200;
    mapping(address => bool) public haveCastedVotes;
    mapping(address => uint256) public voteCount;
    mapping(address => bool) public blocklisted;

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

    function castVote(uint256 index) public virtual;

    // get list of validators
    function listOfValidators() public view returns (address[] memory) {
        address[] memory validValidators = new address[](numberOfValidators);
        uint256 counter = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            address user = validators[i];
            if (validatorExists[user]) {
                validValidators[counter++] = user;
            }
        }
        return validValidators;
    }

    // update validator min stake
    function updateValidatorMinStake(uint256 _validatorMinStake)
        public
        onlyOwner
    {
        validatorMinStake = _validatorMinStake;
    }

    // apply for validator
    function applyForValidator() public virtual;

    // remove for validator
    function removeFromValidator(address _user) public {
        require(validatorExists[_user], "Validator does not exist");
        validatorExists[_user] = false;
        numberOfValidators -= 1;
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
}
