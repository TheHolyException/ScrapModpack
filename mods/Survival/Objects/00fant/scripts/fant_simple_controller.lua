dofile( "$SURVIVAL_DATA/Scripts/game/interactables/DriverSeat.lua")

Fant_Simple_Controller = class( DriverSeat )
Fant_Simple_Controller.maxParentCount = 2
Fant_Simple_Controller.maxChildCount = 255
Fant_Simple_Controller.connectionInput = sm.interactable.connectionType.logic
Fant_Simple_Controller.connectionOutput = sm.interactable.connectionType.seated + sm.interactable.connectionType.power + sm.interactable.connectionType.bearing + sm.interactable.connectionType.piston
Fant_Simple_Controller.colorNormal = sm.color.new( 0x0068068ff )
Fant_Simple_Controller.colorHighlight = sm.color.new( 0x0028028ff )
Fant_Simple_Controller.DefaultColor = "df7f01ff"
Fant_Simple_Controller.SliderSteps = 50
Fant_Simple_Controller.MaxPistonForce = 1000000
Fant_Simple_Controller.lastPistons = 0

Fant_Simple_Controller.GasEngines = {
	"1bfccc0a-828f-475c-882c-87d5a96054c9",
	"33d01ddd-f32b-4a9a-87d6-efb6710b389c",
	"470b9a92-ed94-4ef2-b1ea-b45f47ef0982",
	"bfcaac1a-5a7f-4fba-9980-1159617a7212",
	"3091926a-9340-46d9-83d6-4fd7c68ad950"
}

