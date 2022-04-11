// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "./PresaleLemaRefundVault.sol";
import "./LemaToken.sol";

contract PresaleLemaV2 is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // The vault that will store the BUSD until the goal is reached
    PresaleLemaRefundVault public vault;

    // The block number of when the presale starts
    // Apr 6th 2022, 12 am (UTC)
    uint256 public startTime = 1649203200;

    // The block number of when the presale ends
    // May 21st 2022, 12 am (UTC)
    uint256 public endTime = 1653091200;

    uint256 public startingPrice = 0.00005 ether;
    uint256 public closingPrice = 0.00010 ether;

    LemaToken public lemaToken;
    IBEP20 public busd;

    // Set token claimable or not
    bool public tokenClaimable = false;

    // The wallet that holds the BUSD raised on the presale
    address public wallet;

    uint256 public constant TOTAL_TOKENS = 400000000;

    // The amount of BUSD raised
    uint256 public busdRaised = 0;

    // The amount of tokens raised
    uint256 public tokensRaised = 0;

    // The max amount of BUSD that you can pay to participate in the presale
    uint256 public constant MAX_PURCHASE = 10000 * 1e18;

    // Minimum amount of BUSD to be raised. 20k BUSD
    uint256 public constant MIN_GOAL = 20000 * 1e18;

    // If the presale wasn't successful, this will be true and users will be able
    // to claim the refund of their BUSD
    bool public isRefunding = false;

    // If the presale has ended or not
    bool public isEnded = false;

    // The number of transactions
    uint256 public numberOfTransactions;

    // The amount of tokens claimed
    uint256 public tokensClaimed = 0;

    // How much each user paid for the presale
    mapping(address => uint256) public presaleBalances;

    // How many tokens each user got for the presale
    mapping(address => uint256) public tokenToBeTransferred;

    // To indicate how much token will be received
    event TokenToBeTransferred(
        address indexed buyer,
        uint256 amountDeposited,
        uint256 amountOfTokens
    );

    // To indicate busd has been deposited by buyer
    event BUSDDeposited(address indexed buyer, uint256 amountDeposited);

    // To indicate buyer has claimed refund
    event RefundClaimed(address indexed buyer, uint256 claimedBUSD);

    // To indicate buyer has claimed token
    event TokenClaimed(address indexed buyer, uint256 claimedToken);

    // Indicates if the presale has ended
    event Finalized();

    modifier runningPreSaleOnly() {
        require(
            now >= startTime && now < endTime,
            "Presale has not started or already ended."
        );
        _;
    }

    constructor(
        LemaToken _lemaToken,
        IBEP20 _busd,
        address _wallet,
        PresaleLemaRefundVault _vault
    ) public {
        lemaToken = _lemaToken;
        busd = _busd;
        wallet = _wallet;
        vault = _vault;
    }

    function getPrice() public view returns (uint256) {
        uint256 daysPassed = (block.timestamp.sub(startTime)).div(1 days);
        uint256 duration = (endTime.sub(startTime)).div(1 days);
        uint256 price = startingPrice.add(
            ((closingPrice.sub(startingPrice)).mul(daysPassed)).div(duration)
        );
        return price;
    }

    function buyTokensWithBUSD(uint256 _amount) public runningPreSaleOnly {
        require(_amount > 0, "Amount should be greater than 0");
        require(
            presaleBalances[msg.sender].add(_amount) <= MAX_PURCHASE,
            "Max purchase limit reached"
        );
        require(_amount <= busd.balanceOf(msg.sender), "BUSD is not enough");

        uint256 price = getPrice();
        uint256 tokens = _amount.div(price);

        busdRaised = busdRaised.add(_amount);
        tokensRaised = tokensRaised.add(tokens);

        // keep a record of how many busd has investor deposited
        presaleBalances[msg.sender] = presaleBalances[msg.sender].add(_amount);
        emit BUSDDeposited(msg.sender, _amount);

        // Keep a record of how many tokens investor gets
        tokenToBeTransferred[msg.sender] = tokenToBeTransferred[msg.sender].add(
            tokens
        );
        emit TokenToBeTransferred(msg.sender, _amount, tokens);
        numberOfTransactions = numberOfTransactions.add(1);

        vault.deposit(msg.sender, _amount);
    }

    /// @notice Allow to update Presale start date
    /// @param _startTime Starttime of Presale
    function setStartDate(uint256 _startTime) public onlyOwner {
        require(now < _startTime, "Can only update future start time");
        require(endTime > _startTime, "End time should be greater");
        startTime = _startTime;
    }

    /// @notice Allow to extend Presale end date
    /// @param _endTime Endtime of Presale
    function setEndDate(uint256 _endTime) public onlyOwner {
        require(now < _endTime, "Can only update future end time");
        require(startTime < _endTime, "End time should be greater");
        endTime = _endTime;
    }

    /// @notice Check if the presale has ended and enables refunds only in case the
    /// goal hasn't been reached
    /// call this method after presale has ended
    function checkCompletedPresale() public {
        require(
            !isEnded,
            "Presale has ended and required action has been taken."
        );
        if (hasEnded() && !goalReached()) {
            vault.enableRefunds();
            isRefunding = true;
            isEnded = true;
            emit Finalized();
        } else if (hasEnded() && goalReached()) {
            vault.close();
            isEnded = true;
            emit Finalized();
        }
    }

    /// @notice If presale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(hasEnded() && !goalReached() && isRefunding);
        require(presaleBalances[msg.sender] > 0, "No amount to be refunded");

        uint256 claimedBUSD = presaleBalances[msg.sender];

        busdRaised = busdRaised.sub(presaleBalances[msg.sender]);
        tokensRaised = tokensRaised.sub(tokenToBeTransferred[msg.sender]);

        presaleBalances[msg.sender] = 0;
        tokenToBeTransferred[msg.sender] = 0;

        vault.refund(msg.sender);

        emit RefundClaimed(msg.sender, claimedBUSD);
    }

    /// @notice Public function to check BUSD deposited
    function depositedBUSD() public view returns (uint256) {
        return presaleBalances[msg.sender];
    }

    /// @notice Public function to check token to be claimed
    function tokenToBeClaimed() public view returns (uint256) {
        return tokenToBeTransferred[msg.sender];
    }

    /// @notice To see if the minimum goal of BUSD raied has been reached
    /// @return bool True if the BUSD raised are bigger than the goal or false otherwise
    function goalReached() public view returns (bool) {
        return busdRaised >= MIN_GOAL;
    }

    /// @notice Public function to check if the presale has ended or not
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    function setTokenClaimable(bool _claimable) public onlyOwner {
        tokenClaimable = _claimable;
    }

    function claimLemaToken() public {
        require(
            hasEnded() && goalReached(),
            "Presale not ended and goal not reached"
        );
        require(!isRefunding, "Cannot claim token in Refunding state");
        require(
            tokenClaimable,
            "Token is not claimable right now. Will be available after vesting."
        );
        require(
            tokenToBeTransferred[msg.sender] > 0,
            "No Tokens to be claimed"
        );
        require(
            lemaToken.balanceOf(address(this)) >=
                tokenToBeTransferred[msg.sender],
            "Balance not sufficient"
        );
        uint256 tokens = tokenToBeTransferred[msg.sender];
        tokensRaised = tokensRaised.sub(tokens);
        tokensClaimed = tokensClaimed.add(tokens);

        tokenToBeTransferred[msg.sender] = 0;
        vault.tokenClaimed(msg.sender);
        lemaToken.transfer(msg.sender, tokens);

        emit TokenClaimed(msg.sender, tokens);
    }

    function withdrawBUSDFromVault() public onlyOwner {
        vault.withdrawBUSD();
    }

    /// @notice Update Lema Token Contract Address only if updates are made in LemaToken contract.
    function updateLemaTokenAddress(LemaToken _lemaToken) public onlyOwner {
        lemaToken = _lemaToken;
    }

    /// @notice Update Wallet Address that claims collected BUSD
    function updateWalletAddress(address _wallet) public onlyOwner {
        wallet = _wallet;
        vault.updateWalletAddress(_wallet);
    }

    /// @notice Approve transfer of BUSD from Vault to Owner Address
    function approveOwner(
        address tokenAddress,
        address spender,
        uint256 amount
    ) public onlyOwner returns (bool) {
        return vault.approve(tokenAddress, spender, amount);
    }
}
