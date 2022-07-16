// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Contract.sol";

contract ContractTest is Test {
    TestSwap c ;

    function setUp() public {
        c = new TestSwap();
    }

    function testExample() public {
        uint256 amountIn=719650005876952115146;
        uint256 amountOut=47788554279;
        
        address trader=0x9A315BdF513367C0377FB36545857d12e85813Ef;
        vm.startPrank(trader);  

        IERC20 erc20 = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        erc20.approve(trader,amountIn);
        erc20.approve(vaultAddress,amountIn);

        IVault vault = IVault(vaultAddress);

        SingleSwap memory singleSwap = SingleSwap(
          0xc45d42f801105e861e86658648e3678ad7aa70f900010000000000000000011e,
          SwapKind.GIVEN_IN,
          IAsset(0x6B175474E89094C44Da98b954EedeAC495271d0F),
          IAsset(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5),
          amountIn,
          '0x'
        );

        FundManagement memory funds = FundManagement(
            trader,
            false,
            payable(trader),
            false
        );  

        //block = 15147341
        console.log("Block Timestamp",block.timestamp);
        console.log("Block Number",block.number);
        uint256 amountOutReal= vault.swap(singleSwap,funds,1,block.timestamp+10000);
        vm.stopPrank();
        console.log("amountOutReal", amountOutReal);
        console.log("amountOut Comptued", amountOut);
        console.log("amountOut Diff", amountOutReal-amountOut);
        assertTrue(amountOutReal-amountOut==0);
    }

}
