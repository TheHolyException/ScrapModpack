dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

dofile "$SURVIVAL_DATA/Scripts/game/survivalPlayer.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_flamethrower.lua"


function GetDamageData( self )
	local ID = self.tool:getOwner():getId()
	if ID then
		if g_Players[ ID ] then
			if g_Players[ ID ].damagebuff then
				if g_Players[ ID ].damagebuff >= 1 then
					return true
				end
			end
		end
	end
	return false
end

local Damage = 2.5
local ShootVelocity = 10
local ShootForce = 400

Handheld_Flamethrower = class()
Handheld_Flamethrower.FlameSpeed = 5
Handheld_Flamethrower.FlameMinimumLifetime = 6
Handheld_Flamethrower.FlameMaximumLifetime = 8
Handheld_Flamethrower.TargetBurnTime = 4
Handheld_Flamethrower.TicksPerFuel = 2

local MinimalDamage = 10
local MaximalDamage = 15



local renderables = {
	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Flamethrower/Fant_Flamethrower.rend"
}

local renderablesTp = {"$GAME_DATA/Character/Char_Male/Animations/char_male_tp_spudgun.rend", "$GAME_DATA/Character/Char_Tools/Char_spudgun/char_spudgun_tp_animlist.rend"}
local renderablesFp = {"$GAME_DATA/Character/Char_Tools/Char_spudgun/char_spudgun_fp_animlist.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Handheld_Flamethrower.client_onCreate( self )
	self.cl_timer = 0
	self.network:sendToServer( "sv_onCreate" )
	
	self.FireTrigger = 0
	self.fuel = 0
	self:InitAreaTrigger()
end


function Handheld_Flamethrower.InitAreaTrigger( self )
	if self.areaHitbox ~= nil then
		sm.areaTrigger.destroy( self.areaHitbox )
	end
	local Length = 25
	local BlockSize = 0.5 * sm.construction.constants.subdivideRatio * 25
	local Box = sm.vec3.new( BlockSize, BlockSize, BlockSize )
	local Pos = sm.vec3.new( 0, 0, 0 )
	self.areaHitbox = sm.areaTrigger.createBox( Box, Pos, sm.quat.identity(), sm.areaTrigger.filter.all )	

end

function Handheld_Flamethrower.fdebug( self, Pos )
	if self.effect ~= nil then
		--self.effect:stop()
		--self.effect = nil
		self.effect:setPosition( Pos )
		self.effect:setRotation( sm.quat.identity() )
		print( Pos )
	else
		local UUID = sm.uuid.new("f7881097-9320-4667-b2ba-4101c72b8730")
		self.effect = sm.effect.createEffect( "ShapeRenderable" )				
		self.effect:setParameter( "uuid", UUID )
		
		local BlockSize = 0.5 * sm.construction.constants.subdivideRatio * 25
		local Box = sm.vec3.new( BlockSize, BlockSize, BlockSize )
		
		self.effect:setScale( Box )
		self.effect:start()
	end
end


function Handheld_Flamethrower.client_onRefresh( self )
	self:loadAnimations()
	self:InitAreaTrigger()
end

function Handheld_Flamethrower.loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" }
		}
	)
	local movementAnimations = {
		idle = "spudgun_idle",
		idleRelaxed = "spudgun_relax",

		sprint = "spudgun_sprint",
		runFwd = "spudgun_run_fwd",
		runBwd = "spudgun_run_bwd",

		jump = "spudgun_jump",
		jumpUp = "spudgun_jump_up",
		jumpDown = "spudgun_jump_down",

		land = "spudgun_jump_land",
		landFwd = "spudgun_jump_land_fwd",
		landBwd = "spudgun_jump_land_bwd",

		crouchIdle = "spudgun_crouch_idle",
		crouchFwd = "spudgun_crouch_fwd",
		crouchBwd = "spudgun_crouch_bwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "idle", 5.0 )

	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "spudgun_pickup", { nextAnimation = "idle" } },
				unequip = { "spudgun_putdown" },

				idle = { "spudgun_idle", { looping = true } },
				shoot = { "spudgun_shoot", { nextAnimation = "idle" } },

				aimInto = { "spudgun_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "spudgun_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "spudgun_aim_idle", { looping = true} },
				aimShoot = { "spudgun_aim_shoot", { nextAnimation = "aimIdle"} },

				sprintInto = { "spudgun_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "spudgun_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "spudgun_sprint_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.20,
		spreadCooldown = 0.18,
		spreadIncrement = 2.6,
		spreadMinAngle = .25,
		spreadMaxAngle = 8,
		fireVelocity = 130.0,

		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.20,
		spreadCooldown = 0.18,
		spreadIncrement = 1.3,
		spreadMinAngle = 0,
		spreadMaxAngle = 8,
		fireVelocity =  130.0,

		minDispersionStanding = 0.01,
		minDispersionCrouching = 0.01,

		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.fireCooldownTimer = 0.0
	self.spreadCooldownTimer = 0.0

	self.movementDispersion = 0.0

	self.sprintCooldownTimer = 0.0
	self.sprintCooldown = 0.3

	self.aimBlendSpeed = 3.0
	self.blendTime = 0.2

	self.jointWeight = 0.0
	self.spineWeight = 0.0
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )

