dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

Craft_speed = 2

Fant_Autocrafter = class()
Fant_Autocrafter.poseWeightCount = 2
Fant_Autocrafter.DisplayIndexes = {}
Fant_Autocrafter.DisplayIndexes[ "off" ] = 0
Fant_Autocrafter.DisplayIndexes[ "no_blueprint" ] = 1
Fant_Autocrafter.DisplayIndexes[ "no_materials" ] = 2
Fant_Autocrafter.DisplayIndexes[ "no_inventory_space" ] = 3
Fant_Autocrafter.DisplayIndexes[ "ready" ] = 4
Fant_Autocrafter.DisplayIndexes[ "0" ] = 5
Fant_Autocrafter.DisplayIndexes[ "0.1" ] = 6
Fant_Autocrafter.DisplayIndexes[ "0.2" ] = 7
Fant_Autocrafter.DisplayIndexes[ "0.3" ] = 8
Fant_Autocrafter.DisplayIndexes[ "0.4" ] = 9
Fant_Autocrafter.DisplayIndexes[ "0.5" ] = 10
Fant_Autocrafter.DisplayIndexes[ "0.6" ] = 11
Fant_Autocrafter.DisplayIndexes[ "0.7" ] = 12
Fant_Autocrafter.DisplayIndexes[ "0.8" ] = 13
Fant_Autocrafter.DisplayIndexes[ "0.9" ] = 14
Fant_Autocrafter.DisplayIndexes[ "1" ] = 15
Fant_Autocrafter.sleep = 0
Fant_Autocrafter.maxParentCount = 1
Fant_Autocrafter.connectionInput = sm.interactable.connectionType.logic
Fant_Autocrafter.maxChildCount = 255
Fant_Autocrafter.connectionOutput = sm.interactable.connectionType.logic

CL_AUTOCRAFTER_BLUEPRINTS = CL_AUTOCRAFTER_BLUEPRINTS or {}

function Fant_Autocrafter.server_onCreate( self )
	self.connectedContainers = {}
	self:loadCraftingRecipes()
	self.ActiveRecipe = nil
	self.CraftTimer = 0
	self.lastRecycle = nil
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { BluePrintRecipeIndex = 0, mode = "Crafter" } 
		self.storage:save( self.sv.storage )
	end
	self.BluePrintRecipeIndex = self.sv.storage.BluePrintRecipeIndex
	self.mode = self.sv.storage.mode 
	if self.mode == nil then
		self.mode = "Crafter"
	end
	self.foundMaterialsToActive = false
	--self.network:sendToClients( "cl_setMode", self.mode )	
	self:sv_buildPipeNetwork()
	self.storage:save( self.sv.storage )
	--print( self.shape, self.mode )
end

function Fant_Autocrafter.client_onCreate( self )
	self.poseframe = 0
	self.poseframeDir = 1
	self.ActiveRecipe = nil
	self.BluePrintRecipe = nil
	CL_AUTOCRAFTER_BLUEPRINTS[ self.shape:getId() ] = self.BluePrintRecipe
	self.BluePrintRecipeIndex = self.BluePrintRecipeIndex or 0
	self.recipeSets = {
		{ name = "craftbot", locked = false },
		{ name = "cookbot", locked = false },
		{ name = "autocrafter", locked = false },
		{ name = "dispenser", locked = false },
		{ name = "workbench", locked = false }
	}
	self.cl = {}
	self.cl.craftArray = {}
	self:loadCraftingRecipes()
	self:cl_setupUI()
	self.network:sendToServer( "GetBlueprintItem" )	
	self.cl.crafttime = 0
	self.cl_mode = "Crafter"
	self.interactable:setAnimEnabled( "0_idle", true )	
	self.interactable:setAnimProgress( "0_idle", 1 )
	self.network:sendToServer( "GetMode" )	
end

function Fant_Autocrafter.GetMode( self )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_Autocrafter.sv_setMode( self, mode )
	self.mode = mode
	self.sv.storage.mode = self.mode
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_Autocrafter.cl_setMode( self, mode )
	self.cl_mode = mode
end

