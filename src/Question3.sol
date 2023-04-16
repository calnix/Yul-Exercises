// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Question3 {
    mapping(uint256 => address) private ownerOf;

    constructor() {
        ownerOf[0] = address(1);
        ownerOf[1] = address(2);
        ownerOf[2] = address(3);
        ownerOf[3] = address(4);
        ownerOf[4] = address(5);
    }

    function readOwnerOf(uint256 tokenId) external view returns (address) {
        // TODO: Read the mapping value without calling ownerOf[tokenId]
        
        uint256 slot;
        address ret;

        // get storage slot of mapping
        assembly {
            slot := ownerOf.slot
        }
        
        // get location of element
        bytes32 location = keccak256(abi.encode(tokenId, uint256(slot)));

        // load element
        assembly {
            ret := sload(location)
        }

        return ret;
    }
}

/** Explanation:

The mapping ownerOf is assigned to storage slot 0.

However, elements contained a the mapping are stored at a different storage slot.
The storage slot of such an element is computed using a Keccak-256 hash of the key and storage slot of the mapping.
After obtaining the storage location of the element, we load the data stored in that position by using sload.

*/ 

