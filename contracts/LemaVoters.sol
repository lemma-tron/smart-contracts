// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

abstract contract LemaVoters {
    address[] public voters;
    mapping(address => bool) public haveDelagatedValidators;
    mapping(address => address) public votedToValidator; // address of the validator voted to

    function getVoters() public view returns (address[] memory) {
        return voters;
    }

    function addVoter(address _voter) internal {
        voters.push(_voter);
    }

    function resetVoters() internal {
        delete voters;
    }

    function delegateValidator(address validator) public virtual {
        require(
            !haveDelagatedValidators[msg.sender],
            "LemaGovernance: You have already delegated a validator"
        );
        votedToValidator[msg.sender] = validator;
        haveDelagatedValidators[msg.sender] = true;
    }
}
