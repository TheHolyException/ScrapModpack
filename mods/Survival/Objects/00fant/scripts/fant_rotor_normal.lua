Fant_Rotor_Normal = class()
Fant_Rotor_Normal.maxParentCount = 4
Fant_Rotor_Normal.connectionInput = sm.interactable.connectionType.logic
Fant_Rotor_Normal.TiltSpeed = 1
Fant_Rotor_Normal.SliderSteps = 10
Fant_Rotor_Normal.Force = 150

function Fant_Rotor_Normal.server_onCreate( self )
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { tilt = 0.5, length = 0.01, defaultTilt = 0.5 }
	end
	self.tilt = self.saved.tilt or 0.5
	self.length = self.saved.length or 0.01
	self.lastTilt = self.tilt
	self.lastLength = self.length
	self.lastfineTune = -10
	self.defaultTilt = self.saved.defaultTilt or 0.5
	self.network:sendToClients( "cl_set_data", { tilt = self.tilt, length = self.length, defaultTilt = self.defaultTilt } )
end

function Fant_Rotor_Normal.client_onCreate( self )
	self.animation_length = self.animation_length or 0
	self.animation_tilt = self.animation_tilt or 0
	self.animation_defaultTilt = self.animation_defaultTilt or 0
	self.sliderValue = self.sliderValue or 0
	self.sliderValue2 = self.sliderValue2 or 0.5
	self.interactable:setAnimEnabled( "length", true )	
	self.interactable:setAnimEnabled( "tilt", true )
	self.interactable:setAnimProgress( "length", -1 )
	self.interactable:setAnimProgress( "tilt", -1 )
	self.network:sendToServer( "sv_getData" )
end

function Fant_Rotor_Normal.server_onDestroy( self )	
	self.saved = { tilt = self.tilt, length = self.length, defaultTilt = self.defaultTilt }
	self.storage:save( self.saved )
end

function Fant_Rotor_Normal.sv_getData( self )
	self.network:sendToClients( "cl_set_data", { tilt = self.tilt, length = self.length, defaultTilt = self.defaultTilt } )
end

function Fant_Rotor_Normal.cl_set_data( self, data )
	self.animation_length = data.length
	self.animation_tilt = data.tilt
	self.animation_defaultTilt = data.defaultTilt
	
	self.sliderValue = math.floor( ( self.animation_length * self.SliderSteps ) * 10 + 0.1 ) / 10
	if self.sliderValue < 0.5 then
		self.sliderValue = 0
	end
	self.sliderValue2 = math.floor( ( self.animation_defaultTilt * self.SliderSteps ) * 10 + 0.1 ) / 10
	if self.sliderValue2 < 0.5 then
		self.sliderValue2 = 0
	end
	
	self:cl_updateRotor()
end

function Fant_Rotor_Normal.getParentInputs( self )
	local down = false
	local up = false
	local fineTune = 0
	for i, parent in pairs( self.interactable:getParents() ) do
		if parent:hasOutputType( sm.interactable.connectionType.logic ) then
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) == "0a3ee2ff" then  --blue
				if parent.active then
					fineTune = -1
				end
			end
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) == "d02525ff" then --red
				if parent.active then
					fineTune = 1
				end
			end
			
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) == "df7f01ff" then
				down = parent.active
			end
			
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) ~= "df7f01ff" and tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) ~= "0a3ee2ff" and tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) ~= "d02525ff" then
				up = parent.active
			end
			
		end
	end
	return down, up, fineTune
end

function Fant_Rotor_Normal.server_onFixedUpdate( self, dt )
	local up, down, fineTune = self:getParentInputs()
	if fineTune ~= self.lastfineTune then
		self.lastfineTune = fineTune
		self.defaultTilt = self.defaultTilt + ( fineTune / self.SliderSteps )
		if self.defaultTilt < 0.01 then
			self.defaultTilt = 0.01
		end
		if self.defaultTilt > 1 then
			self.defaultTilt = 1
		end
		self.network:sendToClients( "cl_set_tilt", { tilt = self.tilt, defaultTilt = self.defaultTilt }  )
	end
	if up then
		self.tilt = self.tilt + ( dt * self.TiltSpeed )
		if self.tilt >= 1 then
			self.tilt = 1
		end
	elseif down then
		self.tilt = self.tilt - ( dt * self.TiltSpeed )
		if self.tilt < 0.01 then
			self.tilt = 0.01
		end
	else
		if self.tilt > self.defaultTilt then
			self.tilt = self.tilt - ( dt * self.TiltSpeed )
			if self.tilt < self.defaultTilt then
				self.tilt = self.defaultTilt
			end
		end
		if self.tilt < self.defaultTilt then
			self.tilt = self.tilt + ( dt * self.TiltSpeed )
			if self.tilt > self.defaultTilt then
				self.tilt = self.defaultTilt
			end
		end
	end
	if self.tilt ~= self.lastTilt then
		self.lastTilt = self.tilt
		self.network:sendToClients( "cl_set_tilt", { tilt = self.tilt, defaultTilt = self.defaultTilt }  )
	end
	local body = sm.shape.getBody( self.shape )
	if body ~= nil then
		local relTilt = ( self.tilt * 2 ) - 1
		local relLength = 0.2 + ( self.length * 0.8 )
		local Position = sm.shape.getWorldPosition( self.shape )
		local LocalVelocity = self.shape:transformPoint( Position + ( sm.shape.getVelocity( self.shape ) ) )
		local AngularVelocity = sm.body.getAngularVelocity( body )

		local LocalAngularVelocity = AngularVelocity:dot( sm.shape.getAt( self.shape ) )
		local ForceDir = 1
		if LocalAngularVelocity > 0 then
			ForceDir = -1
		end
		local AngVel =  sm.util.clamp( math.abs( LocalAngularVelocity ) / 120, 0, 1 )
		local VelLength = 1 - sm.util.clamp( ( math.floor( LocalVelocity.y * 100 ) / 100 ) / 75, 0, 1 )
		if LocalVelocity.y <= 0 then
			VelLength = 1
		end
		if VelLength > 1 then
			VelLength = 1
		end
		local Force = sm.util.clamp( sm.vec3.length( AngularVelocity ) / 75, 0, 1 ) * VelLength * ForceDir * self.Force * relTilt * relLength * AngVel
		sm.physics.applyImpulse( self.shape, sm.vec3.new( 0, Force * 30, 0 ), false, sm.vec3.new( 0, 0, 0 ) )
	end
