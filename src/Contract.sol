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

    function trade() public returns (uint256) {

        IERC20 erc20 = IERC20(0x41e5560054824eA6B0732E656E3Ad64E20e94E45);
        erc20.approve(vaultAddress,100000);

        IVault vault = IVault(vaultAddress);

        SingleSwap memory s = SingleSwap(
          0x760afd4460089edbb77f71149f6fe1d7554c545000010000000000000000011d,
          SwapKind.GIVEN_IN,
          IAsset(0x41e5560054824eA6B0732E656E3Ad64E20e94E45),
          IAsset(0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD),
          100000,
          '0x'
        );

        FundManagement memory f = FundManagement(
            address(this),
            false,
            payable(address(this)),
            false
        );

        return vault.swap(s,f,100000,block.timestamp+10000);
    }

}
