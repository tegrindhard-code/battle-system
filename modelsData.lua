-- Model IDs for 3D battle animations
-- Sprite sheet data comes from GifData - this only stores which 3D model to load
-- The 3D model will animate based on the sprite sheet from GifData

return {
	-- Front-facing models (what the opponent sees)
	_FRONT = {
		-- Structure: ["PokemonName"] = modelAssetId or modelName
		-- Example:
		-- ["Pikachu"] = 123456789, -- Asset ID from Roblox catalog
		-- ["Charizard"] = "CharizardModel", -- Model name in ReplicatedStorage.Models

		-- Add your Pokemon model IDs here:
		-- ["Pikachu"] = 123456789,
	},

	-- Back-facing models (what the player sees)
	_BACK = {
		-- Usually same as _FRONT unless Pokemon has different back model
		-- Will fallback to _FRONT if not specified
	},

	-- Shiny front models
	_SHINY_FRONT = {
		-- Optional: Different models for shiny Pokemon
		-- Falls back to _FRONT if not specified
	},

	-- Shiny back models
	_SHINY_BACK = {
		-- Optional: Different back models for shiny Pokemon
		-- Falls back to _BACK then _FRONT if not specified
	},
}
