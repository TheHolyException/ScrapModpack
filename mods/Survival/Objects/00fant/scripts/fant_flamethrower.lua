dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_units.lua"

Fant_Flamethrower = class()
Fant_Flamethrower.maxParentCount = 2
Fant_Flamethrower.connectionInput = sm.interactable.connectionType.gasoline + sm.interactable.connectionType.logic
Fant_Flamethrower.FlameSpeed = 5
Fant_Flamethrower.FlameMinimumLifetime = 6
Fant_Flamethrower.FlameMaximumLifetime = 8
Fant_Flamethrower.TargetBurnTime = 4
Fant_Flamethrower.TicksPerFuel = 2

local MinimalDamage = 10
local MaximalDamage = 15

Flames = {}
Flame_Targets = {}
Flame_On_Targets = {}

Flame_Damage_Timer = 0

G_FLAMERSHAPE = G_FLAMERSHAPE or nil
SV_FLAME_MANAGER = SV_FLAME_MANAGER or nil
CL_FLAME_MANAGER = CL_FLAME_MANAGER or nil

function Fant_Flamethrower.server_onCreate( self )
	G_FLAMERSHAPE = self.shape
	self.timer = 0
	self.state = false
	self.laststate = self.state
	self.FuelContainer = nil
	self:InitAreaTrigger()
	
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { fuelTicks = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.fuelTicks = self.sv.storage.fuelTicks
end

function Fant_Flamethrower.client_onCreate( self )
	self.cl_timer = 0
end

function Fant_Flamethrower.server_onDestroy( self )	
	local data = {
		fuelTicks = self.fuelTicks
	}
	self.sv.storage = data
	self.storage:save( self.sv.storage )
	
	--if SV_FLAME_MANAGER == self.shape.id then
		SV_FLAME_MANAGER = nil
	--end
end

function Fant_Flamethrower.client_onDestroy( self )
	for _, flame in ipairs( Flames ) do
		if flame ~= nil then
			if flame.Effect ~= nil then
				flame.Effect:stop()	
			end
		end
	end
	for _, flame in ipairs( Flame_On_Targets ) do
		if flame ~= nil then
			if flame.Effect ~= nil then
				flame.Effect:stop()	
			end
		end
	end
	--if CL_FLAME_MANAGER == self.shape.id then
		CL_FLAME_MANAGER = nil
	--end
end

function Fant_Flamethrower.server_onFixedUpdate( self, dt )
	self.state, self.FuelContainer = self:getInputs( self )
	if self.FuelContainer == nil and sm.game.getEnableAmmoConsumption() then
		self.state = false
	end
	if not self:consumFuel( dt ) and sm.game.getEnableAmmoConsumption() then
		self.state = false
	end
	for _, result in ipairs( self.waterTrigger:getContents() ) do
		if sm.exists( result ) then
			if type( result ) == "AreaTrigger" then
				local userData = result:getUserData()
				if userData then
					if userData.water == true then
						self.state = false
						break
					end
					if userData.chemical == true then
						self.state = false
						break
					end
					if userData.oil == true then
						self.state = false
						break
					end
				end
			end
		end
	end
	if self.state ~= self.laststate then
		self.laststate = self.state
		self.network:sendToClients( "cl_setState", self.state )
	end
	if self.state then
		self.timer = self.timer - dt
		if self.timer < 0 then
			self.timer = 0.2
			
			for _, result in ipairs( self.areaHitbox:getContents() ) do	
				if result ~= nil and sm.exists( result ) then	
					if type( result ) == "Character" then	
						self:add_Flame_Target( result, nil, self.shape )
					end
					if type( result ) == "Body" then						
						local shapes = sm.body.getShapes( result )
						if shapes ~= nil then
							if sm.shape.getShapeUuid( shapes[1] ) == fant_straw_dog then		
								self:add_Flame_Target( nil, result, self.shape )
								--print(result )
							end
							if sm.shape.getShapeUuid( shapes[1] ) == fant_beebot then		
								self:add_Flame_Target( nil, result, self.shape )
								--print(result )
							end
						end
						
					end
				end
			end
		end
	else
		self.timer = 0
	end
	self:sv_Flame_Manager( dt )
end

function Fant_Flamethrower.client_onUpdate( self, dt )
	self:cl_Flame_Manager( dt )
end



function Fant_Flamethrower.sv_Flame_Manager( self, dt )
	if not self:sv_Register_Flame_Manager() then
		return
	end
	local new_Flame_Targets = {}
	for _, flame_target in ipairs( Flame_Targets ) do
		if flame_target ~= nil then
			flame_target.lifetime = flame_target.lifetime - dt

			if flame_target.lifetime <= 0 then
				flame_target.lifetime = 0
			end
			if flame_target.character ~= nil and sm.exists( flame_target.character ) then
				if flame_target.character:isSwimming() then
					flame_target.lifetime = 0
				end
			end
			if flame_target.lifetime > 0 then
				table.insert( new_Flame_Targets, flame_target )
			end
		end
	end
	Flame_Targets = new_Flame_Targets
	--print( "Flame_Targets: " .. tostring( #Flame_Targets ) )
end

function Fant_Flamethrower.cl_Flame_Manager( self, dt )
	if self:cl_Register_Flame_Manager() then
		for _, flame in ipairs( Flames ) do
			if flame ~= nil then
				flame.lifetime = flame.lifetime - dt
				if flame.Effect ~= nil then
					local move_vector = flame.direction * dt * self.FlameSpeed * ( 1 + flame.lifetime )
					flame.position = flame.position + move_vector
					flame.Effect:setPosition( flame.position )
					--flame.Effect:setRotation( flame.sourceshape:getWorldRotation() )
				end
				if flame.lifetime <= 0 then
					flame.lifetime = 0
					self:cl_deleteFlame( flame )
				end
			end
		end
		--print( "Flames: " .. tostring( #Flames ) )
		for _, flame_on_target in ipairs( Flame_On_Targets ) do
			if flame_on_target ~= nil then
				flame_on_target.lifetime = flame_on_target.lifetime - dt
				if flame_on_target.Effect ~= nil then
					if flame_on_target.character ~= nil and sm.exists( flame_on_target.character ) then
						flame_on_target.Effect:setPosition( flame_on_target.character.worldPosition )
						if flame_on_target.character:isSwimming() then
							flame_on_target.lifetime = 0
							flame_on_target.Effect:stop()
							--print( "isswimstop" )
						end
					end
					if flame_on_target.shape ~= nil and sm.exists( flame_on_target.shape ) then
						if type( flame_on_target.shape ) == "Body" then
							flame_on_target.Effect:setPosition( flame_on_target.shape.worldPosition )
						end
					end
					flame_on_target.Effect:setRotation( sm.quat.identity( ) )
				else
					flame_on_target.lifetime = 0
					flame_on_target.Effect:stop()
				end
				if flame_on_target.lifetime <= 0 or ( flame_on_target.character == nil and flame_on_target.shape == nil ) then
					flame_on_target.lifetime = 0
					flame_on_target.Effect:stop()
					self:cl_deleteFlameOnTarget( flame_on_target )
				end
			end
		end
		--print( "Flame_On_Targets: " .. tostring( #Flame_On_Targets ) )
	end
	self.cl_timer = self.cl_timer - dt
	if self.cl_timer < 0 then
		self.cl_timer = 0.05	
		if self.state then
			self:cl_addFlame( self.shape )
		end
	end
end

function Fant_Flamethrower.sv_Register_Flame_Manager( self )
	if SV_FLAME_MANAGER ~= nil then
	else
		SV_FLAME_MANAGER = self.shape.id
	end
	if SV_FLAME_MANAGER == self.shape.id then
		return true
	else
		return false
	end
end

function Fant_Flamethrower.cl_Register_Flame_Manager( self )
	if CL_FLAME_MANAGER ~= nil then
	else
		CL_FLAME_MANAGER = self.shape.id
	end
	if CL_FLAME_MANAGER == self.shape.id then
		return true
	else
		return false
	end
end

function Fant_Flamethrower.server_onRefresh( self )
	self:InitAreaTrigger()
end

function Fant_Flamethrower.InitAreaTrigger( self )
	if self.areaHitbox ~= nil then
		sm.areaTrigger.destroy( self.areaHitbox )
	end
	local Length = 25
	local BlockSize = 0.5 * sm.construction.constants.subdivideRatio
	local Box = sm.vec3.new( BlockSize * 7, BlockSize * 7, BlockSize * Length )
	local Pos = sm.vec3.new( 0, 0, ( BlockSize * 5 ) - ( - ( Length / 2 ) * sm.construction.constants.subdivideRatio ) )
	self.areaHitbox = sm.areaTrigger.createAttachedBox( sm.shape.getInteractable( self.shape ), Box, Pos, sm.quat.identity(), sm.areaTrigger.filter.all )	
	
	
	if self.waterTrigger ~= nil then
		sm.areaTrigger.destroy( self.waterTrigger )
	end
	self.waterTrigger = sm.areaTrigger.createAttachedBox( sm.shape.getInteractable( self.shape ), sm.vec3.new( 0.2, 0.2, 0.2 ), sm.vec3.new( 0, 0, 0 ), sm.quat.identity(), sm.areaTrigger.filter.all )	
	--self.network:sendToClients( "fdebug", { Pos = Pos, Box = Box } )
end

function Fant_Flamethrower.fdebug( self, data )
	if self.areaHitboxEffect ~= nil then
		self.areaHitboxEffect:stop()
		self.areaHitboxEffect = nil
	end
	local UUID = sm.uuid.new("f7881097-9320-4667-b2ba-4101c72b8730")
	self.areaHitboxEffect = sm.effect.createEffect( "ShapeRenderable" )				
	self.areaHitboxEffect:setParameter( "uuid", UUID )

	self.areaHitboxEffect:setScale( data.Box * 2 )
	self.areaHitboxEffect:start()
	
	local localpos = ( -sm.shape.getAt( self.shape ) * data.Pos.x ) + ( sm.shape.getRight( self.shape ) * data.Pos.y ) + ( sm.shape.getUp( self.shape ) * data.Pos.z )
	self.areaHitboxEffect:setPosition( self.shape:getWorldPosition() + localpos )
	self.areaHitboxEffect:setRotation( self.shape:getWorldRotation() )
end

function Fant_Flamethrower.getInputs( self )
	local parents = self.interactable:getParents()
	local fuelContainer = nil
	local active = false
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[2]:isActive()
		end	
		if parents[2]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[2]:getContainer( 0 )
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[1]:isActive()
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[1]:getContainer( 0 )
		end
	end
	return active, fuelContainer
end

function Fant_Flamethrower.consumFuel( self, dt )
	if self.fuelTicks > 0 and self.state then
		self.fuelTicks = self.fuelTicks - dt
	end
	if self.FuelContainer ~= nil then
		if self.fuelTicks <= 0 then
			for slot = 0, 5 do
				local FuelItem = self.FuelContainer:getItem( slot )											
				if FuelItem then			
					if FuelItem.quantity >= 1 then
						sm.container.beginTransaction()
						sm.container.setItem( self.FuelContainer, slot, obj_consumable_gas, FuelItem.quantity - 1 )
						if sm.container.endTransaction() then
							self.fuelTicks = self.TicksPerFuel
							break
						end
					end
				end
			end
		end
	end
	if self.fuelTicks > 0 then
		return true
	end
	return false
end

function Fant_Flamethrower.cl_setState( self, state )
	self.state = state
end

function Fant_Flamethrower.add_Flame_Target( self, character, shape, attackeshape )
	local hasAllready = false
	for _, target in ipairs( Flame_Targets ) do	
		if target ~= nil then	
			if character ~= nil and target.character ~= nil then
				if target.character == character then
					hasAllready = true
					break
				end
			end
			if shape ~= nil and target.shape ~= nil then
				if target.shape == shape then
					hasAllready = true
					break
				end
			end
		end
	end
	if not hasAllready then
		local data = {}
		if character ~= nil then
			data = { character = character, lifetime = self.TargetBurnTime, shape = nil, attackeshape = attackeshape }
		end
		if shape ~= nil then
			data = { character = nil, lifetime = self.TargetBurnTime, shape = shape, attackeshape = attackeshape }
		end
		table.insert( Flame_Targets, data )
		self.network:sendToClients( "cl_add_Flame_Target", data )
	end
end

function Fant_Flamethrower.cl_add_Flame_Target( self, data )
	local new_flame_target = {}
	new_flame_target.character = data.character
	new_flame_target.lifetime = data.lifetime
	new_flame_target.shape = data.shape
	new_flame_target.Effect = sm.effect.createEffect( "Fire - gradual", nil )
	new_flame_target.Effect:setParameter( "intensity", 0 )
	if new_flame_target.character ~= nil then
		new_flame_target.Effect:setPosition( new_flame_target.character.worldPosition )
	end
	if new_flame_target.shape ~= nil then
		new_flame_target.Effect:setPosition( new_flame_target.shape.worldPosition )
	end
	
	new_flame_target.Effect:setRotation( sm.quat.identity( ) )
	new_flame_target.Effect:start()
	table.insert( Flame_On_Targets, new_flame_target )
end

function Fant_Flamethrower.cl_addFlame( self, sourceshape )
	if sourceshape == nil then
		return
	end
	local target_position = sourceshape:getWorldPosition() + sm.shape.getUp( sourceshape ) * 100
	local new_flame = {}
	new_flame.Effect = sm.effect.createEffect( "Fire - gradual", nil )
	new_flame.lifetime = math.random( self.FlameMinimumLifetime, self.FlameMaximumLifetime ) / 10
	new_flame.sourceshape = sourceshape
	local Spread = 30
	local SpreadVector = sm.vec3.new( math.random( -Spread, Spread ), math.random( -Spread, Spread ), math.random( -Spread, Spread ) )
	new_flame.direction = sm.vec3.normalize( target_position - sourceshape:getWorldPosition() + SpreadVector )
	new_flame.position = sourceshape:getWorldPosition() + ( sm.shape.getUp( sourceshape ) * 1.6 )
	new_flame.Effect:setPosition( new_flame.position )
	new_flame.Effect:setRotation( sourceshape:getWorldRotation() )
	new_flame.Effect:setParameter( "intensity", 0 )
	new_flame.Effect:start()
	table.insert( Flames, new_flame )
end

function Fant_Flamethrower.cl_deleteFlame( self, delete_flame )
	if delete_flame == nil then
		return
	end
	local newFlames = {}
	for _, flame in ipairs( Flames ) do
		if flame ~= nil and flame ~= delete_flame then
			table.insert( newFlames, flame )
		end
	end
	Flames = newFlames
	if delete_flame.Effect ~= nil then
		delete_flame.Effect:stop()
	end
	delete_flame = nil
end

function Fant_Flamethrower.cl_deleteFlameOnTarget( self, delete_flame_on_target )
	if delete_flame_on_target == nil then
		return
	end
	local newFlames = {}
	for _, flame_on_target in ipairs( Flame_On_Targets ) do
		if flame_on_target ~= delete_flame_on_target then
			table.insert( newFlames, flame_on_target )
		end
	end
	Flame_On_Targets = newFlames
	if delete_flame_on_target.Effect ~= nil then
		delete_flame_on_target.Effect:stop()
	end
	delete_flame_on_target = nil
end

function FlamethrowerDamage( self, dt )
	if Flame_Damage_Timer > 0 then
		Flame_Damage_Timer = Flame_Damage_Timer - dt
		return
	end
	Flame_Damage_Timer = 1
	
	local characterType = nil
	local character = nil
	local shape = nil
	
	if self.unit ~= nil then
		character = self.unit:getCharacter()
	elseif self.player ~= nil then
		character = self.player:getCharacter()
	end
	if character ~= nil then
		characterType = character:getCharacterType()
	else
		if self.shape ~= nil then
			if sm.shape.getShapeUuid( self.shape ) == fant_straw_dog then
				characterType = fant_straw_dog
				shape = self.shape
			end
			if sm.shape.getShapeUuid( self.shape ) == fant_beebot then
				characterType = fant_beebot
				shape = self.shape
			end
		end
	end
	local hasAllready = false
	local attacker = nil
	
	for _, target in ipairs( Flame_Targets ) do	
		if target ~= nil then
			if target.attackeshape ~= nil then
				local creationBodies = target.attackeshape:getBody():getCreationBodies()
				for _, body in ipairs( creationBodies ) do
					local seatedCharacters = body:getAllSeatedCharacter()
					
					if #seatedCharacters > 0 then
						local seatedCharacter = seatedCharacters[1]
						if seatedCharacter ~= nil then
							attacker = seatedCharacter:getPlayer()
						end
						break
					end
				end
			end
			if target.character ~= nil then
				if target.character == character then
					hasAllready = true
					if target.attacker ~= nil then
						attacker = target.attacker
					end
					break
				end		
			end
			if target.shape ~= nil then
				local body1 = nil
				if type( target.shape ) == "Shape" then
					body1 = sm.shape.getBody( target.shape )
				end
				if type( target.shape ) == "Body" then
					body1 = target.shape
				end			
				local body2 = nil
				if type( shape ) == "Shape" then
					body2 = sm.shape.getBody( shape )
				end
				if type( shape ) == "Body" then
					body2 = shape
				end
				if body1 == body2 then
					hasAllready = true
					if target.attacker ~= nil then
						attacker = target.attacker
					end
					break
				end
			end
			
		end
	end

	if hasAllready then
		if self.player ~= nil then   
			self.sv_takeDamage( self, math.random( MinimalDamage, MaximalDamage ), G_FLAMERSHAPE )		
		else
			if characterType == unit_woc then
				self.sv_takeFireDamage( self, math.random( MinimalDamage, MaximalDamage ), attacker )		
			elseif characterType == unit_worm then
				self.sv_takeDamage( self, math.random( MinimalDamage, MaximalDamage ), attacker )	
			elseif characterType == fant_straw_dog then
				self.sv_takeDamage( self, nil, math.random( MinimalDamage, MaximalDamage ), sm.vec3.new( 0, 0, 0 ), attacker )
			elseif characterType == fant_beebot then
				self.sv_takeDamage( self, nil, math.random( MinimalDamage, MaximalDamage ), sm.vec3.new( 0, 0, 0 ), attacker )
			else
				self.sv_takeDamage( self, math.random( MinimalDamage, MaximalDamage ), sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 1, 0, 0 ), attacker )
			end
		end
		
	end
end



function ExtinguishFire( self )
	local characterType = nil
	local character = nil
	local shape = nil
	
	if self.unit ~= nil then
		character = self.unit:getCharacter()
	elseif self.player ~= nil then
		character = self.player:getCharacter()
	end
	if character ~= nil then
		characterType = character:getCharacterType()
	else
		if self.shape ~= nil then
			if sm.shape.getShapeUuid( self.shape ) == fant_straw_dog then
				characterType = fant_straw_dog
				shape = self.shape
			end
			if sm.shape.getShapeUuid( self.shape ) == fant_beebot then
				characterType = fant_straw_dog
				shape = self.shape
			end
		end
	end
	for _, target in ipairs( Flame_Targets ) do	
		if target ~= nil then	
			if target.character ~= nil then
				if target.character == character then
					target.lifetime = 0
					break
				end		
			end
			if target.shape ~= nil then
				local body1 = nil
				if type( target.shape ) == "Shape" then
					body1 = sm.shape.getBody( target.shape )
				end
				if type( target.shape ) == "Body" then
					body1 = target.shape
				end			
				local body2 = nil
				if type( shape ) == "Shape" then
					body2 = sm.shape.getBody( shape )
				end
				if type( shape ) == "Body" then
					body2 = shape
				end
				if body1 == body2 then
					target.lifetime = 0
					break
				end
			end
		end
	end

end

