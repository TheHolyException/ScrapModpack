Fant_Projector = class()
Fant_Projector.SliderSteps = 200

function Fant_Projector.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = {} 
		self.sv.storage.sv_sliderData = {}
		self.sv.storage.sv_sliderData.slider1 = self.SliderSteps / 2
		self.sv.storage.sv_sliderData.slider2 = self.SliderSteps / 2
		self.sv.storage.sv_sliderData.slider3 = self.SliderSteps / 2
		self.sv.storage.sv_sliderData.slider4 = self.SliderSteps / 2
		self.storage:save( self.sv.storage )
	end
	self.network:sendToClients( "cl_set_sliderData", self.sv.storage.sv_sliderData )
	self.network:sendToClients( "cl_update_holograms", self.sv.storage.sv_creationData )
end

function Fant_Projector.client_onCreate( self )
	self.sliderValue1 = 0
	self.sliderValue2 = 0
	self.sliderValue3 = 0
	self.sliderValue4 = 0	
	self.network:sendToServer( "sv_get_sliderData" )

	self.network:sendToServer( "sv_get_creation" )		
end

function Fant_Projector.sv_get_sliderData( self )
	self.network:sendToClients( "cl_set_sliderData", self.sv.storage.sv_sliderData )
end

function Fant_Projector.sv_get_creation( self )
	self.network:sendToClients( "cl_update_holograms", self.sv.storage.sv_creationData )	
end

function Fant_Projector.cl_set_sliderData( self, sliderData )
	self.sliderValue1 = sliderData.slider1
	self.sliderValue2 = sliderData.slider2
	self.sliderValue3 = sliderData.slider3
	self.sliderValue4 = sliderData.slider4
	self:cl_refresh_holograms()
end

function Fant_Projector.sv_set_sliderData( self, sliderData )
	self.sv.storage.sv_sliderData = sliderData
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_set_sliderData", self.sv.storage.sv_sliderData )
end

function Fant_Projector.server_onFixedUpdate( self, dt )
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
	
	end
	local interactable = self.shape:getInteractable()
	if interactable ~= nil then
		local data = interactable:getPublicData()
		if data ~= nil and data ~= {} then
			local hasData = false
			for i, k in pairs( data ) do
				if k ~= nil then
					hasData = true
					break
				end
			end
			if hasData then
				if data.projectortarget ~= nil then
					self:sv_get_creationData( data.projectortarget )
				end
				interactable:setPublicData( {} )
			end
		end
	end
end
	
-- function Fant_Projector.client_onUpdate( self, dt )

-- end

function Fant_Projector.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Settings" )
	-- local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	-- sm.gui.setInteractionText( "", keyBindingText, "U" )
	return true
end

-- function Fant_Projector.client_onTinker( self, character, state )
	-- if state then

	-- end
-- end

function Fant_Projector.client_onInteract( self, character, state )
	if state == true then
		if self.gui ~= nil then
			self.gui:destroy()
			self.gui = nil
		end
		if self.gui == nil then
			self.gui = sm.gui.createSteeringBearingGui()
		end
		self.gui:setText( "Name", "CREATION PROJECTOR" )
		self.gui:setText( "SubTitle", "Settings" )

		self.gui:setSliderData( "LeftAngle",self.SliderSteps+1, self.sliderValue1 )
		self.gui:setSliderCallback( "LeftAngle", "cl_onSliderChange" )

		self.gui:setSliderData( "RightAngle",self.SliderSteps+1, self.sliderValue2 )
		self.gui:setSliderCallback( "RightAngle", "cl_onSliderChange2" )

		self.gui:setSliderData( "LeftSpeed",self.SliderSteps+1, self.sliderValue3 )
		self.gui:setSliderCallback( "LeftSpeed", "cl_onSliderChange3" )

		
		self.gui:setSliderData( "RightSpeed",self.SliderSteps+1, self.sliderValue4 )
		self.gui:setSliderCallback( "RightSpeed", "cl_onSliderChange4" )
		
		self:cl_guiRefresh()
		
		self.gui:setVisible( "LeftAngleText", false )
		self.gui:setVisible( "RightAngleText", false )
		self.gui:setVisible( "On", false )
		self.gui:setVisible( "Off", false )
		--self.gui:setVisible( "Bearingtext", false )
		--self.gui:setImage( "IconPic", "$GAME_DATA/Gui/Layouts/suckomatic.png" )
		self.gui:setVisible( "IconPic", false )
		self.gui:setVisible( "LeftRotation", false )
		self.gui:setVisible( "RightRotation", false )
		self.gui:setVisible( "Bearingtext", false )

		self.gui:setIconImage( "Icon", obj_interactive_fant_projector )
		self.gui:setVisible( "FuelContainer", false )
		self.gui:open()
	end