end

function Handheld_Flamethrower.client_onUpdate( self, dt )
	self:cl_Flame_Manager( dt )
	
	-- First person animation
	local isSprinting =  self.tool:isSprinting()
	local isCrouching =  self.tool:isCrouching()

	if self.tool:isLocal() then
		if self.equipped then
			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not self.tool:isSprinting() and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end

			if self.aiming and not isAnyOf( self.fpAnimations.currentAnimation, { "aimInto", "aimIdle", "aimShoot" } ) then
				swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
			end
			if not self.aiming and isAnyOf( self.fpAnimations.currentAnimation, { "aimInto", "aimIdle", "aimShoot" } ) then
				swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
			end
		end
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end

	local effectPos, rot

	if self.tool:isLocal() then

		local zOffset = 0.6
		if self.tool:isCrouching() then
			zOffset = 0.29
		end

		local dir = sm.localPlayer.getDirection()
		local firePos = self.tool:getFpBonePos( "pejnt_barrel" )

		if not self.aiming then
			effectPos = firePos + dir * 0.2
		else
			effectPos = firePos + dir * 0.45
		end

		rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), dir )
	end
	local pos = self.tool:getTpBonePos( "pejnt_barrel" )
	local dir = self.tool:getTpBoneDir( "pejnt_barrel" )

	effectPos = pos + dir * 0.2

	rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), dir )



	-- Timers
	self.fireCooldownTimer = math.max( self.fireCooldownTimer - dt, 0.0 )
	self.spreadCooldownTimer = math.max( self.spreadCooldownTimer - dt, 0.0 )
	self.sprintCooldownTimer = math.max( self.sprintCooldownTimer - dt, 0.0 )


	if self.tool:isLocal() then
		local dispersion = 0.0
		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
		local recoilDispersion = 1.0 - ( math.max( fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

		if isCrouching then
			dispersion = fireMode.minDispersionCrouching
		else
			dispersion = fireMode.minDispersionStanding
		end

		if self.tool:getRelativeMoveDirection():length() > 0 then
			dispersion = dispersion + fireMode.maxMovementDispersion * self.tool:getMovementSpeedFraction()
		end

		if not self.tool:isOnGround() then
			dispersion = dispersion * fireMode.jumpDispersionMultiplier
		end

		self.movementDispersion = dispersion

		self.spreadCooldownTimer = clamp( self.spreadCooldownTimer, 0.0, fireMode.spreadCooldown )
		local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0

		self.tool:setDispersionFraction( clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 ) )

		if self.aiming then
			if self.tool:isInFirstPersonView() then
				self.tool:setCrossHairAlpha( 0.0 )
			else
				self.tool:setCrossHairAlpha( 1.0 )
			end
			self.tool:setInteractionTextSuppressed( true )
		else
			self.tool:setCrossHairAlpha( 1.0 )
			self.tool:setInteractionTextSuppressed( false )
		end
	end

	-- Sprint block
	local blockSprint = self.aiming or self.sprintCooldownTimer > 0.0
	self.tool:setBlockSprint( blockSprint )

	local playerDir = self.tool:getDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )
	local linareAngle = playerDir:dot( sm.vec3.new( 0, 0, 1 ) )

	local linareAngleDown = clamp( -linareAngle, 0.0, 1.0 )

	down = clamp( -angle, 0.0, 1.0 )
	fwd = ( 1.0 - math.abs( angle ) )
	up = clamp( angle, 0.0, 1.0 )

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight

	local totalWeight = 0.0
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )

			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "shoot" or name == "aimShoot" ) then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 10.0 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 0.001 )
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

	-- Third Person joint lock
	local relativeMoveDirection = self.tool:getRelativeMoveDirection()
	if ( ( ( isAnyOf( self.tpAnimations.currentAnimation, { "aimInto", "aim", "shoot" } ) and ( relativeMoveDirection:length() > 0 or isCrouching) ) or ( self.aiming and ( relativeMoveDirection:length() > 0 or isCrouching) ) ) and not isSprinting ) then
		self.jointWeight = math.min( self.jointWeight + ( 10.0 * dt ), 1.0 )
	else
		self.jointWeight = math.max( self.jointWeight - ( 6.0 * dt ), 0.0 )
	end

	if ( not isSprinting ) then
		self.spineWeight = math.min( self.spineWeight + ( 10.0 * dt ), 1.0 )
	else
		self.spineWeight = math.max( self.spineWeight - ( 10.0 * dt ), 0.0 )
	end

	local finalAngle = ( 0.5 + angle * 0.5 )
	self.tool:updateAnimation( "spudgun_spine_bend", finalAngle, self.spineWeight )

	local totalOffsetZ = lerp( -22.0, -26.0, crouchWeight )
	local totalOffsetY = lerp( 6.0, 12.0, crouchWeight )
	local crouchTotalOffsetX = clamp( ( angle * 60.0 ) -15.0, -60.0, 40.0 )
	local normalTotalOffsetX = clamp( ( angle * 50.0 ), -45.0, 50.0 )
	local totalOffsetX = lerp( normalTotalOffsetX, crouchTotalOffsetX , crouchWeight )

	local finalJointWeight = ( self.jointWeight )


	self.tool:updateJoint( "jnt_hips", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.35 * finalJointWeight * ( normalWeight ) )

	local crouchSpineWeight = ( 0.35 / 3 ) * crouchWeight

	self.tool:updateJoint( "jnt_spine1", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight )  * finalJointWeight )
	self.tool:updateJoint( "jnt_spine2", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_spine3", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.45 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_head", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.3 * finalJointWeight )


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

	self.tool:updateCamera( 2.8, 30.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( 30.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeight, bobbing )
	
	
	
	
	if self.fuel <= 0 and self.FireTrigger > 0 then
		self.network:sendToServer( "sv_Refuel" )
	end
	
	local owner = self.tool:getOwner()
	
	if self.fireCooldownTimer <= 0.0 and self.FireTrigger > 0 and self.fuel > 0 and not owner.character:isSwimming() then
		if self.fuel > 0 then
			
			
			local firstPerson = self.tool:isInFirstPersonView()

			local dir = sm.localPlayer.getDirection()

			local firePos = self:calculateFirePosition()
			local fakePosition = self:calculateTpMuzzlePos()
			local fakePositionSelf = fakePosition
			if firstPerson then
				fakePositionSelf = self:calculateFpMuzzlePos()
			end

			-- Aim assist
			if not firstPerson then
				local raycastPos = sm.camera.getPosition() + sm.camera.getDirection() * sm.camera.getDirection():dot( GetOwnerPosition( self.tool ) - sm.camera.getPosition() )
				local hit, result = sm.localPlayer.getRaycast( 250, raycastPos, sm.camera.getDirection() )
				if hit then
					local norDir = sm.vec3.normalize( result.pointWorld - firePos )
					local dirDot = norDir:dot( dir )

					if dirDot > 0.96592583 then -- max 15 degrees off
						dir = norDir
					else
						local radsOff = math.asin( dirDot )
						dir = sm.vec3.lerp( dir, norDir, math.tan( radsOff ) / 3.7320508 ) -- if more than 15, make it 15
					end
				end
			end

			dir = dir:rotate( math.rad( 0.955 ), sm.camera.getRight() ) -- 50 m sight calibration

			-- Spread
			local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
			local recoilDispersion = 1.0 - ( math.max(fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )

			local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0
			spreadFactor = clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 )
			local spreadDeg =  fireMode.spreadMinAngle + ( fireMode.spreadMaxAngle - fireMode.spreadMinAngle ) * spreadFactor

			dir = sm.noise.gunSpread( dir, spreadDeg )

			
			if owner then
				local rel_Damage = Damage
				if GetDamageData( self ) then
					rel_Damage = rel_Damage * 2
				end
				--self:fdebug( firePos + ( dir * 5 ) )
				self.areaHitbox:setWorldPosition( firePos + ( dir * 5 ) )
				for _, result in ipairs(  self.areaHitbox:getContents() ) do	
					if result ~= nil and sm.exists( result ) then	
						if type( result ) ~= "AreaTrigger" then
							if type( result ) == "Character" then
								local charType = result:getCharacterType()
								if charType == sm.uuid.getNil() then
									if Player_VS_Player then
										self.network:sendToServer( "AddTargetToFlamer", { target = result } )
									end
								else
									self.network:sendToServer( "AddTargetToFlamer", { target = result } )
								end
							else
								self.network:sendToServer( "AddTargetToFlamer", { target = result } )
							end					
						end
					end
				end
			end


			-- Timers
			self.fireCooldownTimer = fireMode.fireCooldown
			self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
			self.sprintCooldownTimer = self.sprintCooldown

			-- Send TP shoot over network and dircly to self
			self:onShoot( dir )
			self.network:sendToServer( "sv_n_onShoot", dir )

			-- Play FP shoot animation
			setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.05 )
		else
			local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
			self.fireCooldownTimer = fireMode.fireCooldown
			sm.audio.play( "PotatoRifle - NoAmmo" )
		end
	end
