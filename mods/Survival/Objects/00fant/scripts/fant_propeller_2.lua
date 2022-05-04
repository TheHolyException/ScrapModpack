dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_propeller.lua")
Fant_Propeller_2 = class()
Fant_Propeller_2.Force = -10

function Fant_Propeller_2.server_onFixedUpdate( self, dt )
	PropellerUpdate( { self = self, dt = dt, force = self.Force } )
end
