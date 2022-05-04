dofile( "$SURVIVAL_DATA/Scripts/game/survival_items.lua")

Fant_Miner = class()
Fant_Miner.TickRate = 5
Fant_Miner.TicksPerFuel = 12
Fant_Miner.Chance_To_Generate = 0.2
Fant_Miner.Chance_Stone_vs_metal = 0.8
Fant_Miner.Resouce_Found_Maximum_Stone = 3
Fant_Miner.Resouce_Found_Maximum_Metal = 2
Fant_Miner.poseWeightCount = 2
Fant_Miner.poseAnimationtime = 0
Fant_Miner.poseAnimationDirection = 1
Fant_Miner.poseAnimationSpeed = 0.1
Fant_Miner.maxChildCount = 255
Fant_Miner.connectionOutput = sm.interactable.connectionType.logic
Fant_Miner.maxParentCount = 2
Fant_Miner.connectionInput = sm.interactable.connectionType.gasoline + sm.interactable.connectionType.logic

local ModulesItems = {
	{ Uuid = obj_fant_upgradeModule_1, Productivity = 1.5, Speed = 1 },
	{ Uuid = obj_fant_upgradeModule_2, Productivity = 1, Speed = 2 }
}

function Fant_Miner.server_onCreate( self )	
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { fuelTicks = 0, Module = nil } 
		self.storage:save( self.sv.storage )
	end
	self.fuelTicks = self.sv.storage.fuelTicks or 0
	self.timer = 0
	self.cl_timer = 0
	self.onGround = self:groundcheck()
	self.MinerActive = false
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 30, 256 )
	end
	self.container:setFilters( { blk_scrapstone, blk_metal1 } )	
	
	local containerModule = self.shape:getInteractable():getContainer(1)
	if not containerModule then
		containerModule = self.shape:getInteractable():addContainer( 1, 1, 1 )
	end
	self.Module = self.sv.storage.Module
	
	if self.Module ~= nil and containerModule then
		sm.container.beginTransaction()
		sm.container.setItem( containerModule, 0, self.Module, 1 )
		if sm.container.endTransaction() then

		end
	end	

	self:GetData()
end

function Fant_Miner.server_onDestroy( self )
	--print( "Miner Unloaded")
	
	local data = {
		container = self.container,
		onGround = self.onGround,
		MinerActive = self.MinerActive,
		fuelTicks = self.fuelTicks
	}
	self.sv.storage = data
	self.storage:save( self.sv.storage )
end

function Fant_Miner.client_onDestroy( self )
	if self.drillEffect:isPlaying() == true then
		self.drillEffect:stop()
	end
	-- if self.stoneEffect:isPlaying() == true then
		-- self.stoneEffect:stop()
	-- end
end

function Fant_Miner.client_onCreate( self )
	self.network:sendToServer( "GetData" )
	if self:groundcheck() == false then
		sm.gui.displayAlertText( "Miner Must be Placed on Flat Terrain!", 2.5 )
	end
	self.drillEffect = sm.effect.createEffect( "Drill - StoneDrill", self.interactable )
	self.drillEffect:setParameter( "impact", 0 )
	self.drillEffect:setParameter( "velocity", 0.4 )
	
	-- self.stoneEffect = sm.effect.createEffect( "Stone - Stress" )
	-- self.stoneEffect:setPosition( self.shape.worldPosition )
	-- self.stoneEffect:setParameter( "size", 1 )
	-- self.stoneEffect:setParameter( "velocity_max_50", 25 )
	
	self.interactable:setAnimEnabled( "0_idle", true )	
	self.interactable:setAnimProgress( "0_idle", 0.01 )
end

function Fant_Miner.GetData( self )	
	local data = {
		container = self.container,
		onGround = self.onGround,
		MinerActive = self.MinerActive,
		fuelTicks = self.fuelTicks
	}
	self.sv.storage = data
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "SetData", data )	
end

function Fant_Miner.SetData( self, data )
	self.container = data.container
	self.onGround = data.onGround
	self.MinerActive = data.MinerActive
	self.fuelTicks = data.fuelTicks or 0
end

function Fant_Miner.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return true
end

function Fant_Miner.server_canErase( self )
	local container2 = self.shape.interactable:getContainer( 1 )
	if container2 and not container2:isEmpty() then	
		return false
	end
	return true
end

function Fant_Miner.client_canErase( self )
	local container2 = self.shape.interactable:getContainer( 1 )
	if container2 and not container2:isEmpty() then
		sm.gui.displayAlertText( "#ff0000Remove the Module befor you grab the Miner!", 1.5 )
		return false
	end
	return true
end

function Fant_Miner.client_onInteract( self, character, state)
	if state == true then
		self.gui = sm.gui.createContainerGui( true )
			
		self.gui:setText( "UpperName", "Miner Container" )
		self.gui:setContainer( "UpperGrid", self.container )	

		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		
		self.gui:open()			
	end
end

function Fant_Miner.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Miner" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Module" )
	return true
end

function Fant_Miner.client_onTinker( self, character, state )
	if state == true then 
		local gui = sm.gui.createContainerGui( true )
		gui:setText( "UpperName", "Miner Modules" )
		gui:setContainer( "UpperGrid",self.shape:getInteractable():getContainer(1) )
		gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		gui:open()
	end
end

function Fant_Miner.ModuleManager( self )
	local Module = nil
	for i, m in pairs( ModulesItems ) do
		if self.shape:getInteractable():getContainer(1):getItem( 0 ).uuid == m.Uuid then
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

