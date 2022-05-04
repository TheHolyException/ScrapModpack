
dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

Fant_Waypoint_Marker = class()

local renderables =   {	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Waypoint_Marker/Fant_Waypoint_Marker.rend" }
local renderablesTp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_tp_animlist.rend"}
local renderablesFp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_fp_animlist.rend"}

local currentRenderablesTp = {}
local currentRenderablesFp = {}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

cl_Waypoints = cl_Waypoints or {}

function Fant_Waypoint_Marker.server_onCreate( self )

end

function Fant_Waypoint_Marker.client_onCreate( self )
	self:cl_init()
end

function Fant_Waypoint_Marker.client_onRefresh( self )
	self:cl_init()
end

function Fant_Waypoint_Marker.cl_init( self )
	self.ActiveWaypointDisplay = false
	if cl_Waypoints ~= nil then
		if cl_Waypoints ~= {} then
			for i, waypoint in pairs( cl_Waypoints ) do
				if waypoint.effect ~= nil then
					waypoint.effect:stop()
					waypoint.effect:destroy()
					waypoint.effect = nil
				end
				waypoint = nil
			end
		end
	end
	cl_Waypoints = {}
	self.cl_WaypointCount = 0
	
	self:cl_loadAnimations()
end

function Fant_Waypoint_Marker.cl_loadAnimations( self )

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

function Fant_Waypoint_Marker.client_onUpdate( self, dt )

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
	
	if self.tool:isLocal() then
		self:showWaypoints()
	end
	
end

function Fant_Waypoint_Marker.client_onEquip( self )

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
		
		if self.ActiveWaypointDisplay == false then
			self.ActiveWaypointDisplay = true
			local InfoText = ""
			InfoText = InfoText .. "\n#0000ff[WAYPOINT MARKER TOOL]" .. "\n"
			InfoText = InfoText .. "#ff0000Left Click: #ffffffAdd Waypoint" .. "\n"
			InfoText = InfoText .. "#ff0000Right Click: #ffffffSend Waypoints to the UNITFACER in AIM" .. "\n"
			InfoText = InfoText .. "#ff0000R: #ffffffRead Waypoints from the UNITFACER in AIM" .. "\n"
			InfoText = InfoText .. "#ff0000Q: #ffffffDelete ALL current Waypoints in the Tool"
			
			sm.gui.chatMessage( InfoText )		
		end
	end
	
end

function Fant_Waypoint_Marker.client_onUnequip( self )
	self.wantEquipped = false
	self.equipped = false

	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	self.network:sendToServer( "server_onUnequip" )
	
	if self.tool:isLocal() then
		if self.ActiveWaypointDisplay == true then
			self.ActiveWaypointDisplay = false
			if cl_Waypoints ~= {} then
				for i, waypoint in pairs( cl_Waypoints ) do
					if waypoint.effect ~= nil then
						waypoint.effect:stop()
						waypoint.effect:destroy()
						waypoint.effect = nil
					end
				end
			end
		end
	end
end

function Fant_Waypoint_Marker.server_onUnequip( self )

end

function Fant_Waypoint_Marker.client_onEquippedUpdate( self, primaryState, secondaryState )
	if self.tool:isLocal() then
		if primaryState == 1 then
			local valid, result = sm.localPlayer.getRaycast( 200 )
			if valid and result ~= nil then
				self:addWaypoint( result.pointWorld )
				sm.audio.play( "Construction - Block placed", self.tool:getOwner().character.worldPosition )
				sm.gui.chatMessage( "Waypoint Added!" )
				self.network:sendToServer( "sv_playUseAnimation" )	
			end
		end
		if secondaryState == 1 then
			local valid, result = sm.localPlayer.getRaycast( 200 )
			if valid and result ~= nil then
				if result:getShape() then
					if tostring( result:getShape():getShapeUuid() ) == "979b2a00-dbc4-4275-8fd6-1afb5933d383" then
						if result:getShape():getInteractable() then					
							local PositionList = {}
							if cl_Waypoints ~= {} then
								for i, waypoint in pairs( cl_Waypoints ) do
									table.insert( PositionList, waypoint.worldPosition )
								end
							end
							local params = { shape = result:getShape(), waypoints = PositionList }
							self.network:sendToServer( "sv_setWaypointsToUnitfacer", params )
							sm.audio.play( "Blueprint - Open", self.tool:getOwner().character.worldPosition )
							sm.gui.chatMessage( "Waypoints sended to Unitfacer!" )
							self.network:sendToServer( "sv_playUseAnimation" )	
						end
					end
				end
			end
		end
	end
	return true, true
end

function Fant_Waypoint_Marker.sv_setWaypointsToUnitfacer( self, params )
	if params.shape ~= nil then
		if params.shape:getInteractable() ~= nil then
			sm.interactable.setPublicData( params.shape:getInteractable(), params.waypoints )
		end
	end
end

function Fant_Waypoint_Marker.client_onToggle( self, backwards )
	if self.tool:isLocal() then
		self:removeWaypoints()
		sm.audio.play( "Blueprint - Delete", self.tool:getOwner().character.worldPosition )
		sm.gui.chatMessage( "Waypoints Deleted!" )
	end
	return true
end

function Fant_Waypoint_Marker.client_onReload( self )
	if self.tool:isLocal() then
		local valid, result = sm.localPlayer.getRaycast( 200 )
		if valid and result ~= nil then
			if result:getShape() then
				if result:getShape():getInteractable() then										
					local params = { shape = result:getShape(), owner = self.tool:getOwner() }
					self.network:sendToServer( "sv_getWaypointData", params )
					sm.audio.play( "Blueprint - Share", self.tool:getOwner().character.worldPosition )
					sm.gui.chatMessage( "Waypoints Loaded!" )
				end
			end
		end
	end
	return true
end

function Fant_Waypoint_Marker.sv_getWaypointData( self, params )
	if self.tool:getOwner() == params.owner then
		if params.shape ~= nil then
			if params.shape:getInteractable() ~= nil then
				local WaypointData = sm.interactable.getPublicData( params.shape:getInteractable() )
				if WaypointData ~= nil then				
					self.network:sendToClient( self.tool:getOwner(), "cl_getWaypointData", { WaypointData = WaypointData, owner = params.owner } )
				end
			end
		end
	end
end

function Fant_Waypoint_Marker.cl_getWaypointData( self, params )
	if self.tool:getOwner() == params.owner then
		if cl_Waypoints ~= nil then
			if cl_Waypoints ~= {} then
				for i, waypoint in pairs( cl_Waypoints ) do
					if waypoint.effect ~= nil then
						waypoint.effect:stop()
						waypoint.effect:destroy()
						waypoint.effect = nil
					end
					waypoint = nil
				end
			end
		end
		cl_Waypoints = {}
		self.cl_WaypointCount = 0
		self.ActiveWaypointDisplay = false
		for i, waypointPosition in pairs( params.WaypointData ) do
			newWaypoint = { effect = nil, worldPosition = waypointPosition }
			table.insert( cl_Waypoints, newWaypoint )
			self.cl_WaypointCount = self.cl_WaypointCount + 1
			self.ActiveWaypointDisplay = true
		end
	end
end

function Fant_Waypoint_Marker.addWaypoint( self, position )
	self.cl_WaypointCount = self.cl_WaypointCount + 1	
	newWaypoint = { effect = nil, worldPosition = position }
	table.insert( cl_Waypoints, newWaypoint )
end

function Fant_Waypoint_Marker.removeWaypoints( self )
	if cl_Waypoints ~= {} then
		for i, waypoint in pairs( cl_Waypoints ) do
			if waypoint.effect ~= nil then
				waypoint.effect:stop()
				waypoint.effect:destroy()
				waypoint.effect = nil
			end
			waypoint = nil
		end
	end
	cl_Waypoints = {}
	self.cl_WaypointCount = 0
end

function Fant_Waypoint_Marker.showWaypoints( self )
	if self.cl_WaypointCount > 1 and self.ActiveWaypointDisplay == true then
		local LastPosition = nil
		for i, waypoint in pairs( cl_Waypoints ) do
			if LastPosition ~= nil then			
				if waypoint.effect == nil then
					waypoint.effect = sm.effect.createEffect( "ShapeRenderable" )			
					waypoint.effect:setParameter( "uuid", sm.uuid.new( "f7881097-9320-4667-b2ba-4101c72b8730" ) )
					waypoint.effect:start()
				end
				if waypoint.effect ~= nil and LastPosition ~= nil then
					local Start = waypoint.worldPosition + sm.vec3.new( 0, 0, 1 )
					local End = LastPosition + sm.vec3.new( 0, 0, 1 )
					local Relative = Start - End				
					local Length = sm.vec3.length( Relative )
					if Length > 0 then
						local Direction = sm.vec3.normalize( Relative )
						local Color = sm.color.new( 1, 0, 0 )
						local Rotation = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), Direction )
						local WaypointEffectThinkness = 0.1
						
						waypoint.effect:setScale( sm.vec3.new( WaypointEffectThinkness, WaypointEffectThinkness, Length ) )
						waypoint.effect:setPosition( ( Start + End ) / 2 )
						waypoint.effect:setRotation( Rotation )
						waypoint.effect:setParameter( "color", Color )		
					end
				end				
			end
			LastPosition = waypoint.worldPosition
		end
	end
end


function Fant_Waypoint_Marker.sv_playUseAnimation( self )
	self.network:sendToClients("cl_playUseAnimation" )
end

function Fant_Waypoint_Marker.cl_playUseAnimation( self )
	if self.tool:isLocal() then
		setFpAnimation( self.fpAnimations, "use", 0.25 )
	end
	setTpAnimation( self.tpAnimations, "use", 10.0 )
end







