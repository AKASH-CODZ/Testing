# Lobby Scripts

This directory contains all the scripts for the Lobby place.

## Server Scripts (`ServerScriptService`)

*   **`InventoryService.lua`:** Manages the player's inventory on the server.
*   **`PlayerManager.lua`:** Manages loading and saving of player data using `ProfileService`.
*   **`QueueManager.lua`:** Manages matchmaking queues for various game modes.
*   **`SecurityManager.lua`:** Consolidates all security-related logic.

## Modules (`ReplicatedStorage/Modules`)

*   **`ButtonAnimationController.lua`:** Handles all button animations and effects.
*   **`GameConfig.lua`:** Single source of truth for all game configuration.
*   **`GameStateManager.lua`:** Manages the state of each player.
*   **`InventoryDataProvider.lua`:** Manages inventory data on the client side.
*   **`ItemContainerManager.lua`:** Manages the creation and rendering of inventory item UI elements.
*   **`Logger.lua`:** Provides a simple and robust logging system.
*   **`PlayerDataHandler.lua`:** Defines the data structure for player profiles.
*   **`ProfileService.lua`:** The core `ProfileService` module.
*   **`SearchBarController.lua`:** Manages the search bar functionality.

## Client Scripts (`StarterPlayer/StarterPlayerScripts`)

*   **`InventoryUIManager.lua`:** Manages the inventory UI.
*   **`StandardModeButton.lua`:** Handles the functionality of a UI button that initiates a teleport.
