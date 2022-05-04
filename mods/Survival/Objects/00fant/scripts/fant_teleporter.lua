dofile "$SURVIVAL_DATA/Scripts/game/SurvivalGame.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"

BatterieConsumeOnTeleport = 20
MinimalUseDistance = 1
Fant_Teleporter = class()
Fant_Teleporter.spawnPosition = nil
g_Teleporter = g_Teleporter or {}
Fant_Teleporter.maxParentCount = 1
Fant_Teleporter.connectionInput = sm.interactable.connectionType.electricity
Fant_Teleporter.PortDelay = 0
Fant_Teleporter.PortData = {}

function Fant_Teleporter.server_onCreate( self )
	if self:IsStatic() == false then
		return
	end 
	
	local count = 0
	for indexPos, parameter in pairs( g_Teleporter ) do
		count = count + 1
	end
	if count <= 0 then
		g_Teleporter = self.storage:load()
	end
	if g_Teleporter == nil then
		g_Teleporter = {}
	end
	
	
	self.spawnPosition = sm.vec3.new( math.floor( self.shape.worldPosition.x ),  math.floor( self.shape.worldPosition.y ),  math.floor( self.shape.worldPosition.z ) )
	g_Teleporter[ tostring( self.spawnPosition ) ] = { position = self.shape.worldPosition, color = tostring( sm.shape.getColor( self.shape ) ) }
	self.storage:save( g_Teleporter )
	self.loaded = true
	
	-- count = 0
	-- for indexPos, parameter in pairs( g_Teleporter ) do
		-- count = count + 1
	-- end
	
	-- print( tostring( self.shape ) .. " - onCreate Teleporter: " ..tostring( count ) )
end

function Fant_Teleporter.server_onUnload( self )
	if self.loaded then
		self.loaded = false
	end
	--self.storage:save( g_Teleporter )
	-- local count = 0
	-- for indexPos, parameter in pairs( g_Teleporter ) do
		-- count = count + 1
	-- end
	-- print( "Unload Teleporter: " ..tostring( count ) )
end

function Fant_Teleporter.server_onDestroy( self )
	if self.loaded then
		g_Teleporter[ tostring( self.spawnPosition ) ] = nil
		self.storage:save( g_Teleporter )
		-- local count = 0
		-- for indexPos, parameter in pairs( g_Teleporter ) do
			-- count = count + 1
		-- end
		-- print( "Destroy Teleporter: " ..tostring( count ) )
	end
	
end

function Fant_Teleporter.IsStatic( self )
	return sm.body.isStatic( sm.shape.getBody( self.shape ) ) 
end

function Fant_Teleporter.Teleport( self, data )
	if self:IsStatic() == false then
		return
	end 
	if self.PortDelay > 0 then
		return
	end
	
	self.spawnPosition = sm.vec3.new( math.floor( self.shape.worldPosition.x ),  math.floor( self.shape.worldPosition.y ),  math.floor( self.shape.worldPosition.z ) )
	g_Teleporter[ tostring( self.spawnPosition ) ] = { position = self.shape.worldPosition, color = tostring( sm.shape.getColor( self.shape ) ) }
	
	
	local selfColor = tostring( sm.shape.getColor( self.shape ) )
	local TeleporterTarget = {}
	local counter = 0
	for indexPos, parameter in pairs( g_Teleporter ) do
		if indexPos ~=  tostring( self.spawnPosition ) then
			if selfColor == parameter.color then
				counter = counter + 1
				table.insert( TeleporterTarget, parameter.position )
			end
		end
	end
	if counter == 0 then	
		self.network:sendToClients( "client_NoDestination", data.player )
		return
	end	
	local BatteryContainer = nil
	for i, parent in pairs( self.interactable:getParents() ) do
		if parent:hasOutputType( sm.interactable.connectionType.electricity ) and BatteryContainer == nil then
			BatteryContainer = parent:getContainer( 0 )
		end
	end
	if sm.game.getEnableAmmoConsumption() then
		if BatteryContainer ~= nil and not sm.container.isEmpty( BatteryContainer ) then
			if sm.container.canSpend( BatteryContainer, obj_consumable_battery, BatterieConsumeOnTeleport ) then
				sm.container.beginTransaction()
				sm.container.spend( BatteryContainer, obj_consumable_battery, BatterieConsumeOnTeleport, true )
				if sm.container.endTransaction() then				
					local Destination = TeleporterTarget[ math.floor( math.random( 1, counter ) ) ]
					if isSurvival then
						sm.event.sendToGame( "sv_teleport", { player = data.player, pos = Destination } )	
					end		
					local Dir = data.character:getDirection()
					local yaw = math.atan2( Dir.y, Dir.x ) - math.pi/2
					local pitch = math.asin( Dir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )				
					self.PortData = { pos = Destination, player = data.player, yaw = yaw, pitch = pitch }
					self.PortDelay = 0.5
				end					
			end
		end
	else
		local Destination = TeleporterTarget[ math.floor( math.random( 1, counter ) ) ]
		if isSurvival then
			sm.event.sendToGame( "sv_teleport", { player = data.player, pos = Destination } )	
		end
		local Dir = data.character:getDirection()
		local yaw = math.atan2( Dir.y, Dir.x ) - math.pi/2
		local pitch = math.asin( Dir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )				
		self.PortData = { pos = Destination, player = data.player, yaw = yaw, pitch = pitch }
		self.PortDelay = 0.5
	end
