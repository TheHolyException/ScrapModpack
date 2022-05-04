dofile "$SURVIVAL_DATA/Objects/00fant/character/straw_dog/fant_straw_dog.lua"
dofile "$SURVIVAL_DATA/Scripts/game/SurvivalGame.lua" 

Fant_Homing_Carrot = class()
Fant_Homing_Carrot.lifetime = 20
Fant_Homing_Carrot.FlySpeed = 65
Fant_Homing_Carrot.isAlive = true

function Fant_Homing_Carrot.server_onCreate( self )
	self.Target = nil
	self.sv_spawnProtection = 1
	self.mode = "all"
	self.ownerCharacter = nil
	self.sv_spawned = false
	self.sourceShape = nil
	local data = sm.interactable.getPublicData( sm.shape.getInteractable( self.shape ) )
	if data ~= nil then
		self.mode = data.mode
		self.ownerCharacter = data.ownerCharacter
		self.sourceShape = data.sourceShape
		self.network:sendToClients( "isSpawned" )
		self.sv_spawned = true
	end
	-- local name = "NoOwner"
	-- if self.ownerCharacter ~= nil then
		-- local player = self.ownerCharacter:getPlayer()
		-- if player ~= nil then
			-- name = player.name
		-- end
	-- end
end

function Fant_Homing_Carrot.server_onUnload( self )
	sm.shape.destroyPart( self.shape )
end

function Fant_Homing_Carrot.isSpawned( self )
	self.cl_spawned = true
	self.Effect:start()
end

function Fant_Homing_Carrot.client_onCreate( self )
	self.cl_spawnProtection = 0.5
	self.Effect = sm.effect.createEffect( "Thruster - Level 2", self )
	self.Effect:setParameter( "velocity", 30 )
	
	self.cl_spawned = false
end

function Fant_Homing_Carrot.client_onDestroy( self )
	self.Effect:stop()	
end

function Fant_Homing_Carrot.server_onFixedUpdate( self, dt )
	if not self.sv_spawned then
		return
	end
	if self.sv_spawnProtection >= 0 then
		self.sv_spawnProtection = self.sv_spawnProtection - dt
	end
	self.lifetime = self.lifetime - dt
	if self.lifetime <= 0 then
		self:Explode()
	end
	
	local body = sm.shape.getBody( self.shape )
	if body then	
		local TargetPosition = self.shape.worldPosition + ( sm.shape.getRight( self.shape ) * 1000 ) 
		 if not sm.exists( self.Target ) then
			self.Target = self:getTarget()
		 end
		 if self.Target ~= nil and sm.exists( self.Target ) then
			if type( self.Target ) == "Character" then
				TargetPosition = self.Target.worldPosition
				-- print("Unit:")
				-- print( self.Target )
			elseif type( self.Target ) == "Body" then
				TargetPosition = self.Target.worldPosition
				-- print("Body:")
				-- print( self.Target )
			elseif type( self.Target ) == "Shape" then
				TargetPosition = self.Target.worldPosition
				-- print("Shape:")
				-- print( self.Target )
			end
		end
		
		local distance = sm.vec3.length( TargetPosition - self.shape.worldPosition )	
		local selfpos = self.shape.worldPosition
		local leftPos = selfpos + sm.shape.getAt( self.shape )
		local rightPos = selfpos - sm.shape.getAt( self.shape )
		local upPos = selfpos + sm.shape.getUp( self.shape )
		local downPos = selfpos - sm.shape.getUp( self.shape )
		
		local ud = ( ( sm.vec3.length( TargetPosition - leftPos ) - sm.vec3.length( TargetPosition - rightPos ) ) / ( 1+ distance ) )
		local lr = ( ( sm.vec3.length( TargetPosition - upPos ) - sm.vec3.length( TargetPosition - downPos ) ) / ( 1+ distance ) )
		
		local turn = sm.vec3.new( 0, 0, 0 )
		if self.sv_spawnProtection <= 0 then			
			if distance <= 1 then
				self:Explode()
			end
			turn = sm.shape.getAt( self.shape ) * lr
			turn = turn + ( sm.shape.getUp( self.shape ) * -ud )
			turn = turn * 400 * ( 1 + ( distance / 100 ) )
			turn = turn - ( turn * 0.4 ) 
		end

		local angVel = -sm.body.getAngularVelocity( body ) * 4.5
		sm.physics.applyTorque( body, ( angVel + turn ) * dt, true )		
		
		local antiGrav = sm.vec3.new( 0, 0, 1 ) * body.mass * dt * 9.81 * 1.08
		local velocity = -body.velocity * dt * 100
		sm.physics.applyImpulse( body, antiGrav + velocity, true, nil )
		sm.physics.applyImpulse( body, sm.vec3.new( self.FlySpeed, 0, 0 ), false, nil )
	end
end

function Fant_Homing_Carrot.client_onUpdate( self, dt )
	if not self.cl_spawned then
		return
	end
	if self.cl_spawnProtection > 0 then
		self.cl_spawnProtection = self.cl_spawnProtection - dt
	end
	self.Effect:setPosition( self.shape.worldPosition - ( sm.shape.getRight( self.shape ) * 0.1 ) )
	self.Effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), -sm.shape.getRight( self.shape ) ) )
