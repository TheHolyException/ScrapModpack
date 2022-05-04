dofile "$SURVIVAL_DATA/Scripts/game/units/unit_util.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile( "$SURVIVAL_DATA/Scripts/game/util/Timer.lua" )
dofile "$SURVIVAL_DATA/Scripts/game/units/states/PathingState.lua"


dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_tesla_coil.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survivalPlayer.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_ElectroHammer/Fant_ElectroHammer.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_flamethrower.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_robotdetector.lua"

local Maximal_Wocs = 50
g_BabyWocs = g_BabyWocs or {}

BabyWocUnit = class( nil )

local RoamStartTimeMin = 40 * 10 -- 10 seconds
local RoamStartTimeMax = 40 * 25 -- 25 seconds
local FleeTimeMin = 40 * 14 -- 14 seconds
local FleeTimeMax = 40 * 20 -- 20 seconds
local EdibleSearchRadius = 6.0
local EdibleReach = 1.75
local CornPerMilk = 3

local GrowTime = 600


function BabyWocUnit.server_onCreate( self )

	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	if self.saved.stats == nil then
		self.saved.stats = { hp = 75, maxhp = 75, cornEaten = 0, growtime = GrowTime }
	end

	if self.params then
		if self.params.tetherPoint then
			self.homePosition = self.params.tetherPoint + sm.vec3.new( 0, 0, self.unit.character:getHeight() * 0.5 )
		end
		if self.params.deathTick then
			self.saved.deathTickTimestamp = self.params.deathTick
		end
		if self.params.color then
			self.saved.color = self.params.color
		end
	end
	if not self.homePosition then
		self.homePosition = self.unit.character.worldPosition
	end
	if not self.saved.deathTickTimestamp then
		self.saved.deathTickTimestamp = sm.game.getCurrentTick() + DaysInTicks( 30 )
	end
	self.storage:save( self.saved )

	if self.saved.color then
		self.unit.character:setColor( self.saved.color )
	end
	
	self.unit:setWhiskerData( 3, 60 * math.pi / 180, 1.5, 5.0 )
	self.impactCooldownTicks = 0

	-- Idle
	self.idleState = self.unit:createState( "idle" )
	self.idleState.randomEvents = { { name = "eat", chance = 0.2, interruptible = false, time = 4 },
							   		{ name = "moo", chance = 0.4 } }
	self.idleState.debugName = "idleState"

	-- Roam
	self.roamTimer = Timer()
	self.roamTimer:start( math.random( RoamStartTimeMin, RoamStartTimeMax ) )
	self.roamState = self.unit:createState( "flockingRoam" )
	self.roamState.tetherPosition = self.homePosition
	self.roamState.roamCenterOffset = 0.0
	
	-- Flee
	self.fleeState = self.unit:createState( "flee" )
	self.fleeState.movementAngleThreshold = math.rad( 180 )
	
	-- Pathing
	self.pathingState = PathingState()
	self.pathingState:sv_onCreate( self.unit )
	self.pathingState:sv_setTolerance( EdibleReach )
	self.pathingState:sv_setMovementType( "walk" )
	self.pathingState:sv_setWaterAvoidance( false )
	self.pathingState:sv_setWhiskerAvoidance( false )
	self.pathingState.debugName = "pathingState"

	-- Eat
	self.eatEventState = self.unit:createState( "wait" )
	self.eatEventState.debugName = "eatEventState"
	self.eatEventState.time = 4.0
	self.eatEventState.interruptible = false
	self.eatEventState.name = "eat"

	-- Tumble
	initTumble( self )
	
	-- Crushing
	initCrushing( self, DEFAULT_CRUSH_TICK_TIME )
	
	self.currentState = self.idleState
	self.currentState:start()
	
	
	g_BabyWocs[ self.unit:getId() ] = self.unit
	Fant_RobotDetector_Add_Unit( self.unit:getId(), { character = self.unit:getCharacter(),  health = self.saved.stats.hp, maxhealth = self.saved.stats.maxhp } )

end

function BabyWocUnit.server_onRefresh( self )
	print( "-- BabyWocUnit.refreshed --" )
end

function BabyWocUnit.server_onDestroy( self )
	print( "-- BabyWocUnit.terminated --" )
	g_BabyWocs[ self.unit:getId() ] = nil
end

function BabyWocUnit.Grow( self, dt )
	if self.saved.stats.growtime > 0 then
		self.saved.stats.growtime = self.saved.stats.growtime - dt
	else
		if not self.destroyed then
			self.saved.stats.hp = 0
			self.unit:destroy()
			self.destroyed = true
			
			local yaw = 0
			local spawnOffset = sm.vec3.new( 0, 0, -0.5 )
			sm.unit.createUnit( unit_woc, self.unit.character.worldPosition + spawnOffset, yaw, { color = self.saved.color } )
			
		end
	end