end

function Fant_Projector.cl_onSliderChange( self, sliderName, sliderPos )
	self.sliderValue1 = sliderPos
	self:cl_guiRefresh()
	self.network:sendToServer( "sv_set_sliderData", { slider1 = self.sliderValue1, slider2 = self.sliderValue2, slider3 = self.sliderValue3, slider4 = self.sliderValue4 } )	
end

function Fant_Projector.cl_onSliderChange2( self, sliderName, sliderPos )
	self.sliderValue2 = sliderPos
	self:cl_guiRefresh()
	self.network:sendToServer( "sv_set_sliderData", { slider1 = self.sliderValue1, slider2 = self.sliderValue2, slider3 = self.sliderValue3, slider4 = self.sliderValue4 } )	
end

function Fant_Projector.cl_onSliderChange3( self, sliderName, sliderPos )
	self.sliderValue3 = sliderPos
	self:cl_guiRefresh()
	self.network:sendToServer( "sv_set_sliderData", { slider1 = self.sliderValue1, slider2 = self.sliderValue2, slider3 = self.sliderValue3, slider4 = self.sliderValue4 } )	
end

function Fant_Projector.cl_onSliderChange4( self, sliderName, sliderPos )
	self.sliderValue4 = sliderPos
	self:cl_guiRefresh()
	self.network:sendToServer( "sv_set_sliderData", { slider1 = self.sliderValue1, slider2 = self.sliderValue2, slider3 = self.sliderValue3, slider4 = self.sliderValue4 } )	
end

function Fant_Projector.cl_guiRefresh( self )
	if self.gui ~= nil then
		self.gui:setText( "TurnTextLeft", "X: " .. tostring( self.sliderValue1 - ( self.SliderSteps / 2 ) ) )		
		self.gui:setText( "TurnTextRight", "Y: " .. tostring( self.sliderValue2 ) - ( self.SliderSteps / 2 ) )
		self.gui:setText( "TurnSpeedTextLeft", "Z: " .. tostring( self.sliderValue3 ) - ( self.SliderSteps / 2 ) )
		self.gui:setText( "TurnSpeedTextRight", "Scale: " .. tostring( self.sliderValue4 ) )
	end
end

function Fant_Projector.sv_get_creationData( self, projectorShapeTarget )
	local body = projectorShapeTarget:getBody()
	if body == nil then
		return
	end
	local shapes = {}
	local joints = {}

	for i, subBody in pairs( body:getCreationBodies() ) do
		for j, shape in pairs( subBody:getShapes() ) do
			table.insert( shapes, shape )
			if shape:getInteractable() then
				for k, joint in pairs( shape:getInteractable():getJoints() ) do
					table.insert( joints, joint )
				end
			end
		end
	end
	
	local sendCount = 0
	self.sv.storage.sv_creationData = {}
	self.sv.storage.sv_creationData.scale = 0.2
	self.sv.storage.sv_creationData.shapes = {} 
	
	if shapes ~= nil then
		for index, shape in pairs( shapes ) do
			local newData = {}
			newData.uuid = shape:getShapeUuid()
			newData.position = shape:getWorldPosition() - projectorShapeTarget:getWorldPosition()
			newData.rotation = shape:getWorldRotation()
			newData.color = shape:getColor()
			if sm.item.isBlock( newData.uuid ) then
				newData.shapeSize = shape:getBoundingBox() 
			end
			table.insert( self.sv.storage.sv_creationData.shapes, newData )
			newData = nil
			sendCount = sendCount + 1
		end
	end
	
	if joints ~= nil then
		for index, joint in pairs( joints ) do
			local newData = {}
			
			if joint:getType() == "bearing" then
				newData.uuid = sm.uuid.new( "4a1b886b-913e-4aad-b5b6-6e41b0db23a6" )
			end

			local relPos = ( joint:getShapeA():getWorldPosition() + joint:getShapeB():getWorldPosition() ) / 2
			local dir = ( joint:getShapeA():getWorldPosition() - joint:getShapeB():getWorldPosition() ):normalize()
			newData.position = relPos - projectorShapeTarget:getWorldPosition() + ( dir * 0.125 )
			newData.rotation = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ) , dir )
			newData.color = joint:getColor()
			table.insert( self.sv.storage.sv_creationData.shapes, newData )
			newData = nil
			sendCount = sendCount + 1
		end
	end
	
	--print( "sendCount: ", sendCount )
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_update_holograms", self.sv.storage.sv_creationData )	
end


