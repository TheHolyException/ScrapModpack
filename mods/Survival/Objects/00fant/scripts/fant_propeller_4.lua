dofile( "$SURVIVAL_DATA/Objects/00fant/scripts/fant_propeller.lua")
Fant_Propeller_4 = class()
Fant_Propeller_4.Force = -20

function Fant_Propeller_4.server_onFixedUpdate( self, dt )
	PropellerUpdate( { self = self, dt = dt, force = self.Force } )
end