dofile("$SURVIVAL_DATA/Scripts/game/survival_units.lua")
dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"

Fant_Tesla_Coil = class()
Fant_Tesla_Coil.maxParentCount = 2
Fant_Tesla_Coil.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.electricity
Fant_Tesla_Coil.maxChildCount = 255
Fant_Tesla_Coil.connectionOutput = sm.interactable.connectionType.logic

FuelTicks = 7
TeslaRange = 15
MinimalDamage = 4
MaximalDamage = 12
ftime = (1/40)
g_teslacoils = g_teslacoils or {}
g_teslacoils_Timer = g_teslacoils_Timer or {}

function ProcessTeslaDamage( target, isPlayer )
	
	local selfpos = nil
	local characterType = nil
	local ID = nil
	if isPlayer == false then
		if target.unit ~= nil then
			selfpos = target.unit:getCharacter().worldPosition
			characterType = target.unit:getCharacter():getCharacterType()
			ID = target.unit["id"]
		else
			selfpos = target.shape.worldPosition
			characterType = fant_straw_dog
			ID = sm.interactable.getId( sm.shape.getInteractable(  target.shape ) )
		end
	else
		selfpos =  target.player:getCharacter().worldPosition
		characterType = target.player:getCharacter()
		ID = target.player:getCharacter()["id"]
	end

	local EffectDistance = 2
	for i,Coil in pairs( g_teslacoils ) do
		local distance = sm.vec3.length( selfpos - Coil.shape.worldPosition )  
		local CoilPos = Coil.shape.worldPosition + ( sm.shape.getAt( Coil.shape ) * 1.25 )
		if distance <= TeslaRange then
			Coil.enemyCount = Coil.enemyCount + 1				
			if g_teslacoils_Timer[ID] == nil then
				g_teslacoils_Timer[ID] = 0
			end
			if g_teslacoils_Timer[ID] > 0 then
				g_teslacoils_Timer[ID] = g_teslacoils_Timer[ID] - ftime
				if g_teslacoils_Timer[ID] <= 0 then
					g_teslacoils_Timer[ID] = 0
				end
			else
				if Coil.shape:getInteractable():isActive() then
					--print(characterType)
					g_teslacoils_Timer[ID] = 1
					if isPlayer then   
						target.sv_takeDamage( target, math.random( MinimalDamage, MaximalDamage ), Coil.shape )		
					else
						if characterType == unit_woc or characterType == unit_worm  then
							target.sv_takeDamage( target, math.random( MinimalDamage, MaximalDamage ) )						
						else
							if characterType ~= fant_straw_dog then
								target.sv_takeDamage( target, math.random( MinimalDamage, MaximalDamage ), sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 1, 0, 0 ) )
							else
								target:sv_takeDamage( target, math.random( MinimalDamage, MaximalDamage ), sm.vec3.new( 1, 0, 0 ) )
							end
						end
					end
					local direction = sm.vec3.normalize( selfpos - CoilPos )  
					local effectCount = math.floor( distance / EffectDistance )
					for c = 1, effectCount do
						local pos = CoilPos + ( direction * EffectDistance * c )
						sm.effect.playEffect( "Part - Electricity", pos, sm.vec3.new( 0, 0, 0 ), sm.quat.identity() )
					end		
					
					break
				end
			end
		end
	end
end

function Fant_Tesla_Coil.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { state = false, fuelTicks = 0  } 
		self.storage:save( self.sv.storage )
	end
	self.fuelTicks = self.sv.storage.fuelTicks
	self.state = self.sv.storage.state
	self.lastState = false
	self.Active = false
	g_teslacoils[self.shape["id"]] = { shape = self.shape, enemyCount = 0 }	
end

function Fant_Tesla_Coil.server_onDestroy( self )
	g_teslacoils[self.shape["id"]] = nil
	self.sv.storage = { state = self.state, fuelTicks = self.fuelTicks  } 
	self.storage:save( self.sv.storage )
end

function Fant_Tesla_Coil.client_onCreate( self )
	self.electricEffect = sm.effect.createEffect( "Part - Electricity" )
	self.lightEffect = sm.effect.createEffect( "ShackLight" )	
end

function Fant_Tesla_Coil.client_onDestroy( self )

end

function Fant_Tesla_Coil.client_onInteract(self, _, state)
	if state == true then
		self.network:sendToServer( "Toggle" )
	end
end

function Fant_Tesla_Coil.Toggle( self )
	if self.state then
		self.state = false		
	else
		self.state = true			
	end
	self.network:sendToClients( "SetClientData", { Active = self.Active, state = self.state } )
end

