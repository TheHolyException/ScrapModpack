--  getPublicData value names:
--	descend (bool)
--	ascend (bool)
--	lift (float 0-1)


Fant_Chemical_Lift_Engine = class()
Fant_Chemical_Lift_Engine.poseWeightCount = 1
Fant_Chemical_Lift_Engine.maxParentCount = 3
Fant_Chemical_Lift_Engine.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.water
Fant_Chemical_Lift_Engine.maxChildCount = 1
Fant_Chemical_Lift_Engine.connectionOutput =  sm.interactable.connectionType.logic

Fant_Chemical_Lift_Engine.colorNormal = sm.color.new( 0xff8000ff )
Fant_Chemical_Lift_Engine.colorHighlight = sm.color.new( 0xff9f3aff )
Fant_Chemical_Lift_Engine.ButtonSpeed = ( 1/40 ) / 2
Fant_Chemical_Lift_Engine.LiftSpeed = ( 1/40 ) / 2
Fant_Chemical_Lift_Engine.ConsumeFuel = ( 1/40 ) / 50
Fant_Chemical_Lift_Engine.UseWind = false
Fant_Chemical_Lift_Engine.BaseLiftForce = 1000
Fant_Chemical_Lift_Engine.WindForce = 100
Fant_Chemical_Lift_Engine.Wind_Layers = {
	{
		{ LayerHeight = 0.2, LayerTickness = 0.1, LayerDirection = sm.vec3.new( 1, 1, 0 ) },
		{ LayerHeight = 0.3, LayerTickness = 0.1, LayerDirection = sm.vec3.new( -1, -1, 0 ) },
		{ LayerHeight = 0.4, LayerTickness = 0.1, LayerDirection = sm.vec3.new( -1, 1, 0 ) },
		{ LayerHeight = 0.5, LayerTickness = 0.1, LayerDirection = sm.vec3.new( 1, -1, 0 ) }
	},
	{
		{ LayerHeight = 0.4, LayerTickness = 0.1, LayerDirection = sm.vec3.new( 1, 1, 0 ) },
		{ LayerHeight = 0.5, LayerTickness = 0.1, LayerDirection = sm.vec3.new( -1, -1, 0 ) },
		{ LayerHeight = 0.2, LayerTickness = 0.1, LayerDirection = sm.vec3.new( -1, 1, 0 ) },
		{ LayerHeight = 0.3, LayerTickness = 0.1, LayerDirection = sm.vec3.new( 1, -1, 0 ) }
	},
	{
		{ LayerHeight = 0.6, LayerTickness = 0.1, LayerDirection = sm.vec3.new( 1, 1, 0 ) },
		{ LayerHeight = 0.3, LayerTickness = 0.1, LayerDirection = sm.vec3.new( -1, -1, 0 ) },
		{ LayerHeight = 0.5, LayerTickness = 0.1, LayerDirection = sm.vec3.new( -1, 1, 0 ) },
		{ LayerHeight = 0.4, LayerTickness = 0.1, LayerDirection = sm.vec3.new( 1, -1, 0 ) }
	},
	{
		{ LayerHeight = 0.3, LayerTickness = 0.1, LayerDirection = sm.vec3.new( 1, 1, 0 ) },
		{ LayerHeight = 0.5, LayerTickness = 0.1, LayerDirection = sm.vec3.new( -1, -1, 0 ) },
		{ LayerHeight = 0.4, LayerTickness = 0.1, LayerDirection = sm.vec3.new( -1, 1, 0 ) },
		{ LayerHeight = 0.2, LayerTickness = 0.1, LayerDirection = sm.vec3.new( 1, -1, 0 ) }
	}
}



