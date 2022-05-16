### Instructions

Firstly, Make a copy of .env.example and rename it to .env. Then paste owner's wallet mnemonic phrase and wallet addresses respectively to which vested tokens are to be released.

To deploy on BSC testnet, run: \
`truffle migrate --network testnet`

To deploy on BSC mainnet, run: \
`truffle migrate --network bsc`

This will deploy Proxy Contracts and Implementation Contracts.
Proxy Contracts are automatically verified. We will have to verify Implementation contracts.

To verify Implementation contract, run: \
`truffle run verify <Implementation Contract Name>@<Implementation Contract Address> --network <Network>`

Finding Implementation Contract Address in unusual way: \

- Go to \
   `https://bscscan.com/proxyContractChecker` (BSC mainnet) \
   `https://testnet.bscscan.com/proxyContractChecker` (BSC testnet)
- Enter Proxy Contract Address and click on verify.
- This will link you to unverified implementation contract address.

After Implementation contract is verified, \

- Go back to ProxyContractChecker: \
   `https://bscscan.com/proxyContractChecker` (BSC mainnet) \
   `https://testnet.bscscan.com/proxyContractChecker` (BSC testnet)
- Enter Proxy Contract Address and click on verify.
- This will link proxy contract with implementation contract.
