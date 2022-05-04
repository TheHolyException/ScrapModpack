-- GasEngine.lua --
dofile("$SURVIVAL_DATA/Scripts/game/survival_constants.lua")
dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")

Fant_C_Engine = class()
Fant_C_Engine.maxParentCount = 6
Fant_C_Engine.maxChildCount = 255
Fant_C_Engine.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power + sm.interactable.connectionType.gasoline
Fant_C_Engine.connectionOutput = sm.interactable.connectionType.bearing
Fant_C_Engine.colorNormal = sm.color.new( 0xff8000ff )
Fant_C_Engine.colorHighlight = sm.color.new( 0xff9f3aff )
Fant_C_Engine.poseWeightCount = 1

g_Engine_Gears = g_Engine_Gears or {}

local RadPerSecond_100KmPerHourOn3BlockDiameterTyres = 100 --74.074074

local Gears = {
	{ power = 0,    velocity = 1 },    -- 1
	{ power = 7000, velocity = RadPerSecond_100KmPerHourOn3BlockDiameterTyres / 5 },  -- 2
	{ power = 5000, velocity = RadPerSecond_100KmPerHourOn3BlockDiameterTyres / 3.5 },  -- 3
	{ power = 4000, velocity = RadPerSecond_100KmPerHourOn3BlockDiameterTyres / 2.5 }, -- 4
	{ power = 2000, velocity = RadPerSecond_100KmPerHourOn3BlockDiameterTyres / 1.5 }, -- 5
	{ power = 1000,  velocity = RadPerSecond_100KmPerHourOn3BlockDiameterTyres  }, -- 6
	{ power = 850,  velocity = RadPerSecond_100KmPerHourOn3BlockDiameterTyres * 2 }, -- 7
	{ power = 650,  velocity = RadPerSecond_100KmPerHourOn3BlockDiameterTyres * 3 }, -- 8
}


local EngineLevels = {
	[tostring(obj_interactive_fant_c_engine_v8)] = {
		gears = Gears,
		effect = "GasEngine - Level 3",
		upgrade = tostring(obj_interactive_fant_c_engine_v8),
		cost = 8,
		title = "#{LEVEL} 3",
		gearCount = #Gears,
		bearingCount = 256,
		pointsPerFuel = 15000
	},
	[tostring(obj_interactive_fant_c_engine_v8_rotary)] = {
		gears = Gears,
		effect = "GasEngine - Level 3",
		upgrade = tostring(obj_interactive_fant_c_engine_v8_rotary),
		cost = 8,
		title = "#{LEVEL} 3",
		gearCount = #Gears,
		bearingCount = 256,
		pointsPerFuel = 15000
	}
}


--[[ Server ]]

function Fant_C_Engine.server_onCreate( self )
	local container = self.shape.interactable:getContainer( 0 )
	if not container then
		container = self.shape:getInteractable():addContainer( 0, 1, 10 )
	end
	container:setFilters( { obj_consumable_gas } )

	self.last_inputBreak = false
	self.last_inputClutch = false
	self.last_inputGearUp = false
	self.last_inputGearDown = false
	
	self.level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	assert(self.level)
	if self.level.fn then
		self.level.fn( self )
	end

	self.scrapOffset = 0
	
	self.pointsPerFuel = self.level.pointsPerFuel
	self.gears = self.level.gears
	self:server_init()
end

function Fant_C_Engine.server_onRefresh( self )
	self:server_init()
end

function Fant_C_Engine.server_init( self )

	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.gearIdx == nil then
		self.saved.gearIdx = 1
	end
	if self.saved.fuelPoints == nil then
		self.saved.fuelPoints = 0
	end

	self.power = 0
	self.motorVelocity = 0
	self.motorImpulse = 0
	self.fuelPoints = self.saved.fuelPoints
	self.hasFuel = false
	self.dirtyStorageTable = false
	self.dirtyClientTable = false

	self:sv_setGear( self.saved.gearIdx )
end

function Fant_C_Engine.sv_setGear( self, gearIdx )
	self.saved.gearIdx = gearIdx
	self.dirtyStorageTable = true
	self.dirtyClientTable = true
	
end

function Fant_C_Engine.sv_updateFuelStatus( self, fuelContainer )

	if self.saved.fuelPoints ~= self.fuelPoints then
		self.saved.fuelPoints = self.fuelPoints
		self.dirtyStorageTable = true
	end

	local hasFuel = ( self.fuelPoints > 0 ) or sm.container.canSpend( fuelContainer, obj_consumable_gas, 1 )
	if self.hasFuel ~= hasFuel then
		self.hasFuel = hasFuel
		self.dirtyClientTable = true
	end

end

