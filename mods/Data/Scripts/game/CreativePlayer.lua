dofile( "$GAME_DATA/Scripts/game/CreativeGame.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua" )

CreativePlayer = class( nil )

-- 00Fant
dofile "$SURVIVAL_DATA/mod_version.lua"
dofile "$SURVIVAL_DATA/mod_cloth_upgrades.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_tesla_coil.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_flamethrower.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Block_Editor/Fant_Block_Editor.lua"

CreativePlayer.GrabbedBody = nil
CreativePlayer.GrabbedDistance = 0
CreativePlayer.GrabbedCharacter = nil
CreativePlayer.GrabLock = false
CreativePlayer.Health = 100
CreativePlayer.MaxHealth = 100
CreativePlayer.RespawnPosition = nil
framedeltas = framedeltas or {}
NameTags = NameTags or {}
PlayerScorces = PlayerScorces or {}
PlayerHealths = PlayerHealths or {}
CanRespawn = true
MaxBreath = 10
local TumbleResistTickTime = 3.0 * 40
local StopTumbleTimerTickThreshold = 1.0 * 40 
local MaxTumbleTimerTickThreshold = 20.0 * 40 



function CreativePlayer.sv_shape( self, data )
	if data.shapeType == "cube" or  data.shapeType == "hollowcube" then
		data.shape = sm.shape.createBlock( g_SelectedUUID, data.size, data.pos, sm.quat.identity(), 1, 1 )
	elseif data.shapeType == "sphere" or data.shapeType == "hollowsphere" then
		data.shape = sm.shape.createBlock( g_SelectedUUID, sm.vec3.new( data.size, data.size, data.size ), data.pos + sm.vec3.new( 0, 0, ( data.size / 4 ) * 0.25 ), sm.quat.identity(), 1, 1 )
	elseif data.shapeType == "cylinder" or data.shapeType == "hollowcylinder" then
		data.shape = sm.shape.createBlock( g_SelectedUUID, sm.vec3.new( data.radius * 2, data.radius * 2, data.height ), data.pos + sm.vec3.new( 0, 0, ( data.height / 4 ) * 0.25 ), sm.quat.identity(), 1, 1 )
	end
	self.network:sendToClient( data.player, "cl_cut", data )
end

function CreativePlayer.cl_cut( self, data )
	self.network:sendToServer( "sv_cut", data )
end

function CreativePlayer.sv_cut( self, data )
	if data.shapeType == "hollowcube" then
		for x = 0, data.size.x do
			for y = 0, data.size.y do
				for z = 0, data.size.z do
					if x > 0 and x < data.size.x - 1 then
						if y > 0 and y < data.size.y - 1 then
							if z > 0 and z < data.size.z - 1 then
								data.shape:destroyBlock( sm.vec3.new( x, y, z ), sm.vec3.new( 1, 1, 1 ), 0 )
							end
						end
					end
				end
			end
		end
	end
	if data.shapeType == "sphere" then
		local halfSize = data.size / 2
		for x = 0, data.size do
			for y = 0, data.size do
				for z = 0, data.size do
					local middle = sm.vec3.new( halfSize, halfSize, halfSize )
					
					local distanceToCenter = sm.vec3.length( middle - sm.vec3.new( x, y, z ) )
					if distanceToCenter > halfSize then
						data.shape:destroyBlock( sm.vec3.new( x, y, z ), sm.vec3.new( 1, 1, 1 ), 0 )
					end				
				end
			end
		end
	end
	if data.shapeType == "hollowsphere" then
		local halfSize = data.size / 2
		for x = 0, data.size do
			for y = 0, data.size do
				for z = 0, data.size do
					local middle = sm.vec3.new( halfSize, halfSize, halfSize )
					
					local distanceToCenter = sm.vec3.length( middle - sm.vec3.new( x, y, z ) )
					if distanceToCenter > halfSize or distanceToCenter < halfSize - 2 then
						data.shape:destroyBlock( sm.vec3.new( x, y, z ), sm.vec3.new( 1, 1, 1 ), 0 )
					end				
				end
			end
		end
	end
	if data.shapeType == "cylinder" then 
		local diameter = ( data.radius * 2 ) 
		for x = 0, diameter do
			for y = 0, diameter do
				for z = 0, data.height do
					local middle = sm.vec3.new( data.radius, data.radius, z )				
					local distanceToCenter = sm.vec3.length( middle - sm.vec3.new( x, y, z ) )
					if distanceToCenter > data.radius - 1 then
						data.shape:destroyBlock( sm.vec3.new( x, y, z ), sm.vec3.new( 1, 1, 1 ), 0 )
					end				
				end
			end
		end
	end
	if data.shapeType == "hollowcylinder" then 
		local diameter = ( data.radius * 2 )
		for x = 0, diameter do
			for y = 0, diameter do
				for z = 0, data.height do
					local middle = sm.vec3.new( data.radius, data.radius, z )
					local distanceToCenter = sm.vec3.length( middle - sm.vec3.new( x, y, z ) )
					if distanceToCenter > data.radius - 1 or ( distanceToCenter < data.radius - 2 and z > 0 and z < data.height - 1 ) then
						data.shape:destroyBlock( sm.vec3.new( x, y, z ), sm.vec3.new( 1, 1, 1 ), 0 )
					end				
				end
			end
		end
	end
end

function CreativePlayer.sv_setRope( self, data )
	--print( "sv_setRope" )
	self.RopePosition = data.hitPos
	self.RopeTarget = data.targetShape
	self.ropeLocalPosition = nil
	if self.RopeTarget ~= nil then
		self.ropeLocalPosition = self.RopeTarget:transformPoint( self.RopePosition )
	end
	--print( "self.ropeLocalPosition: ", self.ropeLocalPosition )
end

function CreativePlayer.sv_removeRope( self )
	--print( "sv_removeRope" )
	self.RopePosition = nil
end

function CreativePlayer.IgnoreFluid( self )
	self.ignoreFluid = 0.5
end

function CreativePlayer.ignoreSwimMode( self, dt )
	if self.ignoreFluid == nil then
		self.ignoreFluid = 0
	end
	if self.ignoreFluid > 0 then
		self.ignoreFluid = self.ignoreFluid - dt
		local character = self.player:getCharacter()
		if character then
			if character:isSwimming() then
				character:setSwimming( 0 )
			end
			if character:isDiving() then
				character:setDiving( 0 )
			end
		end
	end
end

function CreativePlayer.setGrabbedBody( self, data )
	self.GrabbedBody = data.body
	self.GrabbedDistance = data.distance
	self.GrabbedCharacter = data.character
end

function CreativePlayer.setDistance( self, distance )
	self.GrabbedDistance = distance
end

function CreativePlayer.setRotation( self, rotation )
	self.GrabbedRotation = rotation
end

