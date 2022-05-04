
dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_harvestable.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

Fant_Block_Editor = class()

--Fant_Block_Editor.EffectName = "SpudgunSpinner - SpinnerMuzzel"
Fant_Block_Editor.EffectName = "Resourcecollector - TakeOut"

g_SelectedUUID = sm.uuid.new( "8aedf6c2-94e1-4506-89d4-a0227c552f1e" )

local renderables =   {	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Block_Editor/Fant_Block_Editor.rend" }
local renderablesTp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_tp_animlist.rend"}
local renderablesFp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_fertilizer.rend", "$SURVIVAL_DATA/Character/Char_Tools/Char_fertilizer/char_fertilizer_fp_animlist.rend"}

local currentRenderablesTp = {}
local currentRenderablesFp = {}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )


function Fant_Block_Editor.server_onCreate( self )
	self.blockTarget = {}
	self.containerTarget = nil
	self.content1 = {}
	self.content2 = {}
end

function Fant_Block_Editor.client_onCreate( self )
	self:cl_init()
end

function Fant_Block_Editor.client_onRefresh( self )
	self:cl_init()
end

function Fant_Block_Editor.cl_init( self )
	if self.tool:isLocal() then
		self.updateContainer = false
		if self.gui ~= nil then
			self.gui:destroy()
			self.gui = nil
		end
	end
	self:cl_loadAnimations()
end

function Fant_Block_Editor.cl_loadAnimations( self )

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

function Fant_Block_Editor.client_onUpdate( self, dt )

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

function Fant_Block_Editor.client_onEquip( self )

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

function Fant_Block_Editor.client_onUnequip( self )
	self.wantEquipped = false
	self.equipped = false

	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
	self.network:sendToServer( "server_onUnequip" )
end

function Fant_Block_Editor.server_onUnequip( self )

end

function Fant_Block_Editor.client_onEquippedUpdate( self, primaryState, secondaryState )
	if self.tool:isLocal() then
		local valid, result = sm.localPlayer.getRaycast( 20 )
		if primaryState == 1 then
			if valid and result ~= nil then
				if result:getShape() ~= nil then
					self.RotateIndex = 1
					self.network:sendToServer( "sv_set_Block_Target", { shape = result:getShape(), point = result.pointWorld, owner =self.tool:getOwner() } )					
					self:OpenGui()
				end
			else
				self.network:sendToServer( "sv_set_Block_Target", { shape = nil, point = nil, owner = self.tool:getOwner() } )	
			end			
			sm.audio.play( "Button on", self.tool:getOwner().character.worldPosition )
			self.network:sendToServer( "sv_playUseAnimation" )	
		end		
		if secondaryState == 1 then
			if valid and result ~= nil then
				if result:getShape() ~= nil then
					self.RotateIndex = 1
					self.network:sendToServer( "sv_set_Block_Target", { shape = result:getShape(), point = result.pointWorld, owner =self.tool:getOwner() } )					
				end
			else
				self.network:sendToServer( "sv_set_Block_Target", { shape = nil, point = nil, owner = self.tool:getOwner() } )	
			end		
			self.network:sendToServer( "sv_repeat" )	
			sm.audio.play( "Button on", self.tool:getOwner().character.worldPosition )
			
			self.network:sendToServer( "sv_playUseAnimation" )	
		end		
	end
	return true, true
end

function Fant_Block_Editor.OpenGui( self )
	local path = "$GAME_DATA/Gui/Layouts/Fant_Block_Editor.layout"
	self.gui = sm.gui.createGuiFromLayout( path )
	
	self.gui:setButtonCallback( "block_edit_forward", "cl_ButtonClick" )
	self.gui:setButtonCallback( "block_edit_backward", "cl_ButtonClick" )
	self.gui:setButtonCallback( "block_edit_left", "cl_ButtonClick" )
	self.gui:setButtonCallback( "block_edit_right", "cl_ButtonClick" )
	self.gui:setButtonCallback( "block_edit_up", "cl_ButtonClick" )
	self.gui:setButtonCallback( "block_edit_down", "cl_ButtonClick" )
	
	self.gui:setButtonCallback( "block_edit_copy_uuid", "cl_ButtonClick" )
	self.gui:setButtonCallback( "block_edit_paste_uuid", "cl_ButtonClick" )
	
	self.gui:setButtonCallback( "block_edit_copy_inputs", "cl_ButtonClick" )
	self.gui:setButtonCallback( "block_edit_paste_inputs", "cl_ButtonClick" )
	
	self.gui:setButtonCallback( "block_edit_copy_outputs", "cl_ButtonClick" )
	self.gui:setButtonCallback( "block_edit_paste_outputs", "cl_ButtonClick" )
	
	self.gui:setButtonCallback( "block_edit_copy_creation", "cl_ButtonClick" )
	
	
	self.gui:setOnCloseCallback( "cl_onClose" )
	
	self.gui:open()
