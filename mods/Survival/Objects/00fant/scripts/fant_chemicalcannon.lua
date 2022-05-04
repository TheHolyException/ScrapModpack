dofile "$GAME_DATA/Objects/Database/ShapeSets/interactive.json"

Fant_Chemicalcannon = class()
Fant_Chemicalcannon.poseWeightCount = 1
Fant_Chemicalcannon.connectionInput =  bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.water )
Fant_Chemicalcannon.maxParentCount = 2
Fant_Chemicalcannon.colorNormal = sm.color.new( 0x8800ffff )
Fant_Chemicalcannon.colorHighlight = sm.color.new( 0x8800ffff )

local MinForce = 25.0
local MaxForce = 30.0
local SpreadDeg = 1.0
local ReloadSpeed = 2 * 40

function Fant_Chemicalcannon.server_onCreate( self )
	self.canFire = true
	self.timer = 0
	self.animation = 0
end

function Fant_Chemicalcannon.client_onCreate( self )
	self.shootEffect = sm.effect.createEffect( "Mountedwatercanon - Shoot" )
end

function Fant_Chemicalcannon.server_onFixedUpdate( self )
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
		if sm.game.getEnableAmmoConsumption() then
			if ammoInteractable then
				local ammoContainer = ammoInteractable:getContainer( 0 )
				if logicInteractable:isActive() and self.canFire and ammoContainer then
					sm.container.beginTransaction()
					sm.container.spend( ammoContainer, obj_consumable_chemical, 1 )			
					if sm.container.endTransaction() then
						self.canFire = false
						local firePos = sm.vec3.new( 0.0, 0.0, 0.5 )
						local fireForce = math.random( MinForce, MaxForce )
						local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), SpreadDeg )
						sm.projectile.shapeProjectileAttack( "pesticide", 7, firePos, dir * fireForce, self.shape )

						self.network:sendToClients( "cl_playShootSound" )
										
						local impulse = dir * -20000
						sm.physics.applyImpulse( self.shape, impulse, false )
					end			
				end
			end
		else 
			if logicInteractable:isActive() and self.canFire then
				self.canFire = false
				local firePos = sm.vec3.new( 0.0, 0.0, 0.5 )
				local fireForce = math.random( MinForce, MaxForce )
				local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), SpreadDeg )
				sm.projectile.shapeProjectileAttack( "pesticide", 7, firePos, dir * fireForce, self.shape )

				self.network:sendToClients( "cl_playShootSound" )
								
				local impulse = dir * -20000
				sm.physics.applyImpulse( self.shape, impulse, false )	
			end
		end
	end
end

function Fant_Chemicalcannon.client_onUpdate( self, dt )
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

function Fant_Chemicalcannon.cl_playShootSound( self )
	self.shootEffect:setPosition( self.shape.worldPosition + ( sm.shape.getUp( self.shape ) * 0.1 ) )
	self.shootEffect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.shape.getUp( self.shape ) ) )
	self.shootEffect:setVelocity( sm.vec3.new( 5, 0, 0 ) )
	self.shootEffect:start()	
	self.animation = 1
end	

function Fant_Chemicalcannon.getInputs( self )
	local logicInteractable = nil
	local ammoInteractable = nil
	local parents = self.interactable:getParents()
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			logicInteractable = parents[2]
		elseif parents[2]:hasOutputType( sm.interactable.connectionType.water ) then
			ammoInteractable = parents[2]
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			logicInteractable = parents[1]
		elseif parents[1]:hasOutputType( sm.interactable.connectionType.water ) then
			ammoInteractable = parents[1]
		end
	end

	return logicInteractable, ammoInteractable
end
