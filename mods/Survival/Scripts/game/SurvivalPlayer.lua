dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_constants.lua"
dofile( "$SURVIVAL_DATA/Scripts/game/util/Timer.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_camera.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/managers/QuestManager.lua" )

SurvivalPlayer = class( nil )

-- 00Fant
dofile "$SURVIVAL_DATA/mod_version.lua"
dofile "$SURVIVAL_DATA/mod_cloth_upgrades.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_tesla_coil.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_flamethrower.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Block_Editor/Fant_Block_Editor.lua"

Fant_EXP_gain_Woc 			= 200 / 9
Fant_EXP_gain_Totebot 		= 200 / 8
Fant_EXP_gain_HeavyTotebot 	= 200 / 7
Fant_EXP_gain_Haybot 		= 200 / 7
Fant_EXP_gain_HeavyHaybot 	= 200 / 6
Fant_EXP_gain_Beebot 		= 200 / 6
Fant_EXP_gain_Strawdog 		= 200 / 5
Fant_EXP_gain_Tapebot 		= 200 / 4
Fant_EXP_gain_RedTapebot	= 200 / 3
Fant_EXP_gain_Farmbot 		= 200 / 2
Fant_EXP_gain_Player 		= 200 / 1
Fant_EXP_level_Points 		= 5
Fant_EXP_level_Malus 		= 0.03125

g_Players = g_Players or {}
local Speed_Boost_Multiplicator = 2.5
local Jump_Boost_Force = 22.5

SurvivalPlayer.GrabbedBody = nil
SurvivalPlayer.GrabbedDistance = 0
SurvivalPlayer.GrabbedCharacter = nil
SurvivalPlayer.GrabLock = false
local jumpMsgPrintTimer = 0
local speedMsgPrintTimer = 0
local damageMsgPrintTimer = 0
local refineBoostsgPrintTimer = 0

framedeltas = framedeltas or {}

local TileDisplayEdgeCount = 5
local TileOffset = 0.5
local TileScaleThing = 64
local BarThinkness = 0.0025

local f_cloud_spawn_timer = 0
g_fant_cl_clouds = nil
local f_max_Clouds = 2000
local f_cloud_radius_distance = 2500
local f_cloud_height = 750
local f_cloud_main_Speed = 1

function SurvivalPlayer.sv_shape( self, data )
	if data.shapeType == "cube" or  data.shapeType == "hollowcube" then
		data.shape = sm.shape.createBlock( g_SelectedUUID, data.size, data.pos, sm.quat.identity(), 1, 1 )
	elseif data.shapeType == "sphere" or data.shapeType == "hollowsphere" then
		data.shape = sm.shape.createBlock( g_SelectedUUID, sm.vec3.new( data.size, data.size, data.size ), data.pos + sm.vec3.new( 0, 0, ( data.size / 4 ) * 0.25 ), sm.quat.identity(), 1, 1 )
	elseif data.shapeType == "cylinder" or data.shapeType == "hollowcylinder" then
		data.shape = sm.shape.createBlock( g_SelectedUUID, sm.vec3.new( data.radius * 2, data.radius * 2, data.height ), data.pos + sm.vec3.new( 0, 0, ( data.height / 4 ) * 0.25 ), sm.quat.identity(), 1, 1 )
	end
	self.network:sendToClient( data.player, "cl_cut", data )
end

function SurvivalPlayer.cl_cut( self, data )
	self.network:sendToServer( "sv_cut", data )
end

function SurvivalPlayer.sv_cut( self, data )
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

function SurvivalPlayer.sv_setRope( self, data )
	--print( "sv_setRope" )
	self.RopePosition = data.hitPos
	self.RopeTarget = data.targetShape
	self.ropeLocalPosition = nil
	if self.RopeTarget ~= nil then
		self.ropeLocalPosition = self.RopeTarget:transformPoint( self.RopePosition )
	end
	--print( "self.ropeLocalPosition: ", self.ropeLocalPosition )
end

function SurvivalPlayer.sv_removeRope( self )
	--print( "sv_removeRope" )
	self.RopePosition = nil
end

function SurvivalPlayer.cl_TileDisplay( self )
	local character = self.player:getCharacter()
	if character == nil then
		return
	end
	local HalfVec = sm.vec3.new( TileScaleThing, TileScaleThing, TileScaleThing ) / 2
	local RelativePlayerPosition = ( character.worldPosition ) / TileScaleThing
	local X = math.floor( RelativePlayerPosition.x ) * TileScaleThing
	local Y = math.floor( RelativePlayerPosition.y ) * TileScaleThing
	local Z = math.floor( RelativePlayerPosition.z ) * TileScaleThing
	local TileCenterPos = sm.vec3.new( X, Y, Z ) + HalfVec
	if showtile == false then
		if self.lastTileCenterPos ~= sm.vec3.new( 0, 0, 0 ) then
			self.lastTileCenterPos = sm.vec3.new( 0, 0, 0 )
			if self.tileBoxes ~= nil then
				if self.tileBoxes ~= {} then
					for i, k in pairs( self.tileBoxes ) do
						if k ~= nil then
							k:destroy()
						end
					end
				end
			end
			self.tileBoxes = {}
		end
	else
		if self.lastTileCenterPos ~= TileCenterPos then
			self.lastTileCenterPos = TileCenterPos
			if self.tileBoxes ~= nil then
				if self.tileBoxes ~= {} then
					for i, k in pairs( self.tileBoxes ) do
						if k ~= nil then
							k:destroy()
						end
					end
				end
			end
			self.tileBoxes = {}
			local zH = math.floor( TileDisplayEdgeCount / 2 )
			for z = -zH, zH do
				for x = -TileDisplayEdgeCount, TileDisplayEdgeCount do
					for y = -TileDisplayEdgeCount, TileDisplayEdgeCount do
						local arrayPos = ( sm.vec3.new( x + TileOffset, y + TileOffset, z + TileOffset ) * TileScaleThing ) 
						self:AddTileDisplayBar( TileCenterPos + arrayPos + ( sm.vec3.new( -1, 0, -1 ) * TileScaleThing * 0.5 ), sm.vec3.new( 1, BarThinkness, BarThinkness ), blk_spaceshipmetal )
						self:AddTileDisplayBar( TileCenterPos + arrayPos + ( sm.vec3.new( 0, -1, -1 ) * TileScaleThing * 0.5 ), sm.vec3.new( BarThinkness, 1, BarThinkness ), blk_spaceshipmetal )
						self:AddTileDisplayBar( TileCenterPos + arrayPos + ( sm.vec3.new( -1, -1, 0 ) * TileScaleThing       ), sm.vec3.new( BarThinkness, BarThinkness, 1 ), blk_spaceshipmetal )			
					end
				end
			end
		end
	end
end

function SurvivalPlayer.AddTileDisplayBar( self, pos, scale, uuid )
	local effect = sm.effect.createEffect( "ShapeRenderable" )				
	effect:setParameter( "uuid", blk_spaceshipmetal )
	effect:start()				
	effect:setPosition( pos )	
	effect:setScale( scale * TileScaleThing )
	table.insert( self.tileBoxes, effect )
end

function SurvivalPlayer.setGrabbedBody( self, data )
	self.GrabbedBody = data.body
	self.GrabbedDistance = data.distance
	self.GrabbedCharacter = data.character
end

function SurvivalPlayer.setDistance( self, distance )
	self.GrabbedDistance = distance
end

function SurvivalPlayer.setRotation( self, rotation )
	self.GrabbedRotation = rotation
end

function SurvivalPlayer.IgnoreFluid( self )
	self.ignoreFluid = 0.5
end

function SurvivalPlayer.ignoreSwimMode( self, dt )
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
			self.sv.saved.stats.breath = 100
		end
	end
end

function SurvivalPlayer.JumpBoostLoop( self, character )
	if self.sv.saved.stats.jumpboost == nil then
		self.sv.saved.stats.jumpboost = 0
	end
	if self.sv.saved.stats.jumpboost > 0 then
		self.sv.saved.stats.jumpboost = self.sv.saved.stats.jumpboost - (1 / 40)
		if self.sv.saved.stats.jumpboost <= 0 then
			self.sv.saved.stats.jumpboost = 0
		end
		local TimerLimit = 1	
		if self.sv.saved.stats.jumpboost >= 30 then
			TimerLimit = 15
		end

		
		jumpMsgPrintTimer = jumpMsgPrintTimer + (1 / 40)
		if jumpMsgPrintTimer >= TimerLimit then
			jumpMsgPrintTimer = 0
			self.network:sendToClients( "JumpBoost", self.sv.saved.stats.jumpboost )
			self:sv_SaveGlobalData( self.sv.saved.stats )
		end		
	end
end

function SurvivalPlayer.JumpBoost( self, value ) 
	if self.player == sm.localPlayer.getPlayer() then
		local duration = 1.25
		if value >= 20 then
			duration = 3
		end
		sm.gui.displayAlertText( "Jump Boost ends in " ..  tostring(math.floor(value)) .. " seconds!", duration )
	end
	
end

function SurvivalPlayer.Speed( self, character )
	if self.sv.saved.stats.speed == nil then
		self.sv.saved.stats.speed = 0
	end
	if self.sv.saved.stats.speed > 0 then
		self.sv.saved.stats.speed = self.sv.saved.stats.speed - (1 / 40)
		if self.sv.saved.stats.speed <= 0 then
			self.sv.saved.stats.speed = 0
		end
		character.movementSpeedFraction = Speed_Boost_Multiplicator
		
		speedMsgPrintTimer = speedMsgPrintTimer + (1 / 40)
		local TimerLimit = 1	
		if self.sv.saved.stats.speed >= 30 then
			TimerLimit = 15
		end
		if speedMsgPrintTimer >= TimerLimit then
			speedMsgPrintTimer = 0
			self.network:sendToClients( "SpeedBoost", self.sv.saved.stats.speed )
			self:sv_SaveGlobalData( self.sv.saved.stats )
		end		
	else
		character.movementSpeedFraction = 1.0
	end
end

function SurvivalPlayer.SpeedBoost( self, value ) 
	if self.player == sm.localPlayer.getPlayer() then
		local duration = 1.25
		if value >= 20 then
			duration = 3
		end
		sm.gui.displayAlertText( "Speed Boost ends in " ..  tostring(math.floor(value)) .. " seconds!", duration )
	end
end

function SurvivalPlayer.DamageBuffLoop( self, character )
	if self.sv.saved.stats.damagebuff == nil then
		self.sv.saved.stats.damagebuff = 0
	end
	if self.sv.saved.stats.damagebuff > 0 then
		self.sv.saved.stats.damagebuff = self.sv.saved.stats.damagebuff - (1 / 40)
		if self.sv.saved.stats.damagebuff <= 0 then
			self.sv.saved.stats.damagebuff = 0
		end
		damageMsgPrintTimer = damageMsgPrintTimer + (1 / 40)
		local TimerLimit = 1	
		if self.sv.saved.stats.damagebuff >= 30 then
			TimerLimit = 15
		end
		if damageMsgPrintTimer >= TimerLimit then
			damageMsgPrintTimer = 0
			self.network:sendToClients( "DamageBuff", self.sv.saved.stats.damagebuff )
			self:sv_SaveGlobalData( self.sv.saved.stats )
		end		
	end
end

function SurvivalPlayer.DamageBuff( self, value ) 
	if self.player == sm.localPlayer.getPlayer() then
		local duration = 1.25
		if value >= 20 then
			duration = 3
		end
		sm.gui.displayAlertText( "Damage Buff ends in " ..  tostring(math.floor(value)) .. " seconds!", duration )
	end
	
end

function SurvivalPlayer.RefineBuffLoop( self, character )
	if self.sv.saved.stats.refinebuff == nil then
		self.sv.saved.stats.refinebuff = 0
	end
	if self.sv.saved.stats.refinebuff > 0 then
		self.sv.saved.stats.refinebuff = self.sv.saved.stats.refinebuff - (1 / 40)
		if self.sv.saved.stats.refinebuff <= 0 then
			self.sv.saved.stats.refinebuff = 0
		end
		refineBoostsgPrintTimer = refineBoostsgPrintTimer + (1 / 40)
		local TimerLimit = 1	
		if self.sv.saved.stats.refinebuff >= 30 then
			TimerLimit = 15
		end
		if refineBoostsgPrintTimer >= TimerLimit then
			refineBoostsgPrintTimer = 0
			self.network:sendToClients( "RefineBuff", self.sv.saved.stats.refinebuff )
			self:sv_SaveGlobalData( self.sv.saved.stats )
		end		
	end
