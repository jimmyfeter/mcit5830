from web3 import Web3
import eth_account
import os

def get_keys(challenge,keyId = 0, filename = "eth_mnemonic.txt"):
    """
    Generate a stable private key
    challenge - byte string
    keyId (integer) - which key to use
    filename - filename to read and store mnemonics

    Each mnemonic is stored on a separate line
    If fewer than (keyId+1) mnemonics have been generated, generate a new one and return that
    """

    from web3 import Web3
import eth_account
from eth_account import Account
from eth_account.messages import encode_defunct
import os

def get_keys(challenge):
    """
    Generate an Ethereum account from a mnemonic and sign a message.
    """

    # BSC and Avalanche RPC endpoints
    BSC_RPC_URL = "https://bsc-dataseed.binance.org/"
    AVAX_RPC_URL = "https://api.avax.network/ext/bc/C/rpc"

    # Initialize Web3 instances for both chains
    bsc_w3 = Web3(Web3.HTTPProvider(BSC_RPC_URL))
    avax_w3 = Web3(Web3.HTTPProvider(AVAX_RPC_URL))

    # Verify connections
    if not bsc_w3.isConnected() or not avax_w3.isConnected():
        raise ConnectionError("Failed to connect to one or both networks.")

    # Your mnemonic phrase
    mnemonic = "sorry proof update famous swear soldier bullet upset lake solar deny fat"
    
    # Generate account from mnemonic
    acct = Account.from_mnemonic(mnemonic)
    eth_addr = acct.address

    # Encode and sign the challenge message
    msg = encode_defunct(challenge)
    sig = acct.sign_message(msg)

    # Return the signature and account address
    return sig, eth_addr

if __name__ == "__main__":
    for i in range(4):
        challenge = os.urandom(64)
        sig, addr = get_keys(challenge=challenge)
        print(addr)
