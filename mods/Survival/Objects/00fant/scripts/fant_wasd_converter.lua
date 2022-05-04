Fant_Wasd_Converter = class()
Fant_Wasd_Converter.maxParentCount = 2
Fant_Wasd_Converter.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
Fant_Wasd_Converter.maxChildCount = 255
Fant_Wasd_Converter.connectionOutput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power + sm.interactable.connectionType.bearing
Fant_Wasd_Converter.poseWeightCount = 2	
Fant_Wasd_Converter.colorNormal = sm.color.new( 0x008000ff )
Fant_Wasd_Converter.colorHighlight = sm.color.new( 0x00ff00ff )

KeyParameter = KeyParameter or {}

function Fant_Wasd_Converter.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { frameIndex = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.frameIndex = self.sv.storage.frameIndex
	self.lastState = false
end

function Fant_Wasd_Converter.client_onCreate( self )
	self.sv = {}
	self.frameIndex = self.frameIndex or 0
	self.network:sendToServer( "sv_GetItemFramData" )
end

function Fant_Wasd_Converter.sv_GetItemFramData( self )
	self.network:sendToClients( "cl_UpdateDisplay", { frameIndex = self.frameIndex } )	
end

function Fant_Wasd_Converter.client_onInteract(self, character, state)
	if state == true then
		if character:isCrouching() then
			self.frameIndex = self.frameIndex - 1
			if self.frameIndex < 0  then
				self.frameIndex = 6
			end
		else
			self.frameIndex = self.frameIndex + 1
			if self.frameIndex >= 7 then
				self.frameIndex = 0
			end
		end
		print( self.frameIndex )
		self.network:sendToServer( "sv_UpdateframeIndex", { frameIndex = self.frameIndex } )	
	end
end

function Fant_Wasd_Converter.sv_UpdateframeIndex(self, data )
	self.sv.storage = data
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_UpdateDisplay", data )
end

function Fant_Wasd_Converter.server_onFixedUpdate( self )
	local OnOff = false
	local parents = self.interactable:getParents()
	if #parents > 0 then
		if parents[1]:isActive() then
			local WS = parents[1]:getPower()
			local AD = parents[1].shape.interactable:getSteeringAngle()
			
			if self.frameIndex == 0 and WS > 0 then
				OnOff = true
			elseif self.frameIndex == 2 and WS < 0 then
				OnOff = true
			elseif self.frameIndex == 1 and AD < 0 then
				OnOff = true
			elseif self.frameIndex == 3 and AD > 0 then
				OnOff = true
			elseif self.frameIndex == 4 then
				OnOff = true
			end
			if self.frameIndex > 4 then
				local ID = parents[1].shape:getId()
				if KeyParameter[ID] ~= nil then
					if KeyParameter[ID][19] ~= nil and self.frameIndex == 5 then -- Key 19 Left Mouse
						OnOff = KeyParameter[ID][19]
					end
					if KeyParameter[ID][18] ~= nil and self.frameIndex == 6 then -- Key 18 Right Mouse
						OnOff = KeyParameter[ID][18]
					end
				end
			end
		end
	end
	sm.interactable.setActive( self.interactable, OnOff )
	if self.lastState ~= OnOff then
		self.lastState = OnOff
		if OnOff then
			self.network:sendToClients( "cl_setPoseWeight", { value = 1 } )
		else
			self.network:sendToClients( "cl_setPoseWeight", { value = 0 } )
		end
	end
end

function Fant_Wasd_Converter.cl_setPoseWeight( self, data )
	self.shape:getInteractable():setPoseWeight( 0, data.value )
end

function Fant_Wasd_Converter.cl_UpdateDisplay( self, data )
	self.frameIndex = data.frameIndex
	self.interactable:setUvFrameIndex( self.frameIndex )
end

