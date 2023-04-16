// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";
import {IERC1271} from "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";

contract Question4 {
    bytes32 public domainSeparator;

    struct SellOrder {
        address signer;
        address collection;
        uint256 id;
        uint256 price;
    }

    error InvalidTokenId();
    error NotOwner();
    error NoApproval();
    error INVALID_S_PARAMETER();
    error INVALID_V_PARAMETER();
    error NULL_SIGNER();
    error INVALID_SIGNER();

    error MISSING_VALID_SIGNATURE_FUNCTION_EIP1271();
    error SIGNATURE_INVALID_EIP1271();

    // TODO: Come up with the typehash
    bytes32 public constant SELL_ORDER_TYPEHASH = keccak256("SellOrder(address signer,address collection,uint256 id,uint256 price)");

    constructor() {
        // TODO: Come up with the domain separator
        bytes32 nameHash = keccak256(bytes("LooksRare"));
        bytes32 versionHash = keccak256(bytes("1"));

        domainSeparator = keccak256(
                abi.encode(
                    // keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    nameHash,        // name: dApp name
                    versionHash,     // version: current version number dApp
                    1,               // chainID
                    address(this)    // address of verifyingContract
                )
            );
    }

    function buy(SellOrder calldata sellOrder, uint8 v, bytes32 r, bytes32 s) external payable {
        // TODO: Execute the trade

        require(sellOrder.signer != address(0), "Order: Invalid signer");
        require(msg.value >= sellOrder.price, "Invalid value");

        // EIP-712’s standard encoding prefix is \x19\x01, so the final digest is bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, sellOrderDigest(sellOrder)));
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
            revert INVALID_S_PARAMETER();

        // v has to be 27 or 28 to be valid
        if (v != 27 && v != 28) revert INVALID_V_PARAMETER();  // This prevents maleability since the public key recovery equation has two possible solutions.

        // verify validity of sell Order as provided by the buyer
        address signer = ecrecover(digest, v, r, s);        // If the signature is valid (and not malleable), return the signer address
        if (signer == address(0)) revert NULL_SIGNER();
        if (signer != sellOrder.signer) revert INVALID_SIGNER();
      
        // send ether to seller
        (bool sent, ) = sellOrder.signer.call{value: sellOrder.price}("");
        require(sent, "sending ether failed");

        // transfer NFT to buyer
        IERC721(sellOrder.collection).safeTransferFrom(sellOrder.signer, msg.sender, sellOrder.id);
    }

    function sellOrderDigest(SellOrder calldata sellOrder) public pure returns (bytes32) {
        // TODO: Come up with the sell order digest

        // The order digest is the keccak256 hash of all the order properties set when creating an order and a constant value
        // The constant value used here is SELL_ORDER_TYPEHASH
        return keccak256(abi.encode(
            SELL_ORDER_TYPEHASH,
            sellOrder.signer,
            sellOrder.collection,
            sellOrder.id,
            sellOrder.price
            )
        );
    }

    function buy2(SellOrder calldata sellOrder, uint8 v, bytes32 r, bytes32 s) external payable {
        // TODO: Execute the trade

        require(sellOrder.signer != address(0), "Order: Invalid signer");
        require(msg.value >= sellOrder.price, "Invalid value");

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, sellOrderDigest(sellOrder)));
        
        if (Address.isContract(sellOrder.signer)) {
            
            _validateERC1271(digest,sellOrder.signer,v,r,s);
        } else{
            _validateEOA(digest, sellOrder.signer, v, r, s);
        }
      
        // send ether to seller
        (bool sent, ) = sellOrder.signer.call{value: sellOrder.price}("");
        require(sent, "sending ether failed");

        // transfer NFT to buyer
        IERC721(sellOrder.collection).safeTransferFrom(sellOrder.signer, msg.sender, sellOrder.id);
    }

    function _validateERC1271(bytes32 digest, address targetSigner, uint8 v, bytes32 r, bytes32 s) internal view {
        (bool success, bytes memory data) = targetSigner.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, abi.encodePacked(r, s, v))
        );

        if (!success) revert MISSING_VALID_SIGNATURE_FUNCTION_EIP1271();
        bytes4 magicValue = abi.decode(data, (bytes4));
        // must return the bytes4 magic value 0x1626ba7e when function passes
        if (magicValue != 0x1626ba7e) revert SIGNATURE_INVALID_EIP1271();
    }

    function _validateEOA(bytes32 digest, address targetSigner, uint8 v, bytes32 r, bytes32 s) internal pure {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert INVALID_S_PARAMETER();

        // v has to be 27 or 28 to be valid
        if (v != 27 && v != 28) revert INVALID_V_PARAMETER();  // This prevents maleability since the public key recovery equation has two possible solutions.

        // verify validity of sell Order as provided by the buyer
        address signer = ecrecover(digest, v, r, s);        // If the signature is valid (and not malleable), return the signer address
        if (signer == address(0)) revert NULL_SIGNER();
        if (signer != targetSigner) revert INVALID_SIGNER();
    } 
}



