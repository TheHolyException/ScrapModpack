dofile( "$SURVIVAL_DATA/Scripts/game/managers/UnitManager.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/recipes.lua" )
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")


CreativeGame = class( nil )
CreativeGame.enableLimitedInventory = false
CreativeGame.enableRestrictions = true
CreativeGame.enableFuelConsumption = false
CreativeGame.enableAmmoConsumption = false
CreativeGame.enableUpgradeCost = true

g_godMode = true
g_disableScrapHarvest = true


-- 00Fant´s code Start
dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_playerblock.lua" )
g_characters = g_characters or {}
CreativeFastGrow = CreativeFastGrow or false
RespawnPositions = RespawnPositions or {}
FantHud = true
g_survivalHud = g_survivalHud or nil
ShowNameTag = true
CanRespawn = true
noBuild = false
fant_clouds_active = true

function CreativeGame.sv_FastGrow( self, data )
	CreativeFastGrow = data.CreativeFastGrow
end

function CreativeGame.sv_exportCreation( self, params )
	local obj = sm.json.parseJsonString( sm.creation.exportToString( params.body ) )
	sm.json.save( obj, "$SURVIVAL_DATA/LocalBlueprints/"..params.name..".blueprint" )
end

function CreativeGame.sv_importCreation( self, params )
	sm.creation.importFromFile( params.world, "$SURVIVAL_DATA/LocalBlueprints/"..params.name..".blueprint", params.position )
end

function CreativeGame.getLocalBlockGridPosition( self, pos )
	local size = sm.vec3.new( 3, 3, 1 )
	local size_2 = sm.vec3.new( 1, 1, 0 )
	local a = pos * sm.construction.constants.subdivisions
	local gridPos = sm.vec3.new( math.floor( a.x ), math.floor( a.y ), a.z ) - size_2
	return gridPos * sm.construction.constants.subdivideRatio + ( size * sm.construction.constants.subdivideRatio ) * 0.5
end

function CreativeGame.cleanup( self, params )
	sm.event.sendToPlayer( params.player, "Cleanup", params.radius )
end

function CreativeGame.sv_delete( self, params )
	local shapes = sm.body.getCreationShapes( params.body )
	for i, shape in ipairs(shapes) do 
		sm.shape.destroyShape( shape, 0 )
	end
end

function CreativeGame.PlaceSoilField( self, params )
	print( "Create Field!" )
	for i, k in pairs( params.data ) do 
		if k ~= nil then
			sm.event.sendToPlayer( params.player, "PlaceSoil", k )
		end
	end
end

function CreativeGame.sv_fill( self, params )
	local filltype = "all"
	if params.filltype ~= nil then
		if params.filltype:lower():match( "ga" ) then
			filltype = "gas"
		end
		if params.filltype:lower():match( "fu" ) then
			filltype = "gas"
		end
		if params.filltype:lower():match( "wa" ) then
			filltype = "water"
		end
		if params.filltype:lower():match( "bat" ) then
			filltype = "batterie"
		end
		if params.filltype:lower():match( "am" ) then
			filltype = "ammo"
		end
		if params.filltype:lower():match( "po" ) then
			filltype = "ammo"
		end
		if params.filltype:lower():match( "ch" ) then
			filltype = "chemicals"
		end	
		if params.filltype:lower():match( "ban" ) then
			filltype = "banana"
		end	
	end
	
	local Quantitys = {
		1000,
		500,
		250,
		100,
		50,
		25,
		10,
		1
	}
	if filltype == "all" then
		Quantitys = {
			50,
			25,
			10,
			1
		}
	end
	local interactable = sm.shape.getInteractable( params.shape ) 
	local container = sm.interactable.getContainer( interactable, 0 )
	if container then
		for index, Quantity in pairs( Quantitys ) do
			for loop = 0, 20 do
				if sm.container.canCollect( container, obj_consumable_gas, Quantity ) and ( filltype == "all" or filltype == "gas" ) then
					sm.container.beginTransaction()
					sm.container.collect( container, obj_consumable_gas, Quantity, true )	
					if sm.container.endTransaction() then	
					end		
				end
				if sm.container.canCollect( container, obj_consumable_battery, Quantity ) and ( filltype == "all" or filltype == "batterie" )  then	
					sm.container.beginTransaction()
					sm.container.collect( container, obj_consumable_battery, Quantity, true )	
					if sm.container.endTransaction() then					
					end		
				end
				if sm.container.canCollect( container, obj_plantables_potato, Quantity ) and ( filltype == "all" or filltype == "ammo" )  then	
					sm.container.beginTransaction()
					sm.container.collect( container, obj_plantables_potato, Quantity, true )	
					if sm.container.endTransaction() then				
					end		
				end
				if sm.container.canCollect( container, obj_consumable_water, Quantity ) and ( filltype == "all" or filltype == "water" )  then	
					sm.container.beginTransaction()
					sm.container.collect( container, obj_consumable_water, Quantity, true )	
					if sm.container.endTransaction() then				
					end		
				end
				if sm.container.canCollect( container, obj_consumable_chemical, Quantity ) and ( filltype == "all" or filltype == "chemicals" )  then	
					sm.container.beginTransaction()
					sm.container.collect( container, obj_consumable_chemical, Quantity, true )	
					if sm.container.endTransaction() then				
					end		
				end
				if sm.container.canCollect( container, obj_plantables_banana, Quantity ) and ( filltype == "all" or filltype == "banana" )  then	
					sm.container.beginTransaction()
					sm.container.collect( container, obj_plantables_banana, Quantity, true )	
					if sm.container.endTransaction() then				
					end		
				end
			end
		end
	end
