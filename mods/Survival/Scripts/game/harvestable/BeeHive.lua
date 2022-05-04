dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")
dofile "$SURVIVAL_DATA/Objects/00fant/character/fant_beebot/fant_beebot.lua"

BeeHive = class()

function BeeHive.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	self:sv_onHit( attacker )
end

function BeeHive.server_onMelee( self, hitPos, attacker, damage )
	self:sv_onHit( attacker )
end

function BeeHive.server_onExplosion( self, center, destructionLevel )
	self:sv_onHit()
end

function BeeHive.sv_onHit( self, attacker )
	if not self.destroyed and sm.exists( self.harvestable ) then

		if SurvivalGame then
			local lootList = {}
			local slots = math.random( 2, 4 )
			for i = 1, slots do
				lootList[i] = { uuid = obj_resource_beewax, quantity = self:getGatherAmount( attacker, 1 ) }
			end
			SpawnLoot( self.harvestable, lootList )
		end

		sm.effect.playEffect( "beehive - destruct", self.harvestable.worldPosition, nil, self.harvestable.worldRotation )
		sm.harvestable.create( hvs_farmables_beehive_broken, self.harvestable.worldPosition, self.harvestable.worldRotation )
		
		self.harvestable:destroy()
		self.destroyed = true
	end
end
function BeeHive.client_onCreate( self )
	self.cl = {}
	self.cl.swarmEffect = sm.effect.createEffect( "beehive - beeswarm" )
	self.cl.swarmEffect:setPosition( self.harvestable.worldPosition )
	self.cl.swarmEffect:setRotation( self.harvestable.worldRotation )
	self.cl.swarmEffect:start()
end

function BeeHive.client_onDestroy( self )
	self.cl.swarmEffect:stop()
	self.cl.swarmEffect:destroy()
end


-- 00Fant

local MaximalBeesInRenderDistance = 10

function BeeHive.server_onCreate( self )
	local canspawn = true
	for i, Beebot in pairs( g_Beebots ) do	
		if Beebot ~= nil and sm.exists( Beebot ) then
			if sm.vec3.length( Beebot.worldPosition - self.harvestable.worldPosition ) < SpawnDistance then
				canspawn = false
			end
		end
	end
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { hasBee = math.random( 0, 100 ), spawntimer = 0 }
	end
	
	local beebotCount = 0
	for i, k in pairs( g_Beebots ) do
		if k ~= nil then
			beebotCount = beebotCount + 1
		end
	end
	--print( "beebotCount:", beebotCount )
	if canspawn then
		if self.saved.hasBee > 90  and beebotCount < MaximalBeesInRenderDistance and self.saved.spawntimer <= 0 then
			sm.shape.createPart( fant_beebot, self.harvestable.worldPosition + sm.vec3.new( 0, 0, 2 ), sm.quat.identity(), true, true ) 
			self.saved.spawntimer = 1200
		end
	end
	self.storage:save( self.saved )
end

function BeeHive.server_onFixedUpdate( self, dt )
	if self.saved.spawntimer > 0 then
		self.saved.spawntimer = self.saved.spawntimer - dt
		if self.saved.spawntimer <= 0 then
			self.storage:save( self.saved )
		end
	end
end


function BeeHive.getGatherAmount( self, player, startValue )
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