function Fant_Chemical_Lift_Engine.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { ForceValue = 0, Fuel = 0, LiftForce = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.ForceValue = self.sv.storage.ForceValue
	self.Fuel = self.sv.storage.Fuel
	self.LiftForce = self.sv.storage.LiftForce
	self.timer = 0
	self.RandomWindLayer = 1
	self.DefaultColor = "df7f01ff"
	self.lastdata = nil
end

function Fant_Chemical_Lift_Engine.client_onCreate( self )
	self.timer = 0
	self.ForceValue = self.ForceValue or 0
	self.Fuel = self.Fuel or 0
	self.LiftForce = self.LiftForce or 0
	self.network:sendToServer( "GetData" )

end

function Fant_Chemical_Lift_Engine.GetData( self )	
	self.network:sendToClients( "SetData", { ForceValue = self.ForceValue, Fuel = self.Fuel, LiftForce = self.LiftForce } )	
end

function Fant_Chemical_Lift_Engine.SetData( self, data )
	self.ForceValue = data.ForceValue
	self.Fuel = data.Fuel
	self.LiftForce = data.LiftForce
	if self.gui then
		local info = "Fuel Level: " ..tostring( math.floor(self.Fuel * 100)  ) .. "%"
		self.gui:setText( "Interaction", info )
		self.gui:setSliderData( "Setting", 26, (self.ForceValue * 25) )
		self.gui:setText( "SubTitle", "Power " .. tostring(math.floor(self.ForceValue * 25)) )		
	end
	self:cl_setballon( { BallonFill = self.LiftForce } )

end

function Fant_Chemical_Lift_Engine.sv_SetData( self, data )
	self.ForceValue = data.ForceValue
	self.Fuel = data.Fuel
	self.LiftForce = data.LiftForce
	self.sv.storage = { ForceValue = self.ForceValue, Fuel = self.Fuel, LiftForce = self.LiftForce } 
	self.storage:save( self.sv.storage )
end	

function Fant_Chemical_Lift_Engine.client_onInteract(self, _, state)
	if state == true then	
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Chemical Lift Engine" )
		self.gui:setText( "SubTitle", "Power " .. tostring(math.floor(self.ForceValue * 25)) )		
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setSliderData( "Setting", 26, (self.ForceValue * 25) )
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		local info = "Fuel Level: " ..tostring( math.floor(self.Fuel * 100)  ) .. "%"
		self.gui:setText( "Interaction", info )
		self.gui:open()		
	end
end

function Fant_Chemical_Lift_Engine.server_onDestroy( self )
	self.sv.storage = { ForceValue = self.ForceValue, Fuel = self.Fuel, LiftForce = self.LiftForce } 
	self.storage:save( self.sv.storage )
end

function Fant_Chemical_Lift_Engine.client_onDestroy( self )
	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end

function Fant_Chemical_Lift_Engine.cl_onGuiClosed( self )
	self.gui:destroy()
	self.gui = nil
end

function Fant_Chemical_Lift_Engine.cl_onSliderChange( self, sliderName, sliderPos )
	self.ForceValue =  ( sliderPos / 25 )
	self.gui:setSliderData( "Setting", 26, (self.ForceValue * 25) )
	self.gui:setText( "SubTitle", "Power " .. tostring(math.floor(self.ForceValue * 25)) )		
	self.network:sendToServer( "sv_SetData", { ForceValue = self.ForceValue, Fuel = self.Fuel, LiftForce = self.LiftForce } )
	
end

function Fant_Chemical_Lift_Engine.getInputs( self )
	local parents = self.interactable:getParents()
	local incresse = nil
	local decresse = nil
	local chemicalContainer = nil

	for i = 1, #parents do
		if parents[i] ~= nil then
			if parents[i]:hasOutputType( sm.interactable.connectionType.logic ) then
				if tostring( sm.shape.getColor( parents[i].shape ) ) == self.DefaultColor then 
					incresse = parents[i]
				else
					decresse = parents[i]
				end
				
			end					
		end	
		if parents[i]:hasOutputType( sm.interactable.connectionType.water ) and chemicalContainer == nil then
			chemicalContainer = parents[i]:getContainer( 0 )
		end
	end	
	return incresse, decresse, chemicalContainer, #parents
end

function Fant_Chemical_Lift_Engine.server_onFixedUpdate( self )	
	local Button_1, Button_2, ExternalChemicalContainer, InputCount = self:getInputs()
	self.container = self.shape:getInteractable():getContainer(0)
	if self.Fuel > 0 and self.LiftForce > 0 then
		self.Fuel = self.Fuel - ( self.ConsumeFuel * self.ForceValue )
		if self.Fuel <= 0 then
			self.Fuel = 0
		end
	end
	
	if self.Fuel <= 0 and ExternalChemicalContainer then
		if sm.container.canSpend( ExternalChemicalContainer, obj_consumable_chemical, 1 ) then
			sm.container.beginTransaction()
			sm.container.spend( ExternalChemicalContainer, obj_consumable_chemical, 1, true )
			if sm.container.endTransaction() then
				self.Fuel = 1
			end
		end
	end
	
	--sm.interactable.setPublicData( sm.shape.getInteractable( self.shape ), { value = 0.75 } )
	local data = sm.interactable.getPublicData( sm.shape.getInteractable( self.shape ) )
	local buttonControle = true
	if data ~= nil then
		if #data > 0 then
			if data.descend then
				if self.ForceValue >= 0 then
					self.ForceValue = self.ForceValue - self.ButtonSpeed 
					if self.ForceValue < 0 then
						self.ForceValue = 0
					end
				end
				buttonControle = false
				data.descend = false
			end
			if data.ascend then
				if self.ForceValue <= 1 and self.Fuel > 0 then
					self.ForceValue = self.ForceValue + self.ButtonSpeed 
					if self.ForceValue > 1 then
						self.ForceValue = 1
					end
				end
				buttonControle = false
				data.descend = ascend
			end
			if data.lift ~= nil then
				if data.lift > 0 then
					self.ForceValue = data.lift
					if self.ForceValue < 0 then
						self.ForceValue = 0
					end
					if self.ForceValue > 1 then
						self.ForceValue = 1
					end
					buttonControle = false
					data.lift = 0
				end
			end
			sm.interactable.setPublicData( sm.shape.getInteractable( self.shape ), data )
		end
	else
		data = {}
	end
	if buttonControle then
		if InputCount >= 3 then
			-- Duel Input
			if Button_1 ~= nil and Button_2 ~= nil then
				if Button_1:isActive() and not Button_2:isActive() then
					if self.ForceValue >= 0 then
						self.ForceValue = self.ForceValue - self.ButtonSpeed 
						if self.ForceValue < 0 then
							self.ForceValue = 0
						end
					end
				elseif not Button_1:isActive() and Button_2:isActive() then
					if self.ForceValue <= 1 and self.Fuel > 0 then
						self.ForceValue = self.ForceValue + self.ButtonSpeed 
						if self.ForceValue > 1 then
							self.ForceValue = 1
						end
					end
				end
			end
		else
			-- Single Input
			if Button_1 ~= nil then
				if not Button_1:isActive() then
					if self.ForceValue >= 0 then
						self.ForceValue = self.ForceValue - self.ButtonSpeed 
						if self.ForceValue < 0 then
							self.ForceValue = 0
						end
					end
				else
					if self.ForceValue <= 1 and self.Fuel > 0 then
						self.ForceValue = self.ForceValue + self.ButtonSpeed 
						if self.ForceValue > 1 then
							self.ForceValue = 1
						end
					end
				end
			elseif Button_2 ~= nil then
				if not Button_2:isActive() then
					if self.ForceValue >= 0 then
						self.ForceValue = self.ForceValue - self.ButtonSpeed 
						if self.ForceValue < 0 then
							self.ForceValue = 0
						end
					end
				else
					if self.ForceValue <= 1 and self.Fuel > 0 then
						self.ForceValue = self.ForceValue + self.ButtonSpeed 
						if self.ForceValue > 1 then
							self.ForceValue = 1
						end
					end
				end
			else
				if self.ForceValue >= 0 then
					self.ForceValue = self.ForceValue - self.ButtonSpeed 
					if self.ForceValue < 0 then
						self.ForceValue = 0
					end
				end
			end
		end
	end
	
	if self.ForceValue > 0 and self.Fuel <= 0 then
		self.ForceValue = 0
	end
	
	if self.LiftForce <= self.ForceValue then
		self.LiftForce = self.LiftForce + self.LiftSpeed
		if self.LiftForce >= self.ForceValue then
			self.LiftForce = self.ForceValue
		end
	end
	
	if self.LiftForce > self.ForceValue then
		self.LiftForce = self.LiftForce - self.LiftSpeed
		if self.LiftForce <= self.ForceValue then
			self.LiftForce = self.ForceValue
		end
	end
	
	local Height = ( math.abs(self.shape.worldPosition.z) / 1000 )
	if Height <= 0.01 then
		Height = 0.01
	end
	if Height >= 1 then
		Height = 1
	end
		
	local Time = sm.storage.load( STORAGE_CHANNEL_TIME )
	if Time then
		if self.timeChange == false and Time.timeOfDay <= 0.1 then
			self.timeChange = true
		end
		if self.timeChange == true and Time.timeOfDay > 0.2 then
			self.timeChange = false
			self.RandomWindLayer = math.random( 1, 4 )
		end	
	end
	local WindForce = sm.vec3.new( 0, 0, 0 )
	if self.UseWind then 
		local DayWindLayer = self.Wind_Layers[self.RandomWindLayer]
		for i = 1, #DayWindLayer do	
			if Height > DayWindLayer[i].LayerHeight and Height < DayWindLayer[i].LayerHeight + DayWindLayer[i].LayerTickness then
				local LayerForce = 1 - math.abs( ( ( ( Height - DayWindLayer[i].LayerHeight ) / ( DayWindLayer[i].LayerHeight + DayWindLayer[i].LayerTickness ) ) * 4 ) - 1 )		
				WindForce = DayWindLayer[i].LayerDirection * LayerForce * self.WindForce * ( 1 - math.abs( ( Time.timeOfDay * 2 ) - 1 ) )
				break
			end
		end
	end
	local Force = sm.vec3.new( 0, 0, math.abs( self.ForceValue * self.BaseLiftForce * (1-Height) ) ) + WindForce
	if Force ~= sm.vec3.new( 0, 0, 0 ) then
		sm.physics.applyImpulse( self.shape, Force, true, sm.vec3.new( 0, 0, 0 ) )
	end
	if self.timer < 1 then
		self.timer = self.timer + 0.4
	else
		self.timer = 0
		self.network:sendToClients( "SetData", { container = self.container, ForceValue = self.ForceValue, Fuel = self.Fuel, LiftForce = self.LiftForce } )	
		self.network:sendToClients( "cl_setballon", { BallonFill = self.LiftForce } )

		data.value = self.ForceValue * 25
		sm.interactable.setPublicData( self.interactable, data )
	end
end

function Fant_Chemical_Lift_Engine.cl_setballon( self, data )
	self.shape:getInteractable():setPoseWeight( 0, data.BallonFill )
end	