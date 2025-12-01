-- Model data for 3D battle animations
-- Structure similar to GifData but contains model IDs and animation configurations
-- Each Pokemon has front and back model configurations with sprite sheet data

return {
	-- Front-facing models (what the opponent sees)
	_FRONT = {
		-- Example structure for a Pokemon:
		-- ["PokemonName"] = {
		--     modelId = 123456789, -- The asset ID of the 3D model
		--     sheets = {{id = 987654321, rows = 8}}, -- Sprite sheet for texture mapping
		--     nFrames = 64, -- Total number of animation frames
		--     framesPerRow = 8, -- Frames per row in sprite sheet
		--     fWidth = 128, -- Frame width in pixels
		--     fHeight = 128, -- Frame height in pixels
		--     speed = 0.03, -- Animation speed
		--     scale = 1.0, -- Model scale multiplier
		--     inAir = 0, -- Vertical offset
		--     border = 1, -- Border between frames
		-- },

		["Pikachu"] = {
			modelId = nil, -- Set to actual model ID when available
			sheets = {{id = 0, rows = 8}},
			nFrames = 64,
			framesPerRow = 8,
			fWidth = 96,
			fHeight = 96,
			speed = 0.03,
			scale = 1.0,
			inAir = 0,
		},
	},

	-- Back-facing models (what the player sees)
	_BACK = {
		["Pikachu"] = {
			modelId = nil,
			sheets = {{id = 0, rows = 8}},
			nFrames = 64,
			framesPerRow = 8,
			fWidth = 96,
			fHeight = 96,
			speed = 0.03,
			scale = 1.0,
			inAir = 0,
		},
	},

	-- Shiny front models
	_SHINY_FRONT = {
		-- Inherits from _FRONT but can override specific properties
	},

	-- Shiny back models
	_SHINY_BACK = {
		-- Inherits from _BACK but can override specific properties
	},
}
