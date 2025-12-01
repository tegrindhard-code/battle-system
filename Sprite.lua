return function(_p)
local storage = game:GetService('ReplicatedStorage')
local class, null; do
	local util = require(script.Parent.BattleUtilities)
	class = util.class
	null = util.null
end

--local _p = require(script.Parent.Parent)--storage.Plugins)
local Utilities = _p.Utilities
local Tween, MoveModel = Utilities.Tween, Utilities.MoveModel
local create = Utilities.Create

-- Model animation support
local ModelAnimator = require(script.Parent.modelAnimator)
local dataChanges = {
	alpha = {
		size = 1.25,
		weight = 1.5
	},
	totem = {
		size = 1.2,
		weight = 1.2
	},
	dynamax = {
		size = 2, --weight doesn't change 
		size2 = 4,
		size3 = 1.3
	}
}
local Sprites = {}

local runService = game:GetService('RunService')
local Tools = require(script.Parent.Tools)
local stepped = runService.RenderStepped
local bound = false
local function bind()
	if bound then return end
	bound = true
	local v3 = Vector3.new
	local xzPlane = v3(1,0,1)
	local cframe = CFrame.new
	runService:BindToRenderStep('SpritePartCFrameRenderStep', Enum.RenderPriority.Last.Value, function()
		if #Sprites == 0 then
			runService:UnbindFromRenderStep('SpritePartCFrameRenderStep')
			bound = false
			return
		end
		local cam = workspace.CurrentCamera
		local lv = (cam.Focus.p - cam.CFrame.p).unit * xzPlane
		for _, s in pairs(Sprites) do
			local part = s.part
			if part then
				local p = s.cf.p + v3(0, part.Size.y/2, 0) + s.offset
				part.CFrame = cframe(p, p - lv)
			end
		end
	end)
end

local function hideAll(...)
	for _, model in pairs({...}) do
		for _, ch in pairs(model:GetChildren()) do
			if ch:IsA('BasePart') then
				ch.Transparency = 1.0
			end
		end
	end
end

local Sprite = class({
	className = 'BattleSprite',

	forme = '',
	offset = Vector3.new(),
	use3D = false,
	modelAnimator = nil,
	model3D = nil,

}, function(self, pokemon, battle, siden)
	self.pokemon = pokemon
	self.battle = battle
	self.siden = siden

	self.isBackSprite = siden == 1
	self.isDyna = false
	self.isGmax = false
	self.isRaid = false
	self.alpha = false
	self.sub = nil

	-- Check if 3D battles are enabled
	print("[SPRITE DEBUG] Constructor called for pokemon:", pokemon and pokemon.species or "nil")
	print("[SPRITE DEBUG] _p.Menu exists:", _p.Menu ~= nil)
	print("[SPRITE DEBUG] _p.Menu.options exists:", _p.Menu and _p.Menu.options ~= nil)
	print("[SPRITE DEBUG] battles3D value:", _p.Menu and _p.Menu.options and _p.Menu.options.battles3D or "nil")
	self.use3D = _p.Menu and _p.Menu.options and _p.Menu.options.battles3D or false
	print("[SPRITE DEBUG] use3D set to:", self.use3D)

	self:updateSpriteData()
	self.duringMove = false

	table.insert(Sprites, self)
	bind()

	return self
end)
function Sprite:closeup(offset)
	local disabledGuis = {}
	for _, side in pairs(self.battle.sides) do
		for _, active in pairs(side.active) do
			pcall(function()
				if active.statbar.main.Visible then
					active.statbar.main.Visible = false
					table.insert(disabledGuis, active.statbar.main)
				end
			end)
		end
	end
	local cam = workspace.CurrentCamera
	local camBefore = cam.CFrame
	local camGoalFocus = self.cf.p + Vector3.new(0, 2.25, 0)
	local camGoal = CFrame.new(camGoalFocus - camBefore.lookVector * Vector3.new(12, 6, 12), camGoalFocus) + (offset or Vector3.new())
	Tween(1.2, "easeOutCubic", function(a)
		cam.CFrame = camBefore:lerp(camGoal, a)
	end)
	cam.CFrame = camGoal
	return function()
		Tween(1.2, "easeOutCubic", function(a)
			cam.CFrame = camGoal:lerp(camBefore, a)
		end)
		cam.CFrame = camBefore
		for _, g in pairs(disabledGuis) do
			pcall(function()
				g.Visible = true
			end)
		end
	end
end
function Sprite:closeuplegend(offset, callback)
	local disabledGuis = {}
	for _, side in pairs(self.battle.sides) do
		for _, active in pairs(side.active) do
			pcall(function()
				if active.statbar.main.Visible then
					active.statbar.main.Visible = false
					table.insert(disabledGuis, active.statbar.main)
				end
			end)
		end
	end
	local cam = workspace.CurrentCamera
	local camBefore = cam.CFrame
	local camGoalFocus = self.cf.p + Vector3.new(0, 2.25, 0)
	local camGoal = CFrame.new(camGoalFocus - camBefore.lookVector * Vector3.new(12, 6, 12), camGoalFocus) + (offset or Vector3.new())

	-- WHO TF FORGOT THIS??? From Infrared
	Utilities.pTween(cam, "CFrame", camGoal, 1.2, "easeOutCubic", nil, function()
		if callback then
			callback()
		end
		Utilities.pTween(cam, "CFrame", camBefore, 1.2, "easeOutCubic", nil, function()
			for _, g in pairs(disabledGuis) do
				pcall(function()
					g.Visible = true
				end)
			end
		end)
	end)
end
function Sprite:updateSpriteData()
	local pokemon = self.pokemon
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	if self.forme and self.forme ~= '' then
		spriteId = spriteId .. '-' .. self.forme
	end
	self.spriteData = _p.DataManager:getSprite((pokemon.shiny and '_SHINY' or '')..(self.isBackSprite and '_BACK' or '_FRONT'), spriteId, pokemon.gender=='F')
end

function Sprite:get3DModelId()
	-- Get 3D model ID via DataManager (which queries modelsData on server)
	-- Animation config comes from existing spriteData (GifData)
	local pokemon = self.pokemon
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	if self.forme and self.forme ~= '' then
		spriteId = spriteId .. '-' .. self.forme
	end

	-- Try to get model ID with fallback chain via DataManager
	local tableName = (pokemon.shiny and '_SHINY' or '')..(self.isBackSprite and '_BACK' or '_FRONT')
	local modelId = _p.DataManager:getModelId(tableName, spriteId)

	-- Fallback: Try non-shiny version
	if not modelId and pokemon.shiny then
		tableName = self.isBackSprite and '_BACK' or '_FRONT'
		modelId = _p.DataManager:getModelId(tableName, spriteId)
	end

	-- Fallback: Try _FRONT if looking for _BACK
	if not modelId and self.isBackSprite then
		tableName = pokemon.shiny and '_SHINY_FRONT' or '_FRONT'
		modelId = _p.DataManager:getModelId(tableName, spriteId)
	end

	return modelId
end

local mobile = Utilities.isTouchDevice()
function Sprite:playCry(pitch, cry, volume, speed)
	pitch = pitch or 1.0
	cry = cry or self.spriteData.cry
	if cry then
		Utilities.fastSpawn(function()
			local sound = create 'Sound' {
				SoundId = 'rbxassetid://'..cry.id,
				Volume = volume or .4,
				--				TimePosition = cry.startTime-.05,
				Pitch = pitch,
				Parent = Utilities.gui,
			}
			sound:Play()
			sound.TimePosition = cry.startTime-.05
			local endTime = cry.startTime + cry.duration + .05
			while sound.TimePosition < endTime do stepped:wait() end
			sound:Stop()
			sound:Destroy()
		end)
	end
end
function Sprite:animBackground(data, fieldData, battle)

	local disabledGuis = {}
	for _, side in pairs(self.battle.sides) do
		for _, active in pairs(side.active) do
			pcall(function()
				if active.statbar.main.Visible then
					active.statbar.main.Visible = false
					table.insert(disabledGuis, active.statbar.main)
				end
			end)
		end
	end

end
function Sprite:getTrainer(slot)
	slot = slot or self.slot
	if self.siden == 1 then
		return self.battle["playerModelObj" .. slot] or self.battle.playerModelObj
	end
	return self.battle["trainerModelObj" .. slot] or self.battle.trainerModelObj
