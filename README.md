
# Roblox Magnet Game – Full Developer Documentation

## Overview
The Roblox Magnet Game is a fishing-style magnet simulator where players throw magnets, reel in catches through a minigame, and collect items of varying rarities. Players can sell items for coins, buy upgrades, track their collection in a journal, and level up for progression.

This README serves as the complete technical documentation for all scripts, their connections, data formats, and key gameplay constants.

---

## Script Map

### **Server Scripts** (`ServerScriptService`)

#### **MagnetGame.server.lua**
- **Purpose:** Core gameplay logic controlling throws, catching, minigame flow, XP, coins, backpack inventory, upgrades, and journal entries.
- **Key Functions:**
  - Validates throws.
  - Picks fish rarity/type.
  - Starts and ends reel minigame.
  - Awards XP and coins.
  - Handles selling and upgrades.
- **Connections:**
  - Communicates with all client UIs via `ReplicatedStorage` RemoteEvents.
- **Critical Notes:** Do not rename RemoteEvents or change payload formats without updating all client scripts.

#### **DayNight.server.lua**
- **Purpose:** Controls the in-game day/night cycle with smooth lighting changes.
- **Connections:** No direct server→client communication. Modifies `Lighting` service properties.
- **Critical Notes:** Cosmetic but noticeable. Cycle length is configurable.

---

### **Client Tool Scripts** (`StarterPack/Magnet`)

#### **Client.local.lua**
- **Purpose:** Controls Magnet tool behavior — charging throws, creating power meter UI, aiming, and starting reel minigame.
- **Connections:** Sends `CastMagnet` to server, listens for `OpenReel` and `ReelEnded`.
- **Critical Notes:** UI is dynamically created; must match server's `CastMagnet` expectations.

---

### **UI Scripts** (`StarterGui`)

#### **ReelMinigame/ReelUI.local.lua**
- **Purpose:** Fishing-style reel minigame UI and logic.
- **Connections:** Listens to `OpenReel`, `ReelResult`, `CatchResult`, `JournalDiscover` from server.
- **Critical Notes:** Complex — contains physics simulation for fish movement.

#### **BackpackUI/BackpackUI.local.lua**
- **Purpose:** Displays player's backpack inventory, allows item deletion.
- **Connections:** `RequestBackpack`, `BackpackData`, `RemoveBackpackItem`.
- **Critical Notes:** Shows rarity colors; deletion sends requests to server.

#### **UpgradeShop/UpgradeUI.local.lua**
- **Purpose:** Upgrade shop UI for Luck, Reel Speed, and Magnet Strength.
- **Connections:** `OpenShopRE`, `BuyUpgradeRE`.
- **Critical Notes:** Must match server upgrade cost/level structure.

#### **XPProgress/XPProgress.local.lua**
- **Purpose:** XP progress bar and level display.
- **Connections:** `XPUpdate` from server.
- **Critical Notes:** Animates smoothly; uses debounce for rapid XP events.

#### **HUDMessages/HUDMessages.local.lua**
- **Purpose:** Displays floating HUD text messages for important events.
- **Connections:** `GameMessageRE`, `SellAllResultRE`.
- **Critical Notes:** Cosmetic but important for feedback.

#### **JournalUI/JournalUI.local.lua**
- **Purpose:** Displays discovered fish species in a paginated journal.
- **Connections:** `RequestJournal`, `JournalData`, `JournalDiscover`.
- **Critical Notes:** Tracks player collection — tied to progression.

#### **MagnetHUD/ClientHUD.local.lua**
- **Purpose:** Cleans old UI remnants from HUD.
- **Connections:** None — maintenance only.

---

### **Player Experience Scripts** (`StarterPlayerScripts`)
- **AutoEquipMagnet.local.lua** — Equips Magnet on spawn.
- **BackgroundMusic.local.lua** — Plays looping background music.
- **DoubleJump.local.lua** — Adds double jump ability.
- **NoDropMagnet.local.lua** — Prevents dropping Magnet.
- **OverheadLevels.local.lua** — Shows player level above heads.
- **SearchingUI.local.lua** — Shows searching UI during fishing wait.
- **Sprint.local.lua** — Allows sprinting with Shift key.
- **XPBillboard.local.lua** — Shows XP gain above players.

---

## System Architecture

![System Diagram](diagram.png)

**Core Flow:**
1. **Throw Magnet** → Client tool sends `CastMagnet` to server.
2. **Server Bite Simulation** → After delay, server chooses fish & starts reel minigame.
3. **Reel Minigame** → Client plays UI game; sends result.
4. **Result Handling** → Server adds to backpack, updates journal, awards XP.
5. **Selling & Upgrades** → Player interacts with shop to sell items or buy upgrades.

---

## RemoteEvents & RemoteFunctions

**From Client to Server:**
- `CastMagnet(power)`
- `ReelResult(success)`
- `RemoveBackpackItem(itemId)`
- `BuyUpgrade(type)`
- `RequestBackpack()`
- `RequestJournal()`

**From Server to Client:**
- `OpenReel(data)`
- `CatchResult(data)`
- `JournalDiscover(entry)`
- `XPUpdate(level, xp, need, delta)`
- `GameMessageRE(messageType)`
- `SellAllResultRE(amount)`

---

## Data Structures

**Backpack Item:**
```lua
{
  id = number,
  name = string,
  weight = number,
  rarity = string
}
```

**Journal Entry:**
```lua
{
  name = string,
  rarity = string,
  found = boolean
}
```

**Upgrade State:**
```lua
{
  luckLevel = number,
  reelSpeedLevel = number,
  magnetStrengthLevel = number
}
```

---

## Gameplay Constants
- **Rarities:** Common, Rare, Epic, Legendary (color coded in UIs).
- **Day/Night Cycle:** 10 minutes total.
- **Upgrades:**
  - Luck — increases rare catch odds.
  - Reel Speed — increases fish hold in minigame.
  - Magnet Strength — increases throw range and speed.
