# Pokemon Model Converter - Scaling Comparison

## Old vs New Approach

### ❌ Old Version (Your Original Script)

**Scaling:**
```python
# Scale up 100x in Blender (hardcoded)
obj.scale = (100, 100, 100)

# Export with 100x global scale
global_scale=100.0
```

**Problems:**
- ❌ Hardcoded 100x scaling (not configurable)
- ❌ Double-scaling (object scale + global_scale)
- ❌ No connection to Roblox/Lua scaling system
- ❌ No way to calculate final in-game size
- ❌ Arbitrary scale that doesn't match sprite sizes

**Result:**
- Models exported at 100x × 100x = 10,000x original size
- No predictable relationship to sprite equivalents
- Had to manually adjust in Roblox to match sprites

### ✅ New Version (pokemon_model_converter.py)

**Scaling:**
```python
# Prompt user for export scale
BLENDER_EXPORT_SCALE = float(input())  # e.g., 100

# Apply once in Blender
obj.scale = (EXPORT_SCALE, EXPORT_SCALE, EXPORT_SCALE)
bpy.ops.object.transform_apply(scale=True)

# Export with no additional scaling
global_scale=1.0

# Calculate final Roblox size
LUA_BASE_SCALE = 0.2  # From Sprite.lua
FINAL_SCALE = EXPORT_SCALE * LUA_BASE_SCALE
```

**Benefits:**
- ✅ Configurable export scale (user input)
- ✅ No double-scaling (clean export)
- ✅ Matches Sprite.lua scaling system exactly
- ✅ Calculates and displays final in-game size
- ✅ Predictable relationship to sprite sizes

**Result:**
```
User inputs: 100
Export scale: 100x
Roblox base:  0.2x (from Sprite.lua:1497)
Final size:   20x original
Target:       ~3.84 studs (96px sprite)
```

## Scaling Math Comparison

### Old System
```
Source model: 0.2 studs
Blender scale: 100x (object) × 100x (global) = 10,000x
Export size: 2,000 studs
Roblox: ??? (no defined scale in old code)
Result: Manually resize to fit
```

### New System (Matches Lua)
```
Source model: 0.2 studs
Export scale: 100x (user configurable)
Export size: 20 studs
Roblox: 0.2x (Sprite.lua baseModelScale)
Final size: 4 studs
Target: 3.84 studs (96px sprite ÷ 25)
Match: ✅ Close enough!
```

## Integration with Sprite.lua

### Sprite.lua Scaling Logic
```lua
-- From Sprite.lua:1494-1503
local baseModelScale = 0.2  -- 20% of imported model
local spriteScale = sd.scale or 1.0  -- From GifData
local finalScale = baseModelScale * spriteScale

if self.alpha then
    finalScale = finalScale * 1.25  -- Alpha: 25% larger
end

self.model3D:ScaleTo(finalScale)
```

### How Converter Matches
```python
# Python converter calculates what Lua will do
LUA_BASE_SCALE = 0.2  # Matches Sprite.lua:1497
FINAL_ROBLOX_SCALE = BLENDER_EXPORT_SCALE * LUA_BASE_SCALE

# Shows user expected final size
print(f"Final in-game size: {FINAL_ROBLOX_SCALE}x original")
print(f"(For 96px sprite = 3.84 studs)")
```

## Target Sizes

### 2D Sprite Sizes (for reference)
```
96px × 96px   → 3.84 studs (pixels ÷ 25)
120px × 120px → 4.8 studs
144px × 144px → 5.76 studs
```

### 3D Model Export Targets

For models to match sprite sizes:

| Source Size | Export Scale | Exported | Roblox (0.2x) | Sprite Equiv |
|-------------|--------------|----------|---------------|--------------|
| 0.2 studs | 100x | 20 studs | 4 studs | 96px (close!) |
| 0.4 studs | 50x | 20 studs | 4 studs | 96px |
| 1.0 studs | 20x | 20 studs | 4 studs | 96px |
| 20 studs | 1x | 20 studs | 4 studs | 96px |

**Formula:**
```
exportScale = targetStuds / (sourceSize * 0.2)
targetStuds = 4 (for 96px sprite)
```

## Example Workflow

### Old Version
1. Run script (hardcoded 100x scale)
2. Import to Roblox
3. Manually test size in-game
4. Adjust :ScaleTo() values until it looks right
5. Hope it matches sprites

### New Version
1. Run script, enter folder paths
2. Script asks: "Blender export scale multiplier?"
3. Enter 100 (or calculate from formula)
4. Script shows:
   ```
   Export: 100x
   Roblox: 0.2x
   Final:  20x (4 studs in-game)
   Target: 3.84 studs (96px sprite)
   ```
5. Import to Roblox
6. Sprite.lua automatically applies 0.2x
7. Model is already correct size!

## Configuration Examples

### Tiny Pokemon Models (0.2 studs source)
```
Export scale: 100
Final size: 20x → 4 studs
Match: 96px sprite ✓
```

### Normal Models (10 studs source)
```
Export scale: 2
Final size: 0.4x → 4 studs
Match: 96px sprite ✓
```

### Large Models (20 studs source)
```
Export scale: 1
Final size: 0.2x → 4 studs
Match: 96px sprite ✓
```

### Wailord (needs to be bigger)
```
Export scale: 150
Final size: 30x → 6 studs
Match: 150px sprite ✓
Override in modelsData: baseScale = 0.4
```

## Files

### Tools
- `pokemon_model_converter.py` - Updated converter (matches Lua)
- `textureconverter.py` - Sprite dimension calculator
- `TEXTURECONVERTER_README.md` - Full documentation

### Game Code
- `Sprite.lua:1494-1519` - 3D model scaling implementation
- `modelsData.lua` - Model ID storage
- `3D_BATTLES_BUGS_AND_NOTES.md` - Implementation notes

## Summary

**Old:** Export at random giant size, manually adjust in Roblox

**New:** Calculate correct export size, automatic correct size in Roblox

The new converter matches the Lua scaling system exactly, making models work correctly on first import!
