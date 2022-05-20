// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IFactoryManager.sol";


contract TokenFactoryBase is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address payable;

  /**
  *@dev this contract is meant for the admin alone to interact with
  * Note: until the transferOwnership(address newOwner) fn is called, the admin is the address
  * that deployed the contract.
  *
  * Here is where all the rules for token creation are set 
  */

  address public factoryManager;
  address public implementation;
  address public feeTo;
  uint256 public flatFee;

  event TokenCreated(
    address indexed owner,
    address indexed token,
    uint8 tokenType
  );

  modifier enoughFee() {
    require(msg.value >= flatFee, "Flat fee");
    _;
  }

  /**
  * @dev The implementation will be address of the type of token we want to clone during
  * the creation of the token of choice
  *
  * @dev In this instance, our "factoryManager_" will be
  * the address of the deployed TokenFactoryManager.sol contract
   */
  constructor(address factoryManager_, address implementation_) {
    factoryManager = factoryManager_;
    implementation = implementation_;
    feeTo = msg.sender;
    flatFee = 10_000_000 gwei;
  }

  //this is used to change the implementation from what was initially set
  function setImplementation(address implementation_) external onlyOwner {
    implementation = implementation_;
  }

  /**
  *@dev this is where we set the address that will receive the fees paid for token creation
  * Note: It was set in constructor, and only the admin (the deployer of this contract) can change this
   */
  function setFeeTo(address feeReceivingAddress) external onlyOwner {
    feeTo = feeReceivingAddress;
  }

  /**
  *@dev this is the function that allows us change the fee charged for token creation
  * Note: initial value set in constructor was 10_000_000 gwei
   */
  function setFlatFee(uint256 fee) external onlyOwner {
    flatFee = fee;
  }

  /**
  *@dev this function allows us assign created tokens to the creator,
  *and  record the event in the Factory Manager
   */
  function assignTokenToOwner(address owner, address token, uint8 tokenType) internal {
    IFactoryManager(factoryManager).assignTokensToOwner(owner, token, tokenType);
  }

  /**
  *@dev this function is called during token creation. It returns the excess
  * of the fees paid for token creation (i.e excess of flatFee)
   */
  function refundExcessiveFee() internal {
    uint256 refund = msg.value.sub(flatFee);
    if (refund > 0) {
      payable(msg.sender).sendValue(refund);
    }
  }
}
