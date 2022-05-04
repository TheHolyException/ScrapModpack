Fant_Smoker = class()
Fant_Smoker.maxParentCount = 1
Fant_Smoker.connectionInput = sm.interactable.connectionType.logic
Fant_Smoker.poseWeightCount = 2
Fant_Smoker.SmokeSpeed = 0.2
Fant_Smoker.SliderMax = 20

function Fant_Smoker.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { state = false, slider = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.state = self.sv.storage.state
	self.sv_slider = self.sv.storage.slider
end

function Fant_Smoker.client_onCreate( self )
	self.sv = {}
	self.value = 0
	self.lastvalue = 1
	self.smokeTimer = 0
	self.cl_slider = 0
	self.network:sendToServer( "GetItemFramData" )
	self.Effect = sm.effect.createEffect( "Fire- Smoke Medium01", self )
	self.smokeEffectToggle = false
end

function Fant_Smoker.client_onDestroy( self )
	self.Effect:stop()	
end

function Fant_Smoker.GetItemFramData( self )
	self.network:sendToClients( "UpdateSmoke", { state = self.state, slider = self.sv_slider } )		
end

function Fant_Smoker.NETUpdateSmoke(self, data )
	self.state = data.state
	self.sv_slider = data.slider
	self.sv.storage = data
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "UpdateSmoke", data )
end

function Fant_Smoker.UpdateSmoke( self, data )
	self.state = data.state
	self.cl_slider = data.slider
	if self.state then
		
	else
		self.Effect:stop()	
	end
end

function Fant_Smoker.server_onFixedUpdate( self )
	local parent = self.shape:getInteractable():getSingleParent()
	if parent then
		if parent.active ~= self.state then
			self.state = parent.active
			self.sv.storage = { state = self.state, slider = self.sv_slider }
			self.storage:save( self.sv.storage )
			self.network:sendToClients( "UpdateSmoke", self.sv.storage )
			sm.interactable.setActive( self.interactable, self.state )	
		end			
	end	
end

function Fant_Smoker.client_onUpdate( self, dt )
	local hatchspeed = 5
	if self.state then
		if self.value < 1 then
			self.value = self.value + ( ( 1 / 40 ) * hatchspeed )
			if self.value >= 1 then
				self.value = 1
			end
		end
		self.Effect:setPosition( self.shape.worldPosition - ( sm.shape.getRight( self.shape ) * 0.1 ) )
		self.Effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.shape.getUp( self.shape ) ) )
		
		if self.smokeTimer >= 1 - ( dt * self.SmokeSpeed * self.cl_slider ) then
			if not self.smokeEffectToggle then
				self.smokeEffectToggle = true
				self.Effect:start()
			end
		else
			if self.smokeEffectToggle then
				self.smokeEffectToggle = false
				self.Effect:stop()	
			end	
		end
		self.smokeTimer = self.smokeTimer + ( dt * self.SmokeSpeed * self.cl_slider )
		if self.smokeTimer > 1 then
			self.smokeTimer = 0
		end
	else
		self.smokeTimer = 0
		if self.value > 0 then
			self.value = self.value - ( ( 1 / 40 ) * hatchspeed )
			if self.value <= 0 then
				self.value = 0
			end
		end
	end
	if self.lastvalue ~= self.value then
		self.lastvalue = self.value
		self.shape:getInteractable():setPoseWeight( 0, self.value )
	end
end


function Fant_Smoker.client_onInteract(self, character, state)
	if state == true then	
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Smoker" )	
		self:ClientInterfaceSetting()
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setText( "Interaction", "Made by 00Fant" )
		self.gui:open()		
	end
end

function Fant_Smoker.cl_onGuiClosed( self )

end

function Fant_Smoker.cl_onSliderChange( self, sliderName, sliderPos )
	self.cl_slider = sliderPos
	self:ClientInterfaceSetting()
	self.network:sendToServer( "sv_setslider", self.cl_slider )
end

function Fant_Smoker.sv_setslider( self, slider )
	self.sv_slider = slider
	self.saved = { slider = self.sv_slider }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_setSlider", self.sv_slider )	
end

function Fant_Smoker.cl_setSlider( self, slider )
	self.cl_slider = slider
end

function Fant_Smoker.ClientInterfaceSetting( self )
	self.gui:setText( "SubTitle", "Threshold: " .. tostring( math.floor( self.cl_slider ) ) )			
	self.gui:setSliderData( "Setting", self.SliderMax, self.cl_slider )
end

