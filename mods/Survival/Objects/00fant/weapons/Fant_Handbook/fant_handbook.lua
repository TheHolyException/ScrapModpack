dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
Fant_Handbook = class()

local Sites = {}
Sites[ #Sites + 1 ] = { "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Handbook/sites/fant_handbook_site_1.rend" }
Sites[ #Sites + 1 ] = { "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Handbook/sites/fant_handbook_site_2.rend" }
Sites[ #Sites + 1 ] = { "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Handbook/sites/fant_handbook_site_3.rend" }
Sites[ #Sites + 1 ] = { "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Handbook/sites/fant_handbook_site_4.rend" }
Sites[ #Sites + 1 ] = { "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Handbook/sites/fant_handbook_site_5.rend" }
Sites[ #Sites + 1 ] = { "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Handbook/sites/fant_handbook_site_6.rend" }
Sites[ #Sites + 1 ] = { "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Handbook/sites/fant_handbook_site_40.rend" }

local renderables =   {"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Handbook/fant_handbook.rend" }
local renderablesTp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_logbook.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_logbook/char_logbook_tp_animlist.rend"}
local renderablesFp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_logbook.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_logbook/char_logbook_fp_animlist.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Fant_Handbook.server_onCreate( self )

end

function Fant_Handbook.client_onCreate( self )
	for i, k in pairs( Sites ) do
		sm.tool.preloadRenderables( k )
	end
	self.cl = {}
	self.site = 1
	self.hold = true
	if self.tool:isLocal() then
		
	end

	self:client_onRefresh()
	self:client_update_site()
end

function Fant_Handbook.client_onRefresh( self )
	self:cl_loadAnimations()
	self:client_update_site()
end

function Fant_Handbook.client_onUpdate( self, dt )
	-- First person animation
	local isCrouching = self.tool:isCrouching()

	if self.tool:isLocal() then
		updateFpAnimations( self.fpAnimations, self.cl.equipped, dt )
	end

	if not self.cl.equipped then
		if self.cl.wantsEquip then
			self.cl.wantsEquip = false
			self.cl.equipped = true
		end
		return
	end

	local crouchWeight = isCrouching and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight
	local totalWeight = 0.0

	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )

			if animation.looping == true then
				if animation.time >= animation.info.duration then
					animation.time = animation.time - animation.info.duration
				end
			end
			if animation.time >= animation.info.duration - self.cl.blendTime and not animation.looping then
				if ( name == "putdown" ) then
					self.cl.equipped = false
				elseif animation.nextAnimation ~= "" then
					setTpAnimation( self.tpAnimations, animation.nextAnimation, 0.001 )
				end
			end
		else
			animation.weight = math.max( animation.weight - ( self.tpAnimations.blendSpeed * dt ), 0.0 )
		end

		totalWeight = totalWeight + animation.weight
	end

	totalWeight = totalWeight == 0 and 1.0 or totalWeight
	for name, animation in pairs( self.tpAnimations.animations ) do

		local weight = animation.weight / totalWeight
		if name == "idle" then
			self.tool:updateMovementAnimation( animation.time, weight )
		elseif animation.crouch then
			self.tool:updateAnimation( animation.info.name, animation.time, weight * normalWeight )
			self.tool:updateAnimation( animation.crouch.name, animation.time, weight * crouchWeight )
		else
			self.tool:updateAnimation( animation.info.name, animation.time, weight )
		end
	end

end

function Fant_Handbook.client_canEquip( _ )
	return true
end

function Fant_Handbook.client_onEquip( self )
	self.cl.wantsEquip = true
	self.cl.seatedEquiped = false
	local rend = renderables
	if self.site ~= nil then
		rend = Sites[ self.site ]
	end
	local currentRenderablesTp = {}
	concat(currentRenderablesTp, renderablesTp)
	concat(currentRenderablesTp, rend)

	local currentRenderablesFp = {}
	concat(currentRenderablesFp, renderablesFp)
	concat(currentRenderablesFp, rend)

	self.tool:setTpRenderables( currentRenderablesTp )

	if self.tool:isLocal() then
		self.tool:setFpRenderables( currentRenderablesFp )
	end

	self:cl_loadAnimations()
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )

	if self.tool:isLocal() then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
	
end

function Fant_Handbook.client_onUnequip( self )
	self.cl.wantsEquip = false
	self.cl.seatedEquiped = false

	setTpAnimation( self.tpAnimations, "useExit" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" and self.fpAnimations.currentAnimation ~= "useExit" then
		swapFpAnimation( self.fpAnimations, "equip", "useExit", 0.2 )
	end
end

function Fant_Handbook.cl_loadAnimations( self )
	-- TP
	self.tpAnimations = createTpAnimations( 
		self.tool,
		{ 
			idle = { "logbook_use_idle", { looping = true } },
			sprint = { "logbook_sprint" },
			pickup = { "logbook_pickup", { nextAnimation = "useInto" } },
			putdown = { "logbook_putdown" },
			useInto = { "logbook_use_into", { nextAnimation = "idle" } },
			useExit = { "logbook_use_exit", { nextAnimation = "putdown" } }
		} 
	)

	local movementAnimations = {
		idle = "logbook_use_idle",
		idleRelaxed = "logbook_idle_relaxed",

		runFwd = "logbook_run_fwd",
		runBwd = "logbook_run_bwd",
		sprint = "logbook_sprint",

		jump = "logbook_jump",
		jumpUp = "logbook_jump_up",
		jumpDown = "logbook_jump_down",

		land = "logbook_jump_land",
		landFwd = "logbook_jump_land_fwd",
		landBwd = "logbook_jump_land_bwd",

		crouchIdle = "logbook_crouch_idle",
		crouchFwd = "logbook_crouch_fwd",
		crouchBwd = "logbook_crouch_bwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	if self.tool:isLocal() then
		-- FP
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				idle = { "logbook_use_idle", { looping = true } },
				equip = { "logbook_pickup", { nextAnimation = "useInto" } },
				unequip = { "logbook_putdown" },
				useInto = { "logbook_use_into", { nextAnimation = "idle" } },
				useExit = { "logbook_use_exit", { nextAnimation = "unequip" } }
			}
		)
	end

	setTpAnimation( self.tpAnimations, "idle", 5.0 )
	self.cl.blendTime = 0.2
end

function Fant_Handbook.cl_onGuiClosed( self )
	sm.tool.forceTool( nil )
	self.cl.seatedEquiped = false
end

function Fant_Handbook.client_onEquippedUpdate( self, primaryState, secondaryState, force )
	local changed = false
	if self.tool:isLocal() and self.hold then
		if primaryState == 1 and not force then
			self.site = self.site + 1
			if self.site > #Sites then
				self.site = 1 
			end
			changed = true
		end
		if secondaryState == 1 then
			self.site = self.site - 1
			if self.site < 1 then
				self.site = #Sites
			end
			changed = true
		end
		if changed then
			--print( "self.site", self.site )
			self:client_update_site()
		end
	end
	if primaryState == 1 and ( force or not self.hold ) then
		local anim = "unequip"
		if not self.hold then
			self.hold = true	
			anim = "equip"			
		else
			self.hold = false
			anim = "unequip"
		end
		
		self:cl_loadAnimations()
		setTpAnimation( self.tpAnimations, anim, 0.0 )

		if self.tool:isLocal() then
			swapFpAnimation( self.fpAnimations, "idle", anim, 0.0 )
		end
		--print( "unequip" )
	end
	return true, true
end

function Fant_Handbook.client_update_site( self )
	local rend = renderables
	if self.site ~= nil then
		rend = Sites[ self.site ]
	end
	local currentRenderablesTp = {}
	concat(currentRenderablesTp, renderablesTp)
	concat(currentRenderablesTp, rend)

	local currentRenderablesFp = {}
	concat(currentRenderablesFp, renderablesFp)
	concat(currentRenderablesFp, rend)

	self.tool:setTpRenderables( currentRenderablesTp )

	if self.tool:isLocal() then
		self.tool:setFpRenderables( currentRenderablesFp )
	end

	self:cl_loadAnimations()
	setTpAnimation( self.tpAnimations, "idle", 0.0001 )

	if self.tool:isLocal() then
		swapFpAnimation( self.fpAnimations, "idle", "idle", 0.0001 )
	end

end