end

function CreativeGame.sv_fly( self, data )
	if self.fly == nil then
		self.fly = false
	end
	if self.fly == true then
		self.fly = false
		self.network:sendToClients( "remove_from_g_characters", data.character )
	else
		self.fly = true
		self.network:sendToClients( "add_to_g_characters", data.character )
	end	
	data.character:setSwimming( self.fly )
	data.character:setDiving( self.fly )
	print( "Fly Mode: " ..tostring( self.fly ) )
end

function CreativeGame.add_to_g_characters( self, character )
	self.fly = true
	local hasPly = false
	for k, g_character in pairs(g_characters) do
		if g_character == character then
			hasPly = true
		end
	end
	if hasPly == false then
		table.insert( g_characters, character )
		sm.gui.displayAlertText( "If the Flymode has not worked, try it again. (lag reason)" )
	end
end

function CreativeGame.remove_from_g_characters( self, character )
	local newPlayers = {}
	for k, g_character in pairs(g_characters) do
		if g_character ~= character then
			table.insert( newPlayers, g_character )
		end
	end
	self.fly = false
	g_characters = newPlayers
	character.movementSpeedFraction = 1
end

function CreativeGame.sv_clear( self, data )
	local isLimited = sm.game.getLimitedInventory()
	sm.game.setLimitedInventory( true )
	local inventory = data.player:getInventory()
	local size = inventory:getSize()
	local lostItems = {}

	for i = 0, size do
		local item = inventory:getItem( i )
		if item.uuid ~= sm.uuid.getNil() then
			item.slot = i
			lostItems[#lostItems+1] = item
		end
	end

	if #lostItems > 0 then
		if sm.container.beginTransaction() then
			for i, item in ipairs( lostItems ) do
				sm.container.spendFromSlot( inventory, item.slot, item.uuid, item.quantity, true )
			end		
			sm.container.endTransaction()
		end
	end
	sm.game.setLimitedInventory( false )
end

function CreativeGame.sv_Respawn( self, data )
	sm.event.sendToPlayer( data.player, "sv_respawn", data )
	local pos = RespawnPositions[ data.player.character.id ]
	if data.spawnPos ~= nil then
		pos = data.spawnPos 
	end	
	if pos ~= nil then
		data.world:loadCell( math.floor( pos.x/64 ), math.floor( pos.y/64 ), data.player )
	end
end

function CreativeGame.sv_SetRespawn( self, player )
	sm.event.sendToPlayer( player, "sv_setrespawn" )
	RespawnPositions[ player.character.id ] = player.character.worldPosition
	print( "Respawn Set: " .. tostring( RespawnPositions[ player.character.id ] ) )
end

function CreativeGame.sv_ScoreReset( self, player )
	for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
		sm.event.sendToPlayer( listPlayer, "sv_CreatePlayerScore", player )
	end
	--sm.event.sendToPlayer( player, "sv_CreatePlayerScore", player )
end

function CreativeGame.sv_ScoreResetAll( self )
	for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
		sm.event.sendToPlayer( listPlayer, "sv_ScoreResetAll" )
	end
end

function CreativeGame.sv_setPlayerScore( self, PlayerScorces )
	for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
		sm.event.sendToPlayer( listPlayer, "sv_setPlayerScore", PlayerScorces )
	end
end

function CreativeGame.SetData( self, data )
	for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
		sm.event.sendToPlayer( listPlayer, data.func, data.data )
	end
end

function CreativeGame.sv_block( self, data )
	FantBlock_sv_block( self, data )
end

function CreativeGame.cl_block( self, data )
	FantBlock_cl_block( self, data )
end

function CreativeGame.sv_unblock( self, data )
	FantBlock_sv_unblock( self, data )
end

function CreativeGame.cl_unblock( self, data )
	FantBlock_cl_unblock( self, data )
end

function CreativeGame.sv_setGod( self, state )
	self.network:sendToClients( "cl_setGod", state )
end

function CreativeGame.cl_setGod( self, state )
	g_godMode = state
	self.network:sendToServer( "sv_ScoreReset", sm.localPlayer.getPlayer() )
	if not g_godMode then
		g_survivalHud:setVisible( "HealthBar", true )		
	else
		g_survivalHud:setVisible( "HealthBar", false )
		--local player = sm.localPlayer.getPlayer()
		--self.network:sendToServer( "sv_SetRespawn", player )
		--self.network:sendToServer( "sv_Respawn", { world = player.character:getWorld(), player = player } )
	end
end

function CreativeGame.sv_getPvPData( self )
	self.network:sendToClients( "cl_setGod", g_godMode )
	for i, listPlayer in pairs( sm.player.getAllPlayers() ) do 
		sm.event.sendToPlayer( listPlayer, "sv_canrespawn", CanRespawn )
		sm.event.sendToPlayer( listPlayer, "sv_noBuild", noBuild )
	end
	self.network:sendToClients( "cl_setUnlimitedInventory", self.enableLimitedInventory )
	
	
end

function CreativeGame.sv_setUnlimitedInventory( self, state )
	self.network:sendToClients( "cl_setUnlimitedInventory", state )
	sm.game.setLimitedInventory( state )
end

function CreativeGame.cl_setUnlimitedInventory( self, state )
	self.enableLimitedInventory = state
	
end

function CreativeGame.sv_team( self, data )
	for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
		sm.event.sendToPlayer( listPlayer, "sv_team", data )
	end
end

function CreativeGame.sv_canrespawn( self, state )
	CanRespawn = state
	for i, listPlayer in pairs( sm.player.getAllPlayers() ) do 
		sm.event.sendToPlayer( listPlayer, "sv_canrespawn", CanRespawn )
	end
end

function CreativeGame.sv_noBuild( self, data )
	noBuild = data.state
	sm.event.sendToPlayer( data.player, "sv_noBuild", noBuild )
end


function CreativeGame.sv_shape( self, data )
	sm.event.sendToPlayer( data.player, "sv_shape", data )
end

-- 00Fant´s code End



function CreativeGame.server_onCreate( self )
	g_unitManager = UnitManager()
	g_unitManager:sv_onCreate( nil, { aggroCreations = true } )

	local time = sm.storage.load( STORAGE_CHANNEL_TIME )
	if time then
		print( "Loaded timeData:" )
		print( time )
	else
		time = {}
		time.timeOfDay = 0.5
		sm.storage.save( STORAGE_CHANNEL_TIME, time )
	end

	self.network:setClientData( { time = time.timeOfDay } )

	self:loadCraftingRecipes()
	
	-- 00Fant
	FantBlock_server_onCreate( self, data )
	-- 00Fant
end

function CreativeGame.loadCraftingRecipes( self )
	LoadCraftingRecipes({
		craftbot = "$SURVIVAL_DATA/CraftingRecipes/craftbot.json"
	})
end

function CreativeGame.server_onFixedUpdate( self, timeStep )
	g_unitManager:sv_onFixedUpdate()
	
	-- 00Fant
	g_unitManager:sv_onFixedUpdate()
	
	FantBlock_server_onFixedUpdate( self, timeStep )
	
	for k, character in pairs(g_characters) do
		if character ~= nil then
			if sm.exists( character ) then
				if character:isSwimming() == false then
					character:setSwimming( self.fly )
				end
				if character:isDiving() == false then
					character:setDiving( self.fly )
				end
			end
		end
	end
	-- 00Fant
end

function CreativeGame.server_onPlayerJoined( self, player, newPlayer )
	g_unitManager:sv_onPlayerJoined( player )
end

function CreativeGame.client_onCreate( self )
	if not sm.isHost then
		self:loadCraftingRecipes()
	end

	sm.game.bindChatCommand( "/noaggro", { { "bool", "enable", true } }, "cl_onChatCommand", "Toggles the player as a target" )
	sm.game.bindChatCommand( "/noaggrocreations", { { "bool", "enable", true } }, "cl_onChatCommand", "Toggles whether the Tapebots will shoot at creations" )
	sm.game.bindChatCommand( "/aggroall", {}, "cl_onChatCommand", "All hostile units will be made aware of the player's position" )
	sm.game.bindChatCommand( "/popcapsules", { { "string", "filter", true } }, "cl_onChatCommand", "Opens all capsules. An optional filter controls which type of capsules to open: 'bot', 'animal'" )
	sm.game.bindChatCommand( "/killall", {}, "cl_onChatCommand", "Kills all spawned units" )
	sm.game.bindChatCommand( "/dropscrap", {}, "cl_onChatCommand", "Toggles the scrap loot from Haybots" )
	sm.game.bindChatCommand( "/place", { { "string", "harvestable", false } }, "cl_onChatCommand", "Places a harvestable at the aimed position. Must be placed on the ground. The harvestable parameter controls which harvestable to place: 'stone', 'tree', 'birch', 'leafy', 'spruce', 'pine'" )
	sm.game.bindChatCommand( "/restrictions", { { "bool", "enable", true } }, "cl_onChatCommand", "Toggles restrictions on creations" )
	sm.game.bindChatCommand( "/day", {}, "cl_onChatCommand", "Sets time of day to day" )
	sm.game.bindChatCommand( "/night", {}, "cl_onChatCommand", "Sets time of day to night" )
		
	-- 00Fant´s code Start
	sm.game.bindChatCommand( "/fant", {}, "cl_onChatCommand", "fant hud" )
	sm.game.bindChatCommand( "/shownametag", {}, "cl_onChatCommand", "toggle the custom nametag" )
	sm.game.bindChatCommand( "/delete", {}, "cl_onChatCommand", "delete" )
	sm.game.bindChatCommand( "/del", {}, "cl_onChatCommand", "delete" )
	sm.game.bindChatCommand( "/undo", {}, "cl_onChatCommand", "undo" )
	sm.game.bindChatCommand( "/fly", {}, "cl_onChatCommand", "fly" )
	sm.game.bindChatCommand( "/cleanup",  { { "int", "radius", true } }, "cl_onChatCommand", "cleanup" )
	sm.game.bindChatCommand( "/cam", { { "int", "toggle", true } }, "cl_onChatCommand", "Camera lock" )
	sm.game.bindChatCommand( "/camself", { { "int", "toggle", true } }, "cl_onChatCommand", "Camera lock" )
	sm.game.bindChatCommand( "/fill", { { "string", "type", true } }, "cl_onChatCommand", "Aim at a Container and use the Command on it. /fill or /fill ammo, gas, batterie, fuel, chemical, potato, water or the short variants like /fill am, ga, ch, wa, po" )
	sm.game.bindChatCommand( "/field", { { "int", "x", true }, { "int", "y", true } }, "cl_onChatCommand", "field" )
	sm.game.bindChatCommand( "/clearinv", {}, "cl_onChatCommand", "clearinv" )
	sm.game.bindChatCommand( "/fastgrow", { { "int", "toggle", true } }, "cl_onChatCommand", "Fatser Growspeed for Plants" )
	sm.game.bindChatCommand( "/clouds", {}, "cl_onChatCommand", "clouds" )
	
	sm.game.bindChatCommand( "/export", { { "string", "name", false } }, "cl_onChatCommand", "Exports blueprint $SURVIVAL_DATA/LocalBlueprints/<name>.blueprint" )
	sm.game.bindChatCommand( "/import", { { "string", "name", false } }, "cl_onChatCommand", "Imports blueprint $SURVIVAL_DATA/LocalBlueprints/<name>.blueprint" )
	sm.game.bindChatCommand( "/raid", { { "int", "level", false }, { "int", "wave", true }, { "number", "hours", true } }, "cl_onChatCommand", "Start a level <level> raid at player position at wave <wave> in <delay> hours." )
	sm.game.bindChatCommand( "/stopraid", {}, "cl_onChatCommand", "Cancel all incoming raids" )
	sm.game.bindChatCommand( "/disableraids", { { "bool", "enabled", false } }, "cl_onChatCommand", "Disable raids if true" )
		
	sm.game.bindChatCommand( "/setrespawn", {}, "cl_onChatCommand", "setrespawn" )
	sm.game.bindChatCommand( "/respawn", {}, "cl_onChatCommand", "respawn" )
	sm.game.bindChatCommand( "/scorereset", {}, "cl_onChatCommand", "scorereset" )
	sm.game.bindChatCommand( "/team", { { "string", "name", false } }, "cl_onChatCommand", "sets your Team. " )
	sm.game.bindChatCommand( "/leaveteam", {}, "cl_onChatCommand", "leave your Team. " )
	
	sm.game.bindChatCommand( "/shape", {  { "string", "form", false }, { "int", "x", true }, { "int", "y", true }, { "int", "z", true } }, "cl_onChatCommand", "shape" )
	
	if sm.isHost then
		sm.game.bindChatCommand( "/pvp", {}, "cl_onChatCommand", "pvp" )
		sm.game.bindChatCommand( "/block", { { "string", "name", false } }, "cl_onChatCommand", "blocks player with name. will be not able to do anything" )
		sm.game.bindChatCommand( "/scoreresetall", {}, "cl_onChatCommand", "scoreresetall" )
		sm.game.bindChatCommand( "/unblock", { { "string", "name", false } }, "cl_onChatCommand", "unblocks player with name. " )
		sm.game.bindChatCommand( "/limited", {}, "cl_onChatCommand", "limited" )
		sm.game.bindChatCommand( "/unlimited", {}, "cl_onChatCommand", "unlimited" )
		sm.game.bindChatCommand( "/canrespawn", {}, "cl_onChatCommand", "allows / disallows after death to respawn the Respawn with (E)" )
		sm.game.bindChatCommand( "/nobuild", {}, "cl_onChatCommand", "allows / disallows building at all!" )
	end
	
	g_survivalHud = sm.gui.createSurvivalHudGui()
	g_survivalHud:open()
	g_survivalHud:setVisible( "HealthBar", false )
	g_survivalHud:setVisible( "FoodBar", false )
	g_survivalHud:setVisible( "WaterBar", false )
	g_survivalHud:setVisible( "BindingPanel", false )
	
	self.network:sendToServer( "sv_getPvPData" )
	
	
	if g_unitManager == nil then
		assert( not sm.isHost )
		g_unitManager = UnitManager()
	end
	g_unitManager:cl_onCreate()
	
	-- 00Fant´s code End
	
	
	
	self.cl = {}
	if sm.isHost then
		self.clearEnabled = false
		sm.game.bindChatCommand( "/allowclear", { { "bool", "enable", true } }, "cl_onChatCommand", "Enabled/Disables the /clear command" )
		sm.game.bindChatCommand( "/clear", {}, "cl_onChatCommand", "Remove all shapes in the world. It must first be enabled with /allowclear" )
	end

	if g_unitManager == nil then
		assert( not sm.isHost )
		g_unitManager = UnitManager()
	end
	g_unitManager:cl_onCreate()
	if not sm.isHost then
		 
	end
end

function CreativeGame.client_onUpdate( self, dt )
	-- 00Fant
	g_unitManager:cl_onWorldUpdate( self, deltaTime )
	
	if self.ScoreInit == nil then
		self.network:sendToServer( "sv_ScoreReset", sm.localPlayer.getPlayer() )
		self.ScoreInit = true
	end
	if self.camModeSelf then
		local DirectionVector = sm.localPlayer.getPlayer().character.worldPosition - sm.camera.getPosition()
		local Distance = sm.vec3.length( DirectionVector )
		local DirectionNormalized = sm.vec3.normalize( DirectionVector )
		if DirectionNormalized == sm.vec3.new( 0, 0, 0 ) then
			DirectionNormalized = sm.vec3.new( 1, 0, 0 )
		end
		sm.camera.setDirection( sm.vec3.lerp( sm.camera.getDirection(), DirectionNormalized, dt * 25 ) )
		if Distance > 5 then
			local NewPos =  sm.localPlayer.getPlayer().character.worldPosition - DirectionNormalized * 4
			NewPos.z = sm.localPlayer.getPlayer().character.worldPosition.z + 3
			self.camSelfPos = NewPos
		end
		if self.camSelfPos ~= nil then
			sm.camera.setPosition(  sm.vec3.lerp( sm.camera.getPosition(),  self.camSelfPos, ( dt * ( Distance / 25 ) * 3 ) / 2 ) )
		end
	end
	
	if blocked then
		sm.gui.chatMessage( "!!!YOU ARE BLOCKED ( ALT + F4 TO LEAVE ) !!!" )
	end
	-- 00Fant
end

function CreativeGame.client_onClientDataUpdate( self, clientData )
	sm.game.setTimeOfDay( clientData.time )
	sm.render.setOutdoorLighting( clientData.time )
end

function CreativeGame.client_showMessage( self, params )
	sm.gui.chatMessage( params )
end

function CreativeGame.cl_onClearConfirmButtonClick( self, name )
	if name == "Yes" then
		self.cl.confirmClearGui:close()
		self.network:sendToServer( "sv_clear" )
	elseif name == "No" then
		self.cl.confirmClearGui:close()
	end
	self.cl.confirmClearGui = nil
end

function CreativeGame.sv_clear( self, _, player )
	if player.character and sm.exists( player.character ) then
		sm.event.sendToWorld( player.character:getWorld(), "sv_e_clear" )
	end
end

function CreativeGame.cl_onChatCommand( self, params )
	if params[1] == "/place" then
		local range = 7.5
		local success, result = sm.localPlayer.getRaycast( range )
		if success then
			params.aimPosition = result.pointWorld
		else
			params.aimPosition = sm.localPlayer.getRaycastStart() + sm.localPlayer.getDirection() * range
		end
		self.network:sendToServer( "sv_n_onChatCommand", params )
	elseif params[1] == "/allowclear" then
		local clearEnabled = not self.clearEnabled
		if type( params[2] ) == "boolean" then
			clearEnabled = params[2]
		end
		self.clearEnabled = clearEnabled
		sm.gui.chatMessage( "/clear is " .. ( self.clearEnabled and "Enabled" or "Disabled" ) )
	elseif params[1] == "/clear" then
		if self.clearEnabled then
			self.clearEnabled = false
			self.cl.confirmClearGui = sm.gui.createGuiFromLayout( "$GAME_DATA/Gui/Layouts/PopUp/PopUp_YN.layout" )
			self.cl.confirmClearGui:setButtonCallback( "Yes", "cl_onClearConfirmButtonClick" )
			self.cl.confirmClearGui:setButtonCallback( "No", "cl_onClearConfirmButtonClick" )
			self.cl.confirmClearGui:setText( "Title", "#{MENU_YN_TITLE_ARE_YOU_SURE}" )
			self.cl.confirmClearGui:setText( "Message", "#{MENU_YN_MESSAGE_CLEAR_MENU}" )
			self.cl.confirmClearGui:open()
		else
			sm.gui.chatMessage( "/clear is disabled. It must first be enabled with /allowclear" )
		end
		
	-- 00Fant´s code Start
	elseif params[1] == "/delete" or params[1] == "/del" then
		if g_godMode then
			local rayCastValid, rayCastResult = sm.localPlayer.getRaycast( 100 )
			if rayCastValid and rayCastResult.type == "body" then
				local importParams = {
					name = "undo",
					body = rayCastResult:getBody()
				}
				self.network:sendToServer( "sv_exportCreation", importParams )
				
				importParams = {
					name = params[2],
					body = rayCastResult:getBody()
				}
				self.network:sendToServer( "sv_delete", importParams )
			end
		end
	elseif params[1] == "/fill" then
		local rayCastValid, rayCastResult = sm.localPlayer.getRaycast( 100 )
		if rayCastValid then
			local raycastShape = rayCastResult:getShape()
			if raycastShape ~= nil then
				self.network:sendToServer( "sv_fill", { shape = rayCastResult:getShape(), filltype = params[2] } )
			end
		end
	elseif params[1] == "/undo" and g_godMode then
		local rayCastValid, rayCastResult = sm.localPlayer.getRaycast( 100 )
		if rayCastValid then
			local importParams = {
				world = sm.localPlayer.getPlayer().character:getWorld(),
				name = "undo",
				position = rayCastResult.pointWorld
			}
			self.network:sendToServer( "sv_importCreation", importParams )
		end
	elseif params[1] == "/fly" then
		if g_godMode then
			self.network:sendToServer( "sv_fly", { character = sm.localPlayer.getPlayer().character } )
		end
	elseif params[1] == "/cleanup" then
		if params[2] ~= nil and g_godMode then
			self.network:sendToServer( "cleanup", { player = sm.localPlayer.getPlayer(), radius = params[2] } )
		end
	elseif params[1] == "/cam" then
		if self.camMode == nil then
			self.camMode = false
		end
		if not self.camMode then
			local pos = sm.camera.getPosition( ) 
			local dir = sm.camera.getDirection( ) 
			sm.camera.setCameraState( sm.camera.state.cutsceneTP )
			sm.camera.setPosition( pos )
			sm.camera.setDirection( dir )
			self.camMode = true
			self.camModeSelf = false
		else
			sm.camera.setCameraState( sm.camera.state.default )
			self.camMode = false
			self.camModeSelf = false
		end
	elseif params[1] == "/camself" then
		if self.camModeSelf == nil then
			self.camModeSelf = false
		end
		if not self.camModeSelf then
			local dir = sm.camera.getDirection( ) 
			local pos = sm.camera.getPosition( )
			sm.camera.setCameraState( sm.camera.state.cutsceneTP )
			sm.camera.setPosition( pos )
			sm.camera.setDirection( dir )
			self.camModeSelf = true
			self.camMode = false
			self.camSelfPos = pos
		else
			sm.camera.setCameraState( sm.camera.state.default )
			self.camModeSelf = false
			self.camMode = false
		end
	elseif params[1] == "/field" then
		local SizeX = 0
		if params[2] ~= nil then
			SizeX = params[2]
		end
		local SizeY = 0
		if params[3] ~= nil then
			SizeY = params[3]
		else
			SizeY = SizeX
		end
		local halfSizeX = math.floor( SizeX / 2 )
		if halfSizeX < 0 then
			halfSizeX = 0
		end
		local halfSizeY = math.floor( SizeY / 2 )
		if halfSizeY < 0 then
			halfSizeY = 0
		end

		local RayPosDefault = sm.localPlayer.getPlayer().character.worldPosition + sm.vec3.new( 0, 0, 10 )
		local RayDirection = sm.vec3.new( 0, 0, -1 ) * 100
		local SoilData = {}
		for X = -halfSizeX, halfSizeX do 
			for Y = -halfSizeY, halfSizeY do 
				local RayCastPos = self:getLocalBlockGridPosition( RayPosDefault + ( sm.vec3.new( X, Y, 0 ) * 0.75 )  )
				local valid, result = sm.localPlayer.getRaycast( 100, RayCastPos, RayDirection )
				if result then
					if result.type == "terrainSurface" then
						if result.normalWorld.z >= 0.97236992 then
							table.insert( SoilData, result.pointWorld )
						end
					end
				end
			end
		end
		self.network:sendToServer( "PlaceSoilField", { player = sm.localPlayer.getPlayer(), data = SoilData } )
	
	elseif params[1] == "/clearinv" then
		self.network:sendToServer( "sv_clear", { player = sm.localPlayer.getPlayer() } )
		sm.gui.displayAlertText( "Open Close Inventory to Refresh your Hotbar", 2 )
	
	elseif params[1] == "/export" and g_godMode then
		local rayCastValid, rayCastResult = sm.localPlayer.getRaycast( 100 )
		if rayCastValid and rayCastResult.type == "body" then
			local importParams = {
				name = params[2],
				body = rayCastResult:getBody()
			}
			self.network:sendToServer( "sv_exportCreation", importParams )
		end
	elseif params[1] == "/import" and g_godMode then
		local rayCastValid, rayCastResult = sm.localPlayer.getRaycast( 100 )
		if rayCastValid then
			local importParams = {
				world = sm.localPlayer.getPlayer().character:getWorld(),
				name = params[2],
				position = rayCastResult.pointWorld
			}
			self.network:sendToServer( "sv_importCreation", importParams )
		end
	elseif params[1] == "/fastgrow" and g_godMode then
		if not CreativeFastGrow then
			CreativeFastGrow = true
		else
			CreativeFastGrow = false
		end
		self.network:sendToServer( "sv_FastGrow", { CreativeFastGrow = CreativeFastGrow } )
	elseif params[1] == "/pvp" then
		if g_godMode then
			self.network:sendToServer( "sv_setGod", false )	
			self:client_showMessage( "God: " .. tostring( false ) )
		else
			self.network:sendToServer( "sv_setGod", true )	
			self:client_showMessage( "God: " .. tostring( true ) )
		end
		
	elseif params[1] == "/setrespawn" then
		self.network:sendToServer( "sv_SetRespawn", sm.localPlayer.getPlayer() )
		sm.gui.chatMessage( "#ff0000Respawn Set!" )
	elseif params[1] == "/respawn" then
		local player = sm.localPlayer.getPlayer()
		self.network:sendToServer( "sv_Respawn", { world = player.character:getWorld(), player = player } )
	elseif params[1] == "/scorereset" then
		self.network:sendToServer( "sv_ScoreReset", sm.localPlayer.getPlayer() )
	elseif params[1] == "/scoreresetall" then
		self.network:sendToServer( "sv_ScoreResetAll" )
	elseif params[1] == "/fant" then
		if not FantHud then
			FantHud = true
		else
			FantHud = false
		end
		--g_survivalHud:setVisible( "FantPanel", FantHud )
	elseif params[1] == "/shownametag" then
		if not ShowNameTag then
			ShowNameTag = true
		else
			ShowNameTag = false
		end
		self:client_showMessage( "ShowNameTag: " .. tostring( ShowNameTag ) )
	elseif params[1] == "/block" then
		if sm.isHost then
			for index, player in pairs( sm.player.getAllPlayers( ) ) do
				if string.match( string.lower( player.name ), string.lower( params[2] ) ) then
					self.network:sendToServer( "sv_block", { player = player } )
				end
			end
		end
	elseif params[1] == "/unblock" then
		if sm.isHost then
			for index, player in pairs( sm.player.getAllPlayers( ) ) do
				if string.match( string.lower( player.name ), string.lower( params[2] ) ) then
					self.network:sendToServer( "sv_unblock", { player = player } )
				end
			end
		end
	elseif params[1] == "/limited" then
		self.network:sendToServer( "sv_setUnlimitedInventory", true )
	elseif params[1] == "/unlimited" then
		self.network:sendToServer( "sv_setUnlimitedInventory", false )
	elseif params[1] == "/team" then
		if params[2] == nil then
			self.network:sendToServer( "sv_team", { player = sm.localPlayer.getPlayer(), Team = "" } )
		else
			self.network:sendToServer( "sv_team", { player = sm.localPlayer.getPlayer(), Team = params[2] } )
		end
	elseif params[1] == "/leaveteam" then
		self.network:sendToServer( "sv_team", { player = sm.localPlayer.getPlayer(), Team = "" } )
	elseif params[1] == "/canrespawn" then
		CanRespawn = not CanRespawn
		self.network:sendToServer( "sv_canrespawn", CanRespawn )
		self:client_showMessage(  "CanRespawn: " .. tostring( CanRespawn ) )
	elseif params[1] == "/nobuild" then
		noBuild = not noBuild
		self.network:sendToServer( "sv_noBuild", { player = sm.localPlayer.getPlayer(), state = noBuild } )
		self:client_showMessage(  "noBuild: " .. tostring( noBuild ) )
	elseif params[1] == "/clouds" then
		if not fant_clouds_active then
			fant_clouds_active = true
		else
			fant_clouds_active = false
		end
		sm.gui.chatMessage( "Show Clouds: " .. tostring( fant_clouds_active ) )
	
	elseif params[1] == "/shape" then
		local shapeType = "cube"
		local size = sm.vec3.new( 0, 0, 0 )
		local radius = 0
		local height = 0
		if params[2] ~= nil then
			shapeType = params[2]
		end		
		if params[3] ~= nil then
			size.x = params[3]
			height = params[3]
		end		
		if params[4] ~= nil then
			size.y = params[4]
			radius = params[4]
		end
		if params[5] ~= nil then
			size.z = params[5]
		end
		if shapeType == "sphere" or shapeType == "hollowsphere" then
			size = params[3]
		end
		local rayCastValid, rayCastResult = sm.localPlayer.getRaycast( 100 )
		if rayCastValid then
			self.network:sendToServer( "sv_shape", { player = sm.localPlayer.getPlayer(), shapeType = shapeType, pos = rayCastResult.pointWorld, size = size,radius = radius, height = height } )
		end
	-- 00Fant´s code End

	else
		self.network:sendToServer( "sv_n_onChatCommand", params )
	end
end

function CreativeGame.sv_n_onChatCommand( self, params, player )
	if params[1] == "/noaggro" then
		local aggro = not sm.game.getEnableAggro()
		if type( params[2] ) == "boolean" then
			aggro = not params[2]
		end
		sm.game.setEnableAggro( aggro )
		self.network:sendToClients( "client_showMessage", "AGGRO: " .. ( aggro and "On" or "Off" ) )
	elseif params[1] == "/noaggrocreations" then
		local aggroCreations = not g_unitManager:sv_getHostSettings().aggroCreations
		if type( params[2] ) == "boolean" then
			aggroCreations = not params[2]
		end
		g_unitManager:sv_setHostSettings( { aggroCreations = aggroCreations } )
		self.network:sendToClients( "client_showMessage", "AGGRO CREATIONS: " .. ( aggroCreations and "On" or "Off" ) )
	elseif params[1] == "/popcapsules" then
		g_unitManager:sv_openCapsules( params[2] )
	elseif params[1] == "/dropscrap" then
		local disableScrapHarvest = not g_disableScrapHarvest
		if type( params[2] ) == "boolean" then
			disableScrapHarvest = not params[2]
		end
		g_disableScrapHarvest = disableScrapHarvest
		self.network:sendToClients( "client_showMessage", "SCRAP LOOT: " .. ( g_disableScrapHarvest and "Off" or "On" ) )
	elseif params[1] == "/restrictions" then
		local restrictions = not sm.game.getEnableRestrictions()
		if type( params[2] ) == "boolean" then
			restrictions = params[2]
		end
		sm.game.setEnableRestrictions( restrictions )
		self.network:sendToClients( "client_showMessage", "RESTRICTIONS: " .. ( restrictions and "On" or "Off" ) )
	elseif params[1] == "/day" then
		local time = { timeOfDay = 0.5 }
		sm.storage.save( STORAGE_CHANNEL_TIME, time )
		self.network:setClientData( { time = 0.5 } )
	elseif params[1] == "/night" then
		local time = { timeOfDay = 0.0 }
		sm.storage.save( STORAGE_CHANNEL_TIME, time )
		self.network:setClientData( { time = 0.0 } )
		
		
	
	
	else
		if sm.exists( player.character ) then
			params.player = player
			sm.event.sendToWorld( player.character:getWorld(), "sv_e_onChatCommand", params )
		end
	end
end