end


function Fant_Teleporter.client_NoDestination( self, player ) 
	if player == sm.localPlayer.getPlayer() then
		sm.gui.displayAlertText( "No destination available!", 2 )
	end
end


function Fant_Teleporter.server_onFixedUpdate( self, dt )
	if self:IsStatic() == false then
		return
	end 
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		self.spawnPosition = sm.vec3.new( math.floor( self.shape.worldPosition.x ),  math.floor( self.shape.worldPosition.y ),  math.floor( self.shape.worldPosition.z ) )
		g_Teleporter[ tostring( self.spawnPosition ) ] = { position = self.shape.worldPosition, color = tostring( sm.shape.getColor( self.shape ) ) }
		self.storage:save( g_Teleporter )
		
		-- local count = 0
		-- for indexPos, parameter in pairs( g_Teleporter ) do
			-- count = count + 1
		-- end
		-- print( "hasChanged Teleporter: " ..tostring( count ) )
	end
	
	if self.PortData ~= {} then
		if self.PortDelay > 0 then
			self.PortDelay = self.PortDelay - dt
			if self.PortDelay <= 0 then
				self.PortDelay = 0
				local character2 = sm.character.createCharacter( self.PortData.player, sm.world.getCurrentWorld(), self.PortData.pos + sm.vec3.new( 0, 0, 0.1 ), self.PortData.yaw, self.PortData.pitch )
				self.PortData.player:setCharacter( character2 )
				self.network:sendToClients( "DoEffect", self.shape.worldPosition + sm.vec3.new( 0, 0, 0.25 ) )
				self.network:sendToClients( "DoEffect", self.PortData.pos + sm.vec3.new( 0, 0, 0.25 ) )
				sm.event.sendToPlayer( self.PortData.player, "sv_extern_fant_cloth_reset" )
				self.PortData = {}
			end
		end
		
	end
end

function Fant_Teleporter.client_canInteract( self, character )

	local BatteryContainer = nil
	for i, parent in pairs( self.interactable:getParents() ) do
		if parent:hasOutputType( sm.interactable.connectionType.electricity ) and BatteryContainer == nil then
			BatteryContainer = parent:getContainer( 0 )
		end
	end
	if self:IsStatic() then
		if sm.vec3.length( character.worldPosition - self.shape.worldPosition ) > MinimalUseDistance then
			sm.gui.setCenterIcon( "Hit" )
			sm.gui.setInteractionText( "You are Too Far Away!" )
			return false
		else
			if ( BatteryContainer and sm.container.canSpend( BatteryContainer, obj_consumable_battery, BatterieConsumeOnTeleport ) ) or not sm.game.getEnableAmmoConsumption() then
				sm.gui.setCenterIcon( "Use" )
				local keyBindingText =  sm.gui.getKeyBinding( "Use" )
				sm.gui.setInteractionText( "", keyBindingText, "Teleport" )
			else
				sm.gui.setCenterIcon( "Hit" )
				sm.gui.setInteractionText( "Requires Batteries!" )
				return false
			end
		end
	else
		sm.gui.setCenterIcon( "Hit" )
		sm.gui.setInteractionText( "No Moving Teleporters Allowed!" )
		return false
	end 
	
	return true
end

function Fant_Teleporter.client_onInteract( self, character, state )
	if self:IsStatic() == false then
		return
	end 
	if state == true then
		if sm.vec3.length( character.worldPosition - self.shape.worldPosition ) <= MinimalUseDistance then
			self.network:sendToServer( "Teleport", { player = character:getPlayer(), character = character } )
		end
	end
end

function Fant_Teleporter.DoEffect( self, pos )
	sm.effect.playEffect( "Part - Electricity", pos, sm.vec3.new( 0, 0, 0 ), sm.quat.identity() )
end
