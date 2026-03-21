GAME CODEBASE STRUCTURE
========================

SERVER SCRIPTS (ServerScriptService)
------------------------------------
Scripts:
├── ServerMain
├── LeaderboardSetup
├── MergeHandler
├── Admin
├── InventoryHandler
└── BattleSystemTest

ModuleScripts:
├── BrainrotModels

Data/
├── DataStoreServiceHandler
└── PlayerDataManager

Services/
├── InventoryService
├── StarterService
├── ResetStarterService
├── ValuablesService
├── MergeService
└── CurrencyService

Systems/
└── ValuablesSystem


CLIENT SCRIPTS (StarterPlayer/StarterPlayerScripts)
---------------------------------------------------
ClientControllers/
├── StarterSelectionController
├── InventoryController
├── HotbarController
├── HUDController
├── MergeController
├── CurrencyController
├── ValuableController
├── ChooseBrainrotTeamController
├── ChooseBrainrotTeamUI1(main)
└── ChooseBrainrotTeamUI2(useless dont use)


UI SCRIPTS (StarterGui)
-----------------------
ResetButtonUI/
└── ResetButtonController

HUD/
└── Multiple HoverHoldAnimation scripts for buttons

MergeBrainrotsUI/
└── HoverAnimation and HoverHoldAnimation scripts

OnboardingUI/
└── HoverAnimation scripts for brainrot selection

ChooseBrainrotTeamUI/
└── HoverAnimation and HoverHoldAnimation scripts

UpgradesUI/
└── HoverAnimation scripts for upgrade buttons

InventoryUI/
└── HoverAnimation and HoverHoldAnimation scripts

SettingsUI/
└── HoverAnimation scripts for toggle buttons

Confirmation/
└── HoverAnimation scripts for purchase buttons


SHARED MODULES (ReplicatedStorage)
----------------------------------
Config/
├── BrainrotStats
├── MergeMap
├── Moves
├── GameConfig
└── BattleConfig

Modules/
├── DamageFormula
├── BattleResult
├── BattleSystem
└── Brainrots/
    └── Brainrots

Remotes/
├── SelectStarterBrainrot (RemoteEvent)
├── RequestStarterOptions (RemoteFunction)
├── ResetStarterChoice (RemoteFunction)
├── ResetPlayer (RemoteEvent)
├── ValuablesCollected (RemoteEvent)
├── ValuableCollected (RemoteEvent)
├── SaveTeam (RemoteEvent)
└── PurchaseSlot (RemoteEvent)

Events/
└── OpenMergeUI (BindableEvent)


SERVER STORAGE (ServerStorage)
------------------------------
Libraries/Dictionaries/
├── BrainrotsDictionary
└── ChestsDictionary


ASSETS (ReplicatedStorage)
--------------------------
BrainrotModels/
└── 90+ character models (Ballerina Cappuccina, Bombardiro Crocodilo, etc.)

Items/
└── 90+ Tool items matching the models

Other/
└── ModelVariants

MoonAnimatorBackups/


BACKUP SCRIPTS (Workspace)
--------------------------
Scripts_Outdated_Backup/
├── LeaderboardSetup
├── ResetButtonController
└── Inventory


ARCHITECTURE SUMMARY
====================
Server-side: 6 main scripts + 9 service/system modules + 2 data modules
Client-side: 10 controller scripts + 50+ UI animation scripts
Shared config: 5 configuration modules
Shared modules: 4 utility modules
Communication: 8 RemoteEvents/Functions for client-server communication
Assets: 90+ Brainrot character models and corresponding tool