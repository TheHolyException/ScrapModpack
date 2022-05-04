dofile "$SURVIVAL_DATA/Scripts/game/survival_units.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/character/straw_dog/fant_straw_dog.lua"
dofile "$SURVIVAL_DATA/Objects/00fant/character/fant_beebot/fant_beebot.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"
dofile "$SURVIVAL_DATA/Scripts/game/SurvivalGame.lua" 
dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_unitfacer_target.lua"
dofile "$SURVIVAL_DATA/Scripts/game/harvestable/LootHarvestable.lua" 

Fant_Unitfacer = class()
Fant_Unitfacer.maxParentCount = 255
Fant_Unitfacer.maxChildCount = 255
Fant_Unitfacer.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.electricity
Fant_Unitfacer.connectionOutput = sm.interactable.connectionType.bearing + sm.interactable.connectionType.logic
Fant_Unitfacer.SliderSteps = 1000
Fant_Unitfacer.Impulse = 2500
Fant_Unitfacer.EnergyConsumeRate = 1/90
Fant_Unitfacer.colorNormal = sm.color.new( 0xffa500ff )
Fant_Unitfacer.colorHighlight = sm.color.new( 0xff4500ff )

g_Fant_Unitfacers = g_Fant_Unitfacers or {}

function set_g_Fant_Unitfacer_Data( self, data )
	local ID = self.shape:getId()
	g_Fant_Unitfacers[ID] = data
end 

function clear_g_Fant_Unitfacer_Data( self )
	local ID = self.shape:getId()
	local newList = {}
	for i, k in pairs( g_Fant_Unitfacers ) do
		if I ~= ID then
			table.insert( newList, k )
		end
	end
	g_Fant_Unitfacers = newList
end

function g_add_Tree( Tree )
	if Tree == nil then
		return
	end
	if Tree.harvestable ~= nil then
		Trees[ sm.harvestable.getId( Tree.harvestable ) ] = Tree.harvestable
	end 
	if Tree.shape ~= nil then
		Trees[ sm.shape.getId( Tree.shape ) ] = Tree.shape
	end 
end

function g_remove_Tree( Tree )
	if Tree == nil then
		return
	end
	local id = -1
	if Tree.harvestable ~= nil then
		id = sm.harvestable.getId( Tree.harvestable )
	end 
	if Tree.shape ~= nil then
		id = sm.shape.getId( Tree.shape )
	end 
	Trees[ id ] = nil
	local newList = {}
	for i, k in pairs( Trees ) do
		if k ~= nil then
			newList[ i ] = k
		end
	end
	Trees = newList
end

function g_add_Rock( Rock )
	if Rock == nil then
		return
	end	
	if Rock.harvestable ~= nil then
		Rocks[ sm.harvestable.getId( Rock.harvestable ) ] = Rock.harvestable
	end 
	if Rock.shape ~= nil then
		Rocks[ sm.shape.getId( Rock.shape ) ] = Rock.shape
	end 
end

function g_remove_Rock( Rock )
	if Rock == nil then
		return
	end
	local id = -1
	if Rock.harvestable ~= nil then
		id = sm.harvestable.getId( Rock.harvestable )
	end 
	if Rock.shape ~= nil then
		id = sm.shape.getId( Rock.shape )
	end 
	Rocks[ id ] = nil
	local newList = {}
	for i, k in pairs( Rocks ) do
		if k ~= nil then
			newList[ i ] = k
		end
	end
	Rocks = newList
end

function g_add_Rod( Rod )
	if Rod == nil then
		return
	end
	if Rod.shape == nil then
		return
	end 
	local id = sm.shape.getId( Rod.shape )
	Rods[ id ] = Rod
end

function g_remove_Rod( Rod )
	if Rod == nil then
		return
	end
	if Rod.shape == nil then
		return
	end 
	local id = sm.shape.getId( Rod.shape )
	Rods[ id ] = nil
	local newList = {}
	for i, k in pairs( Rods ) do
		if k ~= nil then
			newList[ i ] = k
		end
	end
	Rods = newList
end

function g_add_Empty_Soil( soil )
	if soil == nil then
		return
	end
	if soil.harvestable == nil then
		return
	end 
	local id = sm.harvestable.getId( soil.harvestable )
	Empty_Soils[ id ] = soil
end

function g_remove_Empty_Soil( soil )
	if soil == nil then
		return
	end
	if soil.harvestable == nil then
		return
	end 
	local id = sm.harvestable.getId( soil.harvestable )
	Empty_Soils[ id ] = nil
	local newList = {}
	for i, k in pairs( Empty_Soils ) do
		if k ~= nil then
			newList[ i ] = k
		end
	end
	Empty_Soils = newList
end

function g_add_Growing_Soil( soil )
	if soil == nil then
		return
	end
	if soil.harvestable == nil then
		return
	end 
	local id = sm.harvestable.getId( soil.harvestable )
	Growing_Soils[ id ] = soil
end

function g_remove_Growing_Soil( soil )
	if soil == nil then
		return
	end
	if soil.harvestable == nil then
		return
	end 
	local id = sm.harvestable.getId( soil.harvestable )
	Growing_Soils[ id ] = nil
	local newList = {}
	for i, k in pairs( Growing_Soils ) do
		if k ~= nil then
			newList[ i ] = k
		end
	end
	Growing_Soils = newList
end

function g_add_Finish_Soil( soil )
	if soil == nil then
		return
	end
	if soil.harvestable == nil then
		return
	end 
	local id = sm.harvestable.getId( soil.harvestable )
	Finish_Soils[ id ] = soil
end

function g_remove_Finish_Soil( soil )
	if soil == nil then
		return
	end
	if soil.harvestable == nil then
		return
	end 
	local id = sm.harvestable.getId( soil.harvestable )
	Finish_Soils[ id ] = nil
	local newList = {}
	for i, k in pairs( Finish_Soils ) do
		if k ~= nil then
			newList[ i ] = k
		end
	end
	Finish_Soils = newList
end

