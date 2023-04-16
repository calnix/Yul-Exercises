// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Question6 {
    address public owner;
    address public implementation;

    bytes4 private constant NotOwner_error_selector = 0x30cd7471;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        assembly {
            if iszero(xor(caller(), sload(0x00))) {
                mstore(0x00, NotOwner_error_selector)
                revert(0x1c, 0x04)
            }
        }
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setImplementation(address _implementation) external onlyOwner {
        implementation = _implementation;
    }

    function execute(bytes calldata data) external {
        (bool success,) = implementation.delegatecall(data);
        require(success, "Execution failed");
    }
}
