import requests
from collections import defaultdict
import json

def get_nft_items(collection_address, limit=1000, offset=0):
    url = f"https://tonapi.io/v2/nfts/collections/{collection_address}/items?limit={limit}&offset={offset}"
    response = requests.get(url)
    data = response.json()
    items = data['nft_items']
    return items

def get_holders(items):
    # Count holdings and collect owner info in a single pass
    holdings = defaultdict(lambda: {'count': 0, 'name': None})
    
    for item in items:
        owner = item['owner']
        holdings[owner['address']]['count'] += 1
        holdings[owner['address']]['name'] = owner.get('name', None)
    
    # Convert to the desired format
    return [
        {
            'owner_address': addr,
            'owner_name': info['name'],
            'holding_count': info['count']
        }
        for addr, info in holdings.items()
    ]

def print_holders(holders):
    print(f"\nFound {len(holders)} unique holders:")
    print(f"Total pepes: {sum(holder['holding_count'] for holder in holders)}")

# Main execution
offset = 0
found_end = False
all_items = []

while not found_end:
    items = get_nft_items("EQBG-g6ahkAUGWpefWbx-D_9sQ8oWbvy6puuq78U2c4NUDFS", limit=1000, offset=offset)
    if len(items) == 0:
        found_end = True
    else:
        all_items.extend(items)
        offset += 1000
        print(f"Found {len(all_items)} items")

# Process and print results
holders_list = get_holders(all_items)
holders_list.sort(key=lambda x: x['holding_count'], reverse=True)
# write to ./scripts/tg-gifts/plushpepes.json
open("./scripts/tg-gifts/plushpepes.json", "w").write(json.dumps(holders_list, indent=4))
print_holders(holders_list)
    