end

function Handheld_Flamethrower.client_onEquip( self, animate )

	if animate then
		sm.audio.play( "PotatoRifle - Equip", self.tool:getPosition() )
	end

	self.wantEquipped = true
	self.aiming = false
	local cameraWeight, cameraFPWeight = self.tool:getCameraWeights()
	self.aimWeight = math.max( cameraWeight, cameraFPWeight )
	self.jointWeight = 0.0

	currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	self.tool:setTpRenderables( currentRenderablesTp )

	self:loadAnimations()

	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )

	if self.tool:isLocal() then
		-- Sets PotatoRifle renderable, change this to change the mesh
		self.tool:setFpRenderables( currentRenderablesFp )
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function Handheld_Flamethrower.client_onUnequip( self, animate )

	if animate then
		sm.audio.play( "PotatoRifle - Unequip", self.tool:getPosition() )
	end

	self.wantEquipped = false
	self.equipped = false
	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
end

function Handheld_Flamethrower.sv_n_onAim( self, aiming )
	self.network:sendToClients( "cl_n_onAim", aiming )
end

function Handheld_Flamethrower.cl_n_onAim( self, aiming )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onAim( aiming )
	end
end

function Handheld_Flamethrower.onAim( self, aiming )
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function Handheld_Flamethrower.sv_n_onShoot( self, dir )
	self.network:sendToClients( "cl_n_onShoot", dir )
