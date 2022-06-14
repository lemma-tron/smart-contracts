# Functions that are required to be integrated in the dapp

### LemaGovernance

- [vestVotesToDifferentValidator](contracts/governance/LemaGovernance.sol#:~:text=vestVotesToDifferentValidator) - Vested Votes are delegated to a different validator
- [getPastGovernances](contracts/governance/LemaGovernance.sol#:~:text=getPastGovernances) - Get the list of past governances along with projects list and winning project on each governance
- [getProjects](contracts/governance/LemaGovernance.sol#:~:text=getProjects) - Get the list of projects
- [addProject](contracts/governance/LemaGovernance.sol#:~:text=addProject) - Apply for a project
- [delegateValidator](contracts/governance/LemaGovernance.sol#:~:text=delegateValidator) - Delegate a validator
- [applyForValidator](contracts/governance/LemaGovernance.sol#:~:text=applyForValidator) - Apply for a validator
- [castVote](contracts/governance/LemaGovernance.sol#:~:text=castVote) - Cast vote by a validator
- [getValidators](contracts/governance/LemaValidators.sol#:~:text=getValidators) - Get the list of validators
- [getWhitelistedValidators](contracts/governance/LemaValidators.sol#:~:text=getWhitelistedValidators) - Get the list of whitelisted validators
- [getValidatorsExists](contracts/governance/LemaValidators.sol#:~:text=getValidatorsExists) - Check if a validator exists
- [haveCastedVote](contracts/governance/LemaValidators.sol#:~:text=haveCastedVote) - Check if a validator has cast a vote
- [getValidatorsMinStake](contracts/governance/LemaValidators.sol#:~:text=getValidatorsMinStake) - Get the minimum stake of a validator
- [leaveFromValidator](contracts/governance/LemaValidators.sol#:~:text=leaveFromValidator) - Leave from a validator
- [getVoters](contracts/governance/LemaVoters.sol#:~:text=getVoters) - Get the list of voters
- [haveDelagatedValidator](contracts/governance/LemaVoters.sol#:~:text=haveDelagatedValidator) - Check if a voter has delegated a validator
- [delegateMoreValidator](contracts/governance/LemaVoters.sol#:~:text=delegateMoreValidator) - Delegate more than one validator
- [changeValidatorOrder](contracts/governance/LemaVoters.sol#:~:text=changeValidatorOrder) - Change the order of the validators
- [getValidatorsNominatedByNominator](contracts/governance/LemaVoters.sol#:~:text=getValidatorsNominatedByNominator) - Get the list of validators nominated by a nominator

### LemaChef

- [poolLength](contracts/LemaChefV2.sol#:~:text=poolLength) - Returns the length of the pool
- [getPools](contracts/LemaChefV2.sol#:~:text=getPools) - Returns the list of pools
- [pendingReward](contracts/LemaChefV2.sol#:~:text=pendingReward) - Returns the pending reward amount
- [getStakedAmountInPool](contracts/LemaChefV2.sol#:~:text=getStakedAmountInPool) - Returns the staked amount in the pool
- [getLastStakedDateInPool](contracts/LemaChefV2.sol#:~:text=getLastStakedDateInPool) - Returns the last staked date in the pool
- [multiPoolOrNot](contracts/LemaChefV2.sol#:~:text=multiPoolOrNot) - Returns if the user has staked in multi-pool or not
- [deposit](contracts/LemaChefV2.sol#:~:text=deposit) - Stakes the amount to the specific pool
- [getVotingPower](contracts/LemaChefV2.sol#:~:text=getVotingPower) - Returns the vested voting power of the user
- [withdraw](contracts/LemaChefV2.sol#:~:text=withdraw) - Withdraws the amount from the specifig pool
- [emergencyWithdraw](contracts/LemaChefV2.sol#:~:text=emergencyWithdraw) - Withdraws the amount from the pool in emergency mode, i.e without caring about the reward
- [enterStaking](contracts/LemaChefV2.sol#:~:text=enterStaking) - Stakes the amount in the pool 0
- [leaveStaking](contracts/LemaChefV2.sol#:~:text=leaveStaking) - Leaves the staking
- [withdrawReward](contracts/LemaChefV2.sol#:~:text=withdrawReward) - Withdraws the reward amount

### LemaChef - onlyOwner/admin

- [updateLemaGovernanceAddress](contracts/LemaChefV2.sol#:~:text=updateLemaGovernanceAddress) - Updates the LemmaGovernance address
- [updateMultiplier](contracts/LemaChefV2.sol#:~:text=updateMultiplier) - Updates the bonus multiplier
- [add](contracts/LemaChefV2.sol#:~:text=add) - Adds a new pool
- [set](contracts/LemaChefV2.sol#:~:text=set) - Updates allocation point of a pool
- [updateStartBlock](contracts/LemaChefV2.sol#:~:text=updateStartBlock) - Updates the start block
- [updateLemaPerBlockForValidator](contracts/LemaChefV2.sol#:~:text=updateLemaPerBlockForValidator) - Updates the Lema per block for validator
- [updateLemaPerBlockForNominator](contracts/LemaChefV2.sol#:~:text=updateLemaPerBlockForNominator) - Updates the Lema per block for nominator

### LemaGovernance - onlyOwner/admin

- [startNewGovernance](contracts/governance/LemaGovernance.sol#:~:text=startNewGovernance) - Start a new governance
- [approveProject](contracts/governance/LemaGovernance.sol#:~:text=approveProject) - Approve a project
- [rewardMostVotedProject](contracts/governance/LemaGovernance.sol#:~:text=rewardMostVotedProject) - Reward the most voted project
- [updateValidatorMinStake](contracts/governance/LemaValidators.sol#:~:text=updateValidatorMinStake) - Update the minimum stake required to become a validator
- [updateNumberOfValidatorAllowed](contracts/governance/LemaValidators.sol#:~:text=updateNumberOfValidatorAllowed) - Update the number of validators allowed
- [addToBlocklist](contracts/governance/LemaValidators.sol#:~:text=addToBlocklist) - Add a address to the blocklist
- [removeFromBlocklist](contracts/governance/LemaValidators.sol#:~:text=removeFromBlocklist) - Remove a address from the blocklist
