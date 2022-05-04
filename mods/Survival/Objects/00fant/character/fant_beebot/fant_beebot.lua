dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"
dofile "$SURVIVAL_DATA/Scripts/game/characters/Character.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_tesla_coil.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survivalPlayer.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_ElectroHammer/Fant_ElectroHammer.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_robotdetector.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_flamethrower.lua"

Fant_Beebot = class( nil )
local SPAWN_HEALTH = 150
local ANIMATION_SPEED = 0.2
local ATTACK_RANGE = 40
local ATTACK_SPEED = 500
local GRAB_RANGE = 2
local GRAB_TIME = 5
local WAIT_TIME = 5
local SPAWNDISTANCE = 200

g_Beebots = g_Beebots or {}

local LootTable = {
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_resource_beewax, { 5, 10 } },
	{ obj_interactive_thruster_03, { 1, 1 } }
}


function Fant_Beebot.server_onCreate( self )
	if isSurvival then
		for i, Beebot in pairs( g_Beebots ) do	
			if Beebot ~= nil and sm.exists( Beebot ) then
				if sm.vec3.length( Beebot.worldPosition - self.shape.worldPosition ) < SpawnDistance then
					sm.shape.destroyShape( self.shape, 0 )
					self.destroy = true
					return
				end
			end
		end
		
	end
	if sm.body.isStatic( sm.shape.getBody( self.shape ) ) then
		sm.shape.createPart( fant_beebot, self.shape.worldPosition + sm.vec3.new( 0, 0, 1 ), self.shape.worldRotation, true, false ) 
		sm.shape.destroyShape( self.shape, 0 )
		self.destroy = true
		return
	end
	
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { currentHealth = SPAWN_HEALTH, MaximalHealth = SPAWN_HEALTH }
	end
	if self.saved.currentHealth == nil then
		self.saved.currentHealth = SPAWN_HEALTH
	end
	if self.saved.MaximalHealth == nil then
		self.saved.MaximalHealth = SPAWN_HEALTH
	end
	self.storage:save( self.saved )
	
	self.LifeTime = 120
	self.impactCooldownTicks = 0
	
	self.sv_activeAnimation = ""
	self:set_sv_Animation( "idle" )
	
	self.destroy = false
	self.destroyTimer = 0.1
	
	self.ID = sm.interactable.getId( sm.shape.getInteractable( self.shape ) )
	Fant_RobotDetector_Add_Unit( ( self.ID + 200 ), { shape = self.shape,  health = self.saved.currentHealth, maxhealth = self.saved.MaximalHealth } )

	self.spawnPosition = self.shape.worldPosition
	
	self.target = nil
	self.room_timer = 0
	
	self.grab_state = 0
	self.grab_timer = 0
	self.grab_lock_timer = 0
	
	g_Beebots[ self.ID ] = self.shape
end

function Fant_Beebot.client_onCreate( self )
	self.cl_animationTimer = 0
	self.cl_activeAnimation = "idle"
	self.cl_lastAnimation = ""
	
	
	self.Effect_Left = sm.effect.createEffect( "Thruster - Level 3", self.interactable )	
	self.Effect_Left:setOffsetPosition( sm.vec3.new( 0.75, 0.3, 0 ) )
	self.Effect_Left:setOffsetRotation( sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 0, 0, 1 ) ) )
	self.Effect_Left:start()
	self.Effect_Right = sm.effect.createEffect( "Thruster - Level 3", self.interactable )	
	self.Effect_Right:setOffsetPosition( sm.vec3.new( -0.75, 0.3, 0 ) )
	self.Effect_Right:setOffsetRotation( sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 0, 0, 1 ) ) )
	self.Effect_Right:start()

end

function Fant_Beebot.server_onDestroy( self )
	if self.ID ~= nil then
		g_Beebots[ self.ID ] = nil
		self.storage:save( self.saved )
	end
end

function Fant_Beebot.server_onUnload( self )
	sm.shape.destroyShape( self.shape, 0 )
end

