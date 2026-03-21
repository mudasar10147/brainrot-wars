# Brainrot Wars V1 — Detailed Scripting Roadmap

**Document:** Scripting-only task breakdown for V1 (MVP)  
**Source:** [V1_Development_Plan.md](../V1_Development_Plan.md) — Sections 2.1, 3.2, 5.x, 6.1, 8.x  
**Purpose:** Assign one **major task** at a time to scripters; each major task is split into **minor (sub-)tasks** for tracking.

---

## How to Use This Roadmap

- **Major task** = one assignable unit (e.g. “Merge mechanic”). Assign to a single scripter (or pair).
- **Minor tasks** = sub-tasks under that major task. Complete in order where dependencies are noted.
- **Order** = tasks are sequenced by dependency; complete earlier tasks before starting later ones unless marked “can run in parallel.”
- **Done criteria:** All minor tasks under a major task are complete and tested before moving to the next major task.

---

## Dependency Overview

```
[1] Place & Config
        ↓
[2] Starter Flow & Persistence
        ↓
[3] Brainrot Stats Config
        ↓
[4] Merge Mechanic
        ↓
[5] Currency & Pickup + DataStore
        ↓
[6] Battle System (Scaffold + Config)  ← can start after [3]
        ↓
[7] Battle Integration (NPC → Arena → Turns)  ← needs M2 assets
        ↓
[8] Capture Chance
        ↓
[9] Currency on Win (Grant + Scatter + Collect)
        ↓
[10] Region Unlock  ← needs map from 3D
        ↓
[11] Upgrades Backend
        ↓
[12] UI Script APIs & Wiring
        ↓
[13] DataStore Polish & Save/Load
        ↓
[14] Security & Exploit Hardening
        ↓
[15] Build & Config Audit
```

---

## Major Tasks (in order)

---

### **MAJOR TASK 1 — Place Structure & Shared Config**

**Description:** Set up Roblox place hierarchy and shared config layout so all later scripts use the same structure. No gameplay yet.

**Depends on:** Nothing. Do first.

**Assign to:** Lead Scripter or designated scripter.


| #   | Minor task                                   | Details                                                                                                                                                                                                                     |
| --- | -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.1 | Create place folder structure                | `ReplicatedStorage`: `Scripts`, `Modules`, `Config`, `Assets`. `ServerScriptService`: `Scripts`, `Modules`. `StarterPlayer`: `StarterPlayerScripts`. `StarterGui` (or use existing). Document in a short README or comment. |
| 1.2 | Create Config folder and placeholder modules | Under `ReplicatedStorage.Config`: add ModuleScripts `BrainrotStats` (return `{}`), `Moves` (return `{}`), `Upgrades` (return `{}`). Naming: PascalCase.                                                                     |
| 1.3 | Define naming and script layout convention   | Document: ServerScriptService = game logic, DataStore, battle authority; ReplicatedStorage.Config = read-only config; StarterPlayerScripts = input, UI events.                                                              |
| 1.4 | Version control / Rojo (if used)             | Ensure structure syncs with Rojo project; add `.project.json` or confirm structure matches plan.                                                                                                                            |


**Definition of done:** Place has correct folders; config modules exist and can be `require()`d from server and client; doc updated.

---

### **MAJOR TASK 2 — Starter Flow & Persistence**

**Description:** Ensure starter selection adds the chosen brainrot to inventory and that choice (and inventory) persist across sessions.

**Depends on:** Task 1 (place structure). Starter UI and inventory already exist (per Week 1 report); this task is **scripting side**: persistence and validation.

**Assign to:** One scripter.


