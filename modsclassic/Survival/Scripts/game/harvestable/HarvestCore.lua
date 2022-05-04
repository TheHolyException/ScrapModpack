-- HarvestCore.lua --
dofile("$SURVIVAL_DATA/Scripts/game/survival_units.lua")

HarvestCore = class( nil )
HarvestCore.resetStateOnInteract = false

--If you want to change the refine time, modify the stuff below
local scrapWood = 3.5
local wood1 = 4.0
local scrapMetal = 5.0
local metal1 = 6.5
local stone = 5.5
local staminacost = 1.75 --per second of refining
------------------------------------------

local RefineStaminaCost = 10

function HarvestCore.server_onCreate( self )
	self:sv_init()
end

function HarvestCore.server_onRefresh( self )
	self:sv_init()
end

function HarvestCore.sv_init( self )
	self.users = {}
end

function HarvestCore.server_onDestroy( self )
	local activeUsers = {}
	for _, user in ipairs( self.users ) do
		activeUsers[#activeUsers+1] = user
	end
	for _, user in ipairs( activeUsers ) do
		local params = { user = user, state = false }
		self:sv_n_setRefiningState( params )
	end
end

function HarvestCore.client_onDestroy( self )
	self.client_refining = false
	self.client_refineElapsed = 0.0
	self.client_effect:destroy()
end

function HarvestCore.client_onCreate( self )
	self:cl_init()
end

function HarvestCore.client_onRefresh( self )
	self:cl_init()
end

function HarvestCore.cl_init( self ) 
	self.client_refining = false
	self.client_refineTime = 8.0
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
	--From here
	if self.shape.shapeUuid == obj_harvest_wood then
		self.client_refineTime = scrapWood
		RefineStaminaCost = scrapWood*staminacost
	elseif self.shape.shapeUuid == obj_harvest_wood2 then
		self.client_refineTime = wood1
		RefineStaminaCost = wood1*staminacost
	elseif self.shape.shapeUuid == obj_harvest_metal then
		self.client_refineTime = scrapMetal
		RefineStaminaCost = scrapMetal*staminacost
	elseif self.shape.shapeUuid == obj_harvest_metal2 then
		self.client_refineTime = metal1
		RefineStaminaCost = metal1*staminacost
	elseif self.shape.shapeUuid == obj_harvest_stone then
		self.client_refineTime = stone
		RefineStaminaCost = stone*staminacost
	end
	--To here was added by WEN
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
		sm.gui.setProgressFraction( self.client_refineElapsed / self.client_refineTime )
		self.client_refineElapsed = self.client_refineElapsed + dt
		--From here
		local keyBindingText =  sm.gui.getKeyBinding( "Use" )
		sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_REFINE} (".. tostring( self.client_refineTime-tonumber(string.format("%.1f", self.client_refineElapsed))).. ")" )
		--To here was added by WEN
		if self.client_refineElapsed >= self.client_refineTime then
			self.client_refining = false
			self.client_refineElapsed = 0.0
			self.network:sendToServer( "sv_refine", sm.localPlayer.getPlayer() )
			sm.effect.playEffect( "Multiknife - Complete", self.shape.worldPosition )
			end
	elseif self.client_refineElapsed > 0.0 then
		self.client_refineElapsed = math.max( self.client_refineElapsed -  0.25 * ( self.client_refineTime - self.client_refineElapsed ) * dt, 0 )
	else
		self.client_refineElapsed = 0.0
	end
end

function HarvestCore.sv_refine( self, player )
	
	if sm.exists( self.shape ) then
		local recipe = g_refineryRecipes[tostring( self.shape.shapeUuid )]
		sm.container.beginTransaction()
		if recipe then
			sm.container.collect( player:getInventory(), recipe.itemId, recipe.quantity )
		end
		if sm.container.endTransaction() then
			self.shape:destroyShape()
			sm.event.sendToPlayer( player, "sv_e_staminaSpend", RefineStaminaCost )
		end
	end
	
end