function Fant_Beebot.client_onDestroy( self )
	self.Effect_Left:stop()	
	self.Effect_Right:stop()	

end

function getPosZz( pos )
	return sm.vec3.new( pos.x, pos.y, 0 )
end

function Fant_Beebot.server_onFixedUpdate( self, dt )
	self:DestroyCheck()
	if self.destroy then
		return
	end
	self:LifeTimeDeleter( dt )
	
	if g_units[ ( self.ID + 200 ) ] ~= { shape = self.shape,  health = self.saved.currentHealth, maxhealth = self.saved.MaximalHealth } then
		g_units[ ( self.ID + 200 ) ] = { shape = self.shape,  health = self.saved.currentHealth, maxhealth = self.saved.MaximalHealth }
	end

	ProcessTeslaDamage( self, false )
	FlamethrowerDamage( self, dt )
	
	if self.grab_lock_timer > 0  then
		self.grab_lock_timer = self.grab_lock_timer - dt
		if self.grab_lock_timer <= 0 then
			self.grab_lock_timer = 0
		end
	end

	self:getTarget()
	self:checkTarget()
	
	
	if self.target == nil or self.grab_lock_timer > 0 then
		if self.room_position == nil or self.room_timer <= 0 then
			self.room_position = sm.vec3.new( self.spawnPosition.x + math.random( -10, 10 ), self.spawnPosition.y + math.random( -10, 10 ), math.random( 4, 10 ) )
			self.room_timer = math.random( 3, 8 )
		end
		if self.room_timer > 0 then
			self.room_timer = self.room_timer - dt
		end
		local room_Distance = sm.vec3.length( getPosZz( self.room_position ) - getPosZz( self.shape.worldPosition ) )
		if room_Distance > 1 then
			self:set_sv_Animation( "fly" )
			self:MoveTo( self.room_position, 200, dt )
			self:TurnTo( self.room_position, 1, dt )
		else
			
			self:set_sv_Animation( "idle" )
		end
		self:BodyMovement( dt, self.room_position.z )
	end



	if self.target ~= nil and self.grab_lock_timer <= 0 then	
		local target_distance = sm.vec3.length( self.target.character.worldPosition - self.shape.worldPosition )

		if self.grab_state == 0 then
			if self.grab_timer > 0 then
				self.grab_timer = self.grab_timer - dt
				if self.grab_timer <= 0 then
					self:set_sv_Animation( "idle" )
				end
				self:BodyMovement( dt, 7 )
			else
				local target_Z = ( self.target.character.worldPosition.z - self.shape.worldPosition.z ) + 5
				self:BodyMovement( dt, target_Z )
				self:MoveTo( self.target.character.worldPosition, ATTACK_SPEED, dt )
				self:TurnTo( self.target.character.worldPosition, 1, dt )
				if target_distance < GRAB_RANGE then
					self.grab_timer = GRAB_TIME
					self.grab_state = 1
				end
				self:set_sv_Animation( "fly" )
			end
			
		end
		
		if self.grab_state == 1 then
			self:holdTarget( self.target, dt )
			self:MoveTo( self.shape.worldPosition + ( self.shape:getUp() * 1 ), 600, dt )
			--self:TurnTo( self.target.character.worldPosition, 1, dt )
			self:BodyMovement( dt, 50 )
			if self.grab_timer > 0 then
				self.grab_timer = self.grab_timer - dt
				if self.grab_timer <= 0 then
					self.grab_timer = WAIT_TIME
					self.grab_state = 2
				end
			end
			self:set_sv_Animation( "attack" )
		end
		
		
		if self.grab_state == 2 then
			self:BodyMovement( dt, 20 )
			if self.grab_timer > 0 then
				self.grab_timer = self.grab_timer - dt
				if self.grab_timer <= 0 then
					self.grab_timer = 0
					self.grab_state = 0
				end
			end
			self:set_sv_Animation( "idle" )
			self.room_position = sm.vec3.new( self.spawnPosition.x + math.random( -10, 10 ), self.spawnPosition.y + math.random( -10, 10 ), math.random( 4, 10 ) )
		end
		

		
	end
	
	
	
	
