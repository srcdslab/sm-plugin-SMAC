# SMAC (SourceMod Anti-Cheat) Development Guidelines

## Repository Overview

This repository contains SMAC (SourceMod Anti-Cheat), a comprehensive anti-cheat system for Source engine games. SMAC is a collection of SourcePawn plugins that detect various cheating methods including aimbots, wallhacks, speedhacks, and other exploits. The system supports multiple Source engine games (CS:S, CS:GO, TF2, L4D2, etc.) and integrates with ban management systems.

**Key Components:**
- 16 anti-cheat detection modules (aimbot, wallhack, speedhack, etc.)
- Core SMAC framework with shared functionality
- Game-specific fixes and optimizations
- Multi-language translation support
- Integration with SourceBans/SourceBans++

## Technical Environment

- **Language**: SourcePawn
- **Platform**: SourceMod 1.12+ (minimum supported version)
- **Build Tool**: SourceKnight build system
- **Compiler**: SourcePawn compiler (spcomp) via SourceKnight
- **CI/CD**: GitHub Actions with automated builds and releases

### Dependencies
- SourceMod 1.11.0+ (build system uses 1.11.0-git6934)
- MultiColors include for colored chat messages
- SDKTools for Source engine integration
- Optional: SourceBans/SourceBans++ for ban management
- Optional: SM Rcon extension for RCON monitoring

## Project Structure

```
addons/sourcemod/
├── scripting/              # Source code (.sp files)
│   ├── include/            # Include files (.inc)
│   ├── _unsupported/       # Legacy/unsupported modules
│   ├── smac.sp            # Core SMAC plugin
│   ├── smac_aimbot.sp     # Aimbot detection module
│   ├── smac_wallhack.sp   # Wallhack detection module
│   └── smac_*.sp          # Other detection modules
└── translations/           # Multi-language phrase files
    ├── smac.phrases.txt    # Default English phrases
    └── */smac.phrases.txt  # Localized translations
```

### Key Files
- `sourceknight.yaml` - Build configuration and dependencies
- `smac.inc` - Main SMAC include with constants and API
- `smac_stocks.inc` - Shared utility functions
- `smac_wallhack.inc` - Wallhack detection utilities
- `smac_cvars.inc` - ConVar validation data

## Code Style & Standards

### General Conventions
- **Indentation**: Tabs (displayed as 4 spaces)
- **Semicolons**: Required (`#pragma semicolon 1`)
- **New declarations**: Required (`#pragma newdecls required`)
- **Line endings**: Unix-style (LF)
- **Encoding**: UTF-8
- **No trailing whitespace**

### Naming Conventions
- **Functions**: PascalCase (`OnPluginStart`, `SMAC_CreateConVar`)
- **Variables**: camelCase (`playerIndex`, `detectionCount`)
- **Global variables**: Prefix with `g_` (`g_hCvarAimbot`, `g_fEyeAngles`)
- **Constants**: UPPER_CASE (`SMAC_VERSION`, `AIM_ANGLE_CHANGE`)
- **ConVars**: snake_case with plugin prefix (`smac_aimbot_ban`)

### Required Headers
All `.sp` files must include the GPL license header:
```sourcepawn
/*
    SourceMod Anti-Cheat
    Copyright (C) 2011-2016 SMAC Development Team
    Copyright (C) 2007-2011 CodingDirect LLC
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#pragma semicolon 1
#pragma newdecls required
```

### Plugin Info Structure
```sourcepawn
public Plugin myinfo =
{
    name =          "SMAC Module Name",
    author =        SMAC_AUTHOR,
    description =   "Brief description of functionality",
    version =       SMAC_VERSION,
    url =           SMAC_URL
};
```

## Development Patterns

### Memory Management
- Use `delete` for Handle cleanup (no null check needed)
- **Never** use `.Clear()` on StringMap/ArrayList (creates memory leaks)
- Use `delete` and recreate instead of clearing collections
- Properly manage ConVar handles and timers

### Database Operations
- **All SQL queries must be asynchronous**
- Use SQL methodmaps for database operations
- Always use prepared statements to prevent SQL injection
- Escape user input with `SQL_EscapeString`
- Use transactions for multiple related operations
- Example:
```sourcepawn
Database.Query(MyCallback, "SELECT * FROM table WHERE id = %d", userId);
```

### Error Handling
- Always check return values from API calls
- Use proper error checking for database operations
- Handle edge cases and invalid client indices
- Validate client state before operations

### Translation Support
- Load translations in `OnPluginStart()`: `LoadTranslations("smac.phrases");`
- Use translation keys for all user-facing messages
- Support color codes in translations (`{green}`, `{red}`, etc.)
- Add new phrases to `translations/smac.phrases.txt`

### ConVar Management
- Create ConVars with `SMAC_CreateConVar()` function
- Add change hooks for dynamic updates
- Store handles in global variables with proper naming
- Example:
```sourcepawn
ConVar g_hCvarAimbotBan = null;
g_hCvarAimbotBan = SMAC_CreateConVar("smac_aimbot_ban", "0", "Description", 0, true, 0.0);
g_hCvarAimbotBan.AddChangeHook(OnSettingsChanged);
```