function Fant_Autocrafter.GetBlueprintItem( self )
	if self.BluePrintRecipeIndex > 0 then
		self.network:sendToClients( "SetBlueprintOnClients", { index = self.BluePrintRecipeIndex } )
	end
end

function Fant_Autocrafter.SetBlueprintOnClients( self, params )
	self:SetBlueprintItem( { index = params.index } )
end

function Fant_Autocrafter.server_onRefresh( self )
	self:loadCraftingRecipes()
	self:sv_buildPipeNetwork()
end

function Fant_Autocrafter.server_onDestroy( self )
	self.sv.storage.mode = self.mode
	self.storage:save( self.sv.storage )
end

function Fant_Autocrafter.client_onDestroy( self )
	CL_AUTOCRAFTER_BLUEPRINTS[ self.shape:getId() ] = nil
end

function Fant_Autocrafter.GetRecipe( self )
	if self.connectedContainers == nil then
		return
	end
	if #self.connectedContainers == 0 then
		return
	end
	if self.connectedContainers == {} then
		return
	end
	if self.BluePrintRecipe == nil then
		return nil
	end
	local BlueprintUUID = self.BluePrintRecipe["itemId"] 
	if BlueprintUUID == nil or not BlueprintUUID then
		return nil
	end
	local BlueprintUUIDString = tostring( BlueprintUUID )
	if BlueprintUUIDString == tostring( obj_consumable_water ) then
		--print("obj_consumable_water autocrafter restriction!")
		return nil
	end
	if BlueprintUUIDString == tostring( obj_tool_bucket_water ) then
		--print("obj_tool_bucket_water autocrafter restriction!")
		return nil
	end
	if BlueprintUUIDString == tostring( obj_tool_bucket_chemical ) then
		--print("obj_tool_bucket_chemical autocrafter restriction!")
		return nil
	end
	
	if BlueprintUUIDString == tostring( obj_consumable_chemical ) then
		--print("obj_consumable_chemical autocrafter restriction!")
		return nil
	end
	if BlueprintUUIDString == tostring( obj_interactive_robotbliphead01 ) and self.recycle then
		--print("obj_interactive_robotbliphead01 autocrafter restriction!")
		return nil
	end
	if BlueprintUUIDString == tostring( obj_consumable_fertilizer ) and self.recycle then
		--print("obj_consumable_fertilizer autocrafter restriction!")
		return nil
	end
	if BlueprintUUIDString == tostring( obj_survivalobject_keycard ) and not self.recycle then
		--print("obj_survivalobject_keycard autocrafter restriction!")
		return nil
	end
	

	if BlueprintUUIDString == tostring( obj_fant_upgradeModule_1 ) and not self.recycle then
		--print("obj_fant_upgradeModule_1 autocrafter restriction!")
		return nil
	end
	if BlueprintUUIDString == tostring( obj_fant_upgradeModule_2 ) and not self.recycle then
		--print("obj_fant_upgradeModule_2 autocrafter restriction!")
		return nil
	end
	if BlueprintUUIDString == tostring( obj_fant_upgradeModule_3 ) and not self.recycle then
		--print("obj_fant_upgradeModule_3 autocrafter restriction!")
		return nil
	end
	
	--print( BlueprintUUIDString )
	for x, craftingRecipesLists in pairs( self.craftingRecipes ) do		
		for y, g_recipe in pairs( craftingRecipesLists.recipes ) do    
			if tostring( g_recipe["itemId"]) == BlueprintUUIDString and g_recipe ~= nil and g_recipe then			
				local recipe = g_recipe
				local hasIngredients = true
				local recipeIngredients = {}

				local FoundRecycleContainer = nil
				if self.recycle then
					local tempFoundRecycleContainer = FindContainerToSpendFrom( self.connectedContainers, sm.uuid.new( recipe["itemId"] ), recipe["quantity"] )
					if tempFoundRecycleContainer then
						if tempFoundRecycleContainer.shape then
							FoundRecycleContainer = tempFoundRecycleContainer.shape
						end
					end
				end
				
				for a, ingredients in pairs( recipe.ingredientList ) do	
					local quantity = 0
					local uuid = sm.uuid.getNil()
					for b,ingredient in pairs( ingredients ) do			
						if b == "quantity" then
							quantity = ingredient
						end
						if b == "itemId" then
							uuid = ingredient
						end
					end
					if not self.recycle then
						if self.connectedContainers then
							local FoundIngredientContainer = FindContainerToSpendFrom( self.connectedContainers, uuid, quantity ) 
							if FoundIngredientContainer ~= nil then
								table.insert( recipeIngredients, { uuid = uuid, quantity = quantity, foundContainer = FoundIngredientContainer.shape } )
							else
								hasIngredients = false
								recipeIngredients = {}
								break
							end
						end
					else
						if FoundRecycleContainer ~= nil then
							table.insert( recipeIngredients, { uuid = uuid, quantity = quantity, foundContainer = FoundRecycleContainer } )
							hasIngredients = true
						end
					end
				end
				if hasIngredients == true then
					--print( "Found Item With Ingredients: " .. y )
					return { recipe = recipe["itemId"], quantity = recipe["quantity"], crafttime = recipe["craftTime"], ingredients = recipeIngredients, recycleContainer = FoundRecycleContainer }
				else
					--print( "No Item Found With Ingredients!" .. y )
					--return nil
				end 
			end
		end
	end
	return nil
