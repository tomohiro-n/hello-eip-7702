# Hello EIP-7702

Experimenting with [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702).

`src/SimpleAccount.sol` is a simple smart contract wallet implementation.\
`test/SimpleAccount.t.sol` is a test for using the wallet regularly, not using EIP-7702.\
`test/EIP-7702.t.sol` is a test for the EIP-7702 usage of the wallet. Foundry already has a cheatcode [signDelegation](https://book.getfoundry.sh/cheatcodes/sign-delegation) to sign EIP-7702 authorization.\
`script/SignDelegation.s.sol` is a script to do more or less the same thing as `test/EIP-7702.t.sol` but using a script. You can confirm the transaction fee is paid by `tx.origin` not `msg.sender`.

When `SimpleAccount` is set to be an EIP-7702 account, both the EOA and `owner` set in `initialize` or `initializeWithSignature` function can execute transactions.
We can achieve privilege de-escalation described in [the EIP doc](https://eips.ethereum.org/EIPS/eip-7702) by extending the initialization logic or adding other functions to modify permissions.

## How to run

```bash
anvil --hardfork prague
forge script script/SignDelegation.s.sol --rpc-url http://localhost:8545 --broadcast -g 1000 # Somehow the gas was estimated lower than actual, the last tx fails with OutOfGas error if -g option is not specified
```