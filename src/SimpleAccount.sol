// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.28;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @author Tomohiro Nakamura - <tomo@startbahn.jp>
 * @dev A smart contract wallet which is simply owned by an Ethereum address.
 */
contract SimpleAccount is Initializable {
  
  address public owner;
  
  event Execute(address indexed target, uint value, bytes data);
  event AccountInitialized(address indexed owner);

  error NotOwner(address sender);

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert NotOwner(msg.sender);
    }
    _;
  }
  
  constructor() {
  }
  
  function initialize(address _owner) public initializer {
    owner = _owner;
    emit AccountInitialized(owner);
  }
  
  /**
    * @dev Executes a transaction from this wallet
    * @param target Address to send transaction to
    * @param value Amount of ETH to send
    * @param data Transaction data payload
    * @return success Whether the transaction succeeded
    */
  function execute(address target, uint256 value, bytes calldata data)
    external
    onlyOwner
    returns (bool success)
  {
    (success, ) = target.call{value: value}(data);
    require(success, "Transaction failed");
    emit Execute(target, value, data);
    return success;
  }
}