end

function Fant_Autocrafter.printOnShape( self, text )
	if text and text ~= "" then
		if self.guiInfo == nil then
			self.guiInfo = sm.gui.createNameTagGui()
		end
		self.guiInfotimer = 3
		self.guiInfo:setRequireLineOfSight( false )
		self.guiInfo:open()
		self.guiInfo:setMaxRenderDistance( 50 )
		self.guiInfo:setWorldPosition( self.shape.worldPosition + sm.vec3.new( 0, 0, 0 ) )
		self.guiInfo:setText( "Text", "#ff0000".. text )
	else
		if self.guiInfo then
			self.guiInfo:close()
			self.guiInfo = nil
		end
	end
end

function Fant_Autocrafter.server_onFixedUpdate( self, dt )	

	local Active = true
	local parent = self.shape:getInteractable():getSingleParent()
	if parent then
		Active = parent.active
		if self.active ~= Active then
			self.active = Active
			if Active then
				self:sv_buildPipeNetwork()
			end
		end
	end
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) and Active then
		self:sv_buildPipeNetwork()	
		--return
	end
	

	if self.mode == "Recycler" then
		self.recycle = true
	else
		self.recycle = false
	end		
	if self.lastRecycle ~= self.recycle then
		self.lastRecycle = self.recycle
		self.ActiveRecipe = nil
		self.CraftTimer = 0
	end
	
	if self.sleep == nil then
		self.sleep = 0
	end
	if self.sleep > 0 then
		self.sleep = self.sleep - dt
		return
	end
	
	if self.BluePrintRecipe ~= nil and Active then
		if self.ActiveRecipe == nil then
			local ActiveRecipe = self:GetRecipe()
			if self.ActiveRecipe ~= ActiveRecipe then
				if ActiveRecipe then
					self:sv_buildPipeNetwork()
					self.ActiveRecipe = ActiveRecipe
					self.CraftTimer = ActiveRecipe.crafttime			
					self.network:sendToClients( "set_cl_crafttimer", self.CraftTimer )
				else
					self.ActiveRecipe = nil
					self.CraftTimer = 0
				end
			end
		end
		if self.ActiveRecipe then
			if self.ActiveRecipe.recipe ~= tostring( self.BluePrintRecipe["itemId"] ) then
				self.ActiveRecipe = nil
				self.CraftTimer = 0		
			end
		end
		if self.ActiveRecipe then
			if self.CraftTimer > 0 then
				self.CraftTimer = self.CraftTimer - ( dt * Craft_speed * 40 ) 
				self:SetDisplay( ( math.floor( ( self.CraftTimer / 1 ) * 10 ) / 10 ) )
			end
			if self.CraftTimer <= 0 then
				if not self.recycle then
					local CollectContainer =  nil
					if self.connectedContainers ~= {} then
						CollectContainer = FindContainerToCollectTo( self.connectedContainers, sm.uuid.new( self.ActiveRecipe.recipe ), self.ActiveRecipe.quantity )
					end
					if CollectContainer and CollectContainer.shape then
						local hasMaterial = true
						for a, ingredient in pairs( self.ActiveRecipe.ingredients ) do	
							if ingredient then
								if ingredient.foundContainer ~= nil and type( ingredient.foundContainer ) == "Shape" then
									if sm.exists( ingredient.foundContainer ) then
										if ingredient.foundContainer:getInteractable() then
											local SpendContainer = ingredient.foundContainer:getInteractable():getContainer()
											if SpendContainer then
												if not sm.container.canSpend( SpendContainer, ingredient.uuid, ingredient.quantity ) then
													hasMaterial = false
													break
												end
												ingredient.foundContainer = SpendContainer
											else
												hasMaterial = false
											end
										else
											hasMaterial = false
										end
									else
										hasMaterial = false
									end
								else
									hasMaterial = false
								end
							else
								hasMaterial = false
							end
						end									
						if hasMaterial then
							for a, ingredient in pairs( self.ActiveRecipe.ingredients ) do	
								sm.container.beginTransaction()
								sm.container.spend( ingredient.foundContainer, ingredient.uuid, ingredient.quantity, true )
								if sm.container.endTransaction() then				
									
								end	
							end		
							sm.container.beginTransaction()
							sm.container.collect( CollectContainer.shape:getInteractable():getContainer(), sm.uuid.new( self.ActiveRecipe.recipe ), self.ActiveRecipe.quantity, true )
							if sm.container.endTransaction() then
								
							end
							self.foundMaterialsToActive = true
						else
							self:SetDisplay( "no_materials" )
							self.foundMaterialsToActive = false
						end
						self.ActiveRecipe = nil
						self.CraftTimer = 0
					else
						self.ActiveRecipe = nil
						self.CraftTimer = 0
						self:SetDisplay( "no_inventory_space" )
						self.foundMaterialsToActive = false
					end
				else
					if self.ActiveRecipe ~= nil then
						local SpendContainer = nil
						if self.connectedContainers ~= {} then
							SpendContainer = FindContainerToSpendFrom( self.connectedContainers, sm.uuid.new(self.ActiveRecipe.recipe), self.ActiveRecipe.quantity )
						end
						--print( SpendContainer )
						if SpendContainer ~= nil then
							if sm.container.canSpend( SpendContainer.shape:getInteractable():getContainer(), sm.uuid.new(self.ActiveRecipe.recipe), self.ActiveRecipe.quantity ) then
								local CollectContainers = {}
								for a, ingredient in pairs( self.ActiveRecipe.ingredients ) do	
									local FoundFreeSpaceContainer = FindContainerToCollectTo( self.connectedContainers, ingredient.uuid, ingredient.quantity )
									if FoundFreeSpaceContainer ~= nil then
										table.insert( CollectContainers, FoundFreeSpaceContainer )
									end
								end
								if #CollectContainers == #self.ActiveRecipe.ingredients then
									for a, ingredient in pairs( self.ActiveRecipe.ingredients ) do	
										local FoundFreeSpaceContainer = FindContainerToCollectTo( self.connectedContainers, ingredient.uuid, ingredient.quantity )
										if FoundFreeSpaceContainer ~= nil then
											if FoundFreeSpaceContainer.shape ~= nil then
												sm.container.beginTransaction()
												sm.container.collect( FoundFreeSpaceContainer.shape:getInteractable():getContainer(), ingredient.uuid, ingredient.quantity, true )
												if sm.container.endTransaction() then
													
												end
											end
										end
									end
									sm.container.beginTransaction()
									sm.container.spend( SpendContainer.shape:getInteractable():getContainer(), sm.uuid.new(self.ActiveRecipe.recipe), self.ActiveRecipe.quantity, true )
									if sm.container.endTransaction() then			
									end
									self.foundMaterialsToActive = true
								else
									self.ActiveRecipe = nil
									self.CraftTimer = 0
									self:SetDisplay( "no_inventory_space" )
									self.foundMaterialsToActive = false
								end
							end
						else
							if self.BluePrintRecipe == nil then
								self:SetDisplay( "no_blueprint" )
							else
								self:SetDisplay( "no_materials" )
							end
							self.foundMaterialsToActive = false
						end
						self.ActiveRecipe = nil
						self.CraftTimer = 0 
					end
				end
			end	
		else
			if self.BluePrintRecipe == nil then
				self:SetDisplay( "no_blueprint" )
			else
				self:SetDisplay( "no_materials" )
			end
			self.foundMaterialsToActive = false
		end
	else
		self.ActiveRecipe = nil
		self:SetDisplay( "off" )
		self.foundMaterialsToActive = false
	end
	sm.interactable.setActive( self.interactable, self.foundMaterialsToActive )
