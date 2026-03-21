# Brainrot Wars — Version Roadmap

Division of the game into three versions: V1 (MVP), V2 (Expanded), and V3 (End Game). No development plan—scope only.

---

## V1 — Core Gameplay & MVP

**Goal:** Deliver the core concept and playable loop so the game is understandable and fun at a minimal scope.

### In scope
- **Starting system** — Player chooses one of three starter brainrots (Pet Simulator–style); chosen brainrot added to inventory.
- **Inventory** — Fixed limits: e.g. 50 storage slots, 3 equip slots. No upgrades in V1 (or one simple upgrade to show the system).
- **Brainrot stats** — Health, Damage, Resistance, Endurance. Stats drive battle outcomes; no single “power number.”
- **Merge system** — Two identical brainrots merge into the next tier (e.g. Tung Tung Sahur → Tralla Tralla) with a stronger stat profile.
- **NPC battles** — Click NPC → circular transition → separate battle area. Turn-based, Pokémon-style: choose moves; moves cost Endurance and deal damage from Damage vs Resistance. Themed moves per brainrot. Win = enemy HP to 0; lose = all equipped brainrots defeated. No dice; outcomes from stats and choices.
- **Capture** — On win, chance to obtain the defeated brainrot (rarity/strength can reduce chance). Defeated state (e.g. stars/dizzy) for feedback.
- **Currency (basic)** — Win reward: 35 gold, 3 diamonds. Gold and diamonds scattered in arena; must be collected before leaving.
- **Progression** — Gold used to unlock at least one additional area/region so the loop is clear.
- **Upgrades (minimal)** — Diamonds used for a small set of upgrades, e.g.:
  - Inventory capacity increase  
  - Player movement speed  
  - Number of brainrots that can be equipped  
  (Enough to show the upgrade system; full list in V2.)
- **Regions** — At least two areas: starter + one unlockable, to demonstrate the core loop (fight → capture → merge → get stronger → unlock).

### Out of scope for V1
- PvP
- World events
- Rebirth/prestige
- Full upgrade tree
- Spawn scaling math
- Monetization (or only placeholder)
- Daily rewards
- Win animations

---

## V2 — Expanded Experience

**Goal:** Add social competition, full progression tools, and more content so the game feels “complete” for a first full release.

### In scope (adds on V1)
- **Full upgrade system** — All diamond upgrades:
  - Inventory capacity  
  - Movement speed  
  - Equip slots  
  - Magnet (collect gold/diamonds from greater distance)  
  - Lucky Hits (critical hit chance)  
  - Lucky Loot (capture chance after battles)  
  - Luck Select (chance to get a stronger brainrot after PvP)
- **PvP** — Battle request (trade-like). Accept → circular transition → dedicated arena. Same turn-based, stat/Endurance rules. Initiator moves first; same turn = higher remaining Endurance first. Winner receives one of the loser’s used brainrots, chosen at random (“stealing” mechanic).
- **More regions** — Multiple areas unlockable with gold, with broader variety of brainrots.
- **Daily rewards** — Login rewards per day (rewards TBD; implemented at concept level).
- **Win animations (optional)** — Purchasable win animation/cutscene after winning a battle (PvP or NPC).
- **Spawn scaling (optional in V2)** — Region spawn strength can scale with combined stat strength of equipped brainrots in that region, with tier caps and max count per type (e.g. max 20 of strongest type). Exact math can be simplified for V2.

### Out of scope for V2
- Rebirth/prestige
- World events (timed rare spawns, multi-player join, big rewards)
- Full monetization suite (can be partial)
- Full spawn math and region caps as in GDD

---

## V3 — End Game

**Goal:** Full vision from the GDD: long-term retention, live events, and complete monetization.

### In scope (adds on V2)
- **Rebirth / Prestige** — At a progression milestone, player can rebirth and restart. Brainrots can be returned with a modifier that makes them less effective. Perks: e.g. faster walk speed, rare brainrots, lootboxes, etc., to keep players engaged after “beating” the game.
- **World events** — Every 15 minutes a rare brainrot (e.g. “67.”) spawns in a random region. Notification on screen and in chat. Other players can join the same fight (same dust cloud). On battle end: all participants get 250 gold, 50 diamonds; some players obtain the brainrot (announced in chat). Capture/battle rules same; events exempt from normal spawn scaling.
- **Full spawn math** — Spawn strength by region based on combined stat strength of equipped brainrots in that region. Tier rules (e.g. total &lt; 10 → max tier 4; ≥ 10 → 8; ≥ 30 → 17). Per-region upper limit (e.g. Region 1 max tier 10). Max 20 of the strongest brainrot type per region. World events excluded.
- **Monetization (full)** —  
  - **Game passes:** 2x Lucky Loot, VIP (special tag, exclusive brainrot, 1.5x currency), +50 inventory, +2 equip slots, Teleport between regions.  
  - **Developer products:** In-game currency (e.g. 50–5000 Robux), Lucky Blocks, exclusive brainrots, win animations.  
  - **Private servers:** e.g. 200 Robux.
- **All regions and content** — Full map, all brainrot tiers and types, full balance and polish.
- **Full optional systems** — All win animations, UI/UX polish, VFX/SFX as per GDD.

### Summary
- **V1** = Core loop and MVP (concept clear, one loop working).  
- **V2** = Full upgrades, PvP, more regions, daily rewards, optional spawn scaling.  
- **V3** = Rebirth, world events, full spawn math, full monetization, complete content and polish.

---

*No development plan or ordering of tasks is defined in this document—only the division of scope into V1, V2, and V3.*
