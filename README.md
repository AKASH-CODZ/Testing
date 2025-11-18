# NEXTGEN Architecture Update

This document outlines the new "Universe Sharing" architecture implemented in this project, which uses `ProfileService` by loleris to ensure data persistence and security across all places within the experience.

## Core Concepts

### Universe Sharing

All places within this experience (Lobby, Game Places, etc.) share the same `DataStore` backend. This allows for seamless data persistence without the need to pass data between places using `TeleportService`.

### ProfileService

`ProfileService` is a session-locking `DataStore` wrapper that ensures data integrity and prevents data loss. It works by "locking" a player's profile when they join a server, preventing other servers from writing to their data simultaneously.

## Data Flow

1.  **Player Joins Lobby:** The `PlayerManager` in the `Lobby` loads the player's profile using `ProfileService`.
2.  **Player Enters Game Place:** The player is teleported to a game place.
3.  **Player Joins Game Place:** The `PlayerManager` in the `Game Place` loads the player's profile. `ProfileService` handles the session lock, ensuring that the `Lobby`'s session is released before the `Game Place`'s session is acquired.
4.  **Player Wins Match:** The `GameplayManager` in the `Game Place` updates the `TotalWins` value directly in the player's profile data.
5.  **Player Returns to Lobby:** The `TeleportManager` in the `Game Place` releases the player's profile using `profile:Release()`. This saves the updated data to the `DataStore` and releases the session lock.
6.  **Player Rejoins Lobby:** The `PlayerManager` in the `Lobby` re-loads the player's profile, which now contains the updated `TotalWins` value.

## Key Modules

*   **`ProfileService.lua`:** The core `ProfileService` module.
*   **`PlayerDataHandler.lua`:** Contains the `ProfileTemplate`, which defines the default data structure for new players.
*   **`PlayerManager.lua`:** Handles loading and releasing player profiles.
*   **`GameplayManager.lua`:** (Game Place only) Handles game logic and updates player stats.
*   **`TeleportManager.lua`:** (Game Place only) Handles releasing player profiles before teleporting.
