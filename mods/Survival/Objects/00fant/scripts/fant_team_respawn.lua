dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_team_respawn_point.lua" )
dofile( "$GAME_DATA/Scripts/game/CreativePlayer.lua" )

Fant_Team_Respawn = class()
Fant_Team_Respawn.maxParentCount = 1
Fant_Team_Respawn.connectionInput = sm.interactable.connectionType.logic
Fant_Team_Respawn.cooldown = 0

function Fant_Team_Respawn.server_onFixedUpdate( self, dt )
	if self.cooldown ~= nil then
		if self.cooldown > 0 then
			self.cooldown = self.cooldown - dt
			return
		end
	end
	local parent = self.shape:getInteractable():getSingleParent()
	if self.state == nil then
		self.state = false
	end
	if parent then
		
		if self.state ~= parent.active then
			self.state = parent.active
			if parent.active == true then
				self.cooldown = 5
				self:sv_Respawn()
			end
		end
	end	
end

function Fant_Team_Respawn.sv_Respawn( self )
	for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
		local spawnPos = self.shape.worldPosition
		if PlayerScorces ~= nil then
			for name, score in pairs( PlayerScorces ) do 
				if name == listPlayer.name then
					local TeamSpawnPos = getTeamRespwanPoint( score.Team )
					if TeamSpawnPos ~= nil then
						spawnPos = TeamSpawnPos.shape.worldPosition + sm.vec3.new( 0, 0, 1 )
					end
				end
			end
		end
		sm.event.sendToGame( "sv_Respawn", { world = listPlayer.character:getWorld(), player = listPlayer, spawnPos = spawnPos } )
	end
end

function Fant_Team_Respawn.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	sm.gui.setInteractionText( "", sm.gui.getKeyBinding( "Use" ), "Respawn Teams!" )
	return true
end

function Fant_Team_Respawn.client_onInteract( self, character, state )
	if state == true then
		self.network:sendToServer( "sv_Respawn" )
	end
end
