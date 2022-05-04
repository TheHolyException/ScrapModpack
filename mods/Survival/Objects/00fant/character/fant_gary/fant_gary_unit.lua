dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_robotdetector.lua"
dofile "$SURVIVAL_DATA/Scripts/game/units/unit_util.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"

Fant_Gary_Unit = class( nil )

local EdibleSearchRadius = 5.0
local EdibleReach = 0.75
local EatToDrop = 2
local Eatable_Food = obj_plantables_eggplant

local GaryLootTable = {
	obj_resource_beewax,
	obj_resource_ember,
	obj_resources_slimyclam,
	obj_resource_circuitboard,
	obj_consumable_glue,
	obj_consumable_gas,
	obj_consumable_battery,
	obj_consumable_component,
	obj_consumable_inkammo
}

function Fant_Gary_Unit.server_onCreate( self )
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { health = 100, eaten = 0, isPlaced = false, color = self.unit.character:getColor() }
	end
	if self.params then
		if self.params.color then
			self.saved.color = self.params.color
		end
		if self.params.deathTick then
			self.saved.deathTickTimestamp = self.params.deathTick
		end
		if self.params.isPlaced then
			self.saved.isPlaced = true
		end
	end
	if self.saved.color then
		--print( self.saved.color )
		self.unit.character:setColor( self.saved.color )
	end
	if not self.saved.deathTickTimestamp then
		self.saved.deathTickTimestamp = sm.game.getCurrentTick() + DaysInTicks( 30 )
	end
	self.storage:save( self.saved )
	
	self.destination = self.unit.character.worldPosition
	self.roomTimer = 0
	self.fleeDirection = nil
	self.fleeTimer = 0
	self.eatDelay = 0
	-- 00Fant
		Fant_RobotDetector_Add_Unit( self.unit:getId(), { character = self.unit:getCharacter(),  health = self.saved.health, maxhealth = 100 } )
	-- 00Fant
	self.hasEatable = false
end

function Fant_Gary_Unit.client_onCreate( self )
	--sm.effect.playEffect( "Glowgorp - Hit", self.unit.character.worldPosition )
	sm.effect.playEffect( "Glowgorp - Pickup", self.unit.character.worldPosition )
end

function Fant_Gary_Unit.server_onRefresh( self )
	print( "-- Fant_Gary_Unit refreshed --" )
end

function Fant_Gary_Unit.server_onDestroy( self )
	print( "-- Fant_Gary_Unit terminated --" )
	self.storage:save( self.saved )
end

function Fant_Gary_Unit.server_onFixedUpdate( self, dt )
	if g_units[ self.unit:getId() ] ~= { character = self.unit:getCharacter(),  health = self.saved.health, maxhealth = 100 } then
		g_units[ self.unit:getId() ] = { character = self.unit:getCharacter(),  health = self.saved.health, maxhealth = 100 }
	end
	
	if sm.exists( self.unit ) and not self.destroyed then
		if self.saved.deathTickTimestamp and sm.game.getCurrentTick() >= self.saved.deathTickTimestamp then
			self.unit:destroy()
			self.destroyed = true
			return
		end
	end
	
	if self.fleeTimer > 0 then
		self.fleeTimer = self.fleeTimer - dt
		if self.fleeDirection ~= nil and self.fleeDirection ~= sm.vec3.new( 0, 0, 0 ) then
			self.unit:setFacingDirection( self.fleeDirection )
			self.unit:setMovementDirection( self.fleeDirection )
			self.unit:setMovementType( "run" )
		end
		self.destination = self.unit.character.worldPosition
	else
		self.roomTimer = self.roomTimer - dt
		local relativePosition  = self.destination - self.unit.character.worldPosition
		local distance = sm.vec3.length( relativePosition ) / 0.25 

		if self.roomTimer <= 0 or relativePosition == sm.vec3.new( 0, 0, 0 ) then
			self.roomTimer = math.random( 4, 10 )
			local roomDistance = math.random( 6, 15 ) * 0.25
			self.destination = self.unit.character.worldPosition + sm.vec3.new( math.random( -roomDistance, roomDistance ), math.random( -roomDistance, roomDistance ), 0 )
			self.unit:sendCharacterEvent( "eat" )
		end
		if relativePosition ~= sm.vec3.new( 0, 0, 0 ) then
			
			local dir = sm.vec3.normalize( relativePosition )
			
			dir.z = 0
			if dir ~= nil and dir ~= sm.vec3.new( 0, 0, 0 ) then
				self.unit:setFacingDirection( dir )
			end
			self.unit:setMovementDirection( dir * distance )
			if distance > 10 or self.hasEatable then
				if self.eatDelay <= 0 then
					self.unit:setMovementType( "run" )
				else
					self.unit:setMovementType( "stand" )
				end
			else
				self.unit:setMovementType( "stand" )
			end
		end
	end
