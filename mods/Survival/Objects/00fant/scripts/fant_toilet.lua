dofile("$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile( "$SURVIVAL_DATA/Scripts/game/util/Curve.lua" )
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_shapes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/util/pipes.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

Fant_Toilet = class()
Fant_Toilet.PumpSpeedInSeconds = 0.5
ColorModes = {}

--Empty Non Ammo, Non Food, Non Weapons/Tools, Non Paint, Non Glowstick
ColorModes["3e9ffeff"] = {
	name = "emptyRestricted",
	itemFilter = {},
	antiitemFilter = { 
		obj_consumable_fant_steak,
		obj_consumable_fant_redwoc,
		obj_consumable_fant_totebots,
		obj_consumable_fant_fries,
		obj_consumable_fant_popcorn,
		obj_consumable_fant_met,
		obj_consumable_sunshake,
		obj_consumable_carrotburger,
		obj_consumable_pizzaburger,
		obj_consumable_longsandwich,
		obj_consumable_milk,
		obj_consumable_inkammo,
		obj_consumable_glowstick,
		obj_plantables_banana,
		obj_plantables_blueberry,
		obj_plantables_orange,
		obj_plantables_pineapple,
		obj_plantables_carrot,
		obj_plantables_redbeet,
		obj_plantables_tomato,
		obj_plantables_broccoli,
		obj_plantables_potato,
		obj_tool_connect,
		obj_tool_paint,
		obj_tool_weld,
		obj_tool_spudgun,
		obj_tool_spudling,
		obj_tool_frier,
		tool_handbook,
		tool_sledgehammer,
		tool_lift,
		tool_connect,
		tool_paint,
		tool_weld,
		tool_spudgun,
		tool_shotgun,
		tool_gatling,
		weapon_fant_bananammer,
		weapon_fant_baseballbat,
		weapon_fant_constructionlamp,
		weapon_fant_electroHammer,
		weapon_fant_greatNeckWrench,
		weapon_fant_redwochammer,
		weapon_fant_fork,
		weapon_fant_bazooka,
		sm.uuid.new( "e15cdeec-02fb-4113-8626-c66dde3232b5" ),
		sm.uuid.new( "5120e4c9-c160-4434-87f4-c2313e2602c8" ),
		sm.uuid.new( "edeea470-6eda-40ef-95e6-5d37a10bade5" ),
		sm.uuid.new( "40bf4cb9-e857-44de-89b8-0a42de20ebd5" ),
		sm.uuid.new( "cadac9b3-8b3b-4b8e-a50a-f1f23f47a7fc" ),
		sm.uuid.new( "4bec43af-809c-4e01-a249-72ce8184f430" ),
		sm.uuid.new( "41936190-31bf-4cbd-93b4-8e7f2ac2f9c3" ),
		sm.uuid.new( "df1dacba-9905-4dce-aacc-16a1e3c2aef1" ),
		obj_tool_bucket_empty, 
		obj_tool_bucket_water,
		obj_tool_bucket_chemical,
		
		
		
		sm.uuid.new( "04474c14-4240-4729-becf-108680b42b76" ),
		sm.uuid.new( "4f8c659e-924b-4475-a0e8-74b7db696333" ),
		sm.uuid.new( "0d886c8f-5ece-4860-a115-22d5ad339b44" ),
		sm.uuid.new( "7facaa00-bd55-492b-96b7-91481b010601" ),
		sm.uuid.new( "e15cdeec-02fb-4113-8626-c66dde3232b5" ),
		sm.uuid.new( "5120e4c9-c160-4434-87f4-c2313e2602c8" ),
		sm.uuid.new( "edeea470-6eda-40ef-95e6-5d37a10bade5" ),
		sm.uuid.new( "40bf4cb9-e857-44de-89b8-0a42de20ebd5" ),
		sm.uuid.new( "cadac9b3-8b3b-4b8e-a50a-f1f23f47a7fc" ),
		sm.uuid.new( "4bec43af-809c-4e01-a249-72ce8184f430" ),
		sm.uuid.new( "41936190-31bf-4cbd-93b4-8e7f2ac2f9c3" ),
		sm.uuid.new( "df1dacba-9905-4dce-aacc-16a1e3c2aef1" ),
		weapon_fant_watergun,
		weapon_fant_handheld_flamethrower,
		sm.uuid.new( "c9d61b8a-b116-41d5-9f95-77a87e4fcff7" ),
		
		weapon_fant_scrapgun,
		sm.uuid.new( "3ab3f216-f16d-40aa-b125-e54b0e9ae8eb" ),

		weapon_Fant_Waypoint_Marker,
		sm.uuid.new( "1fd57b7b-168e-4209-b0e2-9285ff0ca0af" ),
		
		weapon_Fant_Block_Editor,
		sm.uuid.new( "e5f0077b-05fa-4d41-904b-07c1651686dd" ),
		
		weapon_Fant_Measurement_Tool,
		sm.uuid.new( "8ba1eb2a-4337-4ebc-94c9-24e54b1ae426" ),
		
		weapon_fant_handbook,
		sm.uuid.new( "feae3463-75b7-463c-9de2-b5c341101e8a" ),
		
		weapon_Fant_ThrusterHammer,
		sm.uuid.new( "a41681d5-8c35-48d8-8939-8c9786e62391" ),
		
		weapon_Fant_Remotegun,
		sm.uuid.new( "162365dc-6a45-4c34-b30a-1562c9e3e024" ),

		obj_interactive_fant_head_lamp_obj,
		obj_interactive_fant_corvos_exochest_red,
		obj_interactive_fant_corvos_exopants_red,
		obj_interactive_fant_corvos_exochest_green,
		obj_interactive_fant_corvos_exopants_green,
		obj_interactive_fant_corvos_exochest_blue,
		obj_interactive_fant_corvos_exopants_blue,
		obj_interactive_fant_corvos_exohat_blue,
		obj_interactive_fant_corvos_exohat_red,
		obj_interactive_fant_corvos_exohat_green,
		obj_interactive_fant_glowbug_hat,
		obj_interactive_fant_joint_hat,
		weapon_Fant_Popcorn_Launcher,
		sm.uuid.new( "d0458dad-8cee-44fb-af4a-ebbb4a64293a" )
	}
}
--Empty Everything
ColorModes["eeeeeeff"] = {
	name = "empty",
	itemFilter = {},
	antiitemFilter = {}
}
--Ammo Fill - YELLOW
ColorModes["e2db13ff"] = {
	name = "ammofill",
	itemFilter = { 
		obj_plantables_potato
	},
	antiitemFilter = {}
}
--Food Fill - RED
ColorModes["d02525ff"] = {
	name = "foodfill",
	itemFilter = { 
		obj_consumable_fant_steak,
		obj_consumable_fant_redwoc,
		obj_consumable_fant_totebots,
		obj_consumable_fant_fries,
		obj_consumable_fant_popcorn,
		obj_consumable_fant_met,
		obj_consumable_sunshake,
		obj_consumable_carrotburger,
		obj_consumable_pizzaburger,
		obj_consumable_longsandwich,
		obj_consumable_milk,
		obj_plantables_banana,
		obj_plantables_blueberry,
		obj_plantables_orange,
		obj_plantables_pineapple,
		obj_plantables_carrot,
		obj_plantables_redbeet,
		obj_plantables_tomato,
		obj_plantables_broccoli,
		obj_plantables_potato
	},
	antiitemFilter = {}
}

function Fant_Toilet.server_onCreate( self )
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 1024 )
	end
	self.container:setFilters( {} )
	self.color = sm.shape.getColor( self.shape )
	self:refreshMode()
	
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { mode = "emptyRestricted" } 
		self.storage:save( self.sv.storage )
	end
	
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
	
	self.mode = self.sv.storage.mode
	self.network:sendToClients( "cl_setMode", self.mode )
	
	self.PumpTimer = 0