| #   | Minor task                                | Details                                                                                                                                                                                    |
| --- | ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2.1 | Persist starter choice on selection       | When player confirms 1 of 3 starters, save choice in DataStore (e.g. `StarterId` or `StarterName`). Prevent selecting again if already chosen.                                             |
| 2.2 | Load starter on join                      | On `PlayerAdded` / first load: if no inventory or no starter flag, apply starter flow (add one brainrot to inventory from config). If already has data, load inventory and equipped state. |
| 2.3 | Prevent duplicate starter or re-selection | If player already has a starter (or has progress), do not show starter screen again or allow re-pick.                                                                                      |
| 2.4 | Wire Starter UI to server                 | RemoteEvent/RemoteFunction: client fires “StarterSelected” with choice; server validates (first time only), adds to inventory, sets flag, saves.                                           |


**Definition of done:** New player picks starter → it’s in inventory and saved; rejoin → same starter and inventory; no duplicate starter.

---

### **MAJOR TASK 3 — Brainrot Stats Config**

**Description:** Add config/data for Health, Damage, Resistance, Endurance per brainrot (and optionally per move). Battle and merge will read from here.

**Depends on:** Task 1.

**Assign to:** One scripter.


| #   | Minor task                    | Details                                                                                                                                                                                                                                                                         |
| --- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 3.1 | Define BrainrotStats module   | In `ReplicatedStorage.Config.BrainrotStats`: return a table keyed by brainrot name (e.g. `Tung Tung Sahur`, `Tralla Tralla`). Each entry: `Health`, `Damage`, `Resistance`, `Endurance` (numbers). Include all V1 types: 3 starters, 3 merge results, 2–3 NPC types per region. |
| 3.2 | Document tier / merge mapping | Add a table or section: “which brainrot merges into which” (e.g. Tung Tung Sahur → Tralla Tralla). Can be same module or `MergeMap` in Config.                                                                                                                                  |
| 3.3 | (Optional) Moves config       | In `ReplicatedStorage.Config.Moves`: per move name: `EnduranceCost`, optional `Power` or multiplier. Link move names to brainrots if needed.                                                                                                                                    |
| 3.4 | Helper to get stats by name   | Small function (in module or shared util): `GetStats(brainrotName)` returns stats table; safe fallback if name missing.                                                                                                                                                         |


**Definition of done:** All brainrot types have stats in config; merge mapping clear; battle/merge scripts can `require` and read stats.

---

### **MAJOR TASK 4 — Merge Mechanic**

**Description:** Two identical brainrots merge into one next-tier brainrot. Server-authoritative; persist result in inventory.

**Depends on:** Task 1, 2, 3 (inventory exists, stats and merge mapping in config).

**Assign to:** Lead Scripter or one scripter.


| #   | Minor task                                 | Details                                                                                                                                                              |
| --- | ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 4.1 | Validate merge request on server           | Client sends “Merge” with two inventory slot IDs or brainrot IDs. Server checks: same brainrot type, both in player inventory, player has both. Reject if invalid.   |
| 4.2 | Remove two brainrots and add one next-tier | Server: remove both from inventory; look up next-tier from config (Task 3); add one of that type to inventory. Update equipped slots if one of removed was equipped. |
| 4.3 | Persist after merge                        | Save updated inventory (and equipped state) to DataStore.                                                                                                            |
| 4.4 | Fire success/failure to client             | RemoteEvent: “MergeComplete” with success boolean and updated inventory (or let client refresh from server). Client shows “Merge successful” or error.               |
| 4.5 | Edge cases                                 | Cannot merge if only one of type; cannot merge if inventory full after removal (shouldn’t happen if 2 → 1); handle disconnect during merge safely.                   |


**Definition of done:** Player can select two same brainrots, confirm merge; server validates, performs merge, saves; client reflects new inventory.

---

### **MAJOR TASK 5 — Currency & Pickup + DataStore**

**Description:** Gold and diamonds are collectible; amounts persist in DataStore and display on HUD.

**Depends on:** Task 1. Can run in parallel with Task 4 if different scripter.

**Assign to:** One scripter.


