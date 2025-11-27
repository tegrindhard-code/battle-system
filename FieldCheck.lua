-- Created by Infrared
return function(_p)
	local Utilities = _p.Utilities
	local create = Utilities.Create
	local write = Utilities.Write

	local activated = false
	local fieldThread = nil
	local gui, bg, close

	local null, Not, split, indexOf, toId, sync, endsWith; do
		local util = require(script.Parent.Parent.Battle.BattleUtilities)
		null = util.null
		Not = util.Not
		split = util.split
		indexOf = util.indexOf
		toId = util.toId
		sync = util.sync
		endsWith = util.endsWith
	end

	return function(self, on)
		local battle = _p.Battle.currentBattle
		if activated == on then return end
		if battle.isSafari then return end
		activated = on
		local main = self.main
		if not Utilities.backGui:FindFirstChild("FieldCheck") then
			main = nil
		end

		-- The actual function
		local function fieldCheck()
			-- Add safety checks to prevent errors when battle isn't fully initialized
			if not battle or not battle.mySide or not battle.yourSide or 
				not battle.mySide.active or not battle.yourSide.active then
				-- Silently return if battle data isn't ready
				return
			end

			local fieldData = {
				["user"] = {
					mons = battle.mySide.active,
					sideConditions = battle.mySide.sideConditions
				},
				["foe"] = {
					mons = battle.yourSide.active,
					sideConditions = battle.yourSide.sideConditions
				},
				["field"] = {
					weather = battle.weather,
					weatherDuration = battle.weatherTimeLeft,
					terrain = battle.terrain,
					terrainDuration = battle.terrainTimeLeft,
					pseudoWeather = battle.pseudoWeather
				}
			}

			local weatherMap = {
				["sunnyday"] = "Sun",
				["raindance"] = "Rain",
				["sandstorm"] = "Sand",
				["hail"] = "Hail",	
			}

			local extremeWeathers = {
				["desolateland"] = "Intense Sun",
				["primordialsea"] = "Heavy Rain",
				["deltastream"] = "Strong Wings"
			}

			local terrainMap = {
				["electricterrain"] = "Electric Terrain",
				["psychicterrain"] = "Psychic Terrain",
				["mistyterrain"] = "Misty Terrain",
				["grassyterrain"] = "Grassy Terrain",
			}

			_p.PlayerList:lock()

			local closeFunc = function()
				-- Add safety check for battleGui
				if battle.battleGui and battle.battleGui.mainChoices and battle.battleGui.choicePack then
					spawn(function() battle.battleGui:mainChoices(unpack(battle.battleGui.choicePack)) end)
				end
				Utilities.Tween(.8, 'easeOutCubic', function(a)
					bg.BackgroundTransparency = .5+.5*a
					gui.Position = UDim2.new(.5+.5*a, (-gui.AbsoluteSize.X/2)*(1-a), -0.02, 0)
				end)
				_p.PlayerList:unlock()
				bg.Parent = nil
				gui.Parent = nil
				bg = nil
				gui = nil
			end
			--Actual UI Stuff
			if not gui then
				bg = create("Frame")({
					Name = "BackgroundFrame",
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.new(0, 0, 0),
					Size = UDim2.new(1.0, 0, 1.0, 60),
					Position = UDim2.new(0.0, 0, 0.0, -60),
				})

				gui = create("ImageLabel")({
					Name = "BGImage",
					BackgroundTransparency = 1.0,
					Image = 'rbxassetid://6240990069',
					SizeConstraint = Enum.SizeConstraint.RelativeXY,
					Size = UDim2.new(0.9, 0, 1.0, 0),
					Position = UDim2.new(0.5, 0, -0.02, 0),
					ImageColor3 = Color3.fromRGB(90, 0, 193),
					ZIndex = 5,
				})

				close = _p.RoundedFrame:new({
					Name = "CloseButton",
					Button = true,
					BackgroundColor3 = Color3.new(0.1, 0, 0.5),
					Size = UDim2.new(.31, 0, .08, 0),
					Position = UDim2.new(.65, 0, -.03, 0),
					ZIndex = 6, Parent = gui,
				})

				write('Close')({
					Frame = create('Frame')({
						BackgroundTransparency = 1.0,
						Size = UDim2.new(1.0, 0, 0.7, 0),
						Position = UDim2.new(0.0, 0, 0.15, 0),
						Parent = close.gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				--Writing the stuffs
				write('Field Status')({
					Frame = create('Frame')({
						Name = "TitleFrame",
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.6, 0, 0.09, 0),
						Position = UDim2.new(0.2, 0, 0.05, 0),
						Parent = gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				write('Field')({
					Frame = create('Frame')({
						Name = "FieldFrame",
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.2, 0, 0.06, 0),
						Position = UDim2.new(0.7, 0, 0.2, 0),
						Parent = gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				local weatherStr = "No Weather"
				local weather = fieldData.field.weather 
				local weatherDur = fieldData.field.weatherDuration
				if weather ~= "" then
					if extremeWeathers[weather] then
						weatherStr = extremeWeathers[weather]
					else
						weatherStr = weatherMap[weather] .. ": " .. weatherDur .. " Turns"
					end	
				end

				local terrainStr = "No Terrain"
				local terrain = fieldData.field.terrain
				local terrainDur = fieldData.field.terrainDuration
				if terrain ~= "" then
					terrainStr = terrainMap[terrain] .. ": " .. terrainDur .. " Turns"
				end

				write(weatherStr)({
					Frame = create('Frame')({
						Name = "Weather",
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.2, 0, 0.04, 0),
						Position = UDim2.new(0.7, 0, 0.3, 0),
						Parent = gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				write(terrainStr)({
					Frame = create('Frame')({
						Name = "Terrain",
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.2, 0, 0.03, 0),
						Position = UDim2.new(0.7, 0, 0.38, 0),
						Parent = gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				local psuedoWeathers = fieldData.field.pseudoWeather
				for i, pW in ipairs(psuedoWeathers) do 
					local index = i-1
					local name = pW[1]
					local duration = pW[2]
					local psuedoStr = name .. ": " .. duration .. " Turns"
					write(psuedoStr)({
						Frame = create('Frame')({
							Name = "Psuedo"..i,
							BackgroundTransparency = 1.0,
							Size = UDim2.new(0.2, 0, 0.03, 0),
							Position = UDim2.new(0.7, 0, 0.45 + (0.07 * index), 0),
							Parent = gui,
							ZIndex = 7,
						}), Scaled = true,
					})
				end

				write('Boosts')({
					Frame = create('Frame')({
						Name = "BoostFrame",
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.2, 0, 0.06, 0),
						Position = UDim2.new(0.1, 0, 0.2, 0),
						Parent = gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				for i=1, 4 do
					local index = i-1
					create("ImageLabel")({
						Name = "Boost"..i,
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://121103875437906',
						SizeConstraint = Enum.SizeConstraint.RelativeXY,
						Size = UDim2.new(0.06, 0, 0.7, 0),
						Position = UDim2.new(0.07 + (index * 0.07), 0, 0.27, 0),
						ImageColor3 = Color3.fromRGB(0, 195, 195),
						Parent = gui,
						ZIndex = 7,
					})
				end

				local userMons = fieldData.user.mons
				local foeMons = fieldData.foe.mons
				local bt = {"Icon", "Atk", "Def", "SpA"}
				local bt2 = {"SpD", "Spe", "Acc", "Evas"}
				local boostOrder = {"atk", "def", "spa", "spd", "spe", "accuracy", "evasion"}

				for i, b in ipairs(bt) do
					local index = i-1
					write(b)({
						Frame = create('Frame')({
							Name = "BoostIndex"..i,
							BackgroundTransparency = 1.0,
							Size = UDim2.new(0.06, 0, 0.03, 0),
							Position = UDim2.new(0.01, 0, 0.3 + (index * 0.085), 0),
							Parent = gui,
							ZIndex = 7,
						}), Scaled = true,
					})
				end

				for i, p in ipairs(userMons) do
					if Not(p) then continue end
					local index = i-1
					local icon = p:getIcon(true)
					icon.Parent = gui
					icon.ZIndex = 8
					icon.SizeConstraint = Enum.SizeConstraint.RelativeXY
					icon.Size = UDim2.new(0.06, 0, 0.08, 0)
					icon.Position = UDim2.new(0.07 + (index*0.07), 0, 0.27, 0)
					icon.Name = 'Pokemon'..i
					local boostCount = 0
					--print("YOUR BOOSTS:")
					--print(p.boosts)
					for _, v in ipairs(boostOrder) do
						local yPos = {
							[0] = 0.385, 0.473, 0.56, 0.65, 0.74, 0.825, 0.91
						}
						write(tostring(p.boosts[v]))({
							Frame = create('Frame')({
								Name = "BoostVal".. boostCount,
								BackgroundTransparency = 1.0,
								Size = UDim2.new(0.06, 0, 0.03, 0),
								Position = UDim2.new(0.07 + (index * 0.07), 0, yPos[boostCount], 0),
								Parent = gui,
								ZIndex = 8,
							}), Scaled = true,
						})
						boostCount += 1
					end
				end

				for i, p in ipairs(foeMons) do
					if Not(p) then continue end
					local index = i-1
					local icon = p:getIcon(true)
					icon.Parent = gui
					icon.ZIndex = 8
					icon.SizeConstraint = Enum.SizeConstraint.RelativeXY
					icon.Size = UDim2.new(0.06, 0, 0.08, 0)
					icon.Position = UDim2.new(0.21 + (index*0.07), 0, 0.27, 0)
					icon.Name = 'Pokemon'..(i+2)
					local boostCount = 0
					for _, v in pairs(boostOrder) do
						local yPos = {
							[0] = 0.385, 0.473, 0.56, 0.65, 0.74, 0.825, 0.91
						}
						write(tostring(p.boosts[v]))({
							Frame = create('Frame')({
								Name = "BoostVal".. (boostCount+7),
								BackgroundTransparency = 1.0,
								Size = UDim2.new(0.06, 0, 0.03, 0),
								Position = UDim2.new(0.21 + (index * 0.07), 0, yPos[boostCount], 0),
								Parent = gui,
								ZIndex = 8,
							}), Scaled = true,
						})
						boostCount += 1
					end
				end

				--Pos for boost values is UDim2.new(0.07 + (index * 0.07), 0, 0.385 + (index * 0.085), 0),

				for i, b in ipairs(bt2) do
					local index = i-1
					write(b)({
						Frame = create('Frame')({
							Name = "BoostIndex"..(i+4),
							BackgroundTransparency = 1.0,
							Size = UDim2.new(0.06, 0, 0.03, 0),
							Position = UDim2.new(0.01, 0, 0.65 + (index * 0.085), 0),
							Parent = gui,
							ZIndex = 7,
						}), Scaled = true,
					})
				end

				--Pos for boost values is UDim2.new(0.07 + (index * monCount), 0, 0.65 + (index * 0.085), 0),

				write('Your Side')({
					Frame = create('Frame')({
						Name = "PlayerFrame",
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.2, 0, 0.06, 0),
						Position = UDim2.new(0.4, 0, 0.2, 0),
						Parent = gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				local userSC = fieldData.user.sideConditions
				local counter = 0
				for i, sc in pairs(userSC) do 
					counter += 1
					local index = counter-1
					local name = sc[1]
					local duration = sc[3]
					local psuedoStr = name .. ": " .. duration .. " Turns"

					if duration < 1 then
						continue
					end

					write(psuedoStr)({
						Frame = create('Frame')({
							Name = "UserSC"..i,
							BackgroundTransparency = 1.0,
							Size = UDim2.new(0.2, 0, 0.03, 0),
							Position = UDim2.new(0.4, 0, 0.3 + (0.07 * index), 0),
							Parent = gui,
							ZIndex = 7,
						}), Scaled = true,
					})
				end

				write('Foe Side')({
					Frame = create('Frame')({
						Name = "FoeFrame",
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.2, 0, 0.06, 0),
						Position = UDim2.new(0.4, 0, 0.6, 0),
						Parent = gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				local foeSC = fieldData.foe.sideConditions
				local foeCount = 0
				for i, sc in pairs(foeSC) do 
					local duration = sc[3]
					if duration < 1 then
						continue
					end
					foeCount += 1
					local index = foeCount-1
					local name = sc[1]
					local psuedoStr = name .. ": " .. duration .. " Turns"

					write(psuedoStr)({
						Frame = create('Frame')({
							Name = "FoeSC"..i,
							BackgroundTransparency = 1.0,
							Size = UDim2.new(0.2, 0, 0.03, 0),
							Position = UDim2.new(0.4, 0, 0.7 + (0.07 * index), 0),
							Parent = gui,
							ZIndex = 7,
						}), Scaled = true,
					})
				end

				close.gui.MouseButton1Click:connect(function()
					closeFunc()
				end)

				--print(fieldData)
				bg.Parent = Utilities.frontGui
				gui.Parent = Utilities.frontGui
				close.CornerRadius = Utilities.frontGui.AbsoluteSize.Y*.015

				Utilities.Tween(.8, 'easeOutCubic', function(a)
					bg.BackgroundTransparency = 1-.5*a
					gui.Position = UDim2.new(1-.5*a, -gui.AbsoluteSize.X/2*a, -0.02, 0)
				end)
			end
		end

		local main = self.main
		if not main or not main.Parent then
			main = create 'Frame' {
				Name = "FieldCheck",
				BackgroundTransparency = 1.0,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Size = UDim2.new(-0.45, 0, 0.15, 0),
				Position = UDim2.new(0.975, 0, -0.025, 0),
				Visible = false,
				Parent = Utilities.backGui,
			}
			if battle.gameType == 'doubles' then
				main.Position = UDim2.new(0.02, 0, 0.4, 0)
				main.Size = UDim2.new(0.45, 0, 0.15, 0)
			end
			if battle.isRaid then
				main.Position = UDim2.new(0.975, 0, 0.01, 0)
			end
			local rf = _p.RoundedFrame:new {
				Name = "Button",
				BackgroundColor3 = Color3.new(0.1, 0, 0.5),
				Style = 'HorizontalBar',
				Size = UDim2.new(2, 0, 0.35, 0),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Position = UDim2.new(0.15, 0, 0.65, 0),
				Parent = main,
				Button = true,
				MouseButton1Click = function()
					-- Add safety check before trying to access battle functions
					if not battle or not battle.battleGui then
						return
					end

					spawn(function()
						pcall(function()
							battle.battleGui:fastCancelMain()
						end)
						if battle.battleGui.exitButtonsMain then
							battle.battleGui:exitButtonsMain()
						end
					end)
					fieldCheck()
				end,
			}
			write 'Field Status' {
				Frame = create 'Frame' {
					BackgroundTransparency = 1.0,
					Size = UDim2.new(0.0, 0, 0.7, 0),
					Position = UDim2.new(0.5, 0, 0.15, 0),
					ZIndex = 2, Parent = rf.gui,
				}, Scaled = true,
			}
		end

		-- UI Tween & Visibility
		self.main = main
		if on then
			main.Visible = true
		end
		local xel = math.abs(main.Parent.AbsoluteSize.X) * 0.3
		local thisThread = {}
		fieldThread = thisThread
		local xPos = main.Position.X.Scale
		local yPos = main.Position.Y.Scale
		Utilities.Tween(.5, 'easeOutCubic', function(a)
			if thisThread ~= fieldThread then return false end
			if battle.gameType == "doubles" then
				main.Position = UDim2.new(on and (xPos - 0.2) + 0.2 * a or xPos, -xel * (on and (1-a) or a), yPos, 0)
			else
				main.Position = UDim2.new(on and (xPos + 0.2) - 0.2 * a or xPos, xel * (on and (1-a) or a), yPos, 0)
			end
			--print("X Offset: ", main.Position.X.Offset)
		end)
		if not on and thisThread == fieldThread then
			main.Visible = false	
		end
	end
end