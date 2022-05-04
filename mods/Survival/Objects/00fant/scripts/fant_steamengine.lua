dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")

Fant_Steamengine = class()
Fant_Steamengine.maxParentCount = 2
Fant_Steamengine.maxChildCount = 255
Fant_Steamengine.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power + sm.interactable.connectionType.water
Fant_Steamengine.connectionOutput = sm.interactable.connectionType.bearing
Fant_Steamengine.colorNormal = sm.color.new( 0xff8000ff )
Fant_Steamengine.colorHighlight = sm.color.new( 0xff9f3aff )
Fant_Steamengine.poseWeightCount = 1

Fant_Steamengine.FuelPerItem = {}
Fant_Steamengine.FuelPerItem[tostring(blk_cardboard)] 		= 1
Fant_Steamengine.FuelPerItem[tostring(blk_scrapwood)] 		= 3
Fant_Steamengine.FuelPerItem[tostring(blk_wood1)] 			= 8.5
Fant_Steamengine.FuelPerItem[tostring(obj_resource_ember)] 	= 12
Fant_Steamengine.FuelPerItem[tostring(blk_wood2)] 			= 17
Fant_Steamengine.FuelPerItem[tostring(blk_wood3)] 			= 20
Fant_Steamengine.FuelPerItem[tostring(obj_consumable_gas)] 	= 40

Fant_Steamengine.velocity = 60    -- Here u can change the Torque
Fant_Steamengine.power    = 10000  -- Here the Rotation Speed
Fant_Steamengine.WaterTicksPerFuel = 8

function Fant_Steamengine.server_onCreate( self )
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { gear = 0, fuel = 0, water = 0 }
	end

	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container = self.shape:getInteractable():addContainer( 0, 1, 256 )
	end
	container:setFilters( { blk_scrapwood, blk_wood1, blk_wood2, blk_wood3, obj_resource_ember, obj_consumable_gas, blk_cardboard } )
	self.hasFuel = false
	self.hasFuel_last = nil
	self.gear = self.saved.gear
	self.fuel = self.saved.fuel
	self.water = self.saved.water
	self:server_init()
	self.network:sendToClients( "cl_setGear", self.gear )	
end

function Fant_Steamengine.server_onDestroy( self )
	self.saved = { gear = self.gear, fuel = self.fuel, water = self.water }
	self.storage:save( self.saved )
end

function Fant_Steamengine.server_onRefresh( self )
	self:server_init()
end

function Fant_Steamengine.server_init( self )
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.fuel == nil then
		self.saved.fuel = 0
	end
	self.motorVelocity = 0
	self.motorImpulse = 0
end

function Fant_Steamengine.getInputs( self )
	local parents = self.interactable:getParents()
	local active = false
	local direction = 1
	local hasInput = false
	local waterContainer = nil
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[2]:isActive()
			hasInput = true
		end
		if parents[2]:hasOutputType( sm.interactable.connectionType.power ) then
			active = parents[2]:isActive()
			direction = parents[2]:getPower()
			hasInput = true
		end
		if parents[2]:hasOutputType( sm.interactable.connectionType.water ) then
			waterContainer = parents[2]:getContainer( 0 )
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[1]:isActive()
			hasInput = true
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.power ) then
			active = parents[1]:isActive()
			direction = parents[1]:getPower()
			hasInput = true
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.water ) then
			waterContainer = parents[1]:getContainer( 0 )
		end
	end
	return active, direction, hasInput, waterContainer
end