end

function Fant_Block_Editor.client_onToggle( self, backwards )
	if self.gui ~= nil then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end	
	return true
end

function Fant_Block_Editor.client_onReload( self )
	if self.gui ~= nil then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end	
	return true
end

function Fant_Block_Editor.cl_onClose( self )
	if self.gui ~= nil then
		self.gui:destroy()
		self.gui = nil
	end
end

function Fant_Block_Editor.cl_ButtonClick( self, name )
	if self.tool:isLocal() then
		if name == "block_edit_copy_uuid" then
			if sm.game.getLimitedInventory() then
				sm.gui.chatMessage( "Block Editor Restricted! turn on /unlimited" )
			end
			self.network:sendToServer( "sv_block_edit_copy_uuid" )
			self.gui:close()
		end
		if name == "block_edit_paste_uuid" then
			if sm.game.getLimitedInventory() then
				sm.gui.chatMessage( "Block Editor Restricted! turn on /unlimited" )
			end
			self.network:sendToServer( "sv_block_edit_paste_uuid" )
			self.gui:close()
		end
		
		if name == "block_edit_copy_inputs" then
			self.network:sendToServer( "sv_block_edit_copy_inputs" )
			self.gui:close()
		end
		if name == "block_edit_paste_inputs" then
			self.network:sendToServer( "sv_block_edit_paste_inputs" )
			self.gui:close()
		end
		
		if name == "block_edit_copy_outputs" then
			self.network:sendToServer( "sv_block_edit_copy_outputs" )
			self.gui:close()
		end
		if name == "block_edit_paste_outputs" then
			self.network:sendToServer( "sv_block_edit_paste_outputs" )
			self.gui:close()
		end
		
		if name == "block_edit_copy_creation" then
			self.network:sendToServer( "sv_block_edit_copy_creation" )
			self.gui:close()
		end
		
		local MoveDirection = sm.vec3.new( 0, 0, 0 )
		if name == "block_edit_forward" then
			MoveDirection.x = -1
			self.lastAction = "block_edit_forward"
		end
		if name == "block_edit_backward" then
			MoveDirection.x = 1
			self.lastAction = "block_edit_backward"
		end
		if name == "block_edit_left" then
			MoveDirection.y = -1
			self.lastAction = "block_edit_left"
		end
		if name == "block_edit_right" then
			MoveDirection.y = 1
			self.lastAction = "block_edit_right"
		end
		if name == "block_edit_up" then
			MoveDirection.z = 1
			self.lastAction = "block_edit_up"
		end
		if name == "block_edit_down" then
			MoveDirection.z = -1
			self.lastAction = "block_edit_down"
		end		
		if MoveDirection ~= sm.vec3.new( 0, 0, 0 ) then
			local Angle = self:getAngle( self.tool:getOwner().character:getDirection() ) - 45
			if Angle < 0 then
				Angle = Angle + 360
			end
			if Angle > 360 then
				Angle = Angle - 360
			end		
			local DirectionAngle = math.floor( ( ( Angle ) / 360 ) * 4 )		
			local NewRotateMove = sm.vec3.new( 0, 0, MoveDirection.z )
			if DirectionAngle == 0 then
				NewRotateMove.x = MoveDirection.y
				NewRotateMove.y = -MoveDirection.x
			end
			if DirectionAngle == 1 then
				NewRotateMove.x = MoveDirection.x
				NewRotateMove.y = MoveDirection.y
			end		
			if DirectionAngle == 2 then
				NewRotateMove.x = -MoveDirection.y
				NewRotateMove.y = MoveDirection.x
			end		
			if DirectionAngle == 3 then
				NewRotateMove.x = -MoveDirection.x
				NewRotateMove.y = -MoveDirection.y
			end
			self.network:sendToServer( "sv_blockEdit", { movedir = NewRotateMove } )
		end
		
		sm.audio.play( "Button on", self.tool:getOwner().character.worldPosition )
	end
end

