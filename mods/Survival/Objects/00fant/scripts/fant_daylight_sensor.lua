Fant_Daylight_Sensor = class()
Fant_Daylight_Sensor.poseWeightCount = 1	
Fant_Daylight_Sensor.maxChildCount = 255
Fant_Daylight_Sensor.connectionOutput = sm.interactable.connectionType.logic
Fant_Daylight_Sensor.DayBegin = 4
Fant_Daylight_Sensor.DayEnd = 19.5
Fant_Daylight_Sensor.RaidBegin = 23.5
Fant_Daylight_Sensor.RaidEnd = 4.5
Fant_Daylight_Sensor.colorNormal = sm.color.new( 0x800000ff )
Fant_Daylight_Sensor.colorHighlight = sm.color.new( 0xff0000ff )

		
function Fant_Daylight_Sensor.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { state = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.timer = 0
	self.state = self.sv.storage.state
	self.network:sendToClients( "setState", self.state )
	
end


function Fant_Daylight_Sensor.server_onDestroy( self )
	self.sv.storage = { state = self.state } 
	self.storage:save( self.sv.storage )
end

function Fant_Daylight_Sensor.server_onFixedUpdate( self )
	if self.timer < 10 then
		self.timer = self.timer + 0.4
		return
	end
	self.timer = 0
	
	local time = sm.storage.load( STORAGE_CHANNEL_TIME )
	if time then
		CurrentTime = time.timeOfDay * 24
		if self.state == 1 then
			if CurrentTime > self.RaidBegin or CurrentTime < self.RaidEnd then
				sm.interactable.setActive( self.interactable, true )	
			else
				sm.interactable.setActive( self.interactable, false )	
			end		
		else
			if CurrentTime > self.DayBegin and CurrentTime < self.DayEnd then
				sm.interactable.setActive( self.interactable, false )	
			else
				sm.interactable.setActive( self.interactable, true )	
			end			
		end
		--print( CurrentTime )	
	end
end

function Fant_Daylight_Sensor.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_n_toogle" )		
	end
end

function Fant_Daylight_Sensor.sv_n_toogle( self )
	if self.state == 0 then
		self.state = 1
		self.network:sendToClients( "cl_state_1" )
	else
		self.state = 0
		self.network:sendToClients( "cl_state_0" )
	end
	self.sv.storage = { state = self.state } 
	self.storage:save( self.sv.storage )
	--print( self.state )	
end


function Fant_Daylight_Sensor.setState( self, state )
	self.state = state
	self.shape:getInteractable():setPoseWeight( 0, self.state )
end


function Fant_Daylight_Sensor.cl_state_0( self )
	self.shape:getInteractable():setPoseWeight( 0, 0 )
end

function Fant_Daylight_Sensor.cl_state_1( self )
	self.shape:getInteractable():setPoseWeight( 0, 1 )
end
