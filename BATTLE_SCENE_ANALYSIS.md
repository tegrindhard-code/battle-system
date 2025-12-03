# Battle Scene Structure Analysis

## Issue Found: Missing Doubles Battle Position Parts

### Current bscene.rbxmx Structure

**Model Name:** ArediaNight

**Parts Found:**
- ✅ `_User` - Player side position (5, 1.9, -2), Size: 2×3×0.2
  - Has `Gui` (SurfaceGui) child
- ✅ `_Foe` - Opponent side position (5, 1.9, 9), Size: 2×3×0.2
  - Has `Gui` (SurfaceGui) child
- ❌ `pos11` - Missing (Player doubles position 1)
- ❌ `pos12` - Missing (Player doubles position 2)
- ❌ `pos21` - Missing (Opponent doubles position 1)
- ❌ `pos22` - Missing (Opponent doubles position 2)

### Distance Calculation
- **Z-axis separation:** 11 studs (9 - (-2))
- **Same X coordinate:** 5
- **Same Y coordinate:** 1.9

### Code References Requiring These Parts

#### 1. BattleEngine.lua:278
```lua
for _, partName in pairs({'_User', '_Foe', 'pos11', 'pos12', 'pos21', 'pos22'}) do
```
Iterates over all position parts including doubles positions.

#### 2. MoveAnimations.lua:128, 133
```lua
names = {'pos21', 'pos22', 'pos23'}  -- Opponent team
names = {'pos11', 'pos12', 'pos13'}  -- Player team
```
Uses these parts for team-based move animations.

#### 3. Sprite.lua:1491
```lua
local posPart = self.battle.scene:FindFirstChild('pos'..self.siden..slot)
    or self.battle.scene[self.siden == 1 and '_User' or '_Foe']
```
Tries to find `pos##` first, falls back to `_User/_Foe` for singles.

### Impact

**Singles Battles:** Will work (fallback to _User/_Foe)
**Doubles Battles:** Will NOT work properly (missing dedicated positions)
**Move Animations:** May fail or position incorrectly for team moves

### Recommended Structure

The battle scene should have these parts:

```
ArediaNight (Model)
├── _User (Part) - Singles fallback for side 1
│   └── Gui (SurfaceGui)
├── _Foe (Part) - Singles fallback for side 2
│   └── Gui (SurfaceGui)
├── pos11 (Part) - Player Pokemon #1 (doubles)
│   └── Gui (SurfaceGui)
├── pos12 (Part) - Player Pokemon #2 (doubles)
│   └── Gui (SurfaceGui)
├── pos21 (Part) - Opponent Pokemon #1 (doubles)
│   └── Gui (SurfaceGui)
└── pos22 (Part) - Opponent Pokemon #2 (doubles)
    └── Gui (SurfaceGui)
```

### Recommended Positioning

Based on current _User/_Foe positions, suggest:

**Singles (existing):**
- `_User`: (5, 1.9, -2)
- `_Foe`: (5, 1.9, 9)

**Doubles (to add):**

**Player side (Z = -2):**
- `pos11`: (3.5, 1.9, -2) - Left position, -1.5 studs from center
- `pos12`: (6.5, 1.9, -2) - Right position, +1.5 studs from center

**Opponent side (Z = 9):**
- `pos21`: (6.5, 1.9, 9) - Left position (mirrored), +1.5 studs from center
- `pos22`: (3.5, 1.9, 9) - Right position (mirrored), -1.5 studs from center

Note: Opponent positions are mirrored (left/right swapped) because they face the player.

### Part Properties

All position parts should have:
- **Size:** 2 × 3 × 0.2 (consistent with existing)
- **Transparency:** 1 (invisible)
- **Anchored:** true
- **CanCollide:** false
- **Material:** Plastic (or current material)
- **Child:** SurfaceGui named "Gui" (for 2D sprite rendering)

### Additional Notes

**Triple Battles:**
MoveAnimations.lua references `pos13` and `pos23` (not yet implemented)
BattleEngine.lua has a "todo: triples" comment

**Current Workaround:**
Singles battles will continue to work with just _User/_Foe, but doubles battles require the pos## parts.

## Fix Required

The bscene.rbxmx file needs to be updated in Roblox Studio to include the four missing position parts (pos11, pos12, pos21, pos22) with the recommended positioning and properties above.