end
function Sprite:animZDance(poke, battle, zpowertype)
	task.wait(0.5)
	local sprite = poke.sprite
	local originalSpriteData = sprite.spriteData
	local originalSpriteCFrame = sprite.cf
	local sideDirection = -1
	local originalSpriteLabelSize = sprite.animation.spriteLabel.ImageRectSize
	if sprite.siden == 1 then
		sprite.isBackSprite = false
		sprite:updateSpriteData()
		sprite:renderNewSpriteData()
		sideDirection = 1
		do
			local spriteLabel = sprite.animation.spriteLabel
			local size = spriteLabel.ImageRectSize
			spriteLabel.ImageRectSize = Vector2.new(-size.X, size.Y)
			function sprite.animation.updateCallback()
				local offset = spriteLabel.ImageRectOffset
				spriteLabel.ImageRectOffset = Vector2.new(offset.X + size.X, offset.Y)
			end
		end
	end
	sprite.offset = Vector3.new()	
	local zPowerTable = {
		Poison = BrickColor.new('Royal purple'),
		Fighting = BrickColor.new('Daisy orange'),
		Dark = BrickColor.new('Black metallic'),
		Grass = BrickColor.new('Lime green'),
		Normal = BrickColor.new('Institutional white'),
		Rock = BrickColor.new('CGA brown'),
		Steel = BrickColor.new('Ghost grey'),
		Dragon = BrickColor.new('Light purple'),
		Electric = BrickColor.new('Cool yellow'),
		Water = BrickColor.new('Baby blue'),
		Fire = BrickColor.new('Medium red'),
		Ghost = BrickColor.new('Bright purple'),
		Bug = BrickColor.new('Sea green'),
		Psychic = BrickColor.new('Hot pink'),
		Ice = BrickColor.new('Pastel Blue'),
		Flying = BrickColor.new('Pastel light blue'),
		Ground = BrickColor.new('Light orange brown'),
		Fairy = BrickColor.new('Light pink'),
	}
	_p.storage.Models.Misc.ZMove.Main.BrickColor = zPowerTable[storage.Models.Zpoke.Value]
	_p.storage.Models.Misc.ZMove.Part.BrickColor = zPowerTable[storage.Models.Zpoke.Value]
	local zfield = _p.storage.Models.Misc.ZMove:Clone()
	local main = zfield.Main
	Utilities.MoveModel(main, battle.CoordinateFrame1 + Vector3.new(300, 300, 300))
	local zp = main.Position
	zfield.Parent = workspace
	--colour shit
	sprite.cf = CFrame.new(zp) + Vector3.new(0, main.Size.Y / 2, 0)
	local trainer = self:getTrainer()
	local cp = zfield.PlayerPos.Position + Vector3.new(0, zfield.PlayerPos.Size.Y / 2 + (--[[trainer.IsR15 and trainer.Humanoid.HipHeight + trainer.Root.Size.Y / 2 or]] 1.7999999999999998), 0)
	local tcf = CFrame.new(cp, Vector3.new(zp.X, cp.Y, zp.Z))
	trainer.Root.CFrame = tcf
	trainer.BodyPosition.Position = tcf.Position
	trainer.BodyGyro.CFrame = tcf
	local R6 = zfield.R6
	local R15 = zfield.R15
	--r6 aura
	if trainer.Model:FindFirstChild('Head') then
		R6.Head.Flame.Parent = trainer.Model:FindFirstChild('Head')
		R6.Head.Flame1.Parent = trainer.Model:FindFirstChild('Head')
		R6.Head.Glow.Parent = trainer.Model:FindFirstChild('Head')
		R6.Head.Specs.Parent = trainer.Model:FindFirstChild('Head')
	end	
	if trainer.Model:FindFirstChild('Torso') then
		R6.Torso.Flame.Parent = trainer.Model:FindFirstChild('Torso')
		R6.Torso.Flame1.Parent = trainer.Model:FindFirstChild('Torso')
		R6.Torso.Glow.Parent = trainer.Model:FindFirstChild('Torso')
		R6.Torso.Specs.Parent = trainer.Model:FindFirstChild('Torso')
	end	
	if trainer.Model:FindFirstChild('RightUpperArm') then
		R6['Right Arm'].Flame.Parent = trainer.Model:FindFirstChild('Right Arm')
		R6['Right Arm'].Flame1.Parent = trainer.Model:FindFirstChild('Right Arm')
		R6['Right Arm'].Glow.Parent = trainer.Model:FindFirstChild('Right Arm')
		R6['Right Arm'].Specs.Parent = trainer.Model:FindFirstChild('Right Arm')
	end	
	if trainer.Model:FindFirstChild('Left Arm') then
		R6['Left Arm'].Flame.Parent = trainer.Model:FindFirstChild('Left Arm')
		R6['Left Arm'].Flame1.Parent = trainer.Model:FindFirstChild('Left Arm')
		R6['Left Arm'].Glow.Parent = trainer.Model:FindFirstChild('Left Arm')
		R6['Left Arm'].Specs.Parent = trainer.Model:FindFirstChild('Left Arm')
	end	
	if trainer.Model:FindFirstChild('Right Leg') then
		R6['Right Leg'].Flame.Parent = trainer.Model:FindFirstChild('Right Leg')
		R6['Right Leg'].Flame1.Parent = trainer.Model:FindFirstChild('Right Leg')
		R6['Right Leg'].Glow.Parent = trainer.Model:FindFirstChild('Right Leg')
		R6['Right Leg'].Specs.Parent = trainer.Model:FindFirstChild('Right Leg')
	end	
	if trainer.Model:FindFirstChild('Left Leg') then
		R6['Left Leg'].Flame.Parent = trainer.Model:FindFirstChild('Left Leg')
		R6['Left Leg'].Flame1.Parent = trainer.Model:FindFirstChild('Left Leg')
		R6['Left Leg'].Glow.Parent = trainer.Model:FindFirstChild('Left Leg')
		R6['Left Leg'].Specs.Parent = trainer.Model:FindFirstChild('Left Leg')
	end	
	--r15 aura
	if trainer.Model:FindFirstChild('LeftHand') then
		R15.LeftHand.Flame.Parent = trainer.Model:FindFirstChild('LeftHand')
		R15.LeftHand.Flame1.Parent = trainer.Model:FindFirstChild('LeftHand')
		R15.LeftHand.Glow.Parent = trainer.Model:FindFirstChild('LeftHand')
		R15.LeftHand.Specs.Parent = trainer.Model:FindFirstChild('LeftHand')
	end	
	if trainer.Model:FindFirstChild('LeftFoot') then
		R15.LeftFoot.Flame.Parent = trainer.Model:FindFirstChild('LeftFoot')
		R15.LeftFoot.Flame1.Parent = trainer.Model:FindFirstChild('LeftFoot')
		R15.LeftFoot.Glow.Parent = trainer.Model:FindFirstChild('LeftFoot')
		R15.LeftFoot.Specs.Parent = trainer.Model:FindFirstChild('LeftFoot')
	end	
	if trainer.Model:FindFirstChild('LeftLowerArm') then
		R15.LeftLowerArm.Flame.Parent = trainer.Model:FindFirstChild('LeftLowerArm')
		R15.LeftLowerArm.Flame1.Parent = trainer.Model:FindFirstChild('LeftLowerArm')
		R15.LeftLowerArm.Glow.Parent = trainer.Model:FindFirstChild('LeftLowerArm')
		R15.LeftLowerArm.Specs.Parent = trainer.Model:FindFirstChild('LeftLowerArm')
	end			
	if trainer.Model:FindFirstChild('LeftLowerLeg') then
		R15.LeftLowerLeg.Flame.Parent = trainer.Model:FindFirstChild('LeftLowerLeg')
		R15.LeftLowerLeg.Flame1.Parent = trainer.Model:FindFirstChild('LeftLowerLeg')
		R15.LeftLowerLeg.Glow.Parent = trainer.Model:FindFirstChild('LeftLowerLeg')
		R15.LeftLowerLeg.Specs.Parent = trainer.Model:FindFirstChild('LeftLowerLeg')
	end		
	if trainer.Model:FindFirstChild('LeftUpperArm') then
		R15.LeftUpperArm.Flame.Parent = trainer.Model:FindFirstChild('LeftUpperArm')
		R15.LeftUpperArm.Flame1.Parent = trainer.Model:FindFirstChild('LeftUpperArm')
		R15.LeftUpperArm.Glow.Parent = trainer.Model:FindFirstChild('LeftUpperArm')
		R15.LeftUpperArm.Specs.Parent = trainer.Model:FindFirstChild('LeftUpperArm')
	end		
	if trainer.Model:FindFirstChild('LeftUpperLeg') then
		R15.LeftUpperLeg.Flame.Parent = trainer.Model:FindFirstChild('LeftUpperLeg')
		R15.LeftUpperLeg.Flame1.Parent = trainer.Model:FindFirstChild('LeftUpperLeg')
		R15.LeftUpperLeg.Glow.Parent = trainer.Model:FindFirstChild('LeftUpperLeg')
		R15.LeftUpperLeg.Specs.Parent = trainer.Model:FindFirstChild('LeftUpperLeg')
	end	
	if trainer.Model:FindFirstChild('LowerTorso') then
		R15.LowerTorso.Flame.Parent = trainer.Model:FindFirstChild('LowerTorso')
		R15.LowerTorso.Flame1.Parent = trainer.Model:FindFirstChild('LowerTorso')
		R15.LowerTorso.Glow.Parent = trainer.Model:FindFirstChild('LowerTorso')
		R15.LowerTorso.Specs.Parent = trainer.Model:FindFirstChild('LowerTorso')
	end	
	if trainer.Model:FindFirstChild('RightFoot') then
		R15.RightFoot.Flame.Parent = trainer.Model:FindFirstChild('RightFoot')
		R15.RightFoot.Flame1.Parent = trainer.Model:FindFirstChild('RightFoot')
		R15.RightFoot.Glow.Parent = trainer.Model:FindFirstChild('RightFoot')
		R15.RightFoot.Specs.Parent = trainer.Model:FindFirstChild('RightFoot')
	end	
	if trainer.Model:FindFirstChild('RightHand') then
		R15.RightHand.Flame.Parent = trainer.Model:FindFirstChild('RightHand')
		R15.RightHand.Flame1.Parent = trainer.Model:FindFirstChild('RightHand')
		R15.RightHand.Glow.Parent = trainer.Model:FindFirstChild('RightHand')
		R15.RightHand.Specs.Parent = trainer.Model:FindFirstChild('RightHand')
	end			
	if trainer.Model:FindFirstChild('RightLowerArm') then
		R15.RightLowerArm.Flame.Parent = trainer.Model:FindFirstChild('RightLowerArm')
		R15.RightLowerArm.Flame1.Parent = trainer.Model:FindFirstChild('RightLowerArm')
		R15.RightLowerArm.Glow.Parent = trainer.Model:FindFirstChild('RightLowerArm')
		R15.RightLowerArm.Specs.Parent = trainer.Model:FindFirstChild('RightLowerArm')
	end			
	if trainer.Model:FindFirstChild('RightLowerLeg') then
		R15.RightLowerLeg.Flame.Parent = trainer.Model:FindFirstChild('RightLowerLeg')
		R15.RightLowerLeg.Flame1.Parent = trainer.Model:FindFirstChild('RightLowerLeg')
		R15.RightLowerLeg.Glow.Parent = trainer.Model:FindFirstChild('RightLowerLeg')
		R15.RightLowerLeg.Specs.Parent = trainer.Model:FindFirstChild('RightLowerLeg')
	end		
	if trainer.Model:FindFirstChild('RightUpperArm') then
		R15.RightUpperArm.Flame.Parent = trainer.Model:FindFirstChild('RightUpperArm')
		R15.RightUpperArm.Flame1.Parent = trainer.Model:FindFirstChild('RightUpperArm')
		R15.RightUpperArm.Glow.Parent = trainer.Model:FindFirstChild('RightUpperArm')
		R15.RightUpperArm.Specs.Parent = trainer.Model:FindFirstChild('RightUpperArm')
	end		
	if trainer.Model:FindFirstChild('RightUpperLeg') then
		R15.RightUpperLeg.Flame.Parent = trainer.Model:FindFirstChild('RightUpperLeg')
		R15.RightUpperLeg.Flame1.Parent = trainer.Model:FindFirstChild('RightUpperLeg')
		R15.RightUpperLeg.Glow.Parent = trainer.Model:FindFirstChild('RightUpperLeg')
		R15.RightUpperLeg.Specs.Parent = trainer.Model:FindFirstChild('RightUpperLeg')
	end		
	if trainer.Model:FindFirstChild('UpperTorso') then
		R15.UpperTorso.Flame.Parent = trainer.Model:FindFirstChild('UpperTorso')
		R15.UpperTorso.Flame1.Parent = trainer.Model:FindFirstChild('UpperTorso')
		R15.UpperTorso.Glow.Parent = trainer.Model:FindFirstChild('UpperTorso')
		R15.UpperTorso.Specs.Parent = trainer.Model:FindFirstChild('UpperTorso')
	end				
	local parts = trainer.PartTransparencies
	if parts then
		for p, t in pairs(parts) do
			p.Transparency = t
		end
	end
	trainer.Model.Parent = battle.scene
	local cam = workspace.CurrentCamera
	local disabledGuis = {}
	for _, side in pairs(battle.sides) do
		for _, active in pairs(side.active) do
			pcall(function()
				if active.statbar.main.Visible then
					active.statbar.main.Visible = false
					table.insert(disabledGuis, active.statbar.main)
				end
			end)
		end
	end
	local dif = (zp - cp) * Vector3.new(1, 0, 1)
	local distance = dif.magnitude
	dif = dif.unit
	local b = distance * 0.7
	local theta = -0.17 * sideDirection
	local dir = tcf * CFrame.Angles(0, theta, 0).lookVector
	local fov0 = cam.FieldOfView
	local a = b * math.tan(math.rad(fov0 / 2))
	local inAir = (sprite.spriteData.inAir or 0) * 0.75
	local xOffset = sprite.spriteData.xOffset or 0
	cam.CFrame = CFrame.new((cp + dir / b) + Vector3.new(0, 0, 3) , cp) --+ dir * b, cp)--CFrame.new(cp + dir * b, cp)zfield.Playercam.CFrame
	local animtrack = trainer.ZDance--trainer.Humanoid:LoadAnimation(Utilities.Create("Animation")({
	--AnimationId = "rbxassetid://" .. _p.animationId[(trainer.IsR15 and "R15_" or "") .. "ZDance"]
	--}))

	animtrack:Play(0)
	wait(3.8)

	Utilities.Tween(0.6, "easeOutQuart", function(alpha)
		local focus = cp + dif * distance * 0.75 * alpha
		local bt = b * (1 + 1.5 / alpha)
		local roll = math.rad(15 * alpha) * sideDirection
		cam.CFrame = CFrame.new((cp + dir / bt) + Vector3.new(0, 0, 86 * alpha), focus) * CFrame.Angles(0, 0, -roll) + Vector3.new(xOffset, inAir, 0) --	cam.CFrame = CFrame.new(cp + dir * bt, focus) * CFrame.Angles(0, 0, -roll) + Vector3.new(0, inAir, 0)

		cam.FieldOfView = (2 * math.deg(math.atan(alpha / bt)) + fov0) / 2
	end)
	battle:startZPowerGlow(sprite)
	battle:message(poke:getName() .. " surrounded itself with its Z-Power!")
	--Custom		

	--local zWrittenWord = write("Light That Burns The Sky")({
	--	Frame = create("Frame")({
	--		BackgroundTransparency = 1,
	--		Size = UDim2.new(1, 0, 0.4, 0),
	--		Position = UDim2.new(0, 0, 0.3, 0),
	--		ZIndex = 8,
	--		Parent = s
	--	}),
	--	Scaled = true
	--})
	--local zLetters = {}
	--local zPos = {}
	--for _, l in pairs(zWrittenWord.Labels) do
	--	local p = (l.AbsolutePosition.X - s.AbsolutePosition.X) / s.AbsoluteSize.X
	--	zLetters[l] = p
	--	zPos[l] = l.Position
	--end		
	--for l, p in pairs(zLetters) do
	--	local o = (a + p) % 1
	--	l.Position = zPos[l] + UDim2.new(0, 0, 0.2 * ta * math.sin(o * math.pi * 2), 0)
	--end

	--
	animtrack:Stop(0)
	pcall(function()
		animtrack:Destroy()
	end)
	trainer.Model.Parent = nil
	sprite.cf = originalSpriteCFrame
	if sprite.siden == 1 then
		sprite.isBackSprite = true
		sprite.spriteData = originalSpriteData
		sprite:renderNewSpriteData()
		sprite.animation.spriteLabel.ImageRectSize = originalSpriteLabelSize
		sprite.animation.updateCallback = nil
	end
	zfield:Destroy()
	cam.CFrame = battle.battleCamera.CoordinateFrame + battle.sceneOffset
	if	not workspace:FindFirstChild('DmaxV1')then
		cam.FieldOfView = battle.battleCamera.FieldOfView 
	else
		cam.FieldOfView = 70
	end
	for _, g in pairs(disabledGuis) do
		pcall(function()
			g.Visible = true
		end)
	end






	--		local disabledGuis = {}
	--		for _, side in pairs(self.battle.sides) do
	--			for _, active in pairs(side.active) do
	--				pcall(function()
	--					if active.statbar.main.Visible then
	--						active.statbar.main.Visible = false
	--						table.insert(disabledGuis, active.statbar.main)
	--					end
	--				end)
	--			end
	--		end
	--		--Disabled GUI
	--		local cam = workspace.CurrentCamera
	--		local camBefore = cam.CFrame
	--		local camBefore2 = cam.FieldOfView

	--		--Saves current BattleCam position
	--		spawn(function() _p.MusicManager:fadeToVolume(true, .65, 1) end)
	--		Utilities.sound(0, nil, nil, 10) --Updated Sound ID
	--		--Zmove Sound w/dance
	--		local ZMoveDance = _p.storage.Models.Misc.ZMove:Clone()
	--		ZMoveDance.Parent = workspace

	--		local playerpos = ZMoveDance.PlayerPos
	--		local pokepos = ZMoveDance.PokePos
	--		local pokecam = ZMoveDance.Pokecam
	--		local playercam = ZMoveDance.Playercam
	--		local pokemon = self.pokemon
	--		local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	--		self.slot = slot
	--		local Currentdata = self.CoordinateFrame2 
	--		local data  = _p.DataManager:getSprite((pokemon.shiny and '_SHINY' or '')..'_FRONT', spriteId)
	--		local Currentdata2 = self.spriteData
	--		--self.spriteData = data
	--		local og = self.part
	--		self.part = pokepos

	--		self:updateSpriteData(true)
	--		self:renderNewSpriteData(pokepos)
	--		--local a = _p.AnimatedSprite:New(self.spriteData)


	--		--a.spriteLabel.Parent = pokepos.Gui 
	--		--local posPart = pokepos
	--		--self.cf = posPart.CFrame - Vector3.new(0, posPart.Size.y/2, 0) + Vector3.new(0, data.inAir or 0, 0)
	--		local scale = data.scale or 1
	--		--pokepos.Size = Vector3.new(data.fWidth/25*scale, data.fHeight/25*scale, 0.6)
	--		--pokepos.CFrame = self.cf + Vector3.new(0, pokepos.Size.y/2, 0)
	--		--pokepos.Gui.CanvasSize = Vector2.new(data.fWidth, data.fHeight)
	--		--a:Play()

	--		local trainer
	--		if self.siden == 1 then
	--			trainer = self.battle.playerModelObj
	--		else
	--			trainer = self.battle.trainerModelObj
	--		end
	--		local Player = trainer.Model
	--		trainer.faded = false
	--		self.CoordinateFrame2 = CFrame.new(playerpos.Position) + Vector3.new(0, -playerpos.Size.Y/2, 0)

	--		Player.Parent = ZMoveDance
	--		cam.FieldOfView = 70 
	--		trainer.Root.CFrame = self.CoordinateFrame2 + Vector3.new(0, 3*scale, 0)
	--		trainer.Root.Anchored = true
	--		cam.CFrame = playercam.CFrame
	--		spawn(function() _p.MusicManager:fadeToVolume(true, 1, .8) end)
	--		trainer.ZDance:Play(.5)
	--		--AnimationPlay
	--wait(3)
	--		--Removal of Dance
	--		local TweenService = game:GetService("TweenService")

	--		local tweenInfo = TweenInfo.new(
	--			.7, -- time 
	--			Enum.EasingStyle.Linear, -- style
	--			Enum.EasingDirection.Out, -- direction
	--			0, -- repeat count
	--			false, -- reverses
	--			0  	 -- delaytime
	--		);
	--		local tween = TweenService:Create(cam, tweenInfo, {CFrame = pokecam.CFrame});
	--		tween:Play()
	--		wait(2)
	--		--Zoom On Poke
	--		self.spriteData = Currentdata2
	--		self.offset = Vector3.new()
	--		self.part = og
	--		--self:updateSpriteData()
	--		--self:renderNewSpriteData()

	--		cam.CFrame = camBefore
	--		cam.FieldOfView = camBefore2
	--		--self.animation.spriteLabel.Parent = og
	--		--self:updateSpriteData()
	--		--self:renderNewSpriteData(og)
	--		--local b = _p.AnimatedSprite:New(self.spriteData)


	--		--b.spriteLabel.Parent = og
	--		--local posPart = pokepos
	--		--self.cf = posPart.CFrame - Vector3.new(0, posPart.Size.y/2, 0) + Vector3.new(0, data.inAir or 0, 0)
	--		--local scale = data.scale or 1
	--		--pokepos.Size = Vector3.new(data.fWidth/25*scale, data.fHeight/25*scale, 0.6)
	--		--pokepos.CFrame = self.cf + Vector3.new(0, pokepos.Size.y/2, 0)
	--		--pokepos.Gui.CanvasSize = Vector2.new(data.fWidth, data.fHeight)
	--		--b:Play()


	--		for _, g in pairs(disabledGuis) do
	--			pcall(function() g.Visible = true end)
	--		end

	--		Player.Parent = nil
	--		trainer.faded = true
	--		trainer.Root.Anchored = false
	--		ZMoveDance:Destroy()

	--		self.CoordinateFrame2 = Currentdata
	--		--Removal
	--		--self.stopZPowerGlow() -- Not Needed
