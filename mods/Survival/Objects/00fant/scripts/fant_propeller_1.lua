dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_propeller.lua")
Fant_Propeller_1 = class()
Fant_Propeller_1.Force = 10

function Fant_Propeller_1.server_onFixedUpdate( self, dt )
	PropellerUpdate( { self = self, dt = dt, force = self.Force } )
end
