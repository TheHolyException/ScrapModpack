Fant_Gatling = class()
Fant_Gatling.maxParentCount = 2
Fant_Gatling.maxChildCount = 0
Fant_Gatling.connectionInput = bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.ammo )
Fant_Gatling.connectionOutput = sm.interactable.connectionType.none
Fant_Gatling.colorNormal = sm.color.new( 0xcb0a00ff )
Fant_Gatling.colorHighlight = sm.color.new( 0xee0a00ff )
Fant_Gatling.poseWeightCount = 1

Fant_Gatling.Damage = 25
Fant_Gatling.MinForce = 155.0
Fant_Gatling.MaxForce = 165.0
Fant_Gatling.SpreadDeg = 7.5
Fant_Gatling.AmmoType = obj_plantables_banana
--Fant_Gatling.AmmoType = obj_plantables_potato
Fant_Gatling.SpinSpeed = 0.1
Fant_Gatling.SpinUpSpeed = 1
Fant_Gatling.SpinDownSpeed = 0.25
Fant_Gatling.FireRate = 0.05
Fant_Gatling.FireLimit = 0.85

function Fant_Gatling.server_onCreate( self )
	self.sv_fire = false
	self.firetimer = 0
	self.sv_spin = 0
end

function Fant_Gatling.client_onCreate( self )
	self.interactable:setAnimEnabled( "barrel", true )	
	self.interactable:setAnimEnabled( "leaver", true )
	self.interactable:setAnimProgress( "barrel", 0 )
	self.interactable:setAnimProgress( "leaver", 0 )
	
	self.cl_fire = false
	self.cl_spin = 0
	self.cl_spin_value = 0
	self.cl_leaver = 0
	
	self.windupEffect = sm.effect.createEffect( "ElectricEngine - Level 5" )
end

function Fant_Gatling.client_onDestroy( self )	
	self.windupEffect:stop()	
	self.windupEffect:destroy()
end

function Fant_Gatling.server_onFixedUpdate( self, dt )	
	self:sv_weaponControl( dt )
	if self.firetimer > 0 then
		self.firetimer = self.firetimer - dt
	else
		local active, ammo_container = self:getInputs()
		local canFire = false
		local AmmoConsume = sm.game.getEnableAmmoConsumption()
		if AmmoConsume then
			if active == true and ammo_container ~= nil then
				if sm.container.canSpend( ammo_container, self.AmmoType, 1 ) then
					
					canFire = true
				end
			end
		else
			canFire = active
		end
		if not canFire then
			active = false
		else
			if ammo_container ~= nil then
				self.firetimer = self.FireRate
				if self.sv_spin > self.FireLimit then
					
					sm.container.beginTransaction()
					sm.container.spend( ammo_container,  self.AmmoType, 1 )
					if sm.container.endTransaction() then
						self:sv_FireWeapon()
					end
				end
			end
		end
		if active ~= self.sv_fire then
			self.sv_fire = active
			self.network:sendToClients( "cl_setActive", self.sv_fire )
		end
	end
	
end

function Fant_Gatling.client_onUpdate( self, dt )
	self:cl_weaponControl( dt )
end

function Fant_Gatling.cl_setActive( self, state )
	self.cl_fire = state
	if not state then
		sm.effect.playEffect( "Steam - quench", self.shape.worldPosition, sm.vec3.new( 0, 0, 0 ), self.shape.worldRotation ) 
	end	
end

function Fant_Gatling.sv_weaponControl( self, dt )
	if not self.sv_fire then
		if self.sv_spin > 0 then
			self.sv_spin = self.sv_spin - ( dt * self.SpinDownSpeed )
			if self.sv_spin < 0 then
				self.sv_spin = 0
			end
		end
	else
		if self.sv_spin < 1 then
			self.sv_spin = self.sv_spin + ( dt * self.SpinUpSpeed )
			if self.sv_spin > 1 then
				self.sv_spin = 1
			end
		end
	end
	
