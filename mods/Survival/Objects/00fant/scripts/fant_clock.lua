dofile( "$SURVIVAL_DATA/Scripts/game/survival_items.lua")

Fant_Clock = class()
Fant_Clock.FS = ( 1 /24 )
Fant_Clock.maxChildCount = 255
Fant_Clock.connectionOutput = sm.interactable.connectionType.logic

function Fant_Clock.server_onCreate( self )	
	self.logicValue = 0
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { logicValue = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.logicValue = self.sv.storage.logicValue
	local time = sm.storage.load( STORAGE_CHANNEL_TIME )
	self.sv_time = math.floor( time.timeOfDay * 24 )
	self.network:sendToClients( "cl_setTime", self.sv_time )
	self.active = false
	self.network:sendToClients( "cl_setLogic", self.logicValue )
	
	self.hours = 0
	self.minutes = 0
	self.ClearHours = 0
	self.ClearMinutes = 0
end

function Fant_Clock.server_onDestroy( self )
	self.sv = {}
	self.sv.storage = { logicValue = self.logicValue } 
	self.storage:save( self.sv.storage )
end

function Fant_Clock.client_onCreate( self )
	self.hours = 0
	self.minutes = 0
	self.ClearHours = 0
	self.ClearMinutes = 0
	self.active = false
	
	self.interactable:setAnimEnabled("Logic", true)
	self.interactable:setAnimEnabled("Hour", true)
	self.interactable:setAnimEnabled("Minute", true)
	
	self.network:sendToServer( "getLogic" )
end

function Fant_Clock.client_onDestroy( self )

end

function Fant_Clock.client_onInteract(self, character, state)
	if state == true then
		self.logicValue = self.logicValue + 1
		if self.logicValue >= 12 then
			self.logicValue = 0
		end
		self.network:sendToServer( "sv_setLogic", self.logicValue )
	end
end

function Fant_Clock.getLogic( self )
	self.network:sendToClients( "cl_setLogic", self.logicValue )
end

function Fant_Clock.sv_setLogic( self, value )
	self.logicValue = value
	self.network:sendToClients( "cl_setLogic", self.logicValue )
	self.sv = {}
	self.sv.storage = { logicValue = self.logicValue } 
	self.storage:save( self.sv.storage )
end

function Fant_Clock.cl_setLogic( self, value )
	self.logicValue = value
end

function Fant_Clock.server_onFixedUpdate( self, dt )
	local time = sm.storage.load( STORAGE_CHANNEL_TIME )
	if time then
		if math.floor( time.timeOfDay * 24 ) ~= self.sv_time then
			self.sv_time = math.floor( time.timeOfDay * 24 )
			self.network:sendToClients( "cl_setTime", self.sv_time )
			self.ClearHours = math.floor( self.sv_time )
			if self.ClearHours >= 12 then
				self.ClearHours = self.ClearHours - 12
			end
		end
	end
	if self.logicValue == self.ClearHours and self.ClearMinutes == 0 and not self.active then
		self.active = true
		sm.interactable.setActive( self.interactable, self.active )
	end
	if ( self.logicValue ~= self.ClearHours or self.ClearMinutes ~= 0 ) and self.active then
		self.active = false
		sm.interactable.setActive( self.interactable, self.active )
	end
end

function Fant_Clock.cl_setTime( self, newTime )
	self.hours = newTime
	self.minutes = 7
	self.ClearHours = math.floor( self.hours )
	if self.ClearHours >= 12 then
		self.ClearHours = self.ClearHours - 12
	end
end

function Fant_Clock.client_onUpdate( self, dt )
	self.minutes = self.minutes + ( ( dt / DAYCYCLE_TIME ) * 24 * 60 )
	self.ClearMinutes = math.floor( self.minutes )
	if self.minutes >= 60 then
		self.minutes = 0
		self.hours = self.hours + 1
		if self.hours >= 24 then
			self.hours = 0
		end
		self.ClearHours = math.floor( self.hours )
		if self.ClearHours >= 12 then
			self.ClearHours = self.ClearHours - 12
		end
	end
	--print( "Time: " .. tostring( self.ClearHours ) .. ":" ..  tostring( self.ClearMinutes ) .. " - Logic Time: " .. tostring( self.logicValue ) )
	self.interactable:setAnimProgress("Logic", ( (self.logicValue ) / 12 ) % 1 )
	self.interactable:setAnimProgress("Hour", ( self.minutes / 60 ) )
	self.interactable:setAnimProgress("Minute", ( self.hours / 12 ) % 1 )
end


