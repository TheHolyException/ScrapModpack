dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_wing.lua")
Fant_Wing_2 = class()

Fant_Wing_2.LiftForce = 1

function Fant_Wing_2.server_onFixedUpdate( self, dt )
	local data = { self = self, dt = dt, LiftForce = self.LiftForce }
	WingUpdate( data )
end
