import json

from web3 import Web3

with open("./holders.json", "r") as f:
    holders = json.load(f)

holders = [h for h in holders if h['Quantity'] >= 6]
wallets = [Web3.to_checksum_address(h['HolderAddress']) for h in holders]

print(wallets)
