# Brainrot Wars — V1 Development Plan

**Document:** Comprehensive development plan for Version 1 (MVP)  
**Game:** Brainrot Wars (Roblox)  
**Scope:** Functional MVP — core gameplay loop, 2 regions, NPC battles, merge, currency, minimal upgrades

---

## 1. Project Overview

### 1.1 Game Concept (Brief)
Brainrot Wars is a collect-merge-battle simulator on Roblox. Players choose a starter “brainrot,” fight NPC brainrots in turn-based (Pokémon-style) battles, capture them with a chance on win, and merge two identical brainrots into a stronger tier. Stats (Health, Damage, Resistance, Endurance) drive outcomes. Gold unlocks new regions; diamonds buy upgrades (inventory, movement speed, equip slots). The loop: **fight → capture → merge → get stronger → unlock region.**

### 1.2 Goals for V1
| Goal | Description |
|------|-------------|
| **Playable loop** | Full cycle: starter → battle → capture → merge → upgrade → new region. |
| **Clarity** | New players understand the concept in under 5 minutes. |
| **Stability** | No critical bugs in core flow; save/load works. |
| **Foundation** | Code and assets structured for V2 (PvP, more upgrades, events). |

### 1.3 Core Gameplay Loop (V1)
```
[Start] → Choose 1 of 3 starters → Equip brainrots (max 3) → Walk in Region 1
    → Click NPC brainrot → Battle (turn-based, moves, Endurance) → Win/Lose
    → If Win: collect scattered gold (35) & diamonds (3), chance to capture brainrot
    → Merge 2 same brainrots → Stronger brainrot
    → Spend gold to unlock Region 2
    → Spend diamonds on upgrades (inventory, speed, equip slots)
    → Repeat in Region 1 & 2
```

---

## 2. Scope and Features for V1

### 2.1 Core Mechanics
| # | Mechanic | Description | Owner |
|---|----------|-------------|--------|
| 1 | Starter selection | UI: choose 1 of 3 brainrots; add to inventory. | Lead Scripter + UI/UX |
| 2 | Inventory | 50 slots storage, 3 equip slots; equip/unequip from list. | Lead Scripter |
| 3 | Brainrot stats | Health, Damage, Resistance, Endurance per brainrot. | Lead Scripter |
| 4 | Merge | Two identical brainrots → one next-tier brainrot (e.g. Tung Tung Sahur → Tralla Tralla). | Lead Scripter |
| 5 | NPC battle | Click NPC → transition → battle arena; turn-based moves; Endurance cost; damage from Damage vs Resistance. | Lead Scripter |
| 6 | Capture | On win, % chance to obtain defeated brainrot; visual feedback (dizzy/stars). | Lead Scripter + Animator |
| 7 | Currency | 35 gold, 3 diamonds per win; scattered in arena; must collect before leaving. | Lead Scripter |
| 8 | Region unlock | Gold gate to unlock Region 2 from Region 1. | Lead Scripter |
| 9 | Upgrades | Diamonds: +inventory capacity, +movement speed, +equip slots (minimal set). | Lead Scripter |

### 2.2 Game Environment
| Element | Description | Owner |
|---------|-------------|--------|
| Region 1 (Starter) | Main play area; spawn points; NPC brainrot spawn zones; boundaries. | 3D Modeler + Lead Scripter |
| Region 2 (Unlockable) | Second area; distinct look; NPC brainrots; unlock trigger/portal. | 3D Modeler + Lead Scripter |
| Battle arena(s) | Separate instance or zone; circular transition in; gold/diamond drop layout. | 3D Modeler + Lead Scripter |
| Dust cloud (external view) | Where player/NPC were; visible to other players during battle. | 3D Modeler / VFX + Lead Scripter |

### 2.3 Player Interactions
| Interaction | Description |
|-------------|-------------|
| Click NPC brainrot | Initiates battle (if ≥1 brainrot equipped). |
| Move in world | Standard Roblox movement (keyboard/mobile). |
| Collect gold/diamonds | Walk over or click in battle arena. |
| Open inventory | Toggle UI; equip/unequip brainrots. |
| Open upgrade menu | Spend diamonds on inventory/speed/equip. |
| Merge | Select two same brainrots in inventory → confirm merge. |
| Unlock region | Interact with gate/portal when enough gold. |