GrownPlants = {
	hvs_mature_blueberry,
	hvs_mature_banana,
	hvs_mature_redbeet,
	hvs_mature_carrot,
	hvs_mature_tomato,
	hvs_mature_orange,
	hvs_mature_potato,
	hvs_mature_pineapple,
	hvs_mature_broccoli,
	hvs_mature_cotton,
	hvs_mature_eggplant
}

function Fant_Unitfacer.InitColorModes( self )
	self.ColorModes = {}
	--DEFAULT
	self.ColorModes["df7f01ff"] = {
		name = "robots",
		unitFilter = {
			unit_tapebot,
			unit_tapebot_taped_1,
			unit_tapebot_taped_2,
			unit_tapebot_taped_3,
			unit_tapebot_red,
			unit_totebot_green,
			unit_haybot,
			unit_farmbot,
			unit_totebot_red,
			unit_totebot_blue,
			unit_heavy_haybot
		},
		customEnemySearch = true
	}

	--WHITE
	self.ColorModes["eeeeeeff"] = {
		name = "all",
		unitFilter = {
			unit_tapebot,
			unit_tapebot_taped_1,
			unit_tapebot_taped_2,
			unit_tapebot_taped_3,
			unit_tapebot_red,
			unit_totebot_green,
			unit_haybot,
			unit_farmbot,
			unit_woc,
			unit_worm,
			unit_mechanic,
			unit_totebot_red,
			unit_totebot_blue,
			unit_heavy_haybot,
			unit_fant_gary,
			unit_babywoc
		},
		customEnemySearch = true
	}

	--BLUE
	self.ColorModes["0a3ee2ff"] = {
		name = "wocsandglowbugs",
		unitFilter = {
			unit_woc,
			unit_worm
		},
		customEnemySearch = false
	}
	
	--RED
	self.ColorModes["d02525ff"] = {
		name = "player",
		unitFilter = {
			unit_mechanic
		},
		customEnemySearch = false
	}
	
	--YELLOW "e2db13ff"
	self.ColorModes["e2db13ff"] = {
		name = "allUnits",
		unitFilter = {
			unit_tapebot,
			unit_tapebot_taped_1,
			unit_tapebot_taped_2,
			unit_tapebot_taped_3,
			unit_tapebot_red,
			unit_totebot_green,
			unit_haybot,
			unit_farmbot,
			unit_woc,
			unit_worm,
			unit_totebot_red,
			unit_totebot_blue,
			unit_heavy_haybot
		},
		customEnemySearch = true
	}
	
	--BLACK
	self.ColorModes["222222ff"] = {
		name = "otherplayers",
		unitFilter = {
			unit_mechanic
		},
		customEnemySearch = false
	}
	
	--PURPLE
	self.ColorModes["7514edff"] = {
		name = "owneraimdirection",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--GREEN
	self.ColorModes["19e753ff"] = {
		name = "soils",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--LIGHT BLUE
	self.ColorModes["7eededff"] = {
		name = "soilswithoutwater",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--PINK
	self.ColorModes["cf11d2ff"] = {
		name = "owneraimposition",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--DARKEST GREEN
	self.ColorModes["064023ff"] = {
		name = "soilwithgrownplants",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--LIGHT YELLOW
	self.ColorModes["f5f071ff"] = {
		name = "trees",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--LIGHT ORANGE
	self.ColorModes["eeaf5cff"] = {
		name = "rocks",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--LIGHT GREEN
	self.ColorModes["68ff88ff"] = {
		name = "rods",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--LIGHT Gray
	self.ColorModes["7f7f7fff"] = {
		name = "waypoint",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--BRAUNE
	self.ColorModes["472800ff"] = {
		name = "blocktarget",
		unitFilter = {},
		customEnemySearch = false
	}
	
	--Dark Gray
	self.ColorModes["4a4a4aff"] = {
		name = "itemtarget",
		unitFilter = {},
		customEnemySearch = false
	}
end

function Fant_Unitfacer.server_onCreate( self )
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { energy = 0, playername = "", publicData = nil, slider = self.SliderSteps }
	end
	
	self.container = self.shape.interactable:getContainer( 0 )
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 10 )
	end
	self.container:setFilters( { obj_consumable_battery } )
	
	
	self.publicData = self.saved.publicData
	if self.publicData ~= {} and self.publicData ~= nil then
		sm.interactable.setPublicData( sm.shape.getInteractable( self.shape ), self.publicData )
	end
	self.WaypointIndex = 0
	self.CurrentWaypoint = nil
	
	self.slider = self.saved.slider
	if self.slider == nil then
		self.slider = self.SliderSteps
	end
	self.network:sendToClients( "cl_setSlider", self.slider )	
	
	self.playername = self.saved.playername
	self.energy = self.saved.energy or 0
	self.bearingHorizontal = nil
	self.bearingVertical = nil
	self.DefaultColor = sm.shape.getColor( self.shape )
	self.lastcolor = ""
	self.joints = 0
	self.soilSearchTimer = 0
	self.LastSeatedPlayer = nil
	self.LastOutputLogicActive = false
	self:InitColorModes()
	
	if self.playername ~= "" then
		local players = sm.player.getAllPlayers()
		for index, player in pairs( players ) do
			if player.name == self.playername then
				self.LastSeatedPlayer = player.character
				break
			end
		end	
	else 
		local allplayer = sm.player.getAllPlayers()
		local lastPlayer = allplayer[1]
		for i, nextPlayer in pairs( allplayer ) do
			local Distance1 = sm.vec3.length( lastPlayer.character.worldPosition - self.shape.worldPosition )
			local Distance2 = sm.vec3.length( nextPlayer.character.worldPosition - self.shape.worldPosition )
			if Distance1 <= Distance2 then
				lastPlayer = nextPlayer
			end
		end
		self:sv_setOwner( { player = lastPlayer.character, playername = lastPlayer.name } )
	end
	
	self.color = tostring( sm.shape.getColor( self.shape ) )
	if self.color ~= self.lastcolor then
		self.lastcolor = self.color
		local ModeName = "None"
		if self.ColorModes[self.color] ~= nil then
			ModeName = self.ColorModes[self.color].name
		end
	end
	
	set_g_Fant_Unitfacer_Data( self, { left = false, right = false, up = false, down = false } )
	
	self.network:sendToClients( "cl_setOwner", { player = self.LastSeatedPlayer, playername = self.playername } )
	
	self.storage:save( self.saved )
end

function Fant_Unitfacer.server_onDestroy( self )	
	self.saved = { energy = self.energy, playername = self.playername, publicData = self.publicData, slider = self.slider }
	self.storage:save( self.saved )
	clear_g_Fant_Unitfacer_Data( self )
end

function Fant_Unitfacer.client_onCreate( self )
	self.slider = self.slider or self.SliderSteps 
	self.network:sendToServer( "sv_getSlider" )
end

function Fant_Unitfacer.sv_getSlider( self, slider )
	self.network:sendToClients( "cl_setSlider", self.slider )	
end

function Fant_Unitfacer.getParentInputs( self )
	local Active = false
	local BatteryContainer = nil
	local color = self.DefaultColor
	local ActiveInputCount = 0
	for i, parent in pairs( self.interactable:getParents() ) do
		if parent:hasOutputType( sm.interactable.connectionType.logic ) then
			if parent.active then			
				Active = true
				color = sm.shape.getColor( parent.shape ) 
				ActiveInputCount = ActiveInputCount + 1
			end
		end
		if parent:hasOutputType( sm.interactable.connectionType.electricity ) and BatteryContainer == nil then
			BatteryContainer = parent:getContainer( 0 )
		end
	end
	if ActiveInputCount > 1 then
		Active = false
	end
	return Active, BatteryContainer, color
end

function Fant_Unitfacer.server_onFixedUpdate( self, dt )
	if not sm.isHost then
		return
	end
	local isActive, BatteryContainer, Color = self:getParentInputs()
	local unitPosition = sm.vec3.new( 0, 0, 0 )
	local SpinLeftRight = 0 --bearingVertical
	local SpinUpDown = 0 --bearingHorizontal
	local joints = self.interactable:getJoints()
	local OutputLogicActive = false
	self.color = tostring( Color )
	if self.ColorModes ~= nil then
		if self.ColorModes[self.color] ~= nil then
			if self.ColorModes[self.color].name ~= nil then
				if self.ColorModes[self.color].name == "waypoint" then
					if self.WaypointIndex > 0 and not isActive then
						self.WaypointIndex = 0
						self.CurrentWaypoint = nil
					end
					if self.WaypointIndex <= 0 and isActive then
						self:getClosestWaypoint()	
					end
				end
			end
		end
	end
	local publicData = sm.interactable.getPublicData( sm.shape.getInteractable( self.shape ) )

	if publicData ~= nil then
		if self.publicData ~= publicData then
			self.publicData = publicData
			self.saved = { energy = self.energy, playername = self.playername, publicData = self.publicData }
			self.storage:save( self.saved )
			self.WaypointIndex = 0
			self.CurrentWaypoint = nil
			self:getClosestWaypoint()
		end
	end
	
	--if #joints ~= self.joints then
		--self.joints = #joints
		for _, joint in ipairs( joints ) do
			if joint:getType() == "bearing" then
				if tostring( sm.joint.getColor( joint ) ) == "df7f01ff" then
					self.bearingHorizontal = joint
				else
					self.bearingVertical = joint
				end
			end
		end
	--end
	
	if self.soilSearchTimer > 0 then
		self.soilSearchTimer = self.soilSearchTimer - dt
	end
	
	--if self.shape:getBody():hasChanged( sm.game.getCurrentTick() - 1 ) then
		--self.color = tostring( sm.shape.getColor( self.shape ) )
		if self.color ~= self.lastcolor then
			self.lastcolor = self.color
			--print( self.color )
			local ModeName = "None"
			if self.ColorModes[self.color] ~= nil then
				ModeName = self.ColorModes[self.color].name
			end
			--print( "Mode Change: ", ModeName )
			self.network:sendToClients( "cl_HudPrint", "Color: " .. ModeName .. " - " .. self.color )
			self.blockTarget = nil
			self.ClosestSoil = nil	
		end
	--end
	local consumeMultiplayer = #joints
	
	local GyroUpDown = nil
	local GyroLeftRight = nil
	for i, child in pairs( self.interactable:getChildren() ) do
		if child.shape:getShapeUuid() == obj_interactive_fant_gyroscope then
			if tostring( sm.shape.getColor( child.shape ) ) ~= "df7f01ff" then
				GyroUpDown = child
			else
				GyroLeftRight = child
			end
			consumeMultiplayer = consumeMultiplayer + 1
		end
		if child.shape:getShapeUuid() == obj_interactive_fant_gyroscope3x3 then
			if tostring( sm.shape.getColor( child.shape ) ) ~= "df7f01ff" then
				GyroUpDown = child
			else
				GyroLeftRight = child
			end
			consumeMultiplayer = consumeMultiplayer + 1
		end
	end

	if isActive then
		if self.ColorModes[self.color] == nil or self.ColorModes[self.color].unitFilter == nil then
			self:InitColorModes()
			return
		end
		local allunits = sm.unit.getAllUnits()
		for i, ply in pairs( sm.player.getAllPlayers( ) ) do
			table.insert( allunits, ply )
		end
		local clostestUnit = nil
		local clostestStrawdog = nil
		local isShape = false
		if self.ColorModes[self.color].name ~= "otherplayers" then
			if self.ColorModes[self.color].name ~= "robots" or self.ColorModes[self.color].name ~= "all" or self.ColorModes[self.color].name ~= "wocsandglowbugs" or self.ColorModes[self.color].name ~= "player" or self.ColorModes[self.color].name ~= "allUnits" then
				if allunits ~= {} and self.ColorModes[self.color].unitFilter ~= {} then
					for i, unit in pairs( allunits ) do
						if unit ~= nil then
							if unit.character ~= nil then
								if not unit.character:isTumbling() then
									if self.ColorModes[self.color].unitFilter == nil then
									else
										for i, filterunit in pairs( self.ColorModes[self.color].unitFilter ) do
											if filterunit == unit.character:getCharacterType() then
												if clostestUnit == nil then
													clostestUnit = unit
												end
												local newUnitDistance = sm.vec3.length( unit.character.worldPosition - self.shape.worldPosition )
												local OldUnitDistance = sm.vec3.length( clostestUnit.character.worldPosition - self.shape.worldPosition )
												if newUnitDistance <= OldUnitDistance then
													clostestUnit = unit										
												end
												break
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
		
		if self.ColorModes[self.color].customEnemySearch and g_strawdogs ~= {} then
			local newList = {}
			for i, k in pairs( g_strawdogs ) do
				newList[i] = k
			end
			for i, k in pairs( g_Beebots ) do
				newList[i] = k
			end
			for i, strawdog in pairs( newList ) do
				if strawdog ~= nil and sm.exists( strawdog ) then
					if clostestStrawdog == nil then
						clostestStrawdog = strawdog
					end
					local newUnitDistance = sm.vec3.length( strawdog.worldPosition - self.shape.worldPosition )
					local OldUnitDistance = sm.vec3.length( clostestStrawdog.worldPosition - self.shape.worldPosition )
					if newUnitDistance <= OldUnitDistance then
						clostestStrawdog = strawdog
						isShape = true
						if clostestUnit ~= nil then
							if newUnitDistance > sm.vec3.length( clostestUnit.character.worldPosition - self.shape.worldPosition ) then
								isShape = false
							end
						end
					end
				end
			end
		end	
		
		if self.ColorModes[self.color].name == "otherplayers" then
			if self.LastSeatedPlayer ~= nil then
				if allunits ~= {} and self.ColorModes[self.color].unitFilter ~= {} then
					for i, unit in pairs( allunits ) do
						if self.ColorModes[self.color].unitFilter ~= nil then
							for i, filterunit in pairs( self.ColorModes[self.color].unitFilter ) do										
								if filterunit == unit.character:getCharacterType() then		
									local isOwner = self.LastSeatedPlayer == unit.character
									if isOwner == false then	
										if clostestUnit == nil then
											clostestUnit = unit
										end									
										local newUnitDistance = sm.vec3.length( unit.character.worldPosition - self.shape.worldPosition )
										local OldUnitDistance = sm.vec3.length( clostestUnit.character.worldPosition - self.shape.worldPosition )
										if newUnitDistance <= OldUnitDistance then
											clostestUnit = unit
											break
										end									
										
									end
								end
							end
						end
					end
				end		
			end
			if clostestUnit == nil then
				self.ClosestSoil = nil
				clostestUnit = nil
			end
		end
		
		local TempAimPos = nil
		if self.ColorModes[self.color].name == "owneraimdirection" then
			if self.LastSeatedPlayer ~= nil then				
				local AimPos = self.shape.worldPosition + ( self.LastSeatedPlayer:getDirection() * 100 )
				local RelativeAimPos = sm.vec3.normalize( self.shape:transformPoint( AimPos ) )
				SpinUpDown = RelativeAimPos.x * ( 1 + math.abs( RelativeAimPos.x ) ) * 10
				SpinLeftRight = -RelativeAimPos.y * ( 1 + math.abs( RelativeAimPos.y ) ) * 10
			end
		end
		
		if self.ColorModes[self.color].name == "owneraimposition" then
			if self.LastSeatedPlayer ~= nil then
				local RayStart = self.LastSeatedPlayer.worldPosition + sm.vec3.new( 0, 0, 0.6 )
				local RayStop = RayStart + ( self.LastSeatedPlayer:getDirection() * 100 )
				local valid, result = sm.physics.raycast( RayStart, RayStop, self.LastSeatedPlayer )
				local AimPos = self.shape.worldPosition
				if result then
					AimPos = result.pointWorld
				end
				if AimPos == sm.vec3.new( 0, 0, 0 ) then
					AimPos = self.shape.worldPosition + ( self.LastSeatedPlayer:getDirection() * 100 )
				end
				TempAimPos = AimPos
				local RelativeAimPos = sm.vec3.normalize( self.shape:transformPoint( AimPos ) )
				SpinUpDown = RelativeAimPos.x * ( 1 + math.abs( RelativeAimPos.x ) ) * 10
				SpinLeftRight = -RelativeAimPos.y * ( 1 + math.abs( RelativeAimPos.y ) ) * 10
			end
		end
		
		if self.ColorModes[self.color].name == "soils" and self.soilSearchTimer <= 0 then
			self.ClosestSoil = nil	
			for _, result in pairs( Empty_Soils ) do	
				if result ~= nil and result.harvestable ~= nil and type( result.harvestable ) == "Harvestable" and result.harvestable:getType() == "farm" then				
					if self.ClosestSoil == nil then
						self.ClosestSoil = result.harvestable	
					end
					if self.ClosestSoil ~= nil then
						local NewPos = sm.vec3.length( sm.harvestable.getPosition( result.harvestable ) - self.shape.worldPosition )
						local OldPos = sm.vec3.length( sm.harvestable.getPosition( self.ClosestSoil ) - self.shape.worldPosition )
						if NewPos <= OldPos then						
							local SoilData = sm.harvestable.getPublicData( result.harvestable )
							if SoilData == nil then
								self.ClosestSoil = result.harvestable	
							end
						end
					end
				end
			end
			if self.ClosestSoil ~= nil and sm.exists( self.ClosestSoil ) then
				local SoilData = sm.harvestable.getPublicData( self.ClosestSoil )
				if SoilData ~= nil then
					self.ClosestSoil = nil	
				end
			end
			self.soilSearchTimer = 0.5
			
			
		end
		  
		if self.ColorModes[self.color].name == "soilswithoutwater" and self.soilSearchTimer <= 0  then
			--print( "soilswithoutwater" )
			self.ClosestSoil = nil	
			local SoilResult = nil
			for _, result in pairs( Growing_Soils ) do
				if result ~= nil and result.harvestable ~= nil and type( result.harvestable ) == "Harvestable" and result.harvestable:getType() == "farm"  then
					if self.ClosestSoil == nil or SoilResult == nil then
						self.ClosestSoil = result.harvestable	
					end			
					if self.ClosestSoil ~= nil then
						local NewPos = sm.vec3.length( sm.harvestable.getPosition( result.harvestable ) - self.shape.worldPosition )
						local OldPos = sm.vec3.length( sm.harvestable.getPosition( self.ClosestSoil ) - self.shape.worldPosition )
						if NewPos <= OldPos + 0.1 then						
							local SoilData = sm.harvestable.getPublicData( result.harvestable )
							if SoilData ~= nil  then
								if result.sv.waterTicks <= 0 and result.harvestable.uuid ~= hvs_soil then		
									SoilResult = result
									self.ClosestSoil = result.harvestable									
								end
							end
						end
					end
				end
			end
			
			if SoilResult == nil then
				for _, result in pairs( Empty_Soils ) do
					if result ~= nil and result.harvestable ~= nil and type( result.harvestable ) == "Harvestable" and result.harvestable:getType() == "farm"  then
						if self.ClosestSoil == nil or SoilResult == nil then
							self.ClosestSoil = result.harvestable	
						end			
						if self.ClosestSoil ~= nil then
							local NewPos = sm.vec3.length( sm.harvestable.getPosition( result.harvestable ) - self.shape.worldPosition )
							local OldPos = sm.vec3.length( sm.harvestable.getPosition( self.ClosestSoil ) - self.shape.worldPosition )
							if NewPos <= OldPos + 0.1 then		
								if result.sv.waterTicks ~= nil then
									if result.sv.waterTicks <= 1 then
										SoilResult = result
										self.ClosestSoil = result.harvestable	
									end
								end
							end
						end
					end
				end
			end
			
			
			if self.ClosestSoil ~= nil and sm.exists( self.ClosestSoil )  then
				if SoilResult ~= nil then
					if SoilResult.sv.waterTicks > 0 then
						self.ClosestSoil = nil	
					end
				else
					self.ClosestSoil = nil	
				end
			end	
			self.soilSearchTimer = 0.5
			--print( self.ClosestSoil )
		end
		
		if self.ColorModes[self.color].name == "soilwithgrownplants" and self.soilSearchTimer <= 0  then
			self.ClosestSoil = nil	
			for _, result in pairs( Finish_Soils ) do
				if result ~= nil and result.harvestable ~= nil and type( result.harvestable ) == "Harvestable" and result.harvestable:getType() == "mature"  then
					if self.ClosestSoil == nil then
						self.ClosestSoil = result.harvestable	
					end
					if self.ClosestSoil ~= nil then
						local NewPos = sm.vec3.length( sm.harvestable.getPosition( result.harvestable ) - self.shape.worldPosition )
						local OldPos = sm.vec3.length( sm.harvestable.getPosition( self.ClosestSoil ) - self.shape.worldPosition )
						if NewPos <= OldPos then						
							for _, plant in ipairs( GrownPlants ) do
								if self.ClosestSoil.uuid ~= nil and self.ClosestSoil.uuid == plant then
									self.ClosestSoil = result.harvestable	
									break
								end
							end
						end
					end
				end
			end
			if self.ClosestSoil == nil or not sm.exists( self.ClosestSoil ) then
				self.ClosestSoil = nil	
			end	
			self.soilSearchTimer = 0.5
		end

		if self.ColorModes[self.color].name == "trees" and self.soilSearchTimer <= 0 then
			local tree = nil	
			for _, result in pairs( Trees ) do
				if result ~= nil then
					if tree == nil then
						tree = result
					end					
					if tree ~= nil then
						local NewPos = sm.vec3.length( result.worldPosition - self.shape.worldPosition )
						local OldPos = sm.vec3.length( tree.worldPosition - self.shape.worldPosition )
						if NewPos <= OldPos then						
							tree = result	
						end
					end
				end
			end
			self.ClosestSoil = tree
			self.soilSearchTimer = 0.5
		end
		
		if self.ColorModes[self.color].name == "rocks" and self.soilSearchTimer <= 0 then
			local rock = nil	
			for _, result in pairs( Rocks ) do
				if result ~= nil then
					if rock == nil then
						rock = result
					end					
					if rock ~= nil then
						local NewPos = sm.vec3.length( result.worldPosition - self.shape.worldPosition )
						local OldPos = sm.vec3.length( rock.worldPosition - self.shape.worldPosition )
						if NewPos <= OldPos then						
							rock = result	
						end
					end
				end
			end
			self.ClosestSoil = rock
			self.soilSearchTimer = 0.5
		end
		
		if self.ColorModes[self.color].name == "rods" and self.soilSearchTimer <= 0 then
			local rod = nil	
			for _, result in pairs( Rods ) do
				if result ~= nil and sm.exists( result.shape ) then
					if rod == nil then
						rod = result.shape
					end
					if rod ~= nil then
						local NewPos = sm.vec3.length( result.shape.worldPosition - self.shape.worldPosition )
						local OldPos = sm.vec3.length( rod.worldPosition - self.shape.worldPosition )
						if NewPos <= OldPos then						
							rod = result.shape	
						end
					end
				end
			end
			self.ClosestSoil = rod
			self.soilSearchTimer = 0.5
		end
		
		if self.ColorModes[self.color].name == "waypoint" and self.soilSearchTimer <= 0 then
			if self.publicData ~= nil and self.publicData ~= {} then
				if self.CurrentWaypoint == nil then
					self:getClosestWaypoint()			
				end
				if self.CurrentWaypoint ~= nil and self.WaypointIndex ~= nil then
					local SelfPos = self.shape.worldPosition
					SelfPos.z = 0
					local distance = sm.vec3.length( self.CurrentWaypoint - SelfPos )
					if distance <= 2 then
						self.WaypointIndex = self.WaypointIndex + 1
						if self.WaypointIndex > #self.publicData then
							self.WaypointIndex = 1
						end
						if self.WaypointIndex ~= nil and self.publicData[ self.WaypointIndex ] ~= nil then
							local TNewPos = sm.vec3.new( self.publicData[ self.WaypointIndex ].x, self.publicData[ self.WaypointIndex ].y, self.publicData[ self.WaypointIndex ].z )
							TNewPos.z = 0
							self.CurrentWaypoint = TNewPos		
						end
					end				
				end			
				self.soilSearchTimer = 0.5
			end
		end

		if self.ColorModes[self.color].name == "waypoint" and self.CurrentWaypoint ~= nil then
			local TNewPos = sm.vec3.new( self.CurrentWaypoint.x, self.CurrentWaypoint.y, self.shape.worldPosition.z )
			local RelativeAimPos = sm.vec3.normalize( self.shape:transformPoint( TNewPos ) ) 
			local RelPos = self.shape:transformPoint( TNewPos )
			SpinUpDown = RelativeAimPos.x * ( 1 + math.abs( RelativeAimPos.x ) ) * 10
			SpinLeftRight = -RelativeAimPos.y * ( 1 + math.abs( RelativeAimPos.y ) ) * 10

			if RelPos.z > 1 and math.abs( SpinLeftRight ) < 0.001 then
				SpinLeftRight = math.random( -20, 20 )
				SpinUpDown = math.random( -20, 20 )
			end

			local SelfPos = self.shape.worldPosition
			SelfPos.z = 0
			local distance = sm.vec3.length( self.CurrentWaypoint - SelfPos )
			if distance > 2 and RelativeAimPos.z <= 1 then
				OutputLogicActive = true
			end				
		end
		
		if self.ColorModes[self.color].name == "blocktarget" and self.soilSearchTimer <= 0 then
			self.soilSearchTimer = 0.5
			if g_Fant_Unitfacer_Target ~= nil and g_Fant_Unitfacer_Target ~= {} then

				local prevTarget = nil
				for i, nextTarget in pairs( g_Fant_Unitfacer_Target ) do
					if prevTarget == nil then
						prevTarget = nextTarget
					end
					if prevTarget ~= nil and nextTarget ~= nil then
						local distance1 = sm.vec3.length( prevTarget.worldPosition - self.shape.worldPosition )
						local distance2 = sm.vec3.length( nextTarget.worldPosition - self.shape.worldPosition )
						if distance2 <= distance1 then
							prevTarget = nextTarget
						end
					end
				end
				self.blockTarget = prevTarget
			end
		end
		if self.ColorModes[self.color].name == "blocktarget" and self.blockTarget ~= nil then
			if sm.exists( self.blockTarget ) and sm.exists( self.shape ) then
				local RelativeAimPos = sm.vec3.normalize( self.shape:transformPoint( self.blockTarget.worldPosition ) ) 
				local RelPos = self.shape:transformPoint( self.blockTarget.worldPosition )
				SpinUpDown = RelativeAimPos.x * ( 1 + math.abs( RelativeAimPos.x ) ) * 10
				SpinLeftRight = -RelativeAimPos.y * ( 1 + math.abs( RelativeAimPos.y ) ) * 10

				if RelPos.z > 1 and math.abs( SpinLeftRight ) < 0.001 then
					SpinLeftRight = math.random( -20, 20 )
					SpinUpDown = math.random( -20, 20 )
				end
				
				local targetDistance = sm.vec3.length( self.shape.worldPosition - self.blockTarget.worldPosition ) * 4				
				if targetDistance > self.slider then
					OutputLogicActive = false
				else
					OutputLogicActive = true
				end
				
			end			
		end
		
		
		
		if self.ColorModes[self.color].name == "itemtarget" and self.soilSearchTimer <= 0 then
			self.soilSearchTimer = 0.5
			if g_lootHarvestables ~= nil and g_lootHarvestables ~= {} then

				local prevTarget = nil
				for i, nextTarget in pairs( g_lootHarvestables ) do

					if prevTarget == nil then
						prevTarget = nextTarget
					end
					if prevTarget ~= nil and nextTarget ~= nil and sm.exists( prevTarget.harvestable ) and sm.exists( nextTarget.harvestable ) then
						local distance1 = sm.vec3.length( prevTarget.harvestable:getPosition() - self.shape.worldPosition )
						local distance2 = sm.vec3.length( nextTarget.harvestable:getPosition() - self.shape.worldPosition )
						if distance2 <= distance1 then
							prevTarget = nextTarget
						end
					end
				end
				if prevTarget ~= nil and sm.exists( prevTarget.harvestable ) then
					
					--print ( self.itemtarget )
					
					local targetDistance = sm.vec3.length( self.shape.worldPosition - prevTarget.harvestable:getPosition() ) * 4				
					if targetDistance > self.slider then

					else
						self.itemtarget = prevTarget.harvestable
					end
				end
				
			end
		end 

		if self.ColorModes[self.color].name == "itemtarget" and self.itemtarget ~= nil then
			if sm.exists( self.itemtarget ) and sm.exists( self.shape ) then
				local RelativeAimPos = sm.vec3.normalize( self.shape:transformPoint( self.itemtarget:getPosition() ) ) 
				local RelPos = self.shape:transformPoint( self.itemtarget:getPosition() )
				SpinUpDown = RelativeAimPos.x * ( 1 + math.abs( RelativeAimPos.x ) ) * 10
				SpinLeftRight = -RelativeAimPos.y * ( 1 + math.abs( RelativeAimPos.y ) ) * 10

				if RelPos.z > 1 and math.abs( SpinLeftRight ) < 0.001 then
					SpinLeftRight = math.random( -20, 20 )
					SpinUpDown = math.random( -20, 20 )
				end

				local targetDistance = sm.vec3.length( self.shape.worldPosition - self.itemtarget:getPosition() ) * 4				
				if targetDistance > self.slider then
					OutputLogicActive = false
				else
					OutputLogicActive = true
				end
				
			end			
		end
		

		if self.ClosestSoil ~= nil and sm.exists( self.ClosestSoil ) and self.ColorModes[self.color].name ~= "owneraimdirection" and self.ColorModes[self.color].name ~= "owneraimposition" and self.ColorModes[self.color].name ~= "blocktarget" then	
			local RelativeAimPos = sm.vec3.normalize( self.shape:transformPoint( self.ClosestSoil.worldPosition ) ) 
			SpinUpDown = RelativeAimPos.x * ( 1 + math.abs( RelativeAimPos.x ) ) * 10
			SpinLeftRight = -RelativeAimPos.y * ( 1 + math.abs( RelativeAimPos.y ) ) * 10
			if RelativeAimPos.z > 1 then
				SpinUpDown = math.random( -2, 2 )
			end
			OutputLogicActive = true
			
		end
		if self.ColorModes[self.color].name ~= "soilswithoutwater" and self.ColorModes[self.color].name ~= "soils" and self.ColorModes[self.color].name ~= "soilwithgrownplants" then
			if clostestUnit ~= nil or clostestStrawdog ~= nil or self.ClosestSoil ~= nil or TempAimPos ~= nil or self.blockTarget ~= nil then
				local targetDistance = self.SliderSteps
				local offsetPosition = sm.vec3.new( 0, 0, 0 )
				if TempAimPos ~= nil then
					targetDistance = sm.vec3.length( self.shape.worldPosition - TempAimPos ) * 4
				end
				if isShape and clostestStrawdog then
					offsetPosition = offsetPosition + clostestStrawdog.worldPosition
					
					targetDistance = sm.vec3.length( self.shape.worldPosition - clostestStrawdog.worldPosition ) * 4
				end
				if not isShape and clostestUnit then
					local distance = sm.vec3.length( clostestUnit.character.worldPosition - self.shape.worldPosition )
					offsetPosition = offsetPosition + clostestUnit.character.worldPosition +  sm.vec3.new( 0, 0, 0.5 )
					offsetPosition = offsetPosition + ( clostestUnit.character.velocity * distance * 0.005 )
					
					targetDistance = sm.vec3.length( self.shape.worldPosition - clostestUnit.character.worldPosition ) * 4
				end
				if self.ClosestSoil ~= nil then
					if sm.exists( self.ClosestSoil ) and sm.exists( self.shape ) then
						targetDistance = sm.vec3.length( self.shape.worldPosition - self.ClosestSoil.worldPosition ) * 4
					end
				end
				if self.blockTarget ~= nil then
					if sm.exists( self.blockTarget ) and sm.exists( self.shape ) then
						targetDistance = sm.vec3.length( self.shape.worldPosition - self.blockTarget.worldPosition ) * 4
					end
				end

				if targetDistance > self.slider then
					SpinUpDown = 0
					SpinLeftRight = 0
					OutputLogicActive = false
				else
					if TempAimPos == nil and self.blockTarget == nil then
						if self.ColorModes[self.color].name ~= "rods" then
							if self.ColorModes[self.color].name ~= "trees" then
								if self.ColorModes[self.color].name ~= "rocks" then
									unitPosition = sm.vec3.normalize( self.shape:transformPoint( offsetPosition ) ) 
									SpinUpDown = unitPosition.x * ( 1 + math.abs( unitPosition.x ) ) * 10
									SpinLeftRight = -unitPosition.y * ( 1 + math.abs( unitPosition.y ) ) * 10
								end
							end
						end
					end
					OutputLogicActive = true
				end

			end
		end
	end
	
	--print( self.ClosestSoil )
	-- if self.ClosestSoil ~= nil and sm.exists( self.ClosestSoil ) then
		-- self.network:sendToClients( "testDisplay", self.ClosestSoil.worldPosition + sm.vec3.new( 0, 0, 1 ) )
	-- end
	
	if OutputLogicActive and sm.game.getEnableAmmoConsumption() then
		if BatteryContainer == nil and self.container == nil then
			if self.energy <= 0 then
				isActive = false
			end
		else
			if self.energy <= 0 then
				if BatteryContainer ~= nil and not sm.container.isEmpty( BatteryContainer ) then
					for slot = 0, sm.container.getSize( BatteryContainer ) - 1 do
						local batterie = BatteryContainer:getItem( slot )											
						if batterie then			
							if batterie.quantity >= 1 then
								sm.container.beginTransaction()
								sm.container.setItem( BatteryContainer, slot, obj_consumable_battery, batterie.quantity - 1 )
								if sm.container.endTransaction() then
									self.energy = 1
									break
								end
							end
						end
					end
				else
					if self.container then
						if not sm.container.isEmpty( self.container ) then
							sm.container.beginTransaction()
							sm.container.spend( self.container, obj_consumable_battery, 1 )
							if sm.container.endTransaction() then
								self.energy = 1
							end
						end
					end
				end
			end
			if self.energy > 0 then			
				self.energy = self.energy - ( dt * self.EnergyConsumeRate * ( 1 + ( consumeMultiplayer / 10 ) ) )
				if self.energy < 0 then
					self.energy = 0
				end
			else
				isActive = false
			end
		end
	end

	if self.LastOutputLogicActive ~= OutputLogicActive then
		self.LastOutputLogicActive = OutputLogicActive
		sm.interactable.setActive( self.interactable, OutputLogicActive )
	end
	
	-- if joints ~= nil then
		-- if #joints > 0 and isActive then
			-- if self.bearingHorizontal ~= nil and sm.exists( self.bearingHorizontal ) then
				-- self.bearingHorizontal:setMotorVelocity( SpinUpDown, self.Impulse )
			-- end
			-- if self.bearingVertical ~= nil and sm.exists( self.bearingVertical ) then
				-- self.bearingVertical:setMotorVelocity( SpinLeftRight, self.Impulse )
			-- end
		-- end
	-- end
	
	if isActive then
		if self.bearingHorizontal ~= nil and sm.exists( self.bearingHorizontal ) then
			self.bearingHorizontal:setMotorVelocity( SpinUpDown, self.Impulse )
		end
		if self.bearingVertical ~= nil and sm.exists( self.bearingVertical ) then
			self.bearingVertical:setMotorVelocity( SpinLeftRight, self.Impulse )
		end
	end
	
	
	local threshold = 0.5
	local left = false
	local right = false
	local up = false
	local down = false

	if SpinUpDown > threshold then
		left = false
		right = true
	elseif SpinUpDown < -threshold then
		left = true
		right = false
	end
	
	if SpinLeftRight > threshold then
		up = false
		down = true
	elseif SpinLeftRight < -threshold then
		up = true
		down = false
	end
	
	set_g_Fant_Unitfacer_Data( self, { left = left, right = right, up = up, down = down } )

	if not isActive then
		if self.bearingHorizontal ~= nil and sm.exists( self.bearingHorizontal ) then
			self.bearingHorizontal:setMotorVelocity( 0, self.Impulse )
		end
		if self.bearingVertical ~= nil and sm.exists( self.bearingVertical ) then
			self.bearingVertical:setMotorVelocity( 0, self.Impulse )
		end
		OutputLogicActive = false
	end

	if GyroUpDown then
		local data = sm.interactable.getPublicData( GyroUpDown )
		if data == nil then
			data = {}
		end
		data.value = ( SpinLeftRight * ( 1 + math.abs( SpinLeftRight / 25 ) ) ) / 20
		sm.interactable.setPublicData( GyroUpDown, data )
	end
	if GyroLeftRight then
		local data = sm.interactable.getPublicData( GyroLeftRight )
		if data == nil then
			data = {}
		end
		data.value = ( SpinUpDown * ( 1 +math.abs( SpinUpDown / 25 ) ) ) / 20
		sm.interactable.setPublicData( GyroLeftRight, data )
	end
end

local Testeffect = nil
function Fant_Unitfacer.testDisplay( self, pos )
	if Testeffect == nil then
		Testeffect = sm.effect.createEffect( "ShapeRenderable" )				
		Testeffect:setParameter( "uuid", sm.uuid.new("f7881097-9320-4667-b2ba-4101c72b8730") )
		Testeffect:setPosition( pos )	
		Testeffect:setRotation( self.shape.worldRotation )
		Testeffect:setScale( sm.vec3.new( 0.25, 0.25, 0.25 ) )
		Testeffect:start()
	else
		Testeffect:setPosition( pos )	
		Testeffect:setRotation( self.shape.worldRotation )
	end
end

function Fant_Unitfacer.getClosestWaypoint(self)
	if self.publicData ~= nil and self.publicData ~= {} then
		self.WaypointIndex = 1
		local SelfPos = self.shape.worldPosition
		SelfPos.z = 0				
		for i = 1, #self.publicData do		
			local Current = sm.vec3.new( self.publicData[ i ].x, self.publicData[ i ].y, self.publicData[ i ].z )
			Current.z = 0			
			local CurrentDist = sm.vec3.length( Current - SelfPos )
			local Last = sm.vec3.new( self.publicData[ self.WaypointIndex ].x, self.publicData[ self.WaypointIndex ].y, self.publicData[ self.WaypointIndex ].z )
			Last.z = 0			
			local LastDist = sm.vec3.length( Last - SelfPos )			
			if CurrentDist < LastDist then
				self.WaypointIndex = i	
				self.CurrentWaypoint = Current			
			end			
		end
		self.WaypointIndex = self.WaypointIndex + 1
		if self.WaypointIndex > #self.publicData then
			self.WaypointIndex = 1
		end
		if self.WaypointIndex ~= nil and self.publicData[ self.WaypointIndex ] ~= nil then
			local Current = sm.vec3.new( self.publicData[ self.WaypointIndex ].x, self.publicData[ self.WaypointIndex ].y, self.publicData[ self.WaypointIndex ].z )
			Current.z = 0	
			self.CurrentWaypoint = Current
		end
	else
		self.WaypointIndex = 0
		self.CurrentWaypoint = nil
	end
end

function Fant_Unitfacer.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Unit Facer Settings" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	local name = "none"
	if self.playername ~= nil then
		name = self.playername
	end
	sm.gui.setInteractionText( "", keyBindingText, "Set Owner" .. " - " .. name )
	return true
end

function Fant_Unitfacer.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Unit Facer" )
		self.gui:setText( "Interaction", "Distance" )	
		self.gui:setSliderData( "Setting",self.SliderSteps+1, self.slider )
		self.gui:setText( "SubTitle", "Distance: " .. tostring( self.slider ) )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setIconImage( "Icon", obj_interactive_fant_unitfacer )
		
		local batteryContainer = self.shape.interactable:getContainer( 0 )
		if batteryContainer then
			self.gui:setContainer( "Fuel", batteryContainer )
		end
		local isActive, BatteryContainer = self:getParentInputs()
		if BatteryContainer then
			self.gui:setVisible( "FuelContainer", true )
		end
		self.gui:setVisible( "BackgroundBattery", true )
		self.gui:setVisible( "FuelGrid", true )
		self.gui:open()
	end
end

function Fant_Unitfacer.client_onTinker( self, character, state )
	if state then
		if character == sm.localPlayer.getPlayer().character then
			self.network:sendToServer( "sv_setOwner", { player = character, playername = sm.localPlayer.getPlayer().name } )
		end
	end
end

function Fant_Unitfacer.sv_setOwner( self, data )
	self.LastSeatedPlayer = data.player
	self.playername = data.playername
	self.saved = { energy = self.energy, playername = self.playername, publicData = self.publicData, slider = self.slider }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_setOwner", data )
end

function Fant_Unitfacer.cl_setOwner( self, data )
	self.LastSeatedPlayer = data.player
	self.playername = data.playername
end

function Fant_Unitfacer.cl_onSliderChange( self, sliderName, sliderPos )
	self.slider = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "SubTitle", "Distance: " .. tostring( self.slider ) )
	end
	self.network:sendToServer( "sv_setSlider", self.slider )
end

function Fant_Unitfacer.sv_setSlider( self, slider )
	self.slider = slider
	self.saved = { slider = self.slider, energy = self.energy, playername = self.playername, publicData = self.publicData }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_setSlider", self.slider )	
end

function Fant_Unitfacer.cl_setSlider( self, slider )
	self.slider = slider
end

function Fant_Unitfacer.cl_HudPrint( self, text ) 
	sm.gui.displayAlertText( text, 2 )
end

