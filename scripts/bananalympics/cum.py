import json

with open("./res.json", "r", encoding='utf-8') as f:
    results = json.load(f)

cleanresults = []

for r in results:
    cleanresults.append({
        "rank": r["rank"],
        "displayName": r["wallet_name"],
        "wallet": r["wallet"],
        "currentPortfolio": r["portfolio_value"]
    })

print(json.dumps(cleanresults, indent=4))
