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

    #BSC and Avalanche RPC endpoints
    BSC_RPC_URL = "https://bsc-dataseed.binance.org/"
    AVAX_RPC_URL = "https://api.avax.network/ext/bc/C/rpc"
    
    #Initialize Web3 instances for both chains
    bsc_w3 = Web3(Web3.HTTPProvider(BSC_RPC_URL))
    avax_w3 = Web3(Web3.HTTPProvider(AVAX_RPC_URL))
    
    #Verify connections
    if not bsc_w3.isConnected() or not avax_w3.isConnected():
        raise ConnectionError("Failed to connect to one or both networks.")
    
    #private key
    private_key = "0xdba1bdad6ce33c9ea799b188c1a26fb0d5e5258dd9dd121c1b89c553c6627c50"
    
    #create account from  private key
    acct = eth_account.Account.from_key(private_key)
    eth_addr = acct.address
    
    #encode and sign the challenge message
    msg = eth_account.messages.encode_defunct(challenge)
    sig = acct.sign_message(msg)

    
     # Read mnemonics from the specified file
    # if os.path.exists(filename):
    #     with open(filename, 'r') as f:
    #         mnemonics = f.readlines()
    # else:
    #     mnemonics = []
    # w3 = Web3()


    # msg = eth_account.messages.encode_defunct(challenge)


    # #generate account from the mnemonic of the given key id
    # if keyId < len(mnemonics):
    #     mnemonic = mnemonics[keyId].strip()
    # else:
    #     raise ValueError("Insufficient mnemonics in the key id.")

    # #generate private key and account from mnemonic
    # acct = eth_account.Account.from_mnemonic(mnemonic)
    # eth_addr = acct.address

    # #sign the challenge
    # sig = acct.sign_message(msg)

    # #generate account from the mnemonic of the given key id
    # if keyId < len(mnemonics):
    #     mnemonic = mnemonics[keyId].strip()
    # else:
    #     #create a new mnemonic and write to file 
    #     acct = Account.create()
    #     mnemonic = acct.key.hex() 
    #     with open(filename, 'a') as f:
    #         f.write(mnemonic + '\n')

    # #generate private key and account from mnemonic
    # acct = Account.from_key(mnemonic)
    # eth_addr = acct.address

    # # Sign the challenge
    # sig = acct.sign_message(msg)

    # assert eth_account.Account.recover_message(msg,signature=sig.signature.hex()) == eth_addr, f"Failed to sign message properly"

    # #return sig, acct #acct contains the private key
    # return sig, eth_addr

if __name__ == "__main__":
    for i in range(4):
        challenge = os.urandom(64)
        sig, addr= get_keys(challenge=challenge,keyId=i)
        print( addr )