end
function Sprite:animMegaEvolve(megaEvolutionSpriteData, color1, color2, color3)
	if self.battle.fastForward then
		self.spriteData = megaEvolutionSpriteData
		self.offset = Vector3.new()
		self:renderNewSpriteData()
		return
	end
	--	Utilities.print_r(megaEvolutionSpriteData.cry)
	local disabledGuis = {}
	for _, side in pairs(self.battle.sides) do
		for _, active in pairs(side.active) do
			pcall(function()
				if active.statbar.main.Visible then
					pcall(function()
						active.statbar:update()
					end)
					active.statbar.main.Visible = false
					table.insert(disabledGuis, active.statbar.main)
				end
			end)
		end
	end

	--	local color1, color2, color3 = _p.colorBox1.Text, _p.colorBox2.Text, _p.colorBox3.Text--_p.BrickColor.new('Cyan'), BrickColor.new('Bright orange')
	--	color1 = BrickColor.new(color1)
	--	color2 = BrickColor.new(color2)
	--	if color3 == '' then
	--		color3 = nil
	--	else
	--		color3 = BrickColor.new(color3)
	--	end
	color1, color2 = BrickColor.new(color1), BrickColor.new(color2)
	if color3 == 0 then
		color3 = color2
	else
		color3 = BrickColor.new(color3)
	end

	_p.DataManager:preloadSprites(megaEvolutionSpriteData)
	local inAirBefore = self.spriteData.inAir or 0
	local inAirAfter  = megaEvolutionSpriteData.inAir or 0
	local cam = workspace.CurrentCamera
	local camBefore = cam.CFrame
	local part = self.part
	local lighting = game:GetService('Lighting')
	local ambientBefore = lighting.OutdoorAmbient

	spawn(function() _p.MusicManager:fadeToVolume(true, .65, 1) end)
	Utilities.sound(486262895, nil, nil, 10)

	spawn(function() -- particles 477984910
		local twopi = math.pi*2
		local rand = math.random
		local cos, sin = math.cos, math.sin
		local freq = 3.5
		local absorbDuration = 2
		--		spawn(function()
		--			Tween(2, 'easeInCubic', function(a)
		----				freq = 2 + 4*a
		--				absorbDuration = 2-.5*a
		--			end)
		--		end)
		local st = tick()
		while tick()-st < 4.25 do
			local color = (color3 or color2).Color
			spawn(function()
				local p = create 'Part' {
					Transparency = 1.0,
					Anchored = true,
					CanCollide = false,
					Size = Vector3.new(.2, .2, .2),
					Parent = workspace,
				}
				local bbg = create 'BillboardGui' {
					Adornee = p,
					Size = UDim2.new(.5, 0, .5, 0),
					Parent = p,
					create 'ImageLabel' {
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://478035099',
						ImageColor3 = color,
						Size = UDim2.new(1.0, 0, 1.0, 0),
					},
					create 'ImageLabel' {
						BackgroundTransparency = 1.0,
						Image = 'rbxassetid://478035064',
						Size = UDim2.new(1.0, 0, 1.0, 0),
						ZIndex = 2,
					}
				}
				local h, a = rand()*twopi, (rand()-.5)*2
				local dir = Vector3.new(cos(h)*cos(a), sin(a), sin(h)*cos(a))
				Tween(absorbDuration, nil, function(a)
					local o = 1-a
					p.CFrame = part.CFrame + dir*4*o
					local s = .375 + .125*math.sin(a*10)
					if a < .2 then
						s = s * a * 5
					end
					bbg.Size = UDim2.new(s, 0, s, 0)
				end)
				p:Destroy()
			end)
			wait(1/freq)
		end
	end)
	local _, ambientStartSat, ambientStartVal = Color3.new(ambientBefore)
	-- goal HSV: 0.016, 1, 0.5
	local sLabel = self.animation.spriteLabel
	local camGoalFocus = self.cf.p + Vector3.new(0, .25*18/2-inAirBefore, 0)--part.Position - self.offset - Vector3.new(0, inAirBefore, 0)
	local camGoal = CFrame.new(camGoalFocus - camBefore.lookVector*Vector3.new(12, 6, 12), camGoalFocus)
	local lerp = select(2, Utilities.lerpCFrame(camBefore, camGoal))
	local rst = tick()
	local function rumble()
		local et = tick()-rst
		local mag = .07
		if et < 1 then
			mag = mag * et
		elseif et > 5 then
			mag = mag * (6-et)
		end
		return CFrame.new(0, math.sin(et*50)*mag, 0)
	end
	Tween(3, nil, function(a)
		cam.CFrame = lerp(a) * rumble()
		--		lighting.OutdoorAmbient = Color3.fromHSV(.016, ambientStartSat+(1-ambientStartSat)*a, ambientStartVal+(.5-ambientStartVal)*a)
		if a < .5 then
			local aa = a*2
			self.offset = Vector3.new(0, -inAirBefore*aa, 0)
		else
			local aa = 1-(2*(a-.5))
			sLabel.ImageColor3 = Color3.new(aa,aa,aa)
		end
	end)
	local megaEffect = _p.storage.Models.Misc.Mega:Clone()
	local egg = megaEffect.Egg
	local scale = .25--part.Size.Y/12
	Utilities.ScaleModel(megaEffect.Base, scale, true)
	local cf = self.cf * CFrame.Angles(0, math.pi/12--[[*2*math.random()]], 0) + Vector3.new(0, -.5*scale-inAirBefore, 0)
	local orb = megaEffect.Orb
	local innerEffect = megaEffect.InnerEnergy
	local miniEffect = megaEffect.MiniEnergy
	local outerEffect = megaEffect.OuterEnergy
	local topia = megaEffect.TopiaEnergy
	local fullsize = orb.Size
	--	orb.PointLight.Range = 0
	innerEffect.EnergyPart.Transparency = 1.0
	miniEffect.EnergyPart.Transparency = 1.0
	outerEffect.EnergyPart.Transparency = 1.0
	topia.EnergyPart.Transparency = 1.0
	miniEffect.EnergyPart.BrickColor = color1
	innerEffect.EnergyPart.BrickColor = color1
	topia.EnergyPart.BrickColor = color1
	outerEffect.EnergyPart.BrickColor = color1
	MoveModel(megaEffect.Base, cf, true)
	local ocf = orb.CFrame
	egg.Parent = nil
	orb.BrickColor = color1
	megaEffect.Parent = self.battle.scene
	local shrinkTimer = Utilities.Timing.easeInCubic(.3)
	Tween(1, 'easeOutCubic', function(a, t)
		cam.CFrame = camGoal * rumble()
		orb.Size = fullsize*a
		orb.CFrame = ocf
		--		orb.PointLight.Range = 20*scale*a
		if t > .5 and t < .8 then
			local sc = 1-shrinkTimer((t-.5))*.55
			sLabel.Size = UDim2.new(sc, 0, sc, 0)
			sLabel.Position = UDim2.new(.5-sc/2, 0, .5-sc/2, 0)
		end
	end)
	sLabel.Visible = false
	egg.Parent = megaEffect
	orb.Material = Enum.Material.Neon
	orb.BrickColor = color2
	--	Tween(.5, 'easeInCubic', function(a)
	--		orb.Size = fullsize*(1.05-.1*a)
	--		orb.CFrame = ocf
	--	end)
	local shellOffsets = {}
	for _, ch in pairs(egg:GetChildren()) do
		ch.BrickColor = color1
		shellOffsets[ch] = {ch.CFrame, (ch.Position - ocf.p).unit}
	end
	local stimer = Utilities.Timing.sineBack(1)
	local ecfi, ecfo = innerEffect.Hinge.CFrame, outerEffect.Hinge.CFrame
	Tween(2, 'easeInCubic', function(a)
		cam.CFrame = camGoal * rumble()
		orb.Size = fullsize*(.95+.2*a)
		orb.CFrame = ocf
		for sh, d in pairs(shellOffsets) do
			sh.CFrame = d[1] + d[2]*.4*a
		end
		innerEffect.EnergyPart.Transparency = 1-stimer(a)
		topia.EnergyPart.Transparency = 1-stimer(a)
		miniEffect.EnergyPart.Transparency = 1-stimer(a)
		outerEffect.EnergyPart.Transparency = 1-stimer(a)
		MoveModel(innerEffect.Hinge, ecfi * CFrame.Angles(a*7, 0, 0))
		MoveModel(topia.Hinge, ecfi * CFrame.Angles(a*7, 0, 0))
		MoveModel(miniEffect.Hinge, ecfi * CFrame.Angles(a*7, 0, 0))
		MoveModel(outerEffect.Hinge, ecfo * CFrame.Angles(-a*5, 0, 0))
	end)
	cam.CFrame = camGoal
	self.spriteData = megaEvolutionSpriteData
	self.offset = Vector3.new()
	self:renderNewSpriteData()
	sLabel = self.animation.spriteLabel
	local waitTime
	delay(.25, function()
		local cry = megaEvolutionSpriteData.cry
		if cry then
			if not mobile then waitTime = cry.duration end -- change if mobile gets cries
			self:playCry(nil, cry, .6)
		end
	end)
	Tween(.8, nil, function(a)
		orb.Size = fullsize*(1.15+a)
		orb.Transparency = a
		orb.CFrame = ocf
		for sh, d in pairs(shellOffsets) do
			sh.CFrame = d[1] + d[2]*(.4+15*a)
		end
		if a > .8 then
			for sh in pairs(shellOffsets) do
				sh.Transparency = (a-.8)*5
			end
		end
	end)
	megaEffect:Destroy()

	wait(waitTime and (waitTime - .15) or .5)
	lerp = select(2, Utilities.lerpCFrame(cam.CFrame, camBefore))
	spawn(function() _p.MusicManager:fadeToVolume(true, 1, .8) end)
	Tween(.8, 'easeOutCubic', function(a)
		local cf = lerp(a)
		cam.CFrame = cf--CFrame.new(cf.p, cf.p+cf.lookVector)
	end)

	for _, g in pairs(disabledGuis) do
		pcall(function() g.Visible = true end)
	end

	for _, side in pairs(self.battle.sides) do
		for _, active in pairs(side.active) do
			pcall(function()
				if active.statbar.main.Visible then
					pcall(function()
						active.statbar:update()
						active.statbar.main:update()
					end)
				end
			end)
		end
	end

