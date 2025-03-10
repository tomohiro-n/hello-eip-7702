// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @author Tomohiro Nakamura - <tomo@startbahn.jp>
 * @dev A smart contract wallet which is simply owned by an Ethereum address.
 */
contract SimpleAccount is Initializable {
  address public owner;

  event Execute(address indexed target, uint256 value, bytes data);
  event AccountInitialized(address indexed owner);

  error NotOwner(address sender);
  error InvalidSignature();
  error UnauthorizedInitialization();

  modifier onlyOwner() {
    if (msg.sender != owner && msg.sender != address(this)) {
      revert NotOwner(msg.sender);
    }
    _;
  }

  constructor() {}

  /**
   * @dev Initializes the account with an owner
   * @param _owner Address that will own this account
   *
   * This function can only be called in two scenarios:
   * 1. During contract deployment (when this contract is not an EIP-7702 account)
   * 2. When the caller is the intended owner (self-initialization)
   */
  function initialize(address _owner) public initializer {
    // For usecase 1: Regular deployment - anyone can initialize
    // For usecase 2: EIP-7702 - only the intended owner can initialize themselves
    if (address(this) == _owner || tx.origin == msg.sender) {
      owner = _owner;
      emit AccountInitialized(owner);
    } else {
      // Prevent Bob from setting Alice as owner without her signature
      revert UnauthorizedInitialization();
    }
  }

  /**
   * @dev Initializes the account with an owner using a signature (for EIP-7702)
   * @param _owner Address that will own this account
   * @param signature Signature from the owner authorizing this initialization
   */
  function initializeWithSignature(address _owner, bytes calldata signature) public initializer {
    // Create the message hash in the same way as the test
    bytes32 messageHash = keccak256(abi.encode(address(this), "initialize", _owner));

    // Convert to an Ethereum signed message hash
    bytes32 digest = MessageHashUtils.toEthSignedMessageHash(messageHash);

    // Recover the signer from the signature
    address signer = ECDSA.recover(digest, signature);

    if (signer != address(this)) {
      revert InvalidSignature();
    }

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
  function execute(address target, uint256 value, bytes calldata data) external onlyOwner returns (bool success) {
    (success,) = target.call{value: value}(data);
    require(success, "Transaction failed");
    emit Execute(target, value, data);
    return success;
  }
}
