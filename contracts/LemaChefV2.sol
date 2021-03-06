// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/Pausable.sol";

import "./lib/VotingPower.sol";

import "./LemaToken.sol";
import "./governance/LemaGovernance.sol";

// Master Contract of Lemmatron
contract LemaChefV2 is Initializable, OwnableUpgradeable, Pausable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for LemaToken;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lastStakedDate; // quasi-last staked date
        uint256 lastDeposited; // last deposited timestamp
        uint256 lastDepositedAmount; // last deposited amount
        uint256 multiplier; // individual multiplier, times 10000. should not exceed 10000
        //
        // We do some fancy math here. Basically, any point in time, the amount of LEMAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accLEMAPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accLEMAPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        // uint256 allocPoint; // How many allocation points assigned to this pool. LEMAs to distribute per block.
        uint256 allocPoint; // Considering 1000 for equal share as other pools
        uint256 lastRewardBlock; // Last block number that LEMAs distribution occurs.
        // uint256 accLEMAPerShare; // Accumulated LEMAs per share, times 1e12. See below.
        uint256 accLEMAPerShareForValidator; // Reward for staking(Rs) + Commission Rate(root(Rs))
        uint256 accLEMAPerShareForNominator; // Reward for staking(Rs)
    }

    string public name;

    LemaToken public lemaToken;
    LemaGovernance public lemaGovernance;

    // Lema tokens created per block.
    uint256 public lemaPerBlockForValidator;
    uint256 public lemaPerBlockForNominator;

    // Bonus muliplier for early Lema makers.
    uint256 public bonusMultiplier;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when mining starts.
    uint256 public startBlock;
    // Estimated Total Blocks per year.
    uint256 public blockPerYear;

    // penalty fee when withdrawing reward within 4 weeks of last deposit and after 4 weeks
    uint256 public penaltyFeeRate1;
    uint256 public penaltyFeeRate2;
    // Penalties period
    uint256 public penaltyPeriod;
    // Treasury address
    address public treasury;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    modifier onlyLemaGovernance() {
        require(
            msg.sender == address(lemaGovernance),
            "Only LemaGovernance can perform this action"
        );
        _;
    }

    modifier fridayOnly() {
        uint256 dayCount = block.timestamp / 1 days;
        uint256 dayOfWeek = (dayCount - 2) % 7;
        require(
            dayOfWeek == 5,
            "LemaChef: Operation is allowed only during Friday."
        );
        _;

        // Explanation
        // 1970 January 1 is Thrusday
        // So to get current day's index counting from Saturday as 0,
        // we are subtracting 2 from dayCount and modulo 7.
    }

    function initialize(
        LemaToken _lemaToken,
        address _treasury,
        uint256 _startBlock
    ) public initializer {
        __Ownable_init();
        __PausableUpgradeable_init();
        lemaToken = _lemaToken;
        treasury = _treasury;
        // lemaPerBlock = _lemaPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(
            PoolInfo({
                lpToken: _lemaToken,
                allocPoint: 1000,
                lastRewardBlock: _startBlock,
                accLEMAPerShareForValidator: 0,
                accLEMAPerShareForNominator: 0
            })
        );
        totalAllocPoint = 1000;

        name = "Lema Chef";
        bonusMultiplier = 1;
        blockPerYear = 31536000 / 5; // 1 year in seconds / 5 seconds(mean block time).
        penaltyFeeRate1 = 20; // withdraw penalty fee if last deposited is < 4 weeks
        penaltyFeeRate2 = 15; // fee if last deposited is > 4 weeks (always implemented)
        penaltyPeriod = 4 weeks;
    }

    function getCurrentBlock() public view returns (uint256) {
        return block.number;
    }

    function updateLemaGovernanceAddress(LemaGovernance _lemaGovernanceAddress)
        public
        onlyOwner
    {
        lemaGovernance = _lemaGovernanceAddress;
    }

    function updateMultiplier(uint256 multiplierNumber) external onlyOwner {
        require(multiplierNumber > 0, "Multipler is too less");
        bonusMultiplier = multiplierNumber;
        //determining the Lema tokens allocated to each farm
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
        //Determine how many pools we have
    }

    function getPools() external view returns (PoolInfo[] memory) {
        return poolInfo;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(bonusMultiplier);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (block.number <= startBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 lemaRewardForValidator = multiplier
            .mul(lemaPerBlockForValidator)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        uint256 lemaRewardForNominator = multiplier
            .mul(lemaPerBlockForNominator)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        pool.accLEMAPerShareForValidator = pool.accLEMAPerShareForValidator.add(
            lemaRewardForValidator.mul(1e12).div(lpSupply)
        );
        pool.accLEMAPerShareForNominator = pool.accLEMAPerShareForNominator.add(
            lemaRewardForNominator.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _lpToken,
        bool _withUpdate
    ) external onlyOwner whenNotPaused {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accLEMAPerShareForValidator: 0,
                accLEMAPerShareForNominator: 0
            })
        );

        updateStakingPool();
    }

    // Update the given pool's Lema allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner whenNotPaused {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(
                _allocPoint
            );
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(
                points
            );
            poolInfo[0].allocPoint = points; //setting first pool allocation points to total pool allocation/3
        }
    }

    // To be called at the start of new 3 months tenure, after releasing the vested tokens to this contract.
    // function reallocPoint(bool _withUpdate) public onlyOwner {
    //     if (_withUpdate) {
    //         massUpdatePools();
    //     }
    //     uint256 totalAvailableLEMA = lemaToken.balanceOf(address(this));
    //     uint256 totalLemaPerBlock = (totalAvailableLEMA.mul(4)).div(
    //         blockPerYear
    //     );
    //     // lemaPerBlockForValidator =
    //     // lemaPerBlockForNominator
    // }

    // View function to see pending Rewards.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid]; //getting the specific pool with it id
        UserInfo storage user = userInfo[_pid][_user]; //getting user belongs to that pool
        //getting the accumulated lema per share in that pool
        uint256 accLEMAPerShare = 0;
        uint256 lemaPerBlock = 0;
        if (lemaGovernance.getValidatorsExists(_user)) {
            accLEMAPerShare = pool.accLEMAPerShareForValidator;
            lemaPerBlock = lemaPerBlockForValidator;
        } else {
            accLEMAPerShare = pool.accLEMAPerShareForNominator;
            lemaPerBlock = lemaPerBlockForNominator;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this)); //how many lptokens are there in that pool
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 lemaReward = multiplier
                .mul(lemaPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint); //calculating the Lema reward
            accLEMAPerShare = accLEMAPerShare.add(
                lemaReward.mul(1e12).div(lpSupply)
            ); //accumulated Lema per each share
        }
        uint256 rewardDebt = getRewardDebt(user, accLEMAPerShare);
        return rewardDebt.sub(user.rewardDebt); //get the pending LEMAs which are rewarded to us to harvest
    }

    // Safe Lema transfer function, just in case if rounding error causes pool to not have enough LEMAs.
    function safeLEMATransfer(address _to, uint256 _amount) internal {
        uint256 lemaBal = lemaToken.balanceOf(address(this));
        if (_amount > lemaBal) {
            lemaToken.transfer(_to, lemaBal);
        } else {
            lemaToken.transfer(_to, _amount);
        }
    }

    // calculates last deposit timestamp for fair withdraw fee
    function getLastDepositTimestamp(
        uint256 lastDepositedTimestamp,
        uint256 lastDepositedAmount,
        uint256 currentAmount
    ) internal view returns (uint256) {
        if (lastDepositedTimestamp <= 0) {
            return block.timestamp;
        } else {
            uint256 currentTimestamp = block.timestamp;
            uint256 multiplier = currentAmount.div(
                (lastDepositedAmount.add(currentAmount))
            );
            return
                (currentTimestamp.sub(lastDepositedTimestamp))
                    .mul(multiplier)
                    .add(lastDepositedTimestamp);
        }
    }

    // to fetch staked amount in given pool of given user
    // this can be used to know if user has staked or not
    function getStakedAmountInPool(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        return userInfo[_pid][_user].amount;
    }

    // to fetch last staked date in given pool of given user
    function getLastStakedDateInPool(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        return userInfo[_pid][_user].lastStakedDate;
    }

    // to fetch if user is LP Token Staker or not
    function multiPoolOrNot(address _user) public view returns (bool) {
        uint256 length = poolInfo.length;
        for (uint256 pid = 1; pid < length; pid++) {
            if (userInfo[pid][_user].amount > 0) {
                return true;
            }
        }
        return false;
    }

    function transferRewardWithWithdrawFee(
        uint256 userLastDeposited,
        uint256 pending
    ) internal {
        uint256 withdrawFee = 0;
        uint256 currentTimestamp = block.timestamp;
        if (currentTimestamp < userLastDeposited.add(penaltyPeriod)) {
            withdrawFee = getWithdrawFee(pending, penaltyFeeRate1);
        } else {
            withdrawFee = getWithdrawFee(pending, penaltyFeeRate2);
        }

        uint256 rewardAmount = pending.sub(withdrawFee);

        require(
            pending == withdrawFee + rewardAmount,
            "Lema::transfer: withdrawfee invalid"
        );

        safeLEMATransfer(treasury, withdrawFee);
        safeLEMATransfer(msg.sender, rewardAmount);
    }

    function getAccLEMAPerShare(PoolInfo memory pool)
        internal
        view
        returns (uint256)
    {
        if (lemaGovernance.getValidatorsExists(msg.sender)) {
            return pool.accLEMAPerShareForValidator;
        } else {
            return pool.accLEMAPerShareForNominator;
        }
    }

    function getRewardDebt(UserInfo memory user, uint256 accLEMAPerShare)
        internal
        pure
        returns (uint256)
    {
        return
            user.amount.mul(accLEMAPerShare).div(1e12).mul(user.multiplier).div(
                1e4
            );
    }

    // Deposit LP tokens to LemaChef for Lema allocation.
    function deposit(uint256 _pid, uint256 _amount) external whenNotPaused {
        require(_pid != 0, "deposit Lema by staking");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 accLEMAPerShare = getAccLEMAPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accLEMAPerShare);
        if (user.amount > 0) {
            uint256 pending = rewardDebt.sub(user.rewardDebt);
            if (pending > 0) {
                transferRewardWithWithdrawFee(user.lastDeposited, pending);
            }
        }
        if (_amount > 0) {
            // pool.lpToken.safeTransferFrom(
            pool.lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            user.lastStakedDate = getLastDepositTimestamp(
                user.lastDeposited,
                user.lastDepositedAmount,
                _amount
            );
            user.lastDeposited = block.timestamp;
            user.lastDepositedAmount = _amount;
        }

        user.rewardDebt = rewardDebt;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function getVotingPower(address _user) public view returns (uint256) {
        uint256 lemaStaked = getStakedAmountInPool(0, _user);
        require(lemaStaked > 0, "LemaChefV2: Stake not enough to vote");

        uint256 lastLemaStakedDate = getLastStakedDateInPool(0, _user);
        uint256 numberOfDaysStaked = block
            .timestamp
            .sub(lastLemaStakedDate)
            .div(86400);
        bool multiPool = multiPoolOrNot(_user);
        uint256 votingPower = VotingPower.calculate(
            numberOfDaysStaked,
            lemaStaked,
            multiPool
        );

        return votingPower;
    }

    // Withdraw LP tokens from LemaChef.
    function withdraw(uint256 _pid, uint256 _amount) external whenNotPaused {
        require(_pid != 0, "withdraw Lema by unstaking");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 accLEMAPerShare = getAccLEMAPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accLEMAPerShare);
        uint256 pending = rewardDebt.sub(user.rewardDebt);
        if (pending > 0) {
            transferRewardWithWithdrawFee(user.lastDeposited, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = rewardDebt;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Get Withdraw fee
    function getWithdrawFee(uint256 _amount, uint256 _penaltyFeeRate)
        internal
        pure
        returns (uint256)
    {
        return _amount.mul(_penaltyFeeRate).div(100);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Update treasury address by the previous treasury address holder.
    function updateTreasuryAddress(address _treasury) external {
        require(msg.sender == treasury, "Updating Treasury Forbidden !");
        treasury = _treasury;
    }

    //Update start reward block
    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        startBlock = _startBlock;
    }

    // update lema per block
    // function updateLemaPerBlock(uint256 _lemaPerBlock) public onlyOwner {
    //     lemaPerBlock = _lemaPerBlock;
    // }

    function updateLemaPerBlockForValidator(uint256 _lemaPerBlock)
        external
        onlyOwner
    {
        lemaPerBlockForValidator = _lemaPerBlock;
    }

    function updateLemaPerBlockForNominator(uint256 _lemaPerBlock)
        external
        onlyOwner
    {
        lemaPerBlockForNominator = _lemaPerBlock;
    }

    // Stake Lema tokens to LemaChef
    function enterStaking(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        uint256 accLEMAPerShare = getAccLEMAPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accLEMAPerShare);
        if (user.amount > 0) {
            uint256 pending = rewardDebt.sub(user.rewardDebt);
            if (pending > 0) {
                transferRewardWithWithdrawFee(user.lastDeposited, pending);
            }
        }
        if (_amount > 0) {
            // pool.lpToken.safeTransferFrom(
            pool.lpToken.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
            user.lastStakedDate = getLastDepositTimestamp(
                user.lastDeposited,
                user.lastDepositedAmount,
                _amount
            );
            user.lastDeposited = block.timestamp;
            user.lastDepositedAmount = _amount;
        }
        user.rewardDebt = rewardDebt;
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw Lema tokens from STAKING.
    function leaveStaking(uint256 _amount) external whenNotPaused {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 accLEMAPerShare = getAccLEMAPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accLEMAPerShare);
        uint256 pending = rewardDebt.sub(user.rewardDebt);
        if (pending > 0) {
            transferRewardWithWithdrawFee(user.lastDeposited, pending);
        }
        if (_amount > 0) {
            // check for validator
            if (_amount > lemaGovernance.getValidatorsMinStake()) {
                lemaGovernance.leftStakingAsValidator(msg.sender);
            }

            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = rewardDebt;
        emit Withdraw(msg.sender, 0, _amount);
    }

    // function withdrawReward(uint256 _pid) external fridayOnly {
    function withdrawReward(uint256 _pid) external whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "withdraw: not good");
        updatePool(_pid);
        uint256 accLEMAPerShare = getAccLEMAPerShare(pool);
        uint256 rewardDebt = getRewardDebt(user, accLEMAPerShare);
        uint256 pending = rewardDebt.sub(user.rewardDebt);
        if (pending > 0) {
            transferRewardWithWithdrawFee(user.lastDeposited, pending);
        }
        user.rewardDebt = rewardDebt;
    }

    function slashOfflineValidators(
        uint256 slashingParameter,
        address[] memory offlineValidators,
        address[] memory onlineValidators
    ) public onlyLemaGovernance whenNotPaused {
        require(
            msg.sender == address(lemaGovernance),
            "Only LemaGovernance can slash offline validators"
        );
        if (slashingParameter > 0) {
            for (uint256 i = 0; i < offlineValidators.length; i++) {
                address user = offlineValidators[i];
                uint256 userStake = getStakedAmountInPool(0, user);
                uint256 toBeSlashedAmount = userStake
                    .mul(7)
                    .mul(slashingParameter)
                    .div(10000);

                safeLEMATransfer(treasury, toBeSlashedAmount);

                UserInfo storage userData = userInfo[0][user];
                userData.amount = userData.amount.sub(toBeSlashedAmount);
            }
        }

        // Reducing multiplier
        for (uint256 i = 0; i < offlineValidators.length; i++) {
            address user = offlineValidators[i];
            UserInfo storage userData = userInfo[0][user];
            userData.multiplier = 5000;
        }

        // Recovering multiplier
        for (uint256 i = 0; i < onlineValidators.length; i++) {
            address user = onlineValidators[i];
            UserInfo storage userData = userInfo[0][user];
            userData.multiplier = 10000;
        }
    }

    function evaluateThreeValidatorsNominatedByNominator(
        uint256 slashingParameter,
        address[] memory nominators
    ) public onlyLemaGovernance whenNotPaused {
        require(
            msg.sender == address(lemaGovernance),
            "Only LemaGovernance can evaluate three validators nominated by nominator"
        );
        for (uint256 i = 0; i < nominators.length; i++) {
            address nominator = nominators[i];
            UserInfo storage userData = userInfo[0][nominator];
            address[3] memory validatorsNominatedByNominator = lemaGovernance
                .getValidatorsNominatedByNominator(nominator);

            for (uint256 j = 0; j < 3; j++) {
                address validator = validatorsNominatedByNominator[j];
                if (lemaGovernance.haveCastedVote(validator)) {
                    userData.multiplier = 10000;

                    if (j != 0) {
                        lemaGovernance.vestVotesToDifferentValidator(
                            nominator,
                            validatorsNominatedByNominator[0],
                            validator
                        );
                    }

                    return;
                }
            }
            userData.multiplier = 5000;

            if (slashingParameter > 0) {
                uint256 userStake = getStakedAmountInPool(0, nominator);
                uint256 toBeSlashedAmount = userStake
                    .mul(7)
                    .mul(slashingParameter)
                    .div(10000);

                safeLEMATransfer(treasury, toBeSlashedAmount);

                userData.amount = userData.amount.sub(toBeSlashedAmount);
            }
        }
    }
}
