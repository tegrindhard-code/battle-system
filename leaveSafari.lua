--[[
	Safari Zone Exit Handler

	This function handles player exit from Safari Zone when:
	- Safari Balls run out (forced = true)
	- Player manually leaves (forced = false)

	Usage:
		_p.Events.leaveSafari = require(script.leaveSafari)
		_p.Events.leaveSafari(chunk, forced)
]]

return function(chunk, forced)
	local _p = require(game.ReplicatedStorage.Plugins)
	local player = game.Players.LocalPlayer

	-- Show appropriate message based on how they're leaving
	if forced then
		if _p.Menu and _p.Menu.message then
			_p.Menu.message:show(
				"You're out of Safari Balls!\n" ..
				"You were escorted out of the Safari Zone."
			)
		end
	else
		if _p.Menu and _p.Menu.message then
			_p.Menu.message:show(
				"Thank you for visiting the Safari Zone!\n" ..
				"Come back soon!"
			)
		end
	end

	-- Teleport player to Safari Zone exit
	-- NOTE: Adjust these coordinates to match your Safari Zone exit location
	if chunk and chunk.SafariExit then
		-- If chunk has a defined exit position
		spawn(function()
			wait(1) -- Brief delay for message
			if player.Character and player.Character.PrimaryPart then
				player.Character:SetPrimaryPartCFrame(chunk.SafariExit)
			end
		end)
	elseif chunk and chunk.entrance then
		-- Fallback: teleport to entrance
		spawn(function()
			wait(1)
			if player.Character and player.Character.PrimaryPart then
				player.Character:SetPrimaryPartCFrame(chunk.entrance)
			end
		end)
	end

	-- Clean up Safari state
	if _p.PlayerData then
		pcall(function()
			-- Reset any Safari-specific flags
			_p.PlayerData.inSafari = false
			_p.PlayerData.safariSteps = 0
		end)
	end

	-- Re-enable normal game controls
	pcall(function()
		local MasterControl = require(game.Players.LocalPlayer.PlayerScripts.MasterControl)
		MasterControl.WalkEnabled = true
		MasterControl:Hidden(false)
	end)

	-- Re-enable menu
	if _p.Menu then
		spawn(function()
			_p.Menu:enable()
		end)
	end

	-- Save player data
	if _p.Autosave then
		pcall(function()
			_p.Autosave:queueSave()
		end)
	end
end
