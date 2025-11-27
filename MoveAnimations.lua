

return function(_p)
	local Utilities = _p.Utilities
	local Tween = Utilities.Tween
	local create = Utilities.Create
	local storage = game:GetService('ReplicatedStorage')
	local RunService = game:GetService("RunService")
	local stepped = game:GetService('RunService').RenderStepped
	local moveUtil = require(script.MoveUtil)
	local Misc = storage.Models.Misc
	local Particles = Misc.Particles

	-- NOTE:
	--  Sprite.cf is at the BOTTOM CENTER of the part on which the sprite is rendered, already INCLUDES inAir, and is
	--	oriented such that its lookVector (no matter which side it is on) is the direction pointing from the opposing
	--	side to the viewer's side

	-- queue:
	--	make explosion/selfdestruct use 644263953 animation (8 rows, 8 columns, 128x128 frames, play once)
	-- 
	--	psychic
	--	earthquake
	--	brave bird
	--  stealth rock
	--	dragon rush
	--	leafage
	--	sticky web

	-- todo later:
	--  add particles to dragon claw
	--  make crunch triple-bite
	local randomPoint = Random.new()
	local function targetPoint(pokemon, dist)
		local sprite = pokemon.sprite or pokemon
		return sprite.cf * Vector3.new(0, sprite.part.Size.Y/2, (dist or 1) * (sprite.siden==1 and 1 or -1))
	end

	local function absorb(pokemon, target, amount, color)
		local from = targetPoint(pokemon)
		local to = targetPoint(target)
		local dif = from-to
		local cf = target.sprite.part.CFrame
		cf = cf-cf.p
		for i = 1, (amount or 6) do
			local a = math.random()*6.3
			local offset = (cf*Vector3.new(math.cos(a),math.sin(a),0))*.75
			local so = math.random()*6.3
			_p.Particles:new {
				Image = 478035064,
				Color = (color or Color3.fromHSV((90+40*math.random())/360, 1, .75)),
				Lifetime = .9,
				Size = .7,
				OnUpdate = function(a, gui)
					gui.CFrame = CFrame.new(to+dif*a+(1-a*.6)*(offset+Vector3.new(0,math.sin(so+a*3),0)))
				end
			}
			wait(.06)
		end
		wait(.7)
	end

	local function bite(target, particle, pSize, isCrunch)
		local b = storage.Models.Misc.Bite:Clone()
		if isCrunch then
			Utilities.ScaleModel(b.Main, 1.3)
		end
		local top, btm = b.Top, b.Bottom
		local inv = b.Main.CFrame:inverse()
		local tc, bc = inv * top.CFrame, inv * btm.CFrame
		b.Main:Destroy()
		b.Parent = workspace
		local mcf = CFrame.new(targetPoint(target, 2.5), targetPoint(target, 0))
		if particle then
			delay(.25, function()
				local p = _p.Particles
				local size = .5*(pSize or 1)
				for _ = 1, 5 do
					wait(.04)
					for _ = 1, 2 do
						local r = math.random()
						local t = math.random()*math.pi*2
						local d = Vector3.new(r*math.cos(t), r*.5*math.sin(t), 0)
						local v = ((mcf-mcf.p)*d).unit
						p:new {
							Position = mcf * (d + Vector3.new(0, 0, -1)),
							Rotation = -math.deg(t)+90,
							Velocity = v*6,
							Acceleration = -v*7,
							Lifetime = .7,
							Image = particle,
							OnUpdate = function(a, gui)
								local s = size*math.sin(a*math.pi)
								gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
							end,
						}
					end
				end
			end)
		end
		--	if isCrunch then
		--		Tween(2, nil, function(a)
		--			local s = (1+math.sin(.5+a*5.28))/2
		--			local m = CFrame.new(0, 0, -.6*(1-s))
		--			top.CFrame = mcf * m * CFrame.Angles( .7*s, 0, 0) * tc
		--			btm.CFrame = mcf * m * CFrame.Angles(-.7*s, 0, 0) * bc
		--		end)
		--	else
		Tween(.6, 'easeInOutQuad', function(a)
			local s = (1+math.sin(.5+a*5.28))/2
			--		local t = a<.1 and (1-10*a) or (a>.9 and ((a-.9)*10) or 0)
			--		top.Transparency = t
			--		btm.Transparency = t
			local m = CFrame.new(0, 0, -.6*(1-s))
			top.CFrame = mcf * m * CFrame.Angles( .7*s, 0, 0) * tc
			btm.CFrame = mcf * m * CFrame.Angles(-.7*s, 0, 0) * bc
		end)
		--	end
		b:Destroy()
	end

	local function spikes(pokemon, modelName, color)
		-- get platforms
		local platforms = {}
		local names
		local battle = pokemon.side.battle
		if pokemon.side.n == 1 then
			names = {'pos21', 'pos22', 'pos23'}
			if battle.gameType ~= 'doubles' then -- todo: triples?
				names[4] = '_Foe'
			end
		else
			names = {'pos11', 'pos12', 'pos13'}
			if battle.gameType ~= 'doubles' then -- todo: triples?
				names[4] = '_User'
			end
		end
		for _, name in pairs(names) do
			local p = battle.scene:FindFirstChild(name)
			if p then
				platforms[#platforms+1] = p
			end
		end
		--
		local spike = create 'Part' {
			Anchored = true,
			CanCollide = false,
			BrickColor = BrickColor.new(color or 'Smoky grey'),
			Reflectance = .1,
			Size = Vector3.new(1, 1, 1),

			create 'SpecialMesh' {
				MeshType = Enum.MeshType.FileMesh,
				MeshId = 'rbxassetid://5012973704',
				Scale = Vector3.new(.01, .01, .01)
			}
		}
		local spikeContainer = create 'Model' {
			Name = (modelName or 'Spikes')..(3-pokemon.side.n),
			Parent = battle.scene
		}
		delay(10, function() spike:Destroy() end)
		local throwFrom = targetPoint(pokemon, 1.5)
		for _, platform in pairs(platforms) do
			spawn(function()
				local available = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
				local function r()
					local n = math.random(#available)
					local v = table.remove(available, n) -- middle
					table.remove(available, #available < n and 1 or n) -- right
					table.remove(available, n==1 and #available or n-1) -- left
					return v
				end
				local offset = math.random()*math.pi*2
				for _, v in pairs({r(), r(), r()}) do
					local angle = offset+(v+math.random())*math.pi/6
					local r = 2+math.random()
					local cf = platform.CFrame * CFrame.Angles(0, math.random()*6.28, 0) + Vector3.new(math.cos(angle)*r, -platform.Size.Y/2+.25, math.sin(angle)*r)
					local throw = throwFrom - cf.p
					local rx, ry, rz = (math.random()-.5)*3, (math.random()-.5)*3, (math.random()-.5)*3
					local sp = spike:Clone()
					sp.Parent = spikeContainer
					spawn(function()
						Tween(.5, 'easeOutQuad', function(a)
							local o = 1-a
							sp.CFrame = cf * CFrame.Angles(o*rx, o*ry, o*rz) + throw*o + Vector3.new(0, 2*math.sin(a*math.pi), 0)
						end)
					end)
					wait(.2)
				end
			end)
		end
	end

	local function shield(pokemon, color)
		local sprite = pokemon.sprite
		local part = sprite.part
		local s = create 'Part' {
			Anchored = true,
			CanCollide = false,
			Transparency = .3,
			Reflectance = .4,
			BrickColor = BrickColor.new(color or 'Alder'),
			Parent = part.Parent,

			create 'CylinderMesh' {Scale = Vector3.new(1, 0.01, 1)}
		}
		local cf = sprite.cf * CFrame.new(0, 1.5-(sprite.spriteData.inAir or 0), 2.5 * (sprite.siden==1 and 1 or -1)) * CFrame.Angles(math.pi/2, .5, 0)
		Tween(.6, 'easeOutCubic', function(a)
			s.Size = Vector3.new(3*a, .2, 3*a)
			s.CFrame = cf
		end)
		delay(1, function()
			Tween(.5, 'easeOutCubic', function(a)
				s.Transparency = .3 + .7*a
				s.Reflectance = .4 * (1-a)
			end)
			s:Destroy()
		end)
	end

	local function cut(target, color, qty, pcolor1, pcolor2)
		local parts = {}
		local size
		local scale = .1
		local mscale = scale * 2
		if qty == 3 then
			for i = 1, 3 do
				local p = storage.Models.Misc.SlashEffect:Clone()
				size = p.Size * 4
				parts[p] = target.sprite.part.CFrame * CFrame.new(0, 0, -1) * CFrame.new(Vector3.new(.6, .6, 0)*(i-2))
				p.BrickColor = BrickColor.new(color or 'White')
				p.Parent = workspace
			end
		elseif qty == 2 then
			local p = storage.Models.Misc.SlashEffect:Clone()
			size = p.Size * 4
			parts[p] = target.sprite.part.CFrame * CFrame.new(0, 0, -1)
			p.BrickColor = BrickColor.new(color or 'White')
			p.Parent = workspace
			local p2 = p:Clone()
			parts[p2] = target.sprite.part.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(0, 0, -math.pi/2)
			p2.Parent = workspace
		else
			local p = storage.Models.Misc.SlashEffect:Clone()
			size = p.Size * 4
			parts[p] = target.sprite.part.CFrame * CFrame.new(0, 0, -1)
			p.BrickColor = BrickColor.new(color or 'White')
			p.Parent = workspace
		end
		--	local lastParticle = {}
		Utilities.Tween(.4, nil, function(a)
			for part, cf in pairs(parts) do
				part.Size = size*(0.2+1.2*math.sin(a*math.pi))*scale
				part.CFrame = cf * CFrame.new((-3+6*a)*mscale, (3-6*a)*mscale, 0) * CFrame.Angles(0, math.pi/2, 0) * CFrame.Angles(math.pi/4, 0, 0)
			end
		end)
		for part in pairs(parts) do
			part:Destroy()
		end
	end

	local function tackle(pokemon, target)
		local sprite = pokemon.sprite
		local s = sprite.part.Position
		local e = target.sprite.part.Position
		local dir = ((e-s)*Vector3.new(1,0,1)).unit
		Tween(.1, nil, function(a)
			sprite.offset = dir*2*a
		end)
		spawn(function()
			Tween(.17, 'easeOutCubic', function(a)
				sprite.offset = dir*2*(1-a)
			end)
		end)
	end




	local function cParticle(image, size, color)
		local p = create 'Part' {
			Transparency = 1.0,
			Anchored = true,
			CanCollide = false,
			Size = Vector3.new(.2, .2, .2),
			Parent = workspace,
		}
		local bbg = create 'BillboardGui' {
			Adornee = p,
			Size = UDim2.new(size or 1, 0, size or 1, 0),
			Parent = p
		}
		local img = create 'ImageLabel' {
			BackgroundTransparency = 1.0,
			Image = type(image) == 'number' and ('rbxassetid://'..image) or image,
			ImageColor3 = color or nil,
			Size = UDim2.new(1.0, 0, 1.0, 0),
			ZIndex = 2,
			Parent = bbg
		}
		return p, bbg, img
	end

	return {
		setTweenFunc = function(fn) -- to fastforward
			Tween = fn
		end,

		-- STATUS ANIMS

		status = {
			psn = function(pokemon)
				local p = _p.Particles
				local isTox = pokemon.status=='tox'
				local part = pokemon.sprite.part
				for i = 1, 10 do
					wait(.1)
					p:new {
						Position = (part.CFrame*CFrame.new(part.Size.X*(math.random()-.5)*.7, -part.Size.Y/2*math.random()*.8, -.2)).p,
						Velocity = Vector3.new(0, 3, 0),
						Acceleration = false,
						Color = isTox and Color3.new(111/255, 9/255, 95/255) or Color3.new(175/255, 106/255, 206/255),
						Lifetime = .5,
						Image = 243953162,
						OnUpdate = function(a, gui)
							local s = .8*math.sin(a*math.pi)
							gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
						end,
					}
				end
			end,
			brn = function(pokemon)
				local p = _p.Particles
				local part = pokemon.sprite.part
				for i = 1, 10 do
					wait(.1)
					p:new {
						Position = (part.CFrame*CFrame.new(part.Size.X*(math.random()-.5)*.7, -part.Size.Y/2*math.random()*.8, -.2)).p,
						Velocity = Vector3.new(0, 4, 0),
						Acceleration = false,
						Lifetime = .5,
						Image = 11601142,
						OnUpdate = function(a, gui)
							local s = 1.2*math.cos(a*math.pi/2)
							gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
						end,
					}
				end
			end,
			dynamax = function(pokemon,targets)

				local part = pokemon.sprite.part
				local cf = part.CFrame
				local of = workspace.CurrentCamera.FieldOfView
				local df = 70
				local psv3 = part.Size
				local sprite = pokemon.sprite
				local from = targetPoint(pokemon, -2)
				local to = targetPoint(pokemon, 0.5) - from
				local unt = to * Vector3.new(1, 0, 1).unit
				local air = sprite.spriteData.inAir or 0
				spawn(function()
					Tween(0.6, nil, function(b)
						sprite.offset = unt * -2 * b + Vector3.new(0, math.sin(b * math.pi) - air * b, 0)
					end)
				end)
				Tween(1, 'easeInCubic', function(a)
					part.Size = psv3 * (1 + 1*a)
					workspace.CurrentCamera.FieldOfView = of+(df-of)*a
				end)
			end,
			maxraid = function(pokemon)
				local part = pokemon.sprite.part
				local cf = part.CFrame
				local of = workspace.CurrentCamera.FieldOfView
				local df = 70
				local xz = Vector3.new(1, 0, 1)
				local psv3 = part.Size 
				local sprite = pokemon.sprite
				local from = targetPoint(pokemon, -2)
				local to = targetPoint(pokemon, 0.5) - from
				local unt = to * Vector3.new(1, 0, 1).unit
				local air = sprite.spriteData.inAir or 0
				spawn(function()
					Tween(0.6, nil, function(b)
						sprite.offset = unt * -2 * b + Vector3.new(0, math.sin(b * math.pi) - air * b, 0)
					end)
				end)
				Tween(1, 'easeInCubic', function(a)
					part.Size = psv3 * (1 + 3*a)
					workspace.CurrentCamera.FieldOfView = of+(df-of)*a
				end)
			end,

			redmax = function(pokemon)
				local part = pokemon.sprite.part
				local cf = part.CFrame
				local of = workspace.CurrentCamera.FieldOfView
				local df = 40
				local xz = Vector3.new(1, 0, 1)
				local psv3 = part.Size
				local sprite = pokemon.sprite
				local from = targetPoint(pokemon, 2)
				local to = targetPoint(pokemon, 0.5) - from
				local unt = to * Vector3.new(1, 0, 1).unit
				local air = sprite.spriteData.inAir or 0
				Tween(0.6, nil, function(b)
					sprite.offset = unt * -2 * b + Vector3.new(0, math.sin(b * math.pi) - air * b, 0)
				end)
				Tween(1, 'easeInCubic', function(a)
					part.Size = psv3 / (1 + 1*a)
					workspace.CurrentCamera.FieldOfView = of+(df-of)*a
				end)
			end,
			UBEntry = function(pokemon)
				local part = pokemon.sprite.part
				local particle = storage.Models.Misc.Particles.ShadowBall:Clone()
				particle.Parent = part
				particle:Emit(15)
				delay(1.5, function()
					particle.Enabled = true
				end)
			end,

			
			par = function(pokemon)
				local p = _p.Particles
				local part = pokemon.sprite.part
				pokemon.sprite.animation:Pause()
				for i = 1, 10 do
					wait(.1)
					local rs = 360*math.random()
					p:new {
						Position = (part.CFrame*CFrame.new(part.Size.X*(math.random()-.5)*.7, -part.Size.Y*(math.random()-.5)*.7, -.2)).p,
						Size = .7+.4*math.random(),
						Acceleration = false,
						Lifetime = .2,
						Image = {326993171, 326993181, 326993188},
						Rotation = rs,
					}
				end
				delay(.5, function()
					pokemon.sprite.animation:Play()
				end)
			end,
			slp = function(pokemon)
				local p = _p.Particles
				local part = pokemon.sprite.part
				local dir = 1
				if pokemon.side.n == 2 then
					dir = -1
				end
				for i = 1, 5 do
					p:new {
						Position = (part.CFrame*CFrame.new(part.Size.X*-.25*dir, part.Size.Y*.4, -.2)).p,
						Velocity = Vector3.new(0, 1, 0),
						Acceleration = false,
						Lifetime = 1,
						Color = Color3.new(.7, .7, .7),
						Image = 77146622,
						OnUpdate = function(a, gui)
							local s = .2+.4*math.sin(a*math.pi/2)
							gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
							gui.BillboardGui.ImageLabel.Rotation = -30*a*dir
							if a > .6 then
								gui.BillboardGui.ImageLabel.ImageTransparency = (a-.6)/.4
							end
						end,
					}
					wait(.3)
				end
			end,
			confused = function(pokemon)
				local part = pokemon.sprite.part
				local cf = part.CFrame * CFrame.new(0, part.Size.Y/2+.25, 0)
				local duck1 = create 'Part' {
					Anchored = true,
					CanCollide = false,
					--				FormFactor = Enum.FormFactor.Custom,
					Size = Vector3.new(.2, .2, .2),
					Parent = workspace,

					create 'SpecialMesh' {
						MeshType = Enum.MeshType.FileMesh,
						MeshId = 'rbxassetid://9419831',
						TextureId = 'rbxassetid://9419827',
						Scale = Vector3.new(.5, .5, .5),
					}
				}
				local duck2, duck3 = duck1:Clone(), duck1:Clone()
				duck2.Parent, duck3.Parent = workspace, workspace
				local r = part.Size.X*.45
				local o2, o3 = math.pi*2/3, math.pi*4/3
				Tween(1.5, nil, function(a)
					local angle = a*7
					local a1 = angle
					local a2 = angle + o2
					local a3 = angle + o3
					duck1.CFrame = cf * CFrame.new(math.cos(a1)*r, 0, math.sin(a1)*r) * CFrame.Angles(0, a1*2, 0)
					duck2.CFrame = cf * CFrame.new(math.cos(a2)*r, 0, math.sin(a2)*r) * CFrame.Angles(0, a2*2, 0)
					duck3.CFrame = cf * CFrame.new(math.cos(a3)*r, 0, math.sin(a3)*r) * CFrame.Angles(0, a3*2, 0)
				end)
				duck1:Destroy()
				duck2:Destroy()
				duck3:Destroy()
			end,

			heal = function(pokemon)
				local sprite = pokemon.sprite
				local cf = sprite.part.CFrame
				local size = sprite.part.Size
				for i = 1, 8 do
					_p.Particles:new {
						Rotation = math.random()*360,
						RotVelocity = (math.random(2)==1 and 1 or -1)*(80+math.random(80)),
						Image = 5119912224,
						Color = Color3.fromHSV((150+math.random()*20)/360, .5, 1),
						Position = cf*Vector3.new((math.random()-.5)*.8*size.X, (math.random()-.5)*.8*size.Y, -.5),
						Lifetime = .7,
						Acceleration = false,
						Velocity = Vector3.new(0, 1.5, 0),
						OnUpdate = function(a, gui)
							local s = math.sin(a*math.pi)
							gui.BillboardGui.Size = UDim2.new(.5*s, 0, .5*s, 0)
						end
					}
					wait(.06)
				end
			end
		},
		-- MOVE PREP ANIMS

		prepare = { -- args: pokemon, target, battle, move
			-- in-game, in essence: fall into purple puddle, then on second turn appear behind opponent (fall out of purple thing) and attack
			-- phantomforce  pokemon:getName() .. ' vanished instantly!'
			bounce = function(pokemon, _, _, _, ff)
				local sprite = pokemon.sprite
				if ff then sprite.offset = Vector3.new(0, 10, 0) return end
				for i = 1, 2 do
					Tween(.7, nil, function(a)
						sprite.offset = Vector3.new(0, 2*i*math.sin(a*math.pi), 0)
					end)
				end
				Tween(.5, 'easeOutCubic', function(a)
					sprite.offset = Vector3.new(0, 10*a, 0)
				end)
				return pokemon:getName() .. ' sprang up!'
			end,

			floatyfall = function(pokemon, _, _, _, ff)
				local sprite = pokemon.sprite
				if ff then sprite.offset = Vector3.new(0, 10, 0) return end
				for i = 1, 2 do
					Tween(.7, nil, function(a)
						sprite.offset = Vector3.new(0, 2*i*math.sin(a*math.pi), 0)
					end)
				end
				Tween(.5, 'easeOutCubic', function(a)
					sprite.offset = Vector3.new(0, 10*a, 0)
				end)
				return pokemon:getName() .. ' sprang up!'
			end,

			dig = function(pokemon, _, _, _, ff)
				local sprite = pokemon.sprite
				local y = sprite.part.Size.Y+(sprite.spriteData.inAir or 0)+.2
				if ff then sprite.offset = Vector3.new(0, -y, 0) return end
				local n = 5
				for i = 1, n do
					Tween(.25, 'easeOutCubic', function(a)
						sprite.offset = Vector3.new(0, (i-1+a)/n*-y, 0)
					end)
					wait(.1)
				end
				return pokemon:getName() .. ' burrowed its way under the ground!'
			end,
			dive = function(pokemon, _, _, _, ff)
				local sprite = pokemon.sprite
				local y = sprite.part.Size.Y+(sprite.spriteData.inAir or 0)
				if ff then sprite.offset = Vector3.new(0, -y, 0) return end
				Tween(.9, 'easeOutCubic', function(a)
					sprite.offset = Vector3.new(0, a*-y, 0)
				end)
				return pokemon:getName() .. ' hid underwater!'
			end,
			fly = function(pokemon, _, _, _, ff)
				local sprite = pokemon.sprite
				if ff then sprite.offset = Vector3.new(0, 10, 0) return end
				Tween(1, 'easeInCubic', function(a)
					sprite.offset = Vector3.new(0, 10*a, 0)
				end)
				return pokemon:getName() .. ' flew up high!'
			end,
			freezeshock = function(pokemon, _, _, _, ff)
				-- todo
				return pokemon:getName() .. ' became cloaked in a freezing light!'
			end,
			geomancy = function(pokemon, _, _, _, ff)
				-- todo?
				return pokemon:getName() .. ' is absorbing power!'
			end,
			iceburn = function(pokemon, _, _, _, ff)
				-- todo
				return pokemon:getName() .. ' became cloaked in freezing air!'
			end,
			razorwind = function(pokemon, _, _, _, ff)
				-- todo
				return pokemon:getName() .. ' whipped up a whirlwind!'
			end,
			shadowforce = function(pokemon, _, _, _, ff)
				local spriteLabel = pokemon.sprite.animation.spriteLabel
				if ff then spriteLabel.ImageTransparency = 1.0 return end
				Tween(.5, 'easeOutCubic', function(a)
					spriteLabel.ImageTransparency = a
				end)
				return pokemon:getName() .. ' vanished instantly!'
			end,
			solarbeam = function(pokemon, _, _, _, ff)
				-- todo
				return pokemon:getName() .. ' absorbed light!'
			end,
			skullbash = function(pokemon, _, _, _, ff)
				-- todo
				return pokemon:getName() .. ' tucked in its head!'
			end,
			skyattack = function(pokemon, _, _, _, ff)
				-- todo
				return pokemon:getName() .. ' became cloaked in a harsh light!'
			end,
			skydrop = function(pokemon, targets, _, _, tMeta)
			local target = targets[1] if not target then return end
			local sprite = pokemon.sprite
			local tp = target.sprite.offset
			Tween(.5, 'easeOutQuart', function(a)
				target.sprite.offset = tp*(1-a)
			end)
			if tMeta then
				Utilities.sound(tMeta.soundId[target] or 114870577672963, .75, tMeta.effectiveness[target] == 1 and .5 or .6, 5)
				--			spawn(function()
				--				local sl = target.sprite.animation.spriteLabel
				--				for i = 1, 3 do
				--					wait(.03)
				--					sl.Visible = false
				--					wait(.03)
				--					sl.Visible = true
				--				end
				--			end)
			end
			spawn(function()
				Tween(1, 'easeOutCubic', function(a)
					sprite.offset = Vector3.new(0, 10*(1-a), 0)
				end)
			end)
		end,
		slash = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, nil, 3)
			return 'sound'
		end,
		solarbeamm = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local from = targetPoint(pokemon, 2)
			local to = targetPoint(target)
			local dif = to-from

			local sun = create 'Part' {
				BrickColor = BrickColor.new('New Yeller'),
				Material = Enum.Material.Neon,
				Anchored = true,
				CanCollide = false,
				TopSurface = Enum.SurfaceType.Smooth,
				BottomSurface = Enum.SurfaceType.Smooth,
				Size = Vector3.new(4, 4, 4),
				Shape = Enum.PartType.Ball,
				CFrame = CFrame.new(pokemon.sprite.cf.p+Vector3.new(0, 7-(pokemon.sprite.spriteData.inAir or 0), 0)),
				Parent = workspace
			}
			Tween(1, nil, function(a)
				sun.Transparency = 1-a
			end)
			local blast = sun:Clone()
			blast.BrickColor = BrickColor.new('Bright green')
			blast.Size = Vector3.new(1, 1, 1)
			blast.CFrame = CFrame.new(from)
			blast.Parent = workspace
			local bmesh = create 'SpecialMesh' {
				MeshType = Enum.MeshType.Sphere,
				Parent = blast
			}
			local twoPi = math.pi*2
			local r = 4
			for i = 1, 20 do
				delay(.075*i, function()
					local beam = create 'Part' {
						Material = Enum.Material.Neon,
						BrickColor = BrickColor.new('Br. yellowish green'),
						Anchored = true,
						CanCollide = false,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
						Parent = workspace,
					}
					local transform = CFrame.Angles(twoPi*math.random(),twoPi*math.random(),twoPi*math.random()).lookVector * r
					local cf = CFrame.new(from)*transform
					Tween(.25, nil, function(a)
						beam.Size = Vector3.new(.2, .2, r*a)
						beam.CFrame = CFrame.new(cf + (from-cf)/2*a, cf)
					end)
					Tween(.25, nil, function(a)
						beam.Size = Vector3.new(.2, .2, r*(1-a))
						beam.CFrame = CFrame.new(cf + (from-cf)*(.5+.5*a), cf)
					end)
					beam:Destroy()
				end)
			end
			Tween(2, nil, function(a)
				bmesh.Scale = Vector3.new(2.3,2.3,2.3)*a
			end)
			wait(.2)
			local sbeam = blast:Clone()
			sbeam.Shape = Enum.PartType.Block--Cylinder
			sbeam.Parent = workspace
			local smesh = Instance.new('CylinderMesh', sbeam)
			local len = dif.magnitude
			Tween(.3, nil, function(a)
				sbeam.Size = Vector3.new(.8, len*a, .8)
				sbeam.CFrame = CFrame.new(from+dif*.5*a, to) * CFrame.Angles(math.pi/2, 0, 0)
				local s = (2.3-1.5*a)
				bmesh.Scale = Vector3.new(s,s,s)
				--			blast.CFrame = CFrame.new(from)
			end)
			spawn(function()
				--			local ss, sc = sbeam.Size, sbeam.CFrame
				local bs, bc = blast.Size, blast.CFrame
				Tween(.4, 'easeOutQuad', function(a)
					local o = 1-a
					smesh.Scale = Vector3.new(o,1,o)
					--sbeam.Size = ss*Vector3.new(1,o,o)
					--sbeam.CFrame = sc
					bmesh.Scale = Vector3.new(o,o,o)
					--				blast.Size = bs*o
					--				blast.CFrame = bc
				end)
				sbeam:Destroy()
				blast:Destroy()
				wait(.2)
				Tween(1, nil, function(a)
					sun.Transparency = a
				end)
				sun:Destroy()
			end)
			return true
		end,
		},

		-- REGULAR MOVE ANIMS
		absorb = function(pokemon, targets)
			local target = targets[1] if not target then return end
			absorb(pokemon, target)
			return true
		end,
		aerialace = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Medium blue')
			return 'sound'
		end,
		branchpoke = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Earth Green')
			return 'sound'
		end,	


		aurasphere = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local centroid = targetPoint(pokemon, 2.5)
			local cf = CFrame.new(centroid, centroid + workspace.CurrentCamera.CFrame.lookVector)
			local function makeParticle(hue)
				local p = create 'Part' {
					Transparency = 1.0,
					Anchored = true,
					CanCollide = false,
					Size = Vector3.new(.2, .2, .2),
					Parent = workspace,
				}
				local bbg = create 'BillboardGui' {
					Adornee = p,
					Size = UDim2.new(.7, 0, .7, 0),
					Parent = p,
					create 'ImageLabel' {
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://6294357140',
						ImageTransparency = .15,
						ImageColor3 = Color3.fromHSV(hue/360, 1, .85),
						Size = UDim2.new(1.0, 0, 1.0, 0),
						ZIndex = 2
					}
				}
				return p, bbg
			end
			local main, mbg = makeParticle(260)
			main.CFrame = cf
			local allParticles = {main}
			delay(.3, function()
				local rand = math.random
				for i = 2, 11 do
					local theta = rand()*6.28
					local offset = Vector3.new(math.cos(theta), math.sin(theta), .5)
					local p, b = makeParticle(rand(175, 230))
					allParticles[i] = p
					local r = math.random()*.35+.2
					spawn(function()
						local st = tick()
						local function o(r)
							local et = (tick()-st)*7
							p.CFrame = cf * CFrame.new(offset*r+.125*Vector3.new(math.cos(et), math.sin(et)*math.cos(et), 0))
						end
						Tween(.2, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							b.Size = UDim2.new(.5*a, 0, .5*a, 0)
							o(r+.6)
						end)
						Tween(.25, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							o(r+.6*(1-a))
						end)
						while p.Parent do
							o(r)
							stepped:wait()
						end
					end)
					wait(.1)
				end
			end)
			Tween(1.5, nil, function(a)
				mbg.Size = UDim2.new(2.5*a, 0, 2.5*a, 0)
			end)
			wait(.3)
			local targPos = targetPoint(target)
			local dp = targPos - centroid
			local v = 30
			local scf = cf
			Tween(dp.magnitude/v, nil, function(a)
				cf = scf + dp*a
				main.CFrame = cf
			end)
			for _, p in pairs(allParticles) do
				p:Destroy()
			end
			return true -- perform usual hit anim
		end,
		bite = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			Utilities.fastSpawn(function() bite(target) end)
			wait(.35)--(1.5*3.14-.5) = (t*2/d-1)*...?
			return 'sound'
		end,
		bounce = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local ep = (target.sprite.cf.p - sprite.cf.p)*Vector3.new(.9,0,.9)
			local sp = ep+Vector3.new(0, 10, 0)--sprite.offset
			Tween(.3, nil, function(a)
				sprite.offset = sp + (ep-sp)*a
			end)
			spawn(function()
				wait(.1)
				Tween(1, 'easeOutCubic', function(a)
					sprite.offset = ep*(1-a)
				end)
			end)
			return true -- perform usual hit anim
		end,
		stealthrock = function(poke)
			local parts = {}
			local poses
			local battle = poke.side.battle
			if poke.side.n == 1 then
				poses = { "pos21", "pos22", "pos23" }
				if battle.gameType ~= "doubles" then
					poses[4] = "_Foe"
				end
			else
				poses = { "pos11", "pos12", "pos13" }
				if battle.gameType ~= "doubles" then
					poses[4] = "_User"
				end
			end
			for i, v in pairs(poses) do
				local part = battle.scene:FindFirstChild(v)
				if part then
					parts[#parts + 1] = part
				end
			end
			local rock = create("Part")({
				Anchored = true, 
				CanCollide = false, 
				BrickColor = BrickColor.new("Dark orange"), 
				Size = Vector3.new(0.5, 1, 0.5),
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://818652045", 
					Scale = Vector3.new(0.01, 0.01, 0.01)
				})
			})
			local model = create("Model")({
				Name = "StealthRock" .. 3 - poke.side.n, 
				Parent = battle.scene
			})
			local targ = targetPoint(poke, 1.5)
			for i, v in pairs(parts) do
				spawn(function()
					local available = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 }
					local function getpart()
						local ran = math.random(#available)
						local removed = table.remove(available, ran)
						local num
						if #available < ran then
							num = 1
						else
							num = ran
						end
						table.remove(available, num)
						table.remove(available, ran == 1 and #available or ran - 1)
						return removed
					end
					local rnum = math.random() * math.pi * 2
					for i = 1, 5 do
						local num = rnum + (getpart() + math.random()) * math.pi / 10
						local num2 = 2.5 + math.random()
						local cf = v.CFrame * CFrame.Angles(0, math.random() * 6.28, 0) + Vector3.new(math.cos(num) * num2, -v.Size.Y / 2 + 0.5 + 0.3 * math.random(), math.sin(num) * num2)
						local num3 = (math.random() - 0.5) * 3
						local num4 = (math.random() - 0.5) * 3
						local srock = i == 5 and rock or rock:Clone()
						srock.Parent = model
						local num5 = (math.random() - 0.5) * 3
						local num6 = targ - cf.p
						spawn(function()
							Tween(0.5, "easeOutQuad", function(a)
								local num7 = 1 - a
								srock.CFrame = cf * CFrame.Angles(num7 * num3, num7 * num4, num7 * num5) + num6 * num7 + Vector3.new(0, 2 * math.sin(a * math.pi), 0)
							end)
						end)
						wait(0.1)
					end
				end)
			end
		end,
		stickyweb = function(poke)
			local parts = {}
			local poses
			local battle = poke.side.battle
			if poke.side.n == 1 then
				poses = { "pos21", "pos22", "pos23" }
				if battle.gameType ~= "doubles" then
					poses[4] = "_Foe"
				end
			else
				poses = { "pos11", "pos12", "pos13" }
				if battle.gameType ~= "doubles" then
					poses[4] = "_User"
				end
			end
			for i, v in pairs(poses) do
				local part = battle.scene:FindFirstChild(v)
				if part then
					parts[#parts + 1] = part
				end
			end
			local model = create("Model")({
				Name = "StickyWeb" .. 3 - poke.side.n, 
				Parent = battle.scene
			})
			local targ = targetPoint(poke, 1.5)
			for i, v in pairs(parts) do
				spawn(function()
					local part = create("Part")({
						Anchored = true, 
						CanCollide = false, 
						BrickColor = BrickColor.new("Institutional white"), 
						Size = Vector3.new(3, 3, 0.2)
					})
					local pos = Vector3.new(1.2, 1.2, 0.1)
					local smesh = create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://299832836", 
						Parent = part
					})
					part.Parent = model
					local angle = CFrame.Angles(math.random() < 0.5 and math.pi or 0, 0, math.random() * math.pi * 2)
					local pos2 = v.Position + Vector3.new(math.random() - 0.5, -v.Size.Y / 2 + 0.05, math.random() - 0.5)
					local cf = CFrame.new(pos2, pos2 + Vector3.new(pos2.X - targ.X, 0, pos2.Z - targ.Z))
					local targetPoint89 = targ - cf.p
					Tween(0.8, "easeOutQuad", function(a)
						smesh.Scale = pos * (0.5 + 0.5 * a)
						part.CFrame = cf * CFrame.Angles(1 - 2.57 * a, 0, 0) * angle + targetPoint89 * (1 - a) + Vector3.new(0, 2 * math.sin(a * math.pi), 0)
					end)
				end)
			end
		end,
		swordsdance = function(poke)
			local cf = poke.sprite.part.CFrame * CFrame.new(0, poke.sprite.part.Size.Y / 2, 0)
			local part = create("Part")({
				BrickColor = BrickColor.new("Dark stone grey"), 
				Reflectance = 0.4, 
				Anchored = true, 
				CanCollide = false, 
				Size = Vector3.new(1, 0.8, 4) * 0.6, 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxasset://fonts/sword.mesh", 
					TextureId = "rbxasset://textures/SwordTexture.png", 
					Scale = Vector3.new(0.6, 0.6, 0.6)
				})
			})
			local Swords = {}
			for i = 1, 6 do
				local cpart = i == 1 and part or part:Clone()
				cpart.Parent = workspace
				Swords[cpart] = cf * CFrame.Angles(0, math.pi / 3 * i, 0) * CFrame.new(0, 0, 2) * CFrame.Angles(-math.pi / 2, 0, 0)
			end
			local cf2 = CFrame.new(Vector3.new(0, 0, 0.85) * 0.6)
			Tween(0.6, nil, function(a)
				for i, v in pairs(Swords) do
					i.CFrame = v * CFrame.Angles(0, -math.pi * a, 0) * cf2
				end
			end)
			for i, v in pairs(Swords) do
				Swords[i] = v * CFrame.Angles(0, -math.pi, 0)
			end
			Tween(0.6, nil, function(a)
				for i, v in pairs(Swords) do
					i.CFrame = v * CFrame.Angles(0, 0, math.pi / 2 * a) * CFrame.Angles(0, -math.pi * a, 0) * cf2
				end
			end)
			for i, v in pairs(Swords) do
				Swords[i] = v * CFrame.Angles(0, 0, math.pi / 2) * CFrame.Angles(0, -math.pi, 0)
			end
			wait(0.3)
			delay(0.25, function()
				Utilities.sound("rbxasset://sounds/unsheath.wav", 1, nil, 2)
			end)
			Tween(0.4, nil, function(a)
				for i, v in pairs(Swords) do
					i.CFrame = v * CFrame.Angles(0, -0.9 * a, 0) * CFrame.new(0, 0, 0.6 * a) * cf2 + Vector3.new(0, 0.3 * a, 0)
				end
			end)
			wait(0.5)
			for i, v in pairs(Swords) do
				i:Destroy()
			end
		end,	

		darkpulse = function (poke, targets)
			local targ = targetPoint(poke)
			for i = 1, 3 do
				spawn(function()
					local part = create("Part")({
						BrickColor = BrickColor.new("Black"), 
						Transparency = 0.5, 
						Anchored = true, 
						CanCollide = false, 
						Size = Vector3.new(1, 1, 1), 
						Parent = workspace
					})
					part.CFrame = poke.sprite.part.CFrame * CFrame.Angles(math.pi / 2, 0, 0)
					local sMesh = create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://3270017", 
						Parent = part
					})
					Tween(0.5, nil, function(a)
						local num = a * 25
						sMesh.Scale = Vector3.new(num, num, 1)
						if a > 0.75 then
							part.Transparency = 0.5 + 0.5 * ((a - 0.75) * 4)
						end
					end)
					part:Destroy()
				end)
				wait(0.1)
			end
			wait(0.25)
			return true
		end,	

		rockblast = function(poke, targets)
			local target = targets[1] if not target then return end
			local targ = targetPoint(poke)
			local targ2 = targetPoint(target) - targ
			local Boulder = create("Part")({
				Anchored = true, 
				CanCollide = false, 
				BrickColor = BrickColor.new("Dirt brown"), 
				Size = Vector3.new(1.4, 1.4, 1.4), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://1290033", 
					Scale = Vector3.new(0.8, 0.8, 0.8)
				})
			})
			local cf = CFrame.new(targ) * CFrame.Angles(math.pi * 2 * math.random(), math.pi * 2 * math.random(), math.pi * 2 * math.random())
			Tween(0.4, nil, function(a)
				Boulder.CFrame = cf + targ2 * a
			end)
			Boulder:Destroy()
			return true
		end,	

		bulletseed = function(poke, targets)
			local target = targets[1]
			if not target then
				return true
			end
			local targ = targetPoint(poke)
			local targ2 = targetPoint(target) - targ
			for i = 1, 4 do
				spawn(function()
					local part = create("Part")({
						BrickColor = BrickColor.new("Olive"), 
						Anchored = true, 
						CanCollide = false, 
						TopSurface = Enum.SurfaceType.Smooth, 
						BottomSurface = Enum.SurfaceType.Smooth, 
						Shape = Enum.PartType.Ball, 
						Size = Vector3.new(0.5, 0.5, 0.5), 
						Parent = workspace
					})
					Tween(0.4, nil, function(a)
						part.CFrame = CFrame.new(targ + targ2 * a)
					end)
					part:Destroy()
				end)
				wait(0.15)
			end
			wait(0.25)
			return true
		end,	




		bubble = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local from = targetPoint(pokemon)
			local to = (pokemon.sprite.part.CFrame-pokemon.sprite.part.Position) + targetPoint(target)
			local ease = Utilities.Timing.easeOutCubic(.8)
			for i = 1, 6 do
				local st = tick()
				local dif = (to*Vector3.new((math.random()-.5)*3, (math.random()-.5)*3, (math.random()-.5)*.1))-from
				local size = .7+.3*math.random()

				_p.Particles:new {
					Image = 242218744,
					Color = Color3.fromHSV(math.random(190, 220)/360, 1, 1),
					Lifetime = 1.2,
					OnUpdate = function(a, gui)
						gui.CFrame = CFrame.new(from + dif*(a>.8 and 1 or ease(a))) + Vector3.new(0, math.sin(tick()-st)*.2, 0)
						local s = (.7+.4*a)*size
						if a > .95 then
							s = s + (a-.95)*4
							gui.BillboardGui.ImageLabel.ImageTransparency = (a-.95)*20
						end
						gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
					end
				}
				wait(.1)
			end
			wait(.5)
			return true
		end,
		bubblebeam = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local from = targetPoint(pokemon)
			local to = (pokemon.sprite.part.CFrame-pokemon.sprite.part.Position) + targetPoint(target)
			local ease = Utilities.Timing.easeOutCubic(.8)
			for i = 1, 20 do
				local st = tick()
				local dif = (to*Vector3.new((math.random()-.5)*1.6, (math.random()-.5)*1.6, (math.random()-.5)*.1))-from
				local size = .7+.3*math.random()
				_p.Particles:new {
					Image = 242218744,
					Color = Color3.fromHSV(math.random(190, 220)/360, 1, 1),
					Lifetime = 1.2,
					OnUpdate = function(a, gui)
						gui.CFrame = CFrame.new(from + dif*(a>.8 and 1 or ease(a))) + Vector3.new(0, math.sin(tick()-st)*.2, 0)
						local s = (.7+.4*a)*size
						if a > .95 then
							s = s + (a-.95)*4
							gui.BillboardGui.ImageLabel.ImageTransparency = (a-.95)*20
						end
						gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
					end
				}
				wait(.05)
			end
			wait(.5)
			return true
		end,
		cursedbeam = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local pos = CFrame.new(from, to)
			local dif = to - from
			local missile = storage.Models.Misc.Missile:Clone()
			missile.Color = Color3.fromRGB(58, 36, 70)
			missile.Material = "Neon"
			missile.Anchored = true
			missile.CanCollide = false
			missile.Trail.Lifetime = 1
			missile.Trail.Color = ColorSequence.new(Color3.fromRGB(58, 36, 70))
			missile.Trail.LightEmission = 0.75
			local Particles = storage.Models.Misc.Particles
			local fire = Particles.Beam:Clone()
			fire.LockedToPart = false
			fire.Parent = missile
			missile.CFrame = pos * CFrame.Angles(math.pi / 2, 0, 0)
			missile.Parent = move.scene
			Tween((dif.magnitude / 50), 'easeOutCubic', function(a)
				if not fire.Parent then return false end
				missile.CFrame = (pos + dif * a) * CFrame.Angles(math.pi / 2, 0, 0)
			end)
			fire.Enabled = false
			missile.Transparency = 1
			local attach = Instance.new("Attachment", workspace.Terrain)
			attach.WorldCFrame = CFrame.new(to)
			local spark = Particles.Sparks:Clone()
			spark.Enabled = false
			spark.Speed = NumberRange.new(10, 15)
			spark.Parent = attach
			local sparkv2 = spark:Clone()
			sparkv2.Texture = "rbxassetid://6209248212"
			sparkv2.Size = NumberSequence.new(2.5, 0.5)
			sparkv2.Speed = NumberRange.new(6, 10)
			sparkv2.Parent = attach
			sparkv2:Emit(10)
			spark:Emit(30)
			wait(spark.Lifetime.Max)
			attach:Destroy()
			missile:Destroy()
			return true
		end,
		earthquake = function(pokemon, battle)
			local cordFrame1 = pokemon.side.battle.CoordinateFrame1
			local cordFrame2 = pokemon.side.battle.CoordinateFrame2
			if pokemon.side.n == 2 then
				cordFrame1 = cordFrame2
				cordFrame2 = cordFrame1
			end
			local rock = storage.Models.Misc.Rock
			local random = Random.new()
			local distance = cordFrame1 + 0.5 * (cordFrame2.Position - cordFrame1.Position)
			local magnitude = (cordFrame1.Position - cordFrame2.Position).Magnitude
			for indexed = 0, magnitude + 1, magnitude / 5 do
				local folder = Instance.new("Folder", workspace)
				local items = {}
				for unitIndexed = -2, 2 do
					local clonedRock = rock:Clone()
					local randomUnit = random:NextNumber(0, 2)
					local VectorPlacement = Vector3.new(8, 4 + indexed * 0.25, 8)
					local HalfVectorPlacement = 0.5 * VectorPlacement.Y
					clonedRock.Size = VectorPlacement
					local v78 = cordFrame1 * CFrame.new(unitIndexed * VectorPlacement.X * 0.5, -HalfVectorPlacement, -indexed) * CFrame.Angles(0, math.rad(random:NextInteger(-45, 45)), 0, 0)
					clonedRock.CFrame = v78
					clonedRock.Parent = folder
					table.insert(items, { clonedRock, v78, HalfVectorPlacement })
				end
				coroutine.wrap(function()
					Tween(0.5, "easeOutCubic", function(a)
						for _, item in ipairs(items) do
							item[1].CFrame = item[2] + Vector3.new(0, item[3] * a, 0)
						end
					end)
					Tween(0.5, "easeInCubic", function(a)
						local correctedAlpha = 1 - a
						for _, item in ipairs(items) do
							item[1].CFrame = item[2] + Vector3.new(0, item[3] * correctedAlpha, 0)
						end
					end)
					folder:Destroy()
				end)()
				wait(0.075)
			end
			wait(0.25)
			return true
		end,
		
		moongeistbeam = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local pos = CFrame.new(from, to)
			local dif = to - from
			local missile = storage.Models.Misc.Missile:Clone()
			missile.Color = Color3.new(.5, 0, 1)
			missile.Material = "Neon"
			missile.Anchored = true
			missile.CanCollide = false
			missile.Trail.Lifetime = 1
			missile.Trail.Color = ColorSequence.new(Color3.fromRGB(85, 0, 255))
			missile.Trail.LightEmission = 0.75
			local Particles = storage.Models.Misc.Particles
			local fire = Particles.Beam:Clone()
			fire.LockedToPart = false
			fire.Parent = missile
			missile.CFrame = pos * CFrame.Angles(math.pi / 2, 0, 0)
			missile.Parent = move.scene
			Tween((dif.magnitude / 50), 'easeOutCubic', function(a)
				if not fire.Parent then return false end
				missile.CFrame = (pos + dif * a) * CFrame.Angles(math.pi / 2, 0, 0)
			end)
			fire.Enabled = false
			missile.Transparency = 1
			local attach = Instance.new("Attachment", workspace.Terrain)
			attach.WorldCFrame = CFrame.new(to)
			local spark = Particles.Sparks:Clone()
			spark.Enabled = false
			spark.Speed = NumberRange.new(10, 15)
			spark.Parent = attach
			local sparkv2 = spark:Clone()
			sparkv2.Texture = "rbxassetid://6209248212"
			sparkv2.Size = NumberSequence.new(2.5, 0.5)
			sparkv2.Speed = NumberRange.new(6, 10)
			sparkv2.Parent = attach
			sparkv2:Emit(10)
			spark:Emit(30)
			wait(spark.Lifetime.Max)
			attach:Destroy()
			missile:Destroy()
			return true
		end,		
		['10000000voltthunderbolt'] = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local pos = CFrame.new(from, to)
			local dif = to - from
			local missile = storage.Models.Misc.Missile:Clone()
			missile.Color = Color3.new(1, 1, 0)
			missile.Material = "Neon"
			missile.Anchored = true
			missile.CanCollide = false
			missile.Trail.Lifetime = 1
			missile.Trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 102))
			missile.Trail.LightEmission = 0.75
			local Particles = storage.Models.Misc.Particles
			local fire = Particles.Beam:Clone()
			fire.LockedToPart = false
			fire.Parent = missile
			missile.CFrame = pos * CFrame.Angles(math.pi / 2, 0, 0)
			missile.Parent = move.scene
			Tween((dif.magnitude / 50), 'easeOutCubic', function(a)
				if not fire.Parent then return false end
				missile.CFrame = (pos + dif * a) * CFrame.Angles(math.pi / 2, 0, 0)
			end)
			fire.Enabled = false
			missile.Transparency = 1
			local attach = Instance.new("Attachment", workspace.Terrain)
			attach.WorldCFrame = CFrame.new(to)
			local spark = Particles.Sparks:Clone()
			spark.Enabled = false
			spark.Speed = NumberRange.new(10, 15)
			spark.Parent = attach
			local sparkv2 = spark:Clone()
			sparkv2.Texture = "rbxassetid://6209248212"
			sparkv2.Size = NumberSequence.new(2.5, 0.5)
			sparkv2.Speed = NumberRange.new(6, 10)
			sparkv2.Parent = attach
			sparkv2:Emit(10)
			spark:Emit(30)
			wait(spark.Lifetime.Max)
			attach:Destroy()
			missile:Destroy()
			return true
		end,	
		aurorabeam = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local pos = CFrame.new(from, to)
			local dif = to - from
			local missile = storage.Models.Misc.Missile:Clone()
			missile.Color = Color3.new(.4, 1, 1)
			missile.Material = "Neon"
			missile.Anchored = true
			missile.CanCollide = false
			missile.Trail.Lifetime = 1
			missile.Trail.Color = ColorSequence.new(Color3.new(.4, 1, 1))
			missile.Trail.LightEmission = 0.75
			local Particles = storage.Models.Misc.Particles
			local fire = Particles.Beam:Clone()
			fire.LockedToPart = false
			fire.Parent = missile
			missile.CFrame = pos * CFrame.Angles(math.pi / 2, 0, 0)
			missile.Parent = move.scene
			Tween((dif.magnitude / 50), 'easeOutCubic', function(a)
				if not fire.Parent then return false end
				missile.CFrame = (pos + dif * a) * CFrame.Angles(math.pi / 2, 0, 0)
			end)
			fire.Enabled = false
			missile.Transparency = 1
			local attach = Instance.new("Attachment", workspace.Terrain)
			attach.WorldCFrame = CFrame.new(to)
			local spark = Particles.Sparks:Clone()
			spark.Enabled = false
			spark.Speed = NumberRange.new(10, 15)
			spark.Parent = attach
			local sparkv2 = spark:Clone()
			sparkv2.Texture = "rbxassetid://6209248212"
			sparkv2.Size = NumberSequence.new(2.5, 0.5)
			sparkv2.Speed = NumberRange.new(6, 10)
			sparkv2.Parent = attach
			sparkv2:Emit(10)
			spark:Emit(30)
			wait(spark.Lifetime.Max)
			attach:Destroy()
			missile:Destroy()
			return true
		end,				

		chargebeam = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local pos = CFrame.new(from, to)
			local dif = to - from
			local missile = storage.Models.Misc.Missile:Clone()
			missile.Color = Color3.new(1, 1, .4)
			missile.Material = "Neon"
			missile.Anchored = true
			missile.CanCollide = false
			missile.Trail.Lifetime = 1
			missile.Trail.Color = ColorSequence.new(Color3.new(1, 1, .4))
			missile.Trail.LightEmission = 0.75
			local Particles = storage.Models.Misc.Particles
			local fire = Particles.Beam:Clone()
			fire.LockedToPart = false
			fire.Parent = missile
			missile.CFrame = pos * CFrame.Angles(math.pi / 2, 0, 0)
			missile.Parent = move.scene
			Tween((dif.magnitude / 50), 'easeOutCubic', function(a)
				if not fire.Parent then return false end
				missile.CFrame = (pos + dif * a) * CFrame.Angles(math.pi / 2, 0, 0)
			end)
			fire.Enabled = false
			missile.Transparency = 1
			local attach = Instance.new("Attachment", workspace.Terrain)
			attach.WorldCFrame = CFrame.new(to)
			local spark = Particles.Sparks:Clone()
			spark.Enabled = false
			spark.Speed = NumberRange.new(10, 15)
			spark.Parent = attach
			local sparkv2 = spark:Clone()
			sparkv2.Texture = "rbxassetid://6209248212"
			sparkv2.Size = NumberSequence.new(2.5, 0.5)
			sparkv2.Speed = NumberRange.new(6, 10)
			sparkv2.Parent = attach
			sparkv2:Emit(10)
			spark:Emit(30)
			wait(spark.Lifetime.Max)
			attach:Destroy()
			missile:Destroy()
			return true
		end,						

		psybeam = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local pos = CFrame.new(from, to)
			local dif = to - from
			local missile = storage.Models.Misc.Missile:Clone()
			missile.Color = Color3.new(1, .44, .81)
			missile.Material = "Neon"
			missile.Anchored = true
			missile.CanCollide = false
			missile.Trail.Lifetime = 1
			missile.Trail.Color = ColorSequence.new(Color3.new(1, .44, .81))
			missile.Trail.LightEmission = 0.75
			local Particles = storage.Models.Misc.Particles
			local fire = Particles.Beam:Clone()
			fire.LockedToPart = false
			fire.Parent = missile
			missile.CFrame = pos * CFrame.Angles(math.pi / 2, 0, 0)
			missile.Parent = move.scene
			Tween((dif.magnitude / 50), 'easeOutCubic', function(a)
				if not fire.Parent then return false end
				missile.CFrame = (pos + dif * a) * CFrame.Angles(math.pi / 2, 0, 0)
			end)
			fire.Enabled = false
			missile.Transparency = 1
			local attach = Instance.new("Attachment", workspace.Terrain)
			attach.WorldCFrame = CFrame.new(to)
			local spark = Particles.Sparks:Clone()
			spark.Enabled = false
			spark.Speed = NumberRange.new(10, 15)
			spark.Parent = attach
			local sparkv2 = spark:Clone()
			sparkv2.Texture = "rbxassetid://6209248212"
			sparkv2.Size = NumberSequence.new(2.5, 0.5)
			sparkv2.Speed = NumberRange.new(6, 10)
			sparkv2.Parent = attach
			sparkv2:Emit(10)
			spark:Emit(30)
			wait(spark.Lifetime.Max)
			attach:Destroy()
			missile:Destroy()
			return true
		end,						

		signalbeam = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local pos = CFrame.new(from, to)
			local dif = to - from
			local missile = storage.Models.Misc.Missile:Clone()
			missile.Color = Color3.new(.54, .69, .2)
			missile.Material = "Neon"
			missile.Anchored = true
			missile.CanCollide = false
			missile.Trail.Lifetime = 1
			missile.Trail.Color = ColorSequence.new(Color3.new(.54, .69, .2))
			missile.Trail.LightEmission = 0.75
			local Particles = storage.Models.Misc.Particles
			local fire = Particles.Beam:Clone()
			fire.LockedToPart = false
			fire.Parent = missile
			missile.CFrame = pos * CFrame.Angles(math.pi / 2, 0, 0)
			missile.Parent = move.scene
			Tween((dif.magnitude / 50), 'easeOutCubic', function(a)
				if not fire.Parent then return false end
				missile.CFrame = (pos + dif * a) * CFrame.Angles(math.pi / 2, 0, 0)
			end)
			fire.Enabled = false
			missile.Transparency = 1
			local attach = Instance.new("Attachment", workspace.Terrain)
			attach.WorldCFrame = CFrame.new(to)
			local spark = Particles.Sparks:Clone()
			spark.Enabled = false
			spark.Speed = NumberRange.new(10, 15)
			spark.Parent = attach
			local sparkv2 = spark:Clone()
			sparkv2.Texture = "rbxassetid://6209248212"
			sparkv2.Size = NumberSequence.new(2.5, 0.5)
			sparkv2.Speed = NumberRange.new(6, 10)
			sparkv2.Parent = attach
			sparkv2:Emit(10)
			spark:Emit(30)
			wait(spark.Lifetime.Max)
			attach:Destroy()
			missile:Destroy()
			return true
		end,						
		

		breakneckblitz = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local sprite = pokemon.sprite
			local ep = (target.sprite.cf.p - sprite.cf.p)*Vector3.new(1,0,1)
			ep = ep.unit*(ep.magnitude-3)
			Tween(.4, nil, function(a)
				sprite.offset = ep*a + Vector3.new(0, math.sin(a*math.pi)*1.5, 0)
			end)
			local ts = target.sprite
			local cf = ts.part.CFrame
			local cfo = cf-cf.p
			local size = ts.part.Size
			local offset = ts.offset
			local back = ep.unit*2
			--		cf = cf-cf.p
			for i = 1, 5 do
				local x = math.random()-.5
				local y = math.random()*.5
				_p.Particles:new {
					Acceleration = false,
					Image = 644258078, -- 188x152
					Lifetime = .2,
					Color = Color3.fromRGB(194, 88, 61),
					Size = Vector2.new(1, .8),
					Position = cf * Vector3.new(x*size.X, y*size.Y, -.5),
					OnUpdate = function(a, gui)
						local img = gui.BillboardGui.ImageLabel
						if a < .25 and x < 0 then
							img.ImageRectSize = Vector2.new(-188, 152)
							img.ImageRectOffset = Vector2.new(188, 0)
						elseif a > .5 then
							img.ImageTransparency = (a-.5)*2
						end
					end
				}
				spawn(function()
					Tween(.23, nil, function(a)
						local s = math.sin(a*math.pi)
						ts.offset = offset + (cfo*Vector3.new(-x*size.X*.5*s,0,0)) + back*s
					end)
				end)
				if i < 5 then
					Tween(.23, nil, function(a)
						local s = math.sin(a*math.pi)
						sprite.offset = ep-back*s*.5
					end)
				end
			end
		
			return true
		end,
		closecombat = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local sprite = pokemon.sprite
			local ep = (target.sprite.cf.p - sprite.cf.p)*Vector3.new(1,0,1)
			ep = ep.unit*(ep.magnitude-3)
			Tween(.4, nil, function(a)
				sprite.offset = ep*a + Vector3.new(0, math.sin(a*math.pi)*1.5, 0)
			end)
			local ts = target.sprite
			local cf = ts.part.CFrame
			local cfo = cf-cf.p
			local size = ts.part.Size
			local offset = ts.offset
			local back = ep.unit*2
			--		cf = cf-cf.p
			for i = 1, 5 do
				local x = math.random()-.5
				local y = math.random()*.5
				_p.Particles:new {
					Acceleration = false,
					Image = 644258078, -- 188x152
					Lifetime = .2,
					Color = Color3.fromRGB(194, 88, 61),
					Size = Vector2.new(1, .8),
					Position = cf * Vector3.new(x*size.X, y*size.Y, -.5),
					OnUpdate = function(a, gui)
						local img = gui.BillboardGui.ImageLabel
						if a < .25 and x < 0 then
							img.ImageRectSize = Vector2.new(-188, 152)
							img.ImageRectOffset = Vector2.new(188, 0)
						elseif a > .5 then
							img.ImageTransparency = (a-.5)*2
						end
					end
				}
				spawn(function()
					Tween(.23, nil, function(a)
						local s = math.sin(a*math.pi)
						ts.offset = offset + (cfo*Vector3.new(-x*size.X*.5*s,0,0)) + back*s
					end)
				end)
				if i < 5 then
					Tween(.23, nil, function(a)
						local s = math.sin(a*math.pi)
						sprite.offset = ep-back*s*.5
					end)
				end
			end
			spawn(function()
				Tween(.4, nil, function(a)
					sprite.offset = ep*(1-a) + Vector3.new(0, math.sin(a*math.pi)*1.5, 0)
				end)
			end)
			return true
		end,
		crosschop = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Brown', 2)
			return 'sound'
		end,
		crosspoison = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Magenta', 2)
			return 'sound'
		end,
		crunch = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			Utilities.fastSpawn(function() bite(target, nil, nil, true) end)
			wait(.35)
			return 'sound'
		end,
		cut = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			cut(target)
			return 'sound'
		end,
		dig = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local sp = sprite.offset
			local ep = (target.sprite.cf.p - sprite.cf.p)*Vector3.new(.9,0,.9)
			Tween(.3, nil, function(a)
				sprite.offset = sp + (ep-sp)*a
			end)
			spawn(function()
				wait(.1)
				Tween(1, 'easeOutCubic', function(a)
					sprite.offset = ep*(1-a)
				end)
			end)
			return true -- perform usual hit anim
		end,
		dive = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local sp = sprite.offset
			local ep = (target.sprite.cf.p - sprite.cf.p)*Vector3.new(.9,0,.9)
			Tween(.3, nil, function(a)
				sprite.offset = sp + (ep-sp)*a
			end)
			spawn(function()
				wait(.1)
				Tween(1, 'easeOutCubic', function(a)
					sprite.offset = ep*(1-a)
				end)
			end)
			return true -- perform usual hit anim
		end,
		doubleteam = function(pokemon)
			local sprite = pokemon.sprite
			-- v = v0 + a*t
			-- p = p0 + v0*t + a*t*t/2
			Tween(2, nil, function(a)
				sprite.offset = Vector3.new(math.sin(15*a + 34*a*a), 0, 0)
			end)
			local left, right = Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0)
			Tween(1, 'easeInCubic', function(a, t)
				if t%.07 < .035 then
					sprite.offset = right * (1-a)
				else
					sprite.offset = left * (1-a)
				end
			end)
			sprite.offset = nil
		end,
		dragonclaw = function(pokemon, targets) -- todo: black/red particles
			local target = targets[1] if not target then return end
			cut(target, 'Royal purple', 3)
			return 'sound'
		end,
		drainingkiss = function(pokemon, targets)
			local target = targets[1] if not target then return end
			_p.Particles:new {
				Acceleration = false,
				Image = 644314963,-- 271x186
				Lifetime = .4,
				--			Size = Vector2.new(2, 1.34),
				Position = target.sprite.part.CFrame * Vector3.new(0, 0, -.5),
				OnUpdate = function(a, gui)
					local s = math.sin(.5+1.6*a)
					gui.BillboardGui.Size = UDim2.new(2*s, 0, 1.34*s, 0)
					if a > .5 then
						gui.BillboardGui.ImageLabel.ImageTransparency = (a-.5)*2
					end
				end
			}
			wait(.25)
			absorb(pokemon, target, 12, Color3.new(.92, .7, .92))
			return true
		end,
		dualchop = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Royal purple')
			return 'sound'
		end,
		ember = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local dif = to-from
			for i = 1, 3 do
				_p.Particles:new {
					Image = 11601142,
					Lifetime = .7,
					OnUpdate = function(a, gui)
						gui.CFrame = CFrame.new(from + dif*a)
						local s = 1+1.5*a
						gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
					end
				}
				wait(.05)
			end
			wait(.6)
			return true
		end,
		energyball = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local centroid = targetPoint(pokemon, 2.5)
			local cf = CFrame.new(centroid, centroid + workspace.CurrentCamera.CFrame.lookVector)
			local function makeParticle(hue)
				local p = create 'Part' {
					Transparency = 1.0,
					Anchored = true,
					CanCollide = false,
					Size = Vector3.new(.2, .2, .2),
					Parent = workspace,
				}
				local bbg = create 'BillboardGui' {
					Adornee = p,
					Size = UDim2.new(.7, 0, .7, 0),
					Parent = p,
					create 'ImageLabel' {
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://6294357140',
						ImageTransparency = .15,
						ImageColor3 = Color3.fromHSV(hue/360, 1, .85),
						Size = UDim2.new(1.0, 0, 1.0, 0),
						ZIndex = 2
					}
				}
				return p, bbg
			end
			local main, mbg = makeParticle(100)
			main.CFrame = cf
			local allParticles = {main}
			delay(.3, function()
				local rand = math.random
				for i = 2, 11 do
					local theta = rand()*6.28
					local offset = Vector3.new(math.cos(theta), math.sin(theta), .5)
					local p, b = makeParticle(rand(66, 156))
					allParticles[i] = p
					local r = math.random()*.35+.2
					spawn(function()
						local st = tick()
						local function o(r)
							local et = (tick()-st)*7
							p.CFrame = cf * CFrame.new(offset*r+.125*Vector3.new(math.cos(et), math.sin(et)*math.cos(et), 0))
						end
						Tween(.2, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							b.Size = UDim2.new(.5*a, 0, .5*a, 0)
							o(r+.6)
						end)
						Tween(.25, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							o(r+.6*(1-a))
						end)
						while p.Parent do
							o(r)
							stepped:wait()
						end
					end)
					wait(.1)
				end
			end)
			Tween(1.5, nil, function(a)
				mbg.Size = UDim2.new(2.5*a, 0, 2.5*a, 0)
			end)
			wait(.3)
			local targPos = targetPoint(target)
			local dp = targPos - centroid
			local v = 30
			local scf = cf
			Tween(dp.magnitude/v, nil, function(a)
				cf = scf + dp*a
				main.CFrame = cf
			end)
			for _, p in pairs(allParticles) do
				p:Destroy()
			end
			return true -- perform usual hit anim
		end,


		waterpulse = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local centroid = targetPoint(pokemon, 2.5)
			local cf = CFrame.new(centroid, centroid + workspace.CurrentCamera.CFrame.lookVector)
			local function makeParticle(hue)
				local p = create 'Part' {
					Transparency = 1.0,
					Anchored = true,
					CanCollide = false,
					Size = Vector3.new(.2, .2, .2),
					Parent = workspace,
				}
				local bbg = create 'BillboardGui' {
					Adornee = p,
					Size = UDim2.new(.7, 0, .7, 0),
					Parent = p,
					create 'ImageLabel' {
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://6294357140',
						ImageTransparency = .15,
						ImageColor3 = Color3.fromRGB(41, 145, 242),
						Size = UDim2.new(1.0, 0, 1.0, 0),
						ZIndex = 2
					}
				}
				return p, bbg
			end
			local main, mbg = makeParticle(100)
			main.CFrame = cf
			local allParticles = {main}
			delay(.3, function()
				local rand = math.random
				for i = 2, 11 do
					local theta = rand()*6.28
					local offset = Vector3.new(math.cos(theta), math.sin(theta), .5)
					local p, b = makeParticle(rand(66, 156))
					allParticles[i] = p
					local r = math.random()*.35+.2
					spawn(function()
						local st = tick()
						local function o(r)
							local et = (tick()-st)*7
							p.CFrame = cf * CFrame.new(offset*r+.125*Vector3.new(math.cos(et), math.sin(et)*math.cos(et), 0))
						end
						Tween(.2, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							b.Size = UDim2.new(.5*a, 0, .5*a, 0)
							o(r+.6)
						end)
						Tween(.25, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							o(r+.6*(1-a))
						end)
						while p.Parent do
							o(r)
							stepped:wait()
						end
					end)
					wait(.1)
				end
			end)
			Tween(1.5, nil, function(a)
				mbg.Size = UDim2.new(2.5*a, 0, 2.5*a, 0)
			end)
			wait(.3)
			local targPos = targetPoint(target)
			local dp = targPos - centroid
			local v = 30
			local scf = cf
			Tween(dp.magnitude/v, nil, function(a)
				cf = scf + dp*a
				main.CFrame = cf
			end)
			for _, p in pairs(allParticles) do
				p:Destroy()
			end
			return true -- perform usual hit anim
		end,
		pyroball = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local centroid = targetPoint(pokemon, 2.5)
			local cf = CFrame.new(centroid, centroid + workspace.CurrentCamera.CFrame.lookVector)
			local function makeParticle(hue)
				local p = create 'Part' {
					Transparency = 1.0,
					Anchored = true,
					CanCollide = false,
					Size = Vector3.new(.2, .2, .2),
					Parent = workspace,
				}
				local bbg = create 'BillboardGui' {
					Adornee = p,
					Size = UDim2.new(.7, 0, .7, 0),
					Parent = p,
					create 'ImageLabel' {
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://6294357140',
						ImageTransparency = .15,
						ImageColor3 = Color3.fromRGB(242, 48, 0),
						Size = UDim2.new(1.0, 0, 1.0, 0),
						ZIndex = 2
					}
				}
				return p, bbg
			end
			local main, mbg = makeParticle(100)
			main.CFrame = cf
			local allParticles = {main}
			delay(.3, function()
				local rand = math.random
				for i = 2, 11 do
					local theta = rand()*6.28
					local offset = Vector3.new(math.cos(theta), math.sin(theta), .5)
					local p, b = makeParticle(rand(66, 156))
					allParticles[i] = p
					local r = math.random()*.35+.2
					spawn(function()
						local st = tick()
						local function o(r)
							local et = (tick()-st)*7
							p.CFrame = cf * CFrame.new(offset*r+.125*Vector3.new(math.cos(et), math.sin(et)*math.cos(et), 0))
						end
						Tween(.2, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							b.Size = UDim2.new(.5*a, 0, .5*a, 0)
							o(r+.6)
						end)
						Tween(.25, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							o(r+.6*(1-a))
						end)
						while p.Parent do
							o(r)
							stepped:wait()
						end
					end)
					wait(.1)
				end
			end)
			Tween(1.5, nil, function(a)
				mbg.Size = UDim2.new(2.5*a, 0, 2.5*a, 0)
			end)
			wait(.3)
			local targPos = targetPoint(target)
			local dp = targPos - centroid
			local v = 30
			local scf = cf
			Tween(dp.magnitude/v, nil, function(a)
				cf = scf + dp*a
				main.CFrame = cf
			end)
			for _, p in pairs(allParticles) do
				p:Destroy()
			end
			return true -- perform usual hit anim
		end,
		

		explosion = function(pokemon, targets)
			pcall(function() pokemon.statbar:setHP(0, pokemon.maxhp) end)
			local e = create 'Explosion' {
				BlastPressure = 0,
				Position = pokemon.sprite.cf.p,
				Parent = workspace
			}
			delay(3, function() pcall(function() e:Destroy() end) end)
			wait(.5)
			return true -- perform usual hit anim
		end,
		--[[similar to explosion]]selfdestruct = function(pokemon, targets)
			pcall(function() pokemon.statbar:setHP(0, pokemon.maxhp) end)
			local e = create 'Explosion' {
				BlastPressure = 0,
				Position = pokemon.sprite.cf.p,
				Parent = workspace
			}
			delay(3, function() pcall(function() e:Destroy() end) end)
			wait(.5)
			return true -- perform usual hit anim
		end,
		soulstealing7starstrike = function(pokemon, target)
			pcall(function() pokemon.statbar:setHP(0, pokemon.maxhp) end)
			local e = create 'Explosion' {
				BlastPressure = 0,
				Position = pokemon.sprite.cf.p,
				Parent = workspace
				
			}
			delay(3, function() pcall(function() e:Destroy() end) end)
			e.Trail.Color = ColorSequence.new(Color3.fromRGB(49, 21, 65))
			tackle(target, nil, 3)
			return true -- perform usual hit anim
		end,
		
		electroweb = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local dif = to-from
			local pos = CFrame.new(from, to)
			local bolt = storage.Models.Misc.Bolt:Clone()
			bolt.Anchored = true
			bolt.CanCollide = false
			bolt.Trail.Lifetime = 1
			bolt.Trail.Color = ColorSequence.new(Color3.fromRGB(255, 250, 40))
			bolt.Trail.LightEmission = 0.75
			local Particles = storage.Models.Misc.Particles
			local beam = Particles.ThunderBeam:Clone()
			beam.LockedToPart = false
			beam.Parent = bolt
			bolt.CFrame = pos * CFrame.Angles(math.pi / 2, 0, 0)
			bolt.Parent = move.scene
			Tween((dif.magnitude / 50), 'easeOutCubic', function(a)
				if not beam.Parent then return false end
				bolt.CFrame = (pos + dif * a) * CFrame.Angles(math.pi / 2, 0, 0)
			end)
			beam.Enabled = false
			bolt.Transparency = 1
			bolt:Destroy()
			local web = storage.Models.Misc.webshot:Clone()
			web.Color = Color3.fromRGB(255, 242, 49)
			web.Anchored = true
			web.CanCollide = false
			web.Size = Vector3.new(3, 0.25, 3)
			web.Parent = workspace
			Utilities.fastSpawn(function()
				web.CFrame = CFrame.new(to) * CFrame.Angles(0, math.rad(90), math.rad(-90))
			end)
			wait(1)
			web:Destroy()
			return true
		end,

		gust = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local crescent = storage.Models.Misc.Crescent:Clone()
			crescent.Color = Color3.fromRGB(255, 255, 255)
			crescent.Transparency = 0.2
			crescent.Size = Vector3.new(9, 0.2, 4)
			crescent.Anchored = true
			local Particles = storage.Models.Misc.Particles
			local gust = Particles.Gust:Clone()
			gust.Enabled = true
			gust.Parent = crescent
			crescent.Parent = move.scene
			local pos = CFrame.new(from, to)
			local dif = to - from
			Utilities.fastSpawn(function()
				Tween(0.35, "easeOutQuad", function(a)
					crescent.CFrame = pos * CFrame.new(0, 0, -(dif.magnitude + 2) * a)
					crescent.Transparency = 0.2 + 0.8 * a
				end)
			end)
			gust.Enabled = false
			game.Debris:AddItem(crescent, gust.Lifetime.Max)
			return true
		end,
		falseswipe = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target)
			return 'sound'
		end,
		firefang = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			Utilities.fastSpawn(function() bite(target, 11601142, 2) end)
			wait(.35)
			return 'sound'
		end,
		flamethrower = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local s = targetPoint(pokemon, 2)
			local e = targetPoint(target)
			local dp = e-s
			local up = CFrame.new(s, e).upVector

			local tt = .7
			for n = 1, 20 do
				spawn(function()
					local p, b, i = cParticle(600006428, 1.5)
					Tween(tt, nil, function(a)
						i.ImageColor3 = Color3.fromHSV(.138*(1-a), 1, 1)
						p.CFrame = CFrame.new(s) + up*math.sin(a*math.pi*1.5/tt+n*.2)*.4 + dp*a
					end)
					p:Destroy()
				end)
				wait(.1)
			end
			wait(tt)
			return true--'sound' -- just play sound (single-target)
		end,
		fly = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local sp = sprite.offset
			local ep = (target.sprite.cf.p - sprite.cf.p)*Vector3.new(.9,0,.9)+Vector3.new(0,(sprite.spriteData.inAir or 0)*-.75,0)
			--		local sp = ep+Vector3.new(0, 10, 0)--sprite.offset
			Tween(.3, nil, function(a)
				sprite.offset = sp + (ep-sp)*a
			end)
			spawn(function()
				wait(.1)
				Tween(1, 'easeOutCubic', function(a)
					sprite.offset = ep*(1-a)
				end)
			end)
			return true -- perform usual hit anim
		end,
		furycutter = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Medium green')
			return 'sound'
		end,
		furyswipes = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, nil, 3)
			return 'sound'
		end,
		gigadrain = function(pokemon, targets)
			local target = targets[1] if not target then return end
			absorb(pokemon, target, 20)
			return true
		end,
		icebeam = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local dif = to-from
			local cf = target.sprite.part.CFrame
			cf = cf-cf.p
			local cam = workspace.CurrentCamera
			local fs = cam:WorldToScreenPoint(from)
			local ts = cam:WorldToScreenPoint(to)
			local rot = math.deg(math.atan2(ts.Y-fs.Y, ts.X-fs.X))+90
			for i = 1, 15 do
				local scale = math.random()*.5+.75
				local color = Color3.fromHSV(.5+.08*math.random(), math.random()*.75, 1)
				local offset = cf*(.25*Vector3.new(math.random()-.5, math.random()-.5, 0))
				_p.Particles:new {
					Color = color,
					Image = 644323665,
					Lifetime = .7,
					Rotation = rot,
					OnUpdate = function(a, gui)
						gui.CFrame = CFrame.new(from + dif*a + offset)
						local s = (a<.2 and a*5 or 1)*scale
						gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
					end
				}
				delay(.7, function()
					for i = 1, 2 do
						local angle = math.random()*360
						_p.Particles:new {
							Color = color,
							Image = 644161227,
							Lifetime = .7,
							Rotation = angle+90,
							Size = .4*scale,
							Position = to,
							Velocity = 5*(cf*Vector3.new(math.cos(math.rad(angle)), math.sin(math.rad(angle)), 0)),
							Acceleration = false
						}
					end
				end)
				wait(.06)
			end
			wait(.5)
			return true
		end,
		icefang = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			Utilities.fastSpawn(function() bite(target, 629607498) end)
			wait(.35)
			return 'sound'
		end,
		--	leafage = function(pokemon)
		--		
		--	end,
		lightscreen = function(pokemon)
			shield(pokemon, 'Pastel light blue')
		end,
		megadrain = function(pokemon, targets)
			local target = targets[1] if not target then return end
			absorb(pokemon, target, 12)
			return true
		end,
		metalclaw = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Smoky grey', 3)
			return 'sound'
		end,
		moonblast = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local from = targetPoint(pokemon, 2)
			local to = targetPoint(target)
			local dif = to-from

			local moon = create 'Part' {
				BrickColor = BrickColor.new('Carnation pink'),
				Material = Enum.Material.Neon,
				Anchored = true,
				CanCollide = false,
				TopSurface = Enum.SurfaceType.Smooth,
				BottomSurface = Enum.SurfaceType.Smooth,
				Size = Vector3.new(4, 4, 4),
				Shape = Enum.PartType.Ball,
				CFrame = CFrame.new(pokemon.sprite.cf.p+Vector3.new(0, 7-(pokemon.sprite.spriteData.inAir or 0), 0)),
				Parent = workspace
			}
			Tween(1, nil, function(a)
				moon.Transparency = 1-a
			end)
			local blast = moon:Clone()
			blast.BrickColor = BrickColor.new('Pink')
			blast.Parent = workspace
			local twoPi = math.pi*2
			local r = 4
			for i = 1, 20 do
				delay(.075*i, function()
					local beam = create 'Part' {
						Material = Enum.Material.Neon,
						BrickColor = BrickColor.new('White'),
						Anchored = true,
						CanCollide = false,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
						Parent = workspace,
					}
					local transform = CFrame.Angles(twoPi*math.random(),twoPi*math.random(),twoPi*math.random()).lookVector * r
					local cf = CFrame.new(from)*transform
					Tween(.25, nil, function(a)
						beam.Size = Vector3.new(.2, .2, r*a)
						beam.CFrame = CFrame.new(cf + (from-cf)/2*a, cf)
					end)
					Tween(.25, nil, function(a)
						beam.Size = Vector3.new(.2, .2, r*(1-a))
						beam.CFrame = CFrame.new(cf + (from-cf)*(.5+.5*a), cf)
					end)
					beam:Destroy()
				end)
			end
			Tween(2, nil, function(a)
				blast.Size = Vector3.new(2.3,2.3,2.3)*a
				blast.CFrame = CFrame.new(from)
			end)
			wait(.2)
			Tween(.3, nil, function(a)
				blast.CFrame = CFrame.new(from+dif*a)
			end)
			blast:Destroy()
			spawn(function()
				Tween(1, nil, function(a)
					moon.Transparency = a
				end)
				moon:Destroy()
			end)
			return true
		end,
		oceanicoperetta = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local from = targetPoint(pokemon, 2)
			local to = targetPoint(target)
			local dif = to-from

			local moon = create 'Part' {
				BrickColor = BrickColor.new('Carnation pink'),
				Material = Enum.Material.Neon,
				Anchored = true,
				CanCollide = false,
				TopSurface = Enum.SurfaceType.Smooth,
				BottomSurface = Enum.SurfaceType.Smooth,
				Size = Vector3.new(4, 4, 4),
				Shape = Enum.PartType.Ball,
				CFrame = CFrame.new(pokemon.sprite.cf.p+Vector3.new(0, 7-(pokemon.sprite.spriteData.inAir or 0), 0)),
				Parent = workspace
			}
			Tween(1, nil, function(a)
				moon.Transparency = 1-a
			end)
			local blast = moon:Clone()
			blast.BrickColor = BrickColor.new('Baby blue')
			blast.Parent = workspace
			local twoPi = math.pi*2
			local r = 4
			for i = 1, 20 do
				delay(.075*i, function()
					local beam = create 'Part' {
						Material = Enum.Material.Glacier,
						BrickColor = BrickColor.new('Bright blue'),
						Anchored = true,
						CanCollide = false,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
						Parent = workspace,
					}
					local transform = CFrame.Angles(twoPi*math.random(),twoPi*math.random(),twoPi*math.random()).lookVector * r
					local cf = CFrame.new(from)*transform
					Tween(.25, nil, function(a)
						beam.Size = Vector3.new(.2, .2, r*a)
						beam.CFrame = CFrame.new(cf + (from-cf)/2*a, cf)
					end)
					Tween(.25, nil, function(a)
						beam.Size = Vector3.new(.2, .2, r*(1-a))
						beam.CFrame = CFrame.new(cf + (from-cf)*(.5+.5*a), cf)
					end)
					beam:Destroy()
				end)
			end
			Tween(2, nil, function(a)
				blast.Size = Vector3.new(2.3,2.3,2.3)*a
				blast.CFrame = CFrame.new(from)
			end)
			wait(.2)
			Tween(.3, nil, function(a)
				blast.CFrame = CFrame.new(from+dif*a)
			end)
			blast:Destroy()
			spawn(function()
				Tween(1, nil, function(a)
					moon.Transparency = a
				end)
				moon:Destroy()
			end)
			return true
		end,
		nightslash = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Black', 3)
			return 'sound'
		end,
		protect = function(pokemon)
			shield(pokemon)
		end,

		psychocut = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Pink')
			return 'sound'
		end,
		razorleaf = function(pokemon, targets)
			local target = targets[1] 
			if not target then 
				return 
			end
			local from = targetPoint(pokemon, 2)
			local leaf = storage.Models.Misc.Leaf
			local to = targetPoint(target)
			local part = pokemon.sprite.part
			local tp1 = part.CFrame * Vector3.new(part.Size * Vector3.new(-0.5, 25, -0.25) + Vector3.new(-1, 0, 0))
			local tp2 = part.CFrame * Vector3.new(part.Size * Vector3.new(-0.5, 25, -0.25) + Vector3.new(-1, 0, 0))
			local RightVector = part.CFrame.RightVector
			local LookVector = part.CFrame.LookVector
			for i = 1, 9 do
				local position
				if math.random(2) == 1 then
					position = tp1 - RightVector * math.random() + Vector3.new(0, 4 * (math.random() - 0.5), 0) + LookVector * 2 * (math.random() - 0.5)
				else
					position = tp2 + RightVector * math.random() + Vector3.new(0, 4 * (math.random() - 0.5), 0) + LookVector * 2 * (math.random() - 0.5)
				end
				local leafpart = leaf:Clone()
				leafpart.Parent = workspace
				local spot = CFrame.new(position, to)
				Utilities.fastSpawn(function()
					Tween(0.065, "easeOutQuad", function(a)
						leafpart.CFrame = spot + Vector3.new(0, -0.2 * (1 - a), 0)
					end)
					wait(0.28)
					local ok = to - spot.Position
					local cool = ok + ok.Unit * 0.2
					Tween(0.5, nil, function(b)
						leafpart.CFrame = spot + cool * b
					end)
					leafpart:Destroy()
				end)
				wait(0.01)
			end
			wait(0.6)
			return true
		end,
