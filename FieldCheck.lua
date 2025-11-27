-- Created by Infrared
return function(_p)
	local Utilities = _p.Utilities
	local create = Utilities.Create
	local write = Utilities.Write

	local activated = false
	local fieldThread = nil
	local gui, bg, close
	local isProcessing = false  -- Add debounce flag to prevent double-clicks

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
			-- Prevent creating duplicate GUI
			if gui then return end
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
				-- Prevent closing if already processing
				if isProcessing then return end
				isProcessing = true

				-- Add safety check for battleGui
				if battle.battleGui and battle.battleGui.mainChoices and battle.battleGui.choicePack then
					spawn(function()
						pcall(function()
							battle.battleGui:mainChoices(unpack(battle.battleGui.choicePack))
						end)
					end)
				end
				Utilities.Tween(.8, 'easeOutCubic', function(a)
					bg.BackgroundTransparency = .5+.5*a
					gui.Position = UDim2.new(.5+.5*a, 0, -0.02, 0)
				end)

				-- Wait for animation to complete before cleanup
				task.wait(0.8)
				_p.PlayerList:unlock()
				bg.Parent = nil
				gui.Parent = nil
				bg = nil
				gui = nil
				isProcessing = false
			end
			--Actual UI Stuff
			if not gui then
				bg = create("Frame")({
					Name = "BackgroundFrame",
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
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
					AnchorPoint = Vector2.new(0.5, 0), -- Center horizontally
					ImageColor3 = Color3.fromRGB(30, 100, 180), -- Modern blue theme
					ZIndex = 5,
				})

				close = _p.RoundedFrame:new({
					Name = "CloseButton",
					Button = true,
					BackgroundColor3 = Color3.fromRGB(220, 60, 60), -- Red close button
					Size = UDim2.new(.31, 0, .08, 0),
					Position = UDim2.new(.65, 0, -.03, 0),
					ZIndex = 6, Parent = gui,
				})

				-- Add X icon to close button
				create("TextLabel")({
					Name = "CloseIcon",
					BackgroundTransparency = 1.0,
					Size = UDim2.new(0.2, 0, 0.7, 0),
					Position = UDim2.new(0.05, 0, 0.15, 0),
					Text = "✕",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextScaled = true,
					Font = Enum.Font.GothamBold,
					ZIndex = 7,
					Parent = close.gui,
				})

				write('Close')({
					Frame = create('Frame')({
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.75, 0, 0.7, 0),
						Position = UDim2.new(0.25, 0, 0.15, 0),
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

				-- Field section divider
				create("Frame")({
					Name = "FieldDivider",
					BackgroundColor3 = Color3.fromRGB(100, 180, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0.25, 0, 0.003, 0),
					Position = UDim2.new(0.65, 0, 0.17, 0),
					ZIndex = 6,
					Parent = gui,
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
				local weatherColor = Color3.fromRGB(120, 120, 120) -- Default gray
				if weather ~= "" then
					if extremeWeathers[weather] then
						weatherStr = extremeWeathers[weather]
					else
						weatherStr = weatherMap[weather] .. ": " .. weatherDur .. " Turns"
					end
					-- Set colors based on weather type
					if weather == "sunnyday" or weather == "desolateland" then
						weatherColor = Color3.fromRGB(255, 200, 80)
					elseif weather == "raindance" or weather == "primordialsea" then
						weatherColor = Color3.fromRGB(80, 160, 255)
					elseif weather == "sandstorm" then
						weatherColor = Color3.fromRGB(220, 180, 100)
					elseif weather == "hail" then
						weatherColor = Color3.fromRGB(180, 220, 255)
					end
				end

				local terrainStr = "No Terrain"
				local terrain = fieldData.field.terrain
				local terrainDur = fieldData.field.terrainDuration
				local terrainColor = Color3.fromRGB(120, 120, 120) -- Default gray
				if terrain ~= "" then
					terrainStr = terrainMap[terrain] .. ": " .. terrainDur .. " Turns"
					-- Set colors based on terrain type
					if terrain == "electricterrain" then
						terrainColor = Color3.fromRGB(255, 220, 80)
					elseif terrain == "psychicterrain" then
						terrainColor = Color3.fromRGB(255, 120, 200)
					elseif terrain == "mistyterrain" then
						terrainColor = Color3.fromRGB(220, 180, 255)
					elseif terrain == "grassyterrain" then
						terrainColor = Color3.fromRGB(100, 220, 100)
					end
				end

				-- Weather background box
				create("Frame")({
					Name = "WeatherBG",
					BackgroundColor3 = weatherColor,
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
					Size = UDim2.new(0.22, 0, 0.05, 0),
					Position = UDim2.new(0.69, 0, 0.295, 0),
					ZIndex = 6,
					Parent = gui,
				})

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

				-- Terrain background box
				create("Frame")({
					Name = "TerrainBG",
					BackgroundColor3 = terrainColor,
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
					Size = UDim2.new(0.22, 0, 0.04, 0),
					Position = UDim2.new(0.69, 0, 0.375, 0),
					ZIndex = 6,
					Parent = gui,
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

				-- Tera Types section
				local teraYStart = 0.45 + (0.07 * #psuedoWeathers)
				if teraYStart < 0.6 then
					teraYStart = 0.6
				end

				-- Tera Types divider
				create("Frame")({
					Name = "TeraDivider",
					BackgroundColor3 = Color3.fromRGB(200, 100, 255), -- Purple for tera
					BorderSizePixel = 0,
					Size = UDim2.new(0.25, 0, 0.003, 0),
					Position = UDim2.new(0.65, 0, teraYStart - 0.03, 0),
					ZIndex = 6,
					Parent = gui,
				})

				write('Tera Types')({
					Frame = create('Frame')({
						Name = "TeraFrame",
						BackgroundTransparency = 1.0,
						Size = UDim2.new(0.2, 0, 0.05, 0),
						Position = UDim2.new(0.7, 0, teraYStart, 0),
						Parent = gui,
						ZIndex = 7,
					}), Scaled = true,
				})

				-- Display tera types for user's active Pokémon
				local userMons = fieldData.user.mons
				local teraIndex = 0
				for i, p in ipairs(userMons) do
					if Not(p) then continue end
					local teraStr = ""
					if p.isTerastallized and p.teraType then
						teraStr = p:getName() .. " (Tera: " .. p.teraType .. ")"
					elseif p.teraType then
						teraStr = p:getName() .. " [" .. p.teraType .. "]"
					else
						teraStr = p:getName() .. " [Unknown]"
					end

					-- Color based on terastallization status
					local teraColor = Color3.fromRGB(180, 140, 255) -- Light purple default
					if p.isTerastallized then
						teraColor = Color3.fromRGB(255, 180, 255) -- Bright pink for active tera
					end

					-- Background box for tera type
					create("Frame")({
						Name = "TeraBG"..i,
						BackgroundColor3 = teraColor,
						BackgroundTransparency = 0.6,
						BorderSizePixel = 0,
						Size = UDim2.new(0.22, 0, 0.04, 0),
						Position = UDim2.new(0.69, 0, teraYStart + 0.06 + (0.05 * teraIndex), 0),
						ZIndex = 6,
						Parent = gui,
					})

					write(teraStr)({
						Frame = create('Frame')({
							Name = "UserTera"..i,
							BackgroundTransparency = 1.0,
							Size = UDim2.new(0.2, 0, 0.03, 0),
							Position = UDim2.new(0.7, 0, teraYStart + 0.065 + (0.05 * teraIndex), 0),
							Parent = gui,
							ZIndex = 7,
						}), Scaled = true,
					})
					teraIndex += 1
				end

				-- Display tera types for foe's active Pokémon
				local foeMons = fieldData.foe.mons
				for i, p in ipairs(foeMons) do
					if Not(p) then continue end
					local teraStr = ""
					if p.isTerastallized and p.teraType then
						teraStr = p:getName() .. " (Tera: " .. p.teraType .. ")"
					elseif p.teraType then
						teraStr = p:getName() .. " [" .. p.teraType .. "]"
					else
						teraStr = p:getName() .. " [Unknown]"
					end

					-- Color based on terastallization status
					local teraColor = Color3.fromRGB(180, 140, 255) -- Light purple default
					if p.isTerastallized then
						teraColor = Color3.fromRGB(255, 180, 255) -- Bright pink for active tera
					end

					-- Background box for tera type
					create("Frame")({
						Name = "FoeTeraBG"..i,
						BackgroundColor3 = teraColor,
						BackgroundTransparency = 0.6,
						BorderSizePixel = 0,
						Size = UDim2.new(0.22, 0, 0.04, 0),
						Position = UDim2.new(0.69, 0, teraYStart + 0.06 + (0.05 * teraIndex), 0),
						ZIndex = 6,
						Parent = gui,
					})

					write(teraStr)({
						Frame = create('Frame')({
							Name = "FoeTera"..i,
							BackgroundTransparency = 1.0,
							Size = UDim2.new(0.2, 0, 0.03, 0),
							Position = UDim2.new(0.7, 0, teraYStart + 0.065 + (0.05 * teraIndex), 0),
							Parent = gui,
							ZIndex = 7,
						}), Scaled = true,
					})
					teraIndex += 1
				end

				-- Boosts section divider
				create("Frame")({
					Name = "BoostsDivider",
					BackgroundColor3 = Color3.fromRGB(100, 180, 255),
					BorderSizePixel = 0,
					Size = UDim2.new(0.35, 0, 0.003, 0),
					Position = UDim2.new(0.05, 0, 0.17, 0),
					ZIndex = 6,
					Parent = gui,
				})

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

				-- Boost column headers with improved visuals
				for i=1, 4 do
					local index = i-1
					-- Background for boost column
					create("Frame")({
						Name = "BoostColumnBG"..i,
						BackgroundColor3 = Color3.fromRGB(20, 80, 140),
						BackgroundTransparency = 0.7,
						BorderSizePixel = 0,
						Size = UDim2.new(0.06, 0, 0.08, 0),
						Position = UDim2.new(0.07 + (index * 0.07), 0, 0.27, 0),
						Parent = gui,
						ZIndex = 6,
					})

					create("ImageLabel")({
						Name = "Boost"..i,
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://121103875437906',
						SizeConstraint = Enum.SizeConstraint.RelativeXY,
						Size = UDim2.new(0.06, 0, 0.7, 0),
						Position = UDim2.new(0.07 + (index * 0.07), 0, 0.27, 0),
						ImageColor3 = Color3.fromRGB(100, 220, 255), -- Brighter cyan
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

				-- Your Side section divider
				create("Frame")({
					Name = "YourSideDivider",
					BackgroundColor3 = Color3.fromRGB(80, 220, 120), -- Green for player
					BorderSizePixel = 0,
					Size = UDim2.new(0.25, 0, 0.003, 0),
					Position = UDim2.new(0.35, 0, 0.17, 0),
					ZIndex = 6,
					Parent = gui,
				})

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

				-- Foe Side section divider
				create("Frame")({
					Name = "FoeSideDivider",
					BackgroundColor3 = Color3.fromRGB(255, 100, 100), -- Red for opponent
					BorderSizePixel = 0,
					Size = UDim2.new(0.25, 0, 0.003, 0),
					Position = UDim2.new(0.35, 0, 0.57, 0),
					ZIndex = 6,
					Parent = gui,
				})

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
					gui.Position = UDim2.new(1-.5*a, 0, -0.02, 0)
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
				BackgroundColor3 = Color3.fromRGB(45, 140, 220), -- Modern blue
				Style = 'HorizontalBar',
				Size = UDim2.new(2, 0, 0.35, 0),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Position = UDim2.new(0.15, 0, 0.65, 0),
				Parent = main,
				Button = true,
				MouseButton1Click = function()
					-- Prevent double-clicks while processing
					if isProcessing then return end

					-- Add safety check before trying to access battle functions
					if not battle or not battle.battleGui then
						return
					end

					isProcessing = true

					spawn(function()
						pcall(function()
							battle.battleGui:fastCancelMain()
						end)
						if battle.battleGui.exitButtonsMain then
							battle.battleGui:exitButtonsMain()
						end

						-- Wait for animations to complete before showing field check
						task.wait(0.7)

						-- Now safe to show field check UI
						fieldCheck()
						-- Wait for opening animation to complete (0.8s)
						task.wait(0.8)
						isProcessing = false
					end)
				end,
			}

			-- Add icon to button
			create("ImageLabel")({
				Name = "Icon",
				BackgroundTransparency = 1.0,
				Image = 'rbxassetid://6238710220', -- Info/stats icon
				Size = UDim2.new(0.15, 0, 0.6, 0),
				Position = UDim2.new(0.05, 0, 0.2, 0),
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 3,
				Parent = rf.gui,
			})

			write 'Field Status' {
				Frame = create 'Frame' {
					BackgroundTransparency = 1.0,
					Size = UDim2.new(0.75, 0, 0.7, 0),
					Position = UDim2.new(0.25, 0, 0.15, 0),
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