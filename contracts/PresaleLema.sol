// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

import "./PresaleLemaRefundVault.sol";
import "./LemaToken.sol";

contract PresaleLema is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // The vault that will store the BUSD until the goal is reached
    PresaleLemaRefundVault public vault;

    // The block number of when the presale starts
    // Nov 25th 2021, 12 am (UTC)
    uint256 public startTime = 1637777700;

    // The block number of when the presale ends
    // Dec 15th 2021, 12 am (UTC)
    uint256 public endTime = 1639505700;

    LemaToken public lemaToken;
    IBEP20 public busd;

    // Set token claimable or not
    bool public tokenClaimable = false;

    // The wallet that holds the BUSD raised on the presale
    address public wallet;
    // The rate of BUSD per LEMA. Only applied for the first tier, <= 25k BUSD
    uint256 public rateTier1 = 40;
    // The rate of BUSD per LEMA. Only applied for the second tier, > 25k <= 50k BUSD
    uint256 public rateTier2;
    // The rate of BUSD per LEMA. Only applied for the third tier, at between
    // > 50k BUSD
    uint256 public rateTier3 = 20;

    // The maximum amount of BUSD raised for each tier
    uint256 public limitTier1 = 25000 * 1e18; // if <= limitTier1, use rateTier1
    uint256 public limitTier2 = 50000 * 1e18; // if > limitTier1, <= limitTier2, use rateTier2, > limitTier2, use rateTier3

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
    event BUSDDeposited(
        address indexed buyer,
        uint256 amountDeposited
    );

    // To indicate buyer has claimed refund
    event RefundClaimed(
        address indexed buyer,
        uint256 claimedBUSD
    );

    // To indicate buyer has claimed token
    event TokenClaimed(
        address indexed buyer,
        uint256 claimedToken
    );

    // Indicates if the presale has ended
    event Finalized();

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

    function buyTokensWithBUSD(uint256 _amount) public {
        require(
            now >= startTime && now < endTime,
            "Presale has not started or already ended."
        );
        require(_amount > 0, "Amount should be greater than 0");
        require(
            presaleBalances[msg.sender].add(_amount) <= MAX_PURCHASE,
            "Max purchase limit reached"
        );
        require(_amount <= busd.balanceOf(msg.sender), "BUSD is not enough");

        uint256 tokens = 0;

        if (busdRaised <= limitTier1) {
            // Tier 1: rate = 40
            tokens = _amount.mul(rateTier1);
        } else if (busdRaised > limitTier1 && busdRaised <= limitTier2) {
            // Tier 2
            rateTier2 = busdRaised.div(1000000);
            tokens = _amount.mul(1e18).div(rateTier2);
        } else if (busdRaised > limitTier2) {
            // Tier 3: rate = 20
            tokens = _amount.mul(rateTier3);
        }

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