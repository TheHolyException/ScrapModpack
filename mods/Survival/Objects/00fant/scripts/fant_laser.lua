Fant_Laser = class()
Fant_Laser.maxParentCount = 1
Fant_Laser.connectionInput = sm.interactable.connectionType.logic

Fant_Laser_MaximalRange = 256
Fant_Laser_ParticalSpawnRate = 0.001
Fant_Laser_MaxBeams = 100
Fant_Laser_LaserBeamClamp = 0.2

function Fant_Laser.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = {} 
		self.storage:save( self.sv.storage )
	end
	
	self.sv_timer = 0
	self.sv_LaserTarget_1 = nil
end

function Fant_Laser.client_onCreate( self )
	self.cl = {}
	self.cl.storage = {}
	self.cl_active = false
	self.beams = {}
	
	for i = 1, Fant_Laser_MaxBeams do
		self.beams[i] = sm.effect.createEffect( "ShapeRenderable" )			
		self.beams[i]:setParameter( "uuid", sm.uuid.new( "2fc9be75-2d0d-4687-905d-a0fdc7f3bddd" ) )
		self.beams[i]:setParameter( "color", self.shape:getColor() )
	end
	
	self.particals = {}
	self.particalSpawnTimer = 0
	self.network:sendToServer( "GetData" )
	self.cl_networktimer = 0
	
	
	self.cl_LaserTarget_1 = nil
end

function Fant_Laser.GetData( self )	
	self.network:sendToClients( "SetData", self.sv.storage )	
end

function Fant_Laser.SetData( self, data )
	self.cl.storage = data
end

function Fant_Laser.server_onDestroy( self )
	self.storage:save( self.sv.storage )
end

function Fant_Laser.client_onDestroy( self )
	if self.particals ~= nil then
		for i, partical in pairs( self.particals ) do
			if partical ~= nil then
				if partical.effect ~= nil then
					partical.effect:stop()
					partical.effect:destroy()
					partical.effect = nil
				end
			end
		end	
	end
	if self.beams ~= nil then
		for i, beam in pairs( self.beams ) do
			if beam ~= nil then
				beam:stop()
				beam:destroy()
				beam = nil
			end
		end	
	end
end

function Fant_Laser.server_onFixedUpdate( self, dt )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() ~= self.lastActive then
			self.lastActive = parent:isActive()
			self.network:sendToClients( "cl_setActive", self.lastActive )	
		end
	end
	if self.sv_LaserTarget_1 ~= nil and sm.exists( self.sv_LaserTarget_1 ) then
		if self.sv_LaserTarget_1.interactable then
			self.sv_LaserTarget_1.interactable:setPublicData( { refresh = 0.1 } )
		end
		
		local newcolor = FantMixColor(  self.sv_LaserTarget_1:getColor(), self.shape:getColor() )
		if Fant_Laser_roundColor( newcolor ) ~=  Fant_Laser_roundColor( self.shape:getColor() ) then
			sm.shape.setColor( self.sv_LaserTarget_1, newcolor )
		end
	end
end

function Fant_Laser.cl_setActive( self, state )
	self.cl_active = state
	if not state then
		if self.beams ~= nil then
			for i, beam in pairs( self.beams ) do
				if beam ~= nil then
					beam:stop()
				end
			end	
		end
	end
end

function Fant_Laser.client_onUpdate( self, dt )
	if self.cl_active then	
		local ignoreShape = nil
		local hitShape, ignoreShape = LaserBeam( self, self.beams, self.shape:getWorldPosition(), self.shape:getUp(), self.shape:getColor(), Fant_Laser_MaxBeams, dt, 1, Fant_Laser_MaxBeams )
		if hitShape then	
			if self.cl_LaserTarget_1 ~= hitShape then				
				self.cl_LaserTarget_1 = hitShape
				self.network:sendToServer( "sv_setLaser", hitShape )
			end
		else
			if self.cl_LaserTarget_1 ~= nil then
				self.cl_LaserTarget_1 = nil
				self.network:sendToServer( "sv_resetLaser" )
			end
		end
	else
		if self.cl_LaserTarget_1 ~= nil then
			self.cl_LaserTarget_1 = nil
			self.network:sendToServer( "sv_resetLaser" )
		end
	end
	client_BeamParticalLoop( self, dt )
end

function client_createBeamPartical( self, pos, color, dt )
	if self.particalSpawnTimer > 0 then
		self.particalSpawnTimer = self.particalSpawnTimer - dt
		return
	end
	self.particalSpawnTimer = Fant_Laser_ParticalSpawnRate
	
	local Partical = {}
	Partical.lifetime = math.random( 200, 350 ) / 1000
	Partical.effect = sm.effect.createEffect( "ShapeRenderable" )	
	Partical.effect:setParameter( "uuid", sm.uuid.new( "2fc9be75-2d0d-4687-905d-a0fdc7f3bddd" ) )
	Partical.effect:setParameter( "color", color )	
	Partical.effect:start()	
	
	local dist = math.random( 10000, 20000 ) / 8000
	
	Partical.effect:setScale( sm.vec3.new( 0.01, 0.01, 0.05 * dist  ) )
	Partical.effect:setPosition( pos )
	Partical.effect:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.normalize( pos - ( pos - ( sm.vec3.new( ( math.random( -1000, 1000 ) / 1000 ), ( math.random( -1000, 1000 ) / 1000 ), ( math.random( -1000, 1000 ) / 1000 ) ) ) ) ) ) )
	
	table.insert( self.particals, Partical )
end