| #   | Minor task                             | Details                                                                                                                                                                                                         |
| --- | -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5.1 | Add currency to DataStore schema       | Save/load `Gold`, `Diamonds` per player (with inventory/equipped). Default 0.                                                                                                                                   |
| 5.2 | Pickup logic (in-world or arena)       | When player touches or clicks gold/diamond pickup (or trigger), add amount to player’s runtime currency; remove or hide pickup. Server-authoritative: server adds, client updates HUD via event or replication. |
| 5.3 | Persist currency on change or on leave | On currency change, optionally debounce save; on PlayerRemoving, save. Use same DataStore key as inventory.                                                                                                     |
| 5.4 | HUD / UI update                        | Expose event or value (e.g. BindableEvent or attribute) so HUD can show current gold and diamonds. Load from server on join.                                                                                    |
| 5.5 | Prevent exploit                        | All “add gold/diamonds” only on server (e.g. from pickup or battle win); client never sets currency.                                                                                                            |


**Definition of done:** Gold and diamonds can be picked up, persist, and show on HUD after rejoin.

---

### **MAJOR TASK 6 — Battle System Scaffold & Config**

**Description:** Implement damage formula, turn order, move execution, Endurance cost, and win/lose logic in code. No NPC click or arena yet—pure logic and config.

**Depends on:** Task 3 (stats and moves config). Can start once Task 3 is done.

**Assign to:** Lead Scripter or one scripter.


| #   | Minor task                        | Details                                                                                                                                                                                                      |
| --- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 6.1 | Damage formula module             | Function: given attacker Damage, defender Resistance (and optional move power), return damage dealt. Document formula (e.g. `max(1, Damage - Resistance)` or with multiplier). No magic numbers; use config. |
| 6.2 | Turn order / state machine        | Define states: PlayerTurn, EnemyTurn, Resolving, Win, Lose. Logic: apply move (Endurance cost, damage), check HP ≤ 0 for win/lose, switch turn.                                                              |
| 6.3 | Endurance cost and validation     | On move use: subtract move’s Endurance cost from current Endurance; if insufficient, move not allowed. Optionally refill Endurance per turn (if in V1 spec).                                                 |
| 6.4 | Battle result type / API          | Return “BattleResult” (Win/Lose, optional rewards table) so other systems can consume it. No UI yet; can test with print or test script.                                                                     |
| 6.5 | Config-driven: no hardcoded stats | All HP, Damage, Resistance, Endurance, move costs from ReplicatedStorage.Config.                                                                                                                             |


**Definition of done:** Battle logic runs in isolation (e.g. two stat tables in, result out); formula and turn flow correct; config-driven.

---

### **MAJOR TASK 7 — Battle Integration (NPC → Arena → Turns)**

**Description:** Player clicks NPC brainrot → transition to battle arena; run battle with real models/animations; on win/lose return to world. Requires M2 assets (at least one brainrot model + anims).

**Depends on:** Task 6 (battle scaffold). M2: models and animations available.

**Assign to:** Lead Scripter or one scripter.


| #   | Minor task                     | Details                                                                                                                                                                             |
| --- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 7.1 | NPC detection and validation   | When player clicks or touches NPC brainrot (ProximityPrompt or ClickDetector): server checks player has ≥1 brainrot equipped. If not, reject and optionally show message.           |
| 7.2 | Transition to battle arena     | Move player (and NPC or NPC data) to battle arena (separate area or instance). Lock movement; spawn battle UI if wired. Optionally show “dust cloud” at original position (3D/VFX). |
| 7.3 | Load battle state from config  | Get player’s equipped brainrots’ stats from BrainrotStats; get NPC type and stats. Initialize battle state (HP, Endurance) from config.                                             |
| 7.4 | Run battle loop                | Use Task 6 battle scaffold: turn-based, move selection (from client when UI is ready), damage formula, Endurance, win/lose.                                                         |
| 7.5 | Play animations (hook)         | Where applicable: trigger attack/hurt/dizzy animation IDs from Animator’s list. If anims not ready, placeholder or skip.                                                            |
| 7.6 | On battle end: return to world | On Win or Lose: teleport player back to world (original position or spawn); cleanup arena; unlock movement. Pass result to Task 8 (capture) and Task 9 (currency).                  |


