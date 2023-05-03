// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract Random {
    /* STORAGE */

    uint256 private _seed = 0;

    /* INTERNAL */

    function randomBytes32() internal returns (bytes32) {
        return keccak256(abi.encode(_seed++));
    }

    function randomUint256() internal returns (uint256) {
        return uint256(randomBytes32());
    }

    function randomUint256(uint256 range) internal returns (uint256) {
        return randomUint256() % range;
    }

    function randomAddress() internal returns (address) {
        return address(bytes20(randomBytes32()));
    }
}
