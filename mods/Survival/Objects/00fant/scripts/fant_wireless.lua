Fant_Wireless = class()
Fant_Wireless.maxChildCount = 255
Fant_Wireless.connectionOutput = sm.interactable.connectionType.logic
Fant_Wireless.maxParentCount = 255
Fant_Wireless.connectionInput = sm.interactable.connectionType.logic
Channel = Channel or {}

function Fant_Wireless.server_onCreate( self )	
	self.state = true
	self.lastState = nil
end

function Fant_Wireless.server_onFixedUpdate( self, dt )
	if self.interactable then
		local colorstring = tostring(sm.shape.getColor( self.shape ))
		local isActive = false
		if Channel[ colorstring ] ~= self.lastState and Channel[ colorstring ] ~= nil then
			self.lastState = Channel[ colorstring ]
			sm.interactable.setActive( self.shape:getInteractable(), Channel[ colorstring ] )
		end
		for i, parent in pairs( self.interactable:getParents() ) do
			if parent.active then
				isActive = true
				break
			end
		end
		if isActive ~= self.state then
			self.state = isActive
			Channel[ colorstring ] = self.state
		end		
		if isActive then
			Channel[ colorstring ] = isActive
		end	
	end
end
