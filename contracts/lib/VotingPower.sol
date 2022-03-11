// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";

library VotingPower {
    using SafeMath for uint256;

    function calculateAlpha(
        uint256 d,
        uint256 tv,
        uint256 m
    ) internal pure returns (uint256) {
        // 𝛼 = 1 + (1/(1 + 𝑒^((−𝑑+𝑡𝑣)/𝑚)))/4
        // ; 𝑤ℎ𝑒𝑟𝑒
        // 𝑑 = 𝑛𝑢𝑚𝑏𝑒𝑟 𝑜𝑓 𝑑𝑎𝑦𝑠 𝑠𝑡𝑎𝑘𝑒𝑑,
        // 𝑡𝑣 = 𝑡𝑖𝑚𝑒 𝑤𝑖𝑛𝑑𝑜𝑤 𝑓𝑜𝑟 𝑡ℎ𝑒 𝑠𝑖𝑔𝑚𝑜𝑖𝑑
        // 𝑚 = 𝑠𝑙𝑜𝑝𝑒 𝑜𝑓 𝑡ℎ𝑒 𝑐𝑢𝑟𝑣e

        // uint256 e = 2.7182818284590452353602874713527; // e
        uint256 eN = 2718281828459045; // e numerator
        uint256 eD = 1e15; // e denominator

        if (d == 0) return eD;

        uint256 eP = tv.sub(d).div(m); // e power

        /*
         *    𝛼 = 1 + (1/(1 + 𝑒^eP))/4 as eP = (−𝑑+𝑡𝑣)/𝑚
         *    𝛼 = 1 + (1/(1 + (eN^eP/eD^eP))/4
         *    𝛼 = 1 + (1/((eD^eP + eN^eP)/eD^eP)/4
         *    𝛼 = 1 + 1/4*((eD^eP + eN^eP)/eD^eP)
         *    𝛼 = 1 + eD^eP/4*(eD^eP + eN^eP)
         *    since eD^eP/4*(eD^eP + eN^eP) is always going to be decimal places in between 0 and 1,
         *    multipling eD for decimal places, we get
         *    eD + (eD**(eP + 1)) / (4 * (eD**eP + eN**eP));
         */

        return eD + (eD**(eP + 1)) / (4 * (eD**eP + eN**eP));
    }

    function calculate(
        uint256 d,
        uint256 n,
        bool lpTokenStaker
    ) internal pure returns (uint256) {
        uint256 tv = 45;
        uint256 m = 12;
        uint256 alpha = calculateAlpha(d, tv, m);

        if (lpTokenStaker) {
            return (alpha * n * 12) / 10;
        } else {
            return alpha * n;
        }
    }
}
