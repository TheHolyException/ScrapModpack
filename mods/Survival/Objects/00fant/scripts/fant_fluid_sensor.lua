Fant_Fluid_Sensor = class()
Fant_Fluid_Sensor.maxChildCount = 256
Fant_Fluid_Sensor.connectionOutput = sm.interactable.connectionType.logic

function Fant_Fluid_Sensor.server_onCreate( self )	
	if not self.areaTrigger then
		self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), sm.vec3.new( 0.1, 0.1, 0.1 ), sm.vec3.new(0.0, 0, 0.0), sm.quat.identity(), sm.areaTrigger.filter.all )			
	end
	self.FluidTimer = 0
	self.inFluid = false
	self.state = false
	self.laststate = false
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { sv_UVIndex = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.sv_UVIndex = self.sv.storage.sv_UVIndex
	self.network:sendToClients( "cl_setUVIndex", self.sv_UVIndex )
end

function Fant_Fluid_Sensor.client_onCreate( self )	
	self.cl_UVIndex = self.cl_UVIndex or 0
end

function Fant_Fluid_Sensor.server_onFixedUpdate( self, dt )
	if not self.areaTrigger then
		return
	end
	if self.FluidTimer > 0 then
		self.FluidTimer = self.FluidTimer - dt
		return
	end
	self.FluidTimer = 0.1
	self.state = false
	for _, result in ipairs(  self.areaTrigger:getContents() ) do
		if sm.exists( result ) then
			if type( result ) == "AreaTrigger" then
				local userData = result:getUserData()
				if userData then
					if userData.water == true and self.sv_UVIndex == 0 then
						self.state = true
						break
					end
					if userData.chemical == true and self.sv_UVIndex == 1 then
						self.state = true
						break
					end
					if userData.oil == true and self.sv_UVIndex == 2 then
						self.state = true
						break
					end
				end
			end
		end
	end
	if self.state ~= self.laststate then
		self.laststate = self.state
		sm.interactable.setActive( self.interactable, self.state )
		if self.state then
			self.network:sendToClients( "cl_display", 4 )
		else
			self.network:sendToClients( "cl_display", 0 )
		end
	end
end

function Fant_Fluid_Sensor.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	local modeName = "none"
	if self.cl_UVIndex == 0 then
		modeName = "Water"
	end
	if self.cl_UVIndex == 1 then
		modeName = "Chemical"
	end
	if self.cl_UVIndex == 2 then
		modeName = "Oil"
	end
	sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. modeName )
	return true
end

function Fant_Fluid_Sensor.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_n_toogle" )		
	end
end

function Fant_Fluid_Sensor.sv_n_toogle( self )
	self.sv_UVIndex = self.sv_UVIndex + 1	
	if self.sv_UVIndex > 2 then
		self.sv_UVIndex = 0
	end
	self.sv.storage = { sv_UVIndex = self.sv_UVIndex } 
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_setUVIndex", self.sv_UVIndex )
end

function Fant_Fluid_Sensor.cl_setUVIndex( self, UVIndex )
	self.cl_UVIndex = UVIndex
	self:cl_display( 0 )
end

function Fant_Fluid_Sensor.cl_display( self, Offset_UVIndex )
	self.interactable:setUvFrameIndex( self.cl_UVIndex + Offset_UVIndex )
end
