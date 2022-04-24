// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract MockBEP20 is Initializable, ERC20Upgradeable {
    address private owner;

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