end

function Fant_Autocrafter.set_cl_crafttimer( self, crafttime ) 
	self.cl.crafttime = crafttime
end

function Fant_Autocrafter.SetDisplay( self, displayValue )
	local DisplayIndex = 1
	if type(displayValue) == "string" then
		DisplayIndex = self.DisplayIndexes[displayValue]
		self.sleep = 1
	else
		DisplayIndex =  math.floor( ( ( displayValue ) * 10 ) / self.ActiveRecipe.crafttime ) / 10
		DisplayIndex = self.DisplayIndexes[ tostring( DisplayIndex + 0.1 )]
	end
	if self.displayIndex ~= DisplayIndex then
		self.displayIndex = DisplayIndex
		self.network:sendToClients( "cl_setUvFrameIndex", DisplayIndex )
	end
end

function Fant_Autocrafter.cl_setUvFrameIndex( self, frameIndex )
	if frameIndex ~= nil then
		self.shape:getInteractable():setUvFrameIndex( frameIndex )
	end
end

function Fant_Autocrafter.client_onUpdate( self, dt )

	if self.BluePrintRecipe then
		self.poseframe = self.poseframe + ( dt * self.poseframeDir * 2 )
		if self.poseframe > 1 then
			self.poseframe = 1
			self.poseframeDir = -1
		end
		if self.poseframe < 0 then
			self.poseframe = 0
			self.poseframeDir = 1
		end
	else
		self.poseframe = 0
		self.poseframeDir = 1
	end
	self.interactable:setAnimProgress( "0_idle", self.poseframe )
	-- self.shape:getInteractable():setPoseWeight( 0, self.poseframe )
	
	if self.cl.crafttime > 0 then
		self.cl.crafttime = self.cl.crafttime - ( dt * Craft_speed * 40 ) 
		if self.cl.crafttime < 0 then
			self.cl.crafttime = 0
		end
	end
	self:UpdateGUI( dt )
	
	if self.guiInfo then
		self.guiInfotimer = self.guiInfotimer  - dt
		if self.guiInfotimer < 0 then
			self.guiInfotimer = 0
			self.guiInfo:close()
			self.guiInfo = nil
		end
	end
