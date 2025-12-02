#!/usr/bin/env python3
"""
Texture Converter for 3D Battle System
Converts sprite sheet dimensions to proper 3D model scale factors.

Matches the scaling logic from Sprite.lua:
- 2D sprites: pixels/25 = studs (e.g., 96px = 3.84 studs)
- 3D models: baseScale * spriteScale = finalScale
- Default baseScale: 0.2 (20% of original model size)
"""

import json
import sys
from pathlib import Path
from typing import Dict, Optional, Tuple


class TextureConverter:
    """Converts sprite sheet data to 3D model scaling parameters."""

    # Constants from Sprite.lua
    PIXELS_TO_STUDS = 25  # Divisor for converting pixels to Roblox studs
    BASE_MODEL_SCALE = 0.2  # Default 3D model scale (20% of original)

    # Data changes from Sprite.lua
    ALPHA_SIZE = 1.25
    TOTEM_SIZE = 1.2
    DYNAMAX_SIZE = 2.0

    def __init__(self):
        self.sprite_data = {}

    def pixels_to_studs(self, pixels: int) -> float:
        """
        Convert pixel dimensions to Roblox studs.

        From Sprite.lua:1545
        local size = Vector3.new(sd.fWidth/25*scale, sd.fHeight/25*scale, 0.6)

        Args:
            pixels: Pixel dimension (width or height)

        Returns:
            Equivalent size in studs
        """
        return pixels / self.PIXELS_TO_STUDS

    def calculate_sprite_size(self, width: int, height: int, scale: float = 1.0) -> Tuple[float, float]:
        """
        Calculate 2D sprite size in studs.

        Args:
            width: Sprite width in pixels
            height: Sprite height in pixels
            scale: Scale multiplier from GifData (default 1.0)

        Returns:
            Tuple of (width_studs, height_studs)
        """
        width_studs = self.pixels_to_studs(width) * scale
        height_studs = self.pixels_to_studs(height) * scale
        return (width_studs, height_studs)

    def calculate_3d_scale(
        self,
        sprite_scale: float = 1.0,
        is_alpha: bool = False,
        is_totem: bool = False,
        dynamax_level: int = 0
    ) -> float:
        """
        Calculate final 3D model scale factor.

        Matches Sprite.lua:1494-1503

        Args:
            sprite_scale: Scale from GifData (default 1.0)
            is_alpha: True if Alpha Pokemon
            is_totem: True if Totem Pokemon
            dynamax_level: 0=normal, 1=dynamax, 2=gigantamax

        Returns:
            Final scale factor for Model:ScaleTo()
        """
        # Base calculation
        final_scale = self.BASE_MODEL_SCALE * sprite_scale

        # Apply modifiers
        if is_alpha:
            final_scale *= self.ALPHA_SIZE
        if is_totem:
            final_scale *= self.TOTEM_SIZE
        if dynamax_level > 0:
            final_scale *= self.DYNAMAX_SIZE

        return final_scale

    def get_scale_category(self, pokemon_name: str) -> float:
        """
        Get recommended base scale for specific Pokemon categories.

        Args:
            pokemon_name: Name of the Pokemon

        Returns:
            Recommended base model scale
        """
        # Small Pokemon (0.1-0.15x)
        small_pokemon = [
            "Joltik", "Flabébé", "Cutiefly", "Comfey", "Cosmoem",
            "Natu", "Azurill", "Igglybuff", "Cleffa", "Togepi"
        ]

        # Large Pokemon (0.3-0.5x)
        large_pokemon = [
            "Wailord", "Eternatus", "Alolan Exeggutor", "Steelix",
            "Onix", "Gyarados", "Rayquaza", "Dialga", "Palkia", "Giratina"
        ]

        if pokemon_name in small_pokemon:
            return 0.12  # Small
        elif pokemon_name in large_pokemon:
            return 0.4  # Large
        else:
            return 0.2  # Medium (default)

    def estimate_model_height(
        self,
        model_height_studs: float,
        sprite_scale: float = 1.0
    ) -> float:
        """
        Given a model's current height, calculate what scale factor to use.

        Args:
            model_height_studs: Current height of the model in studs
            sprite_scale: Scale from GifData

        Returns:
            Scale factor to match sprite size
        """
        # Target sprite size (assuming typical 96px sprite)
        target_height = self.pixels_to_studs(96) * sprite_scale  # ~3.84 studs

        # Calculate scale needed
        return target_height / model_height_studs

    def generate_scale_guide(self, sprite_width: int, sprite_height: int) -> Dict:
        """
        Generate a complete scaling guide for a sprite.

        Args:
            sprite_width: Sprite width in pixels
            sprite_height: Sprite height in pixels

        Returns:
            Dictionary with scaling information
        """
        width_studs, height_studs = self.calculate_sprite_size(sprite_width, sprite_height)

        return {
            "sprite_dimensions_px": {
                "width": sprite_width,
                "height": sprite_height
            },
            "sprite_size_studs": {
                "width": round(width_studs, 2),
                "height": round(height_studs, 2)
            },
            "recommended_3d_scales": {
                "small_pokemon": self.calculate_3d_scale(sprite_scale=0.75),  # Small with reduced sprite scale
                "medium_pokemon": self.calculate_3d_scale(),  # Default
                "large_pokemon": self.calculate_3d_scale(sprite_scale=1.5),  # Large with increased sprite scale
                "alpha": self.calculate_3d_scale(is_alpha=True),
                "totem": self.calculate_3d_scale(is_totem=True),
                "dynamax": self.calculate_3d_scale(dynamax_level=1),
            },
            "model_height_estimates": {
                "if_model_15_studs": round(self.estimate_model_height(15), 3),
                "if_model_20_studs": round(self.estimate_model_height(20), 3),
                "if_model_25_studs": round(self.estimate_model_height(25), 3),
            }
        }