end

function BabyWocUnit.server_onFixedUpdate( self, dt )
	self:Grow( dt )
	ProcessTeslaDamage( self, false )
	FlamethrowerDamage( self, dt )
	
	if sm.exists( self.unit ) and not self.destroyed then
		if self.populationCheckTimer == nil then
			self.populationCheckTimer = 0
		end
		self.populationCheckTimer = self.populationCheckTimer - dt
		if self.populationCheckTimer <= 0 then
			self.populationCheckTimer = 10			
			local wocAmount = 0
			for i, bwoc in pairs( g_Wocs ) do 
				if sm.exists( bwoc) then
					wocAmount = wocAmount + 1
				end
				if wocAmount > Maximal_Wocs then
					self.unit:destroy()
					self.destroyed = true
					return
				end
			end
		end
	end
	
	-- if sm.exists( self.unit ) and not self.destroyed then
		-- if self.saved.deathTickTimestamp and sm.game.getCurrentTick() >= self.saved.deathTickTimestamp then
			-- self.unit:destroy()
			-- self.destroyed = true
			-- return
		-- end
	-- end
	
	

	if self.unit.character:isSwimming() then
		self.roamState.cliffAvoidance = false
		self.pathingState:sv_setCliffAvoidance( false )
	else
		self.roamState.cliffAvoidance = true
		self.pathingState:sv_setCliffAvoidance( true )
	end

	if updateCrushing( self ) then
		print("'BabyWocUnit. was crushed!")
		self:sv_takeDamage( self.saved.stats.maxhp )
	end
	
	updateTumble( self )
	updateAirTumble( self, self.idleState )

	if self.currentState then
		self.currentState:onFixedUpdate( dt )
		self.unit:setMovementDirection( self.currentState:getMovementDirection() )
		self.unit:setMovementType( self.currentState:getMovementType() )
		self.unit:setFacingDirection( self.currentState:getFacingDirection() )
		
		-- Random roaming during idle
		if self.currentState == self.idleState then
			self.roamTimer:tick()
		end
		self.impactCooldownTicks = math.max( self.impactCooldownTicks - 1, 0 )
	end

	if self.saved.stats.cornEaten >= CornPerMilk then
		self.saved.stats.cornEaten = self.saved.stats.cornEaten - CornPerMilk
		self.saved.stats.hp = self.saved.stats.maxhp
		self.saved.deathTickTimestamp = sm.game.getCurrentTick() + DaysInTicks( 30 ) -- Neglected Wocs die after 30 days
		if SurvivalGame then
			local loot = SelectLoot( "loot_woc_milk" )
			SpawnLoot( self.unit, loot )
		end
		self.storage:save( self.saved )
	end
	
	
end

function BabyWocUnit.server_onUnitUpdate( self, dt )
	
	if not sm.exists( self.unit ) then
		return
	end

	if self.currentState then
		self.currentState:onUnitUpdate( dt )
	end

	if self.unit.character:isTumbling() then
		return
	end

	-- Find corn
	local targetCorn, cornInRange = FindNearbyEdible( self.unit.character, obj_resource_corn, EdibleSearchRadius, EdibleReach )

	local prevState = self.currentState
	local done, result = self.currentState:isDone()
	local abortState = 	(
							( self.fleeFrom ) or
							( ( self.currentState == self.pathingState or self.currentState == self.roamState ) and cornInRange )
						)

	if ( done or abortState ) then
		-- Select state
		if self.fleeFrom then
			self:sv_flee( self.fleeFrom )
			prevState = self.currentState
			self.fleeFrom = nil
		elseif self.currentState == self.fleeState or self.currentState == self.eatEventState then
			self.currentState = self.idleState
		elseif self.roamTimer:done() and not ( self.currentState == self.idleState and result == "started" ) then
			self.roamTimer:start( math.random( RoamStartTimeMin, RoamStartTimeMax ) )
			self.currentState = self.roamState
		elseif not ( self.currentState == self.roamState and result == "roaming" ) then
			self.currentState = self.idleState
		end
	end

	if prevState ~= self.currentState then
		prevState:stop()
		self.currentState:start()
		if DEBUG_AI_STATES then
			print( self.currentState.debugName )
		end
	end
end

function BabyWocUnit.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	if not sm.exists( self.unit ) or not sm.exists( attacker ) then
		return
	end
	if damage > 0 then
		if self.fleeFrom == nil then
			self.fleeFrom = attacker
			self.unit:sendCharacterEvent( "hit" )
		end
	end
	if projectileName == "water" then
		ExtinguishFire( self )
	end
	self:sv_takeDamage( damage )
end