end

function SurvivalPlayer.RefineBuff( self, value ) 
	if self.player == sm.localPlayer.getPlayer() then
		local duration = 1.25
		if value >= 20 then
			duration = 3
		end
		sm.gui.displayAlertText( "Refine Buff ends in " ..  tostring(math.floor(value)) .. " seconds!", duration )
	end
	
end

function SurvivalPlayer.FantDisplay( self, character, dt )
	if self.FantDisplayUpdate == nil then
		self.FantDisplayUpdate = 0
	end
	self.FantDisplayUpdate = self.FantDisplayUpdate + dt
	if self.FantDisplayUpdate < 0.1 then
		return
	end
	self.FantDisplayUpdate = 0
	
	if g_survivalHud and FantHud then
		local TextData = tostring( "Time: " .. getTimeOfDayString() )  .. "\n"
		TextData = TextData .. getMods()
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
				
				if self.cl_playerScore == nil then
					self.cl_playerScore = { kills = 0, robotkills = 0, deaths = 0, wocs = 0 }
				end
				
				TextData = TextData .. "SCORE:\n"
				TextData = TextData .. "#ff0000Robots: #d3d3d3" .. tostring( self.cl_playerScore.robotkills ) .. "\n"
				TextData = TextData .. "#ffc0cbWoc´s: #d3d3d3" .. tostring( self.cl_playerScore.wocs ) .. "\n"
				TextData = TextData .. "#0000ffPlayer: #d3d3d3" .. tostring( self.cl_playerScore.kills ) .. "\n"
				TextData = TextData .. "#00ff00Deaths: #d3d3d3" .. tostring( self.cl_playerScore.deaths ) .. "\n"
			end
		end
		
		TextData = TextData .. "\n"
		if self.cl_cloth_damage_reduction ~= nil then
			TextData = TextData .. "#ffffffARMOR: #ff0000" .. tostring( self.cl_cloth_damage_reduction ) .. "#ffffff%\n"
		else
			TextData = TextData .. "#ffffffARMOR: #ff00000%\n"
		end
		TextData = TextData .. "#ffffff( #ff0000x#ffffff% less damage )\n"
		
		if self.cl_cloth_walk_speed ~= nil then
			TextData = TextData .. "#ffffffSPEED: #00ff00" .. tostring( self.cl_cloth_walk_speed ) .. "#ffffff%\n"
		else
			TextData = TextData .. "#ffffffSPEED: #00ff000%\n"
		end
		TextData = TextData .. "#ffffff( #00ff00x#ffffff% walk/run speed )\n"
		
		if self.cl_cloth_breath_value ~= nil then
			TextData = TextData .. "#ffffffBREATH: #0000ff" .. tostring( self.cl_cloth_breath_value ) .. "#ffffff%\n"
		else
			TextData = TextData .. "#ffffffBREATH: #0000ff0%\n"
		end
		TextData = TextData .. "#ffffff( #0000ffx#ffffff% more diving time )\n"
		
		-- if self.cl.stats.level ~= nil then
			-- TextData = TextData .. "\n\n\n\n#ffffffLEVEL: #ffffff" .. tostring( self.cl.stats.level ) .. "#ffffff\n"
		-- else
			-- TextData = TextData .. "#ffffffLEVEL: #ffffff0\n"
		-- end
		-- if self.cl.stats.experience ~= nil then
			-- TextData = TextData .. "#ffffffEXP: #ffffff" .. tostring( round( self.cl.stats.experience * 100000 ) / 1000000 ) .. "#ffffff\n"
		-- else
			-- TextData = TextData .. "#ffffffEXP: #ffffff0\n"
		-- end
		
		g_survivalHud:setText( "FantData", TextData )		
		
		g_survivalHud:setVisible( "EXP_BAR", fant_exp_bar_active )
		g_survivalHud:setVisible( "EXP_BAR_LEVEL", fant_exp_bar_active )
		
		if fant_exp_bar_active then
			local expValue = round( self.cl.stats.experience * 40 )
			if expValue < 0 then
				expValue = 0
			end
			if expValue > 40 then
				expValue = 40
			end
			g_survivalHud:setImage( "EXP_BAR_IMAGE", "fant_exp_bar_" ..  tostring( expValue ) .. ".png" )
		end
		g_survivalHud:setText( "EXP_BAR_LEVEL_TEXT", tostring( self.cl.stats.level ) )		
	else
		g_survivalHud:setText( "FantData", "" )	
		g_survivalHud:setVisible( "EXP_BAR", false )
		g_survivalHud:setVisible( "EXP_BAR_LEVEL", false )		
	end
end

function SurvivalPlayer.cl_DisplayPlayerName( self )
	if sm.localPlayer.getPlayer() == self.player then
		if self.cl_DisplayPlayerNameGUI then
			self.cl_DisplayPlayerNameGUI:close()
			self.cl_DisplayPlayerNameGUI = nil
		end
		--print( "sm.localPlayer.getPlayer() == self.player " )
		return
	end
	if ShowNameTag == false then
		if self.cl_DisplayPlayerNameGUI then
			self.cl_DisplayPlayerNameGUI:close()
			self.cl_DisplayPlayerNameGUI = nil
		end
		--print( "ShowNameTag == true " )
		return
	end
	local canShow = false
	if self.player.name == "" then
		canShow = false
	end
	if not Player_VS_Player or g_godMode then
		canShow = true
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
				self.cl_DisplayPlayerNameGUI:setMaxRenderDistance( 25000 )
				
				self.cl_DisplayPlayerNameGUI:setText( "Text", "#ffffff".. self.player.name )
			end
			if self.cl_DisplayPlayerNameGUI then
				self.cl_DisplayPlayerNameGUI:setWorldPosition( character:getWorldPosition() + sm.vec3.new( 0, 0, 1 ) )
			end
		end
	end
end

function SurvivalPlayer.client_onDestroy( self )
	if self.cl_DisplayPlayerNameGUI then
		self.cl_DisplayPlayerNameGUI:close()
		self.cl_DisplayPlayerNameGUI = nil
	end
end

function SurvivalPlayer.PlaceSoil( self, pos )
	local rot = math.random( 0, 3 ) * math.pi * 0.5
	sm.harvestable.create( hvs_soil, pos, sm.quat.angleAxis( rot, sm.vec3.new( 0, 0, 1 ) ) * sm.quat.new( 0.70710678, 0, 0, 0.70710678 ) )
	sm.effect.playEffect( "Plants - SoilbagUse", pos, nil, sm.quat.angleAxis( rot, sm.vec3.new( 0, 0, 1 ) ) * sm.quat.new( 0.70710678, 0, 0, 0.70710678 ) )
end

function SurvivalPlayer.Cleanup( self, radius )
	self.cleanup = true
	self.areaTrigger = sm.areaTrigger.createBox( sm.vec3.new( 1, 1, 1 ) * radius, self.player:getCharacter().worldPosition, sm.quat.identity(), sm.areaTrigger.filter.all )	
	print( "Cleanup Start!" )
end

function SurvivalPlayer.CleanupLoop( self, character )
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

function SurvivalPlayer.setPVP( self, pvp )
	Player_VS_Player = pvp
end

function SurvivalPlayer.getPVP( self )
	self.network:sendToClients( "setPVP", Player_VS_Player )
end

function SurvivalPlayer.sv_SaveGlobalData( self, stats )
	if stats == nil then 
		return
	end
	local ID = self.player:getId()
	g_Players[ID] = stats
	
	self.network:sendToClients( "cl_SaveGlobalData", stats )
end

function SurvivalPlayer.cl_SaveGlobalData( self, stats )
	local ID = self.player:getId()
	g_Players[ID] = stats
end

function SurvivalPlayer.sv_restorejumpboost( self, jumpboost )
	if self.sv.saved.isConscious then
		if self.sv.saved.stats.jumpboost == nil then
			self.sv.saved.stats.jumpboost = 0
			self.sv.saved.stats.maxjumpboost = 1000
		end
		if jumpboost == nil then
			jumpboost = 0
		end
		
		self.sv.saved.stats.jumpboost = self.sv.saved.stats.jumpboost + jumpboost
		self.sv.saved.stats.jumpboost = math.min( self.sv.saved.stats.jumpboost, self.sv.saved.stats.maxjumpboost )
		
		self.network:sendToClients( "JumpBoost", self.sv.saved.stats.jumpboost )
		print( "'SurvivalPlayer' restored:", jumpboost, "jumpboost." )
	end
end

function SurvivalPlayer.sv_restorespeed( self, speed )
	if self.sv.saved.isConscious then
		if self.sv.saved.stats.speed == nil then
			self.sv.saved.stats.speed = 0
			self.sv.saved.stats.maxspeed = 1000
		end
		if speed == nil then
			speed = 0
		end
		
		self.sv.saved.stats.speed = self.sv.saved.stats.speed + speed
		self.sv.saved.stats.speed = math.min( self.sv.saved.stats.speed, self.sv.saved.stats.maxspeed )
		
		self.network:sendToClients( "SpeedBoost", self.sv.saved.stats.speed )
		print( "'SurvivalPlayer' restored:", speed, "speed." )
	end
end

function SurvivalPlayer.damagebuff( self, damagebuff )
	if self.sv.saved.isConscious then
		if self.sv.saved.stats.damagebuff == nil then
			self.sv.saved.stats.damagebuff = 0
			self.sv.saved.stats.maxdamagebuff = 1000
		end
		if damagebuff == nil then
			damagebuff = 0
		end
		
		self.sv.saved.stats.damagebuff = self.sv.saved.stats.damagebuff + damagebuff
		self.sv.saved.stats.damagebuff = math.min( self.sv.saved.stats.damagebuff, self.sv.saved.stats.maxdamagebuff )
		
		self.network:sendToClients( "DamageBuff", self.sv.saved.stats.damagebuff )
		print( "'SurvivalPlayer' restored:", damagebuff, "damagebuff." )
	end
end

function SurvivalPlayer.refinebuff( self, refinebuff )
	if self.sv.saved.isConscious then
		if self.sv.saved.stats.refinebuff == nil then
			self.sv.saved.stats.refinebuff = 0
		end
		if self.sv.saved.stats.maxrefinebuff == nil then
			self.sv.saved.stats.maxrefinebuff = 1000
		end
		if refinebuff == nil then
			refinebuff = 0
		end
		
		self.sv.saved.stats.refinebuff = self.sv.saved.stats.refinebuff + refinebuff
		self.sv.saved.stats.refinebuff = math.min( self.sv.saved.stats.refinebuff, self.sv.saved.stats.maxrefinebuff )
		
		self.network:sendToClients( "RefineBuff", self.sv.saved.stats.refinebuff )
		print( "'SurvivalPlayer' restored:", refinebuff, "refinebuff." )
	end
end

function SurvivalPlayer.Fant_server_onFixedUpdate( self, dt )
	self:ignoreSwimMode( dt )
	local character = self.player:getCharacter()
	if character then
		if Player_VS_Player then
			ProcessTeslaDamage( self, true )  
			FlamethrowerDamage( self, dt )
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
		
		self:Speed( character )
		self:DamageBuffLoop( character )
		self:JumpBoostLoop( character )
		self:RefineBuffLoop( character )
		self:CleanupLoop( character )
		
		if character then
			if self.cloth_walk_speed ~= nil then
				if self.cloth_walk_speed ~= 0 then
					character.movementSpeedFraction = 1 + ( 2 * ( self.cloth_walk_speed / 100 ) )
					
				end
			end
		end
		
		if g_characters then
			for k, g_character in ipairs(g_characters) do
				if g_character == character then
					
					character.movementSpeedFraction = 3.5
					if character:isSprinting() then
						character.movementSpeedFraction = 20.0
					end
					self.sv.saved.stats.breath = self.sv.saved.stats.maxbreath
				end
			end
		end
		
		local ID = self.player:getId()
		if g_Players[ID] ~= nil then
			if g_Players[ID].jumpboost ~= nil then
				if g_Players[ID].jumpboost >= 1 then
					local Force = sm.vec3.new( 0, 0, Jump_Boost_Force )

					sm.physics.applyImpulse( character, Force, true, sm.vec3.new( 0, 0, 0 ) )
				end
			end
		end
		
		
		if self.RopePosition ~= nil and character then
			if not character:isTumbling() then
				local RopeDestination = self.RopePosition
				if self.RopeTarget ~= nil and sm.exists( self.RopeTarget ) then
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
		
	end
