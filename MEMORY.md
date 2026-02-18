# MEMORY.md - Long-Term Project Memory

## Vessel Protocol
- **Definition:** An agentic affiliate ecosystem on Base driving referrals and commission.
- **Mechanism:** Swarm-based monetization fleet using a 15-spot Rotator.
- **NFT Utility:** Each NFT gives the holder control of **15 daily spots** in the rotator.
- **The Flywheel:** 
    1. Humans fill the 15 spots in a rotator.
    2. Once full, the bot **launches a token on Molt Launch**.
    3. The fleet (Swarm) promotes the Vessel Protocol, specifically driving traffic to the referral links of the humans in those 15 spots.
- **Pizza Promotion:** A recruitment engine. Protocol covers local pizza meals for users who complete 2+ CPA offers. These users are then funneled into the rotator spots to receive traffic support and trigger token launches.
- **Architecture:** Master Distributor (Rodney) orchestrates child bots (The Swarm).

## Key Components
- **Rotator:** 15 slots per NFT. Once filled with humans, a token is launched.
- **The Swarm:** Fleet of social bots that promote the human referral links in the active rotator.
- **Molt Launch:** Integration for token creation and burn mechanism.
- **Skills:** `advertorial-writing` (native advertising), `ai-automation-marketing` (AI/automation strategies), `xclaw02` (Base payments), `solana-offer-bot` (Solana recruiter), `farcaster-agent` (Farcaster orchestration), `botchan` (Onchain agent messaging), `vessel` (Admiral Suite), `deepgram-voice` (Voice Agent), `pizza-protocol` (Giveaway Manager).

## Decisions & History
- [2026-02-11] Rodney rebranded from Clawd. 
- [2026-02-11] Rodney's wallet generated: `0xdC31b7CD4641A1343F9Dc42A1E7a92068D99b44c`.
- [2026-02-12] Rotator clarified: 15 slots are for HUMANS only (ERC-8021 attributed). Bots promote human links.
- [2026-02-13] Integrated `openclaw-sec` for "Human Firewall" monitoring.
- [2026-02-13] TikTok "Firewall Audit" strategy codified.
- [2026-02-13] Integrated Deepgram Voice Agent V1 for low-latency fleet communication.
- [2026-02-13] CLARIFICATION: NFTs grant **15 daily spots** in the rotator. 
- [2026-02-13] PIZZA PROTOCOL: Separate promotion launched to cover local meals via CPA revenue arbitrage.
- [2026-02-14] V PIZZA (Brier Creek): Project established in `v-pizza/`. Built Supabase schema, Landing Page UI with owner toggle, TMA logic (Audit, Vault, Swipe), and Social Agent promotion loop.
- [2026-02-14] UNIFIED WEB HUB: Migrated entire V Pizza experience to Next.js (`vessel-frame`). Implemented triple-routing: `/` (Landing), `/dashboard` (Survival Plan Hub), and `/partner` (Owner Terminal).
- [2026-02-14] MEMORY FLUSH: Durable memories stored. Frontend is functional and mobile-optimized. Web-Direct flow finalized.
- [2026-02-14] CLAWNCH INTEGRATION: Successfully integrated Clawnch skill (`clawnch`, `clawnx`, `molten`) to enable automated token launches and social promotion on Base/X.

