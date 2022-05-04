dofile( "$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/Curve.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )

Fant_Beehive = class()
Fant_Beehive.ProductionSpeed = 0.5
Fant_Beehive.Chance = 0.9
Fant_Beehive.maxfood = 5
Fant_Beehive.FoodTypes = { 
	--tier 1
	{ obj_plantables_carrot, 1 },
	{ obj_plantables_redbeet, 1 },
	{ obj_plantables_tomato, 1 },
	--tier2
	{ obj_plantables_banana, 2.5 },
	{ obj_plantables_eggplant, 2.5 },
	{ obj_plantables_blueberry, 2.5 }, 
	{ obj_plantables_orange, 2.5 },
	--tier3
	{ obj_plantables_pineapple, 5 },
	{ obj_plantables_broccoli, 5 }
}
Fant_Beehive.poseWeightCount = 2
Fant_Beehive.maxParentCount = 1
Fant_Beehive.connectionInput = sm.interactable.connectionType.logic

function Fant_Beehive.ChangeToProduce( self )
	if self.Chance >= math.random( 0, 100 ) / 100 then
		return true
	end
	return false
end

function Fant_Beehive.ProduceBeeWax( self, dt )
	self.timer = self.timer + ( dt * self.ProductionSpeed )
	if self.timer >= 1 and self:getInputs() then
		self.timer = 0
		if self.food < self.maxfood then
			for index, food in pairs( Fant_Beehive.FoodTypes ) do
				if sm.container.canSpend( self.container_2, food[1], 1 ) then
					sm.container.beginTransaction()
					sm.container.spend( self.container_2, food[1], 1, true )
					if sm.container.endTransaction() then
						self.food = self.food + food[2]
						if self.food > self.maxfood then
							self.food = self.maxfood
						end
						break
					end
				end
			end
		end
		if self.food >= self.maxfood then
			if self:ChangeToProduce() then
				local FindContainer = FindContainerToCollectTo( self.sv.connectedContainers, obj_resource_beewax, 1 )	
				if FindContainer then
					sm.container.beginTransaction()
					sm.container.collect( FindContainer.shape:getInteractable():getContainer(), obj_resource_beewax, 1, true )
					if sm.container.endTransaction() then
						self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = FindContainer.shapesOnContainerPath, item = obj_resource_beewax } )
						self.food = 0
						if self.food < 0 then
							self.food = 0
						end
					end
				else
					if sm.container.canCollect( self.container_1, obj_resource_beewax, 1 ) then
						sm.container.beginTransaction()
						sm.container.collect( self.container_1, obj_resource_beewax, 1, true )
						if sm.container.endTransaction() then
							self.food = 0
							if self.food < 0 then
								self.food = 0
							end
						end
					end
				end
			end
			if self.playEffect == false then
				self.playEffect = true
				self.network:sendToClients( "SetEffect", self.playEffect )
			end
		else
			if self.playEffect == true then
				self.playEffect = false
				self.network:sendToClients( "SetEffect", self.playEffect )
			end
		end
	end
end

function Fant_Beehive.SetEffect( self, state )
	if state then
		self.swarmEffect:start()
	else
		self.swarmEffect:stop()
	end
end

function Fant_Beehive.getInputs( self )
	local parents = self.interactable:getParents()
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			return parents[1]:isActive()
		end
	end
	return true
end

function Fant_Beehive.server_onCreate( self )	
	self.sv = {}
	self.sv.client = {}
	self.sv.client.pipeNetwork = {}
	self.sv.client.state = PipeState.off
	self.sv.client.showBlockVisualization = false
	self.sv.dirtyClientTable = false
	self.sv.dirtyStorageTable = false
	self.sv.connectedContainers = {}
	self.sv.foundItem = sm.uuid.getNil()
	self.sv.foundContainer = nil
	self:sv_buildPipeNetwork()
	self.sv.ChangedPipPipeNetwork = false
	
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { food = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.food = self.sv.storage.food
	
	self.container_1 = self.shape:getInteractable():getContainer(1)
	if not self.container_1 then
		self.container_1 = self.shape:getInteractable():addContainer( 1, 30, 256 )
	end
	self.container_1:setFilters( { obj_resource_beewax } )	
	
	self.container_2 = self.shape:getInteractable():getContainer(0)
	if not self.container_2 then
		self.container_2 = self.shape:getInteractable():addContainer( 0, 30, 256 )
	end
	self.container_2:setFilters( { 
	obj_plantables_banana,
	obj_plantables_blueberry, 
	obj_plantables_orange,
	obj_plantables_pineapple,
	obj_plantables_carrot,
	obj_plantables_redbeet,
	obj_plantables_tomato,
	obj_plantables_broccoli,
	obj_plantables_eggplant
} )	
	
	self.timer = 0
	self.playEffect = false
end

function Fant_Beehive.server_onDestroy( self )
	self.sv.storage = { food = self.food } 
	self.storage:save( self.sv.storage )
end

function Fant_Beehive.client_onCreate( self )
	self.swarmEffect = sm.effect.createEffect( "beehive - beeswarm" )
	self.swarmEffect:setPosition( self.shape.worldPosition )
	self.swarmEffect:setRotation( sm.quat.new(0,0,0,0) )

	self.cl = {}
	self.cl.pipeNetwork = {}
	self.cl.state = PipeState.off
	self.cl.showBlockVisualization = false
	self.cl.overrideUvFrameIndexTask = nil
	self.cl.poseAnimTask = nil
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
	self.container_1 = self.shape:getInteractable():getContainer(1)
	self.container_2 = self.shape:getInteractable():getContainer(0)
end

function Fant_Beehive.client_onDestroy( self )
	self.swarmEffect:stop()
	self.swarmEffect:destroy()
end

function Fant_Beehive.client_onUpdate( self, dt )
	self.swarmEffect:setPosition( self.shape.worldPosition )
	self:cl_updatePoseAnims( dt )
	self:cl_updateUvIndexFrames( dt )
	self.cl.pipeEffectPlayer:update( dt )
	if self.cl.state == PipeState.connected and self.cl.showBlockVisualization then
		local valid, gridPos, localNormal, worldPos, obj = self:constructionRayCast()
		if valid then
			local function countTerrain()
				if type(obj) == "Shape" then
					return obj:getBody():isDynamic()
				end
				return false
			end
			sm.visualization.setBlockVisualization(gridPos,
				sm.physics.sphereContactCount( worldPos, sm.construction.constants.subdivideRatio_2, countTerrain() ) > 0 or not sm.construction.validateLocalPosition( blk_cardboard, gridPos, localNormal, obj ),
				obj)
		end
	end
end

function Fant_Beehive.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Beewax Output" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Food Input" )
	return true