def main():
    """CLI interface for texture converter."""
    converter = TextureConverter()

    if len(sys.argv) < 2:
        print("Texture Converter - 3D Battle System")
        print("=" * 50)
        print("\nUsage:")
        print("  python textureconverter.py <width> <height> [sprite_scale]")
        print("  python textureconverter.py guide <width> <height>")
        print("\nExamples:")
        print("  python textureconverter.py 96 96")
        print("  python textureconverter.py 120 120 1.2")
        print("  python textureconverter.py guide 96 96")
        print("\nDefault Values:")
        print(f"  Base 3D scale: {converter.BASE_MODEL_SCALE} (20%)")
        print(f"  Pixels to studs: /{converter.PIXELS_TO_STUDS}")
        return

    if sys.argv[1] == "guide":
        # Generate full guide
        if len(sys.argv) < 4:
            print("Error: guide requires width and height")
            print("Usage: python textureconverter.py guide <width> <height>")
            return

        width = int(sys.argv[2])
        height = int(sys.argv[3])

        guide = converter.generate_scale_guide(width, height)
        print(json.dumps(guide, indent=2))

    else:
        # Simple conversion
        width = int(sys.argv[1])
        height = int(sys.argv[2])
        sprite_scale = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0

        # Calculate 2D sprite size
        width_studs, height_studs = converter.calculate_sprite_size(width, height, sprite_scale)

        # Calculate 3D model scale
        model_scale = converter.calculate_3d_scale(sprite_scale)

        print(f"\n2D Sprite: {width}x{height} pixels")
        print(f"  → {width_studs:.2f} x {height_studs:.2f} studs")
        print(f"\n3D Model Scale: {model_scale:.3f}")
        print(f"  (Base: {converter.BASE_MODEL_SCALE} × Sprite: {sprite_scale})")

        # Show special variants
        print("\nSpecial Variants:")
        print(f"  Alpha:   {converter.calculate_3d_scale(sprite_scale, is_alpha=True):.3f}")
        print(f"  Totem:   {converter.calculate_3d_scale(sprite_scale, is_totem=True):.3f}")
        print(f"  Dynamax: {converter.calculate_3d_scale(sprite_scale, dynamax_level=1):.3f}")


if __name__ == "__main__":
    main()
