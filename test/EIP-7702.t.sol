// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.28;

import {Vm} from "forge-std/Vm.sol";
import {Test, console2} from "forge-std/Test.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SimpleAccount} from "../src/SimpleAccount.sol";
import {Counter} from "../src/Counter.sol";

contract EIP7702Test is Test {
  using ECDSA for bytes32;
  using MessageHashUtils for bytes32;

  string constant mnemonic = "test test test test test test test test test test test junk";

  uint256 initializerKey;
  address initializer;
  uint256 aliceKey;
  address alice;
  uint256 bobKey;
  address bob;
  uint256 charlieKey;
  address charlie;

  SimpleAccount simpleAccount;
  Counter counter;

  function setUp() public {
    initializerKey = vm.deriveKey(mnemonic, 0);
    initializer = vm.addr(initializerKey);
    aliceKey = vm.deriveKey(mnemonic, 1);
    alice = vm.addr(aliceKey);
    bobKey = vm.deriveKey(mnemonic, 2);
    bob = vm.addr(bobKey);
    charlieKey = vm.deriveKey(mnemonic, 3);
    charlie = vm.addr(charlieKey);
    vm.startPrank(initializer);
    simpleAccount = new SimpleAccount();
    counter = new Counter();
    counter.setNumber(0);
    vm.stopPrank();
  }

  function test_eip7702() public {
    uint256 aliceNonce = vm.getNonce(alice);
    Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(simpleAccount), aliceKey);
    vm.broadcast(initializerKey);
    vm.attachDelegation(signedDelegation);
    vm.stopBroadcast();

    require(alice.code.length > 0, "no code written to Alice");
    assertEq(vm.getNonce(alice), aliceNonce + 1);

    bytes32 messageHash = keccak256(abi.encode(alice, "initialize", bob));
    bytes32 digest = messageHash.toEthSignedMessageHash();
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
    bytes memory signature = abi.encodePacked(r, s, v);

    // Alice asks Initializer to initialize the EIP-7702 account with Bob as the owner provided her signature
    vm.prank(initializer);
    SimpleAccount(alice).initializeWithSignature(bob, signature);

    // Alice can increment the counter as its her EOA
    vm.prank(alice);
    SimpleAccount(alice).execute(address(counter), 0, abi.encodeWithSelector(Counter.increment.selector));
    assertEq(counter.number(), 1);

    // Bob can increment the counter as he is the owner of the EIP-7702 account
    vm.prank(bob);
    SimpleAccount(alice).execute(address(counter), 0, abi.encodeWithSelector(Counter.increment.selector));
    assertEq(counter.number(), 2);

    // Charlie cannot increment the counter as he's neither the owner of the EIP-7702 account nor the EOA
    vm.prank(charlie);
    vm.expectRevert(abi.encodeWithSelector(SimpleAccount.NotOwner.selector, charlie));
    SimpleAccount(alice).execute(address(counter), 0, abi.encodeWithSelector(Counter.increment.selector));
  }
}
