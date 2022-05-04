	
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/util/pipes.lua"

Fanr_Inline_Refinery = class( nil )
local StackSize = 256
local AnimUnpackTime = 1
local AnimStartTime = 0.8667
local AnimUseTime = 4
local AnimFinishTime = 2

local ModulesItems = {
	{ Uuid = obj_fant_upgradeModule_1, Productivity = 1.5, Speed = 1 },
	{ Uuid = obj_fant_upgradeModule_2, Productivity = 1, Speed = 2 }
}

function Fanr_Inline_Refinery.server_onCreate(self)
	self.sv = {}
	if not self.shape:getInteractable():getContainer(1) then
		self.shape:getInteractable():addContainer( 1, 1, 1 )
	end
	local container = self.shape:getInteractable():getContainer(0)
	if not container then
		container = self.shape:getInteractable():addContainer( 0, 30, StackSize )
	end
	--container.allowCollect = false
	
	
	local containerModule = self.shape:getInteractable():getContainer(2)
	if not containerModule then
		containerModule = self.shape:getInteractable():addContainer( 2, 1, 1 )
	end
	
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { Module = nil } 
		self.storage:save( self.sv.storage )
	end
	self.Module = self.sv.storage.Module
	
	if self.Module ~= nil and containerModule then
		sm.container.beginTransaction()
		sm.container.setItem( containerModule, 0, self.Module, 1 )
		if sm.container.endTransaction() then

		end
	end	
	self:sv_init()	
end

function Fanr_Inline_Refinery.getInputContainer( self )
	return self.shape:getInteractable():getContainer(1)
end

function Fanr_Inline_Refinery.getOutputContainer( self )
	return self.shape:getInteractable():getContainer(0)
end

function Fanr_Inline_Refinery.server_canErase( self )
	local containerIn = self.shape:getInteractable():getContainer(0)
	local containerOut = self.shape:getInteractable():getContainer(1)
	local containerModule = self.shape:getInteractable():getContainer(2)

	if not containerIn:isEmpty() or not containerOut:isEmpty() or not containerModule:isEmpty() then
		return false
	end
	return true
end

function Fanr_Inline_Refinery.client_canErase( self )
	local containerIn = self.shape:getInteractable():getContainer(0)
	local containerOut = self.shape:getInteractable():getContainer(1)
	local containerModule = self.shape:getInteractable():getContainer(2)

	if not containerIn:isEmpty() or not containerOut:isEmpty() or not containerModule:isEmpty() then
		sm.gui.displayAlertText( "#{INFO_BUSY}", 1.5 )
		return false
	end
	return true
end

function Fanr_Inline_Refinery.client_onCreate(self)
	self.cl = {}
	self:cl_init()
	
	
	local Pos = sm.vec3.new( -0.725, 0, 0 )
	local angle = sm.quat.identity() * sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 0, 0, 1 ) )

	self.cl.suckStartEffect = sm.effect.createEffect( "Refinery - SuckStart", self.interactable )
	self.cl.suckStartEffect:setOffsetRotation( angle )
	self.cl.suckStartEffect:setOffsetPosition( Pos )

	angle = sm.quat.identity() * sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 1, 0, 0 ) )
	self.cl.workStoneEffect = sm.effect.createEffect( "Refinery - WorkStone", self.interactable )
	self.cl.workStoneEffect:setOffsetRotation( angle )
	self.cl.workStoneEffect:setOffsetPosition( Pos )
	
	angle = sm.quat.identity() * sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( -1, 0, 0 ) )
	self.cl.workStoneEffect2 = sm.effect.createEffect( "Refinery - WorkStone", self.interactable )
	self.cl.workStoneEffect2:setOffsetRotation( angle )
	self.cl.workStoneEffect2:setOffsetPosition( Pos )

	self.cl.unpackEffect = sm.effect.createEffect( "Refinery - Unpack", self.interactable )
	self.cl.unpackEffect:start()

