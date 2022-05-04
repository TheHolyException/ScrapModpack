-- OilGeyser.lua --
dofile "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua"

OilGeyser = class( nil )


-- 00Fant

function OilGeyser.server_onCreate( self )	
	local respawn = false
	local data = self.harvestable:getPublicData()
	if data then
		if data.respawn then
			respawn = true
		end
	end
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil and not respawn then
		if math.random( 0, 100 ) > 50 then
			local stones = {
				hvs_stone_small01,
				hvs_stone_small02,
				hvs_stone_small03,
				hvs_stone_medium01,
				hvs_stone_medium02,
				hvs_stone_medium03,
				hvs_stone_large01,
				hvs_stone_large02,
				hvs_stone_large03
			}
		
			sm.harvestable.create( stones[ math.random( 1, #stones ) ], self.harvestable.worldPosition, self.harvestable.worldRotation )
			sm.harvestable.destroy( self.harvestable )
		end
		
	end
	self.sv.storage = { isStone = true } 
	self.storage:save( self.sv.storage )
end
-- 00Fant


function OilGeyser.client_onInteract( self, state )
	self.network:sendToServer( "sv_n_harvest" )
end

function OilGeyser.client_canInteract( self )
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Attack" ), "#{INTERACTION_PICK_UP}" )
	return true
end

function OilGeyser.server_canErase( self ) return true end
function OilGeyser.client_canErase( self ) return true end

function OilGeyser.server_onRemoved( self, player )
	self:sv_n_harvest( nil, player )
end

function OilGeyser.client_onCreate( self )
	self.cl = {}
	self.cl.acitveGeyser = sm.effect.createEffect( "Oilgeyser - OilgeyserLoop" )
	self.cl.acitveGeyser:setPosition( self.harvestable.worldPosition )
	self.cl.acitveGeyser:setRotation( self.harvestable.worldRotation )
	self.cl.acitveGeyser:start()
end

function OilGeyser.cl_n_onInventoryFull( self )
	sm.gui.displayAlertText( "#{INFO_INVENTORY_FULL}", 4 )
end

function OilGeyser.sv_n_harvest( self, params, player )
	if not self.harvested and sm.exists( self.harvestable ) then
		if SurvivalGame then
			local container = player:getInventory()
			local quantity = self:getGatherAmount( player, randomStackAmount( 1, 2, 4 ) )
			if sm.container.beginTransaction() then
				sm.container.collect( container, obj_resource_crudeoil, quantity )
				if sm.container.endTransaction() then
					sm.event.sendToPlayer( player, "sv_e_onLoot", { uuid = obj_resource_crudeoil, quantity = quantity, pos = self.harvestable.worldPosition } )
					sm.effect.playEffect( "Oilgeyser - Picked", self.harvestable.worldPosition )
					sm.harvestable.create( hvs_farmables_growing_oilgeyser, self.harvestable.worldPosition, self.harvestable.worldRotation )
					sm.harvestable.destroy( self.harvestable )
					self.harvested = true
				else
					self.network:sendToClient( player, "cl_n_onInventoryFull" )
				end
			end
		else
			sm.effect.playEffect( "Oilgeyser - Picked", self.harvestable.worldPosition )
			sm.harvestable.create( hvs_farmables_growing_oilgeyser, self.harvestable.worldPosition, self.harvestable.worldRotation )
			sm.harvestable.destroy( self.harvestable )
			self.harvested = true
		end
	end
end

function OilGeyser.client_onDestroy( self )
	self.cl.acitveGeyser:stop()
	self.cl.acitveGeyser:destroy()
end




-- 00Fant

function OilGeyser.getGatherAmount( self, player, startValue )
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