/** Explanation:

EIP-712 was aims to improve off-chain message signing. 
Currently signed messages are an opaque hex string displayed to the user with little context about the items that make up the message.
EIP-712 aims to make these hex string human readable.

An EIP-712 signature allows signers to see exactly what they are signing in a client wallet as the signed data is split into different fields and prevents the reuse of signature.
It is achieved by having a domain separator in the signature. 

A seller has to sign an EIP-712 signature of the sell order’s hash, which is stored off-chain.
Buyer will submit a taker order, which is executed on-chain.

The domainSeparator is a value unique to each domain that is ‘mixed in’ the signature.
This helps to prevent a signature meant for one dApp from working in another. 

The sellOrder hash contains all the necessary properties to be processed as a valid order, except the signature values. 
EIP-712’s standard encoding prefix is \x19\x01, so the final digest is: bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
The signature created by the seller is stored off-chain (v, r, s are the values for the transaction's signature).



Subsequently, when a prospective buyer wishes to make a purchase, he would do so with the buy function.
The buy function checks that the sellOrder struct submitted by the buyer lines up with the seller's signature that was previously stored off-chain.
ecrecover is used to verify the signature.
ecrecover is simply recovering the public key (and from there the address) used to sign the digest.

On signing and verifying using ECDSA:
- ECDSA signatures consist of two numbers (integers): r and s. Ethereum uses an additional v (recovery identifier) variable.
- r and s (ECDSA signature outputs), v (recovery identifier)

On why v is either 27 or 28:
v is important because since we are working with elliptic curves, multiple points on the curve can be calculated from r and s alone. (two points of intersection)
This would result in two different public keys (thus addresses) that can be recovered. The v simply indicates which one of these points to use.

- To create a signature you need the message to sign and the private key to sign it with
- The {r, s, v} signature can be combined into one 65-byte-long sequence: 32 bytes for r, 32 bytes for s, and one byte for v
- In order to verify a message, we need the original message, the address of the private key it was signed with, and the signature {r, s, v} itself.


Under what circumstances can v be 0/1? 
 Ethereum originally used 27 & 2 - following bitcoin.
 Later when chain IDs had ot be supported in signatures, the v changed to {0,1} + CHAIN_ID * 2 + 35, as per EIP155. 
 However, both V's are still supported on mainnet.

 The current logic is that the low-level crypto operations returns 0/1, and the higher level signers convert that v to whatever Ethereum specs on top of secp256k1
 Specifically, go-ethereum's secp256k1.Sign function has v with 0 / 1

TL;DR:
 Use the high level signers, don't use the secp256k1 library directly. 
 If you use the low level crypto library directly, you need to be aware of how generic ECC relates to Ethereum signatures.

*/
