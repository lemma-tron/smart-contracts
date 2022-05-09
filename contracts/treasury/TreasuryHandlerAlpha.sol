// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../utils/ExchangePoolProcessor.sol";
import "../utils/LenientReentrancyGuard.sol";
import "./ITreasuryHandler.sol";

/**
 * @title Treasury handler alpha contract
 * @dev Sells tokens that have accumulated through taxes and sends the resulting BUSD to the treasury. If
 * `taxBasisPoints` has been set to a non-zero value, then that percentage will instead be collected at the designated
 * treasury address.
 */
contract TreasuryHandlerAlpha is
    Initializable,
    OwnableUpgradeable,
    ITreasuryHandler,
    LenientReentrancyGuard,
    ExchangePoolProcessor
{
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @dev The set of addresses exempt from tax.
    EnumerableSetUpgradeable.AddressSet private _exempted;

    /// @notice The treasury address.
    address public treasury;

    /// @notice The BUSD token address.
    IERC20Upgradeable public busdToken;
    /// @notice The token that accumulates through taxes. This will be sold for BUSD.
    IERC20Upgradeable public token;

    /// @notice How much tax to collect in basis points. 10,000 basis points is 100%.
    uint256 public taxBasisPoints;

    /// @notice The Uniswap router that handles the sell and liquidity operations.
    IUniswapV2Router02 public router;

    /// @notice Emitted when the basis points value of tokens to collect as tax is updated.
    event TaxBasisPointsUpdated(
        uint256 oldBasisPoints,
        uint256 newBasisPoints
    );

    /// @notice Emitted when the treasury address is updated.
    event TreasuryAddressUpdated(
        address oldTreasuryAddress,
        address newTreasuryAddress
    );
    
    /// @notice Emitted when an address is added to or removed from the exempted addresses set.
    event TaxExemptionUpdated(address indexed wallet, bool exempted);

    /**
     * @param treasuryAddress Address of treasury to use.
     * @param busdTokenAddress Address of busd token.
     * @param tokenAddress Address of token to accumulate and sell.
     * @param routerAddress Address of Uniswap router for sell and liquidity operations.
     * @param initialTaxBasisPoints Initial basis points value of tax to collect in the treasury.
     */
    function initialize(
        address treasuryAddress,
        address busdTokenAddress,
        address tokenAddress,
        address routerAddress,
        uint256 initialTaxBasisPoints
    ) public initializer {
        __Ownable_init();
        __LenientReentrancyGuard_init();
        treasury = treasuryAddress;
        busdToken = IERC20Upgradeable(busdTokenAddress);
        token = IERC20Upgradeable(tokenAddress);
        router = IUniswapV2Router02(routerAddress);
        taxBasisPoints = initialTaxBasisPoints;
    }

    /**
     * @notice Perform operations before a sell action (or a liquidity addition) is executed. The accumulated tokens are
     * then sold for BUSD. In case the number of accumulated tokens exceeds the price impact percentage threshold, then
     * the number will be adjusted to stay within the threshold. If a non-zero percentage is set for liquidity, then
     * that percentage will be added to the primary liquidity pool instead of being sold for BUSD and sent to the
     * treasury.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function beforeTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external override nonReentrant {
        // Silence a few warnings. This will be optimized out by the compiler.
        benefactor;
        amount;

        // No actions are done on transfers other than sells.
        if (!_exchangePools.contains(beneficiary)) {
            return;
        }

        uint256 currentWeiBalance = busdToken.balanceOf(address(this));
        _swapTokensForBUSD(amount);

        if (!_exempted.contains(benefactor)) {
            uint256 weiEarned = busdToken.balanceOf(address(this)) -
                currentWeiBalance;

            // No need to divide this number, because that was only to have enough tokens remaining to pair with this
            // BUSD value.
            uint256 weiForTax = (weiEarned * taxBasisPoints) /
                10000;

            busdToken.transfer(address(treasury), weiForTax);
        }

        // It's cheaper to get the active balance rather than calculating based off of the `currentWeiBalance` and
        // `weiForLiquidity` numbers.
        uint256 remainingWeiBalance = busdToken.balanceOf(address(this));
        if (remainingWeiBalance > 0) {
            busdToken.transfer(msg.sender, remainingWeiBalance);
        }
    }

    /**
     * @notice Perform post-transfer operations. This contract ignores those operations, hence nothing happens.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function afterTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external override nonReentrant {
        // Silence a few warnings. This will be optimized out by the compiler.
        benefactor;
        beneficiary;
        amount;

        return;
    }

    /**
     * @notice Set new tax basis points value.
     * @param newBasisPoints New tax basis points value. Cannot exceed 10,000 (i.e., 100%) as that would break the
     * calculation.
     */
    function setTaxBasisPoints(uint256 newBasisPoints)
        external
        onlyOwner
    {
        require(
            newBasisPoints <= 10000,
            "TreasuryHandlerAlpha:setTaxPercentage:INVALID_PERCENTAGE: Cannot set more than 10,000 basis points."
        );
        uint256 oldBasisPoints = taxBasisPoints;
        taxBasisPoints = newBasisPoints;

        emit TaxBasisPointsUpdated(oldBasisPoints, newBasisPoints);
    }

    /**
     * @notice Set new treasury address.
     * @param newTreasuryAddress New treasury address.
     */
    function setTreasury(address newTreasuryAddress) external onlyOwner {
        require(
            newTreasuryAddress != address(0),
            "TreasuryHandlerAlpha:setTreasury:ZERO_TREASURY: Cannot set zero address as treasury."
        );

        address oldTreasuryAddress = address(treasury);
        treasury = payable(newTreasuryAddress);

        emit TreasuryAddressUpdated(oldTreasuryAddress, newTreasuryAddress);
    }

    /**
     * @notice Withdraw any tokens or BUSD stuck in the treasury handler.
     * @param tokenAddress Address of the token to withdraw. If set to the zero address, BUSD will be withdrawn.
     * @param amount The number of tokens to withdraw.
     */
    function withdraw(address tokenAddress, uint256 amount) external onlyOwner {
        require(
            tokenAddress != address(token),
            "TreasuryHandlerAlpha:withdraw:INVALID_TOKEN: Not allowed to withdraw token required for swaps."
        );

        if (tokenAddress == address(0)) {
            busdToken.transfer(msg.sender, amount);
        } else {
            IERC20Upgradeable(tokenAddress).transferFrom(
                address(this),
                address(treasury),
                amount
            );
        }
    }

    /**
     * @dev Swap accumulated tokens for BUSD.
     * @param tokenAmount Number of tokens to swap for BUSD.
     */
    function _swapTokensForBUSD(uint256 tokenAmount) private {
        // The BUSD/token pool is the primary pool. It always exists.
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(busdToken);

        // Ensure the router can perform the swap for the designated number of tokens.
        token.approve(address(router), tokenAmount);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
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

    /**
     * @notice Allow contract to accept BUSD.
     */
    receive() external payable {}
}
