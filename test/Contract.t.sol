// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Contract.sol";
import "../src/LogExpMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


contract ContractTest is Test {
    TestSwap c ;
    uint256 ONE=1e18;
    uint256 TWO = 2 * ONE;
    uint256 FOUR = 4 * ONE;
    uint256 MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function setUp() public {
        c = new TestSwap();
    }

   function _computeScalingFactor(address token) internal view returns (uint256) {

        // Tokens that don't implement the `decimals` method are not supported.
        uint256 tokenDecimals = ERC20(token).decimals();

        // Tokens with more than 18 decimals are not supported.
        uint256 decimalsDifference = 18- tokenDecimals;
        return ONE * 10**decimalsDifference;
    }

    function _upscale(uint256 amount, uint256 scalingFactor) internal view returns (uint256) {
        // Upscale rounding wouldn't necessarily always go in the same direction: in a swap for example the balance of
        // token in should be rounded up, and that of token out rounded down. This is the only place where we round in
        // the same direction for all amounts, as the impact of this rounding is expected to be minimal (and there's no
        // rounding error unless `_scalingFactor()` is overriden).
        return mulDown(amount, scalingFactor);
    }

    function mulDown(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 product = a * b;

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((product - 1) / ONE) + 1;
        }
    }

    function divDown(uint256 a, uint256 b) internal view returns (uint256) {

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b) internal view returns (uint256) {

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((aInflated - 1) / b) + 1;
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal view returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulDown(x, x);
        } else if (y == FOUR) {
            uint256 square = mulDown(x, x);
            return mulDown(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR)+ 1;

            if (raw < maxError) {
                return 0;
            } else {
                return raw- maxError;
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal view returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulUp(x, x);
        } else if (y == FOUR) {
            uint256 square = mulUp(x, x);
            return mulUp(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) +1;

            return raw+ maxError;
        }
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal view returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }


    function computeBalv(uint256 amount, uint256 swapFeePercentage, uint256 reserveIn,uint256 reserveOut, uint256 weightIn, uint256 weightOut) public returns (uint256) {
        console.log("reserveIn", reserveIn);
        console.log("reserveOut",reserveOut);
        console.log("reserveIn - _upscale",_upscale(reserveIn,_computeScalingFactor(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942)));
        console.log("reserveOut - _upscale",_upscale(reserveOut,_computeScalingFactor(0x3845badAde8e6dFF049820680d1F14bD3903a5d0)));
        console.log("weightIn",weightIn);
        console.log("weightOut",weightOut);
        console.log("amount",amount);
        uint256 feeAmount = mulUp(amount, swapFeePercentage);
        console.log("feeAmount",feeAmount);
	    amount = amount - feeAmount;
        console.log("amount post fee",amount);
        uint256 denominator = reserveIn + amount;
        uint256 base = divUp(reserveIn, denominator);
        uint256 exponent = divDown(weightIn,weightOut);
        uint256 power = powUp(base, exponent);
        uint256 c = complement(power);
        uint256 result = mulDown(reserveOut,c);
        /*uint256 denominator=reserveIn + amount;
        uint256 base = (ONE*reserveIn)/denominator;
        uint256 exponent = weightIn/weightOut;
        uint256 power = (base)**(exponent);
        uint256 complement = ONE-power;
        uint256 result =  reserveOut * complement;*/
        console.log("denominator",denominator);
        console.log("base",base);
        console.log("exponent",exponent);
        console.log("power",power);
        console.log("complement",c);
        console.log("result",result);
        return result;
    }

    function testExample() public {
        uint256 amountIn=9252920066807548690510;
        uint256 amountOutExpected=6825578890111445640730;
        
        address trader=0xe1498a9Ef5c6Aa51790a642F70c31238326b1724;
        vm.startPrank(trader);  

        address assetIn = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;
        IERC201 erc20 = IERC201(assetIn);
        //erc20.approve(trader,100000);
        //15258983
        erc20.approve(vaultAddress,amountIn);

        IVault vault = IVault(vaultAddress);

        SingleSwap memory singleSwap = SingleSwap(
          0x5757b37098d65b097cbcb78e22ae862817a827020001000000000000000002d2,
          SwapKind.GIVEN_IN,
          IAsset(assetIn),
          IAsset(0x3845badAde8e6dFF049820680d1F14bD3903a5d0),
          amountIn,
          '0x'
        );

        FundManagement memory funds = FundManagement(
            trader,
            false,
            payable(trader),
            false
        );
        amountIn=_upscale(amountIn,_computeScalingFactor(assetIn));
        uint256 recomputed = computeBalv(amountIn,5000000000000000, 244922562514107359335879,188404902510508590493405, 200000000000000000, 200000000000000000);

        console.log("B TS",block.timestamp);
        console.log("B NB",block.number);
        uint256 amountOutReal= vault.swap(singleSwap,funds,1,block.timestamp+10000);
        vm.stopPrank();
        console.log("amountOutReal", amountOutReal);
        console.log("amountOutExpected", amountOutExpected);
        console.log("recomputed", recomputed);
        console.log("Diff", amountOutExpected-amountOutReal);
        assertTrue(amountOutReal>0);
    }

}
