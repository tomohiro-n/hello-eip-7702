// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.28;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {Vm} from "forge-std/Vm.sol";
import {Script} from "forge-std/Script.sol";
import {SimpleAccount} from "../src/SimpleAccount.sol";
import {Counter} from "../src/Counter.sol";

contract SignDelegationScript is Script {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;

  address payable ALICE_ADDRESS = payable(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
  uint256 constant ALICE_PK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

  address constant BOB_ADDRESS = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
  uint256 constant BOB_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

  address private constant INITIALIZER_ADDRESS = payable(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
  uint256 private constant INITIALIZER_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

  function run() external {
    vm.startBroadcast(INITIALIZER_PK);
    SimpleAccount simpleAccount = new SimpleAccount();
    Counter counter = new Counter();
    counter.setNumber(0);
    Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(simpleAccount), ALICE_PK);
    vm.attachDelegation(signedDelegation);

    bytes32 messageHash = keccak256(abi.encode(ALICE_ADDRESS, "initialize", BOB_ADDRESS));
    bytes32 digest = messageHash.toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE_PK, digest);
    bytes memory signature = abi.encodePacked(r, s, v);
    SimpleAccount(ALICE_ADDRESS).initializeWithSignature(BOB_ADDRESS, signature);
    vm.stopBroadcast();
    vm.broadcast(BOB_PK);
    SimpleAccount(ALICE_ADDRESS).execute(address(counter), 0, abi.encodeWithSelector(Counter.increment.selector));
  }
}
