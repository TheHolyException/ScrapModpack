
dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_wireless.lua"

Fant_Remotegun = class()

local renderables =   {"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_RemoteGun/Fant_Remotegun.rend" }
local renderablesTp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_tp_animlist.rend"}
local renderablesFp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_fp_animlist.rend"}

local currentRenderablesTp = {}
local currentRenderablesFp = {}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

Colors = {
	sm.color.new( "eeeeee" ),
	sm.color.new( "f5f071" ),
	sm.color.new( "cbf66f" ),
	sm.color.new( "68ff88" ),
	sm.color.new( "7eeded" ),
	sm.color.new( "4c6fe3" ),
	sm.color.new( "ae79f0" ),
	sm.color.new( "ee7bf0" ),
	sm.color.new( "f06767" ),
	sm.color.new( "eeaf5c" ),
	sm.color.new( "7f7f7f" ),
	sm.color.new( "e2db13" ),
	sm.color.new( "a0ea00" ),
	sm.color.new( "19e753" ),
	sm.color.new( "2ce6e6" ),
	sm.color.new( "0a3ee2" ),
	sm.color.new( "7514ed" ),
	sm.color.new( "cf11d2" ),
	sm.color.new( "d02525" ),
	sm.color.new( "df7f00" ),
	sm.color.new( "4a4a4a" ),
	sm.color.new( "817c00" ),
	sm.color.new( "577d07" ),
	sm.color.new( "0e8031" ),
	sm.color.new( "118787" ),
	sm.color.new( "0f2e91" ),
	sm.color.new( "500aa6" ),
	sm.color.new( "720a74" ),
	sm.color.new( "7c0000" ),
	sm.color.new( "673b00" ),
	sm.color.new( "222222" ),
	sm.color.new( "323000" ),
	sm.color.new( "375000" ),
	sm.color.new( "064023" ),
	sm.color.new( "0a4444" ),
	sm.color.new( "0a1d5a" ),
	sm.color.new( "35086c" ),
	sm.color.new( "520653" ),
	sm.color.new( "560202" ),
	sm.color.new( "472800" )
}


function Fant_Remotegun.server_onCreate( self )
	self.sv_index = 1
end

function Fant_Remotegun.client_onCreate( self )
	self:cl_init()
	self.colorIndex = 1
end

function Fant_Remotegun.client_onRefresh( self )
	self:cl_init()
end

function Fant_Remotegun.cl_init( self )
	self:cl_loadAnimations()
end

function Fant_Remotegun.cl_loadAnimations( self )

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

function Fant_Remotegun.client_onUpdate( self, dt )

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
	
end

function Fant_Remotegun.client_onEquip( self )

	self.wantEquipped = true

	currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	
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

function Fant_Remotegun.client_onUnequip( self )
	self.wantEquipped = false
	self.equipped = false

	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	self.network:sendToServer( "server_onUnequip" )
	
	
end

function Fant_Remotegun.server_onUnequip( self )

end

function Fant_Remotegun.client_onEquippedUpdate( self, primaryState, secondaryState )
	if self.tool:isLocal() then
		if primaryState >= 1 then		
			--Channel[ tostring( Colors[ self.sv_index ] ) ] = true
			self.hasPressedLeftClick = true
			self.network:sendToServer( "sv_setColorChannel", { index = self.colorIndex, state = true, toggle = false } )
			
		end
		if primaryState == 0 and self.hasPressedLeftClick ~= nil then		
			--Channel[ tostring( Colors[ self.sv_index ] ) ] = false
			self.hasPressedLeftClick = nil
			self.network:sendToServer( "sv_setColorChannel", { index = self.colorIndex, state = false } )
			self.network:sendToServer( "sv_playUseAnimation" )	
		end

		if secondaryState == 1 then
			--Channel[ tostring( Colors[ self.sv_index ] ) ] = not Channel[ tostring( Colors[ self.sv_index ] ) ]
			self.network:sendToServer( "sv_setColorChannel", { index = self.colorIndex, state = false, toggle = true } )
			self.network:sendToServer( "sv_playUseAnimation" )	
		end

		self.tool:setFpColor( Colors[ self.colorIndex ] )
	end
	self.tool:setTpColor( Colors[ self.colorIndex ] )
	return true, true
end

function Fant_Remotegun.sv_setColorChannel( self, params )
	if params.toggle == true then
		Channel[ tostring( Colors[ params.index ] ) ] = not Channel[ tostring( Colors[ params.index ] ) ]
	else
		Channel[ tostring( Colors[ params.index ] ) ] = params.state
	end
end


function Fant_Remotegun.client_onToggle( self, backwards )
	if self.tool:isLocal() then
		if self.colorGui == nil then
			local path = "$GAME_DATA/Gui/Layouts/Fant_Remotegun.layout"
			self.colorGui = sm.gui.createGuiFromLayout( path )
			for i = 0, 39 do
				self.colorGui:setButtonCallback( "ColorButton" .. tostring( i ), "cl_onColorButtonClick" )
			end

			self.colorGui:setOnCloseCallback( "cl_onClose" )
			self.colorGui:open()
		end
	end
	return true
end

function Fant_Remotegun.cl_onColorButtonClick( self, name )
	self.colorIndex = tonumber( name:match( '%d+' ) ) + 1
	self.colorGui:close()
	self.colorGui:destroy()
	self.colorGui = nil
	self.network:sendToServer( "sv_setIndex", self.colorIndex )
	--print( "Color:", Colors[self.colorIndex] )
end

function Fant_Remotegun.cl_onClose( self )
	if self.colorGui ~= nil then
		self.colorGui:destroy()
		self.colorGui = nil
	end
end

function Fant_Remotegun.client_onReload( self )
	if self.tool:isLocal() then
		
	end
	return true
end

function Fant_Remotegun.sv_setIndex( self, index )
	self.sv_index = index
end


function Fant_Remotegun.sv_playUseAnimation( self )
	self.network:sendToClients("cl_playUseAnimation" )
end

function Fant_Remotegun.cl_playUseAnimation( self )
	if self.tool:isLocal() then
		setFpAnimation( self.fpAnimations, "use", 0.25 )
	end
	setTpAnimation( self.tpAnimations, "use", 10.0 )
end