end

function SurvivalPlayer.Fant_sv_e_eat( self, edibleParams )
	if edibleParams.speed then
		self:sv_restorespeed( edibleParams.speed )
	end
	if edibleParams.damagebuff then
		self:damagebuff( edibleParams.damagebuff )
	end
	if edibleParams.jumpboost then
		self:sv_restorejumpboost( edibleParams.jumpboost )
	end
	if edibleParams.refineboost then
		self:refinebuff( edibleParams.refineboost )
	end
	self:sv_SaveGlobalData( self.sv.saved.stats )
end

function SurvivalPlayer.Fant_sv_n_revive( self, character )
	self.sv.saved.stats.speed = 0
	self.sv.saved.stats.damagebuff = 0
	self.sv.saved.stats.jumpboost = 0
	self.sv.saved.stats.refinebuff = 0
	self:sv_SaveGlobalData( self.sv.saved.stats )
	self.sv_fant_cloth_reset_timer = 10
end

function SurvivalPlayer.Fant_sv_onSpawnCharacter( self )
	self.sv.saved.stats.speed = 0
	self.sv.saved.stats.damagebuff = 0
	self.sv.saved.stats.jumpboost = 0
	self.sv.saved.stats.refinebuff = 0
	self:sv_SaveGlobalData( self.sv.saved.stats )
	self.sv_fant_cloth_reset_timer = 10
end

function SurvivalPlayer.Fant_sv_e_debug( self, params )
	if params.breath then
		self.sv.saved.stats.breath = params.breath
	end
end

function SurvivalPlayer.Fant_client_onInteract( self, state )
	self.GrabbedBody = nil
	self.GrabbedDistance = 0
	self.GrabbedCharacter = nil
	self.GrabLock = state
end

function SurvivalPlayer.Fant_sv_startTumble( self )
	-- 00Fant
	if self.sv ~= nil then
		if self.sv.stats ~= nil then
			if self.sv.stats.speed ~= nil then
				if self.sv.stats.speed > 0 then
					return true
				end
			end
		end
	end
	local character = self.player:getCharacter()
	if g_characters then
		for k, g_character in ipairs(g_characters) do
			if g_character == character then
				return true
			end
		end
	end
	if self.RopePosition ~= nil then
		return true
	end
	-- 00Fant
	return false
end

function SurvivalPlayer.sv_addKill( self, player )
	if self.sv.saved.playerScore == nil then
		self.sv.saved.playerScore = { kills = 0, robotkills = 0, deaths = 0, wocs = 0 }
	end
	self.sv.saved.playerScore.kills = self.sv.saved.playerScore.kills + 1
	self.network:sendToClient( player, "cl_setPlayerScore", self.sv.saved.playerScore )
	self.storage:save( self.sv.saved )
	
	self:sv_addExperience( Fant_EXP_gain_Player )
end

function SurvivalPlayer.sv_addWocKill( self, params )
	if self.sv.saved.playerScore == nil then
		self.sv.saved.playerScore = { kills = 0, robotkills = 0, deaths = 0, wocs = 0 }
	end
	self.sv.saved.playerScore.wocs = self.sv.saved.playerScore.wocs + 1
	self.network:sendToClient( params.attacker, "cl_setPlayerScore", self.sv.saved.playerScore )
	self.storage:save( self.sv.saved )
	
	self:sv_addExperience( Fant_EXP_gain_Woc )
end

function SurvivalPlayer.sv_addDeath( self, player )
	if self.sv.saved.playerScore == nil then
		self.sv.saved.playerScore = { kills = 0, robotkills = 0, deaths = 0, wocs = 0 }
	end
	self.sv.saved.playerScore.deaths = self.sv.saved.playerScore.deaths + 1
	self.network:sendToClient( player, "cl_setPlayerScore", self.sv.saved.playerScore )
	self.storage:save( self.sv.saved )
end

function SurvivalPlayer.sv_addRobotKill( self, params )
	if self.sv.saved.playerScore == nil then
		self.sv.saved.playerScore = { kills = 0, robotkills = 0, deaths = 0, wocs = 0 }
	end
	self.sv.saved.playerScore.robotkills = self.sv.saved.playerScore.robotkills + 1
	self.storage:save( self.sv.saved )

	if params ~= nil then
		if params.attacker ~= nil then
			self.network:sendToClient( params.attacker, "cl_setPlayerScore", self.sv.saved.playerScore )
		end
		if params.typeName ~= nil then
			if params.typeName == "totebot" then
				self:sv_addExperience( Fant_EXP_gain_Totebot )
			end
			if params.typeName == "heavytotebot" then
				self:sv_addExperience( Fant_EXP_gain_HeavyTotebot )
			end
			if params.typeName == "haybot" then
				self:sv_addExperience( Fant_EXP_gain_Haybot )
			end
			if params.typeName == "heavyhaybot" then
				self:sv_addExperience( Fant_EXP_gain_HeavyHaybot )
			end
			if params.typeName == "beebot" then
				self:sv_addExperience( Fant_EXP_gain_Beebot )
			end
			if params.typeName == "strawdog" then
				self:sv_addExperience( Fant_EXP_gain_Strawdog )
			end
			if params.typeName == "tapebot" then
				self:sv_addExperience( Fant_EXP_gain_Tapebot )
			end
			if params.typeName == "redtapebot" then
				self:sv_addExperience( Fant_EXP_gain_RedTapebot )
			end
			if params.typeName == "farmbot" then
				self:sv_addExperience( Fant_EXP_gain_Farmbot )
			end
		end
	end
end

function SurvivalPlayer.cl_setPlayerScore( self, score )
	self.cl_playerScore = score
end

function SurvivalPlayer.cl_fant_cloth_manager( self )	
	local character = self.player:getCharacter()
	
	self.cl_cloth_stats_bonus_health = 0
	self.cl_cloth_stats_bonus_food = 0
	self.cl_cloth_stats_bonus_thirst = 0
	self.cl_cloth_stats_bonus_loot = 0
	self.cl_cloth_stats_bonus_refine = 0
	self.cl_cloth_stats_bonus_farming = 0
	
	self.cl_cloth_damage_reduction = 0
	self.cl_cloth_walk_speed = 0
	self.cl_cloth_breath_value = 0
	
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
						if cloth.cl_state[ self.player:getId() ] == true then
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
								--self:cl_set_cloth( { add = true, character = character, cloth = cloth.male_rend } )
							else
								--character:addRenderable( cloth.female_rend )
								self.network:sendToServer( "sv_set_cloth", { add = true, character = character, cloth = cloth.female_rend } )
								--self:cl_set_cloth( { add = true, character = character, cloth = cloth.female_rend } )
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
								--self:cl_set_cloth( { remove = true, character = character, cloth = cloth.male_rend } )
							else
								--character:removeRenderable( cloth.female_rend )
								self.network:sendToServer( "sv_set_cloth", { remove = true, character = character, cloth = cloth.female_rend } )
								--self:cl_set_cloth( { remove = true, character = character, cloth = cloth.female_rend } )
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
						self.cl_cloth_stats_bonus_health = self.cl_cloth_stats_bonus_health + cloth.stats_bonus_health
						self.cl_cloth_stats_bonus_food = self.cl_cloth_stats_bonus_food + cloth.stats_bonus_food
						self.cl_cloth_stats_bonus_thirst = self.cl_cloth_stats_bonus_thirst + cloth.stats_bonus_thirst
						self.cl_cloth_stats_bonus_loot = self.cl_cloth_stats_bonus_loot + cloth.stats_bonus_loot
						self.cl_cloth_stats_bonus_refine = self.cl_cloth_stats_bonus_refine + cloth.stats_bonus_refine
						self.cl_cloth_stats_bonus_farming = self.cl_cloth_stats_bonus_farming + cloth.stats_bonus_farming		
						
						self.cl_cloth_damage_reduction = self.cl_cloth_damage_reduction + cloth.damage_reduction
						self.cl_cloth_walk_speed = self.cl_cloth_walk_speed + cloth.walk_speed
						self.cl_cloth_breath_value = self.cl_cloth_breath_value + cloth.breath_value
					end
				end
			end
		end
	end
end

function SurvivalPlayer.sv_fant_cloth_manager( self )	
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

function SurvivalPlayer.sv_extern_fant_cloth_reset( self )	
	self.sv_fant_cloth_reset_timer = 10
end

function SurvivalPlayer.sv_fant_cloth_reset( self, dt )	
	if self.sv_fant_cloth_reset_timer > 0 then
		self.sv_fant_cloth_reset_timer = self.sv_fant_cloth_reset_timer - dt
		if self.sv_fant_cloth_reset_timer <= 0 then
			for clothIndex, cloth in pairs( Fant_Cloth_Upgrades ) do
				cloth.sv_state[ self.player:getId() ] = false
				cloth.sv_laststate[ self.player:getId() ] = false
			end
			self.network:sendToClients( "cl_fant_cloth_reset", self.player )
			self.sv_fant_cloth_reset_timer = 30
			--print("SV Cloth Reset")
		end
		return
	end
end

function SurvivalPlayer.cl_fant_cloth_reset( self, player )	
	for clothIndex, cloth in pairs( Fant_Cloth_Upgrades ) do
		cloth.cl_state[ player:getId() ] = false
		cloth.cl_laststate[ player:getId() ] = false		
	end
	--print("CL Cloth Reset")
end

function SurvivalPlayer.sv_set_cloth( self, params )
	self.network:sendToClients( "cl_set_cloth", params )
end

function SurvivalPlayer.cl_set_cloth( self, params )
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

function SurvivalPlayer.cl_fant_clouds( self, dt )
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

function SurvivalPlayer.cl_addCloud( self, pos, spawn )
	local subOffset = 100
	for i = 1, math.random( 1, 7 ) do
		self:cl_subaddCloud( pos + sm.vec3.new( math.random( -subOffset, subOffset ), math.random( -subOffset, subOffset ), math.random( -subOffset, subOffset ) ), spawn )
	end
end

function SurvivalPlayer.cl_subaddCloud( self, pos, spawn ) 
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

function SurvivalPlayer.sv_addExperience( self, experience )
	local gain = ( ( experience / 100 ) / ( self.sv.saved.stats.level + ( self.sv.saved.stats.level * Fant_EXP_level_Malus ) ) )
	print( "EXP gain: ", experience )
	self.sv.saved.stats.experience = self.sv.saved.stats.experience + gain
	
	if self.sv.saved.stats.experience > 1 then
		self.sv.saved.stats.experience = 0
		self.sv.saved.stats.level = self.sv.saved.stats.level + 1
		self.sv.saved.stats.points = self.sv.saved.stats.points + Fant_EXP_level_Points
	end

	self.storage:save( self.sv.saved )
	self.network:sendToClient( self.player, "cl_setExpLevel", self.sv.saved.stats )
	self:sv_SaveGlobalData( self.sv.saved.stats )
end

function SurvivalPlayer.cl_setExpLevel( self, stats )
	self.cl.stats = stats
	self:cl_Update_Skills()
end

function SurvivalPlayer.sv_skill( self, params )
	self.network:sendToClient( params.player, "cl_skill", params )
end

