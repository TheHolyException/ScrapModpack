
dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survivalPlayer.lua"
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

Thruster_Hammers = {} or Thruster_Hammers

Fant_ThrusterHammer = class()

local renderables = {
	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_ThrusterHammer/Fant_ThrusterHammer.rend"
}

local renderablesTp = {"$GAME_DATA/Character/Char_Male/Animations/char_male_tp_sledgehammer.rend", "$GAME_DATA/Character/Char_Tools/Char_sledgehammer/char_sledgehammer_tp_animlist.rend"}
local renderablesFp = {"$GAME_DATA/Character/Char_Tools/Char_sledgehammer/char_sledgehammer_fp_animlist.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

Fant_ThrusterHammer.Damage = 25
Fant_ThrusterHammer.Range = 3.0
Fant_ThrusterHammer.Speed = 1.0
Fant_ThrusterHammer.SwingStaminaSpend = 1.5
Fant_ThrusterHammer.fuel = 0

Fant_ThrusterHammer.swingCount = 2
Fant_ThrusterHammer.mayaFrameDuration = 1.0/30.0
Fant_ThrusterHammer.freezeDuration = 0.075

Fant_ThrusterHammer.swings = { "sledgehammer_attack1", "sledgehammer_attack2" }
Fant_ThrusterHammer.swingFrames = { 4.2 * Fant_ThrusterHammer.mayaFrameDuration, 4.2 * Fant_ThrusterHammer.mayaFrameDuration }
Fant_ThrusterHammer.swingExits = { "sledgehammer_exit1", "sledgehammer_exit2" }

function Fant_ThrusterHammer.client_onCreate( self )
	self.isLocal = self.tool:isLocal()
	self:init()
	self.OwnerID = self.tool:getOwner():getId()
	
	self.Effect = sm.effect.createEffect( "Thruster - Level 3" )	
	self.effectTimer = 0
end

function Fant_ThrusterHammer.server_onCreate( self )
	self.OwnerID = self.tool:getOwner():getId()
end

function Fant_ThrusterHammer.client_onRefresh( self )
	self:init()
	self:loadAnimations()
end

function Fant_ThrusterHammer.init( self )
	
	self.attackCooldownTimer = 0.0
	self.freezeTimer = 0.0
	self.pendingRaycastFlag = false
	self.nextAttackFlag = false
	self.currentSwing = 1
	
	self.swingCooldowns = {}
	for i = 1, self.swingCount do
		self.swingCooldowns[i] = 0.0
	end
	
	self.dispersionFraction = 0.001
	
	self.blendTime = 0.2
	self.blendSpeed = 10.0
	
	self.sharedCooldown = 0.0
	self.hitCooldown = 1.0
	self.blockCooldown = 0.5
	self.swing = false
	self.block = false
	
	self.wantBlockSprint = false
	
	if self.animationsLoaded == nil then
		self.animationsLoaded = false
	end
	
	Thruster_Hammers[ self.tool:getOwner():getId() ] = { fuel = self.fuel, tool = "" }
	
	local color = sm.color.new( "df7f01" )
	self.tool:setTpColor( color )
	if self.tool:isLocal() then
		self.tool:setFpColor( color )
	end
end

function Fant_ThrusterHammer.loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			equip = { "sledgehammer_pickup", { nextAnimation = "idle" } },
			unequip = { "sledgehammer_putdown" },
			idle = {"sledgehammer_idle", { looping = true } },
			idleRelaxed = {"sledgehammer_idle_relaxed", { looping = true } },
			
			sledgehammer_attack1 = { "sledgehammer_attack1", { nextAnimation = "sledgehammer_exit1" } },
			sledgehammer_attack2 = { "sledgehammer_attack2", { nextAnimation = "sledgehammer_exit2" } },
			sledgehammer_exit1 = { "sledgehammer_exit1", { nextAnimation = "idle" } },
			sledgehammer_exit2 = { "sledgehammer_exit2", { nextAnimation = "idle" } },
			
			guardInto = { "sledgehammer_guard_into", { nextAnimation = "guardIdle" } },
			guardIdle = { "sledgehammer_guard_idle", { looping = true } },
			guardExit = { "sledgehammer_guard_exit", { nextAnimation = "idle" } },
			
			guardBreak = { "sledgehammer_guard_break", { nextAnimation = "idle" } }--,
			--guardHit = { "sledgehammer_guard_hit", { nextAnimation = "guardIdle" } }
			--guardHit is missing for tp
			
		
		}
	)
	local movementAnimations = {
		idle = "sledgehammer_idle",
		idleRelaxed = "sledgehammer_idle_relaxed",

		runFwd = "sledgehammer_run_fwd",
		runBwd = "sledgehammer_run_bwd",

		sprint = "sledgehammer_sprint",

		jump = "sledgehammer_jump",
		jumpUp = "sledgehammer_jump_up",
		jumpDown = "sledgehammer_jump_down",

		land = "sledgehammer_jump_land",
		landFwd = "sledgehammer_jump_land_fwd",
		landBwd = "sledgehammer_jump_land_bwd",

		crouchIdle = "sledgehammer_crouch_idle",
		crouchFwd = "sledgehammer_crouch_fwd",
		crouchBwd = "sledgehammer_crouch_bwd"
		
	}
    
	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end
    
	setTpAnimation( self.tpAnimations, "idle", 5.0 )
    
	if self.isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "sledgehammer_pickup", { nextAnimation = "idle" } },
				unequip = { "sledgehammer_putdown" },				
				idle = { "sledgehammer_idle",  { looping = true } },
				
				sprintInto = { "sledgehammer_sprint_into", { nextAnimation = "sprintIdle" } },
				sprintIdle = { "sledgehammer_sprint_idle", { looping = true } },
				sprintExit = { "sledgehammer_sprint_exit", { nextAnimation = "idle" } },
				
				sledgehammer_attack1 = { "sledgehammer_attack1", { nextAnimation = "sledgehammer_exit1" } },
				sledgehammer_attack2 = { "sledgehammer_attack2", { nextAnimation = "sledgehammer_exit2" } },
				sledgehammer_exit1 = { "sledgehammer_exit1", { nextAnimation = "idle" } },
				sledgehammer_exit2 = { "sledgehammer_exit2", { nextAnimation = "idle" } },
				
				guardInto = { "sledgehammer_guard_into", { nextAnimation = "guardIdle" } },
				guardIdle = { "sledgehammer_guard_idle", { looping = true } },
				guardExit = { "sledgehammer_guard_exit", { nextAnimation = "idle" } },
				
				guardBreak = { "sledgehammer_guard_break", { nextAnimation = "idle" } },
				guardHit = { "sledgehammer_guard_hit", { nextAnimation = "guardIdle" } }
			
			}
		)
		setFpAnimation( self.fpAnimations, "idle", 0.0 )
	end
	--self.swingCooldowns[1] = self.fpAnimations.animations["sledgehammer_attack1"].info.duration
	self.swingCooldowns[1] = 0.6
	--self.swingCooldowns[2] = self.fpAnimations.animations["sledgehammer_attack2"].info.duration
	self.swingCooldowns[2] = 0.6
	
	self.animationsLoaded = true