function BabyWocUnit.server_onMelee( self, hitPos, attacker, damage, power )
	if not sm.exists( self.unit ) or not sm.exists( attacker ) then
		return
	end
	local attackingCharacter = attacker:getCharacter()
	GetMeleeHit( self, attacker )
	
	if self.fleeFrom == nil then
		self.fleeFrom = attacker
		self.unit:sendCharacterEvent( "hit" )
	end

	--startTumble( self, SMALL_TUMBLE_TICK_TIME, self.idleState )
	self:sv_takeDamage( damage )
	local attackDirection = ( hitPos - attackingCharacter.worldPosition ):normalize()
	ApplyKnockback( self.unit.character, attackDirection, power )
end

function BabyWocUnit.server_onExplosion( self, center, destructionLevel )
	if not sm.exists( self.unit ) then
		return
	end
	if self.fleeFrom == nil then
		self.fleeFrom = center
		self.unit:sendCharacterEvent( "hit" )
	end
	self:sv_takeDamage( self.saved.stats.maxhp * ( destructionLevel / 10 ) )
end

function BabyWocUnit.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
	if not sm.exists( self.unit ) then
		return
	end

	if self.impactCooldownTicks > 0 then
		return
	end

	local damage, tumbleTicks, tumbleVelocity, impactReaction = CharacterCollision( self.unit.character, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal, self.saved.stats.maxhp )
	if damage > 0 or tumbleTicks > 0 then
		self.impactCooldownTicks = 6
	end
	if damage > 0 then
		print("'BabyWocUnit. took", damage, "collision damage")
		self:sv_takeDamage( damage )
	end
	if tumbleTicks > 0 then
		-- if startTumble( self, tumbleTicks, self.idleState, tumbleVelocity ) then
			-- if type( other ) == "Shape" and sm.exists( other ) and other.body:isDynamic() then
				-- sm.physics.applyImpulse( other.body, impactReaction * other.body.mass, true, collisionPosition - other.body.worldPosition )
			-- end
		-- end
	end
end

function BabyWocUnit.server_onCollisionCrush( self )
	if not sm.exists( self.unit ) then
		return
	end
	onCrush( self )
end

function BabyWocUnit.sv_flee( self, from )
	self.currentState:stop()
	self.currentState = self.fleeState
	self.fleeState.fleeFrom = from
	self.fleeState.maxFleeTime = math.random( FleeTimeMin, FleeTimeMax ) / 40
	self.fleeState.maxDeviation = 45 * math.pi / 180
	self.currentState:start()
end



function BabyWocUnit.sv_takeFireDamage( self, damage )
	if self.saved.stats.hp > 0 then
		self.saved.stats.hp = self.saved.stats.hp - damage
		self.saved.stats.hp = math.max( self.saved.stats.hp, 0 )
		print( "'BabyWocUnit. received:", damage, "damage.", self.saved.stats.hp, "/", self.saved.stats.maxhp, "HP" )

		if self.saved.stats.hp <= 0 then
			self:sv_onFireDeath()
			sm.effect.playEffect( "Woc - Destruct", self.unit.character.worldPosition )
		else
			self.storage:save( self.saved )
			sm.effect.playEffect( "Woc - Panic", self.unit.character.worldPosition )
		end
		
		-- 00Fant
		Fant_RobotDetector_Add_Unit( self.unit:getId(), { character = self.unit:getCharacter(),  health = self.saved.stats.hp, maxhealth = self.saved.stats.maxhp } )
		-- 00Fant
	end
end

function BabyWocUnit.sv_onFireDeath( self )
	local character = self.unit:getCharacter()
	if not self.destroyed then
		self.saved.stats.hp = 0
		self.unit:destroy()
		
		self.destroyed = true
	end
end

function BabyWocUnit.sv_takeDamage( self, damage )
	if self.saved.stats.hp > 0 then
		self.saved.stats.hp = self.saved.stats.hp - damage
		self.saved.stats.hp = math.max( self.saved.stats.hp, 0 )
		print( "'BabyWocUnit. received:", damage, "damage.", self.saved.stats.hp, "/", self.saved.stats.maxhp, "HP" )

		if self.saved.stats.hp <= 0 then
			self:sv_onDeath()
			sm.effect.playEffect( "Woc - Destruct", self.unit.character.worldPosition )
		else
			self.storage:save( self.saved )
			sm.effect.playEffect( "Woc - Panic", self.unit.character.worldPosition )
		end
	end
end

function BabyWocUnit.sv_onDeath( self )
	local character = self.unit:getCharacter()
	if not self.destroyed then
		self.saved.stats.hp = 0
		self.unit:destroy()		
		self.destroyed = true
	end
end

function BabyWocUnit.sv_e_onEnterWater( self )
	ExtinguishFire( self )
end

function BabyWocUnit.sv_e_onStayWater( self ) end

function BabyWocUnit.server_onCharacterChangedColor( self, color )
	if self.saved.color ~= color then
		self.saved.color = color
		self.storage:save( self.saved )
	end
end