end

function Fant_Toilet.client_onCreate( self )
	self.cl = {}
	self.cl.pipeNetwork = {}
	self.cl.state = PipeState.off
	self.cl.showBlockVisualization = false
	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()
	
	self.cl_mode = "emptyRestricted"
	self.network:sendToServer( "GetMode" )	
end

function Fant_Toilet.GetMode( self )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_Toilet.sv_setMode( self, mode )
	self.mode = mode
	self.sv.storage.mode = self.mode
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_Toilet.cl_setMode( self, mode )
	self.cl_mode = mode
end

function Fant_Toilet.refreshMode( self )
	for key, colormode in pairs( ColorModes ) do
		if colormode.name == self.mode and colormode ~= nil then
			if colormode.itemFilter ~= nil then
				self.ColorMode = colormode
				self.container:setFilters( colormode.itemFilter )
				return
			end
			
		end
	end
	self.ColorMode = ColorModes["3e9ffeff"]
	self.container:setFilters( {} )
end

function Fant_Toilet.server_onFixedUpdate( self, dt )
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
	
	if self.PumpTimer > 0 then
		self.PumpTimer = self.PumpTimer - dt
		return
	else
		self.PumpTimer = self.PumpSpeedInSeconds
		self:refreshMode()
		
		local inventory = nil
		local seatedCharacter = self.interactable:getSeatCharacter()
		if seatedCharacter ~= nil then
			
			local player = seatedCharacter:getPlayer()
			if player then
				inventory = player:getInventory()
			end
		end
		if inventory ~= nil and self.ColorMode ~= nil and self.ColorMode.name ~= nil then
			if self.ColorMode.name == "empty" then
				if not inventory:isEmpty() then
					for slot = 0, inventory:getSize() - 1 do									
						local item = inventory:getItem( slot )
						if item then
							if item.uuid ~= sm.uuid.getNil() and item.quantity > 0 and item.uuid ~= tool_sledgehammer and item.uuid ~= tool_lift then	
								self:SendItemToConnectedContainer( item.uuid, inventory, item.quantity )
								
							end
						end
					end
				end
			elseif self.ColorMode.name == "emptyRestricted" then
				if not inventory:isEmpty() then
					for slot = 0, inventory:getSize() - 1 do									
						local item = inventory:getItem( slot )
						if item then
							if item.uuid ~= sm.uuid.getNil() and item.quantity > 0 then					
								local canTransfer = true
								for index, fitem in pairs( self.ColorMode.antiitemFilter ) do
									if fitem == item.uuid then
										canTransfer = false
										break
									end
								end
								if canTransfer then
									self:SendItemToConnectedContainer( item.uuid, inventory, item.quantity )
								end
							end
						end
					end
				end
			elseif self.ColorMode.name == "ammofill" or self.ColorMode.name == "foodfill" then
				for index, fitem in pairs( self.ColorMode.itemFilter ) do
					self:GetItemFromConnectedContainer( fitem, inventory )
				end
			end

		end
		
		
		
		if self.sv.connectedContainers == nil then
			self:sv_buildPipeNetwork()
			return
		else		
			if self.fertilizer_timer == nil then
				self.fertilizer_timer = math.random( 30, 60 )
			end 
			--print( "self.fertilizer_timer: " .. self.fertilizer_timer )	
			self.fertilizer_timer = self.fertilizer_timer - 1
			if inventory ~= nil and self.fertilizer_timer <= 0 then
				self.fertilizer_timer = math.random( 30, 60 )
				if self.sv.connectedContainers == nil then
					self:sv_buildPipeNetwork()
					return
				end
				local FindContainer = FindContainerToCollectTo( self.sv.connectedContainers, obj_consumable_fertilizer, 1 )	
				if FindContainer then
					sm.container.beginTransaction()
					sm.container.collect( FindContainer.shape:getInteractable():getContainer(), obj_consumable_fertilizer, 1, true )
					if sm.container.endTransaction() then
						self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = FindContainer.shapesOnContainerPath, item = uuid } )
						return
					end
				end
			end
		end
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