function SurvivalPlayer.cl_skill( self, params )
	local path = "$GAME_DATA/Gui/Layouts/Fant_Level_Skills.layout"
	self.skillGui = sm.gui.createGuiFromLayout( path )
	
	self.skillGui:setButtonCallback( "LEVEL_SKILLS_HEALTH_UPGRADE", "cl_SkillButtonClick" )
	self.skillGui:setButtonCallback( "LEVEL_SKILLS_FOOD_UPGRADE", "cl_SkillButtonClick" )
	self.skillGui:setButtonCallback( "LEVEL_SKILLS_THIRST_UPGRADE", "cl_SkillButtonClick" )
	self.skillGui:setButtonCallback( "LEVEL_SKILLS_LOOT_UPGRADE", "cl_SkillButtonClick" )
	self.skillGui:setButtonCallback( "LEVEL_SKILLS_REFINE_UPGRADE", "cl_SkillButtonClick" )
	self.skillGui:setButtonCallback( "LEVEL_SKILLS_FARMING_UPGRADE", "cl_SkillButtonClick" )
	self.skillGui:setButtonCallback( "LEVEL_SKILLS_RESPEC", "cl_SkillButtonClick" )
	self.skillGui:setOnCloseCallback( "cl_onCloseSkills" )

	self.skillGui:open()
	
	self:cl_Update_Skills()
end

function SurvivalPlayer.cl_onCloseSkills( self )
	if self.skillGui ~= nil then
		self.skillGui:destroy()
		self.skillGui = nil
	end
end

function SurvivalPlayer.cl_SkillButtonClick( self, name )
	self.network:sendToServer( "sv_SkillButtonClick", name )
end

function SurvivalPlayer.sv_SkillButtonClick( self, name )
	if self.sv.saved.stats.points > 0 then
		if name == "LEVEL_SKILLS_HEALTH_UPGRADE" and self.sv.saved.stats.skill_health < 100 then
			self.sv.saved.stats.skill_health = self.sv.saved.stats.skill_health + 1
			self.sv.saved.stats.points = self.sv.saved.stats.points - 1
		end	
		if name == "LEVEL_SKILLS_FOOD_UPGRADE" and self.sv.saved.stats.skill_food < 100 then
			self.sv.saved.stats.skill_food = self.sv.saved.stats.skill_food + 1
			self.sv.saved.stats.points = self.sv.saved.stats.points - 1
		end
		if name == "LEVEL_SKILLS_THIRST_UPGRADE" and self.sv.saved.stats.skill_thirst < 100 then
			self.sv.saved.stats.skill_thirst = self.sv.saved.stats.skill_thirst + 1
			self.sv.saved.stats.points = self.sv.saved.stats.points - 1
		end
		if name == "LEVEL_SKILLS_LOOT_UPGRADE" and self.sv.saved.stats.skill_loot < 100 then
			self.sv.saved.stats.skill_loot = self.sv.saved.stats.skill_loot + 1
			self.sv.saved.stats.points = self.sv.saved.stats.points - 1
		end
		if name == "LEVEL_SKILLS_REFINE_UPGRADE" and self.sv.saved.stats.skill_refine < 100 then
			self.sv.saved.stats.skill_refine = self.sv.saved.stats.skill_refine + 1
			self.sv.saved.stats.points = self.sv.saved.stats.points - 1
		end
		if name == "LEVEL_SKILLS_FARMING_UPGRADE" and self.sv.saved.stats.skill_farming < 100 then
			self.sv.saved.stats.skill_farming = self.sv.saved.stats.skill_farming + 1
			self.sv.saved.stats.points = self.sv.saved.stats.points - 1
		end
	end
	
	if name == "LEVEL_SKILLS_RESPEC" and ( self.sv.saved.stats.level > 1 or self.sv.saved.stats.experience >= 0.5 ) then
		self.sv.saved.stats.experience = self.sv.saved.stats.experience - 0.5
		if self.sv.saved.stats.experience < 0 and self.sv.saved.stats.level > 1 then
			self.sv.saved.stats.experience = 0
			if self.sv.saved.stats.level > 1 then
				self.sv.saved.stats.experience = 1
				self.sv.saved.stats.level = self.sv.saved.stats.level - 1
			end
		end
		self.sv.saved.stats.skill_health = 0
		self.sv.saved.stats.skill_food = 0
		self.sv.saved.stats.skill_thirst = 0
		self.sv.saved.stats.skill_loot = 0
		self.sv.saved.stats.skill_refine = 0
		self.sv.saved.stats.skill_farming = 0
		self.sv.saved.stats.points = self.sv.saved.stats.level * Fant_EXP_level_Points
	end
		
	self.storage:save( self.sv.saved )
	
	self:sv_SaveGlobalData( self.sv.saved.stats )
	self.network:sendToClient( self.player, "cl_setExpLevel", self.sv.saved.stats )
	
end

function SurvivalPlayer.cl_Update_Skills( self )
	if self.skillGui ~= nil then
		if self.cl_cloth_stats_bonus_health == nil then
			self.cl_cloth_stats_bonus_health = 0
		end
		if self.cl_cloth_stats_bonus_food == nil then
			self.cl_cloth_stats_bonus_food = 0
		end
		if self.cl_cloth_stats_bonus_thirst == nil then
			self.cl_cloth_stats_bonus_thirst = 0
		end
		if self.cl_cloth_stats_bonus_loot == nil then
			self.cl_cloth_stats_bonus_loot = 0
		end
		if self.cl_cloth_stats_bonus_refine == nil then
			self.cl_cloth_stats_bonus_refine = 0
		end
		if self.cl_cloth_stats_bonus_farming == nil then
			self.cl_cloth_stats_bonus_farming = 0
		end
		
		self.skillGui:setText( "LEVEL_SKILLS_NAME", self.player.name )
		self.skillGui:setText( "LEVEL_SKILLS_LEVELNUMBER"	, tostring( self.cl.stats.level ) )
		self.skillGui:setText( "LEVEL_SKILLS_POINTSNUMBER"	, tostring( self.cl.stats.points ) )
		
		self.skillGui:setText( "LEVEL_SKILLS_HEALTHNUMBER"	, tostring( self.cl.stats.skill_health + self.cl_cloth_stats_bonus_health ) )
		self.skillGui:setText( "LEVEL_SKILLS_FOODNUMBER"	, tostring( self.cl.stats.skill_food + self.cl_cloth_stats_bonus_food ) )
		self.skillGui:setText( "LEVEL_SKILLS_THIRSTNUMBER"	, tostring( self.cl.stats.skill_thirst + self.cl_cloth_stats_bonus_thirst ) )
		self.skillGui:setText( "LEVEL_SKILLS_LOOTNUMBER"	, tostring( self.cl.stats.skill_loot + self.cl_cloth_stats_bonus_loot ) )
		self.skillGui:setText( "LEVEL_SKILLS_REFINENUMBER"	, tostring( self.cl.stats.skill_refine + self.cl_cloth_stats_bonus_refine ) )
		self.skillGui:setText( "LEVEL_SKILLS_FARMINGNUMBER"	, tostring( self.cl.stats.skill_farming + self.cl_cloth_stats_bonus_farming ) )
	end
end

function SurvivalPlayer.sv_setLevel( self, level )
	self.sv.saved.stats.level = level
	self.sv.saved.stats.points = self.sv.saved.stats.level * Fant_EXP_level_Points
	
	self.sv.saved.stats.skill_health = 0
	self.sv.saved.stats.skill_food = 0
	self.sv.saved.stats.skill_thirst = 0
	self.sv.saved.stats.skill_loot = 0
	self.sv.saved.stats.skill_refine = 0
	self.sv.saved.stats.skill_farming = 0
	
	self.storage:save( self.sv.saved )
	
	self:sv_SaveGlobalData( self.sv.saved.stats )
	self.network:sendToClient( self.player, "cl_setExpLevel", self.sv.saved.stats )
	
end
-- 00Fant



local StatsTickRate = 40

local PerSecond = StatsTickRate / 40
local PerMinute = StatsTickRate / ( 40 * 60 )

local FoodRecoveryThreshold = 5 -- Recover hp when food is above this value
local FastFoodRecoveryThreshold = 50 -- Recover hp fast when food is above this value
local HpRecovery = 50 * PerMinute
local FastHpRecovery = 75 * PerMinute
local FoodCostPerHpRecovery = 0.2
local FastFoodCostPerHpRecovery = 0.2

local FoodCostPerStamina = 0.02
local WaterCostPerStamina = 0.1
local SprintStaminaCost = 0.7 / 40 -- Per tick while sprinting
local CarryStaminaCost = 1.4 / 40 -- Per tick while carrying

local FoodLostPerSecond = 100 / 3.5 / 24 / 60
local WaterLostPerSecond = 100 / 2.5 / 24 / 60

local BreathLostPerTick = ( 100 / 60 ) / 40

local FatigueDamageHp = 1 * PerSecond
local FatigueDamageWater = 2 * PerSecond
local FireDamage = 10
local FireDamageCooldown = 40
local DrownDamage = 5
local DrownDamageCooldown = 40
local PoisonDamage = 10
local PoisonDamageCooldown = 40

local RespawnTimeout = 60 * 40

local RespawnFadeDuration = 0.45
local RespawnEndFadeDuration = 0.45

local RespawnFadeTimeout = 5.0
local RespawnDelay = RespawnFadeDuration * 40
local RespawnEndDelay = 1.0 * 40

local BaguetteSteps = 9

local StopTumbleTimerTickThreshold = 1.0 * 40 -- Time to keep tumble active after speed is below threshold
local MaxTumbleTimerTickThreshold = 20.0 * 40 -- Maximum time to keep tumble active before timing out
local TumbleResistTickTime = 3.0 * 40 -- Time that the player will resist tumbling after timing out
local MaxTumbleImpulseSpeed = 35
local RecentTumblesTickTimeInterval = 30.0 * 40 -- Time frame to count amount of tumbles in a row
local MaxRecentTumbles = 3

function SurvivalPlayer.server_onCreate( self )
	self.sv = {}
	self.sv.saved = self.storage:load()
	if self.sv.saved == nil then
		self.sv.saved = {}
		self.sv.saved.stats = {
			hp = 100, maxhp = 100,
			food = 100, maxfood = 100,
			water = 100, maxwater = 100,
			
			-- 00Fant
			breath = 100, maxbreath = 100,
			speed = 0, maxspeed = 1000,
			damagebuff = 0, maxdamagebuff = 1000,
			jumpboost = 0, maxjumpboost = 1000,
			refinebuff = 0, maxrefinebuff = 1000
			-- 00Fant
		}
		self.sv.saved.isConscious = true
		self.sv.saved.hasRevivalItem = false
		self.sv.saved.isNewPlayer = true
		self.sv.saved.inChemical = false
		self.sv.saved.inOil = false
		
		-- 00Fant
		self.sv.saved.playerScore = { kills = 0, robotkills = 0, deaths = 0, wocs = 0 }
		-- 00Fant
		
		self.storage:save( self.sv.saved )
	end
	
	-- 00Fant
	local doASave = false
	if self.sv.saved.stats.experience == nil then
		self.sv.saved.stats.experience = 0
		doASave = true
	end
	if self.sv.saved.stats.level == nil then
		self.sv.saved.stats.level = 1
		doASave = true
	end
	if self.sv.saved.stats.level < 1 then
		self.sv.saved.stats.level = 1
		doASave = true
	end
	if self.sv.saved.stats.points == nil then
		self.sv.saved.stats.points = 5
		doASave = true
	end
	
	
	-- SKILLS
	
	if self.sv.saved.stats.skill_health == nil then
		self.sv.saved.stats.skill_health = 0
		doASave = true
	end
	
	if self.sv.saved.stats.skill_food == nil then
		self.sv.saved.stats.skill_food = 0
		doASave = true
	end
	
	if self.sv.saved.stats.skill_thirst == nil then
		self.sv.saved.stats.skill_thirst = 0
		doASave = true
	end
	
	if self.sv.saved.stats.skill_loot == nil then
		self.sv.saved.stats.skill_loot = 0
		doASave = true
	end
	
	if self.sv.saved.stats.skill_refine == nil then
		self.sv.saved.stats.skill_refine = 0
		doASave = true
	end
	
	if self.sv.saved.stats.skill_farming == nil then
		self.sv.saved.stats.skill_farming = 0
		doASave = true
	end
	
	
	if self.sv.saved.playerScore == nil then
		self.sv.saved.playerScore = { kills = 0, robotkills = 0, deaths = 0, wocs = 0 }
		doASave = true
	end
	
	if doASave then
		self.storage:save( self.sv.saved )
	end
	self.network:sendToClient( self.player, "cl_setPlayerScore", self.sv.saved.playerScore )
	
	self.sv.saved.stats.speed = 0
	self.sv.saved.stats.damagebuff = 0
	self.sv.saved.stats.jumpboost = 0
	self.sv.saved.stats.refinebuff = 0
	self:sv_SaveGlobalData( self.sv.saved.stats )
	self.sv_fant_cloth_reset_timer = 10

	-- 00Fant
	
	self:sv_init()
