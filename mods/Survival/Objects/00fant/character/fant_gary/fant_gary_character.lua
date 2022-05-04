dofile( "$SURVIVAL_DATA/Scripts/game/characters/Character.lua" )

Fant_Gary_Character = class( Character )

function Fant_Gary_Character.server_onCreate( self )
	--self:server_onRefresh()
end

function Fant_Gary_Character.server_onRefresh( self )

end

function Fant_Gary_Character.client_onCreate( self )
	--print( "-- Fant_Gary_Character created --" )
	--self:client_onRefresh()
end

function Fant_Gary_Character.client_onDestroy( self )
	--print( "-- Fant_Gary_Character destroyed --" )
end

function Fant_Gary_Character.client_onRefresh( self )
	--print( "-- Fant_Gary_Character refreshed --" )
end

function Fant_Gary_Character.client_onGraphicsLoaded( self )
	
end

function Fant_Gary_Character.client_onGraphicsUnloaded( self )
	
end

function Fant_Gary_Character.client_onUpdate( self, deltaTime )

end

function Fant_Gary_Character.client_onEvent( self, event )
	if event == "hit" then
		sm.effect.playEffect( "Glowgorp - Hit", self.character.worldPosition )
	end
	if event == "eat" then
		sm.effect.playEffect( "Glowgorp - Idlesound", self.character.worldPosition )
	end
	
	
	
end
