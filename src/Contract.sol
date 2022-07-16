// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;


interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

enum SwapKind { GIVEN_IN, GIVEN_OUT }
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}
struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
}

struct SwapRequest {
        SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }


struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}    

interface IVault {
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

}

address constant vaultAddress = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

contract TestSwap {
    address internal owner;


    constructor(){
        owner = msg.sender;
    }

}