end

function SurvivalPlayer.server_onRefresh( self )
	self:sv_init()
end

function SurvivalPlayer.sv_init( self )
	self.sv.staminaSpend = 0
	self.sv.blocking = false

	self.sv.statsTimer = Timer()
	self.sv.statsTimer:start( StatsTickRate )

	self.sv.damageCooldown = Timer()
	self.sv.damageCooldown:start( 3.0 * 40 )

	self.sv.impactCooldown = Timer()
	self.sv.impactCooldown:start( 3.0 * 40 )

	self.sv.fireDamageCooldown = Timer()
	self.sv.fireDamageCooldown:start()

	self.sv.poisonDamageCooldown = Timer()
	self.sv.poisonDamageCooldown:start()

	self.sv.drownTimer = Timer()
	self.sv.drownTimer:stop()

	self.sv.tumbleReset = Timer()
	self.sv.tumbleReset:start( StopTumbleTimerTickThreshold )

	self.sv.maxTumbleTimer = Timer()
	self.sv.maxTumbleTimer:start( MaxTumbleTimerTickThreshold )

	self.sv.resistTumbleTimer = Timer()
	self.sv.resistTumbleTimer:start( TumbleResistTickTime )
	self.sv.resistTumbleTimer.count = TumbleResistTickTime

	self.sv.recentTumbles = {}

	self.sv.spawnparams = {}

	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.server_onDestroy( self )

	-- TODO: make this work
	self.storage:save( self.sv.saved )
end

function SurvivalPlayer.client_onCreate( self )
	self.cl = {}
	if self.player == sm.localPlayer.getPlayer() then
		if g_survivalHud then
			g_survivalHud:open()
		end

		self.cl.hungryEffect = sm.effect.createEffect( "Mechanic - StatusHungry" )
		self.cl.thirstyEffect = sm.effect.createEffect( "Mechanic - StatusThirsty" )
		self.cl.underwaterEffect = sm.effect.createEffect( "Mechanic - StatusUnderwater" )
		
		-- 00Fant
		self.cl_playerScore = { kills = 0, robotkills = 0, deaths = 0, wocs = 0 }
		-- 00Fant
	end
	
	
	self:cl_init()
end

function SurvivalPlayer.client_onRefresh( self )
	self:cl_init()

	sm.gui.hideGui( false )
	sm.camera.setCameraState( sm.camera.state.default )
	sm.localPlayer.setLockedControls( false )
end

function SurvivalPlayer.cl_init(self)
	self.useCutsceneCamera = false
	self.progress = 0
	self.nodeIndex = 1
	self.currentCutscene = {}

	self.cl.revivalChewCount = 0
end

function SurvivalPlayer.cl_n_onEvent( self, data )

	local function getCharParam()
		if self.player:isMale() then
			return 1
		else
			return 2
		end
	end

	local function playSingleHurtSound( effect, pos, damage )
		local params = {
			["char"] = getCharParam(),
			["damage"] = damage
		}
		sm.effect.playEffect( effect, pos, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), params )
	end

	if data.event == "drown" then
		playSingleHurtSound( "Mechanic - HurtDrown", data.pos, data.damage )
	elseif data.event == "fatigue" then
		playSingleHurtSound( "Mechanic - Hurthunger", data.pos, data.damage)
	elseif data.event == "shock" then
		playSingleHurtSound( "Mechanic - Hurtshock", data.pos, data.damage )
	elseif data.event == "impact" then
		playSingleHurtSound( "Mechanic - Hurt", data.pos, data.damage )
	elseif data.event == "fire" then
		playSingleHurtSound( "Mechanic - HurtFire", data.pos, data.damage )
	elseif data.event == "poison" then
		playSingleHurtSound( "Mechanic - Hurtpoision", data.pos, data.damage )
	end
end

function SurvivalPlayer.client_onClientDataUpdate( self, data )
	if sm.localPlayer.getPlayer() == self.player then

		if self.cl.stats == nil then self.cl.stats = data.stats end -- First time copy to avoid nil errors

		if g_survivalHud then
			g_survivalHud:setSliderData( "Health", data.stats.maxhp * 10 + 1, data.stats.hp * 10 )
			g_survivalHud:setSliderData( "Food", data.stats.maxfood * 10 + 1, data.stats.food * 10 )
			g_survivalHud:setSliderData( "Water", data.stats.maxwater * 10 + 1, data.stats.water * 10 )
			g_survivalHud:setSliderData( "Breath", data.stats.maxbreath * 10 + 1, data.stats.breath * 10 )
		end

		if self.cl.hasRevivalItem ~= data.hasRevivalItem then
			self.cl.revivalChewCount = 0
		end

		if self.player.character then
			local charParam = self.player:isMale() and 1 or 2
			self.cl.underwaterEffect:setParameter( "char", charParam )
			self.cl.hungryEffect:setParameter( "char", charParam )
			self.cl.thirstyEffect:setParameter( "char", charParam )

			if data.stats.breath <= 15 and not self.cl.underwaterEffect:isPlaying() and data.isConscious then
				self.cl.underwaterEffect:start()
			elseif ( data.stats.breath > 15 or not data.isConscious ) and self.cl.underwaterEffect:isPlaying() then
				self.cl.underwaterEffect:stop()
			end
			if data.stats.food <= 5 and not self.cl.hungryEffect:isPlaying() and data.isConscious then
				self.cl.hungryEffect:start()
			elseif ( data.stats.food > 5 or not data.isConscious ) and self.cl.hungryEffect:isPlaying() then
				self.cl.hungryEffect:stop()
			end
			if data.stats.water <= 5 and not self.cl.thirstyEffect:isPlaying() and data.isConscious then
				self.cl.thirstyEffect:start()
			elseif ( data.stats.water > 5 or not data.isConscious ) and self.cl.thirstyEffect:isPlaying() then
				self.cl.thirstyEffect:stop()
			end
		end

		if data.stats.food <= 5 and self.cl.stats.food > 5 then
			sm.gui.displayAlertText( "#{ALERT_HUNGER}", 5 )
		end
		if data.stats.water <= 5 and self.cl.stats.water > 5 then
			sm.gui.displayAlertText( "#{ALERT_THIRST}", 5 )
		end

		if data.stats.hp < self.cl.stats.hp and data.stats.breath == 0 then
			sm.gui.displayAlertText( "#{DAMAGE_BREATH}", 1 )
		elseif data.stats.hp < self.cl.stats.hp and data.stats.food == 0 then
			sm.gui.displayAlertText( "#{DAMAGE_HUNGER}", 1 )
		elseif data.stats.hp < self.cl.stats.hp and data.stats.water == 0 then
			sm.gui.displayAlertText( "#{DAMAGE_THIRST}", 1 )
		end

		self.cl.stats = data.stats
		self.cl.isConscious = data.isConscious
		self.cl.hasRevivalItem = data.hasRevivalItem
		self.cl.inChemical = data.inChemical
		self.cl.inOil = data.inOil

		sm.localPlayer.setBlockSprinting( data.stats.food == 0 or data.stats.water == 0 )
	end
end

function SurvivalPlayer.client_onUpdate( self, dt )
	-- 00Fant	
		self:cl_fant_clouds( dt )
		self:cl_DisplayPlayerName()
		self:cl_fant_cloth_manager()
	-- 00Fant
	if self.player == sm.localPlayer.getPlayer() then
		self:cl_localPlayerUpdate( dt )
	end
end

function SurvivalPlayer.cl_localPlayerUpdate( self, dt )
	self:cl_updateCamera( dt )

	local character = self.player:getCharacter()
	if character and not self.cl.isConscious then
		local keyBindingText =  sm.gui.getKeyBinding( "Use" )
		if self.cl.hasRevivalItem then
			if self.cl.revivalChewCount < BaguetteSteps then
				-- sm.gui.setInteractionText( "#{INTERACTION_PRESS}", keyBindingText, "to eat ("..self.cl.revivalChewCount.."/10)" )
				sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_EAT} ("..self.cl.revivalChewCount.."/10)" )
			else
				sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_REVIVE}" )
			end
		else
			sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_RESPAWN}" )
		end
	end

	if character and character:isTumbling() then
		if sm.camera.getCameraState() == sm.camera.state.default then
			sm.camera.setCameraState( sm.camera.state.forcedTP )
			self.cl.tumbleCamera = true
		end
	elseif self.cl.tumbleCamera then
		if sm.camera.getCameraState() == sm.camera.state.default then
			self.cl.tumbleCamera = false
		elseif sm.camera.getCameraState() == sm.camera.state.forcedTP then
			sm.camera.setCameraState( sm.camera.state.default )
			self.cl.tumbleCamera = false
		end
	end

	if character and character:isSwimming() and not self.cl.inChemical and not self.cl.inOil then
		self:cl_n_fillWater()
	end

	if character then
		self.cl.underwaterEffect:setPosition( character.worldPosition )
		self.cl.hungryEffect:setPosition( character.worldPosition )
		self.cl.thirstyEffect:setPosition( character.worldPosition )
		
		
		-- 00Fant
			self:FantDisplay( character, dt )
			self:cl_TileDisplay()
		-- 00Fant
	end
end

function SurvivalPlayer.client_onInteract( self, character, state )
	
	-- 00Fant
	self:Fant_client_onInteract( state )
	-- 00Fant
	
	if state == true then
		--self:cl_startCutscene( camera_test )
		--self:cl_startCutscene( camera_test_joint )
		--self:cl_startCutscene( camera_wakeup_ground )
		--self:cl_startCutscene( camera_approach_crash )
		--self:cl_startCutscene( camera_wakeup_crash )
		--self:cl_startCutscene( camera_wakeup_bed )

		if not self.cl.isConscious then
			if self.cl.hasRevivalItem then
				if self.cl.revivalChewCount >= BaguetteSteps then
					self.network:sendToServer( "sv_n_revive" )
				end
				self.cl.revivalChewCount = self.cl.revivalChewCount + 1
				self.network:sendToServer( "sv_onEvent", { type = "character", data = "chew" } )
			else
				self.network:sendToServer( "sv_n_try_respawn" )
			end
		end
	end
end