### 2.4 Brainrot Entities (V1)
| Entity | Purpose | Count (min) |
|--------|---------|-------------|
| Starter brainrots | 3 types (e.g. Tung Tung Sahur + 2 others). | 3 |
| Next-tier (merge result) | 1 per starter (e.g. Tralla Tralla). | 3 |
| NPC brainrots (Region 1) | Roaming; battleable; captureable. | 2–3 types |
| NPC brainrots (Region 2) | Same; slightly stronger tier. | 2–3 types |

*Each has: model, stats, 1+ themed move(s), idle/walk/attack/dizzy animations.*

### 2.5 UI Elements (V1)
| UI | Description | Owner |
|----|-------------|--------|
| Starter selection screen | 3 options; select one; confirm. | UI/UX Designer |
| HUD | Gold, diamonds, equipped brainrots (icons or names). | UI/UX Designer |
| Inventory panel | Grid of brainrots; equip slots; merge button/flow. | UI/UX Designer |
| Battle UI | Player & enemy HP/Endurance bars; move buttons; turn indicator. | UI/UX Designer |
| Upgrade menu | List of upgrades (inventory, speed, equip); cost in diamonds; buy. | UI/UX Designer |
| Notifications | “Brainrot captured,” “Region unlocked,” “Merge successful.” | UI/UX Designer |
| Region unlock prompt | “Unlock Region 2 for X gold?” confirm/cancel. | UI/UX Designer |

---

## 3. Role-Based Responsibilities

### 3.1 CEO / Project Manager
| Responsibility | Details |
|----------------|---------|
| Planning & timelines | Set milestone dates; adjust when needed. |
| Team coordination | Sync between Scripter, 3D, Animator, UI/UX, HR. |
| Milestone tracking | Run milestone reviews; sign-off on “Definition of Done.” |
| Scope guard | Keep V1 to MVP; log V2 ideas in backlog. |
| Risk & blockers | Escalate blockers; assign risk owners. |

### 3.2 Lead Scripter
| Responsibility | Details |
|----------------|---------|
| Core gameplay | Starter choice, inventory, stats, merge, battle flow, capture chance. |
| Brainrot behavior | NPC roaming (pathfinding or simple movement); battle AI (move choice). |
| Player controls | Movement; interaction with NPCs, pickups, gates. |
| Server–client logic | Authority on server; client prediction/feedback; no exploits on critical data. |
| Data persistence | Save/load inventory, currency, unlocks, upgrades (DataStore). |
| Battle system | Turn order, move execution, damage formula, Endurance, win/lose. |
| Currency & rewards | Grant gold/diamonds on win; scatter in arena; collect logic. |
| Region unlock | Check gold; unlock Region 2; spawn player in new region. |

### 3.3 Animator
| Responsibility | Details |
|----------------|---------|
| Player character | Idle, walk (if custom); minimal for V1 if using default Roblox. |
| Brainrot animations | Idle, walk, attack (per move type), hurt, dizzy/defeated (stars). |
| Environmental interactions | Optional: collect pickup, merge spark. |
| Rigging & export | Rigs compatible with Roblox; export from Blender/Maya per protocol. |
| Animation list | Document animation IDs and naming for scripting. |

### 3.4 3D Modeler
| Responsibility | Details |
|----------------|---------|
| Player avatar | Use Roblox default or minimal custom; no weapon needed in V1. |
| Brainrot models | 3 starters + 3 merge results + 2–3 NPC types per region; low-poly, readable. |
| Environment | Region 1 and Region 2 terrain/builds; battle arena; gates/portals. |
| Props | Gold/diamond pickups; UI placeholders if needed. |
| LOD / performance | Optimize for mobile; part count and mesh guidelines. |

### 3.5 UI/UX Designer
| Responsibility | Details |
|----------------|---------|
| Menus | Starter screen, inventory, upgrades, region unlock. |
| HUD | Gold, diamonds, equipped brainrots; clear, minimal. |
| Battle UI | HP/Endurance bars, move buttons, turn feedback. |
| Popups & notifications | Capture, merge, unlock, errors (e.g. “Not enough gold”). |
| Feedback | Buttons states, transitions; responsive on different resolutions. |
| Design system | Colors, fonts, spacing; document for consistency. |