end
function Sprite:animThrowBerry(brickColorName)
	if not self.battle.isSafari then return end

	local berry = storage.Models.Berry:Clone()
	local brickColor = BrickColor.new(brickColorName)
	for _, p in pairs(berry:GetChildren()) do
		if p:IsA("BasePart") then
			p.BrickColor = brickColor
		end
	end
	berry.Parent = self.battle.scene
	local main = berry.Main
	local p2 = self.battle.CoordinateFrame2 + (self.battle.CoordinateFrame1.p - self.battle.CoordinateFrame2.p).unit * 2 + Vector3.new(0, 0.1, 0)
	local rarm, gripOffset, holdDur
	local trainer = self.battle.playerModelObj
	--pcall(function()
	--	trainer.Model.HumanoidRootPart.Anchored = true
	--end)
	rarm = trainer.Model:FindFirstChild("Right Arm") or trainer.Model:FindFirstChild("RightHand")
	gripOffset = rarm and rarm.Name == "Right Arm" and 1 or 0.1675
	holdDur = rarm and rarm.Name == "Right Arm" and 0.55 or 0.45
	trainer.ThrowAnimation:Play()
	if rarm then
		do
			local trainerScale = trainer.Scale
			Tween(holdDur, nil, function()
				MoveModel(main, rarm.CFrame * CFrame.new(0, -(0.1 + gripOffset) * trainerScale, 0) * CFrame.Angles(-math.pi / 2, 0, 0), true)
			end)
		end
	else
		wait(holdDur)
	end
	local mcf = main.CFrame
	Tween(0.6, nil, function(a)
		MoveModel(main, mcf:lerp(p2, a) * CFrame.Angles(-a * 7, 0, 0) + Vector3.new(0, 2 * math.sin(a * math.pi), 0), true)
	end)
	return berry
end

function Sprite:animSpriteJump(h, t)
	local p = self.part
	local offset = h or .5
	local oPos = p.Position
	local upPos = oPos + Vector3.new(0, offset, 0)

	for i = 1, t do
		Tween(.4/t, nil, function(a)
			p.Position = oPos + Vector3.new(0, offset*a, 0)
		end)
		Tween(.4/t, nil, function(a)
			p.Position = upPos - Vector3.new(0, offset*a, 0)
		end)
	end	
end
function Sprite:animCaptureAttempt(ballId, shakes, critical, caught, isSafari)
	local pokeball = (storage.Models.Pokeballs:FindFirstChild(ballId) or storage.Models.pokeball):Clone()
	pokeball.Parent = self.battle.scene
	local p2 = (self.battle.CoordinateFrame1 + Vector3.new(0, self.part.Size.Y, 0)) * CFrame.new(0, 0, .25)
	p2 = p2 + (self.battle.CoordinateFrame2.p-self.battle.CoordinateFrame1.p)
	local p1 = p2 + (self.battle.CoordinateFrame1.p-self.battle.CoordinateFrame2.p)*1.5 + Vector3.new(0, -self.part.Size.Y+4, 0)
	delay(.5, function()
		Utilities.sound(300394723, nil, nil, 10)
		Tween(.4, 'easeOutCubic', function(a)
			MoveModel(pokeball.top.Hinge,    pokeball.Hinge.CFrame * CFrame.Angles(0, 0, a*-.5))
			MoveModel(pokeball.bottom.Hinge, pokeball.Hinge.CFrame * CFrame.Angles(0, 0, a*.5 ))
		end)
	end)
	delay(.6, function()
		local s = self.animation.spriteLabel
		s.Visible = true
		Tween(.3, 'easeInCubic', function(a)
			local o = 1-a
			s.Size = UDim2.new(o, 0, o, 0)
			s.Position = UDim2.new(.5-o/2, 0, 0.0, 0)
			s.ImageColor3 = Color3.new(o, o, o)
		end)
	end)
	if isSafari then
		local rarm, gripOffset, holdDur
		local trainer = self.battle.playerModelObj
		rarm = trainer.Model:FindFirstChild("Right Arm") or trainer.Model:FindFirstChild("RightHand")
		gripOffset = rarm and rarm.Name == "Right Arm" and 1 or 0.1675
		holdDur = rarm and rarm.Name == "Right Arm" and 0.55 or 0.45
		trainer.ThrowAnimation:Play()
		pcall(function()
			trainer.Model.HumanoidRootPart.Anchored = true
		end)
		if rarm then
			do
				local trainerScale = trainer.Scale
				Tween(holdDur, nil, function()
					MoveModel(pokeball.Main, rarm.CFrame * CFrame.new(0, -(0.1 + gripOffset) * trainerScale, 0) * CFrame.Angles(-math.pi / 2, 0, 0), true)
				end)
			end
		else
			wait(holdDur)
		end
		local mcf = pokeball.Main.CFrame
		Tween(0.6, nil, function(a)
			MoveModel(pokeball.Main, mcf:lerp(p2, a) * CFrame.Angles(-a * 7, 0, 0) + Vector3.new(0, 2 * math.sin(a * math.pi), 0), true)
		end)
		pcall(function()
			trainer.Model.HumanoidRootPart.Anchored = false
		end)
	else
		Tween(1, 'easeOutCubic', function(a)
			MoveModel(pokeball.Main, (p1+(p2.p-p1.p)*a+Vector3.new(0, math.sin(a*math.pi), 0))*CFrame.Angles(-a*6.8, 0, 0), true)
		end)
	end	
	Tween(.2, nil, function(a)
		local o = 1-a
		MoveModel(pokeball.top.Hinge,    pokeball.Hinge.CFrame * CFrame.Angles(0, 0, o*-.5))
		MoveModel(pokeball.bottom.Hinge, pokeball.Hinge.CFrame * CFrame.Angles(0, 0, o*.5 ))
	end)
	local cf = pokeball.Main.CFrame
	if critical then
		wait(.2)
		Tween(.6, nil, function(a)
			MoveModel(pokeball.Main, cf * CFrame.new(math.sin(a*math.pi*4)*(1-a)*.3, 0, 0), true)
		end)
		wait(.1)
	end
	Tween(.2*self.part.Size.Y, 'easeInQuad', function(a)
		local pos = cf.p - Vector3.new(0, (self.part.Size.Y-pokeball.Main.Size.Y/2)*a, 0)
		local look = (cf.lookVector*Vector3.new(1, 1-a, 1)).unit
		MoveModel(pokeball.Main, CFrame.new(pos, pos+look), true)
	end)
	cf = pokeball.Main.CFrame
	Tween(.5, nil, function(a)
		MoveModel(pokeball.Main, cf+Vector3.new(0, math.sin(a*math.pi)*self.part.Size.Y*.2, 0), true)
	end)
	wait(1)
	if critical and shakes == 0 then shakes = 1 end
	if shakes == 4 then shakes = 3 end
	for i = 1, shakes do
		Utilities.sound(301970857, 1, .1, 2)
		local angle = math.random()*math.pi*2
		local translate = Vector3.new(math.sin(angle), 0, math.cos(angle))
		local rotate = Vector3.new(math.sin(angle-math.pi/2), 0, math.cos(angle-math.pi/2))
		local vigor = .7+math.random()*.5
		Tween(.6, nil, function(t)
			local a = math.sin(t*3*math.pi) * (1-t)
			local theta = a*vigor
			local dist = a*pokeball.Main.Size.Y/2
			MoveModel(pokeball.Main, cf * CFrame.fromAxisAngle(rotate, theta) + translate*dist, true)
		end)
		wait(.5 + .5*math.random())
	end
	if caught then
		Utilities.sound(300394776, nil, nil, 5)
		for i = 1, 12 do
			_p.Particles:new {
				Position = cf.p,
				Velocity = Vector3.new(0, 5, 0),
				VelocityVariation = 30,
				Acceleration = Vector3.new(0, -5, 0),
				Size = .3,
				Image = 286854973,
				Color = Utilities.hsb(360*math.random(), 0.6, 1),
				Lifetime = 3,
			}
		end
		wait(.5)
	else
		delay(.125, function()
			hideAll(pokeball.top, pokeball.bottom)
			local s = self.animation.spriteLabel
			Tween(.15, 'easeOutCubic', function(a)
				s.Size = UDim2.new(a, 0, a, 0)
				s.Position = UDim2.new(.5-a/2, 0, 1-a, 0)
				s.ImageColor3 = Color3.new(a, a, a)
			end)
		end)
		Tween(.25, nil, function(a)
			local s = 5*a
			pokeball.Main.Mesh.Scale = Vector3.new(s, s, s)
			pokeball.Main.Transparency = math.abs(1-a*2)
		end)
		self:playCry()
		delay(1, function()
			pokeball:Destroy()
		end)
	end