end

function Fant_Autocrafter.loadCraftingRecipes( self )
	self.craftingRecipes = {}
	local recipePaths = {
		workbench = "$SURVIVAL_DATA/CraftingRecipes/workbench.json",
		dispenser = "$SURVIVAL_DATA/CraftingRecipes/dispenser.json",
		cookbot = "$SURVIVAL_DATA/CraftingRecipes/cookbot.json",
		craftbot = "$SURVIVAL_DATA/CraftingRecipes/craftbot.json",
		autocrafter = "$SURVIVAL_DATA/Objects/00fant/autocrafterrecycler/autocrafterrecycler.json"
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

function Fant_Autocrafter.sv_buildPipeNetwork( self )
	--self.pipeNetwork = {}
	self.connectedContainers = {}

	local function fnOnVertex( vertex )
		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			local container = {
				shape = vertex.shape,
				distance = vertex.distance,
				shapesOnContainerPath = vertex.shapesOnPath
			}

			table.insert( self.connectedContainers, container )			
		-- elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			-- assert( vertex.shape:getInteractable() )
			-- local pipe = {
				-- shape = vertex.shape,
				-- state = PipeState.off
			-- }
			-- table.insert( self.pipeNetwork, pipe )
		end
		return true
	end
	ConstructPipedShapeGraph( self.shape, fnOnVertex )
	-- Sort container by closests
	table.sort( self.connectedContainers, function(a, b) return a.distance < b.distance end )
	
	--self.network:sendToClients( "printOnShape", "sv_buildPipeNetwork" )
end

function Fant_Autocrafter.cl_setupUI( self )
	self.cl.guiInterface = sm.gui.createCraftBotGui()
	--self.cl.guiInterface = sm.gui.createGuiFromLayout( "$GAME_DATA/Gui/Layouts/Interactable/Interactable_CraftBot.layout" )
	self.cl.guiInterface:setGridButtonCallback( "Craft", "cl_onCraft" )
	self.cl.guiInterface:setGridButtonCallback( "Repeat", "cl_onRepeat" )
	self.cl.guiInterface:clearGrid( "RecipeGrid" )
	for _, recipeSet in ipairs( self.recipeSets ) do
		self.cl.guiInterface:addGridItemsFromFile( "RecipeGrid", self.craftingRecipes[recipeSet.name].path, { locked = recipeSet.locked } )
	end
end


function Fant_Autocrafter.getRecipeByIndex( self, index )
	if index < 0 then
		return nil
	end
	-- Convert one dimensional index to recipeSet and recipeIndex
	local recipeName = 0
	local recipeIndex = 0
	local offset = 0
	for _, recipeSet in ipairs( self.recipeSets ) do
		assert( self.craftingRecipes[recipeSet.name].recipesByIndex )
		local recipeCount = #self.craftingRecipes[recipeSet.name].recipesByIndex

		if index <= offset + recipeCount then
			recipeIndex = index - offset
			recipeName = recipeSet.name
			break
		end
		offset = offset + recipeCount
	end

	local recipe = self.craftingRecipes[recipeName].recipesByIndex[recipeIndex]
	assert(recipe)
	if recipe then
		return recipe
	end

	return nil
end

function Fant_Autocrafter.cl_onCraft( self, buttonName, index, data )
	if self.BluePrintRecipe then
		self.network:sendToServer( "sv_n_repeat" )
		self.cl.craftArray = {}
		self.BluePrintRecipe = nil
		CL_AUTOCRAFTER_BLUEPRINTS[ self.shape:getId() ] = self.BluePrintRecipe
		if self.cl.guiInterface ~= nil then
			if not self.recycle then
				self.cl.guiInterface:setText( "Craft", "Autocraft" )
			else
				self.cl.guiInterface:setText( "Craft", "Recycle" )
			end
		end
	else
		self.network:sendToServer( "sv_n_craft", { index = index + 1 } )
	end
end

function Fant_Autocrafter.sv_n_craft( self, params, player )
	self:sv_buildPipeNetwork()
	local recipe = self:getRecipeByIndex( params.index )
	self.network:sendToClients( "SetBlueprintItem", { index = params.index } )
	self.BluePrintRecipe = recipe
	self.BluePrintRecipeIndex = params.index
	self.sv = {}
	self.sv.storage = { BluePrintRecipeIndex = self.BluePrintRecipeIndex } 
	self.storage:save( self.sv.storage )
end

function Fant_Autocrafter.SetBlueprintItem( self, params )
	local recipe = self:getRecipeByIndex( params.index )
	self.cl.craftArray = {}
	self.BluePrintRecipe = recipe
	--print( "Craft Recipe: " .. tostring(self.BluePrintRecipe) )
	table.insert( self.cl.craftArray, { recipe = recipe, time = -1, loop = true } )
	
	CL_AUTOCRAFTER_BLUEPRINTS[ self.shape:getId() ] = self.BluePrintRecipe
	if self.cl.guiInterface ~= nil then
		self.cl.guiInterface:setText( "Craft", "STOP" )
	end
end

function Fant_Autocrafter.cl_onRepeat( self, buttonName, index, gridItem )
	self.network:sendToServer( "sv_n_repeat" )
	self.cl.craftArray = {}
	self.BluePrintRecipe = nil
	CL_AUTOCRAFTER_BLUEPRINTS[ self.shape:getId() ] = self.BluePrintRecipe
	
	if self.cl.guiInterface ~= nil then
		if not self.recycle then
			self.cl.guiInterface:setText( "Craft", "Autocraft" )
		else
			self.cl.guiInterface:setText( "Craft", "Recycle" )
		end
	end
end

function Fant_Autocrafter.sv_n_repeat( self )
	self.BluePrintRecipe = nil
	self.BluePrintRecipeIndex = 0
	self.sv.storage.BluePrintRecipeIndex = self.BluePrintRecipeIndex
	self.storage:save( self.sv.storage )
	--print( "Remove Recipe: " .. tostring(self.BluePrintRecipe) )
end


function Fant_Autocrafter.client_canInteract( self, character )
	if self.cl_mode == nil then
		self.cl_mode = "Crafter"
		self.network:sendToServer( "GetMode" )	
	end
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Open" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. tostring( self.cl_mode ) )
	return true
end


function Fant_Autocrafter.client_onTinker( self, character, state )
	if state then
		if self.cl_mode == "Crafter" then
			self.cl_mode = "Recycler"
		else
			self.cl_mode = "Crafter"
		end
		self.network:sendToServer( "sv_setMode", self.cl_mode )	
	end
end


function Fant_Autocrafter.client_onInteract( self, character, state )
	if state == true then
		for idx = 1, 8 do
			local val = self.cl.craftArray[idx]
			if val then
				local recipe = val.recipe
				local recipeCraftTime = math.ceil( recipe.craftTime / Craft_speed ) + 120
				local gridItem = {}
				gridItem.itemId = recipe.itemId
				gridItem.craftTime = recipeCraftTime
				gridItem.remainingTicks = recipeCraftTime - clamp( val.time, 0, recipeCraftTime )
				gridItem.locked = false
				gridItem.repeating = val.loop
				self.cl.guiInterface:setGridItem( "ProcessGrid", idx - 1, gridItem )

			else
				local gridItem = {}
				gridItem.itemId = "00000000-0000-0000-0000-000000000000"
				gridItem.craftTime = 0
				gridItem.remainingTicks = 0
				gridItem.locked = false
				gridItem.repeating = false
				self.cl.guiInterface:setGridItem( "ProcessGrid", idx - 1, gridItem )
			end
		end		
		
		
		self.cl.guiInterface:setVisible( "PipeConnection", 1 )
		self.cl.guiInterface:setVisible( "Upgrade", false )
		
		--self.cl.guiInterface:setVisible( "MaterialGrid", false )
		--self.cl.guiInterface:setText( "Quantity", "" )
		self.cl.guiInterface:setVisible( "Time", false )
		--self.cl.guiInterface:setVisible( "MaterialTitle", false )
		
		self.cl.guiInterface:setText( "CRAFTBOT_TITLE", " Autocrafter" )
		self.cl.guiInterface:setText( "SubTitle", "its Not a Craftbot!" )
		
		self.cl.guiInterface:setImage( "BackgroundCraftbotImage", "Autocrafter.png" )
		
		if self.BluePrintRecipe == nil then
			if not self.recycle then
				self.cl.guiInterface:setText( "Craft", "Autocraft" )
			else
				self.cl.guiInterface:setText( "Craft", "Recycle" )
			end
		else
			self.cl.guiInterface:setText( "Craft", "STOP" )
		end
		
		self.cl.guiInterface:open()
	end
end

function Fant_Autocrafter.UpdateGUI( self, dt )
	if not self.cl.guiInterface:isActive() then
		return
	end
	
	local gridItem = {}
	gridItem.locked = false
	if self.cl.craftArray[1] then
		local recipe = self.cl.craftArray[1].recipe
		local recipeCraftTime = math.ceil( recipe.craftTime / Craft_speed ) + 120
		gridItem.itemId = recipe.itemId
		gridItem.craftTime = recipeCraftTime
		gridItem.remainingTicks = self.cl.crafttime + 1
		gridItem.repeating = true
	else
		gridItem.itemId = "00000000-0000-0000-0000-000000000000"
		gridItem.craftTime = 0
		gridItem.remainingTicks = 0
		gridItem.repeating = false
	end
	self.cl.guiInterface:setGridItem( "ProcessGrid", 0, gridItem )
	
	--self.cl.guiInterface:setText( "Quantity", "" )
end