end

function Fant_Homing_Carrot.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
	if self.sv_spawnProtection > 0 then
		return
	end
	self:Explode()
end

function Fant_Homing_Carrot.client_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
	if self.cl_spawnProtection > 0 then
		return
	end
	self.network:sendToServer( "Explode" )
end

function Fant_Homing_Carrot.Explode( self )	
	if not self.isAlive then
		return
	end
	self.isAlive = false
	self.destructionLevel = 10
	self.destructionRadius = math.random( 0.5, 1 )
	self.impulseRadius = 5.0
	self.impulseMagnitude = 5.0
	self.explosionEffectName = "PropaneTank - ExplosionSmall" 
	--self.explosionEffectName = "PropaneTank - ExplosionBig" 
	
	sm.physics.explode( self.shape.worldPosition, self.destructionLevel, self.destructionRadius, self.impulseRadius, self.impulseMagnitude, self.explosionEffectName, self.shape )
	sm.shape.destroyPart( self.shape )
end


-- "all"
-- "robots"
-- "player"

-- unit_woc,
-- unit_worm,
-- unit_mechanic

function Fant_Homing_Carrot.getTarget( self )
	local TargetTable = {}
	
	if self.mode == "all" then
		TargetTable = sm.unit.getAllUnits()
		
		for i, ply in pairs( sm.player.getAllPlayers( ) ) do
			if ply ~= nil and self.ownerCharacter ~= nil then
				if ply.character ~= self.ownerCharacter then
					table.insert( TargetTable, ply )
				end
			end
		end
		
		for i, strawdog in pairs( g_strawdogs ) do
			if strawdog ~= nil then
				table.insert( TargetTable, strawdog )
			end
		end
	elseif self.mode == "robots" then
		for i, unit in pairs( sm.unit.getAllUnits() ) do
			if unit ~= nil then
				if unit.character:getCharacterType() ~= unit_woc and unit.character:getCharacterType() ~= unit_worm and unit.character:getCharacterType() ~= unit_mechanic then
					table.insert( TargetTable, unit )
				end
			end
		end
		for i, strawdog in pairs( g_strawdogs ) do
			if strawdog ~= nil then
				table.insert( TargetTable, strawdog )
			end
		end
	elseif self.mode == "player" then
		for i, ply in pairs( sm.player.getAllPlayers( ) ) do
			if ply ~= nil and self.ownerCharacter ~= nil then
				if ply.character ~= self.ownerCharacter then
					table.insert( TargetTable, ply )
				end
			end
		end
	elseif self.mode == "creation" then
		if self.sourceShape ~= nil then
			if sm.exists( self.sourceShape ) then
				local sorceBody = sm.shape.getBody( self.sourceShape )
				local selfBody = sm.shape.getBody( self.shape )
				local selfUUid = sm.shape.getShapeUuid( self.shape )
				for i, body in pairs( sm.body.getAllBodies( ) ) do
					if body ~= nil then
						if sm.body.isDestructable( body ) then
							if body ~= selfBody then
								if body ~= sorceBody then
									local canAdd = true
									local targetshapes = sm.body.getCreationShapes( body ) 
									local c = 0
									local biggestbody = body
									for i, shape in pairs( targetshapes ) do
										c = c + 1					
										if canAdd then
											if sm.shape.getShapeUuid( shape ) == selfUUid then
												canAdd = false
											end						
											local shapeBody = sm.shape.getBody( shape )
											if shapeBody ~= nil then
												if biggestbody.mass <= shapeBody.mass then
													biggestbody = shapeBody
												end
												if shapeBody == selfBody then
													canAdd = false
												end
												if shapeBody == sorceBody then
													canAdd = false
												end
											end
										end
									end
									if canAdd then
										table.insert( TargetTable, targetshapes[ math.random( 1, c ) ] )
										--table.insert( TargetTable, biggestbody )
									end
								end
							end
						end
					end
				end
			end
		end
	end

	local pos = self.shape.worldPosition + ( sm.shape.getRight( self.shape ) * 1000 )
	local returnTarget = nil
	for index, target in pairs( TargetTable ) do 
		--print( type( target ) )
		if sm.exists( target ) then
			if type( target ) == "Unit" then
				if sm.vec3.length( self.shape.worldPosition - target.character.worldPosition ) <= sm.vec3.length( self.shape.worldPosition - pos ) then
					pos = target.character.worldPosition + sm.vec3.new( 0, 0, 0.1 )
					returnTarget = target.character
				end
			end
			if type( target ) == "Body" then
				if sm.vec3.length( self.shape.worldPosition - target.worldPosition ) <= sm.vec3.length( self.shape.worldPosition - pos ) then
					pos = target.worldPosition
					returnTarget = target
				end
			end
			if type( target ) == "Shape" then
				if sm.vec3.length( self.shape.worldPosition - target.worldPosition ) <= sm.vec3.length( self.shape.worldPosition - pos ) then
					pos = target.worldPosition
					returnTarget = target
				end
			end
		end
	end
	return returnTarget
end


