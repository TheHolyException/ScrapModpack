dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"


Fant_Sail = class()
Fant_Sail.poseWeightCount = 1

WIND_HOST = nil
WIND_POWER = 400
WIND_POWER_MUL = 1
WIND_CHANGE_TIMER = 0
WIND_DIRECTION = sm.vec3.new( 1, 0, 0 )
WIND_DIRECTION_CL = WIND_DIRECTION
WIND_OVERTIME = WIND_DIRECTION
WIND_OVERTIME_CL = WIND_DIRECTION


function Fant_Sail.client_onUpdate( self, dt )
	if WIND_OVERTIME_CL ~= WIND_DIRECTION_CL then
		WIND_OVERTIME_CL = sm.vec3.lerp( WIND_OVERTIME_CL, WIND_DIRECTION_CL, dt * 0.05 )
	end
	dot = sm.vec3.dot( self.shape:getRight(), WIND_OVERTIME_CL ) * 0.5
	self.shape:getInteractable():setPoseWeight( 0, 0.5 + dot )
	-- if self.effect == nil then
		-- self.effect = sm.effect.createEffect( "ShapeRenderable" )				
		-- self.effect:setParameter( "uuid", sm.uuid.new("f7881097-9320-4667-b2ba-4101c72b8730") )
		-- self.effect:start()
	-- end
	-- self.effect:setPosition( self.shape.worldPosition + WIND_OVERTIME_CL )	
end

function Fant_Sail.server_onFixedUpdate( self, dt )
	self.body = self.shape:getBody()
	if WIND_HOST == nil or not sm.exists( WIND_HOST ) then
		WIND_HOST = self.shape
	end
	if WIND_HOST == self.shape then
		WIND_CHANGE_TIMER = WIND_CHANGE_TIMER - dt
		if WIND_CHANGE_TIMER <= 0 then
			WIND_CHANGE_TIMER = math.random( 30, 60 )
			newDir = sm.vec3.new( math.random( -1,1 ), math.random( -1,1 ), 0 )
			if newDir ~= sm.vec3.new( 0, 0, 0 ) then
				WIND_DIRECTION = sm.vec3.normalize(  newDir	)	
				WIND_POWER_MUL = 1--math.random( 0.85, 1 )	
				self.network:sendToClients( "cl_set_Wind_Dir", WIND_DIRECTION )
			end
		end
	end
	
	if WIND_OVERTIME ~= WIND_DIRECTION then
		WIND_OVERTIME = sm.vec3.lerp( WIND_OVERTIME, WIND_DIRECTION, dt * 0.05 )
	end
	
	Dot = math.floor( sm.vec3.dot( self.shape:getRight(), WIND_OVERTIME ) * 1000 ) / 1000
	if Dot ~= 0 then
		if self.body ~= nil and sm.exists( self.body ) and #sm.body.getCreationShapes( self.body ) > 1 then
			local ForceMul = 1
			if self.shape:getShapeUuid() == obj_interactive_fant_sail_3x3 then
				ForceMul = 0.4
			end
			if self.shape:getShapeUuid() == obj_interactive_fant_sail_4x4 then
				ForceMul = 0.6
			end
			if self.shape:getShapeUuid() == obj_interactive_fant_sail_5x5 then
				ForceMul = 0.8
			end
			if self.shape:getShapeUuid() == obj_interactive_fant_sail_7x7 then
				ForceMul = 1
			end
			sm.physics.applyImpulse( self.shape, -self.shape:getRight() * WIND_POWER * Dot * ForceMul * WIND_POWER_MUL, true, sm.vec3.new( 0, 0, 0 ) )
		end
	end
end

function Fant_Sail.cl_set_Wind_Dir( self, dir )
	WIND_DIRECTION_CL = dir
	self.network:sendToServer( "sv_set_Wind_Dir", dir )
end

function Fant_Sail.sv_set_Wind_Dir( self, dir )
	WIND_DIRECTION = dir
end

function Fant_Sail.server_onDestroy( self )
	WIND_HOST = nil
end

function Fant_Sail.server_onUnload( self )
	WIND_HOST = nil
end
