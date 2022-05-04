dofile( "$SURVIVAL_DATA/Scripts/game/util/Curve.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua")


Fant_Pigmentflower_Grower = class()
Fant_Pigmentflower_Grower.poseWeightCount = 3
Fant_Pigmentflower_Grower.maxParentCount = 3
Fant_Pigmentflower_Grower.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.water
Fant_Pigmentflower_Grower.GrowSpeed = 1
Fant_Pigmentflower_Grower.MaxWater = 1
Fant_Pigmentflower_Grower.MaxFertilizer = 1
Fant_Pigmentflower_Grower.WaterConsumeRate = 0.4
Fant_Pigmentflower_Grower.FertilizerConsumeRate = 0.6
Fant_Pigmentflower_Grower.GrowStep = 0.005
Fant_Pigmentflower_Grower.ProduceAmount = 1

function Fant_Pigmentflower_Grower.server_onCreate( self )
	self.timer = 0
	self.connectedContainer = nil
	self.container = self.shape.interactable:getContainer( 0 )
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 10, 256 )
	end
	self.container:setFilters( { obj_resource_flower } )
	
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
	
	self.GrowState = 0
	self.LastGrowState = 1
	self.water = 0
	self.fertilizer = 0
end

function Fant_Pigmentflower_Grower.server_onDestroy( self )
	
end

function Fant_Pigmentflower_Grower.getInputs( self )
	local FertilizerContainer = nil
	local WaterContainer = nil
	local LogicInput = false
	for index, parent in pairs( self.interactable:getParents() ) do 
		if parent then
			if parent:hasOutputType( sm.interactable.connectionType.logic ) then
				LogicInput = parent:isActive()
			end
			if parent:hasOutputType( sm.interactable.connectionType.water ) then
				if parent.shape.uuid == obj_container_water then
					WaterContainer = parent:getContainer( 0 )
				end
				if parent.shape.uuid == obj_interactive_fant_fluidconnector then
					WaterContainer = parent:getContainer( 0 )
				end
				if parent.shape.uuid == obj_container_fertilizer then
					FertilizerContainer = parent:getContainer( 0 )
				end
			end
		end
	end
	return LogicInput, WaterContainer, FertilizerContainer
end

function Fant_Pigmentflower_Grower.server_onFixedUpdate( self, dt )
	if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		self:sv_buildPipeNetwork()
	end	
	if self.timer > 0 then
		self.timer = self.timer - dt
		return
	end
	self.timer = 1 / self.GrowSpeed
	
	local LogicInput, WaterContainer, FertilizerContainer = self:getInputs()

	if LogicInput then
		if WaterContainer then
			if self.water <= 0 then
				sm.container.beginTransaction()
				sm.container.spend( WaterContainer, obj_consumable_water, 1, true )
				if sm.container.endTransaction() then	
					self.water = self.MaxWater
				end
			end
		end
		if FertilizerContainer then
			if self.fertilizer <= 0 then
				sm.container.beginTransaction()
				sm.container.spend( FertilizerContainer, obj_consumable_fertilizer, 1, true )
				if sm.container.endTransaction() then	
					self.fertilizer = self.MaxFertilizer
				end
			end
		end	
		if self.water > 0 and self.fertilizer > 0 then
			self.water = self.water - ( dt * self.WaterConsumeRate )
			if self.water < 0 then
				self.water = 0
			end
			self.fertilizer = self.fertilizer - ( dt * self.FertilizerConsumeRate )
			if self.fertilizer < 0 then
				self.fertilizer = 0
			end
			self.GrowState = self.GrowState + math.random( self.GrowStep, self.GrowStep * 2 )
			if self.GrowState > 1 then
				self.GrowState = 0			
				local FindContainerCanCollect = false
				local SelfContainerCanCollect = sm.container.canCollect( self.container, obj_resource_flower, self.ProduceAmount )
				local FindContainer = FindContainerToCollectTo( self.sv.connectedContainers, obj_resource_flower, self.ProduceAmount )
				if FindContainer then
					FindContainerCanCollect = sm.container.canCollect( FindContainer.shape:getInteractable():getContainer(), obj_resource_flower, self.ProduceAmount )
				end		
				if FindContainerCanCollect then									
					sm.container.beginTransaction()
					sm.container.collect( FindContainer.shape:getInteractable():getContainer(), obj_resource_flower, self.ProduceAmount, true )
					if sm.container.endTransaction() then									
						self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = FindContainer.shapesOnContainerPath, item =  obj_resource_flower } )						
					end		
				else
					if SelfContainerCanCollect then
						sm.container.beginTransaction()
						sm.container.collect( self.container, obj_resource_flower, self.ProduceAmount, true )
						if sm.container.endTransaction() then
							self.network:sendToClients( "cl_GrowEffect" )
						
						end	
					end
				end
			end
			
		end
		--print( "Water: " .. tostring( math.floor( self.water * 10 ) / 10 ) )
		--print( "Fertilizer: " .. tostring( math.floor( self.fertilizer* 10 ) / 10 ) )
	end
	if self.GrowState ~= self.LastGrowState then
		self.LastGrowState = self.GrowState
		self.network:sendToClients( "cl_SetPoseValue", self.GrowState )
	end
	
	if self.sv.dirtyStorageTable then
		self.storage:save( self.sv.storage )
		self.sv.dirtyStorageTable = false
	end
	if self.sv.dirtyClientTable then
		self.network:setClientData( { pipeNetwork = self.sv.client.pipeNetwork, state = self.sv.client.state, showBlockVisualization = self.sv.client.showBlockVisualization } )
		self.sv.dirtyClientTable = false
	end
end

