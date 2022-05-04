
dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survivalPlayer.lua"
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua")
dofile( "$SURVIVAL_DATA/Scripts/game/harvestable/LootHarvestable.lua")

Fant_Fork = class()

local renderables = {
	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Fork/Fant_Fork.rend"
}

local renderablesTp = {"$GAME_DATA/Character/Char_Male/Animations/char_male_tp_sledgehammer.rend", "$GAME_DATA/Character/Char_Tools/Char_sledgehammer/char_sledgehammer_tp_animlist.rend"}
local renderablesFp = {"$GAME_DATA/Character/Char_Tools/Char_sledgehammer/char_sledgehammer_fp_animlist.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

Fant_Fork.Damage = 24
Fant_Fork.Range = 3.3
Fant_Fork.Speed = 1.25
Fant_Fork.SwingStaminaSpend = 4
Fant_Fork.GatherAreaSize = 10

Fant_Fork.swingCount = 2
Fant_Fork.mayaFrameDuration = 1.0/30.0
Fant_Fork.freezeDuration = 0.075

Fant_Fork.swings = { "sledgehammer_attack1", "sledgehammer_attack2" }
Fant_Fork.swingFrames = { 4.2 * Fant_Fork.mayaFrameDuration, 4.2 * Fant_Fork.mayaFrameDuration }
Fant_Fork.swingExits = { "sledgehammer_exit1", "sledgehammer_exit2" }

function Fant_Fork.client_onCreate( self )
	self.isLocal = self.tool:isLocal()
	self:init()
end

function Fant_Fork.server_onCreate( self )
	self.areaTrigger = sm.areaTrigger.createBox( sm.vec3.new( self.GatherAreaSize, self.GatherAreaSize, self.GatherAreaSize ), sm.vec3.new( 0, 0, 0 ), sm.quat.identity(), sm.areaTrigger.filter.all )			
end

function Fant_Fork.client_onRefresh( self )
	self:init()
	self:loadAnimations()
end

function Fant_Fork.init( self )
	
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
end

function Fant_Fork.loadAnimations( self )

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

function Fant_Fork.client_onUpdate( self, dt )
	
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
	end
	
end

function Fant_Fork.updateFreezeFrame( self, state, dt )
	local p = 1 - math.max( math.min( self.freezeTimer / self.freezeDuration, 1.0 ), 0.0 )
	local playRate = p * p * p * p
	self.fpAnimations.animations[state].playRate = playRate
	self.freezeTimer = math.max( self.freezeTimer - dt, 0.0 )
end

function Fant_Fork.server_startEvent( self, params )
	local player = self.tool:getOwner()
	if player then
		sm.event.sendToPlayer( player, "sv_e_staminaSpend", self.SwingStaminaSpend )
	end
	self.network:sendToClients( "client_startLocalEvent", params )
end

function Fant_Fork.client_startLocalEvent( self, params )
	self:client_handleEvent( params )
end

function Fant_Fork.client_handleEvent( self, params )
	
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

--function Fant_Fork.sv_n_toggleTumble( self )
--	local character = self.tool:getOwner().character
--	character:setTumbling( not character:isTumbling() )
--end
function Fant_Fork.server_onFixedUpdate( self, dt )
	self.areaTrigger:setWorldPosition( self.tool:getOwner().character.worldPosition )
end

function Fant_Fork.GatherObject( self, PlayerInventory, UUID, AMOUNT )
	if sm.container.canCollect( PlayerInventory, UUID, AMOUNT ) then
		sm.container.beginTransaction()
		sm.container.collect( PlayerInventory, UUID, AMOUNT, true )
		if sm.container.endTransaction() then
			return true
		end		
	end
	return false
end

function Fant_Fork.getGatherAmount( self, player, startValue )
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

function Fant_Fork.OnHit( self, worldPosition )
	--print( self.areaTrigger:getContents() )
	
	for _, result in ipairs(  self.areaTrigger:getContents() ) do
		if sm.exists( result ) then
			local Type = tostring( type( result ) )
			local PlayerInventory = self.tool:getOwner():getInventory()
			if PlayerInventory ~= nil then
				if type( result ) == "Harvestable" then	
					if result:getType() == "mature"  then
						local data = result:getData()
						if data then
	
							if self:GatherObject( PlayerInventory, sm.uuid.new( data["harvest"] ), self:getGatherAmount( self.tool:getOwner(), data.amount ) ) then
								self:GatherObject( PlayerInventory,sm.uuid.new(  data["seed"] ), self:getGatherAmount( self.tool:getOwner(), randomStackAmountAvg2() ) )						
								sm.effect.playEffect( "Plants - Picked", result.worldPosition )
								sm.harvestable.create( hvs_soil, result.worldPosition, result.worldRotation )
								sm.harvestable.destroy( result )
							end							
						end				
					elseif result:getType() == "oil" then
						local data = result:getData()
						if data then
							if self:GatherObject( PlayerInventory, sm.uuid.new( data["harvest"] ), self:getGatherAmount( self.tool:getOwner(), math.random( 1, 3 ) ) ) then		
								sm.effect.playEffect( "Oilgeyser - Picked", result.worldPosition )
								sm.harvestable.create( hvs_farmables_growing_oilgeyser, result.worldPosition, result.worldRotation )
								sm.harvestable.destroy( result )	
							end
						end	
					elseif result:getType() == "flower" then
						local data = result:getData()
						if data then
							if self:GatherObject( PlayerInventory, sm.uuid.new( data["harvest"] ), self:getGatherAmount( self.tool:getOwner(), math.random( 1, 4 ) ) ) then		
								sm.effect.playEffect( "Pigmentflower - Picked", result.worldPosition )
								sm.harvestable.create( hvs_farmables_growing_pigmentflower, result.worldPosition, result.worldRotation )
								sm.harvestable.destroy( result )	
							end
						end	
					elseif result:getType() == "corn" then
						local data = result:getData()
						if data then
							if self:GatherObject( PlayerInventory, sm.uuid.new( data["harvest"] ), self:getGatherAmount( self.tool:getOwner(), math.random( 1, 4 ) ) ) then
								sm.effect.playEffect( "Cotton - Picked", result.worldPosition )
								sm.harvestable.create( hvs_farmables_growing_cornplant, result.worldPosition, result.worldRotation )
								sm.harvestable.destroy( result )		
							end
						end	
					elseif result:getType() == "clam" then
						local data = result:getData()
						if data then
							if self:GatherObject( PlayerInventory, sm.uuid.new( data["harvest"] ), self:getGatherAmount( self.tool:getOwner(), math.random( 1, 4 ) ) ) then
								sm.effect.playEffect( "SlimyClam - Bubbles", result.worldPosition )	
								sm.harvestable.create( hvs_farmables_slimyclam_broken, result.worldPosition, result.worldRotation )
								sm.harvestable.destroy( result )		
							end
						end												
					elseif result:getType() == "honey" then
						local data = result:getData()
						if data then
							if self:GatherObject( PlayerInventory, sm.uuid.new( data["harvest"] ), self:getGatherAmount( self.tool:getOwner(), math.random( 2, 4 ) ) ) then
								sm.effect.playEffect( "beehive - beeswarm", result.worldPosition )	
								sm.harvestable.create( hvs_farmables_beehive_broken, result.worldPosition, result.worldRotation )
								sm.harvestable.destroy( result )		
							end
						end												
					elseif result:getType() == "cotton" then
						local data = result:getData()
						if data then
							if self:GatherObject( PlayerInventory, sm.uuid.new( data["harvest"] ), self:getGatherAmount( self.tool:getOwner(), 1 ) ) then
								sm.effect.playEffect( "Cotton - Picked", result.worldPosition )	
								sm.harvestable.create( hvs_farmables_growing_cottonplant, result.worldPosition, result.worldRotation )
								sm.harvestable.destroy( result )		
							end
						end												
					elseif result:getType() == "filler" then	
						local lootObject  = g_lootHarvestables[result["id"]]
						if lootObject then 
							if self:GatherObject( PlayerInventory, lootObject["uuid"], lootObject["quantity"] ) then
								sm.harvestable.destroy( result )	
							end
						end					
					elseif result:getData() ~= "" then
						local data = result:getData()
						if data then
							if data["destroyEffect"] == "LootCrate - Destroy" then
								local lootTable = self.saved and self.saved.lootTable or nil
								if lootTable == nil then
									lootTable = "loot_crate_standard" 
								end
								local lootList = SelectLoot( lootTable )
								local canDestroy = false
								for i = 1, #lootList do								 
									local GatherItemAmount = lootList[i].quantity or 1
									if self:GatherObject( PlayerInventory, lootList[i].uuid, GatherItemAmount )	then
										canDestroy = true
									end
								end	
								if canDestroy then
									sm.effect.playEffect( "LootCrate - Destroy", result.worldPosition )		
									sm.harvestable.destroy( result )		
								end
							end			
						end												
					else					
						print( "Muh" )
					end		
				end		
			end
		end
	end
end

function Fant_Fork.client_onEquippedUpdate( self, primaryState, secondaryState )
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
			end
			self.network:sendToServer( "OnHit", raycastStart )
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
	return true, false
	
end

function Fant_Fork.client_onEquip( self )
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
	end
	
	--self.network:sendToServer( "sv_updateBlocking", false )
end

function Fant_Fork.client_onUnequip( self )
	
	sm.audio.play( "Sledgehammer - Unequip" )
	self.equipped = false
	setTpAnimation( self.tpAnimations, "unequip" )
	if self.isLocal and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	
	--self.network:sendToServer( "sv_updateBlocking", false )
end

function Fant_Fork.sv_updateBlocking( self, isBlocking )
	if self.isBlocking ~= isBlocking then
		sm.event.sendToPlayer( self.tool:getOwner(), "sv_updateBlocking", isBlocking )
	end
	self.isBlocking = isBlocking
end

function Fant_Fork.GetDamageData( self )
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
