from web3 import Web3
from eth_account import Account
from eth_account.messages import encode_defunct
import os

def get_keys(challenge):
    """
    Generate an Ethereum account from a mnemonic and sign a message.
    """

    #endpoints
    BSC_RPC_URL = "https://bsc-dataseed.binance.org/"
    AVAX_RPC_URL = "https://api.avax.network/ext/bc/C/rpc"

    #initialize Web3 instances 
    bsc_w3 = Web3(Web3.HTTPProvider(BSC_RPC_URL))
    avax_w3 = Web3(Web3.HTTPProvider(AVAX_RPC_URL))

    #verify connections
    if not bsc_w3.isConnected() or not avax_w3.isConnected():
        raise ConnectionError("Failed to connect to one or both networks.")

    #your mnemonic phrase
    mnemonic = "sorry proof update famous swear soldier bullet upset lake solar deny fat"
    
    #create account from mnemonic
    web3 = Web3()
    web3.eth.account.enable_unaudited_hdwallet_features()
    acct = web3.eth.account.from_mnemonic(my_mnemonic)
    eth_addr = acct.address

    #encode and sign
    msg = encode_defunct(challenge)
    sig = acct.sign_message(msg)

    
    return sig, eth_addr

if __name__ == "__main__":
    for i in range(4):
        challenge = os.urandom(64)
        sig, addr = get_keys(challenge=challenge)
        print(addr)
