dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

Fant_Gravitygun = class()
Fant_Gravitygun.lastDistance = 0
Fant_Gravitygun.Modes = {
	"Distance",
	"Rotate X",
	"Rotate Y",
	"Rotate Z"
}

Fant_Gravitygun.ModeColors = {
	"df7f01",
	"ff0000",
	"00ff00",
	"0000ff"
}

local renderables = {
	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Gravitygun/Fant_Gravitygun.rend"
}

local renderablesTp = {"$GAME_DATA/Character/Char_Male/Animations/char_male_tp_spudgun.rend", "$GAME_DATA/Character/Char_Tools/Char_spudgun/char_spudgun_tp_animlist.rend"}
local renderablesFp = {"$GAME_DATA/Character/Char_Tools/Char_spudgun/char_spudgun_fp_animlist.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Fant_Gravitygun.client_onCreate( self )
	self.shootEffect = sm.effect.createEffect( "SpudgunSpinner - SpinnerMuzzel" )
	self.owner = self.tool:getOwner()
	self.currentMode = 1
	local color = sm.color.new( self.ModeColors[ self.currentMode ] )
	self.tool:setTpColor( color )
	if self.tool:isLocal() then
		self.tool:setFpColor( color )
	end
	self.network:sendToServer( "sv_SetGunAndBeamColor", color )
	self.BeamData = nil
end

function Fant_Gravitygun.client_onRefresh( self )
	self:loadAnimations()
end

function Fant_Gravitygun.loadAnimations( self )

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

function Fant_Gravitygun.client_onUpdate( self, dt )

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

	local dir = self.tool:getOwner().character:getDirection()
	local upDir = self.tool:getTpBoneDir( "pejnt_barrel" )
	local pos = self.tool:getTpBonePos( "pejnt_barrel" )
	local firstPerson = self.tool:isInFirstPersonView()
	if firstPerson then
		pos = self.tool:getFpBonePos( "pejnt_barrel" )
	end
	if self.tool:isLocal() then
		if self.aiming then
			pos = pos + ( sm.camera.getRight( ) * -0.3 )
		end
	end
	self.shootEffect:setPosition( pos + ( dir * 0.2 ) + ( upDir * 0.3 ) )
	self.shootEffect:setVelocity( self.tool:getMovementVelocity() )
	self.shootEffect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), dir ) )

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
	
	
	self:showBeam()
end

function Fant_Gravitygun.client_onEquip( self, animate )
	self.owner = self.tool:getOwner()
	
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

function Fant_Gravitygun.client_onUnequip( self, animate )
	if animate then
		sm.audio.play( "PotatoRifle - Unequip", self.tool:getPosition() )
	end

	self.wantEquipped = false
	self.equipped = false
	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	
	self.network:sendToServer( "sv_setGrabbedBody", { body = nil, player = self.owner, distance = 0, character = nil } )
	if self.effect ~= nil then
		self.effect:stop()
		self.effect:destroy()
		self.effect = nil
	end
end

function Fant_Gravitygun.client_onDestroy( self )
	if self.owner ~= nil then
		self.network:sendToServer( "sv_setGrabbedBody", { body = nil, player = self.owner, distance = 0, character = nil } )
	end
	if self.effect ~= nil then
		self.effect:stop()
		self.effect:destroy()
		self.effect = nil
	end
end

function Fant_Gravitygun.calculateFirePosition( self )
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

function Fant_Gravitygun.calculateTpMuzzlePos( self )
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

function Fant_Gravitygun.calculateFpMuzzlePos( self )
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

function Fant_Gravitygun.client_onEquippedUpdate( self, primaryState, secondaryState )
	if primaryState ~= self.prevPrimaryState then
		self:cl_onPrimaryUse( primaryState )
		self.prevPrimaryState = primaryState
	end
	if primaryState == 1 then
		local hit, result = sm.localPlayer.getRaycast( 2000, sm.camera.getPosition(), sm.camera.getDirection() )
		if hit then
			local aim_body = result:getBody()
			if aim_body then
				
				local canGrab = true
				local shapes = aim_body:getShapes()
				if shapes then
					local ShapeUUID = shapes[1]:getShapeUuid()
					if ShapeUUID ==	fant_straw_dog then
						canGrab = false
					end
				end
				if not aim_body:isStatic() then
					if canGrab == true or not sm.game.getLimitedInventory() then
						local dist = sm.vec3.length( self.tool:getOwner().character.worldPosition - aim_body:getCenterOfMassPosition() )
						self.lastDistance = dist
						self.network:sendToServer( "sv_setGrabbedBody", { body = aim_body, player = self.tool:getOwner(), distance = dist, character = nil } )
					end
				end
			end
			local aim_character = result:getCharacter()
			if aim_character then
				local canGrab = true
				local uuid = aim_character:getCharacterType()
				if sm.game.getLimitedInventory() and ( uuid ~= unit_woc or uuid ~= unit_worm ) then
					if uuid ~= unit_woc and uuid ~= unit_worm then
						canGrab = false
					end
				end
				if canGrab == true then
					local dist = sm.vec3.length( self.tool:getOwner().character.worldPosition - aim_character:getWorldPosition() )
					self.lastDistance = dist
					self.network:sendToServer( "sv_setGrabbedBody", { body = nil, player = self.tool:getOwner(), distance = dist, character = aim_character } )
				end
			end
		end
	end
	if primaryState == 2 then

	end
	if primaryState == 3 then
		self.network:sendToServer( "sv_setGrabbedBody", { body = nil, player = self.tool:getOwner(), distance = 0, character = nil } )
	end

	if secondaryState == 1 then
		self.currentMode = self.currentMode + 1
		if self.currentMode > #self.Modes then
			self.currentMode = 1
		end
		--print( "Mode Change: " .. self.Modes[ self.currentMode ] )

		local color = sm.color.new( self.ModeColors[ self.currentMode ] )
		self.tool:setTpColor( color )
		if self.tool:isLocal() then
			sm.gui.chatMessage(  "Mode Change: " .. self.Modes[ self.currentMode ] )
			self.tool:setFpColor( color )
		end
		self.network:sendToServer( "sv_SetGunAndBeamColor", color )
	end

	return true, true
