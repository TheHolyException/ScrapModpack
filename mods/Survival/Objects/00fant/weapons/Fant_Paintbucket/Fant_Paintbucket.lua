dofile "$GAME_DATA/Scripts/game/AnimationUtil.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua"

Fant_Paintbucket = class()

local emptyRenderables = {
	"$SURVIVAL_DATA/Objects/00fant/weapons/Fant_Paintbucket/Fant_Paintbucket.rend"
}

local renderablesTp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_tp_bucket.rend", "$SURVIVAL_DATA/Character/Char_bucket/char_bucket_tp_animlist.rend"}
local renderablesFp = {"$SURVIVAL_DATA/Character/Char_Male/Animations/char_male_fp_bucket.rend", "$SURVIVAL_DATA/Character/Char_bucket/char_bucket_fp_animlist.rend"}

local currentRenderablesTp = {}
local currentRenderablesFp = {}

sm.tool.preloadRenderables( emptyRenderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

local FireCooldown = 0.40
local FireVelocity = 10.0
local SpreadDeg = 10

Paint_Colors = {
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

function Fant_Paintbucket.client_onCreate( self )
	self:client_onRefresh()
end

function Fant_Paintbucket.client_onRefresh( self )
	if self.tool:isLocal() then
		self.activeItem = nil
		self.wasOnGround = true
	end
	self.colorIndex = 1
	self.filter = 0
	
	self.UseCustomColor = false
	self.RValue = 255
	self.GValue = 255
	self.BValue = 255
	
	if self.filter == 0 then
		sm.gui.chatMessage( "Color all" )
	end
	if self.filter == 1 then
		sm.gui.chatMessage( "Color Same Type" )
	end
	if self.filter == 2 then
		sm.gui.chatMessage( "Color Single" )
	end
		
	
	self:client_updateBucketRenderables()
	self:loadAnimations()
	
end

function Fant_Paintbucket.loadAnimations( self )
	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			idle = { "bucket_idle", { looping = true } },
			use = { "bucket_use_full", { nextAnimation = "idle" } },
			useempty = { "bucket_use_empty", { nextAnimation = "idle" } },
			pickup = { "bucket_pickup", { nextAnimation = "idle" } },
			putdown = { "bucket_putdown" }
		
		}
	)
	local movementAnimations = {
		idle = "bucket_idle",
		
		runFwd = "bucket_run",
		runBwd = "bucket_runbwd",
		
		sprint = "bucket_sprint_idle",
		
		jump = "bucket_jump",
		jumpUp = "bucket_jump_up",
		jumpDown = "bucket_jump_down",

		land = "bucket_jump_land",
		landFwd = "bucket_jump_land_fwd",
		landBwd = "bucket_jump_land_bwd",

		crouchIdle = "bucket_crouch_idle",
		crouchFwd = "bucket_crouch_run",
		crouchBwd = "bucket_crouch_runbwd"
	}
    
	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end
    
	setTpAnimation( self.tpAnimations, "idle", 5.0 )
    
	if self.tool:isLocal() then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				idle = { "bucket_idle", { looping = true } },
				use = { "bucket_use_full", { nextAnimation = "idle" } },
				useempty = { "bucket_use_empty", { nextAnimation = "idle" } },
				
				sprintInto = { "bucket_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintIdle = { "bucket_sprint_idle", { looping = true } },
				sprintExit = { "bucket_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				
				jump = { "bucket_jump", { nextAnimation = "idle" } },
				land = { "bucket_jump_land", { nextAnimation = "idle" } },
				
				equip = { "bucket_pickup", { nextAnimation = "idle" } },
				unequip = { "bucket_putdown" }
				
			}
		)
	end
	
	self.fireCooldownTimer = 0.0
	self.blendTime = 0.2
end

