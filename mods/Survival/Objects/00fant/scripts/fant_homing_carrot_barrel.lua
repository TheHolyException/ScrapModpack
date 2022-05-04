dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"

Fant_Homing_Carrot_Barrel = class()
Fant_Homing_Carrot_Barrel.maxParentCount = 1
Fant_Homing_Carrot_Barrel.maxChildCount = 0
Fant_Homing_Carrot_Barrel.connectionInput = sm.interactable.connectionType.logic
Fant_Homing_Carrot_Barrel.connectionOutput = sm.interactable.connectionType.none
Fant_Homing_Carrot_Barrel.colorNormal = sm.color.new( 0xcb0a00ff )
Fant_Homing_Carrot_Barrel.colorHighlight = sm.color.new( 0xee0a00ff )
Fant_Homing_Carrot_Barrel.tickDelay = 0.25
Fant_Homing_Carrot_Barrel.FireDelay = 0.5
Fant_Homing_Carrot_Barrel.modes = {
	"all",
	"robots",
	"player",
	"creation"
}

function Fant_Homing_Carrot_Barrel.server_onCreate( self )
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 4, 1 )
	end
	self.container:setFilters( { obj_fant_homing_carrot } )
	
	self.sv_tick = 0
	self.saved = self.storage:load()
	self.sv_character = nil
	
	if self.saved == nil then
		self.saved = { characterName = "", sv_modeIndex = 1 }
	end
	
	if self.saved.characterName ~= "" then
		local players = sm.player.getAllPlayers()
		for index, player in pairs( players ) do
			if player.name == self.saved.characterName then
				self.sv_character = player.character
				break
			end
		end	
	end
	
	
	self.sv_modeIndex = self.saved.sv_modeIndex
	self.sv_mode = self.modes[ self.sv_modeIndex ]
	self.network:sendToClients( "cl_change_Mode", { index = self.sv_modeIndex, character = self.sv_character } )
	
end

function Fant_Homing_Carrot_Barrel.client_onCreate( self )
	self.cl_container = self.shape:getInteractable():getContainer(0)	
	for i = 0, 3 do  
		self.interactable:setAnimEnabled( "fire_" .. tostring(i), true )	
		self.interactable:setAnimProgress( "fire_" .. tostring(i), 1 )
	end
	self:cl_update_Carrots()
	self.cl_tick = 0
	self.cl_mode = "all"
	self.cl_modeIndex = 1
	self.cl_character = nil
end

function Fant_Homing_Carrot_Barrel.server_onFixedUpdate( self, dt )
	if self.sv_tick > 0 then
		self.sv_tick = self.sv_tick - dt
		return
	end
	if self:getInputs() == false then
		return
	end
	if self.container == nil then
		return
	end
	local AmmoConsume = sm.game.getEnableAmmoConsumption()
	if AmmoConsume then
		if not self.container:isEmpty() then	
			if sm.container.canSpend( self.container, obj_fant_homing_carrot, 1 ) then
				sm.container.beginTransaction()
				sm.container.spend( self.container, obj_fant_homing_carrot, 1, true )
				if sm.container.endTransaction() then
					self:sv_fire_carrot()
					self.sv_tick = self.FireDelay
				end
			end
		end
	else
		self:sv_fire_carrot()
		self.sv_tick = self.FireDelay
	end
end

function Fant_Homing_Carrot_Barrel.client_onUpdate( self, dt )
	if self.cl_tick > 0 then
		self.cl_tick = self.cl_tick - dt
		return
	end
	self.cl_tick = self.tickDelay
	self:cl_update_Carrots()
end

function Fant_Homing_Carrot_Barrel.getInputs( self )
	for index, parent in pairs( self.interactable:getParents() ) do 
		if parent then
			return parent:isActive()
		end
	end
	return false
end