function Fant_Toilet.GetItemFromConnectedContainer( self, uuid, playerinventory )			
	if self.sv.connectedContainers == nil then
		self:sv_buildPipeNetwork()
		return
	end
	if playerinventory ~= nil then
		
		for _, container in ipairs( self.sv.connectedContainers ) do
			if sm.exists( container.shape ) then
				if not container.shape:getInteractable():getContainer():isEmpty() then
					for slot = 0, container.shape:getInteractable():getContainer():getSize() - 1 do
						local foundItem = false										
						local item = container.shape:getInteractable():getContainer():getItem( slot )
						if item then
							if uuid == item.uuid then
								if item.quantity > 0 then
									if sm.container.canCollect( playerinventory, uuid, item.quantity ) then
										if self:server_outgoingShouldReload( container, item ) then
											self:server_outgoingReload( container, item.uuid )
										end			
										if item.uuid ~= sm.uuid.getNil() and sm.container.canCollect( self.container, item.uuid, item.quantity ) then					
											sm.container.beginTransaction()
											sm.container.spend( container.shape:getInteractable():getContainer(), item.uuid, item.quantity, true )
											if sm.container.endTransaction() then
												sm.container.beginTransaction()
												sm.container.collect( playerinventory, item.uuid, item.quantity, true)	
												if sm.container.endTransaction() then
													self.network:sendToClients( "cl_n_onOutgoingFire", { shapesOnContainerPath = self.sv.foundContainer.shapesOnContainerPath } )	
													return
												end					
											end		
											self:server_outgoingReset()		
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
end