function Fant_Paintbucket.client_onUpdate( self, dt )

	-- First person animation	
	local isSprinting =  self.tool:isSprinting() 
	local isCrouching =  self.tool:isCrouching() 
	local isOnGround =  self.tool:isOnGround()
	
	if self.tool:isLocal() then
		if self.equipped then
			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not self.tool:isSprinting() and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end
			
			if not isOnGround and self.wasOnGround and self.fpAnimations.currentAnimation ~= "jump" then
				swapFpAnimation( self.fpAnimations, "land", "jump", 0.2 )
			elseif isOnGround and not self.wasOnGround and self.fpAnimations.currentAnimation ~= "land" then
				swapFpAnimation( self.fpAnimations, "jump", "land", 0.2 )
			end
			
		end
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
		
		self.wasOnGround = isOnGround
	end
	
	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end
	if self.tool:isLocal() then
		local activeItem = sm.localPlayer.getActiveItem()
		if self.activeItem ~= activeItem then
			self.activeItem = activeItem
	
			self.network:sendToServer( "server_network_updateBucketRenderables" )
		end
	end

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight 
	local totalWeight = 0.0
	
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )
			
			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "use" or name == "useempty" ) then
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
	
	-- Timers
	self.fireCooldownTimer = math.max( self.fireCooldownTimer - dt, 0.0 )
end

function Fant_Paintbucket.client_onEquip( self )

	--print("client_onEquip")
	if self.tool:isLocal() then
		self.activeItem = nil
	end
	self:client_updateBucketRenderables( nil )
	
	self:loadAnimations()
	
	self.wantEquipped = true
	self.aiming = false
	
	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )
	if self.tool:isLocal() then
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end

end

function Fant_Paintbucket.server_network_updateBucketRenderables( self )
	self.network:sendToClients( "client_updateBucketRenderables" )
end

