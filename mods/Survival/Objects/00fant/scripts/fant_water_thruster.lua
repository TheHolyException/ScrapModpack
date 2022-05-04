Fant_Water_Thruster = class()

Fant_Water_Thruster.poseWeightCount = 1
Fant_Water_Thruster.maxParentCount = 2
Fant_Water_Thruster.connectionInput = sm.interactable.connectionType.gasoline + sm.interactable.connectionType.logic
Fant_Water_Thruster.ForceMultiplier = 1
Fant_Water_Thruster.SliderSteps = 10
Fant_Water_Thruster.Duration = 10

function Fant_Water_Thruster.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { fuelTicks = 0, sliderValue = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.sliderValue = self.sv.storage.sliderValue or 0
	self.fuelTicks = self.sv.storage.fuelTicks or 0
	self.changeRangeToggle = 0
	if not self.areaTrigger then
		self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), sm.vec3.new( 1, 1, 1 ) * 0.1, sm.vec3.new(0.0, 0, 0.0), sm.quat.identity(), sm.areaTrigger.filter.all )			
	end
	self.waterTimer = 0
	self.inWater = false
	self.lastactive = false
	self.network:sendToClients( "cl_set_data", { fuelTicks = self.fuelTicks, sliderValue = self.sliderValue } )
end

function Fant_Water_Thruster.server_onDestroy( self )
	self.saved = { fuelTicks = self.fuelTicks, sliderValue = self.sliderValue }
	self.storage:save( self.saved )
end

function Fant_Water_Thruster.client_onCreate( self )
	self.sliderValue = self.sliderValue or 0
	self.network:sendToServer( "sv_getData" )
	self.Effect = sm.effect.createEffect( "Thruster - Level 3", self.interactable )	
	
	if self.shape:getShapeUuid() == obj_interactive_fant_water_thruster_1x1x2 then
		self.Effect:setOffsetPosition(  sm.vec3.new( 0.2, 0, 0 ) )
	end
	if self.shape:getShapeUuid() == obj_interactive_fant_water_thruster_3x3x6 then
		self.Effect:setOffsetPosition(  sm.vec3.new( -0.275, 0, 0 ) )
	end		
	self.Effect:setOffsetRotation( sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 0, 0, 1 ) ) )
end

function Fant_Water_Thruster.client_onDestroy( self )
	self.Effect:stop()	
end

function Fant_Water_Thruster.cl_ToogleEffect( self, state )
	if state and not self.Effect:isPlaying() then
		self.Effect:start()
	end
	if not state and self.Effect:isPlaying() then
		self.Effect:stop()
	end
end

function Fant_Water_Thruster.client_onUpdate( self, dt )
	if self.Effect:isPlaying() then
		self.Effect:setParameter( "velocity", self.sliderValue * 5 )
	end
end

function Fant_Water_Thruster.sv_getData( self )
	self.network:sendToClients( "cl_set_data", { fuelTicks = self.fuelTicks, sliderValue = self.sliderValue } )
end

function Fant_Water_Thruster.cl_set_data( self, data )
	self.sliderValue = data.sliderValue
	self.fuelTicks = data.fuelTicks
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Power: ".. tostring( self.sliderValue ) )
	end
end

function Fant_Water_Thruster.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Water Thruster" )
		self.gui:setText( "SubTitle", "Power" )
		self.gui:setText( "Interaction", "Power: ".. tostring( self.sliderValue ) )
		self.gui:setSliderData( "Setting",self.SliderSteps+1, self.sliderValue )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setVisible( "FuelContainer", false )
		self.gui:open()
	end
end

function Fant_Water_Thruster.cl_onSliderChange( self, sliderName, sliderPos )
	self.sliderValue = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Power: ".. tostring( self.sliderValue ) )
	end
	self.network:sendToServer( "setSliderValue", self.sliderValue )
end

function Fant_Water_Thruster.setSliderValue( self, sliderValue )
	self.sliderValue = sliderValue
	self.saved = { fuelTicks = self.fuelTicks, sliderValue = self.sliderValue }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_set_data", self.saved )
	sm.interactable.setPublicData( sm.shape.getInteractable( self.shape ), { value = self.sliderValue } )
end

function Fant_Water_Thruster.getInputs( self )
	local parents = self.interactable:getParents()
	local fuelContainer = nil
	local active = false
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[2]:isActive()
		end	
		if parents[2]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[2]:getContainer( 0 )
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[1]:isActive()
		end 
		if parents[1]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[1]:getContainer( 0 )
		end
	end
	return active, fuelContainer
end

function Fant_Water_Thruster.server_onFixedUpdate( self, dt )
	local body = sm.shape.getBody( self.shape )
	if body == nil then
		return
	end
	local active, fuelContainer = self:getInputs()
	if self.sliderValue <= 0 then
		active = false
	end
	if not self:IsInWater( dt ) then
		active = false
	end
	if active and sm.game.getEnableAmmoConsumption() then
		if self.fuelTicks == nil then
			self.fuelTicks = 0
		end
		if self.fuelTicks > 0 then
			self.fuelTicks = self.fuelTicks - ( ( dt / self.Duration ) * ( self.sliderValue / self.SliderSteps ) )
		end	
		if fuelContainer ~= nil then
			if self.fuelTicks <= 0 then
				for slot = 0, fuelContainer:getSize() - 1 do
					local FuelItem = fuelContainer:getItem( slot )											
					if FuelItem then			
						if FuelItem.quantity >= 1 then
							sm.container.beginTransaction()
							sm.container.setItem( fuelContainer, slot, obj_consumable_gas, FuelItem.quantity - 1 )
							if sm.container.endTransaction() then
								self.fuelTicks = 1		
								break
							end
						end
					end
					
				end
				
			end
		end
		if self.fuelTicks <= 0 then
			self.fuelTicks = 0
			active = false
		end
	end
	
	if self.lastactive ~= active then
		self.lastactive = active
		self.network:sendToClients( "cl_ToogleEffect", active )
	end
	if body:isStatic() then
		active = false
	end
	if active then
		local ForceMul = 0
		if self.shape:getShapeUuid() == obj_interactive_fant_water_thruster_1x1x2 then
			ForceMul = 0.3
		end
		if self.shape:getShapeUuid() == obj_interactive_fant_water_thruster_3x3x6 then
			ForceMul = 1
		end		
		local Force = ( self.sliderValue / self.SliderSteps ) * ForceMul * ( body:getMass() / 25 )
		if Force ~= 0 then
			sm.physics.applyImpulse( self.shape, sm.vec3.new( Force, 0, 0 ) , false, sm.vec3.new( 0, 0, 0 ) )
		end
	end
end

function Fant_Water_Thruster.IsInWater( self, dt )
	if not self.areaTrigger then
		return self.inWater
	end
	if self.waterTimer > 0 then
		self.waterTimer = self.waterTimer - dt
		return self.inWater
	end
	self.waterTimer = 0.1
	self.inWater = false
	for _, result in ipairs(  self.areaTrigger:getContents() ) do
		if sm.exists( result ) then
			if type( result ) == "AreaTrigger" then
				local userData = result:getUserData()
				if userData then
					if userData.water == true then
						self.inWater = true
						break
					end
					if userData.chemical == true then
						self.inWater = true
						break
					end
					if userData.oil == true then
						self.inWater = true
						break
					end
				end
			end
		end
	end
	return self.inWater
end















