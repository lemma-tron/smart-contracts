// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";

import "./LemaToken.sol";

contract LemaTokenVesting is Ownable {
    using SafeMath for uint256;

    LemaToken public lemaToken;

    event TokensReleased(address _vestedAddress, uint256 amount);

    struct TokenGrant {
        uint256 _amount;
        uint256 _start;
        uint256 _duration; // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
        bool _vested;
    }

    mapping(address => TokenGrant[]) public grants;

    uint256 public _totalLemaTokenVestedAmount = 0;

    address public initialLiquidity;
    address public privateSale;
    address public presale;
    address public marketing;
    address public stakingIncentiveDiscount;
    address public advisor;
    address public team;
    address public treasury;

    uint256 private contractDeployedTimestamp;

    constructor(
        LemaToken _lemaToken,
        address _initialLiquidity,
        address _privateSale,
        address _presale,
        address _marketing,
        address _stakingIncentiveDiscount,
        address _advisor,
        address _team,
        address _treasury
    ) public {
        lemaToken = _lemaToken;
        initialLiquidity = _initialLiquidity;
        privateSale = _privateSale;
        presale = _presale;
        marketing = _marketing;
        stakingIncentiveDiscount = _stakingIncentiveDiscount;
        advisor = _advisor;
        team = _team;
        treasury = _treasury;

        contractDeployedTimestamp = block.timestamp;
    }

    function addToTokenVesting(
        address _vestingAddress,
        uint256 _amount,
        uint256 _start,
        uint256 _duration
    ) internal {
        grants[_vestingAddress].push(
            TokenGrant(_amount, _start, _duration, false)
        );
    }

    function createInitialLiquidityVesting() public onlyOwner {
        require(grants[initialLiquidity].length <= 0, "Already Created !");
        addToTokenVesting(initialLiquidity, 500000000e18, contractDeployedTimestamp, 12 weeks);
    }

    function createPrivateSaleVesting() public onlyOwner {
        require(grants[privateSale].length <= 0, "Already Created !");
        addToTokenVesting(privateSale, 75000000e18, contractDeployedTimestamp + 48 weeks, 12 weeks);
        addToTokenVesting(privateSale, 75000000e18, contractDeployedTimestamp + 60 weeks, 12 weeks);
        addToTokenVesting(privateSale, 75000000e18, contractDeployedTimestamp + 72 weeks, 12 weeks);
        addToTokenVesting(privateSale, 75000000e18, contractDeployedTimestamp + 84 weeks, 12 weeks);
        addToTokenVesting(privateSale, 75000000e18, contractDeployedTimestamp + 96 weeks, 12 weeks);
        addToTokenVesting(privateSale, 75000000e18, contractDeployedTimestamp + 108 weeks, 12 weeks);
        addToTokenVesting(privateSale, 75000000e18, contractDeployedTimestamp + 120 weeks, 12 weeks);
        addToTokenVesting(privateSale, 75000000e18, contractDeployedTimestamp + 132 weeks, 12 weeks);
    }

    function createPresaleVesting() public onlyOwner {
        require(grants[presale].length <= 0, "Already Created !");
        addToTokenVesting(presale, 50000000e18, contractDeployedTimestamp + 24 weeks, 12 weeks);
        addToTokenVesting(presale, 50000000e18, contractDeployedTimestamp + 36 weeks, 12 weeks);
        addToTokenVesting(presale, 50000000e18, contractDeployedTimestamp + 48 weeks, 12 weeks);
        addToTokenVesting(presale, 50000000e18, contractDeployedTimestamp + 60 weeks, 12 weeks);
        addToTokenVesting(presale, 50000000e18, contractDeployedTimestamp + 72 weeks, 12 weeks);
        addToTokenVesting(presale, 50000000e18, contractDeployedTimestamp + 84 weeks, 12 weeks);
        addToTokenVesting(presale, 50000000e18, contractDeployedTimestamp + 96 weeks, 12 weeks);
        addToTokenVesting(presale, 50000000e18, contractDeployedTimestamp + 108 weeks, 12 weeks);
    }

    function createMarketingVesting() public onlyOwner {
        require(grants[marketing].length <= 0, "Already Created !");
        addToTokenVesting(marketing, 250000000e18, contractDeployedTimestamp, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 36 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 60 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 84 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 108 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 132 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 156 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 180 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 204 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 228 weeks, 12 weeks);
        addToTokenVesting(marketing, 125000000e18, contractDeployedTimestamp + 252 weeks, 12 weeks);
    }

    function createStakingIncentiveDiscountVesting() public onlyOwner {
        require(grants[stakingIncentiveDiscount].length <= 0, "Already Created !");
        addToTokenVesting(stakingIncentiveDiscount, 100000000e18, contractDeployedTimestamp, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 100000000e18, contractDeployedTimestamp + 12 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 100000000e18, contractDeployedTimestamp + 24 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 100000000e18, contractDeployedTimestamp + 36 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 87500000e18, contractDeployedTimestamp + 48 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 87500000e18, contractDeployedTimestamp + 60 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 87500000e18, contractDeployedTimestamp + 72 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 87500000e18, contractDeployedTimestamp + 84 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 75000000e18, contractDeployedTimestamp + 96 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 75000000e18, contractDeployedTimestamp + 108 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 75000000e18, contractDeployedTimestamp + 120 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 75000000e18, contractDeployedTimestamp + 132 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 62500000e18, contractDeployedTimestamp + 144 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 62500000e18, contractDeployedTimestamp + 156 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 62500000e18, contractDeployedTimestamp + 168 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 62500000e18, contractDeployedTimestamp + 180 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 50000000e18, contractDeployedTimestamp + 192 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 50000000e18, contractDeployedTimestamp + 204 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 50000000e18, contractDeployedTimestamp + 216 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 50000000e18, contractDeployedTimestamp + 228 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 37500000e18, contractDeployedTimestamp + 240 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 37500000e18, contractDeployedTimestamp + 252 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 37500000e18, contractDeployedTimestamp + 264 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 37500000e18, contractDeployedTimestamp + 276 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 288 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 300 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 312 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 324 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 336 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 348 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 360 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 372 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 384 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 396 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 25000000e18, contractDeployedTimestamp + 408 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 12500000e18, contractDeployedTimestamp + 420 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 12500000e18, contractDeployedTimestamp + 432 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 12500000e18, contractDeployedTimestamp + 444 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 12500000e18, contractDeployedTimestamp + 456 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 12500000e18, contractDeployedTimestamp + 468 weeks, 12 weeks);
        addToTokenVesting(stakingIncentiveDiscount, 12500000e18, contractDeployedTimestamp + 480 weeks, 12 weeks);
    }

    function createAdvisorVesting() public onlyOwner {
        require(grants[advisor].length <= 0, "Already Created !");
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 72 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 96 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 120 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 144 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 168 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 192 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 216 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 240 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 264 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 288 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 312 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 336 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 360 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 384 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 408 weeks, 12 weeks);
        addToTokenVesting(advisor, 31250000e18, contractDeployedTimestamp + 432 weeks, 12 weeks);
    }

    function createTeamVesting() public onlyOwner {
        require(grants[team].length <= 0, "Already Created !");
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 72 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 96 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 120 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 144 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 168 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 192 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 216 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 240 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 264 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 288 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 312 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 336 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 360 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 384 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 408 weeks, 12 weeks);
        addToTokenVesting(team, 125000000e18, contractDeployedTimestamp + 432 weeks, 12 weeks);
    }

    function createTreasuryVesting() public onlyOwner {
        require(grants[treasury].length <= 0, "Already Created !");
        addToTokenVesting(treasury, 250000000e18, contractDeployedTimestamp, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 12 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 24 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 36 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 48 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 60 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 72 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 84 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 96 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 108 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 120 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 132 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 144 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 156 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 168 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 180 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 192 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 204 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 216 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 228 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 240 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 252 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 264 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 276 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 288 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 300 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 312 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 324 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 336 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 348 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 360 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 372 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 384 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 396 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 408 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 420 weeks, 12 weeks);
        addToTokenVesting(treasury, 62500000e18, contractDeployedTimestamp + 432 weeks, 12 weeks);
    }

    // Get number of lema token vested
    function getTotalLemaTokenVestedAmount() public view returns (uint256) {
        return _totalLemaTokenVestedAmount;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release(address _vestingAddress) public {
        TokenGrant[] storage vestingGrants = grants[_vestingAddress];

        require(
            vestingGrants.length > 0,
            "Vesting Address not found !"
        );

        uint256 currentTimestamp = block.timestamp;
        for (uint256 i = 0; i < vestingGrants.length; i++) {
            TokenGrant storage grant = vestingGrants[i];
            if (
                currentTimestamp >= grant._start &&
                currentTimestamp <= grant._start.add(grant._duration) &&
                !grant._vested
            ) {
                _totalLemaTokenVestedAmount += grant._amount;
                grant._vested = true;
                lemaToken.transfer(_vestingAddress, grant._amount);
                emit TokensReleased(_vestingAddress, grant._amount);
            }
        }
    }

    function vestInitialTokens() public onlyOwner {
        release(initialLiquidity);
        release(privateSale);
        release(presale);
        release(marketing);
        release(stakingIncentiveDiscount);
        release(advisor);
        release(team);
        release(treasury);
    }
}