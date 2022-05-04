Fant_Unitfacer_Target = class()

g_Fant_Unitfacer_Target = g_Fant_Unitfacer_Target or {}

function Fant_Unitfacer_Target.server_onCreate( self )
	self.ID = self.shape:getId()
	g_Fant_Unitfacer_Target[ self.ID ] = self.shape
end

function Fant_Unitfacer_Target.server_onDestroy( self )	
	g_Fant_Unitfacer_Target[ self.ID ] = nil
end
