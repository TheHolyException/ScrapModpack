Fant_Itemdetector = class()
Fant_Itemdetector.poseWeightCount = 1
Fant_Itemdetector.maxChildCount = 255
Fant_Itemdetector.connectionOutput = sm.interactable.connectionType.logic
Fant_Itemdetector.colorNormal = sm.color.new( 0x800000ff )
Fant_Itemdetector.colorHighlight = sm.color.new( 0xff0000ff )
Fant_Itemdetector.SliderSteps = 20

function Fant_Itemdetector.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { size = 1 } 
	end
	if self.sv.storage.size <= 0 then
		self.sv.storage.size = 1
	end
	self.network:sendToClients( "cl_set_data", { size = self.sv.storage.size } )
	self.storage:save( self.sv.storage )
	
	local size = self.sv.storage.size * 0.25
	self.sv.areaTrigger = sm.areaTrigger.createAttachedBox( self.interactable, sm.vec3.new( size, size, size ), sm.vec3.zero(), sm.quat.identity(), sm.areaTrigger.filter.all )
	
	self.timer = 0
	self.match = false
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 1 )
	end
end

function Fant_Itemdetector.client_onCreate( self )
	self.timer = 0
	self.match = false
	self.container = self.shape:getInteractable():getContainer(0)
	self.network:sendToServer( "GetData" )
end

function Fant_Itemdetector.GetData( self )	
	self.network:sendToClients( "cl_set_data", { size = self.sv.storage.size } )	
end

function Fant_Itemdetector.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Item Detector" )
		self.gui:setText( "SubTitle", "settings" )
		self.gui:setText( "Interaction", "Block Distance: ".. tostring( self.sliderValue ) )
		self.gui:setSliderData( "Setting",self.SliderSteps+1, self.sliderValue )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setIconImage( "Icon", obj_interactive_fant_itemdetector )
		self.gui:setVisible( "FuelContainer", true )
		
		self.gui:setVisible( "BackgroundBattery", false )
		self.container = self.shape.interactable:getContainer( 0 )
		if self.container then
			self.gui:setContainer( "Fuel", self.container )
			
			self.gui:setVisible( "FuelGrid", true )
		else
			
			self.gui:setVisible( "FuelGrid", false )
		end

		self.gui:open()
	end
end

function Fant_Itemdetector.cl_onSliderChange( self, sliderName, sliderPos )
	self.sliderValue = sliderPos
	if self.sliderValue <= 0 then
		self.sliderValue = 1
	end
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Block Distance: ".. tostring( self.sliderValue ) )
	end
	self.network:sendToServer( "setSliderValue", self.sliderValue )
end

function Fant_Itemdetector.setSliderValue( self, sliderValue )
	self.sv.storage.size = sliderValue
	
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_set_data", { size = self.sv.storage.size } )
	sm.areaTrigger.destroy( self.sv.areaTrigger )
	local size = self.sv.storage.size * 0.25
	self.sv.areaTrigger = sm.areaTrigger.createAttachedBox( self.interactable, sm.vec3.new( size, size, size ), sm.vec3.zero(), sm.quat.identity(), sm.areaTrigger.filter.all )
end

function Fant_Itemdetector.cl_set_data( self, data )
	
	self.sliderValue = data.size
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Block Distance: ".. tostring( self.sliderValue ) )
	end
end


function Fant_Itemdetector.server_onFixedUpdate( self )
	if self.timer < 1 then
		self.timer = self.timer + 0.25
		return
	else
		self.timer = 0
	end
	if self.container == nil then
		return
	end
	if self.sv.areaTrigger == nil then
		return
	end
	local AreaTriggerContent = self.sv.areaTrigger:getContents()
	if AreaTriggerContent == nil then
		return
	end
	if self.container:isEmpty() then
		return
	end
	local FilterItem = self.container:getItem( 0 )
	local FilterItemUUID = nil
	if FilterItem then
		FilterItemUUID = FilterItem.uuid
	end
	local found = false
	if FilterItemUUID then
		for _, result in ipairs(  AreaTriggerContent ) do
			if sm.exists( result ) then
				if type( result ) == "Harvestable" then	
					local FoundItemUUID = nil
					if result:getType() == "filler" and g_lootHarvestables then	
						if g_lootHarvestables[result["id"]] then 
							FoundItemUUID = g_lootHarvestables[result["id"]]["uuid"]							
						end		
					else
						local data = result:getData()
						if data then
							FoundItemUUID = data["harvest"]					
						end
					end
					if FilterItemUUID == FoundItemUUID then
						found = true
						break
					end
				end
			end
		end	
	end
	if found == self.match then
		return
	end
	self.match = found
	if found then
		sm.interactable.setActive( self.interactable, true )	
		self.network:sendToClients( "cl_on" )
	else
		sm.interactable.setActive( self.interactable, false )
		self.network:sendToClients( "cl_off" )		
	end	
end

function Fant_Itemdetector.cl_on( self )
	self.shape:getInteractable():setPoseWeight( 0, 1 )
end	

function Fant_Itemdetector.cl_off( self )
	self.shape:getInteractable():setPoseWeight( 0, 0 )
end	