--[[ razorleaf = function(pokemon, targets)
		local target = targets[1] if not target then return end
		local orientation = pokemon.sprite.part.CFrame - pokemon.sprite.part.Position
		local from = orientation + targetPoint(pokemon, -.5)
		local to = orientation + targetPoint(target, .5)
		local psize = pokemon.sprite.part.Size
		local tsize = target.sprite.part.Size
		local p = _p.Particles
		local ease = Utilities.Timing.easeOutCubic(.3)
		local rot = target.sprite.siden==2 and 35 or 215
		for i = 1, 10 do -- 
			wait(.1)
			local x, y = math.random()-.5, math.random()-.5
			local thisfrom = from * CFrame.new(psize.X*x, psize.Y*y, 0)
			local thisto = to * CFrame.new(tsize.X*x, tsize.Y*y, 0)
			local dif = thisto.p - thisfrom.p
			p:new {
				Rotation = math.random(360),
				RotVelocity = 30,
				Acceleration = false,
				Lifetime = 1.45,
				Image = 29073832,
				Size = .6,
				OnUpdate = function(a, gui)
					local t = a*1.45
					if t < .3 then
						gui.CFrame = thisfrom + Vector3.new(0, ease(t), 0)
					elseif t < 1.1 then
						gui.CFrame = thisfrom + Vector3.new(0, 1-.5*(t-.3)/.8, 0)
					else
						gui.BillboardGui.ImageLabel.Rotation = rot
						local o = (t-1.1)/.35
						gui.CFrame = thisfrom + Vector3.new(0, .5*(1-o), 0) + dif*o
					end
				end,
			}
		end
		wait(1.7)
		return true
	end,]]
		reflect = function(pokemon)
			shield(pokemon, 'Carnation pink')
		end,
		rockslide = function(pokemon, targets)
			for _, target in pairs(targets) do
				spawn(function()
					local cf = target.sprite.part.CFrame
					cf = cf-cf.p
					local dir = targetPoint(target, 0)-targetPoint(target, 1)
					local pos = target.sprite.part.Position+Vector3.new(0, -target.sprite.part.Size.Y/2-(target.sprite.spriteData.inAir or 0), 0)
					local rockcf = CFrame.new(pos - dir + Vector3.new(0, .7, 0), pos + Vector3.new(0, .7, 0))

					for _ = 1, 4 do
						local rock = create 'Part' {
							Anchored = true,
							CanCollide = false,
							BrickColor = BrickColor.new('Dirt brown'),
							Size = Vector3.new(1.4, 1.4, 1.4),
							Parent = workspace,

							create 'SpecialMesh' {
								MeshType = Enum.MeshType.FileMesh,
								MeshId = 'rbxassetid://1290033',
								Scale = Vector3.new(.8, .8, .8)
							}
						}
						local xoffset = cf*Vector3.new((math.random()-.5)*3, 0, 0)
						local rot = CFrame.Angles(math.random()*6.3, math.random()*6.3, math.random()*6.3)
						spawn(function()
							Tween(.5, nil, function(a)
								rock.CFrame = (rockcf + xoffset + Vector3.new(0, 8*(1-a), 0)) * rot
							end)
							Tween(.4, nil, function(a)
								rock.CFrame = (rockcf + xoffset + dir*2*a + Vector3.new(0, math.sin(a*math.pi*5/4)-a, 0)) * CFrame.Angles(-6*a, 0, 0) * rot
							end)
							rock:Destroy()
						end)
						wait(.25)
					end
				end)
			end
			wait(1.3)
			return true
		end,
		sacredsword = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Brown')
			return 'sound'
		end,
		scald = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local sprite = pokemon.sprite
			local s = targetPoint(pokemon, 2)
			local e = targetPoint(target, .5)
			local dp = e-s

			local tSprite = target.sprite
			local cf = tSprite.part.CFrame
			cf = cf-cf.p
			local tLabel pcall(function() tLabel = tSprite.animation.spriteLabel end)
			delay(.7, function()
				Tween(.84, nil, function(a)
					local s = math.sin(a*math.pi)
					local m = (a*5)%1
					if m > .75 then
						m = m-1
					elseif m > .25 then
						m = .5-m
					end
					tSprite.offset = cf * Vector3.new(m*s, 0, 0)
					if tLabel then
						tLabel.ImageColor3 = Color3.new(1, 1-s, 1-s)
					end
				end)
			end)
			for n = 1, 15 do
				spawn(function()
					local p = cParticle(650846795, 1, Color3.fromHSV((210+math.random()*20)/360, .8, .75))
					Tween(.7, nil, function(a)
						p.CFrame = CFrame.new(s + dp*a + Vector3.new(0, math.sin(a*math.pi)*.8, 0))
					end)
					p:Destroy()
				end)
				wait(.06)
			end
			wait(.64)
			return true
		end,
		shadowball = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local sprite = pokemon.sprite
			local centroid = targetPoint(pokemon, 2.5)
			local cf = CFrame.new(centroid, centroid + workspace.CurrentCamera.CFrame.lookVector)
			local function makeParticle(hue)
				local p = create 'Part' {
					Transparency = 1.0,
					Anchored = true,
					CanCollide = false,
					Size = Vector3.new(.2, .2, .2),
					Parent = workspace,
				}
				local bbg = create 'BillboardGui' {
					Adornee = p,
					Size = UDim2.new(.7, 0, .7, 0),
					Parent = p,
					create 'ImageLabel' {
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://6294357140',
						ImageTransparency = .15,
						ImageColor3 = Color3.fromHSV(hue/360, .5, .5),
						Size = UDim2.new(1.0, 0, 1.0, 0),
						ZIndex = 2

					}
				}
				return p, bbg
			end
			local main, mbg = makeParticle(260)
			main.CFrame = cf
			local allParticles = {main}
			delay(.3, function()
				local rand = math.random
				for i = 2, 11 do
					local theta = rand()*6.28
					local offset = Vector3.new(math.cos(theta), math.sin(theta), .5)
					local p, b = makeParticle(rand(248, 310))
					allParticles[i] = p
					local r = math.random()*.35+.2
					spawn(function()
						local st = tick()
						local function o(r)
							local et = (tick()-st)*7
							p.CFrame = cf * CFrame.new(offset*r+.125*Vector3.new(math.cos(et), math.sin(et)*math.cos(et), 0))
						end
						Tween(.2, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							b.Size = UDim2.new(.5*a, 0, .5*a, 0)
							o(r+.6)
						end)
						Tween(.25, 'easeOutCubic', function(a)
							if not p.Parent then return false end
							o(r+.6*(1-a))
						end)
						while p.Parent do
							o(r)
							stepped:wait()
						end
					end)
					wait(.1)
				end
			end)
			Tween(1.5, nil, function(a)
				mbg.Size = UDim2.new(2.5*a, 0, 2.5*a, 0)
			end)
			wait(.3)
			local targPos = targetPoint(target)
			local dp = targPos - centroid
			local v = 30
			local scf = cf
			Tween(dp.magnitude/v, nil, function(a)
				cf = scf + dp*a
				main.CFrame = cf
			end)
			for _, p in pairs(allParticles) do
				p:Destroy()
			end
			return true -- perform usual hit anim
		end,



		scratch = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, nil, 3)
			return 'sound'
		end,
		secretsword = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Brown')
			return 'sound'
		end,

		shadowclaw = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Dark indigo', 3)
			return 'sound'
		end,
		shadowforce = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local spriteLabel = pokemon.sprite.animation.spriteLabel
			spawn(function()
				Tween(.075, nil, function(a)
					spriteLabel.ImageTransparency = 1-a
				end)
			end)
			tackle(pokemon, target)
			return true -- perform usual hit anim
		end,
		shadowspatter = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local cpos = CFrame.new(from, to)
			local dif = to - from
			local obj = Random.new()
			for i = 1, 9 do
				local pos = (CFrame.new(from, to) * CFrame.new(obj:NextInteger(-5, 5), obj:NextInteger(8, 18), obj:NextInteger(-3, -10)) + dif).p - from
				local gty = Vector3.new(0, -workspace.Gravity, 0)
				local mag1 = pos.Magnitude
				local mag2 = gty.Magnitude
				local av1 = (2 * mag1 / mag2) ^ 0.5
				local av2 = 2 * math.sqrt(2 * mag2 * mag1 / 2) / mag2
				local av0 = (mag2 * pos - mag1 * gty) / (2 * mag2 * mag1) ^ 0.5 / (av2 / av1)
				local ss = storage.Models.Misc.ShadowSpatter:Clone()
				ss.Color = Color3.fromRGB(90, 76, 66)
				local n = obj:NextNumber() * 2
				ss.Size = Vector3.new(2, 0.1, 2) + Vector3.new(n, 0, n)
				ss.Anchored = false
				ss.Material = "Neon"
				ss.Color = Color3.fromRGB(26, 25, 44)
				ss.Trail.Color = ColorSequence.new(Color3.fromRGB(40, 28, 57))
				ss.Velocity = av0
				ss.CFrame = CFrame.new(Vector3.new(), av0.unit) + from
				ss.Parent = move.scene
				game.Debris:AddItem(ss, av2)
				delay(av1, function()
					local attach = Instance.new("Attachment", workspace.Terrain)
					attach.WorldCFrame = CFrame.new(to)
					local Particles = storage.Models.Misc.Particles
					local mudspat = Particles.ShadowSpatter:Clone()
					mudspat.Parent = attach
					mudspat.LightEmission = 0.2
					mudspat.Texture = "http://www.roblox.com/asset/?id=6204022252"
					mudspat.Color = ColorSequence.new(Color3.fromRGB(42, 26, 65))
					mudspat:Emit(10)
					game.Debris:AddItem(attach, 1)
				end)
				wait()
			end
			wait((2 * dif.Magnitude / Vector3.new(0, -workspace.Gravity, 0).Magnitude) ^ 0.5)
			return true
		end,

		sludgebomb = function(poke, targets)
			local target = targets[1]
			if not target then
				return true
			end 
			local targ = targetPoint(poke)
			local targ2 = targetPoint(target)
			local cf = target.sprite.part.CFrame
			local CurrentCamera = workspace.CurrentCamera
			local part = create("Part")({
				BrickColor = BrickColor.new("Bright violet"), 
				Transparency = 0.1, 
				Reflectance = 0.1, 
				Anchored = true, 
				CanCollide = false, 
				TopSurface = Enum.SurfaceType.Smooth, 
				BottomSurface = Enum.SurfaceType.Smooth, 
				Shape = Enum.PartType.Ball, 
				Parent = workspace
			})
			Tween(0.3, nil, function(a)
				part.Size = Vector3.new(a, a, a) * 2
				part.CFrame = CFrame.new(targ)
			end)
			local cf2 = cf - cf.p
			delay(0.5, function()
				for i = 1, 5 do
					local color = Color3.fromHSV((281 + math.random() * 20) / 360, 0.6, 0.4)
					local num = math.random() * 0.5 + 0.75
					spawn(function()
						for i = 1, 2 do
							local num2 = math.random() * 360
							_p.Particles:new({
								Color = color, 
								Image = 243953162, 
								Lifetime = 0.4, 
								Size = 0.8 * num, 
								Position = targ2, 
								Velocity = 5 * (cf2 * Vector3.new(math.cos(math.rad(num2)), math.sin(math.rad(num2)), 0)), 
								Acceleration = false
							})
						end
					end)
					wait(0.06)
				end
			end)
			local pos = targ2 - targ
			Tween(0.7, nil, function(a)
				part.CFrame = CFrame.new(targ + pos * a + Vector3.new(0, 1.7 * math.sin(a * math.pi), 0))
			end)
			part:Destroy()
			return true
		end,

		headbutt = function(pokemon, targets)
			local target = targets[1] if not target then return end
			tackle(pokemon, target)
			return true -- perform usual hit anim
		end,

		slam = function(poke, targets)
			local target = targets[1] if not target then return end
			tackle(poke, target)
			return true -- perform usual hit anim
		end,

		psychic = function(poke, targets)
			local target = targets[1] if not target then return end
			local targ = targetPoint(poke)
			local targ2 = targetPoint(target)
			local pos = targ2 - targ
			for i = 1, 3 do
				spawn(function()
					local part = create("Part")({
						BrickColor = BrickColor.new("Pink"), 
						Reflectance = 0.5, 
						Anchored = true, 
						CanCollide = false, 
						Size = Vector3.new(1, 1, 1), 
						Parent = workspace
					})
					local mesh = create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://3270017", 
						Parent = part
					})
					Tween(0.8, nil, function(a)
						part.CFrame = CFrame.new(targ, targ2) + pos * a
						local v482 = 1.3 + 0.3 * math.sin(a * 8)
						mesh.Scale = Vector3.new(v482, v482, v482)
					end)
					part:Destroy()
				end)
				wait(0.2)
			end
			wait(0.6)
			return true
		end,

		skydrop = function(pokemon, targets, _, _, tMeta)
			local target = targets[1] if not target then return end
			local sprite = pokemon.sprite
			local tp = target.sprite.offset
			Tween(.5, 'easeOutQuart', function(a)
				target.sprite.offset = tp*(1-a)
			end)
			if tMeta then
				Utilities.sound(tMeta.soundId[target] or 114870577672963, .75, tMeta.effectiveness[target] == 1 and .5 or .6, 5)
				--			spawn(function()
				--				local sl = target.sprite.animation.spriteLabel
				--				for i = 1, 3 do
				--					wait(.03)
				--					sl.Visible = false
				--					wait(.03)
				--					sl.Visible = true
				--				end
				--			end)
			end
			spawn(function()
				Tween(1, 'easeOutCubic', function(a)
					sprite.offset = Vector3.new(0, 10*(1-a), 0)
				end)
			end)
		end,
		slash = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, nil, 3)
			return 'sound'
		end,
		solarbeam = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local from = targetPoint(pokemon, 2)
			local to = targetPoint(target)
			local dif = to-from

			local sun = create 'Part' {
				BrickColor = BrickColor.new('New Yeller'),
				Material = Enum.Material.Neon,
				Anchored = true,
				CanCollide = false,
				TopSurface = Enum.SurfaceType.Smooth,
				BottomSurface = Enum.SurfaceType.Smooth,
				Size = Vector3.new(4, 4, 4),
				Shape = Enum.PartType.Ball,
				CFrame = CFrame.new(pokemon.sprite.cf.p+Vector3.new(0, 7-(pokemon.sprite.spriteData.inAir or 0), 0)),
				Parent = workspace
			}
			Tween(1, nil, function(a)
				sun.Transparency = 1-a
			end)
			local blast = sun:Clone()
			blast.BrickColor = BrickColor.new('Bright green')
			blast.Size = Vector3.new(1, 1, 1)
			blast.CFrame = CFrame.new(from)
			blast.Parent = workspace
			local bmesh = create 'SpecialMesh' {
				MeshType = Enum.MeshType.Sphere,
				Parent = blast
			}
			local twoPi = math.pi*2
			local r = 4
			for i = 1, 20 do
				delay(.075*i, function()
					local beam = create 'Part' {
						Material = Enum.Material.Neon,
						BrickColor = BrickColor.new('Br. yellowish green'),
						Anchored = true,
						CanCollide = false,
						TopSurface = Enum.SurfaceType.Smooth,
						BottomSurface = Enum.SurfaceType.Smooth,
						Parent = workspace,
					}
					local transform = CFrame.Angles(twoPi*math.random(),twoPi*math.random(),twoPi*math.random()).lookVector * r
					local cf = CFrame.new(from)*transform
					Tween(.25, nil, function(a)
						beam.Size = Vector3.new(.2, .2, r*a)
						beam.CFrame = CFrame.new(cf + (from-cf)/2*a, cf)
					end)
					Tween(.25, nil, function(a)
						beam.Size = Vector3.new(.2, .2, r*(1-a))
						beam.CFrame = CFrame.new(cf + (from-cf)*(.5+.5*a), cf)
					end)
					beam:Destroy()
				end)
			end
			Tween(2, nil, function(a)
				bmesh.Scale = Vector3.new(2.3,2.3,2.3)*a
			end)
			wait(.2)
			local sbeam = blast:Clone()
			sbeam.Shape = Enum.PartType.Block--Cylinder
			sbeam.Parent = workspace
			local smesh = Instance.new('CylinderMesh', sbeam)
			local len = dif.magnitude
			Tween(.3, nil, function(a)
				sbeam.Size = Vector3.new(.8, len*a, .8)
				sbeam.CFrame = CFrame.new(from+dif*.5*a, to) * CFrame.Angles(math.pi/2, 0, 0)
				local s = (2.3-1.5*a)
				bmesh.Scale = Vector3.new(s,s,s)
				--			blast.CFrame = CFrame.new(from)
			end)
			spawn(function()
				--			local ss, sc = sbeam.Size, sbeam.CFrame
				local bs, bc = blast.Size, blast.CFrame
				Tween(.4, 'easeOutQuad', function(a)
					local o = 1-a
					smesh.Scale = Vector3.new(o,1,o)
					--sbeam.Size = ss*Vector3.new(1,o,o)
					--sbeam.CFrame = sc
					bmesh.Scale = Vector3.new(o,o,o)
					--				blast.Size = bs*o
					--				blast.CFrame = bc
				end)
				sbeam:Destroy()
				blast:Destroy()
				wait(.2)
				Tween(1, nil, function(a)
					sun.Transparency = a
				end)
				sun:Destroy()
			end)
			return true
		end,
		spikes = function(pokemon)
			spikes(pokemon)
		end,
		dracometeor = function(pokemon, targets, move)
			--[[local target = targets[1]
			if not target then
				return
			end
			local targetPoint = targetPoint(target)
			--local YourPoint = targetPoint(pokemon)
			local playerPart = pokemon.sprite.part
			local resetUnit = Vector3.new(1, 0, 1)
			local field = CFrame.new(playerPart.Position * resetUnit, targetPoint * resetUnit)
			local NeonBall = Utilities.Create("Part")({
				Anchored = true, 
				Shape = "Ball", 
				Material = "Neon", 
				Color = Color3.fromRGB(87, 87, 87), 
				CanCollide = false, 
				Size = Vector3.new(0.2, 0.2, 0.2), 
				Transparency = 1, 
				CFrame = CFrame.new(pokemon.sprite.cf.p + Vector3.new(0, playerPart.Size.Y / 2, 0), targetPoint)
			})
			NeonBall.Parent = move.scene
			local inAction = true
			local halfPoint = 0.5
			spawn(function()
				while inAction == true do
					local HitEffect2 = Misc.HitEffect2:Clone()
					HitEffect2.Color = Color3.fromRGB(208, 59, 9)
					HitEffect2.Material = "Neon"
					local groundPos = CFrame.Angles(math.pi / 2, 2 * math.pi * randomPoint:NextNumber(), 0)
					HitEffect2.CFrame = CFrame.new(NeonBall.Position) - Vector3.new(0, NeonBall.Size.Y / 2, 0)
					local Cframe = HitEffect2.CFrame
					HitEffect2.Parent = move.scene
					local landVector = Vector3.new(NeonBall.Size.X * 1.5, NeonBall.Size.X * 1.5, NeonBall.Size.X * 1.5)
					local landSize = landVector - Vector3.new(1, 0.2, 1)
					HitEffect2.Size = landVector
					moveUtil.Tween(TweenInfo.new(halfPoint), false, function(a)
						HitEffect2.Transparency = 0.5 + 0.5 * a
						HitEffect2.CFrame = NeonBall.CFrame * groundPos
					end)
					game.Debris:AddItem(HitEffect2, 0.5)
					wait(0.05)			
				end
			end)
			local NeonCF = NeonBall.CFrame
			local isMetal = false
			moveUtil.Tween(TweenInfo.new(1), true, function(a)
				NeonBall.CFrame = NeonCF + Vector3.new(0, 5 * a, 0) - field.lookVector * 2.5 * a
				local Size = 0.2 + 7.8 * a
				NeonBall.Size = Vector3.new(Size, Size, Size)
				if not isMetal and a > 0.5 then
					isMetal = true
					NeonBall.Material = "Metal"
				end
				NeonBall.Transparency = 1 - a
			end)
			halfPoint = halfPoint / 2
			local HitClone = Misc.HitEffect2:Clone()
			HitClone.Transparency = 0.5
			HitClone.Material = "Neon"
			HitClone.Color = Color3.fromRGB(179, 0, 0)
			HitClone.Size = Vector3.new(10, 10, 10)
			HitClone.CFrame = NeonBall.CFrame * CFrame.Angles(math.pi / 2, 0, 0) * CFrame.new(0, -NeonBall.Size.Y / 4, 0)
			HitClone.Parent = move.scene
			NeonCF = CFrame.new(NeonBall.Position, targetPoint)
			local TweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
			local VariablePoint = targetPoint - NeonBall.Position
			moveUtil.Tween(TweenInfo, false, function(a)
				NeonBall.CFrame = NeonCF + VariablePoint * a
				HitClone.Size = Vector3.new(10 - 8 * a, 10 + (VariablePoint.magnitude - 10) * a, 10 - 8 * a)
				HitClone.CFrame = NeonCF * CFrame.Angles(math.pi / 2, 0, 0) + VariablePoint / 2 * a
			end)
			wait(0.15)
			inAction = false
			coroutine.wrap(function()
				local HitClone2 = HitClone:Clone()
				HitClone2.CFrame = NeonBall.CFrame * CFrame.Angles(math.pi / 2, 0, 0)
				HitClone2.Size = Vector3.new(5, VariablePoint.magnitude, 5)
				HitClone2.Parent = move.scene
				--	u9("Explosion")
				moveUtil.ballExplosion(TweenInfo.new(1.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), CFrame.new(targetPoint), 24, Color3.fromRGB(141, 0, 0), Color3.fromRGB(255, 127, 42), "Neon", "Neon")
				Utilities.Tween(0.75, nil, function(a)
					HitClone.Transparency = 0.5 + 0.5 * a
					NeonBall.Transparency = a
					HitClone2.Size = Vector3.new(5 + 25 * a, VariablePoint.magnitude - VariablePoint.magnitude * a, 5 + 25 * a)
					HitClone.Size = Vector3.new(2 - 2 * a, VariablePoint.magnitude, 2 - 2 * a)
					HitClone2.Transparency = 0.5 + 0.5 * a
				end)
				HitClone:Destroy()
				NeonBall:Destroy()
				HitClone2:Destroy()
			end)]]
			return true
		end,
		fleurcannon = function(pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local distance = to - from
			local centerPoint = CFrame.new(from, to) * CFrame.new(0, 0, -1)
			local colors = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(248, 129, 60), Color3.fromRGB(255, 240, 17), Color3.fromRGB(0, 255, 0), Color3.fromRGB(9, 137, 207), Color3.fromRGB(71, 24, 158), Color3.fromRGB(152, 71, 177) }
			local parts = {}
			for indexColor, Color in pairs(colors) do
				local Part = Utilities.Create("Part")({
					Anchored = true, 
					CanCollide = false, 
					Shape = "Ball", 
					Size = Vector3.new(0.2, 0.2, 0.2), 
					Color = Color, 
					Material = "Neon", 
					Transparency = 1, 
					CFrame = centerPoint, 
					Parent = move.scene
				})
				local Attachment1 = Instance.new("Attachment", Part)
				Attachment1.Position = Vector3.new(0, 0.1, 0)
				local Attachment2 = Attachment1:Clone()
				Attachment2.Position = Vector3.new(0, -0.1, 0)
				Attachment2.Parent = Part
				local v2206 = Utilities.Create("Trail")({
					Color = ColorSequence.new(Color), 
					Transparency = NumberSequence.new(0, 1), 
					WidthScale = NumberSequence.new(1, 0), 
					Attachment0 = Attachment1, 
					Attachment1 = Attachment2, 
					Lifetime = 1, 
					LightEmission = 1, 
					Parent = Part
				})
				table.insert(parts, {
					part = Part, 
					pos = indexColor, 
					rot = 2 * math.pi * indexColor / #colors, 
					radius = 0
				})
			end
			local partTbl = parts
			local rotation = 2
			RunService:BindToRenderStep("rainbowblast", Enum.RenderPriority.Camera.Value - 1, function()
				for _, part in ipairs(partTbl) do
					part.rot = part.rot + math.rad(rotation)
					part.part.CFrame = centerPoint * CFrame.new(part.radius * math.cos(part.rot), part.radius * math.sin(part.rot), 0)
				end
			end)
			moveUtil.Tween(TweenInfo.new(0.5), true, function(a)
				local radius = 3 * a
				local Size = 0.1 + 0.4 * a
				rotation = 5 - 3 * a
				for _, part in ipairs(partTbl) do
					part.part.Transparency = 1 - a
					part.part.Size = Vector3.new(Size, Size, Size)
					part.radius = radius
				end
			end)
			moveUtil.Tween(TweenInfo.new(1), true, function(a)
				rotation = 2 + 4 * a
			end)
			RunService:UnbindFromRenderStep("rainbowblast")
			moveUtil.Tween(TweenInfo.new(0.05), true, function(a)
				local radius = 3 - 2.5 * a
				for _, part in ipairs(partTbl) do
					part.radius = radius
					part.part.CFrame = centerPoint * CFrame.new(part.radius * math.cos(part.rot), part.radius * math.sin(part.rot), 0)
				end
			end)
			for partIndexed = #partTbl, 1, -1 do
				partTbl[partIndexed].part:Destroy()
				table.remove(partTbl, partIndexed)
			end
			partTbl = {}
			rotation = 2
			local Attachment3 = Instance.new("Attachment", workspace.Terrain)
			Attachment3.WorldCFrame = centerPoint + distance
			local blastPart = Particles.Blast:Clone()
			blastPart.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
			blastPart.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 10), NumberSequenceKeypoint.new(1, 10) })
			blastPart.Lifetime = NumberRange.new(1)
			blastPart.Transparency = NumberSequence.new(0, 1)
			blastPart.RotSpeed = NumberRange.new(180)
			blastPart.Enabled = false
			blastPart.Parent = Attachment3
			for index, color in pairs(colors) do
				local halfSpiral = Misc.HalfSpiral:Clone()
				halfSpiral.Color = color
				halfSpiral.Size = Vector3.new(1, 1, 1)
				halfSpiral.CFrame = centerPoint * CFrame.Angles(math.pi / 2, index * math.pi / 4, 0)
				halfSpiral.Parent = move.scene
				local sparks = Particles.SparkV2:Clone()
				sparks.Color = ColorSequence.new(color)
				sparks.Speed = NumberRange.new(20, 30)
				sparks.Size = NumberSequence.new(0.25, 0.1)
				sparks.Enabled = false
				sparks.Acceleration = Vector3.new(0, 0, 0)
				sparks.Transparency = NumberSequence.new(0, 1)
				sparks.Parent = Attachment3
				table.insert(partTbl, {
					part = halfSpiral, 
					pos = index, 
					rot = index * math.pi / 4, 
					particle = sparks
				})
			end
			local NeonBall = Utilities.Create("Part")({
				Anchored = true, 
				CanCollide = false, 
				Material = "Neon", 
				Color = Color3.fromRGB(255, 255, 255), 
				Size = Vector3.new(1, 1, 1), 
				CFrame = centerPoint, 
				Shape = "Ball", 
				Parent = move.scene
			})
			local cp2 = centerPoint
			RunService:BindToRenderStep("rainbowblast2", Enum.RenderPriority.Camera.Value - 1, function()
				for _, part in ipairs(partTbl) do
					part.rot = part.rot + math.rad(rotation)
					part.part.CFrame = cp2 * CFrame.Angles(math.pi / 2, part.rot, 0)
				end
			end)
			--	u9("BigExplosion")
			local size = 1
			spawn(function()
				for unitIndex = 1, 7 do
					local thinRing = Misc.ThinRing:Clone()
					thinRing.Color = Color3.fromRGB(255, 255, 255)
					thinRing.CFrame = (centerPoint + distance * unitIndex / 7) * CFrame.Angles(math.pi / 2, 0, 0)
					thinRing.Size = Vector3.new(size, 0.1, size)
					thinRing.Parent = move.scene
					local sizeTo6 = 5 + size
					moveUtil.Tween(TweenInfo.new(0.1), false, function(a)
						thinRing.Size = Vector3.new(sizeTo6 + sizeTo6 * a, 0.1, sizeTo6 + sizeTo6 * a)
					end).Completed:Connect(function()
						thinRing:Destroy()
					end)
					wait()
				end
			end)
			local Attachment4 = Instance.new("Attachment", workspace.Terrain)
			Attachment4.WorldCFrame = centerPoint
			local clonedBlastPrt = blastPart:Clone()
			clonedBlastPrt.Parent = Attachment4
			clonedBlastPrt:Emit(1)
			local magnitude = distance.magnitude
			moveUtil.Tween(TweenInfo.new(0.1), true, function(a)
				cp2 = centerPoint + distance * a / 2
				rotation = 3 + 10 * a
				size = 1 + 5 * a
				NeonBall.Size = Vector3.new(size, size, size)
				for _, part in ipairs(partTbl) do
					part.part.Size = Vector3.new(size - 0.5, magnitude * a, size - 0.5)
				end
			end)
			local clonedNeonBall = NeonBall:Clone()
			clonedNeonBall.CFrame = centerPoint + distance
			clonedNeonBall.Size = Vector3.new(3, 3, 3)
			clonedNeonBall.Parent = move.scene
			local clonedThingRing = Misc.ThinRing:Clone()
			clonedThingRing.Color = Color3.fromRGB(255, 255, 255)
			clonedThingRing.Size = Vector3.new(3, 0.1, 3)
			clonedThingRing.Parent = move.scene
			local clonedHitEffect = Misc.HitEffect1:Clone()
			clonedHitEffect.Size = Vector3.new(6, 1, 6)
			clonedHitEffect.Color = Color3.fromRGB(255, 255, 255)
			clonedHitEffect.Parent = move.scene
			local ThingRing3 = clonedThingRing:Clone()
			ThingRing3.Parent = move.scene
			local NeonBall3 = clonedNeonBall:Clone()
			NeonBall3.Shape = "Cylinder"
			NeonBall3.CFrame = (centerPoint + distance / 2) * CFrame.Angles(math.pi / 2, 0, math.pi / 2)
			NeonBall3.Size = Vector3.new(magnitude + size / 2, 0.5, 0.5)
			NeonBall3.Parent = move.scene
			for _, part in pairs(partTbl) do
				part.particle:Emit(20)
				part.particle.Enabled = true
			end
			spawn(function()
				moveUtil.Tween(TweenInfo.new(0.2), true, function(a)
					local Size = 3 + 7 * a
					clonedNeonBall.Size = Vector3.new(Size, Size, Size)
				end)
				blastPart.Lifetime = NumberRange.new(1.5)
				blastPart.Transparency = NumberSequence.new(0, 1)
				blastPart.Size = NumberSequence.new(10, 30)
				spawn(function()
					for unitEmit = 1, 10 do
						blastPart:Emit(1)
						wait()
					end
				end)
				delay(1, function()
					for _, part in pairs(partTbl) do
						part.particle.Enabled = false
					end
				end)
				moveUtil.Tween(TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), true, function(a)
					local Size = 5 + 40 * a
					clonedThingRing.Size = Vector3.new(Size, 0.5, Size)
					ThingRing3.Size = Vector3.new(Size * 1.25, 0.5, Size * 1.25)
					clonedThingRing.Transparency = a
					ThingRing3.Transparency = a
					local Size2 = 10 + 15 * a
					clonedNeonBall.Size = Vector3.new(Size2, Size2, Size2)
					clonedHitEffect.Size = Vector3.new(6 + (Size - 11), 1 + 2 * a, 6 + (Size - 11))
					clonedHitEffect.Transparency = a
					clonedNeonBall.Transparency = a
					NeonBall.Transparency = a
					NeonBall3.Transparency = 1 - a
					for _, part in pairs(partTbl) do
						part.part.Size = Vector3.new(6 - 6 * a, magnitude, 6 - 6 * a)
					end
				end)
				for _, part in pairs(partTbl) do
					part.part.Transparency = 1
				end
				RunService:UnbindFromRenderStep("rainbowblast2")
				moveUtil.Tween(TweenInfo.new(0.5), true, function(a)
					NeonBall3.Transparency = a
					NeonBall3.Size = Vector3.new(magnitude + size / 2, 0.5 - 0.5 * a, 0.5 - 0.5 * a)
				end)
				NeonBall3:Destroy()
				game.Debris:AddItem(Attachment3, 1)
				Attachment4:Destroy()
				clonedThingRing:Destroy()
				ThingRing3:Destroy()
				NeonBall:Destroy()
				clonedHitEffect:Destroy()
				clonedNeonBall:Destroy()
				for _, part in pairs(partTbl) do
					part.part:Destroy()
				end
				partTbl = nil
			end)
			return true
		end,

		surf = 	function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local pos = CFrame.new(from, to)
			local dif = to - from
			local c1 = pos * CFrame.new(0, -13, 20)
			local c2 = pos + dif + dif.unit * 20
			local wave = storage.Models.Misc.WaveMesh:Clone()
			wave.Size = Vector3.new(12, 12, 20)
			wave.CFrame = c1 * CFrame.Angles(0, -math.pi / 2, 0)
			wave.Parent = move.scene
			local part = Instance.new("Part")
			part.Anchored = true
			part.Transparency = 1
			part.CanCollide = false
			part.CFrame = c1
			part.Size = Vector3.new(20, 2, 6)
			local Particles = storage.Models.Misc.Particles
			local splash = Particles.Splash:Clone()
			splash.Rate = 100
			splash.Speed = NumberRange.new(1, 4)
			splash.Acceleration = Vector3.new(0, -5, 0)
			splash.Parent = part
			part.Parent = move.scene
			local fun = 0
			local mag = dif.magnitude + 40
			spawn(function()
				local t = tick()
				local RunService = game:GetService('RunService')
				while tick() - t < 2.5 do
					local v = (tick() - t) / 2.5
					fun = math.sin(v * math.pi) * 13
					wave.CFrame = (c1 + dif.unit * mag * v + Vector3.new(0, fun, 0)) * CFrame.Angles(0, -math.pi / 2, 0)
					part.CFrame = (wave.CFrame + Vector3.new(0, -wave.Size.Y / 2 + part.Size.Y, 0)) * CFrame.Angles(0, math.pi / 2, 0) * CFrame.new(0, 0, -part.Size.Z / 2)
					RunService.Stepped:Wait()		
				end
				splash.Enabled = false
				delay(splash.Lifetime.Max, function()
					part:Destroy()
				end)
				wave:Destroy()
			end)
			wait(1.25)
			return true
		end, -- [pa, my fav anim surely]
		tackle = function(pokemon, targets)
			local target = targets[1] if not target then return end
			tackle(pokemon, target)
			return true -- perform usual hit anim
		end,
		teleport = function(pokemon)
			pcall(function()
				local part = pokemon.sprite.part
				local cf = part.CFrame
				local x = part.Size.X
				local y = part.Size.Y
				Tween(.3, nil, function(a)
					part.Size = Vector3.new(x*math.cos(a*math.pi/2), y*(1+math.sin(a*math.pi/2)*1.5), .2)
					part.CFrame = cf
				end)
				part:Destroy()
			end)
		end,
		thunderbolt = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			local cf = (target.sprite.part.CFrame-target.sprite.part.Position)+targetPoint(target, 0)
			local angles = {.3, -.3, 0}
			for i = 1, 3 do
				local p = create 'Part' {
					Anchored = true,
					CanCollide = false,
					Transparency = 1.0,
					Parent = workspace
				}
				local d = create 'Decal' {
					Texture = 'rbxassetid://650936735',
					Face = Enum.NormalId.Front,
					Parent = p
				}
				local d2 = create 'Decal' {
					Texture = 'rbxassetid://650936735',
					Face = Enum.NormalId.Front,
					Parent = p
				}
				local c = cf * CFrame.Angles(0, 0, angles[i])
				spawn(function()
					Tween(.25, 'easeOutCubic', function(a)
						p.Size = Vector3.new(2, 6*a, .2)
						p.CFrame = c * CFrame.new(0, 6-3*a, 0)
						if a > .8 then
							local t = (a-.8)*5
							d.Transparency = t
							d2.Transparency = t
						end
					end)
				end)
				wait(.16)
			end
			--		wait(.1)
			return true
		end,
		thunderfang = function(pokemon, targets)
			local target = targets[1] if not target then return true end
			Utilities.fastSpawn(function() bite(target, {326993171, 326993181, 326993188}) end)
			wait(.35)
			return 'sound'
		end,
		toxicspikes = function(pokemon)
			spikes(pokemon, 'ToxicSpikes', 'Mulberry')
		end,
		vinewhip = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Bright green')
			return 'sound'
		end,
		watergun = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local sprite = pokemon.sprite
			local s = targetPoint(pokemon, 2)
			local e = targetPoint(target, .5)
			local dp = e-s

			local cf = target.sprite.part.CFrame
			cf = cf-cf.p
			for n = 1, 7 do
				spawn(function()
					local p, _, i = cParticle(650846795, .65+math.random()*.05, Color3.fromHSV((180+math.random()*30)/360, .6, .9))
					i.Rotation = math.random(360)
					i.ImageTransparency = .1+.2*math.random()
					local offset = cf*(Vector3.new(math.random()-.5, math.random()-.5, 0)*.25)
					Tween(.5, nil, function(a)
						p.CFrame = CFrame.new(s + dp*a + offset)
					end)
					p:Destroy()
				end)
				wait(.03)
			end
			wait(.47)
			return true
		end,
		watershuriken = function(pokemon, targets)
			local target = targets[1] if not target then return end
			local s = create 'Part' {
				Anchored = true,
				CanCollide = false,
				BrickColor = BrickColor.new('Cyan'),
				Reflectance = .4,
				Transparency = .3,
				Size = Vector3.new(1, 1, 1),
				Parent = workspace,

				create 'SpecialMesh' {
					MeshType = Enum.MeshType.FileMesh,
					MeshId = 'rbxassetid://11376946',
					Scale = Vector3.new(1.6, 1.6, 1.6)
				}
			}
			local f = targetPoint(pokemon)
			local d = targetPoint(target)-f
			local cf = CFrame.new(f, f+d) * CFrame.Angles(0, 0, -.8)
			Tween(.5, nil, function(a)
				s.CFrame = (cf+d*a) * CFrame.Angles(0, -10*a, 0)
			end)
			s:Destroy()
			return true
		end,
		xscissor = function(pokemon, targets)
			local target = targets[1] if not target then return end
			cut(target, 'Br. yellowish green', 2)--'Moss'
			return 'sound'
		end,

		-- Z-Moves :
		
		bloomdoom = function(pokemon, targets, move)
			local pos1 = nil
			local pos2 = nil
			local target = targets[1]
			if not target then
				return
			end
			local sprite = pokemon.sprite
			local from = targetPoint(pokemon, 2)
			local to = targetPoint(target, 0.5)
			local part1 = create("Part")({
				Anchored = true, 
				CanCollide = false, 
				CFrame = move.CoordinateFrame2 + Vector3.new(0, -3, 0), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://20329976", 
					Scale = Vector3.new(0.2, 0.2, 0.2)
				})
			})
			local posi = sprite.part.Position
			local py = sprite.part.Size.Y / 2
			local scene = {}
			for i = 1, 6 do
				local part2 = create("Part")({
					Transparency = 1, 
					Anchored = true, 
					CanCollide = false, 
					Size = Vector3.new(1, 1, 1), 
					CFrame = CFrame.new(posi + Vector3.new(1.5 * math.cos(math.pi / 3 * i), py * 0.5, 1.5 * math.sin(math.pi / 3 * i)), posi + Vector3.new(0, py * 0.5, 0)), 
					Parent = workspace
				})
				create("Trail")({
					Attachment0 = create("Attachment")({
						CFrame = CFrame.new(-0.3, 0.3, -0.3), 
						Parent = part2
					}), 
					Attachment1 = create("Attachment")({
						CFrame = CFrame.new(0.3, -0.3, 0.3), 
						Parent = part2
					}), 
					Color = ColorSequence.new(Color3.fromRGB(58, 173, 98), Color3.fromRGB(154, 212, 174)), 
					Transparency = NumberSequence.new(0.5, 1), 
					Lifetime = 1, 
					Parent = part2
				})
				scene[i] = part2
			end
			spawn(function()
				Tween(1, nil, function(a)
					for ab, ba in pairs(scene) do
						local z1 = math.pi / 3 * ab + 5 * a
						local z2 = 1.5 + math.sin(a * math.pi)
						local z3 = posi + Vector3.new(z2 * math.cos(z1), py * (0.5 - a), z2 * math.sin(z1))
						ba.CFrame = CFrame.new(z3, Vector3.new(posi.x, z3.Y, posi.Z))
					end
				end)
			end)
			wait(0.3)
			local model = Instance.new("Model", workspace)
			local v1 = sprite.cf + Vector3.new(0, -(sprite.spriteData.inAir or 0), 0)
			local v2 = target.sprite.cf + Vector3.new(0, -(target.sprite.spriteData.inAir or 0), 0)
			local v0 = CFrame.new(v1.p, v2.p)
			local clr = { "Alder", "Carnation pink", "Persimmon", "Daisy orange", "Pastel Blue" }
			local z3ro = 12 - 1 --1 -1
			while true do
				local n3ber = nil
				for s = 1, 2 do
					pos1 = v0
					n3ber = z3ro
					pos2 = model
					spawn(function()
						local flower = _p.storage.Models.Misc.Flower:Clone()
						local main = flower.Main
						local clrc = BrickColor.new(clr[math.random(#clr)])
						for bc, cb in pairs(flower:GetChildren()) do
							if cb:IsA("BasePart") and cb ~= main then
								cb.BrickColor = clrc
							end
						end
						Utilities.MoveModel(main, pos1 * CFrame.Angles(0, -0.7 + 2.6 * math.random(), 0) * CFrame.new(0, 0, -n3ber * 1.2 + math.random()) * CFrame.Angles(0, math.random(), 0) + Vector3.new(0, 0.05, 0))
						flower.Parent = pos2
						local int = 1
						Tween(0.5, nil, function(b)
							local ps = 0.2 + 0.4 * b
							Utilities.ScaleModel(main, ps / int)
							int = ps
						end)
						flower:Destroy()
						main:Destroy()
					end)
				end
				wait(0.1)
				if 0 <= 1 then
					if not (n3ber < 10) then
						break
					end
				elseif not (n3ber > 10) then
					break
				end			
			end
			local part3 = create("Part")({
				BrickColor = BrickColor.new("Bright green"), 
				Material = Enum.Material.Neon, 
				Anchored = true, 
				CanCollide = false, 
				Shape = Enum.PartType.Cylinder, 
				Size = Vector3.new(15, 3, 3), 
				Parent = workspace
			})
			local _xy = CFrame.Angles(0, 0, math.pi / 2)
			Tween(1, nil, function(c)
				part3.CFrame = pos1 * _xy + Vector3.new(0, c * 30 - 15, 0)
			end)
			wait(1)
			part3.Size = Vector3.new(15, 6, 6)
			Tween(0.5, nil, function(d)
				part3.CFrame = v2 * _xy + Vector3.new(0, 22.5 - 15 * d, 0)
			end)
			local inner = _p.storage.Models.Misc.Mega.InnerEnergy:Clone()
			Utilities.ScaleModel(inner.Hinge, 0.35)
			local i_xy = inner.Hinge.CFrame * CFrame.Angles(0, 0, math.pi / 2):inverse() * inner.EnergyPart.CFrame
			local outer = _p.storage.Models.Misc.Mega.OuterEnergy:Clone()
			Utilities.ScaleModel(outer.Hinge, 0.35)
			inner.EnergyPart.BrickColor = BrickColor.new("Medium green")
			outer.EnergyPart.BrickColor = BrickColor.new("Sand green")
			inner.Parent = workspace
			outer.Parent = workspace
			local cc = workspace.CurrentCamera
			local cfr = cc.CFrame
			local v3 = Vector3.new(0, -1.5, 0)
			local c_f = outer.Hinge.CFrame * CFrame.Angles(0, 0, math.pi / 2):inverse() * outer.EnergyPart.CFrame
			spawn(function()
				Tween(3, nil, function(e)
					local r1 = math.random() * 0.5
					local r2 = math.random() * math.pi * 2
					cc.CFrame = cfr * CFrame.new(r1 * math.cos(r2), r1 * math.sin(r2), 0)
					inner.EnergyPart.CFrame = v2 * CFrame.Angles(0, 10 * e, 0) * i_xy + v3
					outer.EnergyPart.CFrame = v2 * CFrame.Angles(0, -10 * e, 0) * c_f + v3
				end)
			end)
			wait(2.5)
			Utilities.FadeOut(0.5, Color3.new(1, 1, 1))
			wait(0.3)
			cc.CFrame = cfr
			pos2:Destroy()
			for cd, dc in pairs(scene) do
				dc:Destroy()
			end
			part1:Destroy()
			inner:Destroy()
			outer:Destroy()
			part3:Destroy()
			Utilities.FadeIn(0.5)
			return true
		end,
		
		hydrovortex = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local sprite = pokemon.sprite
			local from = targetPoint(pokemon, 2)
			local to = targetPoint(target, 0.5)
			local pos1 = target.sprite.spriteData.inAir or 0
			local model = Instance.new("Model", workspace)
			_p.DataManager:preload("Image", 650846795)
			for ab, ba in pairs({ 165709404, 212966179, 1051557 }) do
				local part1 = create("Part")({
					Anchored = true, 
					CanCollide = false, 
					CFrame = move.CoordinateFrame2 + Vector3.new(0, -3, 0), 
					Parent = model,
					create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://" .. ba, 
						Scale = Vector3.new(0.2, 0.2, 0.2)
					})
				})
			end
			local cfr = target.sprite.part.CFrame
			local clr = BrickColor.new("Pastel Blue").Color
			local dif = to - from
			local cfp = cfr - cfr.p
			local function gui(a1)
				local part2 = create("Part")({
					Transparency = 1,
					Anchored = true, 
					CanCollide = false, 
					Parent = workspace
				})
				local bill = create("BillboardGui")({
					Parent = part2
				})
				return part2, bill, create("ImageLabel")({
					BackgroundTransparency = 1, 
					Image = "rbxassetid://".. a1,
					ZIndex = 2, 
					Parent = bill
				})
			end
			spawn(function()
				for i = 1, 50 do
					spawn(function()
						local bc, cb = gui(650846795, 1, Color3.fromHSV((210 + math.random() * 20) / 360, 0.8, 0.75))
						Tween(0.4, nil, function(a)
							bc.CFrame = CFrame.new(from + dif * a)
							cb.Size = UDim2.new(1 + 2 * a, 0, 1 + 2 * a, 0)
						end)
						bc:Destroy()
						for n = 1, 2 do
							local rdom = math.random() * 360
							_p.Particles:new({
								Color = clr, 
								Image = 650846795, 
								Lifetime = 0.5, 
								Size = 1, 
								Position = to, 
								Velocity = 5 * (cfp * Vector3.new(math.cos(math.rad(rdom)), math.sin(math.rad(rdom)), 0)), 
								Acceleration = false, 
								OnUpdate = function(ac, ca)
									ca.BillboardGui.ImageLabel.ImageTransparency = 0.3 + 0.7 * ac
								end
							})
						end
					end)
					wait(0.05)
				end
			end)
			wait(1.7)
			local part3 = create("Part")({
				BrickColor = BrickColor.new("Bright blue"), 
				Material = Enum.Material.Foil, 
				TopSurface = Enum.SurfaceType.Smooth, 
				BottomSurface = Enum.SurfaceType.Smooth, 
				CanCollide = false, 
				Anchored = true, 
				Size = Vector3.new(250, 50, 250), 
				Parent = workspace
			})
			local cfr2 = workspace.CurrentCamera.CFrame
			local cfr3 = CFrame.new((move.CoordinateFrame1.p + move.CoordinateFrame2.p) / 2) + Vector3.new(0, -10, 0)
			local v3c = Vector3.new(0, cfr2.y - cfr3.Y + 3, 0)
			local frame = create("Frame")({
				BorderSizePixel = 0, 
				BackgroundTransparency = 0.6, 
				BackgroundColor3 = part3.BrickColor.Color, 
				Size = UDim2.new(1, 0, 1, 36), 
				ZIndex = 10, 
				Parent = Utilities.frontGui
			})
			local view = cfr2.upVector.Y * 0.5 * math.tan(math.rad(workspace.CurrentCamera.FieldOfView) / 2)
			local v1 = cfr2.y + cfr2.lookVector.Y * 0.5 + view
			local v2 = view * 2
			Tween(1.6, nil, function(b)
				local camera = cfr3 + v3c * b
				part3.CFrame = camera + Vector3.new(0, -25, 0)
				local cam = math.max(0, (v1 - camera.y) / v2)
				frame.Position = UDim2.new(0, 0, cam, -36 * (1 - cam))
			end)
			if pos1 > 0 then
				Tween(1, nil, function(c)
					target.sprite.offset = Vector3.new(0, -pos1 * c, 0)
				end)
			end
			wait(0.5)
			local unt = dif * Vector3.new(1, 0, 1).unit
			local sp = sprite.spriteData.inAir or 0
			Tween(0.6, nil, function(c)
				sprite.offset = unt * -2 * c + Vector3.new(0, math.sin(c * math.pi) - sp * c, 0)
			end)
			local signal = Utilities.Signal()
			local y = sprite.part.Size.Y
			local part4 = create("Part")({
				BrickColor = BrickColor.new("Bright blue"), 
				Anchored = true, 
				CanCollide = false, 
				Size = Vector3.new(1, 1, 1), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://212966179", 
					Scale = Vector3.new(1.1, 1.8, 1.1) * y
				})
			})
			local part5 = create("Part")({
				BrickColor = BrickColor.new("Bright blue"), 
				Transparency = 0.5, 
				Anchored = true, 
				CanCollide = false, 
				Size = Vector3.new(1, 1, 1), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://165709404", 
					Scale = Vector3.new(2, 2, 2) * y
				})
			})
			local sf = sprite.cf.p + Vector3.new(0, y / 2, 0)
			local angle = CFrame.new(sf, sf + unt) * CFrame.Angles(-math.pi / 2, 0, 0)
			local an = angle * CFrame.new(0, -0.48 * y, 0) * CFrame.Angles(math.pi, 0, 0)
			local shift = false
			local magn = dif.magnitude
			local function storm()
				local part6 = create("Part")({
					BrickColor = BrickColor.new("Storm blue"), 
					Anchored = true, 
					CanCollide = false, 
					Size = Vector3.new(1, 1, 1), 
					Parent = workspace,
					create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://1051557", 
						Scale = Vector3.new(4, 4, 4)
					})
				})
				local part7 = part6:Clone()
				part7.Parent = workspace
				local look = target.sprite.cf + Vector3.new(0, 3 - pos1, 0) + workspace.CurrentCamera.CFrame.lookVector * -0.3
				Utilities.Tween(4, nil, function(o, p)
					if p < 0.7 then
						part6.Transparency = math.max(0, 1 - 2 * p)
						part7.Transparency = part6.Transparency
					elseif p > 3 then
						part6.Transparency = p - 3
						part7.Transparency = part6.Transparency
					end
					part6.CFrame = look * CFrame.Angles(0, -5 * p, 0)
					part7.CFrame = look * CFrame.Angles(0, -5 * p + 3.14, 0)
					target.sprite.offset = Vector3.new(0, 1 - math.cos(p * math.pi * 2) - pos1, 0)
					target.sprite.animation.spriteLabel.Rotation = 360 * p * 3
				end)
				part6:Destroy()
				part7:Destroy()
				signal:fire()
			end
			Tween(1, nil, function(q, r)
				local u1 = 70 * r * r - 2 + 5 * r
				local u2 = unt * u1 + Vector3.new(0, -sp, 0)
				sprite.offset = u2
				part4.CFrame = angle + u2
				part5.CFrame = an + u2
				local cal = math.min(1, r * 3)
				part4.Transparency = 1 - 0.2 * cal
				part5.Transparency = 1 - 0.5 * cal
				if not shift and magn <= u1 then
					shift = true
					spawn(storm)
				end
			end)
			part4:Destroy()
			part5:Destroy()
			signal:wait()
			model:Destroy()
			Tween(2, nil, function(f)
				local f1 = cfr3 + v3c * (1 - f)
				part3.CFrame = f1 + Vector3.new(0, -25, 0)
				local f2 = math.max(0, (v1 - f1.y) / v2)
				frame.Position = UDim2.new(0, 0, f2, -36 * (1 - f2))
				sprite.offset = Vector3.new(0, math.max(0, f1.y - sprite.cf.y), 0)
			end)
			part3:Destroy()
			frame:Destroy()
			if pos1 > 0 then
				spawn(function()
					Tween(0.5, nil, function(g)
						target.sprite.offset = Vector3.new(0, -pos1 * (1 - g), 0)
					end)
				end)
			end
			return true
		end, 

		infernooverdrive = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local sprite = pokemon.sprite
			local from = targetPoint(pokemon, 2)
			local to = targetPoint(target, 0.5) - from
			local model = Instance.new("Model", workspace)
			_p.DataManager:preload("Image", 879747500)
			for ab, ba in pairs({ 165709404, 212966179 }) do
				local part1 = create("Part")({
					Anchored = true, 
					CanCollide = false, 
					CFrame = move.CoordinateFrame2 + Vector3.new(0, -3, 0), 
					Parent = model,
					create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://" .. ba, 
						Scale = Vector3.new(0.3, 0.3, 0.3)
					})
				})
			end
			local cfr = target.sprite.part.CFrame
			local cfrp = cfr - cfr.p
			local scene = {}
			for i = 1, 6 do
				local part2 = create("Part")({
					Transparency = 1, 
					Anchored = true, 
					CanCollide = false, 
					Size = Vector3.new(1, 1, 1), 
					CFrame = cfrp * CFrame.Angles(0, 0, math.pi / 3 * i) * CFrame.new(0, 3, 0) + from, 
					Parent = workspace
				})
				create("Trail")({
					Attachment0 = create("Attachment")({
						CFrame = CFrame.new(-0.3, 0.3, -0.3), 
						Parent = part2
					}), 
					Attachment1 = create("Attachment")({
						CFrame = CFrame.new(0.3, -0.3, 0.3), 
						Parent = part2
					}), 
					Color = ColorSequence.new(Color3.new(0.329412, 0.764706, 0.898039), Color3.new(0.00392157, 0.486275, 1)), 
					Transparency = NumberSequence.new(0.5, 1), 
					Lifetime = 1, 
					Parent = part2
				})
				scene[i] = part2
			end
			local part3 = create("Part")({
				BrickColor = BrickColor.new("Bright orange"), 
				Material = Enum.Material.Neon, 
				Anchored = true, 
				CanCollide = false, 
				TopSurface = Enum.SurfaceType.Smooth, 
				BottomSurface = Enum.SurfaceType.Smooth, 
				Shape = Enum.PartType.Ball, 
				Parent = workspace
			})
			local y = sprite.part.Size.Y
			Tween(1, nil, function(a)
				part3.Size = Vector3.new(a, a, a) * y
				part3.CFrame = CFrame.new(from)
				for bc, cb in pairs(scene) do
					cb.CFrame = cfrp * CFrame.Angles(0, 0, math.pi / 3 * bc + 6 * a) * CFrame.new(0, 2 * (1 - a) + 1, 0) + from
				end
			end)
			local unt = to * Vector3.new(1, 0, 1).unit
			local air = sprite.spriteData.inAir or 0
			Tween(0.6, nil, function(b)
				sprite.offset = unt * -2 * b + Vector3.new(0, math.sin(b * math.pi) - air * b, 0)
			end)
			local air2 = target.sprite.spriteData.inAir or 0
			local y2 = target.sprite.part.Size.Y
			local signal = Utilities.Signal()
			local y3 = sprite.part.Size.Y
			local part4 = create("Part")({
				BrickColor = BrickColor.new("CGA brown"), 
				Anchored = true, 
				CanCollide = false, 
				Size = Vector3.new(1, 1, 1), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://212966179", 
					Scale = Vector3.new(1.1, 1.8, 1.1) * y3
				})
			})
			local part5 = create("Part")({
				BrickColor = BrickColor.new("CGA brown"), 
				Transparency = 0.5, 
				Anchored = true, 
				CanCollide = false, 
				Size = Vector3.new(1, 1, 1), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://165709404", 
					Scale = Vector3.new(2, 2, 2) * y3
				})
			})
			local v3c = sprite.cf.p + Vector3.new(0, y3 / 2, 0)
			local ang = CFrame.new(v3c, v3c + unt) * CFrame.Angles(-math.pi / 2, 0, 0)
			local pos = ang * CFrame.new(0, -0.48 * y3, 0) * CFrame.Angles(math.pi, 0, 0)
			local mve = false
			local magn = to.magnitude
			local function ball()
				local part6 = create("Part")({
					BrickColor = BrickColor.new("Bright orange"), 
					Material = Enum.Material.Neon, 
					Anchored = true, 
					CanCollide = false, 
					TopSurface = Enum.SurfaceType.Smooth, 
					BottomSurface = Enum.SurfaceType.Smooth, 
					Shape = Enum.PartType.Ball, 
					Parent = workspace
				})
				local npos = target.sprite.cf + Vector3.new(0, -air2, 0)
				spawn(function()
					local clr = BrickColor.new("Bright yellow").Color
					for n = 1, 10 do
						spawn(function()
							local pi1 = math.random() * math.pi * 2
							local pi2 = math.random() * math.pi / 2
							local fire = {
								Color = clr, 
								Image = 879747500, 
								Lifetime = 0.7, 
								Size = 1, 
								Position = npos.p + part6.Size.Y / 2 * Vector3.new(math.cos(pi1) * math.cos(pi2), math.sin(pi2), math.sin(pi1) * math.cos(pi2)), 
								Rotation = math.random() * 360
							}
							local o
							if math.random(2) == 1 then
								o = 1
							else
								o = -1
							end
							fire.RotVelocity = 100 * o
							fire.Acceleration = false
							function fire.OnUpdate(c, d)
								if c > 0.7 then
									d.BillboardGui.ImageLabel.ImageTransparency = 0.4 + 2 * (c - 0.7)
								end
							end
							_p.Particles:new(fire)
						end)
						wait(0.1)
					end
				end)
				local mx = math.max(7, y2 * 2)
				Tween(0.5, "easeOutCubic", function(e)
					target.sprite.offset = Vector3.new(0, -air2 * e, 0)
					local mxe = mx * e
					part6.Size = Vector3.new(mxe, mxe, mxe)
					part6.CFrame = npos
				end)
				spawn(function()
					Tween(0.5, nil, function(f)
						local mxf = mx + 0.5 * f
						part6.Size = Vector3.new(mxf, mxf, mxf)
						part6.CFrame = npos
					end)
					Tween(0.5, nil, function(g)
						local mxg = mx + 0.5 + 4 * g
						part6.Size = Vector3.new(mxg, mxg, mxg)
						part6.CFrame = npos
					end)
				end)
				local cc = workspace.CurrentCamera
				delay(0.5, function()
					Utilities.FadeOut(0.5, Color3.new(1, 1, 1))
				end)
				local cfcc = cc.CFrame
				Tween(1, nil, function(h)
					local r1 = math.random() * h * 0.5
					local r2 = math.random() * math.pi * 2
					cc.CFrame = cfcc * CFrame.new(r1 * math.cos(r2), r1 * math.sin(r2), 0)
				end)
				wait(0.3)
				part6:Destroy()
				cc.CFrame = cfcc
				signal:fire()
			end
			Tween(1, nil, function(qr, rq)
				local req = 70 * rq * rq - 2 + 5 * rq
				local ureq = unt * req + Vector3.new(0, -air, 0)
				sprite.offset = ureq
				part4.CFrame = ang + ureq
				part5.CFrame = pos + ureq
				local mrq = math.min(1, rq * 3)
				part4.Transparency = 1 - 0.2 * mrq
				part5.Transparency = 1 - 0.5 * mrq
				if req > 2 then
					part3.CFrame = CFrame.new(from + unt * (req - 2))
				end
				if not mve and magn <= req then
					mve = true
					spawn(ball)
				end
			end)
			model:Destroy()
			signal:wait()
			part3:Destroy()
			for dx, xd in pairs(scene) do
				xd:Destroy()
			end
			sprite.offset = Vector3.new()
			target.offset = Vector3.new()
			Utilities.FadeIn(0.5)
			return true
		end,

		gigavolthavoc = function (pokemon, targets, move)
			local target = targets[1]
			if not target then
				return
			end
			local sprite = pokemon.sprite
			local from = targetPoint(pokemon, 2)
			local to = targetPoint(target, 0.5) - from
			local model = Instance.new("Model", workspace)
			_p.DataManager:preload("Image", 879747500)
			for ab, ba in pairs({ 165709404, 212966179 }) do
				local part1 = create("Part")({
					Anchored = true, 
					CanCollide = false, 
					CFrame = move.CoordinateFrame2 + Vector3.new(0, -3, 0), 
					Parent = model,
					create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://" .. ba, 
						Scale = Vector3.new(0.3, 0.3, 0.3)
					})
				})
			end
			local cfr = target.sprite.part.CFrame
			local cfrp = cfr - cfr.p
			local scene = {}
			for i = 1, 6 do
				local part2 = create("Part")({
					Transparency = 1, 
					Anchored = true, 
					CanCollide = false, 
					Size = Vector3.new(1, 1, 1), 
					CFrame = cfrp * CFrame.Angles(0, 0, math.pi / 3 * i) * CFrame.new(0, 3, 0) + from, 
					Parent = workspace
				})
				create("Trail")({
					Attachment0 = create("Attachment")({
						CFrame = CFrame.new(-0.3, 0.3, -0.3), 
						Parent = part2
					}), 
					Attachment1 = create("Attachment")({
						CFrame = CFrame.new(0.3, -0.3, 0.3), 
						Parent = part2
					}), 
					Color = ColorSequence.new(Color3.new(0.752941, 0.917647, 0.027451), Color3.new(0.00392157, 0.486275, 1)), 
					Transparency = NumberSequence.new(0.5, 1), 
					Lifetime = 1, 
					Parent = part2
				})
				scene[i] = part2
			end
			local part3 = create("Part")({
				BrickColor = BrickColor.new("Bright orange"), 
				Material = Enum.Material.Neon, 
				Anchored = true, 
				CanCollide = false, 
				TopSurface = Enum.SurfaceType.Smooth, 
				BottomSurface = Enum.SurfaceType.Smooth, 
				Shape = Enum.PartType.Ball, 
				Parent = workspace
			})
			local y = sprite.part.Size.Y
			Tween(1, nil, function(a)
				part3.Size = Vector3.new(a, a, a) * y
				part3.CFrame = CFrame.new(from)
				for bc, cb in pairs(scene) do
					cb.CFrame = cfrp * CFrame.Angles(0, 0, math.pi / 3 * bc + 6 * a) * CFrame.new(0, 2 * (1 - a) + 1, 0) + from
				end
			end)
			local unt = to * Vector3.new(1, 0, 1).unit
			local air = sprite.spriteData.inAir or 0
			Tween(0.6, nil, function(b)
				sprite.offset = unt * -2 * b + Vector3.new(0, math.sin(b * math.pi) - air * b, 0)
			end)
			local air2 = target.sprite.spriteData.inAir or 0
			local y2 = target.sprite.part.Size.Y
			local signal = Utilities.Signal()
			local y3 = sprite.part.Size.Y
			local part4 = create("Part")({
				BrickColor = BrickColor.new("CGA brown"), 
				Anchored = true, 
				CanCollide = false, 
				Size = Vector3.new(1, 1, 1), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://212966179", 
					Scale = Vector3.new(1.1, 1.8, 1.1) * y3
				})
			})
			local part5 = create("Part")({
				BrickColor = BrickColor.new("CGA brown"), 
				Transparency = 0.5, 
				Anchored = true, 
				CanCollide = false, 
				Size = Vector3.new(1, 1, 1), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://165709404", 
					Scale = Vector3.new(2, 2, 2) * y3
				})
			})
			local v3c = sprite.cf.p + Vector3.new(0, y3 / 2, 0)
			local ang = CFrame.new(v3c, v3c + unt) * CFrame.Angles(-math.pi / 2, 0, 0)
			local pos = ang * CFrame.new(0, -0.48 * y3, 0) * CFrame.Angles(math.pi, 0, 0)
			local mve = false
			local magn = to.magnitude
			local function ball()
				local part6 = create("Part")({
					BrickColor = BrickColor.new("Gold"), 
					Material = Enum.Material.Neon, 
					Anchored = true, 
					CanCollide = false, 
					TopSurface = Enum.SurfaceType.Smooth, 
					BottomSurface = Enum.SurfaceType.Smooth, 
					Shape = Enum.PartType.Ball, 
					Parent = workspace
				})
				local npos = target.sprite.cf + Vector3.new(0, -air2, 0)
				spawn(function()
					local clr = BrickColor.new("Bright yellow").Color
					for n = 1, 10 do
						spawn(function()
							local pi1 = math.random() * math.pi * 2
							local pi2 = math.random() * math.pi / 2
							local fire = {
								Color = clr, 
								Image = 879747500, 
								Lifetime = 0.7, 
								Size = 1, 
								Position = npos.p + part6.Size.Y / 2 * Vector3.new(math.cos(pi1) * math.cos(pi2), math.sin(pi2), math.sin(pi1) * math.cos(pi2)), 
								Rotation = math.random() * 360
							}
							local o
							if math.random(2) == 1 then
								o = 1
							else
								o = -1
							end
							fire.RotVelocity = 100 * o
							fire.Acceleration = false
							function fire.OnUpdate(c, d)
								if c > 0.7 then
									d.BillboardGui.ImageLabel.ImageTransparency = 0.4 + 2 * (c - 0.7)
								end
							end
							_p.Particles:new(fire)
						end)
						wait(0.1)
					end
				end)
				local mx = math.max(7, y2 * 2)
				Tween(0.5, "easeOutCubic", function(e)
					target.sprite.offset = Vector3.new(0, -air2 * e, 0)
					local mxe = mx * e
					part6.Size = Vector3.new(mxe, mxe, mxe)
					part6.CFrame = npos
				end)
				spawn(function()
					Tween(0.5, nil, function(f)
						local mxf = mx + 0.5 * f
						part6.Size = Vector3.new(mxf, mxf, mxf)
						part6.CFrame = npos
					end)
					Tween(0.5, nil, function(g)
						local mxg = mx + 0.5 + 4 * g
						part6.Size = Vector3.new(mxg, mxg, mxg)
						part6.CFrame = npos
					end)
				end)
				local cc = workspace.CurrentCamera
				delay(0.5, function()
					Utilities.FadeOut(0.5, Color3.new(1, 1, 1))
				end)
				local cfcc = cc.CFrame
				Tween(1, nil, function(h)
					local r1 = math.random() * h * 0.5
					local r2 = math.random() * math.pi * 2
					cc.CFrame = cfcc * CFrame.new(r1 * math.cos(r2), r1 * math.sin(r2), 0)
				end)
				wait(0.3)
				part6:Destroy()
				cc.CFrame = cfcc
				signal:fire()
			end
			Tween(1, nil, function(qr, rq)
				local req = 70 * rq * rq - 2 + 5 * rq
				local ureq = unt * req + Vector3.new(0, -air, 0)
				sprite.offset = ureq
				part4.CFrame = ang + ureq
				part5.CFrame = pos + ureq
				local mrq = math.min(1, rq * 3)
				part4.Transparency = 1 - 0.2 * mrq
				part5.Transparency = 1 - 0.5 * mrq
				if req > 2 then
					part3.CFrame = CFrame.new(from + unt * (req - 2))
				end
				if not mve and magn <= req then
					mve = true
					spawn(ball)
				end
			end)
			model:Destroy()
			signal:wait()
			part3:Destroy()
			for dx, xd in pairs(scene) do
				xd:Destroy()
			end
			sprite.offset = Vector3.new()
			target.offset = Vector3.new()
			Utilities.FadeIn(0.5)
			return true
		end,

		devastatingdrake = function(pokemon, targets, move)
			local target = targets[1]
			if not target then
				return true
			end
			local dif = targetPoint(target) - targetPoint(pokemon)
			local cfr = target.sprite.part.CFrame
			local cfp = cfr - cfr.p
			local sprite = pokemon.sprite
			if sprite.spriteData.inAir then
			end
			local tair = target.sprite.spriteData.inAir or 0
			_p.DataManager:preload("Image", 148101819, 879747500)
			local model = Instance.new("Model", workspace)
			local scene = {}
			for ab, ba in pairs({ { 94257616, "Head" }, { 94257586, "Body" }, { 94257664, "RWing" }, { 94257635, "LWing" } }) do
				scene[ba[2]] = create("Part")({
					Anchored = true, 
					CanCollide = false, 
					CFrame = move.CoordinateFrame2 + Vector3.new(0, -4, 0), 
					Parent = model,
					create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://" .. ba[1], 
						TextureId = "rbxassetid://94257533", 
						Scale = Vector3.new(1.2, 1.2, 1.2), 
						VertexColor = Vector3.new(1, 0.5, 1)
					})
				})
			end
			local cf1 = CFrame.new(0, -0.272, 1, 1, 0, 0, 0, 0.928, 0.372, 0, -0.372, 0.928)
			local cf2 = CFrame.new(0, 0.686, -1.786, 1, 0, 0, 0, 0.931, -0.364, 0, 0.364, 0.931)
			local cf3 = CFrame.new(0.164, 0.427, -0.919, 1, 0, 0, 0, 0.941, -0.339, 0, 0.339, 0.941)
			local cf4 = CFrame.new(-0.164, 0.427, -0.919, 1, 0, 0, 0, 0.941, -0.339, 0, 0.339, 0.941)
			local cf5 = CFrame.new(1.314, 0.587, -0.25, 1, 0, 0, 0, 0.819, 0.574, 0, -0.574, 0.819)
			local cf6 = CFrame.new(-1.314, 0.587, -0.25, 1, 0, 0, 0, 0.819, 0.574, 0, -0.574, 0.819)
			local scene2 = {}
			for i = 1, 6 do
				local part1 = create("Part")({
					Transparency = 1, 
					Anchored = true, 
					CanCollide = false, 
					Size = Vector3.new(1, 1, 1), 
					Parent = workspace
				})
				create("Trail")({
					Attachment0 = create("Attachment")({
						CFrame = CFrame.new(-0.3, 0.3, -0.3), 
						Parent = part1
					}), 
					Attachment1 = create("Attachment")({
						CFrame = CFrame.new(0.3, -0.3, 0.3), 
						Parent = part1
					}), 
					Color = ColorSequence.new(Color3.fromRGB(174, 59, 197), Color3.fromRGB(252, 96, 255)), 
					Transparency = NumberSequence.new(0.5, 1), 
					Lifetime = 1, 
					Parent = part1
				})
				scene2[i] = part1
			end
			local Position = sprite.part.Position
			local y = sprite.part.Size.Y
			Tween(1, nil, function(a)
				for bc, cb in pairs(scene2) do
					local bca = math.pi / 3 * bc + 5 * a
					local npos = Position + Vector3.new(2 * math.cos(bca), y * (0.5 - a), 2 * math.sin(bca))
					cb.CFrame = CFrame.new(npos, Vector3.new(Position.x, npos.Y, Position.Z))
				end
			end)
			create("ParticleEmitter")({
				Texture = "rbxassetid://148101819", 
				Color = ColorSequence.new(Color3.fromRGB(194, 135, 216)), 
				Transparency = NumberSequence.new(0.5, 1), 
				Size = NumberSequence.new(0.25), 
				Acceleration = Vector3.new(), 
				LockedToPart = false, 
				Lifetime = NumberRange.new(1), 
				Rate = 50, 
				Rotation = NumberRange.new(0, 360), 
				Speed = NumberRange.new(0), 
				Parent = scene.Body
			})
			local cfn1 = CFrame.new()
			local cfn2 = CFrame.new()
			local cfn3 = CFrame.new()
			local unt = (sprite.part.Position - target.sprite.part.Position) * Vector3.new(1, 0, 1).unit
			local v3c = Vector3.new(0, -1, 0)
			local cros = unt:Cross(v3c)
			local ppo = sprite.part.Position
			local epic = CFrame.new(ppo.X, ppo.Y, ppo.Z, cros.X, unt.X, v3c.X, cros.Y, unt.Y, v3c.Y, cros.Z, unt.Z, v3c.Z)
			local function dragon()
				local cnf = cfn1 * cf1
				scene.Body.CFrame = cnf
				scene.Head.CFrame = cnf * cf2
				scene.RWing.CFrame = cnf * cf3 * cfn2 * cf5
				scene.LWing.CFrame = cnf * cf4 * cfn3 * cf6
			end
			Tween(0.7, nil, function(b)
				cfn1 = epic + Vector3.new(0, 10 * b, 0)
				dragon()
			end)
			wait(0.5)
			local ptpo = (sprite.part.Position + target.sprite.part.Position) / 2
			local ptpy = ptpo + Vector3.new(0, move.CoordinateFrame2.y + 2.5 - ptpo.Y, 0)
			local ang1 = CFrame.Angles(0, -1.4, 0) * CFrame.Angles(-1.1, 0, 0)
			local ang2 = CFrame.Angles(0, 1.4, 0) * CFrame.Angles(-1.1, 0, 0)
			cfn2 = ang1
			cfn3 = ang2
			local s1 = select(2, Utilities.lerpCFrame(ang1, CFrame.new()))
			local s2 = select(2, Utilities.lerpCFrame(ang2, CFrame.new()))
			local timing = Utilities.Timing.easeOutCubic(0.2)
			Tween(0.9, nil, function(c)
				local ch = math.pi * c
				local sch = math.sin(ch)
				local cch = math.cos(ch)
				local psch = ptpy - cros * (8 * cch - 4) + Vector3.new(0, 6 * (1 - sch), 0)
				local crch = cros * sch + Vector3.new(0, -cch, 0).unit
				local crcr = unt:Cross(crch)
				cfn1 = CFrame.new(psch.X, psch.Y, psch.Z, unt.X, crcr.X, -crch.X, unt.Y, crcr.Y, -crch.Y, unt.Z, crcr.Z, -crch.Z)
				if c > 0.3 then
					if c < 0.6 then
						local cx03 = (c - 0.3) / 0.3
						cfn2 = s1(cx03)
						cfn3 = s2(cx03)
					elseif c < 0.8 then
						local tc16 = 1 - timing(c - 0.6)
						cfn2 = s1(tc16)
						cfn3 = s2(tc16)
					else
						cfn2 = ang1
						cfn3 = ang2
					end
				end
				dragon()
			end)
			cfn2 = ang1
			cfn3 = ang2
			wait(0.5)
			local psti = target.sprite.part.Position
			epic = CFrame.new(psti.X, psti.Y, psti.Z, cros.X, -unt.X, -v3c.X, cros.Y, -unt.Y, -v3c.Y, cros.Z, -unt.Z, -v3c.Z)
			spawn(function()
				Tween(0.6, nil, function(d)
					cfn1 = epic * CFrame.Angles(0, 0, 7 * d) + Vector3.new(0, 10 - 16 * d, 0)
					dragon()
				end)
			end)
			wait(0.5)
			local part2 = create("Part")({
				BrickColor = BrickColor.new("Alder"), 
				Material = Enum.Material.Neon, 
				Anchored = true, 
				CanCollide = false, 
				TopSurface = Enum.SurfaceType.Smooth, 
				BottomSurface = Enum.SurfaceType.Smooth, 
				Shape = Enum.PartType.Ball, 
				Parent = workspace
			})
			local tvar = target.sprite.cf + Vector3.new(0, -tair, 0)
			spawn(function()
				local clr = BrickColor.new("Lilac").Color
				for n = 1, 10 do
					spawn(function()
						local r1 = math.random() * math.pi * 2
						local r2 = math.random() * math.pi / 2
						local image = {
							Color = clr, 
							Image = 879747500, 
							Lifetime = 0.7, 
							Size = 1, 
							Position = tvar.p + part2.Size.Y / 2 * Vector3.new(math.cos(r1) * math.cos(r2), math.sin(r2), math.sin(r1) * math.cos(r2)), 
							Rotation = math.random() * 360
						}
						local val
						if math.random(2) == 1 then
							val = 1
						else
							val = -1
						end
						image.RotVelocity = 100 * val
						image.Acceleration = false
						function image.OnUpdate(df, fd)
							if df > 0.7 then
								fd.BillboardGui.ImageLabel.ImageTransparency = 0.4 + 2 * (df - 0.7)
							end
						end
						_p.Particles:new(image)
					end)
					wait(0.1)
				end
			end)
			local tsy = math.max(7, target.sprite.part.Size.Y * 2)
			Tween(0.5, "easeOutCubic", function(s)
				target.sprite.offset = Vector3.new(0, -tair * s, 0)
				local ts2y = tsy * s
				part2.Size = Vector3.new(ts2y, ts2y, ts2y)
				part2.CFrame = tvar
			end)
			spawn(function()
				Tween(0.5, nil, function(t)
					local ttsy = tsy + 0.5 * t
					part2.Size = Vector3.new(ttsy, ttsy, ttsy)
					part2.CFrame = tvar
				end)
				Tween(0.5, nil, function(q)
					local tsyq = tsy + 0.5 + 4 * q
					part2.Size = Vector3.new(tsyq, tsyq, tsyq)
					part2.CFrame = tvar
				end)
			end)
			local cc = workspace.CurrentCamera
			delay(0.5, function()
				Utilities.FadeOut(0.5, Color3.new(1, 1, 1))
			end)
			local cfcc = cc.CFrame
			Tween(1, nil, function(p)
				local rp1 = math.random() * p * 0.5
				local rp2 = math.random() * math.pi * 2
				cc.CFrame = cfcc * CFrame.new(rp1 * math.cos(rp2), rp1 * math.sin(rp2), 0)
			end)
			wait(0.3)
			part2:Destroy()
			cc.CFrame = cfcc
			model:Destroy()
			for xx, xy in pairs(scene2) do
				xy:Destroy()
			end
			Utilities.FadeIn(0.5)
			return true
		end,

		savagespinout = function(pokemon, targets, move)
			local scene = nil
			local target = targets[1]
			if not target then
				return true
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local dif = to - from
			local cfr = target.sprite.part.CFrame
			local cfp = cfr - cfr.p
			local sprite = pokemon.sprite
			local part1 = create("Part")({
				Anchored = true, 
				CanCollide = false, 
				CFrame = move.CoordinateFrame2 + Vector3.new(0, -3, 0), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://928522767", 
					TextureId = "rbxassetid://928525574", 
					Scale = Vector3.new(0.02, 0.02, 0.02)
				})
			})
			local part2 = create("Part")({
				Anchored = true, 
				CanCollide = false, 
				CFrame = part1.CFrame, 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://1290033", 
					Scale = Vector3.new(0.2, 0.2, 0.2)
				})
			})
			local vn = Vector3.new()
			local tair = target.sprite.spriteData.inAir or 0
			spawn(function()
				Tween(0.78, nil, function(a)
					vn = Vector3.new(0, -tair * a, 0)
					target.sprite.offset = vn
				end)
			end)
			for i = 1, 15 do
				scene = from
				spawn(function()
					local tcp = to + cfp * Vector3.new((math.random() - 0.5) * target.sprite.part.Size.X, (math.random() - 0.5) * target.sprite.part.Size.Y, 0) + vn
					local magn = (tcp - scene).magnitude
					local part3 = create("Part")({
						Anchored = true, 
						CanCollide = false, 
						BrickColor = BrickColor.new("Pearl"), 
						TopSurface = Enum.SurfaceType.Smooth, 
						BottomSurface = Enum.SurfaceType.Smooth, 
						Parent = workspace
					})
					local sct = CFrame.new(scene, tcp)
					local nma = magn + 2.6
					Tween(0.5, nil, function(b)
						local nmb = nma * b
						if magn < nmb then
							part3.Size = Vector3.new(0.05, 0.05, nma - nmb)
							part3.CFrame = sct * CFrame.new(0, 0, -magn - (nma - nmb) / 2)
							return
						end
						if nmb < 2.6 then
							part3.Size = Vector3.new(0.05, 0.05, nmb)
							part3.CFrame = sct * CFrame.new(0, 0, nmb / -2)
							return
						end
						part3.Size = Vector3.new(0.05, 0.05, 2.6)
						part3.CFrame = sct * CFrame.new(0, 0, -nmb + 1)
					end)
					part3:Destroy()
				end)
				wait(0.06)
			end
			part1.CFrame = target.sprite.part.CFrame
			Tween(0.6, nil, function(c)
				local c3 = 0.05 * c
				part1.Mesh.Scale = Vector3.new(c3, c3, c3)
			end)
			local spriteLabel = target.sprite.animation.spriteLabel
			Tween(0.3, nil, function(d)
				local de = 1 - d * 0.55
				spriteLabel.Size = UDim2.new(de, 0, de, 0)
				spriteLabel.Position = UDim2.new(0.5 - de / 2, 0, 0.5 - de / 2, 0)
			end)
			spriteLabel.Visible = false
			local Position = part1.Position
			local ps = Position - scene
			local part4 = create("Part")({
				Anchored = true, 
				CanCollide = false, 
				BrickColor = BrickColor.new("Pearl"), 
				TopSurface = Enum.SurfaceType.Smooth, 
				BottomSurface = Enum.SurfaceType.Smooth, 
				Parent = workspace
			})
			local pmag = ps.magnitude
			local csp = CFrame.new(scene, Position)
			Tween(0.4, nil, function(e)
				part4.Size = Vector3.new(0.2, 0.2, pmag * e)
				part4.CFrame = csp + ps * e * 0.5
			end)
			local pcf = CFrame.new(Position, Position + ps):inverse() * part1.CFrame
			spawn(function()
				local scene2 = {}
				for n = 1, 5 do
					scene2[n] = part4:Clone()
					scene2[n].Parent = workspace
				end
				scene2[6] = part4
				local function bug(f)
					local posi = part1.Position
					local psc = (posi - scene).magnitude
					local show = scene
					local spcf = CFrame.new(scene, posi)
					local upVec = spcf.upVector
					local lookVec = spcf.lookVector
					for ab, ba in pairs(scene2) do
						local sVec = scene + lookVec * psc / 6 * ab + upVec * f * math.sin(math.pi / 6 * ab)
						ba.Size = Vector3.new(0.2, 0.2, (show - sVec).magnitude)
						ba.CFrame = CFrame.new((show + sVec) / 2, sVec)
						show = sVec
					end
				end
				Tween(0.5, nil, function(g)
					bug(g)
				end)
				Tween(0.7, nil, function(h)
					bug(1 - 2 * h)
				end)
				Tween(0.4, nil, function(t)
					bug(-1 + t)
				end)
				for bc, cb in pairs(scene2) do
					cb:Destroy()
				end
			end)
			wait(0.4)
			Tween(0.8, "easeInOutQuad", function(m)
				part1.CFrame = csp * CFrame.Angles(1.2 * m, 0, 0) * CFrame.new(0, 0, -pmag) * pcf
			end)
			Tween(0.4, "easeInQuad", function(n)
				part1.CFrame = csp * CFrame.Angles(1.2 * (1 - n), 0, 0) * CFrame.new(0, 0, -pmag) * pcf
			end)
			local model = create("Model")({
				Parent = workspace
			})
			for s = 1, 12 do
				local part5 = create("Part")({
					Anchored = true, 
					CanCollide = false, 
					BrickColor = BrickColor.new("Dirt brown"), 
					CFrame = move.CoordinateFrame2 * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6) + Vector3.new((1.2 + 0.3 * math.random()) * math.sin(0.53 * s), -0.3, (1.2 + 0.3 * math.random()) * math.cos(0.53 * s)), 
					Parent = model,
					create("SpecialMesh")({
						MeshType = Enum.MeshType.FileMesh, 
						MeshId = "rbxassetid://1290033", 
						Scale = Vector3.new(0.8, 0.8, 0.8)
					})
				})
			end
			spawn(function()
				local cc = workspace.CurrentCamera
				local cfc = cc.CFrame
				Tween(1, nil, function(z)
					local z1 = z * 10 % 1
					local z2 
					if z1 < 0.25 then
						z2 = -z1 * 4
					elseif z1 < 0.75 then
						z2 = -1 + (z1 - 0.25) * 4
					else
						z2 = 1 - (z1 - 0.75) * 4
					end
				end)
			end)
			local unt = dif * Vector3.new(1, 0, 1).unit
			local air = sprite.spriteData.inAir or 0
			Tween(0.6, nil, function(l)
				sprite.offset = unt * -2 * l + Vector3.new(0, math.sin(l * math.pi) - air * l, 0)
			end)
			local signal = Utilities.Signal()
			local mve = false
			local dmag = dif.magnitude
			local function pist()
				signal:fire()
				local crcf = CFrame.new(part1.Position, part1.Position + unt:Cross(Vector3.new(0, 1, 0)))
				local inv = crcf:inverse() * part1.CFrame
				Tween(0.6, nil, function(x)
					if not part1.Parent then
						return false
					end
					part1.CFrame = crcf * CFrame.Angles(0, 0, 10 * x) * inv + unt * x * 30 + Vector3.new(0, x * 12, 0)
				end)
			end
			spawn(function()
				Tween(1, nil, function(xx, xy)
					if not part1.Parent then
						return false
					end
					local v100 = 70 * xy * xy - 2 + 5 * xy
					sprite.offset = unt * v100 + Vector3.new(0, -air, 0)
					if not mve and dmag <= v100 then
						mve = true
						spawn(pist)
					end
				end)
			end)
			signal:wait()
			Utilities.FadeOut(0.5, Color3.new(1, 1, 1))
			model:Destroy()
			part1:Destroy()
			spriteLabel.Size = UDim2.new(1, 0, 1, 0)
			spriteLabel.Position = UDim2.new(0, 0, 0, 0)
			spriteLabel.Visible = true
			sprite.offset = Vector3.new()
			target.sprite.offset = Vector3.new()
			Utilities.FadeIn(0.5)
			return true
		end, 

		subzeroslammer = function(pokemon, targets, move)
			local scene = nil
			local target = targets[1]
			if not target then
				return true
			end
			local from = targetPoint(pokemon)
			local to = targetPoint(target)
			local dif = to - from
			local cfr = target.sprite.part.CFrame
			local cfp = cfr - cfr.p
			local sprite = pokemon.sprite
			local part1 = create("Part")({
				Anchored = true, 
				CanCollide = false, 
				CFrame = move.CoordinateFrame2 + Vector3.new(0, -3, 0), 
				Parent = workspace,
				create("SpecialMesh")({
					MeshType = Enum.MeshType.FileMesh, 
					MeshId = "rbxassetid://818652045", 
					Scale = Vector3.new(0.05, 0.05, 0.05)
				})
			})
			local Lighting = game:GetService("Lighting")
			local Ambient = Lighting.Ambient
			local OutdoorAmbient = Lighting.OutdoorAmbient
			local ColorShiftBottom = Lighting.ColorShift_Bottom
			local ColorShiftTop = Lighting.ColorShift_Top
			local FogEnd = Lighting.FogEnd
			local FogStart = Lighting.FogStart
			local cc = workspace.CurrentCamera
			local wspf = cc:WorldToScreenPoint(from)
			local wspt = cc:WorldToScreenPoint(to)
			local apos = math.deg(math.atan2(wspt.Y - wspf.Y, wspt.X - wspf.X)) + 90
			for i = 1, 30 do
				local r1 = math.random() * 0.5 + 0.75
				local r2 = Color3.fromHSV(0.55 + 0.08 * math.random(), 0.5 + math.random() * 0.25, 1)
				local image = {
					Color = r2, 
					Image = 644323665, 
					Lifetime = 0.4, 
					Rotation = apos
				}
				scene = dif
				local r3 = cfp * (0.25 * Vector3.new(math.random() - 0.5, math.random() - 0.5, 0))
				function image.OnUpdate(ab, ba)
					ba.CFrame = CFrame.new(from + scene * ab + r3)
					local rot = (ab < 0.2 and ab * 5 or 1) * r1
					ba.BillboardGui.Size = UDim2.new(rot, 0, rot, 0)
				end
				_p.Particles:new(image)
				delay(0.4, function()
					for n = 1, 2 do
						local angr = math.random() * 360
						_p.Particles:new({
							Color = r2, 
							Image = 644161227, 
							Lifetime = 0.7, 
							Rotation = angr + 90, 
							Size = 0.4 * r1, 
							Position = to, 
							Velocity = 5 * (cfp * Vector3.new(math.cos(math.rad(angr)), math.sin(math.rad(angr)), 0)), 
							Acceleration = false
						})
					end
				end)
				wait(0.035)
			end
			local npos = target.sprite.cf + Vector3.new(0, -(target.sprite.spriteData.inAir or 0), 0) - workspace.CurrentCamera.CFrame.lookVector * 0.2
			local part2 = create("Part")({
				Anchored = true, 
				CanCollide = false, 
				BrickColor = BrickColor.new("Electric blue"), 
				Reflectance = 0.5, 
				Transparency = 0.3, 
				Size = Vector3.new(5, 5, 5), 
				Parent = workspace
			})
			part2.CFrame = npos * CFrame.Angles(0, 0, math.pi)
			local mesh = create("SpecialMesh")({
				MeshType = Enum.MeshType.FileMesh, 
				MeshId = "rbxassetid://818652045", 
				Parent = part2
			})
			Tween(0.5, nil, function(b)
				local b3 = b * 0.15
				mesh.Scale = Vector3.new(b3, b3, b3)
			end)
			pcall(function()
				target.sprite.animation:Pause()
			end)
			local scene2 = {}
			for r = 1, 6 do
				local part3 = part2:Clone()
				part3.Mesh.Scale = Vector3.new(0.1, 0.1, 0.1)
				scene2[part3] = npos * CFrame.Angles(0, math.pi / 3 * r, 0) * CFrame.new(0, 0, -1) * CFrame.Angles(2.5, math.random() * 2 * math.pi, 0)
				part3.Parent = workspace
			end
			Tween(0.4, "easeOutQuad", function(c)
				for bc, cb in pairs(scene2) do
					bc.CFrame = cb * CFrame.new(0, 3 * (1 - c), 0)
				end
			end)
			local v3c = scene * Vector3.new(1, 0, 1).unit
			local air = sprite.spriteData.inAir or 0
			Tween(0.6, nil, function(d)
				sprite.offset = v3c * -2 * d + Vector3.new(0, math.sin(d * math.pi) - air * d, 0)
			end)
			local mve = false
			local signal = Utilities.Signal()
			local magn = scene.magnitude
			local function ice()
				signal:fire()
				local mv = v3c:Cross(Vector3.new(0, 1, 0))
				scene2[part2] = true
				for cd, dc in pairs(scene2) do
					local cdcf = cd.CFrame
					local inc = CFrame.new(cdcf.p, cdcf.p + mv)
					scene2[cd] = { inc, inc:inverse() * cdcf }
				end
				Tween(0.4, nil, function(c)
					if not part2.Parent then
						return false
					end
					target.sprite.offset = v3c * c * 10 + Vector3.new(0, c * 4, 0)
					pcall(function()
						target.sprite.animation.spriteLabel.Rotation = 500 * c
					end)
					local ang = CFrame.Angles(0, 0, c * 1.8)
					local v3c2 = v3c * c * 2 + Vector3.new(0, c * -5, 0)
					for de, ed in pairs(scene2) do
						de.CFrame = ed[1] * ang * ed[2] + v3c2
					end
				end)
			end
			spawn(function()
				Tween(1, nil, function(d, e)
					if not part2.Parent then
						return false
					end
					local ee = 70 * e * e - 2 + 5 * e
					sprite.offset = v3c * ee + Vector3.new(0, -air, 0)
					if not mve and magn <= ee then
						mve = true
						spawn(ice)
					end
				end)
			end)
			signal:wait()
			Utilities.FadeOut(0.35, Color3.new(1, 1, 1))
			part1:Destroy()
			sprite.offset = Vector3.new()
			target.sprite.offset = Vector3.new()
			pcall(function()
				target.sprite.animation.spriteLabel.Rotation = 0
			end)
			Lighting.Ambient = Ambient
			Lighting.OutdoorAmbient = OutdoorAmbient
			Lighting.ColorShift_Bottom = ColorShiftBottom
			Lighting.ColorShift_Top = ColorShiftTop
			Lighting.FogColor = Lighting.FogColor
			Lighting.FogEnd = FogEnd
			Lighting.FogStart = FogStart
			for ef, fe in pairs(scene2) do
				ef:Destroy()
			end
			pcall(function()
				target.sprite.animation:Play()
			end)
			wait(0.1)
			Utilities.FadeIn(0.5)
			return true
		end,

		genesissupernova = function(pokemon, move)
			local camBefore = workspace.CurrentCamera.CFrame
			spawn(function() _p.MusicManager:fadeToVolume('top', .4, .5) end)
			local battle = pokemon.side.battle
			local oldSkybox
			if game.Lighting:FindFirstChild('Sky') then
				oldSkybox = game.Lighting:FindFirstChild('Sky')
				oldSkybox.Parent = workspace
			elseif game.Lighting:FindFirstChild('White') then
				oldSkybox = game.Lighting:FindFirstChild('White')
				oldSkybox.Parent = workspace
			end

			local sky = workspace.SpaceSky:Clone()
			sky.Parent = game.Lighting
			local atmo = workspace.SpaceAtm:Clone()
			atmo.Parent = game.Lighting
			Utilities.sound(6255933126)
			wait(1)
			Utilities.FadeOut(0.5, Color3.new(1, 1, 1))
			local nova = game.ReplicatedStorage.Models.Misc.Supernova:Clone()
			local formulas = nova.Formulas:Clone()
			formulas.Parent = game.Players.LocalPlayer.PlayerGui
			workspace.CurrentCamera.FieldOfView = 70
			nova.Parent = battle.scene
			game.Lighting.ColorCorrection.Enabled = false
			Utilities.sound(6255934214)
			spawn(function()
				Utilities.FadeIn(0.5) end)
			spawn(function()
				Utilities.Tween(0.2, nil, function(a)
					formulas.First.ImageTransparency = 1 - 1 * a
				end)
				wait()
				Utilities.Tween(0.5, nil, function(a)
					formulas.First.ImageTransparency = 0 + 1 * a
				end)
				Utilities.Tween(0.2, nil, function(a)
					formulas.Third.ImageTransparency = 1 - 1 * a
				end)
				wait()
				Utilities.Tween(0.5, nil, function(a)
					formulas.Third.ImageTransparency = 0 + 1 * a
				end)
				Utilities.Tween(0.2, nil, function(a)
					formulas.Second.ImageTransparency = 1 - 1 * a
				end)
				wait()
				Utilities.Tween(0.5, nil, function(a)
					formulas.Second.ImageTransparency = 0 + 1 * a
				end)
				Utilities.Tween(0.2, nil, function(a)
					formulas.Forth.ImageTransparency = 1 - 1 * a
				end)
				wait()
				Utilities.Tween(0.5, nil, function(a)
					formulas.Forth.ImageTransparency = 0 + 1 * a
				end)
				formulas:destroy()
			end)
			local cam = workspace.CurrentCamera
			spawn(function()
				game.Lighting.SunRays.Enabled = false end)
			local missile = nova.Missile
			local planet = nova.Planet
			--		cam.CameraType = Enum.CameraType.Scriptable
			local sCam = CFrame.new(-78.6099319, -360.574432, -994.993042, -0.495598733, -0.33024165, 0.803319693, 1.49011594e-08, 0.924895763, 0.380221099, -0.868551612, 0.188437104, -0.458377153)
			local sCam1 = CFrame.new(-72.7281265, -356.376221, -990.24176, -0.72100544, -0.105626032, 0.684831619, -0, 0.988313675, 0.152434036, -0.692929447, 0.109905772, -0.712579489)
			local sCam2 = CFrame.new(-67.1381836, -364.965851, -849.597534, -0.791943491, -0.052584745, 0.608325839, -3.72528985e-09, 0.996284723, 0.0861205831, -0.610594332, 0.0682026371, -0.789001286)
			local mis1 = CFrame.new(-84.6941757, -362.943512, -991.224243, 0.965925574, 0.257833987, -0.0225575641, -7.4505806e-09, 0.087155737, 0.99619472, 0.258819044, -0.962249875, 0.0841859952)
			local mis2 = CFrame.new(-178.411362, -394.622772, -641.466858, 0.965925574, 0.257833987, -0.0225575641, -7.4505806e-09, 0.087155737, 0.99619472, 0.258819044, -0.962249875, 0.0841859952)
			delay(0.7, function()
				planet.Rocks.Enabled = true
				wait(0.2)
				planet.Rocks.Enabled = false
			end)
			delay(0.6, function()
				--	Utilities.sound(5782801042)
				Utilities.sound(6255936389, 0.3)
				local expEf = Instance.new("Explosion")
				expEf.BlastPressure = 0
				expEf.BlastRadius = 0
				expEf.DestroyJointRadiusPercent = 0
				expEf.Name = "Explosion2"
				expEf.Position = Vector3.new(-98.535, -368.877, -934.049)
				expEf.Parent = nova.Planet
				expEf.Visible = true
				planet.Explosion.Enabled = true
				planet.Beam.Enabled = true

			end)
			delay(1.8, function()
				--	Utilities.sound(1577567682)
				nova.Sun.Biggest:destroy()
				nova.Sun.Biggest2:destroy()
				nova.Sun.Biggest3:destroy()
				nova.Sun.Lens:destroy()
				nova.Sun.Parent = game.Lighting
				nova.BlackBackground.Transparency = 0
				nova.BlackBackground2.Transparency = 0
				nova.BlackBackground3.Transparency = 0
				nova.BlackBackground4.Transparency = 0
				nova.X.Decal.Transparency = 0
				missile:destroy()
				wait(0.05)
				nova.X.Decal.Transparency = 1
				nova.Plus.Decal.Transparency = 0
				wait(0.05)
				nova.Plus.Decal.Transparency = 1
				nova.BlackBackground.Transparency = 1
				nova.BlackBackground2.Transparency = 1
				nova.BlackBackground3.Transparency = 1
				nova.BlackBackground4.Transparency = 1
				nova.BigGlow.Transparency = 0
				game.Lighting.Sun.Parent = nova
				nova.StartRing.Transparency = 0
				nova.Glow.Transparency = 0.8
				spawn(function()
					Utilities.Tween(0.2, "easeInCubic", function(a)
						nova.BigGlow.Transparency = 0 + 1 * a
					end)
				end)
				spawn(function()
					Utilities.Tween(0.2, "easeInCubic", function(a)
						nova.Shine2.Transparency = 1 -0.2 * a
					end)
					Utilities.Tween(0.2, "easeInCubic", function(a)
						nova.Shine2.Size = Vector3.new(328.696, 331.968, 0.05) - Vector3.new(328.696 * a, 331.968 * a, 0.05 * a)
					end)

				end)
				spawn(function()
					Utilities.Tween(0.3, "easeInCubic", function(a)
						nova.Glow.Size = Vector3.new(396.564, 53.489, 383.668) - Vector3.new(396.564 * a, 53.489 * a, 383.668 * a)
					end)
				end)
				nova.Sun:destroy()

				spawn(function()
					Utilities.Tween(0.3, "easeInCubic", function(a)
						nova.SunGlow.Size = Vector3.new(32.151, 32.151, 32.151) - Vector3.new(32.151 * a, 32.151 * a, 32.151 * a)
					end)
				end)
				Utilities.Tween(0.3, "easeInCubic", function(a)
					nova.StartRing.Size = Vector3.new(185.509, 0.05, 187.173) - Vector3.new(185.509 * a, 0.05 * a, 187.173 * a)
				end)
				wait(0.1)

				spawn(function()
					_p.CameraShaker:BeginEarthquake(function(cf)
						cam.CFrame = cam.CFrame * cf
					end, 0.3)
					wait(0.5)
					_p.CameraShaker:EndEarthquake(0.1)
				end)
				Utilities.sound(6255934893)
				spawn(function()
					Utilities.Tween(0.5, "easeInSine", function(a)
						nova.BlastRing.Size = Vector3.new(0, 0, 0) + Vector3.new(729.71 * a, 0.3 * a, 743.564 * a)
					end)
				end)
				spawn(function()
					Utilities.Tween(0.5, "easeInSine", function(a)
						nova.BlastRing.Transparency = 0 + 1 * a
					end)
				end)
				spawn(function()
					Utilities.Tween(3, "easeOutSine", function(a)
						nova.BlastRing2.Size = Vector3.new(0, 0, 0) + Vector3.new(549.694 * a, 0.921 * a, 503.598 * a)
					end)
				end)
				spawn(function()
					--Utilities.Tween(3, "easeOutCubic", function(a)
					--	nova.BlastRing2.Transparency = 0 + 1 * a
					--end)
				end)
				spawn(function()
					nova.Shine.Attachment.ShineParticles.Enabled = true
					nova.Effects.Glow1.Enabled = true
					nova.Effects.Glow2.Enabled = true
					nova.Effects.Glow3.Enabled = true
					wait(0.2)
					nova.Effect2.Glow1.Enabled = true
					nova.Effect2.Glow2.Enabled = true
				end)
				wait(1)
				cam.CFrame = CFrame.new(-5.09776592, -384.158295, -779.417603, 0.337045282, 0.00692439964, -0.941462994, -0, 0.999972999, 0.00735473633, 0.941488504, -0.00247887918, 0.337036133)
				spawn(function()
					delay(0.4, function()
						Utilities.sound(6255935707) end)

					Utilities.Tween(1, "easeInSine", function(a)
						nova.EarthDestroy.CFrame = nova.EarthDestroy.CFrame * CFrame.new(0, 0, 5 * a)
					end)
				end)
				spawn(function()

					Utilities.Tween(1, "easeInSine", function(a)
						nova.EarthDestroy2.CFrame = nova.EarthDestroy2.CFrame * CFrame.new(0, 0, 5 * a)
					end)
				end)
				delay(0.6, function()
					spawn(function()
						_p.CameraShaker:BeginEarthquake(function(cf)
							cam.CFrame = cam.CFrame * cf
						end, 0.5)
						wait(1)
						_p.CameraShaker:EndEarthquake(0.4)
					end)
					Utilities.Tween(0.7, nil, function(a)
						nova.DarkEarth.Transparency = 0.5 - 0.5 * a
					end)
					wait(0.3)
					local dPlanet = game.ReplicatedStorage.Models.Misc["Destroyed Planet"]:Clone()
					nova.DarkEarth:destroy()
					Utilities.sound(6255936389)
					dPlanet.Parent = nova
					delay(0, function()
						nova.Earth.Rocks.Enabled = true
						wait(0.2)
						nova.Earth.Rocks.Enabled = false
					end)
					Utilities.Tween(1, "easeOutCubic", function(a)
						Utilities.MoveModel(dPlanet.Main, dPlanet.Main.CFrame * CFrame.new(0, 0.02 * a, -0.02 * a))
					end)
					wait(0.5)
					spawn(function() _p.MusicManager:fadeToVolume('top', 1, .5) end)
					workspace.CurrentCamera.FieldOfView = 28
					cam.CFrame = camBefore
					game.Lighting.ColorCorrection.Enabled = true
					--	cam.CFrame = CFrame.new(-7.00124121, 4.68963575, -10.3212385, -0.707106233, 0.0458332114, -0.705620468, -3.72528985e-09, 0.997897267, 0.064817898, 0.707107425, 0.0458331443, -0.705619276)
					nova:destroy()
					sky:destroy()
					atmo:destroy()
					if oldSkybox then
						oldSkybox.Parent = game.Lighting
					end
					spawn(function()
						game.Lighting.SunRays.Enabled = true end)
				end)
				delay(1, function()
					Utilities.Tween(1, nil, function(a)
						nova.GlowBackground.Transparency = 1-1 * a
					end)
				end)
				delay(1, function()
					Utilities.Tween(1, nil, function(a)
						nova.Earth.Transparency = 0 + 1 * a
					end)
				end)


			end)

			spawn(function()
				Utilities.Tween(2, "easeInSine", function(a)
					missile.CFrame = mis1:Lerp(mis2, a)
				end)
			end)
			spawn(function()
				Utilities.Tween(1, nil, function(a)
					cam.CFrame = sCam:Lerp(sCam1, a)
				end)
				Utilities.Tween(1, nil, function(a)
					cam.CFrame = sCam1:Lerp(sCam2, a)
				end)
			end)
			spawn(function()
				Utilities.Tween(2, "easeInSine", function(a)
					missile.CFrame = mis1:Lerp(mis2, a)
				end)
			end)
			wait(5)

			return true
		end,

	} end