**Definition of done:** Click NPC → arena → full battle → return; win/lose determined correctly; no client authority on outcome.

---

### **MAJOR TASK 8 — Capture Chance**

**Description:** On battle win, roll a chance to add defeated brainrot to player inventory; notify client.

**Depends on:** Task 7 (battle integration, win path).

**Assign to:** One scripter.


| #   | Minor task                | Details                                                                                                                                             |
| --- | ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| 8.1 | Capture chance config     | Add `CaptureChance` (or per-NPC chance) to Config; e.g. 0.25 or 25%. No hardcoding in script.                                                       |
| 8.2 | Server-side roll on win   | When battle ends in Win: server rolls random; if success, add defeated brainrot type to player inventory (if inventory not full).                   |
| 8.3 | Notify client             | Fire event to client: “Captured” or “Not captured” (and optional reason, e.g. inventory full). Client can show notification (“Brainrot captured!”). |
| 8.4 | Persist new inventory     | Save inventory after adding captured brainrot.                                                                                                      |
| 8.5 | Edge case: inventory full | If full, optionally still show “captured” but don’t add, or show “Inventory full, brainrot not captured.” Per design choice.                        |


**Definition of done:** Winning a battle can add the NPC brainrot to inventory with configurable chance; client notified; data saved.

---

### **MAJOR TASK 9 — Currency on Win (Grant + Scatter + Collect)**

**Description:** On battle win, grant 35 gold and 3 diamonds; scatter in arena (or spawn pickups); player must collect before leaving arena.

**Depends on:** Task 5 (currency DataStore, pickup logic), Task 7 (battle win).

**Assign to:** One scripter.


| #   | Minor task                          | Details                                                                                                                                                                                                               |
| --- | ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 9.1 | Grant rewards on win (server)       | When battle ends in Win: server adds 35 gold and 3 diamonds. Option A: add directly to player currency. Option B: spawn pickups in arena (see 9.2). Plan specifies “scattered in arena; must collect before leaving.” |
| 9.2 | Spawn gold/diamond pickups in arena | Create or enable pickup objects (e.g. 35 gold + 3 diamonds as separate pickups or combined); place in arena. Use existing pickup logic (Task 5) when player touches them.                                             |
| 9.3 | Block exit until collected          | Before allowing player to leave arena (e.g. “Exit” button or auto-return): check all reward pickups collected (or grant remainder directly if time-out). Optional: simple “Collect all to continue” gate.             |
| 9.4 | Persist currency after collect      | After pickup, currency is added and saved (Task 5).                                                                                                                                                                   |


**Definition of done:** Win battle → rewards scattered in arena; player collects; cannot leave until collected (or design alternative); currency persists.

---

### **MAJOR TASK 10 — Region Unlock**

**Description:** When player has enough gold, allow unlock of Region 2; deduct gold; set flag; teleport or allow access to Region 2. Requires map (Region 2, gate/portal) from 3D.

**Depends on:** Task 5 (currency). Map/portal from 3D Modeler.

**Assign to:** One scripter.


| #    | Minor task                        | Details                                                                                                                     |
| ---- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 10.1 | Region unlock cost in config      | Add `Region2UnlockCost` (gold) to Config.                                                                                   |
| 10.2 | Gate/portal interaction           | ProximityPrompt or ClickDetector on gate/portal: when player interacts, server checks gold ≥ cost and not already unlocked. |
| 10.3 | Deduct gold and set unlocked flag | Server: subtract cost from player gold; set `Region2Unlocked` (or similar) in DataStore; save.                              |
| 10.4 | Teleport or enable Region 2       | Teleport player to Region 2 spawn, or enable physics/barrier so they can enter. Reuse same place or instance as per design. |
| 10.5 | Persist and load unlock state     | On join, load unlock state; if unlocked, allow access to Region 2 (e.g. gate already open).                                 |


**Definition of done:** Player with enough gold can unlock Region 2; gold deducted; state saved; player can access Region 2 after unlock.

---

### **MAJOR TASK 11 — Upgrades Backend**