end

function Fanr_Inline_Refinery.client_onClientDataUpdate( self, clientData )
	self.cl.pipes = clientData.pipes
end

function Fanr_Inline_Refinery.client_onDestroy(self)
	if self.cl.suckStartEffect then
		self.cl.suckStartEffect:stop()
		self.cl.suckStartEffect:destroy()
	end
	if self.cl.workStoneEffect then
		self.cl.workStoneEffect:stop()
		self.cl.workStoneEffect:destroy()
	end
	if self.cl.workStoneEffect2 then
		self.cl.workStoneEffect2:stop()
		self.cl.workStoneEffect2:destroy()
	end
	if self.cl.unpackEffect then
		self.cl.unpackEffect:stop()
		self.cl.unpackEffect:destroy()
	end
end

function Fanr_Inline_Refinery.sv_init(self)

	self.sv.updateProgress = 0.0
	self.sv.updateTime = 1.0 		--seconds

	self.sv.hasInputItem = false
	self.sv.outputFull = false

	self.sv.isProducing = false
	self.sv.productionProgress = 0.0
	self.sv.productionTime = AnimStartTime + AnimUseTime + AnimFinishTime

	if self.sv.areaTrigger then
		sm.areaTrigger.destroy( self.sv.areaTrigger )
		self.sv.areaTrigger = nil
	end

	local size = sm.vec3.new( 3, 3, 3 )
	local position = sm.vec3.new( 0, 0, 0.0 )
	local filter = sm.areaTrigger.filter.areaTrigger
	self.sv.areaTrigger = sm.areaTrigger.createAttachedBox( self.interactable, size, position, sm.quat.identity(), filter )

	self.sv.pipes = {}
	self.sv.containers = {}
	self.sv.clientDataDirty = false

	self:server_getConnectedPipesAndChests()

end

function Fanr_Inline_Refinery.cl_init(self)
	self.cl.isProducing = false
	self.cl.productionProgress = 0.0
	self.cl.productionTime = AnimStartTime + AnimUseTime + AnimFinishTime

	self.cl.pipes = {}
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
	

	self.interactable:setAnimEnabled( "idle", true )	
	self.interactable:setAnimProgress( "idle", 0.01 )
	self.interactable:setAnimEnabled( "process", true )	
	self.interactable:setAnimProgress( "process", 0.01 )
	self.lastanimation = ""
end

function Fanr_Inline_Refinery.server_onRefresh(self)
	self:sv_init()
end

function Fanr_Inline_Refinery.client_onRefresh(self)
end

function Fanr_Inline_Refinery.client_onUpdate(self, dt)
	local speed, productivity =  self:ModuleManager()
	dt = dt * speed
	
	self.cl.pipeEffectPlayer:update( dt )

	local container0 = self.shape:getInteractable():getContainer(1)
	local container1 = self.shape:getInteractable():getContainer(0)
	if not container0 or not container1 then
		return
	end

	if self.cl.isProducing then
		self.cl.productionProgress = self.cl.productionProgress + dt/self.cl.productionTime
		if self.cl.productionProgress >= 1.0 then
			self.cl.productionProgress = 1.0
		end
		if self.lastanimation ~= "process" then
			self.lastanimation = "process"		
			self.interactable:setAnimEnabled( "idle", false )	
			self.interactable:setAnimEnabled( "process", true )	
			self.cl.suckStartEffect:start()		
		end	
		if self.cl.productionProgress < 0.8 then
			if not self.cl.workStoneEffect:isPlaying() then
				self.cl.workStoneEffect:start()
			end
			if not self.cl.workStoneEffect2:isPlaying() then
				self.cl.workStoneEffect2:start()
			end
		end
		self.interactable:setAnimProgress( "process", self.cl.productionProgress )
	else
		self.cl.productionProgress = 0.0
		if self.lastanimation ~= "idle" then
			self.lastanimation = "idle"		
			self.interactable:setAnimEnabled( "idle", false )	
			self.interactable:setAnimEnabled( "process", true )	
			self.cl.workStoneEffect:stop()
			self.cl.workStoneEffect2:stop()
			self.cl.suckStartEffect:stop()		
		end
		self.interactable:setAnimProgress( "idle", 0 )
	end

	LightUpPipes( self.cl.pipes )