end

function Fant_Beebot.holdTarget( self, target, dt )
	if target ~= nil then
		if target.character ~= nil then
			local isTumbling = target.character:isTumbling()
			local target_pos = target.character.worldPosition
			local target_mass = 100

			if isTumbling then
				target_pos = target.character:getTumblingWorldPosition()
			else
				target_mass = target.character:getMass()
			end
			
			local force = ( ( self.shape.worldPosition + sm.vec3.new( 0, 0, -0.8 ) ) - target_pos ) * target_mass * 3
			local vel = self.target.character:getVelocity()
			if vel ~= sm.vec3.new( 0, 0, 0 ) then
				force = force - ( vel * target_mass * 0.3 )
			end
			
			if isTumbling then
				target.character:applyTumblingImpulse( force )
			else
				sm.physics.applyImpulse( target.character, force, true )
			end
		end
	end
end

function Fant_Beebot.getTarget( self )
	if self.target == nil then
		local players = sm.player.getAllPlayers() 
		local target = players[1]
		local TargetDistance = sm.vec3.length( getPosZz( target.character.worldPosition ) - getPosZz( self.shape.worldPosition ) )
		for i, player in pairs( players ) do	
			if player ~= nil then 
				if player.character ~= nil then 
					
					if not player.character:isTumbling() and not player.character:isDiving() and not player.character:isSwimming()then 			
						local new_distance = sm.vec3.length( getPosZz( player.character.worldPosition ) - getPosZz( self.shape.worldPosition ) )
						local old_distance = sm.vec3.length( getPosZz( target.character.worldPosition ) - getPosZz( self.shape.worldPosition ) )
						if new_distance < old_distance then
							target = player
							TargetDistance = new_distance
						end
					end
				end
			end
		end
		if sm.vec3.length( getPosZz( target.character.worldPosition ) - getPosZz( self.shape.worldPosition ) ) > ATTACK_RANGE then
			target = nil
		end
		if target ~= nil then
			if target.character:isTumbling() then
				target = nil
			end
		end
		if target ~= nil then
			if target.character:isDiving() then
				target = nil
			end
		end
		if target ~= nil then
			if target.character:isSwimming() then
				target = nil
			end
		end	
		if target ~= nil then
			self.target = target
		end
	else
		if self.target ~= nil then
			if self.target.character:isTumbling() then
				self.target = nil
			end
		end
		if self.target ~= nil then
			if self.target.character:isDiving() then
				self.target = nil
			end
		end
		if self.target ~= nil then
			if self.target.character:isSwimming() then
				self.target = nil
			end
		end

	end
end

function Fant_Beebot.checkTarget( self )
	if self.target ~= nil then
		if sm.vec3.length( getPosZz( self.target.character.worldPosition ) - getPosZz( self.shape.worldPosition ) ) > ATTACK_RANGE then
			self.target = nil
		end
	end
end

function Fant_Beebot.MoveTo( self, targetPos, speed, dt )
	if self.destroy then
		return
	end
	local distance = sm.vec3.length( getPosZz( targetPos ) - getPosZz( self.shape.worldPosition ) )
	if distance > 0.5 then
		local direction = sm.vec3.normalize( getPosZz( targetPos ) - getPosZz( self.shape.worldPosition ) )
		if direction == sm.vec3.new( 0, 0, 0 ) then
			direction = sm.shape.getUp( self.shape )
		end
		sm.physics.applyImpulse( sm.shape.getBody( self.shape ), ( direction * speed ), true, nil )
	end
end