### 3.6 HRs
| Responsibility | Details |
|----------------|---------|
| Task allocation | Assign tasks from this plan to individuals; track capacity. |
| Documentation | Keep progress log; update task status; report to CEO/PM. |
| Onboarding | Ensure access to Roblox project, version control, asset naming. |
| Conflict & availability | Surface blockers; help with deadlines. |

---

## 4. Development Milestones

| # | Milestone | Description | Sign-off | Est. duration |
|---|------------|-------------|----------|----------------|
| **M1** | Concept & design approval | GDD + V1 scope + art direction approved; roles assigned. | CEO/PM | Week 0–1 |
| **M2** | Model & animation prototype | 1 starter brainrot + 1 NPC modeled, rigged, animated (idle, walk, attack, dizzy). Pipeline validated. | CEO/PM + Lead Scripter | Week 2–3 |
| **M3** | Core scripting & mechanics | Starter flow, inventory, stats, merge, battle (single brainrot type), capture chance, currency, 1 region. | Lead Scripter | Week 3–6 |
| **M4** | UI/UX integration | All V1 screens and HUD in-game; wired to scripts; no placeholders for core flows. | UI/UX + Lead Scripter | Week 5–7 |
| **M5** | Internal testing & debugging | QA on all mechanics; bug triage; fixes; balance pass (damage, capture rate, costs). | All + HRs | Week 7–8 |
| **M6** | MVP build ready for playtesting | Full V1 loop (2 regions, all brainrots, upgrades); build packaged; playtest plan ready. | CEO/PM | Week 8–9 |

---

## 5. Technical Requirements

### 5.1 Roblox Studio Setup & Project Structure
| Item | Requirement |
|------|-------------|
| Place structure | Single place; clear hierarchy: `ReplicatedStorage` (shared modules), `ServerScriptService`, `StarterPlayer`, `Workspace` (regions, arenas), `StarterGui`. |
| Script layout | `ServerScriptService`: main game logic, DataStore, battle authority. `StarterPlayerScripts`: input, UI events. `ReplicatedStorage`: shared config (stats, moves, costs). |
| Naming | PascalCase for scripts/modules; folders: `Scripts`, `Modules`, `Config`, `Assets`. |

### 5.2 Version Control & Collaboration
| Item | Guideline |
|------|------------|
| Tool | Use Rojo + Git (or approved VCS); sync to Roblox from main branch. |
| Branches | `main` = stable; feature branches per mechanic (e.g. `feature/battle-system`). |
| Commits | Clear messages; link to task/milestone where possible. |
| Conflicts | Scripts and place file; designate merge owner (e.g. Lead Scripter). |

### 5.3 Asset Organization
| Asset type | Location (example) | Naming |
|------------|--------------------|--------|
| Brainrot models | `ReplicatedStorage.Assets.Brainrots` or `Workspace` template | `Brainrot_[Name]_Tier[N]` |
| Animations | `ReplicatedStorage.Assets.Animations` or Animation folder | `Anim_[Brainrot]_[Idle/Walk/Attack/Dizzy]` |
| UI layouts | `StarterGui` | `Screen_[Name]`, `HUD_Main` |
| Config (stats, moves) | `ReplicatedStorage.Config` | `BrainrotStats`, `Moves`, `Upgrades` |

### 5.4 Coding Standards & Naming Conventions
| Area | Standard |
|------|----------|
| Lua style | snake_case for locals; PascalCase for modules/classes; clear names. |
| Events | RemoteEvents/RemoteFunctions named by purpose: `BattleRequest`, `MergeComplete`. |
| Constants | UPPER_SNAKE for config; no magic numbers in battle/damage formulas. |
| Comments | Brief purpose for modules and complex functions; keep comments up to date. |

### 5.5 Animation Rigging & Export Protocols
| Item | Protocol |
|------|----------|
| Rig | Humanoid or custom rig; consistent bone names; documented for Animator. |
| Export | FBX or direct Roblox upload; same scale/orientation across brainrots. |
| Naming | `[BrainrotName]_[AnimationType]_v[1]`; list in shared doc or Config. |
| Testing | Animator provides; Scripter hooks in Studio; test on default + mobile. |

