return function(_p, chunk, forced)
	local escort2 = {
		"Thank you for visiting the Safari Zone!\n" ..
		"Come back soon!"
	}
	local escort1 = {
		"You're out of Safari Balls!\n" ..
		"You were escorted out of the Safari Zone."
	}

	-- Re-enable controls
	pcall(function()
		local MasterControl = _p.MasterControl
		MasterControl.WalkEnabled = true
	end)
	if _p.Menu then
		spawn(function()
			_p.Menu:enable()
		end)
	end

	-- If forced (ran out of balls), immediately escort player out
	if forced then
		spawn(function()
			wait(0.5)
			if _p.NPCChat then
				_p.NPCChat:say(escort1)
			end
			-- Mark player as no longer in safari
			if _p.PlayerData then
				pcall(function()
					_p.PlayerData.inSafari = false
				end)
			end
			-- Teleport to exit (chunk89)
			wait(0.5)
			if _p.DataManager then
				_p.DataManager:loadChunk('chunk89')
			end
		end)
		return
	end

	-- Setup door touch handlers for voluntary exit
	if chunk and chunk.DoorA and chunk.DoorB then
		local onTouched = function()
			if _p.NPCChat:say('[y/n]Leave the safari zone early?') then
				_p.NPCChat:say(escort2)
				if _p.PlayerData then
					pcall(function()
						_p.PlayerData.inSafari = false
					end)
				end
				_p.DataManager:loadChunk('chunk89')
			end
		end

		chunk.DoorA.Touched:Connect(onTouched)
		chunk.DoorB.Touched:Connect(onTouched)
	end
end
