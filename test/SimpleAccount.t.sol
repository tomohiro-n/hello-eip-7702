// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { SimpleAccount } from "../src/SimpleAccount.sol";
import { Counter } from "../src/Counter.sol";
contract SimpleAccountTest is Test {

  string constant mnemonic = "test test test test test test test test test test test junk";

  uint256 signerKey;
  address signer;
  uint256 ownerKey;
  address owner;

  SimpleAccount simpleAccount;
  Counter counter;
  
  function setUp() public {
    signerKey = vm.deriveKey(mnemonic, 0);
    signer = vm.addr(signerKey);
    ownerKey = vm.deriveKey(mnemonic, 1);
    owner = vm.addr(ownerKey);
    vm.startBroadcast();(signer);
    simpleAccount = new SimpleAccount();
    simpleAccount.initialize(owner);
    vm.stopBroadcast();
  }
  
  function test_executeNotByOwner() public {
    vm.startPrank(signer);
    vm.expectRevert(abi.encodeWithSelector(SimpleAccount.NotOwner.selector, signer));
    simpleAccount.execute(address(0), 0, abi.encodeWithSelector(SimpleAccount.NotOwner.selector, signer));
    vm.stopPrank();
  }

  function test_execute() public {
    counter = new Counter();
    counter.setNumber(0);
    vm.startPrank(owner);
    simpleAccount.execute(address(counter), 0, abi.encodeWithSelector(Counter.increment.selector));
    vm.stopPrank();
    assertEq(counter.number(), 1);
  }
}
