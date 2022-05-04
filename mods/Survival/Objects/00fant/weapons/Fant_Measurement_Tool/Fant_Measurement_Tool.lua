
dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

Fant_Measurement_Tool = class()

local renderables =   {	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Measurement_Tool/Fant_Measurement_Tool.rend" }
local renderablesTp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_tp_animlist.rend"}
local renderablesFp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_fp_animlist.rend"}

local currentRenderablesTp = {}
local currentRenderablesFp = {}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Fant_Measurement_Tool.server_onCreate( self )

end

function Fant_Measurement_Tool.client_onCreate( self )
	self:cl_init()
end

function Fant_Measurement_Tool.client_onRefresh( self )
	self:cl_init()
end

function Fant_Measurement_Tool.cl_init( self )
	self:cl_loadAnimations()
end

function Fant_Measurement_Tool.cl_loadAnimations( self )

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

function Fant_Measurement_Tool.client_onUpdate( self, dt )

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

function Fant_Measurement_Tool.client_onEquip( self )

	self.wantEquipped = true

	currentRenderablesTp = {}
	currentRenderablesFp = {}

	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	local color = sm.color.new( "df7f01" )

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
		
		
		
		if self.effectHitPos == nil then
			self.effectHitPos = sm.effect.createEffect( "ShapeRenderable" )			
			self.effectHitPos:setParameter( "uuid", sm.uuid.new( "5f41af56-df4c-4837-9b3c-10781335757f" ) )
			self.effectHitPos:start()
			local Color = sm.color.new( 1, 0, 0 )
			self.effectHitPos:setParameter( "color", Color )
			self.effectHitPos:setPosition( sm.vec3.new( 1, 1, 1 ) )
			self.effectHitPos:setScale( sm.vec3.new( 1.05, 1.05, 1.05 ) * 0.25 )			
			--self.effectHitPos:setRotation(  )
		end
			
	end
	
end

function Fant_Measurement_Tool.client_onUnequip( self )
	self.wantEquipped = false
	self.equipped = false

	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
		
		
		
		if self.effectHitPos ~= nil then
			self.effectHitPos:stop()
			self.effectHitPos:destroy()
			self.effectHitPos = nil
		end
		if self.effectArea ~= nil then
			self.effectArea:stop()
			self.effectArea:destroy()
			self.effectArea = nil
		end
		if self.effectMassCenter_1 ~= nil then
			self.effectMassCenter_1:stop()
			self.effectMassCenter_1:destroy()
			self.effectMassCenter_1 = nil
		end
		if self.effectMassCenter_2 ~= nil then
			self.effectMassCenter_2:stop()
			self.effectMassCenter_2:destroy()
			self.effectMassCenter_2 = nil
		end
		if self.effectMassCenter_3 ~= nil then
			self.effectMassCenter_3:stop()
			self.effectMassCenter_3:destroy()
			self.effectMassCenter_3 = nil
		end
		
	end
end

function Fant_Measurement_Tool.client_onEquippedUpdate( self, primaryState, secondaryState )
	
	if self.tool:isLocal() then
		local valid, result = sm.localPlayer.getRaycast( 200 )
		if valid and result ~= nil then
			local Pos = result.pointWorld * 0.25 * 16
			local PosX = math.floor( Pos.x )
			local PosY = math.floor( Pos.y )
			local PosZ = math.floor( Pos.z )
			local RoundedPos = ( sm.vec3.new( PosX, PosY, PosZ ) + sm.vec3.new( 0.5, 0.5, 0.5 ) ) * 4 / 16
			
			if self.effectHitPos ~= nil then
				self.effectHitPos:setPosition( RoundedPos )
			end
			
			if self.effectArea ~= nil and self.lastMeasurementPos ~= nil then
				local MiddlePos = ( RoundedPos + self.lastMeasurementPos ) / 2
				local Size = (RoundedPos - self.lastMeasurementPos ) * 4
				Size.x = math.abs( Size.x ) + 1
				Size.y = math.abs( Size.y ) + 1
				Size.z = math.abs( Size.z ) + 1
				if Size.x < 1 then
					Size.x = 1
				end
				if Size.y < 1 then
					Size.y = 1
				end
				if Size.z < 1 then
					Size.z = 1
				end
				self.effectArea:setPosition( MiddlePos )
				self.effectArea:setScale( sm.vec3.new( Size.x + 0.025, Size.y + 0.025, Size.z + 0.025 ) * 0.25 )			
			end
			
			if primaryState == 1 then
				if self.effectArea == nil then
					self.effectArea = sm.effect.createEffect( "ShapeRenderable" )			
					self.effectArea:setParameter( "uuid", sm.uuid.new( "5f41af56-df4c-4837-9b3c-10781335757f" ) )
					self.effectArea:start()
					local Color = sm.color.new( 0, 1, 0 )
					self.effectArea:setParameter( "color", Color )
					self.effectArea:setPosition( RoundedPos )
					self.effectArea:setScale( sm.vec3.new( 1.05, 1.05, 1.05 ) * 0.25 )			
					--self.effectHitPos:setRotation(  )
				end
				if self.lastMeasurementPos == nil then
					self.lastMeasurementPos = RoundedPos
					sm.gui.chatMessage( "Measurement point set..." )
				else
					local MeasureVector = self.lastMeasurementPos - RoundedPos
					
					local MeasureVectorX = sm.vec3.new( MeasureVector.x, 0, 0 )
					local MeasureVectorY = sm.vec3.new( 0, MeasureVector.y, 0 )
					local MeasureVectorZ = sm.vec3.new( 0, 0, MeasureVector.z )
					
					local distance = 1
					if MeasureVector ~= sm.vec3.new( 0, 0, 0 ) then
						distance = math.floor( sm.vec3.length( MeasureVector * 0.25 * 16  ) + 1 ) 
					end
					
					local distanceX = 1
					if MeasureVectorX ~= sm.vec3.new( 0, 0, 0 ) then
						distanceX = math.floor( sm.vec3.length( MeasureVectorX * 0.25 * 16  ) + 1 ) 
					end
					
					local distanceY = 1
					if MeasureVectorY ~= sm.vec3.new( 0, 0, 0 ) then
						distanceY = math.floor( sm.vec3.length( MeasureVectorY * 0.25 * 16  ) + 1 ) 
					end
					
					local distanceZ = 1
					if MeasureVectorZ ~= sm.vec3.new( 0, 0, 0 ) then
						distanceZ = math.floor( sm.vec3.length( MeasureVectorZ * 0.25 * 16  ) + 1 ) 
					end
					local Info = "#ffffffMeasurement Distance: #ff0000" .. tostring( distance )
					Info = Info .. "\n" .. "#ffffffX: #ff0000" .. tostring( distanceX )
					Info = Info .. "\n" .. "#ffffffY: #ff0000" .. tostring( distanceY )
					Info = Info .. "\n" .. "#ffffffZ: #ff0000" .. tostring( distanceZ )
					Info = Info .. "\n" .. "#ffffffBlocks: #ff0000" .. tostring( distanceX * distanceY * distanceZ )
					sm.gui.chatMessage( Info )
					self.lastMeasurementPos = nil
					
					
					if self.effectArea ~= nil then
						self.effectArea:stop()
						self.effectArea:destroy()
						self.effectArea = nil
					end
				end
				sm.audio.play( "Construction - Block placed", self.tool:getOwner().character.worldPosition )
				self.network:sendToServer( "sv_playUseAnimation" )	
			end
			
			if secondaryState == 1 then			
				if self.effectMassCenter_1 ~= nil then
					self.effectMassCenter_1:stop()
					self.effectMassCenter_1:destroy()
					self.effectMassCenter_1 = nil
				end
				if self.effectMassCenter_2 ~= nil then
					self.effectMassCenter_2:stop()
					self.effectMassCenter_2:destroy()
					self.effectMassCenter_2 = nil
				end
				if self.effectMassCenter_3 ~= nil then
					self.effectMassCenter_3:stop()
					self.effectMassCenter_3:destroy()
					self.effectMassCenter_3 = nil
				end
				sm.audio.play( "Construction - Block placed", self.tool:getOwner().character.worldPosition )
				self.network:sendToServer( "sv_playUseAnimation" )	
				local Body = result:getBody()
				if Body ~= nil then				
					local MassCenterPos = Body:getCenterOfMassPosition()
					local Color = sm.color.new( 0, 0, 1 )
					local Thinkness = 0.1
					local Length = 100
					local Text = "#ff0000Dynamic #ffffffObject Mass Center!"
					
					
					if Body:isStatic() then
						local P1, P2 = Body:getWorldAabb()
						MassCenterPos = ( P1 + P2 ) * 0.5
						Text = "#ff0000Static #ffffffObject Bounding Box Center!"
					end			
					self.effectMassCenter_1 = sm.effect.createEffect( "ShapeRenderable" )			
					self.effectMassCenter_1:setParameter( "uuid", sm.uuid.new( "5f41af56-df4c-4837-9b3c-10781335757f" ) )
					self.effectMassCenter_1:start()
					
					self.effectMassCenter_1:setParameter( "color", Color )
					self.effectMassCenter_1:setPosition( MassCenterPos )
					self.effectMassCenter_1:setScale( sm.vec3.new( Length, Thinkness, Thinkness ) * 0.25 )		

					
					self.effectMassCenter_2 = sm.effect.createEffect( "ShapeRenderable" )			
					self.effectMassCenter_2:setParameter( "uuid", sm.uuid.new( "5f41af56-df4c-4837-9b3c-10781335757f" ) )
					self.effectMassCenter_2:start()
					
					self.effectMassCenter_2:setParameter( "color", Color )
					self.effectMassCenter_2:setPosition( MassCenterPos )
					self.effectMassCenter_2:setScale( sm.vec3.new( Thinkness, Length, Thinkness ) * 0.25 )		
					
					
					self.effectMassCenter_3 = sm.effect.createEffect( "ShapeRenderable" )			
					self.effectMassCenter_3:setParameter( "uuid", sm.uuid.new( "5f41af56-df4c-4837-9b3c-10781335757f" ) )
					self.effectMassCenter_3:start()
					
					self.effectMassCenter_3:setParameter( "color", Color )
					self.effectMassCenter_3:setPosition( MassCenterPos )
					self.effectMassCenter_3:setScale( sm.vec3.new( Thinkness, Thinkness, Length ) * 0.25 )		

					sm.gui.chatMessage( Text )
				end
			end
		end
	end
	return true, true
end

function Fant_Measurement_Tool.client_onToggle( self, backwards )
	if self.tool:isLocal() then
		
	end
	return true
end

function Fant_Measurement_Tool.client_onReload( self )
	if self.tool:isLocal() then
		
	end
	return true
end


function Fant_Measurement_Tool.sv_playUseAnimation( self )
	self.network:sendToClients("cl_playUseAnimation" )
end

function Fant_Measurement_Tool.cl_playUseAnimation( self )
	if self.tool:isLocal() then
		setFpAnimation( self.fpAnimations, "use", 0.25 )
	end
	setTpAnimation( self.tpAnimations, "use", 10.0 )
end