function Fant_Paintbucket.client_updateBucketRenderables( self )

	local bucketRenderables = {}
	bucketRenderables = emptyRenderables

	currentRenderablesTp = {}
	currentRenderablesFp = {}
	
	for k,v in pairs( renderablesTp ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( renderablesFp ) do currentRenderablesFp[#currentRenderablesFp+1] = v end
	for k,v in pairs( bucketRenderables ) do currentRenderablesTp[#currentRenderablesTp+1] = v end
	for k,v in pairs( bucketRenderables ) do currentRenderablesFp[#currentRenderablesFp+1] = v end

	self.tool:setTpRenderables( currentRenderablesTp )

	if self.UseCustomColor then
		self.tool:setTpColor( sm.color.new( self.RValue / 255, self.GValue / 255, self.BValue / 255, 1 ) )
	else
		self.tool:setTpColor( Paint_Colors[ self.colorIndex ] )
	end
	
	if self.tool:isLocal() then
		-- Sets bucket renderable, change this to change the mesh
		self.tool:setFpRenderables( currentRenderablesFp )
		
		if self.UseCustomColor then
			self.tool:setFpColor(sm.color.new( self.RValue / 255, self.GValue / 255, self.BValue / 255, 1 )  )
		else
			self.tool:setFpColor( Paint_Colors[ self.colorIndex ] )
		end
	end

end

function Fant_Paintbucket.client_onUnequip( self )
	--print("client_onUnequip")
	if self.tool:isLocal() then
		self.activeItem = nil
	end
	self.wantEquipped = false
	self.equipped = false
	setTpAnimation( self.tpAnimations, "putdown" )
	if self.tool:isLocal() and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
end

function Fant_Paintbucket.calculateFirePosition( self )
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

function Fant_Paintbucket.calculateTpMuzzlePos( self )
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

-- Interact
function Fant_Paintbucket.client_onEquippedUpdate( self, primaryState, secondaryState, forceBuildActive )
	local activeItem = sm.localPlayer.getActiveItem()
	local Inventory = self.tool:getOwner():getInventory()
	local canPaint = not sm.game.getEnableAmmoConsumption()
	local isCrouching = sm.localPlayer.getPlayer().character:isCrouching()
	if not isCrouching then
		if primaryState == sm.tool.interactState.start then	
			if Inventory and canPaint == false then
				if sm.container.canSpend( Inventory, obj_consumable_inkammo, 1 ) then
					canPaint = true
				end
			end
			if canPaint then
				local rayStart = sm.localPlayer.getRaycastStart()
				local rayDir = sm.localPlayer.getDirection()
				local success, result = sm.physics.raycast( rayStart, rayStart + rayDir * 7.5, sm.localPlayer.getPlayer().character )
				if success then
					self:cl_paintAnimation()
					if self.filter == 0 then
						self.network:sendToServer( "sv_colorall", { colorIndex = self.colorIndex, body = result:getBody(), UseCustomColor = self.UseCustomColor, RValue = self.RValue , GValue = self.GValue , BValue = self.BValue } )
					end
					if self.filter == 1 then
						if result:getShape() then
							self.network:sendToServer( "sv_colorOnly", { colorIndex = self.colorIndex, body = result:getBody(), filterUUID = result:getShape():getShapeUuid(), UseCustomColor = self.UseCustomColor, RValue = self.RValue , GValue = self.GValue , BValue = self.BValue } )
						end
					end
					if self.filter == 2 then
						if result:getShape() then
							self.network:sendToServer( "sv_colorSingle", { unpaint = false, colorIndex = self.colorIndex, position = result.pointWorld,  shape = result:getShape(), body = result:getBody(), filterUUID = result:getShape():getShapeUuid(), UseCustomColor = self.UseCustomColor, RValue = self.RValue , GValue = self.GValue , BValue = self.BValue } )
						end
					end
				end
				return true, false
			end
		end	
		if secondaryState == sm.tool.interactState.start then			
			if Inventory and canPaint == false then
				if sm.container.canSpend( Inventory, obj_consumable_inkammo, 1 ) then
					canPaint = true
				end
			end
			if canPaint then
				local rayStart = sm.localPlayer.getRaycastStart()
				local rayDir = sm.localPlayer.getDirection()
				local success, result = sm.physics.raycast( rayStart, rayStart + rayDir * 7.5, sm.localPlayer.getPlayer().character )

				if success then
					self:cl_paintAnimation()
					
					if self.filter == 0 then
						self.network:sendToServer( "sv_uncolorall", { body = result:getBody(), filterUUID = nil } )
					end
					if self.filter == 1 then
						if result:getShape() then
							self.network:sendToServer( "sv_uncolorall", { body = result:getBody(), filterUUID = result:getShape():getShapeUuid() } )
						end
					end
					if self.filter == 2 then
						if result:getShape() then
							self.network:sendToServer( "sv_colorSingle", { unpaint = true, colorIndex = self.colorIndex, position = result.pointWorld,  shape = result:getShape(), body = result:getBody(), filterUUID = result:getShape():getShapeUuid(), UseCustomColor = self.UseCustomColor, RValue = self.RValue , GValue = self.GValue , BValue = self.BValue } )
						end
					end
				end
				return true, true
			end
		end
	else
		if primaryState == sm.tool.interactState.start then	
			local rayStart = sm.localPlayer.getRaycastStart()
			local rayDir = sm.localPlayer.getDirection()
			local success, result = sm.physics.raycast( rayStart, rayStart + rayDir * 7.5, sm.localPlayer.getPlayer().character )
			if success then
				self:cl_paintAnimation()
				if result:getShape() then
					self.UseCustomColor = true
					local TargetColor = result:getShape():getColor()
					self.RValue = math.floor( TargetColor.r * 255 )
					self.GValue = math.floor( TargetColor.g * 255 )
					self.BValue = math.floor( TargetColor.b * 255 )
					
					if self.colorGui ~= nil then
						self.colorGui:setText( "RValue", tostring( self.RValue ) )
						self.colorGui:setText( "GValue", tostring( self.GValue ) )
						self.colorGui:setText( "BValue", tostring( self.BValue ) )
						
						self.colorGui:setColor( "CustomColorPic", sm.color.new( self.RValue / 255, self.GValue / 255, self.BValue / 255, 1 )  )
					end
					
					self:client_updateBucketRenderables()
				end
			end
			return true, true
		end
		if secondaryState == sm.tool.interactState.start then	
			self:cl_paintAnimation()
			return true, true
		end
	end
	return false, false
end

function Fant_Paintbucket.client_onToggle( self, backwards )
	if self.colorGui == nil then
		local path = "$GAME_DATA/Gui/Layouts/Fant_Paint_Bucket.layout"
		self.colorGui = sm.gui.createGuiFromLayout( path )
		for i = 0, 39 do
			self.colorGui:setButtonCallback( "ColorButton" .. tostring( i ), "cl_onColorButtonClick" )
		end
		
		self.colorGui:setButtonCallback( "R--", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "R-", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "R+", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "R++", "cl_onCustomColorButtonClick" )
		
		self.colorGui:setButtonCallback( "G--", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "G-", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "G+", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "G++", "cl_onCustomColorButtonClick" )
		
		self.colorGui:setButtonCallback( "B--", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "B-", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "B+", "cl_onCustomColorButtonClick" )
		self.colorGui:setButtonCallback( "B++", "cl_onCustomColorButtonClick" )
		
		self.colorGui:setText( "RValue", tostring( self.RValue ) )
		self.colorGui:setText( "GValue", tostring( self.GValue ) )
		self.colorGui:setText( "BValue", tostring( self.BValue ) )
		
		self.colorGui:setColor( "CustomColorPic", sm.color.new( self.RValue / 255, self.GValue / 255, self.BValue / 255, 1 )  )
		
		self.colorGui:setOnCloseCallback( "cl_onClose" )
		self.colorGui:open()
	end
	return true
end

function Fant_Paintbucket.cl_onCustomColorButtonClick( self, name )
	--print( "cl_onCustomColorButtonClick", name )
	self.UseCustomColor = true
	
	if name == "R--" then
		self.RValue = self.RValue - 10
	end
	if name == "R-" then
		self.RValue = self.RValue - 1
	end
	if name == "R+" then
		self.RValue = self.RValue + 1
	end
	if name == "R++" then
		self.RValue = self.RValue + 10
	end
	
	if self.RValue < 0 then
		self.RValue = 0
	end
	if self.RValue > 255 then
		self.RValue = 255
	end
	
	if name == "G--" then
		self.GValue = self.GValue - 10
	end
	if name == "G-" then
		self.GValue = self.GValue - 1
	end
	if name == "G+" then
		self.GValue = self.GValue + 1
	end
	if name == "G++" then
		self.GValue = self.GValue + 10
	end
	
	if self.GValue < 0 then
		self.GValue = 0
	end
	if self.GValue > 255 then
		self.GValue = 255
	end
	
	if name == "B--" then
		self.BValue = self.BValue - 10
	end
	if name == "B-" then
		self.BValue = self.BValue - 1
	end
	if name == "B+" then
		self.BValue = self.BValue + 1
	end
	if name == "B++" then
		self.BValue = self.BValue + 10
	end
	
	if self.BValue < 0 then
		self.BValue = 0
	end
	if self.BValue > 255 then
		self.BValue = 255
	end
	
	self.colorGui:setText( "RValue", tostring( self.RValue ) )
	self.colorGui:setText( "GValue", tostring( self.GValue ) )
	self.colorGui:setText( "BValue", tostring( self.BValue ) )
	
	self.colorGui:setColor( "CustomColorPic", sm.color.new( self.RValue / 255, self.GValue / 255, self.BValue / 255, 1 )  )
	
	self:client_updateBucketRenderables()
end

function Fant_Paintbucket.client_onReload( self )
	if self.tool:isLocal() then
		self.filter = self.filter + 1
		if self.filter > 2 then
			self.filter = 0
		end
		if self.filter == 0 then
			sm.gui.chatMessage( "Color all" )
		end
		if self.filter == 1 then
			sm.gui.chatMessage( "Color Same Type" )
		end
		if self.filter == 2 then
			sm.gui.chatMessage( "Color Single" )
		end
		
	end
	
	return true
end

function Fant_Paintbucket.cl_onColorButtonClick( self, name )
	--print( "cl_onButtonClick", name )
	self.UseCustomColor = false
	
	self.colorIndex = tonumber( name:match( '%d+' ) ) + 1
	self.colorGui:close()
	self.colorGui:destroy()
	self.colorGui = nil
	self:client_updateBucketRenderables()
end

function Fant_Paintbucket.cl_onClose( self )
	if self.colorGui ~= nil then
		self.colorGui:destroy()
		self.colorGui = nil
	end
end

function Fant_Paintbucket.sv_colorall( self, params )
	local bucket_color = Paint_Colors[params.colorIndex]
	if params.UseCustomColor then
		bucket_color = sm.color.new( params.RValue / 255, params.GValue / 255, params.BValue / 255, 1 ) 
	end
	if not params.body or params.body == nil then
		return
	end
	
	if sm.game.getEnableAmmoConsumption() then
		local Inventory = self.tool:getOwner():getInventory()
		if Inventory then
			sm.container.beginTransaction()
			sm.container.spend( Inventory, obj_consumable_inkammo, 1, true )
			if sm.container.endTransaction() then
				colorAll( params.body, bucket_color )
				local bodys = params.body:getCreationBodies()
				for i, body in pairs( bodys ) do 
					colorAll( body, bucket_color )
				end
			end	
		end
	else
		colorAll( params.body, bucket_color )
		local bodys = params.body:getCreationBodies()
		for i, body in pairs( bodys ) do 
			colorAll( body, bucket_color )
		end
	end
end

function colorAll( body, color )
	local shapes = body:getShapes()
	if shapes ~= nil then
		for i, shape in pairs( shapes ) do 
			shape:setColor( color )
		end
	end
end

function Fant_Paintbucket.sv_uncolorall( self, params )
	if not params.body or params.body == nil then
		return
	end
	
	uncolorAll( params.body, params.filterUUID )
	local bodys = params.body:getCreationBodies()
	for i, body in pairs( bodys ) do 
		uncolorAll( body, params.filterUUID )
	end
	if sm.game.getEnableAmmoConsumption() then
		local Inventory = self.tool:getOwner():getInventory()
		if Inventory then
			sm.container.beginTransaction()
			sm.container.spend( Inventory, obj_consumable_inkammo, 1, true )
			if sm.container.endTransaction() then
				
			end	
		end
	end
end

function uncolorAll( body, uuid )
	local shapes = body:getShapes()
	if shapes ~= nil then
		for i, shape in pairs( shapes ) do 		
			if uuid ~= nil then
				if shape:getShapeUuid() == uuid then
					shape:setColor( sm.item.getShapeDefaultColor( shape:getShapeUuid() ) )
				end
			else
				shape:setColor( sm.item.getShapeDefaultColor( shape:getShapeUuid() ) )
			end
		end
	end
end

function Fant_Paintbucket.sv_colorOnly( self, params )
	local bucket_color = Paint_Colors[params.colorIndex]
	if params.UseCustomColor then
		bucket_color = sm.color.new( params.RValue / 255, params.GValue / 255, params.BValue / 255, 1 ) 
	end
	if not params.body or params.body == nil or params.filterUUID == nil then
		return
	end
	
	if sm.game.getEnableAmmoConsumption() then
		local Inventory = self.tool:getOwner():getInventory()
		if Inventory then
			sm.container.beginTransaction()
			sm.container.spend( Inventory, obj_consumable_inkammo, 1, true )
			if sm.container.endTransaction() then
				colorOnly( params.body, bucket_color, params.filterUUID )
				local bodys = params.body:getCreationBodies()
				for i, body in pairs( bodys ) do 
					colorOnly( body, bucket_color, params.filterUUID )
				end
			end	
		end
	else
		colorOnly( params.body, bucket_color, params.filterUUID )
		local bodys = params.body:getCreationBodies()
		for i, body in pairs( bodys ) do 
			colorOnly( body, bucket_color, params.filterUUID )
		end
	end
end

function colorOnly( body, color, uuid )
	local shapes = body:getShapes()
	if shapes ~= nil then
		for i, shape in pairs( shapes ) do 
			if shape:getShapeUuid() == uuid then
				shape:setColor( color )
			end
		end
	end
end

function Fant_Paintbucket.sv_colorSingle( self, params )
	local bucket_color = Paint_Colors[params.colorIndex]
	if self.UseCustomColor then
		bucket_color = sm.color.new( params.RValue / 255, params.GValue / 255, params.BValue / 255, 1 ) 
	end
	if not params.body or params.body == nil or params.filterUUID == nil then
		return
	end
	if params.unpaint == false then
		if sm.game.getEnableAmmoConsumption() then
			local Inventory = self.tool:getOwner():getInventory()
			if Inventory then
				sm.container.beginTransaction()
				sm.container.spend( Inventory, obj_consumable_inkammo, 1, true )
				if sm.container.endTransaction() then
					colorSingle( params.shape, bucket_color, params.position )
				end	
			end
		else
			colorSingle( params.shape, bucket_color, params.position )
		end
	else
		colorUnpaintSingle( params.shape, bucket_color, params.position )
	end
end


function colorSingle( shape, color, position )
	local shapeUUID = shape:getShapeUuid()
	if sm.item.isBlock( shapeUUID ) then
		local localPos = shape:getClosestBlockLocalPosition( position ) 
		NewShape = shape.body:createBlock( shapeUUID, sm.vec3.new( 1, 1, 1 ), localPos, true )
		NewShape:setColor( color )
		shape:destroyBlock( localPos, sm.vec3.new( 1, 1, 1 ), 0 )
	else
		shape:setColor( color )
	end
end

function colorUnpaintSingle( shape, color, position )
	local shapeUUID = shape:getShapeUuid()
	if sm.item.isBlock( shapeUUID ) then
		local localPos = shape:getClosestBlockLocalPosition( position ) 
		NewShape = shape.body:createBlock( shapeUUID, sm.vec3.new( 1, 1, 1 ), localPos, true )
		NewShape:setColor( sm.item.getShapeDefaultColor( shapeUUID ) )
		shape:destroyBlock( localPos, sm.vec3.new( 1, 1, 1 ), 0 )
	else
		shape:setColor( sm.item.getShapeDefaultColor( shapeUUID ) )
	end
end





function Fant_Paintbucket.cl_paintAnimation( self )
	if self.tool:getOwner().character == nil then
		return
	end
	if self.fireCooldownTimer <= 0.0 then
		local firstPerson = self.tool:isInFirstPersonView()
		local dir = sm.localPlayer.getDirection()
		local firePos = self:calculateFirePosition()
		local fakePos = self:calculateTpMuzzlePos()
		
		local forward = sm.vec3.new( 0, 0, 1 ):cross( sm.localPlayer.getRight() )
		local pitchScale = forward:dot( dir )
		dir = dir:rotate( math.rad( pitchScale * 18 ), sm.camera.getRight() )
		
		-- Timers
		self.fireCooldownTimer = FireCooldown

		self.network:sendToServer( "sv_n_paintAnimation", params )
		self:paintAnimation( params )

		-- Play FP shoot animation
		setFpAnimation( self.fpAnimations, "use", 0.25 )
	end
end

function Fant_Paintbucket.sv_n_paintAnimation( self, params )
	self.network:sendToClients( "cl_n_paintAnimation", params )
end

function Fant_Paintbucket.cl_n_paintAnimation( self, params )
	self:paintAnimation( params )
end

function Fant_Paintbucket.paintAnimation( self, params )
	self.tpAnimations.animations.idle.time = 0
	setTpAnimation( self.tpAnimations, "use", 10.0 )
	sm.effect.playHostedEffect("Bucket - Throw", self.tool:getOwner():getCharacter() )
end
