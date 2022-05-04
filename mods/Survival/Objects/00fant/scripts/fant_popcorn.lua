dofile("$SURVIVAL_DATA/Scripts/game/survival_units.lua")

Fant_Popcorn = class()
Fant_Popcorn.Range = 1
Fant_Popcorn.ValidTargets = {
	unit_tapebot,
	unit_tapebot_taped_1,
	unit_tapebot_taped_2,
	unit_tapebot_taped_3,
	unit_tapebot_red,
	unit_totebot_green,
	unit_haybot,
	unit_farmbot,
	unit_totebot_red,
	unit_totebot_blue,
	unit_heavy_haybot
	--unit_woc,
	--unit_worm,
	--unit_mechanic
}

--Server

function Fant_Popcorn.server_onCreate( self )	
	self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), sm.vec3.new( self.Range, self.Range, self.Range ), sm.vec3.new( 0, 0, 0 ), sm.quat.identity()  )			
end

function Fant_Popcorn.server_onDestroy( self )

end

function Fant_Popcorn.server_onFixedUpdate( self, dt )
	for _, result in ipairs(  self.areaTrigger:getContents() ) do
		if sm.exists( result ) then
			if type( result ) == "Character" then
				if self:getVaildTarget( result:getCharacterType() ) then
					self:Explode()
					return
				end
			end
			if type( result ) == "Body" then
				local shape = result:getShapes()[1]
				if shape ~= self.shape then
					if shape:getShapeUuid() == fant_straw_dog then
						self:Explode()
						return
					end
					if shape:getShapeUuid() == fant_beebot then
						self:Explode()
						return
					end
				end
			end
		end
	end
end

function Fant_Popcorn.getVaildTarget( self, unit )
	for i, valid in pairs(  self.ValidTargets ) do
		if unit == valid then
			return true
		end
	end
	return false
end

function Fant_Popcorn.Explode( self )
	self.destructionLevel = 5
	self.destructionRadius = 5
	self.impulseRadius = 5.0
	self.impulseMagnitude = 5.0
	self.explosionEffectName = "PropaneTank - ExplosionSmall" 
	
	sm.physics.explode( self.shape.worldPosition, self.destructionLevel, self.destructionRadius, self.impulseRadius, self.impulseMagnitude, self.explosionEffectName, self.shape )
	sm.shape.destroyPart( self.shape )
end

--Client
-- function Fant_Popcorn.client_onCreate( self )

-- end

-- function Fant_Popcorn.client_onDestroy( self )

-- end

-- function Fant_Popcorn.client_onUpdate( self, dt )
	
-- end

-- function Fant_Popcorn.client_onInteract(self, character, state)
	-- if state == true then

	-- end
-- end

-- self.network:sendToClients( "xyz" )
-- self.network:sendToServer( "xyz" )

	
	
	
	