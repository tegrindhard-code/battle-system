--// Animated Sprites v4
return function(_p)
	local RunService = game:GetService("RunService")
	local AnimationConnection = nil
	local ActiveAnimations = {}

	local AnimatedSprite = _p.Utilities.class({
		className = "AnimatedSprite",
		border = 1,
		startPixelY = 0,
		speed = .03,
		paused = true,
		startTime = 0,
		currentFrame = 0,
		nCaches = 0
	}, function(spriteConfig)
		-- Create and configure the sprite label (Image Label or Image Button)
		local sprite = {
			spriteData = spriteConfig,
			startTime = tick()
		}
		local label = Instance.new(spriteConfig.button and "ImageButton" or "ImageLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 1, 0)
		label.ImageRectSize = Vector2.new(spriteConfig.fWidth, spriteConfig.fHeight)
		label.ResampleMode = Enum.ResamplerMode.Pixelated

		sprite.spriteLabel = label

		-- Optional caching layer for multiple sheet animations
		if #spriteConfig.sheets > 1 then
			sprite.nCaches = 1
			local cache = Instance.new("ImageLabel", label)
			cache.ImageTransparency = .9
			cache.Image = "rbxassetid://" .. spriteConfig.sheets[1].id
			cache.BackgroundTransparency = 1
			cache.Size = UDim2.new(0, 1, 0, 1)
			cache.ResampleMode = Enum.ResamplerMode.Pixelated
			sprite.cache = cache
		end

		return sprite
	end)

	AnimatedSprite.New = AnimatedSprite.new

	local function UpdateFrame(sprite)
		if sprite.paused then return end
		local label = sprite.spriteLabel
		if not label.Parent then
			sprite:Destroy()
			return
		end
		if not label.Visible then return end

		local config = sprite.spriteData
		local frameIndex = math.floor((tick() - sprite.startTime) / (config.speed or sprite.speed) * sprite.relativeSpeed)

		-- Handle end of single loop playback
		if sprite.pauseAfterFirstLoop and config.nFrames <= frameIndex then
			frameIndex = config.nFrames
			for i = #ActiveAnimations, 1, -1 do
				if ActiveAnimations[i] == sprite then
					table.remove(ActiveAnimations, i)
				end
			end
			sprite.endOfLoopReached = true
		else
			frameIndex = (frameIndex % config.nFrames) + 1
		end

		if frameIndex == sprite.currentFrame then return end
		sprite.currentFrame = frameIndex

		local frameData = sprite.frameData[frameIndex]
		label.Image = frameData[1]
		label.ImageRectOffset = frameData[2]
		if frameData[3] then
			sprite.cache.Image = frameData[3]
		end

		if sprite.updateCallback then
			sprite.updateCallback(frameIndex / config.nFrames, frameIndex)
		end
	end

	local function AnimationLoop()
		if #ActiveAnimations == 0 then
			AnimationConnection:Disconnect()
			AnimationConnection = nil
			return
		end

		for _, sprite in pairs(ActiveAnimations) do
			UpdateFrame(sprite)
		end
	end

	-- Start playing an animation (looped)
	function AnimatedSprite.Play(sprite, relativeSpeed)
		if not sprite.paused then return end
		sprite.relativeSpeed = relativeSpeed or 1
		sprite.paused = false

		if sprite.pauseOffset then
			sprite.startTime = tick() - sprite.pauseOffset
			sprite.pauseOffset = nil
		end

		for _, anim in pairs(ActiveAnimations) do
			if sprite == anim then return end
		end

		if not sprite.frameData then
			local sheetFrameOffset = 0
			local config = sprite.spriteData
			local frameList = {}

			for sheetIndex, sheet in pairs(config.sheets) do
				local firstFrameIndex = sheetFrameOffset
				local totalFrames = sheet.rows * config.framesPerRow
				local endFrameIndex = firstFrameIndex + totalFrames

				for frameIndex = firstFrameIndex, math.min(endFrameIndex, config.nFrames) - 1 do
					local relativeIndex = frameIndex - firstFrameIndex
					local x = relativeIndex % config.framesPerRow
					local y = math.floor(relativeIndex / config.framesPerRow)

					local nextSheetId = sprite.nCaches > 0 and (sheetIndex == #config.sheets and config.sheets[1].id or config.sheets[sheetIndex + 1].id) or nil

					frameList[frameIndex + 1] = {
						"rbxassetid://" .. sheet.id,
						Vector2.new(
							x * (config.fWidth + (config.border or sprite.border)),
							y * (config.fHeight + (config.border or sprite.border)) + (sheet.startPixelY or sprite.startPixelY)
						),
						nextSheetId and "rbxassetid://" .. nextSheetId or nil
					}
				end
				sheetFrameOffset = endFrameIndex
			end

			sprite.frameData = frameList
		end

		table.insert(ActiveAnimations, sprite)
		if not AnimationConnection then
			AnimationConnection = RunService.Stepped:Connect(AnimationLoop)
		end
	end

	-- Play the animation once and pause
	function AnimatedSprite.PlayOnce(sprite, yieldUntilEnd)
		sprite.endOfLoopReached = false
		sprite.startTime = tick()
		sprite.pauseAfterFirstLoop = true
		sprite:RenderFirstFrame()
		sprite:Play()

		for _, anim in pairs(ActiveAnimations) do
			if sprite == anim then return end
		end

		table.insert(ActiveAnimations, sprite)
		if not AnimationConnection then
			AnimationConnection = RunService.Stepped:Connect(AnimationLoop)
		end

		if yieldUntilEnd then
			while not sprite.endOfLoopReached do
				RunService.Stepped:Wait()
			end
		end
	end

	-- Pause animation
	function AnimatedSprite.Pause(sprite)
		if sprite.paused then return end
		sprite.paused = true
		sprite.pauseOffset = tick() - sprite.startTime

		for i = #ActiveAnimations, 1, -1 do
			if ActiveAnimations[i] == sprite then
				table.remove(ActiveAnimations, i)
			end
		end
	end

	-- Render the first frame immediately
	function AnimatedSprite.RenderFirstFrame(sprite)
		local label = sprite.spriteLabel
		local sheet = sprite.spriteData.sheets[1]
		label.Image = "rbxassetid://" .. sheet.id
		label.ImageRectOffset = Vector2.new(0, sheet.startPixelY or 0)
	end

	-- Render the last frame
	function AnimatedSprite.RenderLastFrame(sprite)
		local label = sprite.spriteLabel
		local frames = sprite.frameData
		if frames then
			local lastFrame = frames[#frames]
			label.Image = lastFrame[1]
			label.ImageRectOffset = lastFrame[2]
			return
		end

		local config = sprite.spriteData
		local remainingFrames = config.nFrames
		local lastSheet

		for _, sheet in pairs(config.sheets) do
			lastSheet = sheet
			remainingFrames = remainingFrames - config.framesPerRow * sheet.rows
		end

		label.Image = "rbxassetid://" .. lastSheet.id
		label.ImageRectOffset = Vector2.new(
			(remainingFrames - 1) * (config.fWidth + (config.border or sprite.border)),
			(lastSheet.startPixelY or 0) + (lastSheet.rows - 1) * (config.fHeight + (config.border or sprite.border))
		)
	end

	-- Destory the sprite object and clean up
	function AnimatedSprite.Destroy(sprite)
		sprite:destroy()
	end

	function AnimatedSprite.destroy(sprite)
		for i = #ActiveAnimations, 1, -1 do
			if ActiveAnimations[i] == sprite then
				table.remove(ActiveAnimations, i)
			end
		end

		pcall(function()
			sprite.spriteLabel:Destroy()
		end)

		if sprite.frameData then
			for k in pairs(sprite.frameData) do
				sprite.frameData[k] = nil
			end
		end

		for k in pairs(sprite) do
			sprite[k] = nil
		end
	end

	AnimatedSprite.UpdateFrame = UpdateFrame
	return AnimatedSprite
end