function Fant_Beebot.TurnTo( self, targetPos, speed, dt )
	if self.destroy then
		return
	end
	local direction = self.shape:transformPoint( sm.vec3.new( targetPos.x, targetPos.y, self.shape.worldPosition.z ) )
	if direction == sm.vec3.new( 0, 0, 0 ) then
		direction = sm.shape.getUp( self.shape )
	end
	local TurnForce = sm.vec3.normalize( direction ).x * 5000
	if direction.z < -0.2 then
		if direction.x < -0.5 then
			TurnForce = -10000
		end
		if direction.x > 0.5 then
			TurnForce = 10000
		end
	end
	--if direction.z > 0.001 then
		TurnForce = TurnForce - ( sm.shape.getBody( self.shape ):getAngularVelocity().z * 2 )
		sm.physics.applyTorque( sm.shape.getBody( self.shape ), sm.vec3.new( 0, 0, TurnForce ) * dt * speed, true )
	--end
end

function Fant_Beebot.BodyMovement( self, dt, height )
	if self.destroy then
		return
	end
	local body = sm.shape.getBody( self.shape )
	local DownDirection = sm.vec3.new( 0, 0, -1 )
	local Force = -sm.body.getVelocity( body ) * 100
	local GroundHits = 1
	local GroundDistance1 = self:getDistance( self.shape.worldPosition + ( sm.shape.getRight( self.shape ) * 4 ), DownDirection )
	if GroundDistance1 == nil then
		GroundDistance1 = height
	end
	local GroundDistance2 = self:getDistance( self.shape.worldPosition + ( sm.shape.getRight( self.shape ) * -4 ), DownDirection )
	if GroundDistance2 == nil then
		GroundDistance2 = height
	else
		GroundHits = GroundHits + 1
	end
	local GroundDistance = ( GroundDistance1 + GroundDistance2 ) / GroundHits
	local GroundForceValue = ( height - GroundDistance )
	local ClampValue = 2
	if GroundForceValue < -ClampValue then
		GroundForceValue = -ClampValue
	end
	if GroundForceValue > ClampValue then
		GroundForceValue = ClampValue
	end
	Force = Force + sm.vec3.new( 0, 0, GroundForceValue * 250 )
	sm.physics.applyImpulse( body, Force, true, nil )
	local leverlength = 0.5
	local blanceForce = 10000
	local fb = ( self.shape.worldPosition + ( sm.shape.getUp( self.shape ) * leverlength ) ).z - ( self.shape.worldPosition + ( sm.shape.getUp( self.shape ) * -leverlength ) ).z
	local lr = ( self.shape.worldPosition + ( sm.shape.getRight( self.shape ) * leverlength ) ).z - ( self.shape.worldPosition + ( sm.shape.getRight( self.shape ) * -leverlength ) ).z
	if ( self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * leverlength ) ).z <= self.shape.worldPosition.z then
		fb = 10
	end
	local balanceVec = sm.shape.getRight( self.shape ) * fb
	balanceVec = balanceVec + ( sm.shape.getUp( self.shape ) * -lr )
	sm.physics.applyTorque( body, balanceVec * blanceForce * dt, true )
	
	sm.physics.applyTorque( body, ( -sm.body.getAngularVelocity( body ) * 1000 ) * dt, true )
end

function Fant_Beebot.getDistance( self, StartPos, Direction )
	local Valid, Result = sm.physics.raycast( StartPos, StartPos + ( Direction * 100), self.shape )
	if Valid or Result then
		--print( Result)
		if Result.type == "terrainSurface" or Result.type == "terrainAsset" then
			return sm.vec3.length( StartPos - Result.pointWorld )
		else
			return nil
		end
	end
	return nil
end

function Fant_Beebot.set_sv_Animation( self, animation )
	if self.destroy then
		return
	end
	if self.sv_activeAnimation ~= animation then
		self.sv_activeAnimation = animation
		self.network:sendToClients( "set_cl_Animation", self.sv_activeAnimation )
	end
end

function Fant_Beebot.set_cl_Animation( self, animation )
	if self.destroy then
		return
	end
	if animation == "attack" then
		self.cl_animationTimer = 0
	end
	self.cl_activeAnimation = animation
end