function CreativePlayer.PlaceSoil( self, pos )
	local rot = math.random( 0, 3 ) * math.pi * 0.5
	sm.harvestable.create( hvs_soil, pos, sm.quat.angleAxis( rot, sm.vec3.new( 0, 0, 1 ) ) * sm.quat.new( 0.70710678, 0, 0, 0.70710678 ) )
	sm.effect.playEffect( "Plants - SoilbagUse", pos, nil, sm.quat.angleAxis( rot, sm.vec3.new( 0, 0, 1 ) ) * sm.quat.new( 0.70710678, 0, 0, 0.70710678 ) )
end

function CreativePlayer.Cleanup( self, radius )
	self.cleanup = true
	self.areaTrigger = sm.areaTrigger.createBox( sm.vec3.new( 1, 1, 1 ) * radius, self.player:getCharacter().worldPosition, sm.quat.identity(), sm.areaTrigger.filter.all )	
	print( "Cleanup Start!" )
end

function CreativePlayer.CleanupLoop( self, character )
	if self.areaTrigger == nil then
		return
	end
	if self.cleanup == nil then
		return
	end
	if self.cleanup == false then
		return
	end
	self.areaTrigger:setWorldPosition( character.worldPosition )
	local hasDeleted = false
	for _, result in ipairs(  self.areaTrigger:getContents() ) do
		if result ~= nil then
			--print( type( result ) )
			if type( result ) == "Harvestable" then
				sm.harvestable.destroy( result )	
			end
			if type( result ) == "Body" then
				local shapes = sm.body.getShapes( result )
				for i, k in pairs ( shapes ) do 
					k:destroyShape()
				end
			end
			hasDeleted = true
		end
	end
	if hasDeleted then
		self.cleanup = false
		print( "Cleanup Finish!" )
	end
end

function CreativePlayer.sv_takeDamage( self, damage, source )
	if damage > 0 then
		if self.cloth_damage_reduction ~= nil and self.sv_cloth_stats_bonus_health ~= nil then
			local SkillHealthLevel = self.sv_cloth_stats_bonus_health + self.cloth_damage_reduction
			print( SkillHealthLevel )
			if SkillHealthLevel > 0 then
				local subDamage = ( damage / 2 ) * ( SkillHealthLevel / 100 )
				
				damage = damage - subDamage
				if damage < 0 then
					damage = 0
				end
			end
		end
	end
	
	if damage > 0 then
		local character = self.player:getCharacter()
		local lockingInteractable = character:getLockingInteractable()
		if lockingInteractable and lockingInteractable:hasSeat() then
			lockingInteractable:setSeatCharacter( character )
		end
		local canDoDamage = true
		if source then
			if type( source ) == "Player" then
				local AttackerName = source.name
				local VictimName = self.player.name
				
				if PlayerScorces[ AttackerName ] ~= nil and PlayerScorces[ VictimName ] ~= nil then
					if PlayerScorces[ AttackerName ].Team == PlayerScorces[ VictimName ].Team and PlayerScorces[ AttackerName ].Team ~= "" and PlayerScorces[ VictimName ].Team ~= "" then
						canDoDamage = false
					end
					if PlayerScorces[ AttackerName ].Team == PlayerScorces[ VictimName ].Team and PlayerScorces[ AttackerName ].Team ~= "" and PlayerScorces[ VictimName ].Team ~= "" then
						canDoDamage = false
					end
				end
			end
		end
		if not g_godMode and canDoDamage then
			if self.Health > 0 then
				self.Health = math.max( self.Health - damage, 0 )

				print( "'CreativePlayer' took:", damage, "damage.", self.Health, "/", self.MaxHealth, "HP" )
				self.network:sendToClients( "cl_setHealth", { player = self.player, health = self.Health } )
				if self.Health <= 0 then
					print( "'CreativePlayer' knocked out!" )			
					if source then
						if type( source ) == "Player" then
							--sm.event.sendToGame( "SetData", { func = "sv_addKill", data = source } )
							self:sv_addKill( source )
						end
					end
					--sm.event.sendToGame( "SetData", { func = "sv_addDeath", data = self.player } )
					self:sv_addDeath( self.player )
					character:setTumbling( true )
					character:setDowned( true )		
				end
			end
			PlayerHealths[ self.player.name ] = self.Health
		else
			print( "'CreativePlayer' resisted", damage, "damage" )
		end
	end
end

function CreativePlayer.cl_setHealth( self, data )
	if sm.localPlayer.getPlayer() == data.player then
		self.Health = data.health
		if self.Health <= 0 and CanRespawn then
			sm.gui.displayAlertText( "Press (E) use to Respawn!", 10 )
		end
	end
end

function CreativePlayer.sv_setrespawn( self )
	local character = self.player:getCharacter()
	self.RespawnPosition = character:getWorldPosition()
end

function CreativePlayer.sv_respawn( self, data )
	local character = self.player:getCharacter()
	character:setTumbling( false )
	character:setDowned( false )
	self.Health = self.MaxHealth
	self.network:sendToClients( "cl_setHealth",  { player = self.player, health = self.Health } )
	if self.RespawnPosition == nil then
		self.RespawnPosition = character.worldPosition
	end
	if data ~= nil then
		if data.spawnPos ~= nil then
			self.RespawnPosition = data.spawnPos 
		end	
	end	
	local Dir = character:getDirection()
	local yaw = math.atan2( Dir.y, Dir.x ) - math.pi/2
	local pitch = math.asin( Dir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )
	local character2 = sm.character.createCharacter( self.player, character:getWorld(), self.RespawnPosition + sm.vec3.new( 0, 0, 0.25 ), yaw, pitch )	
	self.player:setCharacter( character2 )
	
	self.breath = MaxBreath
	self.network:sendToClients( "cl_setBreath", self.breath )
	
	self.sv_fant_cloth_reset_timer = 10
end

function CreativePlayer.sv_ScoreResetAll( self )
	if not sm.isHost then
		return
	end
	local NewPlayerScorces = {}
	for name, score in pairs( PlayerScorces ) do
		for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
			if listPlayer.name == name then
				--NewPlayerScorces[ name ] = { kills = 0, deaths = 0, robotkills = 0, Team = "" }
				
				local Kills = 0
				local Deaths = 0
				local Robots = 0
				local Team = ""
				if score ~= nil then
					-- if score.kills ~= nil then
						-- Kills = score.kills
					-- end
					-- if score.deaths ~= nil then
						-- Deaths = score.deaths
					-- end
					-- if score.robotkills ~= nil then
						-- Robots = score.robotkills
					-- end
					if score.Team ~= nil then
						Team = score.Team
					end
				end
				NewPlayerScorces[ name ] = { kills = Kills, deaths = Deaths, robotkills = Robots, Team = Team }
				print( name  )
				print( NewPlayerScorces[ name ] )
				
			end
		end
	end
	
	--print( "_____"  )
	PlayerScorces = NewPlayerScorces
	
	self.network:sendToClients( "cl_setPlayerScore", PlayerScorces )
	sm.event.sendToGame( "sv_setPlayerScore", PlayerScorces )
end

