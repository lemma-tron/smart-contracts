// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

abstract contract LemaVoters {
    address[] private voters;
    mapping(address => bool) private delagatedValidator;
    mapping(address => address) private votedToValidator; // address of the validator voted to

    function getVoters() public view returns (address[] memory) {
        return voters;
    }

    function addVoter(address _voter) internal {
        voters.push(_voter);
    }

    function resetVoters() internal {
        delete voters;
    }

    function haveDelagatedValidator(address _voter) public view returns (bool) {
        return delagatedValidator[_voter];
    }

    function delegateValidator(address validator) public virtual {
        require(
            !delagatedValidator[msg.sender],
            "LemaGovernance: You have already delegated a validator"
        );
        votedToValidator[msg.sender] = validator;
        delagatedValidator[msg.sender] = true;
    }

    function unDelegateValidator() internal {
        require(
            delagatedValidator[msg.sender],
            "LemaGovernance: You have not delegated a validator"
        );
        delete votedToValidator[msg.sender];
        delete delagatedValidator[msg.sender];
    }

    function getVotedToValidator(address _voter) public view returns (address) {
        return votedToValidator[_voter];
    }
}