function Fant_Homing_Carrot_Barrel.sv_fire_carrot( self )
	local body = sm.shape.getBody( self.shape )
	local vel = sm.vec3.new( 0, 0, 0 )
	if body then
		vel = sm.vec3.new( body.velocity.x, body.velocity.z, body.velocity.y ) / 100
	end
	local spawnposition = vel + self.shape.worldPosition + ( sm.shape.getRight( self.shape ) * 1.5 )  + ( sm.shape.getUp( self.shape ) * -0.125 )   + ( sm.shape.getAt( self.shape ) * -0.1 ) 
	local carrot = sm.shape.createPart( obj_fant_homing_carrot, spawnposition, self.shape.worldRotation, true, true ) 	

	sm.interactable.setPublicData( sm.shape.getInteractable( carrot ), { mode = self.sv_mode, ownerCharacter = self.sv_character, sourceShape = self.shape } )
	
	self.network:sendToClients( "cl_fire_carrot" )
end

function Fant_Homing_Carrot_Barrel.cl_fire_carrot( self )
	self:cl_update_Carrots()
end

function Fant_Homing_Carrot_Barrel.getCarrots( self, container )
	if not sm.game.getEnableAmmoConsumption() then
		return 4
	end
	local carrots_left = 0
	if container ~= nil then
		if not container:isEmpty() then
			for Slot = 0, container:getSize() do									
				local Item = container:getItem( Slot )
				if Item then
					if Item.quantity > 0 then
						carrots_left = carrots_left + Item.quantity
					end
				end
			end
		end
	end
	return carrots_left
end

function Fant_Homing_Carrot_Barrel.cl_update_Carrots( self )
	local carrots = self:getCarrots( self.cl_container )
	for i = 0, 3 do  
		if carrots > i then
			self.interactable:setAnimProgress( "fire_" .. tostring(i), 0.01 )
		else
			self.interactable:setAnimProgress( "fire_" .. tostring(i), 1 )
		end
	end
end

function Fant_Homing_Carrot_Barrel.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	
	local name = "NoOwner"
	if self.cl_character ~= nil then
		local player = self.cl_character:getPlayer()
		if player ~= nil then
			name = player.name
		end
	end
	if self.cl_mode == nil then
		self.cl_mode = "All"
	end
	sm.gui.setInteractionText( "", keyBindingText, "Ammo Container - " .. name )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. self.cl_mode  )
	return true
end

function Fant_Homing_Carrot_Barrel.client_onInteract(self, character, state)
	if state == true then
		self.cl_container = self.shape:getInteractable():getContainer(0)	
		if self.cl_container ~= nil then
			self.gui = sm.gui.createContainerGui( true )
			self.gui:setText( "UpperName", "Homing Carrots" )
			self.gui:setContainer( "UpperGrid", self.cl_container )		
			self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
			self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
			self.gui:open()
		end
		self.network:sendToServer( "sv_setCharacter", { character = character } )
	end
end

function Fant_Homing_Carrot_Barrel.client_onTinker( self, character, state )
	if state then
		self.network:sendToServer( "sv_change_Mode", { character = character } )
	end
end

function Fant_Homing_Carrot_Barrel.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Fant_Homing_Carrot_Barrel.sv_setCharacter( self, data )
	self.sv_character = data.character
	self.sv_mode = self.modes[ self.sv_modeIndex ]
	self.network:sendToClients( "cl_change_Mode", { index = self.sv_modeIndex, character = self.sv_character } )
	
	self.storage:save( { characterName = self.sv_character:getPlayer().name, sv_modeIndex = self.sv_modeIndex } )
end

function Fant_Homing_Carrot_Barrel.sv_change_Mode( self, data )
	self.sv_character = data.character
	self.sv_modeIndex = self.sv_modeIndex + 1
	local count = 0
	for i,k in pairs( self.modes ) do
		count = count + 1
	end
	
	if self.sv_modeIndex > count then
		self.sv_modeIndex = 1
	end
	self.sv_mode = self.modes[ self.sv_modeIndex ]
	self.network:sendToClients( "cl_change_Mode", { index = self.sv_modeIndex, character = self.sv_character } )
	
	self.storage:save( { characterName = self.sv_character:getPlayer().name, sv_modeIndex = self.sv_modeIndex } )
end

function Fant_Homing_Carrot_Barrel.cl_change_Mode( self, data )
	self.cl_modeIndex = data.index
	self.cl_mode = self.modes[ self.cl_modeIndex ]
	self.cl_character = data.character
end






