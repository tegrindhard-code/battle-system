return function(_p)

	local usableItems = {
		gracidea = {
			nonConsumable = true,
		},
		['griseousorb'] = {
			nonConsumable = true,
		},
		['adamantorb'] = {
			nonConsumable = true,
		},
		['lustrousorb'] = {
			nonConsumable = true,
		},
		blackorb = {
			nonConsumable = true,
		},
		whiteorb  = {
			nonConsumable = true,
		},
		['eonflute'] = {
			canUse = true, 
			noTarget = true, 
			nonConsumable = true, 
			onUse = function()
				if _p.Soaring.inSoaring then
					_p.NPCChat:say("You are already doing that...");
					return;
				end;
				_p.NPCChat:say("You used the Eon Flute!");
				_p.Menu.bag:close();
				spawn(function()
					_p.MusicManager:popMusic("all", 0.5);
				end);
				_p.Utilities.FadeOut(0.5);
				_p.Soaring:Anim(_p.DataManager.currentChunk.id);
			end
		};		
		['charizardsaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Charizard')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Charizard"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Charizard Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Charizard')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},

		['koraidonsaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Koraidon')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Koraidon"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Koraidon Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Koraidon')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['mewsaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Mew')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Mew"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Mew Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Mew')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['miraidonsaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Miraidon')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Miraidon"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Miraidon Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Miraidon')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['suicunesaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Suicune')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Suicune"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Suicune Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Suicune')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['landorustheriansaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Therian Landorus')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Therian Landorus"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Therian Landorus Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Therian Landorus')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['houndoomsaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Houndoom')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Houndoom"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Houndoom Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Houndoom')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['metagrosssaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Metagross')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Metagross"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Metagross Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Metagross')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['solgaleosaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Solgaleo')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Solgaleo"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Solgaleo Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Solgaleo')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['venusaursaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Venusaur')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Venusaur"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Venusaur Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Venusaur')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},
		['blastoisesaddle'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.MountPokemon.equippedSaddle
				local chat = _p.NPCChat
				if chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Blastoise')..' Saddle is currently '..(on and 'equipped.' or 'unequipped.'),
					'[y/n]Would you like to '..(on and 'unequip it?' or 'equip it?')) then

					if on then
						_p.MountPokemon.equippedSaddle = nil
					else
						_p.MountPokemon.equippedSaddle = "Blastoise"
					end
					chat:say('You '..(on and 'unequipped' or 'equipped')..' the Blastoise Saddle.')
				else
					chat:say('The '..(on and _p.MountPokemon.equippedSaddle or 'Blastoise')..' Saddle remained '..(on and 'Equipped.' or 'Unequipped.'))
				end
			end
		},

		--	abilitycapsule
		['antidote'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and (pokemon.status == 'psn' or pokemon.status == 'tox')
			end
		},
		['lavacookie'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and (pokemon.status == 'psn' or pokemon.status == 'tox' or pokemon.status == 'slp' or pokemon.status == 'par' or pokemon.status == 'brn')
			end
		},
		['awakening'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.status and pokemon.status:sub(1, 3) == 'slp'
			end
		},
		['burnheal'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.status == 'brn'
			end
		},
		['expshare'] = {
			canUse = true,
			noTarget = true,
			nonConsumable = true,
			onUse = function()
				local on = _p.PlayerData.expShareOn
				local chat = _p.NPCChat
				if chat:say('The Exp. Share is currently '..(on and 'on.' or 'off.'),
					'[y/n]Would you like to switch it '..(on and 'off?' or 'on?')) then
					_p.PlayerData.expShareOn = not on
					chat:say('You switched '..(on and 'off' or 'on')..' the Exp. Share.')
				else
					chat:say('The Exp. Share remained '..(on and 'on.' or 'off.'))
				end
			end
		},
		['freshwater'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
			end
		},
		['fullheal'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and ((pokemon.status and pokemon.status ~= '') or (pokemon.volatiles and pokemon.volatiles['confusion']))
			end
		},
		['fullrestore'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and
					(pokemon.hp < pokemon.maxhp or (pokemon.status and pokemon.status ~= '') or (pokemon.volatiles and pokemon.volatiles['confusion']))
			end
		},
		['iceheal'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.status == 'frz'
			end
		},
		['paralyzeheal'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.status == 'par'
			end
		},
		['hotchocolate'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
			end
		},
		['potion'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
			end,
			allowMultiple = true
		},
		['superpotion'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
			end,
			allowMultiple = true
		},
		['hyperpotion'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
			end,
			allowMultiple = true
		},
		['maxpotion'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
			end
		},

		['rarecandy'] = {
			onProcess = function(pokemon, data)
				_p.Utilities.sound(287531241, nil, nil, 5)
				if data.evo and data.evo.flip then
					data.evo.orientation0 = _p.Battle:sampleOrientation()
				end
				_p.NPCChat:say(data.pokeName .. ' grew to level ' .. data.newLevel .. '!')
				_p.Pokemon:processMovesAndEvolution(data, false)
			end,
			allowMultiple = true
		},
		['revive'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp <= 0
			end
		},
		['maxrevive'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp <= 0
			end
		},
		['ppup'] = {
			chooseMove = true,
			canUse = function(pokemon, moveIndex)
				local cannotUse = false
				if pokemon.moves[moveIndex].ppup >= 3 then cannotUse = true end
				return not pokemon.egg and not cannotUse
			end,
		},
		['ppmax'] = {
			chooseMove = true,
			canUse = function(pokemon, moveIndex)
				local cannotUse = false
				if pokemon.moves[moveIndex].ppup >= 3 then cannotUse = true end
				return not pokemon.egg and not cannotUse
			end,
		},
		['pclink'] = {
			noTarget = true,
			canUse = true,
			nonConsumable = true,
			onUse = function()
				spawn(function() _p.Menu:enable() end)	
				_p.Menu.bag:close()
				_p.Menu.pc:bootUp()
			end,
		},
		['moomoomilk'] = {
			canUse = function(pokemon)
				return not pokemon.egg and pokemon.hp > 0 and pokemon.hp < pokemon.maxhp
			end
		},

		['abilitypatch'] = {
			canUse = function(pokemon)
				if not pokemon.hashiddenAbility then return false end
				return not pokemon.egg and not pokemon.hiddenAbility
			end,
		},

		-- EV Resets
		--	hpreset
		--	attackreset
		--	defensereset
		--	spatkreset
		--	spdefreset
		--	speedreset

		-- Repels
		['repel'] = {
			canUse = true,
			noTarget = true,
			onUse = function()
				local chat = _p.NPCChat
				if _p.Repel.steps > 0 then
					chat:say('Another repellent\'s effects still linger.', 'You can\'t use this now.')
					return false
				end
				chat:say(_p.PlayerData.trainerName .. ' used the Repel.',
					'The likelihood of encountering wild pokemon decreased!')
				_p.Repel.steps = 100 * 2
				_p.Repel.kind = 1
			end
		},
		['superrepel'] = {
			canUse = true,
			noTarget = true,
			onUse = function()
				local chat = _p.NPCChat
				if _p.Repel.steps > 0 then
					chat:say('Another repellent\'s effects still linger.', 'You can\'t use this now.')
					return false
				end
				chat:say(_p.PlayerData.trainerName .. ' used the Super Repel.',
					'The likelihood of encountering wild pokemon decreased!')
				_p.Repel.steps = 200 * 2
				_p.Repel.kind = 2
			end
		},
		['maxrepel'] = {
			canUse = true,
			noTarget = true,
			onUse = function()
				local chat = _p.NPCChat
				if _p.Repel.steps > 0 then
					chat:say('Another repellent\'s effects still linger.', 'You can\'t use this now.')
					return false
				end
				chat:say(_p.PlayerData.trainerName .. ' used the Max Repel.',
					'The likelihood of encountering wild pokemon decreased!')
				_p.Repel.steps = 250 * 2
				_p.Repel.kind = 3
			end
		}
	}

	usableItems.cheriberry  = usableItems.paralyzeheal
	usableItems.chestoberry = usableItems.awakening
	usableItems.pechaberry  = usableItems.antidote
	usableItems.rawstberry  = usableItems.burnheal
	usableItems.aspearberry = usableItems.iceheal

	local stone = {
		onProcess = function(pokemon, data)
			_p.Pokemon:processMovesAndEvolution(data, false)
		end
	}
	usableItems.sunstone     	= stone
	usableItems.moonstone    	= stone
	usableItems.firestone    	= stone
	usableItems.thunderstone 	= stone
	usableItems.waterstone   	= stone
	usableItems.leafstone    	= stone
	usableItems.shinystone   	= stone
	usableItems.duskstone    	= stone
	usableItems.dawnstone    	= stone
	usableItems.icestone     	= stone
	usableItems.auspiciousarmor = stone
	usableItems.maliciousarmor  = stone
	usableItems.leaderscrest    = stone
	usableItems.metalalloy      = stone
	usableItems.blackaugurite   = stone
	usableItems.linkingcord     = stone


	return usableItems end