**Description:** Script APIs for spending diamonds on upgrades: inventory capacity, movement speed, equip slots. Server validates and applies.

**Depends on:** Task 5 (diamonds in DataStore). UI can wire later (Task 12).

**Assign to:** One scripter.


| #    | Minor task                        | Details                                                                                                                                                                                         |
| ---- | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 11.1 | Upgrades config                   | In `ReplicatedStorage.Config.Upgrades`: list upgrades (e.g. InventoryCapacity, MovementSpeed, EquipSlots); each has `Cost` (diamonds), `MaxLevel` or single purchase, `Value` (e.g. +10 slots). |
| 11.2 | Server: purchase upgrade          | RemoteFunction or RemoteEvent: client requests “PurchaseUpgrade” (upgrade id). Server checks diamond balance, checks not already maxed; deducts diamonds; applies upgrade (update player data). |
| 11.3 | Persist upgrade state             | Save upgraded state in DataStore (e.g. `UpgradesPurchased` or per-upgrade level).                                                                                                               |
| 11.4 | Apply effects                     | Inventory capacity: increase max slots when upgrade purchased. Movement speed: set player’s WalkSpeed. Equip slots: increase from 3 to higher if in V1 scope.                                   |
| 11.5 | Expose current upgrades to client | So Upgrade UI can show “Purchased” or cost; client can request “GetUpgrades” or server pushes on join.                                                                                          |


**Definition of done:** Server can process upgrade purchases; diamonds deducted; effects applied and persisted; client can query state.

---

### **MAJOR TASK 12 — UI Script APIs & Wiring**

**Description:** Provide script interfaces (RemoteEvents, RemoteFunctions, or BindableEvents) so UI can trigger actions and receive updates. Wire existing UI to these APIs.

**Depends on:** Tasks 2, 4, 5, 7, 8, 9, 10, 11 (relevant systems exist). UI screens exist (Starter, HUD, Inventory, Battle, Upgrade, Notifications).

**Assign to:** Lead Scripter or one scripter (can split by screen with second scripter).


| #    | Minor task           | Details                                                                                                                                              |
| ---- | -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| 12.1 | Inventory UI wiring  | Open/close, equip/unequip, merge request: client fires events; server responds. Refresh inventory display from server data or events.                |
| 12.2 | HUD wiring           | Gold, diamonds, equipped brainrots: update when server pushes or client reads from shared state.                                                     |
| 12.3 | Battle UI wiring     | Move buttons → send move choice to server; receive HP/Endurance updates, turn indicator, win/lose.                                                   |
| 12.4 | Upgrade menu wiring  | List upgrades and costs; “Purchase” button fires purchase request; update list and diamond count after response.                                     |
| 12.5 | Notifications        | “Brainrot captured,” “Region unlocked,” “Merge successful,” “Not enough gold/diamonds”: server or client fires notification event; UI shows message. |
| 12.6 | Region unlock prompt | “Unlock Region 2 for X gold?” Confirm/cancel → Task 10 logic.                                                                                        |


**Definition of done:** All V1 UI screens are wired to server logic; no critical placeholders for core flows.

---

### **MAJOR TASK 13 — DataStore Polish & Save/Load**

**Description:** Single coherent save/load for inventory, currency, equipped state, unlocks, upgrades. Retry logic and error handling.

**Depends on:** All systems that persist (Tasks 2, 4, 5, 8, 10, 11).

**Assign to:** Lead Scripter or one scripter.


| #    | Minor task               | Details                                                                                                                                                        |
| ---- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 13.1 | Unified save schema      | One DataStore key per player (e.g. `PlayerData_UserId`). Document schema: inventory, equipped, gold, diamonds, starter chosen, region unlocked, upgrades.      |
| 13.2 | Load on join             | On PlayerAdded: load once; apply defaults for new players; populate runtime state.                                                                             |
| 13.3 | Save triggers            | Save on critical changes (merge, purchase, unlock, capture); optional debounce. Save on PlayerRemoving.                                                        |
| 13.4 | Retry and error handling | DataStore calls: retry on failure (e.g. 3 attempts); if load fails, use session-only or show “Data failed to load.” Don’t save every second; avoid throttling. |
| 13.5 | Test save/load           | Rejoin and verify: inventory, currency, equipped, region unlock, upgrades all persist.                                                                         |


