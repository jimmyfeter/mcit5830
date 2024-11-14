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

    function createToken(address _underlying_token, string memory name, string memory symbol, address manager) 
    public onlyRole(CREATOR_ROLE) returns (address) {
    
    // Ensure there isn’t already a token mapped to this underlying token
    require(underlying_tokens[_underlying_token] == address(0), "Token already exists");

    // Deploy new BridgeToken contract with the additional constructor arguments
    BridgeToken newToken = new BridgeToken(_underlying_token, name, symbol, manager);
    address wrappedTokenAddr = address(newToken);

    // Map the underlying token to the wrapped token and vice versa
    underlying_tokens[_underlying_token] = wrappedTokenAddr;
    wrapped_tokens[wrappedTokenAddr] = _underlying_token;
    tokens.push(wrappedTokenAddr);

    // Emit the creation event with the mapping details
    emit Creation(_underlying_token, wrappedTokenAddr);

    return wrappedTokenAddr;
}


    function wrap(address _underlying_token, address _recipient, uint256 _amount) 
        public onlyRole(WARDEN_ROLE) {
        
        // Retrieve the wrapped token address for the given underlying token
        address wrappedTokenAddr = underlying_tokens[_underlying_token];
        require(wrappedTokenAddr != address(0), "Underlying token not registered");

        // Interact with the wrapped token instance to mint tokens to the recipient
        BridgeToken wrappedToken = BridgeToken(wrappedTokenAddr);
        wrappedToken.mint(_recipient, _amount);

        // Emit the wrap event
        emit Wrap(_underlying_token, wrappedTokenAddr, _recipient, _amount);
    }

    function unwrap(address _wrapped_token, address _recipient, uint256 _amount) 
        public onlyRole(WARDEN_ROLE) {
        
        // Retrieve the underlying token address for the given wrapped token
        address underlyingTokenAddr = wrapped_tokens[_wrapped_token];
        require(underlyingTokenAddr != address(0), "Wrapped token not registered");

        // Interact with the wrapped token instance to burn tokens from the sender's balance
        BridgeToken wrappedToken = BridgeToken(_wrapped_token);
        wrappedToken.burnFrom(msg.sender, _amount);

        // Emit the unwrap event
        emit Unwrap(underlyingTokenAddr, _wrapped_token, msg.sender, _recipient, _amount);
    }
}
