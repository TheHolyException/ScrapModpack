Fant_Campfire = class()
Fant_Campfire.poseWeightCount = 2
Fant_Campfire.RostingTimeInSeconds = 40
Fant_Campfire.maxParentCount = 1
Fant_Campfire.connectionInput = sm.interactable.connectionType.logic

function Fant_Campfire.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { state = false, hasSteak = false, isRosted = false } 
		self.storage:save( self.sv.storage )
	end
	self.state = self.sv.storage.state
	self.hasSteak = self.sv.storage.hasSteak
	self.isRosted = self.sv.storage.isRosted
	self.last_state = false
	self.last_hasSteak = false
	self.last_isRosted = false
	self.rostTime = 0
	self.isRosting = false
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 1 )
	end
	self.container:setFilters( { obj_consumable_fant_steak, obj_resource_steak } )
end

function Fant_Campfire.client_onCreate( self )
	self.sv = {}
	self.Effect = sm.effect.createEffect( "Smoke - blowing01", self )
	--self.Effect2 = sm.effect.createEffect( "Fire - small01", self )
	self.Effect2 = sm.effect.createEffect( "ShipFire - medium01", self )
	self.network:sendToServer( "GetData" )
end

function Fant_Campfire.GetData( self )
	self.network:sendToClients( "UpdateCampfire", { state = self.state, isRosted = self.isRosted, hasSteak = self.hasSteak } )		
end

function Fant_Campfire.client_onInteract(self, _, state)
	if state == true then
		if self.container == nil then
			self.container = self.shape:getInteractable():getContainer(0)
		end
		self.gui = sm.gui.createContainerGui( true )				
		self.gui:setText( "UpperName", "Campfire" )
		self.gui:setContainer( "UpperGrid", self.container )				
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
		self.network:sendToServer( "SetData", { state = self.state, isRosted = self.isRosted, hasSteak = self.hasSteak } )	
	end
end

function Fant_Campfire.SetData( self, data )
	self.state = data.state
	self.hasSteak = data.hasSteak
	self.isRosted = data.isRosted
	self.network:sendToClients( "UpdateCampfire", data )		
end

function Fant_Campfire.UpdateCampfire( self, data )
	self.state = data.state
	if self.state then
		self.Effect:start()			
		self.Effect2:start()			
	else
		self.Effect:stop()	
		self.Effect2:stop()			
	end
	self.hasSteak = data.hasSteak
	if self.hasSteak then
		self.shape:getInteractable():setPoseWeight( 0, 1 )
	else
		self.shape:getInteractable():setPoseWeight( 0, 0 )
	end
	self.isRosted = data.isRosted
	if self.isRosted then
		self.interactable:setUvFrameIndex( 1 )
	else
		self.interactable:setUvFrameIndex( 0 )
	end
end

function Fant_Campfire.server_onFixedUpdate( self )
	
	
	local item = self.container:getItem( 0 )	
	local hasSteak = false
	if item then
		if item.quantity > 0 then
			hasSteak = true
			if item.uuid == obj_resource_steak then
				self.isRosted = false			
			elseif item.uuid == obj_consumable_fant_steak then
				self.isRosted = true
			end
		end
	end
	self.hasSteak = hasSteak
		
	if self.hasSteak and not self.isRosting and not self.isRosted then
		self.isRosting = true
		self.state = true
		self.rostTime = self.RostingTimeInSeconds
	end	
	if not self.hasSteak and self.isRosting then
		self.isRosting = false
		self.state = false
		self.rostTime = 0
	end	
	if self.hasSteak and self.isRosting and self.rostTime >= 0 then
		self.rostTime = self.rostTime - (1/40)
		if self.rostTime <= 0 then
			self.isRosting = false
			self.rostTime = 0
			self.isRosted = true			 
			sm.container.beginTransaction()
			sm.container.spend( self.container, obj_resource_steak, 1, true )
			if sm.container.endTransaction() then
				sm.container.beginTransaction()
				sm.container.collect( self.container, obj_consumable_fant_steak, 1, true)	
				sm.container.endTransaction()	
				self.state = false				
			end		
		end
	end
	local hasChanged = false
	if self.last_hasSteak ~= self.hasSteak then
		self.last_hasSteak = self.hasSteak
		hasChanged = true
	end
	if self.last_isRosted ~= self.isRosted then
		self.last_isRosted = self.isRosted
		hasChanged = true
	end
	if self.last_state ~= self.state then
		self.last_state = self.state
		hasChanged = true
	end
	local parent = self.shape:getInteractable():getSingleParent()
	if parent then
		if parent.active ~= self.state then
			self.state = parent.active
		end			
	end	
	if hasChanged then
		self.network:sendToClients( "UpdateCampfire", { state = self.state, isRosted = self.isRosted, hasSteak = self.hasSteak } )	
	end
	
end

function Fant_Campfire.client_onUpdate( self, dt )
	if self.state then
		self.Effect:setPosition( self.shape.worldPosition - ( sm.shape.getUp( self.shape ) * 0.25 ) + ( sm.shape.getAt( self.shape ) * 0.4 ) )
		self.Effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.shape.getAt( self.shape ) ) )
		self.Effect2:setPosition( self.shape.worldPosition - ( sm.shape.getAt( self.shape ) * 0.3 ) )
		self.Effect2:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.shape.getAt( self.shape ) ) )
	end	
end

function Fant_Campfire.client_onDestroy( self )
	self.Effect:stop()	
	self.Effect2:stop()	
end

function Fant_Campfire.server_onDestroy( self )
	self.sv.storage = { state = self.state, isRosted = self.isRosted, hasSteak = self.hasSteak }
	self.storage:save( self.sv.storage )
end


