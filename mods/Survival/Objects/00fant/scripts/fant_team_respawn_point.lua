Fant_Team_Respawn_Point = class()

Team_Respawn_Points = Team_Respawn_Points or {}

function Fant_Team_Respawn_Point.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { team = "RED" } 
		self.storage:save( self.sv.storage )
	end
	self.team = self.sv.storage.team or ""
	Team_Respawn_Points[ self.shape.id ] = { Team = self.team, shape = self.shape }
	self.network:sendToClients( "cl_change_Team", self.team )
end

function Fant_Team_Respawn_Point.server_onDestroy( self )
	local new = {}
	for i, k in pairs( Team_Respawn_Points ) do
		if i ~= self.shape.id then
			new[ i ] = k
		end
	end
	Team_Respawn_Points = new
end

function Fant_Team_Respawn_Point.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_change_Team" )
	end
end

function Fant_Team_Respawn_Point.sv_change_Team( self )
	if self.team == "RED" then
		self.team = "BLUE"
	else
		self.team = "RED"
	end
	Team_Respawn_Points[ self.shape.id ] = { Team = self.team, shape = self.shape }
	self.network:sendToClients( "cl_change_Team", self.team )
	self.sv.storage = { team = self.team } 
	self.storage:save( self.sv.storage )
end

function Fant_Team_Respawn_Point.cl_change_Team( self, team )
	self.team = team
end

function Fant_Team_Respawn_Point.client_canInteract( self, character )
	if self.team == nil then
		self.team = "RED"
	end
	sm.gui.setCenterIcon( "Use" )
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "Team " .. self.team .. " Spawn Point!" )
	return true
end

function getTeamRespwanPoint( teamname )
	local REDSpawns = {}
	local BLUESpawns = {}
	for i, k in pairs( Team_Respawn_Points ) do
		if k.Team == "RED" then
			table.insert( REDSpawns, k )
		end
		if k.Team == "BLUE" then
			table.insert( BLUESpawns, k )
		end
	end
	local point = nil
	if teamname == "RED" then
		point = REDSpawns[ math.floor( math.random( 1, #REDSpawns ) ) ]
	end
	if teamname == "BLUE" then
		point = BLUESpawns[ math.floor( math.random( 1, #BLUESpawns ) ) ]
	end
	return point
end