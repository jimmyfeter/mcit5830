// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Source is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
	mapping( address => bool) public approved;
	address[] public tokens;

	event Deposit( address indexed token, address indexed recipient, uint256 amount );
	event Withdrawal( address indexed token, address indexed recipient, uint256 amount );
	event Registration( address indexed token );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);

    }

	function deposit(address _token, address _recipient, uint256 _amount ) public {
        //check if token registered
        require(approved[_token], "Token not registered");
        
        //pull token from sender  
        ERC20 token = ERC20(_token);
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        //emit deposit event for the bridge operator
        emit Deposit(_token, _recipient, _amount);
    }

	function withdraw(address _token, address _recipient, uint256 _amount ) onlyRole(WARDEN_ROLE) public {
        //check valid recipient
        require(_recipient != address(0), "Invalid recipient");
        
        //transfer tokens to the recipient
        ERC20 token = ERC20(_token);
        require(token.transfer(_recipient, _amount), "Transfer failed");
        
        //emit event
        emit Withdrawal(_token, _recipient, _amount);
    }

	function registerToken(address _token) onlyRole(ADMIN_ROLE) public {
        //check if valid token address
        require(_token != address(0), "Invalid token address");
        
        //check if not already registered
        require(!approved[_token], "Token already registered");
        
        //add to approved mapping and tokens array
        approved[_token] = true;
        tokens.push(_token);
        
        //emit
        emit Registration(_token);
    }


}


