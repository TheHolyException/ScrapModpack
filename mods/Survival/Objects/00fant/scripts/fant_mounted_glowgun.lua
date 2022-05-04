-- Fant_Mounted_Glowgun.lua --

Fant_Mounted_Glowgun = class()
Fant_Mounted_Glowgun.maxParentCount = 2
Fant_Mounted_Glowgun.maxChildCount = 0
Fant_Mounted_Glowgun.connectionInput = bit.bor( sm.interactable.connectionType.logic, sm.interactable.connectionType.ammo )
Fant_Mounted_Glowgun.connectionOutput = sm.interactable.connectionType.none
Fant_Mounted_Glowgun.colorNormal = sm.color.new( 0xcb0a00ff )
Fant_Mounted_Glowgun.colorHighlight = sm.color.new( 0xee0a00ff )
Fant_Mounted_Glowgun.poseWeightCount = 1

local FireDelay = 1 --ticks
local MinForce = 125.0
local MaxForce = 135.0
local SpreadDeg = 1.0
local Damage = 4

--[[ Server ]]

-- (Event) Called upon creation on server
function Fant_Mounted_Glowgun.server_onCreate( self )
	self:sv_init()
end

-- (Event) Called when script is refreshed (in [-dev])
function Fant_Mounted_Glowgun.server_onRefresh( self )
	self:sv_init()
end

-- Initialize mounted gun
function Fant_Mounted_Glowgun.sv_init( self )
	self.sv = {}
	self.sv.fireDelayProgress = 0
	self.sv.canFire = true
	self.sv.parentActive = false
end

-- (Event) Called upon game tick. (40 times a second)
function Fant_Mounted_Glowgun.server_onFixedUpdate( self, timeStep )
	if not self.sv.canFire then
		self.sv.fireDelayProgress = self.sv.fireDelayProgress + 1
		if self.sv.fireDelayProgress >= FireDelay then
			self.sv.fireDelayProgress = 0
			self.sv.canFire = true
		end
	end
	self:sv_tryFire()
	local logicInteractable, _ = self:getInputs()
	if logicInteractable then
		self.sv.parentActive = logicInteractable:isActive()
	end
end

-- Attempt to fire a projectile
function Fant_Mounted_Glowgun.sv_tryFire( self )
	local logicInteractable, ammoInteractable = self:getInputs()
	if logicInteractable then
		if logicInteractable:isActive() and not self.sv.parentActive and self.sv.canFire then
			if sm.game.getEnableAmmoConsumption() then
				if ammoInteractable then
					local ammoContainer = ammoInteractable:getContainer( 0 )
					if ammoContainer then
						sm.container.beginTransaction()
						sm.container.spend( ammoContainer, obj_consumable_glowstick, 1 )
						if sm.container.endTransaction() then
							self.sv.canFire = false
							local firePos = sm.vec3.new( 0.0, 0.0, 0.375 )

							-- Add random spread
							local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), SpreadDeg )

							-- Fire projectile from the shape
							--sm.projectile.shapeProjectileAttack( "potato", 7, firePos, dir * fireForce, self.shape )
							sm.projectile.shapeProjectileAttack( "fant_glowstick", 50, firePos, dir * 250, self.shape )
							self.network:sendToClients( "cl_onShoot" )
						end
					end
				end
			else
				self.sv.canFire = false
				local firePos = sm.vec3.new( 0.0, 0.0, 0.375 )

				-- Add random spread
				local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), SpreadDeg )

				-- Fire projectile from the shape
				--sm.projectile.shapeProjectileAttack( "potato", 7, firePos, dir * fireForce, self.shape )
				sm.projectile.shapeProjectileAttack( "fant_glowstick", 50, firePos, dir * 250, self.shape )
				self.network:sendToClients( "cl_onShoot" )
			end
		end
	end
end


--[[ Client ]]

-- (Event) Called upon creation on client
function Fant_Mounted_Glowgun.client_onCreate( self )
	self.cl = {}
	self.cl.boltValue = 0.0
end


-- (Event) Called upon every frame. (Same as fps)
function Fant_Mounted_Glowgun.client_onUpdate( self, dt )
	if self.cl.boltValue > 0.0 then
		self.cl.boltValue = self.cl.boltValue - dt * 10
	end
	if self.cl.boltValue ~= self.cl.prevBoltValue then	
		self.interactable:setPoseWeight( 0, self.cl.boltValue ) --Clamping inside
		self.cl.prevBoltValue = self.cl.boltValue
	end
end

function Fant_Mounted_Glowgun.client_getAvailableParentConnectionCount( self, connectionType )
	if bit.band( connectionType, sm.interactable.connectionType.logic ) ~= 0 then
		return 1 - #self.interactable:getParents( sm.interactable.connectionType.logic )
	end
	if bit.band( connectionType, sm.interactable.connectionType.ammo ) ~= 0 then
		return 1 - #self.interactable:getParents( sm.interactable.connectionType.ammo )
	end
	return 0
end

-- Called from server upon the gun shooting
function Fant_Mounted_Glowgun.cl_onShoot( self )
	self.cl.boltValue = 1.0
	local impulse = sm.vec3.new( 0, 0, -1 ) * 500
	sm.physics.applyImpulse( self.shape, impulse )
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ),sm.shape.getUp( self.shape ) )
	sm.effect.playEffect( "SpudgunSpinner - SpinnerMuzzel", self.shape.worldPosition + ( sm.shape.getUp( self.shape ) * 0.65 ), sm.vec3.new( 0, 0, 0 ), rot ) 
end

function Fant_Mounted_Glowgun.getInputs( self )
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