end

function Fant_Gatling.cl_weaponControl( self, dt )
	if not self.cl_fire then
		if self.cl_spin > 0 then
			self.cl_spin = self.cl_spin - ( dt * self.SpinDownSpeed )
			if self.cl_spin < 0 then
				self.cl_spin = 0
			end
		end
		if self.cl_leaver > 0.1 then
			self.cl_leaver = self.cl_leaver - dt * 4
			if self.cl_leaver < 0.1 then
				self.cl_leaver = 0.1
			end
		end
		if self.windupEffect:isPlaying() and self.cl_leaver <= 0.1 then
			self.windupEffect:stop()		
		end
	else
		if self.cl_spin < 1 then
			self.cl_spin = self.cl_spin + ( dt * self.SpinUpSpeed )
			if self.cl_spin > 1 then
				self.cl_spin = 1
			end
		end
		if self.cl_leaver < 1 then
			self.cl_leaver = self.cl_leaver + dt * 4
			if self.cl_leaver > 1 then
				self.cl_leaver = 1
			end
		end
		if not self.windupEffect:isPlaying() and self.cl_leaver > 0.1 then
			self.windupEffect:start()
		end
	end
	
	if self.windupEffect:isPlaying() then
		self.windupEffect:setParameter( "rpm", self.cl_leaver * 1 )
		self.windupEffect:setParameter( "load", 1 )
	end
	self.windupEffect:setPosition( self.shape.worldPosition )
	
	self.cl_spin_value = self.cl_spin_value + ( self.cl_spin * self.SpinSpeed )

	if self.cl_spin_value > 1 then
		self.cl_spin_value = 0
	end
	
	self.interactable:setAnimProgress( "barrel", self.cl_spin_value  )
	self.interactable:setAnimProgress( "leaver", self.cl_leaver )
end


function Fant_Gatling.sv_FireWeapon( self )
	--print( "sv_Fire" )
	self.firePos = sm.vec3.new( 0.0, 0.15, -0.8 )
	sm.projectile.shapeProjectileAttack( "evil_banana", self.Damage, self.firePos, sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, -1.0 ), self.SpreadDeg ) * math.random( self.MinForce, self.MaxForce ), self.shape )
	self.network:sendToClients( "cl_FireWeapon" )
end

function Fant_Gatling.cl_FireWeapon( self )
	--print( "cl_Fire" )
	local impulse = sm.vec3.new( 0, 0, 1 ) * 1500
	sm.physics.applyImpulse( self.shape, impulse )
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, -1 ),sm.shape.getUp( self.shape ) )
	sm.effect.playEffect( "SpudgunSpinner - SpinnerMuzzel", self.shape.worldPosition + ( sm.shape.getUp( self.shape ) * -2.2 ) + ( sm.shape.getAt( self.shape ) * 0.125 ), sm.vec3.new( 0, 0, 0 ), rot ) 
end













function Fant_Gatling.client_getAvailableParentConnectionCount( self, connectionType )
	if bit.band( connectionType, sm.interactable.connectionType.logic ) ~= 0 then
		return 1 - #self.interactable:getParents( sm.interactable.connectionType.logic )
	end
	if bit.band( connectionType, sm.interactable.connectionType.ammo ) ~= 0 then
		return 1 - #self.interactable:getParents( sm.interactable.connectionType.ammo )
	end
	return 0
end

function Fant_Gatling.getInputs( self )
	local active = false
	local ammo_container = nil
	local parents = self.interactable:getParents()
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[2]:isActive()
		elseif parents[2]:hasOutputType( sm.interactable.connectionType.ammo ) then
			ammo_container = parents[2]:getContainer( 0 )
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[1]:isActive()
		elseif parents[1]:hasOutputType( sm.interactable.connectionType.ammo ) then
			ammo_container = parents[1]:getContainer( 0 )
		end
	end
	-- if ammo_container == nil and active then
		-- active = false
	-- end
	return active, ammo_container
end
