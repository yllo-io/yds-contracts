# YDS Contracts

This is YDS launchpad contracts repo 😉

## About Launchpad

### Trade contract

`Trade.sol` is trade contract implementation. This contract is buying/selling tokens and storing all market founds.

### XRC20

This is ERC20 based token. `Mint` & `Burn` methods are available to be called by trade contract only (via `TradeProxy.sol`)

## How to run tests

- `npm ci`
- `npx hardhat compile`
- `npx hardhat test`
