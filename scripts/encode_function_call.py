import json

from hexbytes import HexBytes
from web3 import Web3

with open("../abis/ScatterArchetype.json", "r") as f:
    json_abi = json.load(f)

ca = "0x12Dd66366d45F44128083233c6FbADfE7CBAe221"

w3 = Web3(Web3.HTTPProvider("https://ethereum.publicnode.com"))
contract = w3.eth.contract(abi=json_abi, address=Web3.to_checksum_address(ca))

hex_data = contract.encodeABI(fn_name="mint", args=[
    (HexBytes('0x0000000000000000000000000000000000000000000000000000000000000000'), []),
    5,
    '0x0000000000000000000000000000000000000000',
    HexBytes('0x')
])

print(hex_data)