end

function Fant_Gary_Unit.server_onUnitUpdate( self, dt )
	if self.eatDelay > 0 then
		self.eatDelay = self.eatDelay - dt
		return
	end
	if self.fleeTimer > 0 then
		self.hasEatable = false
		return
	end
	local targetCardboard, cardboardInRange = FindNearbyEdible( self.unit.character, Eatable_Food, EdibleSearchRadius, EdibleReach )
	local targetPosition = nil
	if targetCardboard then
		targetPosition = targetCardboard.worldPosition
		cardboardInRange = ( targetPosition - self.unit.character.worldPosition ):length() <= EdibleReach
		if math.abs( targetPosition.z - self.unit.character.worldPosition.z ) > EdibleReach then
			targetCardboard = nil
			targetPosition = nil
			cardboardInRange = false
		end
	end	
	if targetCardboard and targetPosition then
		self.destination = targetPosition
		self.hasEatable = true
		if cardboardInRange then
			self.eatDelay = 0.5
			sm.shape.destroyShape( targetCardboard )
			self.saved.eaten = self.saved.eaten + 1
			self.unit:sendCharacterEvent( "eat" )
			self.saved.deathTickTimestamp = sm.game.getCurrentTick() + DaysInTicks( 30 )
			
			if self.saved.eaten >= EatToDrop then
				self.saved.eaten = 0
				
				local params = { lootUid = GaryLootTable[ math.random( 1, #GaryLootTable ) ], lootQuantity = 1, epic = false }
				sm.projectile.customProjectileAttack( params, "loot", 0, self.unit.character.worldPosition, sm.vec3.new( 0, 0, 3 ), self.unit, self.unit.character.worldPosition, self.unit.character.worldPosition, 0 )
				
			end
			self.storage:save( self.saved )
			if self.saved.health < 100 then
				self.saved.health = self.saved.health + 10
				if self.saved.health > 100 then
					self.saved.health = 100
				end
				Fant_RobotDetector_Add_Unit( self.unit:getId(), { character = self.unit:getCharacter(), health = self.saved.health, maxhealth = 100 } )
			end
		end
	else
		self.hasEatable = false
	end
end

-- function Fant_Gary_Unit.server_onUnitUpdate( self, dt )
	-- if self.eatDelay > 0 then
		-- self.eatDelay = self.eatDelay - dt
		-- return
	-- end
	-- if self.fleeTimer > 0 then
		-- self.hasEatable = false
		-- return
	-- end
	-- local targetCardboard, cardboardInRange = FindNearbyEdible( self.unit.character, Eatable_Food, EdibleSearchRadius, EdibleReach )
	-- local targetPosition = nil
	-- local targetLocalPosition = nil
	-- if targetCardboard then
		-- targetLocalPosition = targetCardboard:getClosestBlockLocalPosition( self.unit.character.worldPosition )
		-- targetPosition = targetCardboard.body:transformPoint( ( targetLocalPosition + sm.vec3.new( 0.5, 0.5, 0.5 ) ) * 0.25 )
		-- cardboardInRange = ( targetPosition - self.unit.character.worldPosition ):length() <= EdibleReach
		-- if math.abs( targetPosition.z - self.unit.character.worldPosition.z ) > EdibleReach then
			-- targetCardboard = nil
			-- targetPosition = nil
			-- targetLocalPosition = nil
			-- cardboardInRange = false
		-- end
	-- end	
	-- if targetCardboard and targetPosition and targetLocalPosition then
		-- self.destination = targetPosition
		-- self.hasEatable = true
		-- if cardboardInRange then
			-- self.eatDelay = 0.5
			-- targetCardboard:destroyBlock( targetLocalPosition, sm.vec3.new( 1, 1, 1 ) )
			-- self.saved.eaten = self.saved.eaten + 1
			-- if self.saved.eaten >= EatToDrop then
				-- self.saved.eaten = 0
				
				-- local params = { lootUid = GaryLootTable[ math.random( 1, #GaryLootTable + 1 ) ], lootQuantity = 1, epic = false }
				-- sm.projectile.customProjectileAttack( params, "loot", 0, self.unit.character.worldPosition, sm.vec3.new( 0, 0, 3 ), self.unit, self.unit.character.worldPosition, self.unit.character.worldPosition, 0 )
				
			-- end
			-- self.storage:save( self.saved )
			-- if self.saved.health < 100 then
				-- self.saved.health = self.saved.health + 10
				-- if self.saved.health > 100 then
					-- self.saved.health = 100
				-- end
				-- Fant_RobotDetector_Add_Unit( self.unit:getId(), { character = self.unit:getCharacter(), health = self.saved.health, maxhealth = 100 } )
			-- end
		-- end
	-- else
		-- self.hasEatable = false
	-- end
-- end

function Fant_Gary_Unit.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	if not sm.exists( self.unit ) or not sm.exists( attacker ) then
		return
	end
	
	self:sv_takeDamage( damage, attacker )
end

function Fant_Gary_Unit.server_onMelee( self, hitPos, attacker, damage, power )
	if not sm.exists( self.unit ) or not sm.exists( attacker ) then
		return
	end

	self:sv_takeDamage( damage, attacker )
end

function Fant_Gary_Unit.server_onExplosion( self, center, destructionLevel )
	if not sm.exists( self.unit ) then
		return
	end
	self:sv_takeDamage( 100, nil )
end

function Fant_Gary_Unit.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal )
	if not sm.exists( self.unit ) then
		return
	end
	
end

function Fant_Gary_Unit.server_onCollisionCrush( self )
	if not sm.exists( self.unit ) then
		return
	end
end

function Fant_Gary_Unit.sv_takeDamage( self, damage, attacker )
	self.saved.health = self.saved.health - damage
	if attacker ~= nil then
		self.fleeDirection = self.unit.character.worldPosition - attacker.character.worldPosition
		if self.fleeDirection ~= sm.vec3.new( 0, 0, 0 ) then
			self.fleeDirection = sm.vec3.normalize( self.fleeDirection )
		else
			self.fleeDirection = -self.unit.character:getDirection()
		end
		self.fleeTimer = math.random( 4, 10 )
	end
	self.unit:sendCharacterEvent( "hit" )
	-- 00Fant
		Fant_RobotDetector_Add_Unit( self.unit:getId(), { character = self.unit:getCharacter(), health = self.saved.health, maxhealth = 100 } )
	-- 00Fant
	if self.saved.health <= 0 then
		self:sv_onDeath()
	end
end

function Fant_Gary_Unit.sv_onDeath( self )
	self.unit:destroy()
end

function Fant_Gary_Unit.sv_e_onEnterWater( self )

end

function Fant_Gary_Unit.sv_e_onStayWater( self ) end

function Fant_Gary_Unit.server_onCharacterChangedColor( self, color )
	if self.saved.color ~= color then
		self.saved.color = color
		self.storage:save( self.saved )
	end
end
