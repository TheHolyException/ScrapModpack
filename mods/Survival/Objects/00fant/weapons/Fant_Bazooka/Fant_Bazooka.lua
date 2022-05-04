dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"
dofile "$SURVIVAL_DATA/Scripts/game/SurvivalGame.lua"

Fant_Bazooka = class( nil )
Fant_Bazooka.FireDelay = 1

local heavyRenderables = {
	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Bazooka/Fant_Bazooka.rend"
}
local renderablesHeavyTp = { "$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_heavytool.rend", "$SURVIVAL_DATA/Character/Char_Tools/char_heavytool/char_heavytool_tp_animlist.rend" }
local renderablesHeavyFp = { "$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_heavytool.rend", "$SURVIVAL_DATA/Character/Char_Tools/char_heavytool/char_heavytool_fp_animlist.rend" }
sm.tool.preloadRenderables( heavyRenderables )
sm.tool.preloadRenderables( renderablesHeavyTp )
sm.tool.preloadRenderables( renderablesHeavyFp )

function Fant_Bazooka.client_onCreate( self )
	self:client_onRefresh()
end

function Fant_Bazooka.client_onRefresh( self )
	if self.tool:isLocal() then
		self.activeItem = nil
		self.wasOnGround = true
	end
	self.aiming = false
	self.aimBlendSpeed = 3.0
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.jointWeight = 0.0
	self.spineWeight = 0.0
	self.FireTimer = 0
	
	self:cl_updateCarryRenderables( nil )
	self:cl_loadAnimations( nil )
end

function Fant_Bazooka.cl_loadAnimations( self, activeUid )
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			idle = { "heavytool_idle", { looping = true } },
			sprint = { "heavytool_sprint_idle" },
			pickup = { "heavytool_pickup", { nextAnimation = "idle" } },
			putdown = { "heavytool_putdown" }

		}
	)
	local movementAnimations = {

		idle = "heavytool_idle",

		runFwd = "heavytool_run",
		runBwd = "heavytool_runbwd",

		sprint = "heavytool_sprint_idle",

		jump = "heavytool_jump",
		jumpUp = "heavytool_jump_up",
		jumpDown = "heavytool_jump_down",

		land = "heavytool_jump_land",
		landFwd = "heavytool_jump_land_fwd",
		landBwd = "heavytool_jump_land_bwd",

		crouchIdle = "heavytool_crouch_idle",
		crouchFwd = "heavytool_crouch_run",
		crouchBwd = "heavytool_crouch_runbwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				idle = { "heavytool_idle", { looping = true } },

				sprintInto = { "heavytool_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintIdle = { "heavytool_sprint_idle", { looping = true } },
				sprintExit = { "heavytool_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },

				equip = { "heavytool_pickup", { nextAnimation = "idle" } },
				unequip = { "heavytool_putdown" }
			}
		)
	end
	setTpAnimation( self.tpAnimations, "idle", 5.0 )
	self.blendTime = 0.2
end

function Fant_Bazooka.client_onUpdate( self, dt )

	--local isOnGround =  self.tool:isOnGround()

	if self.tool:isLocal() then
		if self.equipped then
			if self.tool:isSprinting() and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not self.tool:isSprinting() and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end

			-- if not isOnGround and self.wasOnGround and self.fpAnimations.currentAnimation ~= "jump" then
			-- 	swapFpAnimation( self.fpAnimations, "land", "jump", 0.2 )
			-- elseif isOnGround and not self.wasOnGround and self.fpAnimations.currentAnimation ~= "land" then
			-- 	swapFpAnimation( self.fpAnimations, "jump", "land", 0.2 )
			-- end
		end
		updateFpAnimations( self.fpAnimations, self.equipped, dt )

		--self.wasOnGround = isOnGround
	end

	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end

	if self.tool:isLocal() then
		local carryContainer = sm.localPlayer.getCarry()
		local activeItem = carryContainer:getItem( 0 ).uuid
		if self.activeItem ~= activeItem then
			self.activeItem = activeItem
			self.network:sendToServer( "sv_n_updateCarryRenderables", activeItem )
		end
	end

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight
	local totalWeight = 0.0

	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )

			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "use" or name == "useempty" ) then
					setTpAnimation( self.tpAnimations, "idle", 10.0 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, "idle", 0.001 )
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
	

	-- Camera update
	local bobbing = 1
	if self.aiming then
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 1.0, blend )
		bobbing = 0.12
	else
		local blend = 1 - math.pow( 1 - 1 / self.aimBlendSpeed, dt * 60 )
		self.aimWeight = sm.util.lerp( self.aimWeight, 0.0, blend )
		bobbing = 1
	end

	self.tool:updateCamera( 2.8, 30.0, sm.vec3.new( -0.2, 0.0, 0.35 ), self.aimWeight )
	self.tool:updateFpCamera( 30.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeight, bobbing )
end

function Fant_Bazooka.client_onToggle( self )
	return false
end

function Fant_Bazooka.client_onEquip( self )
	sm.audio.play( "PotatoRifle - Equip" )
	if self.tool:isLocal() then
		self.tool:setBlockSprint( true )
		local carryContainer = sm.localPlayer.getCarry()
		local activeItem = carryContainer:getItem( 0 ).uuid
		self.activeItem = activeItem
		self.network:sendToServer( "sv_n_updateCarryRenderables", activeItem )
		if activeItem == obj_character_worm then
			sm.effect.playEffect( "Glowgorp - Pickup", self.tool:getOwner().character.worldPosition )
		end
	end

	self:cl_updateCarryRenderables( self.activeItem )
	self:cl_loadAnimations( self.activeItem )

	self.wantEquipped = true

	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.tool:isLocal() then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end

