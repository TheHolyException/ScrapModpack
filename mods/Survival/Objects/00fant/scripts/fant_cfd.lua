Fant_cfd = class()
Fant_cfd.poseWeightCount = 1	
Fant_cfd.maxChildCount = 255
Fant_cfd.connectionOutput = sm.interactable.connectionType.logic
Fant_cfd.SliderSteps = 100
Fant_cfd.colorNormal = sm.color.new( 0x008080ff )
Fant_cfd.colorHighlight = sm.color.new( 0x00ffffff )


function Fant_cfd.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { fillPercent = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.timer = 0
	self.fillPercent = self.sv.storage.fillPercent or 0
	self.network:sendToClients( "cl_set_data", { fillPercent = self.fillPercent } )
	self.lastState = false
	
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 1 )
	end
	
	self.lastStatic = false
end

function Fant_cfd.cl_set_data( self, data )
	self.sliderValue = math.floor( data.fillPercent * self.SliderSteps ) 
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Fill Percent: ".. tostring( self.sliderValue ).."%" )
	end
end

function Fant_cfd.client_onCreate( self )
	self.sliderValue = self.sliderValue or 0
	self.network:sendToServer( "sv_getData" )
end

function Fant_cfd.sv_getData( self )
	self.network:sendToClients( "cl_set_data", { fillPercent = self.fillPercent } )
end

function Fant_cfd.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "CFD" )
		self.gui:setText( "SubTitle", "Chest Fill Detector" )
		self.gui:setText( "Interaction", "Fill Percent: ".. tostring( self.sliderValue ).."%" )
		self.gui:setSliderData( "Setting",self.SliderSteps+1, self.sliderValue )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setIconImage( "Icon", obj_interactive_cfd )
		self.gui:setVisible( "FuelContainer", true )
		
		self.gui:setVisible( "BackgroundBattery", false )
		local conatiner = self.shape.interactable:getContainer( 0 )
		if conatiner then
			self.gui:setContainer( "Fuel", conatiner )
			
			self.gui:setVisible( "FuelGrid", true )
		else
			
			self.gui:setVisible( "FuelGrid", false )
		end

		self.gui:open()
	end
end



function Fant_cfd.cl_onSliderChange( self, sliderName, sliderPos )
	self.sliderValue = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Fill Percent: ".. tostring( self.sliderValue ).."%" )
	end
	self.network:sendToServer( "setSliderValue", self.sliderValue )
end

function Fant_cfd.setSliderValue( self, sliderValue )
	self.fillPercent = ( sliderValue ) / self.SliderSteps
	self.saved = { fillPercent = self.fillPercent }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_set_data", self.saved )
end

function Fant_cfd.server_onFixedUpdate( self, dt )
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		
		local ChestStart = self.shape:getWorldPosition()
		local ChestStop = self.shape:getWorldPosition() + sm.shape.getAt( self.shape ) * 0.75
		
		local ChestValid, ChestResult = sm.physics.raycast( ChestStart, ChestStop, self.shape )
		
		if ChestValid and ChestResult then
			if ChestResult.type == "body" then
				FilterChestShape = ChestResult:getShape()
				if FilterChestShape then			
					if FilterChestShape:getInteractable() then
						if FilterChestShape:getInteractable():getContainer() then
							self.ChestContainer = FilterChestShape:getInteractable():getContainer()	
						end							
					end					
				end
			elseif ChestResult.type == "shape" then
				if ChestResult then
					if ChestResult:getInteractable() then
						if FilterChestShape:getInteractable():getContainer() then
							self.ChestContainer = FilterChestShape:getInteractable():getContainer()					
						end	
					end
				end			
			end			
		end
		--print( "ChestFillDetector Chest Scan: ", self.ChestContainer )
	end
	if self.timer > 0 then
		self.timer = self.timer - dt
		return
	else
		self.timer = 0.25
	end
	
	
	local OnOff = false
	
	if self.ChestContainer ~= nil then
		local filtercontainer = self.shape:getInteractable():getContainer(0)
		if not self.ChestContainer:isEmpty() then
			local filterItemUUID = nil
			if not filtercontainer:isEmpty() then
				local filterItem = filtercontainer:getItem( 0 )
				if filterItem ~= nil then
					filterItemUUID = filterItem.uuid
				end
			end
			local amount = 0
			if filterItemUUID ~= nil then
				for slot = 0, self.ChestContainer:getSize() - 1 do
					local item = self.ChestContainer:getItem( slot )											
					if item then
						if item.uuid then
							if item.uuid == filterItemUUID then
								if item.quantity > 0 then
									amount = amount + 1
								end
							end
						end
					end
				end					
			else
				for slot = 0, self.ChestContainer:getSize() - 1 do
					local item = self.ChestContainer:getItem( slot )											
					if item then
						if item.uuid then
							if item.quantity > 0 then
								amount = amount + 1
							end
						end
					end
				end		
			end
			if amount > 0 then
				local currentFillPercent = amount / self.ChestContainer:getSize()
				if currentFillPercent >= self.fillPercent then
					OnOff = true
				end
			end
		end	
	end	
	
	if self.shape:getBody():isStatic() ~= self.lastStatic then
		self.lastStatic = self.shape:getBody():isStatic()
		sm.interactable.setActive( self.interactable, OnOff )	
		self.network:sendToClients( "cl_state", { OnOff = OnOff } )
		self.lastState = OnOff
	end
	 
	
	if OnOff ~= self.lastState then
		self.lastState = OnOff
		sm.interactable.setActive( self.interactable, OnOff )	
		self.network:sendToClients( "cl_state", { OnOff = OnOff } )
	end
end

function Fant_cfd.cl_state( self, data )
	if data.OnOff then
		self.shape:getInteractable():setPoseWeight( 0, 1 )
	else
		self.shape:getInteractable():setPoseWeight( 0, 0 )
	end
end


function Fant_cfd.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end
