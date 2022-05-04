Fant_Air_Generator = class()
Fant_Air_Generator.poseAnimationSpeed = 1
Fant_Air_Generator.OffSize = sm.vec3.new( 1, 1, 1 ) * 0.5
Fant_Air_Generator.maxParentCount = 2
Fant_Air_Generator.connectionInput = sm.interactable.connectionType.electricity + sm.interactable.connectionType.logic
Fant_Air_Generator.EnergyConsumeRate = 1/90
Fant_Air_Generator.MaxBoxSize = 25

function Fant_Air_Generator.server_onCreate( self )	
	self.FluidTimer = 0
	self.inFluid = false
	self.state = false
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { Size = sm.vec3.new( 8, 8, 8 ), energy = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.Size = self.sv.storage.Size
	self.energy = self.sv.storage.energy or 0
	self:sv_refreshBox()
end

function Fant_Air_Generator.server_onDestroy( self )
	if sm.exists( self.areaTrigger ) then
		sm.areaTrigger.destroy( self.areaTrigger )
	end
	self.sv = {}
	self.sv.storage = { Size = self.Size, energy = self.energy } 
	self.storage:save( self.sv.storage )
end

function Fant_Air_Generator.client_onCreate( self )
	self.poseAnimationtime = 0
	self.interactable:setAnimEnabled( "fanspin", true )	
	self.interactable:setAnimProgress( "fanspin", 0.01 )
	self.cl_active = false
	self.effect = sm.effect.createEffect( "ShapeRenderable", self.interactable )				
	self.effect:setParameter( "uuid", sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f") )
	self.ModeIndex = 0
	self.ShowEffectTimer = 0
	self.cl_Size = sm.vec3.new( 8, 8, 8 )
	--self:cl_showBox()
end

function Fant_Air_Generator.client_onDestroy( self )
	if self.effect ~= nil then
		self.effect:stop()
		self.effect = nil
	end
	
end

function Fant_Air_Generator.getParentInputs( self )
	local Active = true
	local BatteryContainer = nil
	for i, parent in pairs( self.interactable:getParents() ) do
		if parent:hasOutputType( sm.interactable.connectionType.logic ) then
			Active = parent.active
		end
		if parent:hasOutputType( sm.interactable.connectionType.electricity ) and BatteryContainer == nil then
			BatteryContainer = parent:getContainer( 0 )
		end
	end
	return Active, BatteryContainer
end

function Fant_Air_Generator.getnergyConsumeBoxSizeRate( self, size )
	return ( ( size.x * size.y * size.z ) / 250 )
end

function Fant_Air_Generator.server_onFixedUpdate( self, dt )
	local isActive, BatteryContainer = self:getParentInputs()

	if isActive and sm.game.getEnableAmmoConsumption() then
		if BatteryContainer == nil then
			if self.energy <= 0 then
				isActive = false
			end
		else
			if self.energy <= 0 then
				if BatteryContainer ~= nil and not sm.container.isEmpty( BatteryContainer ) then
					for slot = 0, sm.container.getSize( BatteryContainer ) - 1 do
						local batterie = BatteryContainer:getItem( slot )											
						if batterie then			
							if batterie.quantity >= 1 then
								sm.container.beginTransaction()
								sm.container.setItem( BatteryContainer, slot, obj_consumable_battery, batterie.quantity - 1 )
								if sm.container.endTransaction() then
									self.energy = 1
									break
								end
							end
						end
					end
				end
			end
		end
		if self.energy > 0 then
				self.energy = self.energy - ( dt * self.EnergyConsumeRate * ( 1 + ( self:getnergyConsumeBoxSizeRate( self.Size ) / 5 ) ) )
				if self.energy < 0 then
					self.energy = 0
				end
			else
				isActive = false
			end
	end
	if isActive ~= self.state then
		self.state = isActive
		self.network:sendToClients( "cl_setstate", self.state )
	end	
	if self.FluidTimer > 0 then
		self.FluidTimer = self.FluidTimer - dt
	else
		self.FluidTimer = 0.1
		if isActive then
			if self.areaTrigger then
				for _, result in ipairs(  self.areaTrigger:getContents() ) do
					if sm.exists( result ) then
						if type( result ) == "Character" then
							local resultPlayer = result:getPlayer()
							if resultPlayer then
								sm.event.sendToPlayer( resultPlayer, "IgnoreFluid" )
							end
						end
					end
				end
			end
		end
		
	end
end

function Fant_Air_Generator.cl_setstate( self, state )
	self.cl_active = state
	self:cl_showBox()
end

function Fant_Air_Generator.client_onUpdate( self, dt )
	if self.cl_active then
		self.poseAnimationtime = self.poseAnimationtime + ( self.poseAnimationSpeed * dt * ( self:getnergyConsumeBoxSizeRate( self.cl_Size ) * 0.5 ) )
		if self.poseAnimationtime > 1  then
			self.poseAnimationtime = 0
		end
		self.interactable:setAnimProgress( "fanspin", self.poseAnimationtime )
	end
	if self.ShowEffectTimer ~= nil then
		if self.ShowEffectTimer > 0 then
			self.ShowEffectTimer = self.ShowEffectTimer - dt
			if not self.effect:isPlaying() then
				self.effect:start()
			end
		else
			if self.effect:isPlaying() then
				self.effect:stop()
			end
		end
	end
end

function Fant_Air_Generator.sv_refreshBox( self )
	if self.areaTrigger ~= nil then
		sm.areaTrigger.destroy( self.areaTrigger )
	end
	if self.Size.x < 3 then
		self.Size.x = 3
	end
	if self.Size.x > self.MaxBoxSize then
		self.Size.x = self.MaxBoxSize
	end
	if self.Size.y < 3 then
		self.Size.y = 3
	end
	if self.Size.y > self.MaxBoxSize then
		self.Size.y = self.MaxBoxSize
	end
	if self.Size.z < 3 then
		self.Size.z = 3
	end
	if self.Size.z > self.MaxBoxSize then
		self.Size.z = self.MaxBoxSize
	end
	local Pos = sm.vec3.new( 0, 0, 0 ) * 0.25
	local Size = self.Size * 0.25
	self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), ( Size - self.OffSize ) / 2, Pos + sm.vec3.new( 0, -Size.y / 2, 0 ), sm.quat.identity(), sm.areaTrigger.filter.all )			
	self.network:sendToClients( "cl_refreshBox", { Pos = Pos, Size = Size } )