function Fant_Beebot.client_onUpdate( self, dt )
	if self.destroy then
		return
	end
	if self.cl_lastAnimation ~= self.cl_activeAnimation then
		if self.cl_lastAnimation ~= "" then
			self.interactable:setAnimProgress( self.cl_lastAnimation, 0 )
			self.interactable:setAnimEnabled( self.cl_lastAnimation, false )
		end
		if self.cl_activeAnimation ~= "" then
			self.interactable:setAnimEnabled( self.cl_activeAnimation, true )	
		end
		self.cl_lastAnimation = self.cl_activeAnimation
	end
	self.cl_animationTimer = self.cl_animationTimer + ( dt * ANIMATION_SPEED )
	if self.cl_animationTimer > 1 then
		self.cl_animationTimer = 0
	end
	if self.cl_activeAnimation ~= "" then
		self.interactable:setAnimProgress( self.cl_activeAnimation, self.cl_animationTimer )
	end
end

function Fant_Beebot.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	self:sv_takeDamage( attacker, damage, hitPos )
end

function Fant_Beebot.server_onMelee( self, hitPos, attacker, damage )
	self:sv_takeDamage( attacker, damage, hitPos, true )
	GetMeleeHit( self, attacker )
end

function Fant_Beebot.server_onExplosion( self, position, destructionLevel )
	self:sv_takeDamage( nil, 50, position )
end

function Fant_Beebot.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal  ) 
	if self.impactCooldownTicks > 0 then
		return
	end
	if other == nil then
		return
	end
	if type( other ) == "Character" then
		if not sm.exists( other ) then
			return
		end
	end
	if type( other ) == "Shape" then
		if not sm.exists( other ) then
			return
		end
		if other == self.shape then
			return
		end
	end
	--print( other )
	local ImpactVel = sm.vec3.length( selfPointVelocity + otherPointVelocity )
	--print( ImpactVel )
	if ImpactVel < 20 then 
		return
	end
	self.impactCooldownTicks = 0.5
	local damage = 15 + ( ImpactVel / 10 )
	if damage > 0 then		
		self:sv_takeDamage( other, damage )
	end
end

function Fant_Beebot.sv_takeDamage( self, attacker, damage, pos, melee )
	if self.destroy then
		return
	end
	if damage == nil then
		return
	end
	if damage <= 0 then
		return
	end
	if attacker ~= nil then
		--print( type(attacker) )
		if type(attacker) == "Player" then

		end
		if type(attacker) == "Shape" then

		end
	end
	
	if melee then
		self.grab_state = 0
		self.grab_lock_timer = 1
		self.room_position = sm.vec3.new( self.spawnPosition.x + math.random( -10, 10 ), self.spawnPosition.y + math.random( -10, 10 ), math.random( 4, 10 ) )
	end
	--print( "Fant_Beebot took damage: "..tostring( self.saved.currentHealth ) )
	if self.saved.currentHealth == nil then
		self.saved.currentHealth = SPAWN_HEALTH
	end
	self.saved.currentHealth = self.saved.currentHealth - damage
	if self.saved.currentHealth < 0 then
		self.saved.currentHealth = 0
	end
	if self.saved.currentHealth == 0 then
		self:Die()
		-- 00Fant
		if type( attacker ) == "Player" then
			sm.event.sendToPlayer( attacker, "sv_addRobotKill", { attacker = attacker, typeName = "beebot" } )
		end
		-- 00Fant
	else
		self.network:sendToClients( "cl_setHealth", self.saved.currentHealth )
		--self:sv_doSound( "Farmbot - Angry" )
	end
	
	-- 00Fant
	Fant_RobotDetector_Add_Unit( ( self.ID + 200 ), { shape = self.shape,  health = self.saved.currentHealth, maxhealth = self.saved.MaximalHealth } )
	-- 00Fant
end

function Fant_Beebot.cl_setHealth( self, health )
	self.currentHealth = health
end

function Fant_Beebot.Die( self )
	if self.destroy == false then
		self:DropLoot()
		self.destroy = true
		self.destroyTimer = 0.1
		self.network:sendToClients( "PlayDeathEffect" )
		if isSurvival then
			self:sv_spawnParts()
		end
		self:sv_doSound( "Haybot - Destroyed" )
	end
