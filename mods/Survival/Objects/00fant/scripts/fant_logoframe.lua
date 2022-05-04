Fant_Logoframe = class()
Fant_Logoframe.maxParentCount = 1
Fant_Logoframe.connectionInput = sm.interactable.connectionType.logic

function Fant_Logoframe.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { frameIndex = 0, state = true } 
		self.storage:save( self.sv.storage )
	end
	self.state = self.sv.storage.state
	self.frameIndex = self.sv.storage.frameIndex
end

function Fant_Logoframe.client_onCreate( self )
	self.sv = {}
	self.network:sendToServer( "GetItemFramData" )
	self.Effect = sm.effect.createEffect( "ShackLight" )
	self.Effect:setPosition( self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * 3) )
	self.Effect:start()	
	self.Effect2 = sm.effect.createEffect( "ShackLight" )
	self.Effect2:setPosition( self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * -3 ) )
	self.Effect2:start()	
end

function Fant_Logoframe.GetItemFramData( self )
	self.network:sendToClients( "UpdateDisplay", { frameIndex = self.frameIndex, state = self.state } )		
end

function Fant_Logoframe.client_onInteract(self, _, state)
	if state == true then
		local valid, result = sm.localPlayer.getRaycast( 7 )
		if valid and result then
			local leftDistance = sm.vec3.length( ( self.shape:getWorldPosition() + ( sm.shape.getUp( self.shape ) * 2 ) ) - result.pointWorld )
			local rightDistance = sm.vec3.length( ( self.shape:getWorldPosition() - ( sm.shape.getUp( self.shape ) * 2 ) ) - result.pointWorld )
			if self.frameIndex == nil then
				self.frameIndex = 0
			end
			if leftDistance < rightDistance then
				self.frameIndex = self.frameIndex + 1
				if self.frameIndex > 26 then
					self.frameIndex = 0
				end
			else
				self.frameIndex = self.frameIndex - 1
				if self.frameIndex < 0 then
					self.frameIndex = 26
				end
			end
		end		
		self.network:sendToServer( "UpdateframeIndex", { frameIndex = self.frameIndex, state = self.state } )	
	end
end

function Fant_Logoframe.UpdateframeIndex(self, data )
	self.sv.storage = data
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "UpdateDisplay", data )
end

function Fant_Logoframe.UpdateDisplay( self, data )
	self.frameIndex = data.frameIndex
	self.state = data.state
	self.interactable:setUvFrameIndex( self.frameIndex )
	if self.state then
		self.Effect:start()	
		self.Effect2:start()	
	else
		self.Effect:stop()	
		self.Effect2:stop()	
	end
end


function Fant_Logoframe.server_onFixedUpdate( self )
	local parent = self.shape:getInteractable():getSingleParent()
	if parent then
		if parent.active ~= self.state then
			self.state = parent.active
			self.sv.storage = { frameIndex = self.frameIndex, state = self.state }
			self.storage:save( self.sv.storage )
			self.network:sendToClients( "UpdateDisplay", self.sv.storage )
			sm.interactable.setActive( self.interactable, self.state )	
		end			
	end	
end


function Fant_Logoframe.client_onUpdate( self, deltaTime )
	if self.state == true then
		if math.floor( sm.vec3.length( sm.shape.getVelocity( self.shape ) ) ) >= 1 then
			self.Effect:setPosition( self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * 3) )
			self.Effect2:setPosition( self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * -3 ) )
		end
	end
end

function Fant_Logoframe.client_onDestroy( self )
	if self.Effect then
		self.Effect:stop()	
	end
	if self.Effect2 then	
		self.Effect2:stop()	
	end
end