end

function Fant_Air_Generator.cl_refreshBox( self, data )
	self.cl_Size = data.Size * 4
	self.effect:setOffsetPosition( data.Pos + sm.vec3.new( 0, -data.Size.y / 2, 0 ) )
	self.effect:setScale( -data.Size )
end

function Fant_Air_Generator.cl_showBox( self )
	self.ShowEffectTimer = 1
end

function Fant_Air_Generator.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	local EText = "Size " .. "X:" .. tostring( math.floor( self.cl_Size.x ) ) .. " Y:" .. tostring( math.floor( self.cl_Size.y ) ) .. " Z:" .. tostring( math.floor( self.cl_Size.z ) )
	sm.gui.setInteractionText( "", keyBindingText, EText )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	
	local ModeName = ""
	if self.ModeIndex == 0 then
		ModeName = "X"
	end
	if self.ModeIndex == 1 then
		ModeName = "Y"
	end
	if self.ModeIndex == 2 then
		ModeName = "Z"
	end
	if self.cl_active then
		sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. ModeName .. "  - Energy Consume: " .. tostring( self:getnergyConsumeBoxSizeRate( self.cl_Size ) ) )
	else
		sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. ModeName .. "  - Energy Consume: 0" )
	end
	return true
end

function Fant_Air_Generator.client_onInteract( self, character, state )
	if state == true then
		if character:isCrouching() then
			self.network:sendToServer( "sv_setValue", { mode = self.ModeIndex, value = -1 } )
		else
			self.network:sendToServer( "sv_setValue", { mode = self.ModeIndex, value = 1 } )
		end			
		self:cl_showBox()
	end
end

function Fant_Air_Generator.client_onTinker( self, character, state )
	if state then
		if character:isCrouching() then
			self.ModeIndex = self.ModeIndex - 1
			if self.ModeIndex < 0 then
				self.ModeIndex = 2
			end
		else
			self.ModeIndex = self.ModeIndex + 1
			if self.ModeIndex > 2 then
				self.ModeIndex = 0
			end
		end	
		self:cl_showBox()
	end
end

function Fant_Air_Generator.sv_setValue( self, data )
	if data.mode == 0 then
		self.Size.x = self.Size.x + data.value
		if self.Size.x < 3 then
			self.Size.x = 3
		end
		if self.Size.x > self.MaxBoxSize then
			self.Size.x = self.MaxBoxSize
		end
	end
	if data.mode == 1 then
		self.Size.y = self.Size.y + data.value
		if self.Size.y < 3 then
			self.Size.y = 3
		end
		if self.Size.y > self.MaxBoxSize then
			self.Size.y = self.MaxBoxSize
		end
	end
	if data.mode == 2 then
		self.Size.z = self.Size.z + data.value
		if self.Size.z < 3 then
			self.Size.z = 3
		end
		if self.Size.z > self.MaxBoxSize then
			self.Size.z = self.MaxBoxSize
		end
	end
	self.sv = {}
	self.sv.storage = { Size = self.Size } 
	self.storage:save( self.sv.storage )
	self:sv_refreshBox()
	self.network:sendToClients( "cl_showBox" )
end










