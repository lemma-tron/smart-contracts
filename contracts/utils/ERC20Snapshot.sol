// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ERC20Snapshot is ERC20SnapshotUpgradeable, OwnableUpgradeable {
    function __ERC20SnapshotUpgradeable_init() internal onlyInitializing {
        __Ownable_init();
        __ERC20Snapshot_init_unchained();
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }
}
