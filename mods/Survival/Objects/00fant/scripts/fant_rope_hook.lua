Fant_Rope_Hook = class( nil )
Fant_Rope_Hook.maxParentCount = 2
Fant_Rope_Hook.connectionInput = sm.interactable.connectionType.logic
Fant_Rope_Hook.maxChildCount = 255
Fant_Rope_Hook.connectionOutput = sm.interactable.connectionType.logic

function Fant_Rope_Hook.server_onCreate( self )
	self.data = self.storage:load()

	if self.data == nil then
		self.data = { target = nil, distance = 0 }
	end

	self.storage:save( self.data )
	self.loaded = true
	
	refreshTimer = 10
end

function Fant_Rope_Hook.server_onUnload( self )
	if self.loaded then
		self.loaded = false
	end
end

function Fant_Rope_Hook.server_onDestroy( self )
	if self.loaded then
				
	end	
end

function Fant_Rope_Hook.server_onFixedUpdate( self, dt )
	local data = self.interactable:getPublicData()
	if data then
		if data.hook then
			if self.data.target ~= data.target then
				self.data.target = data.target
				if self.data.target then
					--self.data.target.interactable:setPublicData( { hook = self.data.target, target = nil } )
					self.data.distance = sm.vec3.length( self.shape.worldPosition - self.data.target.worldPosition )
				else
					self.data.distance = 0
				end
				self.storage:save( self.data )
				self.network:sendToClients( "cl_setData", self.data )
				self.interactable:setPublicData( {} )
			end
		end
	end
	refreshTimer = refreshTimer - dt
	if self.data ~= nil and refreshTimer <= 0 then
		self.network:sendToClients( "cl_setData", self.data )
		refreshTimer = 10 +  math.random( 0, 5 )
		--print( "Rope Refresh" )
	end
	
	local parents = self.interactable:getParents()
	local ChangeRange = 0
	for i = 1, #parents do
		if parents[i] then
			if parents[i]:hasOutputType( sm.interactable.connectionType.logic ) then
				if tostring( parents[i].shape.color ) == "df7f01ff" then  --default
					if parents[i].active then
						ChangeRange = 1
					end
				else
					if parents[i].active then
						ChangeRange = -1
					end
				end
			end		
		end
	end	
	if ChangeRange ~= 0 then
		if self.data.distance == nil then
			if self.data.target then
				self.data.distance = sm.vec3.length( self.shape.worldPosition - self.data.target.worldPosition )
			else
				self.data.distance = 0
			end
		end
		self.data.distance = self.data.distance + ( ChangeRange * dt * 0.5 )
		if self.data.distance < 0 then
			self.data.distance = 0
		end
		self.storage:save( self.data )
	end
	
	
	if self.data.target and sm.exists( self.data.target ) then
		local pos_a = self.shape.worldPosition
		local pos_b = self.data.target.worldPosition
		
		local distance = sm.vec3.length( pos_a - pos_b ) - self.data.distance
		local distance_clamped = distance
		if distance_clamped < 0 then
			distance_clamped = 0
		end
		if ( pos_a - pos_b ) == sm.vec3.new( 0, 0, 0 ) then
			return
		end
		local direction = -( pos_a - pos_b ):normalize() * 2
		local force = ( direction * ( distance_clamped * distance_clamped ) ) 
		force = force - ( force / 15 ) 
		
		local mass_a = self.shape:getBody():getMass() 
		
		if mass_a < 1 then
			mass_a = 1
		end
		if self.shape:getBody():isStatic() then
			mass_a = 10000
		end
		
		local mass_b = self.data.target:getBody():getMass() 
		
		if mass_b < 1 then
			mass_b = 1
		end
		if self.data.target:getBody():isStatic() then
			mass_b = 10000
		end
		
		local mass_b_max = mass_b
		if mass_a < mass_b then
			mass_b_max = mass_a * 1.5
		end
		
		local mass_a_max = mass_a
		if mass_b < mass_a then
			mass_a_max = mass_b * 1.5
		end
		
		local velClampA = self.shape:getBody():getVelocity():length() / 100
		if velClampA > 1 then
			velClampA = 1
		end
		
		local velClampB = self.data.target:getBody():getVelocity():length() / 100
		if velClampB > 1 then
			velClampB = 1
		end

		
		local force_a =  force * mass_b_max / 5
		local velocity_a = -self.shape:getBody():getVelocity() 		 * mass_a / ( 35 / ( velClampA + 1 ) )

		local force_b = -force * mass_a_max / 5
		local velocity_b = -self.data.target:getBody():getVelocity() * mass_b / ( 35 / ( velClampB + 1 ) )

		sm.physics.applyImpulse( self.shape,       force_a + velocity_a, true )
		sm.physics.applyImpulse( self.data.target, force_b + velocity_b, true )
		
		if self.shape:getBody() then
			local angvel = -sm.body.getAngularVelocity( self.shape:getBody() ) / 250
			if angvel:length() < 0.0001 then
				angvel = sm.vec3.new( 0, 0, 0 )
			end
			if angvel:length() > 0.1 then
				angvel = angvel:normalize() * 0.1
			end
			sm.physics.applyTorque( self.shape:getBody(), angvel * mass_b_max, true )
		end
		
		if self.data.target:getBody() then
			local angvel = -sm.body.getAngularVelocity( self.data.target:getBody() ) / 250
			if angvel:length() < 0.0001 then
				angvel = sm.vec3.new( 0, 0, 0 )
			end
			if angvel:length() > 0.1 then
				angvel = angvel:normalize() * 0.1
			end
			sm.physics.applyTorque( self.data.target:getBody(), angvel * mass_a_max, true )
		end
		
	end
	if self.shape:getBody():getVelocity():length() > 1000 then
		sm.shape.destroyShape( self.shape )
		--print( "Fail Safe Delete" )
	end
end

function Fant_Rope_Hook.client_onCreate(self)
	self.network:sendToServer( "sv_getData" )
	self.effect = sm.effect.createEffect( "ShapeRenderable" )				
	self.effect:setParameter( "uuid", sm.uuid.new( "7ff274b1-eb23-4480-9921-371f4e03e5b0") )
end

function Fant_Rope_Hook.sv_getData( self )
	self.network:sendToClients( "cl_setData", self.data )
end

function Fant_Rope_Hook.cl_setData( self, data )
	self.cl_data = data
	if self.cl_data.target and sm.exists( self.cl_data.target ) then
		self.effect:start()
	else
		self.effect:stop()
	end
end

function Fant_Rope_Hook.client_onDestroy(self)
	self.effect:stop()
	self.effect:destroy()
end
 
function Fant_Rope_Hook.client_onUpdate(self, dt)
	if self.effect and self.cl_data ~= nil and self.cl_data.target and sm.exists( self.cl_data.target ) then
		if not self.effect:isPlaying() then
			self.effect:start()
		end
		if ( self.shape.worldPosition - self.cl_data.target.worldPosition ) == sm.vec3.new( 0, 0, 0 ) then
			return
		end
		self.effect:setScale( sm.vec3.new( 0.08, 0.08, sm.vec3.length( self.shape.worldPosition - self.cl_data.target.worldPosition ) - 0.1 ) )
		self.effect:setPosition( ( self.shape.worldPosition + self.cl_data.target.worldPosition ) / 2 )
		self.effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.normalize( self.shape.worldPosition - self.cl_data.target.worldPosition ) ) )
	else
		if self.effect:isPlaying() then
			self.effect:stop()
		end
	end
end
