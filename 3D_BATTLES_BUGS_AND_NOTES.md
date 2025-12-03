# 3D Battles - Bugs and Implementation Notes

## Console Output Analysis (Session: 19:09:36-51)

### Status
- ✅ 3D mode toggle working correctly
- ✅ Constructor properly detects `battles3D = true`
- ✅ Fallback to 2D working when model ID not found
- ✅ 3D model loading successful for Pikachu

### Bugs Identified

#### 1. **Sprite.lua:1634** - "attempt to index nil with 'FindFirstChild'"
**Status**: Fixed in commit 31020b6, client needs reload
**Issue**: `self.part` is nil in 3D mode when checking for ParticleEmitter
**Fix**: Added check `if self.part and self.part:FindFirstChild('ParticleEmitter') then`
**Current Code (line 1634)**:
```lua
if self.part and self.part:FindFirstChild('ParticleEmitter') then
    self.part:FindFirstChild('ParticleEmitter'):Destroy()
end
```

#### 2. **BattleGui.lua:374** - "attempt to call missing method 'getPosition' of table"
**Status**: Fixed in commit 31020b6, client needs reload
**Issue**: `sprite:getPosition()` method not found
**Fix**: Added `Sprite:getPosition()` helper method (lines 209-219)
**Current Code**:
```lua
function Sprite:getPosition()
    if self.use3D and self.model3D and self.model3D.PrimaryPart then
        return self.model3D.PrimaryPart.Position
    elseif self.part then
        return self.part.Position
    else
        -- Fallback to battle coordinate frame
        local cf = self.battle and self.battle['CoordinateFrame'..self.siden]
        return cf and cf.p or Vector3.new(0, 0, 0)
    end
end
```

#### 3. **BattleGui.lua:303** - "attempt to index nil with 'main'"
**Status**: NEEDS FIX
**Issue**: `poke.statbar` is nil (statbar not created for 3D sprites?)
**Location**: `BattleGui:animAbility()`
**Code**:
```lua
posYO = poke.statbar.main.AbsolutePosition.y + poke.statbar.main.AbsoluteSize.y + 20
```
**Suggested Fix**: Add nil check for statbar
```lua
if poke.statbar and poke.statbar.main then
    posYO = poke.statbar.main.AbsolutePosition.y + poke.statbar.main.AbsoluteSize.y + 20
end
```

## Battle Field Structure

### Positioning Parts
- **_User**: Player's side (side 1)
- **_Foe**: Opponent's side (side 2)
- **pos11, pos12**: Player doubles positions
- **pos21, pos22**: Opponent doubles positions

### Coordinate System
```lua
-- From Battle.lua:2644-2645
self.CoordinateFrame1 = CFrame.new(scene._User.Position, scene._Foe.Position) + Vector3.new(0, -scene._User.Size.Y/2, 0)
self.CoordinateFrame2 = CFrame.new(scene._Foe.Position, scene._User.Position) + Vector3.new(0, -scene._Foe.Size.Y/2, 0)
```

## Scale Factor Estimation

### 2D Sprite Sizing
From code analysis:
```lua
-- Sprite.lua:1437-1441 (2D part creation)
local size = Vector3.new(sd.fWidth/25*scale, sd.fHeight/25*scale, 0.6)
```

Example calculations:
- 96x96 sprite: `96/25 = 3.84 studs`
- 120x120 sprite: `120/25 = 4.8 studs`
- Average sprite: **~3-5 studs**

### 3D Model Scale Factor

**Base Scale: 0.1** (10% of original model size) - **FIXED FOR ALL MODELS**

Reasoning:
1. **Consistent sizing**: All models use the same base scale
2. **Smaller than 2D**: Models at 10% provide better detail visibility
3. **Easier management**: No per-Pokemon scale adjustments needed

**Implementation**:
```lua
-- Sprite.lua:1496-1508
local baseModelScale = 0.1  -- Fixed scale for all Pokemon models
local spriteScale = sd.scale or 1.0  -- From GifData
local finalScale = baseModelScale * spriteScale

if self.alpha then
    finalScale = finalScale * dataChanges.alpha.size  -- 1.25x for alpha
end

-- Position at exact center (no offsets)
self.model3D:ScaleTo(finalScale)
self.model3D:MoveTo(posPart.Position)  -- Centered on _User/_Foe
```

### Model Positioning

**Centered positioning** (no sprite offsets):
- **Old**: `posPart.Position + Vector3.new(sd.xOffset or 0, sd.inAir or 0, 0)`
- **New**: `posPart.Position` (exact center)
- **Result**: Models appear smack dab in the middle of _User/_Foe parts

## Additional Fixes Needed

### Model-Specific Workarounds

#### 1. Model Validation
Before using model, verify:
```lua
if self.model3D.PrimaryPart then
    -- Safe to use :ScaleTo(), :MoveTo()
else
    warn("[3D BATTLES] Model has no PrimaryPart:", self.pokemon.species)
    self.use3D = false  -- Fallback to 2D
end
```

#### 2. Model Hierarchy
3D models need:
- ✅ PrimaryPart set (for positioning/scaling)
- ✅ Multiple parts (for ModelAnimator to work)
- ✅ Proper naming (no special characters that break animation)