end

function Fanr_Inline_Refinery.client_onInteract(self, _, state)
	if state == true then
		local gui = sm.gui.createContainerGui( true )
		gui:setText( "UpperName", "Inline Refinery" )
		gui:setContainer( "UpperGrid", self.shape:getInteractable():getContainer(0) )
		gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		gui:open()
	end
end

function Fanr_Inline_Refinery.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Refinery" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Module" )
	return true
end

function Fanr_Inline_Refinery.client_onTinker( self, character, state )
	if state == true then 
		local gui = sm.gui.createContainerGui( true )
		gui:setText( "UpperName", "Refinery Modules" )
		gui:setContainer( "UpperGrid",self.shape:getInteractable():getContainer(2) )
		gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		gui:open()
	end
end

function Fanr_Inline_Refinery.ModuleManager( self )
	local Module = nil
	for i, m in pairs( ModulesItems ) do
		if self.shape:getInteractable():getContainer(2):getItem( 0 ).uuid == m.Uuid then
			Module = m
			break
		end
	end
	if Module ~= nil then
		--print( Module )
		-- AnimUnpackTime = 1 / Module.Speed
		-- AnimStartTime = 0.8667 / Module.Speed
		-- AnimUseTime = 4 / Module.Speed
		-- AnimFinishTime = 2 / Module.Speed
		
		return Module.Speed, Module.Productivity
	end
	
	-- StackSize = 256
	-- AnimUnpackTime = 1
	-- AnimStartTime = 0.8667
	-- AnimUseTime = 4
	-- AnimFinishTime = 2
	return 1, 1
end

function Fanr_Inline_Refinery.server_markClientDataDirty( self )
	self.sv.clientDataDirty = true
end

function Fanr_Inline_Refinery.server_sendClientData( self )
	if self.sv.clientDataDirty then
		self.network:setClientData( { pipes = self.sv.pipes } )
		self.sv.clientDataDirty = false
	end
end

