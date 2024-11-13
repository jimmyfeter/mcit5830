// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
	mapping( address => address) public underlying_tokens;
	mapping( address => address) public wrapped_tokens;
	address[] public tokens;

	event Creation( address indexed underlying_token, address indexed wrapped_token );
	event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

	function wrap(address _underlying_token, address _recipient, uint256 _amount ) public onlyRole(WARDEN_ROLE) {
    
    //check if the token is already registered
    address wrappedTokenAddr = underlying_tokens[_underlying_token];
    require(wrappedTokenAddr != address(0), "Underlying token not registered");

    //cast wrapped token address to a BridgeToken instance
    BridgeToken wrappedToken = BridgeToken(wrappedTokenAddr);

    //mint specified amount of tokens to recipient
    wrappedToken.mint(_recipient, _amount);

    //emit the wrap event with details
    emit Wrap(_underlying_token, wrappedTokenAddr, _recipient, _amount);
}

	function unwrap(address _wrapped_token, address _recipient, uint256 _amount ) public {
    //check if the wrapped token is registered
    address underlyingTokenAddr = wrapped_tokens[_wrapped_token];
    require(underlyingTokenAddr != address(0), "Wrapped token not registered");

    //cast the wrapped token address to a BridgeToken 
    BridgeToken wrappedToken = BridgeToken(_wrapped_token);

    //burn the amount of tokens from the sender balance
    wrappedToken.burnFrom(msg.sender, _amount);

    //emit the unwrap event with details
    emit Unwrap(underlyingTokenAddr, _wrapped_token, msg.sender, _recipient, _amount);
}

function createToken(
        address _underlying_token,
        string memory name,
        string memory symbol
    ) public onlyRole(CREATOR_ROLE) returns (address) {
        require(underlying_tokens[_underlying_token] == address(0), "Token already exists");

        BridgeToken newToken = new BridgeToken(_underlying_token, name, symbol, address(this));
        address wrappedTokenAddr = address(newToken);

        underlying_tokens[_underlying_token] = wrappedTokenAddr;
        wrapped_tokens[wrappedTokenAddr] = _underlying_token;
        tokens.push(wrappedTokenAddr);

        emit Creation(_underlying_token, wrappedTokenAddr);

        return wrappedTokenAddr;
    }


}


