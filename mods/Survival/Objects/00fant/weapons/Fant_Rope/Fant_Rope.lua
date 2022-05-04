dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"
dofile "$SURVIVAL_DATA/Scripts/game/SurvivalGame.lua"

Fant_Rope = class()

local soilbagRenderables = { "$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Rope/Fant_Rope.rend" }

local renderablesTp = { "$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_soilbag.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_soilbag/char_soilbag_tp.rend" }
local renderablesFp = { "$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_soilbag.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_soilbag/char_soilbag_fp.rend" }

sm.tool.preloadRenderables( soilbagRenderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Fant_Rope.client_onCreate( self )
	self:client_onRefresh()
end

function Fant_Rope.client_onRefresh( self )
	self:cl_updateRenderables()
	self:cl_loadAnimations()
end 
 
function Fant_Rope.cl_loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			idle = { "soilbag_idle", { looping = true } },
			use = { "soilbag_use", { nextAnimation = "idle" } },
			pickup = { "soilbag_pickup", { nextAnimation = "idle" } },
			putdown = { "soilbag_putdown" }
		
		}
	)
	local movementAnimations = {

		idle = "soilbag_idle",
		
		runFwd = "soilbag_run_fwd",
		runBwd = "soilbag_run_bwd",
		
		jump = "soilbag_jump",
		jumpUp = "soilbag_jump_up",
		jumpDown = "soilbag_jump_down",

		land = "soilbag_jump_land",
		landFwd = "soilbag_jump_land_fwd",
		landBwd = "soilbag_jump_land_bwd",

		crouchIdle = "soilbag_crouch_idle",
		crouchFwd = "soilbag_crouch_fwd",
		crouchBwd = "soilbag_crouch_bwd"
	}
	
	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end
	
	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				idle = { "soilbag_idle", { looping = true } },
				use = { "soilbag_use", { nextAnimation = "idle" } },
				equip = { "soilbag_pickup", { nextAnimation = "idle" } },
				unequip = { "soilbag_putdown" }
			}
		)
	end
	setTpAnimation( self.tpAnimations, "idle", 5.0 )
	self.blendTime = 0.2
	
end

function Fant_Rope.cl_updateRenderables( self )

	local currentRenderablesTp = {}
	local currentRenderablesFp = {}
	
	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	for k,v in pairs( soilbagRenderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( soilbagRenderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	
	self.tool:setTpRenderables( currentRenderablesTp )
	if self.tool:isLocal() then
		self.tool:setFpRenderables( currentRenderablesFp )
	end
	
end

function Fant_Rope.client_onDestroy( self )

end

function Fant_Rope.client_onUpdate( self, dt )

	-- First person animation	
	local isCrouching =  self.tool:isCrouching() 
	
	if self.tool:isLocal() then
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end
	
	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end
	
	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight 
	local totalWeight = 0.0
	
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt
	
		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )
			
			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "use" ) then
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
	
end

function Fant_Rope.client_onEquippedUpdate( self, primaryState, secondaryState, forceBuildActive )
	if self.tool:isLocal() then
		if forceBuildActive then
			self.hook = nil
			return false, false
		end
		
		local CanShoot = false
		if sm.game.getLimitedInventory() then
			if sm.container.canSpend( sm.localPlayer.getInventory(), weapon_Fant_Rope, 1 ) then
				CanShoot = true
			end
		else
			CanShoot = true
		end
		
		local valid, result = sm.localPlayer.getRaycast( 50 )
		if valid and CanShoot then
			
			if primaryState == sm.tool.interactState.start then
				if result:getShape() then
					if self.hook == nil then
						if result:getShape().uuid == sm.uuid.new( "db262014-1014-41c0-87aa-095e38bea934" ) then
							self.hook = result:getShape()
							self.network:sendToServer( "sv_use" )
						else
							self.hook = nil
						end
					else
						if result:getShape() then
							
							self.network:sendToServer( "sv_addRope", { hook = self.hook, target = result:getShape() } )							
						end
						self.hook = nil
					end
				else
					self.hook = nil
				end
				--print( "self.hook", self.hook )
			end
			if secondaryState == sm.tool.interactState.start then
				
				if result:getShape() then
					if result:getShape().uuid == sm.uuid.new( "db262014-1014-41c0-87aa-095e38bea934" ) then
						self.network:sendToServer( "sv_removeRope", { hook = result:getShape(), target = nil } )
						-- Clear
						self.hook = nil
					end
				else
					self.hook = nil
				end
				--print( "result:getShape()", result:getShape() )
			end
		end
	end
	return true, true
end


function Fant_Rope.sv_use( self )
	self.network:sendToClients( "cl_use" )
end

function Fant_Rope.cl_use( self )
	if self.tool:isLocal() then
		setFpAnimation( self.fpAnimations, "use", 0.25 )
	end
	setTpAnimation( self.tpAnimations, "use", 10.0 )
end

function Fant_Rope.client_onEquip( self )
	if self.tool:isLocal() then
		self:client_onRefresh()
	end
	
	self.wantEquipped = true
	
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.tool:isLocal() then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function Fant_Rope.client_onUnequip( self )
	self.wantEquipped = false
	self.equipped = false
	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	
	self.hook = nil
end

function Fant_Rope.sv_addRope( self, data )
	if data.hook then
		self.network:sendToClients( "cl_use" )
		--print( "sv_addRope", data )
		data.hook.interactable:setPublicData( data )

		sm.container.beginTransaction()
		sm.container.spend( self.tool:getOwner():getInventory(), weapon_Fant_Rope, 1 )
		sm.container.endTransaction()
	end
	
end

function Fant_Rope.sv_removeRope( self, data )
	if data.hook then
		self.network:sendToClients( "cl_use" )
		--print( "sv_removeRope", data )
		data.hook.interactable:setPublicData( data )
		
		--sm.container.beginTransaction()
		--sm.container.collect( self.tool:getOwner():getInventory(), weapon_Fant_Rope, 1 )
		--sm.container.endTransaction()
	end
end
