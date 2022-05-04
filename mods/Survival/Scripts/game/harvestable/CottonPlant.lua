-- CottonPlant.lua --
dofile "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua"

CottonPlant = class( nil )

function CottonPlant.client_onInteract( self, state )
	self.network:sendToServer( "sv_n_harvest" )
end

function CottonPlant.client_canInteract( self )
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Attack" ), "#{INTERACTION_PICK_UP}" )
	return true
end

function CottonPlant.server_onMelee( self, hitPos, attacker, damage )
	if not self.harvested and sm.exists( self.harvestable ) then
		sm.effect.playEffect( "Cotton - Picked", self.harvestable.worldPosition )

		if SurvivalGame then
			local harvest = {
				lootUid = obj_resource_cotton,
				lootQuantity = self:getGatherAmount( attacker, 1 )
			}
			local pos = self.harvestable:getPosition() + sm.vec3.new( 0, 0, 0.5 )
			sm.projectile.harvestableCustomProjectileAttack( harvest, "loot", 0, pos, sm.noise.gunSpread( sm.vec3.new( 0, 0, 1 ), 20 ) * 5, self.harvestable, 0 )
		end
		sm.harvestable.create( hvs_farmables_growing_cottonplant, self.harvestable.worldPosition, self.harvestable.worldRotation )
		sm.harvestable.destroy( self.harvestable )
		self.harvested = true
	end
end

function CottonPlant.server_canErase( self ) return true end
function CottonPlant.client_canErase( self ) return true end

function CottonPlant.server_onRemoved( self, player )
	self:sv_n_harvest( nil, player )
end

function CottonPlant.client_onCreate( self )
	self.cl = {}
	self.cl.cottonfluff = sm.effect.createEffect( "Cotton - Fluff" )
	self.cl.cottonfluff:setPosition( self.harvestable.worldPosition )
	self.cl.cottonfluff:setRotation( self.harvestable.worldRotation )
	self.cl.cottonfluff:start()
end

function CottonPlant.cl_n_onInventoryFull( self )
	sm.gui.displayAlertText( "#{INFO_INVENTORY_FULL}", 4 )
end

function CottonPlant.sv_n_harvest( self, params, player )
	if not self.harvested and sm.exists( self.harvestable ) then
		if SurvivalGame then
			local container = player:getInventory()
			if sm.container.beginTransaction() then
				local amount = self:getGatherAmount( player, 1 )
				sm.container.collect( container, obj_resource_cotton, amount )
				if sm.container.endTransaction() then
					sm.event.sendToPlayer( player, "sv_e_onLoot", { uuid = obj_resource_cotton, pos = self.harvestable.worldPosition } )
					sm.effect.playEffect( "Cotton - Picked", self.harvestable.worldPosition )
					sm.harvestable.create( hvs_farmables_growing_cottonplant, self.harvestable.worldPosition, self.harvestable.worldRotation )
					sm.harvestable.destroy( self.harvestable )
					self.harvested = true
				else
					self.network:sendToClient( player, "cl_n_onInventoryFull" )
				end
			end
		else
			sm.effect.playEffect( "Cotton - Picked", self.harvestable.worldPosition )
			sm.harvestable.create( hvs_farmables_growing_cottonplant, self.harvestable.worldPosition, self.harvestable.worldRotation )
			sm.harvestable.destroy( self.harvestable )
			self.harvested = true
		end
	end
end

function CottonPlant.client_onDestroy( self )
	self.cl.cottonfluff:stop()
	self.cl.cottonfluff:destroy()
end


-- 00Fant

function CottonPlant.getGatherAmount( self, player, startValue )
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