---

## 6. Testing & QA

### 6.1 Test Cases (Gameplay Mechanics)
| # | Area | Test case | Expected |
|---|------|-----------|----------|
| 1 | Starter | New player sees 3 options; selects one; brainrot in inventory. | One starter in inventory; no duplicates. |
| 2 | Equip | Equip 1–3 brainrots; unequip; try equip 4th. | Max 3 equipped; 4th rejected. |
| 3 | Battle | Click NPC with brainrot equipped; complete battle. | Transition to arena; turns; win or lose. |
| 4 | Capture | Win battle; check capture chance. | Sometimes brainrot added; notification. |
| 5 | Currency | Win battle; collect all gold/diamonds. | +35 gold, +3 diamonds; cannot leave before collect. |
| 6 | Merge | Two same brainrots; merge. | One next-tier brainrot; two removed. |
| 7 | Upgrade | Spend diamonds on inventory/speed/equip. | Effect applied; balance decreased. |
| 8 | Region unlock | Have enough gold; unlock Region 2. | Gate opens; can enter Region 2. |
| 9 | Save/Load | Play, earn progress; rejoin. | Currency, inventory, unlocks, upgrades persist. |

### 6.2 Bug Tracking & Reporting
| Item | Process |
|------|---------|
| Tool | Use a simple board (e.g. Trello, Notion, spreadsheet): Backlog, In Progress, Testing, Done. |
| Report fields | Title, steps, expected vs actual, severity (Critical/High/Medium/Low), reporter, build. |
| Triage | CEO/PM or Lead Scripter assigns; Critical/High fixed before MVP release. |

### 6.3 Player Feedback (Post–playtest)
| Item | Use |
|------|-----|
| Playtest form | Short survey: clarity of loop, difficulty, fun, biggest confusion. |
| Metrics | Session length, battles per session, merge count, where players drop off. |
| V1 improvement | Prioritize 3–5 changes for a small post-MVP patch before V2. |

---

## 7. Delivery & Deployment

### 7.1 Build Packaging
| Step | Owner | Details |
|------|--------|--------|
| Final build | Lead Scripter | All V1 features in one place; no test scripts in production. |
| Config check | Lead Scripter | Costs, capture rates, stats in config (no hardcode). |
| Asset audit | 3D Modeler / UI/UX | No duplicate or unused assets; names match plan. |

### 7.2 Server Setup
| Item | Requirement |
|------|-------------|
| Reserved servers | Optional for V1; use default Roblox servers if acceptable. |
| Capacity | Estimate concurrent players; set max players per server if needed. |
| DataStore | Enable Studio API; use one main DataStore key per player; error handling and retries. |

### 7.3 Publishing on Roblox
| Step | Owner |
|------|--------|
| Game icon & description | UI/UX or CEO/PM |
| Age / genre / tags | CEO/PM |
| Upload place | Lead Scripter |
| Publish to public or “Friends” first | CEO/PM |

### 7.4 Post-Launch Monitoring Plan
| Action | Owner | Frequency |
|--------|--------|-----------|
| Crash/error logs | Lead Scripter | Daily (first week), then weekly |
| DataStore failures | Lead Scripter | Alerts if possible; daily check early on |
| Player count & retention | CEO/PM | Weekly |
| Top reported bugs | HRs / CEO/PM | Triage within 48 hours |
| Small patch plan | CEO/PM | One patch 1–2 weeks after launch for critical fixes |

---

## 8. Timeline & Dependencies

### 8.1 Suggested Timeline (Weeks 0–9)

| Week | Focus | Key deliverables |
|------|--------|-------------------|
| 0–1 | M1 Concept & design | Approved scope; roles; art direction; task list |
| 2 | M2 Start | 3D: 1 brainrot model; Animator: rig + 4 anims |
| 3 | M2 Complete | All 3 starters + 1 NPC modeled/animated; pipeline doc |
| 4 | M3 Scripting | Starter + inventory + stats + merge + single-type battle |
| 5 | M3 Scripting | Full battle + capture + currency + Region 1 + Region 2 unlock |
| 6 | M3 Complete | DataStore; polish; all NPC types in |
| 5–6 | M4 UI start | Screens designed; implemented in Studio |
| 7 | M4 Complete | All UI wired; no critical placeholders |
| 7–8 | M5 Testing | QA runs test cases; bug fix sprint |
| 8–9 | M6 MVP | Final build; playtest; package & publish |

