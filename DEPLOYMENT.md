### Instructions

Firstly, Make a copy of .env.example and rename it to .env. Then paste owner's wallet mnemonic phrase and wallet addresses respectively to which vested tokens are to be released.

To deploy on BSC testnet, run: \
`truffle migrate --network testnet`

In case of error regarding Error: PollingBlockTracker, run: \
`truffle migrate --network testnet --compile-none`

Make sure contracts compile before running this. For this run: \
`truffle compile`

To deploy on BSC mainnet, run: \
`truffle migrate --network bsc`
