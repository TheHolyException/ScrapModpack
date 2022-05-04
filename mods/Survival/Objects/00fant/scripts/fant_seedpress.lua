dofile( "$SURVIVAL_DATA/Scripts/game/survival_items.lua")

Fant_Seedpress = class()
Fant_Seedpress.poseWeightCount = 2
Fant_Seedpress.maxParentCount = 3
Fant_Seedpress.connectionInput = sm.interactable.connectionType.water + sm.interactable.connectionType.logic

Fant_Seedpress.ProductionSpeed = 1/3
Fant_Seedpress.ProductionlRewardOil = 2
Fant_Seedpress.ProductionlRewardWood = 10

Fant_Seedpress.Recipes = {
	--tier 1
	{ seed = obj_seed_carrot, 	seedAmount = 10, chemicalAmount = 4 },
	{ seed = obj_seed_redbeet, 	seedAmount = 10, chemicalAmount = 4 },
	{ seed = obj_seed_tomato, 	seedAmount = 10, chemicalAmount = 4 },
	--tier2
	{ seed = obj_seed_potato, 	seedAmount = 8,  chemicalAmount = 3 },
	{ seed = obj_seed_cotton, 	seedAmount = 8,  chemicalAmount = 3 },
	{ seed = obj_seed_eggplant, seedAmount = 8,  chemicalAmount = 3 },
	--tier3
	{ seed = obj_seed_banana, 	seedAmount = 6,  chemicalAmount = 2 },
	{ seed = obj_seed_blueberry,seedAmount = 6,  chemicalAmount = 2 },
	{ seed = obj_seed_orange, 	seedAmount = 6,  chemicalAmount = 2 },
	--tier4
	{ seed = obj_seed_pineapple,seedAmount = 4,  chemicalAmount = 1 },	
	{ seed = obj_seed_broccoli, seedAmount = 4,  chemicalAmount = 1 }
}


function Fant_Seedpress.server_onCreate( self )	
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 10, 256 )
	end
	self.container:setFilters( { obj_resource_crudeoil, blk_scrapwood } )	
	self.pressValue = 0
	self.laststate = 0
	
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { mode = "Scrapwood" } 
		self.storage:save( self.sv.storage )
	end
	self.mode = self.sv.storage.mode
	self.network:sendToClients( "cl_setMode", self.mode )
end

function Fant_Seedpress.server_onDestroy( self )

end

function Fant_Seedpress.client_onDestroy( self )

end

function Fant_Seedpress.client_onCreate( self )
	self.state = 0
	self.poseDirection = 1
	self.poseValue = 0
	self.lastPoseValue = 0
	
	self.cl_mode = "Scrapwood"
	self.network:sendToServer( "GetMode" )	
end

function Fant_Seedpress.GetMode( self )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_Seedpress.sv_setMode( self, mode )
	self.mode = mode
	self.sv.storage.mode = self.mode
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_Seedpress.cl_setMode( self, mode )
	self.cl_mode = mode
end

function Fant_Seedpress.client_canCarry( self )
	self.container = self.shape.interactable:getContainer( 0 )
	if self.container and sm.exists( self.container ) then
		return not self.container:isEmpty()
	end
	return false
end

function Fant_Seedpress.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Open" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. tostring( self.cl_mode ) )
	return true
end


function Fant_Seedpress.client_onTinker( self, character, state )
	if state then
		if self.cl_mode == "Scrapwood" then
			self.cl_mode = "Oil"
		else
			self.cl_mode = "Scrapwood"
		end
		self.network:sendToServer( "sv_setMode", self.cl_mode )	
	end
end


function Fant_Seedpress.client_onInteract(self, character, state)
	if state == true then
		self.container = self.shape:getInteractable():getContainer(0)
		if self.container then
			self.gui = sm.gui.createContainerGui( true )				
			self.gui:setText( "UpperName", "Seed Press" )
			self.gui:setContainer( "UpperGrid", self.container )	
			self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
			self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )	
			self.gui:open()		
		end		
	end
end