end

function Fant_Beebot.DropLoot( self )
	local Loot = LootTable[ math.floor( math.random( 1, #LootTable  ) ) ]
	local amount = math.floor( math.random( Loot[2][1], Loot[2][2] ) )
	local params = { lootUid = Loot[1], lootQuantity = amount, epic = false }
	sm.projectile.shapeCustomProjectileAttack( params, "loot", 0, sm.vec3.new( 0, 0, 0 ), sm.vec3.new( 0, -5, 0 ), self.shape, 0 )			
end

function Fant_Beebot.PlayDeathEffect( self )
	sm.effect.playEffect( "Part - Electricity", self.shape.worldPosition, sm.vec3.new( 0, 0, 0 ), sm.quat.identity() )
end

function Fant_Beebot.sv_spawnParts( self )
	self:sv_lazyPartSpawn( obj_robotparts_haybothead, sm.vec3.new( 0, 1, 0 ) )
	self:sv_lazyPartSpawn( obj_harvest_metal, sm.vec3.new( 0, 1, 0 ) )
	self:sv_lazyPartSpawn( obj_harvest_metal, sm.vec3.new( 0, 1, 0 ) )
	self:sv_lazyPartSpawn( obj_harvest_metal, sm.vec3.new( 0, 1, 0 ) )
	self:sv_lazyPartSpawn( obj_harvest_metal, sm.vec3.new( 0, 1, 0 ) )
	
end

function Fant_Beebot.sv_lazyPartSpawn( self, partUUID, offset )
	if partUUID == nil then
		return
	end
	local impact = sm.vec3.new( 0, 1, 0 ) + offset
	local bodyPos = self.shape.worldPosition
	local rot = sm.quat.new( math.random( -1.0, 1.0 ), math.random( -1.0, 1.0 ), math.random( -1.0, 1.0 ), math.random( -1.0, 1.0 ) )

	local part = sm.shape.createPart( partUUID, bodyPos + offset, rot, true, true )
	part:setColor( self.shape:getColor() )
	sm.physics.applyImpulse( part, impact, true )
end

function Fant_Beebot.sv_doSound( self, name )
	if self.destroy then
		return
	end
	if self.SoundDelay <= 0 then
		self.network:sendToClients( "cl_doSound", name )
	end
	self.SoundDelay = 0.5
end

function Fant_Beebot.cl_doSound( self, name )
	if self.destroy then
		return
	end
	sm.effect.playEffect( name, self.shape.worldPosition, nil, nil )
end

function Fant_Beebot.LifeTimeDeleter( self, dt )
	if self.destroy then
		return
	end
	local players = sm.player.getAllPlayers() 
	local nearestplayer = players[1]
	local MinimalDistanceToPlayer = 0
	for i, player in pairs( players ) do	
		if player ~= nil then 
			if player.character ~= nil then 
				local new_distance = sm.vec3.length( player.character.worldPosition - self.shape.worldPosition )
				local old_distance = sm.vec3.length( nearestplayer.character.worldPosition - self.shape.worldPosition )
				if new_distance <= old_distance then
					nearestplayer = player
					MinimalDistanceToPlayer = new_distance
				end
			end
		end
	end
	if self.LifeTime > 0 and MinimalDistanceToPlayer > SPAWNDISTANCE / 2 then
		self.LifeTime = self.LifeTime - dt
		--print( "Fant_Beebot Lifetime: " .. tostring(self.LifeTime) )
	end
	if self.LifeTime <= 0 then
		sm.shape.destroyShape( self.shape, 0 )
		--print( "Fant_Beebot Lifetime Deleter!" )
	end
	
	--print( "Fant_Beebot Lifetime: " .. tostring(self.LifeTime) )
end

function Fant_Beebot.DestroyCheck( self )
	if self.destroy then
		sm.shape.destroyShape( self.shape, 0 )
	end
end
