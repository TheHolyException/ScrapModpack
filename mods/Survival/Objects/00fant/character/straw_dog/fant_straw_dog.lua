dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"
dofile "$SURVIVAL_DATA/Scripts/game/characters/Character.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_tesla_coil.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survivalPlayer.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_ElectroHammer/Fant_ElectroHammer.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_robotdetector.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_flamethrower.lua"

g_strawdogs = g_strawdogs or {}

Blender_Animation_Speed = 0.25
Fant_Straw_Dog = class( Character )
Fant_Straw_Dog.RoomingRange = 20
Fant_Straw_Dog.MaximalHealth = 200
Fant_Straw_Dog.Damage = 12
Fant_Straw_Dog.AttackRate = 1.2
Fant_Straw_Dog.AttackRange = 6
Fant_Straw_Dog.LifeTime = 5
Fant_Straw_Dog.AggroRange = 200

SpawnDistance = 150


function SpawnStraw_dog( self )
	for i, strawdog in pairs( g_strawdogs ) do	
		if strawdog ~= nil and sm.exists( strawdog ) then
			if sm.vec3.length( strawdog.worldPosition - self.unit.character.worldPosition ) < SpawnDistance then
				return
			end
		end
	end
	
	if math.random( 0.0, 100.0 ) > 50 then
		sm.shape.createPart( fant_straw_dog, self.unit.character.worldPosition, sm.quat.identity( ), true, true )
		print( "-- HaybotUnit replaced with StrawDog --" )
		--self.unit:destroy()
		print("Strawdog Amount: " ..  tostring( #g_strawdogs ) )
		return
	end
end


LootTable = {
	{ obj_resource_corn, { 1, 3 } },
	{ obj_consumable_component, { 1, 2 } },
	{ obj_resource_circuitboard, { 2, 5 } },
	{ obj_consumable_battery, { 1, 2 } },
	{ blk_scrapmetal, { 10, 20 } }
}

AnimationTable = {
	idle = {
		animationspeed = 0.25,
		height = 0.0,
		movespeed = 0
	},
	walk = {
		animationspeed = 1.0,
		height = 0.5,
		movespeed = 300
	},
	run = {
		animationspeed = 1.4,
		height = 1.3,
		movespeed = 600
	},
	attack01 = {
		animationspeed = 1.2,
		height = 0.7,
		movespeed = 0
	}
	,
	death01 = {
		animationspeed = 1.0,
		height = 0,
		movespeed = 0
	}
}

function Fant_Straw_Dog.server_onCreate( self )	
	if sm.body.isStatic( sm.shape.getBody( self.shape ) ) then
		sm.shape.createPart( fant_straw_dog, self.shape.worldPosition + sm.vec3.new( 0, 0, 1 ), sm.quat.identity( ), true, false ) 
		sm.shape.destroyShape( self.shape, 0 )
	end
	if isSurvival then
		for i, strawdog in pairs( g_strawdogs ) do	
			if strawdog ~= nil and sm.exists( strawdog ) then
				if sm.vec3.length( strawdog.worldPosition - self.shape.worldPosition ) < SpawnDistance then
					sm.shape.destroyShape( self.shape, 0 )
				end
			end
		end
	end
	self.spawnPosition = self.shape.worldPosition
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = {  } 
		self.storage:save( self.sv.storage )
	end
	self.sv_activeAnimation = "idle"
	
	self.TargetPosition = self.shape.worldPosition
	self.idleSleeper = 0
	self.attackSleeper = 0
	
	self.currentHealth = self.MaximalHealth
	self.network:sendToClients( "cl_setHealth", self.currentHealth )
	
	self.destroy = false
	self.destroyTimer = 0.1
	
	self.LifeTime = 120
	
	self.aggrotimer = 0
	self.impactCooldownTicks = 0
	
	self.ID = sm.interactable.getId( sm.shape.getInteractable( self.shape ) ) 
	g_strawdogs[ self.ID ] = self.shape
	
	print("Strawdog Amount: " ..  tostring( #g_strawdogs ) )
	
	Fant_RobotDetector_Add_Unit( ( self.ID + 200 ), { shape = self.shape,  health = self.currentHealth, maxhealth = self.MaximalHealth } )
end

function Fant_Straw_Dog.client_onCreate( self )
	self.cl_animationTimer = 0
	self.cl_activeAnimation = "idle"
	self.cl_lastAnimation = ""
	self.currentHealth = self.currentHealth or 0
	self.HalfAnimationDone = false
	self.SoundDelay = 0
end

function Fant_Straw_Dog.IsInView( self, target )
	if target == nil then
		return false
	end
	local localPosZ = self.shape:transformPoint( target.character.worldPosition ).z
	
	local start = self.shape:getWorldPosition()
	local stop = target.character.worldPosition
	local valid, result = sm.physics.raycast( start, stop, self.shape )
	
	local ClosestPlayerDistance = sm.vec3.length( start - stop ) / sm.construction.constants.subdivideRatio
	if ClosestPlayerDistance < self.AggroRange  / 4 then
		return true
	end
	if valid then	
		if result:getCharacter() == target:getCharacter() then
			if localPosZ < 0 then
				return false
			end
			return true
		end
	end	
	return false
end

function Fant_Straw_Dog.server_onFixedUpdate( self, dt )
	if g_units[ ( self.ID + 200 ) ] ~= { shape = self.shape,  health = self.currentHealth, maxhealth = self.MaximalHealth } then
		g_units[ ( self.ID + 200 ) ] = { shape = self.shape,  health = self.currentHealth, maxhealth = self.MaximalHealth }
	end
	
	ProcessTeslaDamage( self, false )
	FlamethrowerDamage( self, dt )
	
	self:BodyMovement( dt )
	if self.aggrotimer > 0 then
		self.aggrotimer = self.aggrotimer - dt
	end
	if self.SoundDelay > 0 then
		self.SoundDelay = self.SoundDelay - dt
	end	
	if self.impactCooldownTicks > 0 then
		self.impactCooldownTicks = self.impactCooldownTicks - dt
	end
	if self.attackSleeper > 0 then
		self.attackSleeper = self.attackSleeper - dt 
	end
	if not self.destroy and self.currentHealth > 0 then
		local players = sm.player.getAllPlayers() 
		local targetPos = self.shape.worldPosition + ( sm.shape.getUp( self.shape ) * 1000 )
		local target = nil
		for i, player in pairs( players ) do	
			if player ~= nil then 
				if player.character ~= nil then 
					local new_distance = sm.vec3.length( player.character.worldPosition - self.shape.worldPosition )
					local old_distance = sm.vec3.length( targetPos - self.shape.worldPosition )
					if new_distance <= old_distance and ( self:IsInView( player ) or self.aggrotimer > 0 ) then
						targetPos = player.character.worldPosition
						target = player
					end
				end
			end
		end
		
		
		local ClosestPlayerDistance = sm.vec3.length( targetPos - self.shape.worldPosition ) / sm.construction.constants.subdivideRatio
		if ClosestPlayerDistance < self.AggroRange and self.aggrotimer <= 0 then
			self.TargetPosition = targetPos
		else
			if self.aggrotimer > 0.1 and self.attackSleeper <= 0 then
				self.TargetPosition = targetPos
			else
				target = nil
			end
		end

		local distance = 10000
		if self.TargetPosition ~= nil then
			distance = sm.vec3.length( self.TargetPosition - self.shape.worldPosition ) / sm.construction.constants.subdivideRatio
		end
		if target then
			if distance > 6 and self.attackSleeper <= 0 then
				if self.attackSleeper <= 0 then
					self:set_sv_Animation( "run" )
					if not self:IsInView( target ) and self.attackSleeper <= 0 then
						targetPos = self.shape.worldPosition
						target = nil
					end
				else
					self:set_sv_Animation( "idle" )
					self.TargetPosition = self.shape.worldPosition
				end
			else
				if self.attackSleeper <= 0 then
					self.attackSleeper = self.AttackRate
					self:set_sv_Animation( "attack01" )
					if distance <= self.AttackRange then
						sm.event.sendToPlayer( target, "sv_e_receiveDamage", { target, damage = self.Damage }   )
					end
					self:sv_doSound( "Farmbot - Attack01" )
				else
					if self.attackSleeper <= 0 then
						self:set_sv_Animation( "idle" )
						self.attackSleeper = 0
					end
				end		
			end
		else
			if distance < 9 then
				if self.idleSleeper <= 0 then
					self.TargetPosition = self.spawnPosition + ( sm.vec3.normalize( sm.vec3.new( ( math.random( 0, 1 ) * 2 ) - 1, ( math.random( 0, 1 ) * 2 ) - 1, 0 ) ) * math.random( 4, 20 ) )
					self.idleSleeper =  math.random( 5, self.RoomingRange )
				else
					self.idleSleeper = self.idleSleeper - dt
					self.TargetPosition = self.shape.worldPosition
				end
				self:set_sv_Animation( "idle" )
			else
				if self.idleSleeper <= 0 then
					self.TargetPosition = self.spawnPosition + ( sm.vec3.normalize( sm.vec3.new( ( math.random( 0, 1 ) * 2 ) - 1, ( math.random( 0, 1 ) * 2 ) - 1, 0 ) ) * math.random( 4, 20 ) )
					self.idleSleeper =  math.random( 5, self.RoomingRange )
				else
					self.idleSleeper = self.idleSleeper - dt
				end
				self:set_sv_Animation( "walk" )
			end
		end
		if self.TargetPosition ~= nil and self.TargetPosition ~= self.shape.worldPosition then
			self:MoveTo( self.TargetPosition, dt )
			self:TurnTo( self.TargetPosition, dt )
		end
	else
	
	end
		
	self:DestroyTimer( dt )
	self:LifeTimeDeleter( dt ) 
end 

function Fant_Straw_Dog.MoveTo( self, targetPos, dt )
	if self.destroy then
		return
	end
	if sm.vec3.length( targetPos - self.shape.worldPosition ) < 0.01 then
		return
	end
	targetPos.z = self.shape.worldPosition.z
	local direction = sm.vec3.normalize( targetPos - self.shape.worldPosition )
	if direction == sm.vec3.new( 0, 0, 0 ) then
		direction = sm.shape.getUp( self.shape )
	end
	sm.physics.applyImpulse( sm.shape.getBody( self.shape ), ( direction * AnimationTable[ self.sv_activeAnimation ].movespeed ), true, nil )
end

function Fant_Straw_Dog.TurnTo( self, targetPos, dt )
	if self.destroy then
		return
	end
	targetPos.z = self.shape.worldPosition.z
	local direction = self.shape:transformPoint( targetPos )
	if direction == sm.vec3.new( 0, 0, 0 ) then
		direction = sm.shape.getUp( self.shape )
	end
	sm.physics.applyTorque( sm.shape.getBody( self.shape ), sm.vec3.new( 0, 0, sm.vec3.normalize( direction ).x * 10000 ) * dt, true )
end

function Fant_Straw_Dog.BodyMovement( self, dt )
	if self.destroy then
		return
	end
	local body = sm.shape.getBody( self.shape )
	local DownDirection = sm.vec3.new( 0, 0, -1 )
	local Force = -sm.body.getVelocity( body ) * 100
	Force = Force + sm.vec3.new( 0, 0, ( AnimationTable[ self.sv_activeAnimation ].height - self:getDistance( self.shape.worldPosition, DownDirection ) ) * 250 )
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

function Fant_Straw_Dog.getDistance( self, StartPos, Direction )
	local Valid, Result = sm.physics.raycast( StartPos, StartPos + ( Direction * 100), self.shape )
	if Valid then
		return sm.vec3.length( StartPos - Result.pointWorld )
	end
	return 0
end

function Fant_Straw_Dog.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	--print( "Fant_Straw_Dog.server_onProjectile" )
	self:sv_takeDamage( attacker, damage, hitPos )
end

function Fant_Straw_Dog.server_onMelee( self, hitPos, attacker, damage )
	--print( "Fant_Straw_Dog.server_onMelee" )
	self.attackSleeper = math.random( 0.2, 0.4 )
	self:sv_takeDamage( attacker, damage, hitPos )
	GetMeleeHit( self, attacker )
end

function Fant_Straw_Dog.server_onExplosion( self, position, destructionLevel )
	--print( "Fant_Straw_Dog.server_onExplosion" )
	self:sv_takeDamage( nil, 50, position )
end

function Fant_Straw_Dog.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal  ) 
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
	local damage2 = 0
	if type( other ) == "Shape" then
		if not sm.exists( other ) then
			return
		end
		if other == self.shape then
			return
		end
		
		local shapeUUID = sm.shape.getShapeUuid( other )
		if shapeUUID == obj_powertools_sawblade or shapeUUID == obj_powertools_fant_drill or shapeUUID == obj_powertools_fant_drill_small or shapeUUID == obj_powertools_fant_drill_large   or shapeUUID == obj_powertools_fant_autominer_farmbot_drill then
			local angularVelocity = other.body.angularVelocity
			if angularVelocity:length() > 0.001 then
				damage2 = 2.5
				if shapeUUID == obj_powertools_fant_autominer_farmbot_drill then
					damage2 = damage2 * 2
				end
			end
			
		end
		
	end
	print(damage2 )
	
	local ImpactVel = sm.vec3.length( selfPointVelocity + otherPointVelocity )
	local damage = 15 + ( ImpactVel / 10 )
	if ImpactVel < 15 then 
		damage = 0
	end
	self.impactCooldownTicks = 0.5
	
	if damage + damage2 > 0 then		
		self:sv_takeDamage( other, damage + damage2 )
	end
end

function Fant_Straw_Dog.sv_takeDamage( self, attacker, damage, pos )
	if self.destroy then
		return
	end
	if damage <= 0 then
		return
	end
	self.TargetPosition = self.shape.worldPosition
	
	if attacker ~= nil then
		--print( type(attacker) )
		if type(attacker) == "Player" then
			self.TargetPosition = attacker.character.worldPosition
			self.aggrotimer = 5
		end
		if type(attacker) == "Shape" then
			self.TargetPosition = attacker.worldPosition
			self.aggrotimer = 5
		end
	else
		self.TargetPosition = pos
	end
	--print( "Straw Dog took damage: "..tostring( self.currentHealth ) )
	self.currentHealth = self.currentHealth - damage
	if self.currentHealth < 0 then
		self.currentHealth = 0
	end
	if self.currentHealth == 0 then
		self:Die()
		-- 00Fant
		if type( attacker ) == "Player" then
			sm.event.sendToPlayer( attacker, "sv_addRobotKill", { attacker = attacker, typeName = "strawdog" } )
		end
		-- 00Fant
	else
		self.network:sendToClients( "cl_setHealth", self.currentHealth )
		self:sv_doSound( "Farmbot - Angry" )
	end
	
	-- 00Fant
	Fant_RobotDetector_Add_Unit( ( self.ID + 200 ), { shape = self.shape,  health = self.currentHealth, maxhealth = self.MaximalHealth } )
	-- 00Fant
end

function Fant_Straw_Dog.cl_setHealth( self, health )
	self.currentHealth = health
end

function Fant_Straw_Dog.Die( self )
	if self.destroy == false then
		self:DropLoot()
		self:DropLoot()
		self.destroy = true
		self:set_sv_Animation( "death01" )
		self.network:sendToClients( "PlayDeathEffect" )
		self:sv_spawnParts()
		self:sv_doSound( "Haybot - Destroyed" )
	end
end

function Fant_Straw_Dog.DropLoot( self )
	local Loot = LootTable[ math.floor( math.random( 1, #LootTable  ) ) ]
	local amount = math.floor( math.random( Loot[2][1], Loot[2][2] ) )
	local params = { lootUid = Loot[1], lootQuantity = amount, epic = false }
	sm.projectile.shapeCustomProjectileAttack( params, "loot", 0, sm.vec3.new( 0, 0, 0 ), sm.vec3.new( 0, -5, 0 ), self.shape, 0 )			
end

function Fant_Straw_Dog.PlayDeathEffect( self )
	sm.effect.playEffect( "Part - Electricity", self.shape.worldPosition, sm.vec3.new( 0, 0, 0 ), sm.quat.identity() )
end

function Fant_Straw_Dog.DestroyTimer( self, dt )
	if self.destroy then
		if self.destroyTimer > 0 then
			self.destroyTimer = self.destroyTimer - dt
			if self.destroyTimer <= 0 then
				sm.shape.destroyShape( self.shape, 0 )
			end
		end
	end
end

function Fant_Straw_Dog.set_sv_Animation( self, animation )
	if self.destroy then
		return
	end
	if self.sv_activeAnimation ~= animation then
		self.sv_activeAnimation = animation
		if animation == "attack" then
			self.cl_animationTimer = 0
		end
		self.network:sendToClients( "set_cl_Animation", self.sv_activeAnimation )
	end
end

function Fant_Straw_Dog.set_cl_Animation( self, animation )
	if self.destroy then
		return
	end
	if animation == "attack" then
		self.cl_animationTimer = 0
	end
	self.cl_activeAnimation = animation
	--print( animation )
end

function Fant_Straw_Dog.client_onUpdate( self, dt )
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
		--self.cl_animationTimer = 0
		self.cl_lastAnimation = self.cl_activeAnimation
	end
	self.cl_animationTimer = self.cl_animationTimer + ( dt * AnimationTable[ self.cl_lastAnimation ].animationspeed )
	
	local doWalkSound = false
	if self.cl_animationTimer > 1 and self.currentHealth > 0 then
		self.cl_animationTimer = 0
		self.HalfAnimationDone = false
		doWalkSound = true
	end
	if self.cl_animationTimer > 0.5 and self.HalfAnimationDone == false then
		self.HalfAnimationDone = true
		doWalkSound = true
	end
	
	if doWalkSound then
		if self.cl_activeAnimation == "run" then
			self:cl_doSound( "Farmbot - SprintBody" )			
		end
		if self.cl_activeAnimation == "walk" then
			self:cl_doSound( "Farmbot - RunBody" )
		end
	end
	
	if self.cl_activeAnimation ~= "" then
		self.interactable:setAnimProgress( self.cl_activeAnimation, self.cl_animationTimer )
	end
end

function Fant_Straw_Dog.server_onDestroy( self )
	self.sv = {}
	self.sv.storage = {  } 
	self.storage:save( self.sv.storage )
	
	g_strawdogs[ self.ID ] = nil
	local newList = {}
	for i, strawdog in pairs( g_strawdogs ) do	
		if strawdog ~= nil and sm.exists( strawdog ) then
			table.insert( newList, strawdog )
		end
	end
	g_strawdogs = newList
	print("Strawdog Amount: " ..  tostring( #g_strawdogs ) )
end

function Fant_Straw_Dog.client_onDestroy( self )

end

function Fant_Straw_Dog.sv_spawnParts( self )
	self:sv_lazyPartSpawn( fant_straw_dog_body, sm.vec3.new( 0, 1, 0 ) )
	self:sv_lazyPartSpawn( fant_straw_dog_eye, ( sm.shape.getUp( self.shape ) * 1 ) + ( sm.shape.getAt( self.shape ) * 1 ) )
	self:sv_lazyPartSpawn( fant_straw_dog_head, ( sm.shape.getUp( self.shape ) * 1.25 ) + ( sm.shape.getAt( self.shape ) * 0 ) )
	self:sv_lazyPartSpawn( fant_straw_dog_jaw, ( sm.shape.getUp( self.shape ) * 1.5 ) + ( sm.shape.getAt( self.shape ) * 0 ) )
	self:sv_lazyPartSpawn( fant_straw_dog_left_feet, ( sm.shape.getUp( self.shape ) * 1 ) + ( sm.shape.getRight( self.shape ) * 1 ) )
	self:sv_lazyPartSpawn( fant_straw_dog_left_leg, ( sm.shape.getUp( self.shape ) * 1 ) + ( sm.shape.getRight( self.shape ) * 1 ) )
	self:sv_lazyPartSpawn( fant_straw_dog_right_feet, ( sm.shape.getUp( self.shape ) * 1 ) + ( sm.shape.getRight( self.shape ) * -1 ) )
	self:sv_lazyPartSpawn( fant_straw_dog_right_leg, ( sm.shape.getUp( self.shape ) * 1 ) + ( sm.shape.getRight( self.shape ) * -1 ) )
	self:sv_lazyPartSpawn( fant_straw_dog_tail, ( sm.shape.getUp( self.shape ) * -1 ) + ( sm.shape.getAt( self.shape ) * 0 ) )
end

function Fant_Straw_Dog.sv_lazyPartSpawn( self, partUUID, offset )
	if partUUID == nil then
		return
	end
	local impact = sm.vec3.new( 0, 1, 0 ) + offset
	local bodyPos = self.shape.worldPosition

	local part = sm.shape.createPart( partUUID, bodyPos + offset, sm.quat.identity(), true, true )
	sm.physics.applyImpulse( part, impact, true )
end

function Fant_Straw_Dog.sv_doSound( self, name )
	if self.destroy then
		return
	end
	if self.SoundDelay <= 0 then
		self.network:sendToClients( "cl_doSound", name )
	end
	self.SoundDelay = 0.5
end

function Fant_Straw_Dog.cl_doSound( self, name )
	if self.destroy then
		return
	end
	sm.effect.playEffect( name, self.shape.worldPosition, nil, nil )
end

function Fant_Straw_Dog.LifeTimeDeleter( self, dt )
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
	if self.LifeTime > 0 and MinimalDistanceToPlayer > SpawnDistance / 2 then
		self.LifeTime = self.LifeTime - dt
		--print( "Strawdog Lifetime: " .. tostring(self.LifeTime) )
	end
	if self.LifeTime <= 0 then
		sm.shape.destroyShape( self.shape, 0 )
		print( "Strawdog Lifetime Deleter!" )
	end
end