end
-- transform
function Sprite:renderNewSpriteData(item, illusion)
	if self.use3D then
		-- 3D Model rendering path
		-- Uses spriteData from GifData for animation configuration
		if self.modelAnimator then
			local wasPlaying = not self.modelAnimator._p
			if self.modelAnimator then
				self.modelAnimator:Destroy()
			end

			-- Use spriteData (from GifData) as the animation config
			if self.spriteData and self.model3D then
				-- Create new model animator with sprite data from GifData
				self.modelAnimator = ModelAnimator.new(self.model3D, self.spriteData)

				if item then
					self.modelAnimator:PlayOnce(true)
				elseif wasPlaying then
					self.modelAnimator:Play()
				end
			end

			if illusion then
				self.pokemon.revealed = true
			end
		end
	else
		-- 2D Sprite rendering path (original logic)
		if self.animation then
			local wasPlaying = not self.animation.paused
			self.animation:destroy()

			local sd, part = self.spriteData, self.part
			if self.slot then
				local posPart = self.battle.scene:FindFirstChild('pos'..self.siden..self.slot) or self.battle.scene[self.siden == 1 and '_User' or '_Foe']
				self.cf = posPart.CFrame - Vector3.new(0, posPart.Size.y/2, 0) + Vector3.new(sd.xOffset or 0, sd.inAir or 0, 0)
				local scale
				if sd.scale then
					scale = sd.scale
				else
					scale = 1
				end
				local size = Vector3.new(sd.fWidth/25*scale, sd.fHeight/25*scale, 0.6)
				if self.alpha then
					size = size * dataChanges.alpha.size--1.25
				end
				if self.isDyna then
					size = size * dataChanges.dynamax.size
				elseif self.isRaid then
					size = size * dataChanges.dynamax.size2
				elseif self.isGmax then
					size = size * dataChanges.dynamax.size3
				end
				part.Size = size
				--	if _p.PlayerData.isDate == 'aprilfools' then
				--	self.cf = posPart.CFrame + Vector3.new(0, posPart.Size.y/2, 0)-- + Vector3.new(0, sd.inAir or 0, 0)
				--	part.CFrame = self.cf + Vector3.new(0, part.Size.y/2, 0) * CFrame.Angles(0, math.rad(180), 0)
				--else
				part.CFrame = self.cf + Vector3.new(0, part.Size.y/2, 0)
				--end
				part.Gui.CanvasSize = Vector2.new(sd.fWidth, sd.fHeight)
			end
			--if self.volatiles['dynamax'] then
			--	part.Size.X = part.Size.X * 2
			--	part.Size.Y = part.Size.Y * 2
			--	part.CFrame = self.cf + Vector3.new(0, part.Size.y/2, 0)
			--end
			local a = _p.AnimatedSprite:New(sd)
			a.spriteLabel.Parent = part.Gui
			if _p.PlayerData.isDate == 'aprilfools' then
				a.spriteLabel.Rotation = 180
			end
			if item then
				a:PlayOnce(true)
			elseif wasPlaying then
				a:Play()
			end
			self.animation = a
			if illusion then
				self.pokemon.revealed = true
			end
		end
	end
end
function Sprite:animTransform(targetPokemon, spriteForme)
	if not self.oldSpriteData then
		self.oldSpriteData = self.spriteData
	end
	if targetPokemon then
		self.pokemon.spriteSpecies = targetPokemon.spriteSpecies or targetPokemon.species or targetPokemon.name
		self.forme = targetPokemon.sprite.forme
	else
		self.forme = spriteForme
	end
	self:updateSpriteData()
	self:renderNewSpriteData()
end
function Sprite:removeTransform(species)
	if self.oldSpriteData then
		self.spriteData = self.oldSpriteData
		--		self.forme = ?
		self.oldSpriteData = nil
		self:renderNewSpriteData()
	end
end
-- substitute
function Sprite:animSub()
	if self.sub then return end
	local subModel = storage.Models.Misc.Substitute:Clone()
	subModel.Parent = self.battle.scene
	local subPos = self.cf * CFrame.new(0, self.part.Size.Y/2, 1.5 * (self.siden==1 and 1 or -1))
	subModel:PivotTo(subPos)
	self.sub = subModel
end
function Sprite:animSubFade()
	if not self.sub then return end
	local subModel = self.sub
	Tween(1, "easeInOutCubic", function(a)
		for _, part in pairs(subModel:GetChildren()) do
			if part:IsA("Part") or part:IsA("BasePart") then
				part.Transparency = a
			end
		end
	end)
	subModel:Destroy()
	self.sub = nil
end
function Sprite:removeSub()
	if not self.sub then return end
	local subModel = self.sub
	subModel:Destroy()
	self.sub = nil
end
-- move
function Sprite:beforeMove()
	local pokemon = self.pokemon
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
end
function Sprite:animateAttack()
	local pokemon = self.pokemon
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	pcall(function()
		self.spriteData = _p.DataManager:getSprite((pokemon.shiny and '_SHINY' or '')..(self.isBackSprite and '_BACK' or '_FRONT'), spriteId..'-Attack')
		self:renderNewSpriteData(true)
		self.spriteData = _p.DataManager:getSprite((pokemon.shiny and '_SHINY' or '')..(self.isBackSprite and '_BACK' or '_FRONT'), 'Marshadow')
		self:renderNewSpriteData()    
	end)
end
function Sprite:afterMove()

end
function Sprite:animReset()
	self.offset = Vector3.new()
	pcall(function() self.animation.spriteLabel.ImageTransparency = 0.0 end)