function Fant_Block_Editor.sv_block_edit_copy_creation( self )
	if self.blockTarget == {} or self.blockTarget == nil then
		return
	end
	if self.blockTarget.shape == nil then
		return
	end
	if self.blockTarget.shape:getShapeUuid() == obj_interactive_fant_projector then
		if self.creationProjectorTarget ~= nil then
			local interactable = self.blockTarget.shape:getInteractable()
			if interactable then
				interactable:setPublicData( { projectortarget = self.creationProjectorTarget } )
			end
		end
		self.creationProjectorTarget = nil
	else
		self.creationProjectorTarget = self.blockTarget.shape
	end
end


function Fant_Block_Editor.sv_block_edit_copy_uuid( self )
	if self.blockTarget == {} or self.blockTarget == nil then
		return
	end
	self.block_edit_copy_uuid = nil
	if self.blockTarget.shape ~= nil then
		self.block_edit_copy_uuid = self.blockTarget.shape:getShapeUuid()		
	end
	self.network:sendToClient( self.tool:getOwner(), "cl_set_copy_UUID", { uuid = self.block_edit_copy_uuid } )
	g_SelectedUUID = self.block_edit_copy_uuid
end

function Fant_Block_Editor.cl_set_copy_UUID( self, data )
	self.cl_set_copy_data_UUID = data.uuid
	sm.gui.chatMessage( "Block Editor UUID:\n" .. tostring( self.cl_set_copy_data_UUID ) )
end

function Fant_Block_Editor.sv_block_edit_paste_uuid( self )	
	self.lastAction = "sv_block_edit_paste_uuid"
	
	if sm.game.getLimitedInventory() then
		return
	end
	if self.block_edit_copy_uuid == nil then
		return
	end
	if self.blockTarget == {} or self.blockTarget == nil then
		return
	end
	if self.blockTarget.shape ~= nil then
		local NewShape = nil
		local shapeUUID = self.blockTarget.shape:getShapeUuid()
		local shapeColor = self.blockTarget.shape:getColor()
		local parents = {}
		local children = {}	
		if not sm.item.isBlock( shapeUUID ) and not sm.item.isBlock( self.block_edit_copy_uuid ) then			
			
			local targetInteractable = self.blockTarget.shape:getInteractable()
			if targetInteractable ~= nil then				
				parents = targetInteractable:getParents()
				children = targetInteractable:getChildren()	
				local container1 = targetInteractable:getContainer(0)				
				if container1 ~= nil then
					if not container1:isEmpty() then
						local sortedItems = {}
						for slot = 0, container1:getSize() do									
							local item = container1:getItem( slot )
							if item then
								if item.quantity > 0 then
									table.insert( self.content1, item )
								end
							end
						end
					end
				end
				local container2 = targetInteractable:getContainer(1)		
				if container2 ~= nil then
					if not container2:isEmpty() then
						local sortedItems = {}
						for slot = 0, container2:getSize() do									
							local item = container2:getItem( slot )
							if item then
								if item.quantity > 0 then
									table.insert( self.content2, item )
								end
							end
						end
					end
				end
			end					
			NewShape = self.blockTarget.shape.body:createPart( self.block_edit_copy_uuid, self.blockTarget.shape.localPosition, self.blockTarget.shape.zAxis, self.blockTarget.shape.xAxis, true )
			
			self.blockTarget.shape:destroyShape( 0 )		
			
			local NewtargetInteractable = NewShape:getInteractable()
			if NewtargetInteractable ~= nil then
				self.containerTarget = NewtargetInteractable
				self.network:sendToClient( self.tool:getOwner(), "cl_setContainer" )
				
				if parents ~= {} then				
					for i, parent in pairs( parents ) do
						sm.interactable.connect( parent, NewtargetInteractable )
					end
				end
				if children ~= {} then				
					for i, child in pairs( children ) do
						sm.interactable.connect( NewtargetInteractable, child )
					end
				end							
			end
			
			
		else
			local localPos = self.blockTarget.shape.localPosition
			local size = sm.shape.getBoundingBox( self.blockTarget.shape ) * 4
			if size.x <= 0 then
				size.x = 1
			end
			if size.y <= 0 then
				size.y = 1
			end
			if size.z <= 0 then
				size.z = 1
			end
			NewShape = self.blockTarget.shape.body:createBlock( self.block_edit_copy_uuid, size, localPos , true )
			self.blockTarget.shape:destroyBlock( localPos, size, 0 )
		end

		
		if NewShape ~= nil then
			sm.shape.setColor( NewShape, shapeColor )
			self.blockTarget.shape = NewShape
			self.blockTarget.point = NewShape.worldPosition
		end
	end		
end

