// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM is AccessControl {
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    uint256 public invariant;
    address public tokenA;
    address public tokenB;
    uint256 feebps = 3; // Fee in basis points (0.03%)

    event Swap(address indexed _inToken, address indexed _outToken, uint256 inAmt, uint256 outAmt);
    event LiquidityProvision(address indexed _from, uint256 AQty, uint256 BQty);
    event Withdrawal(address indexed _from, address indexed recipient, uint256 AQty, uint256 BQty);

    constructor(address _tokenA, address _tokenB) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LP_ROLE, msg.sender);

        require(_tokenA != address(0), 'Token address cannot be 0');
        require(_tokenB != address(0), 'Token address cannot be 0');
        require(_tokenA != _tokenB, 'Tokens cannot be the same');
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function getTokenAddress(uint256 index) public view returns(address) {
        require(index < 2, 'Only two tokens');
        if(index == 0) {
            return tokenA;
        } else {
            return tokenB;
        }
    }

    function tradeTokens(address sellToken, uint256 sellAmount) public {
        require(invariant > 0, 'Invariant must be nonzero');
        require(sellToken == tokenA || sellToken == tokenB, 'Invalid token');
        require(sellAmount > 0, 'Cannot trade 0');
        
        uint256 qtyA = ERC20(tokenA).balanceOf(address(this));
        uint256 qtyB = ERC20(tokenB).balanceOf(address(this));
        
        // First transfer the sell tokens to the contract
        if (sellToken == tokenA) {
            ERC20(tokenA).transferFrom(msg.sender, address(this), sellAmount);
            
            // Calculate amounts after fee
            uint256 amountWithFee = (sellAmount * (10000 - feebps));
            uint256 newQtyA = (qtyA * 10000) + amountWithFee;
            uint256 newQtyB = (invariant * 10000) / newQtyA;
            uint256 tokensToSend = qtyB - newQtyB / 10000;
            
            require(tokensToSend > 0 && tokensToSend <= qtyB, 'Invalid swap amount');
            
            // Perform the swap
            ERC20(tokenB).transfer(msg.sender, tokensToSend);
            
            // Update invariant based on actual balances
            invariant = ERC20(tokenA).balanceOf(address(this)) * 
                       ERC20(tokenB).balanceOf(address(this));
            
            emit Swap(tokenA, tokenB, sellAmount, tokensToSend);
        } else {
            ERC20(tokenB).transferFrom(msg.sender, address(this), sellAmount);
            
            // Calculate amounts after fee
            uint256 amountWithFee = (sellAmount * (10000 - feebps));
            uint256 newQtyB = (qtyB * 10000) + amountWithFee;
            uint256 newQtyA = (invariant * 10000) / newQtyB;
            uint256 tokensToSend = qtyA - newQtyA / 10000;
            
            require(tokensToSend > 0 && tokensToSend <= qtyA, 'Invalid swap amount');
            
            // Perform the swap
            ERC20(tokenA).transfer(msg.sender, tokensToSend);
            
            // Update invariant based on actual balances
            invariant = ERC20(tokenA).balanceOf(address(this)) * 
                       ERC20(tokenB).balanceOf(address(this));
            
            emit Swap(tokenB, tokenA, sellAmount, tokensToSend);
        }
    }

    function provideLiquidity(uint256 amtA, uint256 amtB) public {
        require(amtA > 0 || amtB > 0, 'Cannot provide 0 liquidity');

        ERC20(tokenA).transferFrom(msg.sender, address(this), amtA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), amtB);

        invariant = ERC20(tokenA).balanceOf(address(this)) * 
                   ERC20(tokenB).balanceOf(address(this));

        emit LiquidityProvision(msg.sender, amtA, amtB);
    }

    function withdrawLiquidity(address recipient, uint256 amtA, uint256 amtB) public onlyRole(LP_ROLE) {
        require(amtA > 0 || amtB > 0, 'Cannot withdraw 0');
        require(recipient != address(0), 'Cannot withdraw to 0 address');
        
        if(amtA > 0) {
            ERC20(tokenA).transfer(recipient, amtA);
        }
        if(amtB > 0) {
            ERC20(tokenB).transfer(recipient, amtB);
        }
        
        invariant = ERC20(tokenA).balanceOf(address(this)) * 
                   ERC20(tokenB).balanceOf(address(this));
                   
        emit Withdrawal(msg.sender, recipient, amtA, amtB);
    }
}
