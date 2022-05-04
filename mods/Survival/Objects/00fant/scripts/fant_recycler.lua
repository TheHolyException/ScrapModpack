Fant_Recycler = class()
Fant_Recycler.DisplayIndexes = {}
Fant_Recycler.DisplayIndexes[ "off" ] = 0
Fant_Recycler.DisplayIndexes[ "no_blueprint" ] = 1
Fant_Recycler.DisplayIndexes[ "no_materials" ] = 2
Fant_Recycler.DisplayIndexes[ "no_inventory_space" ] = 3
Fant_Recycler.DisplayIndexes[ "ready" ] = 4
Fant_Recycler.DisplayIndexes[ "0" ] = 5
Fant_Recycler.DisplayIndexes[ "0.1" ] = 6
Fant_Recycler.DisplayIndexes[ "0.2" ] = 7
Fant_Recycler.DisplayIndexes[ "0.3" ] = 8
Fant_Recycler.DisplayIndexes[ "0.4" ] = 9
Fant_Recycler.DisplayIndexes[ "0.5" ] = 10
Fant_Recycler.DisplayIndexes[ "0.6" ] = 11
Fant_Recycler.DisplayIndexes[ "0.7" ] = 12
Fant_Recycler.DisplayIndexes[ "0.8" ] = 13
Fant_Recycler.DisplayIndexes[ "0.9" ] = 14
Fant_Recycler.DisplayIndexes[ "1" ] = 15

Fant_Recycler.maxParentCount = 1
Fant_Recycler.connectionInput = sm.interactable.connectionType.logic
Fant_Recycler.maxChildCount = 255
Fant_Recycler.connectionOutput = sm.interactable.connectionType.logic
Fant_Recycler.containerSlots = 30
Fant_Recycler.recyclerDelay = 0.1

function Fant_Recycler.server_onCreate( self )
	self:loadCraftingRecipes()
	self.container = self.shape.interactable:getContainer( 0 )
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, self.containerSlots, 256 )
	end
	self.displayIndex = -1
	self.recycleTimer = 0
end

function Fant_Recycler.server_onRefresh( self )
	self:loadCraftingRecipes()
end

function Fant_Recycler.loadCraftingRecipes( self )
	self.craftingRecipes = {}
	local recipePaths = {
		autocrafter = "$SURVIVAL_DATA/Objects/00fant/autocrafterrecycler/autocrafterrecycler.json",
		craftbot = "$SURVIVAL_DATA/CraftingRecipes/craftbot.json",
		workbench = "$SURVIVAL_DATA/CraftingRecipes/workbench.json",
		dispenser = "$SURVIVAL_DATA/CraftingRecipes/dispenser.json",
		cookbot = "$SURVIVAL_DATA/CraftingRecipes/cookbot.json"
	}
	self.craftingRecipes = {}
	for name, path in pairs( recipePaths ) do
		local json = sm.json.open( path )
		local recipes = {}
		local recipesByIndex = {}
		for idx, recipe in ipairs( json ) do			
			recipe.craftTime = math.ceil( recipe.craftTime * 40 ) 
			for _,ingredient in ipairs( recipe.ingredientList ) do
				ingredient.itemId = sm.uuid.new( ingredient.itemId )
			end
			recipes[idx] = recipe
			recipesByIndex[idx] = recipe
		end
		self.craftingRecipes[name] = { path = path, recipes = recipes, recipesByIndex = recipesByIndex }
	end
end

function Fant_Recycler.isNotRestrictedUUID( self, uuid )
	if uuid == obj_consumable_water then
		return false
	end
	if uuid == obj_tool_bucket_water then
		return false
	end
	if uuid == obj_tool_bucket_chemical then
		return false
	end
	if uuid == obj_consumable_chemical then
		return false
	end
	if uuid == obj_interactive_robotbliphead01 then
		return false
	end
	if uuid == obj_consumable_fertilizer then
		return false
	end
	if uuid == obj_survivalobject_keycard then
		return false
	end
	return true
end