function Fant_Block_Editor.sv_block_edit_copy_inputs( self )
	if self.blockTarget == {} or self.blockTarget == nil then
		return
	end
	if self.blockTarget.shape ~= nil then
		local shapeUUID = self.blockTarget.shape:getShapeUuid()
		if not sm.item.isBlock( shapeUUID ) then		
			self.block_edit_copy_inputs = nil
			local targetInteractable = self.blockTarget.shape:getInteractable()
			if targetInteractable ~= nil then				
				self.block_edit_copy_inputs = targetInteractable:getParents()			
			end		
		end
	end
end

function Fant_Block_Editor.sv_block_edit_paste_inputs( self )
	self.lastAction = "sv_block_edit_paste_inputs"
	if self.blockTarget == {} or self.blockTarget == nil then
		return
	end
	if self.blockTarget.shape ~= nil then
		local shapeUUID = self.blockTarget.shape:getShapeUuid()
		if not sm.item.isBlock( shapeUUID ) then		
			local targetInteractable = self.blockTarget.shape:getInteractable()
			if targetInteractable ~= nil then							
				if self.block_edit_copy_inputs ~= {} and self.block_edit_copy_inputs ~= nil then				
					for i, parent in pairs( self.block_edit_copy_inputs ) do
						sm.interactable.connect( parent, targetInteractable )
					end
				end			
			end		
		end
	end
end

function Fant_Block_Editor.sv_block_edit_copy_outputs( self )
	if self.blockTarget == {} or self.blockTarget == nil then
		return
	end
	if self.blockTarget.shape ~= nil then
		local shapeUUID = self.blockTarget.shape:getShapeUuid()
		if not sm.item.isBlock( shapeUUID ) then		
			self.block_edit_copy_outputs = nil
			local targetInteractable = self.blockTarget.shape:getInteractable()
			if targetInteractable ~= nil then				
				self.block_edit_copy_outputs = targetInteractable:getChildren()					
			end		
		end
	end
end

function Fant_Block_Editor.sv_block_edit_paste_outputs( self )
	self.lastAction = "sv_block_edit_paste_outputs"
	if self.blockTarget == {} or self.blockTarget == nil then
		return
	end
	if self.blockTarget.shape ~= nil then
		local shapeUUID = self.blockTarget.shape:getShapeUuid()
		if not sm.item.isBlock( shapeUUID ) then		
			local targetInteractable = self.blockTarget.shape:getInteractable()
			if targetInteractable ~= nil then							
				if self.block_edit_copy_outputs ~= {} and self.block_edit_copy_outputs ~= nil then				
					for i, child in pairs( self.block_edit_copy_outputs ) do
						sm.interactable.connect( targetInteractable, child )
					end
				end			
			end		
		end
	end
end

function Fant_Block_Editor.sv_repeat( self )
	if self.lastAction == nil then
		return
	end
	if self.lastAction == "" then
		return
	end
	if self.lastAction == "sv_block_edit_paste_uuid" then
		self:sv_block_edit_paste_uuid()
	elseif self.lastAction == "sv_block_edit_paste_inputs" then
		self:sv_block_edit_paste_inputs()
	elseif self.lastAction == "sv_block_edit_paste_outputs" then
		self:sv_block_edit_paste_outputs()
	else
		self.network:sendToClient( self.tool:getOwner(), "cl_ButtonClick", self.lastAction )
	end
	
end

function Fant_Block_Editor.sv_set_Block_Target( self, params )
	if self.tool:getOwner() == params.owner then
		self.blockTarget = params
	else
		self.blockTarget = {}
	end
end

