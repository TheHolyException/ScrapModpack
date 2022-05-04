dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

CornPlant = class()

function CornPlant.server_onCreate( self )
	self.sv = {}

	local aabbMin, aabbMax = self.harvestable:getAabb()
	local bounds = sm.vec3.new( math.abs( aabbMax.x - aabbMin.x ), math.abs( aabbMax.y - aabbMin.y ), math.abs( aabbMax.z - aabbMin.z ) )
	local centerPos = aabbMin + bounds * 0.5

	self.sv.areaTrigger = sm.areaTrigger.createBox( bounds * 0.5, centerPos, nil, sm.areaTrigger.filter.dynamicBody )
	self.sv.areaTrigger:bindOnEnter( "trigger_onEnter" )
end

function CornPlant.server_onDestroy( self )
	if self.sv.areaTrigger then
		sm.areaTrigger.destroy( self.sv.areaTrigger )
		self.sv.areaTrigger = nil
	end
end

function CornPlant.sv_onHit( self, attacker )
	if not self.destroyed and sm.exists( self.harvestable ) then

		if SurvivalGame then
			local lootList = {}
			local slots = math.random( 3, 4 )
			for i = 1, slots do
				lootList[i] = { uuid = obj_resource_corn, quantity = self:getGatherAmount( attacker, 1 ) }
			end
			SpawnLoot( self.harvestable, lootList, self.harvestable.worldPosition + sm.vec3.new( 0, 0, 1.0 ) )
		end
		
		sm.effect.playEffect( "Corn - Destruct", self.harvestable.worldPosition, nil, self.harvestable.worldRotation )
		sm.harvestable.create( hvs_farmables_growing_cornplant, self.harvestable.worldPosition, self.harvestable.worldRotation )
		
		self.harvestable:destroy()
		self.destroyed = true
	end
end

function CornPlant.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	self:sv_onHit( attacker )
end

function CornPlant.server_onMelee( self, hitPos, attacker, damage )
	self:sv_onHit( attacker )
end

function CornPlant.server_onExplosion( self, center, destructionLevel )
	self:sv_onHit( nil )
end

function CornPlant.trigger_onEnter( self, trigger, results )
	for _, result in ipairs( results ) do
		if sm.exists( result ) then
			if type( result ) == "Body" then
				self:sv_onHit()
				break
			end
		end
	end
end



-- 00Fant

function CornPlant.getGatherAmount( self, player, startValue )
	if g_Players ~= nil and player ~= nil then
		if g_Players[ player:getId() ] ~= nil then
			if g_Players[ player:getId() ].skill_farming ~= nil then
				if g_Players[ player:getId() ].skill_farming > 0 then
					if g_Players[ player:getId() ].skill_farming > math.random( 0, 100 ) then
						return startValue + ( 1 + round( math.random( 0, g_Players[ player:getId() ].skill_farming ) / 20 ) )
					end
				end
			end
		end
	end
	return startValue
end
