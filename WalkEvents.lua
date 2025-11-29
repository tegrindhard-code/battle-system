return function(_p)--local _p = require(script.Parent)
	local Utilities = _p.Utilities
	local create = Utilities.Create
	local write = Utilities.Write
	local MasterControl = _p.MasterControl

	local player = _p.player

	local WalkEvents = {
		checkEggs = true,
		stepsRemaining = nil, -- Safari zone steps tracking
	}

	local boundStepFunctions = {}

	--
	local lastTorsoPos
	local distanceWalked = 0
	local studsPerGrassStep = 2
	local grassStepsPerEggStep = 2
	local immunitySteps = 0

	local eggStepCount = 0
	--

	local repel, rShoes

	-- Safari Zone step counter UI
	local safariStepUI = nil

	function WalkEvents:createSafariStepUI()
		if safariStepUI then
			safariStepUI:Destroy()
		end

		local frontGui = Utilities.frontGui
		if not frontGui then return end

		safariStepUI = create 'Frame' {
			Name = 'SafariStepCounter',
			BackgroundTransparency = 1.0,
			Size = UDim2.new(0.25, 0, 0.08, 0),
			Position = UDim2.new(0.02, 0, 0.85, 0), -- Bottom left corner
			Parent = frontGui,
			ZIndex = 10,
		}

		self:updateSafariStepUI()
	end

	function WalkEvents:updateSafariStepUI()
		if not safariStepUI then return end

		-- Remove old text
		for _, child in pairs(safariStepUI:GetChildren()) do
			child:Destroy()
		end

		if not self.stepsRemaining or self.stepsRemaining <= 0 then
			return
		end

		write(self.stepsRemaining .. " steps remaining") {
			Frame = safariStepUI,
			Scaled = true,
			Color = Color3.new(1, 1, 1), -- White text
			Size = 1.0,
		}
	end

	function WalkEvents:removeSafariStepUI()
		if safariStepUI then
			safariStepUI:Destroy()
			safariStepUI = nil
		end
	end

	function WalkEvents:init()
		repel = _p.Repel
		rShoes = _p.RunningShoes
	end

	local queuedHatch
	_p.Network:bindEvent('hatch', function(data) queuedHatch = data end)
	function WalkEvents:clearHatchQueue() queuedHatch = nil end

	--local lastEggStepTick = tick()--
	local function onStepTaken(inGrass, inMiscGrass, IsSurfing)
		if not MasterControl.WalkEnabled then return end -- let's not count forced steps

		-- Deduct safari zone steps when walking
		if WalkEvents.stepsRemaining and WalkEvents.stepsRemaining > 0 then
			WalkEvents.stepsRemaining = WalkEvents.stepsRemaining - 1
			WalkEvents:updateSafariStepUI()
			_p.Network:post('PDS', 'updateSafariSteps', WalkEvents.stepsRemaining)

			-- Check if steps ran out
			if WalkEvents.stepsRemaining <= 0 then
				-- Player ran out of steps, show dramatic display
				WalkEvents:removeSafariStepUI()

				local frontGui = Utilities.frontGui
				if frontGui then
					-- Create dramatic center screen display
					local dramaBG = create 'Frame' {
						Name = 'SafariOutOfSteps',
						BackgroundTransparency = 0.3,
						BackgroundColor3 = Color3.new(0, 0, 0),
						Size = UDim2.new(1, 0, 1, 0),
						Position = UDim2.new(0, 0, 0, 0),
						Parent = frontGui,
						ZIndex = 100,
					}

					local textFrame = create 'Frame' {
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.8, 0, 0.3, 0),
						Position = UDim2.new(0.1, 0, 0.35, 0),
						Parent = dramaBG,
						ZIndex = 101,
					}

					write("OUT OF STEPS!") {
						Frame = textFrame,
						Scaled = true,
						Color = Color3.new(1, 0, 0), -- Red text
						Size = 2.5, -- Much bigger
					}

					-- Wait 5 seconds then leave safari
					delay(5, function()
						dramaBG:Destroy()
						local function leaveSafari(chunk, forced)
							local map = chunk.map
							if map.DoorA and map.DoorB then
								local escort2 = {
									"Thank you for visiting the Safari Zone!\n" ..
										"Come back soon!"
								}
								local escort1 = {
									"You're out of Safari Balls!\n" ..
										"You were escorted out of the Safari Zone."
								}
								local escort = {
									"You've hit the step limit!\n"..
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
											local count = _p.Battle.SBCount
											if count == 0 then 
												_p.NPCChat:say(escort1)
											elseif _p.Battle.stepsRemaining == 0 then
												_p.NPCChat:say(escort)
											end
										end
										wait(0.5)
										if _p.DataManager then
											_p.DataManager.currentChunk:Destroy()
											_p.DataManager:loadChunk('chunk89')
											_p.player.Character.HumanoidRootPart.Position = Vector3.new(-1811.142, -3288.876, 733.832)
											_p.NPCChat:say('Thanks for visiting! Come again anytime you want!')
										end
									end)
									return
								end
							end
						
						leaveSafari(nil, true)
					end)
				else
					-- Fallback if no frontGui
					if _p.L then
						_p.L.leave(_p, nil, true)
					end
				end
			end
		end

		for n, t in pairs(boundStepFunctions) do
			if type(t) == 'function' then
				t()
			else
				t[3] = t[3] + 1
				if t[3] >= t[2] then
					t[3] = 0
					t[1]()
				end
			end
		end
		eggStepCount = eggStepCount + 1/grassStepsPerEggStep--(1 + getRoPowerLevel(2))/grassStepsPerEggStep
		if eggStepCount >= 256 then
			--		print(tick()-lastEggStepTick)--
			--		lastEggStepTick = tick()--
			_p.Network:post('PDS', 'completedEggCycle')
			eggStepCount = eggStepCount % 256
			return
		end
		if queuedHatch then
			local data = queuedHatch
			queuedHatch = nil
			_p.Pokemon:hatch(data)
			print('Egg hatching')
			return
		end
		if repel.steps > 0 then
			repel.steps = repel.steps - 1
			if repel.steps == 0 then
				MasterControl.WalkEnabled = false
				MasterControl:Stop()
				_p.NPCChat:say('The repellent\'s effect wore off.')
				local kind = repel.kinds[repel.kind]
				if repel.more and _p.NPCChat:say('[y/n]Use another?') then
					repel.steps = kind.steps * 2 -- double because grass is actually checked 2x per "step"
					Utilities.fastSpawn(function() repel.more = _p.Network:get('PDS', 'useItem', Utilities.rc4(kind.id)) == 1 end)
					_p.NPCChat:say(_p.PlayerData.trainerName .. ' used a ' .. kind.name .. '.')
				end
				MasterControl.WalkEnabled = true
				MasterControl:Stop()
				return
			end
		end
		local s, regionData = pcall(function() return _p.DataManager.currentChunk.regionData end)
		if not s or not regionData then return end
		local grass
		local scene
		local GrassNotRequired
		if not IsSurfing then
			GrassNotRequired = regionData.GrassNotRequired
		end
		if inGrass or (GrassNotRequired and (not regionData.NoGrassIndoors or not _p.DataManager.currentChunk.indoors)) then
			grass = regionData.Grass
			scene = nil
		elseif inMiscGrass then
			grass = regionData.MiscEncounter
			scene = nil
		elseif IsSurfing then
			grass = regionData.Surf
			scene = 'Surf'
			pcall(function()
				local s = _p.DataManager.currentChunk.regionData.SurfScene
				if s then scene = s end
			end)
		end
		if not grass or _p.Battle.currentBattle then return end
		if immunitySteps > 0 or repel.steps > 0 then
			immunitySteps = immunitySteps - 1
		elseif math.random(100) <= (regionData.GrassEncounterChance or 12) then
			immunitySteps = 8
			_p.Battle:doWildBattle(grass, {battleSceneType = scene}, repel.steps>0)
		end
	end


	local charIsGrounded; do
		local function grassIgnoreFn(obj)
			if obj:IsA('BasePart') and not obj.CanCollide and obj.Name ~= 'Grass' and obj.Name ~= 'MiscGrass' and obj.Name ~= 'Water' then
				return true
			end
			return false
		end
		local fporwif = Utilities.findPartOnRayWithIgnoreFunction
		local ray = Ray.new
		local up = Vector3.new(0, 1.5, 0)
		local down = Vector3.new(0, -5.5, 0)
		local hoverdown = Vector3.new(0, -7.5, 0)

		local sandModeOn = false
		local function sandIgnoreFn(obj)
			return obj.Name ~= 'Sand'
		end
		local function leaveFootprint(root, leg)
			if not root or not leg then return end
			return function()
				if rShoes.running then return end
				local _, _, _, _, tx, _, _, ty, _, _, tz, _ = leg.CFrame:components()
				local part, pos, normal = fporwif(ray(leg.Position, Vector3.new(tx*-1.5,ty*-1.5,tz*-1.5)), {player.Character}, sandIgnoreFn)
				if not part then return end
				local front = root.CFrame.lookVector
				local right = front:Cross(normal)
				local cf = CFrame.new(pos.X, pos.Y, pos.Z,
					right.X, normal.X, -front.X,
					right.Y, normal.Y, -front.Y,
					right.Z, normal.Z, -front.Z)
				local fp = create 'Part' {
					--				FormFactor = Enum.FormFactor.Custom,
					Transparency = 1.0,
					Anchored = true,
					CanCollide = false,

					create 'Decal' {
						Face = Enum.NormalId.Top,
						Texture = 'rbxassetid://5119874352',--5217748251
						Shiny = 0,
						Specular = 0,
					}
				}
				fp.Size = Vector3.new(.9, .2, .9)
				fp.CFrame = cf * CFrame.new(0, -.09, 0)
				fp.Parent = workspace
				delay(3, function()
					Utilities.Tween(1, nil, function(a)
						fp.Decal.Transparency = a
					end)
					fp:Destroy()
				end)
			end
		end

		charIsGrounded = function(torso)
			local hit = fporwif(ray(torso.Position + up, _p.Hoverboard.equipped and hoverdown or down), {player.Character}, grassIgnoreFn)
			local name = hit and hit.Name
			if not sandModeOn and name == 'Sand' then
				sandModeOn = true
				local ch = _p.player.Character
				local root = ch:FindFirstChild('HumanoidRootPart')
				_p.Animation:BindKeyframeReachedEvent('walk', 'RightFootDown', leaveFootprint(root, ch:FindFirstChild('Right Leg')))
				_p.Animation:BindKeyframeReachedEvent('walk', 'LeftFootDown', leaveFootprint(root, ch:FindFirstChild('Left Leg')))
			elseif sandModeOn and name ~= 'Sand' then
				sandModeOn = false
				_p.Animation:UnbindKeyframeReachedEvent('walk', 'RightFootDown')
				_p.Animation:UnbindKeyframeReachedEvent('walk', 'LeftFootDown')
			end
			return (hit ~= nil), (name == 'Grass'), (name == 'MiscGrass'), (name == 'Water')
		end
	end

	function WalkEvents:bindToStep(name, fn, nSteps)
		if nSteps then
			boundStepFunctions[name] = {fn, nSteps, 0}
		else
			boundStepFunctions[name] = fn
		end
	end

	function WalkEvents:unbindFromStep(name)
		boundStepFunctions[name] = nil
	end

	function WalkEvents:resetStepDistance()
		distanceWalked = 0
	end

	function WalkEvents:beginLoop()
		local flat = Vector3.new(1,0,1)
		local tc = _p.NPC.trainersCheck
		local heartbeat = game:GetService('RunService').Heartbeat
		while true do
			heartbeat:wait()
			if not tc() then
				local pos, torso
				pcall(function()
					torso = player.Character.HumanoidRootPart -- Has to be humanoidRootPart because Torso wouldnt work for R15
					pos = torso.Position
				end)
				if not lastTorsoPos or not pos or not torso then
					lastTorsoPos = pos
				else
					local dist = ((lastTorsoPos-pos)*flat).magnitude
					lastTorsoPos = pos
					distanceWalked = distanceWalked + dist
					local isGrounded, isInGrass, isInMiscGrass = charIsGrounded(torso)
					local IsSurfing = _p.Surf.surfing
					if distanceWalked >= studsPerGrassStep and isGrounded then
						distanceWalked = distanceWalked % studsPerGrassStep
						onStepTaken(isInGrass, isInMiscGrass, IsSurfing)
					elseif distanceWalked >= studsPerGrassStep and IsSurfing then
						distanceWalked = distanceWalked % studsPerGrassStep
						onStepTaken(isInGrass, isInMiscGrass, IsSurfing)
					end
				end
			end
		end
	end


	return WalkEvents end