### 8.2 Dependencies Between Roles

```
Concept (M1)
    │
    ├── 3D Modeler: Brainrot models ──────────┐
    │                                         │
    ├── Animator: Rig + anims (needs model) ──┼──→ M2 Prototype
    │                                         │
    └── Lead Scripter: Place structure, config (no model dependency for logic)
    │
    ├── After M2: Lead Scripter: Full mechanics (battle uses model + anims)
    │
    ├── UI/UX: Can start after M1 (mockups); integration needs scripts (M3)
    │
    └── M4: UI/UX + Lead Scripter integrate
    │
    M5: All roles (testing, fixes)
    │
    M6: CEO/PM sign-off → Deploy
```

| Dependency | Blocker | Waits for |
|------------|---------|-----------|
| Battle in-game | Battle script needs brainrot instance + animation IDs | M2 (model + anims) |
| UI integration | Buttons/events need script APIs | M3 (script interfaces) |
| Full environment | Region 2 + arena layout | 3D Modeler (Week 3–4) |
| Capture/dizzy | Dizzy animation | Animator (M2) |

### 8.3 Task-Level Time Estimates (Summary)

| Role | Tasks | Estimated time |
|------|--------|----------------|
| CEO/PM | Kickoff, milestones, sync, sign-offs, risk | ~2–3 days per milestone |
| Lead Scripter | Full V1 systems, DataStore, integration | ~6–7 weeks full-time equivalent |
| 3D Modeler | 2 regions, 6+ brainrots, props, arena | ~4–5 weeks |
| Animator | 6+ brainrots × 4+ anims each | ~3–4 weeks (after models) |
| UI/UX Designer | 6+ screens, HUD, notifications | ~2–3 weeks design + 1–2 integration |
| HRs | Tasks, docs, progress | Ongoing ~0.5 day/week |

---

## 9. Additional Notes

### 9.1 Placeholders for Future V2 Features
| V2 Feature | V1 Placeholder |
|------------|----------------|
| PvP | No UI; optional comment in code: `-- V2: PvP battle request`. |
| More upgrades | Only 3 upgrades in UI; config table can already support more entries. |
| Daily rewards | No UI; optional `PlayerJoined` hook with comment for daily reward. |
| Win animations | No purchase; optional `OnBattleWin` event for future animation trigger. |
| Spawn scaling | NPCs can spawn at fixed tiers per region; no “average player strength” math. |
| More regions | Region unlock script accepts region ID; adding Region 3 in V2 is config + map. |

### 9.2 Risk Mitigation (Common Roblox Challenges)

| Risk | Mitigation |
|------|------------|
| DataStore throttling/loss | Retry logic; fallback to session-only if load fails; don’t save every second. |
| Exploits (currency/items) | All rewards and merges on server; validate costs and capture chance on server. |
| Performance on mobile | Limit parts in view; simple effects; test on low-end device early. |
| Merge/battle desync | Single source of truth on server; client shows results after server confirms. |
| Scope creep | Strict V1 list; “nice to have” goes to V2 backlog. |
| Model/anim delay | M2 early; one brainrot done end-to-end before scaling to all. |
| Animation import issues | Agree rig + export format in M1; test one asset in Week 2. |

---

## 10. Quick Reference — Responsibility Matrix

| Deliverable | CEO/PM | Lead Scripter | 3D Modeler | Animator | UI/UX | HRs |
|-------------|--------|---------------|------------|----------|--------|-----|
| Scope & milestones | ● Owner | Consult | Consult | Consult | Consult | Track |
| Place & scripts | Approve | ● Owner | — | — | — | — |
| Brainrot models | — | — | ● Owner | — | — | — |
| Animations | — | Integrate | — | ● Owner | — | — |
| All UI screens | Approve | Wire logic | — | — | ● Owner | — |
| Testing & bugs | Prioritize | Fix | — | — | Fix UI | Log |
| Publish & monitor | ● Owner | Build & logs | — | — | — | Report |

---

*End of V1 Development Plan. Revise as needed; document changes in version control.*
