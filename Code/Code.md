This is the Roblox game code workspace. We’ll collaborate here, then you’ll copy/paste the Roblox-ready scripts into Studio to test.

## How we’ll work
1. You tell me what you want (feature/bug), and which part of Roblox it affects (`ServerScriptService`, `StarterPlayerScripts`, `ReplicatedStorage`, etc.).
2. If relevant, you paste the current code (full file if possible) and any error message from the Output/console.
3. I will respond with:
   - The updated code blocks (Roblox Lua compatible)
   - Where each block should go (Script vs LocalScript vs ModuleScript, and the expected parent)
   - Any required assumptions (e.g., RemoteEvent names, folder paths)

## Roblox rules (important)
- Use Roblox APIs only (e.g., `Instance.new`, `Players`, `RunService`); avoid standard Lua IO/network libraries.
- Respect execution context: `ServerScriptService` = server only, `StarterPlayerScripts` = client only.
- If Remotes are needed, I’ll specify which `RemoteEvent/RemoteFunction` to create/use.

## Testing loop
1. You paste the script(s) into Studio.
2. Run Play and send me the exact error/log lines.
3. We iterate until it works.
