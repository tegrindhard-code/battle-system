return function(_p)
	local Utilities = _p.Utilities
	local create = Utilities.Create
	local write = Utilities.Write

	local function createLabel(text, config)
		return create 'TextLabel' {
			BackgroundTransparency = 1,
			Size = config.Size or UDim2.new(1, 0, 1, 0),
			Position = config.Position or UDim2.new(0, 0, 0, 0),
			ZIndex = config.ZIndex or 3,
			Parent = config.Parent,
			Text = text,
			TextColor3 = config.Color or Color3.new(1, 1, 1),
			TextScaled = true,
			TextWrapped = true,
			Font = Enum.Font.GothamBold,
			TextXAlignment = config.TextXAlignment or Enum.TextXAlignment.Center,
			TextYAlignment = config.TextYAlignment or Enum.TextYAlignment.Center,
		}
	end

	local options = {
		isOpen = false,
		lastUnstuckTick = 0,
		reduceGraphics = false,
		codesEnabled = true,
		IconSFX = false,
		epilepsy = false,
		battleStyle = 1,
		battles3D = false

	}
	local gui, bg, close, unstuckButton, unstuckTimerContainer, CodesTextBox, CodesFrame, MusicEncounterFrame

	local unstuckCooldown = 5 * 2
	local madePages = false
	local currentPage = 1
	local pageContainer
	local toggles = {}
	local dropdowns = {}

	local function color(r, g, b)
		return Color3.new(r/255, g/255, b/255)
	end

	local function setupBusyFn(fn)
		local busy = false
		return function(...)
			if busy then return end
			busy = true
			fn(...)
			busy = false
		end
	end

	local function unstuckTimer()
		Utilities.fastSpawn(function()
			unstuckTimerContainer:ClearAllChildren()
			local et = tick()-options.lastUnstuckTick
			if et >= unstuckCooldown then
				write 'Ready' {
					Frame = unstuckTimerContainer,
					Scaled = true,
					Color = color(124, 200, 99),
				}
				return
			end
			et = math.floor(et+.5)
			while gui.Parent do
				local t = options.lastUnstuckTick + et + 1
				wait(t-tick())
				unstuckTimerContainer:ClearAllChildren()
				et = math.floor(tick()-options.lastUnstuckTick+.5)
				if et >= unstuckCooldown then
					write 'Ready' {
						Frame = unstuckTimerContainer,
						Scaled = true,
						Color = color(124, 200, 99),
					}
					return
				end
				local rt = unstuckCooldown-et
				local rm = math.floor(rt/60)
				local rs = rt%60
				write(rm..':'..(rs<10 and ('0'..rs) or rs)) {
					Frame = unstuckTimerContainer,
					Scaled = true,
				}
			end
		end)
	end

	function options:setLightingForReducedGraphics(isReduced)
		local lighting = game:GetService('Lighting')
		lighting.GlobalShadows = not isReduced
		lighting.Ambient = isReduced and Color3.new(.6, .6, .6) or Color3.new(.3, .3, .3)
		lighting.OutdoorAmbient = isReduced and Color3.new(.75, .75, .75) or Color3.new(.5, .5, .5)
		pcall(function() _p.DataManager.currentChunk:setDay(_p.DataManager.isDay) end)
	end

	function options:getUnstuck(manually)
		if not manually and tick()-self.lastUnstuckTick < unstuckCooldown then return end
		local chunk = _p.DataManager.currentChunk
		_p.Hoverboard:unequip(true)
		if _p.Surf.surfing then
			if chunk.id ~= 'chunk69' then
				_p.Surf:forceUnsurf()
			end
		end
		local cf
		if _p.context == 'battle' then
			local t = math.random()*math.pi*2
			local r = math.random()*40
			cf = CFrame.new(-24.4, 3.5, -206.5) + Vector3.new(math.cos(t)*r, 0, math.sin(t)*r)
		else
			if chunk.id == 'mining' then
				cf = CFrame.new(350, 93, -883)
				if manually then
					Utilities.TeleportToSpawnBox()
					chunk:destroy()
					wait(.5)
					_p.DataManager:loadChunk('chunk9')
					wait(.5)
					Utilities.Teleport(cf)
				else
					Utilities.FadeOut(.5, Color3.new(0, 0, 0))
					Utilities.TeleportToSpawnBox()
					chunk:destroy()
					wait(.5)
					_p.DataManager:loadChunk('chunk9')
					wait(.5)
					Utilities.Teleport(cf)
					self.lastUnstuckTick = tick()
					self:fastClose(false)
					wait(.5)
					Utilities.FadeIn(.5)
					_p.MasterControl.WalkEnabled = true
				end
				return
			end
			if chunk.indoors then
				local room = chunk:topRoom()
				local entrance = room.Entrance
				if entrance then
					cf = entrance.CFrame * CFrame.new(0, 3, 3.5) * CFrame.Angles(0, math.pi, 0)
				else
					entrance = room.model:FindFirstChild('ToChunk:'..chunk.id)
					if entrance then
						cf = entrance.CFrame * CFrame.new(0, 0, -5.5)
					end
				end
			else
				local door
				if chunk.id == 'chunk1' then
					door = chunk:getDoor('yourhomef1')
				elseif chunk.id == 'chunk7' then
					cf = CFrame.new(-761, 45.2, -705)
				elseif chunk.id == 'chunk9' then
					door = chunk:getDoor('PokeCenter')
				elseif chunk.id == 'chunk16' then
					cf = CFrame.new(662.3, 9.5, 628.5)
				elseif chunk.id == 'chunk23' then
					door = chunk:getDoor('C_chunk20')
				elseif chunk.id == 'gym6' then
					cf = CFrame.new(989, 52, 503)
				elseif chunk.id == 'chunk45' then
					cf = CFrame.new(-5086.791, 2007.131, 1738.624)
				elseif chunk.id == 'gym7' then
					door = chunk:getDoor('C_chunk46')
				elseif chunk.id == 'chunk55' then
					door = chunk:getDoor('C_chunk54')
				elseif chunk.id == 'chunk65' then
					cf = CFrame.new(736.754, 9641.552, 7278.048)
				elseif chunk.id == 'chunk74' then
					cf = CFrame.new(-106, 184.117, -1603.9)
				elseif chunk.id == 'chunk77' then
					cf = CFrame.new(-91.504, 325.407, -743.627)
				elseif chunk.id == 'chunk78' then
					door = chunk:getDoor('C_chunk77|a')
				elseif chunk.id == 'chunk79' then
					door = chunk:getDoor('C_chunk77|a')
				elseif chunk.id == 'chunk80' then
					door = chunk:getDoor('C_chunk77')
				elseif chunk.id == 'chunk81' then
					door = chunk:getDoor('C_chunk77')
				elseif chunk.id == 'chunk82' then
					door = chunk:getDoor('C_chunk77')
				elseif chunk.id == 'chunk83' then
					door = chunk:getDoor('C_chunk77')
				elseif chunk.id == 'chunk84' then
					door = chunk:getDoor('C_chunk83')
				elseif chunk.id == 'chunk85' then
					door = chunk:getDoor('C_chunk79')
				elseif chunk.id == 'gym8' then
					cf = CFrame.new(4599.507, 40.324, -6913.594)
				elseif chunk.id == 'chunk2000' then
					cf = CFrame.new(-157.416, 1.309, -63.486)
				elseif chunk.id == 'chunk2001' then
					cf = CFrame.new(1654.441, 300.508, 11567.69)
				else
					door = chunk:getDoor('PokeCenter')
					if not door then
						local gateNum = 999
						for _, d in pairs(chunk.doors) do
							if d.id:sub(1, 4) == 'Gate' then
								local n = tonumber(d.id:sub(5))
								if n and n < gateNum then
									door = d
									gateNum = n
								end
							end
						end
					end
					if not door then
						print('trying cave doors')
						local caveDoor
						local cdn
						for _, p in pairs(chunk.map:GetChildren()) do
							if p:IsA('BasePart') then
								local id = p.Name:match('^CaveDoor:([^:]+)')
								if id then
									local n
									if id:sub(1, 5) == 'chunk' then
										n = tonumber(id:sub(6))
									end
									print('found cave door:', n or '?')
									if not caveDoor or (not cdn and n) or (cdn and n and n < cdn) then
										print('setting')
										caveDoor = p
										cdn = n
									end
								end
							end
						end
						if caveDoor then
							cf = caveDoor.CFrame * CFrame.new(0, -caveDoor.Size.Y/2+3, -caveDoor.Size.Z-4)
						end
					end
				end
				if door then
					cf = door.CFrame * CFrame.new(0, 0, -5)
				end
			end
		end
		if cf then
			if manually then
				Utilities.Teleport(cf)
			else
				Utilities.FadeOut(.5, Color3.new(0, 0, 0))
				Utilities.Teleport(cf)
				self.lastUnstuckTick = tick()
				self:fastClose(false)
				wait(.5)
				Utilities.FadeIn(.5)
				_p.MasterControl.WalkEnabled = true
			end
		end
	end

	local StarterGui = game:GetService("StarterGui")
	local BindableEvent = create("BindableEvent")({
		Event = function()
			if not _p.MasterControl.WalkEnabled then
				return
			end
			if not (tick() - options.lastUnstuckTick < unstuckCooldown) then
				options:getUnstuck(false)
				return
			end
			StarterGui:SetCore("SendNotification", {
				Title = "Reset Cooldown", 
				Text = "Please wait " .. math.ceil(unstuckCooldown - (tick() - options.lastUnstuckTick)) .. " seconds before trying again.", 
				Duration = 5
			})
		end
	})

	local function Connect()
		return pcall(function()
			StarterGui:SetCore("ResetButtonCallback", BindableEvent)
		end)
	end
	if not Connect() then
		delay(5, function()
			while not Connect() do
				wait(5)            
			end
		end)
	end

	function options:makePages()
		if madePages then return end
		madePages = true

		local pages = {
			-- PAGE 1: Main Options
			function(pageGui)
				-- Autosave
				local autosaveToggle = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.075, 0),
					Value = _p.Autosave.enabled,
					ZIndex = 3, Parent = pageGui,
				}
				autosaveToggle.ValueChanged:connect(function()
					if autosaveToggle.Value then
						autosaveToggle.Enabled = false
						wait(.2)
						if _p.NPCChat:say('Autosave will save every two minutes, and after completing battles.',
							'It is recommended that you still manually save before leaving the game.',
							'[y/n]Would you like to enable Autosave?') then
							if _p.Menu.willOverwriteIfSaveFlag then
								if _p.NPCChat:say('There is another save file that may be overwritten by Autosave.',
									'[y/n]Would you still like to enable Autosave?') then
									_p.Autosave:enable()
								else
									autosaveToggle:animateToValue(false)
								end
							else
								_p.Autosave:enable()
							end
						else
							autosaveToggle:animateToValue(false)
						end
						autosaveToggle.Enabled = true
					else
						_p.Autosave:disable()
					end
				end)
				table.insert(toggles, autosaveToggle)

				write 'Autosave' {
					Frame = create 'Frame' {
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.0, 0, 0.05, 0),
						Position = UDim2.new(0.05, 0, 0.1, 0),
						ZIndex = 3, Parent = pageGui,
					}, Scaled = true, TextXAlignment = Enum.TextXAlignment.Left,
				}

				-- Reduced Graphics
				local reducedGraphicsToggle = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.225, 0),
					Value = options.reduceGraphics,
					ZIndex = 3, Parent = pageGui,
				}
				reducedGraphicsToggle.ValueChanged:connect(function()
					reducedGraphicsToggle.Enabled = false
					local chunk = _p.DataManager.currentChunk
					local v = reducedGraphicsToggle.Value
					options.reduceGraphics = v
					options:setLightingForReducedGraphics(v)
					if not _p.Utilities.isTouchDevice() then
						local grass = _p.DataManager:request({'Grass', chunk.id, v})
						if grass then
							pcall(function() chunk.map[v and 'Grass' or 'MGrass']:Destroy() end)
							grass.Parent = chunk.map
						end
					end
					reducedGraphicsToggle.Enabled = true
				end)
				table.insert(toggles, reducedGraphicsToggle)

				write 'Reduced Graphics' {
					Frame = create 'Frame' {
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.0, 0, 0.05, 0),
						Position = UDim2.new(0.05, 0, 0.25, 0),
						ZIndex = 3, Parent = pageGui,
					}, Scaled = true, TextXAlignment = Enum.TextXAlignment.Left,
				}

				-- Instant Text Speed
				write 'Instant Text Speed' {
					Frame = create 'Frame' {
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.0, 0, 0.05, 0),
						Position = UDim2.new(0.05, 0, 0.4, 0),
						ZIndex = 3, Parent = pageGui,
					}, Scaled = true, TextXAlignment = Enum.TextXAlignment.Left,
				}

				local TextSpeed = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.375, 0),
					Value = _p.NPCChat.speed ~= 35 and true or false,
					ZIndex = 3, Parent = pageGui,
				}
				TextSpeed.ValueChanged:connect(function()
					_p.NPCChat.speed = TextSpeed.Value and 35*1000 or 35
				end)
				table.insert(toggles, TextSpeed)

				-- Unstuck
				write 'Stuck?' {
					Frame = create 'Frame' {
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.0, 0, 0.05, 0),
						Position = UDim2.new(0.05, 0, 0.55, 0),
						ZIndex = 3, Parent = pageGui,
					}, Scaled = true, TextXAlignment = Enum.TextXAlignment.Left,
				}
				unstuckButton = _p.RoundedFrame:new {
					Button = true,
					BackgroundColor3 = Color3.new(.4, .4, .4),
					Size = UDim2.new(0.4, 0, 0.1, 0),
					Position = UDim2.new(0.3, 0, 0.525, 0),
					ZIndex = 3, Parent = pageGui,
					MouseButton1Click = setupBusyFn(function()
						options:getUnstuck()
					end),
				}
				write 'Get Unstuck' {
					Frame = create 'Frame' {
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.4, 0, 0.05, 0),
						Position = UDim2.new(0.3, 0, 0.55, 0),
						ZIndex = 4, Parent = pageGui,
					}, Scaled = true, Color = Color3.new(.8, .8, .8),
				}
				unstuckTimerContainer = create 'Frame' {
					BackgroundTransparency = 1.0,
					Size = UDim2.new(0.0, 0, 0.05, 0),
					Position = UDim2.new(0.825, 0, 0.55, 0),
					ZIndex = 3, Parent = pageGui,
				}

				-- Icons SFX
				local IconSFXToggle = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.675, 0),
					Value = options.IconSFX,
					ZIndex = 3, Parent = pageGui,
				}
				IconSFXToggle.ValueChanged:connect(function()
					options.IconSFX = IconSFXToggle.Value
				end)
				table.insert(toggles, IconSFXToggle)

				write("Icons SFX") {
					Frame = create 'Frame' {
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 0, 0.05, 0),
						Position = UDim2.new(0.05, 0, 0.7, 0),
						ZIndex = 3, Parent = pageGui,
					}, Scaled = true, TextXAlignment = Enum.TextXAlignment.Left,
				}

				-- Battle Flashing
				local epilepsyTrigger = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.825, 0),
					Value = options.epilepsy,
					ZIndex = 3, Parent = pageGui,
				}
				epilepsyTrigger.ValueChanged:connect(function()
					options.epilepsy = epilepsyTrigger.Value
				end)
				table.insert(toggles, epilepsyTrigger)

				write("Battle Flashing Off") {
					Frame = create 'Frame' {
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 0, 0.05, 0),
						Position = UDim2.new(0.05, 0, 0.85, 0),
						ZIndex = 3, Parent = pageGui,
					}, Scaled = true, TextXAlignment = Enum.TextXAlignment.Left,
				}
			end,

			-- PAGE 2: Verification & Claims
			function(pageGui)
				createLabel('Discord Verification', {
					Size = UDim2.new(0.9, 0, 0.06, 0),
					Position = UDim2.new(0.05, 0, 0.02, 0),
					ZIndex = 3, Parent = pageGui,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local verifyButton = _p.RoundedFrame:new {
					Button = true,
					BackgroundColor3 = Color3.new(.3, .5, .8),
					Size = UDim2.new(0.5, 0, 0.1, 0),
					Position = UDim2.new(0.25, 0, 0.1, 0),
					ZIndex = 3, Parent = pageGui,
					MouseButton1Click = setupBusyFn(function()
						local success, result = pcall(function()
							return _p.Network:get('PDS', 'generateVerificationCode')
						end)
						if success and result and type(result) == 'table' and result.code then
							_p.NPCChat:say(
								'Your verification code is:',
								result.code,
								'Badges: ' .. result.badges .. ' | Level Cap: ' .. result.levelCap,
								'Use /verify ' .. result.code .. ' in Discord!'
							)
						elseif not success then
							_p.NPCChat:say('Network error. Check that generateVerificationCode', 'is added to publicFns in PlayerDataService.')
						else
							_p.NPCChat:say('Failed to generate code.', 'Make sure generateVerificationCode is in publicFns.')
						end
					end),
				}
				createLabel('Get Verification Code', {
					Size = UDim2.new(0.5, 0, 0.1, 0),
					Position = UDim2.new(0.25, 0, 0.1, 0),
					ZIndex = 4, Parent = pageGui,
				})

				createLabel('Claim Rewards', {
					Size = UDim2.new(0.9, 0, 0.06, 0),
					Position = UDim2.new(0.05, 0, 0.24, 0),
					ZIndex = 3, Parent = pageGui,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local claimSpinButton = _p.RoundedFrame:new {
					Button = true,
					BackgroundColor3 = Color3.new(.6, .3, .7),
					Size = UDim2.new(0.44, 0, 0.12, 0),
					Position = UDim2.new(0.03, 0, 0.32, 0),
					ZIndex = 3, Parent = pageGui,
					MouseButton1Click = setupBusyFn(function()
						local success, result = pcall(function()
							return _p.Network:get('PDS', 'claimSpinRewards')
						end)
						if success and result and type(result) == 'table' then
							if result.success then
								local rewardText = ''
								if result.rewards and #result.rewards > 0 then
									for _, r in ipairs(result.rewards) do
										if r.name then
											rewardText = rewardText .. r.name .. ', '
										end
									end
									rewardText = rewardText:sub(1, -3)
								end
								_p.NPCChat:say(
									'Claimed ' .. result.count .. ' spin reward(s)!',
									rewardText ~= '' and ('Received: ' .. rewardText) or 'Check your PC!'
								)
							else
								_p.NPCChat:say(result.message or 'No pending spin rewards.')
							end
						elseif not success then
							_p.NPCChat:say('Network error.', 'Make sure claimSpinRewards is in publicFns.')
						else
							_p.NPCChat:say('No pending spin rewards.')
						end
					end),
				}
				createLabel('Claim Spun Pokemon', {
					Size = UDim2.new(0.44, 0, 0.12, 0),
					Position = UDim2.new(0.03, 0, 0.32, 0),
					ZIndex = 4, Parent = pageGui,
				})

				local claimSpawnButton = _p.RoundedFrame:new {
					Button = true,
					BackgroundColor3 = Color3.new(.7, .5, .2),
					Size = UDim2.new(0.44, 0, 0.12, 0),
					Position = UDim2.new(0.53, 0, 0.32, 0),
					ZIndex = 3, Parent = pageGui,
					MouseButton1Click = setupBusyFn(function()
						local success, result = pcall(function()
							return _p.Network:get('PDS', 'claimSpawnRewards')
						end)
						if success and result and type(result) == 'table' then
							if result.success then
								local rewardText = ''
								if result.rewards and #result.rewards > 0 then
									for _, r in ipairs(result.rewards) do
										if r.type then
											rewardText = rewardText .. r.type .. ', '
										end
									end
									rewardText = rewardText:sub(1, -3)
								end
								_p.NPCChat:say(
									'Claimed ' .. result.count .. ' spawned reward(s)!',
									rewardText ~= '' and ('Types: ' .. rewardText) or 'Check your PC/Bag!'
								)
							else
								_p.NPCChat:say(result.message or 'No pending spawn rewards.')
							end
						elseif not success then
							_p.NPCChat:say('Network error.', 'Make sure claimSpawnRewards is in publicFns.')
						else
							_p.NPCChat:say('No pending spawn rewards.')
						end
					end),
				}
				createLabel('Claim Spawned Gifts', {
					Size = UDim2.new(0.44, 0, 0.12, 0),
					Position = UDim2.new(0.53, 0, 0.32, 0),
					ZIndex = 4, Parent = pageGui,
				})

				createLabel('Spin rewards: from Discord /spin', {
					Size = UDim2.new(0.9, 0, 0.06, 0),
					Position = UDim2.new(0.05, 0, 0.48, 0),
					ZIndex = 3, Parent = pageGui,
				})

				createLabel('Spawned gifts: from mods/admins', {
					Size = UDim2.new(0.9, 0, 0.06, 0),
					Position = UDim2.new(0.05, 0, 0.56, 0),
					ZIndex = 3, Parent = pageGui,
				})
			end,
--// Page 3
			function(pageGui)
				createLabel('3D Battles', {
					Size = UDim2.new(0.7, 0, 0.06, 0),
					Position = UDim2.new(0.05, 0, 0.08, 0),
					ZIndex = 3, Parent = pageGui,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local BattlesTog = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.055, 0),
					Value = options.battles3D,
					ZIndex = 3, Parent = pageGui,
				}
				BattlesTog.ValueChanged:connect(function()
					options.battles3D = BattlesTog.Value
				end)
				table.insert(toggles, BattlesTog)

				-- Placeholder Option 2
				createLabel('Placeholder Option 2', {
					Size = UDim2.new(0.7, 0, 0.06, 0),
					Position = UDim2.new(0.05, 0, 0.25, 0),
					ZIndex = 3, Parent = pageGui,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local placeholder2Toggle = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.225, 0),
					Value = false,
					ZIndex = 3, Parent = pageGui,
				}
				placeholder2Toggle.ValueChanged:connect(function()
					-- .. Your Logic here
					print('Placeholder Option 2:', placeholder2Toggle.Value)
				end)
				table.insert(toggles, placeholder2Toggle)

				-- Placeholder Option 3
				createLabel('Placeholder Option 3', {
					Size = UDim2.new(0.7, 0, 0.06, 0),
					Position = UDim2.new(0.05, 0, 0.42, 0),
					ZIndex = 3, Parent = pageGui,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local placeholder3Toggle = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.395, 0),
					Value = false,
					ZIndex = 3, Parent = pageGui,
				}
				placeholder3Toggle.ValueChanged:connect(function()
					-- .. Your Logic here
					print('Placeholder Option 3:', placeholder3Toggle.Value)
				end)
				table.insert(toggles, placeholder3Toggle)

				-- Placeholder Option 4
				createLabel('Placeholder Option 4', {
					Size = UDim2.new(0.7, 0, 0.06, 0),
					Position = UDim2.new(0.05, 0, 0.59, 0),
					ZIndex = 3, Parent = pageGui,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				local placeholder4Toggle = _p.ToggleButton:new {
					Size = UDim2.new(0.0, 0, 0.1, 0),
					Position = UDim2.new(0.8, 0, 0.565, 0),
					Value = false,
					ZIndex = 3, Parent = pageGui,
				}
				placeholder4Toggle.ValueChanged:connect(function()
					-- .. Your Logic here
					print('Placeholder Option 4:', placeholder4Toggle.Value)
				end)
				table.insert(toggles, placeholder4Toggle)
			end,
		}

		pageContainer = create 'Frame' {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0.85, 0),
			Position = UDim2.new(0, 0, 0.1, 0),
			ZIndex = 3, Parent = gui,
		}

		local pageFrames = {}
		for i, pageFn in ipairs(pages) do
			local pageFrame = create 'Frame' {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Visible = i == 1,
				ZIndex = 3, Parent = pageContainer,
			}
			pageFn(pageFrame)
			pageFrames[i] = pageFrame
		end

		local pageIndicator
		local pageIndicatorLabel

		local function showPage(pageNum)
			for i, frame in ipairs(pageFrames) do
				frame.Visible = i == pageNum
			end
			currentPage = pageNum
			-- Update page indicator text
			if pageIndicatorLabel then
				pageIndicatorLabel.Text = pageNum .. ' / ' .. #pageFrames
			end
		end

		-- Page navigation arrows
		local leftArrow = _p.RoundedFrame:new {
			Button = true,
			BackgroundColor3 = Color3.new(.4, .4, .4),
			Size = UDim2.new(0.08, 0, 0.08, 0),
			Position = UDim2.new(0.02, 0, 0.92, 0),
			ZIndex = 3, Parent = gui,
			MouseButton1Click = function()
				if currentPage > 1 then
					showPage(currentPage - 1)
				end
			end,
		}
		write '<' {
			Frame = create 'Frame' {
				BackgroundTransparency = 1.0,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = leftArrow.gui,
				ZIndex = 4,
			}, Scaled = true, Color = Color3.new(1, 1, 1),
		}

		local rightArrow = _p.RoundedFrame:new {
			Button = true,
			BackgroundColor3 = Color3.new(.4, .4, .4),
			Size = UDim2.new(0.08, 0, 0.08, 0),
			Position = UDim2.new(0.9, 0, 0.92, 0),
			ZIndex = 3, Parent = gui,
			MouseButton1Click = function()
				if currentPage < #pageFrames then
					showPage(currentPage + 1)
				end
			end,
		}
		write '>' {
			Frame = create 'Frame' {
				BackgroundTransparency = 1.0,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = rightArrow.gui,
				ZIndex = 4,
			}, Scaled = true, Color = Color3.new(1, 1, 1),
		}

		-- Page indicator
		pageIndicator = create 'Frame' {
			Name = 'PageIndicator',
			BackgroundTransparency = 1.0,
			Size = UDim2.new(0.2, 0, 0.05, 0),
			Position = UDim2.new(0.4, 0, 0.93, 0),
			ZIndex = 3, Parent = gui,
		}
		pageIndicatorLabel = write('1 / ' .. #pageFrames) {
			Frame = pageIndicator,
			Scaled = true,
		}
	end

	function options:open()
		if self.isOpen or not _p.MasterControl.WalkEnabled then return end
		self.isOpen = true

		_p.MasterControl.WalkEnabled = false
		_p.MasterControl:Stop()
		spawn(function() _p.Menu:disable() end)

		if not gui then
			bg = create 'Frame' {
				BorderSizePixel = 0,
				BackgroundColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1.0, 0, 1.0, 36),
				Position = UDim2.new(0.0, 0, 0.0, -36),
			}
			gui = create 'ImageLabel' {
				BackgroundTransparency = 1.0,
				Image = 'rbxassetid://18434587582', 
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Size = UDim2.new(0.9, 0, 0.9, 0),
				ZIndex = 2,
			}
			close = _p.RoundedFrame:new {
				Button = true,
				BackgroundColor3 = color(1, 1, 0),
				Size = UDim2.new(.31, 0, .08, 0),
				Position = UDim2.new(.65, 0, -.03, 0),
				ZIndex = 3, Parent = gui,
			}
			write 'Close' {
				Frame = create 'Frame' {
					BackgroundTransparency = 1.0,
					Size = UDim2.new(1.0, 0, 0.7, 0),
					Position = UDim2.new(0.0, 0, 0.15, 0),
					Parent = close.gui,
					ZIndex = 4,
				}, Scaled = true,
			}

			close.gui.MouseButton1Click:connect(function()
				for _, toggle in ipairs(toggles) do
					if not toggle.Enabled then return end
				end
				self:close()
			end)

			self:makePages()
		end

		bg.Parent = Utilities.gui
		gui.Parent = Utilities.gui
		close.CornerRadius = Utilities.gui.AbsoluteSize.Y*.015
		if unstuckButton then
			unstuckButton.CornerRadius = Utilities.gui.AbsoluteSize.Y*.02
		end

		unstuckTimer()

		Utilities.Tween(.8, 'easeOutCubic', function(a)
			if not self.isOpen then return false end
			bg.BackgroundTransparency = 1-.3*a
			gui.Position = UDim2.new(1-.5*a, -gui.AbsoluteSize.X/2*a, 0.05, 0)
		end)
	end

	function options:close()
		if not self.isOpen then return end
		self.isOpen = false

		spawn(function() _p.Menu:enable() end)

		Utilities.Tween(.8, 'easeOutCubic', function(a)
			if self.isOpen then return false end
			bg.BackgroundTransparency = .7+.3*a
			gui.Position = UDim2.new(.5+.5*a, -gui.AbsoluteSize.X/2*(1-a), 0.05, 0)
		end)
		bg.Parent = nil
		gui.Parent = nil

		_p.MasterControl.WalkEnabled = true
	end

	function options:fastClose(enableWalk)
		if not self.isOpen then return end
		self.isOpen = false

		spawn(function() _p.Menu:enable() end)

		bg.BackgroundTransparency = 1.0
		gui.Position = UDim2.new(1.0, 0, 0.05, 0)
		bg.Parent = nil
		gui.Parent = nil

		if enableWalk then
			_p.MasterControl.WalkEnabled = true
		end
	end


	return options end