function Fant_Pigmentflower_Grower.cl_GrowEffect( self )
	sm.effect.playEffect( "Pigmentflower - Picked", self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * -1.5 ) )
end

function Fant_Pigmentflower_Grower.cl_SetPoseValue( self, value )
	self.shape:getInteractable():setPoseWeight( 0, value )
end

function Fant_Pigmentflower_Grower.client_onUpdate( self, dt )
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

function Fant_Pigmentflower_Grower.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Fant_Pigmentflower_Grower.client_onInteract(self, character, state)
	if state == true then
		self.container = self.shape.interactable:getContainer( 0 )
		self.gui = sm.gui.createContainerGui( true )
		self.gui:setText( "UpperName", "Pigment Flower Box" )
		self.gui:setContainer( "UpperGrid", self.container )	
		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()
	end
end

function Fant_Pigmentflower_Grower.server_outgoingReload( self, container, item )
	self.sv.foundContainer, self.sv.foundItem = container, item
	local isBlock = sm.item.isBlock( self.sv.foundItem )
	if self.sv.client.showBlockVisualization ~= isBlock then
		self.sv.client.showBlockVisualization = isBlock
		self:sv_markClientTableAsDirty()
	end
	if self.sv.foundContainer then
		self.network:sendToClients( "cl_n_onOutgoingReload", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath, item = self.sv.foundItem } )
	end
end

function Fant_Pigmentflower_Grower.server_outgoingReset( self )
	self.sv.foundContainer = nil
	self.sv.foundItem = sm.uuid.getNil()
	if self.sv.client.showBlockVisualization then
		self.sv.client.showBlockVisualization = false
		self:sv_markClientTableAsDirty()
	end
end

function Fant_Pigmentflower_Grower.server_outgoingShouldReload( self, container, item )
	return self.sv.foundItem ~= item
end

function Fant_Pigmentflower_Grower.cl_n_onOutgoingFire( self, data )
	if data.shapesOnContainerPath then
		table.insert( data.shapesOnContainerPath, self.shape )
	end		
end

function Fant_Pigmentflower_Grower.cl_n_onOutgoingReload( self, data )
	if not data then
		return
	end
	if not data.item then
		return
	end
	if data.item == sm.uuid.getNil() then
		return
	end
	if data.item == tool_gatling then
		return
	end
	if data.item == tool_shotgun then
		return
	end
	if data.item == tool_spudgun then
		return
	end
	if data.item == tool_spudgun_creative then
		return
	end
	if data.item == tool_weld then
		return
	end
	if data.item == tool_paint then
		return
	end
	if data.item == tool_connect then
		return
	end
	if data.item == tool_lift then
		return
	end
	if data.item == tool_sledgehammer then
		return
	end
	local shapeList = {}
	for idx, shape in reverse_ipairs( data.shapesOnContainerPath ) do
		table.insert( shapeList, shape )
	end
	table.insert( shapeList, self.shape )
	self.cl.pipeEffectPlayer:pushShapeEffectTask( shapeList, data.item )
end

function Fant_Pigmentflower_Grower.client_onCreate( self )
	self.cl = {}
	self.cl.pipeNetwork = {}
	self.cl.state = PipeState.off
	self.cl.showBlockVisualization = false
	self.cl.overrideUvFrameIndexTask = nil
	self.cl.poseAnimTask = nil
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
end

function Fant_Pigmentflower_Grower.cl_n_onIncomingFire( self, data )
	table.insert( data.shapesOnContainerPath, 1, self.shape )
	self.cl.pipeEffectPlayer:pushShapeEffectTask( data.shapesOnContainerPath, data.item )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.valid )
	self:cl_setPoseAnimTask( "incomingFire" )
	self:cl_GrowEffect()
end

function Fant_Pigmentflower_Grower.cl_setPoseAnimTask( self, name )
	self.cl.poseAnimTask = { name = name, progress = 0 }
end

function Fant_Pigmentflower_Grower.sv_buildPipeNetwork( self )
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

function Fant_Pigmentflower_Grower.sv_markClientTableAsDirty( self )
	self.sv.dirtyClientTable = true
end

function Fant_Pigmentflower_Grower.sv_markStorageTableAsDirty( self )
	self.sv.dirtyStorageTable = true
	self:sv_markClientTableAsDirty()
end

function Fant_Pigmentflower_Grower.cl_pushEffectTask( self, shapeList, effect )
	self.cl.pipeEffectPlayer:pushEffectTask( shapeList, effect )
end

function Fant_Pigmentflower_Grower.client_onClientDataUpdate( self, clientData )
	if #clientData.pipeNetwork > 0 then
		assert( clientData.state )
	end
	self.cl.pipeNetwork = clientData.pipeNetwork
	self.cl.state = clientData.state
	self.cl.showBlockVisualization = clientData.showBlockVisualization
end

function Fant_Pigmentflower_Grower.cl_n_onError( self, data )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.invalid )
end

PoseCurves = {}
PoseCurves["outgoingFire"] = Curve()
PoseCurves["outgoingFire"]:init({{v=0.5, t=0.0},{v=1.0, t=0.1},{v=0.5, t=0.2},{v=0.0, t=0.3},{v=0.5, t=0.6}})
PoseCurves["incomingFire"] = Curve()
PoseCurves["incomingFire"]:init({{v=0.5, t=0.0},{v=0.0, t=0.1},{v=0.5, t=0.2},{v=1.0, t=0.3},{v=0.5, t=0.6}})


function Fant_Pigmentflower_Grower.cl_setOverrideUvIndexFrame( self, shapeList, state )
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


function Fant_Pigmentflower_Grower.cl_updateUvIndexFrames( self, dt )

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



