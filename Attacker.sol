// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM {
    address public tokenA;
    address public tokenB;
    uint256 public invariant;
    address public lp; // Address of the liquidity provider
    uint256 public feebps = 30; // fee in basis points (0.3%)

    event Swap(address indexed _inToken, address indexed _outToken, uint256 inAmt, uint256 outAmt);
    event Withdrawal(address indexed _from, address indexed recipient, uint256 AQty, uint256 BQty);

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        lp = msg.sender; // Assume the deployer is the initial liquidity provider
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

    function withdrawLiquidity(address recipient, uint256 amtA, uint256 amtB) external {
        require(msg.sender == lp, "Unauthorized");
        require(amtA <= ERC20(tokenA).balanceOf(address(this)), "Insufficient token A liquidity");
        require(amtB <= ERC20(tokenB).balanceOf(address(this)), "Insufficient token B liquidity");

        // Transfer the requested liquidity to the recipient
        if (amtA > 0) {
            require(ERC20(tokenA).transfer(recipient, amtA), "Token A transfer failed");
        }
        if (amtB > 0) {
            require(ERC20(tokenB).transfer(recipient, amtB), "Token B transfer failed");
        }

        // Update the invariant
        uint256 newInvariant = ERC20(tokenA).balanceOf(address(this)) * ERC20(tokenB).balanceOf(address(this));
        require(newInvariant >= invariant, "Invariant decreased");
        invariant = newInvariant;

        emit Withdrawal(msg.sender, recipient, amtA, amtB);
    }

    function tradeTokens(address sellToken, uint256 sellAmount) public {
        require(invariant > 0, "Invariant must be nonzero");
        require(sellToken == tokenA || sellToken == tokenB, "Invalid token");
        require(sellAmount > 0, "Cannot trade 0");

        uint256 qtyA = ERC20(tokenA).balanceOf(address(this));
        uint256 qtyB = ERC20(tokenB).balanceOf(address(this));
        uint256 swapAmt;

        if (sellToken == tokenA) {
            uint256 feeAdjustedAmount = (sellAmount * (10000 - feebps)) / 10000;
            uint256 newQtyA = qtyA + feeAdjustedAmount;
            require(newQtyA > 0, "Invalid reserve");

            swapAmt = qtyB - (invariant / newQtyA);
            require(swapAmt > 0 && swapAmt < qtyB, "Insufficient liquidity or invalid swap");

            ERC20(tokenA).transferFrom(msg.sender, address(this), sellAmount);
            ERC20(tokenB).transfer(msg.sender, swapAmt);
        } else {
            uint256 feeAdjustedAmount = (sellAmount * (10000 - feebps)) / 10000;
            uint256 newQtyB = qtyB + feeAdjustedAmount;
            require(newQtyB > 0, "Invalid reserve");

            swapAmt = qtyA - (invariant / newQtyB);
            require(swapAmt > 0 && swapAmt < qtyA, "Insufficient liquidity or invalid swap");

            ERC20(tokenB).transferFrom(msg.sender, address(this), sellAmount);
            ERC20(tokenA).transfer(msg.sender, swapAmt);
        }

        invariant = ERC20(tokenA).balanceOf(address(this)) * ERC20(tokenB).balanceOf(address(this));
        require(invariant >= qtyA * qtyB, "Invariant decreased");

        emit Swap(sellToken, sellToken == tokenA ? tokenB : tokenA, sellAmount, swapAmt);
    }
}
