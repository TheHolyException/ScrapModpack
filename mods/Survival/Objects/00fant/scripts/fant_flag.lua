dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_sail.lua"

Fant_Flag = class()
Fant_Flag.directionSpeed = 10
Fant_Flag.WaveSpeed = 0.5
Fant_Flag.MaxIndex = 80

function Fant_Flag.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { flag = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.sv_flag = self.sv.storage.flag or 0
	self.network:sendToClients( "cl_flag", { flag = self.sv_flag }  )
end

function Fant_Flag.cl_flag( self, data )
	self:UpdateFlag( data.flag )
end

function Fant_Flag.UpdateFlag( self, index )
	self.flag = index
	self.interactable:setUvFrameIndex( index )
end

function Fant_Flag.SaveFlag( self, flag )
	self.sv_flag = flag
	self.sv.storage = { flag = self.sv_flag } 
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_flag", { flag = self.sv_flag }  )
end

function Fant_Flag.client_onCreate( self )
	self.wave = 0
	self.direction = 0
	self.flag = 0
	self.interactable:setAnimEnabled( "direction", true )	
	self.interactable:setAnimEnabled( "wave", true )	
	self.network:sendToServer( "getData" )
end

function Fant_Flag.getData( self )
	self.network:sendToClients( "cl_flag", { flag = self.sv_flag }  )
end

function Fant_Flag.client_onInteract(self, character, state)
	if state then
		if character:isCrouching() then
			self.flag = self.flag - 1
			if self.flag < 0 then
				self.flag = self.MaxIndex - 1
			end
		else
			self.flag = self.flag + 1
			if self.flag >= self.MaxIndex then
				self.flag = 0
			end
		end
		
		self.network:sendToServer( "SaveFlag", self.flag )
		self:UpdateFlag( self.flag )
	end
end

function Fant_Flag.client_onUpdate( self, dt )
	self.wave = self.wave + ( dt * self.WaveSpeed )
	if self.wave > 1 then
		self.wave = 0
	end
	self.interactable:setAnimProgress( "wave", self.wave )
	local body = sm.shape.getBody( self.shape )
	if body == nil then
		return
	end
	local velocity = WIND_OVERTIME_CL--sm.body.getVelocity( body )
	if sm.vec3.length( velocity ) > 0.1 then
		self.direction = ( -self:getAngle( sm.vec3.normalize( velocity ) ) ) + ( self:getAngle( sm.shape.getUp( self.shape ) ) )
		while self.direction > 360 do
			self.direction = self.direction - 360
		end
		self.interactable:setAnimProgress( "direction", self.direction / 360 )
	else
		--self.direction = self.direction + ( dt * self.directionSpeed )
		--if self.direction > 360 then
			--self.direction = 0
		--end
	end
end

function Fant_Flag.getAngle( self, direction )
	local angle = math.atan2( direction.y, direction.x )
    local degrees = 180 * angle / math.pi
    return ( 360 + math.floor( degrees ) ) % 360
end











