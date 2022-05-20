// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TokenFactoryBase.sol";
import "../../interfaces/IStandardERC20.sol";

contract StandardTokenFactory is TokenFactoryBase {
  using Address for address payable;
  using SafeMath for uint256;

  //Implementation refers to the contract that we want this factory to clone/copy
  //In this case, it would be a Standard token (../tokens/StandardToken.sol) that was previously deployed.
  constructor(address factoryManager_, address implementation_) TokenFactoryBase(factoryManager_, implementation_) {}

  //Create a new token using the name, symbol, decimals and totalSupply passed in
  //Modifiers: ensure that the sender provided enough fee from the TokeFactoryBase.sol side
  function create(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply)
  external payable enoughFee nonReentrant returns (address token) {

    //first refund excess fee, if any
    refundExcessiveFee();

    //pay the flatFee to the Factory owner as specified in the
    //TokenFactoryBase.sol contract
    payable(feeTo).sendValue(flatFee);

    //create a clone of the "implementation"... I don't know what that is yet
    //the "token" variable is an address for the new token contract
    token = Clones.clone(implementation);

    //using the interface of a StandardERC20 (i.e IStandardERC20),
    //set the owner of the new token to be the person who called it
    //and also set the other parameters accordingly
    IStandardERC20(token).initialize(msg.sender, name, symbol, decimals, totalSupply);

    //assign Ownership of the new tokens to its creator
    assignTokenToOwner(msg.sender, token, 0);

    //emit an event stating the owner, token address and type of token
    // '0' stands for Fungible tokens.
    emit TokenCreated(msg.sender, token, 0);
  }
}