return function(_p, chunk, forced)
	local escort2 = {

		"Thank you for visiting the Safari Zone!\n" ..

			"Come back soon!"
}
	local escort1 = {
		"You're out of Safari Balls!\n" ..

			"You were escorted out of the Safari Zone."
	}
	
local onTouched = function()
	if not forced then 
		if _p.NPCChat:say('[y/n]Leave the safari zone early?') then
			_p.NPCChat:say(escort2) 
			_p.DataManager:loadChunk('chunk89')
		else
			_p.NPCChat:say(escort1) 
			_p.DataManager:loadChunk('chunk89')
		end
	end
end
	
chunk.DoorA.Touched:Connect(onTouched)
chunk.DoorB.Touched:Connect(onTouched)
	pcall(function()
		local MasterControl = _p.MasterControl
		MasterControl.WalkEnabled = true
	end)
	if _p.Menu then
		spawn(function()
			_p.Menu:enable()

		end)

	end
end
