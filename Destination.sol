function createToken(address _underlying_token, string memory name, string memory symbol) 
    public onlyRole(CREATOR_ROLE) returns(address) {
    
    // Verify there isn't already a token mapped to the current asset
    require(underlying_tokens[_underlying_token] == address(0), "Token already exists");

    // Deploy new BridgeToken contract with all required arguments
    BridgeToken newToken = new BridgeToken(_underlying_token, name, symbol, address(this));

    // Map the token to the new BridgeToken
    address wrappedTokenAddr = address(newToken);
    underlying_tokens[_underlying_token] = wrappedTokenAddr;
    wrapped_tokens[wrappedTokenAddr] = _underlying_token;
    tokens.push(wrappedTokenAddr);

    // Emit the creation event
    emit Creation(_underlying_token, wrappedTokenAddr);

    // Return the address of the token
    return wrappedTokenAddr;
}