function SurvivalPlayer.server_onFixedUpdate( self, dt )
	if g_survivalDev and not self.sv.saved.isConscious and not self.sv.saved.hasRevivalItem then
		if sm.container.canSpend( self.player:getInventory(), obj_consumable_longsandwich, 1 ) then
			if sm.container.beginTransaction() then
				sm.container.spend( self.player:getInventory(), obj_consumable_longsandwich, 1, true )
				if sm.container.endTransaction() then
					self.sv.saved.hasRevivalItem = true
					self.player:sendCharacterEvent( "baguette" )
					self.network:setClientData( self.sv.saved )
				end
			end
		end
	end

	local character = self.player:getCharacter()
	if character then
		self:sv_updateTumbling()
	end

	-- Delays the respawn so clients have time to fade to black
	if self.sv.respawnDelayTimer then
		self.sv.respawnDelayTimer:tick()
		if self.sv.respawnDelayTimer:done() then
			self:sv_e_respawn()
			self.sv.respawnDelayTimer = nil
		end
	end

	-- End of respawn sequence
	if self.sv.respawnEndTimer then
		self.sv.respawnEndTimer:tick()
		if self.sv.respawnEndTimer:done() then
			self.network:sendToClient( self.player, "cl_n_endFadeToBlack", { duration = RespawnEndFadeDuration } )
			self.sv.respawnEndTimer = nil;
		end
	end

	-- If respawn failed, restore the character
	if self.sv.respawnTimeoutTimer then
		self.sv.respawnTimeoutTimer:tick()
		if self.sv.respawnTimeoutTimer:done() then
			self:sv_onSpawnCharacter()
		end
	end

	self.sv.damageCooldown:tick()
	self.sv.impactCooldown:tick()
	self.sv.fireDamageCooldown:tick()
	self.sv.poisonDamageCooldown:tick()

	-- Update breathing
	if character then
		if character:isDiving() then
		
			-- 00Fant
			local breathMul = 1
			if self.cloth_breath_value ~= nil then
				breathMul = 1 - ( self.cloth_breath_value / 100 )
			end
			self.sv.saved.stats.breath = math.max( self.sv.saved.stats.breath - ( BreathLostPerTick * breathMul ), 0 )
			-- 00Fant
			
			if self.sv.saved.stats.breath == 0 then
				self.sv.drownTimer:tick()
				if self.sv.drownTimer:done() then
					if self.sv.saved.isConscious then
						print( "'SurvivalPlayer' is drowning!" )
						self:sv_takeDamage( DrownDamage, "drown" )
					end
					self.sv.drownTimer:start( DrownDamageCooldown )
				end
			end
			ExtinguishFire( self )
		else
			self.sv.saved.stats.breath = self.sv.saved.stats.maxbreath
			self.sv.drownTimer:start( DrownDamageCooldown )
		end

		-- Spend stamina on sprinting
		if character:isSprinting() then
			self.sv.staminaSpend = self.sv.staminaSpend + SprintStaminaCost
		end

		-- Spend stamina on carrying
		if not self.player:getCarry():isEmpty() then
			self.sv.staminaSpend = self.sv.staminaSpend + CarryStaminaCost
		end
		
	end

	-- Update stamina, food and water stats
	if character and self.sv.saved.isConscious and not g_godMode then
		self.sv.statsTimer:tick()
		if self.sv.statsTimer:done() then
			self.sv.statsTimer:start( StatsTickRate )

			-- Recover health from food
			if self.sv.saved.stats.food > FoodRecoveryThreshold then
				local fastRecoveryFraction = 0

				-- Fast recovery when food is above fast threshold
				if self.sv.saved.stats.food > FastFoodRecoveryThreshold then
					local recoverableHp = math.min( self.sv.saved.stats.maxhp - self.sv.saved.stats.hp, FastHpRecovery )
					local foodSpend = math.min( recoverableHp * FastFoodCostPerHpRecovery, math.max( self.sv.saved.stats.food - FastFoodRecoveryThreshold, 0 ) )
					local recoveredHp = foodSpend / FastFoodCostPerHpRecovery

					self.sv.saved.stats.hp = math.min( self.sv.saved.stats.hp + recoveredHp, self.sv.saved.stats.maxhp )
					self.sv.saved.stats.food = self.sv.saved.stats.food - foodSpend
					fastRecoveryFraction = ( recoveredHp ) / FastHpRecovery
				end

				-- Normal recovery
				local recoverableHp = math.min( self.sv.saved.stats.maxhp - self.sv.saved.stats.hp, HpRecovery * ( 1 - fastRecoveryFraction ) )
				local foodSpend = math.min( recoverableHp * FoodCostPerHpRecovery, math.max( self.sv.saved.stats.food - FoodRecoveryThreshold, 0 ) )
				local recoveredHp = foodSpend / FoodCostPerHpRecovery

				self.sv.saved.stats.hp = math.min( self.sv.saved.stats.hp + foodSpend / FoodCostPerHpRecovery, self.sv.saved.stats.maxhp )
				self.sv.saved.stats.food = self.sv.saved.stats.food - foodSpend
			end

			-- Spend water and food on stamina usage
			self.sv.saved.stats.water = math.max( self.sv.saved.stats.water - self.sv.staminaSpend * WaterCostPerStamina, 0 )
			self.sv.saved.stats.food = math.max( self.sv.saved.stats.food - self.sv.staminaSpend * FoodCostPerStamina, 0 )
			self.sv.staminaSpend = 0
			
			-- 00Fant
			
			-- Decrease food and water with time
			if self.sv_cloth_stats_bonus_food == nil then
				self.sv_cloth_stats_bonus_food = 0
			end
			if self.sv_cloth_stats_bonus_thirst == nil then
				self.sv_cloth_stats_bonus_thirst = 0
			end
			local FoodSkill = ( ( 1 - ( ( self.sv.saved.stats.skill_food + self.sv_cloth_stats_bonus_food ) / 100 ) ) * 0.75 ) + 0.25
			local ThirstSkill = ( ( 1 - ( ( self.sv.saved.stats.skill_thirst + self.sv_cloth_stats_bonus_thirst ) / 100 ) ) * 0.75 ) + 0.25
			self.sv.saved.stats.food = math.max( self.sv.saved.stats.food - ( FoodLostPerSecond * FoodSkill ), 0 )
			self.sv.saved.stats.water = math.max( self.sv.saved.stats.water - ( WaterLostPerSecond * ThirstSkill ), 0 )
			
			-- 00Fant
			
			local fatigueDamageFromHp = false
			if self.sv.saved.stats.food <= 0 then
				self:sv_takeDamage( FatigueDamageHp, "fatigue" )
				fatigueDamageFromHp = true
			end
			if self.sv.saved.stats.water <= 0 then
				if not fatigueDamageFromHp then
					self:sv_takeDamage( FatigueDamageWater, "fatigue" )
				end
			end

			self.storage:save( self.sv.saved )
			self.network:setClientData( self.sv.saved )
			
			
			-- 00Fant
			self:sv_SaveGlobalData( self.sv.saved.stats )
			
		end
	end
	
	-- 00Fant
	self:sv_fant_cloth_reset( dt )
	self:sv_fant_cloth_manager()
	self:Fant_server_onFixedUpdate( dt )
	-- 00Fant
end

function SurvivalPlayer.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	-- 00Fant
	if type( attacker ) == "Unit" or ( type( attacker ) == "Shape" and isTrapProjectile( projectileName ) ) then
		self:sv_takeDamage( damage, "shock" )
	else
		if Player_VS_Player then
			self:sv_takeDamage( damage, "impact" )
		end
	end
	-- 00Fant

	if self.player.character:isTumbling() then
		ApplyKnockback( self.player.character, hitVelocity:normalize(), 2000 )
	end

	if projectileName == "water"  then
		self.network:sendToClient( self.player, "cl_n_fillWater" )
		ExtinguishFire( self )
	end
end

function SurvivalPlayer.cl_n_fillWater( self )
	if self.player == sm.localPlayer.getPlayer() then
		if sm.localPlayer.getActiveItem() == obj_tool_bucket_empty then
			local params = {}
			params.playerInventory = sm.localPlayer.getInventory()
			params.slotIndex = sm.localPlayer.getSelectedHotbarSlot()
			params.previousUid = obj_tool_bucket_empty
			params.nextUid = obj_tool_bucket_water
			params.previousQuantity = 1
			params.nextQuantity = 1
			self.network:sendToServer( "sv_n_exchangeItem", params )
		end
	end
end

function SurvivalPlayer.sv_updateBlocking( self, blocking )
	self.sv.blocking = blocking
end

function SurvivalPlayer.server_onMelee( self, hitPos, attacker, damage, power )
	if not sm.exists( attacker ) then
		return
	end
	local attackingCharacter = attacker:getCharacter()
	local playerCharacter = self.player:getCharacter()
	if attackingCharacter ~= nil and playerCharacter ~= nil then
		local attackDirection = ( hitPos - attackingCharacter.worldPosition ):normalize()
		local directionDiff = ( attackDirection - playerCharacter:getDirection() ):length()
		local directionDiffThreshold = 1.6
		if directionDiff >= directionDiffThreshold and self.sv.blocking == true then
			print("'SurvivalPlayer' blocked melee damage")
			sm.effect.playEffect( "SledgehammerHit - Default", playerCharacter.worldPosition + sm.vec3.new( 0, 0, 0.5 ) - ( attackDirection - playerCharacter:getDirection() ) * 0.25 )
		else
			print("'SurvivalPlayer' took melee damage")
			if type( attacker ) == "Unit" then
				self:sv_takeDamage( damage, "impact" )
			else
				
				-- 00Fant
				if Player_VS_Player then
					self:sv_takeDamage( damage, "impact" )
				end
				-- 00Fant
				
				self.network:sendToClients( "cl_n_onEvent", { event = "impact", pos = playerCharacter:getWorldPosition(), damage = damage * 0.01 } )
			end

			-- Melee impulse
			if attacker then
				ApplyKnockback( self.player.character, attackDirection, power )
			end
		end
	end
end

function SurvivalPlayer.server_onExplosion( self, center, destructionLevel )
	print("'SurvivalPlayer' took explosion damage")
	
	print( "\ndestructionLevel: ", destructionLevel , "\n" )
	
	-- 00Fant
	self:sv_takeDamage( destructionLevel * 5, "impact" )
	-- 00Fant
	
	if self.player.character:isTumbling() then
		local knockbackDirection = ( self.player.character.worldPosition - center ):normalize()
		ApplyKnockback( self.player.character, knockbackDirection, 5000 )
	end
end