**Definition of done:** One source of truth for save data; load/save reliable; rejoin preserves full progress.

---

### **MAJOR TASK 14 — Security & Exploit Hardening**

**Description:** Ensure no client can grant itself currency, items, or wins; all critical logic and rewards on server.

**Depends on:** All gameplay tasks (2–12).

**Assign to:** Lead Scripter or one scripter.


| #    | Minor task                         | Details                                                                                                                                     |
| ---- | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 14.1 | Audit RemoteEvents/RemoteFunctions | List all client→server calls; ensure server validates every request (ownership, state, costs). No “AddGold” that trusts amount from client. |
| 14.2 | Battle outcome on server only      | Win/lose, damage, capture roll—all computed on server. Client only sends move choice; server runs battle and sends result.                  |
| 14.3 | Merge and purchase on server       | Already in Tasks 4 and 11; re-check: no client-sent “add item” or “set diamonds.”                                                           |
| 14.4 | Rate limiting (optional)           | Throttle expensive operations (e.g. merge, purchase) per player to prevent spam.                                                            |


**Definition of done:** No way for client to grant itself items, currency, or battle wins; server validates all critical actions.

---

### **MAJOR TASK 15 — Build & Config Audit**

**Description:** Production-ready build: no test code, no hardcoded values; config holds all tunables.

**Depends on:** All previous tasks.

**Assign to:** Lead Scripter.


| #    | Minor task             | Details                                                                                                                                             |
| ---- | ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| 15.1 | Remove test/debug code | No print statements or test scripts in production paths; remove or gate behind debug flag.                                                          |
| 15.2 | Config audit           | All costs, capture rate, damage formula constants, region unlock cost in Config (ReplicatedStorage). No magic numbers in battle or economy scripts. |
| 15.3 | Place cleanup          | Remove unused scripts; ensure only V1 features active.                                                                                              |
| 15.4 | Document config keys   | Short doc or comments: list all config keys and expected format for future changes.                                                                 |


**Definition of done:** Build is clean; all tunables in config; ready for QA (M5) and MVP (M6).

---

## Summary Table (Assignable Order)


| Order | Major task                       | Assignable to            | Depends on         |
| ----- | -------------------------------- | ------------------------ | ------------------ |
| 1     | Place Structure & Shared Config  | Lead Scripter            | —                  |
| 2     | Starter Flow & Persistence       | Scripter                 | 1                  |
| 3     | Brainrot Stats Config            | Scripter                 | 1                  |
| 4     | Merge Mechanic                   | Lead Scripter            | 1, 2, 3            |
| 5     | Currency & Pickup + DataStore    | Scripter                 | 1                  |
| 6     | Battle System Scaffold & Config  | Lead Scripter            | 3                  |
| 7     | Battle Integration (NPC → Arena) | Lead Scripter            | 6 + M2 assets      |
| 8     | Capture Chance                   | Scripter                 | 7                  |
| 9     | Currency on Win                  | Scripter                 | 5, 7               |
| 10    | Region Unlock                    | Scripter                 | 5 + map            |
| 11    | Upgrades Backend                 | Scripter                 | 5                  |
| 12    | UI Script APIs & Wiring          | Lead Scripter / Scripter | 2, 4, 5, 7–11      |
| 13    | DataStore Polish & Save/Load     | Lead Scripter            | 2, 4, 5, 8, 10, 11 |
| 14    | Security & Exploit Hardening     | Lead Scripter            | 2–12               |
| 15    | Build & Config Audit             | Lead Scripter            | 1–14               |


---

*End of Scripting Roadmap. Update as tasks are completed or scope changes; align with [V1_Development_Plan.md](../V1_Development_Plan.md) and weekly reports.*