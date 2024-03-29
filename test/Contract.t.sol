// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Contract.sol";
//import "../src/LogExpMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";



contract ContractTest is Test {
    TestSwap c;
    uint256 ONE = 1e18;
    uint256 TWO = 2 * ONE;
    uint256 FOUR = 4 * ONE;
    uint256 MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    address ASSET_IN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address ASSET_OUT = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    bytes32 POOL_ID = 0xd4e2af4507b6b89333441c0c398edffb40f86f4d0001000000000000000002ab;
    address POOL_ADDRESS = 0xd4E2af4507B6B89333441C0c398edfFB40f86f4D;
    address TRADER = 0x06920C9fC643De77B99cB7670A944AD31eaAA260;
    uint256 RESERVE_IN =51631307241259069889;
    uint256 RESERVE_OUT=410893919;
    uint256 AMOUNT_IN = 5000000000000000000;
    uint256 amountOutExpected = 361787316415099392;

    

    function setUp() public {
        c = new TestSwap();
    }

    function _computeScalingFactor(address token)
        
        public
        returns (uint256)
    {
        // Tokens that don't implement the `decimals` method are not supported.
        uint256 tokenDecimals = ERC20(token).decimals();

        // Tokens with more than 18 decimals are not supported.
        uint256 decimalsDifference = 18 - tokenDecimals;
        return 10**decimalsDifference;
    }

    function _upscale(uint256 amount, uint256 scalingFactor)
        
        public
        returns (uint256)
    {
        // Upscale rounding wouldn't necessarily always go in the same direction: in a swap for example the balance of
        // token in should be rounded up, and that of token out rounded down. This is the only place where we round in
        // the same direction for all amounts, as the impact of this rounding is expected to be minimal (and there's no
        // rounding error unless `_scalingFactor()` is overriden).
        return  amount* scalingFactor;
    }

    function _downscale(uint256 amount, uint256 scalingFactor)
        
        public
        returns (uint256)
    {
        // Upscale rounding wouldn't necessarily always go in the same direction: in a swap for example the balance of
        // token in should be rounded up, and that of token out rounded down. This is the only place where we round in
        // the same direction for all amounts, as the impact of this rounding is expected to be minimal (and there's no
        // rounding error unless `_scalingFactor()` is overriden).
        return amount/ scalingFactor;
    }

    function mulDown(uint256 a, uint256 b)  public returns (uint256) {
        uint256 product = a * b;

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b)  public returns (uint256) {
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

    function divDown(uint256 a, uint256 b)  public returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;

            return aInflated / b;
        }
    }

    function divUp(uint256 a, uint256 b)  public returns (uint256) {
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

    function powDown(uint256 x, uint256 y)  public returns (uint256) {
        uint256 raw = pow(x, y);
        uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR)+ 1;

        if (raw < maxError) {
            return 0;
        } else {
            return raw- maxError;
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDownOld(uint256 x, uint256 y)  public returns (uint256) {
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
            uint256 raw = pow(x, y);
            uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;

            if (raw < maxError) {
                return 0;
            } else {
                return raw - maxError;
            }
        }
    }


   function powUp(uint256 x, uint256 y)  public returns (uint256) {
        uint256 raw = pow(x, y);
        console.log("RAW",raw);
        uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) +1;
        console.log("maxError",maxError);
        uint256 r=raw+ maxError;
        console.log("r",r);

        return r;
    }
    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUpOld(uint256 x, uint256 y)  public returns (uint256) {
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
            uint256 raw = pow(x, y);
            uint256 maxError = mulUp(raw, MAX_POW_RELATIVE_ERROR) + 1;

            return raw + maxError;
        }
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x)  public returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }

    function computeBalv(
        uint256 amount,
        uint256 swapFeePercentage,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 weightIn,
        uint256 weightOut
    ) public returns (uint256) {
        console.log("reserveIn", reserveIn);
        console.log("reserveOut", reserveOut);
        /*console.log(
            "reserveIn - _upscale",
            _upscale(
                reserveIn,
                _computeScalingFactor(
                    0x0F5D2fB29fb7d3CFeE444a200298f468908cC942
                )
            )
        );
        console.log(
            "reserveOut - _upscale",
            _upscale(
                reserveOut,
                _computeScalingFactor(
                    0x3845badAde8e6dFF049820680d1F14bD3903a5d0
                )
            )
        );*/
        console.log("weightIn", weightIn);
        console.log("weightOut", weightOut);
        console.log("amount", amount);
        uint256 feeAmount = mulUp(amount, swapFeePercentage);
        console.log("feeAmount", feeAmount);
        amount = amount - feeAmount;
        console.log("amount post fee", amount);
        amount = _upscale(amount, _computeScalingFactor(ASSET_IN));
        console.log("amount post upscale", amount);
        uint256 denominator = reserveIn + amount;
        uint256 base = divUp(reserveIn, denominator);
        uint256 exponent = divDown(weightIn, weightOut);
        uint256 power = powUp(base, exponent);
        uint256 c = complement(power);
        uint256 result = mulDown(reserveOut, c);
        /*uint256 denominator=reserveIn + amount;
        uint256 base = (ONE*reserveIn)/denominator;
        uint256 exponent = weightIn/weightOut;
        uint256 power = (base)**(exponent);
        uint256 complement = ONE-power;
        uint256 result =  reserveOut * complement;*/
        console.log("denominator", denominator);
        console.log("base", base);
        console.log("exponent", exponent);
        console.log("power", power);
        console.log("complement", c);
        console.log("result", result);
        return result;
    }

    function _calcOutGivenIn(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn
    )  public returns (uint256) {
        /**********************************************************************************************
        // outGivenIn                                                                                //
        // aO = amountOut                                                                            //
        // bO = balanceOut                                                                           //
        // bI = balanceIn              /      /            bI             \    (wI / wO) \           //
        // aI = amountIn    aO = bO * |  1 - | --------------------------  | ^            |          //
        // wI = weightIn               \      \       ( bI + aI )         /              /           //
        // wO = weightOut                                                                            //
        **********************************************************************************************/

        // Amount out, so we round down overall.

        // The multiplication rounds down, and the subtrahend (power) rounds up (so the base rounds up too).
        // Because bI / (bI + aI) <= 1, the exponent rounds down.

        // Cannot exceed maximum in ratio

        uint256 denominator = balanceIn +amountIn;
        console.log("denominator", denominator);
        uint256 base = divUp(balanceIn,denominator);
        console.log("base", base);
        uint256 exponent = divDown(weightIn,weightOut);
        console.log("exponent", exponent);
        uint256 power = powUp(base,exponent);
        console.log("power", power);
        uint256 c=complement(power);
        console.log("c", c);
        return mulDown(balanceOut,c);
    }

    function getBalanceAndManaged(IVault vault, bytes32 POOL_ID, address targetAddress) public  returns (uint256) {
        address[] memory a;
        uint256[] memory b;
        uint256 c;
        console.log("START");
        (a, b, c) = vault.getPoolTokens(POOL_ID);
        uint256 cash;
        uint256 managed;
        uint256 lastChangeBlock;
        address assetManager;
        for (uint i=0; i<a.length;i++){
            (cash, managed, lastChangeBlock, assetManager) = vault.getPoolTokenInfo(POOL_ID, IERC201(a[i]));
            //console.log(cash);
            if(a[i] == targetAddress){
                console.log("cash",cash);
                console.log("managed",managed);
                console.log("b",b[i]);
                return b[i];
            }
        }
        console.log("END");
    }

    function testOutGivenIn() public{
        IGeneralPool pool = IGeneralPool(POOL_ADDRESS);
        uint256 swapFeePercentage = pool.getSwapFeePercentage();

        uint256 amountInit = AMOUNT_IN;
        uint256 feeAmount = mulUp(amountInit, swapFeePercentage);
        console.log("feeAmount", feeAmount);
        uint256 amount = amountInit - feeAmount;
        console.log("amount post fee", amount);
        uint256 scalingFactorIn = _computeScalingFactor(ASSET_IN);
        uint256 scalingFactorOut = _computeScalingFactor(ASSET_OUT);
        console.log("scalingFactorIn",scalingFactorIn);
        console.log("scalingFactorOut",scalingFactorOut);
        amount = _upscale(amount, scalingFactorIn);
        IVault vault = IVault(vaultAddress);
        console.log("R_IN", RESERVE_IN);
        RESERVE_IN = getBalanceAndManaged(vault, POOL_ID, ASSET_IN);
        console.log("R_IN", RESERVE_IN);
        console.log("R_OUT", RESERVE_OUT);
        RESERVE_OUT = getBalanceAndManaged(vault, POOL_ID, ASSET_OUT);
        console.log("R_OUT", RESERVE_OUT);
        uint256 balanceIn = RESERVE_IN;
        uint256 balanceOut = RESERVE_OUT;
        balanceIn = _upscale(balanceIn, scalingFactorIn);
        balanceOut = _upscale(balanceOut,scalingFactorOut);
        uint256[] memory weights = pool.getNormalizedWeights();
        uint256 weight_in =weights[0];// 250000000000000000;
        uint256 weight_out =weights[1];// 250000000000000000;
        console.log("weight_in", weight_in);
        console.log("weight_out", weight_out);
        uint256 outGivenIn=_calcOutGivenIn(balanceIn,weight_in,balanceOut,weight_out,amount);
        console.log("outGivenIn", outGivenIn);
        outGivenIn= _downscale(outGivenIn, scalingFactorOut);
        console.log("outGivenIn downscale", outGivenIn);
        console.log("testOutGivenIn - ",outGivenIn);
    }

   
    function testVaultSwap() public {
        uint256 amountIn = AMOUNT_IN;

        address trader = TRADER;
        vm.startPrank(trader);

        IERC201 tokenIn = IERC201(ASSET_IN);
        IERC201 tokenOut = IERC201(ASSET_OUT);
        //15258983
        tokenIn.approve(vaultAddress, 1000000+amountIn);

        IVault vault = IVault(vaultAddress);
        //RESERVE_IN = getBalanceAndManaged(vault, POOL_ID, ASSET_IN);
        //RESERVE_OUT = getBalanceAndManaged(vault, POOL_ID, ASSET_OUT);

        //uint256 spe = uint256(POOL_ID >> (10 * 8)) & (2**(2 * 8) - 1);
        //console.log("spe",spe);
        SingleSwap memory singleSwap = SingleSwap(
            POOL_ID,
            SwapKind.GIVEN_IN,
            IAsset(ASSET_IN),
            IAsset(ASSET_OUT),
            amountIn,
            "0x"
        );

        FundManagement memory funds = FundManagement(
            trader,
            false,
            payable(trader),
            false
        );

        /*uint256 recomputed = _downscale(computeBalv(
            amountIn,
            5000000000000000,
            RESERVE_IN,
            RESERVE_OUT,
            200000000000000000,
            200000000000000000
        ),_computeScalingFactor(ASSET_OUT));*/


        //console.log("B TS", block.timestamp);
        //console.log("B NB", block.number);
        uint256 amountOutReal = vault.swap(
            singleSwap,
            funds,
            1,
            block.timestamp + 1000000000
        );
        vm.stopPrank();
        console.log("vault.swap - amountCalculated", amountOutReal);
        console.log("amountOutExpected", amountOutExpected);
        //console.log("recomputed", recomputed);
        //console.log("Diff", recomputed - amountOutReal);
        assertTrue(amountOutReal > 0);
        int256 a=100;
        int256 b=-33;
        int256 c=a%b;
        console.log(c> 0 ? "+" : "-",uint256(abs(c)));
    }


    function testOnSwap() public {
        uint256 amountIn = AMOUNT_IN;

        address trader = TRADER;
        vm.startPrank(trader);

        IERC201 tokenIn = IERC201(ASSET_IN);
        IERC201 tokenOut = IERC201(ASSET_OUT);
        //15314876
        tokenIn.approve(vaultAddress, 1000000+amountIn);

        IVault vault = IVault(vaultAddress);

        SingleSwap memory singleSwap = SingleSwap(
            POOL_ID,
            SwapKind.GIVEN_IN,
            IAsset(ASSET_IN),
            IAsset(ASSET_OUT),
            amountIn,
            "0x"
        );

        SwapRequest memory poolRequest;
        poolRequest.poolId = singleSwap.poolId;
        poolRequest.kind = singleSwap.kind;
        poolRequest.tokenIn = tokenIn;
        poolRequest.tokenOut = tokenOut;
        poolRequest.amount = singleSwap.amount;
        poolRequest.userData = singleSwap.userData;
        poolRequest.from = trader;
        poolRequest.to = payable(trader);

        uint256 amountCalculated;

        IGeneralPool pool = IGeneralPool(POOL_ADDRESS);
        //RESERVE_IN = getBalanceAndManaged(vault, POOL_ID, ASSET_IN);
        //RESERVE_OUT = getBalanceAndManaged(vault, POOL_ID, ASSET_OUT);
        amountCalculated = pool.onSwap(poolRequest, RESERVE_IN, RESERVE_OUT);
        console.log("OnSwap - amountCalculated",amountCalculated);       
        uint256 diff;
        if(amountCalculated>amountOutExpected){
            diff = amountCalculated-amountOutExpected;
        }else{
            diff = amountOutExpected-amountCalculated;
        }
        console.log("OnSwap - DIFF",diff);

    }


    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // ly, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because ly the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)


    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) public returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            console.log("IF");
            console.log("x_int256",uint256(x_int256));
            console.log("LN_36_LOWER_BOUND",uint256(LN_36_LOWER_BOUND));
            console.log("LN_36_UPPER_BOUND",uint256(LN_36_UPPER_BOUND));
            console.log("MIN_NATURAL_EXPONENT",uint256(MIN_NATURAL_EXPONENT));
            console.log("MAX_NATURAL_EXPONENT",uint256(MAX_NATURAL_EXPONENT));
            console.log("MILD_EXPONENT_BOUND",uint256(MILD_EXPONENT_BOUND));
            //console.log(int2str(x_int256));
            /*console.log("LN_36_LOWER_BOUND",LN_36_LOWER_BOUND);
            console.log("LN_36_UPPER_BOUND",LN_36_UPPER_BOUND);*/
            int256 ln_36_x = _ln_36(x_int256);
            console.log("ln_36_x",ln_36_x> 0 ? "+" : "-",uint256(abs(ln_36_x)));

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
            console.log("logx_times_y",logx_times_y> 0 ? "+" : "-",uint256(abs(logx_times_y)));
        } else {
            console.log("ELSE");
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;
        console.log("logx_times_y",logx_times_y> 0 ? "+" : "-",uint256(abs(logx_times_y)));

        // Finally, we compute exp(y * ln(x)) to arrive at x^y

        uint256 rr = uint256(exp(logx_times_y));
        console.log("logx_times_y",rr> 0 ? "+" : "-",rr);
        return rr;
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x)  public returns (int256) {

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Logarithm (mathsExpLog(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function mathsExpLog(int256 arg, int256 base)  public returns (int256) {
        // This performs a simple base change: mathsExpLog(arg, base) = ln(arg) / ln(base).

        // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
        // upscaling.

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = _ln_36(base);
        } else {
            logBase = _ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = _ln_36(arg);
        } else {
            logArg = _ln(arg) * ONE_18;
        }

        // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
        return (logArg * ONE_18) / logBase;
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a)  public returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
            return _ln_36(a) / ONE_18;
        } else {
            return _ln(a);
        }
    }

    /**
     * @dev  natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a)  public returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x)  public returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        console.log("x",uint256(x));
        x *= ONE_18;
        console.log("x",uint256(x));
        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        console.log("z",z > 0 ? "+" : "-",uint256(abs(z)));
        int256 z_squared = (z * z) / ONE_36;
        console.log("z_squared",uint256(z_squared));

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;
        console.log("num",num > 0 ? "+" : "-",uint256(abs(num)));

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;
        console.log("3 - num",num > 0 ? "+" : "-",uint256(abs(num)));
        console.log("3 - seriesSum",seriesSum > 0 ? "+" : "-",uint256(abs(seriesSum)));

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;
        console.log("5 - num",num > 0 ? "+" : "-",uint256(abs(num)));
        console.log("5 - seriesSum",seriesSum > 0 ? "+" : "-",uint256(abs(seriesSum)));

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;
        console.log("7 - num",num > 0 ? "+" : "-",uint256(abs(num)));
        console.log("7 - seriesSum",seriesSum > 0 ? "+" : "-",uint256(abs(seriesSum)));

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;
        console.log("9 - num",num > 0 ? "+" : "-",uint256(abs(num)));
        console.log("9 - seriesSum",seriesSum > 0 ? "+" : "-",uint256(abs(seriesSum)));

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;
        console.log("11 - num",num > 0 ? "+" : "-",uint256(abs(num)));
        console.log("11 - seriesSum",seriesSum > 0 ? "+" : "-",uint256(abs(seriesSum)));

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;
        console.log("13 - num",num > 0 ? "+" : "-",uint256(abs(num)));
        console.log("13 - seriesSum",seriesSum > 0 ? "+" : "-",uint256(abs(seriesSum)));

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;
        console.log("15 - num",num > 0 ? "+" : "-",uint256(abs(num)));
        console.log("15 - seriesSum",seriesSum > 0 ? "+" : "-",uint256(abs(seriesSum)));

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        int256 rr=seriesSum * 2;
        console.log("rr",rr > 0 ? "+" : "-",uint256(abs(rr)));
        return seriesSum * 2;
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

}
