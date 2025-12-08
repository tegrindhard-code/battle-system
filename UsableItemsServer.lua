local _f = require(script.Parent) -- will be SFramework at run-time (see SDriver)

-- todo: many items affect a pokemon's happiness
--       make sure to script this change when adding those items to this list

local usableItems = {
	['ppup'] = {
		chooseMove = true,
		canUse = function(pokemon)
			return not pokemon.egg
		end,

		onUse = function(pokemon, index)
			if pokemon.moves[index].ppup >= 3 then
				return                
			else
				pokemon.moves[index].ppup += 1
				return  --pokemon.moves[index].name .. " increased its PP with the PP Up!"                
			end
		end,
	},
	['ppmax'] = {
		chooseMove = true,
		canUse = function(pokemon)
			return not pokemon.egg
		end,

		onUse = function(pokemon, index)
			if pokemon.moves[index].ppup >= 3 then
				return                
			else
				pokemon.moves[index].ppup = 3
				return  --pokemon.moves[index].name .. " increased its PP with the PP Up!"                
			end
		end,
	},
	['moomoomilk'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(100, pokemon, pokemon, {id = 'moomoomilk', effectType = 'Item'}, true)
			else
				local initialHp = pokemon.hp
				pokemon.hp = math.min(pokemon.maxhp, pokemon.hp + 100)
				return pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points!'
			end
		end,
	},
	prisonbottle = {
		nonConsumable = true,
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.num == 720 and pokemon.forme == nil and pokemon.status ~= 'frz'
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			if pokemon.num == 720 and pokemon.forme == nil then
				pokemon.forme = 'Confined'
				pokemon.data = _f.Database.PokemonById.hoopa
				return pokemon:getName() .. ' changed form!'
			elseif pokemon.num == 720 and pokemon.forme == 'Confined' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.hoopaunbound
				return pokemon:getName() .. ' changed form!'	
			end
		end
	},
	['revealglass'] = {
		nonConsumable = true,
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.status ~= 'frz' and pokemon.num == 641 or pokemon.num == 642 or pokemon.num == 645 
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			if pokemon.num == 641 and pokemon.forme == nil then
				pokemon.forme = 'Therian'
				pokemon.data = _f.Database.PokemonById.tornadustherian
				return pokemon:getName() .. ' changed form!'
			elseif pokemon.num == 642 and pokemon.forme == nil then
				pokemon.forme = 'Therian'
				pokemon.data = _f.Database.PokemonById.thundurustherian
				return pokemon:getName() .. ' changed form!'
			elseif pokemon.num == 645 and pokemon.forme == nil then
				pokemon.forme = 'Therian'
				pokemon.data = _f.Database.PokemonById.landorustherian
				return pokemon:getName() .. ' changed form!'
			elseif pokemon.num == 641 and pokemon.forme == 'Therian' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.tornadus
				return pokemon:getName() .. ' changed form!'	
			elseif pokemon.num == 642 and pokemon.forme == 'Therian' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.thundurus
				return pokemon:getName() .. ' changed form!'
			elseif pokemon.num == 645 and pokemon.forme == 'Therian' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.landorus
			end
		end
	},
	['griseousorb']  = {
		nonConsumable = true,
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.status ~= 'frz'  and pokemon.num == 487
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			if pokemon.num == 487 and pokemon.forme == nil then
				pokemon.forme = 'Origin'
				pokemon.data = _f.Database.PokemonById.giratinaorigin
				return pokemon:getName() .. ' changed into its Origin form!'
			elseif pokemon.num == 487 and pokemon.forme == 'Origin' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.giratina
				return pokemon:getName() .. ' changed into its base form!'
			end
		end
	},
	['adamantorb'] = {
		nonConsumable = true,
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.status ~= 'frz'  and pokemon.num == 483
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			if pokemon.num == 483 and pokemon.forme == nil then
				pokemon.forme = 'Origin'
				pokemon.data = _f.Database.PokemonById.dialgaorigin
				return pokemon:getName() .. ' changed into its Origin form!'
			elseif pokemon.num == 483 and pokemon.forme == 'Origin' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.dialga
				return pokemon:getName() .. ' changed into its base form!'
			end
		end
	},
	['lustrousorb'] = {
		nonConsumable = true,
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.status ~= 'frz'  and pokemon.num == 484
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			if pokemon.num == 484 and pokemon.forme == nil then
				pokemon.forme = 'Origin'
				pokemon.data = _f.Database.PokemonById.palkiaorigin
				return pokemon:getName() .. ' changed into its Origin form!'
			elseif pokemon.num == 484 and pokemon.forme == 'Origin' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.palkia
				return pokemon:getName() .. ' changed into its base form!'
			end
		end
	},
	['blackorb']  = {
		nonConsumable = true,
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.status ~= 'frz'  and pokemon.num == 646
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			if pokemon.num == 646 and pokemon.forme == nil then
				pokemon.forme = 'Blackoverdrive'
				pokemon.data = _f.Database.PokemonById.kyuremblack
				return pokemon:getName() .. ' changed into Kyurem Black form!'
			elseif pokemon.num == 646 and pokemon.forme == 'Blackoverdrive' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.kyurem
				return pokemon:getName() .. ' changed into Kyurem!'
			elseif pokemon.num == 646 and pokemon.forme == 'Whiteoverdrive' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.kyurem
				return pokemon:getName() .. ' changed into Kyurem!'
			end
		end
	},
	['whiteorb']  = {
		nonConsumable = true,
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.status ~= 'frz'  and pokemon.num == 646
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			if pokemon.num == 646 and pokemon.forme == nil then
				pokemon.forme = 'Whiteoverdrive'
				pokemon.data = _f.Database.PokemonById.kyuremwhite
				return pokemon:getName() .. ' changed into Kyurem White form!'
			elseif pokemon.num == 646 and pokemon.forme == 'Whiteoverdrive' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.kyurem
				return pokemon:getName() .. ' changed into Kyurem!'
			elseif pokemon.num == 646 and pokemon.forme == 'Blackoverdrive' then
				pokemon.forme = nil
				pokemon.data = _f.Database.PokemonById.kyurem
				return pokemon:getName() .. ' changed into Kyurem!'
			end

		end
	},

	-- Mints
	jollymint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 14
			return pokemon:getName() .. ' changed its nature to Jolly!'
		end
	},

	lonelymint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 2
			return pokemon:getName() .. ' changed its nature to Lonely!'
		end
	},

	bravemint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 3
			return pokemon:getName() .. ' changed its nature to Brave!'
		end
	},

	adamantmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 4
			return pokemon:getName() .. ' changed its nature to Adamant!'
		end
	},

	naughtymint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 5
			return pokemon:getName() .. ' changed its nature to Naughty!'
		end
	},

	boldmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 6
			return pokemon:getName() .. ' changed its nature to Bold!'
		end
	},

	relaxedmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 8
			return pokemon:getName() .. ' changed its nature to Relaxed!'
		end
	},
	impishmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 9
			return pokemon:getName() .. ' changed its nature to Impish!'
		end
	},

	laxmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 10
			return pokemon:getName() .. ' changed its nature to Lax!'
		end
	},

	timidmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 11
			return pokemon:getName() .. ' changed its nature to Timid!'
		end
	},

	hastymint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 12
			return pokemon:getName() .. ' changed its nature to Hasty!'
		end
	},

	seriousmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 13
			return pokemon:getName() .. ' changed its nature to Serious!'
		end
	},

	naivemint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 15
			return pokemon:getName() .. ' changed its nature to Naive!'
		end
	},

	modestmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 16
			return pokemon:getName() .. ' changed its nature to Modest!'
		end
	},

	mildmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 17
			return pokemon:getName() .. ' changed its nature to Mild!'
		end
	},

	quietmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 18
			return pokemon:getName() .. ' changed its nature to Quiet!'
		end
	},

	rashmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 20
			return pokemon:getName() .. ' changed its nature to Rash!'
		end
	},

	calmmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 21
			return pokemon:getName() .. ' changed its nature to Calm!'
		end
	},

	gentlemint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 22
			return pokemon:getName() .. ' changed its nature to Gentle!'
		end
	},


	sassymint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 23
			return pokemon:getName() .. ' changed its nature to Sassy!'
		end
	},

	carefulmint = {

		canUse = function(pokemon)
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.nature = 24
			return pokemon:getName() .. ' changed its nature to Careful!'
		end
	},

	['abilitypatch'] = {
		canUse = function(pokemon)
			if not pokemon.data.hiddenAbility then return false end
			return not pokemon.egg
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.hiddenAbility = true
			pcall(function()
				if pokemon:isLead() then
					_f.Network:post('PDChanged', pokemon.PlayerData.player, 'firstNonEggAbility', pokemon:getAbilityName())
				end
			end)
			return pokemon:getName() .. '\'s Ability changed! Its Ability is now '..pokemon:getAbilityName()..'!'
		end,
	},
	gracidea = {
		nonConsumable = true,
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.num == 492 and pokemon.forme == nil and pokemon.status ~= 'frz'
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.forme = 'sky'
			pokemon.data = _f.Database.PokemonById.shayminsky
		end
	},

	['abilitycapsule'] = {
		canUse = function(pokemon)
			return not pokemon.egg and not pokemon.hiddenAbility and #pokemon.data.abilities > 1
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.swappedAbility = not pokemon.swappedAbility
			pcall(function()
				if pokemon:isLead() then
					_f.Network:post('PDChanged', pokemon.PlayerData.player, 'firstNonEggAbility', pokemon:getAbilityName())
				end
			end)
			return pokemon:getName() .. ' had its Ability swapped!'
		end,
	},
	['antidote'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and (pokemon.status == 'psn' or pokemon.status == 'tox')
		end,
		onUse = function(pokemon, battle)
			if battle then
				pokemon:cureStatus()
			else
				pokemon.status = nil
				return pokemon:getName() .. ' was cured of its poisoning!'
			end
		end,
	},
	['awakening'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.status and pokemon.status:sub(1, 3) == 'slp'
		end,
		onUse = function(pokemon, battle)
			if battle then
				pokemon:cureStatus()
			else
				pokemon.status = nil
				return pokemon:getName() .. ' woke up!'
			end
		end,
	},
	['burnheal'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.status == 'brn'
		end,
		onUse = function(pokemon, battle)
			if battle then
				pokemon:cureStatus()
			else
				pokemon.status = nil
				return pokemon:getName() .. '\'s burn was healed!'
			end
		end,
	},
	['expshare'] = {
		canUse = true,
		noTarget = true,
		nonConsumable = true,
		--		onUse = function() end
	},
	['freshwater'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(50, pokemon, pokemon, {id = 'freshwater', effectType = 'Item'}, true)
			else
				local initialHp = pokemon.hp
				pokemon.hp = math.min(pokemon.maxhp, pokemon.hp + 50)
				return pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points!'
			end
		end,
	},
	['fullrestore'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and
				(pokemon.hp < pokemon.maxhp or (pokemon.status and pokemon.status ~= '') or (pokemon.volatiles and pokemon.volatiles['confusion']))
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(pokemon.maxhp, pokemon, pokemon, {id = 'fullrestore', effectType = 'Item'}, true)
				pokemon:cureStatus()
				pokemon:removeVolatile('confusion')
			else
				local rstr = ''
				if pokemon.hp and pokemon.hp < pokemon.maxhp then
					local initialHp = pokemon.hp
					pokemon.hp = pokemon.maxhp
					rstr = pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points! '
				end
				local s = pokemon.status
				pokemon.status = nil
				if s and s ~= '' then
					rstr = rstr .. string.format(({
						brn = '%s\'s burn was healed!',
						frz = '%s thawed out!',
						par = '%s was cured of paralysis!',
						psn = '%s was cured of its poisoning!',
						tox = '%s was cured of its poisoning!',
						slp = '%s woke up!',
					})[s:sub(1, 3)] or '%s was cured!', pokemon:getName())
				end
				return rstr
			end
		end,
	},
	['fullheal'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and ((pokemon.status and pokemon.status ~= '') or (pokemon.volatiles and pokemon.volatiles['confusion']))
		end,
		onUse = function(pokemon, battle)
			if battle then
				pokemon:cureStatus()
				pokemon:removeVolatile('confusion')
			else
				local s = pokemon.status
				pokemon.status = nil
				return string.format(({
					brn = '%s\'s burn was healed!',
					frz = '%s thawed out!',
					par = '%s was cured of paralysis!',
					psn = '%s was cured of its poisoning!',
					tox = '%s was cured of its poisoning!',
					slp = '%s woke up!',
				})[s:sub(1, 3)] or '%s was cured!', pokemon:getName())
			end
		end,
	},
	['iceheal'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.status == 'frz'
		end,
		onUse = function(pokemon, battle)
			if battle then
				pokemon:cureStatus()
			else
				pokemon.status = nil
				return pokemon:getName() .. ' thawed out!'
			end
		end,
	},
	['paralyzeheal'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.status == 'par'
		end,
		onUse = function(pokemon, battle)
			if battle then
				pokemon:cureStatus()
			else
				pokemon.status = nil
				return pokemon:getName() .. ' was cured of paralysis!'
			end
		end,
	},
	['pclink'] = {
		canUse = true,
		noTarget = true,
		nonConsumable = true,
	},
	['hotchocolate'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(60, pokemon, pokemon, {id = 'hotchocolate', effectType = 'Item'}, true)
			else
				local initialHp = pokemon.hp
				pokemon.hp = math.min(pokemon.maxhp, pokemon.hp + 60)
				return pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points!'
			end
		end,
	},
	['ragecandybar'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(20, pokemon, pokemon, {id = 'ragecandybar', effectType = 'Item'}, true)
			else
				local initialHp = pokemon.hp
				pokemon.hp = math.min(pokemon.maxhp, pokemon.hp + 20)
				return pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points!'
			end
		end,
	},

	['potion'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(20, pokemon, pokemon, {id = 'potion', effectType = 'Item'}, true)
			else
				local initialHp = pokemon.hp
				pokemon.hp = math.min(pokemon.maxhp, pokemon.hp + 20)
				return pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points!'
			end
		end,
	},
	['superpotion'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(50, pokemon, pokemon, {id = 'superpotion', effectType = 'Item'}, true)
			else
				local initialHp = pokemon.hp
				pokemon.hp = math.min(pokemon.maxhp, pokemon.hp + 50)
				return pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points!'
			end
		end,
	},
	['hyperpotion'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(200, pokemon, pokemon, {id = 'hyperpotion', effectType = 'Item'}, true)
			else
				local initialHp = pokemon.hp
				pokemon.hp = math.min(pokemon.maxhp, pokemon.hp + 200)
				return pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points!'
			end
		end,
	},
	['maxpotion'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
		end,
		onUse = function(pokemon, battle)
			if battle then
				battle:heal(pokemon.maxhp, pokemon, pokemon, {id = 'maxpotion', effectType = 'Item'}, true)
			else
				local initialHp = pokemon.hp
				pokemon.hp = pokemon.maxhp
				return pokemon:getName() .. '\'s HP was restored by ' .. (pokemon.hp - initialHp) .. ' points!'
			end
		end,
	},

	['rarecandy'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.level < _f.levelCap
		end,
		onUse = function(poke, battle)
			if battle then return end
			local PlayerData = poke.PlayerData
			if not PlayerData then print('PlayerData not found when using Rare Candy') return end

			local hpMissing = poke.maxhp - poke.hp
			local level = poke.level + 1
			poke.level = level
			poke.experience = poke:getRequiredExperienceForLevel(level)
			poke:addHappiness(5, 4, 3)
			poke:calculateStats()
			poke.hp = poke.maxhp - hpMissing
			local learnedMoves = poke:generateDecisionsForMoves(poke:getMovesLearnedAtLevel(level))
			local evoData = poke:generateEvolutionDecision(1, _f.isDay())

			pcall(function()
				if poke:isLead() then
					_f.Network:post('PDChanged', PlayerData.player, 'firstNonEggLevel', level)
				end
			end)

			return {
				pokeName = poke:getName(),
				newLevel = level,
				moves = learnedMoves,
				known = (learnedMoves or (evoData and evoData.moves)) and poke:getCurrentMovesData() or nil,
				evo = evoData,
			}
		end,
	},
	['revive'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp <= 0
		end,
		onUse = function(pokemon, battle)
			if battle then
				pokemon.side.pokemonLeft = pokemon.side.pokemonLeft + 1
				pokemon.fainted = false
				pokemon.faintQueued = false
				pokemon.hp = 1
				pokemon.status = ''
				if pokemon.maxhp > 2 then
					battle:heal(math.ceil(pokemon.maxhp/2)-1, pokemon, pokemon, {id = 'revive', effectType = 'Item'}, true, '[silent]')
				end
				battle:add('-cometo', pokemon)
				--				if pokemon.statbar then
				--					pokemon.statbar:setHP(pokemon.hp, pokemon.maxhp)
				--				end
			else
				pokemon.hp = math.ceil(pokemon.maxhp/2)
				return pokemon:getName() .. ' recovered from fainting!'
			end
		end,
	},
	['maliciousarmor'] = {
		nonConsumable = true,
		canUse = function(pokemon)
			return 
		end,
	},
	['auspiciousarmor '] = {
		nonConsumable = true,
		canUse = function(pokemon)
			return
		end,
	}, 
	['metalalloy'] = {
		nonConsumable = true,
		canUse = function(pokemon)
			return
		end,
	},
	['blackaugurite'] = {
		nonConsumable = true,
		canUse = function(pokemon)
			return
		end,
	},
	['boosterenergy'] = {
		nonConsumable = true,
	},
	['leaderscrest'] = {
		nonConsumable = true,
		canUse = function(pokemon)
			return
		end,
	},
	['maxrevive'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.hp <= 0
		end,
		onUse = function(pokemon, battle)
			if battle then
				pokemon.side.pokemonLeft = pokemon.side.pokemonLeft + 1
				pokemon.fainted = false
				pokemon.faintQueued = false
				pokemon.hp = 1
				pokemon.status = ''
				if pokemon.maxhp > 1 then
					battle:heal(pokemon.maxhp-1, pokemon, pokemon, {id = 'maxrevive', effectType = 'Item'}, true, '[silent]')
				end
				battle:add('-cometo', pokemon)
				--				if pokemon.statbar then
				--					pokemon.statbar:setHP(pokemon.hp, pokemon.maxhp)
				--				end
			else
				pokemon.hp = pokemon.maxhp
				return pokemon:getName() .. ' recovered from fainting!'
			end
		end,
	},


	-- EV Resets
	['hpreset'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.evs[1] > 0
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.evs[1] = 0
			return pokemon:getName() .. '\'s effort was reset!'
		end,
	},
	['attackreset'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.evs[2] > 0
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.evs[2] = 0
			return pokemon:getName() .. '\'s effort was reset!'
		end,
	},
	['defensereset'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.evs[3] > 0
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.evs[3] = 0
			return pokemon:getName() .. '\'s effort was reset!'
		end,
	},
	['spatkreset'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.evs[4] > 0
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.evs[4] = 0
			return pokemon:getName() .. '\'s effort was reset!'
		end,
	},
	['spdefreset'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.evs[5] > 0
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.evs[5] = 0
			return pokemon:getName() .. '\'s effort was reset!'
		end,
	},
	['speedreset'] = {
		canUse = function(pokemon)
			return not pokemon.egg and pokemon.evs[6] > 0
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			pokemon.evs[6] = 0
			return pokemon:getName() .. '\'s effort was reset!'
		end,
	},
	['hpup'] = {
		canUse = function(pokemon)
			local totalEVs = 0
			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end
			return not pokemon.egg and pokemon.evs[1] < 252 and totalEVs < 510
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			local maxEVsPerStat = 252
			local maxTotalEVs = 510
			local evIncrease = 50
			local currentEVs = pokemon.evs[1]
			local totalEVs = 0

			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end

			if totalEVs >= maxTotalEVs then
				return pokemon:getName() .. ' cannot gain any more EVs!'
			end

			if currentEVs >= maxEVsPerStat then
				return pokemon:getName() .. '\'s EVs are already maxed out in this stat!'
			end

			if currentEVs + evIncrease > maxEVsPerStat then
				evIncrease = maxEVsPerStat - currentEVs
			end

			if totalEVs + evIncrease > maxTotalEVs then
				evIncrease = maxTotalEVs - totalEVs
			end

			pokemon.evs[1] = currentEVs + evIncrease
			return pokemon:getName() .. ' gained ' .. evIncrease .. ' EVs!'
		end,
	},
	['protein'] = {
		canUse = function(pokemon)
			local totalEVs = 0
			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end
			return not pokemon.egg and pokemon.evs[2] < 252 and totalEVs < 510
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			local maxEVsPerStat = 252
			local maxTotalEVs = 510
			local evIncrease = 50
			local currentEVs = pokemon.evs[2]
			local totalEVs = 0

			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end

			if totalEVs >= maxTotalEVs then
				return pokemon:getName() .. ' cannot gain any more EVs!'
			end

			if currentEVs >= maxEVsPerStat then
				return pokemon:getName() .. '\'s EVs are already maxed out in this stat!'
			end

			if currentEVs + evIncrease > maxEVsPerStat then
				evIncrease = maxEVsPerStat - currentEVs
			end

			if totalEVs + evIncrease > maxTotalEVs then
				evIncrease = maxTotalEVs - totalEVs
			end

			pokemon.evs[2] = currentEVs + evIncrease
			return pokemon:getName() .. ' gained ' .. evIncrease .. ' EVs!'
		end,
	},
	['iron'] = {
		canUse = function(pokemon)
			local totalEVs = 0
			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end
			return not pokemon.egg and pokemon.evs[3] < 252 and totalEVs < 510
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			local maxEVsPerStat = 252
			local maxTotalEVs = 510
			local evIncrease = 50
			local currentEVs = pokemon.evs[3]
			local totalEVs = 0

			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end

			if totalEVs >= maxTotalEVs then
				return pokemon:getName() .. ' cannot gain any more EVs!'
			end

			if currentEVs >= maxEVsPerStat then
				return pokemon:getName() .. '\'s EVs are already maxed out in this stat!'
			end

			if currentEVs + evIncrease > maxEVsPerStat then
				evIncrease = maxEVsPerStat - currentEVs
			end

			if totalEVs + evIncrease > maxTotalEVs then
				evIncrease = maxTotalEVs - totalEVs
			end

			pokemon.evs[3] = currentEVs + evIncrease
			return pokemon:getName() .. ' gained ' .. evIncrease .. ' EVs!'
		end,
	},
	['calcium'] = {
		canUse = function(pokemon)
			local totalEVs = 0
			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end
			return not pokemon.egg and pokemon.evs[4] < 252 and totalEVs < 510
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			local maxEVsPerStat = 252
			local maxTotalEVs = 510
			local evIncrease = 50
			local currentEVs = pokemon.evs[4]
			local totalEVs = 0

			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end

			if totalEVs >= maxTotalEVs then
				return pokemon:getName() .. ' cannot gain any more EVs!'
			end

			if currentEVs >= maxEVsPerStat then
				return pokemon:getName() .. '\'s EVs are already maxed out in this stat!'
			end

			if currentEVs + evIncrease > maxEVsPerStat then
				evIncrease = maxEVsPerStat - currentEVs
			end

			if totalEVs + evIncrease > maxTotalEVs then
				evIncrease = maxTotalEVs - totalEVs
			end

			pokemon.evs[4] = currentEVs + evIncrease
			return pokemon:getName() .. ' gained ' .. evIncrease .. ' EVs!'
		end,
	},
	['zinc'] = {
		canUse = function(pokemon)
			local totalEVs = 0
			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end
			return not pokemon.egg and pokemon.evs[5] < 252 and totalEVs < 510
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			local maxEVsPerStat = 252
			local maxTotalEVs = 510
			local evIncrease = 50
			local currentEVs = pokemon.evs[5]
			local totalEVs = 0

			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end

			if totalEVs >= maxTotalEVs then
				return pokemon:getName() .. ' cannot gain any more EVs!'
			end

			if currentEVs >= maxEVsPerStat then
				return pokemon:getName() .. '\'s EVs are already maxed out in this stat!'
			end

			if currentEVs + evIncrease > maxEVsPerStat then
				evIncrease = maxEVsPerStat - currentEVs
			end

			if totalEVs + evIncrease > maxTotalEVs then
				evIncrease = maxTotalEVs - totalEVs
			end

			pokemon.evs[5] = currentEVs + evIncrease
			return pokemon:getName() .. ' gained ' .. evIncrease .. ' EVs!'
		end,
	},
	['carbos'] = {
		canUse = function(pokemon)
			local totalEVs = 0
			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end
			return not pokemon.egg and pokemon.evs[6] < 252 and totalEVs < 510
		end,
		onUse = function(pokemon, battle)
			if battle then return end
			local maxEVsPerStat = 252
			local maxTotalEVs = 510
			local evIncrease = 50
			local currentEVs = pokemon.evs[6]
			local totalEVs = 0

			for i = 1, 6 do
				totalEVs = totalEVs + pokemon.evs[i]
			end

			if totalEVs >= maxTotalEVs then
				return pokemon:getName() .. ' cannot gain any more EVs!'
			end

			if currentEVs >= maxEVsPerStat then
				return pokemon:getName() .. '\'s EVs are already maxed out in this stat!'
			end

			if currentEVs + evIncrease > maxEVsPerStat then
				evIncrease = maxEVsPerStat - currentEVs
			end

			if totalEVs + evIncrease > maxTotalEVs then
				evIncrease = maxTotalEVs - totalEVs
			end

			pokemon.evs[6] = currentEVs + evIncrease
			return pokemon:getName() .. ' gained ' .. evIncrease .. ' EVs!'
		end,
	},
	-- Repels
	--	['repel'] = {
	--		canUse = true,
	--		noTarget = true,
	----		onUse = function() end
	--	},
	--	['superrepel'] = {
	--		canUse = true,
	--		noTarget = true,
	----		onUse = function() end
	--	},
	--	['maxrepel'] = {
	--		canUse = true,
	--		noTarget = true,
	----		onUse = function() end
	--	},
}