function Fant_C_Engine.controlEngine( self, direction, active, timeStep, gearIdx )

	direction = clamp( direction, -1, 1 )
	if ( math.abs( direction ) > 0 or not active ) then
		self.power = self.power + timeStep
	else
		self.power = self.power - timeStep
	end
	self.power = clamp( self.power, 0, 1 )

	if direction == 0 and active then
		self.power = 0
	end
	
	
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	local avgImpulse = 0
	local avgVelocity = 0

	if #bearings > 0 then
		for _, currentBearing in ipairs( bearings ) do
			avgImpulse = avgImpulse + math.abs( currentBearing.appliedImpulse )
			avgVelocity = avgVelocity + math.abs( currentBearing.angularVelocity )
		end

		avgImpulse = avgImpulse / #bearings
		avgVelocity = avgVelocity / #bearings

		avgVelocity = math.min( avgVelocity, self.gears[self.client_gearIdx].velocity )
	end
	
	local WheelForce = 1 - sm.util.clamp( (avgVelocity/4) / self.gears[ self.client_gearIdx ].velocity, 0, 1 )
	
	self.motorVelocity = ( active and direction or 0 ) * self.gears[gearIdx].velocity * WheelForce
	self.motorImpulse = ( active and self.power or 2 ) * self.gears[gearIdx].power * WheelForce
	
end

function Fant_C_Engine.getInputs( self )

	local parents = self.interactable:getParents()
	local active = true
	local direction = 1
	local fuelContainer = nil
	local hasInput = false
	
	local inputBreak = false
	local inputClutch = false
	local inputGearUp = false
	local inputGearDown = false
	
	for i, parent in pairs( self.interactable:getParents() ) do
		if parent then
			if parent:hasOutputType( sm.interactable.connectionType.logic ) then
				if tostring( sm.shape.getColor( parent.shape ) ) == "0a3ee2ff" then --BLUE
					inputBreak = parent:isActive()
				elseif tostring( sm.shape.getColor( parent.shape ) ) == "d02525ff" then --RED
					inputClutch = parent:isActive()
				elseif tostring( sm.shape.getColor( parent.shape ) ) == "19e753ff" then --GREEN
					inputGearUp = parent:isActive()
				elseif tostring( sm.shape.getColor( parent.shape ) ) == "e2db13ff" then --YELLOW
					inputGearDown = parent:isActive()
				else
					active = parent:isActive()
					hasInput = true
				end
			elseif parent:hasOutputType( sm.interactable.connectionType.power ) then
				active = parent:isActive()
				direction = parent:getPower()
				hasInput = true
			elseif parent:hasOutputType( sm.interactable.connectionType.gasoline ) then
				fuelContainer = parent:getContainer( 0 )
			end
		end
	end
	
	return active, direction, fuelContainer, hasInput, inputBreak, inputClutch, inputGearUp, inputGearDown
end

