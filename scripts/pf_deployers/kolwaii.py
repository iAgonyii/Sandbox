import os
import time

import requests

kolwaiis = []
pengempresses = []

for i in range(0, 50):
    offset = i * 50
    limit = 50

    request_url = f"https://frontend-api-v2.pump.fun/coins?offset={offset}&limit={limit}&sort=market_cap&order=DESC&includeNsfw=true&searchTerm=kolwaii"

    response = requests.get(request_url)
    res = response.json()

    if len(res) == 0:
        break

    temp_kolwaiis = [token['mint'] for token in res]
    kolwaiis.extend(temp_kolwaiis)

    print(f"Found {len(temp_kolwaiis)} kolwaiis in batch {i}")

for i in range(0, 50):
    offset = i * 50
    limit = 50

    request_url = f"https://frontend-api-v2.pump.fun/coins?offset={offset}&limit={limit}&sort=market_cap&order=DESC&includeNsfw=true&searchTerm=penguin%20empress"

    response = requests.get(request_url)
    res = response.json()

    if len(res) == 0:
        break

    temp_pengempresses = [token['mint'] for token in res]
    pengempresses.extend(temp_pengempresses)

    print(f"Found {len(temp_pengempresses)} pengempresses in batch {i}")


kolwaiis = set(kolwaiis)
pengempresses = set(pengempresses)

print(f"Found {len(kolwaiis)} kolwaiis in total")
print(f"Found {len(pengempresses)} pengempresses in total")

combined = kolwaiis.union(pengempresses)
combined = set(combined)

f = open("kolwaiis_combined-4.txt", "w")
for combined in combined:
    f.write(f"{combined}\n")
f.close()