end

function Fant_Bazooka.sv_n_updateCarryRenderables( self, activeUid, player )
	self.network:sendToClients( "cl_n_updateActiveCarry", { activeUid = activeUid, player = player } )
end

function Fant_Bazooka.cl_n_updateActiveCarry( self, params )
	if params.player ~= sm.localPlayer.getPlayer() then
		self:cl_updateCarryRenderables( params.activeUid )
		self:cl_loadAnimations( params.activeUid )
	end
end

function Fant_Bazooka.cl_updateCarryRenderables( self, activeUid )
	local carryRenderables = heavyRenderables
	local animationRenderablesTp = renderablesHeavyTp
	local animationRenderablesFp = renderablesHeavyFp

	local currentRenderablesTp = {}
	local currentRenderablesFp = {}

	for k,v in pairs( animationRenderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( animationRenderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	for k,v in pairs( carryRenderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( carryRenderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	self.tool:setTpRenderables( currentRenderablesTp )
	if self.tool:isLocal() then
		self.tool:setFpRenderables( currentRenderablesFp )
	end

end

function Fant_Bazooka.client_onUnequip( self )
	sm.audio.play( "PotatoRifle - Unequip" )
	if self.tool:isLocal() then
		self:cl_updateCarryRenderables( nil )

		self.tool:setBlockSprint( false )
		local carryContainer = sm.localPlayer.getCarry()
		local activeItem = carryContainer:getItem( 0 ).uuid
		self.activeItem = activeItem
		self.network:sendToServer( "sv_n_updateCarryRenderables", activeItem )
	end

	self.wantEquipped = false
	self.equipped = false
	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end

end

function Fant_Bazooka.calculateFirePosition( self )
	local crouching = self.tool:isCrouching()
	local firstPerson = self.tool:isInFirstPersonView()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )
	local right = sm.localPlayer.getRight()

	local fireOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	if crouching then
		fireOffset.z = 0.15
	else
		fireOffset.z = 0.45
	end

	if firstPerson then
		if not self.aiming then
			fireOffset = fireOffset + right * 0.05
		end
	else
		fireOffset = fireOffset + right * 0.25
		fireOffset = fireOffset:rotate( math.rad( pitch ), right )
	end
	local firePosition = GetOwnerPosition( self.tool ) + fireOffset
	return firePosition
end

function Fant_Bazooka.client_onEquippedUpdate( self, primaryState, secondaryState )
	if self.tool:isLocal() then
		if secondaryState == sm.tool.interactState.start and not self.aiming then
			self.aiming = true		
			self.tool:setMovementSlowDown( self.aiming )
		end

		if self.aiming and ( secondaryState == sm.tool.interactState.stop ) then
			self.aiming = false		
			self.tool:setMovementSlowDown( self.aiming )
		end
		
		if self.FireTimer > 0 then
			self.FireTimer = self.FireTimer - (1/40)
		end
		if primaryState == 2 then
			if self.FireTimer <= 0 then
				self.FireTimer = self.FireDelay
				self:Fire1()
				return true, true
			end
		end
	end
	return false, false
end

function Fant_Bazooka.Fire1( self )
	local FirePos = self:calculateFirePosition()
	local FireDir = sm.localPlayer.getDirection()
	local Inventory = self.tool:getOwner():getInventory()
	local canFire = false
	local AmmoType = "small"
	
	if not sm.game.getLimitedInventory() then
		canFire = true
		AmmoType = "large"
		FireDir = FireDir * 100
	else
		if Inventory then
			if not canFire then
				if sm.container.canSpend( Inventory, obj_interactive_propanetank_small, 1 ) then
					canFire = true
					FireDir = FireDir * 35
				end
			end
			if not canFire then
				if sm.container.canSpend( Inventory, obj_interactive_propanetank_large, 1 ) then
					canFire = true
					AmmoType = "large"
					FireDir = FireDir * 100
				end
			end
		end
	end
	if canFire then
		sm.audio.play( "Gas Explosion" )
		self.network:sendToServer( "Fire2", { FirePos = FirePos, FireDir = FireDir, AmmoType = AmmoType } )
	end
end

function Fant_Bazooka.Fire2( self, data )
	if not sm.game.getLimitedInventory() then
		sm.projectile.projectileAttack( "explosivetape", 1, data.FirePos, data.FireDir, self.tool:getOwner(), data.FirePos, data.FirePos )
	else
		local Inventory = self.tool:getOwner():getInventory()
		if Inventory then
			sm.container.beginTransaction()
			if data.AmmoType == "small" then
				sm.container.spend( Inventory, obj_interactive_propanetank_small, 1, true )
			else
				sm.container.spend( Inventory, obj_interactive_propanetank_large, 1, true )
			end
			if sm.container.endTransaction() then
				sm.projectile.projectileAttack( "explosivetape", 1, data.FirePos, data.FireDir, self.tool:getOwner(), data.FirePos, data.FirePos )
			end	
		end
	end
end