function Fanr_Inline_Refinery.server_getConnectedPipesAndChests( self )
	self.sv.pipes = {}
	self.sv.containers = {}

	local function fnOnVertex( vertex )

		if isAnyOf( vertex.shape:getShapeUuid(), { obj_craftbot_craftbot1, obj_craftbot_craftbot2, obj_craftbot_craftbot3, obj_craftbot_craftbot4, obj_craftbot_craftbot5, obj_craftbot_refinery } ) then
			return false
		elseif isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			local container = {
				shape = vertex.shape,
				distance = vertex.distance,
				shapesOnContainerPath = vertex.shapesOnPath
			}

			table.insert( self.sv.containers, container )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			assert( vertex.shape:getInteractable() )
			local pipe = {
				shape = vertex.shape,
				state = PipeState.off
			}
			table.insert( self.sv.pipes, pipe )
		end

		return true
	end

	ConstructPipedShapeGraph( self.shape, fnOnVertex )

	table.sort( self.sv.containers, function(a, b) return a.distance < b.distance end )

	for _, container in ipairs( self.sv.containers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.pipes ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end

	self:server_markClientDataDirty()

end

function Fanr_Inline_Refinery.server_onFixedUpdate( self, dt )
	local speed, productivity =  self:ModuleManager()
	dt = dt * speed
	
	if self.Module ~= self.shape:getInteractable():getContainer(2):getItem( 0 ).uuid then
		self.Module = self.shape:getInteractable():getContainer(2):getItem( 0 ).uuid	
		self.sv.storage = { Module = self.Module } 
		self.storage:save( self.sv.storage )
	end
	
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		self:server_getConnectedPipesAndChests()
	end

	if self.sv.isProducing then

		local inputItemUuids = sm.container.itemUuid( self:getInputContainer() )
		local harvestUuid = inputItemUuids[1]
		local recipe = g_refineryRecipes[tostring(inputItemUuids[1])]
	
		if recipe then
			self.sv.productionProgress = self.sv.productionProgress + dt/self.sv.productionTime
			if self.sv.productionProgress >= 1.0 then
				if sm.container.beginTransaction() then

					local outputContainer
					local objContainer
					if #self.sv.containers > 0 then
						objContainer = FindContainerToCollectTo( self.sv.containers, recipe.itemId, recipe.quantity )
						if objContainer then
							outputContainer = objContainer.shape:getInteractable():getContainer()
						end
					end
					if outputContainer == nil then
						outputContainer = self.shape:getInteractable():getContainer( 0 )
					end
					
					sm.container.spend( self.shape:getInteractable():getContainer( 1 ), harvestUuid, 1, true )
					sm.container.collect( outputContainer, recipe.itemId, recipe.quantity * productivity, true )
					if sm.container.endTransaction() then
						self.sv.productionProgress = 0.0
						self.sv.isProducing = false

						if objContainer then
							self.network:sendToClients("cl_finishProduction", { shapesOnContainerPath = objContainer.shapesOnContainerPath, item = recipe.itemId } )
						else
							self.network:sendToClients("cl_finishProduction")
						end
					end
				end
			end
		else
			self.sv.isProducing = false
			self.sv.productionProgress = 0.0
			local params = { isProducing = false}
			self.network:sendToClients("cl_setIsProducing", params)
		end
	else
		self.sv.productionProgress = 0
	end

	--------------------

	self.sv.updateProgress = self.sv.updateProgress + dt/self.sv.updateTime
	if self.sv.updateProgress >= 1.0 then
		self.sv.updateProgress = 0.0

		local inputItemUuids = sm.container.itemUuid( self:getInputContainer() )
		local harvestUuid = inputItemUuids[1]
		local recipe = g_refineryRecipes[tostring(inputItemUuids[1])]

		local outputItem = nil

		if inputItemUuids[1] == sm.uuid.getNil() then
			self.sv.hasInputItem = false
		else
			if sm.shape.getIsHarvest(inputItemUuids[1]) then
				self.sv.hasInputItem = true
			else
				self.sv.hasInputItem = false
				print("ERROR, invalid object")
				--borde inte hända men spotta ut allt ur container 0 om detta händer
			end
		end

		-------------------
		--Determine if the output is occupied or available for more
		local outputItemUuids = sm.container.itemUuid( self:getOutputContainer() )
		if outputItemUuids[1] == sm.uuid.getNil() then
			self.sv.outputFull = false
		else	
			outputItem = outputItemUuids[1]	
			local currentOutputQuantity = sm.container.quantity( self:getOutputContainer() )[1]
			if recipe then	
				local foundExternalSpace = false
				if #self.sv.containers > 0 then
					local objContainer = FindContainerToCollectTo( self.sv.containers, recipe.itemId, recipe.quantity )
					if objContainer then
						self.sv.outputFull = false
						foundExternalSpace = true
					end
				end
				if not foundExternalSpace then
					
					local otherContainerOutput = self.shape:getInteractable():getContainer(0)
					if sm.container.canCollect( otherContainerOutput, recipe.itemId, recipe.quantity ) then
						self.sv.outputFull = false
					else
						self.sv.outputFull = true
					end
					-- if recipe.itemId ~= outputItem or recipe.quantity + currentOutputQuantity > StackSize then
						-- self.sv.outputFull = true
					-- else
						-- self.sv.outputFull = false
					-- end
				end
			else
				self.sv.outputFull = true
			end
		end
		-------------------

		if self.sv.hasInputItem and not self.sv.outputFull then
			--Can produce so start production
			if not self.sv.isProducing then
				self.sv.isProducing = true
				self.sv.productionProgress = 0.0
				local params = { isProducing = true}
				self.network:sendToClients("cl_setIsProducing", params)
			end
		elseif not self.sv.hasInputItem then

			----Try to collect nearby harvest
			local foundHarvest = false
			for _, object in ipairs( self.sv.areaTrigger:getContents() ) do
				if foundHarvest then
					break
				end
				if type( object ) == "AreaTrigger" then
					local trigger = object
					if sm.exists( trigger ) then
						local userData = trigger:getUserData()
						if userData and userData.resourceCollector then
							local shape = userData.resourceCollector
							--Search shape containers
							if shape:getInteractable() then

								local otherContainerInput = shape:getInteractable():getContainer(1)
								local otherContainerOutput = shape:getInteractable():getContainer(0)
								local otherContainer
								if otherContainerOutput then
									otherContainer = otherContainerOutput
								else
									otherContainer = otherContainerInput
								end
								if otherContainer then

									local otherItemUuids = sm.container.itemUuid( otherContainer )
									for _, itemUuid in ipairs( otherItemUuids ) do
										if foundHarvest then
											break
										end
										if sm.shape.getIsHarvest(itemUuid) then
											foundHarvest = true
											if sm.container.beginTransaction() then
												sm.container.collect(self.shape:getInteractable():getContainer(1), itemUuid, 1, true)
												sm.container.spend(otherContainer, itemUuid, 1, true)
												sm.container.endTransaction()
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		if not self.sv.hasInputItem or self.sv.outputFull then
			--Abort any ongoing production because production can't continue
			if self.sv.isProducing then
				self.sv.isProducing = false
				self.sv.productionProgress = 0.0
				local params = { isProducing = false}
				self.network:sendToClients("cl_setIsProducing", params)
			end
		end
	end


	self:server_sendClientData()
end

function Fanr_Inline_Refinery.sv_takeHarvest(self, params)
	if self.sv.productionProgress <= 0.5 then
		if sm.container.beginTransaction() then
			sm.container.spend(params.inputContainer, params.itemUuid, 1, true)
			sm.container.collect(params.carryContainer, params.itemUuid, 1, true)
			sm.container.endTransaction()
		end
	end
end

function Fanr_Inline_Refinery.sv_e_receiveItem( self, params )
	if sm.shape.getIsHarvest( params.itemA ) then
		local container = self.interactable:getContainer( 1 )
		if container then
			sm.container.beginTransaction()
			sm.container.spend( params.containerA, params.itemA, params.quantityA, true )
			sm.container.collect( container, params.itemA, params.quantityA, true )
			sm.container.endTransaction()
		end
	end
end

function Fanr_Inline_Refinery.sv_collectPart(self, params)

	if sm.container.beginTransaction() then
		sm.container.collect(params.container, params.shape.shapeUuid, 1, true)
		if sm.container.endTransaction() then
			sm.body.removePart(params.body, params.shape)
			sm.shape.destroy(params.shape)
			sm.body.destroy(params.body)
		end
	end

end

function Fanr_Inline_Refinery.cl_setIsProducing( self, params )
	self.cl.productionProgress = 0.0
	self.cl.isProducing = params.isProducing
	if params.isProducing then
		
	else

	end
end

function Fanr_Inline_Refinery.cl_finishProduction( self, params )
	self.cl.productionProgress = 0.0
	self.cl.isProducing = false

	if params then
        local startNode = PipeEffectNode()
        startNode.shape = self.shape
        startNode.point = sm.vec3.new( 0, 0, 0 ) * sm.construction.constants.subdivideRatio
        table.insert( params.shapesOnContainerPath, 1, startNode )

		self.cl.pipeEffectPlayer:pushShapeEffectTask( params.shapesOnContainerPath, params.item )
	end

end