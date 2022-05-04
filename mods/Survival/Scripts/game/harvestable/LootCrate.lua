dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

LootCrate = class()

function LootCrate.server_onCreate( self )
	self.saved = self.storage:load()
	if self.saved == nil and self.params then
		self.saved = {}
		self.saved.lootTable = self.params.lootTable
		self.storage:save( self.saved )
	end
end

-- 00Fant

function LootCrate.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	self:sv_onHit( sm.vec3.new( 0, 0, 0 ), attacker )
end

-- 00Fant

function LootCrate.server_onMelee( self, hitPos, attacker, damage )
	self:sv_onHit( attacker.character.direction * 5, attacker )
end

function LootCrate.server_onExplosion( self, center, destructionLevel )
	self:sv_onHit()
end

function LootCrate.sv_onHit( self, velocity, attacker )
	if not self.destroyed and sm.exists( self.harvestable ) then
		if self.data.destroyEffect then
			sm.effect.playEffect( self.data.destroyEffect, self.harvestable.worldPosition, nil, self.harvestable.worldRotation, nil, { startVelocity = velocity } )
		end
		if self.data.staticDestroyEffect then
			sm.effect.playEffect( self.data.staticDestroyEffect, self.harvestable.worldPosition, nil, self.harvestable.worldRotation )
		end
		print( self.saved )
		local lootTable = self.saved and self.saved.lootTable or nil
		
		if lootTable == nil then
			lootTable = "loot_crate_standard" --Error fallback
		end
		
		
		-- 00Fant
		local lootList = SelectLoot( lootTable )
		local NewLootList = {}
		for i, k in pairs( lootList ) do
			NewLootList[ i ] = k
			
			if g_Players[ attacker:getId() ].skill_loot > math.random( 0, 100 ) then
				NewLootList[ i ].quantity = NewLootList[ i ].quantity + 1
			else
				NewLootList[ i ].quantity = NewLootList[ i ].quantity
			end
			
		end
		-- 00Fant
		
		SpawnLoot( self.harvestable, NewLootList )

		self.destroyed = true
		self.harvestable:destroy()
	end
end
