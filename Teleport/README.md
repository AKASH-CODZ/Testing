# Teleport Scripts

This directory contains all the scripts for the Teleport (Game Place).

## Server Scripts (`ServerScriptService`)

*   **`GameplayManager.lua`:** Manages the gameplay logic for the teleported place.
*   **`LoadoutManager.lua`:** Retrieves player loadouts from the `MemoryStoreQueue`.
*   **`PlayerManager.lua`:** Manages loading and saving of player data using `ProfileService`.
*   **`TeleportManager.lua`:** Handles teleportation requests from clients.

## Modules (`ReplicatedStorage/Modules`)

*   **`GameConfig.lua`:** Single source of truth for all game configuration.
*   **`GameStateManager.lua`:** Manages the state of each player.
*   **`Logger.lua`:** Provides a simple and robust logging system.
*   **`PlayerDataHandler.lua`:** Defines the data structure for player profiles.
*   **`ProfileService.lua`:** The core `ProfileService` module.
*   **`SecurityManager.lua`:** Consolidates all security-related logic.

## Client Scripts (`StarterPlayer/StarterPlayerScripts`)

*   **`ReturnToLobby.lua`:** Manages the "Return to Lobby" button.
