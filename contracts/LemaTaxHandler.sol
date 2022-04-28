// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./utils/ExchangePoolProcessor.sol";

contract LemaTaxHandler is Initializable, OwnableUpgradeable, ExchangePoolProcessor {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @dev The set of addresses exempt from tax.
    EnumerableSetUpgradeable.AddressSet private _exempted;

    /// @notice How much tax to collect in basis points. 10,000 basis points is 100%.
    uint256 public taxBasisPoints;

    address public uniswapV2Router;

    /// @notice Emitted when the tax basis points number is updated.
    event TaxBasisPointsUpdated(uint256 oldBasisPoints, uint256 newBasisPoints);

    /// @notice Emitted when an address is added to or removed from the exempted addresses set.
    event TaxExemptionUpdated(address indexed wallet, bool exempted);

    /**
     * @param initialTaxBasisPoints The number of tax basis points to start out with for tax calculations.
     */
    function initialize(
        uint256 initialTaxBasisPoints
    ) public initializer {
        __Ownable_init();
        taxBasisPoints = initialTaxBasisPoints;
        uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    }

    /**
     * @notice Get number of tokens to pay as tax. This method specifically only check for sell-type transfers to
     * designated exchange pool addresses.
     * @dev There is no easy way to differentiate between a user selling tokens and a user adding liquidity to the pool.
     * In both cases tokens are transferred to the pool. This is an unfortunate case where users have to accept being
     * taxed on liquidity additions. To get around this issue, a separate liquidity addition contract can be deployed.
     * This contract can be exempt from taxes if its functionality is verified to only add liquidity.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external view returns (uint256) {
        if (_exempted.contains(benefactor) || _exempted.contains(beneficiary)) {
            return 0;
        }

        // If the transfer is to or from the uniswapV2Router, the tax is capped at 3% of the amount.
        if ((beneficiary == uniswapV2Router || benefactor == uniswapV2Router) && taxBasisPoints > 300) {
            return (amount * 300) / 10000;
        }

        // Transactions between regular users (this includes contracts) aren't taxed.
        if (!_exchangePools.contains(benefactor) && !_exchangePools.contains(beneficiary)) {
            return 0;
        }

        return (amount * taxBasisPoints) / 10000;
    }

    /**
     * @notice Set new number for tax basis points. This number can only ever be lowered.
     * @param newBasisPoints New tax basis points number to set for calculations.
     */
    function setTaxBasisPoints(uint256 newBasisPoints) external onlyOwner {
        require(
            newBasisPoints < taxBasisPoints,
            "LemaTaxHandler:setTaxBasisPoints:HIGHER_VALUE: Basis points can only be lowered."
        );

        uint256 oldBasisPoints = taxBasisPoints;
        taxBasisPoints = newBasisPoints;

        emit TaxBasisPointsUpdated(oldBasisPoints, newBasisPoints);
    }

    /**
     * @notice Add address to set of tax-exempted addresses.
     * @param exemption Address to add to set of tax-exempted addresses.
     */
    function addExemption(address exemption) external onlyOwner {
        if (_exempted.add(exemption)) {
            emit TaxExemptionUpdated(exemption, true);
        }
    }

    /**
     * @notice Remove address from set of tax-exempted addresses.
     * @param exemption Address to remove from set of tax-exempted addresses.
     */
    function removeExemption(address exemption) external onlyOwner {
        if (_exempted.remove(exemption)) {
            emit TaxExemptionUpdated(exemption, false);
        }
    }
}