function SurvivalPlayer.sv_startTumble( self, tumbleTickTime )
	
	-- 00Fant
	if self:Fant_sv_startTumble() then
		return
	end
	-- 00Fant
	
	if not self.player.character:isDowned() and self.sv.resistTumbleTimer:done() then
		local currentTick = sm.game.getCurrentTick()
		self.sv.recentTumbles[#self.sv.recentTumbles+1] = currentTick
		local recentTumbles = {}
		for _, tumbleTickTimestamp in ipairs( self.sv.recentTumbles ) do
			if tumbleTickTimestamp >= currentTick - RecentTumblesTickTimeInterval then
				recentTumbles[#recentTumbles+1] = tumbleTickTimestamp
			end
		end
		self.sv.recentTumbles = recentTumbles
		if #self.sv.recentTumbles > MaxRecentTumbles then
			-- Too many tumbles in quick succession, gain temporary tumble immunity
			self.player.character:setTumbling( false )
			self.sv.maxTumbleTimer:reset()
			self.sv.tumbleReset:reset()
			self.sv.resistTumbleTimer:reset()
		else
			self.player.character:setTumbling( true )
			if tumbleTickTime then
				self.sv.tumbleReset:start( tumbleTickTime )
			else
				self.sv.tumbleReset:start( StopTumbleTimerTickThreshold )
			end
			return true
		end
	end
	return false
end

function SurvivalPlayer.sv_updateTumbling( self )
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

function SurvivalPlayer.sv_n_exchangeItem( self, params )
	if sm.container.beginTransaction() then
		sm.container.spendFromSlot( params.playerInventory, params.slotIndex, params.previousUid, params.previousQuantity, true )
		sm.container.collectToSlot( params.playerInventory, params.slotIndex, params.nextUid, params.nextQuantity, true )
		sm.container.endTransaction()
	end
end

function SurvivalPlayer.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal  )

	if not self.player.character or not sm.exists( self.player.character ) then
		return
	end

	if not self.sv.impactCooldown:done() then
		return
	end

	local collisionDamageMultiplier = 0.25
	local damage, tumbleTicks, tumbleVelocity, impactReaction = CharacterCollision( self.player.character, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal, self.sv.saved.stats.maxhp / collisionDamageMultiplier, 24 )
	damage = damage * collisionDamageMultiplier
	if damage > 0 or tumbleTicks > 0 then
		self.sv.impactCooldown:start( 0.25 * 40 )
	end
	if damage > 0 then
		print("'SurvivalPlayer' took", damage, "collision damage")
		self:sv_takeDamage( damage, "shock" )
	end
	if tumbleTicks > 0 then
		if self:sv_startTumble( tumbleTicks ) then
			-- Limit tumble velocity
			if tumbleVelocity:length2() > MaxTumbleImpulseSpeed * MaxTumbleImpulseSpeed then
				tumbleVelocity = tumbleVelocity:normalize() * MaxTumbleImpulseSpeed
			end
			self.player.character:applyTumblingImpulse( tumbleVelocity * self.player.character.mass )
			if type( other ) == "Shape" and sm.exists( other ) and other.body:isDynamic() then
				sm.physics.applyImpulse( other.body, impactReaction * other.body.mass, true, collisionPosition - other.body.worldPosition )
			end
		end
	end

end

function SurvivalPlayer.sv_e_staminaSpend( self, stamina )
	if not g_godMode then
		if stamina > 0 then
			self.sv.staminaSpend = self.sv.staminaSpend + stamina
			print( "SurvivalPlayer spent:", stamina, "stamina" )
		end
	else
		print( "SurvivalPlayer resisted", stamina, "stamina spend" )
	end
end

function SurvivalPlayer.sv_e_receiveDamage( self, damageData )
	self:sv_takeDamage( damageData.damage )
end

function SurvivalPlayer.sv_takeDamage( self, damage, source )
	if damage > 0 then
		if self.cloth_damage_reduction ~= nil then
			local reduction = self.cloth_damage_reduction / 100
			local relDamage = damage * reduction
			damage = damage - relDamage
			if damage < 0 then
				damage = 0
			end
		end
	end
	if damage > 0 then
		local SkillHealthLevel = self.sv_cloth_stats_bonus_health + self.sv.saved.stats.skill_health
		if SkillHealthLevel > 0 then
			local subDamage = ( damage / 2 ) * ( SkillHealthLevel / 100 )
			
			damage = damage - subDamage
			if damage < 1 then
				damage = 1
			end
		end
	end
	
	if damage > 0 then
		damage = damage * GetDifficultySettings().playerTakeDamageMultiplier
		local character = self.player:getCharacter()
		local lockingInteractable = character:getLockingInteractable()
		if lockingInteractable and lockingInteractable:hasSeat() then
			lockingInteractable:setSeatCharacter( character )
		end

		if not g_godMode and self.sv.damageCooldown:done() then
			if self.sv.saved.isConscious then
				self.sv.saved.stats.hp = math.max( self.sv.saved.stats.hp - damage, 0 )

				print( "'SurvivalPlayer' took:", damage, "damage.", self.sv.saved.stats.hp, "/", self.sv.saved.stats.maxhp, "HP" )

				if source then
					self.network:sendToClients( "cl_n_onEvent", { event = source, pos = character:getWorldPosition(), damage = damage * 0.01 } )
				else
					self.player:sendCharacterEvent( "hit" )
				end

				if self.sv.saved.stats.hp <= 0 then
					print( "'SurvivalPlayer' knocked out!" )
					self.sv.respawnInteractionAttempted = false
					self.sv.saved.isConscious = false
					character:setTumbling( true )
					character:setDowned( true )
					
					-- 00Fant
					self:sv_addDeath( self.player )
					-- 00Fant
				end

				self.storage:save( self.sv.saved )
				self.network:setClientData( self.sv.saved )
			end
		else
			print( "'SurvivalPlayer' resisted", damage, "damage" )
		end
	end
end

function SurvivalPlayer.sv_n_revive( self )
	local character = self.player:getCharacter()
	if not self.sv.saved.isConscious and self.sv.saved.hasRevivalItem and not self.sv.spawnparams.respawn then
		print( "SurvivalPlayer", self.player.id, "revived" )
		self.sv.saved.stats.hp = self.sv.saved.stats.maxhp
		self.sv.saved.stats.food = self.sv.saved.stats.maxfood
		self.sv.saved.stats.water = self.sv.saved.stats.maxwater
		self.sv.saved.isConscious = true
		self.sv.saved.hasRevivalItem = false
		self.storage:save( self.sv.saved )
		self.network:setClientData( self.sv.saved )
		self.network:sendToClient( self.player, "cl_n_onEffect", { name = "Eat - EatFinish", host = self.player.character } )
		if character then
			character:setTumbling( false )
			character:setDowned( false )
		end
		self.sv.damageCooldown:start( 40 )
		self.player:sendCharacterEvent( "revive" )
		
		-- 00Fant
		self:Fant_sv_n_revive( character )
		-- 00Fant
		
	end
end

function SurvivalPlayer.sv_e_respawn( self )
	if self.sv.spawnparams.respawn then
		if not self.sv.respawnTimeoutTimer then
			self.sv.respawnTimeoutTimer = Timer()
			self.sv.respawnTimeoutTimer:start( RespawnTimeout )
		end
		return
	end
	if not self.sv.saved.isConscious then
		g_respawnManager:sv_performItemLoss( self.player )
		self.sv.spawnparams.respawn = true

		sm.event.sendToGame( "sv_e_respawn", { player = self.player } )
	else
		print( "SurvivalPlayer must be unconscious to respawn" )
	end
end

function SurvivalPlayer.sv_n_try_respawn( self )
	if not self.sv.saved.isConscious and not self.sv.respawnDelayTimer and not self.sv.respawnInteractionAttempted then
		self.sv.respawnInteractionAttempted = true
		self.sv.respawnEndTimer = nil;
		self.network:sendToClient( self.player, "cl_n_startFadeToBlack", { duration = RespawnFadeDuration, timeout = RespawnFadeTimeout } )
		
		self.sv.respawnDelayTimer = Timer()
		self.sv.respawnDelayTimer:start( RespawnDelay )
	end
end

function SurvivalPlayer.sv_startFadeToBlack( self, param )
	self.network:sendToClient( self.player, "cl_n_startFadeToBlack", { duration = param.duration, timeout = param.timeout } )
end

function SurvivalPlayer.sv_endFadeToBlack( self, param )
	self.network:sendToClient( self.player, "cl_n_endFadeToBlack", { duration = param.duration } )
end

function SurvivalPlayer.cl_n_startFadeToBlack( self, param )
	sm.gui.startFadeToBlack( param.duration, param.timeout )
end

function SurvivalPlayer.cl_n_endFadeToBlack( self, param )
	sm.gui.endFadeToBlack( param.duration )
end

function SurvivalPlayer.sv_onSpawnCharacter( self )
	if self.sv.saved.isNewPlayer then
		-- Intro cutscene for new player
		if not g_survivalDev then
			--self:sv_e_startLocalCutscene( "camera_approach_crash" )
		end
	elseif self.sv.spawnparams.respawn then
		local playerBed = g_respawnManager:sv_getPlayerBed( self.player )
		if playerBed and playerBed.shape and sm.exists( playerBed.shape ) and playerBed.shape.body:getWorld() == self.player.character:getWorld() then
			-- Attempt to seat the respawned character in a bed
			self.network:sendToClient( self.player, "cl_seatCharacter", { shape = playerBed.shape  } )
		else
			-- Respawned without a bed
			--self:sv_e_startLocalCutscene( "camera_wakeup_ground" )
		end

		self.sv.respawnEndTimer = Timer()
		self.sv.respawnEndTimer:start( RespawnEndDelay )
	
	end

	if self.sv.saved.isNewPlayer or self.sv.spawnparams.respawn then
		print( "SurvivalPlayer", self.player.id, "spawned" )
		if self.sv.saved.isNewPlayer then
			self.sv.saved.stats.hp = self.sv.saved.stats.maxhp
			self.sv.saved.stats.food = self.sv.saved.stats.maxfood
			self.sv.saved.stats.water = self.sv.saved.stats.maxwater
		else
			self.sv.saved.stats.hp = 30
			self.sv.saved.stats.food = 30
			self.sv.saved.stats.water = 30
		end
		self.sv.saved.isConscious = true
		self.sv.saved.hasRevivalItem = false
		self.sv.saved.isNewPlayer = false
		
		-- 00Fant
		self:Fant_sv_onSpawnCharacter()
		-- 00Fant
		
		self.storage:save( self.sv.saved )
		self.network:setClientData( self.sv.saved )

		self.player.character:setTumbling( false )
		self.player.character:setDowned( false )
		self.sv.damageCooldown:start( 40 )
	else
		-- SurvivalPlayer rejoined the game
		if self.sv.saved.stats.hp <= 0 or not self.sv.saved.isConscious then
			self.player.character:setTumbling( true )
			self.player.character:setDowned( true )
		end
	end

	self.sv.respawnInteractionAttempted = false
	self.sv.respawnDelayTimer = nil
	self.sv.respawnTimeoutTimer = nil
	self.sv.spawnparams = {}

	sm.event.sendToGame( "sv_e_onSpawnPlayerCharacter", self.player )
end

function SurvivalPlayer.cl_seatCharacter( self, params )
	if sm.exists( params.shape ) then
		params.shape.interactable:setSeatCharacter( self.player.character )
	end
end

function SurvivalPlayer.sv_e_debug( self, params )
	if params.hp then
		self.sv.saved.stats.hp = params.hp
	end
	if params.water then
		self.sv.saved.stats.water = params.water
	end
	if params.food then
		self.sv.saved.stats.food = params.food
	end
	
	-- 00Fant
	self:Fant_sv_e_debug( params )
	-- 00Fant
	
	self.storage:save( self.sv.saved )
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_eat( self, edibleParams )
	if edibleParams.hpGain then
		self:sv_restoreHealth( edibleParams.hpGain )
	end
	if edibleParams.foodGain then
		self:sv_restoreFood( edibleParams.foodGain )

		self.network:sendToClient( self.player, "cl_n_onEffect", { name = "Eat - EatFinish", host = self.player.character } )
	end
	if edibleParams.waterGain then
		self:sv_restoreWater( edibleParams.waterGain )
		-- self.network:sendToClient( self.player, "cl_n_onEffect", { name = "Eat - DrinkFinish", host = self.player.character } )
	end
	
	-- 00Fant
	self:Fant_sv_e_eat( edibleParams )
	-- 00Fant
	
	self.storage:save( self.sv.saved )
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_feed( self, params )
	if not self.sv.saved.isConscious and not self.sv.saved.hasRevivalItem then
		if sm.container.beginTransaction() then
			sm.container.spend( params.playerInventory, params.foodUuid, 1, true )
			if sm.container.endTransaction() then
				self.sv.saved.hasRevivalItem = true
				self.player:sendCharacterEvent( "baguette" )
				self.network:setClientData( self.sv.saved )
			end
		end
	end
end

function SurvivalPlayer.sv_restoreHealth( self, health )
	if self.sv.saved.isConscious then
		self.sv.saved.stats.hp = self.sv.saved.stats.hp + health
		self.sv.saved.stats.hp = math.min( self.sv.saved.stats.hp, self.sv.saved.stats.maxhp )
		print( "'SurvivalPlayer' restored:", health, "health.", self.sv.saved.stats.hp, "/", self.sv.saved.stats.maxhp, "HP" )
	end
end

function SurvivalPlayer.sv_restoreFood( self, food )
	if self.sv.saved.isConscious then
		food = food * ( 0.8 + ( self.sv.saved.stats.maxfood - self.sv.saved.stats.food ) / self.sv.saved.stats.maxfood * 0.2 )
		self.sv.saved.stats.food = self.sv.saved.stats.food + food
		self.sv.saved.stats.food = math.min( self.sv.saved.stats.food, self.sv.saved.stats.maxfood )
		print( "'SurvivalPlayer' restored:", food, "food.", self.sv.saved.stats.food, "/", self.sv.saved.stats.maxfood, "FOOD" )
	end
end

function SurvivalPlayer.sv_restoreWater( self, water )
	if self.sv.saved.isConscious then
		water = water * ( 0.8 + ( self.sv.saved.stats.maxwater - self.sv.saved.stats.water ) / self.sv.saved.stats.maxwater * 0.2 )
		self.sv.saved.stats.water = self.sv.saved.stats.water + water
		self.sv.saved.stats.water = math.min( self.sv.saved.stats.water, self.sv.saved.stats.maxwater )
		print( "'SurvivalPlayer' restored:", water, "water.", self.sv.saved.stats.water, "/", self.sv.saved.stats.maxwater, "WATER" )
	end
end

function SurvivalPlayer.sv_e_setRefiningState( self, params )
	local userPlayer = params.user:getPlayer()
	if userPlayer then
		if params.state == true then
			userPlayer:sendCharacterEvent( "refine" )
		else
			userPlayer:sendCharacterEvent( "refineEnd" )
		end
	end
end

function SurvivalPlayer.sv_e_onLoot( self, params )
	self.network:sendToClient( self.player, "cl_n_onLoot", params )
end

function SurvivalPlayer.cl_n_onLoot( self, params )
	local message = "#{INFO_PICKED_LOOT} "
	if params.uuid then
		message = message .. sm.shape.getShapeTitle( params.uuid )
	elseif params.name then
		message = message .. params.name
	end
	if params.quantity and params.quantity > 1 then
		message = message.." x"..params.quantity
	end
	sm.gui.displayAlertText( message, 2 )
	local color
	if params.uuid then
		color = sm.shape.getShapeTypeColor( params.uuid )
	end
	local effectName = params.effectName or "Loot - Pickup"
	sm.effect.playEffect( effectName, params.pos, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), { ["Color"] = color } )
