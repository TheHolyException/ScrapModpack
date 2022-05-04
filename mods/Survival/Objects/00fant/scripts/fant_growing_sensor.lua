dofile( "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua" )

Fant_Growing_Sensor = class()
Fant_Growing_Sensor.maxChildCount = 255
Fant_Growing_Sensor.connectionOutput = sm.interactable.connectionType.logic

GrownPlants = {
	hvs_mature_blueberry,
	hvs_mature_banana,
	hvs_mature_redbeet,
	hvs_mature_carrot,
	hvs_mature_tomato,
	hvs_mature_orange,
	hvs_mature_potato,
	hvs_mature_pineapple,
	hvs_mature_broccoli,
	hvs_mature_cotton,
	hvs_mature_eggplant
}

function Fant_Growing_Sensor.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { state = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.timer = 0
	self.state = self.sv.storage.state or 0
	self.laststate = false
	self.network:sendToClients( "cl_UpdateDisplay", { state = self.state }  )
	self.plantData = nil	
	self.growstate = 0
	self.waterstate = 0
	self.fertilizer = false
	self:InitAreaTrigger()
end

function Fant_Growing_Sensor.server_onRefresh( self )
	self:InitAreaTrigger()
end

function Fant_Growing_Sensor.InitAreaTrigger( self )
	if self.areaTrigger ~= nil then
		sm.areaTrigger.destroy( self.areaTrigger )
	end
	local BlockSize = 1 * sm.construction.constants.subdivideRatio
	local Box = sm.vec3.new( BlockSize, BlockSize * 10, BlockSize )
	local Pos = sm.vec3.new( 0, 0.75, 0 )
	self.areaTrigger = sm.areaTrigger.createAttachedBox( sm.shape.getInteractable( self.shape ), Box, Pos, sm.quat.identity(), sm.areaTrigger.filter.all )	

	--self.network:sendToClients( "fdebug", { Pos = Pos, Box = Box } )
end

function Fant_Growing_Sensor.fdebug( self, data )
	if self.effect ~= nil then
		self.effect:stop()
		self.effect = nil
	end
	local UUID = sm.uuid.new("f7881097-9320-4667-b2ba-4101c72b8730")
	self.effect = sm.effect.createEffect( "ShapeRenderable" )				
	self.effect:setParameter( "uuid", UUID )

	self.effect:setScale( data.Box )
	self.effect:start()
	
	local localpos = ( sm.shape.getAt( self.shape ) * data.Pos.y ) + ( sm.shape.getRight( self.shape ) * data.Pos.z ) + ( sm.shape.getUp( self.shape ) * data.Pos.x )
	self.effect:setPosition( self.shape:getWorldPosition() + localpos )
	self.effect:setRotation( self.shape:getWorldRotation() )
end

function Fant_Growing_Sensor.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_n_toogle" )		
	end
end

function Fant_Growing_Sensor.sv_n_toogle( self )
	self.state = self.state + 1
	if self.state > 3 then
		self.state = 0
	end
	self.sv.storage = { state = self.state } 
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_UpdateDisplay", { state = self.state }  )
end

function Fant_Growing_Sensor.cl_UpdateDisplay( self, data )
	self.interactable:setUvFrameIndex( data.state )
end

function Fant_Growing_Sensor.server_onFixedUpdate( self, dt )
	self.timer = self.timer - dt
	local ClosestSoil = nil
	if self.timer < 0 then
		self.timer = 0.1

		self.growstate = -1
		self.waterstate = -1
		self.fertilizer = false
		
		
		for _, result in ipairs(  self.areaTrigger:getContents() ) do
			if result ~= nil and sm.exists( result ) and type( result ) == "Harvestable" then	
				if ClosestSoil == nil then
					ClosestSoil = result	
				end
				local NewPos = sm.vec3.length( sm.harvestable.getPosition( result ) - self.shape.worldPosition )
				local OldPos = sm.vec3.length( sm.harvestable.getPosition( ClosestSoil ) - self.shape.worldPosition )
				if NewPos <= OldPos then
					ClosestSoil = result	
				end
			end
		end
		if ClosestSoil ~= nil then	
			local hasPlant = false
			local isGrowing = false
			self.plantData = sm.harvestable.getPublicData( ClosestSoil )
			if self.plantData ~= nil then
				if self.plantData ~= {} then
					self.growstate = self.plantData.growFraction
					self.waterstate = self.plantData.waterstate
					self.fertilizer = self.plantData.fertilizer
				else
					isGrowing = true
				end
			end
			if not isGrowing then
				for _, plant in ipairs( GrownPlants ) do
					if ClosestSoil.uuid ~= nil and ClosestSoil.uuid == plant then
						self.growstate = 1
						break
					end
				end
			end
		end
		-- print( "Growing: " .. tostring( self.growstate ) )
		-- print( "Water: " .. tostring( self.waterstate ) )
		-- print( "Fertilizer: " .. tostring( self.fertilizer ) )
		-- print( "________________________________" )
	
		local newState = false
		if self.state == 0 and self.growstate ~= nil then --Growing
			if tonumber( self.growstate ) >= 1 and ClosestSoil ~= nil then   -- IF FINISH WITH GROW THEN ON
				newState = true	
			else
				newState = false
			end
		end
		if self.state == 1 and self.waterstate ~= nil then --Water
			if tonumber( self.waterstate ) <= 0 and ClosestSoil ~= nil  then     --  IF NO WATER THEN ON
				newState = true	
			else
				newState = false
			end
		end
		if self.state == 2 and self.fertilizer ~= nil then --Fertilizer
			if self.fertilizer == false and ClosestSoil ~= nil  then    -- IF NO FERT THEN ON
				newState = true		
			else
				newState = false
			end
		end
		if self.state == 3 and self.growstate ~= nil then --Fertilizer
			if tonumber( self.growstate ) > -0.1 and ClosestSoil ~= nil  then    -- IF NO FERT THEN ON
				newState = true		
			else
				newState = false
			end
		end
		if self.laststate ~= newState then
			self.laststate = newState
			sm.interactable.setActive( self.interactable, newState )		
		end
	end	
end