function Fant_Block_Editor.sv_blockEdit( self, params )
	if self.blockTarget == {} or self.blockTarget == nil then
		return
	end
	if self.blockTarget.shape ~= nil then
		local NewShape = nil
		local shapeUUID = self.blockTarget.shape:getShapeUuid()
		local shapeColor = self.blockTarget.shape:getColor()
		if sm.item.isBlock( shapeUUID ) then
			local localPos =  self.blockTarget.shape:getClosestBlockLocalPosition( self.blockTarget.point  ) 
			NewShape = self.blockTarget.shape.body:createBlock( shapeUUID, sm.vec3.new( 1, 1, 1 ), localPos + ( params.movedir ), true )
			self.blockTarget.shape:destroyBlock( self.blockTarget.shape:getClosestBlockLocalPosition( self.blockTarget.point ), sm.vec3.new( 1, 1, 1 ), 0 )
		else			
			local parents = {}
			local children = {}	
			
			-- Not working because Axolot!
			-- local joints = {}			
			-- local bearings = {}
			-- local pistons = {}
			
			local targetInteractable = self.blockTarget.shape:getInteractable()
			if targetInteractable ~= nil then				
				parents = targetInteractable:getParents()
				children = targetInteractable:getChildren()	
				-- joints = targetInteractable:getJoints()	
				-- bearings = targetInteractable:getBearings()	
				-- pistons = targetInteractable:getPistons()	
	
				local container1 = targetInteractable:getContainer(0)				
				if container1 ~= nil then
					if not container1:isEmpty() then
						local sortedItems = {}
						for slot = 0, container1:getSize() do									
							local item = container1:getItem( slot )
							if item then
								if item.quantity > 0 then
									table.insert( self.content1, item )
								end
							end
						end
					end
				end
				local container2 = targetInteractable:getContainer(1)		
				if container2 ~= nil then
					if not container2:isEmpty() then
						local sortedItems = {}
						for slot = 0, container2:getSize() do									
							local item = container2:getItem( slot )
							if item then
								if item.quantity > 0 then
									table.insert( self.content2, item )
								end
							end
						end
					end
				end
			end			
			
			NewShape = self.blockTarget.shape.body:createPart( shapeUUID, self.blockTarget.shape.localPosition + ( params.movedir ), self.blockTarget.shape.zAxis, self.blockTarget.shape.xAxis, true )
			
			self.blockTarget.shape:destroyShape( 0 )		
			
			local NewtargetInteractable = NewShape:getInteractable()
			if NewtargetInteractable ~= nil then
				self.containerTarget = NewtargetInteractable
				self.network:sendToClient( self.tool:getOwner(), "cl_setContainer" )
				
				if parents ~= {} then				
					for i, parent in pairs( parents ) do
						sm.interactable.connect( parent, NewtargetInteractable )
					end
				end
				if children ~= {} then				
					for i, child in pairs( children ) do
						sm.interactable.connect( NewtargetInteractable, child )
					end
				end				
				-- if joints ~= {} then
					-- print( "joints", joints )
					-- for i, joint in pairs( joints ) do
						-- sm.interactable.connect( NewtargetInteractable, joint )
					-- end
				-- end
				
				-- if bearings ~= {} then	
					-- print( "bearings", bearings )
					-- for i, bearing in pairs( bearings ) do
						-- sm.interactable.connect( NewtargetInteractable, bearing )
					-- end
				-- end
				
				-- if pistons ~= {} then	
					-- print(pistons)
					-- for i, piston in pairs( pistons ) do
						-- sm.interactable.connect( NewtargetInteractable, piston )
					-- end
				-- end				
			end
		end			

		
		if NewShape ~= nil then
			sm.shape.setColor( NewShape, shapeColor )
			self.blockTarget.shape = NewShape
			self.blockTarget.point = NewShape.worldPosition
		end
	end		
end

function Fant_Block_Editor.cl_setContainer( self )
	self.network:sendToServer( "sv_setContainer" )
end

function Fant_Block_Editor.sv_setContainer( self )
	if self.containerTarget ~= nil and sm.exists( self.containerTarget ) then
		local container1 = self.containerTarget:getContainer(0)		
		local container2 = self.containerTarget:getContainer(1)		
		if container1 ~= nil and self.content1 ~= {} then
			sm.container.beginTransaction()
			for i, item in pairs( self.content1 ) do
				sm.container.collect( container1, item.uuid, item.quantity, 1 )		
			end
			sm.container.endTransaction()
			self.content1 = {}
		end
		if container2 ~= nil and self.content2 ~= {} then
			sm.container.beginTransaction()
			for i, item in pairs( self.content2 ) do
				sm.container.collect( container2, item.uuid, item.quantity, 1 )		
			end
			sm.container.endTransaction()
			self.content2 = {}
		end
		self.containerTarget = nil
	end
end

function Fant_Block_Editor.getAngle( self, direction )
	local angle = math.atan2( direction.y, direction.x )
    local degrees = 180 * angle / math.pi
    return ( 360 + math.floor( degrees ) ) % 360
end



function Fant_Block_Editor.sv_playUseAnimation( self )
	self.network:sendToClients("cl_playUseAnimation" )
end

function Fant_Block_Editor.cl_playUseAnimation( self )
	if self.tool:isLocal() then
		setFpAnimation( self.fpAnimations, "use", 0.25 )
	end
	setTpAnimation( self.tpAnimations, "use", 10.0 )
end