end
-- send in / out
local stampEmitter = {
	function(stamp, cf) -- fountain
		local sheetId = stamp.sheetId
		local s = stamp.n-1
		local imageRectSize = Vector2.new(200, 200)
		local imageRectOffset = Vector2.new(200*(s%5), 200*math.floor(s/5))
		local rainbow = stamp.rainbow and true or false
		local imageColor3 = stamp.color3
		local accel = 30
		local pSpread = 2
		local aSpread = 40
		local roffset = math.random(6)
		for i = 1, 6 do
			local c0 = cf * CFrame.new((pSpread*7/6)/2-pSpread/6*i, -.7, -.5)
			local t0 = math.rad((aSpread*7/6)/2-aSpread/6*i)
			local vx = 10*math.sin(t0)
			local vy = 10*math.cos(t0)*1.2
			_p.Particles:new {
				Image = sheetId,
				Color = rainbow and Color3.fromHSV(((i+roffset)%6)/6, 1, 1) or imageColor3,
				ImageRectSize = imageRectSize,
				ImageRectOffset = imageRectOffset,
				Acceleration = false,
				Lifetime = .7,
				OnUpdate = function(a, gui)
					local t = a*.7
					gui.CFrame = c0 * CFrame.new(vx*t, vy*t-.5*accel*t*t, 0)
					local s = .6+1*a
					gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
					gui.BillboardGui.ImageLabel.Rotation = -vx*30*t
					if a > .8 then
						gui.BillboardGui.ImageLabel.ImageTransparency = (a-.8)*5
					end
				end
			}
		end
	end,
	function(stamp, cf) -- explode
		local sheetId = stamp.sheetId
		local s = stamp.n-1
		local imageRectSize = Vector2.new(200, 200)
		local imageRectOffset = Vector2.new(200*(s%5), 200*math.floor(s/5))
		local rainbow = stamp.rainbow and true or false
		local imageColor3 = stamp.color3
		local twoPi = math.pi*2
		local offset = math.random()*twoPi
		for i = 1, 6 do
			local theta = offset+twoPi/6*i+.13*(math.random()-.5)
			local v = 5--2+3*math.random()
			local r = .1--.5+math.random()
			local rot = math.deg(theta)-90
			_p.Particles:new {
				Image = sheetId,
				Color = rainbow and Color3.fromHSV(i/6, 1, 1) or imageColor3,
				ImageRectSize = imageRectSize,
				ImageRectOffset = imageRectOffset,
				Position = cf * Vector3.new(math.cos(theta)*r, math.sin(theta)*r, -.5),
				--				Size = 1.3,
				Velocity = (cf-cf.p) * Vector3.new(math.cos(theta)*v, math.sin(theta)*v, 0),
				Acceleration = false,
				--				Rotation = math.deg(theta)-90,
				Lifetime = .7,--.4,--.2+.3*math.random()
				OnUpdate = function(a, gui)
					local s = .8+.8*a
					gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
					gui.BillboardGui.ImageLabel.Rotation = rot+160*(a-.5)
					if a > .8 then
						gui.BillboardGui.ImageLabel.ImageTransparency = (a-.8)*5
					end
				end
			}
		end
	end,
	function(stamp, cf) -- wave
		local sheetId = stamp.sheetId
		local s = stamp.n-1
		local imageRectSize = Vector2.new(200, 200)
		local imageRectOffset = Vector2.new(200*(s%5), 200*math.floor(s/5))
		local rainbow = stamp.rainbow and true or false
		local imageColor3 = stamp.color3
		local twoPi = math.pi*2
		local offset = math.random()*twoPi
		for i = 1, 6 do
			local theta = offset+twoPi/6*i+.13*(math.random()-.5)
			--			local v = 5--2+3*math.random()
			--			local r = .1--.5+math.random()
			local rot = math.deg(theta)-90
			_p.Particles:new {
				Image = sheetId,
				Color = rainbow and Color3.fromHSV(i/6, 1, 1) or imageColor3,
				ImageRectSize = imageRectSize,
				ImageRectOffset = imageRectOffset,
				--				Position = cf * Vector3.new(math.cos(theta)*r, math.sin(theta)*r, -.5),
				--				Size = 1.3,
				--				Velocity = (cf-cf.p) * Vector3.new(math.cos(theta)*v, math.sin(theta)*v, 0),
				Acceleration = false,
				--				Rotation = math.deg(theta)-90,
				Lifetime = .7,--.4,--.2+.3*math.random()
				OnUpdate = function(a, gui)
					local t = theta - .3*math.sin(a*9)
					local r = .1 + a*.7*5
					gui.CFrame = cf * CFrame.new(math.cos(t)*r, math.sin(t)*r, -.5)
					local s = .8+.8*a
					gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
					gui.BillboardGui.ImageLabel.Rotation = rot-90*math.cos(a*9)--+160*(a-.5)
					if a > .8 then
						gui.BillboardGui.ImageLabel.ImageTransparency = (a-.8)*5
					end
				end
			}
		end
	end,
	function(stamp, cf) -- spiral
		local sheetId = stamp.sheetId
		local s = stamp.n-1
		local imageRectSize = Vector2.new(200, 200)
		local imageRectOffset = Vector2.new(200*(s%5), 200*math.floor(s/5))
		local rainbow = stamp.rainbow and true or false
		local imageColor3 = stamp.color3
		local twoPi = math.pi*2
		local offset = math.random()*twoPi
		for i = 1, 6 do
			local theta = offset+twoPi/6*i+.13*(math.random()-.5)
			--			local v = 5--2+3*math.random()
			--			local r = .1--.5+math.random()
			local rot = math.deg(theta)-90
			_p.Particles:new {
				Image = sheetId,
				Color = rainbow and Color3.fromHSV(i/6, 1, 1) or imageColor3,
				ImageRectSize = imageRectSize,
				ImageRectOffset = imageRectOffset,
				--				Position = cf * Vector3.new(math.cos(theta)*r, math.sin(theta)*r, -.5),
				--				Size = 1.3,
				--				Velocity = (cf-cf.p) * Vector3.new(math.cos(theta)*v, math.sin(theta)*v, 0),
				Acceleration = false,
				--				Rotation = math.deg(theta)-90,
				Lifetime = .7,--.4,--.2+.3*math.random()
				OnUpdate = function(a, gui)
					local t = theta - 1.7*a
					local r = .1 + a*.7*5
					gui.CFrame = cf * CFrame.new(math.cos(t)*r, math.sin(t)*r, -.5)
					local s = .8+.8*a
					gui.BillboardGui.Size = UDim2.new(s, 0, s, 0)
					gui.BillboardGui.ImageLabel.Rotation = rot+160*(a-.5)
					if a > .8 then
						gui.BillboardGui.ImageLabel.ImageTransparency = (a-.8)*5
					end
				end
			}
		end
	end
}
function Sprite:animSummon(slot, msgFn, isSecondary)
	self.slot = slot
	while not self.spriteData do runService.RenderStepped:wait() end
	local sd = self.spriteData

	-- Only create 2D part if NOT using 3D
	if not self.use3D then
		if not self.part then
			local posPart = self.battle.scene:FindFirstChild('pos'..self.siden..slot) or self.battle.scene[self.siden == 1 and '_User' or '_Foe']
			self.cf = posPart.CFrame - Vector3.new(0, posPart.Size.y/2, 0) + Vector3.new(sd.xOffset or 0, sd.inAir or 0, 0)
			local part = posPart:Clone()
			local scale = 1
			if sd.scale then
				scale = sd.scale
			else
				scale = 1
			end
			local size = Vector3.new(sd.fWidth/25*scale, sd.fHeight/25*scale, 0.6)
			if self.alpha then
				size = size * dataChanges.alpha.size
			end
			part.Size = size
			--if _p.PlayerData.isDate == 'aprilfools' then
			--	self.cf = posPart.CFrame + Vector3.new(0, posPart.Size.y/2, 0)-- + Vector3.new(0, sd.inAir or 0, 0)
			--	part.CFrame = (self.cf + Vector3.new(0, part.Size.y/2, 0)) * CFrame.Angles(0, math.rad(180), 0)
			--else
			part.CFrame = self.cf + Vector3.new(0, part.Size.y/2, 0)
			--end
			part.Gui.CanvasSize = Vector2.new(sd.fWidth, sd.fHeight)
			part.Name = 'Part'
			part.Parent = self.battle.scene
			self.part = part
		else
			local posPart = self.battle.scene:FindFirstChild('pos'..self.siden..slot) or self.battle.scene[self.siden == 1 and '_User' or '_Foe']
			self.cf = posPart.CFrame - Vector3.new(0, posPart.Size.y/2, 0) + Vector3.new(sd.xOffset or 0, sd.inAir or 0, 0)
			local part = self.part
			--if _p.PlayerData.isDate == 'aprilfools' then
			--	self.cf = posPart.CFrame + Vector3.new(0, posPart.Size.y/2, 0)-- + Vector3.new(0, sd.inAir or 0, 0)
			--	part.CFrame = (self.cf + Vector3.new(0, part.Size.y/2, 0)) * CFrame.Angles(0, math.rad(180), 0)
			--else
			part.CFrame = self.cf + Vector3.new(0, part.Size.y/2, 0)
			--end
		end
	end

	if self.use3D then
		-- 3D Model creation path
		-- Uses spriteData from GifData for animation, modelId from modelsData
		print("[3D BATTLES] Attempting to load 3D model for", self.pokemon.species or self.pokemon.name)
		if not self.modelAnimator then
			local modelId = self:get3DModelId()
			print("[3D BATTLES] Model ID:", modelId)
			if modelId then
				-- Load the 3D model from storage
				local modelAsset
				if type(modelId) == "string" then
					-- Model name provided
					modelAsset = storage.Models:FindFirstChild(modelId)
					print("[3D BATTLES] Looking for model by name:", modelId, "Found:", modelAsset ~= nil)
				elseif type(modelId) == "number" then
					-- Asset ID provided - try to load from InsertService or use existing
					modelAsset = storage.Models:FindFirstChild(self.pokemon.species)
					print("[3D BATTLES] Looking for model by species:", self.pokemon.species, "Found:", modelAsset ~= nil)
				end

				if modelAsset then
					print("[3D BATTLES] Loading 3D model for", self.pokemon.species)
					self.model3D = modelAsset:Clone()
					self.model3D.Parent = self.battle.scene

					-- Position the model at the battle position using spriteData config
					local posPart = self.battle.scene:FindFirstChild('pos'..self.siden..slot) or self.battle.scene[self.siden == 1 and '_User' or '_Foe']
					local scale = sd.scale or 1.0
					if self.alpha then
						scale = scale * dataChanges.alpha.size
					end

					-- Set model position using GifData offsets
					if self.model3D.PrimaryPart then
						self.model3D:ScaleTo(scale)
						self.model3D:MoveTo(posPart.Position + Vector3.new(sd.xOffset or 0, sd.inAir or 0, 0))
					end

					-- Create model animator using sprite data from GifData
					self.modelAnimator = ModelAnimator.new(self.model3D, sd)
					self.modelAnimator:Play()
					print("[3D BATTLES] 3D model loaded and animating!")
				else
					-- Fallback to 2D if model not found
					warn(string.format("[3D BATTLES] 3D model not found for %s (ID: %s), falling back to 2D sprite", self.pokemon.species, tostring(modelId)))
					self.use3D = false
				end
			else
				-- Fallback to 2D if no model ID in modelsData
				print("[3D BATTLES] No model ID found in modelsData for", self.pokemon.species, "- falling back to 2D")
				self.use3D = false
			end
		else
			self.modelAnimator:Play()
		end
	end

	-- Ensure 2D part exists when not using 3D (handles fallback from 3D and initial 2D)
	if not self.use3D and not self.part then
		print("[2D FALLBACK] Creating 2D part for", self.pokemon.species)
		local posPart = self.battle.scene:FindFirstChild('pos'..self.siden..slot) or self.battle.scene[self.siden == 1 and '_User' or '_Foe']
		print("[2D FALLBACK] posPart:", posPart)
		if posPart then
			self.cf = posPart.CFrame - Vector3.new(0, posPart.Size.y/2, 0) + Vector3.new(sd.xOffset or 0, sd.inAir or 0, 0)
			local part = posPart:Clone()
			print("[2D FALLBACK] part cloned:", part ~= nil, "has Gui:", part and part:FindFirstChild("Gui") ~= nil)
			local scale = sd.scale or 1
			local size = Vector3.new(sd.fWidth/25*scale, sd.fHeight/25*scale, 0.6)
			if self.alpha then
				size = size * dataChanges.alpha.size
			end
			part.Size = size
			part.CFrame = self.cf + Vector3.new(0, part.Size.y/2, 0)
			if part:FindFirstChild("Gui") then
				part.Gui.CanvasSize = Vector2.new(sd.fWidth, sd.fHeight)
			else
				warn("[2D FALLBACK] Cloned part has no Gui child!")
			end
			part.Name = 'Part'
			part.Parent = self.battle.scene
			self.part = part
			print("[2D FALLBACK] self.part created successfully")
		else
			warn("[2D FALLBACK] Failed to find posPart for slot", slot)
		end
	end

	if not self.use3D then
		-- 2D Sprite creation path (original logic)
		if not self.animation then
			local a = _p.AnimatedSprite:New(sd)
			a.spriteLabel.Visible = false
			if self.part and self.part.Gui then
				a.spriteLabel.Parent = self.part.Gui
			else
				warn("[2D ANIMATION] self.part or self.part.Gui is nil!")
			end
			if _p.PlayerData.isDate == 'aprilfools' then
				a.spriteLabel.Rotation = 180
			end
			self.animation = a
		end

		self.animation:Play()
	end
	local customSparkle
	local pokemon = self.pokemon
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	local pdata = _p.DataManager:getData('Pokedex', pokemon.num)

	--	print(spriteId, pokemon.forme)
	if self.forme == 'shadow' then

	elseif self.alpha then
		customSparkle = function()
			Utilities.sound(569564686, 1.5, nil, 5)
		end
	end
	local function sparkle()
		if type(customSparkle) == 'function' then
			customSparkle()
			if not self.pokemon.shiny then
				return
			end
			customSparkle = nil
		end
		Utilities.sound(282237234, nil, nil, 5)
		local nsk = NumberSequenceKeypoint.new
		local newSparkles = create("ParticleEmitter")({
			Name = "Aura",
			Texture = "rbxassetid://771860314",
			ZOffset = 0.71,
			LightEmission = 0.2,
			Size = NumberSequence.new({
				nsk(0, 0, 0),
				nsk(0.5, 0.15, 0.05),
				nsk(1, 0, 0)
			}),
			Acceleration = Vector3.new(0, 0, 0),
			Lifetime = NumberRange.new(2),
			Rate = 5,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-150, 150),
			Speed = NumberRange.new(0),
			Parent = self.part
		})
		local p = self.part
		for _ = 1, 8 do
			for _ = 1, 3 do
				local theta = math.random()*math.pi*2
				_p.Particles:new {
					Image = customSparkle or 280857070,
					Position = p.Position + Vector3.new(math.cos(theta)*(p.Size.x/2+1)*math.random(), -p.Size.Y*.5*math.random(), math.sin(theta)*(p.Size.x/2+1)*math.random()),
					Size = .25+.75*math.random(),
					ImageColor3 = Utilities.hsb(360*math.random(), 0.6, 1),
					Velocity = Vector3.new(0, 1+7*math.random(), 0),
					VelocityVariation = 15,
					Acceleration = Vector3.new(0, 5, 0),
					Lifetime = .2+.3*math.random()
				}
			end
			wait(.125)
		end
	end
	--
	if self.battle.kind == 'wild' and self.siden == 2 then
		self.animation.spriteLabel.Visible = true
		if customSparkle or self.pokemon.shiny then delay(.5, sparkle) end

		return
	end
	self.animation:Play()

	local pokemon = self.pokemon
	local illusionCheck = pokemon.baseSpecies == "Zoroark"
	pokemon.revealed = not illusionCheck
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	if self.part:FindFirstChild('ParticleEmitter') then
		self.part:FindFirstChild('ParticleEmitter'):Destroy()
	end

	local trainer
	if self.siden == 1 then
		trainer = self.battle['playerModelObj'..slot] or self.battle.playerModelObj
	else
		trainer = self.battle['trainerModelObj'..slot] or self.battle.trainerModelObj
	end
	if trainer and not isSecondary then
		if trainer.faded then
			trainer = nil
		else
			trainer.faded = true
		end
	end
	if self.battle.fastForward then
		self.animation.spriteLabel.Visible = true
		if trainer and not isSecondary then
			trainer.Model.Parent = nil
			trainer.Root.CFrame = trainer.Root.CFrame * CFrame.new(0, 8, 0)
			for _, p in pairs(Utilities.GetDescendants(trainer.Model, 'BasePart')) do
				p.Transparency = 1.0
			end
		end
		return
	end

	local ballName = 'pokeball'
	pcall(function() if self.pokemon.pokeball then ballName = _p.Pokemon:getPokeBall(self.pokemon.pokeball) end end)
	local pokeball = (storage.Models.Pokeballs:FindFirstChild(ballName) or storage.Models.pokeball):Clone()
	local function check(model) for _, p in pairs(model:GetChildren()) do if p:IsA('BasePart') then p.Anchored = true p.CanCollide = false end check(p) end end check(pokeball)
	pokeball.Parent = self.battle.scene
	local p2; do
		local cf = self.battle['CoordinateFrame'..self.siden]
		p2 = (cf - cf.p + self.part.Position + Vector3.new(0, self.part.Size.Y/2, 0)) * CFrame.new(0, 0, .25)
	end
	local p1 = p2 * CFrame.new(0, 0, 4)

	local speed = 1
	local rarm, gripOffset, holdDur
	if trainer then -- pokeball grows in hand
		rarm = trainer.Model:FindFirstChild('Right Arm') or trainer.Model:FindFirstChild('RightHand')
		gripOffset = (rarm.Name=='Right Arm') and 1 or .335/2
		holdDur    = (rarm.Name=='Right Arm') and .55 or .45
		if rarm then
			local trainerScale = trainer.Scale
			local scale = Utilities.ScaleModel
			local main = pokeball.Main
			local lastScale = 1
			Tween(.6/speed, 'easeOutCubic', function(a)
				local newScale = .5 + .5*a
				scale(main, newScale / lastScale, true)
				lastScale = newScale
				MoveModel(main, rarm.CFrame * CFrame.new(0, -(newScale*.5+gripOffset)*trainerScale, 0) * CFrame.Angles(-math.pi/2, 0, 0), true)
			end)
			--			wait(.15/speed)
		end
	end
	delay(.8/speed, function() -- cry & ball sounds
		local v = .2
		local sound = Utilities.sound(300394663, v, nil, 5)
		wait(.5/speed)
		delay(.25/speed, function()
			if self.alpha then
				self:playCry(.75, nil, .75)
			else
				self:playCry()
			end
		end)
		Utilities.Tween(2.5/speed, nil, function(a)
			sound.Volume = (1-a)*v
		end)
	end)
	if msgFn then
		spawn(msgFn)
	end
	delay(.5/speed, function() -- pokeball opening
		Tween(.4/speed, 'easeOutCubic', function(a)
			MoveModel(pokeball.top.Hinge,    pokeball.Hinge.CFrame * CFrame.Angles(0, 0, a*-.5))
			MoveModel(pokeball.bottom.Hinge, pokeball.Hinge.CFrame * CFrame.Angles(0, 0, a*.5 ))
		end)
	end)

	delay(.9/speed, function() -- pokemon growing from small / fading in from black
		local s = self.animation.spriteLabel

		if self.alpha then
			pdata.weightkg = pdata.weightkg * dataChanges.alpha.weight
		end
		s.Visible = true
		local scf = self.part.CFrame
		local fallHeight = .5
		if sd.inAir then
			fallHeight = 0
		end
		s.Position = UDim2.new(0, 0, -fallHeight, 0)
		Tween(.3/speed, 'easeInCubic', function(a)
			s.Size = UDim2.new(a, 0, a, 0)
			s.Position = UDim2.new(.5-a/2, 0, -fallHeight*a, 0)--s.Position = UDim2.new(.5-a/2, 0, 0.0, 0)
			s.ImageColor3 = Color3.new(a, a, a)
		end)
		if not sd.inAir then
			wait(.2)
			local CFRAME = workspace.CurrentCamera.CFrame
			local function shake(vig, dur)
				Utilities.Tween(dur or 1.2, nil, function(a)
					local r = (1-a)*vig
					local t = math.random()*math.pi*2
					workspace.CurrentCamera.CFrame = CFRAME * CFrame.new(0, math.cos(t)*r, 0)
				end)
			end


			Tween(.4, "easeInCubic", function(a)
				s.Position = UDim2.new(0, 0, -0.5+.5*a, 0)
			end)
			local shakeValue = .025
			local values = {
				ground = {
					{15, 0, 315912428, .025},
					{30, 15, 315912428, .05},
					{50, 30, 315912428, .1},
					{100, 50, 1014910006, .2},
					{150, 100, 514867425, .5},
					{9999, 150, 6271036229, .7},
				},
				water = {
					{15, 0, 7058273073, .025},
					{30, 15, 7058273073, .05},
					{50, 30, 7058273073, .1},
					{100, 50, 137304720, .2},
					{150, 100, 5564174993, .5},
					{9999, 150, 8031010108, .7},
				},
			}
			local gType = 'ground'
			if self.battle.scene.Name == 'ShallowWater' then
				gType = 'water'
			end
			for i, p in pairs(values[gType]) do
				if (pdata.weightkg < p[1] and pdata.weightkg > p[2]) or i == #values then
					shakeValue = p[4]
					Utilities.sound(p[3])
					shake(shakeValue, .3)
					break
				end
			end
		end


	end)
	if pokemon.pbs then -- poke ball stamps
		delay(.8/speed, function()
			for _, stamp in pairs(pokemon.pbs) do
				local pos = pokeball.Main.Position
				local cf = self.part.CFrame
				cf = cf-cf.p+pos
				pcall(function() stampEmitter[stamp.style](stamp, cf) end)
				wait(.1)
			end
		end)
	end
	delay(.8/speed, function() -- white flash expand effect, ball disappear
		delay(.25/speed, function()
			hideAll(pokeball.top, pokeball.bottom)
			if pokeball:FindFirstChild('Ball') then
				pokeball.Ball.Transparency = 1
			end
		end)
		Tween(.5/speed, nil, function(a)
			local s = 5*a
			pokeball.Main.Mesh.Scale = Vector3.new(s, s, s)
			pokeball.Main.Transparency = .5+.5*math.abs(1-a*2)
		end)
	end)

	-- main ball movement
	if trainer then -- throw from arm
		local main = pokeball.Main
		--		local holdDur = .55
		if not isSecondary then
			trainer.ThrowAnimation:Play(nil, nil, speed)
			local v = create 'BodyVelocity' {
				MaxForce = Vector3.new(math.huge, 0, math.huge),
				Velocity = trainer.CFrame.lookVector*-8*speed,
				Parent = trainer.Root,
			}
			delay(1/speed, function()
				v:Destroy()
				trainer.Model.Parent = nil
			end)
			if self.siden == 2 then
				local root = trainer.Root
				local parts = {}
				local function check(obj)
					for _, p in pairs(obj:GetChildren()) do
						if p:IsA('BasePart') and p ~= root then
							parts[p] = p.Transparency
						elseif p:IsA('Model') then
							check(p)
						end
					end
				end
				check(trainer.Model)
				spawn(function()
					Tween(1/speed, nil, function(a)
						if a > .5 then
							local ta = (a-.5)*2
							for p, t in pairs(parts) do
								p.Transparency = t + (1-t)*ta
							end
						end
					end)
				end)
			end
		end
		if rarm then
			local trainerScale = trainer.Scale
			Tween(holdDur/speed, nil, function()
				MoveModel(main, rarm.CFrame * CFrame.new(0, -(.5+gripOffset)*trainerScale, 0) * CFrame.Angles(-math.pi/2, 0, 0), true)
			end)
		else
			wait(holdDur/speed)
		end
		local lerp = select(2, Utilities.lerpCFrame(main.CFrame, p2))
		Tween(1/speed, 'easeOutCubic', function(a)
			MoveModel(main, lerp(a) * CFrame.Angles(-a*7, 0, 0) + Vector3.new(0, math.sin(a*math.pi), 0), true)
		end)
	else -- throw from air
		Tween(1/speed, 'easeOutCubic', function(a)
			MoveModel(pokeball.Main, (p1+(p2.p-p1.p)*a+Vector3.new(0, math.sin(a*math.pi), 0))*CFrame.Angles(-a*7, 0, 0), true)
		end)
	end
	--
	delay(1/speed, function() -- ball cleanup
		pokeball:Destroy()
	end)
	wait(.25)
	if customSparkle or self.pokemon.shiny then -- shiny sparkle
		sparkle()
		wait(.2)
	end
	wait(.4)
