// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM {
    address public tokenA;
    address public tokenB;
    uint256 public invariant;
    uint256 public feebps = 30; // fee in basis points (0.3%)

    event Swap(address indexed _inToken, address indexed _outToken, uint256 inAmt, uint256 outAmt);

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        invariant = 0;
    }

    function provideLiquidity(uint256 amtA, uint256 amtB) external {
        require(amtA > 0 && amtB > 0, "Invalid amounts");
        require(ERC20(tokenA).transferFrom(msg.sender, address(this), amtA), "Token A transfer failed");
        require(ERC20(tokenB).transferFrom(msg.sender, address(this), amtB), "Token B transfer failed");

        uint256 newInvariant = ERC20(tokenA).balanceOf(address(this)) * ERC20(tokenB).balanceOf(address(this));
        require(newInvariant > invariant, "Invariant decrease");
        invariant = newInvariant;
    }

    function tradeTokens(address sellToken, uint256 sellAmount) public {
        require(invariant > 0, "Invariant must be nonzero");
        require(sellToken == tokenA || sellToken == tokenB, "Invalid token");
        require(sellAmount > 0, "Cannot trade 0");

        uint256 qtyA = ERC20(tokenA).balanceOf(address(this));
        uint256 qtyB = ERC20(tokenB).balanceOf(address(this));
        uint256 swapAmt;

        if (sellToken == tokenA) {
            // Selling token A for token B
            uint256 feeAdjustedAmount = (sellAmount * (10000 - feebps)) / 10000; // Apply fee
            uint256 newQtyA = qtyA + feeAdjustedAmount; // New reserve of tokenA after adding sellAmount
            require(newQtyA > 0, "Invalid reserve");

            swapAmt = qtyB - (invariant / newQtyA); // Calculate tokenB to return
            require(swapAmt > 0 && swapAmt < qtyB, "Insufficient liquidity or invalid swap");

            ERC20(tokenA).transferFrom(msg.sender, address(this), sellAmount); // Collect sellToken
            ERC20(tokenB).transfer(msg.sender, swapAmt); // Send buyToken to the trader
        } else {
            // Selling token B for token A
            uint256 feeAdjustedAmount = (sellAmount * (10000 - feebps)) / 10000; // Apply fee
            uint256 newQtyB = qtyB + feeAdjustedAmount; // New reserve of tokenB after adding sellAmount
            require(newQtyB > 0, "Invalid reserve");

            swapAmt = qtyA - (invariant / newQtyB); // Calculate tokenA to return
            require(swapAmt > 0 && swapAmt < qtyA, "Insufficient liquidity or invalid swap");

            ERC20(tokenB).transferFrom(msg.sender, address(this), sellAmount); // Collect sellToken
            ERC20(tokenA).transfer(msg.sender, swapAmt); // Send buyToken to the trader
        }

        // Update the invariant using current reserves after the swap
        invariant = ERC20(tokenA).balanceOf(address(this)) * ERC20(tokenB).balanceOf(address(this));
        require(invariant >= qtyA * qtyB, "Invariant decreased");

        emit Swap(sellToken, sellToken == tokenA ? tokenB : tokenA, sellAmount, swapAmt);
    }
}