function Fant_Projector.cl_update_holograms( self, data )
	self:cl_clearHolos()
	
	self.cl_creationData = data
	if self.cl_creationData ~= nil and self.cl_creationData ~= {} then
		self.holograms = {}
		local offset = sm.vec3.new( self.sliderValue1 - ( self.SliderSteps / 2 ), ( self.sliderValue2 - ( self.SliderSteps / 2 ) ), ( self.sliderValue3 - ( self.SliderSteps / 2 ) ) ) * 0.25
		for i, shapeData in pairs( self.cl_creationData.shapes ) do	
			if shapeData ~= nil then
				local effect = sm.effect.createEffect( "ShapeRenderable", self.interactable )				
				effect:setParameter( "uuid", shapeData.uuid )
				effect:setParameter( "color", shapeData.color )
				effect:setOffsetPosition( ( shapeData.position * ( self.cl_creationData.scale * ( self.sliderValue4 / 10 ) ) ) + offset )	
				effect:setOffsetRotation( shapeData.rotation )
				local scale = sm.vec3.new( 0.25, 0.25, 0.25 )
				if shapeData.shapeSize ~= nil then
					scale = shapeData.shapeSize * ( self.cl_creationData.scale * ( self.sliderValue4 / 10 ) )
				else
					scale = sm.vec3.new( 0.25, 0.25, 0.25 ) * ( self.cl_creationData.scale * ( self.sliderValue4 / 10 ) )
				end
				effect:setScale( scale )
				effect:start()
				
				local newHoloData = {}
				newHoloData.shapeData = shapeData
				newHoloData.effect = effect				
				table.insert( self.holograms, newHoloData )
			end
		end
	end
end


function Fant_Projector.cl_refresh_holograms( self )
	if self.holograms ~= nil and self.holograms ~= {} then
		local offset = sm.vec3.new( self.sliderValue1 - ( self.SliderSteps / 2 ), ( self.sliderValue2 - ( self.SliderSteps / 2 ) ), ( self.sliderValue3 - ( self.SliderSteps / 2 ) ) ) * 0.25
		for i, HoloData in pairs( self.holograms ) do	
			if HoloData.shapeData ~= nil then				
				HoloData.effect:setParameter( "uuid", HoloData.shapeData.uuid )
				HoloData.effect:setParameter( "color", HoloData.shapeData.color )
				HoloData.effect:setOffsetPosition( ( HoloData.shapeData.position * ( self.cl_creationData.scale * ( self.sliderValue4 / 10 ) ) ) + offset )	
				HoloData.effect:setOffsetRotation( HoloData.shapeData.rotation )
				local scale = sm.vec3.new( 0.25, 0.25, 0.25 )
				if HoloData.shapeData.shapeSize ~= nil then
					scale = HoloData.shapeData.shapeSize * ( self.cl_creationData.scale * ( self.sliderValue4 / 10 ) )
				else
					scale = sm.vec3.new( 0.25, 0.25, 0.25 ) * ( self.cl_creationData.scale * ( self.sliderValue4 / 10 ) )
				end
				HoloData.effect:setScale( scale )
			end
		end
	else
		self:cl_clearHolos()
	end
end


function Fant_Projector.client_onDestroy( self )
	self:cl_clearHolos()
end


function Fant_Projector.client_onRefresh( self )
	self:cl_refresh_holograms()
end

function Fant_Projector.cl_clearHolos( self )
	if self.holograms ~= nil then
		for i, hologram in pairs( self.holograms ) do
			if hologram ~= nil then
				if hologram.effect ~= nil then
					hologram.effect:stop()
					hologram.effect:destroy()
					hologram.effect = nil
				end
			end
		end
		self.holograms = nil
	end
end