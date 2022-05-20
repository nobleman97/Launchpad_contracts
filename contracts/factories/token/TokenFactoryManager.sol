// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../interfaces/IFactoryManager.sol";

contract TokenFactoryManager is Ownable, IFactoryManager {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct Token {
    uint8 tokenType;
    address tokenAddress;
  }

  //a structure that keeps track of all Whitelisted factories
  EnumerableSet.AddressSet private tokenFactories;

  //"tokensOf" will keep track of the tokens a particular address
  mapping(address => Token[]) private tokensOf;
  mapping(address => mapping(address => bool)) private hasToken;
  mapping(address => bool) private isGenerated;

  modifier onlyAllowedFactory() {
    require(tokenFactories.contains(msg.sender), "Not a whitelisted factory");
    _;
  }

  //"whitelists" a Token factory (e.g tokenFactoryBase)
  function addTokenFactory(address factory) public onlyOwner {
    tokenFactories.add(factory);
  }

  //"whitelists" multiple token factories
  function addTokenFactories(address[] memory factories) external onlyOwner {
    for (uint256 i = 0; i < factories.length; i++) {
      addTokenFactory(factories[i]);
    }
  }

  //removes a toke factory from the 'whitelist'
  function removeTokenFactory(address factory) external onlyOwner {
    tokenFactories.remove(factory);
  }

  //when called, this function assigns tokens to teh creator of the tokens
  function assignTokensToOwner(address owner, address token, uint8 tokenType)
    external override onlyAllowedFactory {
    //Ensure that the owner does not already have the token we want
    //to assign to him
    require(!hasToken[owner][token], "Token already exists");

    //add the new token to the tokens he owns
    tokensOf[owner].push(Token(tokenType, token));

    //set these statuses as true
    hasToken[owner][token] = true;
    isGenerated[token] = true;
  }

  //this returns a list of factories that are allowed to call
  //functions marked "onlyAllowedFactory"
  function getAllowedFactories() public view returns (address[] memory) {
    uint256 length = tokenFactories.length();
    address[] memory factories = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      factories[i] = tokenFactories.at(i);
    }
    return factories;
  }

  //to check if token of the address passed in was enerated here
  function isTokenGenerated(address token) external view returns (bool) {
    return isGenerated[token];
  }

  //get info about specific token among those held by a certain token creator(a person)
  function getToken(address owner, uint256 index) external view returns (address, uint8) {
    //if the index entered is greater than the number of tokens the person owns,
    //return zeros
    if (index > tokensOf[owner].length) {
      return (address(0), 0);
    }

    //else if a correct position number was entered,
    //return the token address and token type
    return (tokensOf[owner][index].tokenAddress, uint8(tokensOf[owner][index].tokenType));
  }

  //this allows us get all the tokens(addresses and types) that belong to any creator
  function getAllTokens(address owner) external view returns (address[] memory, uint8[] memory) {
    uint256 length = tokensOf[owner].length;
    address[] memory tokenAddresses = new address[](length);
    uint8[] memory tokenTypes = new uint8[](length);
    for (uint256 i = 0; i < length; i++) {
      tokenAddresses[i] = tokensOf[owner][i].tokenAddress;
      tokenTypes[i] = uint8(tokensOf[owner][i].tokenType);
    }
    return (tokenAddresses, tokenTypes);
  }

  //
  function getTokensForType(address owner, uint8 tokenType) external view returns (address[] memory) {
    uint256 length = 0;

    //go through all the tokens the address(user) has,
    //at each index, if the token type is the desired one,
    //increase count of length
    for (uint256 i = 0; i < tokensOf[owner].length; i++) {
      if (tokensOf[owner][i].tokenType == tokenType) {
        length++;
      }
    }

    address[] memory tokenAddresses = new address[](length);

    //if none of the token he owns if of the desired type, return an empty array
    if (length == 0) {
      return tokenAddresses;
    }

    uint256 currentIndex;

    //go through all the coins this user has, take note of
    //the addresses of the coins of desired type. Return an array of all the token addresses
    for (uint256 i = 0; i < tokensOf[owner].length; i++) {
      if (tokensOf[owner][i].tokenType == tokenType) {
        tokenAddresses[currentIndex] = tokensOf[owner][i].tokenAddress;
        currentIndex++;
      }
    }

    return tokenAddresses;
  }
}