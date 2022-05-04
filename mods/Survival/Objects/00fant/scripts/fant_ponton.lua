dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"

Fant_Ponton = class()
Fant_Ponton.poseWeightCount = 1
Fant_Ponton.maxParentCount = 3
Fant_Ponton.connectionInput = sm.interactable.connectionType.logic
Fant_Ponton.maxChildCount = 255
Fant_Ponton.connectionOutput = sm.interactable.connectionType.logic
Fant_Ponton.ForceMultiplier = 5
Fant_Ponton.SliderSteps = 10

function Fant_Ponton.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { sliderValue = 10 } 
		self.storage:save( self.sv.storage )
	end
	self.sliderValue = self.sv.storage.sliderValue or 0
	self.changeRangeToggle = 15234230
	if not self.areaTrigger then
		self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), sm.vec3.new( 1, 1, 1 ) * 0.1, sm.vec3.new(0.0, 0, 0.0), sm.quat.identity(), sm.areaTrigger.filter.all )			
	end
	self.waterTimer = 0
	self.inWater = false
	self.WaterHeight = 0
	self.network:sendToClients( "cl_set_data", { sliderValue = self.sliderValue } )
end

function Fant_Ponton.client_onCreate( self )
	self.sliderValue = self.sliderValue or 0
	self.network:sendToServer( "sv_getData" )
end

function Fant_Ponton.sv_getData( self )
	self.network:sendToClients( "cl_set_data", { sliderValue = self.sliderValue } )
end

function Fant_Ponton.cl_set_data( self, data )
	self.sliderValue = data.sliderValue
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Buoyancy: ".. tostring( self.sliderValue ) )
	end
end

function Fant_Ponton.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Ballst Tank" )
		self.gui:setText( "SubTitle", "Buoyancy" )
		self.gui:setText( "Interaction", "Buoyancy: ".. tostring( self.sliderValue ) )
		self.gui:setSliderData( "Setting",self.SliderSteps+1, self.sliderValue )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setVisible( "FuelContainer", false )
		self.gui:open()
	end
end

function Fant_Ponton.cl_onSliderChange( self, sliderName, sliderPos )
	self.sliderValue = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Buoyancy: ".. tostring( self.sliderValue ) )
	end
	self.network:sendToServer( "setSliderValue", self.sliderValue )
end

function Fant_Ponton.setSliderValue( self, sliderValue )
	self.sliderValue = sliderValue
	self.saved = { sliderValue = self.sliderValue }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_set_data", self.saved )
	sm.interactable.setPublicData( sm.shape.getInteractable( self.shape ), { value = self.sliderValue } )
end

function Fant_Ponton.server_onFixedUpdate( self, dt )
	local body = sm.shape.getBody( self.shape )
	if body == nil then
		return
	end
	if body:isStatic() then
		return
	end
	
	local RelativeWaterHeight = -( ( ( self.shape.worldPosition.z - self.WaterHeight ) * 1 ) / ( 1 + sm.vec3.length( body.velocity  ) ) ) 
	
	--print( ( self.shape.worldPosition.z - self.WaterHeight ) )
	
	if not self:IsInWater( dt ) then
		return
	end
	
	
	local parents = self.interactable:getParents()
	local ChangeRange = 0
	for i = 1, #parents do
		if parents[i] then
			if parents[i]:hasOutputType( sm.interactable.connectionType.logic ) then
				if tostring( parents[i].shape.color ) == "df7f01ff" then  --default
					if parents[i].active then
						ChangeRange = 1
					end
				else
					if parents[i].active then
						ChangeRange = -1
					end
				end
			end		
		end
	end	
	if self.changeRangeToggle == ChangeRange then
		ChangeRange = 0
	else
		self.changeRangeToggle = ChangeRange
		self.sliderValue = self.sliderValue + ChangeRange
		if self.sliderValue < 0 then
			self.sliderValue = 0
		end
		if self.sliderValue > self.SliderSteps then
			self.sliderValue = self.SliderSteps
		end
		self.saved = { sliderValue = self.sliderValue }
		self.storage:save( self.saved )
		self.network:sendToClients( "cl_set_data", self.saved )
		sm.interactable.setPublicData( sm.shape.getInteractable( self.shape ), { value = self.sliderValue } )
	end
	
	local ForceMul = 0
	if self.shape:getShapeUuid() == obj_industrial_cylindersmall then
		ForceMul = 0.333
	end
	if self.shape:getShapeUuid() == obj_industrial_cylindermedium then
		ForceMul = 0.666
	end
	if self.shape:getShapeUuid() == obj_industrial_cylinderlarge then
		ForceMul = 1
	end
	local Force = ( self.sliderValue / self.SliderSteps ) * ForceMul * 5000
	
	if RelativeWaterHeight < 0.0001 then
		RelativeWaterHeight = 0
	end
	if RelativeWaterHeight > 1 then
		RelativeWaterHeight = 1
	end
	Force = Force * RelativeWaterHeight 

	--print( Force )
	if Force > 0.001 then
		sm.physics.applyImpulse( self.shape, sm.vec3.new( 0, 0, Force ) , true, sm.vec3.new( 0, 0, 0 ) )
	end
end

function Fant_Ponton.IsInWater( self, dt )
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
						self.WaterHeight = result:getWorldMax().z
						break
					end
					if userData.chemical == true then
						self.inWater = true
						self.WaterHeight = result:getWorldMax().z
						break
					end
					if userData.oil == true then
						self.inWater = true
						self.WaterHeight = result:getWorldMax().z
						break
					end
				end
			end
		end
	end
	--local Pos = self.shape.worldPosition
	--Pos.z = self.WaterHeight
	
	--self.network:sendToClients( "cl_BoxAreaTrigger", { Pos = Pos } )
	return self.inWater
end


function Fant_Ponton.cl_BoxAreaTrigger( self, data )
	if self.effect == nil then
		self.effect = sm.effect.createEffect( "ShapeRenderable" )				
		self.effect:setParameter( "uuid", sm.uuid.new("f7881097-9320-4667-b2ba-4101c72b8730") )
		self.effect:start()
		self.effect:setScale( sm.vec3.new( 1, 1, 1 ) * 0.25 )
	end
	self.effect:setPosition( data.Pos )	
end

