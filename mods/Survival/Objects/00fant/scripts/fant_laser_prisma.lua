dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_laser.lua"

Fant_Laser_Prisma = class()

function Fant_Laser_Prisma.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { defaultcolor = self.shape:getColor() } 
		self.storage:save( self.sv.storage )
	end
	self.sv_timer = 0
	self.sv_resetTimer = 0 
	
	self.sv_LaserTarget_1 = nil
	self.sv_LaserTarget_2 = nil
	self.sv_LaserTarget_3 = nil
end

function Fant_Laser_Prisma.client_onCreate( self )
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
	self.cl_LaserTarget_2 = nil
	self.cl_LaserTarget_3 = nil
end

function Fant_Laser_Prisma.GetData( self )	
	self.network:sendToClients( "SetData", self.sv.storage )	
end

function Fant_Laser_Prisma.SetData( self, data )
	self.cl.storage = data
end

function Fant_Laser_Prisma.server_onDestroy( self )
	self.storage:save( self.sv.storage )
end

function Fant_Laser_Prisma.client_onDestroy( self )
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

function Fant_Laser_Prisma.server_onFixedUpdate( self, dt )
	local data = self.interactable:getPublicData()
	if data ~= nil and data ~= {} then
		if data.refresh ~= nil then
			self.sv_resetTimer = data.refresh
			data.refresh = 0
			self.interactable:setPublicData( {} )
		end
	end
	local active = false
	if self.sv_resetTimer > 0 then
		active = true
		self.sv_resetTimer = self.sv_resetTimer - dt
		if self.sv_resetTimer <= 0 then	
			self.sv_resetTimer = 0			
			active = false
		end
	end
	if active ~= self.lastActive then
		self.lastActive = active
		self.network:sendToClients( "cl_setActive", self.lastActive )	
		if active == false then
			sm.shape.setColor( self.shape, sm.color.new( 0,0,0, 1 ) )
		end
	end
	
	if active then
		local currentColor = self.shape:getColor()
		if self.sv_LaserTarget_1 ~= nil and sm.exists( self.sv_LaserTarget_1 ) then
			if self.sv_LaserTarget_1.interactable then
				self.sv_LaserTarget_1.interactable:setPublicData( { refresh = 0.2 } )
			end

			local newcolor = FantMixColor(  self.sv_LaserTarget_1:getColor(), currentColor )
			if Fant_Laser_roundColor( newcolor ) ~=  Fant_Laser_roundColor( currentColor ) then
				sm.shape.setColor( self.sv_LaserTarget_1, newcolor )
			end
		end
		
		if self.sv_LaserTarget_2 ~= nil and sm.exists( self.sv_LaserTarget_2 ) then
			if self.sv_LaserTarget_2.interactable then
				self.sv_LaserTarget_2.interactable:setPublicData( { refresh = 0.2 } )
			end
			
			local newcolor = FantMixColor(  self.sv_LaserTarget_2:getColor(), currentColor )
			if Fant_Laser_roundColor( newcolor ) ~=  Fant_Laser_roundColor( currentColor ) then
				sm.shape.setColor( self.sv_LaserTarget_2, newcolor )
			end
		end
		
		if self.sv_LaserTarget_3 ~= nil and sm.exists( self.sv_LaserTarget_3 ) then
			if self.sv_LaserTarget_3.interactable then
				self.sv_LaserTarget_3.interactable:setPublicData( { refresh = 0.2 } )
			end
			
			local newcolor = FantMixColor(  self.sv_LaserTarget_3:getColor(), currentColor )
			if Fant_Laser_roundColor( newcolor ) ~=  Fant_Laser_roundColor( currentColor ) then
				sm.shape.setColor( self.sv_LaserTarget_3, newcolor )
			end
		end
	end
end

function Fant_Laser_Prisma.cl_setActive( self, state )
	if not state then
		if self.beams ~= nil then
			for i, beam in pairs( self.beams ) do
				if beam ~= nil then
					beam:stop()
				end
			end	
		end
	end
	self.cl_active = state
end