function Fant_Tesla_Coil.server_onFixedUpdate( self )
	local OnOffButton, BatteryContainer = getInputs(self)
	if self.state then
		if self:consumFuel( BatteryContainer ) == false then
			self.state = false
		end
	end
	local ButtonState = false
	if OnOffButton then
		ButtonState = OnOffButton:isActive()
		if self.lastState ~= ButtonState then
			self.lastState = ButtonState		
			if ButtonState and not self.state then
				self.state = true			
			end
			if not ButtonState and self.state then
				self.state = false			
			end
		end
	end
	local InWater = self:IsInWater()
	if not self.Active and self.fuelTicks > 0 and self.state and not InWater then
		self.Active = true
		sm.interactable.setActive( self.interactable, true )	
		self.network:sendToClients( "SetClientData", { Active = self.Active, state = self.state } )
		sm.interactable.setActive( self.interactable, self.Active )	
	end	
	if ( self.Active or self.fuelTicks <= 0 or InWater ) and not self.state then
		self.Active = false
		sm.interactable.setActive( self.interactable, false )	
		self.network:sendToClients( "SetClientData", { Active = self.Active } )
		sm.interactable.setActive( self.interactable, self.Active )	
	end	
end

function Fant_Tesla_Coil.SetClientData( self, data )
	self.Active = data.Active
	self.state = data.state
end

function Fant_Tesla_Coil.client_onUpdate( self, dt )
	if self.ElectricPulse == nil then
		self.ElectricPulse = 0
	end
	if self.ElectricPulse > 0 then
		self.ElectricPulse = self.ElectricPulse - dt
	end
	if self.ElectricPulse <= 0 and self.Active then		
		self.ElectricPulse = math.random( 0.85,1.25)		
		self.electricEffect:start()
		self.electricEffect:setPosition( self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * 0.8 ) )
		self.lightEffect:setPosition( self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * 1.4 ) )
	end	
	if self.Active and not self.lightEffect:isPlaying() then
		self.lightEffect:start()
	end
	if not self.Active and self.lightEffect:isPlaying() then
		self.lightEffect:stop()
	end
end

function getInputs( self )
	local interactable = self.shape:getInteractable()
	if interactable == nil then
		return nil, nil
	end
	local parents = interactable:getParents()
	if parents == nil then
		return nil, nil
	end
	local OnOff = nil
	local BatteryContainer = nil

	for i = 1, #parents do
		if parents[i] and OnOff == nil then
			if parents[i]:hasOutputType( sm.interactable.connectionType.logic ) then
				OnOff = parents[i]
			end					
		end
		if parents[i]:hasOutputType( sm.interactable.connectionType.electricity ) and BatteryContainer == nil then
			BatteryContainer = parents[i]:getContainer( 0 )
		end
	end	
	return OnOff, BatteryContainer
end

function GetRandomVector( multiplicator )
	return sm.vec3.new( math.random(-1,1), math.random(-1,1), math.random(-1,1) ) * multiplicator
end

function Fant_Tesla_Coil.consumFuel( self, fuelcontainer )
	if fuelcontainer ~= nil then
		local EnemysAround = g_teslacoils[self.shape["id"]].enemyCount or 0
		if EnemysAround == 0 then
			EnemysAround = 1
		end
		--print(EnemysAround)
		if self.fuelTicks > 0 then
			self.fuelTicks = self.fuelTicks - ( ftime * ( EnemysAround ) )
		end
		g_teslacoils[self.shape["id"]].enemyCount = 0
		if self.fuelTicks <= 0 then		
			for slot = 0, 5 do
				local FuelItem = fuelcontainer:getItem( slot )											
				if FuelItem then			
					if FuelItem.quantity >= 1 then
						sm.container.beginTransaction()
						sm.container.setItem( fuelcontainer, slot, obj_consumable_battery, FuelItem.quantity - 1 )
						if sm.container.endTransaction() then
							self.fuelTicks = FuelTicks
							break
						end
					end
				end
			end
		end
		if self.fuelTicks > 0 then
			return true
		end
	end
	return false
end

function Fant_Tesla_Coil.IsInWater( self )
	if not self.areaTrigger then
		self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), sm.vec3.new( 0.5, 0.5, 0.5 ), sm.vec3.new(0.0, 0, 0.0), sm.quat.identity(), sm.areaTrigger.filter.all )			
	end
	for _, result in ipairs(  self.areaTrigger:getContents() ) do
		if sm.exists( result ) then
			if type( result ) == "AreaTrigger" then
				local userData = result:getUserData()
				if userData and userData.water == true then
					return true
				end
			end
		end
	end
	return false
end










