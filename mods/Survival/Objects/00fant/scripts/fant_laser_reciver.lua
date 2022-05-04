Fant_Laser_Reciver = class()
Fant_Laser_Reciver.maxChildCount = 256
Fant_Laser_Reciver.connectionOutput = sm.interactable.connectionType.logic
Fant_Laser_Reciver.colorNormal = sm.color.new( 0x0000680ff )
Fant_Laser_Reciver.colorHighlight = sm.color.new( 0x0000ff0ff )

function Fant_Laser_Reciver.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { color = self.shape:getColor(), defaultcolor = self.shape:getColor() } 
		self.storage:save( self.sv.storage )
	end
	self.sv_resetTimer = 0
end

function Fant_Laser_Reciver.server_onFixedUpdate( self, dt )
	if self.sv_resetTimer > 0 then
		self.sv_resetTimer = self.sv_resetTimer - dt
		if self.sv_resetTimer <= 0 then	
			self.sv_resetTimer = 0			
		end
		if tostring( Fant_Laser_Reciver_roundColor( self.sv.storage.color ) ) == tostring( Fant_Laser_Reciver_roundColor( self.shape:getColor() ) ) then
			sm.interactable.setActive( self.interactable, true )	
		else
			sm.interactable.setActive( self.interactable, false )	
		end
	else
		sm.interactable.setActive( self.interactable, false )
		sm.shape.setColor( self.shape, self.sv.storage.defaultcolor )
	end
	
	local data = self.interactable:getPublicData()
	if data ~= nil and data ~= {} then
		if data.refresh ~= nil then
			self.sv_resetTimer = data.refresh
			data.refresh = 0
			self.interactable:setPublicData( {} )
		end
	end
end

function Fant_Laser_Reciver.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_refresh" )
	end
end

function Fant_Laser_Reciver.sv_refresh( self )
	self.sv.storage.color = self.shape:getColor()  
	self.storage:save( self.sv.storage )
end

function Fant_Laser_Reciver_roundColor( col )
	local r = 10
	return sm.color.new( math.floor( col.r * r ) / r, math.floor( col.g * r ) / r, math.floor( col.b * r ) / r, math.floor( col.a * r ) / r )
end 
