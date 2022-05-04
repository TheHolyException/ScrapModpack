VelocityMultiplayer = 0.2

function WingUpdate( data )
	local self = data.self
	local dt = data.dt
	local LiftForce = data.LiftForce * 3
	local Position = sm.shape.getWorldPosition( self.shape )
	if not self.areaTrigger then
		self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), sm.vec3.new( 0.5, 0.5, 0.5 ), sm.vec3.new(0.0, 0, 0.0), sm.quat.identity(), sm.areaTrigger.filter.all )			
	end
	for _, result in ipairs(  self.areaTrigger:getContents() ) do
		if sm.exists( result ) then
			if type( result ) == "AreaTrigger" then
				local userData = result:getUserData()
				if userData and userData.water == true then
					--return true
					LiftForce = LiftForce / 2
				end
			end
		end
	end

	local Mass = sm.shape.getMass( self.shape ) 
	local LocalVelocity = self.shape:transformPoint( Position + ( sm.shape.getVelocity( self.shape ) ) )
	local LocalVerticalVelocity = LocalVelocity.y
	local LocalHorizontalVelocity = sm.vec3.length( sm.vec3.new( LocalVelocity.x, 0, LocalVelocity.z ) * VelocityMultiplayer )
	local SpeedMultiplayer = math.abs( LocalHorizontalVelocity * VelocityMultiplayer )
	
	if SpeedMultiplayer > 1 then
		SpeedMultiplayer = 1
	end
	if SpeedMultiplayer < 0 then
		SpeedMultiplayer = 0
	end
	if SpeedMultiplayer > 0 then
		local Force = sm.vec3.new( 0, -LocalVerticalVelocity, 0 ) * Mass * SpeedMultiplayer * LiftForce / 4
		sm.physics.applyImpulse( self.shape, Force, false, sm.vec3.new( 0, 0, 0 ) )
	end
end