end

function Fant_Beehive.client_onInteract(self, character, state)
	if state == true then
		self.container_1 = self.shape:getInteractable():getContainer(1)
		self.gui = sm.gui.createContainerGui( true )	
		self.gui:setText( "UpperName", "Beehive Beewax" )
		self.gui:setContainer( "UpperGrid", self.container_1 )			
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end

function Fant_Beehive.client_onTinker( self, character, state )
	if state then
		self.container_2 = self.shape:getInteractable():getContainer(0)
		self.gui = sm.gui.createContainerGui( true )
		self.gui:setText( "UpperName", "Beehive Food" )
		self.gui:setContainer( "UpperGrid", self.container_2 )		
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end


function Fant_Beehive.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Fant_Beehive.server_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Fant_Beehive.server_canErase( self )
	local container2 = self.shape.interactable:getContainer( 1 )
	local canCarryed = true
	if container2 and sm.exists( container2 ) then
		if not container2:isEmpty() then
			canCarryed = false
		end
	end
	return canCarryed
end

function Fant_Beehive.client_canErase( self )
	local container2 = self.shape.interactable:getContainer( 1 )
	local canCarryed = true
	if container2 and sm.exists( container2 ) then
		if not container2:isEmpty() then
			canCarryed = false
		end
	end
	if canCarryed == false then
		sm.gui.displayAlertText( "Remove Beewax!", 1.5 )
	end
	return canCarryed
end

function Fant_Beehive.server_onFixedUpdate( self, dt )
	if self.lastChangedPipPipeNetwork == nil then
		self.lastChangedPipPipeNetwork = 0
	end
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		if self.lastChangedPipPipeNetwork <= 0 then
			self.sv.ChangedPipPipeNetwork = true
		end
	end
	if self.lastChangedPipPipeNetwork >= 0 then
		self.lastChangedPipPipeNetwork = self.lastChangedPipPipeNetwork - 0.08
		if self.lastChangedPipPipeNetwork <= 0 then
			self.lastChangedPipPipeNetwork = 0
		end
	end	
	if self.sv.ChangedPipPipeNetwork then
		self:sv_buildPipeNetwork()
		self.sv.ChangedPipPipeNetwork = false
		self.lastChangedPipPipeNetwork = 1
	end
	
	self:ProduceBeeWax( dt )
	

	if self.sv.dirtyStorageTable then
		self.storage:save( self.sv.storage )
		self.sv.dirtyStorageTable = false
	end
	if self.sv.dirtyClientTable then
		self.network:setClientData( { pipeNetwork = self.sv.client.pipeNetwork, state = self.sv.client.state, showBlockVisualization = self.sv.client.showBlockVisualization } )
		self.sv.dirtyClientTable = false
	end
end

function Fant_Beehive.cl_n_onIncomingFire( self, data )
	table.insert( data.shapesOnContainerPath, 1, self.shape )
	self.cl.pipeEffectPlayer:pushShapeEffectTask( data.shapesOnContainerPath, data.item )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.valid )
	self:cl_setPoseAnimTask( "incomingFire" )
end

function Fant_Beehive.cl_setPoseAnimTask( self, name )
	self.cl.poseAnimTask = { name = name, progress = 0 }
end

function Fant_Beehive.cl_updatePoseAnims( self, dt )
	if self.cl.poseAnimTask then
		self.cl.poseAnimTask.progress = self.cl.poseAnimTask.progress + dt
		local curve = PoseCurves[self.cl.poseAnimTask.name]
		if curve then
			self.shape:getInteractable():setPoseWeight( 0, curve:getValue( self.cl.poseAnimTask.progress ) )

			if self.cl.poseAnimTask.progress > curve:duration() then
				self.cl.poseAnimTask = nil
			end
		else
			self.cl.poseAnimTask = nil
		end
	end
