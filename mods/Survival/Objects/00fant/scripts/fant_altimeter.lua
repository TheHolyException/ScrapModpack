Fant_Altimeter = class()
Fant_Altimeter.DefaultColor = "df7f01ff"
Fant_Altimeter.poseWeightCount = 1
Fant_Altimeter.maxChildCount = 256
Fant_Altimeter.connectionOutput = sm.interactable.connectionType.logic
Fant_Altimeter.maxParentCount = 1
Fant_Altimeter.connectionInput = sm.interactable.connectionType.logic
Fant_Altimeter.colorNormal = sm.color.new( 0x0000680ff )
Fant_Altimeter.colorHighlight = sm.color.new( 0x0000ff0ff )
Fant_Altimeter.SliderSteps = 1000

function Fant_Altimeter.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { Height = 0.5 } 
		self.storage:save( self.sv.storage )
	end
	self.Height = self.sv.storage.Height
	self.lastState = false
end

function Fant_Altimeter.getHeight( self )
	return ( math.floor( ( ( self.shape.worldPosition.z - 0.5 ) / sm.construction.constants.subdivideRatio ) * 10 ) / 10 )
end

function Fant_Altimeter.server_onDestroy( self )
	self:SaveData()
end

function Fant_Altimeter.sv_SetData( self, data )
	self.Height = data.Height
	self:SaveData()
end	

function Fant_Altimeter.SaveData( self )
	self.sv.storage = { Height = self.Height } 
	self.storage:save( self.sv.storage )
end

function Fant_Altimeter.server_onFixedUpdate( self, dt )
	if self.shape:getBody() then
		if not self.shape:getBody():isDynamic() then
			self.lastState = not self.lastState
		end
	end
	local currentHeight = self:getHeight()
	if currentHeight <= self.Height * self.SliderSteps then
		if not self.lastState then
			self.network:sendToClients( "cl_setPoseWeight", 1 )
			sm.interactable.setActive( self.interactable, true )
			self.lastState = true
		end
	else
		if self.lastState then
			self.network:sendToClients( "cl_setPoseWeight", 0 )
			sm.interactable.setActive( self.interactable, false )
			self.lastState = false
		end
	end
	local parent = self.interactable:getSingleParent()
	if parent ~= nil then
		if parent:isActive() then
			local newHeight = self:getHeight()
			self.Height = self:getHeight() / self.SliderSteps
			if newHeight ~= self.LastHeight then				
				self.LastHeight = newHeight
				self:SaveData()
				self.network:sendToClients( "SetData", { Height = self.Height } )	
			end
		end
	end
end

function Fant_Altimeter.client_onInteract(self, _, state)
	if state == true then	
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Altimeter" )	
		self:ClientInterfaceSetting()	
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setText( "Interaction", "Current Height:" .. tostring( self:getHeight() ) .. " \nUse Mousewheel for Small Adjustments!" )
		self.gui:open()		
	end
end

function Fant_Altimeter.client_onCreate( self )
	self.Height = self.Height or 0
	self.network:sendToServer( "GetData" )
end

function Fant_Altimeter.GetData( self )	
	self.network:sendToClients( "SetData", { Height = self.Height } )	
end

function Fant_Altimeter.client_onDestroy( self )
	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end

function Fant_Altimeter.cl_onGuiClosed( self )
	self.gui:destroy()
	self.gui = nil
end

function Fant_Altimeter.cl_onSliderChange( self, sliderName, sliderPos )
	self.Height = ( sliderPos / self.SliderSteps )
	self:ClientInterfaceSetting()
	self.network:sendToServer( "sv_SetData", { Height = self.Height } )
end

function Fant_Altimeter.SetData( self, data )
	self.Height = data.Height
	if self.gui then
		self:ClientInterfaceSetting()
	end
end

function Fant_Altimeter.ClientInterfaceSetting( self )
	self.gui:setText( "SubTitle", "Height " .. tostring( math.floor( ( self.Height * self.SliderSteps + 0.5 ) ) ) )			
	self.gui:setSliderData( "Setting", self.SliderSteps+1, ( self.Height * self.SliderSteps ) )
end

function Fant_Altimeter.cl_setPoseWeight( self, state )
	self.shape:getInteractable():setPoseWeight( 0, state )
end