end

function Handheld_Flamethrower.sv_Refuel( self )
	if sm.container.canSpend( self.tool:getOwner():getInventory(), obj_consumable_gas, 1 ) then
		sm.container.beginTransaction()
		sm.container.spend( self.tool:getOwner():getInventory(), obj_consumable_gas, 1, true )
		if sm.container.endTransaction() then		
			self.network:sendToClients( "cl_Refuel" )
		end
	end
end

function Handheld_Flamethrower.cl_Refuel( self )
	self.fuel = 1
end

function Handheld_Flamethrower.cl_n_onShoot( self, dir )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:onShoot( dir )
	end
end

function Handheld_Flamethrower.onShoot( self, dir )

	self.tpAnimations.animations.idle.time = 0
	self.tpAnimations.animations.shoot.time = 0
	self.tpAnimations.animations.aimShoot.time = 0

	setTpAnimation( self.tpAnimations, self.aiming and "aimShoot" or "shoot", 10.0 )

end

function Handheld_Flamethrower.calculateFirePosition( self )
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

function Handheld_Flamethrower.calculateTpMuzzlePos( self )
	local crouching = self.tool:isCrouching()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )
	local right = sm.localPlayer.getRight()
	local up = right:cross(dir)

	local fakeOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	--General offset
	fakeOffset = fakeOffset + right * 0.25
	fakeOffset = fakeOffset + dir * 0.5
	fakeOffset = fakeOffset + up * 0.25

	--Action offset
	local pitchFraction = pitch / ( math.pi * 0.5 )
	if crouching then
		fakeOffset = fakeOffset + dir * 0.2
		fakeOffset = fakeOffset + up * 0.1
		fakeOffset = fakeOffset - right * 0.05

		if pitchFraction > 0.0 then
			fakeOffset = fakeOffset - up * 0.2 * pitchFraction
		else
			fakeOffset = fakeOffset + up * 0.1 * math.abs( pitchFraction )
		end
	else
		fakeOffset = fakeOffset + up * 0.1 *  math.abs( pitchFraction )
	end

	local fakePosition = fakeOffset + GetOwnerPosition( self.tool )
	return fakePosition
