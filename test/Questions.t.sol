// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {FungibleToken} from "./FungibleToken.sol";
import {NFT} from "./NFT.sol";

import "../src/Question1.sol";
import "../src/Question2.sol";
import "../src/Question3.sol";
import "../src/Question4.sol";
import "../src/Question5.sol";
import "../src/Question6.sol";

import "../src/Solution5.sol";
import "../src/Solution6.sol";

contract QuestionsTest is Test {
    function testQuestion1() public {
        Question1 question1 = new Question1();

        uint256[] memory array = new uint256[](5);
        array[0] = 1;
        array[1] = 2;
        array[2] = 3;
        array[3] = 4;
        array[4] = 5;

        uint256 sum = question1.iterateEachElementInArrayAndReturnTheSum(array);
        assertEq(sum, 15);
    }

    function testQuestion2() public {
        Question2 question2 = new Question2();
        assertEq(question2.readStateVariable(), 55);
    }

    function testQuestion3() public {
        Question3 question3 = new Question3();
        assertEq(question3.readOwnerOf(0), address(1));
        assertEq(question3.readOwnerOf(1), address(2));
        assertEq(question3.readOwnerOf(2), address(3));
        assertEq(question3.readOwnerOf(3), address(4));
        assertEq(question3.readOwnerOf(4), address(5));
    }

    function testQuestion4() public {
        Question4 question4 = new Question4();

        uint256 sellerPrivateKey = 0xA11CE;
        address seller = vm.addr(sellerPrivateKey);

        NFT nft = new NFT();
        uint256 id = 42;
        nft.mint(seller, id);

        Question4.SellOrder memory sellOrder = Question4.SellOrder({
            signer: seller,
            collection: address(nft),
            id: id,
            price: 1 ether
        });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sellerPrivateKey,
            keccak256(abi.encodePacked("\x19\x01", question4.domainSeparator(), question4.sellOrderDigest(sellOrder)))
        );

        vm.prank(seller);
        nft.setApprovalForAll(address(question4), true);

        address buyer = address(888);
        vm.prank(buyer);
        vm.deal(buyer, sellOrder.price);

        question4.buy{value: sellOrder.price}(sellOrder, v, r, s);

        assertEq(nft.ownerOf(id), buyer);

        assertEq(buyer.balance, 0);
        assertEq(seller.balance, 1 ether);
    }

    function testQuestion5() public {
        Question5 question5 = new Question5();

        address victim = address(1);

        vm.deal(victim, 1 ether);
        vm.prank(victim);
        question5.deposit{value: 1 ether}();

        Solution5 thief = new Solution5(address(question5));
        // TODO: Steal the victim's money

        vm.deal(address(thief), 1 ether);
        thief.deposit(1 ether);
        thief.attack();

        // Verify end state
        assertEq(address(thief).balance, 2 ether);
        assertEq(address(question5).balance, 0);
        assertEq(question5.balanceOf(victim), 1 ether);
    }

    function testQuestion6() public {
        Question6 question6 = new Question6();
        FungibleToken erc20 = new FungibleToken();
        erc20.mint(address(question6), 1 ether);

        Solution6 thief = new Solution6();

        // TODO: Steal the contract's ERC20 tokens and explain how you do it
       
        //Note: activate a specific scenario by uncommenting it

        //... Scenario 1 ...
        //thief.scenario1(); 

        //...Scenario 2 ...
        //thief.scenario2();
        //question6.execute("");
        thief.setImplementation(address(question6));
        question6.execute(abi.encodeWithSignature("transfer(address,address,uint256)", address(erc20), address(thief), 1 ether));

        assertEq(erc20.balanceOf(address(thief)), 1 ether);
    }

    function testQuestion7() public {
        uint256 a = 10_000;
        uint256 b = 8_000;
        uint256 c = 9_000;

        // TODO: Explain why the 2 values are not equal
        assertGt(a * b / c, a / c * b);

        /** Explanation:

            Scenario 1: (a * b) / c -> 8888
            Scenario 2: (a / c) * b -> 8000

            In Solidity, division rounds towards zero.
            In scenario 2, (a / c) = 1.111 (recurring decimal), is rounded to 1.
            Therefore, (a / c) * b = 1 * 8000 = 8000

            Whereas in scenario 1, no rounding occured due to the order of operations:
            (a * b) / c = 80,000,000 / 9000 = 8888
            
        */
    }

    function testQuestion8() public {
        bool a = false;
        bool b = true;

        uint256 startingGas = gasleft();
        if (a && b) {
            // Do nothing
        }
        uint256 gasSpent = startingGas - gasleft();

        uint256 startingGas2 = gasleft();
        if (a) {
            if (b) {
                // Do nothing
            }
        }
        uint256 gasSpent2 = startingGas2 - gasleft();

        // TODO: Explain why one spents more gas than the other
        assertGt(gasSpent, gasSpent2);

        /** Explanation:

         gasSpent is more than gasSpent2 because the second if statement in the second block of code is a nested if statement.

         Since the first condition equates to false (a == false), then the second condition in the nested if loop will not be evaluated.
         Therefore, gas spent in executing the nested if statement will be less compared to the first block of code.    

         In the first block of code, both conditions are evaluated simultaneously. 
         Even though the condition 'a' is false, the condition 'b' is still evaluated, resulting in a higher gas cost.
       
        */
    }
}
