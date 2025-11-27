local null, Not, filter; do
	local util = require(game:GetService('ServerStorage'):WaitForChild('src').BattleUtilities)
	null = util.null
	Not = util.Not
	filter = util.filter
end

--[[
	Todo:
	
	 Todo: Mimicry Screen Cleaner >252
	267 max todo
--]]
--[[
ABILITY EVENT FLAGS AND THEIR MEANINGS:

=== DAMAGE & COMBAT EVENTS ===
onDamage - Triggers when the Pokemon takes damage
onAfterDamage - Triggers after damage is dealt to the Pokemon
onDamagingHit - Triggers when the Pokemon is hit by a damaging move
onSourceModifyDamage - Modifies damage when this Pokemon is the source/attacker
onModifyDamage - Modifies damage dealt to this Pokemon
onDirectDamage - Handles direct damage (like recoil, confusion)

=== ATTACK & STAT MODIFICATION EVENTS ===
onModifyAtk - Modifies the Attack stat
onModifyDef - Modifies the Defense stat
onModifySpA - Modifies the Special Attack stat
onModifySpD - Modifies the Special Defense stat
onModifySpe - Modifies the Speed stat
onModifyMove - Modifies move properties before use
onModifyMovePriority - Changes move priority order
onModifyPriority - General priority modification
onModifyBoost - Modifies stat boosts/drops

=== MOVE-RELATED EVENTS ===
onBasePower - Modifies a move's base power
onBasePowerPriority - Priority for base power modifications
onBeforeMove - Triggers before a move is used
onAfterMove - Triggers after a move is used
onPrepareHit - Triggers when preparing to use a move
onTryHit - Determines if a move can hit the target
onHit - Triggers when a move successfully hits
onCriticalHit - Determines if a move will be a critical hit

=== TURN & BATTLE FLOW EVENTS ===
onStart - Triggers when the Pokemon enters battle
onEnd - Triggers when the Pokemon leaves battle/faints
onBeforeTurn - Triggers before each turn
onResidual - Triggers during the residual phase (end of tur)
onUpdate - Triggers when the Pokemon's status updates
onSwitchIn - Triggers when switching in
onSwitchOut - Triggers when switching out
onBeforeSwitchIn - Triggers before switching in

=== STATUS & CONDITION EVENTS ===
onSetStatus - Triggers when a status condition is applied
onImmunity - Determines immunity to types/effects
onBoost - Triggers when stat stages change
onFaint - Triggers when the Pokemon faints
onSourceFaint - Triggers when this Pokemon causes another to faint

=== WEATHER & TERRAIN EVENTS ===
onWeather - Triggers during weather effects
onSetWeather - Triggers when weather is set
onTerrain - Triggers during terrain effects (not fully implemented)

=== ITEM EVENTS ===
onTakeItem - Triggers when an item is taken/removed
onEatItem - Triggers when a berry is consumed

=== ACCURACY & EVASION EVENTS ===
onSourceModifyAccuracy - Modifies accuracy when this Pokemon attacks
onModifyAccuracy - Modifies accuracy of moves targeting this Pokemon

=== TARGETING & REDIRECTION EVENTS ===
onRedirectTarget - Redirects move targets
onAnyRedirectTarget - Global move redirection

=== FOE/ALLY INTERACTION EVENTS ===
onFoeModifyPokemon - Affects opposing Pokemon
onFoeTryMove - Prevents opposing Pokemon from using moves
onAllyTryHit - Affects moves targeting allies
onAllyModifyAtk/SpD - Modifies ally stats


=== SPECIAL EVENT MODIFIERS ===
suppressWeather - Suppresses weather effects (Air Lock, Cloud Nine)
stopAttackEvents - Prevents attack-related events (Mold Breaker)
isUnbreakable - Prevents ability from being suppressed

--]]
self = nil -- to hush intelisense; self property is injected at object-call simulation; see BattleEngine::call / BattleEngine::callAs

