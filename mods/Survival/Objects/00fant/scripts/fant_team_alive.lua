dofile( "$GAME_DATA/Scripts/game/CreativePlayer.lua" )

Fant_Team_Alive = class()
Fant_Team_Alive.maxChildCount = 255
Fant_Team_Alive.connectionOutput = sm.interactable.connectionType.logic

function Fant_Team_Alive.server_onCreate( self )
	self.state = false
	self.team = "RED"
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { team = "RED" } 
		self.storage:save( self.sv.storage )
	end
	self.team = self.sv.storage.team or ""
	self.network:sendToClients( "cl_change_Team", self.team )
end

function Fant_Team_Alive.cl_change_Team( self, team )
	self.team = team
end

function Fant_Team_Alive.client_canInteract( self, character )
	if self.team == nil then
		self.team = "RED"
	end
	sm.gui.setCenterIcon( "Use" )
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "Team " .. self.team )
	return true
end

function Fant_Team_Alive.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_change_Team" )
	end
end

function Fant_Team_Alive.sv_change_Team( self )
	if self.team == "RED" then
		self.team = "BLUE"
	else
		self.team = "RED"
	end
	self.network:sendToClients( "cl_change_Team", self.team )
	self.sv.storage = { team = self.team } 
	self.storage:save( self.sv.storage )
end


function Fant_Team_Alive.sv_isTeamAlive( self )
	TeamAlive = {}
	for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
		if PlayerScorces[ listPlayer.name ] ~= nil then
			if PlayerScorces[ listPlayer.name ].Team ~= nil then
				if TeamAlive[ PlayerScorces[ listPlayer.name ].Team ] == nil then
					TeamAlive[ PlayerScorces[ listPlayer.name ].Team ] = { Alive = 0, Total = 0 }
				end
				if PlayerHealths[ listPlayer.name ] > 0 then
					TeamAlive[ PlayerScorces[ listPlayer.name ].Team ].Alive = TeamAlive[ PlayerScorces[ listPlayer.name ].Team ].Alive + 1
				end
				TeamAlive[ PlayerScorces[ listPlayer.name ].Team ].Total = TeamAlive[ PlayerScorces[ listPlayer.name ].Team ].Total + 1
			end
		end
	end
	return TeamAlive
end


function Fant_Team_Alive.server_onFixedUpdate( self, dt )
	local Teamdata = self:sv_isTeamAlive()
	local Alive = true
	local foundTeam = false
	for Team, Data in pairs( Teamdata ) do 
		if Team == self.team then
			foundTeam = true
			if Data.Alive > 0 then
				Alive = false
				break				
			end
		end
	end
	if not foundTeam then
		Alive = false
	end
	if Alive ~= self.state then
		self.state = Alive
		sm.interactable.setActive( self.interactable, self.state )	
	end
end