function Fant_Seedpress.getInputs( self )
	local parents = self.interactable:getParents()
	local seedContainer = nil
	local chemicalContainer = nil
	local active = false
	local generateOil = false
	if self.mode == "Oil" then
		generateOil = true
	end
	for i = 1, #parents + 1 do 
		if parents[i] then	
			if parents[i]:hasOutputType( sm.interactable.connectionType.logic ) then
				active = parents[i]:isActive()
			end
			if parents[i]:hasOutputType( sm.interactable.connectionType.water ) then		
				if parents[i].shape["uuid"] == obj_container_seed then
					seedContainer = parents[i]:getContainer( 0 )
				end
				if parents[i].shape["uuid"] == obj_container_chemical then
					chemicalContainer = parents[i]:getContainer( 0 )
				end
				if parents[i].shape["uuid"] == obj_interactive_fant_fluidconnector then
					chemicalContainer = parents[i]:getContainer( 0 )
				end
			end
		end
	end
	return active, seedContainer, chemicalContainer, generateOil
end

function Fant_Seedpress.HasRequiements( self, seedContainer, chemicalContainer )
	if seedContainer == nil then
		return nil
	end
	if chemicalContainer == nil then
		return nil
	end
	for i = 1, #self.Recipes do 
		if sm.container.canSpend( seedContainer, self.Recipes[i].seed, self.Recipes[i].seedAmount ) then
			if sm.container.canSpend( chemicalContainer, obj_consumable_chemical, self.Recipes[i].chemicalAmount ) then
				return self.Recipes[i]
			end
		end
	end
end

function Fant_Seedpress.server_onFixedUpdate( self, dt )	
	self.container = self.shape:getInteractable():getContainer(0)
	local ActiveLogic, seedContainer, chemicalContainer, generateOil = self:getInputs()
	local hasRequiements = self:HasRequiements( seedContainer, chemicalContainer )
	local isWorking = false
	if ActiveLogic and seedContainer ~= nil and chemicalContainer ~= nil and self.container and hasRequiements ~= nil then
		isWorking = true
		self.pressValue = self.pressValue + ( dt * self.ProductionSpeed )
		if self.pressValue > 1 then
			self.pressValue = 0
			local ProductionlReward = self.ProductionlRewardWood
			local rewardUUID = blk_scrapwood
			if generateOil then
				rewardUUID = obj_resource_crudeoil
				ProductionlReward = self.ProductionlRewardOil
			end
			if sm.container.canCollect( self.container, rewardUUID, ProductionlReward ) then
				sm.container.beginTransaction()
				sm.container.collect( self.container, rewardUUID, ProductionlReward, true )				
				if sm.container.endTransaction() then										
					sm.container.beginTransaction()
					sm.container.spend( seedContainer, hasRequiements.seed, hasRequiements.seedAmount, true )
					if sm.container.endTransaction() then
						sm.container.beginTransaction()
						sm.container.spend( chemicalContainer, obj_consumable_chemical, hasRequiements.chemicalAmount, true )
						if sm.container.endTransaction() then
							self.network:sendToClients( "cl_finish" )
						end					
					end	
				end		
			end
		end
	else
		if self.pressValue ~= 0 then
			self.pressValue = 0
		end
	end
	if isWorking ~= self.state then
		self.state = isWorking
		self.network:sendToClients( "cl_SetActive", self.state )
	end
end

function Fant_Seedpress.cl_SetActive( self, state )
	self.state = state
end

function Fant_Seedpress.cl_finish( self )

end

function Fant_Seedpress.client_onUpdate( self, dt )
	if self.state then
		self.poseValue = self.poseValue + ( dt * self.ProductionSpeed * self.poseDirection )
		if self.poseValue > 1 then
			self.poseValue = 1
			self.poseDirection = -1
		end
		if self.poseValue < 0 then
			self.poseValue = 0
			self.poseDirection = 1
		end
	else
		if self.poseValue ~= 0 then
			self.poseValue = 0
		end
	end
	if self.lastPoseValue ~= self.poseValue then
		self.lastPoseValue = self.poseValue
		self.shape:getInteractable():setPoseWeight( 0, self.poseValue )
	end
end






