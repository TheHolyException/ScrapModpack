Fant_Gyroscope = class()
Fant_Gyroscope.AngleForce = 100
Fant_Gyroscope.LeverDistance = 1
Fant_Gyroscope.DefaultColor = "df7f01ff"
Fant_Gyroscope.poseWeightCount = 1
Fant_Gyroscope.maxParentCount = 2
Fant_Gyroscope.connectionInput = sm.interactable.connectionType.logic
Fant_Gyroscope.colorNormal = sm.color.new( 0x0068068ff )
Fant_Gyroscope.colorHighlight = sm.color.new( 0x0028028ff )
Fant_Gyroscope.SliderSteps = 50

function Fant_Gyroscope.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { Power = 0.5 } 
		self.storage:save( self.sv.storage )
	end
	self.Power = self.sv.storage.Power
end

function Fant_Gyroscope.server_onDestroy( self )
	self:SaveData()
end

function Fant_Gyroscope.sv_SetData( self, data )
	self.Power = data.Power
	self:SaveData()
end	

function Fant_Gyroscope.SaveData( self )
	self.sv.storage = { Power = self.Power } 
	self.storage:save( self.sv.storage )
end

function Fant_Gyroscope.getInputs( self )
	local parents = self.interactable:getParents()
	local Logic_1 = nil
	local Logic_2 = nil
	local ExternalInput = nil
	for i = 1, #parents do
		if parents[i] then
			if parents[i]:hasOutputType( sm.interactable.connectionType.logic ) then
				if parents[i].shape:getShapeUuid() == obj_interactive_fant_angle_sensor then
					ExternalInput = parents[i]
				end
				if parents[i].shape:getShapeUuid() == obj_interactive_fant_gyroscope then
					ExternalInput = parents[i]
				end
				if parents[i].shape:getShapeUuid() == obj_interactive_fant_gyroscope3x3 then
					ExternalInput = parents[i]
				end
				if tostring( parents[i].shape.color ) == self.DefaultColor then
					if Logic_1 ~= nil then
						self.network:sendToClients( "cl_error" )
					end
					Logic_1 = parents[i]		
				else
					Logic_2 = parents[i]		
				end
			end		
		end
	end	
	if not Logic_1 and not Logic_2 then
		return 0, 0, ExternalInput
	end
	if Logic_1 and Logic_2 then
		if Logic_1:isActive() and Logic_2:isActive() then
			return 0, 1, ExternalInput
		end
		if not Logic_1:isActive() and Logic_2:isActive() then
			return -1, 1, ExternalInput
		end
		if Logic_1:isActive() and not Logic_2:isActive() then
			return 1, 1, ExternalInput
		end
		if not Logic_1:isActive() and not Logic_2:isActive() then
			return 0, 1, ExternalInput
		end
	end
	if Logic_1 and not Logic_2 then
		if Logic_1:isActive() then
			return 1, 1, ExternalInput
		end
		if not Logic_1:isActive() then
			return 0, 1, ExternalInput
		end
	end
	if Logic_2 and not Logic_1 then
		if Logic_2:isActive() then
			return -1, 1, ExternalInput
		end	
		if not Logic_2:isActive() then
			return 0, 1, ExternalInput
		end	
	end
	return 0, 0, ExternalInput
end 

function Fant_Gyroscope.server_onFixedUpdate( self, dt )
	local Body = sm.shape.getBody( self.shape )
	if Body == nil then
		return
	end
	if not sm.body.isDynamic( Body ) then
		return
	end
	local Input, isActive, ExternalInput = self:getInputs()	
	local data = {}
	if sm.exists( ExternalInput ) then
		data = sm.interactable.getPublicData( ExternalInput.shape:getInteractable() )
	else
		data = sm.interactable.getPublicData( self.shape:getInteractable() )
	end
	if data ~= nil then
		if data.value ~= nil then
			isActive = true
			Input = data.value
		end
	end
	local RotationForce = sm.vec3.new( 0, 0, 0 )
	if Input ~= 0 then
		RotationForce = ( sm.shape.getAt( self.shape ) * ( Input * self.AngleForce * self.Power ) / 2 ) * sm.body.getMass( Body )
	end

	local angvel = -sm.body.getAngularVelocity( Body ) / 3
	
	local Force = angvel * sm.body.getMass( Body ) * self.Power * 5
	
	if sm.vec3.length( Force + RotationForce ) > 0.001 then
		sm.physics.applyTorque( Body, ( Force + RotationForce ) * dt, true )
	end
end

function Fant_Gyroscope.client_onInteract(self, _, state)
	if state == true then	
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Gyroscope" )	
		self:ClientInterfaceSetting()	
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setText( "Interaction", "Made by 00Fant" )
		self.gui:open()		
	end
end

function Fant_Gyroscope.client_onCreate( self )
	self.Power = self.Power or 0
	self.network:sendToServer( "GetData" )
end

function Fant_Gyroscope.GetData( self )	
	self.network:sendToClients( "SetData", { Power = self.Power } )	
end

function Fant_Gyroscope.client_onDestroy( self )
	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end

function Fant_Gyroscope.cl_onGuiClosed( self )
	self.gui:destroy()
	self.gui = nil
end

function Fant_Gyroscope.cl_onSliderChange( self, sliderName, sliderPos )
	self.Power = ( sliderPos / self.SliderSteps )
	self:ClientInterfaceSetting()
	self.network:sendToServer( "sv_SetData", { Power = self.Power } )
end

function Fant_Gyroscope.SetData( self, data )
	self.Power = data.Power
	if self.gui then
		self:ClientInterfaceSetting()
	end
end

function Fant_Gyroscope.ClientInterfaceSetting( self )
	self.gui:setText( "SubTitle", "Power " .. tostring(math.floor( self.Power * self.SliderSteps * 10 ) / 10 ) )			
	self.gui:setSliderData( "Setting", self.SliderSteps + 1, ( self.Power * self.SliderSteps ) )
end

function Fant_Gyroscope.cl_error( self ) 
	sm.gui.displayAlertText( "Gyroscope\nPaint the Second Input Different!", 1 )
end
