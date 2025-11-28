return function(_p, chunk, forced)
	local escort2 = {
		"Thank you for visiting the Safari Zone!\n" ..
			"Come back soon!"
	}
	local escort1 = {
		"You're out of Safari Balls!\n" ..
			"You were escorted out of the Safari Zone."
	}

	pcall(function()
		local MasterControl = _p.MasterControl
		MasterControl.WalkEnabled = true
	end)
	if _p.Menu then
		spawn(function()
			_p.Menu:enable()
		end)
	end

	if forced then
		spawn(function()
			wait(0.5)
			if _p.NPCChat then
				_p.NPCChat:say(escort1)
			end
			
			wait(0.5)
			if _p.DataManager then
				_p.DataManager.currentChunk:Destroy()
				_p.DataManager:loadChunk('chunk89')
			
			end
		end)
		return
	end

	if chunk and chunk.DoorA and chunk.DoorB then
		local onTouched = function()
			if _p.NPCChat:say('[y/n]Leave the safari zone early?') then
				_p.NPCChat:say(escort2)
				if _p.PlayerData then
				end
				local chunk = _p.DataManager.currentChunk	
				chunk:Destroy()
				_p.DataManager:loadChunk('chunk89')
			end
		end

		chunk.map.DoorA.PrimaryPart.Touched:Connect(onTouched)
		chunk.map.DoorB.PrimaryPart.Touched:Connect(onTouched)
	end
end