end
function Sprite:animUnsummon()
	if self.battle.fastForward then
		if self.use3D then
			-- Cleanup 3D model
			if self.modelAnimator then
				self.modelAnimator:Pause()
			end
			if self.model3D then
				self.model3D.Parent = nil
			end
		else
			self.animation.spriteLabel.Visible = false
			self.animation:Pause()
		end
		return
	end
	local pos = (self.part.CFrame*CFrame.new(0, -self.part.Size.Y/2+1, 0)).p
	local cf = self.battle['CoordinateFrame'..self.siden]
	cf = cf - cf.p + pos
	--	local p, s = Utilities.extents(pos, 2)

	local part = create 'Part' {
		Transparency = 1.0,
		Anchored = true,
		CanCollide = false,
		--		FormFactor = Enum.FormFactor.Custom,
		Size = Vector3.new(.2, .2, .2),
		CFrame = CFrame.new(pos),
		Parent = workspace,
	}
	local orb = create 'ImageLabel' {
		BackgroundTransparency = 1.0,
		Image = 'rbxassetid://6604459090',
		create 'ImageLabel' {
			BackgroundTransparency = 1.0,
			Image = 'rbxassetid://6604459090',
			Size = UDim2.new(0.5, 0, 0.5, 0),
			Position = UDim2.new(0.25, 0, 0.25, 0),
		},
		Parent = create 'BillboardGui' {
			Size = UDim2.new(1.5, 0, 1.5, 0),
			Parent = part,
		}
	}

	Utilities.sound(300394866, nil, .2, 8)

	if self.use3D then
		-- 3D model recall animation
		if self.modelAnimator then
			-- Tween the model shrinking into the orb
			Tween(.5, 'easeInCubic', function(a)
				orb.Size = UDim2.new(a, 0, a, 0)
				orb.Position = UDim2.new(0.5-a/2, 0, 0.5-a/2, 0)
				if self.model3D and self.model3D.PrimaryPart then
					local o = 1-a
					self.model3D:ScaleTo(o)
				end
			end)
			self.modelAnimator:Pause()
			if self.model3D then
				self.model3D.Parent = nil
			end
		end
	else
		-- 2D sprite recall animation
		local sprite = self.animation.spriteLabel
		local offset = (self.part.Size.Y-1)/self.part.Size.Y - .5
		Tween(.5, 'easeInCubic', function(a)
			orb.Size = UDim2.new(a, 0, a, 0)
			orb.Position = UDim2.new(0.5-a/2, 0, 0.5-a/2, 0)
			local o = 1-a
			sprite.Size = UDim2.new(o, 0, o, 0)
			sprite.Position = UDim2.new(0.5-o/2, 0, 0.5-o/2+offset*a, 0)
		end)
		sprite.Visible = false
		if self.pokemon.shiny then
			self.part.Aura:destroy()
		end

		self.animation:Pause()
	end
	local timerx = Utilities.Timing.easeInCubic(1)
	local timery = Utilities.Timing.easeOutCubic(1)
	local lastp = 0
	Tween(.75, nil, function(a)
		local cf = cf + Vector3.new(0, timery(a)*2, 0) - cf.lookVector*a*4.5
		part.CFrame = cf
		if a-lastp > .1 then
			lastp = a
			_p.Particles:new {
				Image = 6604459090,
				Position = cf.p,
				Size = .25+.5*math.random(),
				Velocity = Vector3.new(0, 1+7*math.random(), 0),
				VelocityVariation = 10,
				Acceleration = Vector3.new(0, 2, 0),
				Lifetime = .2+.25*math.random(),
			}
		end
	end)
	part:Destroy()
end
function Sprite:animDragIn(slot)
	self:animSummon(slot) --