function Fant_Toilet.SendItemToConnectedContainer( self, uuid, playerinventory, amount )
	if self.sv.connectedContainers == nil then
		self:sv_buildPipeNetwork()
		return
	end
	if playerinventory ~= nil then
		if sm.container.canSpend( playerinventory, uuid, amount ) then
			if uuid ~= nil and amount > 0 then
				local FindContainer = FindContainerToCollectTo( self.sv.connectedContainers, uuid, amount )	
				if FindContainer then
					sm.container.beginTransaction()
					sm.container.spend( playerinventory, uuid, amount, true )
					if sm.container.endTransaction() then
						sm.container.beginTransaction()
						sm.container.collect( FindContainer.shape:getInteractable():getContainer(), uuid, amount, true )
						if sm.container.endTransaction() then
							self.network:sendToClients( "cl_n_onIncomingFire", { shapesOnContainerPath = FindContainer.shapesOnContainerPath, item = uuid } )
							return
						end
					end
				end
			end
		end
	end
end
	
function Fant_Toilet.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Sit" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. tostring( self.cl_mode ) )
	return true
end

function Fant_Toilet.client_onTinker( self, character, state )
	if state then
		if self.cl_mode == "emptyRestricted" then
			self.cl_mode = "empty"
		elseif self.cl_mode == "empty" then
			self.cl_mode = "ammofill"
		elseif self.cl_mode == "ammofill" then
			self.cl_mode = "foodfill"
		elseif self.cl_mode == "foodfill" then
			self.cl_mode = "emptyRestricted"
		end
		self.network:sendToServer( "sv_setMode", self.cl_mode )	
	end
end
		
function Fant_Toilet.client_onInteract( self, character, state )
	if state then
		self:cl_seat()
		if self.shape.interactable:getSeatCharacter() ~= nil then
			sm.gui.displayAlertText( "#{ALERT_DRIVERS_SEAT_OCCUPIED}", 4.0 )
		end
	end
end

function Fant_Toilet.cl_seat( self )
	if sm.localPlayer.getPlayer() and sm.localPlayer.getPlayer():getCharacter() then
		self.interactable:setSeatCharacter( sm.localPlayer.getPlayer():getCharacter() )
	end
end

function Fant_Toilet.client_onAction( self, controllerAction, state )
	if state == true then
		if controllerAction == sm.interactable.actions.use or controllerAction == sm.interactable.actions.jump then
			self:cl_seat()
		end
	end
	return false
end

function Fant_Toilet.client_onUpdate( self, dt )

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

function Fant_Toilet.sv_buildPipeNetwork( self )
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

function Fant_Toilet.sv_markClientTableAsDirty( self )
	self.sv.dirtyClientTable = true
end

