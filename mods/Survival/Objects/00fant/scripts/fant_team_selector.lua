dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_team_respawn_point.lua" )

Fant_Team_Selector = class()

Teams = {
	"RED",
	"BLUE"
}

function Fant_Team_Selector.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "Team " .. Teams[1] )
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Tinker" ), "Team " .. Teams[2] )
	return true
end

function Fant_Team_Selector.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_joinTeam", { player = character:getPlayer(), Team = Teams[1] } )
	end
end

function Fant_Team_Selector.client_onTinker( self, character, state )
	if state then
		self.network:sendToServer( "sv_joinTeam", { player = character:getPlayer(), Team = Teams[2] } )
	end
end

function Fant_Team_Selector.sv_joinTeam( self, data )
	for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
		sm.event.sendToPlayer( listPlayer, "sv_team", data )
	end
	local spawnPos = self.shape.worldPosition
	local teamname = ""
	local TeamSpawn = getTeamRespwanPoint( data.Team )
	if TeamSpawn ~= nil then
		spawnPos = TeamSpawn.shape.worldPosition + sm.vec3.new( 0, 0, 1 )
		teamname = data.Team
	end
	sm.event.sendToGame( "sv_Respawn", { world = data.player.character:getWorld(), player = data.player, spawnPos = spawnPos, Team = teamname } )
end