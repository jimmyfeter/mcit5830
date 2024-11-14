
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol"; //This allows role-based access control through _grantRole() and the modifier onlyRole
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; //This contract needs to interact with ERC20 tokens

contract AMM is AccessControl{
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
	uint256 public invariant;
	address public tokenA;
	address public tokenB;
	uint256 feebps = 3; //The fee in basis points (i.e., the fee should be feebps/10000)

	event Swap( address indexed _inToken, address indexed _outToken, uint256 inAmt, uint256 outAmt );
	event LiquidityProvision( address indexed _from, uint256 AQty, uint256 BQty );
	event Withdrawal( address indexed _from, address indexed recipient, uint256 AQty, uint256 BQty );

	/*
		Constructor sets the addresses of the two tokens
	*/
    constructor( address _tokenA, address _tokenB ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender );
        _grantRole(LP_ROLE, msg.sender);

		require( _tokenA != address(0), 'Token address cannot be 0' );
		require( _tokenB != address(0), 'Token address cannot be 0' );
		require( _tokenA != _tokenB, 'Tokens cannot be the same' );
		tokenA = _tokenA;
		tokenB = _tokenB;

    }


	function getTokenAddress( uint256 index ) public view returns(address) {
		require( index < 2, 'Only two tokens' );
		if( index == 0 ) {
			return tokenA;
		} else {
			return tokenB;
		}
	}

	/*
		The main trading functions
		
		User provides sellToken and sellAmount

		The contract must calculate buyAmount using the formula:
	*/
	function tradeTokens( address sellToken, uint256 sellAmount ) public {
    require( invariant > 0, 'Invariant must be nonzero' );
    require( sellToken == tokenA || sellToken == tokenB, 'Invalid token' );
    require( sellAmount > 0, 'Cannot trade 0' );
    
    uint256 qtyA = ERC20(tokenA).balanceOf(address(this));
    uint256 qtyB = ERC20(tokenB).balanceOf(address(this));
    uint256 swapAmt;
    uint256 new_invariant;
    
    //calculate the amount of the opposite token to return using the constant product formula
    if (sellToken == tokenA) {
        //sell token A, calculate how much token B to return
        uint256 feeAdjustedAmountA = sellAmount * (10000 - feebps) / 10000; // Apply fee to the sell amount
        uint256 newQtyA = qtyA + feeAdjustedAmountA; // New reserve for tokenA after deposit
        swapAmt = qtyB - (invariant / newQtyA); // Calculate how much token B to send back
        require(swapAmt > 0, 'Insufficient liquidity');
        ERC20(tokenA).transferFrom(msg.sender, address(this), feeAdjustedAmountA); // Transfer token A to contract
        ERC20(tokenB).transfer(msg.sender, swapAmt); // Transfer token B to the sender
    } else {
        //sell token B, calculate how much token A to return
        uint256 feeAdjustedAmountB = sellAmount * (10000 - feebps) / 10000; // Apply fee to the sell amount
        uint256 newQtyB = qtyB + feeAdjustedAmountB; // New reserve for tokenB after deposit
        swapAmt = qtyA - (invariant / newQtyB); // Calculate how much token A to send back
        require(swapAmt > 0, 'Insufficient liquidity');
        ERC20(tokenB).transferFrom(msg.sender, address(this), feeAdjustedAmountB); // Transfer token B to contract
        ERC20(tokenA).transfer(msg.sender, swapAmt); // Transfer token A to the sender
    }

    //update invariant
    new_invariant = ERC20(tokenA).balanceOf(address(this)) * ERC20(tokenB).balanceOf(address(this));
		//ensure invariant does not decrease
    require(new_invariant >= invariant, 'Bad trade'); 
		//update invariant
    invariant = new_invariant; 
    
    emit Swap(sellToken, sellToken == tokenA ? tokenB : tokenA, sellAmount, swapAmt);
}

	/*
		Use the ERC20 transferFrom to "pull" amtA of tokenA and amtB of tokenB from the sender
	*/
	function provideLiquidity( uint256 amtA, uint256 amtB ) public {
    require( amtA > 0 || amtB > 0, 'Cannot provide 0 liquidity' );

    //calculate the fee-adjustments
    uint256 feeAdjustedAmtA = amtA * (10000 - feebps) / 10000;
    uint256 feeAdjustedAmtB = amtB * (10000 - feebps) / 10000;

    //transfer tokens from the user to the contract
    ERC20(tokenA).transferFrom(msg.sender, address(this), feeAdjustedAmtA);
    ERC20(tokenB).transferFrom(msg.sender, address(this), feeAdjustedAmtB);

    //update the invariant: k = Ai * Bi, where Ai and Bi are the current balances of tokenA and tokenB in the contract
    uint256 new_invariant = ERC20(tokenA).balanceOf(address(this)) * ERC20(tokenB).balanceOf(address(this));
    invariant = new_invariant;

    emit LiquidityProvision(msg.sender, feeAdjustedAmtA, feeAdjustedAmtB);
}

	/*
		Use the ERC20 transfer function to send amtA of tokenA and amtB of tokenB to the target recipient
		The modifier onlyRole(LP_ROLE) 
	*/
	function withdrawLiquidity( address recipient, uint256 amtA, uint256 amtB ) public onlyRole(LP_ROLE) {
		require( amtA > 0 || amtB > 0, 'Cannot withdraw 0' );
		require( recipient != address(0), 'Cannot withdraw to 0 address' );
		if( amtA > 0 ) {
			ERC20(tokenA).transfer(recipient,amtA);
		}
		if( amtB > 0 ) {
			ERC20(tokenB).transfer(recipient,amtB);
		}
		invariant = ERC20(tokenA).balanceOf(address(this))*ERC20(tokenB).balanceOf(address(this));
		emit Withdrawal( msg.sender, recipient, amtA, amtB );
	}


}
