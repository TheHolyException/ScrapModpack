dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"
dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_customizable_engine.lua")


Fant_Display = class()

Fant_Display.modes = {}
Fant_Display.modes[#Fant_Display.modes + 1] = "Kmh"
Fant_Display.modes[#Fant_Display.modes + 1] = "Height"
Fant_Display.modes[#Fant_Display.modes + 1] = "Container"
Fant_Display.modes[#Fant_Display.modes + 1] = "Gear"
Fant_Display.modes[#Fant_Display.modes + 1] = "Mass"
Fant_Display.modes[#Fant_Display.modes + 1] = "Pitch"
Fant_Display.modes[#Fant_Display.modes + 1] = "Roll"
Fant_Display.modes[#Fant_Display.modes + 1] = "Yaw"
Fant_Display.modes[#Fant_Display.modes + 1] = "PublicData"

Fant_Display.maxParentCount = 255
Fant_Display.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.ammo + sm.interactable.connectionType.water + sm.interactable.connectionType.gasoline + sm.interactable.connectionType.bearing + sm.interactable.connectionType.logic + sm.interactable.connectionType.electricity
Fant_Display.maxChildCount = 255
Fant_Display.connectionOutput = sm.interactable.connectionType.power + sm.interactable.connectionType.ammo + sm.interactable.connectionType.water + sm.interactable.connectionType.gasoline + sm.interactable.connectionType.bearing + sm.interactable.connectionType.logic + sm.interactable.connectionType.electricity

function Fant_Display.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { mode = 1 } 
		self.storage:save( self.sv.storage )
	end
	self.sv_mode = self.sv.storage.mode
	self.LastIncomingData = nil
	self.network:sendToClients( "cl_setMode", { mode = self.sv_mode } )	
end

function Fant_Display.sv_setMode( self, data )
	self.sv_mode = data.mode
	self.sv.storage = { mode = self.sv_mode } 
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_setMode", { mode = self.sv_mode } )	
end

function Fant_Display.cl_setMode( self, data )
	self.mode = data.mode
end

function Fant_Display.sv_getMode( self )
	self.network:sendToClients( "cl_setMode", { mode = self.sv_mode } )	
end

function Fant_Display.client_onCreate( self )
	self.interactable:setAnimEnabled( "number_1", true )	
	self.interactable:setAnimProgress( "number_1", 0.01 )
	self.interactable:setAnimEnabled( "number_2", true )	
	self.interactable:setAnimProgress( "number_2", 0.01 )
	self.interactable:setAnimEnabled( "number_3", true )	
	self.interactable:setAnimProgress( "number_3", 0.01 )
	self.interactable:setAnimEnabled( "number_4", true )	
	self.interactable:setAnimProgress( "number_4", 0.01 )	
	self.mode = 1
	self.network:sendToServer( "sv_getMode" )	
	self.delay = 0
	self.IncomingData = nil
end

function Fant_Display.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Current Mode" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, self.modes[ self.mode ] )
	return true
end

function Fant_Display.client_onInteract( self, character, state )
	if state then
		self.mode = self.mode + 1
		if self.mode > #self.modes then
			self.mode = 1
		end
		--print( "Mode: ".. tostring( self.mode ) )
		self.network:sendToServer( "sv_setMode", { mode = self.mode } )	
	end
end

function Fant_Display.client_onTinker( self, character, state )
	if state then
		self.mode = self.mode - 1
		if self.mode < 1 then
			self.mode = #self.modes
		end
		--print( "Mode: ".. tostring( self.mode ) )
		self.network:sendToServer( "sv_setMode", { mode = self.mode } )	
	end
end

function Fant_Display.client_onUpdate( self, dt )
	if self.delay < 0.25 then
		self.delay = self.delay + dt
		return
	end
	self.delay = 0
	
	local DisplayNumber = 0
	local shape = self:getConnectedLogicShapes()[1]
	local uuid = nil
	local container = nil
	local body = sm.shape.getBody( self.shape )
	
	if shape ~= nil then
		uuid = shape:getShapeUuid()
		container = sm.interactable.getContainer( shape.interactable, 0 )
	end
	
	if self.modes[ self.mode ] == "Kmh" then
		DisplayNumber = math.floor( sm.vec3.length( sm.body.getVelocity( body ) ) * 3.6 )
	end 
	
	if self.modes[ self.mode ] == "Height" then
		DisplayNumber = ( math.floor( self.shape.worldPosition.z * 10 ) / 10 ) * 4
	end
	
	if self.modes[ self.mode ] == "Container" then
		if container then
			if not sm.container.isEmpty( container ) then
				DisplayNumber = 0
				if not container:isEmpty() then
					for slot = 0, container:getSize() - 1 do
						local item = container:getItem( slot )											
						if item then
							DisplayNumber = DisplayNumber + item.quantity
						end
					end
				end	
			end
		end
	end
	
	if self.modes[ self.mode ] == "Gear" then
		if uuid ~= nil and shape ~= nil then
			if uuid == obj_interactive_fant_c_engine_v8 then
				DisplayNumber = g_Engine_Gears[ shape:getId() ]
			end
		end
	end
	
	if self.modes[ self.mode ] == "Mass" then
		if body ~= nil then
			DisplayNumber = sm.body.getMass( body ) - 15
		end
	end
	
	if self.modes[ self.mode ] == "Pitch" then
		DisplayNumber = self:GetAngle().y
	end
	
	if self.modes[ self.mode ] == "Roll" then
		DisplayNumber = self:GetAngle().x
	end
	
	if self.modes[ self.mode ] == "Yaw" then
		DisplayNumber = self:getAngleYaw()
	end
	if self.modes[ self.mode ] == "PublicData" then
		if self.IncomingData ~= nil then
			--print(  self.IncomingData )
			if self.IncomingData.value ~= nil then
				--print(  self.IncomingData.value )
				DisplayNumber = self.IncomingData.value
			end
		end
	end
	
	
	
	
	
	self:cl_setNumber( math.floor( math.abs( DisplayNumber ) ) )
end

-- distance with laser sensor

  
function Fant_Display.cl_setNumber( self, number ) 
	local numberstring = tostring( math.floor( number ) )
	while string.len( numberstring ) < 4 do
		numberstring = "0" .. numberstring
	end

	self.interactable:setUvFrameIndex( 0 )

	self.interactable:setAnimProgress( "number_1", ( 1 - fround( tonumber( string.sub( numberstring, 4, 4 ) ) ) ) )
	self.interactable:setAnimProgress( "number_2", ( 1 - fround( tonumber( string.sub( numberstring, 3, 3 ) ) ) ) )
	self.interactable:setAnimProgress( "number_3", ( 1 - fround( tonumber( string.sub( numberstring, 2, 2 ) ) ) ) )	
	self.interactable:setAnimProgress( "number_4", ( 1 - fround( tonumber( string.sub( numberstring, 1, 1 ) ) ) ) )
end

function fround( val )
	if val == nil then
		return 0
	end
	if type( val ) ~= "number" then
		return 0
	end
	return math.floor( ( val / 10 ) * 10 ) / 10
end

function Fant_Display.getConnectedLogicShapes( self )
	local shapes = {}
	for i, parent in pairs( self.interactable:getParents() ) do
		table.insert( shapes, parent.shape )
	end
	for i, child in pairs( self.interactable:getChildren() ) do
		table.insert( shapes, child.shape )
	end
	return shapes
end

function Fant_Display.server_onFixedUpdate( self, dt )
	local shape = self:getConnectedLogicShapes()[1]

	if shape then
		local data = sm.interactable.getPublicData( sm.shape.getInteractable( shape ) )
		local value = 0
		if data then
			value = data.value
		end
		if self.LastIncomingData ~= value then
			self.LastIncomingData = value
			self.network:sendToClients( "setData", { value = value } )	
		end
		--sm.interactable.setActive( self.interactable, false )
	end
end

function Fant_Display.setData( self, data )
	self.IncomingData = data
end

--MJM´s Help. Thanks Men! ;)
function Fant_Display.GetAngle( self )
	-- get orientation vectors for comparison
    local localX = self.shape:getRight()
    local localY = self.shape:getAt()
    local localZ = self.shape:getUp()
-- get pitch angle
    local angleY = 90 - math.deg(math.acos(sm.util.clamp(localY.z,-1,1)))
    if localZ.z < 0 then
        if localY.z < 0 then
            angleY = -180 - angleY
        else
            angleY = 180 - angleY
        end
    end
    --print("Angle Y: "..string.format("%.3f", tostring(angleY))) -- Debug
    -- get roll angle
    local angleX = 90 - math.deg(math.acos(sm.util.clamp(localX.z,-1,1)))
    if localZ.z < 0 then
        if localX.z < 0 then
            angleX = -180 - angleX
        else
            angleX = 180 - angleX
        end
    end
    --print("Angle X: "..string.format("%.3f", tostring(angleX))) -- Debug
	return sm.vec3.new( angleX, angleY, 0 )
end

function Fant_Display.getAngle( self, direction )
	local angle = math.atan2( direction.y, direction.x )
    local degrees = 180 * angle / math.pi
    return ( 360 + math.floor( degrees ) ) % 360
end

function Fant_Display.getAngleYaw( self )
	local val = ( -self:getAngle( sm.vec3.normalize( self.shape:getAt() ) ) - 180 ) + ( self:getAngle( sm.shape.getUp( self.shape ) ) )
	while val > 360 do
		val = val - 360
	end
	while val < 0 do
		val = val + 360
	end
	return val
end