function Fant_C_Engine.server_onFixedUpdate( self, timeStep )
	-- Check engine connections
	local hadInput = self.hasInput == nil and true or self.hasInput --Pretend to have had input if nil to avoid starting engines at load
	local active, direction, fuelContainer, hasInput, inputBreak, inputClutch, inputGearUp, inputGearDown = self:getInputs()
	self.hasInput = hasInput
	local useCreativeFuel = not sm.game.getEnableFuelConsumption() and fuelContainer == nil
	
	-- Check fuel container
	if not fuelContainer or fuelContainer:isEmpty() then
		fuelContainer = self.shape.interactable:getContainer( 0 )
	end

	if inputBreak ~= self.last_inputBreak then
		self.last_inputBreak = inputBreak
	end
	
	if inputClutch ~= self.last_inputClutch then
		self.last_inputClutch = inputClutch
	end
	
	if inputGearUp ~= self.last_inputGearUp then
		self.last_inputGearUp = inputGearUp
		if inputGearUp and self.saved.gearIdx < self.level.gearCount then
			self.saved.gearIdx = self.saved.gearIdx + 1
			if self.saved.gearIdx > self.level.gearCount then
				self.saved.gearIdx = self.level.gearCount
			end
			self:sv_setGear( self.saved.gearIdx )
		end
	end
	if inputGearDown ~= self.last_inputGearDown then
		self.last_inputGearDown = inputGearDown
		if inputGearDown and self.saved.gearIdx > 1 then
			self.saved.gearIdx = self.saved.gearIdx - 1
			if self.saved.gearIdx < 1 then
				self.saved.gearIdx = 1
			end
			self:sv_setGear( self.saved.gearIdx )
		end
	end
	
	-- Check bearings
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	-- Update motor gear when a steering is added
	if not hadInput and hasInput then
		if self.saved.gearIdx == 1 then
			self:sv_setGear( 2 )
		end
	end

	-- Consume fuel for fuel points
	local canSpend = false
	if self.fuelPoints <= 0 then
		canSpend = sm.container.canSpend( fuelContainer, obj_consumable_gas, 1 )
	end

	-- Control engine
	if self.fuelPoints > 0 or canSpend or useCreativeFuel then
		if inputBreak then
			direction = 1
		end
		if hasInput == false then
			self.power = 1
			self:controlEngine( 1, true, timeStep, self.saved.gearIdx )
		else
			self:controlEngine( direction, active, timeStep, self.saved.gearIdx )
		end

		if not useCreativeFuel then
			-- Consume fuel points
			local appliedImpulseCost = 0.015625
			local fuelCost = 0
			for _, bearing in ipairs( bearings ) do
				if bearing.appliedImpulse * bearing.angularVelocity < 0 then -- No added fuel cost if the bearing is decelerating
					fuelCost = fuelCost + math.abs( bearing.appliedImpulse ) * appliedImpulseCost
				end
			end
			fuelCost = math.min( fuelCost, math.sqrt( fuelCost / 7.5 ) * 7.5 )

			self.fuelPoints = self.fuelPoints - fuelCost

			if self.fuelPoints <= 0 and fuelCost > 0 then
				sm.container.beginTransaction()
				sm.container.spend( fuelContainer, obj_consumable_gas, 1, true )
				if sm.container.endTransaction() then
					self.fuelPoints = self.fuelPoints + self.pointsPerFuel
				end
			end
		end

	else
		self:controlEngine( 0, false, timeStep, self.saved.gearIdx )
	end
	
	local motorImpulse = self.motorImpulse
	local motorVelocity = self.motorVelocity
	if inputBreak then
		motorVelocity = 0
	end
	if inputClutch and not inputBreak then
		motorImpulse = 0
	end
	-- Update rotational joints
	for _, bearing in ipairs( bearings ) do
		bearing:setMotorVelocity( motorVelocity, motorImpulse )
	end

	self:sv_updateFuelStatus( fuelContainer )

	-- Storage table dirty
	if self.dirtyStorageTable then
		self.storage:save( self.saved )
		self.dirtyStorageTable = false
	end

	-- Client table dirty
	if self.dirtyClientTable then
		self.network:setClientData( { gearIdx = self.saved.gearIdx, engineHasFuel = self.hasFuel or useCreativeFuel, scrapOffset = self.scrapOffset } )
		self.dirtyClientTable = false
	end
end

--[[ Client ]]

function Fant_C_Engine.client_onCreate( self )
	self.cl_level = EngineLevels[tostring( self.shape:getShapeUuid() )]
	self.gears = self.cl_level.gears
	self.client_gearIdx = 1
	self.effect = sm.effect.createEffect( self.cl_level.effect, self.interactable )
	self.engineHasFuel = false
	self.scrapOffset = self.scrapOffset or 0
	self.power = 0
	g_Engine_Gears[ self.shape:getId() ] = self.gears
end