end

function Fant_Beehive.sv_buildPipeNetwork( self )
	self.sv.client.pipeNetwork = {}
	self.sv.connectedContainers = {}
	local function fnOnVertex( vertex )
		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			local container = {
				shape = vertex.shape,
				distance = vertex.distance,
				shapesOnContainerPath = vertex.shapesOnPath
			}
			table.insert( self.sv.connectedContainers, container )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			assert( vertex.shape:getInteractable() )
			local pipe = {
				shape = vertex.shape,
				state = PipeState.off
			}
			table.insert( self.sv.client.pipeNetwork, pipe )
		end
		return true
	end
	ConstructPipedShapeGraph( self.shape, fnOnVertex )
	table.sort( self.sv.connectedContainers, function(a, b) return a.distance < b.distance end )
	local state = PipeState.off
	for _, container in ipairs( self.sv.connectedContainers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.client.pipeNetwork ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end
	self.sv.client.state = state
	self:sv_markClientTableAsDirty()
end

function Fant_Beehive.sv_markClientTableAsDirty( self )
	self.sv.dirtyClientTable = true
end

function Fant_Beehive.sv_markStorageTableAsDirty( self )
	self.sv.dirtyStorageTable = true
	self:sv_markClientTableAsDirty()
end

function Fant_Beehive.cl_pushEffectTask( self, shapeList, effect )
	self.cl.pipeEffectPlayer:pushEffectTask( shapeList, effect )
end

function Fant_Beehive.client_onClientDataUpdate( self, clientData )
	if #clientData.pipeNetwork > 0 then
		assert( clientData.state )
	end
	self.cl.pipeNetwork = clientData.pipeNetwork
	self.cl.state = clientData.state
	self.cl.showBlockVisualization = clientData.showBlockVisualization
end

function Fant_Beehive.cl_n_onError( self, data )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.invalid )
end

PoseCurves = {}
PoseCurves["outgoingFire"] = Curve()
PoseCurves["outgoingFire"]:init({{v=0.5, t=0.0},{v=1.0, t=0.1},{v=0.5, t=0.2},{v=0.0, t=0.3},{v=0.5, t=0.6}})
PoseCurves["incomingFire"] = Curve()
PoseCurves["incomingFire"]:init({{v=0.5, t=0.0},{v=0.0, t=0.1},{v=0.5, t=0.2},{v=1.0, t=0.3},{v=0.5, t=0.6}})


function Fant_Beehive.cl_setOverrideUvIndexFrame( self, shapeList, state )
	local shapeMap = {}
	if shapeList then
		for _, shape in ipairs( shapeList ) do
			shapeMap[shape:getId()] = state
		end
	end
	self.cl.overrideUvFrameIndexTask = { shapeMap = shapeMap, state = state, progress = 0 }
end

local GlowCurve = Curve()
GlowCurve:init({{v=1.0, t=0.0}, {v=0.5, t=0.05}, {v=0.0, t=0.1}, {v=0.5, t=0.3}, {v=1.0, t=0.4}, {v=0.5, t=0.5}, {v=0.0, t=0.7}, {v=0.5, t=0.75}, {v=1.0, t=0.8}})


function Fant_Beehive.cl_updateUvIndexFrames( self, dt )

	local glowMultiplier = 1.0

	-- Events allow for overriding the uv index frames, time it out
	if self.cl.overrideUvFrameIndexTask then
		self.cl.overrideUvFrameIndexTask.progress = self.cl.overrideUvFrameIndexTask.progress + dt

		glowMultiplier = GlowCurve:getValue( self.cl.overrideUvFrameIndexTask.progress )

		if self.cl.overrideUvFrameIndexTask.progress > 0.1 then

			self.cl.overrideUvFrameIndexTask.change = true
		end

		if self.cl.overrideUvFrameIndexTask.progress > 0.7 then

			self.cl.overrideUvFrameIndexTask.change = false
		end

		if self.cl.overrideUvFrameIndexTask.progress > GlowCurve:duration() then

			self.cl.overrideUvFrameIndexTask = nil
		end
	end

	-- Light up vacuum
	local state = self.cl.state
	if self.cl.overrideUvFrameIndexTask and self.cl.overrideUvFrameIndexTask.change == true then
		state = self.cl.overrideUvFrameIndexTask.state
	end

	assert( state > 0 and state <= 4 )


	local function fnOverride( pipe )

		local state = pipe.state
		local glow = 1.0

		if self.cl.overrideUvFrameIndexTask then
			local overrideState = self.cl.overrideUvFrameIndexTask.shapeMap[pipe.shape:getId()]
			if overrideState then
				if self.cl.overrideUvFrameIndexTask.change == true then
					state = overrideState
				end
				glow = glowMultiplier
			end
		end

		return state, glow
	end

	-- Light up pipes
	LightUpPipes( self.cl.pipeNetwork, fnOverride )
end

