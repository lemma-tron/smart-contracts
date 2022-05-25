// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LemaToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";

/**
 * @title LemaToken
 * @notice This is Lemmatron Governance Token.
 */
contract LemaTokenV2 is LemaToken, ERC20SnapshotUpgradeable {
    function snapshot() external onlyOwner {
        _snapshot();
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override(ERC20SnapshotUpgradeable, ERC20Upgradeable) {
        ERC20SnapshotUpgradeable._beforeTokenTransfer(_from, _to, _amount);
        ERC20Upgradeable._beforeTokenTransfer(_from, _to, _amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, LemaToken) whenNotPaused {
        LemaToken._transfer(from, to, amount);
        ERC20Upgradeable._transfer(from, to, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override(ERC20Upgradeable, LemaToken)
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        override(ERC20Upgradeable, LemaToken)
        whenNotPaused
        returns (bool)
    {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);
        return true;
    }
}
