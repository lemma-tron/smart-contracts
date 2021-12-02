// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

/**
 * @title PresaleLemaRefundVault
 * @dev This contract is used for storing funds while a presale
 * is in progress. Supports refunding the money if presale fails,
 * and forwarding it if presale is successful.
 */
contract PresaleLemaRefundVault is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    enum State {
        Active,
        Refunding,
        Closed
    }

    mapping(address => uint256) public deposited;
    mapping(address => bool) public tokenClaimedTracker;

    uint256 public totalBUSDDeposited = 0;

    address public wallet;
    IBEP20 public busd;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 busdAmount);

    constructor(address _wallet, IBEP20 _busd) public {
        wallet = _wallet;
        busd = _busd;
        state = State.Active;
    }

    function approve(
        address tokenAddress,
        address spender,
        uint256 amount
    ) public onlyOwner returns (bool) {
        IBEP20(tokenAddress).approve(spender, amount);
        return true;
    }

    function deposit(address _investor, uint256 _amount) public onlyOwner {
        require(state == State.Active, "Requires Active state");
        deposited[_investor] = deposited[_investor].add(_amount);
        totalBUSDDeposited = totalBUSDDeposited.add(_amount);
        busd.safeTransferFrom(_investor, address(this), _amount);
    }

    function tokenClaimed(address investor) public onlyOwner {
        tokenClaimedTracker[investor] = true;
    }

    function close() public onlyOwner {
        require(state == State.Active, "Requires Active state");
        state = State.Closed;
        emit Closed();
    }

    function enableRefunds() public onlyOwner {
        require(state == State.Active, "Requires Active state");
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function withdrawBUSD() public onlyOwner {
        require(state == State.Closed, "Requires Closed state");
        busd.safeTransfer(wallet, totalBUSDDeposited);
    }

    function refund(address investor) public onlyOwner {
        require(state == State.Refunding, "Requires Refunding state");
        require(
            tokenClaimedTracker[investor] == false,
            "Token has already been claimed"
        );
        require(deposited[investor] > 0, "No amount to be refunded.");

        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;

        totalBUSDDeposited = totalBUSDDeposited.sub(depositedValue);

        busd.safeTransfer(investor, depositedValue);
        emit Refunded(investor, depositedValue);
    }

    function updateWalletAddress(address _wallet) public onlyOwner {
        wallet = _wallet;
    }
}
