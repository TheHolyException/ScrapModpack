Fant_Angle_Sensor = class()
Fant_Angle_Sensor.maxChildCount = 255
Fant_Angle_Sensor.connectionOutput = sm.interactable.connectionType.logic
Fant_Angle_Sensor.maxParentCount = 1
Fant_Angle_Sensor.connectionInput = sm.interactable.connectionType.logic
Fant_Angle_Sensor.poseWeightCount = 2	
Fant_Angle_Sensor.AngleOffset = 90
Fant_Angle_Sensor.MaxAngle = 180
Fant_Angle_Sensor.colorNormal = sm.color.new( 0x800000ff )
Fant_Angle_Sensor.colorHighlight = sm.color.new( 0xff0000ff )

function Fant_Angle_Sensor.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { angle = self.AngleOffset } 
		self.storage:save( self.sv.storage )
	end
	self.angle = self.sv.storage.angle
	self.laststate = nil
	self.LastData = nil
end

function Fant_Angle_Sensor.client_onCreate( self )
	self.angle = self.angle or self.AngleOffset
	self.network:sendToServer( "sv_getData" )
end

function Fant_Angle_Sensor.sv_getData( self )
	self.network:sendToClients( "cl_getData", self.angle )
end

function Fant_Angle_Sensor.cl_getData( self , value )
	self.angle = value
end


function Fant_Angle_Sensor.server_onFixedUpdate( self )
	--local direction 
	local parent = self.shape:getInteractable():getSingleParent()
	local isActive = false
	if parent then
		isActive = parent.active 		
	end	
	local Body = sm.shape.getBody( self.shape )
	if Body == nil then
		return
	end
	local AngleValue = ( self.shape:getWorldPosition() + ( sm.shape.getRight( self.shape ) * 1 ) ).z - ( self.shape:getWorldPosition() - ( sm.shape.getRight( self.shape ) * 1 ) ).z
	local DataValue = ( AngleValue - ( self.angle - self.AngleOffset ) / self.AngleOffset ) / 2
	if DataValue < 0 then 
		self.state = true
	else
		self.state = false
	end
	if isActive then
		self.state = false
	end
	if self.laststate ~= self.state then
		self.laststate = self.state		
		sm.interactable.setActive( self.interactable, self.state )
		if self.state then
			self.network:sendToClients( "cl_setPoseWeight", { value = 0 } )
		else
			self.network:sendToClients( "cl_setPoseWeight", { value = 1 } )
		end
	end
	local data = sm.interactable.getPublicData( self.interactable )
	if data == nil then
		data = {}
	end
	local forceValue = -DataValue / 5 
	if forceValue < -1 then
		forceValue = -1
	end
	if forceValue > 1 then
		forceValue = 1
	end
	forceValue = math.floor( forceValue * 100 ) / 100
	data.value = forceValue
	if isActive then
		data.value = 0
	end
	if self.LastData ~= data then
		self.LastData = data
		sm.interactable.setPublicData( self.interactable, data )
	end
end

function Fant_Angle_Sensor.cl_setPoseWeight( self, data )
	self.shape:getInteractable():setPoseWeight( 0, data.value )
end



-- function Fant_Angle_Sensor.client_canInteract( self, character )
	-- sm.gui.setCenterIcon( "Use" )
	-- local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	-- sm.gui.setInteractionText( "", keyBindingText, "Angle Sensor Settings" )
	-- return true
-- end


function Fant_Angle_Sensor.client_onInteract(self, character, state)
	if state == true then	
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Angle Sensor" )	
		self:ClientInterfaceSetting()
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setText( "Interaction", "Made by 00Fant" )
		self.gui:open()		
	end
end


function Fant_Angle_Sensor.cl_onGuiClosed( self )

end


function Fant_Angle_Sensor.cl_onSliderChange( self, sliderName, sliderPos )
	self.angle = sliderPos
	self:ClientInterfaceSetting()
	self.network:sendToServer( "sv_setAngle", self.angle )
end

function Fant_Angle_Sensor.sv_setAngle( self, angle )
	self.angle = angle
	self.saved = { angle = self.angle }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_setAngle", self.angle )	
end

function Fant_Angle_Sensor.cl_setAngle( self, angle )
	self.angle = angle
end

function Fant_Angle_Sensor.cl_HudPrint( self, text ) 
	sm.gui.displayAlertText( text, 2 )
end

function Fant_Angle_Sensor.ClientInterfaceSetting( self )
	self.gui:setText( "SubTitle", "Threshold: " .. tostring(math.floor( self.angle - self.AngleOffset )) )			
	self.gui:setSliderData( "Setting", self.MaxAngle+1, self.angle )
end
