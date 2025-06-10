import time

import requests

deployers = []

for i in range(0, 20):
    offset = i * 50
    limit = 50

    request_url = f"https://frontend-api.pump.fun/coins?offset={offset}&limit={limit}&sort=market_cap&order=DESC&includeNsfw=true"

    response = requests.get(request_url)
    res = response.json()

    tokens_above_100k_mcap = [token for token in res if token['usd_market_cap'] >= 500000]
    creators = [token['creator'] for token in tokens_above_100k_mcap]
    deployers.extend(creators)

    print(f"Found {len(creators)} deployers in batch {i}")

blacklist = open("blacklist.txt", "r").read().split("\n")
deployers = list(set(deployers) - set(blacklist))

print(f"Found {len(deployers)} deployers in total")

for deployer in deployers:

    request_url = f"https://frontend-api.pump.fun/coins/user-created-coins/{deployer}?offset=0&limit=50&includeNsfw=true"
    time.sleep(1)
    response = requests.get(request_url)
    print(response.status_code)

    res = response.json()

    try:
        # Find coins where 'mint' is the same and only keep the highest market cap coin
        coins = {}
        for token in res:
            mint = token['mint']
            if mint in coins:
                if token['usd_market_cap'] > coins[mint]['usd_market_cap']:
                    coins[mint] = token
            else:
                coins[mint] = token

        coins_under_30k = [coin for coin in coins.values() if coin['usd_market_cap'] < 30000]
    except Exception:
        coins_under_30k = ['']
        print(f"Error fetching coins for {deployer}")
    if len(coins_under_30k) >= 1:
        deployers.remove(deployer)
        print(f"Removed {deployer} from deployers list")

f = open("deployers_over_250k_mcap.txt", "w")
for deployer in deployers:
    f.write(f"{deployer}\n")