function Fant_Laser_Prisma.client_onUpdate( self, dt )
	if self.cl_active then		
		local hitShape_1 = nil
		local hitShape_Pos_1 = nil
		local ignoreShape_1 = nil
		
		local hitShape_2 = nil
		local hitShape_Pos_2 = nil
		local ignoreShape_2 = nil
		
		local hitShape_3 = nil
		local hitShape_Pos_3 = nil
		local ignoreShape_3 = nil
		
		local vd = 1
		local aThrid = math.floor( Fant_Laser_MaxBeams / 3  )
		
		hitShape_1, ignoreShape_1 = LaserBeam( self, self.beams, self.shape:getWorldPosition(), self.shape:getRight(), self.shape:getColor(), aThrid, dt, 1, aThrid, ignoreShape_1 )
		if hitShape_1 then	
			if self.cl_LaserTarget_1 ~= hitShape_1 then				
				self.cl_LaserTarget_1 = hitShape_1
				self.network:sendToServer( "sv_setLaser1", hitShape_1 )
			end
		else
			if self.cl_LaserTarget_1 ~= nil then
				self.cl_LaserTarget_1 = nil
				self.network:sendToServer( "sv_resetLaser1" )
			end
		end
		
		
		hitShape_2, ignoreShape_2 = LaserBeam( self, self.beams, self.shape:getWorldPosition(), -self.shape:getRight(), self.shape:getColor(), aThrid, dt, aThrid + 1, aThrid * 2, ignoreShape_2 )
		if hitShape_2 then	
			if self.cl_LaserTarget_2 ~= hitShape_2 then				
				self.cl_LaserTarget_2 = hitShape_2
				self.network:sendToServer( "sv_setLaser2", hitShape_2 )
			end
		else
			if self.cl_LaserTarget_2 ~= nil then
				self.cl_LaserTarget_2 = nil
				self.network:sendToServer( "sv_resetLaser2" )
			end
		end
	
		hitShape_3, ignoreShape_3 = LaserBeam( self, self.beams, self.shape:getWorldPosition(), self.shape:getUp(), self.shape:getColor(), aThrid, dt, ( aThrid * 2 ) + 1, Fant_Laser_MaxBeams, ignoreShape_3 )
		if hitShape_3 then	
			if self.cl_LaserTarget_3 ~= hitShape_3 then				
				self.cl_LaserTarget_3 = hitShape_3
				self.network:sendToServer( "sv_setLaser3", hitShape_3 )
			end
		else
			if self.cl_LaserTarget_3 ~= nil then
				self.cl_LaserTarget_3 = nil
				self.network:sendToServer( "sv_resetLaser3" )
			end
		end
	
	else
		
		if self.cl_LaserTarget_1 ~= nil then
			self.cl_LaserTarget_1 = nil
			self.network:sendToServer( "sv_resetLaser1" )
		end
		if self.cl_LaserTarget_2 ~= nil then
			self.cl_LaserTarget_2 = nil
			self.network:sendToServer( "sv_resetLaser2" )
		end
		if self.cl_LaserTarget_3 ~= nil then
			self.cl_LaserTarget_3 = nil
			self.network:sendToServer( "sv_resetLaser3" )
		end
	end
	client_BeamParticalLoop( self, dt )
end

function Fant_Laser_Prisma.sv_setLaser1( self, target )
	self.sv_LaserTarget_1 = target
end

function Fant_Laser_Prisma.sv_setLaser2( self, target )
	self.sv_LaserTarget_2 = target
end

function Fant_Laser_Prisma.sv_setLaser3( self, target )
	self.sv_LaserTarget_3 = target
end

function Fant_Laser_Prisma.sv_resetLaser1( self )
	if self.sv_LaserTarget_1 ~= nil and sm.exists( self.sv_LaserTarget_1 ) then
		if self.sv_LaserTarget_1.interactable then
			self.sv_LaserTarget_1.interactable:setPublicData( { refresh = 0 } )
		end
	end
	self.sv_LaserTarget_1 = nil
end

function Fant_Laser_Prisma.sv_resetLaser2( self )
	if self.sv_LaserTarget_2 ~= nil and sm.exists( self.sv_LaserTarget_2 ) then
		if self.sv_LaserTarget_2.interactable then
			self.sv_LaserTarget_2.interactable:setPublicData( { refresh = 0 } )
		end
	end
	self.sv_LaserTarget_2 = nil
end

function Fant_Laser_Prisma.sv_resetLaser3( self )
	if self.sv_LaserTarget_3 ~= nil and sm.exists( self.sv_LaserTarget_3 ) then
		if self.sv_LaserTarget_3.interactable then
			self.sv_LaserTarget_3.interactable:setPublicData( { refresh = 0 } )
		end
	end
	self.sv_LaserTarget_3 = nil
end