function Fant_Toilet.sv_markStorageTableAsDirty( self )
	self.sv.dirtyStorageTable = true
	self:sv_markClientTableAsDirty()
end

function Fant_Toilet.server_outgoingReload( self, container, item )
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

function Fant_Toilet.server_outgoingReset( self )
	self.sv.foundContainer = nil
	self.sv.foundItem = sm.uuid.getNil()
	if self.sv.client.showBlockVisualization then
		self.sv.client.showBlockVisualization = false
		self:sv_markClientTableAsDirty()
	end
end

function Fant_Toilet.server_outgoingShouldReload( self, container, item )
	return self.sv.foundItem ~= item
end

function Fant_Toilet.cl_n_onOutgoingFire( self, data )
	if data.shapesOnContainerPath then
		table.insert( data.shapesOnContainerPath, self.shape )
	end		
end

function Fant_Toilet.cl_n_onOutgoingReload( self, data )
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

function Fant_Toilet.cl_pushEffectTask( self, shapeList, effect )
	self.cl.pipeEffectPlayer:pushEffectTask( shapeList, effect )
end

function Fant_Toilet.client_onClientDataUpdate( self, clientData )
	if #clientData.pipeNetwork > 0 then
		assert( clientData.state )
	end
	self.cl.pipeNetwork = clientData.pipeNetwork
	self.cl.state = clientData.state
	self.cl.showBlockVisualization = clientData.showBlockVisualization
end

function Fant_Toilet.cl_n_onError( self, data )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.invalid )
end

function Fant_Toilet.cl_setOverrideUvIndexFrame( self, shapeList, state )
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

function Fant_Toilet.cl_updateUvIndexFrames( self, dt )

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

function Fant_Toilet.cl_n_onIncomingFire( self, data )
	table.insert( data.shapesOnContainerPath, 1, self.shape )
	
	
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
	if data.item == sm.uuid.new( "04474c14-4240-4729-becf-108680b42b76" ) then
		return
	end
	if data.item == sm.uuid.new( "4f8c659e-924b-4475-a0e8-74b7db696333" ) then
		return
	end
	if data.item == sm.uuid.new( "0d886c8f-5ece-4860-a115-22d5ad339b44" ) then
		return
	end
	if data.item == sm.uuid.new( "7facaa00-bd55-492b-96b7-91481b010601" ) then
		return
	end
	if data.item == sm.uuid.new( "e15cdeec-02fb-4113-8626-c66dde3232b5" ) then
		return
	end
	if data.item == sm.uuid.new( "5120e4c9-c160-4434-87f4-c2313e2602c8" ) then
		return
	end
	if data.item == sm.uuid.new( "edeea470-6eda-40ef-95e6-5d37a10bade5" ) then
		return
	end
	if data.item == sm.uuid.new( "40bf4cb9-e857-44de-89b8-0a42de20ebd5" ) then
		return
	end
	if data.item == sm.uuid.new( "cadac9b3-8b3b-4b8e-a50a-f1f23f47a7fc" ) then
		return
	end
	if data.item == sm.uuid.new( "4bec43af-809c-4e01-a249-72ce8184f430" ) then
		return
	end
	if data.item == sm.uuid.new( "41936190-31bf-4cbd-93b4-8e7f2ac2f9c3" ) then
		return
	end
	if data.item == sm.uuid.new( "df1dacba-9905-4dce-aacc-16a1e3c2aef1" ) then
		return
	end
	if data.item == weapon_fant_watergun then
		return
	end
	if data.item == weapon_fant_handheld_flamethrower then
		return
	end
	if data.item == sm.uuid.new( "c9d61b8a-b116-41d5-9f95-77a87e4fcff7" ) then
		return
	end
	
	
	self.cl.pipeEffectPlayer:pushShapeEffectTask( data.shapesOnContainerPath, data.item )
	self:cl_setOverrideUvIndexFrame( data.shapesOnContainerPath, PipeState.valid )
	self:cl_setPoseAnimTask( "incomingFire" )
end

function Fant_Toilet.cl_setPoseAnimTask( self, name )
	self.cl.poseAnimTask = { name = name, progress = 0 }
end


