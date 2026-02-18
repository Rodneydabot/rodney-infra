# Vessel Protocol × Bankr Integration

Multi-launch infrastructure for NFT-owned bots with 96-minute rotator auctions.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    VESSEL PROTOCOL                           │
├─────────────────────────────────────────────────────────────┤
│  NFT/Bot Asset                                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────┐ │
│  │   NFT 1     │    │   NFT 2     │    │   NFT N         │ │
│  │ (Bot Alpha) │    │ (Bot Beta)  │    │ (Bot Gamma...)  │ │
│  └──────┬──────┘    └──────┬──────┘    └────────┬────────┘ │
│         │                   │                     │          │
│         └───────────────────┴─────────────────────┘          │
│                           │                                  │
│              ┌─────────────┴─────────────┐                    │
│              │     ROTATOR ENGINE        │                    │
│              │   (96-min auctions)       │                    │
│              │                           │                    │
│              │   Seat 1 ─── Seat 15      │                    │
│              │   [BID]      [BID]        │                    │
│              └─────────────┬─────────────┘                    │
│                            │                                 │
│              ┌─────────────┴─────────────┐                   │
│              │     LAUNCHERS             │                   │
│              │  ┌─────┐   ┌─────┐       │                   │
│              │  │Bankr│   │Molt │       │                   │
│              │  │ (1) │   │ (2) │       │                   │
│              │  └──┬──┘   └──┬──┘       │                   │
│              └─────┼─────────┼───────────┘                   │
│                    │         │                              │
│              ┌─────┴─────────┴─────┐                       │
│              │   TOKEN DEPLOYMENT   │                       │
│              └──────────┬───────────┘                       │
│                         │                                   │
│              ┌─────────┴──────────┐                        │
│              │   FEE DISTRIBUTION │                        │
│              │   (24hr pulls)      │                        │
│              └─────────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## Launch Flow (Bankr)

### Prerequisites
- Bankr API key (`bk_...`)
- Bot wallet (connected to NFT)
- 15 seat bidders ready

### Step 1: Bot Initialization
```bash
# Bot claims its identity via ERC-8004
bankr prompt "Register agent with ERC-8004 standard"

# Bot checks its reputation score
bankr prompt "Show my agent reputation across 8004, x402, and Molt"
```

### Step 2: Seat Auction (96 min cycle)
```javascript
// Rotator contract state
{
  currentAuction: {
    endsAt: 1739834567, // Unix timestamp
    seatsAvailable: [1, 5, 12], // Which slots auctioning
    highestBids: {
      1: { bidder: "0x...", amount: "0.5" }, // ETH
      5: { bidder: "0x...", amount: "0.3" },
      12: { bidder: "0x...", amount: "0.8" }
    },
    feeSplit: 60 // NFT owner sets % to seats (60%)
  }
}
```

### Step 3: Launch Trigger (When Rotator Full)
```bash
# Bot uses natural language to deploy via Bankr
bankr prompt "Deploy token named 'AlphaSwarm' symbol ASWARM on Base with 1B supply. Return contract address."

# Or via REST API
POST https://api.bankr.bot/agent/prompt
{
  "prompt": "Deploy memecoin on Base: name 'YieldBot', symbol YBOT, 100M supply. Include LP setup.",
  "context": { // Passed via custom instructions
    "nftId": "123",
    "rotator": "vessel-alpha",
    "feeSplit": 60
  }
}
```

### Step 4: Fee Distribution Tracking

**Off-Chain Calculation (Backend):**
```javascript
// Every block scan
{
  tokenAddress: "0x...",
  tradingFees: {
    collected: "1.23 ETH",
    timestamp: 1739840000
  },
  seatHolders: [
    { seat: 1, address: "0xA...", share: "0.082 ETH" },
    { seat: 2, address: "0xB...", share: "0.082 ETH" },
    // ... 15 total
  ],
  nftOwner: { address: "0xOwner...", share: "0.492 ETH" }, // 40%
  botTreasury: { share: "0.369 ETH" } // 30% for buybacks
}
```

**24-Hour Pull Distribution:**
```solidity
// Seat holder claims
function claimFees(uint256 seatId) external {
  require(msg.sender == seatToAddress[seatId], "Not seat holder");
  uint256 amount = accruedFees[seatId];
  require(amount > 0, "Nothing to claim");
  
  accruedFees[seatId] = 0;
  payable(msg.sender).transfer(amount);
}
```

## Bankr Advantages for Vessel

| Feature | Benefit |
|---------|---------|
| Natural language deployment | Bot "decides" when to launch, what to name it |
| Multi-chain | Base, Polygon, Solana as Vessel expands |
| Built-in wallet management | Bot has persistent wallet tied to NFT |
| LLM Gateway | Bot intelligence for timing launches |
| Async jobs | Handle long operations without blocking |

## Test Launch Script

```bash
#!/bin/bash
# vessel-bankr-test.sh

export BANKR_API_KEY="bk_YOUR_KEY"
export VESSEL_BOT_ID="nft-123"

# 1. Check bot wallet
bankr prompt "What is my Base wallet balance?"

# 2. Check reputation
bankr prompt "Show my agent stats: launches, volume, x402 payments"

# 3. Simulate launch (Bankr)
bankr prompt "Deploy a test token: name 'VesselTest' symbol VTEST on Base. Max supply 1 trillion. Set up Uniswap V4 pool."

# 4. Verify deployment
bankr prompt "Show deployed token details for VTEST"

# 5. Check fees (simulated)
bankr prompt "Calculate pro-rata fees for 15 seat holders if we collected 0.5 ETH ($60% split)"
```

## Open Questions

1. **Bankr token deployment**: Does it support custom fee splitting on deploy?
2. **LP management**: Can Bankr lock liquidity with custom vesting?
3. **Event streaming**: Does Bankr webhooks notify on trades?
4. **Cost**: What % does Bankr take vs Molt Launch?

## Next Steps

1. Get Bankr CLI + API key
2. Test single token deployment
3. Map fee structures (Bankr vs Molt)
4. Build rotator contract scaffolding
5. Integrate event streaming