end

function Fant_ThrusterHammer.set_currenttool( self, tool )
	self.currentTool = tool
	Thruster_Hammers[ self.tool:getOwner():getId() ].tool = tool
	self.network:sendToClients( "cl_set_currenttool", tool )
	--print( Thruster_Hammers[ self.tool:getOwner():getId() ] )
end

function Fant_ThrusterHammer.cl_set_currenttool( self, tool )
	self.currentTool = tool
	Thruster_Hammers[ self.tool:getOwner():getId() ].tool = tool
	--print(Thruster_Hammers[ self.tool:getOwner():getId() ])
end

function Fant_ThrusterHammer.client_onUpdate( self, dt )
	
	if not self.animationsLoaded then
		return
	end
	
	--synchronized update
	self.attackCooldownTimer = math.max( self.attackCooldownTimer - ( dt * self.Speed ), 0.0 )

	--standard third person updateAnimation
	updateTpAnimations( self.tpAnimations, self.equipped, ( dt * self.Speed ) )
	
	--update
	if self.isLocal then
		
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			self:updateFreezeFrame(self.swings[self.currentSwing], ( dt * self.Speed ))
		end
		
		local preAnimation = self.fpAnimations.currentAnimation

		updateFpAnimations( self.fpAnimations, self.equipped, ( dt * self.Speed ) )
		
		if preAnimation ~= self.fpAnimations.currentAnimation then
			
			-- Ended animation - re-evaluate what next state is
			
			local keepBlockSprint = false
			local endedSwing = preAnimation == self.swings[self.currentSwing] and self.fpAnimations.currentAnimation == self.swingExits[self.currentSwing]
			if self.nextAttackFlag == true and endedSwing == true then
				-- Ended swing with next attack flag
				
				-- Next swing
				self.currentSwing = self.currentSwing + 1
				if self.currentSwing > self.swingCount then
					self.currentSwing = 1
				end
				local params = { name = self.swings[self.currentSwing] }
				self.network:sendToServer( "server_startEvent", params )
				sm.audio.play( "Sledgehammer - Swing" )
				self.pendingRaycastFlag = true
				self.nextAttackFlag = false
				self.attackCooldownTimer = self.swingCooldowns[self.currentSwing]
				keepBlockSprint = true
				
			elseif isAnyOf( self.fpAnimations.currentAnimation, { "guardInto", "guardIdle", "guardExit", "guardBreak", "guardHit" } )  then
				keepBlockSprint = true
			end
			
			--Stop sprint blocking
			self.tool:setBlockSprint(keepBlockSprint)
		end
		
		local isSprinting =  self.tool:isSprinting() 
		if isSprinting and self.fpAnimations.currentAnimation == "idle" and self.attackCooldownTimer <= 0 and not isAnyOf( self.fpAnimations.currentAnimation, { "sprintInto", "sprintIdle" } ) then
			local params = { name = "sprintInto" }
			self:client_startLocalEvent( params )
		end
		
		if ( not isSprinting and isAnyOf( self.fpAnimations.currentAnimation, { "sprintInto", "sprintIdle" } ) ) and self.fpAnimations.currentAnimation ~= "sprintExit" then
			local params = { name = "sprintExit" }
			self:client_startLocalEvent( params )
		end
		if self.fuel <= 0 then
			self.network:sendToServer( "refill" )
		end
	end