end

function Handheld_Flamethrower.calculateFpMuzzlePos( self )
	local fovScale = ( sm.camera.getFov() - 45 ) / 45

	local up = sm.localPlayer.getUp()
	local dir = sm.localPlayer.getDirection()
	local right = sm.localPlayer.getRight()

	local muzzlePos45 = sm.vec3.new( 0.0, 0.0, 0.0 )
	local muzzlePos90 = sm.vec3.new( 0.0, 0.0, 0.0 )

	if self.aiming then
		muzzlePos45 = muzzlePos45 - up * 0.2
		muzzlePos45 = muzzlePos45 + dir * 0.5

		muzzlePos90 = muzzlePos90 - up * 0.5
		muzzlePos90 = muzzlePos90 - dir * 0.6
	else
		muzzlePos45 = muzzlePos45 - up * 0.15
		muzzlePos45 = muzzlePos45 + right * 0.2
		muzzlePos45 = muzzlePos45 + dir * 1.25

		muzzlePos90 = muzzlePos90 - up * 0.15
		muzzlePos90 = muzzlePos90 + right * 0.2
		muzzlePos90 = muzzlePos90 + dir * 0.25
	end

	return self.tool:getFpBonePos( "pejnt_barrel" ) + sm.vec3.lerp( muzzlePos45, muzzlePos90, fovScale )
end

function Handheld_Flamethrower.cl_onPrimaryUse( self, state )
	if self.tool:getOwner().character == nil then
		return
	end
	if self.tool:getOwner().character:isSwimming() then
		self.FireTrigger = 0
		return
	end
	if state > 0 then
		self.FireTrigger = 1
	else
		self.FireTrigger = 0
	end
	--self.network:sendToServer( "sv_set_FireTrigger", { FireTrigger = self.FireTrigger } )
end