function CreativePlayer.sv_CreatePlayerScore( self, player )
	if not sm.isHost then
		return
	end
	if PlayerScorces  == nil then
		PlayerScorces = {}
	end
	local Kills = 0
	local Deaths = 0
	local Robots = 0
	local Team = ""
	if PlayerScorces[ player.name ] ~= nil then
		if PlayerScorces[ player.name ].kills ~= nil then
			Kills = PlayerScorces[ player.name ].kills
		end
		if PlayerScorces[ player.name ].deaths ~= nil then
			Deaths = PlayerScorces[ player.name ].deaths
		end
		if PlayerScorces[ player.name ].robotkills ~= nil then
			Robots = PlayerScorces[ player.name ].robotkills
		end
		if PlayerScorces[ player.name ].Team ~= nil then
			Team = PlayerScorces[ player.name ].Team
		end
	end
	PlayerScorces[ player.name ] = { kills = Kills, deaths = Deaths, robotkills = Robots, Team = Team }

	
	self.network:sendToClients( "cl_setPlayerScore", PlayerScorces )
	sm.event.sendToGame( "sv_setPlayerScore", PlayerScorces )
end

function getRandomName()
	symbols = {
		'ach', 'ack', 'ad', 'age', 'ald', 'ale', 'an', 'ang', 'ar', 'ard',
		'as', 'ash', 'at', 'ath', 'augh', 'aw', 'ban', 'bel', 'bur', 'cer',
		'cha', 'che', 'dan', 'dar', 'del', 'den', 'dra', 'dyn', 'ech', 'eld',
		'elm', 'em', 'en', 'end', 'eng', 'enth', 'er', 'ess', 'est', 'et',
		'gar', 'gha', 'hat', 'hin', 'hon', 'ia', 'ight', 'ild', 'im', 'ina',
		'ine', 'ing', 'ir', 'is', 'iss', 'it', 'kal', 'kel', 'kim', 'kin',
		'ler', 'lor', 'lye', 'mor', 'mos', 'nal', 'ny', 'nys', 'old', 'om',
		'on', 'or', 'orm', 'os', 'ough', 'per', 'pol', 'qua', 'que', 'rad',
		'rak', 'ran', 'ray', 'ril', 'ris', 'rod', 'roth', 'ryn', 'sam',
		'say', 'ser', 'shy', 'skel', 'sul', 'tai', 'tan', 'tas', 'ther',
		'tia', 'tin', 'ton', 'tor', 'tur', 'um', 'und', 'unt', 'urn', 'usk',
		'ust', 'ver', 'ves', 'vor', 'war', 'wor', 'yer'
	}
	local name = ""
	local rand = math.floor( math.random( 2, math.floor( math.random( 2, 4 ) ) ) )
	for i = 1, rand do
		name = name .. symbols[math.floor( math.random( 1, #symbols ) )]
	end
	local function firstToUpper( str )
		return ( str:gsub( "^%l", string.upper ) )
	end
	return firstToUpper( name )
end

function CreativePlayer.sv_addKill( self, player )
	if PlayerScorces[ player.name ] == nil then
		return
	end
	PlayerScorces[ player.name ].kills = PlayerScorces[ player.name ].kills + 1
	
	sm.event.sendToGame( "sv_setPlayerScore", PlayerScorces )
	self.network:sendToClients( "cl_setPlayerScore", PlayerScorces )
end

function CreativePlayer.sv_addDeath( self, player )
	if PlayerScorces[ player.name ] == nil then
		return
	end
	PlayerScorces[ player.name ].deaths = PlayerScorces[ player.name ].deaths + 1
	
	sm.event.sendToGame( "sv_setPlayerScore", PlayerScorces )
	self.network:sendToClients( "cl_setPlayerScore", PlayerScorces )
end

function CreativePlayer.sv_addRobotKill( self, params )
	if PlayerScorces[ params.attacker.name ] == nil then
		return
	end
	PlayerScorces[ params.attacker.name ].robotkills = PlayerScorces[ params.attacker.name ].robotkills + 1
	
	sm.event.sendToGame( "sv_setPlayerScore", PlayerScorces )
	self.network:sendToClients( "cl_setPlayerScore", PlayerScorces )
end

function CreativePlayer.sv_setPlayerScore( self, data )
	PlayerScorces = data
	self.network:sendToClients( "cl_setPlayerScore", PlayerScorces )
end

function CreativePlayer.cl_setPlayerScore( self, data )
	PlayerScorces = data
	if self.cl_DisplayPlayerNameGUI ~= nil then
		self.cl_DisplayPlayerNameGUI:close()
		self.cl_DisplayPlayerNameGUI = nil
	end
end

function CreativePlayer.cl_DisplayPlayerName( self )
	if sm.localPlayer.getPlayer() == self.player or not ShowNameTag then
		if self.cl_DisplayPlayerNameGUI then
			self.cl_DisplayPlayerNameGUI:close()
			self.cl_DisplayPlayerNameGUI = nil
		end
		return
	end
	local LocalName = sm.localPlayer.getPlayer().name
	local OtherName = self.player.name
	local canShow = g_godMode
	local TeamName = ""
	if PlayerScorces[ OtherName ] ~= nil and PlayerScorces[ LocalName ] ~= nil then
		if PlayerScorces[ OtherName ].Team ~= "" then
			TeamName = PlayerScorces[ OtherName ].Team .. " | "
		end
		if PlayerScorces[ OtherName ].Team == PlayerScorces[ LocalName ].Team and PlayerScorces[ OtherName ].Team ~= "" and PlayerScorces[ LocalName ].Team ~= "" then
			canShow = true
		end
		if PlayerScorces[ OtherName ].Team == PlayerScorces[ LocalName ].Team and PlayerScorces[ OtherName ].Team ~= "" and PlayerScorces[ LocalName ].Team ~= "" then
			canShow = true
		end
	end
	if self.player.name == "" then
		canShow = false
	end
	if canShow == false then
		if self.cl_DisplayPlayerNameGUI then
			self.cl_DisplayPlayerNameGUI:close()
			self.cl_DisplayPlayerNameGUI = nil
		end
	else
		local character = self.player:getCharacter()
		if character then
			if self.cl_DisplayPlayerNameGUI == nil then
				self.cl_DisplayPlayerNameGUI = sm.gui.createNameTagGui()
				self.cl_DisplayPlayerNameGUI:setRequireLineOfSight( false )
				self.cl_DisplayPlayerNameGUI:open()
				self.cl_DisplayPlayerNameGUI:setMaxRenderDistance( 2500 )
				
				self.cl_DisplayPlayerNameGUI:setText( "Text", "#ffffff".. TeamName .. self.player.name )
			end
			if self.cl_DisplayPlayerNameGUI then
				self.cl_DisplayPlayerNameGUI:setWorldPosition( character:getWorldPosition() + sm.vec3.new( 0, 0, 1 ) )
			end
		end
	end
end

function CreativePlayer.fant_client_onUpdate( self, dt ) 
	self:cl_DisplayPlayerName()
	
	if sm.localPlayer.getPlayer() ~= self.player then
		return
	end
	if g_survivalHud and FantHud then
		local TextData = tostring( "Time: " .. getTimeOfDayString() )  .. "\n"
		TextData = TextData .. getMods()
		local character = self.player:getCharacter()
		if character then
			if FantHud then
				local newDeltas = {}
				local counter = 0
				local frameVal = 0
				for i, k in pairs( framedeltas ) do
					counter = counter + 1
					if counter > 1 then
						table.insert( newDeltas, k )
						frameVal = frameVal + k
					end
				end
				while counter < 25 do
					counter = counter + 1
					table.insert( newDeltas, dt )
					frameVal = frameVal + dt
				end
				
				framedeltas = newDeltas
				TextData = TextData .. "Framedelta: " ..  tostring( math.floor( ( frameVal / counter ) * 10000 ) / 10 ) .."\n"
				
				local playerPosX = math.floor( character.worldPosition.x )
				local playerPosY = math.floor( character.worldPosition.y )
				TextData = TextData .. "Pos: " .. tostring( playerPosX ) .. ", " .. tostring( playerPosY ) .. "\n"
				
				TextData = TextData .. "Height: " ..  tostring( math.floor( character.worldPosition.z ) ).. "\n"
				local speed =  math.floor( (( sm.vec3.length( character:getVelocity() ) * 1 ) / 1 ) * 3.6 )
				TextData = TextData .. "Kmh: " .. tostring( speed ) .. "\n\n"
				
				TextData = TextData .. "Team | Name: #ff0000Kills | #00ff00Robots | #0000ffDeaths\n#ffffff---------------------\n"
				local colorFlip = false
				local function swap( list, a, b )
					local temp = list[ b ]
					list[ b ] = list[ a ]
					list[ a ] = temp
				end
				
				if PlayerScorces ~= nil then
					local cl_PlayerScorces_Sorted = {}
					local index = 1
					for name, score in pairs( PlayerScorces ) do 
						table.insert( cl_PlayerScorces_Sorted, index, { name = name, score = score } )
						index = index + 1
					end		
					for indexA = 1, #cl_PlayerScorces_Sorted do 
						for indexB = 1, #cl_PlayerScorces_Sorted do 
							if indexA ~= indexB then
								if cl_PlayerScorces_Sorted[ indexA ].score.kills > cl_PlayerScorces_Sorted[ indexB ].score.kills then
									swap( cl_PlayerScorces_Sorted, indexA, indexB )
								end
								if cl_PlayerScorces_Sorted[ indexA ].score.kills == cl_PlayerScorces_Sorted[ indexB ].score.kills then
									if cl_PlayerScorces_Sorted[ indexA ].score.robotkills > cl_PlayerScorces_Sorted[ indexB ].score.robotkills then
										swap( cl_PlayerScorces_Sorted, indexA, indexB )
									end
									if cl_PlayerScorces_Sorted[ indexA ].score.robotkills == cl_PlayerScorces_Sorted[ indexB ].score.robotkills then
										if cl_PlayerScorces_Sorted[ indexA ].score.deaths < cl_PlayerScorces_Sorted[ indexB ].score.deaths then
											swap( cl_PlayerScorces_Sorted, indexA, indexB )
										end
									end								
								end
							end
						end	
					end	
					index = 0

					for index, PlayerScorce in pairs( cl_PlayerScorces_Sorted ) do 
						if PlayerScorce.score ~= nil then
							local TeamName = ""
							if PlayerScorce.score.Team ~= "" then						
								TeamName = PlayerScorce.score.Team .. " | "
							end
							if colorFlip then
								colorFlip = false
								TextData = TextData .. "#808080" .. TeamName ..PlayerScorce.name .. " : #ff0000" .. tostring( PlayerScorce.score.kills ) .. " | #00ff00" ..  tostring( PlayerScorce.score.robotkills ) .. " | #0000ff" ..  tostring( PlayerScorce.score.deaths ) .. "\n"
							else
								colorFlip = true
								TextData = TextData .. "#d3d3d3" .. TeamName ..PlayerScorce.name .. " : #ff0000" .. tostring( PlayerScorce.score.kills ) .. " | #00ff00" ..  tostring( PlayerScorce.score.robotkills ) .. " | #0000ff" ..  tostring( PlayerScorce.score.deaths ) .. "\n"
							end
						end
					end					
				end
			end
		end
		
		TextData = TextData .. "\n"
		if self.cloth_damage_reduction ~= nil then
			TextData = TextData .. "#ffffffARMOR: #ff0000" .. tostring( self.cloth_damage_reduction ) .. "#ffffff%\n"
		else
			TextData = TextData .. "#ffffffARMOR: #ff00000%\n"
		end
		TextData = TextData .. "#ffffff( #ff0000x#ffffff% less damage )\n"
		
		if self.cloth_walk_speed ~= nil then
			TextData = TextData .. "#ffffffSPEED: #00ff00" .. tostring( self.cloth_walk_speed ) .. "#ffffff%\n"
		else
			TextData = TextData .. "#ffffffSPEED: #00ff000%\n"
		end
		TextData = TextData .. "#ffffff( #00ff00x#ffffff% walk/run speed )\n"
		
		if self.cloth_breath_value ~= nil then
			TextData = TextData .. "#ffffffBREATH: #0000ff" .. tostring( self.cloth_breath_value ) .. "#ffffff%\n"
		else
			TextData = TextData .. "#ffffffBREATH: #0000ff0%\n"
		end
		TextData = TextData .. "#ffffff( #0000ffx#ffffff% more diving time )\n"
		
		g_survivalHud:setText( "FantData", TextData )		
		if self.Health ~= nil then
			g_survivalHud:setSliderData( "Health", 100 * 10 + 1, self.Health * 10 )
		end
		if self.breath == nil then
			self.breath = MaxBreath
		end
		g_survivalHud:setSliderData( "Breath", (MaxBreath ) * 10, ( self.breath ) * 10 )
		
		g_survivalHud:setVisible( "EXP_BAR", false )
		g_survivalHud:setVisible( "EXP_BAR_LEVEL", false )
	else
		g_survivalHud:setText( "FantData", "" )
	end
end

function CreativePlayer.sv_team( self, data )
	if PlayerScorces == nil then
		PlayerScorces = {}
	end
	PlayerScorces[ data.player.name ].Team = data.Team
	self.network:sendToClients( "cl_setPlayerScore", PlayerScorces )
end

function CreativePlayer.client_onDestroy( self )
	if self.cl_DisplayPlayerNameGUI then
		self.cl_DisplayPlayerNameGUI:close()
		self.cl_DisplayPlayerNameGUI = nil
	end
end

function CreativePlayer.sv_canrespawn( self, state )
	CanRespawn = state
	self.network:sendToClients( "cl_canrespawn", state )
end

function CreativePlayer.cl_canrespawn( self, state )
	CanRespawn = state
end

function CreativePlayer.cl_setBreath( self, breath )
	self.breath = breath
end

function CreativePlayer.sv_noBuild( self, state )
	for i, body in pairs( sm.body.getAllBodies( ) ) do 
		if sm.exists( body ) then
			body:setBuildable( not state )
			body:setErasable( not state )
		end
	end
end

function CreativePlayer.cl_fant_cloth_manager( self )	
	local character = self.player:getCharacter()
	if character then
		local inventory = self.player:getInventory()
		if sm.game.getLimitedInventory() == false then
			inventory = self.player:getHotbar()
		end
		if inventory ~= nil then
			local size = inventory:getSize()
			local hasHead = false
			local hasChest = false
			local hasPants = false

			for clothIndex, cloth in pairs( Fant_Cloth_Upgrades ) do
				if cloth ~= nil and size > 0 then
					cloth.cl_state[ self.player:getId() ] = false
					for i = 0, size do
						if i >= 10 and cloth.hotbarOnly then
							break
						end
						local item = inventory:getItem( i )
						if item.uuid == cloth.itemUUid then
							if cloth.cloth_type == "head" and not hasHead then
								hasHead = true
								cloth.cl_state[ self.player:getId() ] = true	
							end
							if cloth.cloth_type == "chest" and not hasChest then
								hasChest = true
								cloth.cl_state[ self.player:getId() ] = true	
							end
							if cloth.cloth_type == "pants" and not hasPants then
								hasPants = true
								cloth.cl_state[ self.player:getId() ] = true	
							end
							if cloth.cloth_type == "free" then
								cloth.cl_state[ self.player:getId() ] = true	
							end						
						end
					end
					if cloth.cl_state[ self.player:getId() ] ~= cloth.cl_laststate[ self.player:getId() ] then
						cloth.cl_laststate[ self.player:getId() ] = cloth.cl_state[ self.player:getId() ]				
						if cloth.cl_state[ self.player:getId() ] then
							if cloth.effectData ~= nil then
								if cloth.effectData ~= nil then
									if self.cloth_Effects == nil then
										self.cloth_Effects = {}
									end
									if self.cloth_Effects ~= nil then
										self.cloth_Effects[ cloth.name ] = sm.effect.createEffect( cloth.effectData.name )
									end
									
								end
								if self.cloth_Effects ~= nil then	
									if self.cloth_Effects[ cloth.name ] ~= nil then
										if not self.cloth_Effects[ cloth.name ]:isPlaying() then								
											self.cloth_Effects[ cloth.name ]:start()
										end		
									end		
								end
							end
							if self.player:isMale() then
								--character:addRenderable( cloth.male_rend )
								self.network:sendToServer( "sv_set_cloth", { add = true, character = character, cloth = cloth.male_rend } )
							else
								--character:addRenderable( cloth.female_rend )
								self.network:sendToServer( "sv_set_cloth", { add = true, character = character, cloth = cloth.female_rend } )
							end
							
							
						else
							if cloth.effectData ~= nil then
								if self.cloth_Effects ~= nil then
									if self.cloth_Effects[ cloth.name ] ~= nil then
										self.cloth_Effects[ cloth.name ]:stop()
									end
								end
							end
							if self.player:isMale() then
								--character:removeRenderable( cloth.male_rend )
								self.network:sendToServer( "sv_set_cloth", { remove = true, character = character, cloth = cloth.male_rend } )
							else
								--character:removeRenderable( cloth.female_rend )
								self.network:sendToServer( "sv_set_cloth", { remove = true, character = character, cloth = cloth.female_rend } )
							end
						end
					end
					if cloth.cl_state[ self.player:getId() ] then
						if cloth.effectData ~= nil then
							if self.cloth_Effects ~= nil then
								if self.cloth_Effects[ cloth.name ] ~= nil then
									local pos = character.worldPosition + sm.vec3.new( 0, 0, 2.5 )
									local direction = character:getDirection()
									pos = pos + ( direction * cloth.effectData.local_position.x )
									self.cloth_Effects[ cloth.name ]:setPosition( pos )
								end
							end
						end				
					end
				end
			end
		end
	end
end

function CreativePlayer.sv_fant_cloth_manager( self )	
	local character = self.player:getCharacter()
	self.cloth_damage_reduction = 0
	self.cloth_walk_speed = 0
	self.cloth_breath_value = 0
	
	self.sv_cloth_stats_bonus_health = 0
	self.sv_cloth_stats_bonus_food = 0
	self.sv_cloth_stats_bonus_thirst = 0
	self.sv_cloth_stats_bonus_loot = 0
	self.sv_cloth_stats_bonus_refine = 0
	self.sv_cloth_stats_bonus_farming = 0
	
	if character then
		local inventory = self.player:getInventory()
		local hasHead = false
		local hasChest = false
		local hasPants = false

		if sm.game.getLimitedInventory() == false then
			inventory = self.player:getHotbar()
		end
		if inventory ~= nil then
			local size = inventory:getSize()
			for clothIndex, cloth in pairs( Fant_Cloth_Upgrades ) do
				if cloth ~= nil and size > 0 then
					cloth.sv_state[ self.player:getId() ] = false
					for i = 0, size do
						if i >= 10 then
							break
						end
						local item = inventory:getItem( i )
						if item.uuid == cloth.itemUUid then
							if cloth.cloth_type == "head" and not hasHead then
								hasHead = true
								cloth.sv_state[ self.player:getId() ] = true	
							end
							if cloth.cloth_type == "chest" and not hasChest then
								hasChest = true
								cloth.sv_state[ self.player:getId() ] = true	
							end
							if cloth.cloth_type == "pants" and not hasPants then
								hasPants = true
								cloth.sv_state[ self.player:getId() ] = true	
							end
							if cloth.cloth_type == "free" then
								cloth.sv_state[ self.player:getId() ] = true	
							end
						end
					end
					if cloth.sv_state[ self.player:getId() ] ~= cloth.sv_laststate[ self.player:getId() ] then
						cloth.sv_laststate[ self.player:getId() ] = cloth.sv_state[ self.player:getId() ]					
						if cloth.sv_state[ self.player:getId() ] then

						else

						end
					end
					if cloth.sv_state[ self.player:getId() ] then
						self.cloth_damage_reduction = self.cloth_damage_reduction + cloth.damage_reduction
						self.cloth_walk_speed = self.cloth_walk_speed + cloth.walk_speed
						self.cloth_breath_value = self.cloth_breath_value + cloth.breath_value
						
						self.sv_cloth_stats_bonus_health = self.sv_cloth_stats_bonus_health + cloth.stats_bonus_health
						self.sv_cloth_stats_bonus_food = self.sv_cloth_stats_bonus_food + cloth.stats_bonus_food
						self.sv_cloth_stats_bonus_thirst = self.sv_cloth_stats_bonus_thirst + cloth.stats_bonus_thirst
						self.sv_cloth_stats_bonus_loot = self.sv_cloth_stats_bonus_loot + cloth.stats_bonus_loot
						self.sv_cloth_stats_bonus_refine = self.sv_cloth_stats_bonus_refine + cloth.stats_bonus_refine
						self.sv_cloth_stats_bonus_farming = self.sv_cloth_stats_bonus_farming + cloth.stats_bonus_farming	
					end
				end
			end
		end
	end
end

function CreativePlayer.sv_set_cloth( self, params )
	self.network:sendToClients( "cl_set_cloth", params )
end

function CreativePlayer.cl_set_cloth( self, params )
	if params.cloth == nil then
		return
	end
	if params.add then
		params.character:addRenderable( params.cloth )
	end
	if params.remove then
		params.character:removeRenderable( params.cloth )
	end
end


function CreativePlayer.sv_fant_cloth_reset( self )	
	if self.sv_fant_cloth_reset_timer > 0 then
		self.sv_fant_cloth_reset_timer = self.sv_fant_cloth_reset_timer - 1
		if self.sv_fant_cloth_reset_timer <= 0 then
			for clothIndex, cloth in pairs( Fant_Cloth_Upgrades ) do
				cloth.sv_state[ self.player:getId() ] = false
				cloth.sv_laststate[ self.player:getId() ] = false
			end
			self.network:sendToClients( "cl_fant_cloth_reset", self.player )
			self.sv_fant_cloth_reset_timer = 0
		end
		return
	end
end

function CreativePlayer.cl_fant_cloth_reset( self, player )	
	for clothIndex, cloth in pairs( Fant_Cloth_Upgrades ) do
		cloth.cl_state[ player:getId() ] = false
		cloth.cl_laststate[ player:getId() ] = false		
	end
end

function CreativePlayer.sv_extern_fant_cloth_reset( self )	
	self.sv_fant_cloth_reset_timer = 10
end

local f_cloud_spawn_timer = 0
g_fant_cl_clouds = nil
local f_max_Clouds = 2000
local f_cloud_radius_distance = 1500
local f_cloud_height = 750
local f_cloud_main_Speed = 1

function CreativePlayer.cl_fant_clouds( self, dt )
	if fant_clouds_active == nil or not fant_clouds_active then
		if g_fant_cl_clouds ~= nil then
			for i, cloud in pairs( g_fant_cl_clouds ) do
				if cloud.effect ~= nil then
					cloud.effect:stop()
					cloud.effect:destroy()
					cloud.effect = nil
				end
				cloud = nil
			end
			g_fant_cl_clouds = nil
			print( g_fant_cl_clouds )
		end
		return
	end
	if sm.localPlayer.getPlayer() ~= self.player then
		return
	end
	local cloudCounter = 0
	
	if g_fant_cl_clouds == nil and fant_clouds_active then
		local randomCloudAmount = math.random( 10, 30 )
		for rand = 1, randomCloudAmount do
			local ply = sm.localPlayer.getPlayer()
			if ply ~= nil then
				if ply.character ~= nil then
					local randomPos = sm.vec3.new( 0, 0, 0 )
					local halff_cloud_radius_distance = f_cloud_radius_distance / 2
					randomPos.x = math.random( -halff_cloud_radius_distance, halff_cloud_radius_distance )
					randomPos.y = math.random( -halff_cloud_radius_distance, halff_cloud_radius_distance )
					randomPos.z = math.random( -5, 5 ) + f_cloud_height
					self:cl_addCloud( sm.vec3.new( ply.character.worldPosition.x, ply.character.worldPosition.y, 0 ) + randomPos, true )
					cloudCounter = cloudCounter + 1
				end
			end	
		end
	end
	if g_fant_cl_clouds ~= nil then
		for i, cloud in pairs( g_fant_cl_clouds ) do
			if cloud.effect ~= nil then
				if cloud.spawnSize < 1 and cloud.lifetime > 0 then
					cloud.spawnSize = cloud.spawnSize + ( dt * 0.1 * f_cloud_main_Speed )
					if cloud.spawnSize >= 1 then
						cloud.spawnSize = 1
					end
					cloud.effect:setScale( cloud.cloudSize * math.sin( cloud.spawnSize ) )
				end
				cloud.lifetime = cloud.lifetime - ( dt * f_cloud_main_Speed )			
				cloud.pos = cloud.pos + ( cloud.cloud_direction:normalize() * cloud.cloud_speed * dt * f_cloud_main_Speed )
				cloud.effect:setPosition( cloud.pos )

				if cloud.lifetime <= 0 then
					if cloud.spawnSize > 0.01 then
						cloud.spawnSize = cloud.spawnSize - ( dt * 0.1 * f_cloud_main_Speed )
						if cloud.spawnSize <= 0.01 then
							cloud.spawnSize = 0.01
						end
						cloud.effect:setScale( cloud.cloudSize * math.sin( cloud.spawnSize ) )
						if cloud.spawnSize <= 0.01 then
							cloud.effect:stop()
							cloud.effect:destroy()
							cloud.effect = nil
							cloud = nil
						end
					end
				else
					cloudCounter = cloudCounter + 1
				end	
			end
		end
	end
	if f_cloud_spawn_timer <= 0 and cloudCounter < f_max_Clouds then
		f_cloud_spawn_timer = math.random( 5, 8 ) / f_cloud_main_Speed
		local ply = sm.localPlayer.getPlayer()
		if ply ~= nil then
			if ply.character ~= nil then
				local randomPos = sm.vec3.new( 0, 0, 0 )
				randomPos.x = math.random( 0, 1000 )  / 1000
				randomPos.y = 1 - randomPos.x
				randomPos = randomPos:normalize() * -f_cloud_radius_distance
				randomPos.z = math.random( -5, 5 ) + f_cloud_height
				local newP = sm.vec3.new( 0, 0, 0 )
				newP.x = ply.character.worldPosition.x
				newP.y = ply.character.worldPosition.y
				self:cl_addCloud( newP + randomPos )
			end
		end	
	else
		f_cloud_spawn_timer = f_cloud_spawn_timer - dt
	end
end

function CreativePlayer.cl_addCloud( self, pos, spawn )
	local subOffset = 100
	for i = 1, math.random( 1, 7 ) do
		self:cl_subaddCloud( pos + sm.vec3.new( math.random( -subOffset, subOffset ), math.random( -subOffset, subOffset ), math.random( -subOffset, subOffset ) ), spawn )
	end
end

function CreativePlayer.cl_subaddCloud( self, pos, spawn ) 
	local cloudRot = sm.quat.new( 0, 0, 0, 0 )

	
	local new_f_effect = {}
	new_f_effect.cloud_direction = sm.vec3.new( math.random( 7, 10 ), math.random( 7, 10 ), 0 ):normalize()
	new_f_effect.cloud_speed = math.random( 8, 10 )
	
	new_f_effect.pos = pos
	new_f_effect.spawnSize = 0.01
	if spawn then
		new_f_effect.spawnSize = 1
	end
	new_f_effect.cloudSize = sm.vec3.new( math.random( 15, 50 ), math.random( 15, 50 ), math.random( 5, 25 ) )
	
	new_f_effect.lifetime = math.random( 450, 500 ) 
	local f_effect = sm.effect.createEffect( "ShapeRenderable" )				
	--f_effect:setParameter( "uuid", sm.uuid.new("f7881097-9320-4667-b2ba-4101c72b8730") )  -- blk_fant_block
	f_effect:setParameter( "uuid", sm.uuid.new("589dda51-0702-4aad-8986-bb8eff77a5b4") ) 
	f_effect:setPosition( new_f_effect.pos )	
	f_effect:setScale( new_f_effect.cloudSize * new_f_effect.spawnSize )
	f_effect:setRotation( cloudRot )	
	
	f_effect:setParameter( "color", sm.color.new( 1, 1, 1, 1 ) * ( math.random( 85, 95 ) / 100 ) )
	f_effect:start()
	
	new_f_effect.effect = f_effect
	if g_fant_cl_clouds == nil then
		g_fant_cl_clouds = {}
	end
	table.insert( g_fant_cl_clouds, new_f_effect )
end


function CreativePlayer.sv_updateTumbling( self )
	if not self.sv.resistTumbleTimer:done() then
		self.sv.resistTumbleTimer:tick()
	end

	if not self.player.character:isDowned() then
		if self.player.character:isTumbling() then
			self.sv.maxTumbleTimer:tick()
			if self.sv.maxTumbleTimer:done() then
				-- Stuck in the tumble state for too long, gain temporary tumble immunity
				self.player.character:setTumbling( false )
				self.sv.maxTumbleTimer:reset()
				self.sv.tumbleReset:reset()
				self.sv.resistTumbleTimer:reset()
			else
				local tumbleVelocity = self.player.character:getTumblingLinearVelocity()
				if tumbleVelocity:length() < 1.0 then
					self.sv.tumbleReset:tick()

					if self.sv.tumbleReset:done() then
						self.player.character:setTumbling( false )
						self.sv.tumbleReset:reset()
					end
				else
					self.sv.tumbleReset:reset()
				end
			end
		end
	end
end

function CreativePlayer.sv_e_spawnRaiders( self, params )
	print( "CreativePlayer.sv_e_spawnRaiders" )
	local attackPos = params.attackPos
	local raiders = params.raiders

	local minDistance = 50
	local maxDistance = 80 -- 128 is maximum guaranteed terrain distance

	local incomingUnits = {}
	for k,v in pairs( raiders ) do
		for i=1, v do
			table.insert( incomingUnits, k )
		end
	end

	print( #incomingUnits, "raiders incoming" )

	local maxSpawnAttempts = 32
	for i = 1, #incomingUnits do
		local spawnAttempts = 0
		while spawnAttempts < maxSpawnAttempts do
			spawnAttempts = spawnAttempts + 1
			local distanceFromCenter = math.random( minDistance, maxDistance )
			local spawnDirection = sm.vec3.new( 0, 1, 0 )
			spawnDirection = spawnDirection:rotateZ( math.rad( math.random( 359 ) ) )
			local unitPos = attackPos + spawnDirection * distanceFromCenter

			local success, result = sm.physics.raycast( unitPos + sm.vec3.new( 0, 0, 128 ), unitPos + sm.vec3.new( 0, 0, -128 ), nil, -1 )
			if success and ( result.type == "invalid" or result.type == "terrainSurface" ) then
				local direction = attackPos - unitPos
				local yaw = math.atan2( direction.y, direction.x ) - math.pi / 2
				unitPos = result.pointWorld
				local deathTick = sm.game.getCurrentTick() + 40 * 60 * 5 -- Despawn after 5 minutes (flee after 4)
				sm.unit.createUnit( incomingUnits[i], unitPos, yaw, { temporary = true, roaming = true, raider = true, tetherPoint = attackPos, deathTick = deathTick } )
				break
			end
		end
	end

	-- self.network:sendToClients( "cl_n_unitMsg", {
	-- 	fn = "cl_n_waveMsg",
	-- 	wave = params.wave,
	-- } )
end

-- 00Fant






function CreativePlayer.server_onCreate( self )
	self.sv = {}
	self:sv_init()
	-- 00Fant
	--self:sv_CreatePlayerScore( self.player )
	PlayerHealths[ self.player.name ] = self.Health
	self.breath = MaxBreath
	self.network:sendToClients( "cl_setBreath", self.breath )
	
	self.sv_fant_cloth_reset_timer = 20
	-- 00Fant
	
	
end

function CreativePlayer.server_onRefresh( self )
	self:sv_init()
end

function CreativePlayer.sv_init( self ) 
	-- 00Fant
	self.sv.resistTumbleTimer = Timer()
	self.sv.resistTumbleTimer:start( TumbleResistTickTime )
	self.sv.resistTumbleTimer.count = TumbleResistTickTime
	
	self.sv.tumbleReset = Timer()
	self.sv.tumbleReset:start( StopTumbleTimerTickThreshold )

	self.sv.maxTumbleTimer = Timer()
	self.sv.maxTumbleTimer:start( MaxTumbleTimerTickThreshold )
end

function CreativePlayer.server_onDestroy( self ) end

function CreativePlayer.client_onCreate( self )
	self.cl = {}
	self:cl_init()
	-- 00Fant
	PlayerScorces = PlayerScorces or {}
	self.breath = MaxBreath
	
	g_survivalHud:setSliderData( "Breath", (MaxBreath ) * 10, ( self.breath ) * 10 )
	
	-- 00Fant
end

function CreativePlayer.client_onRefresh( self )
	self:cl_init()
end

function CreativePlayer.cl_init(self) end

function CreativePlayer.client_onUpdate( self, dt ) 
	-- 00Fant
	self:cl_fant_clouds( dt )
	self:fant_client_onUpdate( dt ) 
	self:cl_fant_cloth_manager()
	-- 00Fant
end

function CreativePlayer.client_onInteract( self, character, state ) 
	-- 00Fant
	self.GrabbedBody = nil
	self.GrabbedDistance = 0
	self.GrabbedCharacter = nil
	self.GrabLock = state
	if self.Health <= 0 and CanRespawn then
		self.network:sendToServer( "sv_respawn" )
	end
	-- 00Fant
end

function CreativePlayer.server_onFixedUpdate( self, dt ) 
	-- 00Fant
	self:sv_fant_cloth_reset()
	self:sv_fant_cloth_manager()
	
	if PlayerHealths[ self.player.name ] == nil then
		PlayerHealths[ self.player.name ] = self.Health
	end
	if PlayerHealths[ self.player.name ] ~= self.Health then
		PlayerHealths[ self.player.name ] = self.Health
	end
	
	self:ignoreSwimMode( dt )
	
	local character = self.player:getCharacter()
	if character and not g_godMode then
		ProcessTeslaDamage( self, true )  
		FlamethrowerDamage( self, dt )
		
		if self.breathTimer == nil then
			self.breathTimer = 0
		end
		
		if self.breath == nil then
			self.breath = MaxBreath
			self.network:sendToClients( "cl_setBreath", self.breath )
		end
		if self.breathTimer > 0 then
			local breathMul = 1
			if self.cloth_breath_value ~= nil then
				breathMul = 1 - ( self.cloth_breath_value / 100 )
			end
			self.breathTimer = self.breathTimer - ( dt * breathMul )
		else	
			self.breathTimer = 1
			if character:isDiving() then				
				self.breath = math.max( self.breath - 1, 0 )
				if self.breath <= 0 then
					print( "'CreativePlayer' is drowning!" )
					self:sv_takeDamage( 5, "drown" )
				end
			else
				self.breath = MaxBreath
			end
			self.network:sendToClients( "cl_setBreath", self.breath )
		end
	end
	
	if character then
		if self.cloth_walk_speed ~= nil then
			if self.cloth_walk_speed ~= 0 then
				character.movementSpeedFraction = 1 + ( 2 * ( self.cloth_walk_speed / 100 ) )
			end
		end
		
		self:sv_updateTumbling()
	end
	
	self:CleanupLoop( character )
	if g_characters then
		for k, g_character in ipairs(g_characters) do
			if g_character == character then			
				character.movementSpeedFraction = 3.5
				if character:isSprinting() then
					character.movementSpeedFraction = 20.0
				end
			end
		end
	end
	
	if self.GrabbedBody ~= nil and not self.GrabLock and sm.exists( self.GrabbedBody ) then
		local bodyShape = self.GrabbedBody:getShapes()[1]
		
		local dir = character:getDirection()
		local pos = character.worldPosition + sm.vec3.new( 0, 0, 0.8 ) + ( dir * self.GrabbedDistance ) 
		local force = pos - self.GrabbedBody:getCenterOfMassPosition()
		local vel = self.GrabbedBody.velocity
		force = force * self.GrabbedBody.mass * 2
		force = force - ( vel * self.GrabbedBody.mass * 0.3 )
		sm.physics.applyImpulse(  self.GrabbedBody, force, true )
		
		if self.GrabbedRotation ~= nil then
			local RotationForce = self.GrabbedRotation * self.GrabbedBody.mass * 2
			sm.physics.applyTorque( self.GrabbedBody, RotationForce, true )
			self.GrabbedRotation = nil
		end
		
		local angvel = -self.GrabbedBody:getAngularVelocity() / 5
		local AngForce = angvel * self.GrabbedBody:getMass()
		if sm.vec3.length( AngForce ) > 0.001 then
			sm.physics.applyTorque( self.GrabbedBody, AngForce * dt, true )
		end
	else
		self.GrabbedBody = nil
		self.GrabLock = false
	end

	if self.GrabbedCharacter ~= nil and not self.GrabLock and sm.exists( self.GrabbedCharacter ) then
		
		local GrabbedCharacterPos = self.GrabbedCharacter.worldPosition
		local GrabbedCharacterMass = 500
		if self.GrabbedCharacter:isTumbling() then
			GrabbedCharacterPos = self.GrabbedCharacter:getTumblingWorldPosition()
		else
			GrabbedCharacterMass = self.GrabbedCharacter:getMass()
		end
		local dir = character:getDirection()
		local pos = character.worldPosition + sm.vec3.new( 0, 0, 0.8 ) + ( dir * self.GrabbedDistance )
		local force = pos - GrabbedCharacterPos
		local vel = self.GrabbedCharacter:getVelocity()
		force = force * GrabbedCharacterMass * 2
		force = force - ( vel * GrabbedCharacterMass * 0.3 )
		if self.GrabbedCharacter:isTumbling() then
			self.GrabbedCharacter:applyTumblingImpulse( force )
		else
			sm.physics.applyImpulse(  self.GrabbedCharacter, force, true )
		end
		
	else
		self.GrabbedCharacter = nil
		self.GrabLock = false
	end
	
	if self.RopePosition ~= nil and character then
		if not character:isTumbling() then
			local RopeDestination = self.RopePosition
			if self.RopeTarget ~= nil  and sm.exists( self.RopeTarget )then
				RopeDestination = self.RopeTarget.worldPosition
				RopeDestination = RopeDestination + ( self.RopeTarget:getRight() * self.ropeLocalPosition.x )
				RopeDestination = RopeDestination + ( self.RopeTarget:getAt() * self.ropeLocalPosition.y )
				RopeDestination = RopeDestination + ( self.RopeTarget:getUp() * self.ropeLocalPosition.z )
			end
		
		
			local force = ( RopeDestination - character.worldPosition	) * 10	
			local length = force:length()
			if length > 200 then
				length = 200
			end
			force = ( RopeDestination - character.worldPosition ):normalize() * length
			force = force + ( character:getDirection() * 40 )
				
			sm.physics.applyImpulse( character, force, true )
		end
	end
	
	
	-- 00Fant
end

function CreativePlayer.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage ) 
	-- 00Fant
	self:sv_takeDamage( damage, attacker )
	-- 00Fant
end

function CreativePlayer.server_onMelee( self, hitPos, attacker, damage, power )
	-- 00Fant
	if not sm.exists( attacker ) then
		return
	end

	if self.player.character and attacker.character then
		local attackDirection = ( hitPos - attacker.character.worldPosition ):normalize()
		-- Melee impulse
		if attacker then
			ApplyKnockback( self.player.character, attackDirection, power )
		end
	end
	self:sv_takeDamage( damage, attacker )
	-- 00Fant
end

function CreativePlayer.server_onExplosion( self, center, destructionLevel )
	-- 00Fant
	local character = self.player:getCharacter()
	local distance = sm.vec3.length( character.worldPosition - center ) / 5
	if distance > 1 then
		distance = 1
	end
	if distance < 0 then
		distance = 0
	end
	--print( 1 - distance )
	local rel_damage = 75 * ( 1 - distance )

	self:sv_takeDamage( rel_damage, nil )
	-- 00Fant
end

function CreativePlayer.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal  ) 
	-- 00Fant
	if not self.player.character or not sm.exists( self.player.character ) then
		return
	end
	local damage = math.floor( sm.vec3.length( otherPointVelocity ) * 0.15 )
	if damage > 0 then
		local tumbleVelocity = otherPointVelocity * 0.15
		self.player.character:applyTumblingImpulse( tumbleVelocity * self.player.character.mass )
		self:sv_takeDamage( damage, "shock" )
	end
	-- 00Fant
end

function CreativePlayer.sv_e_staminaSpend( self, stamina ) end

function CreativePlayer.sv_e_receiveDamage( self, damageData ) end

function CreativePlayer.sv_e_respawn( self ) end

function CreativePlayer.sv_e_debug( self, params ) end

function CreativePlayer.sv_e_eat( self, edibleParams ) end

function CreativePlayer.sv_e_feed( self, params ) end

function CreativePlayer.sv_e_setRefiningState( self, params )
	local userPlayer = params.user:getPlayer()
	if userPlayer then
		if params.state == true then
			userPlayer:sendCharacterEvent( "refine" )
		else
			userPlayer:sendCharacterEvent( "refineEnd" )
		end
	end
end

function CreativePlayer.sv_e_onLoot( self, params ) end

function CreativePlayer.sv_e_onStayPesticide( self ) end

function CreativePlayer.sv_e_onEnterFire( self ) end

function CreativePlayer.sv_e_onStayFire( self ) end

function CreativePlayer.sv_e_onEnterChemical( self ) end

function CreativePlayer.sv_e_onStayChemical( self ) end

function CreativePlayer.sv_e_startLocalCutscene( self, cutsceneInfoName ) end

function CreativePlayer.client_onCancel( self ) end

function CreativePlayer.client_onReload( self ) end

function CreativePlayer.server_onShapeRemoved( self, removedShapes ) end