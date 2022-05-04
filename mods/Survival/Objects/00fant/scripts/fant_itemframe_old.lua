Fant_Itemframe = class()

function Fant_Itemframe.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { frameIndex = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.frameIndex = self.sv.storage.frameIndex
end
function Fant_Itemframe.client_onCreate( self )
	self.sv = {}
	self.network:sendToServer( "GetItemFramData" )
end

function Fant_Itemframe.GetItemFramData( self )
	self.network:sendToClients( "UpdateDisplay", { frameIndex = self.frameIndex } )	
end


function Fant_Itemframe.client_onInteract(self, character, state)
	if state == true then
		if character:isCrouching() then
			self.frameIndex = self.frameIndex - 1
			if self.frameIndex < 0 then
				self.frameIndex = 83
			end
		else
			self.frameIndex = self.frameIndex + 1
			if self.frameIndex > 83 then
				self.frameIndex = 0
			end
		end
		
		self.network:sendToServer( "UpdateframeIndex", { frameIndex = self.frameIndex } )	
	end
end

function Fant_Itemframe.UpdateframeIndex(self, data )
	self.sv.storage = data
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "UpdateDisplay", data )
end


function Fant_Itemframe.UpdateDisplay( self, data )
	self.frameIndex = data.frameIndex
	self.interactable:setUvFrameIndex( self.frameIndex )
end