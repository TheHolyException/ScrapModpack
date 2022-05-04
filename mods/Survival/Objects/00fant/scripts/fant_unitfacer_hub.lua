dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_unitfacer.lua"

Fant_Unitfacer_Hub = class()
Fant_Unitfacer_Hub.poseWeightCount = 2	
Fant_Unitfacer_Hub.maxParentCount = 1
Fant_Unitfacer_Hub.maxChildCount = 255
Fant_Unitfacer_Hub.connectionInput = sm.interactable.connectionType.logic
Fant_Unitfacer_Hub.connectionOutput = sm.interactable.connectionType.logic

function Fant_Unitfacer_Hub.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { mode = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.mode = self.sv.storage.mode
	self.network:sendToClients( "cl_mode", { mode = self.mode }  )
	self.lastState = false
end

function Fant_Unitfacer_Hub.client_onCreate( self )
	self.mode = self.mode or 0
	self.network:sendToServer( "getData" )
end

function Fant_Unitfacer_Hub.server_onFixedUpdate( self )
	local OnOff = false
	local parent = self.shape:getInteractable():getSingleParent()
	local ID = -1
	if parent ~= nil then
		ID = parent.shape:getId()
	end
	if ID > -1 and g_Fant_Unitfacers[ ID ] ~= nil then
		if self.mode == 0 then-- 0 = Up
			OnOff = g_Fant_Unitfacers[ ID ].up
		elseif self.mode == 1 then-- 1 = Down
			OnOff = g_Fant_Unitfacers[ ID ].down
		elseif self.mode == 2 then-- 2 = Left
			OnOff = g_Fant_Unitfacers[ ID ].left
		elseif self.mode == 3 then-- 3 = Right
			OnOff = g_Fant_Unitfacers[ ID ].right
		end
	end
	--print( ID, g_Fant_Unitfacers[ ID ] )
	if self.lastState ~= OnOff then
		self.lastState = OnOff
		if OnOff then
			self.network:sendToClients( "cl_setPoseWeight", { posevalue = 1 } )
		else
			self.network:sendToClients( "cl_setPoseWeight", { posevalue = 0 } )
		end
		sm.interactable.setActive( self.interactable, OnOff )
	end
end

function Fant_Unitfacer_Hub.client_onInteract(self, character, state)
	if state then
		if character:isCrouching() then
			self.mode = self.mode - 1
			if self.mode < 0 then
				self.mode = 3
			end
		else
			self.mode = self.mode + 1
			if self.mode >= 4 then
				self.mode = 0
			end
		end
		--print( "Mode: " .. tostring( self.mode ) )
		self.network:sendToServer( "SaveMode", self.mode )
		self:UpdateFlag( self.mode )
	end
end

function Fant_Unitfacer_Hub.client_onUpdate( self, dt )

end


function Fant_Unitfacer_Hub.getData( self )
	self.network:sendToClients( "cl_mode", { mode = self.mode }  )
end

function Fant_Unitfacer_Hub.cl_mode( self, data )
	self:UpdateFlag( data.mode )
end

function Fant_Unitfacer_Hub.SaveMode( self, mode )
	self.mode = mode
	self.sv.storage = { mode = self.mode } 
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_mode", { mode = self.mode }  )
end


function Fant_Unitfacer_Hub.UpdateFlag( self, mode )
	if mode == nil then 
		return
	end
	self.mode = mode
	self.interactable:setUvFrameIndex( self.mode )
end

function Fant_Unitfacer_Hub.cl_setPoseWeight( self, data )
	self.shape:getInteractable():setPoseWeight( 0, data.posevalue )
end