end

function Fant_ThrusterHammer.refill( self )
	if self.fuel <= 0 then
		self.fuel = 0
		local inventory = self.tool:getOwner():getInventory()
		--print( inventory)
		if inventory ~= nil then
			if sm.container.canSpend( inventory, obj_consumable_gas, 1 ) then
				sm.container.beginTransaction()
				sm.container.spend( inventory, obj_consumable_gas, 1, true )
				if sm.container.endTransaction() then
					self.fuel = 5
					self.network:sendToClients( "setFuel", self.fuel )
					Thruster_Hammers[ self.tool:getOwner():getId() ].fuel = self.fuel
				end		
			end
		end
	end
end

function Fant_ThrusterHammer.setFuel( self, fuel )
	self.fuel = fuel
	Thruster_Hammers[ self.tool:getOwner():getId() ].fuel = self.fuel
end


function Fant_ThrusterHammer.updateFreezeFrame( self, state, dt )
	local p = 1 - math.max( math.min( self.freezeTimer / self.freezeDuration, 1.0 ), 0.0 )
	local playRate = p * p * p * p
	self.fpAnimations.animations[state].playRate = playRate
	self.freezeTimer = math.max( self.freezeTimer - dt, 0.0 )
end

function Fant_ThrusterHammer.server_startEvent( self, params )
	local player = self.tool:getOwner()
	if player then
		sm.event.sendToPlayer( player, "sv_e_staminaSpend", self.SwingStaminaSpend )
	end
	self.network:sendToClients( "client_startLocalEvent", params )
end

function Fant_ThrusterHammer.client_startLocalEvent( self, params )
	self:client_handleEvent( params )
end

function Fant_ThrusterHammer.client_handleEvent( self, params )
	
	-- Setup animation data on equip
	if params.name == "equip" then
		self.equipped = true		
		--self:loadAnimations()
	elseif params.name == "unequip" then
		self.equipped = false
	end

	if not self.animationsLoaded then
		return
	end
	
	--Maybe not needed
-------------------------------------------------------------------
	
	-- Third person animations
	local tpAnimation = self.tpAnimations.animations[params.name]
	if tpAnimation then
		local isSwing = false
		for i = 1, self.swingCount do
			if self.swings[i] == params.name then
				self.tpAnimations.animations[self.swings[i]].playRate = 1
				isSwing = true
			end
		end
		
		local blend = not isSwing
		setTpAnimation( self.tpAnimations, params.name, blend and 0.2 or 0.0 )
	end
	
	-- First person animations
	if self.isLocal then
		local isSwing = false
		
		for i = 1, self.swingCount do
			if self.swings[i] == params.name then
				self.fpAnimations.animations[self.swings[i]].playRate = 1
				isSwing = true
			end
		end

		if isSwing or isAnyOf( params.name, { "guardInto", "guardIdle", "guardExit", "guardBreak", "guardHit" } ) then
			self.tool:setBlockSprint( true )
		else
			self.tool:setBlockSprint( false )
		end
		
		if params.name == "guardInto" then
			swapFpAnimation( self.fpAnimations, "guardExit", "guardInto", 0.2 )
		elseif params.name == "guardExit" then
			swapFpAnimation( self.fpAnimations, "guardInto", "guardExit", 0.2 )
		elseif params.name == "sprintInto" then
			swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.2 )
		elseif params.name == "sprintExit" then
			swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.2 )
		else
			local blend = not ( isSwing or isAnyOf( params.name, { "equip", "unequip" } ) )
			setFpAnimation( self.fpAnimations, params.name, blend and 0.2 or 0.0 )
		end
		
	end
		
