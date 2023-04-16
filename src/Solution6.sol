// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/Question6.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Solution6 {
    function setImplementation(address victim) external {
        Question6(victim).setImplementation(address(this));
    }

    function transfer(address token, address to, uint256 amount) external {
        IERC20(token).transfer(to, amount);
    }
}



/** Explanation:
    
    On Question6.sol:
     This is a proxy pattern contract. 
     Uninitialised Storage Pointer: implementation is uninitialised and points address(0).
     All the functions are protected with onlyOwner modifier execept execute().

     execute() delegatecalls the implementation address passing data as the payload.  
     delegatecall: call will take place in the caller's storage context.

     On onlyOwner modifier:
     'if iszero(xor(caller(), sload(0x00))) { ... }': 
      checks whether the bitwise XOR of the caller address and the address stored in slot 0 of the contract's storage is equal to zero.
      If the caller's address MATCHES the owner storage variable, the result of the XOR operation will be zero.
      If zero, the code inside the if block is executed, thereby reverting. 
      This means that the onlyOwner modifier is working in reverse: everyone but the owner can call the protected functions.
      
    On revert(offset, size) -> revert(0x1c, 0x04):
      offset is the starting position of the desired return data in memory.
      size is the size of the desired return data in memory.
      the return data starts (offset) and ends (offset + size) in memory.
      if there is an error, 0 is returned on the stack and the returned data is served as an error message to the caller.

    On stealing tokens:
     We need to engineer a call to the token contract within its own storage context, where the msg.sender is Question6.sol. 
     This will allow for transfer of tokens.
     

 */
