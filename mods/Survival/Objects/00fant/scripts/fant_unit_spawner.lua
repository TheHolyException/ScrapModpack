dofile( "$SURVIVAL_DATA/Scripts/game/survival_units.lua")

Fant_Unit_Spawner = class()
Fant_Unit_Spawner.maxParentCount = 1
Fant_Unit_Spawner.connectionInput = sm.interactable.connectionType.logic

Units = {
	{ capsule = sm.uuid.new( "34d22fc5-0a45-4d71-9aaf-64df1355c272" ), unit = sm.uuid.new( "8984bdbf-521e-4eed-b3c4-2b5e287eb879" ) },
	{ capsule = sm.uuid.new( "da993c70-ba90-4748-8a22-6246bad32930" ), unit = sm.uuid.new( "c8bfb8f3-7efc-49ac-875a-eb85ac0614db" ) },
	{ capsule = sm.uuid.new( "4c5c3ffd-9aaf-4ded-a7c5-452d239cac32" ), unit = sm.uuid.new( "04761b4a-a83e-4736-b565-120bc776edb2" ) },
	{ capsule = sm.uuid.new( "50f624e6-7e33-4118-8252-2219e73e9af1" ), unit = sm.uuid.new( "c3d31c47-0c9b-4b07-9bd4-8f022dc4333e" ) },
	{ capsule = sm.uuid.new( "9c1f1f76-7391-4661-ae32-e96250030229" ), unit = sm.uuid.new( "9f4fde94-312f-4417-b13b-84029c5d6b52" ) },
	{ capsule = sm.uuid.new( "7735cab3-56d7-4d52-b615-090d021e8fdc" ), unit = sm.uuid.new( "48c03f69-3ec8-454c-8d1a-fa09083363b1" ) },
	{ capsule = sm.uuid.new( "12cc6e9a-6d66-4a9a-bb59-b13a50373fd8" ), unit = sm.uuid.new( "264a563a-e304-430f-a462-9963c77624e9" ) },
	{ capsule = sm.uuid.new( "da59ba03-e5fe-4940-aedf-55b72708e467" ), unit = sm.uuid.new( "176dd781-967a-4b5c-905b-4003f43b77f7" ) },
	{ capsule = sm.uuid.new( "eb783a31-3ec2-49c5-8a5f-5006da0e5d05" ), unit = sm.uuid.new( "f5294ddb-8af2-4309-a82b-7a59a7d13e54" ) },
	{ capsule = sm.uuid.new( "15743263-3e56-4b7e-a9cd-2e5b9fc531c6" ), unit = sm.uuid.new( "2f09bad6-fe15-436b-a02e-196badddb714" ) },
	{ capsule = sm.uuid.new( "04ba5ad0-1cc5-4a15-a834-720277cd07f6" ), unit = sm.uuid.new( "c9524d17-a38b-42c2-ad27-de4726e0b917" ) }
}

Filter = {
	sm.uuid.new( "34d22fc5-0a45-4d71-9aaf-64df1355c272" ),
	sm.uuid.new( "da993c70-ba90-4748-8a22-6246bad32930" ),
	sm.uuid.new( "4c5c3ffd-9aaf-4ded-a7c5-452d239cac32" ),
	sm.uuid.new( "50f624e6-7e33-4118-8252-2219e73e9af1" ),
	sm.uuid.new( "9c1f1f76-7391-4661-ae32-e96250030229" ),
	sm.uuid.new( "7735cab3-56d7-4d52-b615-090d021e8fdc" ),
	sm.uuid.new( "12cc6e9a-6d66-4a9a-bb59-b13a50373fd8" ),
	sm.uuid.new( "da59ba03-e5fe-4940-aedf-55b72708e467" ),
	sm.uuid.new( "eb783a31-3ec2-49c5-8a5f-5006da0e5d05" ),
	sm.uuid.new( "15743263-3e56-4b7e-a9cd-2e5b9fc531c6" ),
	sm.uuid.new( "04ba5ad0-1cc5-4a15-a834-720277cd07f6" )
}

function Fant_Unit_Spawner.server_onCreate( self )
	self.lastState = false
	
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 1 )
	end
	self.container:setFilters( Filter )
	self.ColorUnitId = -1
end

function Fant_Unit_Spawner.client_onCreate( self )
	self.network:sendToServer( "GetData" )
end

function Fant_Unit_Spawner.GetData( self )	
	self.network:sendToClients( "SetData", { container = self.container } )	
end

function Fant_Unit_Spawner.SetData( self, data )
	self.container = data.container
end

function Fant_Unit_Spawner.client_onInteract(self, character, state)
	if state == true then
		self.gui = sm.gui.createContainerGui( true )
		self.gui:setText( "UpperName", "Unit Blueprint" )
		self.gui:setContainer( "UpperGrid", self.container )	
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end

function Fant_Unit_Spawner.server_onFixedUpdate( self, dt )
	local parent = self.shape:getInteractable():getSingleParent()
	if parent then
		if parent.active then
			if self.lastState == false then
				self.lastState = true
				self:SpawnUnit()
			end
		else
			self.lastState = false
		end
	end
	if self.ColorUnitId > 0 then
		for i, unit in pairs( sm.unit.getAllUnits() ) do 
			if unit.id ==  self.ColorUnitId then
				unit:getCharacter():setColor(  sm.shape.getColor( self.shape ) )
				self.ColorUnitId = -1
				return
			end
		end
	end
end

function Fant_Unit_Spawner.SpawnUnit( self )
	if self.container == nil then
		return
	end
	local blueprintUnit = self.container:getItem( 0 )
	if blueprintUnit == nil then
		return
	end
	local UnitUUID = nil
	for _, blueprint in ipairs( Units ) do
		if blueprintUnit.uuid == blueprint.capsule then
			UnitUUID = blueprint.unit
			break
		end
	end
	if UnitUUID ~= nil then
		local unit = sm.unit.createUnit( UnitUUID, self.shape.worldPosition + ( sm.shape.getAt( self.shape ) ), math.random( 0, 360 ) )
		self.ColorUnitId = unit.id
	end
end



