end

function Fant_Gravitygun.sv_SetGunAndBeamColor( self , color )
	self.network:sendToClients( "cl_SetGunAndBeamColor", color )
end

function Fant_Gravitygun.cl_SetGunAndBeamColor( self , color )
	self.tool:setTpColor( color )
	if self.tool:isLocal() then
		self.tool:setFpColor( color )
	end
end

function Fant_Gravitygun.sv_setGrabbedBody( self, data )
	if self.tool:getOwner() == data.player then
		sm.event.sendToPlayer( data.player, "setGrabbedBody", data )
		
	end
	self.network:sendToClients( "cl_setBeamData", data )
end


function Fant_Gravitygun.cl_setBeamData( self, BeamData )
	self.BeamData = BeamData
end

function Fant_Gravitygun.showBeam( self )
	local BeamEnd = nil
	if self.BeamData ~= nil then
		if sm.exists( self.BeamData.body ) then
			BeamEnd = self.BeamData.body:getCenterOfMassPosition()
		end
		if sm.exists( self.BeamData.character ) then		
			if self.BeamData.character:isTumbling() then
				BeamEnd = self.BeamData.character:getTumblingWorldPosition()
			else
				BeamEnd = self.BeamData.character.worldPosition
			end
		end
	end
	if BeamEnd == nil and self.effect ~= nil then
		self.effect:stop()
		self.effect:destroy()
		self.effect = nil
	end
	if BeamEnd ~= nil and self.effect == nil then
		local UUID = sm.uuid.new( "f7881097-9320-4667-b2ba-4101c72b8730")
		self.effect = sm.effect.createEffect( "ShapeRenderable" )				
		self.effect:setParameter( "uuid", UUID )
		self.effect:start()
	end
	if self.effect ~= nil and BeamEnd ~= nil then
		local BeamStart = self.tool:getTpBonePos( "pejnt_barrel" )
		if self.tool:isLocal() and self.tool:isInFirstPersonView() then
			BeamStart = self.tool:getFpBonePos( "pejnt_barrel" )
		end
		self.effect:setScale( sm.vec3.new( 0.005, 0.005, sm.vec3.length( BeamStart - BeamEnd ) ) )
		self.effect:setPosition( ( BeamStart + BeamEnd ) / 2 )
		self.effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.normalize( BeamStart - BeamEnd ) ) )
		self.effect:setParameter( "color", sm.color.new( self.ModeColors[ self.currentMode ] ) )
	end
end


function Fant_Gravitygun.client_onToggle( self, backwards )
	if self.Modes[ self.currentMode ] == "Distance" then
		self.lastDistance = self.lastDistance - 1
		if self.lastDistance < 0.1 then
			self.lastDistance = 0.1
		end
		self.network:sendToServer( "sv_setDistance", self.lastDistance )
	end
	
	if self.Modes[ self.currentMode ] == "Rotate X" then
		self.network:sendToServer( "sv_setRotation", sm.vec3.new( -1, 0, 0 ) )
	end
	if self.Modes[ self.currentMode ] == "Rotate Y" then
		self.network:sendToServer( "sv_setRotation", sm.vec3.new( 0, -1, 0 ) )
	end
	if self.Modes[ self.currentMode ] == "Rotate Z" then
		self.network:sendToServer( "sv_setRotation", sm.vec3.new( 0, 0, -1 ) )
	end
	return true
end

function Fant_Gravitygun.client_onReload( self )
	if self.Modes[ self.currentMode ] == "Distance" then
		self.lastDistance = self.lastDistance + 1
		self.network:sendToServer( "sv_setDistance", self.lastDistance )
	end
	
	if self.Modes[ self.currentMode ] == "Rotate X" then
		self.network:sendToServer( "sv_setRotation", sm.vec3.new( 1, 0, 0 ) )
	end
	if self.Modes[ self.currentMode ] == "Rotate Y" then
		self.network:sendToServer( "sv_setRotation", sm.vec3.new( 0, 1, 0 ) )
	end
	if self.Modes[ self.currentMode ] == "Rotate Z" then
		self.network:sendToServer( "sv_setRotation", sm.vec3.new( 0, 0, 1 ) )
	end
	return true
end

function Fant_Gravitygun.sv_setDistance( self, distance )
	sm.event.sendToPlayer(  self.tool:getOwner(), "setDistance", distance )
end


function Fant_Gravitygun.sv_setRotation( self, rotation )
	sm.event.sendToPlayer(  self.tool:getOwner(), "setRotation", rotation )
end

function Fant_Gravitygun.cl_onPrimaryUse( self, state )
	if self.tool:getOwner().character == nil then
		return
	end
	if self.fireCooldownTimer <= 0.0 and state == sm.tool.interactState.start then
		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
		-- Timers
		self.fireCooldownTimer = fireMode.fireCooldown
		self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
		self.sprintCooldownTimer = self.sprintCooldown
		setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.05 )
	end
end
