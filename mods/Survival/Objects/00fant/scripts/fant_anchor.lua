Fant_Anchor = class()

Fant_Anchor.maxParentCount = 1
Fant_Anchor.connectionInput = sm.interactable.connectionType.logic

g_tranferData = {}

function Fant_Anchor.server_onCreate( self )
	self.initTimer = 0.5
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {}
	end
	local parent = self.interactable:getSingleParent()
	local onLoadActive = false
	if parent ~= nil then
		onLoadActive = parent:isActive()
	end
	self.saved.state = onLoadActive
	if g_tranferData == nil then
		g_tranferData = {}
	end
	local body = sm.shape.getBody( self.shape )
	local shapes = sm.body.getCreationShapes( body )
	if g_tranferData ~= {} then
		for p, l in pairs( g_tranferData ) do
			if l ~= nil then
				for i, new_shape in pairs( shapes ) do
					if new_shape ~= nil then
						local sub_interactable = new_shape:getInteractable()
						if sub_interactable ~= nil then
							if sub_interactable:hasSeat() then
								sub_interactable:setSeatCharacter( l.character )
								l = nil
							end
						end
					end
				end
			end
		end
	end
	g_tranferData = {}
	self.storage:save( self.saved )
end

function Fant_Anchor.server_onFixedUpdate( self, dt )
	if self.initTimer > 0 then
		self.initTimer = self.initTimer - dt
		return
	end
	local body = sm.shape.getBody( self.shape )
	if body == nil then
		return
	end
	
	local parent = self.interactable:getSingleParent()
	if parent == nil then
		return
	end
	local active = parent:isActive()
	if self.saved.state ~= active then
		self.saved.state = active
		self.storage:save( self.saved )
		
		local worldPosition = body.worldPosition

		local obj = sm.json.parseJsonString( sm.creation.exportToString( body ) )

		local isStatic = obj.bodies[1].type
		for i, k in pairs( 	obj.bodies ) do
			if isStatic == 1 then
				k.type = 0
			else
				k.type = 1
			end
		end
		sm.json.save( obj, "$SURVIVAL_DATA/LocalBlueprints/fant_anchor_save.blueprint" )
		local shapes = sm.body.getCreationShapes( body )
		g_tranferData = {}
		for i, shape in pairs( shapes ) do
			if shape ~= nil then
				local sub_interactable = shape:getInteractable()
				if sub_interactable ~= nil then
					if sub_interactable:hasSeat() then
						if sub_interactable:getSeatCharacter() ~= nil then
							table.insert( g_tranferData, { character = sub_interactable:getSeatCharacter(), seat = sub_interactable } )
						end
					end
				end
			end
		end
		for i, shape in ipairs(shapes) do 
			sm.shape.destroyShape( shape, 0 )
		end
		sm.creation.importFromFile( sm.world.getCurrentWorld(), "$SURVIVAL_DATA/LocalBlueprints/fant_anchor_save.blueprint", worldPosition )

	end
end










