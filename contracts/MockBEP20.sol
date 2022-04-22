// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MockBEP20 is ERC20Upgradeable {
    address private owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory name,
        string memory symbol,
        uint256 supply
    ) public initializer {
        __ERC20_init(name, symbol);
        _mint(msg.sender, supply);
        owner = msg.sender;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}