function Handheld_Flamethrower.sv_set_FireTrigger( self, data )
	self.FireTrigger = data.FireTrigger
	self.network:sendToClients( "cl_set_FireTrigger", data )
end

function Handheld_Flamethrower.cl_set_FireTrigger( self, data )
	self.FireTrigger = data.FireTrigger
end



function Handheld_Flamethrower.cl_onSecondaryUse( self, state )
	if state == sm.tool.interactState.start and not self.aiming then
		self.aiming = true
		self.tpAnimations.animations.idle.time = 0

		self:onAim( self.aiming )
		self.tool:setMovementSlowDown( self.aiming )
		self.network:sendToServer( "sv_n_onAim", self.aiming )
	end

	if self.aiming and (state == sm.tool.interactState.stop or state == sm.tool.interactState.null) then
		self.aiming = false
		self.tpAnimations.animations.idle.time = 0

		self:onAim( self.aiming )
		self.tool:setMovementSlowDown( self.aiming )
		self.network:sendToServer( "sv_n_onAim", self.aiming )
	end
end

function Handheld_Flamethrower.client_onEquippedUpdate( self, primaryState, secondaryState )
	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse( primaryState )
		self.prevPrimaryState = primaryState
	end

	if secondaryState ~= self.prevSecondaryState then
		self:cl_onSecondaryUse( secondaryState )
		self.prevSecondaryState = secondaryState
	end

	return true, true
end


function Handheld_Flamethrower.sv_onCreate( self )
	--print( "Handheld_Flamethrower.sv_onCreate" )
	G_FLAMERSHAPE = self.shape
	self.FireTrigger = 0
end

function Handheld_Flamethrower.server_onDestroy( self )	
	-- local data = {
		-- fuelTicks = self.fuelTicks
	-- }
	-- self.sv.storage = data
	-- self.storage:save( self.sv.storage )
	
	--if SV_FLAME_MANAGER == self.shape.id then
		SV_FLAME_MANAGER = nil
	--end
end

function Handheld_Flamethrower.client_onDestroy( self )
	for _, flame in ipairs( Flames ) do
		if flame ~= nil then
			if flame.Effect ~= nil then
				flame.Effect:stop()	
			end
		end
	end
	for _, flame in ipairs( Flame_On_Targets ) do
		if flame ~= nil then
			if flame.Effect ~= nil then
				flame.Effect:stop()	
			end
		end
	end
	--if CL_FLAME_MANAGER == self.shape.id then
		CL_FLAME_MANAGER = nil
	--end
end

function Handheld_Flamethrower.server_onFixedUpdate( self, dt )
	self:sv_Flame_Manager( dt )
end

function Handheld_Flamethrower.AddTargetToFlamer( self, targetData )
	local result = targetData.target
	if result ~= nil and sm.exists( result ) then	
		if type( result ) == "Character" then	
			if result ~= self.tool:getOwner().character then
				self:add_Flame_Target( result, nil )
			end
		end
		if type( result ) == "Body" then						
			local shapes = sm.body.getShapes( result )
			if shapes ~= nil then
				if sm.shape.getShapeUuid( shapes[1] ) == fant_straw_dog then		
					self:add_Flame_Target( nil, result )
					--print(result )
				end
				if sm.shape.getShapeUuid( shapes[1] ) == fant_beebot then		
					self:add_Flame_Target( nil, result )
					--print(result )
				end
			end
			
		end
	end
end

