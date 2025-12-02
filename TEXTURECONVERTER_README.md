# Texture Converter - 3D Battle System

A Python utility that converts sprite sheet dimensions to proper 3D model scale factors, matching the exact scaling logic from `Sprite.lua`.

## Purpose

When integrating 3D models into the battle system, you need to scale them to match the size of 2D sprites. This tool calculates the correct scale factors based on sprite dimensions.

## Scaling Logic

Matches `Sprite.lua` exactly:

### 2D Sprite Sizing
```lua
-- From Sprite.lua:1545
local size = Vector3.new(sd.fWidth/25*scale, sd.fHeight/25*scale, 0.6)
```
- **Formula**: `pixels ÷ 25 = studs`
- **Example**: 96px sprite → 3.84 studs

### 3D Model Scaling
```lua
-- From Sprite.lua:1494-1503
local baseModelScale = 0.2  -- 20% of original
local finalScale = baseModelScale * spriteScale

if self.alpha then
    finalScale = finalScale * 1.25
end
```
- **Base**: 0.2 (20% of original model size)
- **Multipliers**: spriteScale, alpha (1.25x), totem (1.2x), dynamax (2.0x)

## Installation

```bash
chmod +x textureconverter.py
```

Requires Python 3.6+

## Usage

### Basic Conversion
```bash
python3 textureconverter.py <width> <height> [sprite_scale]
```

**Examples:**
```bash
# Standard 96x96 sprite
python3 textureconverter.py 96 96

# 120x120 sprite with 1.5x scale
python3 textureconverter.py 120 120 1.5
```

**Output:**
```
2D Sprite: 96x96 pixels
  → 3.84 x 3.84 studs

3D Model Scale: 0.200
  (Base: 0.2 × Sprite: 1.0)

Special Variants:
  Alpha:   0.250
  Totem:   0.240
  Dynamax: 0.400
```

### Full Guide Mode
```bash
python3 textureconverter.py guide <width> <height>
```

**Example:**
```bash
python3 textureconverter.py guide 96 96
```

**Output (JSON):**
```json
{
  "sprite_dimensions_px": {
    "width": 96,
    "height": 96
  },
  "sprite_size_studs": {
    "width": 3.84,
    "height": 3.84
  },
  "recommended_3d_scales": {
    "small_pokemon": 0.15,
    "medium_pokemon": 0.2,
    "large_pokemon": 0.3,
    "alpha": 0.25,
    "totem": 0.24,
    "dynamax": 0.4
  },
  "model_height_estimates": {
    "if_model_15_studs": 0.256,
    "if_model_20_studs": 0.192,
    "if_model_25_studs": 0.154
  }
}
```

## Use Cases

### 1. Finding Scale for Specific Sprite
```bash
python3 textureconverter.py 120 120
# Use the "3D Model Scale" output in your Lua code
```

### 2. Estimating Scale for Existing Model
If you have a model that's 20 studs tall:
```bash
python3 textureconverter.py guide 96 96
# Look at "if_model_20_studs": 0.192
# Use 0.192 as your baseModelScale
```

### 3. Calculating Special Variant Scales
```bash
python3 textureconverter.py 96 96 1.5
# See Alpha, Totem, Dynamax scales for a 1.5x sprite scale
```

## Scale Recommendations

### By Pokemon Size Category

| Category | Base Scale | Examples |
|----------|-----------|----------|
| **Small** | 0.1-0.15 | Joltik, Flabébé, Cutiefly, Natu |
| **Medium** | 0.15-0.25 | Pikachu, Eevee, most Pokemon |
| **Large** | 0.3-0.5 | Wailord, Eternatus, Steelix, Onix |

### By Sprite Dimensions

| Sprite Size | Studs | Recommended Scale |
|-------------|-------|-------------------|
| 80x80 | 3.2 | 0.16 |
| 96x96 | 3.84 | 0.2 (default) |
| 120x120 | 4.8 | 0.24 |
| 144x144 | 5.76 | 0.29 |

## Python API

```python
from textureconverter import TextureConverter

converter = TextureConverter()

# Convert pixels to studs
width_studs, height_studs = converter.calculate_sprite_size(96, 96)
# (3.84, 3.84)

# Calculate 3D scale
scale = converter.calculate_3d_scale(sprite_scale=1.0, is_alpha=True)
# 0.25

# Get recommended scale for specific Pokemon
scale = converter.get_scale_category("Pikachu")
# 0.2

# Generate full guide
guide = converter.generate_scale_guide(96, 96)
# Returns dict with all scaling info
```

## Integration with modelsData.lua

You can use this tool to determine scale factors, then optionally store them in modelsData.lua:

```lua
-- Option 1: Just store model ID (current approach)
["Pikachu"] = "Pikachu"

-- Option 2: Store model ID + custom scale override
["Wailord"] = {
    id = "Wailord",
    baseScale = 0.4  -- Custom scale for large Pokemon
}
```

## Constants

All constants match `Sprite.lua`:

```python
PIXELS_TO_STUDS = 25      # From: sd.fWidth/25
BASE_MODEL_SCALE = 0.2    # From: local baseModelScale = 0.2
ALPHA_SIZE = 1.25         # From: dataChanges.alpha.size
TOTEM_SIZE = 1.2          # From: dataChanges.totem.size
DYNAMAX_SIZE = 2.0        # From: dataChanges.dynamax.size
```

## Troubleshooting

### Model appears too large
- Decrease `baseModelScale` in `Sprite.lua`
- Try smaller values: 0.15, 0.1, etc.

### Model appears too small
- Increase `baseModelScale` in `Sprite.lua`
- Try larger values: 0.25, 0.3, etc.

### Want per-Pokemon custom scales
Modify `Sprite.lua:1497` to check for custom scales:
```lua
local baseModelScale = modelsData.customScales[self.pokemon.species] or 0.2
```

## Files Modified

- `Sprite.lua:1494-1519` - 3D model scaling implementation
- `textureconverter.py` - This utility tool
- `3D_BATTLES_BUGS_AND_NOTES.md` - Scaling documentation

## See Also

- `3D_BATTLES_BUGS_AND_NOTES.md` - Full 3D battles implementation notes
- `Sprite.lua` - Main sprite and model handling
- `modelAnimator.lua` - 3D model animation system
