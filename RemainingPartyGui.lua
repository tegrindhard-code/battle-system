return function(_p)
	local Utilities = _p.Utilities
	local create = Utilities.Create

	local rPartyState = false
	local rPartyThread
	local status_normal = 'rbxassetid://7824188301'
	local status_faint  = 'rbxassetid://6222199540'
	return function(self, on)
		if rPartyState == on then return end
		local battle = _p.Battle.currentBattle
		if not battle then return end
		rPartyState = on
		local left, right = self.leftRemainingPartyGui, self.rightRemainingPartyGui
		if not left then
			left = create 'Frame' {
				BackgroundTransparency = 1.0,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Size = UDim2.new(-0.45, 0, -0.45/6, 0),
				Position = UDim2.new(0.0, 0, 1.0, 0),
				Visible = false,
				Parent = Utilities.backGui,

				_p.RoundedFrame:new {
					BackgroundColor3 = Color3.new(.4, .4, .4),
					Style = 'HorizontalBar',
					Size = UDim2.new(1.0, 0, 0.35, 0),
					Position = UDim2.new(0.0, 0, 0.65, 0),
				},
			}
			for i = 1, 6 do
				create 'ImageLabel' {
					BackgroundTransparency = 1.0,
					Image = 'rbxassetid://11106505014',
					ImageColor3 = Color3.new(1, 1, 1),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Size = UDim2.new(0.1, 0, 0.1, 0),
					Position = UDim2.new(0.45/6+(i-1)/6, 0, 0.45, 0),
					ZIndex = 2, Parent = left,
				}
				create 'ImageLabel' {
					Name = 'StatusBall'..(7-i),
					BackgroundTransparency = 1.0,
					Image = status_normal,
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Size = UDim2.new(0.8, 0, 0.8, 0),
					Position = UDim2.new(0.1/6+(i-1)/6, 0, 0.1, 0),
					Visible = false,
					ZIndex = 3, Parent = left,
				}
				create 'ImageLabel' {
					Name = 'PokemonIcon'..(7-i),
					BackgroundTransparency = 1.0,
					Image = '',
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Size = UDim2.new(0.6, 0, 0.6, 0),
					Position = UDim2.new(0.2/6+(i-1)/6, 0, 0.05, 0),
					Visible = false,
					ZIndex = 4, Parent = left,
				}
			end
			right = create 'Frame' {
				BackgroundTransparency = 1.0,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Size = UDim2.new(0.45, 0, 0.45/6, 0),
				Position = UDim2.new(1.0, 0, 0.25, 0),
				Visible = false,
				Parent = Utilities.backGui,

				_p.RoundedFrame:new {
					BackgroundColor3 = Color3.new(.4, .4, .4),
					Style = 'HorizontalBar',
					Size = UDim2.new(1.0, 0, 0.35, 0),
					Position = UDim2.new(0.0, 0, 0.65, 0),
				},
			}
			for i = 1, 6 do
				create 'ImageLabel' {
					BackgroundTransparency = 1.0,
					Image = 'rbxassetid://11106505014',
					ImageColor3 = Color3.new(.25, .25, .25),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Size = UDim2.new(0.1, 0, 0.1, 0),
					Position = UDim2.new(0.45/6+(i-1)/6, 0, 0.45, 0),
					ZIndex = 2, Parent = right,
				}
				create 'ImageLabel' {
					Name = 'StatusBall'..i,
					BackgroundTransparency = 1.0,
					Image = status_normal,
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Size = UDim2.new(0.8, 0, 0.8, 0),
					Position = UDim2.new(0.1/6+(i-1)/6, 0, 0.1, 0),
					Visible = false,
					ZIndex = 3, Parent = right,
				}
				create 'ImageLabel' {
					Name = 'PokemonIcon'..i,
					BackgroundTransparency = 1.0,
					Image = '',
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					Size = UDim2.new(0.6, 0, 0.6, 0),
					Position = UDim2.new(0.2/6+(i-1)/6, 0, 0.05, 0),
					Visible = false,
					ZIndex = 4, Parent = right,
				}
			end
			self.leftRemainingPartyGui, self.rightRemainingPartyGui = left, right
		end
		if on then
			local o = 0
			for i = 1, 6 do
				do -- left
					local statusBall = left['StatusBall'..(i+o)]
					local pokemonIcon = left['PokemonIcon'..(i+o)]
					local p = battle.mySide.pokemon[i]
					if p then
						if battle.npcPartner and p.teamn == 2 then
							o = o - 1
							statusBall.Visible = false
							pokemonIcon.Visible = false
						else
							statusBall.Visible = true
							pokemonIcon.Visible = true
							if tonumber(p.hp) > 0 then
								statusBall.Image = status_normal
							else
								statusBall.Image = status_faint
							end

							local iconGui = p:getIcon()
							if iconGui then
								if iconGui.Image then
									pokemonIcon.Image = iconGui.Image
									pokemonIcon.ImageRectOffset = iconGui.ImageRectOffset or Vector2.new(0, 0)
									pokemonIcon.ImageRectSize = iconGui.ImageRectSize or Vector2.new(0, 0)
								elseif iconGui:FindFirstChild("ImageLabel") then
									local childIcon = iconGui:FindFirstChild("ImageLabel")
									pokemonIcon.Image = childIcon.Image
									pokemonIcon.ImageRectOffset = childIcon.ImageRectOffset or Vector2.new(0, 0)
									pokemonIcon.ImageRectSize = childIcon.ImageRectSize or Vector2.new(0, 0)
								end
								iconGui:Destroy()
							else
							end
						end
					else
						statusBall.Visible = false
						pokemonIcon.Visible = false
					end
					if i == 6 and o < 0 then
						for j = 6+o+1, 6 do
							left['StatusBall'..j].Visible = false
							left['PokemonIcon'..j].Visible = false
						end
					end
				end
				do -- right
					local statusBall = right['StatusBall'..i]
					local pokemonIcon = right['PokemonIcon'..i]
					local p = battle.yourSide.pokemon[i]
					if p then
						statusBall.Visible = true
						if tonumber(p.hp) > 0 then
							statusBall.Image = status_normal
						else
							statusBall.Image = status_faint
						end

						if p.revealed or p.active then
							pokemonIcon.Visible = true
							local iconGui = p:getIcon()
							if iconGui then
								if iconGui.Image then
									pokemonIcon.Image = iconGui.Image
									pokemonIcon.ImageRectOffset = iconGui.ImageRectOffset or Vector2.new(0, 0)
									pokemonIcon.ImageRectSize = iconGui.ImageRectSize or Vector2.new(0, 0)
								elseif iconGui:FindFirstChild("ImageLabel") then
									local childIcon = iconGui:FindFirstChild("ImageLabel")
									pokemonIcon.Image = childIcon.Image
									pokemonIcon.ImageRectOffset = childIcon.ImageRectOffset or Vector2.new(0, 0)
									pokemonIcon.ImageRectSize = childIcon.ImageRectSize or Vector2.new(0, 0)
								end
								iconGui:Destroy()
							else
							end
						else
							pokemonIcon.Visible = false
						end
					else
						statusBall.Visible = false
						pokemonIcon.Visible = false
					end
				end
			end
			left.Visible = true
			right.Visible = battle.kind~='wild'
		end
		local xsl = left.Position.X.Offset
		local xel = on and math.abs(left.AbsoluteSize.X) or -math.abs(left.Parent.AbsoluteSize.X)*0.05
		local xsr = right.Position.X.Offset
		local xer = on and -math.abs(right.AbsoluteSize.X) or math.abs(right.Parent.AbsoluteSize.X)*0.025
		local thisThread = {}
		rPartyThread = thisThread
		Utilities.Tween(.5, 'easeOutCubic', function(a)
			if thisThread ~= rPartyThread then return false end
			left.Position = UDim2.new(0.025, xsl + (xel-xsl)*a, 0.975, 0)
			right.Position = UDim2.new(0.975, xsr + (xer-xsr)*a, 0.275, 0)
		end)
		if not on and thisThread == rPartyThread then
			left.Visible = false
			right.Visible = false
		end
	end
end