## Build & Validation Process

### Building
1. **Local Development**: Use SourceKnight build system
   ```bash
   sourceknight build
   ```

2. **CI/CD**: Automated builds via GitHub Actions
   - Triggers on push, PR, and manual dispatch
   - Builds all targets defined in `sourceknight.yaml`
   - Creates release packages with plugins and translations

### Targets
All plugins defined in `sourceknight.yaml` targets section:
- Core: `smac`
- Detection modules: `smac_aimbot`, `smac_wallhack`, `smac_speedhack`, etc.
- Game-specific: `smac_css_fixes`, `smac_l4d2_fixes`, etc.

### Testing
- Test on development servers before deployment
- Verify compatibility with target SourceMod version
- Check for memory leaks using SourceMod profiler
- Validate detection accuracy and false positive rates
- Test game-specific functionality on appropriate servers

## Performance Considerations

### Optimization Guidelines
- **Minimize timer usage** where possible
- **Cache expensive operations** and results
- **Avoid O(n) operations** in frequently called functions
- **Reduce string operations** in hot code paths
- **Consider server tick rate impact** for all operations
- **Use efficient data structures** (StringMap over arrays when appropriate)

### Critical Functions
- Event handlers (OnPlayerRunCmd, OnGameFrame)
- Timer callbacks
- Frame-based checks
- Real-time detection algorithms

## Game Support

### Supported Games
- Counter-Strike: Source (CSS)
- Counter-Strike: Global Offensive (CS:GO)
- Team Fortress 2 (TF2)
- Left 4 Dead 2 (L4D2)
- Day of Defeat: Source (DoD:S)
- Half-Life 2: Deathmatch (HL2DM)
- Fistful of Frags (FoF)
- Zombie Panic! Source (ZPS)
- And others...

### Game-Specific Code
Use `SMAC_GetGameType()` for game detection:
```sourcepawn
switch (SMAC_GetGameType())
{
    case Game_CSS:
    {
        // CSS-specific code
    }
    case Game_CSGO:
    {
        // CS:GO-specific code  
    }
    case Game_TF2:
    {
        // TF2-specific code
    }
}
```

## Common Patterns

### Module Structure
```sourcepawn
// Standard includes
#include <sourcemod>
#include <sdktools>
#include <smac>

// Global variables
ConVar g_hCvarExample = null;
Handle g_hDataStructure = INVALID_HANDLE;

// Plugin lifecycle
public void OnPluginStart()
{
    LoadTranslations("smac.phrases");
    // ConVar creation
    // Event hooks
    // Data structure initialization
}

public void OnPluginEnd()
{
    // Cleanup if necessary
}

public void OnClientConnected(int client)
{
    // Reset client-specific data
}
```

### Detection Pattern
```sourcepawn
void CheckForCheat(int client)
{
    if (!SMAC_IsValidClient(client))
        return;
        
    // Perform detection logic
    if (DetectionConditionMet)
    {
        g_iDetections[client]++;
        
        if (g_iDetections[client] >= threshold)
        {
            SMAC_PrintAdminNotice("%N was detected for cheating", client);
            
            if (g_iAutoBan > 0)
            {
                SMAC_LogAction(client, "Auto-banned for cheating");
                SMAC_Ban(client, "Cheating detected");
            }
        }
    }
}
```

## Documentation Requirements

### Code Comments
- **No unnecessary header comments** for plugins
- **Document complex logic sections** with inline comments
- **Explain detection algorithms** and thresholds
- **Note game-specific behaviors** and workarounds

### Include File Documentation
Document all native functions in `.inc` files:
```sourcepawn
/**
 * Brief description of function purpose
 *
 * @param client    Client index
 * @param reason    Reason for action
 * @return          True on success, false otherwise
 */
native bool SMAC_Function(int client, const char[] reason);
```

## Integration Guidelines

### SMAC API Usage
- Use `SMAC_IsValidClient()` for client validation
- Use `SMAC_CreateConVar()` for ConVar creation
- Use `SMAC_Ban()` for ban actions
- Use `SMAC_LogAction()` for logging
- Use `SMAC_PrintAdminNotice()` for admin notifications

### External Integrations
- **SourceBans++**: Preferred ban system integration
- **SourceBans**: Legacy support maintained
- **IRC plugins**: Notification support
- **Web panels**: Log integration support

## Version Control & Releases

- Use semantic versioning (MAJOR.MINOR.PATCH.BUILD)
- Version defined in `smac.inc` as `SMAC_VERSION`
- Tag releases for distribution
- Maintain changelog in README.md
- Automated releases via GitHub Actions

## Troubleshooting

### Common Issues
- **False positives**: Adjust detection thresholds
- **Performance**: Profile and optimize hot code paths
- **Compatibility**: Test with latest SourceMod versions
- **Memory leaks**: Check Handle management and collections

### Debugging
- Enable SMAC debug logging
- Use SourceMod's built-in profiler
- Test on isolated development servers
- Monitor server performance impact