end

function Fant_Rotor_Normal.cl_set_tilt( self, data )
	self.animation_tilt = data.tilt
	self.animation_defaultTilt = data.defaultTilt
	self.sliderValue2 = math.floor( data.defaultTilt * ( self.SliderSteps + 0.5 ) )
	self:cl_updateRotor()
end

function Fant_Rotor_Normal.cl_updateRotor( self )
	self.interactable:setAnimProgress( "length", self.animation_length )
	self.interactable:setAnimProgress( "tilt", self.animation_tilt )
end

function Fant_Rotor_Normal.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Tilt" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Length"  )
	return true
end

function Fant_Rotor_Normal.client_onTinker( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Adjustable Rotor" )
		self.gui:setText( "Interaction", "Length" )	
		self.gui:setSliderData( "Setting",self.SliderSteps+1, self.sliderValue )
		self.gui:setText( "SubTitle", "Length: " .. tostring( self.sliderValue ) )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setIconImage( "Icon", obj_interactive_fant_rotor )
		self.gui:setVisible( "FuelContainer", false )
		self.gui:open()
	end
end

function Fant_Rotor_Normal.cl_onSliderChange( self, sliderName, sliderPos )
	self.sliderValue = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "SubTitle", "Length: " .. tostring( self.sliderValue ) )
	end
	self.network:sendToServer( "setSliderValue", self.sliderValue )
end

function Fant_Rotor_Normal.setSliderValue( self, sliderValue )
	self.length = ( sliderValue ) / self.SliderSteps
	if self.length < 0.01 then
		self.length = 0.01
	end
	if self.length > 1 then
		self.length = 1
	end
	self.saved = { tilt = self.tilt, length = self.length, defaultTilt = self.defaultTilt }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_set_data", { tilt = self.tilt, length = self.length, defaultTilt = self.defaultTilt } )
end

function Fant_Rotor_Normal.client_onInteract( self, character, state )
	if state == true then
		if self.gui2 == nil then
			self.gui2 = sm.gui.createEngineGui()
		end
		self.gui2:setText( "Name", "Adjustable Rotor" )
		self.gui2:setText( "Interaction", "Tilt" )	
		self.gui2:setSliderData( "Setting",self.SliderSteps+1, self.sliderValue2 )
		self.gui2:setText( "SubTitle", "Tilt: " .. tostring( self.sliderValue2 ) )
		self.gui2:setSliderCallback( "Setting", "cl_onSliderChange2" )
		self.gui2:setIconImage( "Icon", obj_interactive_fant_rotor )
		self.gui2:setVisible( "FuelContainer", false )
		self.gui2:open()
	end
end

function Fant_Rotor_Normal.cl_onSliderChange2( self, sliderName, sliderPos )
	self.sliderValue2 = sliderPos
	if self.gui2 ~= nil then
		self.gui2:setText( "SubTitle", "Tilt: " .. tostring( self.sliderValue2 ) )
	end
	self.network:sendToServer( "setSliderValue2", self.sliderValue2 )
end

function Fant_Rotor_Normal.setSliderValue2( self, sliderValue2 )
	self.defaultTilt = ( sliderValue2 ) / self.SliderSteps
	if self.defaultTilt < 0.01 then
		self.defaultTilt = 0.01
	end
	if self.defaultTilt > 1 then
		self.defaultTilt = 1
	end
	self.saved = { tilt = self.tilt, length = self.length, defaultTilt = self.defaultTilt }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_set_data", { tilt = self.tilt, length = self.length, defaultTilt = self.defaultTilt } )
end








