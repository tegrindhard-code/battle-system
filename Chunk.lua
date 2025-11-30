return function(_p)

	local players = game:GetService('Players')
	local player = players.LocalPlayer
	local storage = game:GetService('ReplicatedStorage')

	local Utilities = _p.Utilities
	local MasterControl = _p.MasterControl
	local create = Utilities.Create
	local rc4 = Utilities.rc4
	local runService = game:GetService('RunService')
	local stepped = runService.RenderStepped

	local Door = require(script.Door)(_p)
	local Room = require(script.Room)(_p, Door)
	_p.Door = Door

	----------------------------------------------------------
	-- CLASS DEFINITION
	----------------------------------------------------------
	local Chunk = Utilities.class({
		className = 'Chunk',
		doorDebounce = false,
		indoors = false,
	}, function(self)

		self.map.Parent = storage
		for _, room in pairs(self.rooms) do
			room.Parent = storage
		end

		self.regions = {}

		if self.map:FindFirstChild('Regions') then
			for _, part in pairs(self.map.Regions:GetChildren()) do
				if part:IsA('BasePart') then
					local region = _p.Region.FromPart(part)
					region.Name = part.Name
					table.insert(self.regions, region)
				end
			end
			self.map.Regions:Destroy()
		end

		local battle = _p.Battle
		local indoorCamOffset
		do
			local angle = math.rad(40)
			indoorCamOffset = Vector3.new(0, math.sin(angle), -math.cos(angle)) * 18
		end

		local min, max = math.min, math.max
		local v3 = Vector3.new
		local cf = CFrame.new

		----------------------------------------------------------
		-- Indoor Camera (bindable function)
		----------------------------------------------------------
		self.indoorCamFunc = function(override)
			local room = self.room
			if not room then
				self:unbindIndoorCam()
				return
			end
			if override ~= 'super' then
				if battle.currentBattle or self.roomCamDisabled or not player.Character then
					return
				end
			end

			local hp = player.Character.HumanoidRootPart.CFrame * v3(0, 1.5, 0)
			local p = v3(
				max(room.indoorCamMinX, min(room.indoorCamMaxX, hp.x)),
				hp.y,
				hp.z
			)

			local ico = indoorCamOffset
			if self.getCamOffset then
				local nico, po = self.getCamOffset(hp - room.basePosition)
				if nico then ico = nico end
				if po then p = p + po end
			end

			local from = p + ico
			workspace.CurrentCamera.CoordinateFrame = cf(from, p)
		end

		self.getIndoorCamCFrame = function()
			local room = self.room
			local hp = player.Character.HumanoidRootPart.CFrame * v3(0, 1.5, 0)
			local p = v3(
				max(room.indoorCamMinX, min(room.indoorCamMaxX, hp.x)),
				hp.y,
				hp.z
			)

			local ico = indoorCamOffset
			if self.getCamOffset then
				local nico, po = self.getCamOffset(hp - room.basePosition)
				if nico then ico = nico end
				if po then p = p + po end
			end

			local from = p + ico
			return cf(from, p)
		end

		self.roomStack = {}
		self.doors = {}
		self.npcs = {}

		return self
	end)

	----------------------------------------------------------
	-- CAMERA BINDING
	----------------------------------------------------------
	function Chunk:bindIndoorCam()
		runService:BindToRenderStep("IndoorCameraStep", Enum.RenderPriority.Camera.Value, self.indoorCamFunc)
	end

	function Chunk:unbindIndoorCam()
		runService:UnbindFromRenderStep("IndoorCameraStep")
	end

	----------------------------------------------------------
	-- SET DAY
	----------------------------------------------------------
	function Chunk:setDay(isDay, model)
		if _p.Menu.options.reduceGraphics then
			isDay = true
		end

		local function set(obj)
			if obj.Name == "Light" and obj:IsA("BasePart") then
				obj.Material = isDay and Enum.Material.SmoothPlastic or Enum.Material.Neon
				for _, light in pairs(obj:GetChildren()) do
					if light:IsA("Light") then light.Enabled = not isDay end
				end
			else
				for _, ch in pairs(obj:GetChildren()) do
					set(ch)
				end
			end
		end

		if model then
			set(model)
		else
			set(self.map)
			for _, r in pairs(self.roomStack) do
				set(r.model)
			end
		end
	end

	----------------------------------------------------------
	-- REGION CHANGE
	----------------------------------------------------------
	function Chunk:changedRegions(newRegion)
		local s, regionData = pcall(function()
			return self.data.regions[newRegion.Name]
		end)
		if not s or not regionData then return end

		self.regionData = regionData

		_p.MusicManager:popMusic("RegionMusic", 1.5)

		if regionData.Music then
			local music = _p.MusicManager:stackMusic(regionData.Music, "RegionMusic", regionData.MusicVolume)
			if self.StartMusicAtZeroVolume then
				music.Volume = 0
				local cn
				cn = music.Changed:connect(function()
					if not self.StartMusicAtZeroVolume then cn:disconnect() return end
					if music.Volume > 0 then music.Volume = 0 end
				end)
			end
		end

		if _p.DataManager.ignoreRegionChangeFlag or regionData.NoSign then
			_p.DataManager.ignoreRegionChangeFlag = nil
			return
		end

		if self.delayShowRegionName then
			wait(self.delayShowRegionName)
			self.delayShowRegionName = nil
		end

		local thread = {}
		self.regionThread = thread

		----------------------------------------------------------
		-- UI container for region text
		----------------------------------------------------------
		local container = create("Frame")({
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 0.08, 0),
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0.06, 0, 0.93, 0),
			Parent = Utilities.gui
		})

		local destroy
		function destroy()
			destroy = nil
			container:Destroy()
		end

		Utilities.Write(newRegion.Name)({
			Frame = container,
			Scaled = true,
			TextXAlignment = Enum.TextXAlignment.Left
		})

		local labels = {}
		for _, l in pairs(container:GetDescendants()) do
			if l:IsA("ImageLabel") then
				table.insert(labels, l)

				local c = create("Frame")({
					BackgroundTransparency = 1,
					SizeConstraint = l.SizeConstraint,
					Size = l.Size,
					AnchorPoint = l.AnchorPoint,
					Position = l.Position,
					Parent = l.Parent
				})

				l.SizeConstraint = Enum.SizeConstraint.RelativeXY
				l.Size = UDim2.new(1, 0, 1, 0)
				l.AnchorPoint = Vector2.new(0, 0)
				l.ImageTransparency = 1
				l.Parent = c

				delay(0.5 * math.random(), function()
					if self.regionThread ~= thread then
						if destroy then destroy() end
						return
					end

					local bounce = Utilities.Timing.easeOutBounce(1)
					local cubic = Utilities.Timing.easeOutCubic(1)
					local dir = math.random() < 0.5 and 1 or -1
					local x = dir * 0.6 * c.AbsoluteSize.X / c.AbsoluteSize.Y
					local y = -0.6

					Utilities.Tween(1, nil, function(a)
						if self.regionThread ~= thread then
							if destroy then destroy() end
							return false
						end
						local cb = 1 - cubic(a)
						l.ImageTransparency = cb
						l.Position = UDim2.new(x*(1-a),0, y*(1-bounce(a)),0)
						l.Rotation = 30*dir*cb
					end)
				end)
			end
		end

		Utilities.Tween(4, nil, function()
			if self.regionThread ~= thread then
				if destroy then destroy() end
				return false
			end
		end)

		if self.regionThread == thread then
			Utilities.Tween(1, nil, function(a)
				if self.regionThread ~= thread then
					if destroy then destroy() end
					return false
				end
				for _, l in pairs(labels) do
					l.ImageTransparency = a
				end
			end)
			if destroy then destroy() end
		end
	end

	----------------------------------------------------------
	-- REGION CHECK
	----------------------------------------------------------
	function Chunk:checkRegion(pos)
		if not pos then
			local s, p = pcall(function()
				return _p.player.Character.HumanoidRootPart.Position
			end)
			if not s or not p then return end
			pos = p
		end

		local currentRegion = self.currentRegion
		if currentRegion and (currentRegion.isSoleRegion or currentRegion:CastPoint(pos)) then
			return
		end

		for _, region in pairs(self.regions) do
			if region ~= currentRegion
				and (not currentRegion or region.Name ~= currentRegion.Name)
				and region:CastPoint(pos) then

				Utilities.fastSpawn(function()
					self:changedRegions(region)
				end)

				self.currentRegion = region
				return
			end
		end
	end

	----------------------------------------------------------
	-- DOOR LOOKUP HELPERS
	----------------------------------------------------------
	function Chunk:doorFromModel(door)
		if type(door) ~= "userdata" then return door end
		for _, d in pairs(self.doors) do
			if d.model == door then return d end
		end
	end

	function Chunk:getDoor(id)
		for _, door in pairs(self.doors) do
			if door.id == id then return door end
		end
	end

	----------------------------------------------------------
	-- GET ALL NPCS
	----------------------------------------------------------
	function Chunk:getNPCs()
		local npcs = {}
		for _, npc in pairs(self.npcs) do
			table.insert(npcs, npc)
		end
		for _, room in pairs(self.roomStack) do
			for _, npc in pairs(room.npcs) do
				table.insert(npcs, npc)
			end
		end
		return npcs
	end

	----------------------------------------------------------
	-- ROOM HANDLING
	----------------------------------------------------------
	function Chunk:topRoom()
		return self.roomStack[#self.roomStack]
	end

	function Chunk:setRoom(room)
		self.room = room
		self.getCamOffset = nil
		if not room then return end

		pcall(function()
			self.getCamOffset = _p.Events["cameraOffset_"..room.id]()
		end)
	end

	----------------------------------------------------------
	-- ROOM CREATION
	----------------------------------------------------------
	function Chunk:getRoom(id, door, level)
		level = level or 1

		local pos = (self.localIndoorsOrigin or _p.DataManager.localIndoorsOrigin)
			+ Vector3.new(0, (level-1)*100, 0)

		local room = Room:new(self.rooms[id]:Clone(), pos)
		room.id = id
		room.chunk = self
		room.model.Parent = workspace
		room:init()

		self:setDay(_p.DataManager.isDay, room.model)

		if self.roomData and self.roomData[id] and self.roomData[id].NPCs then
			for _, nd in pairs(self.roomData[id].NPCs) do
				local model = _p.storage.Models.NPCs[nd.appearance]:Clone()
				Utilities.MoveModel(model.HumanoidRootPart,
					CFrame.new(room.model.Base.Position + nd.cframe.p + Vector3.new(0, room.model.Base.Size.Y/2+3, 0))
						* (nd.cframe - nd.cframe.p),
					true
				)
				model.Parent = room.model

				local npc = _p.NPC:new(model)
				room.npcs[model.Name] = npc

				if nd.interact then
					_p.NPCChat.interactableNPCs[model] = nd.interact
				end
			end
		end

		self:setRoom(room)

		----------------------------------------
		-- EXIT HANDLER
		----------------------------------------
		local exitPart = room.Exit or room.model:FindFirstChild("ToChunk:"..self.id)
		local exitCon

		exitCon = exitPart.Touched:connect(function(p)
			if self.doorDebounce or not p or not p:IsDescendantOf(player.Character)
				or not p.Parent or p.Parent:IsA("Accoutrement") then return end
			if not _p.MasterControl.WalkEnabled then return end

			exitCon:disconnect()

			if door then
				self.doorDebounce = true
				self:exitDoor(door)
				self.doorDebounce = false
			else
				self:popSubRoom()
			end
		end)

		----------------------------------------
		-- TO OTHER CHUNK PARTS
		----------------------------------------
		for _, part in pairs(room.model:GetChildren()) do
			if part:IsA("BasePart") and part.Name:sub(1,8) == "ToChunk:" then
				local chunkId = part.Name:sub(9)
				if chunkId ~= self.id then
					local touchCon
					touchCon = part.Touched:connect(function(p)
						if self.doorDebounce or not p or not p:IsDescendantOf(player.Character)
							or not p.Parent or p.Parent:IsA("Accoutrement") then return end

						touchCon:disconnect()
						self.doorDebounce = true
						MasterControl.WalkEnabled = false
						MasterControl:Stop()
						_p.Hoverboard:unequip(true)

						_p.MusicManager:popMusic("all", 1)
						Utilities.FadeOut(1)

						Utilities.Teleport(
							CFrame.new(3,70,389)
								+ Vector3.new(math.random(-20,20), 0, math.random(-20,20))
						)

						self:destroy()

						local newChunk = _p.DataManager:loadChunk(chunkId)
						newChunk.doorDebounce = true
						self:exitDoor(newChunk:getDoor(id), true)
						newChunk.doorDebounce = false
					end)
				end
			end
		end

		return room
	end

	----------------------------------------------------------
	-- STACK SUBROOM
	----------------------------------------------------------
	function Chunk:stackSubRoom(id, button, noAnim)
		if not noAnim then
			MasterControl.WalkEnabled = false
			MasterControl:Stop()
			_p.Hoverboard:unequip(true)
			Utilities.FadeOut(1)
		end

		local newroom = self:getRoom(id, nil, #self.roomStack + 1)
		table.insert(self.roomStack, newroom)
		newroom.exitCFrame = button.CFrame * CFrame.new(0,3,-3.5)

		local event = _p.Events["onBeforeEnter_"..id]
		if event then event(newroom) end

		if not noAnim then
			Utilities.Teleport(self.room.Entrance.CFrame * CFrame.new(0,3,3.5) * CFrame.Angles(0,math.pi,0))
			wait(.5)
			Utilities.FadeIn(1)
			MasterControl.WalkEnabled = true
		end

		return newroom
	end

	----------------------------------------------------------
	-- POP SUBROOM
	----------------------------------------------------------
	function Chunk:popSubRoom(noAnim)
		if not noAnim then
			MasterControl.WalkEnabled = false
			MasterControl:Stop()
			_p.Hoverboard:unequip(true)
			Utilities.FadeOut(1)
		end

		local st = tick()
		local room = table.remove(self.roomStack, #self.roomStack)

		local event = _p.Events["onExit_"..room.id]
		if event then event(room) end

		local exitcf = room.exitCFrame
		room:destroy()
		self:setRoom(self.roomStack[#self.roomStack])

		if not noAnim then
			Utilities.Teleport(exitcf)
			local elapsed = tick() - st
			if elapsed < .5 then wait(.5 - elapsed) end
			Utilities.FadeIn(1)
			MasterControl.WalkEnabled = true
		end
	end

	----------------------------------------------------------
	-- ROOM MUSIC
	----------------------------------------------------------
	function Chunk:getRoomMusic(roomId)
		local roomMusicId, roomMusicVolume

		if roomId == "PokeCenter" then
			roomMusicId = _p.musicId.PokeCenter
		elseif roomId:sub(1,4) == "Gate" and tonumber(roomId:sub(5)) then
			roomMusicId = _p.musicId.Gate
			roomMusicVolume = .45
		end

		pcall(function()
			if not self.roomData[roomId].Music then return end
			roomMusicId = self.roomData[roomId].Music
			roomMusicVolume = self.roomData[roomId].MusicVolume
		end)

		return roomMusicId, roomMusicVolume
	end

	----------------------------------------------------------
	-- ENTER DOOR
	----------------------------------------------------------
	function Chunk:enterDoor(door)
		MasterControl.WalkEnabled = false
		MasterControl:Stop()
		_p.Hoverboard:unequip(true)
		_p.NPCChat:disable()
		spawn(function() _p.Menu:disable() end)

		self.indoors = true

		local angle
		pcall(function() angle = self.roomData[door.id].DoorViewAngle end)

		local zoom
		pcall(function() zoom = self.roomData[door.id].DoorViewZoom end)

		local y = player.Character.HumanoidRootPart.Position.Y

		local walkTo1 = door.Position + Vector3.new(0, y-door.Position.Y, 0)
		local walkTo2 = door.Position + Vector3.new(0, y-door.Position.Y, 0) - door.CFrame.lookVector*5

		local cam = workspace.CurrentCamera
		local camF0 = cam.Focus.Position
		local camC0 = cam.CoordinateFrame.Position
		local camF1 = door.Position
		local camC1 = door.Position + (door.CFrame * CFrame.Angles(math.rad(angle or 35),0,0)).lookVector * (zoom or 20)

		if door.id ~= "C_chunk46" then
			cam.CameraType = Enum.CameraType.Scriptable
			Utilities.Tween(.3,"easeOutCubic", function(a)
				cam.CoordinateFrame = CFrame.new(camC0:Lerp(camC1,a), camF0:Lerp(camF1,a))
			end)
		end

		local event = _p.Events["onDoorFocused_"..door.id]
		if event and event() then
			_p.NPCChat:enable()
			self.indoors = false
			return
		end

		door:open(.75)
		player:Move(walkTo1 - player.Character.HumanoidRootPart.Position, false)
		wait(.1)
		player:Move(walkTo2 - player.Character.HumanoidRootPart.Position, false)

		------------------------------------------------------
		-- CHUNK-TO-CHUNK DOOR
		------------------------------------------------------
		if door.id:sub(1,2) == "C_" then
			local findsub = string.split(door.id, "|")
			if findsub[2] then door.id = findsub[1] end

			-- Check for onBeforeEnter event (e.g., Safari zone exit prompt)
			local beforeEnterEvent = _p.Events["onBeforeEnter_"..door.id]
			if beforeEnterEvent and beforeEnterEvent() then
				-- Event returned true, abort transition
				cam.CameraType = Enum.CameraType.Custom
				_p.NPCChat:enable()
				spawn(function() _p.Menu:enable() end)
				MasterControl.WalkEnabled = true
				self.indoors = false
				return
			end

			local newChunkId = door.id:sub(3)
			_p.MusicManager:popMusic("RegionMusic", 1, true)
			Utilities.FadeOut(1)
			MasterControl:Stop()
			Utilities.TeleportToSpawnBox()

			if findsub[2] then
				self.id = self.id .. "|" .. findsub[2]
			end

			local oldChunkId = self.id
			local doorId = "C_"..oldChunkId

			self:destroy()
			wait()

			local newChunk = _p.DataManager:loadChunk(newChunkId)
			newChunk.doorDebounce = true

			local door2 = newChunk:getDoor(doorId)

			local angle2
			pcall(function() angle2 = newChunk.roomData[doorId].DoorViewAngle end)

			local zoom2
			pcall(function() zoom2 = newChunk.roomData[doorId].DoorViewZoom end)

			local walkFrom = door2.CFrame * CFrame.new(0, -door2.Size.Y/2 + 3, 2)
			local walkTo = door2.Position + door2.CFrame.lookVector * 5

			local cam = workspace.CurrentCamera
			cam.CoordinateFrame = CFrame.new(
				door2.Position + (door2.CFrame * CFrame.Angles(math.rad(angle2 or 35),0,0)).lookVector*(zoom2 or 20),
				door2.Position
			)

			door2:open()
			Utilities.Teleport(walkFrom)
			wait()

			spawn(function() Utilities.FadeIn(1) end)

			local flat = Vector3.new(1,0,1)
			local torso = player.Character.HumanoidRootPart
			local prox

			repeat
				prox = (walkTo - torso.Position).magnitude
				player:Move((walkTo - torso.Position) * flat, false)
				stepped:wait()
			until (walkTo - torso.Position).magnitude > prox or ((walkTo - torso.Position)*flat).magnitude < .1

			MasterControl:Stop()
			door2:close(.75)

			local event2 = _p.Events["onExitC_"..oldChunkId]
			if event2 then event2(newChunk) end

			Utilities.lookBackAtMe()
			newChunk.doorDebounce = false
			MasterControl.WalkEnabled = true
			_p.NPCChat:enable()
			spawn(function() _p.Menu:enable() end)

			return
		end

		---------------------------------------------------------
		-- NORMAL DOOR ENTER
		---------------------------------------------------------
		local roomMusicId, roomMusicVolume = self:getRoomMusic(door.id)
		spawn(function()
			_p.MusicManager:fadeToVolume("top", roomMusicId and 0 or 0.3, 1)
		end)

		Utilities.FadeOut(1)

		local room = self:getRoom(door.id, door)
		self.roomStack = {room}

		local evt = _p.Events["onBeforeEnter_"..door.id]
		if evt then evt(room) end

		MasterControl:Stop()

		local entrance = self.room.Entrance
		local cf
		if entrance then
			cf = entrance.CFrame * CFrame.new(0,3,3.5) * CFrame.Angles(0, math.pi, 0)
		else
			entrance = self.room.model:FindFirstChild("ToChunk:"..self.id)
			if entrance then
				cf = entrance.CFrame * CFrame.new(0,0,-5.5)
			end
		end

		pcall(function()
			player.Character.HumanoidRootPart.Velocity = Vector3.new()
		end)

		Utilities.Teleport(cf)
		MasterControl:SetIndoors(true)

		door:close()
		self.indoorCamFunc()
		self:bindIndoorCam()

		wait(.5)

		if roomMusicId then
			_p.MusicManager:stackMusic(roomMusicId, "RoomMusic", roomMusicVolume)
		end

		Utilities.FadeIn(1)
		MasterControl.WalkEnabled = true
		_p.NPCChat:enable()
		spawn(function() _p.Menu:enable() end)
	end

	----------------------------------------------------------
	-- EXIT DOOR
	----------------------------------------------------------
	function Chunk:exitDoor(door, alreadyFaded)
		MasterControl:SetJumpEnabled(false)
		MasterControl.WalkEnabled = false
		MasterControl:Stop()
		_p.Hoverboard:unequip(true)
		MasterControl:SetIndoors(false)

		_p.NPCChat:disable()
		spawn(function() _p.Menu:disable() end)

		_p.MusicManager:popMusic("RoomMusic", 1, true)

		if not alreadyFaded then
			Utilities.FadeOut(1)
		end

		local angle
		pcall(function() angle = self.roomData[door.id].DoorViewAngle end)

		local zoom
		pcall(function() zoom = self.roomData[door.id].DoorViewZoom end)

		self:unbindIndoorCam()

		local walkFrom = door.CFrame * CFrame.new(0, -door.Size.Y/2 + 3, 2)
		local walkTo = door.Position + door.CFrame.lookVector * 5

		local cam = workspace.CurrentCamera
		local camF0 = door.Position
		local camC0 = door.Position + (door.CFrame * CFrame.Angles(math.rad(angle or 35),0,0)).lookVector * (zoom or 20)

		cam.CoordinateFrame = CFrame.new(camC0, camF0)

		door:open()
		Utilities.Teleport(walkFrom)

		if self.room then self.room:destroy() end
		self:setRoom(nil)
		self.roomStack = {}

		wait(.5)

		spawn(function() _p.MusicManager:fadeToVolume("top",1,1) end)
		spawn(function() Utilities.FadeIn(1) end)

		local flat = Vector3.new(1,0,1)
		local torso = player.Character.HumanoidRootPart

		local prox
		repeat
			prox = (walkTo - torso.Position).magnitude
			player:Move((walkTo - torso.Position) * flat, false)
			stepped:wait()
		until (walkTo - torso.Position).magnitude > prox or ((walkTo - torso.Position)*flat).magnitude < .1

		MasterControl:Stop()
		door:close(.75)

		self.indoors = false
		_p.NPCChat:enable()

		local event = _p.Events["onExit_"..door.id]

		local camCFinal = camC0
		local camFFinal = camF0
		local headP = player.Character.Head.Position

		if event and event() then
			local camGoal = CFrame.new(headP + (cam.CoordinateFrame.Position - headP).unit*12.5, headP)
			local _, lerp = Utilities.lerpCFrame(cam.CoordinateFrame, camGoal)

			Utilities.Tween(.8, "easeOutCubic", function(a)
				cam.CoordinateFrame = lerp(a)
			end)
		else
			Utilities.Tween(.2, "easeOutCubic", function(a)
				cam.CoordinateFrame = CFrame.new(
					camCFinal:Lerp(headP + (camCFinal - camFFinal).unit*12.5, a),
					camFFinal:Lerp(headP, a)
				)
			end)
		end

		cam.CameraType = Enum.CameraType.Custom
		MasterControl.WalkEnabled = true
		spawn(function() _p.Menu:enable() end)
	end

	----------------------------------------------------------
	-- HOOKUP STANDARD DOORS
	----------------------------------------------------------
	function Chunk:hookupDoor(doorModel)
		local door = Door:new(doorModel)
		table.insert(self.doors, door)

		doorModel.Main.Touched:connect(function(p)
			if door.disabled or door.locked or self.doorDebounce
				or not p or not p:IsDescendantOf(player.Character)
				or not p.Parent or p.Parent:IsA("Accoutrement")
				or _p.Battle.currentBattle then return end

			self.doorDebounce = true
			self:enterDoor(door)
			self.doorDebounce = false
		end)
	end

	----------------------------------------------------------
	-- HOOKUP CAVE DOOR
	----------------------------------------------------------
	function Chunk:hookupCaveDoor(doorPart, roomId)
		local doorCF = doorPart.CFrame
		local pos = doorCF.p
		local dir = doorCF.lookVector

		local thisChunkId = self.id

		local otherChunkId, subId, otherRoomId = doorPart.Name:match("^CaveDoor:([^:|]+):?([^|]*)|?(.*)$")
		if subId == "" then subId = nil end
		if otherRoomId == "" then otherRoomId = nil end

		doorPart.Touched:connect(function(p)
			if not p or not p.Parent or players:GetPlayerFromCharacter(p.Parent) ~= player
				or not MasterControl.WalkEnabled then return end
			if self.doorDebounce then return end

			self.doorDebounce = true
			MasterControl.WalkEnabled = false
			MasterControl:Stop()
			_p.Hoverboard:unequip(true)

			spawn(function() MasterControl:WalkTo(player.Character.HumanoidRootPart.Position - dir*20) end)

			local cam = workspace.CurrentCamera
			local camF0 = cam.Focus.Position
			local camC0 = cam.CoordinateFrame.Position
			local camF1 = pos
			local camC1 = pos + (doorCF * CFrame.Angles(math.rad(20),0,0)).lookVector * 20

			cam.CameraType = Enum.CameraType.Scriptable

			spawn(function()
				Utilities.Tween(.5,"easeOutCubic", function(a)
					cam.CoordinateFrame = CFrame.new(camC0:Lerp(camC1,a), camF0:Lerp(camF1,a))
				end)
			end)

			wait(.25)
			_p.MusicManager:popMusic("all",1)
			local circ = Utilities.FadeOutWithCircle(1,true)

			MasterControl:Stop()
			Utilities.TeleportToSpawnBox()
			self:destroy()

			local newChunk = _p.DataManager:loadChunk(otherChunkId)
			newChunk.doorDebounce = true

			local map = newChunk.map
			if otherRoomId then
				newChunk.indoors = true
				local room = newChunk:getRoom(otherRoomId, newChunk:getDoor(otherRoomId))
				newChunk.roomStack = {room}

				local evt = _p.Events["onBeforeEnter_"..otherRoomId]
				if evt then evt(room) end

				MasterControl:SetIndoors(true)
				newChunk.indoorCamFunc()
				newChunk:bindIndoorCam()

				local musicId, musicVolume = newChunk:getRoomMusic(otherRoomId)
				if musicId then
					spawn(function()
						local stack = _p.MusicManager:getMusicStack()
						while true do
							local l = stack[#stack]
							if l and l.Name == "RegionMusic" then break end
							wait(.1)
						end
						_p.MusicManager:stackMusic(musicId,"RoomMusic",musicVolume)
					end)
				end

				map = room.model
			end

			doorPart = map:FindFirstChild(
				"CaveDoor:"..thisChunkId
					.. (subId and (":"..subId) or "")
					.. (roomId and ("|"..roomId) or "")
			)

			if not doorPart and not subId then
				doorPart = map["CaveDoor:"..thisChunkId..":a"]
			end

			doorCF = doorPart.CFrame
			pos = doorCF.p
			dir = doorCF.lookVector

			local pcf = doorCF * CFrame.new(0, -doorPart.Size.Y/2 + 3, 0)
			local focus = pcf.p

			cam.CoordinateFrame = CFrame.new(
				focus + (doorCF * CFrame.Angles(math.rad(20),0,0)).lookVector * 20,
				focus
			)

			if _p.Surf.surfing then
				local bp = _p.player.Character:FindFirstChildWhichIsA("BodyPosition", true)
				if bp then
					local waterHeight = pos.Y - 0.5 * doorPart.Size.Y
					bp.Position = Vector3.new(0, waterHeight - 0.25, 0)
				end
				if _p.Surf.invalidateSurfWalls then _p.Surf.invalidateSurfWalls() end
			end

			Utilities.Teleport(pcf)
			spawn(function() Utilities.FadeInWithCircle(1,circ) end)

			MasterControl:WalkTo(pos + dir*5)
			Utilities.lookBackAtMe()
			newChunk.doorDebounce = false
			MasterControl.WalkEnabled = true
		end)
	end

	----------------------------------------------------------
	-- ITEM HOOKUP
	----------------------------------------------------------
	local obtainedCache = {}

	function Chunk:hookupItem(itemModel)
		local part = itemModel:FindFirstChild("Top")
		local hinge = itemModel:FindFirstChild("Hinge")
		local itemIdObj = itemModel:FindFirstChild("ItemId")

		local itemId = itemIdObj and itemIdObj.Value

		if not part or not hinge or not itemId or obtainedCache[itemId] then
			itemModel:Destroy()
			return
		end

		local db = false

		part.Touched:connect(function(p)
			if db or not MasterControl.WalkEnabled or not p
				or not p:IsDescendantOf(player.Character)
				or not p.Parent or p.Parent:IsA("Accoutrement") then return end

			if part.Transparency == 1 then
				pcall(function()
					itemModel.Model.Union.Transparency = 0
					part.Transparency = 0
				end)
			end

			db = true
			MasterControl.WalkEnabled = false
			MasterControl:Stop()
			_p.Hoverboard:unequip(true)

			obtainedCache[itemId] = true

			local itemName, done
			Utilities.fastSpawn(function()
				itemName = _p.Network:get("PDS","obtainItem",itemId)
				done = true
			end)

			local pos = part.Position + Vector3.new(0, -0.25, 0)
			local cf = hinge.CFrame

			delay(.2, function()
				for i = 1,12 do
					_p.Particles:new {
						Position = pos,
						Velocity = Vector3.new(0,5,0),
						VelocityVariation = 30,
						Acceleration = Vector3.new(0,-5,0),
						Size = .3,
						Image = 286854973,
						Color = Color3.new(.9,.9,.9),
						Lifetime = 3,
					}
				end
			end)

			Utilities.Tween(.5,"easeOutCubic", function(a)
				Utilities.MoveModel(hinge, cf * CFrame.Angles(0,0,-math.pi/2 * a))
			end)

			Utilities.sound(288899943, nil, nil, 10)

			local chat = _p.NPCChat
			while not done do wait() end

			if itemName then
				chat:say(_p.PlayerData.trainerName .. " found " .. Utilities.aOrAn(itemName) .. "!")
			else
				chat:say("An error occurred.")
			end

			itemModel:Destroy()

			if itemName then
				chat:say(_p.PlayerData.trainerName .. " put the " .. itemName .. " in the Bag.")
			end

			MasterControl.WalkEnabled = true
		end)
	end

	----------------------------------------------------------
	-- CHUNK INIT
	----------------------------------------------------------
	function Chunk:init(withData)
		local ignoreNPCs =
			(withData and withData.ignoreNPCs)
			or (self.id == "chunk23"
				and _p.PlayerData.completedEvents.EnteredPast
				and not _p.PlayerData.completedEvents.DefeatTEinAC)

		for _, obj in pairs(self.map:GetChildren()) do
			if obj.Name == "Door" then
				self:hookupDoor(obj)
			elseif obj.Name:match("^CaveDoor:") then
				self:hookupCaveDoor(obj)
			elseif obj.Name == "#Item" then
				self:hookupItem(obj)
			elseif not ignoreNPCs and obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
				local npc = _p.NPC:new(obj)
				if not obj:FindFirstChild("NoAnimate") then npc:Animate() end
				self.npcs[obj.Name] = npc
			end
		end

		if not ignoreNPCs then
			_p.NPC:collectNPCs(self.map, self.npcs)
		end

		local onlyRegion
		for name, region in pairs(self.data.regions) do
			if not onlyRegion then
				onlyRegion = {Name=name, isSoleRegion=true}
			else
				onlyRegion = nil
				break
			end
		end

		local event = _p.Events["onLoad_"..self.id]
		if event then event(self, withData) end

		delay(.5, function()
			if onlyRegion then
				Utilities.fastSpawn(function()
					self:changedRegions(onlyRegion)
				end)
				self.currentRegion = onlyRegion
			else
				while self.regions do
					if not self.indoors then self:checkRegion() end
					wait(.5)
				end
			end
		end)
	end

	----------------------------------------------------------
	-- DESTROY
	----------------------------------------------------------
	function Chunk:destroy()
		local event = _p.Events["onUnload_"..self.id]
		if event then event() end

		if self.lightingRestore then
			local lighting = game:GetService("Lighting")
			for prop, val in pairs(self.lightingRestore) do
				lighting[prop] = val
			end
		end

		self.regions = nil
		self.currentRegion = nil
		self.regionData = nil

		pcall(function() self.map:Destroy() end)

		local music = self.Music
		if music then
			spawn(function()
				local v = music.Volume
				Utilities.Tween(.5, nil, function(a)
					music.Volume = v * (1-a)
				end)
				music:Destroy()
			end)
		end

		for _, room in pairs(self.roomStack) do
			pcall(function() room:Destroy() end)
		end
		self.roomStack = nil

		for _, room in pairs(self.rooms) do
			pcall(function() room:Destroy() end)
		end
		self.rooms = nil

		for _, door in pairs(self.doors) do
			pcall(function() door:Destroy() end)
		end
		self.doors = nil

		for _, npc in pairs(self.npcs) do
			pcall(function() npc:Destroy() end)
		end
		self.npcs = nil
	end

	----------------------------------------------------------
	return Chunk
end