function client_BeamParticalLoop( self, dt )
	local counter = 0
	if self.particals ~= nil then
		local newparticals = {}	
		for i, partical in pairs( self.particals ) do
			if partical ~= nil then
				counter = counter + 1
				if partical.effect ~= nil then
					local dist = math.random( 10000, 20000 ) / 8000	
					partical.effect:setScale( sm.vec3.new( 0.01, 0.01, 0.05 * dist ) )
					if partical.lifetime ~= nil then
						partical.lifetime = partical.lifetime - dt
						if partical.lifetime <= 0 then
							partical.effect:stop()
							partical.effect:destroy()
							partical.effect = nil
							partical.lifetime = nil
							partical = nil
						end		
					end
				end
			end
			if partical ~= nil then
				table.insert( newparticals, partical )
			end
		end
		self.particals = nil
		self.particals = newparticals
		--print( "counter: ", counter )
	end
end

function FantMixColor( c1, c2 )
	if c1 == nil or c2 == nil then
		return
	end
	local a = 0.5
	local r = ( ( c1.r * a ) + ( c2.r * a ) * ( (1 - a ) ) / a )
	local g = ( ( c1.g * a ) + ( c2.g * a ) * ( (1 - a ) ) / a )
	local b = ( ( c1.b * a ) + ( c2.b * a ) * ( (1 - a ) ) / a )
	return sm.color.new( r, g, b, a )
end

function Fant_Laser_roundColor( col )
	local r = 1000
	return sm.color.new( math.floor( col.r * r ) / r, math.floor( col.g * r ) / r, math.floor( col.b * r ) / r, 1 )
end 

function Fant_Laser.sv_setLaser( self, hitShape )
	self.sv_LaserTarget_1 = hitShape
end

function Fant_Laser.sv_resetLaser( self )
	if self.sv_LaserTarget_1 ~= nil and sm.exists( self.sv_LaserTarget_1 ) then
		if self.sv_LaserTarget_1.interactable then
			self.sv_LaserTarget_1.interactable:setPublicData( { refresh = 0 } )
		end
	end
	self.sv_LaserTarget_1 = nil
end

function LaserBeam( self, beams, start, direction, color, reflect, dt, startIndex, endIndex, ignoreShape )
	local LastHitShape = nil
	local LastHitPos = nil
	for i = startIndex, endIndex do
		if reflect > 0 then
			if sm.vec3.length( direction ) > 0.001 then
				local valid, result = sm.physics.raycast( start, ( start + ( direction * Fant_Laser_MaximalRange ) ), ignoreShape )
				if result and valid then 
					local length = sm.vec3.length( start - result.pointWorld )
					if length > 0.01 and sm.vec3.length( result.normalWorld ) > 0 then	
						local noeffect = true
						local shape = result:getShape()	
						
						direction = sm.vec3.normalize( result.normalWorld - ( ( -direction - result.normalWorld ) * 2 ) )
							
						if math.abs( direction.x ) <= Fant_Laser_LaserBeamClamp then
							direction.x = 0
						end
						if math.abs( direction.y ) <= Fant_Laser_LaserBeamClamp then
							direction.y = 0
						end
						if math.abs( direction.z ) <= Fant_Laser_LaserBeamClamp then
							direction.z = 0
						end
						
						if shape ~= nil then		
							
							
							if shape:getMaterial() == "Glass" then							
								local dot = result.normalWorld:dot( direction )
								if dot > 0.999 then
									--reflect = 0
									ignoreShape = shape
									direction = -direction
									noeffect = false
									--color = FantMixColor( shape:getColor(), color )
								end
								reflect = reflect - 1								
							else
								reflect = 0
								if sm.uuid.new( "8ea2b14f-63bd-418c-a352-80aa262b2808" ) == shape:getShapeUuid() then
									if tostring( shape:getColor() ) ~= tostring( color ) then
										LastHitShape = shape
										LastHitPos = result.pointWorld
									end								
								end								
								if  sm.uuid.new( "b60f8bc3-a791-4a09-a070-b387c71b53cb" ) == shape:getShapeUuid() then
									LastHitShape = shape
									LastHitPos = result.pointWorld
								end
								if sm.uuid.new( "18555183-f3a8-452e-93ae-24649f1383fe" ) == shape:getShapeUuid() then
									LastHitShape = shape
									LastHitPos = result.pointWorld
								end
								if sm.uuid.new( "89c8ffd0-e747-430a-b2cd-1cefe9d14f01" ) == shape:getShapeUuid() then
									LastHitShape = shape
									LastHitPos = result.pointWorld
								end
							end					
						else
							reflect = 0
						end
						if not beams[i]:isPlaying() then
							beams[i]:start()
						end			
						beams[i]:setScale( sm.vec3.new( 0.1, 0.1, length ) )
						beams[i]:setPosition( ( start + result.pointWorld ) / 2 )
						beams[i]:setRotation( sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.normalize( start - result.pointWorld ) ) )
						beams[i]:setParameter( "color", color )	
						if start ~= nil and noeffect then
							for z = 1, 5 do
								client_createBeamPartical( self, result.pointWorld, color, dt )
							end
						end
						start = result.pointWorld
						
						if shape ~= nil then			
							if shape == self.shape then
								reflect = 0
							end
						end
					end	
				else			
					if beams[i]:isPlaying() then
						beams[i]:stop()
					end
				end
			else
				if beams[i]:isPlaying() then
					beams[i]:stop()
				end
			end
		else			
			if beams[i]:isPlaying() then
				beams[i]:stop()
			end
		end
	end
	return LastHitShape, ignoreShape
end


