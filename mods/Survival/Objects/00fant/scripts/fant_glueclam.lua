dofile( "$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/Curve.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )

Fant_Glueclam = class()
Fant_Glueclam.ProductionSpeed = 0.5
Fant_Glueclam.MaxPower = 10
Fant_Glueclam.Chance = 0.15
Fant_Glueclam.poseWeightCount = 2
Fant_Glueclam.maxParentCount = 2
Fant_Glueclam.connectionInput = sm.interactable.connectionType.electricity + sm.interactable.connectionType.logic
Fant_Glueclam.colorNormal = sm.color.new( 0xff8000ff )
Fant_Glueclam.colorHighlight = sm.color.new( 0xff9f3aff )

function Fant_Glueclam.ChangeToProduce( self )
	if self.Chance >= math.random( 0, 100 ) / 100 then
		return true
	end
	return false
end

function Fant_Glueclam.ProduceGlue( self, dt )
	self.timer = self.timer + ( dt * self.ProductionSpeed )
	if self.timer >= 1 then
		self.timer = 0
		local active, batterieContainer = self:getInputs()
		if self.Power <= 0 then	
			if active then			
				if batterieContainer then
					if sm.container.canSpend( batterieContainer, obj_consumable_battery, 1 ) then
						sm.container.beginTransaction()
						sm.container.spend( batterieContainer, obj_consumable_battery, 1, true )
						if sm.container.endTransaction() then
							self.Power = self.MaxPower
						end
					end
				end
			end
		end
		
		if self.Power > 0 and active then
			local FindContainer = FindContainerToCollectTo( self.sv.connectedContainers, obj_resources_slimyclam, 1 )	
			if FindContainer and self:ChangeToProduce() then
				sm.container.beginTransaction()
				sm.container.collect( FindContainer.shape:getInteractable():getContainer(), obj_resources_slimyclam, 1, true )
				if sm.container.endTransaction() then
					self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = FindContainer.shapesOnContainerPath, item = obj_resources_slimyclam } )
				end
			else
				if sm.container.canCollect( self.container, obj_resources_slimyclam, 1 ) and self:ChangeToProduce() then
					sm.container.beginTransaction()
					sm.container.collect( self.container, obj_resources_slimyclam, 1, true )
					sm.container.endTransaction()
				end
			end
			self.Power = self.Power - 1
			if self.Power < 0 then
				self.Power = 0
			end
			self.network:sendToClients( "cl_setPoseAnimTask", "incomingFire" )
		end
	end
end

function Fant_Glueclam.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Fant_Glueclam.server_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Fant_Glueclam.getInputs( self )
	local parents = self.interactable:getParents()
	local batterieContainer = nil
	local active = false
	local haslogic = false
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[2]:isActive()
			haslogic = true
		end	
		if parents[2]:hasOutputType( sm.interactable.connectionType.electricity ) then
			batterieContainer = parents[2]:getContainer( 0 )
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[1]:isActive()
			haslogic = true
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.electricity ) then
			batterieContainer = parents[1]:getContainer( 0 )
		end
	end
	if haslogic == false then
		active = true
	end
	return active, batterieContainer
end

function Fant_Glueclam.server_onCreate( self )	
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
		self.sv.storage = { Power = 0 } 
		self.storage:save( self.sv.storage )
	end
	self.Power = self.sv.storage.Power
	
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 30, 256 )
	end
	self.container:setFilters( { obj_resources_slimyclam } )	
	
	self.timer = 0
end

function Fant_Glueclam.server_onDestroy( self )
	self.sv.storage = { Power = self.Power } 
	self.storage:save( self.sv.storage )
end

function Fant_Glueclam.client_onCreate( self )
	--self.Effect = sm.effect.createEffect( "SlimyClam - Bubbles" )
	-- self.Effect:setPosition( self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * 0.5 ) ) --
	-- self.Effect:setRotation( sm.quat.new(0,0,0,0) )
	-- self.Effect:start()
	
	self.cl = {}
	self.cl.pipeNetwork = {}
	self.cl.state = PipeState.off
	self.cl.showBlockVisualization = false
	self.cl.overrideUvFrameIndexTask = nil
	self.cl.poseAnimTask = nil
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
end

function Fant_Glueclam.client_onDestroy( self )
	--self.Effect:stop()
	--self.Effect:destroy()
end

function Fant_Glueclam.client_onUpdate( self, dt )
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

function Fant_Glueclam.client_onInteract(self, character, state)
	if state == true then
		self.container = self.shape:getInteractable():getContainer(0)
		self.gui = sm.gui.createContainerGui( true )		
		self.gui:setText( "UpperName", "Glue Clam Tank" )
		self.gui:setContainer( "UpperGrid", self.container )		

		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		self.gui:open()		
	end
end

function Fant_Glueclam.server_onFixedUpdate( self, dt )
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
	
	
	
	self:ProduceGlue( dt )
	

	if self.sv.dirtyStorageTable then
		self.storage:save( self.sv.storage )
		self.sv.dirtyStorageTable = false
	end
	if self.sv.dirtyClientTable then
		self.network:setClientData( { pipeNetwork = self.sv.client.pipeNetwork, state = self.sv.client.state, showBlockVisualization = self.sv.client.showBlockVisualization } )
		self.sv.dirtyClientTable = false
	end
end

function Fant_Glueclam.cl_n_onIncomingFire( self, data )
	table.insert( data.shapesOnContainerPath, 1, self.shape )
	self.cl.pipeEffectPlayer:pushShapeEffectTask( data.shapesOnContainerPath, data.item )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.valid )
	--self:cl_setPoseAnimTask( "incomingFire" )
end

function Fant_Glueclam.cl_setPoseAnimTask( self, name )
	self.cl.poseAnimTask = { name = name, progress = 0 }
end

function Fant_Glueclam.cl_updatePoseAnims( self, dt )
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

function Fant_Glueclam.sv_buildPipeNetwork( self )
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

function Fant_Glueclam.sv_markClientTableAsDirty( self )
	self.sv.dirtyClientTable = true
end

function Fant_Glueclam.sv_markStorageTableAsDirty( self )
	self.sv.dirtyStorageTable = true
	self:sv_markClientTableAsDirty()
end

function Fant_Glueclam.cl_pushEffectTask( self, shapeList, effect )
	self.cl.pipeEffectPlayer:pushEffectTask( shapeList, effect )
end

function Fant_Glueclam.client_onClientDataUpdate( self, clientData )
	if #clientData.pipeNetwork > 0 then
		assert( clientData.state )
	end
	self.cl.pipeNetwork = clientData.pipeNetwork
	self.cl.state = clientData.state
	self.cl.showBlockVisualization = clientData.showBlockVisualization
end

function Fant_Glueclam.cl_n_onError( self, data )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.invalid )
end

PoseCurves = {}
PoseCurves["outgoingFire"] = Curve()
PoseCurves["outgoingFire"]:init({{v=0.5, t=0.0},{v=1.0, t=0.1},{v=0.5, t=0.2},{v=0.0, t=0.3},{v=0.5, t=0.6}})
PoseCurves["incomingFire"] = Curve()
PoseCurves["incomingFire"]:init({{v=0.5, t=0.0},{v=0.0, t=0.1},{v=0.5, t=0.2},{v=1.0, t=0.3},{v=0.5, t=0.6}})


function Fant_Glueclam.cl_setOverrideUvIndexFrame( self, shapeList, state )
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


function Fant_Glueclam.cl_updateUvIndexFrames( self, dt )

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