function Fant_Simple_Controller.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { Power = 0.5, ShortPiston = 0, LongPiston = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.Power = self.sv.storage.Power or 0.5
	self.ShortPiston = self.sv.storage.ShortPiston or 0
	self.LongPiston = self.sv.storage.LongPiston or 0
	self.ConnectedPistonData = {}
end

function Fant_Simple_Controller.sv_SetData( self, data )
	self.Power = data.Power
	self:SaveData()
end	

function Fant_Simple_Controller.SaveData( self )
	self.sv.storage = { Power = self.Power, ShortPiston = self.ShortPiston, LongPiston = self.LongPiston } 
	self.storage:save( self.sv.storage )
end

function Fant_Simple_Controller.client_onInteract(self, _, state)
	if state == true then	
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Piston Speed" )	
		self:ClientInterfaceSetting()	
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setText( "Interaction", "Made by 00Fant" )
		self.gui:open()		
	end
end

function Fant_Simple_Controller.client_onCreate( self )
	self.Power = self.Power or 0
	self.network:sendToServer( "GetData" )
	self.cl = {}
	self.cl.updateDelay = 0.0
	self.cl.updateSettings = {}
end

function Fant_Simple_Controller.GetData( self )	
	self.network:sendToClients( "SetData", { Power = self.Power } )	
end

function Fant_Simple_Controller.client_onDestroy( self )
	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end

function Fant_Simple_Controller.cl_onGuiClosed( self )
	self.gui:destroy()
	self.gui = nil
end

function Fant_Simple_Controller.cl_onSliderChange( self, sliderName, sliderPos )
	self.Power = ( sliderPos / self.SliderSteps )
	self:ClientInterfaceSetting()
	self.network:sendToServer( "sv_SetData", { Power = self.Power } )
end

function Fant_Simple_Controller.SetData( self, data )
	self.Power = data.Power
	if self.gui then
		self:ClientInterfaceSetting()
	end
end

function Fant_Simple_Controller.ClientInterfaceSetting( self )
	self.gui:setText( "SubTitle", "Power " .. tostring(math.floor( self.Power * self.SliderSteps * 10 ) / 10 ) )			
	self.gui:setSliderData( "Setting", self.SliderSteps + 1, ( self.Power * self.SliderSteps ) )
end

function Fant_Simple_Controller.IsGasEngine( self, engine )
	for i = 1, #self.GasEngines do
		if engine == self.GasEngines[i] then
			return true
		end
	end
	return false
end

function Fant_Simple_Controller.getInputs( self, dt )
	local parents = self.interactable:getParents()
	local Logic_1 = nil
	local Logic_2 = nil
	local active = 0
	
	for i = 1, #parents do
		if parents[i] then
			if parents[i]:hasOutputType( sm.interactable.connectionType.logic ) then
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

	local children = self.interactable:getChildren()
	local HasGasengine = false
	if children then
		if children[1] then
			if children[1].shape then
				if self:IsGasEngine( tostring( children[1].shape:getShapeUuid() ) ) then
					HasGasengine = true
				end
			end
		end
	end

	if self.OnTimer == nil then
		self.OnTimer = 0
	end
	if HasGasengine then
		if Logic_1 and Logic_2 then
			if Logic_1:isActive() or Logic_2:isActive() then
				self.OnTimer = 5
			end
		end
		if self.OnTimer > 0 then
			self.OnTimer = self.OnTimer - dt
			if self.OnTimer <= 0 then
				self.OnTimer = 0
			end
			active = 1
		else	
			active = 0
		end
	else
		if Logic_1 and Logic_2 then
			active = 1
		else
			active = 0
		end
	end
	if Logic_1 and Logic_2 then
		if Logic_1:isActive() and Logic_2:isActive() then
			return 0, active
		end
		if not Logic_1:isActive() and Logic_2:isActive() then
			return -1, active
		end
		if Logic_1:isActive() and not Logic_2:isActive() then
			return 1, active
		end
	end
	if Logic_1 and not Logic_2 then
		if Logic_1:isActive() then
			return 1, active
		end
	end
	if Logic_2 and not Logic_1 then
		if Logic_2:isActive() then
			return -1, active
		end	
	end
	return 0, active
end

function Fant_Simple_Controller.server_onFixedUpdate( self, dt )
	local LogicInput, Active = self:getInputs( dt )
	self.interactable:setPower( LogicInput )
	self.interactable:setActive( Active )
	self:SetPistons( LogicInput, dt )
	if LogicInput == 1 then
		self.interactable:setSteeringFlag( sm.interactable.steering.right )
		self.interactable:setSteeringFlag( sm.interactable.steering.forward )
		self.interactable:unsetSteeringFlag( sm.interactable.steering.left )
		self.interactable:unsetSteeringFlag( sm.interactable.steering.backward )
	elseif LogicInput == -1 then
		self.interactable:setSteeringFlag( sm.interactable.steering.left )
		self.interactable:setSteeringFlag( sm.interactable.steering.backward )
		self.interactable:unsetSteeringFlag( sm.interactable.steering.right )
		self.interactable:unsetSteeringFlag( sm.interactable.steering.forward )
	else
		self.interactable:unsetSteeringFlag( sm.interactable.steering.right )
		self.interactable:unsetSteeringFlag( sm.interactable.steering.left )
		self.interactable:unsetSteeringFlag( sm.interactable.steering.forward )
		self.interactable:unsetSteeringFlag( sm.interactable.steering.backward )
	end
	
	self:RefreshPistons()
end

function Fant_Simple_Controller.RefreshPistons( self )
	local Pistons = sm.interactable.getPistons( self.interactable )
	if Pistons == nil then
		return
	end
	if #Pistons == 0 then
		return
	end
	local PistonCount = 0
	for k, piston in pairs( Pistons ) do
		PistonCount = PistonCount + 1
	end
	if PistonCount ~= self.lastPistons then
		self.lastPistons = PistonCount
		local obj = sm.json.parseJsonString( sm.creation.exportToString( self.shape:getBody() ) )
		self.ConnectedPistonData = {}
		for i, k in pairs( obj.joints ) do
			table.insert( self.ConnectedPistonData, { uuid = k.shapeId, id = k.id } )
		end
	end
end

function Fant_Simple_Controller.SetPistons( self, state, dt )
	local Pistons = sm.interactable.getPistons( self.interactable )
	if Pistons == nil then
		return
	end
	if #Pistons == 0 then
		return
	end
	local speed = ( state * dt * self.Power * self.SliderSteps )
	self.ShortPiston = sm.util.clamp( self.ShortPiston + speed, 0, 16 )
	self.LongPiston = sm.util.clamp( self.LongPiston + speed, 0, 128 )
	if state ~= self.lastState then
		self.lastState = state
		self:SaveData()
	end
	for k, piston in pairs( Pistons ) do	
		for i, pistonData in pairs( self.ConnectedPistonData ) do
			if pistonData.id == piston:getId() then
				if tostring( pistonData.uuid ) ~= "dff53b11-2d8d-4044-ad51-59321f117f8e" then
					sm.joint.setTargetLength( piston, self.ShortPiston, 10, self.MaxPistonForce )
				else
					sm.joint.setTargetLength( piston, self.LongPiston, 10, self.MaxPistonForce )
				end
			end
		end
	end
end

function Fant_Simple_Controller.client_getAvailableChildConnectionCount( self, connectionType )
	return 255 - #self.interactable:getChildren()
end

function Fant_Simple_Controller.cl_error( self ) 
	sm.gui.displayAlertText( "Simple Controller\nPaint the Second Input Different!", 1 )
end

function Fant_Simple_Controller.client_onUpdate( self, dt )
	return true
end

function Fant_Simple_Controller.client_canInteractThroughJoint( self )
	if not self.shape.body.connectable then
		return false
	end
	return true
end

function Fant_Simple_Controller.client_onInteractThroughJoint( self, character, state, joint )
	self.cl.bearingGui = sm.gui.createSteeringBearingGui()
	self.cl.bearingGui:open()
	self.cl.bearingGui:setOnCloseCallback( "cl_onGuiClosed" )
	self.cl.currentJoint = joint
	self.cl.bearingGui:setSliderCallback("LeftAngle", "cl_onLeftAngleChanged")
	self.cl.bearingGui:setSliderData("LeftAngle", 120, self.interactable:getSteeringJointLeftAngleLimit( joint ) - 1 )
	self.cl.bearingGui:setSliderCallback("RightAngle", "cl_onRightAngleChanged")
	self.cl.bearingGui:setSliderData("RightAngle", 120, self.interactable:getSteeringJointRightAngleLimit( joint ) - 1 )
	local SpeedPerStep = 1 / math.rad( 27 ) / 3
	self.cl.bearingGui:setSliderCallback("LeftSpeed", "cl_onLeftSpeedChanged")
	self.cl.bearingGui:setSliderData("LeftSpeed", 10, ( self.interactable:getSteeringJointLeftAngleSpeed( joint ) / SpeedPerStep ) - 1)
	self.cl.bearingGui:setSliderCallback("RightSpeed", "cl_onRightSpeedChanged")
	self.cl.bearingGui:setSliderData("RightSpeed", 10, ( self.interactable:getSteeringJointRightAngleSpeed( joint ) / SpeedPerStep ) - 1)
	if self.interactable:getSteeringJointUnlocked( joint ) then
		self.cl.bearingGui:setButtonState( "Off", true )
	else
		self.cl.bearingGui:setButtonState( "On", true )
	end
	self.cl.bearingGui:setButtonCallback( "On", "cl_onLockButtonClicked" )
	self.cl.bearingGui:setButtonCallback( "Off", "cl_onLockButtonClicked" )
end
