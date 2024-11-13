// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Destination is AccessControl {
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    mapping(address => address) public wrapped_tokens;
    mapping(address => address) public underlying_tokens;

    event Creation(address indexed underlying_token, address indexed wrapped_token);
    event Wrap(address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount);
    event Unwrap(address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount);

    constructor(address admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(CREATOR_ROLE, admin);
    }

    function createToken(address _underlying_token, string memory name, string memory symbol) 
        public 
        onlyRole(CREATOR_ROLE) 
        returns (address) 
    {
        require(wrapped_tokens[_underlying_token] == address(0), "Token already wrapped");

        ERC20 wrappedToken = new ERC20(name, symbol);
        wrapped_tokens[_underlying_token] = address(wrappedToken);
        underlying_tokens[address(wrappedToken)] = _underlying_token;

        emit Creation(_underlying_token, address(wrappedToken));
        return address(wrappedToken);
    }

    function wrap(address _underlying_token, address to, uint256 amount) 
        public 
        onlyRole(CREATOR_ROLE)
    {
        address wrapped_token = wrapped_tokens[_underlying_token];
        require(wrapped_token != address(0), "Token not registered");

        ERC20(_underlying_token).transferFrom(msg.sender, address(this), amount);
        ERC20(wrapped_token).transfer(to, amount);

        emit Wrap(_underlying_token, wrapped_token, to, amount);
    }

    function unwrap(address wrapped_token, address to, uint256 amount) 
        public 
    {
        require(underlying_tokens[wrapped_token] != address(0), "Token not registered");
        ERC20(wrapped_token).transferFrom(msg.sender, address(this), amount);

        address underlying_token = underlying_tokens[wrapped_token];
        ERC20(underlying_token).transfer(to, amount);

        emit Unwrap(underlying_token, wrapped_token, msg.sender, to, amount);
    }
}