#### 3. Missing Statbar
Statbar may not initialize for 3D sprites. Need to check:
- `BattleGui.lua:303` (animAbility)
- Any other statbar references
- Consider: Should 3D sprites have statbars?

## Testing Checklist

- [x] 3D mode toggle (Options page 3)
- [x] Model loading from ReplicatedStorage.Models
- [x] Fallback to 2D when model not found
- [x] Fallback to 2D when no model ID
- [x] Position calculation (getPosition helper)
- [x] Throwball animation
- [ ] Hit animations (BattleGui:animHit) - NEEDS TESTING
- [ ] Ability animations (BattleGui:animAbility) - BROKEN (line 303)
- [ ] Move animations
- [ ] Mega Evolution
- [ ] Dynamax/Gigantamax
- [ ] Statbar visibility/positioning

## Battle Scene Structure Issue

**Status**: ❌ CRITICAL - Battle scene missing doubles battle positions

### Problem
The `bscene.rbxmx` file is missing required position parts for doubles battles:
- ❌ Missing `pos11` (Player Pokemon #1)
- ❌ Missing `pos12` (Player Pokemon #2)
- ❌ Missing `pos21` (Opponent Pokemon #1)
- ❌ Missing `pos22` (Opponent Pokemon #2)

### Current Structure
- ✅ `_User` at (5, 1.9, -2) - Player side fallback
- ✅ `_Foe` at (5, 1.9, 9) - Opponent side fallback
- Both parts: Size 2×3×0.2, with Gui (SurfaceGui) child

### Impact
- **Singles battles:** Will work (uses _User/_Foe fallback)
- **Doubles battles:** Will NOT work properly
- **Team move animations:** May fail (MoveAnimations.lua expects pos11/12/21/22)
- **BattleEngine.lua:278:** Iterates over all 6 position parts

### Required Fix
Add the following parts to bscene.rbxmx in Roblox Studio:

**Player side (Z = -2):**
- `pos11`: (3.5, 1.9, -2), Size: 2×3×0.2, +Gui child
- `pos12`: (6.5, 1.9, -2), Size: 2×3×0.2, +Gui child

**Opponent side (Z = 9):**
- `pos21`: (6.5, 1.9, 9), Size: 2×3×0.2, +Gui child (mirrored)
- `pos22`: (3.5, 1.9, 9), Size: 2×3×0.2, +Gui child (mirrored)

All parts: Transparency=1, Anchored=true, CanCollide=false

See `BATTLE_SCENE_ANALYSIS.md` for complete details.

## Pikachu Model Pivot Issue (lol.rbxmx)

**Status**: ❌ CRITICAL - Model pivot way off from mesh geometry

### Problem
The Pikachu model's pivot is so far from the actual mesh that it appears **massive and incorrectly positioned** in battles.

**Root Cause:**
- Pivot (RootPart): 0.0035 studs at (4.67, 0.29, -1.97)
- Actual mesh geometry: Positioned 50+ studs away from pivot
- When `ScaleTo(0.1)` scales around the pivot, mesh is still huge
- When `MoveTo()` positions the pivot, mesh appears way off

**Why it looks massive:**
```
If mesh is 100 studs from pivot:
- After 0.1x scale → mesh still 10 studs from pivot
- Model appears 10 studs away from where it should be
- And appears 10x larger than intended
```

### Issues
1. **Pivot way off from mesh:** Makes model appear massive even after 0.1x scale
2. **Y-position too low:** Pivot at Y=0.29 instead of Y≈1.9 (center)
3. **Facing backwards:** 180° rotation (R00=-1, R22=-1)

### Fix Required
**CRITICAL:** Use Roblox Studio's "Edit Pivot" tool (Alt+P) to move the pivot to the **visual center** of Pikachu's body.

The pivot MUST be at the center of the mesh geometry for scaling and positioning to work correctly.

See `BATTLE_SCENE_ANALYSIS.md` for detailed fix instructions.

## Next Steps

1. **CRITICAL**: Fix Pikachu model pivot in Roblox Studio (Alt+P, move to center)
2. **CRITICAL**: Add pos11, pos12, pos21, pos22 to battle scene in Roblox Studio
3. **Immediate**: Fix BattleGui:303 statbar nil check ✅ (FIXED)
4. **High Priority**: Test that client has loaded latest code (31020b6)
5. **High Priority**: Test 3D battles with corrected Pikachu pivot
6. **Medium Priority**: Test doubles battles with new position parts
7. **Low Priority**: Test all special animations (Mega, Gigantamax, etc.)
8. **Enhancement**: Add per-species scale overrides in modelsData

## Code Reload Required

⚠️ **The client is running OLD CODE** - errors at lines 1634 and 374 are already fixed in commit 31020b6

To reload:
1. Stop Roblox server completely
2. Restart game/pull latest code
3. Look for these debug messages to confirm new code:
   - `[3D BATTLES V2] Attempting to load 3D model for X - Code version: cd3d17d`
   - `[2D FALLBACK] Creating 2D part for X`