end

--function Fant_ThrusterHammer.sv_n_toggleTumble( self )
--	local character = self.tool:getOwner().character
--	character:setTumbling( not character:isTumbling() )
--end

function Fant_ThrusterHammer.client_onEquippedUpdate( self, primaryState, secondaryState )
	--HACK Enter/exit tumble state when hammering
	--if primaryState == sm.tool.interactState.start then
	--	self.network:sendToServer( "sv_n_toggleTumble" )
	--end

	if self.pendingRaycastFlag then
		local time = 0.0
		local frameTime = 0.0
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			time = self.fpAnimations.animations[self.swings[self.currentSwing]].time
			frameTime = self.swingFrames[self.currentSwing] * self.Speed
		end
		if time >= frameTime and frameTime ~= 0 then
			self.pendingRaycastFlag = false
			local raycastStart = sm.localPlayer.getRaycastStart()
			local direction = sm.localPlayer.getDirection()
			
			local rel_Damage = self.Damage	

			if self:GetDamageData( self ) then
				rel_Damage = rel_Damage * 2
			end
			
			
			sm.melee.meleeAttack( "Sledgehammer", rel_Damage, raycastStart, direction * self.Range, self.tool:getOwner() )
			local success, result = sm.localPlayer.getRaycast( self.Range, raycastStart, direction )
			if success then
				self.freezeTimer = self.freezeDuration
				--print( "result", result )
				self.network:sendToServer( "performHit", { character = result:getCharacter(), body = result:getBody(), shape = result:getShape(), owner = self.tool:getOwner(), damage = rel_Damage } )
			end
		end
	end
	
	--Start attack?
	self.startedSwinging = ( self.startedSwinging or primaryState == sm.tool.interactState.start ) and primaryState ~= sm.tool.interactState.stop and primaryState ~= sm.tool.interactState.null
	if primaryState == sm.tool.interactState.start or ( primaryState == sm.tool.interactState.hold and self.startedSwinging ) then
		
		--Check if we are currently playing a swing
		if self.fpAnimations.currentAnimation == self.swings[self.currentSwing] then
			if self.attackCooldownTimer < self.swingCooldowns[self.currentSwing] - 0.25 then
				self.nextAttackFlag = true
			end
		else
			--Not currently swinging
			--Is the prev attack done?
			if self.attackCooldownTimer <= 0 then
				self.currentSwing = 1
				--Not sprinting and not close to anything
				--Start swinging!
				local params = { name = self.swings[self.currentSwing] }
				self.network:sendToServer( "server_startEvent", params )
				sm.audio.play( "Sledgehammer - Swing" )
				self.pendingRaycastFlag = true
				self.nextAttackFlag = false
				self.attackCooldownTimer = self.swingCooldowns[self.currentSwing]
				self.network:sendToServer( "sv_updateBlocking", false )
			end
		end
	end
	
	--Seondary Block
	--if secondaryState == sm.tool.interactState.start then
	--	if not isAnyOf( self.fpAnimations.currentAnimation, { "guardInto", "guardIdle" } ) and self.attackCooldownTimer <= 0 then
	--		local params = { name = "guardInto" }
	--		self.network:sendToServer( "server_startEvent", params )
	--		self.network:sendToServer( "sv_updateBlocking", true )
	--	end
	--end
	--
	--if secondaryState == sm.tool.interactState.stop or secondaryState == sm.tool.interactState.null then
	--	if isAnyOf( self.fpAnimations.currentAnimation, { "guardInto", "guardIdle" } ) and self.fpAnimations.currentAnimation ~= "guardExit"  then
	--		local params = { name = "guardExit" }
	--		self.network:sendToServer( "server_startEvent", params )
	--		self.network:sendToServer( "sv_updateBlocking", false )
	--	end
	--end
	--
	--return primaryState ~= sm.tool.interactState.null or secondaryState ~= sm.tool.interactState.null
	
	--Secondary destruction
	
	local pos1 = self.tool:getTpBonePos( "jnt_strech1")
	local pos2 = self.tool:getTpBonePos( "jnt_strech2")
	local dir1 = self.tool:getTpBoneDir( "jnt_strech1")
	local dir2 = pos2 - pos1
	if self.Effect:isPlaying() then
		self.Effect:setPosition( pos1 - ( dir1 * 0.0 ) )
		self.Effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), dir2 ) )
	end
	if self.effectTimer ~= nil then
		if self.effectTimer > 0 then
			self.effectTimer = self.effectTimer - 0.04
			if self.effectTimer <= 0 then
				self.effectTimer = 0
				self.Effect:stop()
			end
		end
	else
		self.Effect:stop()
	end
	
	return true, false
	