function Fant_Miner.groundcheck( self )
	local RayStart = self.shape:getWorldPosition()
	local RayStop = self.shape:getWorldPosition() - sm.shape.getAt( self.shape ) * 3.6
	local Valid, Result = sm.physics.raycast( RayStart, RayStop, self.shape )
	if Valid then
		if Result.normalWorld.z >= 0.97 then
			if Result.type == "terrainSurface" then
				return true
			-- elseif Result.type == "terrainAsset" then
				-- return true
			end
		end
	end
	return false
end

function Fant_Miner.consumFuel( self, fuelcontainer )
	if self.fuelTicks == nil then
		self.fuelTicks = 0
	end
	if self.fuelTicks >= 1 then
		self.fuelTicks = self.fuelTicks - 1
	end
	if fuelcontainer ~= nil then
		if self.fuelTicks <= 0 then
			for slot = 0, fuelcontainer:getSize() - 1 do
				local FuelItem = fuelcontainer:getItem( slot )											
				if FuelItem then			
					if FuelItem.quantity >= 1 then
						sm.container.beginTransaction()
						sm.container.setItem( fuelcontainer, slot, obj_consumable_gas, FuelItem.quantity - 1 )
						if sm.container.endTransaction() then
							self.fuelTicks = self.TicksPerFuel
							break
						end
					end
				end
			end
		end
	end
	if self.fuelTicks >= 1 then
		return true
	end
	return false
end

function Fant_Miner.addResource( self, item, amount )
	if self.container ~= nil then
		sm.container.beginTransaction()
		sm.container.collect( self.container, item, amount, true)	
		if sm.container.endTransaction() then
			return true
		end
	end
	return false
end

function Fant_Miner.getInputs( self )
	local parents = self.interactable:getParents()
	local fuelContainer = nil
	local active = false
	if parents[2] then
		if parents[2]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[2]:isActive()
		end	
		if parents[2]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[2]:getContainer( 0 )
		end
	end
	if parents[1] then
		if parents[1]:hasOutputType( sm.interactable.connectionType.logic ) then
			active = parents[1]:isActive()
		end
		if parents[1]:hasOutputType( sm.interactable.connectionType.gasoline ) then
			fuelContainer = parents[1]:getContainer( 0 )
		end
	end
	return active, fuelContainer
end

function Fant_Miner.server_onFixedUpdate( self, dt )
	local speed, productivity =  self:ModuleManager()
	dt = dt * speed
	if self.timer < self.TickRate then
		self.timer = self.timer + dt
	else
		self.onGround = self:groundcheck()
		if not self.onGround then	
			if self.MinerActive then
				self.MinerActive = false
				hasChanged = true
				sm.interactable.setActive( self.interactable, self.MinerActive )
				self:GetData()		
			end
			return
		end
		self.timer = 0		
		local ActiveLogic, FuelContainer = self:getInputs( self )
		local hasChanged = false
		if ActiveLogic then 
			hasChanged = self:consumFuel( FuelContainer )		
		end		
		if self.MinerActive then
			if self.fuelTicks <= 0 then
				self.MinerActive = false
				hasChanged = true
				self.network:sendToClients( "client_OutOfFuel" )
			end
			if ActiveLogic == false then
				self.MinerActive = false
				hasChanged = true
			end
		else
			
			if self.fuelTicks >= 1 and ActiveLogic then
				self.MinerActive = true
				hasChanged = true
			end
		end
		if self.MinerActive then		
			if math.random( 0, 1 ) > self.Chance_To_Generate then
				local gathered = false
				if math.random( 0, 1 ) <= self.Chance_Stone_vs_metal then
					local foundAmount = math.random( 1, self.Resouce_Found_Maximum_Stone ) * productivity
					gathered = self:addResource( blk_scrapstone, foundAmount )
				else
					local foundAmount = math.random( 1, self.Resouce_Found_Maximum_Metal ) * productivity
					gathered = self:addResource( blk_metal1, foundAmount )
				end			
				if gathered then
					hasChanged = true
					--self.network:sendToClients( "playGatherEffect" )
				end
			end							
		end
		if hasChanged then
			sm.interactable.setActive( self.interactable, self.MinerActive )
			self:GetData()			
		end			
	end
end

function Fant_Miner.playGatherEffect( self )
	local worldPosition = sm.shape.getWorldPosition(self.shape) + ( self.shape.getAt(self.shape) * -1 )
	sm.effect.playEffect( "Stone - BreakChunk", worldPosition, nil, self.shape.worldRotation, nil, { size = 0.02 } )
end

function Fant_Miner.client_onUpdate( self, dt )
	if self.MinerActive then
		local speed, productivity =  self:ModuleManager()
		dt = dt * speed
	
		self.poseAnimationtime = self.poseAnimationtime + ( self.poseAnimationSpeed * self.poseAnimationDirection * dt )
		if self.poseAnimationtime > 1  then
			self.poseAnimationtime = 0
		end
		

		if self.drillEffect:isPlaying() == false then
			self.drillEffect:start()
		end
		-- if self.stoneEffect:isPlaying() == false then
			-- self.stoneEffect:start()
		-- end
		--self.shape:getInteractable():setPoseWeight( 0, self.poseAnimationtime )
		
		self.interactable:setAnimProgress( "0_idle", self.poseAnimationtime )
	else
		if self.drillEffect:isPlaying() == true then
			self.drillEffect:stop()
		end
		-- if self.stoneEffect:isPlaying() == true then
			-- self.stoneEffect:stop()
		-- end
	end		
end

function Fant_Miner.client_OutOfFuel( self ) 
	sm.gui.displayAlertText( "Miner Out of Fuel!", 2 )
	if self.drillEffect:isPlaying() == true then
		self.drillEffect:stop()
	end
	-- if self.stoneEffect:isPlaying() == true then
		-- self.stoneEffect:stop()
	-- end
end