function Fant_C_Engine.client_onClientDataUpdate( self, params )

	if self.gui then
		if self.gui:isActive() and params.gearIdx ~= self.client_gearIdx then
			self.gui:setSliderPosition("Setting", params.gearIdx - 1 )
		end
	end

	self.client_gearIdx = params.gearIdx
	self.interactable:setPoseWeight( 0, params.gearIdx / #self.gears )
	
	if self.engineHasFuel and not params.engineHasFuel then
		local character = sm.localPlayer.getPlayer().character
		if character then
			if ( self.shape.worldPosition - character.worldPosition ):length2() < 100 then
				sm.gui.displayAlertText( "#{INFO_OUT_OF_FUEL}" )
			end
		end
	end

	if params.engineHasFuel then
		self.effect:setParameter("gas", 0.0 )
	else
		self.effect:setParameter("gas", 1.0 )
	end

	self.engineHasFuel = params.engineHasFuel
	self.scrapOffset = params.scrapOffset
	
	g_Engine_Gears[ self.shape:getId() ] = self.client_gearIdx
end

function Fant_C_Engine.client_onDestroy( self )
	self.effect:destroy()

	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end

function Fant_C_Engine.client_onFixedUpdate( self, timeStep )

	local active, direction, externalFuelTank, hasInput = self:getInputs()


	if self.gui then
		self.gui:setVisible( "FuelContainer", externalFuelTank ~= nil )
	end

	if sm.isHost then
		return
	end

	-- Check bearings
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	-- Control engine
	if self.engineHasFuel then
		if hasInput == false then
			self.power = 1

			self:controlEngine( 1, true, timeStep, self.client_gearIdx )
		else
		
			self:controlEngine( direction, active, timeStep, self.client_gearIdx )
		end
	else
		self:controlEngine( 0, false, timeStep, self.client_gearIdx )
	end

	-- Update rotational joints
	for _, bearing in ipairs( bearings ) do
		bearing:setMotorVelocity( self.motorVelocity, self.motorImpulse )
	end
end

function Fant_C_Engine.client_onUpdate( self, dt )

	local active, direction, fuelContainer, hasInput, inputBreak, inputClutch, inputGearUp, inputGearDown = self:getInputs()

	self:cl_updateEffect( direction, active, inputClutch )
end

function Fant_C_Engine.client_onInteract( self, character, state )
	if state == true then
		self.gui = sm.gui.createEngineGui()

		self.gui:setText( "Name", "C Engine" )
		self.gui:setText( "SubTitle", "Customizable Engine" )
		self.gui:setText( "Interaction", "Gear: ".. tostring( self.client_gearIdx ) )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setSliderData( "Setting", self.cl_level.gearCount, self.client_gearIdx - 1 )
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setVisible( "Upgrade", false )
		
		local fuelContainer = self.shape.interactable:getContainer( 0 )

		if fuelContainer then
			self.gui:setContainer( "Fuel", fuelContainer )
		end

		local _, _, externalFuelContainer, _ = self:getInputs()
		if externalFuelContainer then
			self.gui:setVisible( "FuelContainer", true )
		end

		if not sm.game.getEnableFuelConsumption() then
			self.gui:setVisible( "BackgroundGas", false )
			self.gui:setVisible( "FuelGrid", false )
		end

		self.gui:open()
	end
end

function Fant_C_Engine.cl_onGuiClosed( self )
	self.gui:destroy()
	self.gui = nil
end

function Fant_C_Engine.cl_onSliderChange( self, sliderName, sliderPos )
	self.network:sendToServer( "sv_setGear", sliderPos + 1 )
	self.gui:setText( "Interaction", "Gear: ".. tostring( sliderPos + 1 ) )
	self.client_gearIdx = sliderPos + 1
end

function Fant_C_Engine.cl_updateEffect( self, direction, active, inputClutch )
	local bearings = {}
	local joints = self.interactable:getJoints()
	for _, joint in ipairs( joints ) do
		if joint:getType() == "bearing" then
			bearings[#bearings+1] = joint
		end
	end

	local avgImpulse = 0
	local avgVelocity = 0

	if #bearings > 0 then
		for _, currentBearing in ipairs( bearings ) do
			avgImpulse = avgImpulse + math.abs( currentBearing.appliedImpulse )
			avgVelocity = avgVelocity + math.abs( currentBearing.angularVelocity )
		end

		avgImpulse = avgImpulse / #bearings
		avgVelocity = avgVelocity / #bearings

		avgVelocity = math.min( avgVelocity, self.gears[self.client_gearIdx].velocity )
	end

	local impulseFraction = 0
	local velocityFraction = avgVelocity / (  self.gears[self.client_gearIdx].velocity / 3 )

	if direction ~= 0 and self.gears[self.client_gearIdx].power > 0 then
		impulseFraction = math.abs( avgImpulse ) / self.gears[self.client_gearIdx].power
	end

	local maxRPM = 0.9 * (self.client_gearIdx / #self.gears )
	local rpm = 0.1

	if avgVelocity > 0 then
		rpm = rpm + math.min( velocityFraction * maxRPM, maxRPM )
	end

	local engineLoad = 0
	if not inputClutch then
		if direction ~= 0 then
			engineLoad = impulseFraction - math.min( velocityFraction, 1.0 )
		end
	else
		engineLoad = math.abs( direction )
		rpm = engineLoad
		--print( direction )
	end

	if #self.interactable:getParents() == 0 then
		if self.effect:isPlaying() == false and #bearings > 0 and self.gears[self.client_gearIdx].power > 0 then
			self.effect:start()
		elseif self.effect:isPlaying() and ( #bearings == 0 or self.gears[self.client_gearIdx].power == 0 ) then
			self.effect:setParameter( "load", 0.5 )
			self.effect:setParameter( "rpm", 0 )
			self.effect:stop()
		end
	else
		if self.effect:isPlaying() and ( #bearings == 0 or active == false or self.gears[self.client_gearIdx].power == 0 ) then
			self.effect:setParameter( "load", 0.5 )
			self.effect:setParameter( "rpm", 0 )
			self.effect:stop()
		elseif self.effect:isPlaying() == false and #bearings > 0 and active == true and self.gears[self.client_gearIdx].power > 0 then
			self.effect:start()
		end
	end

	if self.effect:isPlaying() then
		self.effect:setParameter( "rpm", rpm * 0.8 )
		self.effect:setParameter( "load", engineLoad * 0.2 + 0.8 )
	end
end