function Fant_Steamengine.server_onFixedUpdate( self, dt )
	local active, direction, hasInput, waterContainer = self:getInputs()
	if self.gear == 0 and active then
		active = false
	end
	local fuelContainer = self.shape.interactable:getContainer( 0 )

	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	local canSpend = nil
	if self.fuel <= 0 then
		if sm.container.canSpend( fuelContainer, blk_scrapwood, 1 ) then
			canSpend = blk_scrapwood
		elseif sm.container.canSpend( fuelContainer, blk_wood1, 1 ) then
			canSpend = blk_wood1
		elseif sm.container.canSpend( fuelContainer, blk_wood2, 1 ) then
			canSpend = blk_wood2
		elseif sm.container.canSpend( fuelContainer, blk_wood3, 1 ) then
			canSpend = blk_wood3
		elseif sm.container.canSpend( fuelContainer, obj_consumable_gas, 1 ) then
			canSpend = obj_consumable_gas
		elseif sm.container.canSpend( fuelContainer, blk_cardboard, 1 ) then
			canSpend = blk_cardboard
		elseif sm.container.canSpend( fuelContainer, obj_resource_ember, 1 ) then
			canSpend = obj_resource_ember
		end
	end
	
	local hasWater = false
	if waterContainer ~= nil then
		hasWater = sm.container.canSpend( waterContainer, obj_consumable_water, 1 )
	end
	
	if self.fuel <= 0 then
		if self.water <= 0 then
			if hasWater then
				sm.container.beginTransaction()
				sm.container.spend( waterContainer, obj_consumable_water, 1, true )
				if sm.container.endTransaction() then
					self.water = self.WaterTicksPerFuel
				end
			end
		end
		if self.water > 0 then
			if canSpend ~= nil then
				sm.container.beginTransaction()
				sm.container.spend( fuelContainer, canSpend, 1, true )
				if sm.container.endTransaction() then
					self.water = self.water -1
					self.fuel = self.fuel + self.FuelPerItem[tostring(canSpend)]
				end
			end
		end
	end
	
	if not self.hasFuel and self.fuel > 0 then
		self.hasFuel = true
	end
	if self.hasFuel and self.fuel <= 0 then
		self.hasFuel = false
	end
	if self.hasFuel_last ~= self.hasFuel then
		self.hasFuel_last = self.hasFuel
		self.network:sendToClients( "SetHasFuel", self.hasFuel )	
	end
	
	if self.fuel > 0 and active then
		self:controlEngine( direction, active )
		local appliedImpulseCost = 0.015625
		local fuelCost = 0
		for _, bearing in ipairs( bearings ) do
			if bearing.appliedImpulse * bearing.angularVelocity < 0 then -- No added fuel cost if the bearing is decelerating
				fuelCost = 1 + math.abs( bearing.appliedImpulse ) * appliedImpulseCost
			end
		end
		if fuelCost > 0 then
			fuelCost = fuelCost * ( ( 0.1 + ( self.gear / 25 ) ) * dt )
		else
			fuelCost = 0
		end
		self.fuel = self.fuel - fuelCost
		if self.fuel < 0 then
			 self.fuel = 0
		end
	else
		self:controlEngine( 0, hasInput )
	end
	for _, bearing in ipairs( bearings ) do
		bearing:setMotorVelocity( self.motorVelocity, self.motorImpulse )
	end
end

function Fant_Steamengine.SetHasFuel( self, hasFuelData )
	self.hasFuel = hasFuelData
end

function Fant_Steamengine.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Steam Engine" )
		self.gui:setText( "Interaction", "Needs Wood / Ember as Fuel" )
		self.gui:setText( "SubTitle", "Power " .. tostring(self.gear) )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setSliderData( "Setting", 10, self.gear )
		self.gui:setIconImage( "Icon", obj_interactive_fant_steamengine )
		
		local fuelContainer = self.shape.interactable:getContainer( 0 )

		if fuelContainer then
			self.gui:setContainer( "Fuel", fuelContainer )
		end
		self.gui:open()
	end
end

function Fant_Steamengine.cl_onSliderChange( self, sliderName, sliderPos )
	self.gear = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "SubTitle", "Power " .. tostring(self.gear) )
	end
	self.network:sendToServer( "sv_setGear", self.gear )
end

function Fant_Steamengine.sv_setGear( self, gear )
	self.gear = gear
	self.saved = { gear = self.gear, fuel = self.fuel, water = self.water }
	self.storage:save( self.saved )
end

