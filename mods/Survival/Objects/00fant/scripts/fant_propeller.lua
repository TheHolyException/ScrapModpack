function PropellerUpdate( data )
	local self = data.self
	local dt = data.dt
	local forceDirection = data.force
	local body = sm.shape.getBody( self.shape )
	if body == nil then
		return
	end
	local Position = sm.shape.getWorldPosition( self.shape )
	local LocalVelocity = self.shape:transformPoint( Position + ( sm.shape.getVelocity( self.shape ) ) )
	local AngularVelocity = sm.body.getAngularVelocity( body )
    local LocalAngularVelocity = AngularVelocity:dot( sm.shape.getAt( self.shape ) )
	local ForceDir = 1
	if LocalAngularVelocity > 0 then
		ForceDir = -1
	end
	local VelLength = 1 - sm.util.clamp( ( math.floor( LocalVelocity.y * 100 ) / 100 ) / 75, 0, 1 )
	if LocalVelocity.y <= 0 then
		VelLength = 1
	end
	if VelLength > 1 then
		VelLength = 1
	end
	local Force = sm.util.clamp( sm.vec3.length( AngularVelocity ) / 75, 0, 1 ) * VelLength * ForceDir * forceDirection
	sm.physics.applyImpulse( self.shape, sm.vec3.new( 0, Force * 30, 0 ), false, sm.vec3.new( 0, 0, 0 ) )
end





