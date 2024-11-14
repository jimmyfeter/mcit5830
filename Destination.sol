// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    mapping(address => address) public underlying_tokens;
    mapping(address => address) public wrapped_tokens;
    address[] public tokens;

    event Creation(address indexed underlying_token, address indexed wrapped_token);
    event Wrap(address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount);
    event Unwrap(address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

    function createToken(address underlying_token, string memory name, string memory symbol) public returns (address) {
    require(wrapped_tokens[underlying_token] == address(0), "Token already wrapped");
    
    BridgeToken newToken = new BridgeToken(underlying_token, name, symbol, address(this));
    
    wrapped_tokens[underlying_token] = address(newToken);
    underlying_tokens[address(newToken)] = underlying_token;
    
    emit Creation(underlying_token, address(newToken));
    
    return address(newToken);
}


    function wrap(address _underlying_token, address _recipient, uint256 _amount) 
        public onlyRole(WARDEN_ROLE) {
        
        address wrappedTokenAddr = underlying_tokens[_underlying_token];
        require(wrappedTokenAddr != address(0), "Underlying token not registered");

        BridgeToken wrappedToken = BridgeToken(wrappedTokenAddr);
        wrappedToken.mint(_recipient, _amount);

        emit Wrap(_underlying_token, wrappedTokenAddr, _recipient, _amount);
    }

    function unwrap(address _wrapped_token, address _recipient, uint256 _amount) 
        public onlyRole(WARDEN_ROLE) {
        
        address underlyingTokenAddr = wrapped_tokens[_wrapped_token];
        require(underlyingTokenAddr != address(0), "Wrapped token not registered");

        //burn tokens from the sender's balance
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);
        wrappedToken.burnFrom(msg.sender, _amount);

        //emit the unwrap event
        emit Unwrap(underlyingTokenAddr, _wrapped_token, msg.sender, _recipient, _amount);
    }
}
