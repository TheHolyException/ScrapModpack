
dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

Fant_Mutliconnecttool = class()

--Fant_Mutliconnecttool.EffectName = "SpudgunSpinner - SpinnerMuzzel"
Fant_Mutliconnecttool.EffectName = "Resourcecollector - TakeOut"

local renderables =   {	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Mutliconnecttool/Fant_Mutliconnecttool.rend" }
local renderablesTp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_tp_animlist.rend"}
local renderablesFp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_fp_animlist.rend"}

local currentRenderablesTp = {}
local currentRenderablesFp = {}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Fant_Mutliconnecttool.server_onCreate( self )
	self.connection_Outputs = {}
	self.connection_Inputs = {}
	self.connection_Direction = 0
end

function Fant_Mutliconnecttool.client_onCreate( self )
	self:cl_init()
	self.cl_connection_Inputs = {}
	self.cl_connection_Outputs = {}
	self.cl_direction = 0
	self.drawEffects = {}
end

function Fant_Mutliconnecttool.client_onRefresh( self )
	self:cl_init()
end

function Fant_Mutliconnecttool.cl_init( self )
	self:cl_loadAnimations()
end

function Fant_Mutliconnecttool.cl_loadAnimations( self )

	self.tpAnimations = createTpAnimations(
			self.tool,
			{
				idle = { "fertilizer_idle", { looping = true } },
				use = { "fertilizer_paint", { nextAnimation = "idle" } },
				sprint = { "fertilizer_sprint" },
				pickup = { "fertilizer_pickup", { nextAnimation = "idle" } },
				putdown = { "fertilizer_putdown" }

			}
		)
		local movementAnimations = {

			idle = "fertilizer_idle",
			idleRelaxed = "fertilizer_idle_relaxed",

			runFwd = "fertilizer_run_fwd",
			runBwd = "fertilizer_run_bwd",
			sprint = "fertilizer_sprint",

			jump = "fertilizer_jump",
			jumpUp = "fertilizer_jump_up",
			jumpDown = "fertilizer_jump_down",

			land = "fertilizer_jump_land",
			landFwd = "fertilizer_jump_land_fwd",
			landBwd = "fertilizer_jump_land_bwd",

			crouchIdle = "fertilizer_crouch_idle",
			crouchFwd = "fertilizer_crouch_fwd",
			crouchBwd = "fertilizer_crouch_bwd"
		}

		for name, animation in pairs( movementAnimations ) do
			self.tool:setMovementAnimation( name, animation )
		end

		if self.tool:isLocal() then
			self.fpAnimations = createFpAnimations(
				self.tool,
				{
					idle = { "fertilizer_idle", { looping = true } },

					sprintInto = { "fertilizer_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
					sprintIdle = { "fertilizer_sprint_idle", { looping = true } },
					sprintExit = { "fertilizer_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },

					use = { "fertilizer_paint", { nextAnimation = "idle" } },

					equip = { "fertilizer_pickup", { nextAnimation = "idle" } },
					unequip = { "fertilizer_putdown" }
				}
			)
		end
		setTpAnimation( self.tpAnimations, "idle", 5.0 )
		self.blendTime = 0.2

end

function Fant_Mutliconnecttool.client_onUpdate( self, dt )

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

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
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
			if animation.time >= animation.info.duration - self.blendTime and not animation.looping then
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
	
	
	self:drawConnections()
end

function Fant_Mutliconnecttool.client_onEquip( self )

	self.wantEquipped = true

	currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	local color = sm.color.new( "0000ff" )
	if self.connection_Direction == 1 then
		color = sm.color.new( "ff0000" )
	end
	if self.connection_Direction == -1 then
		color = sm.color.new( "00ff00" )
	end
	self.tool:setTpRenderables( currentRenderablesTp )
	self.tool:setTpColor( color )
	if self.tool:isLocal() then
		self.tool:setFpRenderables( currentRenderablesFp )
		self.tool:setFpColor( color )
	end

	self:cl_loadAnimations()

	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.tool:isLocal() then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function Fant_Mutliconnecttool.client_onUnequip( self )
	self.wantEquipped = false
	self.equipped = false

	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	self.network:sendToServer( "server_onUnequip" )
	
	if tableCount( self.drawEffects ) > 0 then
		for i, k in pairs( self.drawEffects ) do
			k:destroy()
			k = nil
		end
	end
	self.drawEffects = {}
	self.cl_connection_Inputs = {}
	self.cl_connection_Outputs = {}
	self.cl_direction = 0
end

function Fant_Mutliconnecttool.server_onUnequip( self )
	self.connection_Inputs = {}
	self.connection_Outputs = {}
	self.connection_Direction = 0
end

function Fant_Mutliconnecttool.client_onEquippedUpdate( self, primaryState, secondaryState )
	if self.tool:isLocal() then
		local valid, result = sm.localPlayer.getRaycast( 7.5 )

		local shootPosition = self.tool:getPosition() + ( sm.camera.getRight() * 0.125 ) + ( sm.camera.getUp() * 0.4 )
		if primaryState == sm.tool.interactState.start then
			self:doEffect()
			self.network:sendToServer( "sv_n_action", { primary = true, secondary = false, position = shootPosition, shape = result:getShape() } )
			self.network:sendToServer( "sv_playUseAnimation" )	
		end
		if secondaryState == sm.tool.interactState.start then
			self:doEffect()
			self.network:sendToServer( "sv_n_action", { primary = false, secondary = true, position = shootPosition, shape = result:getShape() } )
			self.network:sendToServer( "sv_playUseAnimation" )	
		end
	end
	return true, true
end

function Fant_Mutliconnecttool.sv_n_action( self, params )
	self.network:sendToClients( "cl_doEffect" )
	local interactableTarget = self:getInteractableFromShape( params.shape )
	local clear = false
	if interactableTarget then
		if self.connection_Direction == 0 then
			if params.primary then
				self.connection_Direction = 1
				sm.gui.chatMessage( "From Left Select to Right Select!\n--->" )
			else
				self.connection_Direction = -1
				sm.gui.chatMessage( "From Right Select to Left Select!\n<---" )
			end
		end
		if self.connection_Direction >= 0 then
			if params.primary then	
				table.insert( self.connection_Outputs, interactableTarget )
				sm.gui.chatMessage( "Left Selected: " ..  tostring( tableCount( self.connection_Outputs ) ) .. "\nPress Rightclick to Connect" )
			end
			if params.secondary then	
				table.insert( self.connection_Inputs, interactableTarget )
				connect( self.connection_Outputs, self.connection_Inputs )
				sm.gui.chatMessage( "Connected!" )
				clear = true
			end
		end
		
		if self.connection_Direction <= 0 then
			if params.secondary then	
				table.insert( self.connection_Inputs, interactableTarget )
				sm.gui.chatMessage( "Right Selected: " ..  tostring( tableCount( self.connection_Inputs ) ) .. "\nPress Leftclick to Connect" )
			end
			if params.primary then	
				table.insert( self.connection_Outputs, interactableTarget )
				connect( self.connection_Outputs, self.connection_Inputs )
				sm.gui.chatMessage( "Connected!" )
				clear = true
			end
		end
	else
		clear = true
	end
	if clear then
		self.connection_Inputs = {}
		self.connection_Outputs = {}
		self.connection_Direction = 0
		sm.gui.chatMessage( "Selection Clear!" )
	end
	self.network:sendToClients( "cl_updateData", { connection_Inputs = self.connection_Inputs, connection_Outputs = self.connection_Outputs, direction = self.connection_Direction } )
end

function Fant_Mutliconnecttool.cl_updateData( self, data )
	self.cl_connection_Inputs = data.connection_Inputs
	self.cl_connection_Outputs = data.connection_Outputs
	self.cl_direction = data.direction
	print( self.cl_connection_Inputs )
	print( self.cl_connection_Outputs )
	print( self.cl_direction )
	local color = sm.color.new( "0000ff" )
	if self.connection_Direction == 1 then
		color = sm.color.new( "ff0000" )
	end
	if self.connection_Direction == -1 then
		color = sm.color.new( "00ff00" )
	end
	self.tool:setTpColor( color )
	if self.tool:isLocal() then
		self.tool:setFpColor( color )
	end
end

function connect( connectA, connectB )
	if tableCount( connectA ) > 0 and tableCount( connectB ) > 0 then
		for i, A in pairs( connectA ) do 
			for i, B in pairs( connectB ) do 
				if A ~= nil and B ~= nil then 
					if A ~= B then 
						sm.interactable.connect( A, B )
					end
				end
			end
		end
	end
end

function tableCount( list )
	if list == nil then
		return 0
	end
	local count = 0
	for i, k in pairs( list ) do 
		if k ~= nil  then 
			count = count + 1
		end
	end
	return count
end

function Fant_Mutliconnecttool.getInteractableFromShape( self, shape )
	if shape then
		return shape:getInteractable()
	end
	return nil
end

function Fant_Mutliconnecttool.cl_doEffect( self )
	if not self.tool:isLocal() and self.tool:isEquipped() then
		self:doEffect()
	end
end

function Fant_Mutliconnecttool.doEffect( self )
	if self.tool:isLocal() then
		setFpAnimation( self.fpAnimations, "use", 0.25 )
	end
	setTpAnimation( self.tpAnimations, "use", 10.0 )

	if self.tool:isLocal() and self.tool:isInFirstPersonView() then
		local effectPos = sm.localPlayer.getFpBonePos( "jnt_fertilizer" )
		if effectPos then
			local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.localPlayer.getDirection() )

			local fovScale = ( sm.camera.getFov() - 45 ) / 45

			local xOffset45 = sm.localPlayer.getRight() * 0.12
			local yOffset45 = sm.localPlayer.getDirection() * 0.65
			local zOffset45 = sm.localPlayer.getUp() * -0.1
			local offset45 = xOffset45 + yOffset45 + zOffset45

			local xOffset90 = sm.localPlayer.getRight() * 0.375
			local yOffset90 = sm.localPlayer.getDirection() * 0.65
			local zOffset90 = sm.localPlayer.getUp() * -0.3
			local offset90 = xOffset90 + yOffset90 + zOffset90

			local offset = sm.vec3.lerp( offset45, offset90, fovScale )

			--sm.effect.playEffect( "Itemtool - FPFertilizerUse", effectPos + offset, nil, rot )
			sm.effect.playEffect( self.EffectName, effectPos + offset, nil, rot )
		end
	else
		--sm.effect.playHostedEffect("Itemtool - FertilizerUse", self.tool:getOwner():getCharacter(), "jnt_fertilizer" )
		sm.effect.playHostedEffect( self.EffectName, self.tool:getOwner():getCharacter(), "jnt_fertilizer" )
	end
end

function Fant_Mutliconnecttool.drawConnections( self )
	if self.cl_direction == 0 then
		if tableCount( self.drawEffects ) > 0 then
			for i, k in pairs( self.drawEffects ) do
				k:destroy()
				k = nil
			end
			self.drawEffects = {}
		end
	end
	if self.cl_direction > 0 then
		--Outputs
		for i, k in pairs( self.cl_connection_Outputs ) do
			self:drawIcon( i, k:getShape().worldPosition )
		end
	end
	if self.cl_direction < 0 then
		--Inputs
		for i, k in pairs( self.cl_connection_Inputs ) do
			self:drawIcon( i, k:getShape().worldPosition )
		end
	end
end

function Fant_Mutliconnecttool.drawIcon( self, id, pos )
	if self.drawEffects[ id ] == nil then
		self.drawEffects[ id ] = sm.gui.createNameTagGui()
		self.drawEffects[ id ]:setRequireLineOfSight( false )
		self.drawEffects[ id ]:setMaxRenderDistance( 50 )
		self.drawEffects[ id ]:setWorldPosition( pos )
		if self.cl_direction > 0 then
			self.drawEffects[ id ]:setText( "Text", "#ff0000".. tostring( id ) .. "->" )	
		else
			self.drawEffects[ id ]:setText( "Text", "#00ff00".. "->" .. tostring( id ) )	
		end
		self.drawEffects[ id ]:open()
	end	
end


function Fant_Mutliconnecttool.sv_playUseAnimation( self )
	self.network:sendToClients("cl_playUseAnimation" )
end

function Fant_Mutliconnecttool.cl_playUseAnimation( self )
	if self.tool:isLocal() then
		setFpAnimation( self.fpAnimations, "use", 0.25 )
	end
	setTpAnimation( self.tpAnimations, "use", 10.0 )
end











