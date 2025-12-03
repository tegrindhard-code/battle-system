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

---

# Pikachu Model Pivot Issue (lol.rbxmx)

## Problem: Model Pivot Way Off

The Pikachu model in `lol.rbxmx` has incorrect pivot positioning that will cause it to appear in the wrong location during battles.

### Current Pivot Position
- **PrimaryPart:** "RootPart"
- **Position:** (4.67, 0.29, -1.97)
- **Rotation:** 180° around Y-axis (facing backwards)
- **Size:** Tiny (0.0035 × 0.0035 × 0.0017 studs)

### Expected Position (_User reference)
- **Position:** (5, 1.9, -2)

### Offset Analysis
| Axis | Model Pivot | _User Target | Offset |
|------|-------------|--------------|--------|
| X    | 4.67        | 5.0          | -0.33  |
| **Y**| **0.29**    | **1.9**      | **-1.61** ⚠️ |
| Z    | -1.97       | -2.0         | +0.03  |

### Critical Issues

1. **Pivot Way Off from Mesh Geometry** ⚠️⚠️⚠️
   - **Pivot (RootPart):** 0.0035 studs at (4.67, 0.29, -1.97)
   - **Actual mesh geometry:** Positioned elsewhere in world space
   - **When ScaleTo(0.1) is applied:** Scales around the tiny ground-level pivot
   - **Result:** Model appears MASSIVE and in completely wrong location
   - **Why:** Mesh is far from pivot, so even after 0.1x scaling, visible parts are still huge/offset

2. **Y-Position Too Low (-1.61 studs)**
   - Model pivot is at ground level (Y=0.29)
   - Should be at center of Pokemon (Y≈1.9)
   - Combined with issue #1, makes model appear way off

3. **Facing Backwards (180° rotation)**
   - Rotation matrix shows R00=-1, R22=-1
   - Pokemon will face away from opponent
   - Needs to face opponent (towards +Z)

### Root Cause

This looks like a model exported from Blender where:
- The armature root/origin was placed at world origin (0,0,0)
- The actual mesh geometry is positioned elsewhere (likely 5-10+ studs away)
- Roblox uses the RootPart position as the pivot for scaling/positioning

**What happens when Sprite.lua runs:**
```lua
self.model3D:ScaleTo(0.1)  -- Scales to 10% around the pivot point
self.model3D:MoveTo(posPart.Position)  -- Moves the pivot to battle position
```

**The problem:**
1. Pivot is at (4.67, 0.29, -1.97) - tiny RootPart
2. Actual Pikachu mesh is positioned 50+ studs away (estimated)
3. When scaled to 0.1x around that distant pivot, the mesh is still huge
4. When MoveTo() positions the pivot at _User, the mesh appears way off

**Example calculation:**
- If mesh is 100 studs from pivot
- After 0.1x scale: mesh is still 10 studs from pivot
- Model appears 10 studs away from where it should be
- And appears 10x larger than intended

### Fix in Roblox Studio

**Option 1: Move Model Pivot (Recommended)**
1. Open lol.rbxmx in Roblox Studio
2. Select the "Pikachu" model
3. Use "Edit Pivot" tool (Alt+P)
4. Move pivot to center of model visually
5. Should be roughly at Pikachu's center of mass (chest/belly area)
6. Save the model

**Option 2: Adjust in Blender Before Export**
1. In Blender, position the armature root at Pokemon's center
2. Apply all transforms (Ctrl+A → All Transforms)
3. Ensure "origin to geometry" is centered
4. Re-export using textureconverter.py
5. Import to Roblox with correct pivot

### Expected Correct Pivot

For a Pokemon model that's properly centered:
- **Y-position:** Should be at model's vertical center (not ground)
- **Rotation:** Should face +Z direction (towards opponent)
- **Visual check:** When MoveTo() is called, Pokemon appears centered at the target position

### Testing in Game

After fixing pivot:
```lua
-- In Sprite.lua, this should center the model properly
self.model3D:MoveTo(posPart.Position)
-- If pivot is correct, model appears centered on _User/_Foe
-- If pivot is wrong, model appears offset or underground
```

### Workaround in Code (NOT RECOMMENDED)

Could add offset in Sprite.lua, but this is a **bad solution**:
```lua
-- BAD: Model-specific hardcoded offset
local yOffset = 1.6  -- Compensate for low pivot
self.model3D:MoveTo(posPart.Position + Vector3.new(0, yOffset, 0))
```

**Why this is bad:**
- Requires per-model offset data
- Doesn't fix rotation issue
- Makes all models harder to manage
- Proper pivot is the correct solution

## Summary

**Battle Scene (bscene.rbxmx):**
- Missing pos11, pos12, pos21, pos22 parts for doubles battles
- **Status**: Needs manual fix in Roblox Studio

**Pikachu Model (lol.rbxmx):**
- Pivot 1.6 studs too low (model geometry positioned far from pivot)
- Facing backwards (180° rotation)
- **Status**: ✅ FIXED PROGRAMMATICALLY - Automatic pivot offset correction implemented
- No manual Studio fixes required - the code now handles this automatically!
