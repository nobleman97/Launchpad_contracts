// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IFactoryManager {
  //this allows us securely access this function from the tokenFactoryManager.sol
  function assignTokensToOwner(address owner, address token, uint8 tokenType) external;
}