function Fant_Recycler.server_onFixedUpdate( self, dt )	
	if self.recycleTimer > 0 then
		self.recycleTimer = self.recycleTimer - dt
		return
	end
	self.recycleTimer = self.recyclerDelay
	
	if self.craftingRecipes == nil then
		return
	end
	local displayOutput = "ready"
	local Active = true
	local parent = self.shape:getInteractable():getSingleParent()
	if parent then
		if parent.active == false then
			Active = false
			displayOutput = "off"
		end
	end
	if Active then
		if self.container == nil then
			self.container = self.shape.interactable:getContainer( 0 )
		end
		if self.container ~= nil then
			displayOutput = "no_materials"
			for slot = 0, self.containerSlots - 1 do
				if self.container:getItem( slot ).uuid ~= sm.uuid.getNil() then
					if self:isNotRestrictedUUID( self.container:getItem( slot ).uuid ) then
						displayOutput = "ready"
						local recycleFounds = {}
						for x, craftingRecipesLists in pairs( self.craftingRecipes ) do	
							local hasAllready = false
							for uuid, checkrecycleFound in pairs( recycleFounds ) do		
								if uuid ~= sm.uuid.getNil() then
									if uuid == self.container:getItem( slot ).uuid then
										hasAllready = true
									end
								end
							end
							if hasAllready == false then
								for y, g_recipe in pairs( craftingRecipesLists.recipes ) do   
									if g_recipe ~= nil and g_recipe then
										if g_recipe["itemId"] == tostring( self.container:getItem( slot ).uuid ) then								
											local recycleFound = {}
											for a, ingredients in pairs( g_recipe.ingredientList ) do	
												local quantity = 0
												local uuid = sm.uuid.getNil()
												for b, ingredient in pairs( ingredients ) do												
													if b == "quantity" then
														quantity = ingredient
													end
													if b == "itemId" then
														uuid = ingredient
													end
												end		
												if quantity > 0 then
													if uuid ~= sm.uuid.getNil() then
														if uuid ~= self.container:getItem( slot ).uuid then
															table.insert( recycleFound, { uuid = uuid, quantity = quantity } )
														end
													end
												end
											end
											if recycleFound ~= {} then
												recycleFounds[ self.container:getItem( slot ).uuid ] = {
													recycleUUid = self.container:getItem( slot ).uuid,											
													recycleQuantity = g_recipe.quantity,
													ingredients = recycleFound
												}
											end
										end
									end
								end
							end							
						end					
						for x, recycleFound in pairs( recycleFounds ) do		
							if sm.container.canSpend( self.container, recycleFound.recycleUUid, recycleFound.recycleQuantity ) then
								local canCollectAllIngredients = true
								for y, ingredient in pairs( recycleFound.ingredients ) do
									if sm.container.canCollect( self.container, ingredient.uuid, ingredient.quantity ) == false then
										canCollectAllIngredients = false
										break
									end
								end
								if canCollectAllIngredients then
									sm.container.beginTransaction()									
									sm.container.spend( self.container, recycleFound.recycleUUid, recycleFound.recycleQuantity, true )
									if sm.container.endTransaction() then
										sm.container.beginTransaction()
										for y, ingredient in pairs( recycleFound.ingredients ) do
											sm.container.collect( self.container, ingredient.uuid, ingredient.quantity, true )
										end
										sm.container.endTransaction()
									end
								end
							end
							recycleFound = nil
						end						
					else
						displayOutput = "no_blueprint"
					end
				end
			end
		end
	else
		displayOutput = "off"
	end
	self:SetDisplay( displayOutput )
end

function Fant_Recycler.SetDisplay( self, displayValue )
	local DisplayIndex = 1
	if type(displayValue) == "string" then
		DisplayIndex = self.DisplayIndexes[displayValue]
	else
		DisplayIndex =  math.floor( displayValue * 10 ) / 10

		DisplayIndex = self.DisplayIndexes[ tostring( DisplayIndex )]
	end
	if self.displayIndex ~= DisplayIndex then
		self.displayIndex = DisplayIndex
		self.network:sendToClients( "cl_setUvFrameIndex", DisplayIndex )
	end
end

function Fant_Recycler.cl_setUvFrameIndex( self, frameIndex )
	if frameIndex ~= nil then
		self.shape:getInteractable():setUvFrameIndex( frameIndex )
	end
end

function Fant_Recycler.client_onInteract(self, character, state)
	if state == true then
		self.cl_container = self.shape:getInteractable():getContainer()
		self.gui = sm.gui.createContainerGui( true )	
		self.gui:setText( "UpperName", "Recycler" )
		self.gui:setContainer( "UpperGrid", self.cl_container )			
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end
