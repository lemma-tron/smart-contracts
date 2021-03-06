// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library VotingPower {
    using SafeMathUpgradeable for uint256;

    function calculateAlpha(
        uint256 d,
        uint256 tv,
        uint256 m
    ) internal pure returns (uint256) {
        // ๐ผ = 1 + (1/(1 + ๐^((โ๐+๐ก๐ฃ)/๐)))/4
        // ; ๐คโ๐๐๐
        // ๐ = ๐๐ข๐๐๐๐ ๐๐ ๐๐๐ฆ๐  ๐ ๐ก๐๐๐๐,
        // ๐ก๐ฃ = ๐ก๐๐๐ ๐ค๐๐๐๐๐ค ๐๐๐ ๐กโ๐ ๐ ๐๐๐๐๐๐
        // ๐ = ๐ ๐๐๐๐ ๐๐ ๐กโ๐ ๐๐ข๐๐ฃe

        // uint256 e = 2.7182818284590452353602874713527; // e
        uint256 eN = 2718281828459045; // e numerator
        uint256 eD = 1e15; // e denominator

        if (d == 0) return eD;

        /*
         *    ๐ผ = 1 + (1/(1 + ๐^eP))/4 as eP = (โ๐+๐ก๐ฃ)/๐
         *    ๐ผ = 1 + (1/(1 + (eN^eP/eD^eP))/4
         *    ๐ผ = 1 + (1/((eD^eP + eN^eP)/eD^eP)/4
         *    ๐ผ = 1 + 1/4*((eD^eP + eN^eP)/eD^eP)
         *    ๐ผ = 1 + eD^eP/4*(eD^eP + eN^eP)
         *    since eD^eP/4*(eD^eP + eN^eP) is always going to be decimal places in between 0 and 1,
         *    multipling eD for decimal places, we get
         *    eD + (eD**(eP + 1)) / (4 * (eD**eP + eN**eP));
         */

        if (tv > d) {
            uint256 eP = tv.sub(d).div(m); // e power
            return eD + (eD**(eP + 1)) / (4 * (eD**eP + eN**eP));
        } else {
            // (eN/eD)^(-eP) = (eD/eN)^eP
            uint256 eP = d.sub(tv).div(m); // e power
            return eD + (eN**(eP + 1)) / (4 * (eN**eP + eD**eP));
        }
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
