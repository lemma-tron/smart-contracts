// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

abstract contract LemaVoters {
    mapping(address => bool) public haveDelagatedValidators;
    mapping(address => address) public votedToValidator; // address of the validator voted to

    function getVoters() public view virtual returns (address[] memory);

    function delegateValidator(address validator) public virtual;
}
