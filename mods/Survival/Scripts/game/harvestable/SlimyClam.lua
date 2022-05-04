dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

SlimyClam = class()


function SlimyClam.server_onMelee( self, hitPos, attacker, damage )
	self:sv_onHit( attacker  )
end

function SlimyClam.server_onExplosion( self, center, destructionLevel )
	self:sv_onHit()
end

function SlimyClam.sv_onHit( self, attacker )
	if not self.harvested and sm.exists( self.harvestable ) then
		if SurvivalGame then
			local lootList = {}
			local count = self:getGatherAmount( attacker, randomStackAmountAvg2() )
			for i = 1, count do
				lootList[i] = { uuid = obj_resources_slimyclam }
			end
			SpawnLoot( self.harvestable, lootList, self.harvestable.worldPosition + sm.vec3.new( 0, 0, 0.25 ), math.pi / 36 )
		end

		sm.effect.playEffect("SlimyClam - Destruct", self.harvestable.worldPosition, nil, self.harvestable.worldRotation )
		sm.harvestable.create( hvs_farmables_slimyclam_broken, self.harvestable.worldPosition, self.harvestable.worldRotation )
		sm.harvestable.destroy( self.harvestable )
		self.harvested = true
	end
end

function SlimyClam.client_onCreate( self )
	self.cl = {}
	self.cl.bubbleEffect = sm.effect.createEffect( "SlimyClam - Bubbles" )
	self.cl.bubbleEffect:setPosition( self.harvestable.worldPosition )
	self.cl.bubbleEffect:setRotation( self.harvestable.worldRotation )
	self.cl.bubbleEffect:start()
end

function SlimyClam.client_onDestroy( self )
	self.cl.bubbleEffect:stop()
	self.cl.bubbleEffect:destroy()
end



-- 00Fant

function SlimyClam.getGatherAmount( self, player, startValue )
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
