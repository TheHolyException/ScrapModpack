dofile "$SURVIVAL_DATA/Scripts/game/survival_units.lua"

Fant_Camera = class()
Fant_Camera.maxParentCount = 3
Fant_Camera.connectionInput = sm.interactable.connectionType.logic
Fant_Camera.Zoom_Speed = 40
Fant_Camera.SliderSteps = 100

function Fant_Camera.server_onCreate( self )
	self.lastState = false
	self.lastZoom = false
	self.saved = self.storage:load()
	self.owner = nil
	if self.saved == nil then
		self.saved = { sliderZoom = 0, playername = "" }
	end
	self.sliderZoom = self.saved.sliderZoom or 0
	self.playername = self.saved.playername or ""

	local players = sm.player.getAllPlayers()
	for index, player in pairs( players ) do
		if player.name == self.playername then
			self.owner = player.character
			break
		end
	end	
	self.network:sendToClients( "cl_setOwner", { player = self.owner, playername = self.playername } )
	self.network:sendToClients( "cl_setSliderZoom", self.sliderZoom )	
end

function Fant_Camera.getParentInputs( self )
	local Active = false
	local Zoom = false
	for i, parent in pairs( self.interactable:getParents() ) do
		if parent:hasOutputType( sm.interactable.connectionType.logic ) then
			if tostring( sm.shape.getColor( sm.interactable.getShape( parent ) ) ) == "df7f01ff" then
				if parent.active then
					Active = true
				end
			else
				if parent.active then
					Zoom = true
				end
			end
			
		end
	end
	return Active, Zoom
end

function Fant_Camera.server_onFixedUpdate( self )
	local active, zoom = self:getParentInputs()
	if self.owner ~= nil then
		if self.owner:isCrouching() then
			--print( "Owner isCrouching: " .. tostring(self.owner) )
			active = false
		end	
	else
		active = false
	end
	if self.lastState ~= active or self.lastZoom ~= zoom then
		self.lastState = active
		self.lastZoom = zoom
		self.network:sendToClients( "setCameraMode", { player = self.owner, state = active, zoom = zoom } )
	end
end

function Fant_Camera.client_onCreate( self )
	self.cl_Player = nil
	self.cl_active = false
	self.cl_zoom = false
	self.zoomValue = 0
	self.cl_sliderZoom = 0
	
	self.owner = self.owner or nil
	self.playername = self.playername or ""
end

function Fant_Camera.setCameraMode( self, data )
	if data.player == sm.localPlayer.getPlayer().character then
		self.cl_active = data.state
		self.cl_Player = data.player
		self.cl_zoom = data.zoom
		if data.state then
			sm.camera.setCameraState( sm.camera.state.cutsceneTP )
			self:SetCamera( 0 )
		else
			self.zoomValue = 0
			sm.camera.setCameraState( sm.camera.state.default )
		end
	end
end

function Fant_Camera.client_onUpdate( self, dt )
	if self.cl_active and self.cl_Player ~= nil then
		self:SetCamera( dt )			
	end
end

function Fant_Camera.SetCamera( self, dt )
	if self.cl_zoom == true and self.zoomValue < self.cl_sliderZoom then
		self.zoomValue = self.zoomValue + ( dt * self.Zoom_Speed )
		if self.zoomValue >= self.cl_sliderZoom then
			self.zoomValue = self.cl_sliderZoom
		end
	elseif self.cl_zoom == true and self.zoomValue > self.cl_sliderZoom then
		self.zoomValue = self.zoomValue - ( dt * self.Zoom_Speed )
		if self.zoomValue <= self.cl_sliderZoom then
			self.zoomValue = self.cl_sliderZoom
		end
	elseif self.cl_zoom == false and self.zoomValue > 0 then
		self.zoomValue = self.zoomValue - ( dt * self.Zoom_Speed )
		if self.zoomValue <= 0 then
			self.zoomValue = 0
		end
	end
	
	local vel = sm.vec3.new( 0, 0, 0 )
	local body = sm.shape.getBody( self.shape )
	if body ~= nil then
		vel = sm.body.getVelocity( body )
	end
	local dir = sm.shape.getRight( self.shape )
	local pos = self.shape.worldPosition + ( dir * 0.4 ) + ( dir * self.zoomValue * 3 ) 
	
	local force = pos - sm.camera.getPosition() + ( vel * 0.1 )
	local newCamPos = sm.camera.getPosition() + ( force * dt * 10 )
	
	sm.camera.setPosition( newCamPos )
	sm.camera.setDirection( sm.vec3.lerp( sm.camera.getDirection(), dir, dt * 20 ) )
end

function Fant_Camera.sv_setOwner( self, data )
	self.owner = data.player
	if data.playername ~= "" then
		self.playername = data.playername
	end
	self.saved = { sliderZoom = self.sliderZoom, playername = self.playername }
	self.storage:save( self.saved )
end

function Fant_Camera.cl_setOwner( self, data )
	self.owner = data.player
	if data.playername ~= "" then
		self.playername = data.playername
	end
end

function Fant_Camera.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Camera Settings" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Set Owner" .. " - " .. self.playername )
	return true
end

function Fant_Camera.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Camera" )
		self.gui:setText( "Interaction", "Zoom" )	
		self.gui:setSliderData( "Setting",self.SliderSteps+1, self.cl_sliderZoom )
		self.gui:setText( "SubTitle", "Max Zoom: " .. tostring( self.cl_sliderZoom ) )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setIconImage( "Icon", obj_interactive_fant_camera )
		self.gui:setVisible( "FuelContainer", false )
		self.gui:open()
	end
end

function Fant_Camera.client_onTinker( self, character, state )
	if state then
		if character == sm.localPlayer.getPlayer().character then
			self.network:sendToServer( "sv_setOwner", { player = character, playername = sm.localPlayer.getPlayer().name } )
			self.network:sendToServer( "server_PrintText", { character = character, text = "Owner Set!\nHold Crouch to Deactivate it temporarily!", duration = 5 } )
		end
	end
end

function Fant_Camera.server_PrintText( self, data )
	self.network:sendToClients( "client_PrintText", data )
end

function Fant_Camera.client_PrintText( self, data ) 
	if data.character ~= nil then
		if data.character:getPlayer() == sm.localPlayer.getPlayer() then
			sm.gui.displayAlertText( data.text, data.duration )
		end
	end
end

function Fant_Camera.cl_onSliderChange( self, sliderName, sliderPos )
	self.cl_sliderZoom = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "SubTitle", "Max Zoom: " .. tostring( self.cl_sliderZoom ) )
	end
	self.network:sendToServer( "setSliderZoom", self.cl_sliderZoom )
end

function Fant_Camera.setSliderZoom( self, sliderZoom )
	self.sliderZoom = sliderZoom
	self.saved = { sliderZoom = self.sliderZoom, playername = self.playername }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_setSliderZoom", self.sliderZoom )	
end

function Fant_Camera.cl_setSliderZoom( self, sliderZoom )
	self.cl_sliderZoom = sliderZoom
	if self.gui ~= nil then
		self.gui:setText( "SubTitle", "Max Zoom: " .. tostring( self.cl_sliderZoom ) )
		self.gui:setSliderData( "Setting",self.SliderSteps+1, self.cl_sliderZoom )
	end
end



