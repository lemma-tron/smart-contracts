# Lemmatron Smart Contracts

**This project is work in progress**. This project holds smart contracts of Lemmatron.

## Smart Contracts

- [LEMA Token](https://github.com/lemmatron/smart-contracts/blob/master/contracts/LemaToken.sol)
- [LEMA Token Vesting](https://github.com/lemmatron/smart-contracts/blob/master/contracts/LemaTokenVesting.sol)
- [LEMA Token MasterChef](https://github.com/lemmatron/smart-contracts/blob/master/contracts/LemaChef.sol)
- [LEMA Token Presale](https://github.com/lemmatron/smart-contracts/blob/master/contracts/PresaleLema.sol)

- [LEMA Token PresaleV2](https://github.com/lemma-tron/smart-contracts/blob/develop/contracts/PresaleLemaV2.sol)
- [LEMA Token Governance](https://github.com/lemma-tron/smart-contracts/blob/develop/contracts/LemaGovernance.sol)

## To know more about Lemmatron:

- [Offical Site](https://www.lemmatron.com/)
- [Whitepaper](<https://www.lemmatron.com/assets/whitepaper/whitepaper(v2).pdf>)

## Upgradable Demo

### Understanding the process and contract state of an upgradable contract

1. truffle console
2. npm run test:initial

During this phase(deploying proxy), Initial version of upgradable contract is deployed on top of which we can later add new features.

1. npm run migrate:later
2. npm run test:later

After upgrading proxy, We can access the new features of the upgraded contract through the same old address.
