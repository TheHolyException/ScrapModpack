Fant_Gearbox = class()
Fant_Gearbox.maxParentCount = 3
Fant_Gearbox.maxChildCount = 255
Fant_Gearbox.connectionInput = sm.interactable.connectionType.logic
Fant_Gearbox.connectionOutput = sm.interactable.connectionType.bearing
Fant_Gearbox.colorNormal = sm.color.new( 0xffa500ff )
Fant_Gearbox.colorHighlight = sm.color.new( 0xff4500ff )
Fant_Gearbox_MaxTorque = 2000

Fant_Gearbox.Gears = {
	{ Ratio = 0.25, Torque = Fant_Gearbox_MaxTorque / 1 },
	{ Ratio = 0.5, 	Torque = Fant_Gearbox_MaxTorque / 1.5 },
	{ Ratio = 1, 	Torque = Fant_Gearbox_MaxTorque / 2 },
	{ Ratio = 2, 	Torque = Fant_Gearbox_MaxTorque / 2.5 },
	{ Ratio = 3, 	Torque = Fant_Gearbox_MaxTorque / 3 },
	{ Ratio = 4, 	Torque = Fant_Gearbox_MaxTorque / 3.5 }
}
	
function Fant_Gearbox.server_onCreate( self )
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { slider = math.floor( #self.Gears / 2.5 ) }
	end
	self.network:sendToClients( "cl_setSlider", self.saved.slider )
	self.storage:save( self.saved )
end 

function Fant_Gearbox.getGears( self, gear )
	if self.Gears ~= nil then
		if self.Gears[ gear + 1 ] ~= nil then
			return self.Gears[ gear + 1 ].Ratio, self.Gears[ gear + 1 ].Torque
		else
			return 0, 0
		end	
	else
		return 0, 0
	end
end

function Fant_Gearbox.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Gearbox Settings" )
	return true
end

function Fant_Gearbox.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Gearbox" )
		self.gui:setSliderData( "Setting", #self.Gears, self.slider )		
		local Ratio, Torque = self:getGears( self.slider )	
		self.gui:setText( "SubTitle", "Ratio: " .. tostring( Ratio ) )
		self.gui:setText( "Interaction", "Torque: " .. tostring( math.floor( Torque ) ) )			
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setIconImage( "Icon", obj_interactive_fant_gearbox )
		self.gui:setVisible( "BackgroundBattery", false )
		self.gui:setVisible( "FuelGrid", false )
		self.gui:open()
	end
end

function Fant_Gearbox.cl_onSliderChange( self, sliderName, sliderPos )
	self.slider = sliderPos
	if self.gui ~= nil then
		local Ratio, Torque = self:getGears( self.slider )
		self.gui:setText( "SubTitle", "Ratio: " .. tostring( Ratio ) )
		self.gui:setText( "Interaction", "Torque: " .. tostring( math.floor( Torque ) ) )	
	end
	self.network:sendToServer( "sv_setSlider", self.slider )
end

function Fant_Gearbox.sv_setSlider( self, slider )
	self.saved.slider = slider
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_setSlider", self.saved.slider )	
end

function Fant_Gearbox.cl_setSlider( self, slider )
	self.slider = slider
end

function Fant_Gearbox.getParentInputs( self )
	local gearShift = 0
	local gearBreak = 0
	for i, parent in pairs( self.interactable:getParents() ) do
		if parent:hasOutputType( sm.interactable.connectionType.logic ) then		
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) == "d02525ff" then
				if parent.active then
					gearBreak = 1
				end
			end
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) == "df7f01ff" then
				if parent.active then
					gearShift = 1
				end
			end		
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) ~= "df7f01ff" and tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) ~= "d02525ff" then
				if parent.active then
					gearShift = -1
				end
			end
		end
	end
	return gearShift, gearBreak
end

function Fant_Gearbox.server_onFixedUpdate( self, dt )
	local GearShift, GearBreak = self:getParentInputs()
	if GearShift ~= self.lastGearShift then
		self.lastGearShift = GearShift
		self.saved.slider = self.saved.slider + GearShift
		if self.saved.slider < 0 then
			self.saved.slider = 0
		end
		if self.saved.slider > #self.Gears - 1 then
			self.saved.slider = #self.Gears - 1
		end
		self.storage:save( self.saved )
		self.network:sendToClients( "cl_setSlider", self.saved.slider )
	end
	local InputShaft = nil
	local OutputShafts = {}
	for _, joint in ipairs( self.interactable:getJoints() ) do
		if joint:getType() == "bearing" then
			if tostring( sm.joint.getColor( joint ) ) ~= "df7f01ff" then
				InputShaft = joint
			else
				table.insert( OutputShafts, joint )
			end
		end
	end
	local Ratio, Torque = self:getGears( self.saved.slider )
	if InputShaft ~= nil and sm.exists( InputShaft ) then
		InputShaft:setMotorVelocity( 0, Torque / ( Fant_Gearbox_MaxTorque * 10 ) )
		for i, output in pairs( OutputShafts ) do		
			if output ~= nil and sm.exists( output ) then
				output:setMotorVelocity( InputShaft:getAngularVelocity() * Ratio * ( 1 - GearBreak ), Torque )
			end
		end
	end
end