function Handheld_Flamethrower.sv_Flame_Manager( self, dt )
	if not self:sv_Register_Flame_Manager() then
		return
	end
	local new_Flame_Targets = {}
	for _, flame_target in ipairs( Flame_Targets ) do
		if flame_target ~= nil then
			flame_target.lifetime = flame_target.lifetime - dt

			if flame_target.lifetime <= 0 then
				flame_target.lifetime = 0
			end
			if flame_target.character ~= nil and sm.exists( flame_target.character ) then
				if flame_target.character:isSwimming() then
					flame_target.lifetime = 0
				end
			end
			if flame_target.lifetime > 0 then
				table.insert( new_Flame_Targets, flame_target )
			end
		end
	end
	Flame_Targets = new_Flame_Targets
	--print( "Flame_Targets: " .. tostring( #Flame_Targets ) )
end

function Handheld_Flamethrower.cl_Flame_Manager( self, dt )
	if self:cl_Register_Flame_Manager() then
		for _, flame in ipairs( Flames ) do
			if flame ~= nil then
				flame.lifetime = flame.lifetime - dt
				if flame.Effect ~= nil then
					local move_vector = flame.direction * dt * self.FlameSpeed * ( 1 + flame.lifetime )
					flame.position = flame.position + move_vector
					flame.Effect:setPosition( flame.position )
					--flame.Effect:setRotation( flame.sourceshape:getWorldRotation() )
				end
				if flame.lifetime <= 0 then
					flame.lifetime = 0
					self:cl_deleteFlame( flame )
				end
			end
		end
		--print( "Flames: " .. tostring( #Flames ) )
		for _, flame_on_target in ipairs( Flame_On_Targets ) do
			if flame_on_target ~= nil then
				flame_on_target.lifetime = flame_on_target.lifetime - dt
				if flame_on_target.Effect ~= nil then
					if flame_on_target.character ~= nil and sm.exists( flame_on_target.character ) then
						flame_on_target.Effect:setPosition( flame_on_target.character.worldPosition )
						if flame_on_target.character:isSwimming() then
							flame_on_target.lifetime = 0
							flame_on_target.Effect:stop()
							--print( "isswimstop" )
						end
					end
					if flame_on_target.shape ~= nil then
						if type( flame_on_target.shape ) == "Body" and sm.exists( flame_on_target.shape ) then
							flame_on_target.Effect:setPosition( flame_on_target.shape.worldPosition )
						end
					end
					flame_on_target.Effect:setRotation( sm.quat.identity( ) )
				else
					flame_on_target.lifetime = 0
					flame_on_target.Effect:stop()
				end
				if flame_on_target.lifetime <= 0 or ( flame_on_target.character == nil and flame_on_target.shape == nil ) then
					flame_on_target.lifetime = 0
					flame_on_target.Effect:stop()
					self:cl_deleteFlameOnTarget( flame_on_target )
				end
			end
		end
		--print( "Flame_On_Targets: " .. tostring( #Flame_On_Targets ) )
	end
	
	
	self.cl_timer = self.cl_timer - dt
	if self.cl_timer < 0 then
		self.cl_timer = 0.05	
		if self.FireTrigger > 0 and self.fuel > 0 then
			self.fuel = self.fuel - ( dt * 0.75 )
			--self:cl_addFlame(  )
			--print( self.fuel )
			self.network:sendToServer( "sv_addFlame", { character = sm.localPlayer.character, direction =  sm.localPlayer.getDirection() } )
		end
	end
	
end

function Handheld_Flamethrower.sv_addFlame( self, data )
	self.network:sendToClients( "cl_addFlame", data )
end


function Handheld_Flamethrower.sv_Register_Flame_Manager( self )
	if SV_FLAME_MANAGER ~= nil then
	else
		SV_FLAME_MANAGER = self.tool.id
	end
	if SV_FLAME_MANAGER == self.tool.id then
		return true
	else
		return false
	end
end

function Handheld_Flamethrower.cl_Register_Flame_Manager( self )
	if CL_FLAME_MANAGER ~= nil then
	else
		CL_FLAME_MANAGER = self.tool.id
	end
	if CL_FLAME_MANAGER == self.tool.id then
		return true
	else
		return false
	end
end

function Handheld_Flamethrower.cl_setState( self, state )
	self.state = state
end

function Handheld_Flamethrower.add_Flame_Target( self, character, shape )
	local hasAllready = false
	for _, target in ipairs( Flame_Targets ) do	
		if target ~= nil then	
			if character ~= nil and target.character ~= nil then
				if target.character == character then
					if target.lifetime > self.TargetBurnTime / 2 then
						hasAllready = true
						break
					end
				end
			end
			if shape ~= nil and target.shape ~= nil then
				if target.shape == shape then
					if target.lifetime > self.TargetBurnTime / 2 then
						hasAllready = true
						break
					end
				end
			end
		end
	end
	if not hasAllready then
		local data = {}
		if character ~= nil then
			data = { character = character, lifetime = self.TargetBurnTime, shape = nil, attacker = self.tool:getOwner() }
		end
		if shape ~= nil then
			data = { character = nil, lifetime = self.TargetBurnTime, shape = shape, attacker = self.tool:getOwner() }
		end
		table.insert( Flame_Targets, data )
		self.network:sendToClients( "cl_add_Flame_Target", data )
	end
end

function Handheld_Flamethrower.cl_add_Flame_Target( self, data )
	local new_flame_target = {}
	new_flame_target.character = data.character
	new_flame_target.lifetime = data.lifetime
	new_flame_target.shape = data.shape
	new_flame_target.Effect = sm.effect.createEffect( "Fire - gradual", nil )
	new_flame_target.Effect:setParameter( "intensity", 0 )
	if new_flame_target.character ~= nil then
		new_flame_target.Effect:setPosition( new_flame_target.character.worldPosition )
	end
	if new_flame_target.shape ~= nil then
		new_flame_target.Effect:setPosition( new_flame_target.shape.worldPosition )
	end
	
	new_flame_target.Effect:setRotation( sm.quat.identity( ) )
	new_flame_target.Effect:start()
	table.insert( Flame_On_Targets, new_flame_target )
end

function Handheld_Flamethrower.cl_addFlame( self, data )
	if data.character ~= sm.localPlayer.character then
		return
	end
	local toolPos = self.tool:getTpBonePos( "pejnt_barrel" ) 
	if self.tool:isInFirstPersonView() then
		toolPos = self.tool:getFpBonePos( "pejnt_barrel" )
	end
	local Direction = data.direction
	local target_position = toolPos + Direction * 100
	local new_flame = {}
	new_flame.Effect = sm.effect.createEffect( "Fire - gradual", nil )
	new_flame.lifetime = math.random( self.FlameMinimumLifetime, self.FlameMaximumLifetime ) / 10
	new_flame.sourceshape = self.tool
	local Spread = 30
	local SpreadVector = sm.vec3.new( math.random( -Spread, Spread ), math.random( -Spread, Spread ), math.random( -Spread, Spread ) )
	new_flame.direction = sm.vec3.normalize( target_position -toolPos + SpreadVector )
	new_flame.position = toolPos + ( Direction * 1.6 )
	new_flame.Effect:setPosition( new_flame.position )
	new_flame.Effect:setRotation( sm.quat.lookRotation( Direction, sm.vec3.new( 0, 1, 0 ) ) )
	new_flame.Effect:setParameter( "intensity", 0 )
	new_flame.Effect:start()
	table.insert( Flames, new_flame )
end

function Handheld_Flamethrower.cl_deleteFlame( self, delete_flame )
	if delete_flame == nil then
		return
	end
	local newFlames = {}
	for _, flame in ipairs( Flames ) do
		if flame ~= nil and flame ~= delete_flame then
			table.insert( newFlames, flame )
		end
	end
	Flames = newFlames
	if delete_flame.Effect ~= nil then
		delete_flame.Effect:stop()
	end
	delete_flame = nil
end

function Handheld_Flamethrower.cl_deleteFlameOnTarget( self, delete_flame_on_target )
	if delete_flame_on_target == nil then
		return
	end
	local newFlames = {}
	for _, flame_on_target in ipairs( Flame_On_Targets ) do
		if flame_on_target ~= delete_flame_on_target then
			table.insert( newFlames, flame_on_target )
		end
	end
	Flame_On_Targets = newFlames
	if delete_flame_on_target.Effect ~= nil then
		delete_flame_on_target.Effect:stop()
	end
	delete_flame_on_target = nil
end