end

function SurvivalPlayer.sv_e_onMsg( self, msg )
	self.network:sendToClient( self.player, "cl_n_onMsg", msg )
end

function SurvivalPlayer.cl_n_onMsg( self, msg )
	sm.gui.displayAlertText( msg )
end

function SurvivalPlayer.cl_n_onEffect( self, params )
	if params.host then
		sm.effect.playHostedEffect( params.name, params.host, params.boneName, params.parameters )
	else
		sm.effect.playEffect( params.name, params.position, params.velocity, params.rotation, params.scale, params.parameters )
	end
end

function SurvivalPlayer.sv_e_onStayPesticide( self )
	if self.sv.poisonDamageCooldown:done() then
		self:sv_takeDamage( PoisonDamage, "poison" )
		self.sv.poisonDamageCooldown:start( PoisonDamageCooldown )
	end
end

function SurvivalPlayer.sv_e_onEnterFire( self )
	if self.sv.fireDamageCooldown:done() then
		self:sv_takeDamage( FireDamage, "fire" )
		self.sv.fireDamageCooldown:start( FireDamageCooldown )
	end
end

function SurvivalPlayer.sv_e_onStayFire( self )
	if self.sv.fireDamageCooldown:done() then
		self:sv_takeDamage( FireDamage, "fire" )
		self.sv.fireDamageCooldown:start( FireDamageCooldown )
	end
end

function SurvivalPlayer.sv_e_onEnterChemical( self )
	if self.sv.poisonDamageCooldown:done() then
		self:sv_takeDamage( PoisonDamage, "poison" )
		self.sv.poisonDamageCooldown:start( PoisonDamageCooldown )
	end
	self.sv.saved.inChemical = true
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_onStayChemical( self )
	if self.sv.poisonDamageCooldown:done() then
		self:sv_takeDamage( PoisonDamage, "poison" )
		self.sv.poisonDamageCooldown:start( PoisonDamageCooldown )
	end
end

function SurvivalPlayer.sv_e_onExitChemical( self )
	self.sv.saved.inChemical = false
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_onEnterOil( self )
	self.sv.saved.inOil = true
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_onExitOil( self )
	self.sv.saved.inOil = false
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.server_onShapeRemoved( self, removedShapes )
	local numParts = 0
	local numBlocks = 0
	local numJoints = 0
	for _, removedShapeType in ipairs( removedShapes ) do
		if removedShapeType.type == "block"  then
			numBlocks = numBlocks + removedShapeType.amount
		elseif removedShapeType.type == "part"  then
			numParts = numParts + removedShapeType.amount
		elseif removedShapeType.type == "joint"  then
			numJoints = numJoints + removedShapeType.amount
		end
	end

	local staminaSpend = numParts + numJoints + math.sqrt( numBlocks )
	--self:sv_e_staminaSpend( staminaSpend )
end

-- Camera

function SurvivalPlayer.cl_updateCamera( self, dt )

	if self.useCutsceneCamera then
		local cameraPath = self.currentCutscene.cameraPath
		local cameraAttached = self.currentCutscene.cameraAttached
		if #cameraPath > 1 then
			if cameraPath[self.nodeIndex+1] then
				local prevNode = cameraPath[self.nodeIndex]
				local nextNode = cameraPath[self.nodeIndex+1]

				local prevPosition = prevNode.position
				local nextPosition = nextNode.position
				local prevDirection = prevNode.direction
				local nextDirection = nextNode.direction

				if prevNode.type == "playerSpace" then
					prevPosition = sm.camera.getDefaultPosition()
				end
				if nextNode.type == "playerSpace" then
					nextPosition = nextNode.position + sm.camera.getDefaultPosition()
					-- Set player to look in the same direction as the player node
					if cameraPath[self.nodeIndex].direction then
						sm.localPlayer.setDirection( cameraPath[self.nodeIndex+1].direction )
					end
				end

				if nextNode.lerpTime > 0 then
					self.progress = self.progress + dt / nextNode.lerpTime
				else
					self.progress = 1
				end

				if self.progress >= 1 then

					-- Trigger events in the next node
					if nextNode.events then
						for _, eventParams in pairs( nextNode.events ) do
							if eventParams.type == "character" then
								eventParams.character = self.player.character
							end
							self.network:sendToServer( "sv_onEvent", eventParams )
						end
					end

					self.nodeIndex = self.nodeIndex + 1
					local upcomingNextNode = cameraPath[self.nodeIndex+1]
					if upcomingNextNode then
						self.progress = ( self.progress - 1.0 ) * nextNode.lerpTime / upcomingNextNode.lerpTime
						self.progress = math.max( math.min( self.progress, 1.0 ), 0 )
						prevPosition = nextNode.position
						nextPosition = upcomingNextNode.position
						prevDirection = nextNode.direction
						nextDirection = upcomingNextNode.direction
						if nextNode.type == "playerSpace" then
							prevPosition = sm.camera.getDefaultPosition()
						end
						if upcomingNextNode.type == "playerSpace" then
							nextPosition = nextPosition +  sm.camera.getDefaultPosition()
							-- Set player to look in the same direction as the player node
							if cameraPath[self.nodeIndex].direction then
								sm.localPlayer.setDirection( cameraPath[self.nodeIndex+1].direction )
							end
						end
					else
						--Finished the cutscene
						self.progress = 0
						self.nodeIndex = 1
						if self.currentCutscene.nextCutscene then
							self:cl_startCutscene( camera_cutscenes[self.currentCutscene.nextCutscene] )
						else
							self.useCutsceneCamera = false
							sm.gui.hideGui( false )
							sm.camera.setCameraState( sm.camera.state.default )
							sm.localPlayer.setLockedControls( false )
						end
					end
				end

				local camPos = sm.vec3.lerp( prevPosition, nextPosition, self.progress )
				local camDir = sm.vec3.lerp( prevDirection, nextDirection, self.progress )

				sm.camera.setPosition( camPos )
				sm.camera.setDirection( camDir )
			end
		elseif cameraAttached then

			if self.progress >= 1 then
				--Finished the cutscene
				self.progress = 0
				self.nodeIndex = 1
				if self.currentCutscene.nextCutscene then
					self:cl_startCutscene( camera_cutscenes[self.currentCutscene.nextCutscene] )
				else
					self.useCutsceneCamera = false
					sm.gui.hideGui( false )
					sm.camera.setCameraState( sm.camera.state.default )
					sm.localPlayer.setLockedControls( false )
				end
			else
				local character = self.player:getCharacter()
				if character then
					sm.camera.setCameraState( sm.camera.state.cutsceneFP )
					local camPos = character:getTpBonePos( cameraAttached.jointName )
					local camDir = character:getTpBoneRot( cameraAttached.jointName ) * cameraAttached.initialDirection

					sm.camera.setPosition( camPos )
					sm.camera.setDirection( camDir )
				end
			end
			self.progress = self.progress + dt / cameraAttached.attachTime

		else
			self:cl_startCutscene( nil )
		end
	end

end


function SurvivalPlayer.cl_startCutscene( self, cutsceneInfo )
	if cutsceneInfo then
		self.useCutsceneCamera = true
		sm.gui.hideGui( true )
		sm.camera.setCameraState( cutsceneInfo.cameraState )
		if cutsceneInfo.cameraPullback then
			sm.camera.setCameraPullback( cutsceneInfo.cameraPullback.standing, cutsceneInfo.cameraPullback.seated )
		end

		sm.localPlayer.setLockedControls( true )

		if self.useCutsceneCamera then
			-- Set camera nodes to follow
			self.currentCutscene = {}
			self.currentCutscene.cameraAttached = cutsceneInfo.attached
			local cameraPath = {}
			local characterPosition = sm.vec3.new( 0, 0, 0 )
			local characterDirection = sm.vec3.new( 0, 1, 0 )
			local character = self.player.character
			if character then
				characterPosition = character.worldPosition + sm.vec3.new( 0, 0, character:getHeight() * 0.5 )
				characterDirection = character:getDirection()
			else
				characterPosition = sm.localPlayer.getRaycastStart()
				characterDirection = sm.localPlayer.getDirection()
			end

			-- Get character heading
			characterDirection.z = 0
			if characterDirection:length() >= FLT_EPSILON then
				characterDirection = characterDirection:normalize()
			else
				characterDirection = sm.vec3.new( 0, 1, 0 )
			end

			-- Prepare a world direction and positon for each camera node
			if cutsceneInfo.nodes then
				for _, node in pairs( cutsceneInfo.nodes ) do
					local updatedNode = {}
					if node.type == "localSpace" then
						local right = characterDirection:cross( sm.vec3.new( 0, 0, 1 ) )
						local pitchedDirection = sm.vec3.rotate( characterDirection, math.rad( node.pitch ), right )
						updatedNode.direction = sm.vec3.rotateZ( pitchedDirection, -math.rad( node.yaw ) )
						updatedNode.position = characterPosition + sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), characterDirection ) * node.position
					elseif node.type == "playerSpace" then
						local right = sm.localPlayer.getDirection():cross( sm.vec3.new( 0, 0, 1 ) )
						local pitchedDirection = sm.vec3.rotate( sm.localPlayer.getDirection(), math.rad( node.pitch ), right )
						updatedNode.direction = sm.vec3.rotateZ( pitchedDirection, -math.rad( node.yaw ) )

						--updatedNode.position = sm.camera.getDefaultPosition() + sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.localPlayer.getDirection() ) * node.position
						updatedNode.position = sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.localPlayer.getDirection() ) * node.position
					else
						updatedNode.position = node.position
						updatedNode.direction = node.direction
					end
					updatedNode.type = node.type
					updatedNode.lerpTime = node.lerpTime
					updatedNode.events = node.events
					cameraPath[#cameraPath+1] = updatedNode
				end
			end

			if #cameraPath > 0 then
				-- Trigger events in the first node
				if cameraPath[1] then
					if cameraPath[1].events then
						for _, eventParams in pairs( cameraPath[1].events ) do
							if eventParams.type == "character" then
								eventParams.character = self.player.character
							end
							self.network:sendToServer( "sv_onEvent", eventParams )
						end
					end
				end
			elseif self.currentCutscene.cameraAttached then
				-- Trigger events
				if self.currentCutscene.cameraAttached.events then
					for _, eventParams in pairs( self.currentCutscene.cameraAttached.events ) do
						if eventParams.type == "character" then
							eventParams.character = self.player.character
						end
						self.network:sendToServer( "sv_onEvent", eventParams )
					end
				end
			end

			self.currentCutscene.cameraPath = cameraPath
			self.currentCutscene.nextCutscene = cutsceneInfo.nextCutscene
			self.currentCutscene.canSkip = cutsceneInfo.canSkip
		end
	else
		self.useCutsceneCamera = false
		sm.gui.hideGui( false )
		sm.camera.setCameraState( sm.camera.state.default )
		sm.localPlayer.setLockedControls( false )
		self.progress = 0
		self.nodeIndex = 1
	end
end

function SurvivalPlayer.cl_startLocalCutscene( self, params )
	if params.player == sm.localPlayer.getPlayer() then
		self:cl_startCutscene( camera_cutscenes[params.cutsceneInfoName] )
	end
end

function SurvivalPlayer.sv_e_startLocalCutscene( self, cutsceneInfoName )
	local params = { player = self.player, cutsceneInfoName = cutsceneInfoName }
	self.network:sendToClients( "cl_startLocalCutscene", params )
end

function SurvivalPlayer.sv_onEvent( self, eventParams )
	if eventParams.type == "character" then
		self.player:sendCharacterEvent( eventParams.data )
	end
end


function SurvivalPlayer.client_onCancel( self )

	if self.useCutsceneCamera and self.currentCutscene.canSkip then
		if self.currentCutscene.nextCutscene then
			self:cl_startCutscene( camera_cutscenes[self.currentCutscene.nextCutscene] )
		else
			self.useCutsceneCamera = false
			sm.gui.hideGui( false )
			sm.camera.setCameraState( sm.camera.state.default )
			sm.localPlayer.setLockedControls( false )
			self.progress = 0
			self.nodeIndex = 1
		end
	end
	
end

function SurvivalPlayer.client_onReload( self ) end