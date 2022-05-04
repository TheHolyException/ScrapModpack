Fant_Ballwheel = class()

function Fant_Ballwheel.server_onCreate( self )	
	self.updownchange = false
	self.lastupdownchange = false
	self.movedirection = sm.vec3.new( 0, 0, 0 ) 
	self.forceMul = 1
	
	if self.shape:getShapeUuid() == obj_interactive_fant_ball_wheel_3x3x3 then
		self.forceMul = 10
	end
	if self.shape:getShapeUuid() == obj_interactive_fant_ball_wheel_5x5x5 then
		self.forceMul = 50
	end
	if self.shape:getShapeUuid() == obj_interactive_fant_ball_wheel_7x7x7 then
		self.forceMul = 150
	end
	
	if self.shape:getShapeUuid() == obj_interactive_fant_waterwheel_2x5 then
		self.forceMul = 20
	end
	if self.shape:getShapeUuid() == obj_interactive_fant_waterwheel_3x5 then
		self.forceMul = 60
	end
	if self.shape:getShapeUuid() == obj_interactive_fant_waterwheel_3x7 then
		self.forceMul = 120
	end
	if self.shape:getShapeUuid() == obj_interactive_fant_waterwheel_4x7 then
		self.forceMul = 240
	end
	if self.shape:getShapeUuid() == obj_interactive_fant_waterwheel_4x9 then
		self.forceMul = 360
	end
	if self.shape:getShapeUuid() == obj_interactive_fant_waterwheel_5x9 then
		self.forceMul = 450
	end

	local waterTriggerSize = sm.vec3.new( 2, 2, 2 )
	if not self.areaTrigger then
		self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), waterTriggerSize, sm.vec3.new(0.0, 0, 0.0), sm.quat.identity(), sm.areaTrigger.filter.all )			
	end
	self.waterTimer = 0
	self.inWater = false
end

function Fant_Ballwheel.server_onFixedUpdate( self, dt )
	local body = sm.shape.getBody( self.shape )
	if body == nil then
		return
	end
	if body:isStatic() then
		return
	end
	self:IsInWater( dt )
	if self.inWater then
		local mass = 1 + ( body:getMass() / 1000 )
		local direction = self:getDirection()	
		if sm.vec3.length( direction ) > 0.01 then
			local Force = direction * ( math.abs( sm.body.getAngularVelocity( body ):dot( sm.shape.getAt( self.shape ) ) ) / 10 ) * self.forceMul * 0.5 * mass
			if sm.vec3.length( Force ) > 0.01 then
				sm.physics.applyImpulse(body, Force, true, sm.vec3.new( 0, 0, 0 ) )
			end
		end
	end
end


function Fant_Ballwheel.getDirection( self )
	local position = self.shape:getWorldPosition()
	local offsetposition = position + self.shape:getUp()	
	if offsetposition.z > position.z then
		self.updownchange = true
	else
		self.updownchange = false
	end
	if self.lastupdownchange ~= self.updownchange then
		self.lastupdownchange = self.updownchange
		offsetposition.z = position.z
		if sm.vec3.length( offsetposition ) > 0.01 then 
			if self.updownchange then
				self.movedirection = -sm.vec3.normalize( offsetposition - position ) 
			else
				if offsetposition - position ~= sm.vec3.new(0,0,0) then
					self.movedirection = sm.vec3.normalize( offsetposition - position ) 
				end
			end
		end
	end
	return self.movedirection
end

function Fant_Ballwheel.IsInWater( self, dt )
	if not self.areaTrigger then
		return
	end
	if self.waterTimer > 0 then
		self.waterTimer = self.waterTimer - dt
		return
	end
	self.waterTimer = 0.25
	for _, result in ipairs(  self.areaTrigger:getContents() ) do
		if sm.exists( result ) then
			if type( result ) == "AreaTrigger" then
				local userData = result:getUserData()
				if userData then
					if userData.water == true then
						self.inWater = true
						return
					end
					if userData.chemical == true then
						self.inWater = true
						return
					end
					if userData.oil == true then
						self.inWater = true
						return
					end
				end
			end
		end
	end
	self.inWater = false
	return
end