end

function Fant_ThrusterHammer.performHit( self, data )
	if data.character ~= nil then

		if isSurvival and tostring( data.character:getCharacterType() ) == "9f4fde94-312f-4417-b13b-84029c5d6b52" then
			--print( "Thruster Hammer Farmbot Restriction" )
			return
		end
		
		if Thruster_Hammers[ data.owner:getId() ].fuel <= 0 then
			Thruster_Hammers[ data.owner:getId() ].fuel = 0
			local inventory = data.owner:getInventory()
			if inventory ~= nil then
				if sm.container.canSpend( inventory, obj_consumable_gas, 1 ) then
					sm.container.beginTransaction()
					sm.container.spend( inventory, obj_consumable_gas, 1, true )
					if sm.container.endTransaction() then
						Thruster_Hammers[ data.owner:getId() ].fuel = 5
					end		
				end
			end
		end
		if Thruster_Hammers[ data.owner:getId() ].fuel > 0 or not isSurvival then	
			Thruster_Hammers[ data.owner:getId() ].fuel = Thruster_Hammers[ data.owner:getId() ].fuel - 1
			local dir = data.owner.character:getDirection()
			dir = sm.vec3.normalize( dir )
			dir.z = 0.5
			sm.physics.applyImpulse( data.character, dir * data.character:getMass() * 25 )
			data.character:setTumbling( 150 )
			data.character:applyTumblingImpulse(  dir * data.character:getMass() * 25 )
			
			self.network:sendToClients( "cl_performHit" )
		end
	end
end

function Fant_ThrusterHammer.cl_performHit( self, data )
	self.Effect:start()
	self.effectTimer = 0.75
end

function Fant_ThrusterHammer.client_onEquip( self )
	sm.audio.play( "Sledgehammer - Equip" )
	self.equipped = true

	for k,v in pairs( renderables ) do renderablesTp[#renderablesTp+1] = v end
	for k,v in pairs( renderables ) do renderablesFp[#renderablesFp+1] = v end
	
	self.tool:setTpRenderables( renderablesTp )

	self:init()
	self:loadAnimations()

	setTpAnimation( self.tpAnimations, "equip", 0.0001 )

	if self.isLocal then
		self.tool:setFpRenderables( renderablesFp )
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
		self.network:sendToServer( "set_currenttool",  tostring( sm.localPlayer.getActiveItem() ) )
	end
	local color = sm.color.new( "df7f01" )
	self.tool:setTpColor( color )
	if self.tool:isLocal() then
		self.tool:setFpColor( color )
	end
	--self.network:sendToServer( "sv_updateBlocking", false )
	
end

function Fant_ThrusterHammer.client_onUnequip( self )
	
	sm.audio.play( "Sledgehammer - Unequip" )
	self.equipped = false
	setTpAnimation( self.tpAnimations, "unequip" )
	if self.isLocal and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	if self.isLocal then
		self.network:sendToServer( "set_currenttool",  "" )
	end
--	self.network:sendToServer( "sv_updateBlocking", false )
end

function Fant_ThrusterHammer.server_onDestroy( self )
	Thruster_Hammers[ self.OwnerID ].tool = ""
end

function Fant_ThrusterHammer.client_onDestroy( self )
	Thruster_Hammers[ self.OwnerID ].tool = ""
end

function Fant_ThrusterHammer.sv_updateBlocking( self, isBlocking )
	if self.isBlocking ~= isBlocking then
		sm.event.sendToPlayer( self.tool:getOwner(), "sv_updateBlocking", isBlocking )
	end
	self.isBlocking = isBlocking
end

function Fant_ThrusterHammer.GetDamageData( self )
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