function Fant_Steamengine.cl_setGear( self, gear )
	self.gear = gear
end

function Fant_Steamengine.cl_onGuiClosed( self )
	self.network:sendToServer( "sv_setGear", self.gear )
	self.gui:destroy()
	self.gui = nil
end

function Fant_Steamengine.client_getAvailableParentConnectionCount( self, connectionType )
	if bit.band( connectionType, bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.power ) ) ~= 0 then
		return 1 - #self.interactable:getParents( bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.power ) )
	end
	if bit.band( connectionType, sm.interactable.connectionType.water ) ~= 0 then
		return 1 - #self.interactable:getParents( sm.interactable.connectionType.water )
	end
	return 0
end

function Fant_Steamengine.client_getAvailableChildConnectionCount( self, connectionType )
	if connectionType ~= sm.interactable.connectionType.bearing then
		return 0
	end
	local maxBearingCount = 255
	return maxBearingCount - #self.interactable:getChildren( sm.interactable.connectionType.bearing )
end

function Fant_Steamengine.controlEngine( self, direction, active )
	if active and direction ~= 0 and self.gear > 0 then
		self.motorVelocity = clamp( direction, -1, 1 ) * math.rad( self.velocity ) * self.gear
		self.motorImpulse = self.power
	else
		self.motorVelocity = 0
		self.motorImpulse = self.power
	end
end

function Fant_Steamengine.client_onCreate( self )
	self.gear = 0
	self.PoseValue = 0
	self.PoseDirection = 1
	self.smoke_effect = sm.effect.createEffect(  "Smoke - pillar02", nil )
	self.sound_effect = sm.effect.createEffect(  "GasEngine - Level 2", self.interactable )
end

function Fant_Steamengine.client_onFixedUpdate( self, dt )
	local active, direction, hasInput, watercontainer = self:getInputs()
	local pos = self.shape.worldPosition + ( self.shape.getAt( self.shape ) * 0.9 ) + ( self.shape.getUp( self.shape ) * 0.1 )	
	if self.gear == 0 and active then
		active = false
	end
	if active and direction ~= 0 and self.hasFuel then		
		self.PoseValue = self.PoseValue + ( dt * self.PoseDirection * ( self.gear / 3 ) )			
		if self.PoseValue >= 1 then
			self.PoseValue = 1
			self.PoseDirection = -1
			sm.effect.playEffect( "Steam - quench", pos, sm.vec3.new( 0, 0, 0 ), sm.quat.identity() )
		end
		if self.PoseValue <= 0 then
			self.PoseValue = 0
			self.PoseDirection = 1
			sm.effect.playEffect( "Steam - quench", pos, sm.vec3.new( 0, 0, 0 ), sm.quat.identity() )
		end
		if not self.smoke_effect:isPlaying() then
			self.smoke_effect:start()
			self.sound_effect:start()
		end
	else
		if self.smoke_effect:isPlaying() then
			self.smoke_effect:stop()
			self.sound_effect:stop()
		end
	end
	
	if self.smoke_effect:isPlaying() then	
		self.sound_effect:setParameter( "rpm", 0.10 + ( self.gear / 50 ) )
		self.sound_effect:setParameter( "load", 1 )
		self.smoke_effect:setPosition( pos )
		self.smoke_effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.shape.getAt( self.shape ) ) )
	end
	
	self.shape:getInteractable():setPoseWeight( 0, self.PoseValue )

	if not sm.isHost then
		-- Check bearings
		local bearings = {}
		local joints = self.interactable:getJoints()
		for _, joint in ipairs( joints ) do
			if joint:getType() == "bearing" then
				bearings[#bearings+1] = joint
			end
		end

		-- Control engine
		if self.hasFuel then
			self:controlEngine( direction, active )
		else
			self:controlEngine( 0, hasInput )
		end

		-- Update rotational joints
		for _, bearing in ipairs( bearings ) do
			bearing:setMotorVelocity( self.motorVelocity, self.motorImpulse )
		end
	end
end

