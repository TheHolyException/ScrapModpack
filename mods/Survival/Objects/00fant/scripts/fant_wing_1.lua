dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_wing.lua")
Fant_Wing_1 = class()

Fant_Wing_1.LiftForce = 1

function Fant_Wing_1.server_onFixedUpdate( self, dt )
	local data = { self = self, dt = dt, LiftForce = self.LiftForce }
	WingUpdate( data )
end
