dofile "$GAME_DATA/Objects/Database/ShapeSets/interactive.json"

Fant_Cannon_1 = class()
Fant_Cannon_1.poseWeightCount = 1
Fant_Cannon_1.connectionInput =  bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.ammo )
Fant_Cannon_1.maxParentCount = 2
local SmallMinForce = 25.0
local SmallMaxForce = 30.0
local LargeMinForce = 125.0
local LargeMaxForce = 135.0
local SpreadDeg = 1.0
local ReloadSpeed = 2 * 40

function Fant_Cannon_1.server_onCreate( self )
	self.canFire = true
	self.timer = 0
	self.animation = 0
end

function Fant_Cannon_1.client_onCreate( self )
	self.shootEffect = sm.effect.createEffect( "SpudgunFrier - FrierMuzzel" )
end

function Fant_Cannon_1.server_onFixedUpdate( self )
	if not self.canFire then
		if self.timer > ReloadSpeed then
			self.timer = 0
			self.canFire = true
		else
			self.timer = self.timer + 1
		end
	end
	
	
	local logicInteractable, ammoInteractable = self:getInputs()
	if logicInteractable then
		
		if logicInteractable:isActive() and self.canFire then
			if sm.game.getEnableAmmoConsumption() then
				if ammoInteractable then
					local ammoContainer = ammoInteractable:getContainer( 0 )
					if ammoContainer then
						local AmmoType = 0
						sm.container.beginTransaction()
						if sm.container.canSpend( ammoContainer, obj_interactive_propanetank_small, 1 ) then
							sm.container.spend( ammoContainer, obj_interactive_propanetank_small, 1 )	
							AmmoType = 1				
						else
							if sm.container.canSpend( ammoContainer, obj_interactive_propanetank_large, 1 ) then
								sm.container.spend( ammoContainer, obj_interactive_propanetank_large, 1 )
								AmmoType = 2
							end
						end			
						if sm.container.endTransaction() and AmmoType > 0 then
							self.canFire = false
							local firePos = sm.vec3.new( 0.0, 0.0, -0.375 )
							local fireForce = math.random( SmallMinForce, SmallMaxForce )
							if AmmoType > 1 then
								fireForce = math.random( LargeMinForce, LargeMaxForce )
							end
							local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), SpreadDeg )
							sm.projectile.shapeProjectileAttack( "explosivetape", 7, firePos, dir * fireForce, self.shape )

							self.network:sendToClients( "cl_playShootSound" )
											
							local impulse = dir * -20000
							sm.physics.applyImpulse( self.shape, impulse, false )
						end	
					end
				end
			else
				AmmoType = 2
				self.canFire = false
				local firePos = sm.vec3.new( 0.0, 0.0, -0.375 )
				local fireForce = math.random( SmallMinForce, SmallMaxForce )
				if AmmoType > 1 then
					fireForce = math.random( LargeMinForce, LargeMaxForce )
				end
				local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), SpreadDeg )
				sm.projectile.shapeProjectileAttack( "explosivetape", 7, firePos, dir * fireForce, self.shape )

				self.network:sendToClients( "cl_playShootSound" )
								
				local impulse = dir * -20000
				sm.physics.applyImpulse( self.shape, impulse, false )
			end
		end
	end
end

function Fant_Cannon_1.client_onUpdate( self, dt )
	if self.animation then
		if self.animation > 0 then
			self.animation = self.animation - dt
			if self.animation < 0 then
				self.animation = 0
			end
		end
		self.shape:getInteractable():setPoseWeight( 0, self.animation )
	end
end

function Fant_Cannon_1.cl_playShootSound( self )
	sm.audio.play( "Gas Explosion", self.shape.worldPosition )

	self.shootEffect:setPosition( self.shape.worldPosition + ( sm.shape.getUp( self.shape ) * 1.6 ) )
	self.shootEffect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.shape.getUp( self.shape ) ) )
	--self.shootEffect:setVelocity( sm.vec3.new( 0, 1, 0 ) )
	self.shootEffect:start()
	
	self.animation = 1
end	

function Fant_Cannon_1.getInputs( self )
	local logicInteractable = nil
	local ammoInteractable = nil
	local parents = self.interactable:getParents()
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			logicInteractable = parents[2]
		elseif parents[2]:hasOutputType( sm.interactable.connectionType.ammo ) then
			ammoInteractable = parents[2]
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			logicInteractable = parents[1]
		elseif parents[1]:hasOutputType( sm.interactable.connectionType.ammo ) then
			ammoInteractable = parents[1]
		end
	end

	return logicInteractable, ammoInteractable
end
