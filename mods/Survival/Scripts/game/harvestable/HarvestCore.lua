-- HarvestCore.lua --
dofile("$SURVIVAL_DATA/Scripts/game/survival_units.lua")
dofile "$SURVIVAL_DATA/Scripts/game/survivalPlayer.lua"

HarvestCore = class( nil )
HarvestCore.resetStateOnInteract = false

local RefineStaminaCost = 10
local RefineTime = 5.2
local RefineBoostValue = 10


dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_unitfacer.lua"


function HarvestCore.server_onCreate( self )
	g_add_Rod( self )
	self:sv_init()
end

function HarvestCore.server_onRefresh( self )
	self:sv_init()
end

function HarvestCore.sv_init( self )
	self.users = {}
end

function HarvestCore.server_onDestroy( self )
	g_remove_Rod( self )
	local activeUsers = {}
	for _, user in ipairs( self.users ) do
		activeUsers[#activeUsers+1] = user
	end
	for _, user in ipairs( activeUsers ) do
		local params = { user = user, state = false }
		self:sv_n_setRefiningState( params )
	end
	self.refinePlayer = nil
end

function HarvestCore.client_onDestroy( self )
	self.client_refining = false
	self.client_refineElapsed = 0.0
	self.client_effect:destroy()
end

function HarvestCore.client_onCreate( self )
	self:cl_init()
	self.refinePlayer = sm.localPlayer.getPlayer()
end

function HarvestCore.client_onRefresh( self )
	self:cl_init()
end

function HarvestCore.cl_init( self )
	self.client_refining = false
	self.client_refineElapsed = 0.0
	
	self.client_effect = sm.effect.createEffect( "Harvestable - Marker", self.interactable )
	self.client_effect:start()
end

function HarvestCore.client_canInteract( self, character )
	if character:getCharacterType() == unit_mechanic then
		return not character:isTumbling()
	end
	return false
end

function HarvestCore.client_onInteract( self, user, state )
	local recipe = g_refineryRecipes[tostring( self.shape.shapeUuid )]
	local player = user:getPlayer()
	if recipe and player then
		if sm.container.canCollect( player:getInventory(), recipe.itemId, recipe.quantity ) then
			self.client_refining = state
			local params = { user = user, state = state }
			self.network:sendToServer( "sv_n_setRefiningState", params )
		else
			sm.gui.displayAlertText( "#{INFO_INVENTORY_FULL}" )
		end
	end
end

function HarvestCore.sv_n_setRefiningState( self, params )
	if params.state == true then
		self.users[#self.users+1] = params.user
	else
		local usersLeft = {}
		for _, user in ipairs( self.users ) do
			if user ~= params.user then
				usersLeft[#usersLeft+1] = user
			end
		end
		self.users = usersLeft
	end
	
	if sm.exists( params.user ) and params.user:getPlayer() ~= nil then
		sm.event.sendToPlayer( params.user:getPlayer(), "sv_e_setRefiningState", params )
	end
end

function HarvestCore.client_onUpdate( self, dt )
	if self.client_refining == true then
		sm.gui.setProgressFraction( self.client_refineElapsed / RefineTime )
		self.client_refineElapsed = self.client_refineElapsed + ( dt * self:RefineBoost() )
		if self.client_refineElapsed >= RefineTime then
			self.client_refining = false
			self.client_refineElapsed = 0.0
			self.network:sendToServer( "sv_refine", sm.localPlayer.getPlayer() )
			sm.effect.playEffect( "Multiknife - Complete", self.shape.worldPosition )
		end
	elseif self.client_refineElapsed > 0.0 then
		self.client_refineElapsed = math.max( self.client_refineElapsed -  0.25 * ( RefineTime - self.client_refineElapsed ) * dt, 0 )
	else
		self.client_refineElapsed = 0.0
	end
end

function HarvestCore.sv_refine( self, player )
	
	if sm.exists( self.shape ) then
		local recipe = g_refineryRecipes[tostring( self.shape.shapeUuid )]
		sm.container.beginTransaction()
		if recipe then
			local quantity = recipe.quantity
			if g_Players ~= nil then
				if g_Players[ player:getId() ].skill_refine ~= nil then
					if g_Players[ player:getId() ].skill_refine > 0 then
						if g_Players[ player:getId() ].skill_refine > math.random( 0, 100 ) then
							quantity = quantity + 10
						end
					end
				end
			end
			sm.container.collect( player:getInventory(), recipe.itemId, quantity )
		end
		if sm.container.endTransaction() then
			self.shape:destroyShape()
			sm.event.sendToPlayer( player, "sv_e_staminaSpend", RefineStaminaCost )
		end
	end
	
end

function HarvestCore.sv_setRefinePlayer( self, refinePlayer )
	self.refinePlayer = refinePlayer
	--self.network:sendToClients( "cl_setRefinePlayer", self.refinePlayer )
end

function HarvestCore.cl_setRefinePlayer( self, refinePlayer )
	self.refinePlayer = refinePlayer
end

function HarvestCore.RefineBoost( self )
	if self.refinePlayer == nil then
		return 1
	end
	local ID = self.refinePlayer:getId()
	if ID then
		if g_Players[ ID ] then
			if g_Players[ ID ].refinebuff then
				if g_Players[ ID ].refinebuff >= 1 then
					return RefineBoostValue
				end
			end
		end
	end
	return 1
end