end
function Sprite:animDragOut()
	self.pokemon.statbar:slideOffscreen(true)
	self.pokemon.statbar = nil

	if self.battle.fastForward then
		if self.use3D then
			if self.modelAnimator then
				self.modelAnimator:Pause()
			end
			if self.model3D then
				self.model3D.Parent = nil
			end
		else
			self.animation.spriteLabel.Visible = false
			self.animation:Pause()
		end
		return
	end

	local dir = -self.battle['CoordinateFrame'..self.siden].lookVector

	if self.use3D then
		-- 3D model drag out
		if self.model3D and self.model3D.PrimaryPart then
			local startCF = self.model3D.PrimaryPart.CFrame
			Utilities.Tween(.5, nil, function(a)
				self.offset = dir*3*a
				if self.model3D and self.model3D.PrimaryPart then
					-- Fade out the model by making parts transparent
					for _, part in pairs(self.model3D:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = a
						end
					end
				end
			end)
		end
		if self.modelAnimator then
			self.modelAnimator:Pause()
		end
		if self.model3D then
			self.model3D.Parent = nil
		end
	else
		-- 2D sprite drag out
		local part = self.part
		local sprite = self.animation.spriteLabel
		local cf = part.CFrame
		Utilities.Tween(.5, nil, function(a)
			self.offset = dir*3*a
			--		part.CFrame = cf + dir*3*a
			sprite.ImageTransparency = a
		end)
		sprite.Visible = false
		sprite.ImageTransparency = 0.0
		self.animation:Pause()
		if self.pokemon.shiny then
			self.part.Aura:destroy()
		end
	end

	self.offset = nil
	--	part.CFrame = cf
end
function Sprite:animFaint()
	if not self.battle.fastForward then
		self:playCry(0.75)
	end
	if self.battle.kind == 'wild' and self.siden == 2 then
		delay(.5, function()
			self.pokemon.statbar:slideOffscreen(true)
			self.pokemon.statbar = nil
		end)

		if self.use3D then
			-- 3D model faint animation for wild battles
			-- Use spriteData from GifData for positioning
			local inAir = (self.spriteData and self.spriteData.inAir) or 0
			local xOffset = (self.spriteData and self.spriteData.xOffset) or 0

			Utilities.Tween(1, 'easeInCubic', function(a)
				self.offset = Vector3.new(xOffset*a, -inAir * a, 0)
				if self.model3D then
					local o = 1-a
					-- Fade and shrink the model
					for _, part in pairs(self.model3D:GetDescendants()) do
						if part:IsA("BasePart") then
							part.Transparency = part.Transparency + a * (1 - part.Transparency)
						end
					end
					if self.model3D.PrimaryPart then
						self.model3D:ScaleTo(o)
					end
				end
			end)
			if self.model3D then
				self.model3D.Parent = nil
			end
			if self.modelAnimator then
				self.modelAnimator:Pause()
			end
		else
			-- 2D sprite faint animation for wild battles
			local s = self.animation.spriteLabel
			local inAir = self.spriteData.inAir or 0
			local xOffset = self.spriteData.xOffset or 0

			Utilities.Tween(1, 'easeInCubic', function(a)
				self.offset = Vector3.new(xOffset*a, -inAir * a, 0)
				local o = 1-a
				s.Size = UDim2.new(o, 0, o, 0)
				s.Position = UDim2.new(.5-o/2, 0, a, 0)
				s.ImageColor3 = Color3.new(o, o, o)
			end)
			s.Visible = false
		end
	else
		self.pokemon.statbar:slideOffscreen(true)
		self.pokemon.statbar = nil
		self:animUnsummon()
	end
end

function Sprite:Animgmax(Gmax)
	local pokemon = self.pokemon
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	if Gmax then
		pcall(function()
			self.spriteData = _p.DataManager:getSprite((pokemon.shiny and '_SHINY' or '')..(self.isBackSprite and '_BACK' or '_FRONT'), spriteId..'-Gmax')
			self:renderNewSpriteData()    
		end)
	else
		pcall(function()
			self.spriteData = _p.DataManager:getSprite((pokemon.shiny and '_SHINY' or '')..(self.isBackSprite and '_BACK' or '_FRONT'), spriteId)
			self:renderNewSpriteData()    
		end)	
	end
end

-- Gigantamax
function Sprite:animGMax(poke, battle)
	self:animGUnsummon()
	task.wait(.5)
	battle:animGMax(battle, poke)
	self:animGSummon()
end
function Sprite:animGUnsummon()
	if self.battle.fastForward then
		self.animation:Pause()
		return
	end

	local pos = (self.part.CFrame * CFrame.new(0, -self.part.Size.Y/2+1, 0)).p
	local cf = self.battle["CoordinateFrame"..self.siden]

	cf = cf - cf.p + pos

	local part = create("Part")({
		Transparency = 1.0,
		Anchored = true,
		CanCollide = false,
		Size = Vector3.new(.2, .2, .2),
		CFrame = CFrame.new(pos),
		Parent = workspace
	})

	local orb = create("ImageLabel")({
		BackgroundTransparency = 1.0,
		Image = "rbxassetid://6604459090",

		create("ImageLabel")({
			BackgroundTransparency = 1.0,
			Image = "rbxassetid://6604459090",
			Size = UDim2.new(.5, 0, .5, 0),
			Position = UDim2.new(.25, 0, .25, 0)
		}),

		Parent = create("BillboardGui")({
			Size = UDim2.new(1.5, 0, 1.5, 0),
			Parent = part
		}),
	})

	Utilities.sound(300394866, nil, .2, 8)

	local sprite = self.animation.spriteLabel
	Utilities.Tween(.5, "easeInCubic", function(a)
		orb.Size = UDim2.new(a, 0, a, 0)
		orb.Position = UDim2.new(0.5-a/2, 0, 0.5-a/2, 0)
	end)

	sprite.Visible = false

	local timerX = Utilities.Timing.easeInCubic(1)
	local timerY = Utilities.Timing.easeOutCubic(1)
	local lastP = 0

	Utilities.Tween(.75, nil, function(a)
		cf = cf + Vector3.new(0, timerY(a)*2, 0) - cf.lookVector*a*4.5
		part.CFrame = cf
		if a - lastP > .1 then
			lastP = a
			_p.Particles:new({
				Image = 6604459090,
				Position = cf.p,
				Size = .25+.5*math.random(),
				Velocity = Vector3.new(0, 1+7*math.random(), 0),
				VelocityVariation = 10,
				Acceleration = Vector3.new(0, 2, 0),
				Lifetime = .2+.25*math.random()
			})
		end
	end)
	self.animation.spriteLabel.Visible = false
	part:Destroy()
end
function Sprite:animGSummon()
	while not self.spriteData do
		runService.RenderStepped:wait()
	end

	local spriteData = self.spriteData

	self.animation:Play()
	local pokemon = self.pokemon
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name

	local speed = 1
	local trainer
	local p1, p2
	local rightArm, gripOffset, holdDur

	self.animation:Play()
	self.animation.spriteLabel.Visible = false

	pokemon = self.pokemon
	spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	local ParticleEmitter = self.part:FindFirstChild("ParticleEmitter")
	if ParticleEmitter then
		ParticleEmitter:Destroy()
	end
	--gigantamaxball
	local gigantamaxball = (storage.Models.Pokeballs:FindFirstChild("dynamaxball")):Clone()
	local function check(model: Model)
		for _, part in pairs(model:GetChildren()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
			check(part)
		end
	end
	check(gigantamaxball)
	gigantamaxball.Parent = self.battle.scene

	do
		local cf = self.battle['CoordinateFrame'..self.siden]
		p2 = (cf - cf.p + self.part.Position + Vector3.new(0, self.part.Size.Y/2, 0)) * CFrame.new(0, 0, .25)
	end
	p1 = p2 * CFrame.new(0, 0, 4)

	-- Cry & Ball sounds
	task.delay(.8 / speed, function()
		local volume = .2
		local sound = Utilities.sound(300394663, volume, nil, 6)

		task.wait(.5 / speed)
		task.delay(.25 / speed, function()
			self:playCry()
		end)

		Utilities.Tween(2.5 / speed, nil, function(a)
			sound.Volume = (1 - a) * volume
		end)
	end)

	-- Pokeball opening
	task.delay(.5 / speed, function()
		Utilities.Tween(.4 / speed, "easeOutCubic", function(a)
			Utilities.MoveModel(gigantamaxball.top.Hinge, gigantamaxball.Hinge.CFrame * CFrame.Angles(0, 0, a*-.5))
			Utilities.MoveModel(gigantamaxball.bottom.Hinge, gigantamaxball.Hinge.CFrame * CFrame.Angles(0, 0, a*-.5))
		end)
	end)

	-- Pokemon growing from small / fading in from black
	task.delay(.9 / speed, function()
		local spriteLabel = self.animation.spriteLabel
		spriteLabel.Visible = false

		Utilities.Tween(.3 / speed, "easeInCubic", function(a)
			spriteLabel.Size = UDim2.new(a, 0, a, 0)
			spriteLabel.Position = UDim2.new(.5-a/2, 0, 0, 0)
			spriteLabel.ImageColor3 = Color3.new(a, a, a)
		end)
	end)

	-- White flash expand effect, ball dissappear
	task.delay(.8 / speed, function()
		task.delay(.25 / speed, function()
			hideAll(gigantamaxball.top, gigantamaxball.bottom)
		end)

		Utilities.Tween(.5 / speed, nil, function(a)
			local s = 5*a
			gigantamaxball.Main.Mesh.Scale = Vector3.new(s, s, s)
			gigantamaxball.Main.Transparency = .5+.5*math.abs(1-a*2)
		end)
	end)

	-- Main ball movement
	Utilities.Tween(1 / speed, "easeOutCubic", function(a)
		Utilities.MoveModel(gigantamaxball.Main, (p1+(p2.p-p1.p)*a+Vector3.new(0, math.sin(a*math.pi), 0))*CFrame.Angles(-a*7, 0, 0), true)
	end)

	-- Ball cleanup
	task.delay(1 / speed, function()
		gigantamaxball:Destroy()
	end)

	-- Render sprite data
	task.wait(.25)
	pcall(function()
		self.spriteData = _p.DataManager:getSprite((pokemon.shiny and "_SHINY" or "")..(self.isBackSprite and "_BACK" or "_FRONT"), spriteId.."-Gmax")
		self:renderNewSpriteData()
	end)
	self.animation.spriteLabel.Visible = true
end

-- Dynamax
function Sprite:animDMax(poke, battle)
	if storage.Models.Max.Value == 'Gmax' then
		self:animGMax(poke, battle)
		return
	end
	self:animDUnsummon()
	task.wait(0.5)
	--battle:animGMax(battle, poke)
	self:animDSummon()
end
function Sprite:animDUnsummon()
	if self.battle.fastForward then
		self.animation:Pause()
		return
	end

	local pos = (self.part.CFrame * CFrame.new(0, -self.part.Size.Y/2+1, 0)).p
	local cf = self.battle["CoordinateFrame"..self.siden]

	cf = cf - cf.p + pos

	local part = create("Part")({
		Transparency = 1.0,
		Anchored = true,
		CanCollide = false,
		Size = Vector3.new(.2, .2, .2),
		CFrame = CFrame.new(pos),
		Parent = workspace
	})

	local orb = create("ImageLabel")({
		BackgroundTransparency = 1.0,
		Image = "rbxassetid://6604459090",

		create("ImageLabel")({
			BackgroundTransparency = 1.0,
			Image = "rbxassetid://6604459090",
			Size = UDim2.new(.5, 0, .5, 0),
			Position = UDim2.new(.25, 0, .25, 0)
		}),

		Parent = create("BillboardGui")({
			Size = UDim2.new(1.5, 0, 1.5, 0),
			Parent = part
		}),
	})

	Utilities.sound(300394866, nil, .2, 8)

	local sprite = self.animation.spriteLabel
	Utilities.Tween(.5, "easeInCubic", function(a)
		orb.Size = UDim2.new(a, 0, a, 0)
		orb.Position = UDim2.new(0.5-a/2, 0, 0.5-a/2, 0)
	end)

	sprite.Visible = false

	local timerX = Utilities.Timing.easeInCubic(1)
	local timerY = Utilities.Timing.easeOutCubic(1)
	local lastP = 0

	Utilities.Tween(.75, nil, function(a)
		cf = cf + Vector3.new(0, timerY(a)*2, 0) - cf.lookVector*a*4.5
		part.CFrame = cf
		if a - lastP > .1 then
			lastP = a
			_p.Particles:new({
				Image = 6604459090,
				Position = cf.p,
				Size = .25+.5*math.random(),
				Velocity = Vector3.new(0, 1+7*math.random(), 0),
				VelocityVariation = 10,
				Acceleration = Vector3.new(0, 2, 0),
				Lifetime = .2+.25*math.random()
			})
		end
	end)
	part:Destroy()
	self.animation.spriteLabel.Visible = false
end
function Sprite:animDSummon()
	while not self.spriteData do
		runService.RenderStepped:wait()
	end

	local spriteData = self.spriteData

	self.animation:Play()
	local pokemon = self.pokemon
	local spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name

	local speed = 1
	local trainer
	local p1, p2
	local rightArm, gripOffset, holdDur

	self.animation:Play()
	self.animation.spriteLabel.Visible = false

	pokemon = self.pokemon
	spriteId = pokemon.spriteSpecies or pokemon.species or pokemon.name
	local ParticleEmitter = self.part:FindFirstChild("ParticleEmitter")
	if ParticleEmitter then
		ParticleEmitter:Destroy()
	end
	--gigantamaxball
	local gigantamaxball = (storage.Models.Pokeballs:FindFirstChild("dynamaxball")):Clone()
	local function check(model: Model)
		for _, part in pairs(model:GetChildren()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
			end
			check(part)
		end
	end
	check(gigantamaxball)
	gigantamaxball.Parent = self.battle.scene

	do
		local cf = self.battle['CoordinateFrame'..self.siden]
		p2 = (cf - cf.p + self.part.Position + Vector3.new(0, self.part.Size.Y/2, 0)) * CFrame.new(0, 0, .25)
	end
	p1 = p2 * CFrame.new(0, 0, 4)

	-- Cry & Ball sounds
	task.delay(.8 / speed, function()
		local volume = .2
		local sound = Utilities.sound(300394663, volume, nil, 6)

		task.wait(.5 / speed)
		task.delay(.25 / speed, function()
			self:playCry()
		end)

		Utilities.Tween(2.5 / speed, nil, function(a)
			sound.Volume = (1 - a) * volume
		end)
	end)

	-- Pokeball opening
	task.delay(.5 / speed, function()
		Utilities.Tween(.4 / speed, "easeOutCubic", function(a)
			Utilities.MoveModel(gigantamaxball.top.Hinge, gigantamaxball.Hinge.CFrame * CFrame.Angles(0, 0, a*-.5))
			Utilities.MoveModel(gigantamaxball.bottom.Hinge, gigantamaxball.Hinge.CFrame * CFrame.Angles(0, 0, a*-.5))
		end)
	end)

	-- Pokemon growing from small / fading in from black
	task.delay(.9 / speed, function()
		local spriteLabel = self.animation.spriteLabel
		spriteLabel.Visible = false

		Utilities.Tween(.3 / speed, "easeInCubic", function(a)
			spriteLabel.Size = UDim2.new(a, 0, a, 0)
			spriteLabel.Position = UDim2.new(.5-a/2, 0, 0, 0)
			spriteLabel.ImageColor3 = Color3.new(a, a, a)
		end)
	end)

	-- White flash expand effect, ball dissappear
	task.delay(.8 / speed, function()
		task.delay(.25 / speed, function()
			hideAll(gigantamaxball.top, gigantamaxball.bottom)
		end)

		Utilities.Tween(.5 / speed, nil, function(a)
			local s = 5*a
			gigantamaxball.Main.Mesh.Scale = Vector3.new(s, s, s)
			gigantamaxball.Main.Transparency = .5+.5*math.abs(1-a*2)
		end)
	end)

	-- Main ball movement
	Utilities.Tween(1 / speed, "easeOutCubic", function(a)
		Utilities.MoveModel(gigantamaxball.Main, (p1+(p2.p-p1.p)*a+Vector3.new(0, math.sin(a*math.pi), 0))*CFrame.Angles(-a*7, 0, 0), true)
	end)

	-- Ball cleanup
	task.delay(1 / speed, function()
		gigantamaxball:Destroy()
	end)

	task.wait(.25)
	self.animation.spriteLabel.Visible = true
end

function Sprite:delay(time) end
function Sprite:selfAnim() end
function Sprite:anim() end

function Sprite:destroy()
	--	print('sprite::destroy')
	pcall(function() self.animation:Destroy() end)
	--	pcall(function() self.testAnimation:Destroy() end)
	pcall(function() self.part:Destroy() end)
	self.pokemon = nil
	self.battle = nil
	self.spriteData = nil

end


return Sprite end