usableItems.cheriberry  = usableItems.paralyzeheal
usableItems.chestoberry = usableItems.awakening
usableItems.pechaberry  = usableItems.antidote
usableItems.rawstberry  = usableItems.burnheal
usableItems.aspearberry = usableItems.iceheal


for stone, num in pairs({
	sunstone     = 80,
	moonstone    = 81,
	firestone    = 82,
	thunderstone = 83,
	waterstone   = 84,
	leafstone    = 85,
	shinystone   = 107,
	duskstone    = 108,
	dawnstone    = 109,
	icestone     = 665,
	auspiciousarmor = 827,
	maliciousarmor = 800,
	leaderscrest = 821,
	metalalloy = 830,
	blackaugurite = 820,
	linkingcord = 834
	}) do
	usableItems[stone] = {
		canUse = function(pokemon)
			if pokemon.egg then return false end
			if stone ~= 'linkingcord' then
				return pokemon:getEligibleEvolution(3, _f.isDay(), num) ~= nil
			else
				return pokemon:getEligibleEvolution(2, _f.isDay(), nil, nil, true) ~= nil
			end
		end,
		onUse = function(poke, battle)
			if battle then return end
			local PlayerData = poke.PlayerData
			if not PlayerData then print('PlayerData not found when using [an evolution stone]') return end

			local evoData
			if stone ~= 'linkingcord' then
				evoData = poke:generateEvolutionDecision(3, _f.isDay(), num)
			else
				evoData = poke:generateEvolutionDecision(2, _f.isDay(), nil, nil, true)
			end
			if not evoData then return end
			evoData.cannotCancel = true

			return {
				pokeName = poke:getName(),
				known = (evoData and evoData.moves and poke:getCurrentMovesData()),
				evo = evoData,
			}
		end
	}
end

return usableItems