return {
	['battlebond'] = {
		onSourceFaint = function(target, source, effect)
			if effect and effect.effectType == 'Move' and source.template.species == 'Greninja' and source.template.forme == 'BB' and source.hp > 0 and not source.transformed and source.side.foe.pokemonLeft > 0 then
				self:add('-activate', source, 'ability: Battle Bond')
				local template = self:getTemplate('Greninja-Ash')
				source:formeChange(template)
				source.baseTemplate = template
				source.details = template.species .. ', L' .. source.level .. (source.gender == '' and '' or ', ') .. source.gender .. (source.set.shiny and ', shiny' or '')
				self:add('detailschange', source, source.details, '[battleBond]', '[icon] '..(template.icon or 0))
				local shinyPrefix = source.shiny and '_SHINY' or ''
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Greninja-ash')
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Greninja-ash')

				source.iconOverride = template.icon-1
				-- is there a better way to access this?
				source.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Greninja-ash']
				source.baseStatOverride = template.baseStats
			end
		end,
		onModifyMove = function(move, attacker)
			if move.id == 'watershuriken' and attacker.template.species == 'Greninja' and attacker.template.forme == 'Ash' then
				--				self:debug('battle bond modify watershuriken')
				-- for some reason base power is handled on the move itself
				move.multihit = 3
			end
		end,
		id = "battlebond",
		name = "Battle Bond",
		rating = 3,
		num = 210,
	},
	['liquidvoice'] = {
		onModifyMovePriority = -1,
		onModifyMove = function(move)
			if move.flags and move.flags['sound'] then
				move.type = 'Water'
			end
		end,
		id = "liquidvoice",
		name = "Liquid Voice",
		rating = 2.5,
		num = 204,
	},
	['longreach'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if move.flags['contact'] then
				return self:chainModify(1.2)
			end
		end,
		onModifyMove = function(move)
			if move.flags then
				move.flags['contact'] = nil
			end
		end,
		id = "longreach",
		name = "Long Reach",
		rating = 3,
		num = 203,
	},
	['slushrush'] = {
		onModifySpe = function(spe, pokemon)
			if self:isWeather('hail') then
				return self:chainModify(2)
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'hail' then return false end
		end,
		id = "slushrush",
		name = "Slush Rush",
		rating = 2.5,
		num = 202,
	},

	['adaptability'] = {
		onModifyMove = function(move)
			move.stab = 2
		end,
		id = "adaptability",
		name = "Adaptability",
		rating = 3.5,
		num = 91
	},
	['aftermath'] = {
		id = "aftermath",
		name = "Aftermath",
		onAfterDamageOrder = 1,
		onAfterDamage = function(damage, target, source, move)
			if source and source ~= target and move and move.flags['contact'] and target.hp <= 0 then
				self:damage(source.maxhp / 4, source, target, nil, true)
			end
		end,
		rating = 2.5,
		num = 106
	},
	['aerilate'] = {
		onModifyMovePriority = -1,
		onModifyMove = function(move, pokemon)
			if move.type == 'Normal' and move.id ~= 'naturalgift' then
				move.type = 'Flying'
				if move.category ~= 'Status' then
					pokemon:addVolatile('aerilate')
				end
			end
		end,
		effect = {
			duration = 1,
			onBasePowerPriority = 8,
			onBasePower = function(basePower, pokemon, target, move)
				return self:chainModify(0x1333, 0x1000)
			end
		},
		id = "aerilate",
		name = "Aerilate",
		rating = 4,
		num = 185
	},
	['airlock'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Air Lock')
		end,
		suppressWeather = true,
		id = "airlock",
		name = "Air Lock",
		rating = 3,
		num = 76
	},
	['analytic'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if not self:willMove(defender) then
				self:debug('Analytic boost')
				return self:chainModify(0x14CD, 0x1000)
			end
		end,
		id = "analytic",
		name = "Analytic",
		rating = 2,
		num = 148
	},
	['angerpoint'] = {
		onStart = function(pokemon)
			local attacked = 0
			if pokemon.timesAttacked > 0 then
				self:add('-activate', pokemon, 'ability: Anger Point')
				attacked = math.min(pokemon.timesAttacked, 5)
				self:add('-start', pokemon, attacked .. attacked, '[silent]')
				pokemon.attacked = attacked
			end
		end,
		onEnd = function(pokemon)
			if pokemon.attacked then
				self:add('-end', pokemon, pokemon.attacked .. pokemon.attacked, '[silent]')
			end
		end,
		onBasePowerPriority = 21,
		onBasePower = function(basePower, attacker, defender, move)
			if attacker.attacked then
				local powMod = {4506, 4915, 5325, 5734, 6144}
				return self:chainModify({powMod[attacker.attacked], 4096})
			end
		end,
		id = "angerpoint",
		name = "Anger Point",
		rating = 3,
		num = 83
	},
	['anticipation'] = {
		onStart = function(pokemon)
			pokemon.anticipationActivated = false
			for _, target in pairs(pokemon.side.foe.active) do
				if target ~= null and not target.fainted then
					for _, m in pairs(target.moveset) do
						local move = self:getMove(m.move)
						if move.category ~= 'Status' and (self:getImmunity(move.type, pokemon) and self:getEffectiveness(move.type, pokemon) > 1 or move.ohko) then
							self:add('-ability', pokemon, 'Anticipation')
							pokemon.anticipationActivated = true
							return
						end
					end
				end
			end
		end,
		onSourceModifyDamage = function(damage, source, target, move)
			if target.anticipationActivated and target.activeTurns < 1 then
				self:debug('Anticipation weaken')
				return self:chainModify(0.5)
			end
		end,
		id = "anticipation",
		name = "Anticipation",
		rating = 1,
		num = 107
	},
	['arenatrap'] = {
		onFoeModifyPokemon = function(pokemon)
			if not self:isAdjacent(pokemon, self.effectData.target) then return end
			if pokemon:isGrounded() then
				pokemon:tryTrap(true, self.effectData.target, 'Arena Trap')
			end
		end,
		onFoeMaybeTrapPokemon = function(pokemon, source)
			if Not(source) then source = self.effectData.target end
			if not self:isAdjacent(pokemon, source) then return end
			if pokemon:isGrounded() then
				pokemon.maybeTrapped = true
			end
		end,
		id = "arenatrap",
		name = "Arena Trap",
		rating = 4.5,
		num = 71
	},
	['aromaveil'] = {
		onAllyTryHit = function(target, source, move)
			local protects = {'attract', 'disable', 'encore', 'healblock', 'taunt', 'torment'}
			if move and protects[move.id] then
				return false
			end
		end,
		id = "aromaveil",
		name = "Aroma Veil",
		rating = 1.5,
		num = 165
	},
	['aurabreak'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Aura Break')
		end,
		onAnyTryPrimaryHit = function(target, source, move)
			if target == source or move.category == 'Status' then return end
			source:addVolatile('aurabreak')
		end,
		effect = {
			duration = 1
		},
		id = "aurabreak",
		name = "Aura Break",
		rating = 2,
		num = 188
	},
	['baddreams'] = {
		onResidualOrder = 26,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			if pokemon.hp <= 0 then return end
			for _, target in pairs(pokemon.side.foe.active) do
				if target ~= null and target.hp > 0 then
					if target.status == 'slp' then
						self:damage(target.maxhp / 8, target)
					end
				end
			end
		end,
		id = "baddreams",
		name = "Bad Dreams",
		rating = 2,
		num = 123
	},
	['battlearmor'] = {
		onCriticalHit = function() return false end,
		id = "battlearmor",
		name = "Battle Armor",
		rating = 1,
		num = 4
	},
	['bigpecks'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Flying' then
				self:debug('Big Pecks boost')
				return self:chainModify(1.3)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move)
			if move.type == 'Flying' then
				self:debug('Big Pecks boost')
				return self:chainModify(1.3)
			end
		end,
		id = "bigpecks",
		name = "Big Pecks",
		rating = 2,
		num = 145
	},
	['blaze'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Fire' then
				self:debug('Blaze boost')
				return self:chainModify(1.3)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move)
			if move.type == 'Fire' then
				self:debug('Blaze boost')
				return self:chainModify(1.3)
			end
		end,
		id = "blaze",
		name = "Blaze",
		rating = 2,
		num = 66
	},
	['bulletproof'] = {
		onTryHit = function(pokemon, target, move)
			if move.flags['bullet'] then
				self:add('-immune', pokemon, '[msg]', '[from] Bulletproof')
				return null
			end
		end,
		id = "bulletproof",
		name = "Bulletproof",
		rating = 3,
		num = 171
	},
	['cheekpouch'] = {
		onEatItem = function(item, pokemon)
			self:heal(pokemon.maxhp / 3)
		end,
		id = "cheekpouch",
		name = "Cheek Pouch",
		rating = 2,
		num = 167
	},
	['chlorophyll'] = {
		onModifySpe = function(spe)
			if self:isWeather({'sunnyday', 'desolateland'}) then
				return self:chainModify(2)
			end
		end,
		id = "chlorophyll",
		name = "Chlorophyll",
		rating = 2.5,
		num = 34
	},
	['clearbody'] = {
		onBoost = function(boost, target, source, effect)
			if source and target == source then return end
			local showMsg = false
			for i, b in pairs(boost) do
				if b < 0 then
					boost[i] = nil
					showMsg = true
				end
			end
			if showMsg and not effect.secondaries then
				self:add("-fail", target, "unboost", "[from] ability = Clear Body", "[of] " .. target)
			end
		end,
		id = "clearbody",
		name = "Clear Body",
		rating = 2,
		num = 29
	},
	['cloudnine'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Cloud Nine')
		end,
		suppressWeather = true,
		id = "cloudnine",
		name = "Cloud Nine",
		rating = 3,
		num = 13
	},
	['colorchange'] = {
		onAfterMoveSecondary = function(target, source, move)
			local type = move.type
			if target.isActive and move.effectType == 'Move' and move.category ~= 'Status' and type ~= '???' and not target:hasType(type) then
				if not target:setType(type) then return false end
				self:add('-start', target, 'typechange', type, '[from] Color Change')
				target:update()
			end
		end,
		id = "colorchange",
		name = "Color Change",
		rating = 1,
		num = 16
	},
	['innardsout'] = {
		name = "Innards Out",
		onAfterDamageOrder = 1,
		onAfterDamage = function(damage, target, source, move)
			if not (target.hp) then
				self:damage(target:getUndynamaxedHP(damage), source, target)
			end
		end,
		rating = 4,
		num = 215,
		id = 'innardsout'
	},
	['dancer'] = {
		name = "Dancer",
		id = 'dancer',
		--implemented in runMove in BattleEngine.Extension
		rating = 1.5,
		num = 216,
	},
	['steelworker'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, attacker, defender, move)
			if (move.type == 'Steel') then
				return self:chainModify(1.5)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move)
			if (move.type == 'Steel') then
				return self:chainModify(1.5)
			end
		end,
		name = "Steelworker",
		rating = 3.5,
		num = 200,
		id = 'steelworker'
	},
	['prismarmor'] = {
		onSourceModifyDamage = function(damage, source, target, move)
			if move.typeMod > 0 then --if self:getEffectiveness(move, target) > 1 then
				self:debug('Prism Armor neutralize')
				return self:chainModify(0.75)
			end
		end,
		isUnbreakable = true,
		name = "Prism Armor",
		rating = 3,
		num = 232,
		id = 'prismarmor'
	},
	['neuroforce'] = {
		onModifyDamage = function(damage, source, target, move)
			if move and move.typeMod > 0 then
				return self:chainModify(1.3)
			end
		end,
		name = "Neuroforce",
		rating = 2.5,
		num = 233,
		id = 'neuroforce'
	},
	['intrepidsword'] = {
		onStart = function(pokemon)
			self:boost({atk = 1})
		end,
		id = "intrepidsword",
		name = "Intrepid Sword",
		rating = 2.5,
		num = 234
	},
	['dauntlessshield'] = {
		onStart = function(pokemon)
			self:boost({def = 1})
		end,
		id = "dauntlessshield",
		name = "Dauntless Shield",
		rating = 2.5,
		num = 235
	},
	['ballfetch'] = {
		name = "Ball Fetch",
		rating = 0,
		num = 237,
		id = 'ballfetch'
	},
	['cottondown'] = {
		onAfterDamage = function(damage, target, source, move)
			local activated = false
			for _, pokemon in pairs(self:getAllActive()) do
				if not (pokemon == target or pokemon.fainted) then return end
				if not (activated) then
					self:add('-ability', target, 'Cotton Down')
					activated = true
				end
				self:boost({spe = -1}, pokemon, target, nil, true)
			end
		end,
		name = "Cotton Down",
		rating = 2,
		num = 238,
		id = 'cottondown'
	},
	['propellertail'] = {   
		onRedirectTargetPriority = 3,
		onRedirectTarget = function(target, source, move) 
			-- Fires for all pokemon on the ability holder's side apparently
			-- Ensure source is the ability holder
			self:debug('onRedirectTarget: ${target} (${target.side.name}), ${source} (${source.side.name}), ${source2}, ${move}')
			local te = self:getAbility(target.ability)
			if (te == 'propellertail')then
				self:debug('Propeller Tail prevented redirection')
				return target
			end
		end,
		id = "propellertail",
		name = "Propeller Tail",
		rating = 0,
		num = 239
	},
	['dazzling'] = {
		onFoeTryMove = function(target, source, move)
			local targetAllExceptions = {'perishsong', 'flowershield', 'rototiller'}
			if (move.target == 'foeSide' or (move.target == 'all' and not targetAllExceptions:find(move.id))) then
				return
			end
			local dazzlingHolder = self.effectData.target
			if ((source.side == dazzlingHolder.side or move.target == 'all') and move.priority > 0.1) then
				self:attrLastMove('[still]')
				self:add('cant', dazzlingHolder, 'ability: Dazzling', move, '[of] '..target)
				return false
			end
		end,
		name = "Dazzling",
		rating = 2.5,
		num = 219,
		id = 'dazzling'
	},
	['soulheart'] = {
		onSourceFaint = function(target, source, effect)
			if effect and effect.effectType == 'Move' then
				self:boost({spa = 1}, source)
			end
		end,
		name = "Soul-Heart",
		rating = 3.5,
		num = 220,
		id = 'soulheart'
	},
	['receiver'] = {
		onAllyFaint = function(target)
			if not (self.effectData.target.hp) then return end
			local ability = target:getAbility()
			local pokemon = self.effectData.target
			local additionalBannedAbilities = {'noability', 'flowergift', 'forecast', 'hungerswitch', 'illusion', 'imposter', 'neutralizinggas', 'powerofalchemy', 'receiver', 'trace', 'wonderguard', 'asone'}
			if (table.find(additionalBannedAbilities,target.ability)) then return end
			self:add('-ability', pokemon, ability, '[from] ability: Receiver', '[of] '..target)
			pokemon:setAbility(ability)
		end,
		name = "Receiver",
		rating = 0,
		num = 222,
		id = 'receiver'
	},
	powerofalchemy = {
		onAllyFaint = function(target)
			if not (self.effectData.target.hp) then return end
			local pokemon = self.effectData.target
			local ability = target:getAbility()
			local additionalBannedAbilities = {'noability', 'flowergift', 'forecast', 'hungerswitch', 'illusion', 'imposter', 'neutralizinggas', 'powerofalchemy', 'receiver', 'trace', 'wonderguard', 'asone'}
			if table.find(additionalBannedAbilities,target.ability) then return end
			self:add('-ability', pokemon, ability, '[from] ability: Power of Alchemy', '[of] '..target)
			pokemon:setAbility(ability)
		end,
		name = "Power of Alchemy",
		rating = 0,
		num = 223,
		id = 'powerofalchemy'
	},
	['beastboost'] = {
		onSourceFaint = function(target, source, effect)
			if effect and effect.effectType == 'Move' then 
				local stat = 'atk'
				local bestStat = 0
				for i, s in pairs(source.stats) do
					if (source.stats[i] > bestStat) then
						stat = i
						bestStat = source.stats[i]
					end
				end
				self:boost({[stat]=1}, source)
			end
		end,
		id = "beastboost",
		name = "Beast Boost",
		rating = 3.5,
		num = 224,
	},
	rkssystem = {
		-- RKS System's type-changing itself is implemented in statuses.js
		onTakeItem = function(item)
			if item.onMemory then return false end
		end,
		name = "RKS System",
		rating = 4,
		num = 225,
		id = 'rkssystem'
	},
	tanglinghair = {
		onAfterDamage = function(damage, target, source, move)
			if (move.flags['contact']) then
				self:add('-ability', target, 'Tangling Hair')
				self:boost({spe = -1}, source, target, nil, true)
			end
		end,
		name = "Tangling Hair",
		rating = 2,
		num = 221,
		id = 'tanglinghair'
	},
	['comatose'] = {
		onResidualOrder = 5,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			self:debug('Simple Comatose')
			pokemon:cureStatus()
		end,
		id ="comatose",
		name = "Comatose",
		rating = 3,
		num = 213,
	},
	['competitive'] = {
		onAfterEachBoost = function(boost, target, source)
			if Not(source) or target.side == source.side then return end
			local statsLowered = false
			for i, b in pairs(boost) do
				if b < 0 then
					statsLowered = true
					break
				end
			end
			if statsLowered then
				self:boost({spa = 2})
			end
		end,
		id = "competitive",
		name = "Competitive",
		rating = 2.5,
		num = 172
	},
	['compoundeyes'] = {
		onSourceModifyAccuracy = function(accuracy)
			if type(accuracy) ~= 'number' then return end
			self:debug('compoundeyes - enhancing accuracy')
			return accuracy * 1.3
		end,
		id = "compoundeyes",
		name = "Compound Eyes",
		rating = 3.5,
		num = 14
	},
	['contrary'] = {
		onBoost = function(boost)
			for i, b in pairs(boost) do
				boost[i] = -b
			end
		end,
		id = "contrary",
		name = "Contrary",
		rating = 4,
		num = 126
	},
	['cursedbody'] = {
		onAfterDamage = function(damage, target, source, move)
			if Not(source) or source.volatiles['disable'] then return end
			if source ~= target and move and move.effectType == 'Move' and not move.isMax and not move.flags['futuremove'] and move.id ~= 'struggle' then
				if math.random(10) <= 3 then
					source:addVolatile('disable')
				end
			end
		end,
		id = "cursedbody",
		name = "Cursed Body",
		rating = 2,
		num = 130
	},
	['cutecharm'] = {
		onAfterDamage = function(damage, target, source, move)
			if move and move.flags['contact'] then
				if math.random(10) <= 3 then
					source:addVolatile('attract', target)
				end
			end
		end,
		id = "cutecharm",
		name = "Cute Charm",
		rating = 1,
		num = 56
	},
	['damp'] = {
		id = "damp",
		onAnyTryMove = function(target, source, effect)
			if effect.id == 'selfdestruct' or effect.id == 'explosion' then
				self:attrLastMove('[still]')
				self:add('-activate', self.effectData.target, 'ability = Damp')
				return false
			end
		end,
		onAnyDamage = function(damage, target, source, effect)
			if effect and effect.id == 'aftermath' then
				return false
			end
		end,
		name = "Damp",
		rating = 1,
		num = 6
	},
	['darkaura'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Dark Aura')
		end,
		onAnyTryPrimaryHit = function(target, source, move)
			if target == source or move.category == 'Status' then return end
			if move.type == 'Dark' then
				source:addVolatile('aura')
			end
		end,
		id = "darkaura",
		name = "Dark Aura",
		rating = 3,
		num = 186
	},
	['adrenaline'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, pokemon)
			if pokemon.hp <= pokemon.maxhp/2 then
				return self:chainModify(1.5)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, pokemon)
			if pokemon.hp <= pokemon.maxhp/2 then
				return self:chainModify(1.5)
			end
		end,
		onResidual = function(pokemon)
			pokemon:update()
		end,
		id = "adrenaline",
		name = "Adrenaline",
		rating = 4,
		num = 129
	},
	['defiant'] = {
		onAfterEachBoost = function(boost, target, source)
			if Not(source) or target.side == source.side then return end
			local statsLowered = false
			for i, b in pairs(boost) do
				if b < 0 then
					statsLowered = true
					break
				end
			end
			if statsLowered then
				self:boost({atk = 2})
			end
		end,
		id = "defiant",
		name = "Defiant",
		rating = 2.5,
		num = 128
	},
	['deltastream'] = {
		onStart = function(source)
			self:setWeather('deltastream')
		end,
		onAnySetWeather = function(target, source, weather)
			local allowedWeathers = {primordialsea = true, desolateland = true, none = true}
			if self:getWeather().id == 'deltastream' and not allowedWeathers[weather.id] and not Not(weather.id) then
				return false
			end
		end,
		onEnd = function(pokemon)
			if self.weatherData.source ~= pokemon then
				return
			end
			for _, target in pairs(self:getAllActive()) do
				if target == pokemon then continue end
				if target:hasAbility('deltastream') then
					self.weatherData.source = target
					return
				end
			end
			self:clearWeather()
		end,
		id = "deltastream",
		name = "Delta Stream",
		rating = 5,
		num = 191
	},
	['desolateland'] = {
		onStart = function(source)
			self:setWeather('desolateland')
		end,
		onAnySetWeather = function(target, source, weather)
			local allowedWeathers = {primordialsea = true, deltastream = true, none = true}
			if self:getWeather().id == 'desolateland' and not allowedWeathers[weather.id] and not Not(weather.id) then
				return false
			end
		end,
		onEnd = function(pokemon)
			if self.weatherData.source ~= pokemon then
				return
			end
			for _, target in pairs(self:getAllActive()) do
				if target == pokemon then continue end
				if target:hasAbility('desolateland') then
					self.weatherData.source = target
					return
				end
			end
			self:clearWeather()
		end,
		id = "desolateland",
		name = "Desolate Land",
		rating = 5,
		num = 190
	},
	['download'] = {
		onStart = function(pokemon)
			local totaldef = 0
			local totalspd = 0
			for _, foe in pairs(pokemon.side.foe.active) do
				if foe ~= null and not foe.fainted then
					totaldef = totaldef + foe:getStat('def', false, true)
					totalspd = totalspd + foe:getStat('spd', false, true)
				end
			end
			if totaldef and totaldef >= totalspd then
				self:boost({spa = 1})
			elseif totalspd > 0 then
				self:boost({atk = 1})
			end
		end,
		id = "download",
		name = "Download",
		rating = 4,
		num = 88
	},
	['drizzle'] = {
		onStart = function(source)
			self:setWeather('raindance', source)
		end,
		id = "drizzle",
		name = "Drizzle",
		rating = 4,
		num = 2
	},
	['drought'] = {
		onStart = function(source)
			self:setWeather('sunnyday', source)
		end,
		id = "drought",
		name = "Drought",
		rating = 4,
		num = 70
	},


	['dryskin'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Water' then
				local h = self:heal(target.maxhp / 4)
				if not h or h == 0 then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		onBasePowerPriority = 7,
		onFoeBasePower = function(basePower, attacker, defender, move)
			if self.effectData.target ~= defender then return end
			if move.type == 'Fire' then
				return self:chainModify(1.25)
			end
		end,
		onWeather = function(target, source, effect)
			if effect.id == 'raindance' or effect.id == 'primordialsea' then
				self:heal(target.maxhp / 8)
			elseif effect.id == 'sunnyday' or effect.id == 'desolateland' then
				self:damage(target.maxhp / 8)
			end
		end,
		id = "dryskin",
		name = "Dry Skin",
		rating = 3.5,
		num = 87
	},
	['earlybird'] = {
		id = "earlybird",
		name = "Early Bird",
		-- Implemented in Statuses
		rating = 2.5,
		num = 48
	},
	['effectspore'] = {
		onAfterDamage = function(damage, target, source, move)
			if move and move.flags['contact'] and (not source.status or source.status == '') and source:runImmunity('powder') then
				local r = math.random(100)
				if r <= 33 then
					self.statusSourceMessage = {'-ability', target, 'effectspore'}
				end
				if r <= 11 then
					source:setStatus('slp', target)
				elseif r <= 22 then
					source:setStatus('par', target)
				elseif r <= 33 then
					source:setStatus('tox', target)
				end
				self.statusSourceMessage = nil
			end
		end,
		id = "effectspore",
		name = "Effect Spore",
		rating = 2,
		num = 27
	},
	['fairyaura'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Fairy Aura')
		end,
		onAnyTryPrimaryHit = function(target, source, move)
			if target == source or move.category == 'Status' then return end
			if move.type == 'Fairy' then
				source:addVolatile('aura')
			end
		end,
		id = "fairyaura",
		name = "Fairy Aura",
		rating = 3,
		num = 187
	},
	['filter'] = {
		onSourceModifyDamage = function(damage, source, target, move)
			if move.typeMod > 0 then --if self:getEffectiveness(move, target) > 1 then
				self:debug('Filter neutralize')
				return self:chainModify(0.75)
			end
		end,
		id = "filter",
		name = "Filter",
		rating = 3,
		num = 111
	},
	['flamebody'] = {
		onAfterDamage = function(damage, target, source, move)
			if move and move.flags['contact'] then
				if math.random(10) <= 3 then
					self.statusSourceMessage = {'-ability', target, 'flamebody'}
					source:trySetStatus('brn', target, move)
					self.statusSourceMessage = nil
				end
			end
		end,
		id = "flamebody",
		name = "Flame Body",
		rating = 2,
		num = 49
	},
	['flareboost'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if attacker.status == 'brn' then
				return self:chainModify(1.5)
			end
		end,
		id = "flareboost",
		name = "Flare Boost",
		rating = 2.5,
		num = 138
	},
	['flashfire'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Fire' then
				move.accuracy = true
				if not target:addVolatile('flashfire') then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		onEnd = function(pokemon)
			pokemon:removeVolatile('flashfire')
		end,
		effect = {
			noCopy = true, -- doesn't get copied by Baton Pass
			onStart = function(target)
				self:add('-start', target, 'ability = Flash Fire')
			end,
			onModifyAtkPriority = 5,
			onModifyAtk = function(atk, attacker, defender, move)
				if move.type == 'Fire' then
					self:debug('Flash Fire boost')
					return self:chainModify(1.5)
				end
			end,
			onModifySpAPriority = 5,
			onModifySpA = function(atk, attacker, defender, move)
				if move.type == 'Fire' then
					self:debug('Flash Fire boost')
					return self:chainModify(1.5)
				end
			end,
			onEnd = function(target)
				self:add('-end', target, 'ability: Flash Fire', '[silent]')
			end
		},
		id = "flashfire",
		name = "Flash Fire",
		rating = 3,
		num = 18
	},
	['flowergift'] = {
		onStart = function(pokemon)
			self:singleEvent('WeatherChange', self.effect, self.effectData, pokemon)
		end,
		onWeatherChange = function(pokemon)
			if not pokemon.isActive or pokemon.template.species ~= 'Cherrim' or pokemon.transformed then return end
			if not pokemon.hp then return end
			if self:isWeather({'sunnyday', 'desolateland'}) then
				if pokemon.template.forme ~= 'Sunshine' then
					local template = self:getTemplate('Cherrim-Sunshine')
					pokemon:formeChange(template)
					pokemon.baseTemplate = template
					pokemon.details = template.species .. ', L' .. pokemon.level .. (pokemon.gender == '' and '' or ', ') .. pokemon.gender .. (pokemon.set.shiny and ', shiny' or '')
					self:add('detailschange', pokemon, pokemon.details, '[flowerGift]', '[icon] '..(template.icon or 0))

					local shinyPrefix = pokemon.shiny and '_SHINY' or ''
					self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Cherrim-Sunshine')
					self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Cherrim-Sunshine')
					pokemon.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Cherrim-Sunshine']

					pokemon.iconOverride = template.icon-1
					pokemon.baseStatOverride = template.baseStats
					pokemon.typeOverride = template.types
					self:add('-formechange', pokemon, 'Cherrim-Sunshine', '[msg]')
				end
			else
				if pokemon.template.forme == 'Sunshine' then
					local template = self:getTemplate('Cherrim')
					pokemon:formeChange(template)
					pokemon.baseTemplate = template
					pokemon.details = template.species .. ', L' .. pokemon.level .. (pokemon.gender == '' and '' or ', ') .. pokemon.gender .. (pokemon.set.shiny and ', shiny' or '')
					self:add('detailschange', pokemon, pokemon.details, '[flowerGiftN]', '[icon] '..(template.icon or 0))

					local shinyPrefix = pokemon.shiny and '_SHINY' or ''
					self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Cherrim')
					self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Cherrim')
					pokemon.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Cherrim']

					pokemon.iconOverride = template.icon-1
					pokemon.baseStatOverride = template.baseStats
					pokemon.typeOverride = template.types
					self:add('-formechange', pokemon, 'Cherrim', '[msg]')
				end
			end
		end,
		onModifySpAPriority = 3,
		onAllyModifySpA = function(spa, pokemon)
			if self.effectData.target.template.species ~= 'Cherrim' then return end
			if self:isWeather({'sunnyday', 'desolateland'}) then
				return self:chainModify(1.5)
			end
		end,
		onModifySpDPriority = 4,
		onAllyModifySpD = function(spd, pokemon)
			if self.effectData.target.template.species ~= 'Cherrim' then return end
			if self:isWeather({'sunnyday', 'desolateland'}) then
				return self:chainModify(1.5)
			end
		end,
		id = "flowergift",
		name = "Flower Gift",
		rating = 2.5,
		num = 122
	},
	['flowerveil'] = {
		onAllyBoost = function(boost, target, source, effect)
			if (source and target == source) then return end
			local showMsg = false
			for i, b in pairs(boost) do
				if b < 0 then
					boost[i] = nil
					showMsg = true
				end
			end
			if showMsg and not effect.secondaries then
				self:add("-fail", target, "unboost", "[from] ability = Flower Veil", "[of] " .. target)
			end
		end,
		onAllySetStatus = function(status, target)
			return false
		end,
		id = "flowerveil",
		name = "Flower Veil",
		rating = 0,
		num = 166
	},
	['forecast'] = {
		onUpdate = function(pokemon)
			if pokemon.baseTemplate.species ~= 'Castform' or pokemon.transformed then return end
			local forme
			local w = self:effectiveWeather()
			if (w == 'sunnyday' or w == 'desolateland') and pokemon.template.speciesid ~= 'castformsunny' then
				forme = 'Castform-Sunny'
			elseif (w == 'raindance' or w == 'primordialsea') and pokemon.template.speciesid ~= 'castformrainy' then
				forme = 'Castform-Rainy'
			elseif w == 'hail' and pokemon.template.speciesid ~= 'castformsnowy' then
				forme = 'Castform-Snowy'
			elseif pokemon.template.speciesid ~= 'castform' then
				forme = 'Castform'
			end
			if pokemon.isActive and forme then
				pokemon:formeChange(forme)
				self:add('-formechange', pokemon, forme, '[msg]')
			end
		end,
		id = "forecast",
		name = "Forecast",
		rating = 3,
		num = 59
	},
	['mirrorarmor'] = {
		onBoost = function(boost, target, source, effect)
			--Don't bounce self stat changes, or boosts that have already bounced
			if (Not(source) or target == source or not boost or effect.id == 'mirrorarmor') then return end
			for b, value in pairs(boost) do
				if value < 0 then
					if target.boosts[b] == -6 then
						continue
					end
					local negativeBoost = {}
					negativeBoost[b] = value
					boost[b] = nil
					if source.hp then
						self:add('-ability', target, 'Mirror Armor')
						self:boost(negativeBoost, source, target, nil, true)
					end
				end
			end
		end,
		name = "Mirror Armor",
		id = 'mirrorarmor',
		rating = 2,
		num = 240,
	},
	['gulpmissile'] = {
		onBeforeMovePriority = 11,
		onBeforeMove = function(pokemon, target, move)
			if pokemon.template.species ~= 'Cramorant' then return end
			if pokemon.hp < pokemon.maxhp/2 then
				if Not(pokemon.template.forme) and pokemon:formeChange('Cramorant-Gorging') then
					self:add('-formechange', pokemon, 'Cramorant-Gorging')
				end
			else
				if Not(pokemon.template.forme) and pokemon:formeChange('Cramorant-Gulping') then
					self:add('-formechange', pokemon, 'Cramorant-Gulping')
				end
			end
		end,
		onAfterDamageOrder = 1,
		onAfterDamage = function(damage, target, source, move)
			if source and source ~= target and move and move.flags['contact'] then
				if target.template.forme == 'Gorging' and target:formeChange('Cramorant') then
					self:add('-formechange', target, 'Cramorant')
					source:setStatus('par', source)
					self:damage(source.maxhp / 4, source, target, nil, true)
				elseif target.template.forme == 'Gulping' and target:formeChange('Cramorant') then
					self:add('-formechange', target, 'Cramorant')
					self:boost({def = -1}, source, target)
					self:damage(source.maxhp / 4, source, target, nil, true)
				end
			end
		end,
		id = "gulpmissile",
		name = "Gulp Missile",
		rating = -1,
		num = 241
	},
	['stalwart'] = {
		onModifyMove =  function(move)
			--this doesn't actually do anything because ModifyMove happens after the tracksTarget check
			--the actual implementation is in Battle#getTarget
			move.tracksTarget = true
		end,
		name = "Stalwart",
		rating = 0,
		num = 242,
		id = 'stalwart'
	},
	['forewarn'] = {
		onStart = function(pokemon)
			local warnMoves = {}
			local warnBp = 1
			for _, target in pairs(pokemon.side.foe.active) do
				if target ~= null and not target.fainted then
					for _, m in pairs(target.moveset) do
						local move = self:getMove(m.move)
						local bp = move.basePower
						if move.ohko then bp = 160 end
						if move.id == 'counter' or move.id == 'metalburst' or move.id == 'mirrorcoat' then bp = 120 end
						if (not bp or bp == 0) and move.category ~= 'Status' then bp = 80 end
						if bp > warnBp then
							warnMoves = {{move, target}}
							warnBp = bp
						elseif bp == warnBp then
							table.insert(warnMoves, {move, target})
						end
					end
				end
			end
			if #warnMoves == 0 then return end
			local warnMove = warnMoves[math.random(#warnMoves)]
			self:add('-activate', pokemon, 'ability = Forewarn', warnMove[1], '[of] ' .. warnMove[2])
		end,
		id = "forewarn",
		name = "Forewarn",
		rating = 1,
		num = 108
	},
	['friendguard'] = {
		id = "friendguard",
		name = "Friend Guard",
		onAnyModifyDamage = function(damage, source, target, move)
			if target ~= self.effectData.target and target.side == self.effectData.target.side then
				self:debug('Friend Guard weaken')
				return self:chainModify(0.75)
			end
		end,
		rating = 0,
		num = 132
	},
	['frisk'] = {
		onStart = function(pokemon)
			for _, foe in pairs(pokemon.side.foe.active) do
				if foe ~= null and not foe.fainted then
					if foe.item and foe.item ~= '' then
						self:add('-item', foe, foe:getItem().name, '[from] ability = Frisk', '[of] ' .. pokemon, '[identify]')
					end
				end
			end
		end,
		id = "frisk",
		name = "Frisk",
		rating = 1.5,
		num = 119
	},
	['furcoat'] = {
		onModifyDefPriority = 6,
		onModifyDef = function(def)
			return self:chainModify(2)
		end,
		id = "furcoat",
		name = "Fur Coat",
		rating = 3.5,
		num = 169
	},
	['galewings'] = {
		onModifyPriority = function(priority, pokemon, target, move)
			if move and move.type == 'Flying' and pokemon.hp >= pokemon.maxhp/2 then return priority + 1 end
		end,
		id = "galewings",
		name = "Gale Wings",
		rating = 3,
		num = 177
	},
	['gluttony'] = {
		onEatItem = function(item, pokemon)
			self:heal(pokemon.maxhp / 3)
		end,
		id = "gluttony",
		name = "Gluttony",
		rating = 2,
		num = 82
	},
	['gooey'] = {
		onAfterDamage = function(damage, target, source, move)
			if move and move.flags['contact'] then
				self:boost({spe = -1}, source, target)
			end
		end,
		id = "gooey",
		name = "Gooey",
		rating = 2.5,
		num = 183
	},
	['grasspelt'] = {
		onModifyDefPriority = 6,
		onModifyDef = function(pokemon) -- shouldn't it be def, pokemon? doesn't *really* matter cuz neither is used
			if self:isTerrain('grassyterrain') then
				return self:chainModify(1.5)
			end
		end,
		id = "grasspelt",
		name = "Grass Pelt",
		rating = 0.5,
		num = 179
	},
	['guts'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, pokemon)
			if pokemon.status and pokemon.status ~= '' then
				return self:chainModify(1.5)
			end
		end,
		id = "guts",
		name = "Guts",
		rating = 3,
		num = 62
	},
	['harvest'] = {
		id = "harvest",
		name = "Harvest",
		onResidualOrder = 26,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			if self:isWeather({'sunnyday', 'desolateland'}) or math.random(2) == 1 then
				if pokemon.hp and Not(pokemon.item) and self:getItem(pokemon.lastItem).isBerry then
					pokemon:setItem(pokemon.lastItem)
					self:add('-item', pokemon, pokemon:getItem(), '[from] ability = Harvest')
				end
			end
		end,
		rating = 2.5,
		num = 139
	},
	['healer'] = {
		id = "healer",
		name = "Healer",
		onResidualOrder = 5,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			if #pokemon.side.active == 1 then return end
			for _, ally in pairs(pokemon.side.active) do
				if ally ~= null and self:isAdjacent(pokemon, ally) and ally.status and math.random(10) <= 5 then
					ally:cureStatus()
				end
			end
		end,
		rating = 0,
		num = 131
	},
	['heatproof'] = {
		onBasePowerPriority = 7,
		onSourceBasePower = function(basePower, attacker, defender, move)
			if move.type == 'Fire' then
				return self:chainModify(0.5)
			end
		end,
		onDamage = function(damage, target, source, effect)
			if effect and effect.id == 'brn' then
				return damage / 2
			end
		end,
		id = "heatproof",
		name = "Heatproof",
		rating = 2.5,
		num = 85
	},
	['heavymetal'] = {
		onModifyWeight = function(weight)
			return weight * 2
		end,
		id = "heavymetal",
		name = "Heavy Metal",
		rating = -1,
		num = 134
	},
	['honeygather'] = {
		id = "honeygather",
		name = "Honey Gather",
		rating = 0,
		num = 118
	},
	['hospitality'] = {
		id = "hospitality",
		name = "Hospitality",
		onStart = function(pokemon)
			if #pokemon.side.active == 1 then return end
			for _, ally in pairs(pokemon.side.active) do
				if ally ~= null and self:isAdjacent(pokemon, ally) then
					self:heal(ally.baseMaxhp / 4, ally, pokemon)
				end
			end
		end,
		rating = 0,
		num = 301
	},
	['hubris'] = {
		onSourceFaint = function(target, source, effect)
			if effect and effect.effectType == 'Move' then
				self:boost({spa = 1}, source)
			end
		end,
		id = "hubris",
		name = "Hubris",
		rating = 3.5,
		num = 300
	},
	['hugepower'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk)
			return self:chainModify(2)
		end,
		id = "hugepower",
		name = "Huge Power",
		rating = 5,
		num = 37
	},
	['hustle'] = {
		-- This should be applied directly to the stat as opposed to chaining with the others
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk)
			return self:modify(atk, 1.5)
		end,
		onModifyMove = function(move)
			if move.category == 'Physical' and type(move.accuracy) == 'number' then
				move.accuracy = move.accuracy * 0.8
			end
		end,
		id = "hustle",
		name = "Hustle",
		rating = 3,
		num = 55
	},
	['hydration'] = {
		onResidualOrder = 5,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			if pokemon.status and self:isWeather({'raindance', 'primordialsea'}) then
				self:debug('hydration')
				pokemon:cureStatus()
			end
		end,
		id = "hydration",
		name = "Hydration",
		rating = 2,
		num = 93
	},
	['hypercutter'] = {
		onBoost = function(boost, target, source, effect)
			if source and target == source then return end
			if boost['atk'] and boost['atk'] < 0 then
				boost['atk'] = 0
				if not effect.secondaries then
					self:add("-fail", target, "unboost", "Attack", "[from] ability = Hyper Cutter", "[of] " .. target)
				end
			end
		end,
		id = "hypercutter",
		name = "Hyper Cutter",
		rating = 1.5,
		num = 52
	},
	['icebody'] = {
		onWeather = function(target, source, effect)
			if effect.id == 'hail' then
				self:heal(target.maxhp / 16)
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'hail' then return false end
		end,
		id = "icebody",
		name = "Ice Body",
		rating = 1.5,
		num = 115
	},
	['illuminate'] = {
		id = "illuminate",
		name = "Illuminate",
		rating = 0,
		num = 35
	},
	['illusion'] = {
		onBeforeSwitchIn = function(pokemon)
			--if pokemon.template.forme ~= '' then return end
			pokemon.illusion = nil
			local illusion
			for i = #pokemon.side.pokemon, pokemon.position, -1 do
				local p = pokemon.side.pokemon[i]
				for i in ipairs(p) do
					print(p[i])
				end
				if p ~= null and not p.fainted then
					illusion = p
					break
				end
			end
			if not illusion or pokemon == illusion then return end
			pokemon.illusion = illusion
		end,
		-- illusion clearing is hardcoded in the damage function
		-- function because mold breaker inhibits the damage event
		onEnd = function(pokemon)
			if pokemon.illusion then
				self:debug('illusion cleared')
				pokemon.illusion = nil
				--				let details = pokemon.template.species + (pokemon.level === 100 ? '' : ', L' + pokemon.level) + (pokemon.gender === '' ? '' : ', ' + pokemon.gender) + (pokemon.set.shiny ? ', shiny' : '')
				--				this.add('replace', pokemon, details)
				--				this.add('-end', pokemon, 'Illusion')
				self:add('-endability', pokemon, 'Illusion', pokemon.getDetails)
			end
		end,
		onFaint = function(pokemon)
			pokemon.illusion = nil
		end,
		id = "illusion",
		name = "Illusion",
		rating = 4.5,
		num = 149
	},
	['immunity'] = {
		onUpdate = function(pokemon)
			if pokemon.status == 'psn' or pokemon.status == 'tox' then
				pokemon:cureStatus()
			end
		end,
		onImmunity = function(type)
			if type == 'psn' then return false end
		end,
		id = "immunity",
		name = "Immunity",
		rating = 2,
		num = 17
	},
	['imposter'] = {
		onStart = function(pokemon)
			local target = pokemon.side.foe.active[#pokemon.side.foe.active + 1 - pokemon.position]
			if not Not(target) then
				pokemon:transformInto(target, pokemon, self:getAbility('imposter'))
			end
		end,
		id = "imposter",
		name = "Imposter",
		rating = 4.5,
		num = 150
	},
	['infiltrator'] = {
		onModifyMove = function(move)
			move.infiltrates = true
		end,
		id = "infiltrator",
		name = "Infiltrator",
		rating = 3,
		num = 151
	},
	['inflate'] = {
		onModifyDefPriority = 6,
		onModifyDef = function(def, pokemon)
			if pokemon.status then
				return self:chainModify(1.5)
			end
		end,
		id = "inflate",
		name = "Inflate",
		rating = 2.5,
		num = 299
	},
	['innerfocus'] = {
		onFlinch = function() return false end,
		onBoost = function(boost, target, source, effect)
			if effect.name == "Intimidate" and boost.atk and boost.atk < 0 then
				boost.atk = 0
				self:add('-fail', target, 'unboost', 'Attack', '[from] ability: Inner Focus', '[of] ' .. target)
			end
		end,
		id = "innerfocus",
		name = "Inner Focus",
		rating = 1.5,
		num = 39
	},
	['insomnia'] = {
		onUpdate = function(pokemon)
			if pokemon.status == 'slp' then
				pokemon:cureStatus()
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'slp' then return false end
		end,
		id = "insomnia",
		name = "Insomnia",
		rating = 2,
		num = 15
	},
	['intimidate'] = {
		onStart = function(pokemon)
			local activated = false
			for _, foe in pairs(pokemon.side.foe.active) do
				if foe ~= null and self:isAdjacent(foe, pokemon) then
					if not activated then
						self:add('-ability', pokemon, 'Intimidate')
						activated = true
					end
					if foe.volatiles['substitute'] then
						self:add('-activate', foe, 'Substitute', 'ability = Intimidate', '[of] ' .. pokemon)
					else
						self:boost({atk = -1}, foe, pokemon)
					end
				end
			end
		end,
		id = "intimidate",
		name = "Intimidate",
		rating = 3.5,
		num = 22
	},
	['ironbarbs'] = {
		onAfterDamageOrder = 1,
		onAfterDamage = function(damage, target, source, move)
			if source and source ~= target and move and move.flags['contact'] then
				self:damage(source.maxhp / 8, source, target, nil, true)
			end
		end,
		id = "ironbarbs",
		name = "Iron Barbs",
		rating = 3,
		num = 160
	},
	['ironfist'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if move.flags['punch'] then
				self:debug('Iron Fist boost')
				return self:chainModify(1.3)
			end
		end,
		id = "ironfist",
		name = "Iron Fist",
		rating = 3,
		num = 89
	},
	['justified'] = {
		onAfterDamage = function(damage, target, source, effect)
			if effect and effect.type == 'Dark' then
				self:boost({atk = 1})
			end
		end,
		id = "justified",
		name = "Justified",
		rating = 2,
		num = 154
	},
	['keeneye'] = {
		onBoost = function(boost, target, source, effect)
			if source and target == source then return end
			if boost['accuracy'] and boost['accuracy'] < 0 then
				boost['accuracy'] = 0
				if not effect.secondaries then
					self:add("-fail", target, "unboost", "accuracy", "[from] ability = Keen Eye", "[of] " .. target)
				end
			end
		end,
		onModifyMove = function(move)
			move.ignoreEvasion = true
		end,
		id = "keeneye",
		name = "Keen Eye",
		rating = 1,
		num = 51
	},
	['klutz'] = {
		-- Item suppression implemented in BattlePokemon:ignoringItem()
		id = "klutz",
		name = "Klutz",
		rating = -1,
		num = 103
	},
	['leafguard'] = {
		onSetStatus = function(pokemon)
			if self:isWeather({'sunnyday', 'desolateland'}) then
				return false
			end
		end,
		onTryHit = function(target, source, move)
			if move and move.id == 'yawn' and self:isWeather({'sunnyday', 'desolateland'}) then
				return false
			end
		end,
		id = "leafguard",
		name = "Leaf Guard",
		rating = 1,
		num = 102
	},
	['levitate'] = {
		onImmunity = function(type)
			if type == 'Ground' then return false end
		end,
		id = "levitate",
		name = "Levitate",
		rating = 3.5,
		num = 26
	},
	['lightmetal'] = {
		onModifyWeight = function(weight)
			return weight / 2
		end,
		id = "lightmetal",
		name = "Light Metal",
		rating = 1,
		num = 135
	},
	['lightningrod'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Electric' then
				if not self:boost({spa = 1}) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		onAnyRedirectTargetPriority = 1,
		onAnyRedirectTarget = function(target, source, source2, move)
			if move.type ~= 'Electric' or ({firepledge=true, grasspledge=true, waterpledge=true})[move.id] then return end
			if self:validTarget(self.effectData.target, source, move.target) then
				return self.effectData.target
			end
		end,
		id = "lightningrod",
		name = "Lightning Rod",
		rating = 3.5,
		num = 31
	},

	['limber'] = {
		onUpdate = function(pokemon)
			if pokemon.status == 'par' then
				pokemon:cureStatus()
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'par' then return false end
		end,
		id = "limber",
		name = "Limber",
		rating = 1.5,
		num = 7
	},
	['liquidooze'] = {
		id = "liquidooze",
		onSourceTryHeal = function(damage, target, source, effect)
			self:debug("Heal is occurring = " .. target .. " <- " .. source .. " : = " .. effect.id)
			local canOoze = {drain=true, leechseed=true}
			if canOoze[effect.id] then
				self:damage(damage, nil, nil, nil, true)
				return 0
			end
		end,
		name = "Liquid Ooze",
		rating = 1.5,
		num = 64
	},
	['magicbounce'] = {
		id = "magicbounce",
		name = "Magic Bounce",
		onTryHitPriority = 1,
		onTryHit = function(target, source, move)
			if target == source or move.hasBounced or not move.flags['reflectable'] then return end
			local newMove = self:getMoveCopy(move.id)
			newMove.hasBounced = true
			newMove.pranksterBoosted = false
			self:useMove(newMove, target, source)
			return null
		end,
		onAllyTryHitSide = function(target, source, move)
			if target.side == source.side or move.hasBounced or not move.flags['reflectable'] then return end
			local newMove = self:getMoveCopy(move.id)
			newMove.hasBounced = true
			newMove.pranksterBoosted = false
			self:useMove(newMove, target, source)
			return null
		end,
		effect = {
			duration = 1
		},
		rating = 4.5,
		num = 156
	},
	['magicguard'] = {
		onDamage = function(damage, target, source, effect)
			if effect.effectType ~= 'Move' then
				return false
			end
		end,
		id = "magicguard",
		name = "Magic Guard",
		rating = 4.5,
		num = 98
	},
	['magician'] = {
		onSourceHit = function(target, source, move)
			if not move or Not(target) then return end
			if target ~= source and move.category ~= 'Status' then
				if source.item and source.item ~= '' then return end
				local yourItem = target:takeItem(source)
				if Not(yourItem) then return end
				if not source:setItem(yourItem) then
					target.item = yourItem.id -- bypass setItem so we don't break choicelock or anything
					return
				end
				self:add('-item', source, yourItem, '[from] ability = Magician', '[of] ' .. target)
			end
		end,
		id = "magician",
		name = "Magician",
		rating = 1.5,
		num = 170
	},
	['magmaarmor'] = {
		onUpdate = function(pokemon)
			if pokemon.status == 'frz' then
				pokemon:cureStatus()
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'frz' then return false end
		end,
		id = "magmaarmor",
		name = "Magma Armor",
		rating = 0.5,
		num = 40
	},
	['magnetpull'] = {
		onFoeModifyPokemon = function(pokemon)
			if pokemon:hasType('Steel') and self:isAdjacent(pokemon, self.effectData.target) then
				pokemon:tryTrap(true, self.effectData.target, 'Magnet Pull')
			end
		end,
		onFoeMaybeTrapPokemon = function(pokemon, source)
			if Not(source) then source = self.effectData.target end
			if pokemon:hasType('Steel') and self:isAdjacent(pokemon, source) then
				pokemon.maybeTrapped = true
			end
		end,
		id = "magnetpull",
		name = "Magnet Pull",
		rating = 4.5,
		num = 42
	},
	['marvelscale'] = {
		onModifyDefPriority = 6,
		onModifyDef = function(def, pokemon)
			if pokemon.status then
				return self:chainModify(1.5)
			end
		end,
		id = "marvelscale",
		name = "Marvel Scale",
		rating = 2.5,
		num = 63
	},
	['megalauncher'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if move.flags['pulse'] then
				return self:chainModify(1.5)
			end
		end,
		id = "megalauncher",
		name = "Mega Launcher",
		rating = 3.5,
		num = 178
	},
	['minus'] = {
		onModifySpAPriority = 5,
		onModifySpA = function(spa, pokemon)
			if #pokemon.side.active == 1 then return end
			for _, ally in pairs(pokemon.side.active) do
				if ally ~= null and ally.position ~= pokemon.position and not ally.fainted and ally:hasAbility('minus', 'plus') then
					return self:chainModify(1.5)
				end
			end
		end,
		id = "minus",
		name = "Minus",
		rating = 0,
		num = 58
	},
	['moldbreaker'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Mold Breaker')
		end,
		onModifyMove = function(move)
			move.ignoreAbility = true
		end,
		stopAttackEvents = true,
		id = "moldbreaker",
		name = "Mold Breaker",
		rating = 3.5,
		num = 104
	},
	['moody'] = {
		onResidualOrder = 26,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			local stats = {}
			local boost = {}
			local inc
			for i, b in pairs(pokemon.boosts) do
				if b < 6 then
					table.insert(stats, i)
				end
			end
			if #stats > 0 then
				inc = stats[math.random(#stats)]
				boost[inc] = 2
			end
			stats = {}
			for j, b in pairs(pokemon.boosts) do
				if b > -6 and j ~= inc then
					table.insert(stats, j)
				end
			end
			if #stats > 0 then
				local dec = stats[math.random(#stats)]
				boost[dec] = -1
			end
			self:boost(boost)
		end,
		id = "moody",
		name = "Moody",
		rating = 5,
		num = 141
	},
	['motordrive'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Electric' then
				if not self:boost({spe = 1}) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		id = "motordrive",
		name = "Motor Drive",
		rating = 3,
		num = 78
	},
	['moxie'] = {
		onSourceFaint = function(target, source, effect)
			if effect and effect.effectType == 'Move' then
				self:boost({atk = 1}, source)
			end
		end,
		id = "moxie",
		name = "Moxie",
		rating = 3.5,
		num = 153
	},
	['multiscale'] = {
		onSourceModifyDamage = function(damage, source, target, move)
			if target.hp >= target.maxhp then
				self:debug('Multiscale weaken')
				return self:chainModify(0.5)
			end
		end,
		id = "multiscale",
		name = "Multiscale",
		rating = 4,
		num = 136
	},
	['multitype'] = {
		-- Multitype's type-changing is implemented in Statuses
		onTakeItem = function(item)
			if item.onPlate then return false end
		end,
		id = "multitype",
		name = "Multitype",
		rating = 4,
		num = 121
	},
	['mummy'] = {
		id = "mummy",
		name = "Mummy",
		onAfterDamage = function(damage, target, source, move)
			if source and source ~= target and move and move.flags['contact'] then
				local oldAbility = source:setAbility('mummy', source, 'mummy', true)
				if oldAbility then
					--					self:add('-endability', source, oldAbility, '[from] Mummy')
					--					self:add('-ability', source, 'Mummy', '[from] Mummy')
					self:add('-activate', target, 'ability: Mummy', oldAbility, '[of] ' .. source)
				end
			end
		end,
		rating = 2,
		num = 152
	},
	['naturalcure'] = {
		onSwitchOut = function(pokemon)
			pokemon:setStatus('')
		end,
		onBattleEnd = function(pokemon)
			pokemon:setStatus('')
		end,
		id = "naturalcure",
		name = "Natural Cure",
		rating = 3.5,
		num = 30
	},
	['noguard'] = {
		onAnyAccuracy = function(accuracy, target, source, move)
			if move and (source == self.effectData.target or target == self.effectData.target) then
				return true
			end
			return accuracy
		end,
		id = "noguard",
		name = "No Guard",
		rating = 4,
		num = 99
	},
	['normalize'] = {
		onModifyMovePriority = 1,
		onModifyMove = function(move)
			if move.id ~= 'struggle' then
				move.type = 'Normal'
			end
		end,
		id = "normalize",
		name = "Normalize",
		rating = -1,
		num = 96
	},
	['oblivious'] = {
		onUpdate = function(pokemon)
			if pokemon.volatiles['attract'] then
				pokemon:removeVolatile('attract')
				self:add('-end', pokemon, 'move: Attract', '[from] ability: Oblivious')
			end
			if pokemon.volatiles['taunt'] then
				pokemon:removeVolatile('taunt')
				-- Taunt's volatile already sends the -end message when removed
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'attract' then
				self:add('-immune', pokemon, '[from] Oblivious')
				return false
			end
		end,
		onTryHit = function(pokemon, target, move)
			if move.id == 'captivate' or move.id == 'taunt' then
				self:add('-immune', pokemon, '[msg]', '[from] Oblivious')
				return null
			end
		end,
		onBoost = function(boost, target, source, effect)
			if effect.name == "Intimidate" and boost.atk and boost.atk < 0 then
				boost.atk = 0
				self:add('-fail', target, 'unboost', 'Attack', '[from] ability: Oblivious', '[of] ' .. target)
			end
		end,
		id = "oblivious",
		name = "Oblivious",
		rating = 1,
		num = 12
	},
	['overcoat'] = {
		onImmunity = function(type, pokemon)
			if type == 'sandstorm' or type == 'hail' or type == 'powder' then return false end
		end,
		id = "overcoat",
		name = "Overcoat",
		rating = 2.5,
		num = 142
	},
	['overgrow'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Grass' then
				self:debug('Overgrow boost')
				return self:chainModify(1.3)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move)
			if move.type == 'Grass' then
				self:debug('Overgrow boost')
				return self:chainModify(1.3)
			end
		end,
		id = "overgrow",
		name = "Overgrow",
		rating = 2,
		num = 65
	},
	['owntempo'] = {
		onUpdate = function(pokemon)
			if pokemon.volatiles['confusion'] then
				pokemon:removeVolatile('confusion')
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'confusion' then
				self:add('-immune', pokemon, 'confusion')
				return false
			end
		end,
		onBoost = function(boost, target, source, effect)
			if effect.name == "Intimidate" and boost.atk and boost.atk < 0 then
				boost.atk = 0
				self:add('-fail', target, 'unboost', 'Attack', '[from] ability: Own Tempo', '[of] ' .. target)
			end
		end,
		id = "owntempo",
		name = "Own Tempo",
		rating = 1,
		num = 20
	},
	powerconstruct={
		id='powerconstruct',
		name='Power Construct',
		num=211,
		onResidualOrder=27,
		onResidual = function(pokemon)
			if pokemon.baseSpecies ~= 'Zygarde' and not pokemon.transformed and pokemon.hp <= 0 then return end
			if pokemon.species.id == 'zygardecomplete' and pokemon.hp > pokemon.maxhp / 2 then return end
			if pokemon.side.isComplete then return end
			if pokemon.hp > pokemon.maxhp/2 then return end
			self:add('-activate', pokemon, 'ability: Power Construct')
			--FORME
			local template = self:getTemplate('Zygarde-complete')
			pokemon:formeChange(template)
			pokemon.baseTemplate = template
			pokemon.details = template.species .. ', L' .. pokemon.level .. (pokemon.gender == '' and '' or ', ') .. pokemon.gender .. (pokemon.set.shiny and ', shiny' or '')
			self:add('detailschange', pokemon, pokemon.details, '[powerConstruct]', '[icon] '..(template.icon or 0))
			local shinyPrefix = pokemon.shiny and '_SHINY' or ''
			self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Zygarde-Complete')
			self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Zygarde-Complete')

			pokemon.iconOverride = template.icon-1
			-- is there a better way to access this?
			pokemon.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Zygarde-complete']
			pokemon.baseStatOverride = template.baseStats
			--FORME
			--self:add('-formechange', pokemon, 'Zygarde-Complete')
			pokemon.baseMaxhp = math.floor(math.floor(2*pokemon.template.baseStats[1] + pokemon.set.ivs[1] + math.floor(pokemon.set.evs[1]/4) + 100) * pokemon.level/100+10) -- 1 = hp
			local newMaxHP = (pokemon.volatiles['dynamax'] and 2*pokemon.baseMaxhp or pokemon.baseMaxhp)
			pokemon.maxhp = newMaxHP
			pokemon.hp = newMaxHP - (pokemon.maxhp - pokemon.hp)
			self:heal(pokemon.hp)
			pokemon.side.isComplete = true
		end
	},
	schooling = {
		onStart = function(pokemon) 
			if pokemon.template.species == 'Wishiwashi' and pokemon.level >= 20 and pokemon.hp > pokemon.maxhp / 4 and not pokemon.schooling and pokemon:formeChange('Wishiwashi-School') then 
				pokemon.schooling = true
				self:add('-formechange', pokemon, 'Wishiwashi-School')
			end
		end,
		onResidualOrder = 27,
		onResidual = function(pokemon) 
			if pokemon.template.species == 'Wishiwashi' and pokemon.level >= 20 then 
				if pokemon.hp > pokemon.maxhp / 4 and not pokemon.schooling then
					if pokemon:formeChange('Wishiwashi-School') then
						pokemon.schooling = true
						self:add('-formechange', pokemon, 'Wishiwashi-School')
					end
				elseif pokemon.hp <= pokemon.maxhp / 4 and pokemon.schooling then
					if pokemon:formeChange('Wishiwashi') then
						pokemon.schooling = false
						self:add('-formechange', pokemon, 'Wishiwashi')
					end
				end
			end
		end,

		name = "Schooling",
		rating = 3,
		num = 208,
		id = 'schooling'
	},
	['sharpness'] = {
		onBasePowerPriority = 19,
		onBasePower = function(basePower, attacker, defender, move)
			if move.flags['slicing'] then
				self:debug('Sharpness boost')
				return self:chainModify(1.5)
			end
		end,
		id = "sharpness",
		name = "Sharpness",
		rating = 3,
		num = 267
	},
	['galvanize'] = {
		onModifyMovePriority = -1,
		onModifyMove = function(move, pokemon)
			if move.type == 'Normal' and move.id ~= 'naturalgift' then
				move.type = 'Electric'
				if move.category ~= 'Status' then
					pokemon:addVolatile('galvanize')
				end
			end
		end,
		effect = {
			duration = 1,
			onBasePowerPriority = 8,
			onBasePower = function(basePower, pokemon, target, move)
				return self:chainModify(0x1333, 0x1000)
			end
		},
		id = 'galvanize',
		name = "Galvanize",
		rating = 4,
		num = 206,
	},
	['surgesurfer'] = {
		onModifySpe = function(spe)
			if (self:isTerrain('electricterrain')) then
				return self:chainModify(2)
			end
		end,
		id = 'surgesurfer',
		name = "Surge Surfer",
		rating = 3,
		num = 207,
	},
	['parentalbond'] = {
		onPrepareHit = function(source, target, move)
			if move.id == 'iceball' or move.id == 'rollout' then return end
			if move.category ~= 'Status' and not move.selfdestruct and not move.multihit and not move.flags['charge'] and not move.spreadHit then
				move.multihit = 2
				source:addVolatile('parentalbond')
			end
		end,
		effect = {
			duration = 1,
			onBasePowerPriority = 8,
			onBasePower = function(basePower)
				if self.effectData.hit then
					return self:chainModify(0.25)
				else
					self.effectData.hit = true
				end
			end
		},
		id = "parentalbond",
		name = "Parental Bond",
		rating = 4,
		num = 184
	},

	['pickup'] = {
		onResidualOrder = 26,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			if pokemon.item and pokemon.item ~= '' then return end
			local pickupTargets = {}
			for _, side in pairs(self.sides) do
				for _, target in pairs(side.active) do
					if target ~= null and (target.lastItem and target.lastItem ~= '') and target.usedItemThisTurn and self:isAdjacent(pokemon, target) then
						table.insert(pickupTargets, target)
					end
				end
			end
			if #pickupTargets == 0 then return end
			local target = pickupTargets[math.random(#pickupTargets)]
			pokemon:setItem(target.lastItem)
			target.lastItem = ''
			local item = pokemon:getItem()
			self:add('-item', pokemon, item, '[from] Pickup')
			if item.isBerry then pokemon:update() end
		end,
		id = "pickup",
		name = "Pickup",
		rating = 0.5,
		num = 53
	},
	['pickpocket'] = {
		onAfterMoveSecondary = function(target, source, move)
			if source and source ~= target and move and move.flags['contact'] then
				if target.item and target.item ~= '' then return end
				local yourItem = source:takeItem(target)
				if Not(yourItem) then return end
				if not target:setItem(yourItem) then
					source.item = yourItem.id
					return
				end
				self:add('-item', target, yourItem, '[from] ability = Pickpocket', '[of] ' .. source)
			end
		end,
		id = "pickpocket",
		name = "Pickpocket",
		rating = 1,
		num = 124
	},
	['pixilate'] = {
		onModifyMovePriority = -1,
		onModifyMove = function(move, pokemon)
			if move.type == 'Normal' and move.id ~= 'naturalgift' then
				move.type = 'Fairy'
				if move.category ~= 'Status' then
					pokemon:addVolatile('pixilate')
				end
			end
		end,
		effect = {
			duration = 1,
			onBasePowerPriority = 8,
			onBasePower = function(basePower, pokemon, target, move)
				return self:chainModify(0x1333, 0x1000)
			end
		},
		id = "pixilate",
		name = "Pixilate",
		rating = 3.5,
		num = 182
	},
	['plus'] = {
		onModifySpAPriority = 5,
		onModifySpA = function(spa, pokemon)
			if #pokemon.side.active == 1 then return end
			for _, ally in pairs(pokemon.side.active) do
				if ally ~= null and ally.position ~= pokemon.position and not ally.fainted and ally:hasAbility('minus', 'plus') then
					return self:chainModify(1.5)
				end
			end
		end,
		id = "plus",
		name = "Plus",
		rating = 0,
		num = 57
	},
	['poisonheal'] = {
		onDamage = function(damage, target, source, effect)
			if effect.id == 'psn' or effect.id == 'tox' then
				self:heal(target.maxhp / 8)
				return false
			end
		end,
		id = "poisonheal",
		name = "Poison Heal",
		rating = 4,
		num = 90
	},
	['poisonpoint'] = {
		onAfterDamage = function(damage, target, source, move)
			if move and move.flags['contact'] then
				if math.random(10) <= 3 then
					self.statusSourceMessage = {'-ability', target, 'poisonpoint'}
					source:trySetStatus('psn', target, move)
					self.statusSourceMessage = nil
				end
			end
		end,
		id = "poisonpoint",
		name = "Poison Point",
		rating = 2,
		num = 38
	},
	['poisontouch'] = {
		onModifyMove = function(move)
			if not move or not move.flags['contact'] then return end
			if not move.secondaries then
				move.secondaries = {}
			end
			table.insert(move.secondaries, {
				chance = 30,
				status = 'psn'
			})
		end,
		id = "poisontouch",
		name = "Poison Touch",
		rating = 2,
		num = 143
	},
	['prankster'] = {
		onModifyPriority = function(priority, pokemon, target, move)
			if not move then return end
			if move and move.category == 'Status' then
				move.pranksterBoosted = true
				return priority + 1	
			end
		end,
		id = "prankster",
		name = "Prankster",
		rating = 4,--dropped it not as good as before due to gen 7 nerf!.
		num = 158
	},

	['pressure'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Pressure')
		end,
		onDeductPP = function(target, source)
			if target.side == source.side then return end
			return 1
		end,
		id = "pressure",
		name = "Pressure",
		rating = 1.5,
		num = 46
	},
	['primordialsea'] = {
		onStart = function(source)
			self:setWeather('primordialsea')
		end,
		onAnySetWeather = function(target, source, weather)
			local allowedWeathers = {deltastream = true, desolateland = true, none = true}
			if self:getWeather().id == 'primordialsea' and not allowedWeathers[weather.id] and not Not(weather.id) then
				return false
			end
		end,
		onEnd = function(pokemon)
			if self.weatherData.source ~= pokemon then
				return
			end
			for _, target in pairs(self:getAllActive()) do
				if target == pokemon then continue end
				if target:hasAbility('primordialsea') then
					self.weatherData.source = target
					return
				end
			end
			self:clearWeather()
		end,
		id = "primordialsea",
		name = "Primordial Sea",
		rating = 5,
		num = 189
	},
	['protean'] = {
		onBeforeMovePriority = 14,
		onBeforeMove = function(source, target, move)
			local type = move.type
			if type and type ~= '???' and table.concat(source:getTypes(), '') ~= type then
				if not source:setType(type) then return end
				self:add('-start', source, 'typechange', type, '[from] Protean')
			end
		end,
		id = "protean",
		name = "Protean",
		rating = 4,
		num = 168
	},
	['purepower'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk)
			return self:chainModify(2)
		end,
		id = "purepower",
		name = "Pure Power",
		rating = 5,
		num = 74
	},
	['quickfeet'] = {
		onModifySpe = function(spe, pokemon)
			if pokemon.status and pokemon.status ~= '' then
				return self:chainModify(1.5)
			end
		end,
		id = "quickfeet",
		name = "Quick Feet",
		rating = 2.5,
		num = 95
	},
	['raindish'] = {
		onResidualOrder = 5,
		onResidualSubOrder = 2,
		onResidual = function(pokemon)
			if self:isWeather({'raindance', 'primordialsea'}) then
				self:heal(pokemon.maxhp / 8)
			else
				self:heal(pokemon.maxhp / 16)
			end
		end,
		id = "raindish",
		name = "Rain Dish",
		rating = 2.5,
		num = 44
	},
	['rattled'] = {
		onAfterDamage = function(damage, target, source, effect)
			if effect and (effect.type == 'Dark' or effect.type == 'Bug' or effect.type == 'Ghost') then
				self:boost({spe = 1})
			end
		end,
		onAfterBoost = function(boost, target, source, effect)
			if effect and effect.name == "Intimidate" and boost.atk then
				self:boost({spe = 1})
			end
		end,
		id = "rattled",
		name = "Rattled",
		rating = 1.5,
		num = 155
	},
	['reckless'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if move.recoil or move.hasCustomRecoil then
				self:debug('Reckless boost')
				return self:chainModify(0x1333, 0x1000)
			end
		end,
		id = "reckless",
		name = "Reckless",
		rating = 3,
		num = 120
	},
	['refrigerate'] = {
		onModifyMovePriority = -1,
		onModifyMove = function(move, pokemon)
			if move.type == 'Normal' and move.id ~= 'naturalgift' then
				move.type = 'Ice'
				if move.category ~= 'Status' then
					pokemon:addVolatile('refrigerate')
				end
			end
		end,
		effect = {
			duration = 1,
			onBasePowerPriority = 8,
			onBasePower = function(basePower, pokemon, target, move)
				return self:chainModify(0x1333, 0x1000)
			end
		},
		id = "refrigerate",
		name = "Refrigerate",
		rating = 4,
		num = 174
	},

	['regenerator'] = {
		onSwitchOut = function(pokemon)
			pokemon:heal(pokemon.maxhp / 3)
		end,
		id = "regenerator",
		name = "Regenerator",
		rating = 4,
		num = 144
	},
	['rivalry'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if attacker.gender and attacker.gender ~= '' and defender.gender and defender.gender ~= '' then
				if attacker.gender == defender.gender then
					self:debug('Rivalry boost')
					return self:chainModify(1.25)
				end
			end
		end,
		id = "rivalry",
		name = "Rivalry",
		rating = 1.5,
		num = 79
	},
	['rockhead'] = {
		onDamage = function(damage, target, source, effect)
			if effect.id == 'recoil' and self.activeMove.id ~= 'struggle' then return null end
		end,
		id = "rockhead",
		name = "Rock Head",
		rating = 3,
		num = 69
	},
	['roughskin'] = {
		onAfterDamageOrder = 1,
		onAfterDamage = function(damage, target, source, move)
			if source and source ~= target and move and move.flags['contact'] then
				self:damage(source.maxhp / 8, source, target, nil, true)
			end
		end,
		id = "roughskin",
		name = "Rough Skin",
		rating = 3,
		num = 24
	},
	['runaway'] = {
		id = "runaway",
		name = "Run Away",
		rating = 0,
		num = 50
	},
	['sandforce'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if self:isWeather('sandstorm') then
				if move.type == 'Rock' or move.type == 'Ground' or move.type == 'Steel' then
					self:debug('Sand Force boost')
					return self:chainModify(0x14CD, 0x1000)
				end
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'sandstorm' then return false end
		end,
		id = "sandforce",
		name = "Sand Force",
		rating = 2,
		num = 159
	},


	['sandrush'] = {
		onModifySpe = function(spe, pokemon)
			if self:isWeather('sandstorm') then
				return self:chainModify(2)
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'sandstorm' then return false end
		end,
		id = "sandrush",
		name = "Sand Rush",
		rating = 2.5,
		num = 146
	},
	['sandstream'] = {
		onStart = function(source)
			self:setWeather('sandstorm')
		end,
		id = "sandstream",
		name = "Sand Stream",
		rating = 4,
		num = 45
	},


	['sandveil'] = {
		onImmunity = function(type, pokemon)
			if type == 'sandstorm' then return false end
		end,
		onModifyAccuracy = function(accuracy)
			if type(accuracy) ~= 'number' then return end
			if self:isWeather('sandstorm') then
				self:debug('Sand Veil - decreasing accuracy')
				return accuracy * 0.8
			end
		end,
		id = "sandveil",
		name = "Sand Veil",
		rating = 1.5,
		num = 8
	},
	['sapsipper'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Grass' then
				if not self:boost({atk = 1}) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		onAllyTryHitSide = function(target, source, move)
			if target == self.effectData.target or target.side ~= source.side then return end
			if move.type == 'Grass' then
				self:boost({atk = 1}, self.effectData.target)
			end
		end,
		id = "sapsipper",
		name = "Sap Sipper",
		rating = 3.5,
		num = 157
	},
	['scrappy'] = {
		onModifyMovePriority = -5,
		onModifyMove = function(move)
			if not move.ignoreImmunity then move.ignoreImmunity = {} end
			if move.ignoreImmunity ~= true then
				move.ignoreImmunity['Fighting'] = true
				move.ignoreImmunity['Normal'] = true
			end
		end,
		onBoost = function(boost, target, source, effect)
			if effect.name == "Intimidate" and boost.atk and boost.atk < 0 then
				boost.atk = 0
				self:add('-fail', target, 'unboost', 'Attack', '[from] ability: Scrappy', '[of] ' .. target)
			end
		end,
		id = "scrappy",
		name = "Scrappy",
		rating = 3,
		num = 113
	},
	['serenegrace'] = {
		onModifyMovePriority = -2,
		onModifyMove = function(move)
			if move.secondaries and move.id ~= 'secretpower' then
				self:debug('doubling secondary chance')
				for _, s in pairs(move.secondaries) do
					s.chance = s.chance * 2
				end
			end
		end,
		id = "serenegrace",
		name = "Serene Grace",
		rating = 4,
		num = 32
	},
	['shadowtag'] = {
		onFoeModifyPokemon = function(pokemon)
			if not pokemon:hasAbility('shadowtag') and self:isAdjacent(pokemon, self.effectData.target) then
				pokemon:tryTrap(true, self.effectData.target, 'Shadow Tag')
			end
		end,
		onFoeMaybeTrapPokemon = function(pokemon, source)
			if Not(source) then source = self.effectData.target end
			if not pokemon:hasAbility('shadowtag') and self:isAdjacent(pokemon, source) then
				pokemon.maybeTrapped = true
			end
		end,
		id = "shadowtag",
		name = "Shadow Tag",
		rating = 5,
		num = 23
	},
	['shedskin'] = {
		onResidualOrder = 5,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			if pokemon.hp and (pokemon.status and pokemon.status ~= '') and math.random(3) == 1 then
				self:debug('shed skin')
				self:add('-activate', pokemon, 'ability = Shed Skin')
				pokemon:cureStatus()
			end
		end,
		id = "shedskin",
		name = "Shed Skin",
		rating = 3.5,
		num = 61
	},
	['sheerforce'] = {
		onModifyMove = function(move, pokemon)
			if move.secondaries then
				move.secondaries = nil
				-- Negation of `AfterMoveSecondary` effects implemented in Extension
				pokemon:addVolatile('sheerforce')
			end
		end,
		effect = {
			duration = 1,
			onBasePowerPriority = 8,
			onBasePower = function(basePower, pokemon, target, move)
				return self:chainModify(0x14CD, 0x1000)
			end
		},
		id = "sheerforce",
		name = "Sheer Force",
		rating = 4,
		num = 125
	},
	['shellarmor'] = {
		onCriticalHit = function() return false end,
		id = "shellarmor",
		name = "Shell Armor",
		rating = 1,
		num = 75
	},
	['shielddust'] = {
		onModifySecondaries = function(secondaries)
			self:debug('Shield Dust prevent secondary')
			return filter(secondaries, function(effect)
				return effect.self and true or false
			end)
		end,
		id = "shielddust",
		name = "Shield Dust",
		rating = 2.5,
		num = 19
	},
	['simple'] = {
		onBoost = function(boost)
			for i, b in pairs(boost) do
				boost[i] = b * 2
			end
		end,
		id = "simple",
		name = "Simple",
		rating = 4,
		num = 86
	},
	['skilllink'] = {
		onModifyMove = function(move)
			if move.multihit and type(move.multihit) == 'table' then
				move.multihit = move.multihit[2]
			end
		end,
		id = "skilllink",
		name = "Skill Link",
		rating = 4,
		num = 92
	},
	['slowstart'] = {
		onStart = function(pokemon)
			pokemon:addVolatile('slowstart')
		end,
		onEnd = function(pokemon)
			pokemon.volatiles['slowstart'] = nil
			self:add('-end', pokemon, 'Slow Start', '[silent]')
		end,
		effect = {
			duration = 5,
			onStart = function(target)
				self:add('-start', target, 'Slow Start')
			end,
			onModifyAtkPriority = 5,
			onModifyAtk = function(atk, pokemon)
				return self:chainModify(0.5)
			end,
			onModifySpe = function(spe, pokemon)
				return self:chainModify(0.5)
			end,
			onEnd = function(target)
				self:add('-end', target, 'Slow Start')
			end
		},
		id = "slowstart",
		name = "Slow Start",
		rating = -2,
		num = 112
	},
	['sniper'] = {
		onModifyDamage = function(damage, source, target, move)
			if move.crit then
				self:debug('Sniper boost')
				return self:chainModify(1.5)
			end
		end,
		id = "sniper",
		name = "Sniper",
		rating = 1,
		num = 97
	},
	['snowcloak'] = {
		onImmunity = function(type, pokemon)
			if type == 'hail' then return false end
		end,
		onModifyAccuracy = function(accuracy)
			if type(accuracy) ~= 'number' then return end
			if self:isWeather('hail') then
				self:debug('Snow Cloak - decreasing accuracy')
				return accuracy * 0.8
			end
		end,
		id = "snowcloak",
		name = "Snow Cloak",
		rating = 1.5,
		num = 81
	},
	['snowwarning'] = {
		onStart = function(source)
			self:setWeather('hail')
		end,
		id = "snowwarning",
		name = "Snow Warning",
		rating = 3.5,
		num = 117
	},
	['solarpower'] = {
		onModifySpAPriority = 5,
		onModifySpA = function(spa, pokemon)
			if self:isWeather({'sunnyday', 'desolateland'}) then
				return self:chainModify(1.5)
			end
		end,
		id = "solarpower",
		name = "Solar Power",
		rating = 2,
		num = 94
	},
	['solidrock'] = {
		onSourceModifyDamage = function(damage, source, target, move)
			if move.typeMod > 0 then --if self:getEffectiveness(move, target) > 1 then
				self:debug('Solid Rock neutralize')
				return self:chainModify(0.75)
			end
		end,
		id = "solidrock",
		name = "Solid Rock",
		rating = 3,
		num = 116
	},
	['soundproof'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.flags['sound'] then
				self:add('-immune', target, '[msg]')
				return null
			end
		end,
		id = "soundproof",
		name = "Soundproof",
		rating = 2,
		num = 43
	},
	['speedboost'] = {
		onResidualOrder = 26,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			if pokemon.activeTurns and pokemon.activeTurns > 0 then
				self:boost({spe = 1})
			end
		end,
		id = "speedboost",
		name = "Speed Boost",
		rating = 4.5,
		num = 3
	},
	['stall'] = {
		onModifyPriority = function(priority)
			return priority - 0.1
		end,
		id = "stall",
		name = "Stall",
		rating = -1,
		num = 100
	},
	['stancechange'] = {
		onBeforeMovePriority = 11,
		onBeforeMove = function(pokemon, target, move)
			if pokemon.template.species ~= 'Aegislash' then return end
			if move.category ~= 'Status' then
				if Not(pokemon.template.forme) and pokemon:formeChange('Aegislash-Blade') then
					self:add('-formechange', pokemon, 'Aegislash-Blade')
				end
			elseif move.id == 'kingsshield' then
				if pokemon.template.forme == 'Blade' and pokemon:formeChange('Aegislash') then
					self:add('-formechange', pokemon, 'Aegislash')
				end
			end
		end,
		id = "stancechange",
		name = "Stance Change",
		rating = 5,
		num = 176
	},
	['static'] = {
		onAfterDamage = function(damage, target, source, effect)
			if effect and effect.flags['contact'] then
				if math.random(10) <= 3 then
					self.statusSourceMessage = {'-ability', target, 'static'}
					source:trySetStatus('par', target, effect)
					self.statusSourceMessage = nil
				end
			end
		end,
		id = "static",
		name = "Static",
		rating = 2,
		num = 9
	},
	['steadfast'] = {
		onFlinch = function(pokemon)
			self:boost({spe = 1})
		end,
		id = "steadfast",
		name = "Steadfast",
		rating = 1,
		num = 80
	},
	['stench'] = {
		onModifyMove = function(move)
			if move.category ~= "Status" then
				self:debug('Adding Stench flinch')
				if not move.secondaries then move.secondaries = {} end
				for _, s in pairs(move.secondaries) do
					if s.volatileStatus == 'flinch' then return end
				end
				table.insert(move.secondaries, {
					chance = 10,
					volatileStatus = 'flinch'
				})
			end
		end,
		id = "stench",
		name = "Stench",
		rating = 0.5,
		num = 1
	},
	['stickyhold'] = {
		onTakeItem = function(item, pokemon, source)
			if self:suppressingAttackEvents() and pokemon ~= self.activePokemon then return end
			if (source and source ~= pokemon) or self.activeMove.id == 'knockoff' then
				self:add('-activate', pokemon, 'ability: Sticky Hold')
				return false
			end
		end,
		id = "stickyhold",
		name = "Sticky Hold",
		rating = 1.5,
		num = 60
	},
	['stormdrain'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Water' and move.id ~= 'snipeshot' then
				if not self:boost({spa = 1}) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		onAnyRedirectTargetPriority = 1,
		onAnyRedirectTarget = function(target, source, source2, move)
			if move.type ~= 'Water' or ({firepledge=true, grasspledge=true, waterpledge=true})[move.id] then return end
			if self:validTarget(self.effectData.target, source, move.target) then
				move.accuracy = true
				return self.effectData.target
			end
		end,
		id = "stormdrain",
		name = "Storm Drain",
		rating = 3.5,
		num = 114
	},

	['strongjaw'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if move.flags['bite'] then
				return self:chainModify(1.5)
			end
		end,
		id = "strongjaw",
		name = "Strong Jaw",
		rating = 3,
		num = 173
	},
	['sturdy'] = {
		onTryHit = function(pokemon, target, move)
			if move.ohko then
				self:add('-immune', pokemon, '[msg]')
				return null
			end
		end,
		onDamagePriority = -100,
		onDamage = function(damage, target, source, effect)
			if target.hp == target.maxhp and damage >= target.hp and effect and effect.effectType == 'Move' then
				self:add('-ability', target, 'Sturdy')
				return target.hp - 1
			end
		end,
		id = "sturdy",
		name = "Sturdy",
		rating = 3,
		num = 5
	},
	['suctioncups'] = {
		onDragOutPriority = 1,
		onDragOut = function(pokemon)
			self:add('-activate', pokemon, 'ability = Suction Cups')
			return null
		end,
		id = "suctioncups",
		name = "Suction Cups",
		rating = 2,
		num = 21
	},
	['superluck'] = {
		onModifyMove = function(move)
			move.critRatio = move.critRatio + 1
		end,
		id = "superluck",
		name = "Super Luck",
		rating = 1.5,
		num = 105
	},
	['supersweetsyrup'] = {
		onStart = function(pokemon)
			local activated = false
			for _, foe in pairs(pokemon.side.foe.active) do
				if foe ~= null and self:isAdjacent(foe, pokemon) then
					if not activated then
						self:add('-ability', pokemon, 'Supersweet Syrup', foe)
						activated = true
					end
					if foe.volatiles['substitute'] then
						self:add('-activate', foe, 'Substitute', 'ability = Supersweet Syrup', '[of] ' .. pokemon)
					else
						self:boost({evasion = -1}, foe, pokemon)
					end
				end
			end
		end,
		id = "supersweetsyrup",
		name = "Supersweet Syrup",
		rating = 3.5,
		num = 302
	},
	['swarm'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Bug' then
				self:debug('Swarm boost')
				return self:chainModify(1.3)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move)
			if move.type == 'Bug' then
				self:debug('Swarm boost')
				return self:chainModify(1.3)
			end
		end,
		id = "swarm",
		name = "Swarm",
		rating = 2,
		num = 68
	},
	['sweetveil'] = {
		id = "sweetveil",
		name = "Sweet Veil",
		onAllySetStatus = function(status, target, source, effect)
			if status.id == 'slp' then
				self:debug('Sweet Veil interrupts sleep')
				return false
			end
		end,
		onAllyTryHit = function(target, source, move)
			if move and move.id == 'yawn' then
				self:debug('Sweet Veil blocking yawn')
				return false
			end
		end,
		rating = 2,
		num = 175
	},
	['swiftswim'] = {
		onModifySpe = function(spe, pokemon)
			if self:isWeather({'raindance', 'primordialsea'}) then
				return self:chainModify(2)
			end
		end,
		id = "swiftswim",
		name = "Swift Swim",
		rating = 2.5,
		num = 33
	},
	['symbiosis'] = {
		onAllyAfterUseItem = function(item, pokemon)
			local sourceItem = self.effectData.target:getItem()
			local noSharing = sourceItem.onTakeItem and sourceItem.onTakeItem(sourceItem, pokemon) == false
			if (not sourceItem or sourceItem == '') or noSharing then return end
			sourceItem = self.effectData.target:takeItem()
			if Not(sourceItem) then return end
			if pokemon:setItem(sourceItem) then
				self:add('-activate', pokemon, 'ability = Symbiosis', sourceItem, '[of] ' .. self.effectData.target)
			end
		end,
		id = "symbiosis",
		name = "Symbiosis",
		rating = 0,
		num = 180
	},
	['synchronize'] = {
		onAfterSetStatus = function(status, target, source, effect)
			if Not(source) or source == target then return end
			if effect and effect.id == 'toxicspikes' then return end
			if status.id == 'slp' or status.id == 'frz' then return end
			source:trySetStatus(status, target)
		end,
		id = "synchronize",
		name = "Synchronize",
		rating = 2.5,
		num = 28
	},
	['tangledfeet'] = {
		id = "tangledfeet",
		name = "Tangled Feet",
		rating = 1,
		num = 77
	},
	['technician'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if basePower <= 60 then
				self:debug('Technician boost')
				return self:chainModify(1.5)
			end
		end,
		id = "technician",
		name = "Technician",
		rating = 4,
		num = 101
	},
	['telepathy'] = {
		onTryHit = function(target, source, move)
			if target ~= source and target.side == source.side and move.category ~= 'Status' then
				self:add('-activate', target, 'ability = Telepathy')
				return null
			end
		end,
		id = "telepathy",
		name = "Telepathy",
		rating = 0,
		num = 140
	},
	['teravolt'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Teravolt')
		end,
		stopAttackEvents = true,
		id = "teravolt",
		name = "Teravolt",
		rating = 3.5,
		num = 164
	},
	['thickfat'] = {
		onModifyAtkPriority = 6,
		onSourceModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Ice' or move.type == 'Fire' then
				self:debug('Thick Fat weaken')
				return self:chainModify(0.5)
			end
		end,
		onModifySpAPriority = 5,
		onSourceModifySpA = function(atk, attacker, defender, move)
			if move.type == 'Ice' or move.type == 'Fire' then
				self:debug('Thick Fat weaken')
				return self:chainModify(0.5)
			end
		end,
		id = "thickfat",
		name = "Thick Fat",
		rating = 3.5,
		num = 47
	},
	['tintedlens'] = {
		onModifyDamage = function(damage, source, target, move)
			if move.typeMod < 0 then --if self:getEffectiveness(move, target) < 1 then
				self:debug('Tinted Lens boost')
				return self:chainModify(2)
			end
		end,
		id = "tintedlens",
		name = "Tinted Lens",
		rating = 4,
		num = 110
	},
	['torrent'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Water' then
				self:debug('Torrent boost')
				return self:chainModify(1.3)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move)
			if move.type == 'Water' then
				self:debug('Torrent boost')
				return self:chainModify(1.3)
			end
		end,
		id = "torrent",
		name = "Torrent",
		rating = 2,
		num = 67
	},
	['toxicboost'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if (attacker.status == 'psn' or attacker.status == 'tox') and move.category == 'Physical' then
				return self:chainModify(1.5)
			end
		end,
		id = "toxicboost",
		name = "Toxic Boost",
		rating = 3,
		num = 137
	},
	['toughclaws'] = {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move)
			if move.flags['contact'] then
				return self:chainModify(0x14CD, 0x1000)
			end
		end,
		id = "toughclaws",
		name = "Tough Claws",
		rating = 3.5,
		num = 181
	},
	['trace'] = {
		onUpdate = function(pokemon)
			local possibleTargets = {}
			for _, foe in pairs(pokemon.side.foe.active) do
				if foe ~= null and not foe.fainted then
					table.insert(possibleTargets, foe)
				end
			end
			while #possibleTargets > 0 do
				local rand = 1
				if #possibleTargets > 1 then
					rand = math.random(#possibleTargets)
				end
				local target = possibleTargets[rand]
				local ability = self:getAbility(target.ability)
				local bannedAbilities = {flowergift=true, forecast=true, illusion=true, imposter=true, multitype=true, stancechange=true, trace=true, zenmode=true, asone=true}
				if bannedAbilities[target.ability] then
					table.remove(possibleTargets, rand)
				else
					self:add('-ability', pokemon, ability, '[from] ability = Trace', '[of] ' .. target)
					pokemon:setAbility(ability)
					return
				end
			end
		end,
		id = "trace",
		name = "Trace",
		rating = 3,
		num = 36
	},
	['truant'] = {
		onBeforeMovePriority = 9,
		onBeforeMove = function(pokemon, target, move)
			if pokemon:removeVolatile('truant') then
				self:add('cant', pokemon, 'ability = Truant', move)
				return false
			end
			pokemon:addVolatile('truant')
		end,
		effect = {
			duration = 2
		},
		id = "truant",
		name = "Truant",
		rating = -2,
		num = 54
	},
	['turboblaze'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Turboblaze')
		end,
		stopAttackEvents = true,
		id = "turboblaze",
		name = "Turboblaze",
		rating = 3.5,
		num = 163
	},
	['unaware'] = {
		id = "unaware",
		name = "Unaware",
		onAnyModifyBoost = function(boosts, target)
			local source = self.effectData.target
			if source == target then return end
			if source == self.activePokemon and target == self.activeTarget then
				boosts['def'] = 0
				boosts['spd'] = 0
				boosts['evasion'] = 0
			end
			if target == self.activePokemon and source == self.activeTarget then
				boosts['atk'] = 0
				boosts['spa'] = 0
				boosts['accuracy'] = 0
			end
		end,
		rating = 3,
		num = 109
	},
	['unburden'] = {
		onAfterUseItem = function(item, pokemon)
			if pokemon ~= self.effectData.target then return end
			pokemon:addVolatile('unburden')
		end,
		onTakeItem = function(item, pokemon)
			pokemon:addVolatile('unburden')
		end,
		onEnd = function(pokemon)
			pokemon:removeVolatile('unburden')
		end,
		effect = {
			onModifySpe = function(spe, pokemon)
				if Not(pokemon.item) and Not(pokemon:ignoringAbility()) then
					return self:chainModify(2)
				end
			end
		},
		id = "unburden",
		name = "Unburden",
		rating = 3.5,
		num = 84
	},
	['unnerve'] = {
		onStart = function(pokemon)
			self:add('-ability', pokemon, 'Unnerve', pokemon.side.foe)
		end,
		onFoeEatItem = function() return false end,
		id = "unnerve",
		name = "Unnerve",
		rating = 1.5,
		num = 127
	},
	['victorystar'] = {
		onAllyModifyMove = function(move)
			if type(move.accuracy) == 'number' then
				move.accuracy = move.accuracy * 1.3
			end
		end,
		id = "victorystar",
		name = "Victory Star",
		rating = 2.5,
		num = 162
	},
	['vitalspirit'] = {
		onUpdate = function(pokemon)
			if pokemon.status == 'slp' then
				pokemon:cureStatus()
			end
		end,
		onImmunity = function(type)
			if type == 'slp' then return false end
		end,
		id = "vitalspirit",
		name = "Vital Spirit",
		rating = 2,
		num = 72
	},
	['voltabsorb'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Electric' then
				if Not(self:heal(target.maxhp / 4)) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		id = "voltabsorb",
		name = "Volt Absorb",
		rating = 3.5,
		num = 10
	},
	['waterabsorb'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Water' and move.id ~= 'snipeshot' then
				if Not(self:heal(target.maxhp / 4)) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		id = "waterabsorb",
		name = "Water Absorb",
		rating = 3.5,
		num = 11
	},
	['waterveil'] = {
		onUpdate = function(pokemon)
			if pokemon.status == 'brn' then
				pokemon:cureStatus()
			end
		end,
		onImmunity = function(type, pokemon)
			if type == 'brn' then return false end
		end,
		id = "waterveil",
		name = "Water Veil",
		rating = 2,
		num = 41
	},
	['weakarmor'] = {
		onAfterDamage = function(damage, target, source, move)
			if move.category == 'Physical' then
				self:boost({def = -1, spe = 2})
			end
		end,
		id = "weakarmor",
		name = "Weak Armor",
		rating = 0.5,
		num = 133
	},
	['whitesmoke'] = {
		onBoost = function(boost, target, source, effect)
			if source and target == source then return end
			local showMsg = false
			for i, b in pairs(boost) do
				if b < 0 then
					boost[i] = nil
					showMsg = true
				end
			end
			if showMsg and not effect.secondaries then
				self:add("-fail", target, "unboost", "[from] ability = White Smoke", "[of] " .. target)
			end
		end,
		id = "whitesmoke",
		name = "White Smoke",
		rating = 2,
		num = 73
	},
	['wonderguard'] = {
		onTryHit = function(target, source, move)
			if target == source or move.category == 'Status' or move.type == '???' or move.id == 'struggle' or move.isFutureMove then return end
			self:debug('Wonder Guard immunity = ' .. move.id)
			if target:runEffectiveness(move) <= 1 then
				self:add('-activate', target, 'ability = Wonder Guard')
				return null
			end
		end,
		id = "wonderguard",
		name = "Wonder Guard",
		rating = 5,
		num = 25
	},
	['wonderskin'] = {
		onModifyAccuracyPriority = 10,
		onModifyAccuracy = function(accuracy, target, source, move)
			if move.category == 'Status' and type(move.accuracy) == 'number' then
				self:debug('Wonder Skin - setting accuracy to 50')
				return 50
			end
		end,
		id = "wonderskin",
		name = "Wonder Skin",
		rating = 2,
		num = 147
	},
	['zenmode'] = {
		onSwitchIn = function(pokemon)
			pokemon:addVolatile('zenmode')
		end,
		effect = {
			onStart = function(pokemon)
				if pokemon.template.speciesid == 'darmanitangalar' then
					if pokemon:formeChange('Darmanitan-ZenGalar') and pokemon.volatiles['zenmode'] then
						self:add('-formechange', pokemon, 'Darmanitan-ZenGalar', '[from] ability: Zen Mode')
					else
						return false
					end
				else
					if pokemon:formeChange('Darmanitan-Zen') and pokemon.volatiles['zenmode'] then
						self:add('-formechange', pokemon, 'Darmanitan-Zen', '[from] ability: Zen Mode')
					else
						return false
					end	
				end
			end,
			onEnd = function(pokemon)
				if pokemon.template.speciesid == 'darmanitanzengalar' then
					if pokemon:formeChange('Darmanitan-Galar') and not pokemon.volatiles['zenmode'] then
						self:add('-formechange', pokemon, 'Darmanitan-Galar', '[from] ability: Zen Mode')
					else
						return false
					end
				else
					if pokemon:formeChange('Darmanitan') and not pokemon.volatiles['zenmode'] then
						self:add('-formechange', pokemon, 'Darmanitan', '[from] ability: Zen Mode')
					else
						return false
					end	
				end
			end,
		},
		id = "zenmode",
		name = "Zen Mode",
		rating = 3,
		num = 161
	},

	['libero'] = {
		onBeforeMovePriority = 14,
		onBeforeMove = function(source, target, move)
			if self.effectData.libero then return end
			local type = move.type
			if type and type ~= '???' and table.concat(source:getTypes(), '') ~= type then
				if not source:setType(type) then return end
				self.effectData.libero = true
				self:add('-start', source, 'typechange', type, '[from] Libero')
			end
		end,
		onSwitchIn = function()
			self.effectData.libero = nil
		end,
		id = "libero",
		name = "Libero",
		rating = 4.5,
		num = 236
	},

	['steamengine'] = {
		onAfterDamage = function(damage, target, source, effect) 
			if (effect and effect.type == 'Water' or effect.type == 'Fire') then
				self:boost({spe = 6})
			end
		end,
		id = "steamengine",
		name = "Steam Engine",
		rating = 3,
		num = 243
	},
	['punkrock']= {
		onBasePowerPriority = 8,
		onBasePower = function(basePower, attacker, defender, move) 
			if (move.flags['sound']) then
				self:debug('Punk Rock boost')
				return self:chainModify(1.3)
			end
		end,
		onSourceModifyDamage = function(damage, source, target, move) 
			if (move.flags['sound']) then
				self:debug('Punk Rock weaken')
				return self:chainModify(0.5)
			end
		end,
		id = 'punkrock',
		name = 'Punk Rock',
		rating = 3.5,
		num = 244,
	},	
	['sandspit'] = {
		onAfterDamage = function(damage, target, source, move)
			if Not(source) or source == target then return end
			if (self:getWeather().id ~= 'sandstorm') then
				self:setWeather('sandstorm')
			end
		end,
		name = "Sand Spit",
		rating = 2,
		num = 245,
		id = 'sandspit'
	},
	['corrosion'] = {
		onModifyMovePriority = -5,
		onModifyMove = function(move)
			if not move.ignoreImmunity then move.ignoreImmunity = {} end
			if move.ignoreImmunity ~= true then
				move.ignoreImmunity['Steel'] = true
				move.ignoreImmunity['Poison'] = true
			end
		end,
		id = "corrosion",
		name = "Corrosion",
		rating = 2,
		num = 212
	},	

	['watercompaction'] = {
		onAfterDamage = function(target, source, move)
			if move and move.type == 'Water' then
				self:boost({def = 2})
			end
		end,
		id = "watercompaction",
		name = "Water Compaction",
		rating = 1.5,
		num = 195
	},

	['triage'] = {
		onModifyPriority = function(priority, pokemon, target, move)
			if move.flags and move.flags ['heal']
			then return priority + 3
			end
		end,
		id = "triage",
		name = "Triage",
		rating = 3.5,
		num = 205
	},	

	['glacialabsorb'] = { --CUSTOM ABILITY CHANGE ID IF NEEDED
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Ice' then
				if not self:boost({spa = 1}) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		onAnyRedirectTargetPriority = 1,
		onAnyRedirectTarget = function(target, source, source2, move)
			if move.type ~= 'Ice' or ({firepledge=true, grasspledge=true, waterpledge=true})[move.id] then return end
			if self:validTarget(self.effectData.target, source, move.target) then
				return self.effectData.target
			end
		end,
		id = "glacialabsorb",
		name = "Glacial Absorb",
		rating = 3.5,
		num = 231
	},		

	['battery'] = {
		onModifySpAPriority = 5,
		onModifySpA = function(spa, pokemon)
			for _, ally in pairs(pokemon.side.active) do
				return self:chainModify(1.2)
			end
		end,
		id = "battery",
		name = "Battery",
		rating = 2,
		num = 217
	},	

	['queenlymajesty'] = {
		onFoeTryMove = function(target, source, move)
			local targetAllExceptions = {'perishsong', 'flowershield', 'rototiller'}
			if (move.target == 'foeSide' or (move.target == 'all' and not targetAllExceptions:find(move.id))) then
				return
			end
			local queenlyholder = self.effectData.target
			if ((source.side == queenlyholder.side or move.target == 'all') and move.priority > 0.1) then
				self:attrLastMove('[still]')
				self:add('cant', queenlyholder, 'ability: Queenly Majesty', move, '[of] '..target)
				return false
			end
		end,
		id = 'queenlymajesty',
		name = 'Queenly Majesty',
		rating = 2.5,
		num = 214,
	},
	['fluffy'] = {
		onSourceModifyDamage= function(damage,source,target,move)
			local mod = 1
			if move.type == "Fire" then mod = mod * 2
				if move.flags["contact"]then mod = mod / 2		
					return self:chainModify (mod)	
				end	
			end				
		end,
		id = "fluffy",
		name = "Fluffy",
		rating = 3.5,
		num = 218
	},		

	['berserk'] = {
		onDamage = function(damage, target, source, effect)
			if effect and effect.effectType == 'Move' and not effect.multihit and not (effect.negateSecondary and (effect.hasSheerForce and source:hasAbility('sheerforce'))) then
				self.effectData.checkedBerserk = false
			else
				self.effectData.checkedBerserk = true
			end
		end,
		onTryEatItem = function(item)
			local healingItems = {'aguavberry', 'enigmaberry', 'figyberry', 'iapapaberry', 'magoberry', 'sitrusberry', 'wikiberry', 'oranberry', 'berryjuice',}
			if healingItems[item.id] then
				return self.effectData.checkedBerserk            
			end
			return true
		end,
		onAfterMoveSecondary = function(target,source,move)
			self.effectData.checkedBerserk = true
			if (Not(source) or source == target or not target.hp or not move.totalDamage) then return end
			local lastAttackedBy = target:getLastAttackedBy()
			if (not lastAttackedBy) then return end
			local damage = move.multihit or move.totalDamage and lastAttackedBy.damage
			if (target.hp <= target.maxhp / 2 and target.hp + damage > target.maxhp / 2) then
				self:boost({spa = 1})
			end
		end,
		id = 'berserk',
		name = 'Berserk',
		rating = 2,
		num = 201,
	},
	['wimpout'] = {
		onAfterMoveSecondary = function(target, source, move)
			if not target.side:canSwitch(target.position) or target.forceSwitchFlag then return end
			if source and source ~= target and target.hp <= target.maxhp/2  and move.category ~= 'Status' then
				self:add('-activate', target, 'ability: Wimp Out')
				target.switchFlag = true
				source.switchFlag = false
			end
		end,
		id = "wimpout",
		name = "wimpout",
		rating = 2,
		num = 193	
	},
	['emergencyexit'] = {
		onAfterMoveSecondary = function(target, source, move)
			if not target.side:canSwitch(target.position) or target.forceSwitchFlag then return end
			if source and source ~= target and target.hp <= target.maxhp/2  and move.category ~= 'Status' then
				self:add('-activate', target, 'ability: Emergency Exit')
				target.switchFlag = true
				source.switchFlag = false
			end
		end,
		id = "emergencyexit",
		name = "Emergency Exit",
		rating = 1,
		num = 194	
	},
	['disguise'] = {
		onDamagePriority = 1,
		onDamage = function(damage, target, source, effect)
			if effect and effect.effectType == 'Move' and target.template.species == 'Mimikyu' and not self.effectData.busted and target:formeChange('Mimikyu-Busted') then
				self.effectData.busted = true
				self:add('-activate', target, 'ability: Disguise')
				self:add('-formechange', target, 'Mimikyu-Busted')
				return 0
			end
		end,
		onUpdate = function(pokemon)
			if pokemon.template.species == 'Mimikyu' and self.effectData.busted and not self.effectData.damaged then
				self:damage(pokemon.baseMaxhp/8)
				self.effectData.damaged = true
			end
		end,
		onFaint = function(pokemon)
			if pokemon.template.species == 'Mimikyu' and self.effectData.busted and pokemon:formeChange('Mimikyu') then
				self.effectData.busted = false
				self:add('-formechange', pokemon, 'Mimikyu', '[silent]')
			end
		end,
		name = 'Disguise',
		num = 209,
		id = 'disguise'
	},
	['stakeout'] = { --Should Be FIXED!
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, attacker, defender, move)
			if defender.activeTurns == 1 then
				self:debug ("Stakeout Boost")
				return self:chainModify(2)				
			end
		end,	
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move)
			if defender.activeTurns == 1 then
				self:debug ("Stakeout Boost")
				return self:chainModify(2)
			end
		end,	
		id = "stakeout",
		name = "Stakeout",
		rating = 4.5,
		num = 198
	},		

	--[[
Add AlliesAndSelf()
]]


	['ripen'] = {
		onResidualOrder = 26,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			if self:isWeather({'sunnyday', 'desolateland'}) or math.random(2) == 1 then
				if pokemon.hp and Not(pokemon.item) and self:getItem(pokemon.lastItem).isBerry then
					pokemon:setItem(pokemon.lastItem)
					self:add('-item', pokemon, pokemon:getItem(), '[from] ability = Ripen')
				end
			end
		end,
		id = "ripen",
		name = "Ripen",
		rating = 2,
		num = 247
	},

	['merciless'] = {
		onModifyCritRatio = function(critRatio,source,target)
			if target.status == "psn" or target.status == "tox" then
				return 5
			end
		end,
		id = "merciless",
		name = "Merciless",
		rating = 1.5,
		num = 196
	},			

	['stamina'] = {
		onAfterDamage = function(damage, target, source, move)
			if source and source ~= target then
				self:boost({def = 1})
			end
		end,
		id = "stamina",
		name = "Stamina",
		rating = 3.5,
		num = 192
	},				
	['shieldsdown'] = {
		onBeforeSwitchIn = function(pokemon)
			if (pokemon.baseTemplate.species ~= 'Minior' or pokemon.transformed) then return end
			if (pokemon.hp > pokemon.maxhp / 2) then
				if pokemon.template.speciesid ~= 'miniormeteor' then
					pokemon:formeChange('Minior-Meteor')
					self:add('-formechange', pokemon, 'Minior-Meteor', '[silent]')
					local template = self:getTemplate('Minior-Meteor')
					pokemon.baseStatOverride = template.baseStats
					pokemon.iconOverride = 951
				end
			else
				if (pokemon.template.speciesid == 'miniormeteor') then
					pokemon:formeChange(pokemon.baseTemplate.species)
					self:add('-formechange', pokemon, pokemon.baseTemplate.species, '[silent]')
				end
			end
		end,
		onResidualOrder = 27,
		onResidual = function(pokemon)
			if (pokemon.baseTemplate.species ~= 'Minior' or pokemon.transformed) then return end
			if (pokemon.hp > pokemon.maxhp / 2) then
				if pokemon.template.speciesid ~= 'miniormeteor' then
					pokemon:formeChange('Minior-Meteor')
					self:add('-formechange', pokemon, 'Minior-Meteor', '[silent]')
					local template = self:getTemplate('Minior-Meteor')
					pokemon.baseStatOverride = template.baseStats
				end
			else
				if pokemon.template.speciesid == 'miniormeteor' then
					pokemon:formeChange(pokemon.baseTemplate.species)
					self:add('-formechange', pokemon, pokemon.baseTemplate.species, '[silent]')
					self:add('-ability', pokemon, 'Shields Down')
					local template = self:getTemplate('Minior-Red')
					pokemon.baseStatOverride = template.baseStats
				end
			end
		end,
		onSetStatus = function(status, target, source, effect)
			if target.template.speciesid ~= 'miniormeteor' or target.transformed then return end
			if effect.status then
				self:add('-immune', target, '[from] ability: Shields Down')
			end
			return false
		end,
		onTryAddVolatile = function(status, target)
			if target.template.speciesid ~= 'miniormeteor' or target.transformed then return end 
			if status.id ~= 'yawn' then return end
			self:add('-immune', target, '[from] ability: Shields Down')
			return
		end,
		name = 'Shields Down',
		id = 'shieldsdown', 
		rating = 3,
		num = 197,
	},

	['quickdraw'] = {
		onFractionalPriorityPriority = 1,
		onFractionalPriority = function(priority, pokemon, target, move)
			if (move.category == 'Status' and self:randomChance(3, 10)) then
				self:add('-activate', pokemon, 'ability: Quick Draw')
				return 0.1
			end
		end,
		id = "quickdraw",
		name = "Quick Draw",
		rating = 2.5,
		num = 259
	},

	['electricsurge'] = {
		onStart = function(source)
			local move = self:getMoveCopy('electricterrain')
			self:setTerrain('electricterrain', source)
		end,
		id = "electricsurge",
		name = "Electric Surge",
		rating = 4,
		num = 226
	},
	['psychicsurge'] = {
		onStart = function(source)
			local move = self:getMoveCopy('psychicterrain')
			self:setTerrain('psychicterrain', source)
		end,
		id = "psychicsurge",
		name = "Psychic Surge",
		rating = 4,
		num = 227
	},
	['mistysurge'] = {
		onStart = function(source)
			local move = self:getMoveCopy('mistyterrain')
			self:setTerrain('mistyterrain', source)
		end,
		id = "mistysurge",
		name = "Misty Surge",
		rating = 4,
		num = 228
	},
	['grassysurge'] = {
		onStart = function(source)
			local move = self:getMoveCopy('grassyterrain')
			self:setTerrain('grassyterrain', source)
		end,
		id = "grassysurge",
		name = "Grassy Surge",
		rating = 4,
		num = 229
	},
	['fullmetalbody'] = {
		onBoost = function(boost, target, source, effect)
			if source and target == source then return end
			local showMsg = false
			for i, b in pairs(boost) do
				if b < 0 then
					boost[i] = nil
					showMsg = true
				end
			end
			if showMsg and not effect.secondaries then
				self:add("-fail", target, "unboost", "[from] ability = Full Metal Body", "[of] " .. target)
			end
		end,
		id = "fullmetalbody",
		name = "Full Metal Body",
		rating = 2,
		num = 230
	},
	['shadowshield'] = {
		onSourceModifyDamage = function(damage, source, target, move)
			if target.hp >= target.maxhp then
				self:debug('Shadow Shield weaken')
				return self:chainModify(0.5)
			end
		end,
		id = "shadowshield",
		name = "Shadow Shield",
		rating = 4,
		num = 231
	},
	['icescales'] = {
		onSourceModifyDamage = function(damage, source, target, move)
			if move.category == "Special" then
				self:debug ("Half damage taken due to Ice Scales")
				return self:chainModify(0.5)
			end
		end,
		id = "icescales",
		name = "Ice Scales",
		rating = 4,
		num = 246
	},
	['iceface'] = {
		onStart = function(pokemon) 
			if (self:isWeather('hail') and pokemon.template.speciesid == 'eiscuenoice') then
				self:add('-activate', pokemon, 'ability: Ice Face')
				self.effectData.busted = false

				local template = self:getTemplate('Eiscue')
				pokemon:formeChange(template)
				pokemon.baseTemplate = template
				pokemon.details = template.species .. ', L' .. pokemon.level .. (pokemon.gender == '' and '' or ', ') .. pokemon.gender .. (pokemon.set.shiny and ', shiny' or '')
				self:add('detailschange', pokemon, pokemon.details, '[iceFaceN]', '[icon] '..(template.icon or 0))

				local shinyPrefix = pokemon.shiny and '_SHINY' or ''
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Eiscue')
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Eiscue')
				pokemon.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Eiscue']

				pokemon.iconOverride = template.icon-1
				pokemon.baseStatOverride = template.baseStats
				pokemon.typeOverride = template.types
				self:add('-formechange', pokemon, 'Eiscue', '[msg]')
			end
		end,
		onDamagePriority = 1,
		onDamage = function(damage, target, source, effect)
			if (effect and effect.effectType == 'Move' and effect.category == 'Physical' and target.template.speciesid == 'eiscue') then
				self:add('-activate', target, 'ability: Ice Face')
				self.effectData.busted = true
				return 0
			end
		end,
		onCriticalHit = function(target, type, move)
			if not (target) then return end
			if (move.category ~= 'Physical' or target.template.speciesid ~= 'eiscue') then return end
			if (target.volatiles['substitute'] and not (move.flags['authentic'] or  move.infiltrates)) then return end
			if not (target:runImmunity(move.type)) then return end
			return false
		end,
		onEffectiveness = function(typeMod, target, type, move)
			if not (target) then return end
			if (move.category ~= 'Physical' or target.template.speciesid ~= 'eiscue') then return end
			if (target.volatiles['substitute'] and not (move.flags['authentic'] or move.infiltrates)) then return end
			if not (target:runImmunity(move.type)) then return end
			return 0
		end,
		onUpdate = function(pokemon) 
			if (pokemon.template.speciesid == 'eiscue' and self.effectData.busted) then
				local template = self:getTemplate('Eiscue-Noice')
				pokemon:formeChange(template)
				pokemon.baseTemplate = template
				pokemon.details = template.species .. ', L' .. pokemon.level .. (pokemon.gender == '' and '' or ', ') .. pokemon.gender .. (pokemon.set.shiny and ', shiny' or '')
				self:add('detailschange', pokemon, pokemon.details, '[iceFace]', '[icon] '..(template.icon or 0))

				local shinyPrefix = pokemon.shiny and '_SHINY' or ''
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Eiscue-Noice')
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Eiscue-Noice')
				pokemon.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Eiscue-Noice']

				pokemon.iconOverride = template.icon-1
				pokemon.baseStatOverride = template.baseStats
				pokemon.typeOverride = template.types
				self:add('-formechange', pokemon, 'Eiscue-Noice', '[msg]')
			end
		end,
		onWeatherChange = function(pokemon, source, sourceEffect)
			if sourceEffect and sourceEffect.suppressWeather then return end
			if not (pokemon.hp) then return end
			if (self:isWeather('hail') and pokemon.template.speciesid == 'eiscuenoice') then
				self:add('-activate', pokemon, 'ability: Ice Face')
				self.effectData.busted = false		

				local template = self:getTemplate('Eiscue')
				pokemon:formeChange(template)
				pokemon.baseTemplate = template
				pokemon.details = template.species .. ', L' .. pokemon.level .. (pokemon.gender == '' and '' or ', ') .. pokemon.gender .. (pokemon.set.shiny and ', shiny' or '')
				self:add('detailschange', pokemon, pokemon.details, '[iceFaceN]', '[icon] '..(template.icon or 0))

				local shinyPrefix = pokemon.shiny and '_SHINY' or ''
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Eiscue')
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Eiscue')
				pokemon.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Eiscue']

				pokemon.iconOverride = template.icon-1
				pokemon.baseStatOverride = template.baseStats
				pokemon.typeOverride = template.types
				self:add('-formechange', pokemon, 'Eiscue', '[msg]')
			end
		end,
		name = "Ice Face",
		rating = 3,
		num = 248,
		id = 'iceface'
	},
	powerspot = {
		onBasePowerPriority = 22,
		onBasePower = function(basePower, attacker, defender, move)
			if (attacker == self.effectData.target) then
				self:debug('Power Spot boost')
				return self:chainModify(5325, 4096)
			end
		end,
		name = "Power Spot",
		rating = 1,
		num = 249,
		id = 'powerspot'
	},
	--[[	mimicry: {
			onStart(pokemon) {
				if (this.field.terrain) {
					pokemon.addVolatile('mimicry')
					} else {
		const types = pokemon.baseSpecies.types
		if (pokemon.getTypes().join() === types.join() || !pokemon.setType(types)) return
			this.add('-start', pokemon, 'typechange', types.join('/'), '[from] ability: Mimicry')
			this.hint("Transform Mimicry changes you to your original un-transformed types.")
			}
		},
		onAnyTerrainStart() {
		const pokemon = this.effectData.target
		delete pokemon.volatiles['mimicry']
		pokemon.addVolatile('mimicry')
	},
	onEnd(pokemon) {
		delete pokemon.volatiles['mimicry']
	},
	condition: {
		onStart(pokemon) {
			let newType
			switch (this.field.terrain) {
				case 'electricterrain':
				newType = 'Electric'
				break
				case 'grassyterrain':
				newType = 'Grass'
				break
				case 'mistyterrain':
				newType = 'Fairy'
				break
				case 'psychicterrain':
				newType = 'Psychic'
				break
			}
			if (!newType || pokemon.getTypes().join() === newType || !pokemon.setType(newType)) return
				this.add('-start', pokemon, 'typechange', newType, '[from] ability: Mimicry')
		},
		onUpdate(pokemon) {
			if (!this.field.terrain) {
				const types = pokemon.species.types
				if (pokemon.getTypes().join() === types.join() || !pokemon.setType(types)) return
					this.add('-activate', pokemon, 'ability: Mimicry')
					this.add('-end', pokemon, 'typechange', '[silent]')
					pokemon.removeVolatile('mimicry')
					}
		},
	},
	name: "Mimicry",
	rating: 0.5,
	num: 250,
	},]]
	--[[
	screencleaner: {
		onStart(pokemon) {
			let activated = false
			for (const sideCondition of ['reflect', 'lightscreen', 'auroraveil']) {
				if (pokemon.side.getSideCondition(sideCondition)) {
					if (!activated) {
						this.add('-activate', pokemon, 'ability: Screen Cleaner')
						activated = true
					}
					pokemon.side.removeSideCondition(sideCondition)
				}
				if (pokemon.side.foe.getSideCondition(sideCondition)) {
					if (!activated) {
						this.add('-activate', pokemon, 'ability: Screen Cleaner')
						activated = true
					}
					pokemon.side.foe.removeSideCondition(sideCondition)
				}
			}
		},
		name: "Screen Cleaner",
		rating: 2,
		num: 251,
	},
	]]
	['steelyspirit'] = {
		onStart = function(pokemon,source)
			local targets = {}
			local activated = false
			for _, side in pairs(self.sides) do
				for _, pokemon in pairs(side.active) do
					if pokemon ~= null and not pokemon.fainted and pokemon:hasType('Steel') then

						table.insert(targets, pokemon)
					end
				end
			end
			if #targets == 0 then return false end -- No targets; move fails
			for _, target in pairs(targets) do
				self:boost({atk = 1}, target, source, self:getMove('Steely Spirit'))
			end
		end,
		id = "steelyspirit",
		name = "Steely Spirit",
		rating = 3.5,
		num = 252
	},
	['screencleaner'] = {
		onStart = function(pokemon)
			if not Not(pokemon:runImmunity('Fighting')) then
				pokemon.side:removeSideCondition('reflect')
				pokemon.side:removeSideCondition('lightscreen')
				pokemon.side:removeSideCondition('auroraveil')
			end
		end,
		id = "screencleaner",
		name = "Screen Cleaner",
		rating = 2,
		num = 251
	},
	['mimicry'] = {
		onStart = function(target)
			local newType = 'Normal'
			if self:isTerrain('electricterrain') then
				newType = 'Electric'
			elseif self:isTerrain('grassyterrain') then
				newType = 'Grass'
			elseif self:isTerrain('mistyterrain') then
				newType = 'Fairy'
			end

			if Not(target:setType(newType)) then return false end
			self:add('-start', target, 'typechange', newType)
		end,
		id = "mimicry",
		name = "Mimicry",
		rating = 0.5,
		num = 250

	},
	['perishbody'] = {
		onAfterDamage = function(damage, target, source, move)
			if not move.flags['contact'] or not source then
				return
			end
			local announced = false
			for i, pokemon in ipairs({target, source}) do
				if pokemon.volatiles.perishsong then continue end
				if not announced then
					self:add("-ability", target, "Perish Body")
					announced = true
				end
				pokemon:addVolatile("perishsong")
			end
		end,
		id = "perishbody",
		name = "Perish Body",
		rating = 1,
		num = 253
	},
	['wanderingspirit'] = {
		onAfterDamage = function(damage, target, source, move)
			local additionalBannedAbilities = {'hungerswitch', 'illusion', 'neutralizinggas', 'wonderguard'}
			if Not(source) or source == target then return end
			if (source:getAbility().isPermanent or target.volatiles['dynamax']) then return end
			for k, ability in ipairs(additionalBannedAbilities) do
				if source:getAbility().id == ability then return end
			end
			if (move.flags['contact']) then
				local sourceAbility = source:setAbility('wanderingspirit', target)
				if not (sourceAbility) then return end
				if (target.side == source.side) then
					self:add('-activate', target, 'Skill Swap', '', '', '[of] '..source)
				else
					self:add('-activate', target, 'ability: Wandering Spirit', self:getAbility(sourceAbility).name, 'Wandering Spirit', '[of] '..source)
				end
				target:setAbility(sourceAbility)
			end
		end,
		id = "wanderingspirit",
		name = "Wandering Spirit",
		rating = 2.5,
		num = 254
	},
	['gorillatactics'] = {		
		onStart = function(pokemon)
			pokemon.abilityData.choicelock = false
		end,
		onBeforeMove = function(pokemon, target, move)
			if move.isZ or move.isMax or move.id == 'struggle' then
				return
			end
			if (pokemon.abilityData.choicelock and pokemon.abilityData.choicelock ~= move.id) then
				self:add('-fail')
				self:debug("Disabled by Gorilla Tactics")
				return false
			end
		end,
		onModifyMove = function(move, pokemon)
			if (pokemon.abilityData.choicelock or move.isZ or move.isMax or move.id == 'struggle') then
				return
			end
			pokemon.abilityData.choicelock = move.id
		end,
		onModifyAtk = function(atk, pokemon)
			if pokemon.currentDyna then return end
			return self:chainModify(1.5)
		end,
		onDisableMove = function(pokemon)
			if not pokemon.abilityData.choicelock or pokemon.currentDyna then
				return
			end
			for _, move in pairs(pokemon.moveset) do
				if move.id ~= pokemon.abilityData.choicelock then
					print("Disabling " .. move.id)
					pokemon:disableMove(move.id, false, self.effectData.sourceEffect)
				end
			end
		end,
		onEnd = function(pokemon)
			pokemon.abilityData.choicelock = false
		end,
		id = "gorillatactics",
		name = "Gorilla Tactics",
		rating = 4.5,
		num = 255
	},	
	['neutralizinggas'] = {
		onBeforeSwitchIn = function(pokemon)
			self:add("-ability", pokemon, "Neutralizing Gas")
			pokemon.abilityData.ending = false

			local strongWeathers = {'desolateland', 'primordialsea', 'deltastream'}
			for _, target in pairs(self:getAllActive()) do
				if target == null then
					continue
				end
				if target:hasItem('abilityshield') then
					self:add('-block', target, 'item: Ability Shield')
					continue
				end
				if target.volatiles['commanding'] then
					continue
				end
				if target.illusion then
					self:add('-endability', target, 'Illusion', target.getDetails)
				end
				if target.volatiles['slowstart'] then
					target.volatiles['slowstart'] = nil
					self:add('-end', target, "Slow Start", "[silent]")
				end
				if table.find(strongWeathers, target.ability) then
					self:singleEvent('End', self:getAbility(target:getAbility()), target.abilityData, target, pokemon, 'neutralizinggas')
				end
			end
			for _, side in pairs(self.sides) do
				for _, target in pairs(side.active) do
					if target == null then
						continue
					end
					if target.illusion then
						self:add('-endability', target, 'Illusion', target.getDetails)
					end
					if target.volatiles['slowstart'] then
						target.volatiles['slowstart'] = nil
						self:add("-end", target, "Slow Start", "[silent]")
					end
				end
			end
		end,
		onEnd = function(source)
			if source.transformed then
				return
			end

			for _, pokemon in pairs(self:getAllActive()) do
				if pokemon ~= source and pokemon:hasAbility('neutralizinggas') then
					return
				end
			end
			self:add("-end", source, "ability: Neutralizing Gas")

			-- Mark this as ending
			if source.abilityData.ending then return end
			source.abilityData.ending = true

			local unaffected = {'powerconstruct', 'rkssystem', 'schooling', 'shieldsdown', 'stancechange', 'terashift', 'zenmode',
				'zerotohero', 'asone', 'battlebond', 'comatose', 'disguise', 'gulpmissle', 'iceface', 'multitype'}
			local sortedActive = self:getAllActive()
			self:sortByPriority(sortedActive)
			for _, pokemon in pairs(sortedActive) do
				if pokemon ~= source then
					if table.find(unaffected, pokemon.ability) then
						continue
					end
					if pokemon:hasItem('abilityshield') then
						continue
					end

					self:singleEvent('Start', pokemon:getAbility(), pokemon.abilityData, pokemon)
				end
			end
		end,
		num = 256,
		name = "Neutralizing Gas",
		id = "neutralizinggas",
		rating = 4
	},
	['pastelveil'] = {
		onStart = function(pokemon)
			for _, ally in pairs(pokemon.side.active) do
				if ally.status['psn'] or ally.status['tox'] then
					self:add('-activate', pokemon, 'ability: Pastel Veil')
					ally:cureStatus()
				end
			end
		end,
		onUpdate = function(pokemon)
			if pokemon.status['psn'] or pokemon.status['tox'] then
				self:add('-activate', pokemon, 'ability: Pastel Veil')
				pokemon:cureStatus()
			end
		end,
		onAllySwitchIn = function(pokemon)
			if pokemon.status['psn'] or pokemon.status['tox'] then
				self:add('-activate', self.effectData.target, 'ability: Pastel Veil')
				pokemon:cureStatus()
			end
		end,
		onSetStatus = function(status, target, source, effect)
			if not (status.id == 'psn' or status.id == 'tox') then return end
			return false
		end,
		onAllySetStatus = function(status, target, source, effect)
			if not (status.id == 'psn' or status.id == 'tox') then return end
			return false
		end,
		name = 'Pastel Veil',
		id = 'pastelveil',
		num = 257,
	},
	['hungerswitch'] = {
		onBeforeMovePriority = 11,
		onBeforeMove = function(pokemon, target, move)
			if pokemon.template.species ~= 'Morpeko' then return end
			if move.category == 'Physical' then
				if Not(pokemon.template.forme) and pokemon:formeChange('Morpeko-Hangry') then
					self:add('-formechange', pokemon, 'Morpeko-Hangry')
				end
			elseif move.id == 'aurawheel' then
				if pokemon.template.forme == 'Hangry' and pokemon:formeChange('Morpeko') then
					self:add('-formechange', pokemon, 'Morpeko')
				end
			end
		end,
		id = "hungerswitch",
		name = "Hunger Switch",
		rating = 1,
		num = 258
	},
	['unseenfist'] = {
		onModifyMove = function(move)
			if move.flags['contact'] then
				move.flags['protect'] = nil
			end
		end,
		id = "unseenfist",
		name = "Unseen Fist",
		rating = 2,
		num = 260
	},
	['curiousmedicine'] = {
		onStart = function(pokemon)
			for _, ally in pairs(pokemon.side.active) do
				if (ally ~= pokemon) then
					ally:clearBoosts()
					self:add('-clearboost', ally, '[from] ability: Curious Medicine', '[of] '..pokemon)
				end
			end
		end,
		name = "Curious Medicine",
		id = 'curiousmedicine',
		rating = 0,
		num = 261,
	},
	['transistor'] = {
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, attacker, defender, move)
			if (move.type == 'Electric') then
				return self:chainModify(1.5)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move) 
			if (move.type == 'Electric') then
				return self:chainModify(1.5)
			end
		end,
		name = "Transistor",
		id = 'transistor',
		rating = 3.5,
		num = 262,
	},
	['dragonsmaw'] = {
		onBasePower = function(basePower, attacker, defender, move)
			if move.type == 'Dragon' then
				self:debug('Dragon\'s Maw boost')
				return self:chainModify(1.75)
			end
		end,
		id = "dragonsmaw",
		name = "Dragon's Maw",
		rating = 3.5,
		num = 263
	},
	['chillingneigh'] = {
		onSourceFaint = function(target, source, effect)
			if (effect and effect.effectType == 'Move') then
				self:boost({atk = 1}, source)
			end
		end,
		name = "Chilling Neigh",
		id = 'chillingneigh',
		rating = 3,
		num =  264,
	},
	['grimneigh'] = {
		onSourceFaint = function(target, source, effect)
			if (effect and effect.effectType == 'Move') then
				self:boost({spa = 1}, source)
			end
		end,
		name = "Grim Neigh",
		id = 'grimneigh',
		rating = 3,
		num = 265,
	},
	['asone'] = {
		onBeforeSwitchIn = function(pokemon)
			self:add('-ability', pokemon, 'As One')
			self:add('-ability', pokemon, 'Unnerve', pokemon.side.foe)
		end,
		onFoeEatItem = function() return false end,
		onSourceFaint = function(target, source, effect)
			if (effect and effect.effectType == 'Move') then
				if source.template.forme == 'shadowrider' then
					self:boost({spa = 1}, source, source, self:getAbility('grimneigh'))
				else
					self:boost({atk = 1}, source, source, self:getAbility('chillingneigh'))
				end
			end
		end,
		name = "As One",
		id = 'asone',
		rating = 3.5,
		num = 266,
	},
	['waterbubble'] = {		
		onSourceModifyAtkPriority = 5,
		onSourceModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Fire' then
				self:debug('Water Bubble weaken')
				return self:chainModify(0.5)
			end
		end,
		onSourceModifySpAPriority = 5,
		onSourceModifySpA = function(atk, attacker, defender, move)
			if move.type == 'Fire' then
				self:debug('Water Bubble weaken')
				return self:chainModify(0.5)
			end
		end,
		onModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Water'then
				self:debug('Water Bubble boost')
				return self:chainModify(2)
			end
		end,
		onModifySpA = function(atk, attacker, defender, move)
			if move.type == 'Water'then
				self:debug('Water Bubble boost')
				return self:chainModify(2)
			end
		end,
		onUpdate = function(pokemon)
			if pokemon.status == 'brn' then
				pokemon:cureStatus()
			end
		end,
		onSetStatus = function(status, target, source, effect)
			if status.id == 'brn' then return false				
			end
		end,
		id = "waterbubble",
		name = "Water Bubble",
		rating = 4.5,
		num = 199
	},		

	['northpole'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Ice' then
				if not self:boost({spa = 1}) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		onAnyRedirectTargetPriority = 1,
		onAnyRedirectTarget = function(target, source, source2, move)
			if move.type ~= 'Ice' or ({firepledge=true, grasspledge=true, waterpledge=true})[move.id] then return end
			if self:validTarget(self.effectData.target, source, move.target) then
				return self.effectData.target
			end
		end,
		id = "northpole",
		name = "North Pole",
		rating = 3.5,
		num = 960
	},
	['angershell'] = {
		onDamage = function(damage, target, source, effect)
			if effect and effect.effectType == 'Move' and not effect.multihit and not (effect.negateSecondary and (effect.hasSheerForce and source:hasAbility('sheerforce'))) then
				self.effectData.checkedAngerShell = false
			else
				self.effectData.checkedAngerShell = true
			end
		end,
		onTryEatItem = function(item)
			local healingItems = {'aguavberry', 'enigmaberry', 'figyberry', 'iapapaberry', 'magoberry', 'sitrusberry', 'wikiberry', 'oranberry', 'berryjuice',}
			if healingItems[item.id] then
				return self.effectData.checkedAngerShell            
			end
			return true
		end,
		onAfterMoveSecondary = function(target,source,move)
			self.effectData.checkedAngerShell = true
			if (Not(source) or source == target or not target.hp or not move.totalDamage) then return end
			local lastAttackedBy = target:getLastAttackedBy()
			if (not lastAttackedBy) then return end
			local damage = move.multihit or move.totalDamage and lastAttackedBy.damage
			if (target.hp <= target.maxhp / 2 and target.hp + damage > target.maxhp / 2) then
				self:boost({atk = 1, spa = 1, spe = 1, def = -1, spd = -1})
			end
		end,
		id = "angershell",
		name = "Anger Shell",
		rating = 4,
		num = 271,
	},
	['beadsofruin'] = {
		onStart = function(pokemon)
			if self:suppressingAbility(pokemon) then return end
			self:add('-ability', pokemon, 'Beads of Ruin')
		end,
		onAnyModifySpD = function(spd, target, source, move)
			local abilityHolder = self.effectData.target
			if target:hasAbility("beadsofruin") then return end
			if not (move.ruinedDef and move.ruinedDef:hasAbility("beadsofruin")) then
				move.ruinedDef = abilityHolder
			end
			if move.ruinedDef ~= abilityHolder then return end
			self:debug("Beads of Ruin SpD Drop")
			return self:chainModify(0.75)
		end,
		id = "beadsofruin",
		name = "Beads of Ruin",
		rating = 4.5,
		num = 284,
	},
	['armortail'] = {
		onFoeTryMove = function(target, source, move)
			local targetAllExceptions = {'perishsong', 'flowershield', 'rototiller'}
			if (move.target == 'foeSide' or (move.target == 'all' and not targetAllExceptions:find(move.id))) then
				return
			end
			local armorholder = self.effectData.target
			if ((source.side == armorholder.side or move.target == 'all') and move.priority > 0.1) then
				self:attrLastMove('[still]')
				self:add('cant', armorholder, 'ability: Armor Tail', move, '[of] '..target)
				return false
			end
		end,
		id = "armortail",
		name = "Armor Tail",
		rating = 2.5,
		num = 296,
	},
	['commander'] = {
		onUpdate = function(pokemon)
			if self.gameType ~= 'doubles' then return end
			local ally = pokemon:allies()[1]
			if not (ally or pokemon.baseSpecies == 'Tatsugiri' or ally.baseSpecies == 'Dondozo') then
				if pokemon:getVolatile('commanding') then
					pokemon:removeVolatile('commanding')
					return 
				end
				if not pokemon:getVolatile('commanding') then
					-- If Dondozo was already commanded this fails
					if ally:getVolatile('commanded') then return end
					-- Tatsugiri can't move
					self:cancelDecision(pokemon)
					-- Add the volatiles
					self:add('-activate', pokemon, "ability: Commander", "[of] " .. ally)
					pokemon:addVolatile('commanding')
					ally:addVolatile('commanded', pokemon)
					-- BattleData.Statuses has the other volatile data
				else
					if not ally.fainted then return end
					pokemon:removeVolatile('commanding')
				end
			end
		end,
		id = "commander",
		name = "Commander",
		rating = 0,
		num = 279,
	},
	['costar'] = {
		onStart = function(pokemon)
			local ally = pokemon:allies()[1]
			if Not(ally) then return end
			local boosts = ally.boosts
			for i, b in pairs(boosts) do
				pokemon.boosts[i] = boosts[i]	
			end

			local volatilesToCopy = {'focusenergy', 'gmaxchistrike', 'laserfocus', "dragoncheer"}
			for i, volatile in ipairs(volatilesToCopy) do
				pokemon:removeVolatile(volatile)
			end
			for i, volatile in ipairs(volatilesToCopy) do
				if (ally.volatiles[volatile]) then
					pokemon:addVolatile(volatile)
					if (volatile == 'gmaxchistrike') then
						pokemon.volatiles[volatile].layers = ally.volatiles[volatile].layers
					end
					if (volatile == 'dragoncheer') then
						pokemon.volatiles[volatile].hasDragonType = ally.volatiles[volatile].hasDragonType
					end
				end
			end
			self:add('-copyboost', pokemon,ally, '[from] ability = Costar')
		end,
		id = "costar",
		name = "Costar",
		rating = 0,
		num = 294
	},
	['zerotohero'] = {
		onSwitchOut = function(pokemon)
			if pokemon.template.species == 'Palafin' and not pokemon.side.heroActivated and pokemon.hp > 0 and not pokemon.transformed and pokemon.side.pokemonLeft > 0 then
				self:add('-activate', pokemon, 'ability: Zero to Hero')
				local template = self:getTemplate('Palafin-Hero')
				pokemon:formeChange(template)
				pokemon.baseTemplate = template
				pokemon.details = template.species .. ', L' .. pokemon.level .. (pokemon.gender == '' and '' or ', ') .. pokemon.gender .. (pokemon.set.shiny and ', shiny' or '')
				self:add('detailschange', pokemon, pokemon.details, '[zeroToHero]', '[icon] ' .. (template.icon or 0))
				local shinyPrefix = pokemon.shiny and '_SHINY' or ''
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix .. '_FRONT/Palafin-Hero')
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix .. '_BACK/Palafin-Hero')

				pokemon.iconOverride = template.icon - 1
				-- is there a better way to access this?
				pokemon.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix .. '_FRONT']['Palafin-Hero']
				pokemon.baseStatOverride = template.baseStats

				pokemon.side.heroActivated = true
			end
		end,
		id = "zerotohero",
		name = "Zero to Hero",
		rating = 5,
		num = 278,
	},
	['guarddog'] = {
		onDragOut = function(pokemon)
			self:add('-activate', pokemon, 'ability: Guard Dog')
			return null
		end,
		onBoost = function(boost, target, source, effect)
			if effect.name == "Intimidate" and boost.atk and boost.atk < 0 then
				boost.atk = 0
				self:boost({atk = 1}, target, target, nil, false, true)
			end
		end,
		id = "guarddog",
		name = "Guard Dog",
		rating = 2,
		num = 275,
	},
	['windrider'] = {
		onStart = function(pokemon)
			if (pokemon.side.sideConditions['tailwind']) then
				self:boost({atk = 1}, pokemon, pokemon)
			end
		end,
		onTryHit = function(target, source, move)
			if (target ~= source and move.flags['wind']) then
				if Not(self:boost({atk = 1}, target, target)) then
					self:add('-immune', target, '[from] ability = Wind Rider')
				end
				return null
			end
		end,
		onAllySideConditionStart = function(target,source,sideCondition)
			local pokemon = self.effectData.target
			if (sideCondition.id == 'tailwind') then
				self:boost({atk = 1}, pokemon, pokemon)
			end
		end,
		id = "windrider",
		name = "Wind Rider",
		rating = 3.5,
		num = 274,
	},
	['windpower'] = {
		onAfterDamage = function(damage, target, source, move) 
			if (move.flags['wind']) then
				target:addVolatile('charge')
			end
		end,
		onAllySideConditionStart = function(target, source, sideCondition)
			local pokemon = self.effectData.target
			if (sideCondition.id == 'tailwind') then
				pokemon:addVolatile('charge')
			end
		end,
		id = "windpower",
		name = "Wind Power",
		rating = 1,
		num = 277,
	},
	['wellbakedbody'] = {
		onTryHit = function(target, source, move)
			if (target ~= source and move.type == 'Fire') then
				if (not self:boost({def = 2})) then
					self:add('-immune', target, '[from] ability = Well-Baked Body')
				end
				return null
			end
		end,
		id = "wellbakedbody",
		name = "Well-Baked Body",
		rating = 3.5,
		num = 273,
	},
	['vesselofruin'] = {
		onStart = function(pokemon)
			if self:suppressingAbility(pokemon) then return end
			self:add('-ability', pokemon, 'Vessel of Ruin')
		end,
		onAnyModifySpA = function(spa, target, source, move)
			local abilityHolder = self.effectData.target
			if target:hasAbility("vesselofruin") then return end
			if not (move.ruinedDef and move.ruinedDef:hasAbility("vesselofruin")) then
				move.ruinedDef = abilityHolder
			end
			if move.ruinedDef ~= abilityHolder then return end
			self:debug("Vessel of Ruin SpA Drop")
			return self:chainModify(0.75)
		end,
		id = "vesselofruin",
		name = "Vessel Of Ruin",
		rating = 4.5,
		num = 284,
	},
	['toxicdebris'] = {
		onAfterDamage = function(damage, target, source, move)
			if Not(source) or source == target then return end
			local attackerSide = source.side
			if target.side == source.side then
				attackerSide = source.side.foe
			end
			local toxspikes = attackerSide.sideConditions["toxicspikes"]
			if (move.category == 'Physical') then
				self:add('-activate', target, 'ability: Toxic Debris')
				self:addMove("-anim", target, "Toxic Spikes", source)
				attackerSide:addSideCondition("toxicspikes", target)
			end
		end,
		id = "toxicdebris",
		name = "Toxic Debris",
		rating = 3.5,
		num = 295,
	},
	['eartheater'] = {
		onTryHit = function(target, source, move)
			if target ~= source and move.type == 'Ground' then
				if Not(self:heal(target.maxhp / 4)) then
					self:add('-immune', target, '[msg]')
				end
				return null
			end
		end,
		id = "eartheater",
		name = "Earth Eater",
		rating = 3.5,
		num = 297,
	},
	['thermalexchange'] = {
		onAfterDamage = function(damage, target, source, move)
			if (move.type == 'Fire') then
				print('Thermal Exchange Boost')
				self:boost({atk = 1})
			end
		end,
		onUpdate = function(pokemon)
			if pokemon.status == 'brn' then
				pokemon:cureStatus()
			end
		end,
		onImmunity = function(type)
			if type == 'brn' then return false end
		end,
		id = "thermalexchange",
		name = "Thermal Exchange",
		rating = 2.5,
		num = 270,
	},
	['tabletsofruin'] = {
		onStart = function(pokemon)
			if self:suppressingAbility(pokemon) then return end
			self:add('-ability', pokemon, 'Tablets of Ruin')
		end,
		onAnyModifyAtk = function(atk, target, source, move)
			local abilityHolder = self.effectData.target
			if target:hasAbility("tabletsofruin") then return end
			if not (move.ruinedDef and move.ruinedDef:hasAbility("tabletsofruin")) then
				move.ruinedDef = abilityHolder
			end
			if move.ruinedDef ~= abilityHolder then return end
			self:debug("Tablets of Ruin Atk Drop")
			return self:chainModify(0.75)
		end,
		id = "tabletsofruin",
		name = "Tablets of Ruin",
		rating = 4.5,
		num = 284,
	},
	['supremeoverlord'] = {
		onStart = function(pokemon)
			local fallen = 0
			--print('Supreme Overlord onStart: totalFainted = ' .. tostring(pokemon.side.totalFainted))
			if pokemon.side.totalFainted > 0 then
				self:add('-activate', pokemon, 'ability: Supreme Overlord')
				fallen = math.min(pokemon.side.totalFainted, 5)
				self:add('-start', pokemon, fallen, '[silent]')
				pokemon.fallen = fallen
				--print('Supreme Overlord onStart: fallen = ' .. fallen)
			end
		end,
		onEnd = function(pokemon)
			if pokemon.fallen then
				self:add('-end', pokemon, pokemon.fallen, '[silent]')
			end
		end,
		onBasePowerPriority = 21,
		onBasePower = function(basePower, attacker, defender, move)
			if attacker.fallen then
				local powMod = {4506, 4915, 5325, 5734, 6144}
				return self:chainModify({powMod[attacker.fallen], 4096})
			end
		end,
		id = "supremeoverlord",
		name = "Supreme Overlord",
		rating = 3.5,
		num = 293,
	},
	['swordofruin'] = {
		onStart = function(pokemon)
			if self:suppressingAbility(pokemon) then return end
			self:add('-ability', pokemon, 'Sword of Ruin')
		end,
		onAnyModifyDef = function(def, target, source, move)
			local abilityHolder = self.effectData.target
			if target:hasAbility("swordofruin") then return end
			if not (move.ruinedDef and move.ruinedDef:hasAbility("swordofruin")) then
				move.ruinedDef = abilityHolder
			end
			if move.ruinedDef ~= abilityHolder then return end
			self:debug("Sword of Ruin Def Drop")
			return self:chainModify(0.75)
		end,
		id = "swordofruin",
		name = "Sword of Ruin",
		rating = 4.5,
		num = 285,
	},
	['seedsower'] = {
		onAfterDamage = function(damage, target, source, move)
			if source then
				self:setTerrain('grassyterrain')
			end
		end,
		id = "seedsower",
		name = "Seed Sower",
		rating = 2.5,
		num = 269,
	},
	['rockypayload'] = {
		onModifyAtkPriority = 5,
		onModifyAtk  = function(atk, attacker, defender, move)
			if (move.type == 'Rock') then
				self:debug('Rocky Payload Boost')
				return self:chainModify(1.5)
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(atk, attacker, defender, move)
			if (move.type == 'Rock') then
				self:debug('Rocky Payload Boost')
				return self:chainModify(1.5)
			end
		end,
		id = "rockypayload",
		name = "Rocky Payload",
		rating = 3.5,
		num = 276,
	},
	['purifyingsalt'] = {
		onSetStatus = function(status, target, source, effect)
			if effect and effect.status then
				self:add('-immune', target, '[from] ability: Purifying Salt')
			end
			return false
		end,
		onTryAddVolatile = function(status, target)
			if status.id == 'yawn' then
				self:add('-immune', target, '[from] ability: Purifying Salt')
				return nil
			end
		end,
		onSourceModifyAtkPriority = 6,
		onSourceModifyAtk = function(atk, attacker, defender, move)
			if move.type == 'Ghost' then
				print('Purifying Salt weaken')
				return self:chainModify(0.5)
			end
		end,
		onSourceModifySpAPriority = 5,
		onSourceModifySpA = function(spa, attacker, defender, move)
			if move.type == 'Ghost' then
				print('Purifying Salt weaken')
				return self:chainModify(0.5)
			end
		end,
		id = "purifyingsalt",
		name = "Purifying Salt",
		rating = 4,
		num = 272
	},
	['quarkdrive'] = {
		onStart = function(pokemon)
			self:singleEvent('TerrainChange', self.effect, self.effectData, pokemon)
		end,
		onTerrainChange = function(pokemon)
			if pokemon.transformed then return end
			if self:isTerrain('electricterrain') then
				pokemon:addVolatile('quarkdrive')
			elseif not pokemon.volatiles['quarkdrive'] or not pokemon.volatiles['quarkdrive'].fromBooster then
				pokemon:removeVolatile('quarkdrive')
			end
		end,
		onEnd = function(pokemon)
			pokemon.volatiles['quarkdrive'] = nil
			self:add('-end', pokemon, 'Quark Drive', '[silent]')
		end,
		effect = {
			noCopy = true,
			onStart = function(pokemon, source, effect)
				if effect and effect.id == 'boosterenergy' then
					self.effectData.fromBooster = true
					self:add('-activate', pokemon, 'ability: Quark Drive', '[fromitem]')
				else
					self:add('-activate', pokemon, 'ability: Quark Drive')
				end
				self.effectData.bestStat = pokemon:getBestStat(false, true)
				self:add('-start', pokemon, 'quarkdrive'..self.effectData.bestStat)
			end,
			onModifyAtkPriority = 5,
			onModifyAtk = function(atk, source, target, move)
				if  self.effectData.bestStat ~= 'atk' then return end
				print('Quark Drive atk boost')
				return self:chainModify(1.3)
			end,
			onModifyDefPriority = 6,
			onModifyDef = function(def, target, source, move)
				if  self.effectData.bestStat ~= 'def' then return end
				print('Quark Drive def boost')
				return self:chainModify(1.3)
			end,
			onModifySpAPriority = 5,
			onModifySpA = function(spa, source, target, move)
				if self.effectData.bestStat ~= 'spa' then return end
				print('Quark Drive spa boost')
				return self:chainModify(1.3)
			end,
			onModifySpDPriority = 6,
			onModifySpD = function(spd, target, source, move)
				if  self.effectData.bestStat ~= 'spd' then return end
				print('Quark Drive spd boost')
				return self:chainModify(1.3)
			end,
			onModifySpe = function(spe, target, source, move)
				if  self.effectData.bestStat ~= 'spe' then return end
				print('Quark Drive spe boost')
				return self:chainModify(1.5)
			end,
			onEnd = function(pokemon)
				self:add('-end', pokemon, 'quarkdrive'..self.effectData.bestStat, '[silent]')
			end,
		},
		id = "quarkdrive",
		name = "Quark Drive",
		rating = 4,
		num = 296,
	},
	['opportunist'] = {
		onFoeAfterBoost = function(boost, target, source, effect)
			if effect and (effect.name == "Opportunist" or effect.name == "Mirror Herb") then
				return
			end
			local pokemon = self.effectData.target
			local positiveBoosts = {}
			for i, b in pairs(boost) do
				if b > 0 then
					positiveBoosts[i] = b
				end
			end
			if Not(positiveBoosts) then
				return
			end
			self:boost(positiveBoosts, pokemon)
		end,
		id = "opportunist",
		name = "Opportunist",
		rating = 3,
		num = 290
	},
	['orichalcumpulse'] = {
		onStart = function(pokemon)
			if self:setWeather('sunnyday') then
				self:add('-activate', pokemon, "ability: Orichalcum Pulse", '[source]')
			elseif self:isWeather('sunnyday') then
				self:add('-activate', pokemon, "ability: Orichalcum Pulse")
			end
		end,
		onModifyAtkPriority = 5,
		onModifyAtk = function(atk, pokemon)
			if self:isWeather({'sunnyday', 'desolateland'}) then
				self:debug('Orichalcum boost')
				return self:chainModify({5461, 4096})
			end
		end,
		id = "orichalcumpulse",
		name = "Orichalcum Pulse",
		rating = 4.5,
		num = 288,
	},
	['protosynthesis'] = {
		onStart = function(pokemon)
			self:singleEvent('WeatherChange',  self.effect,  self.effectData, pokemon)
		end,
		onWeatherChange = function(pokemon)
			if pokemon.transformed then return end
			-- Protosynthesis is not affected by Utility Umbrella
			if self:isWeather({'sunnyday', 'desolateland'}) then
				pokemon:addVolatile('protosynthesis')
			elseif not pokemon.volatiles['protosynthesis'] or not pokemon.volatiles['protosynthesis'].fromBooster then
				pokemon:removeVolatile('protosynthesis')
			end
		end,
		onEnd = function(pokemon)
			pokemon.volatiles['protosynthesis'] = nil
			self:add('-end', pokemon, 'Protosynthesis', '[silent]')
		end,
		effect = {
			noCopy = true,
			onStart = function(pokemon, source, effect)
				if effect and effect.id == 'boosterenergy' then
					self.effectData.fromBooster = true
					self:add('-activate', pokemon, 'ability: Protosynthesis', '[fromitem]')
				else
					self:add('-activate', pokemon, 'ability: Protosynthesis')
				end
				self.effectData.bestStat = pokemon:getBestStat(false, true)
				self:add('-start', pokemon, 'protosynthesis', self.effectData.bestStat)
			end,
			onModifyAtkPriority = 5,
			onModifyAtk = function(atk, source, target, move)
				if  self.effectData.bestStat ~= 'atk' then return end
				print('Protosynthesis atk boost')
				return self:chainModify(1.3)
			end,
			onModifyDefPriority = 6,
			onModifyDef = function(def, target, source, move)
				if  self.effectData.bestStat ~= 'def' then return end
				print('Protosynthesis def boost')
				return self:chainModify(1.3)
			end,
			onModifySpAPriority = 5,
			onModifySpA = function(spa, source, target, move)
				if self.effectData.bestStat ~= 'spa' then return end
				print('Protosynthesis spa boost')
				return self:chainModify(1.3)
			end,
			onModifySpDPriority = 6,
			onModifySpD = function(spd, target, source, move)
				if  self.effectData.bestStat ~= 'spd' then return end
				print('Protosynthesis spd boost')
				return self:chainModify(1.3)
			end,
			onModifySpe = function(spe, target, source, move)
				if  self.effectData.bestStat ~= 'spe' then return end
				print('Protosynthesis spe boost')
				return self:chainModify(1.5)
			end,	
		},
		id = "protosynthesis",
		name = "Protosynthesis",
		rating = 3,
		num = 281,
	},
	['electromorphosis'] = {
		onAfterDamageOrder = 1,
		onAfterDamage = function(damage, target, source, move)
			if Not(source) or source == target then return end
			target:addVolatile('charge')
			self:add('-ability', target, 'Electromorphosis')
		end,
		id = "electromorphosis",
		name = "Electromorphosis",
		rating = 2,
		num = 280,
	},
	['myceliummight'] = {
		onModifyPriority = function(priority, pokemon, target, move)
			if (move.category == 'Status') then
				return priority - 0.1
			end
		end,
		onModifyMove = function(move)
			if (move.category == 'Status') then
				move.ignoreAbility = true
			end
		end,
		id = "myceliummight",
		name = "Mycelium Might",
		rating = 2,
		num = 298
	},
	['lingeringaroma'] = {
		onAfterDamage = function(damage, target, source, move)
			if source and source ~= target and move and move.flags['contact'] then
				local oldAbility = source:setAbility('lingeringaroma', source, 'lingeringaroma', true)
				if oldAbility then
					self:add('-activate', target, 'ability: Lingering Aroma', oldAbility, '[of] ' .. source)
				end
			end
		end,
		id = "lingeringaroma",
		name = "Lingering Aroma",
		rating = 2,
		num = 268,
	},
	['cudchew'] = {
		onEatItem = function(item, pokemon)
			if item.isBerry and not pokemon.volatiles['cudchew'] then
				pokemon:addVolatile('cudchew', pokemon)
				pokemon.volatiles['cudchew'].berry = item
			end
		end,
		onEnd = function(pokemon)
			if pokemon.volatiles['cudchew'] then
				pokemon:removeVolatile('cudchew')
			end
		end,
		effect = {
			duration = 2,
			onStart = function(self, pokemon)
				self:add('-start', pokemon, 'ability: Cud Chew')
			end,
			onResidualOrder = 28,
			onResidualSubOrder = 2,
			onEnd = function(self, pokemon)
				if pokemon.hp and pokemon.volatiles['cudchew'] then
					local item = pokemon.volatiles['cudchew'].berry
					self:add('-activate', pokemon, 'ability: Cud Chew')
					self:add('-enditem', pokemon, item.name, '[eat]')
					if self:singleEvent('Eat', item, nil, pokemon, nil, nil) then
						self:runEvent('EatItem', pokemon, nil, nil, item)
					end
					if item.onEat then
						pokemon.ateBerry = true
					end
				end
			end,
		},
		name = "Cud Chew",
		id = "cudchew",
		rating = 2,
		num = 291,
	},
	['hadronengine'] = {
		onStart = function(pokemon)
			if not self:setTerrain("electricterrain") and self:isTerrain("electricterrain") then
				self:add('-activate', pokemon, "ability: Hadron Engine")
			end
		end,
		onModifySpAPriority = 5,
		onModifySpA = function(spa, pokemon, target, move)
			if self:isTerrain("electricterrain") then
				self:debug('Hadron Engine boost')
				return self:chainModify({5461, 4096})
			end
		end,
		id = "hadronengine",
		name = "Hadron Engine",
		rating = 4.5,
		num = 289,
	},
	['goodasgold'] = {
		onTryHit = function(target, source, move)
			if (move.category == 'Status' and target ~= source) then
				self:add('-immune', target, '[from] ability = Good as Gold')
				return null
			end
		end,
		id = "goodasgold",
		name = "Good as Gold",
		rating = 5,
		num = 283
	},
	['mindseye'] = {
		onBoost = function(boost, target, source, effect)
			if source and target == source then return end
			if boost['accuracy'] and boost['accuracy'] < 0 then
				boost['accuracy'] = 0
				if not effect.secondaries then
					self:add("-fail", target, "unboost", "accuracy", "[from] ability = Mind's Eye", "[of] " .. target)
				end
			end
		end,
		onModifyMovePriority = -5,
		onModifyMove = function(move)
			if not move.ignoreImmunity then move.ignoreImmunity = {} end
			if move.ignoreImmunity ~= true then
				move.ignoreImmunity['Fighting'] = true
				move.ignoreImmunity['Normal'] = true
			end
		end,
		id = "mindseye",
		name = "Mind's Eye",
		rating = 1,
		num = 292
	},
	['embodyaspect'] = {
		onStart = function(pokemon)
			if pokemon.baseSpecies ~= 'Ogerpon' or pokemon.embodied then return end
			local forme = pokemon.template.forme or "Teal"
			local formeTable = {
				["Hearthflame"] = {atk = 1},
				["Cornerstone"] = {def = 1},
				["Wellspring"] = {spd = 1},
				["Teal"] = {spe = 1},
			}
			pokemon.embodied = true
			self:boost(formeTable[forme], pokemon)
		end,
		id = "embodyaspect",
		name = "Embody Aspect",
		rating = 3.5,
		num = 303
	},
	['toxicchain'] = {
		onModifyMove = function(move)
			if not move then return end
			if not move.secondaries then
				move.secondaries = {}
			end
			table.insert(move.secondaries, {
				chance = 30,
				status = 'tox'
			})
		end,
		id = "toxicchain",
		name = "Toxic Chain",
		rating = 4.5,
		num = 304
	},
	['terashift'] = {
		onSwitchIn = function(pokemon)
			if pokemon.template.species ~= 'Terapagos' then return end
			if pokemon.template.forme ~= 'Terastal' then
				self:add('-activate', pokemon, 'ability: Tera Shift')
				local template = self:getTemplate('Terapagos-Terastal')
				pokemon:formeChange('Terapagos-Terastal')
				pokemon.baseTemplate = template

				pokemon.details = template.species .. ', L' .. pokemon.level .. (pokemon.gender == '' and '' or ', ') .. pokemon.gender .. (pokemon.set.shiny and ', shiny' or '')
				self:add('detailschange', pokemon, pokemon.details, '[teraShift]', '[icon] '..(template.icon or 0))
				local shinyPrefix = pokemon.shiny and '_SHINY' or ''
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Terapagos-Terastal')
				self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Terapagos-Terastal')

				pokemon.iconOverride = template.icon-1
				-- is there a better way to access this?
				pokemon.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Terapagos-Terastal']
				pokemon.baseStatOverride = template.baseStats

				pokemon.baseMaxhp = math.floor(math.floor(2*pokemon.template.baseStats[1] + pokemon.set.ivs[1] + math.floor(pokemon.set.evs[1]/4) + 100) * pokemon.level/100+10) -- 1 = hp
				local newMaxHp = pokemon.baseMaxhp
				pokemon.hp = newMaxHp - (pokemon.maxhp - pokemon.hp)
				pokemon.maxhp = newMaxHp
				self:heal(pokemon.hp)
			end
		end,
		id = "terashift",
		name = "Tera Shift",
		rating = 3,
		num = 305
	},
	['terashell'] = {
		onEffectiveness = function(typeMod, target, type, move)
			if Not(target) or target.template.species ~= 'Terapagos' or target.template.forme ~= 'Terastal' then return end
			if self.effectData.resisted then return -1 end
			if move.category == 'Status' or move.id == 'struggle' then return end
			if Not(target:runImmunity(move.type)) then return end
			if target.hp < target.maxhp then return end

			self:add('-activate', target, 'ability: Tera Shell')
			self.effectData.resisted = true
			return -1
		end,
		id = "terashell",
		name = "Tera Shell",
		rating = 3.5,
		num = 306
	},
	['teraformzero'] = {
		onStart = function(pokemon)
			if pokemon.template.species ~= 'Terapagos' and pokemon.template.forme ~= 'Stellar' then
				return
			end
			if not (Not(self.weather) or Not(self.terrain)) then
				self:add('-ability', pokemon, 'ability: Teraform Zero')
				self:clearWeather()
				self:clearTerrain()
			end
		end,
		id = "teraformzero",
		name = "Terafrom Zero",
		rating = 4.5,
		num = 307
	},
	['fusioncore'] = {
		onStart = function(source)
			self:setWeather('hail')
			if self:bossDifficulty() == 'Hard' then
				if source.template.species == "Kyurem" then
					source.maxhp = 2000
					source.hp = 2000
				end
			elseif self:bossDifficulty() == 'Easy' then
				if source.template.species == "Kyurem" then
					source.maxhp = 1500
					source.hp = 1500
				end
			end
		end,
		onResidualOrder = 5,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			--	self:debug('fusioncore')
			pokemon:cureStatus()
		end,
		onFoeTryMove = function(target, source, move)
			local blockedMoves = {
				destinybond = true,
				endeavor = true,
				curse = true,
				painsplit = true,
				perishsong = true,
				transform = true,
				skillswap = true,
				powersplit = true,
				powertrick = true,
				superfang = true,
				ruination = true,
				naturesmadness = true,
				gastroacid = true,
				powerswap = true,
				trick = true,
				switcheroo = true,
				doodle = true,
				guillotine = true,
				sheercold = true,
				fissure = true,
				roleplay = true,
				simplebeam = true,
				worryseed = true,
				grudge = true,
				nightmare = true,
				entrainment = true
			}

			if self:bossDifficulty() == 'Hard' then
				blockedMoves.saltcure = true
				blockedMoves.leechseed = true
				blockedMoves.whirlpool = true
				blockedMoves.wrap = true
				blockedMoves.magmastorm = true
				blockedMoves.firespin = true
				blockedMoves.infestation = true
				blockedMoves.sandtomb = true
				blockedMoves.thundercage = true
				blockedMoves.bind = true
				blockedMoves.snaptrap = true
			end

			if blockedMoves[move.id] then
				--	target.lastMove('[still]')
				self:attrLastMove('[still]')
				return false
			end
		end,
		onBeforeMove = function(source, target, move)
			if self:bossDifficulty() == 'Hard' then
				if move and move.id == 'fusionflare' and source.template.species ~= "Kyurem-White" then
					self:add('-activate', source, 'ability: Fusion Core')
					local template = self:getTemplate('Kyurem-White')
					source:formeChange(template)
					source.baseTemplate = template
					source.details = template.species .. ', L' .. source.level .. (source.gender == '' and '' or ', ') .. source.gender .. (source.set.shiny and ', shiny' or '')
					self:add('detailschange', source, source.details, '[fusionCoreW]', '[icon] '..(template.icon or 0))
					local shinyPrefix = source.shiny and '_SHINY' or ''
					self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Kyurem-White')
					self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Kyurem-White')

					source.iconOverride = template.icon-1
					source.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Kyurem-White']
					source.baseStatOverride = template.baseStats

					-- copy pasta
					self:boost({ spa = 1 }, source)
				elseif move and move.id == 'fusionbolt' and source.template.species ~= "Kyurem-Black"  then 
					self:add('-activate', source, 'ability: Fusion Core')
					local template = self:getTemplate('Kyurem-Black')
					source:formeChange(template)
					source.baseTemplate = template
					source.details = template.species .. ', L' .. source.level .. (source.gender == '' and '' or ', ') .. source.gender .. (source.set.shiny and ', shiny' or '')
					self:add('detailschange', source, source.details, '[fusionCoreB]', '[icon] '..(template.icon or 0))
					local shinyPrefix = source.shiny and '_SHINY' or ''
					self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_FRONT/Kyurem-Black')
					self:setupDataForTransferToPlayers('Sprite', shinyPrefix..'_BACK/Kyurem-Black')

					source.iconOverride = template.icon-1
					source.frontSpriteOverride = require(game:GetService('ServerStorage').Data.GifData)[shinyPrefix..'_FRONT']['Kyurem-Black']
					source.baseStatOverride = template.baseStats

					self:boost({ atk = 1 }, source)
				end
			else
				return
			end
		end,
		onModifyAtk = function(atk, attacker, defender, move)
			if self:bossDifficulty() == 'Easy' then
				if (move.id == 'fusionbolt') then
					return self:chainModify(1.5)
				end
			end

		end,
		onModifySpA = function(atk, attacker, defender, move)
			if self:bossDifficulty() == 'Easy' then
				if (move.id == 'fusionflare') then
					return self:chainModify(1.5)
				end
			end
		end,
		stopAttackEvents = true,
		id = "fusioncore",
		name = "Fusion Core",
		rating = 5,
		num = 500,
	},
	-- Dialga
	['timedeity'] = {
		onStart = function(source)
			if self:bossDifficulty() == 'Hard' then
				if source.template.species == "Dialga" then
					source.maxhp = 2000
					source.hp = 2000
				end
			elseif self:bossDifficulty() == 'Easy' then
				if source.template.species == "Dialga" then
					source.maxhp = 1500
					source.hp = 1500
				end
			end
		end,
		onResidualOrder = 5,
		onResidualSubOrder = 1,
		onResidual = function(pokemon)
			pokemon:cureStatus()
		end,
		onFoeTryMove = function(target, source, move)
			local blockedMoves = {
				destinybond = true,
				endeavor = true,
				curse = true,
				painsplit = true,
				perishsong = true,
				transform = true,
				skillswap = true,
				powersplit = true,
				powertrick = true,
				superfang = true,
				ruination = true,
				naturesmadness = true,
				gastroacid = true,
				powerswap = true,
				trick = true,
				switcheroo = true,
				doodle = true,
				guillotine = true,
				sheercold = true,
				fissure = true,
				roleplay = true,
				simplebeam = true,
				worryseed = true,
				grudge = true,
				nightmare = true,
				entrainment = true
			}

			if self:bossDifficulty() == 'Hard' then
				blockedMoves.saltcure = true
				blockedMoves.leechseed = true
				blockedMoves.whirlpool = true
				blockedMoves.wrap = true
				blockedMoves.magmastorm = true
				blockedMoves.firespin = true
				blockedMoves.infestation = true
				blockedMoves.sandtomb = true
				blockedMoves.thundercage = true
				blockedMoves.bind = true
				blockedMoves.snaptrap = true
			end

			if blockedMoves[move.id] then
				--	target.lastMove('[still]')
				self:attrLastMove('[still]')
				return false
			end
		end,
		onModifyPriority = function(priority, pokemon, target, move)
			return priority + 6
		end,
		id = "timedeity",
		name = "Time Deity",
		rating = 5,
		num = 501
	}
}