Fant_RobotDetector = class()
Fant_RobotDetector.poseWeightCount = 2	
Fant_RobotDetector.maxChildCount = 255
Fant_RobotDetector.connectionOutput = sm.interactable.connectionType.logic
Fant_RobotDetector.MaximalRange = 512

g_units = g_units or {}
cl_g_units = cl_g_units or {}
cl_guis = cl_guis or {}
g_robot_detector = g_robot_detector or {}
refresh = false

UnitData = {}
UnitData[ unit_tapebot ] =  "Tapebot"
UnitData[ unit_tapebot_taped_1 ] =  "Tapebot"
UnitData[ unit_tapebot_taped_2 ] =  "Tapebot"
UnitData[ unit_tapebot_taped_3 ] =  "Tapebot"
UnitData[ unit_tapebot_red ] =  "Tapebot"
UnitData[ unit_totebot_green ] =  "Totebot"
UnitData[ unit_haybot ] =  "Haybot"
UnitData[ unit_farmbot ] =  "Farmbot"
UnitData[ unit_woc ] =  "Woc"
UnitData[ unit_worm ] =  "Glowbug"
UnitData[ unit_babywoc ] =  "Baby Woc"
UnitData[ unit_fant_gary ] =  "Snail"
UnitData[ unit_totebot_red ] =  "Explosive Totebot"
UnitData[ unit_totebot_blue ] =  "Blue Totebot"
UnitData[ unit_heavy_haybot ] =  "Heavy Haybot"

function Fant_RobotDetector.server_onCreate( self )
	--print( "Fant_RobotDetector", self.shape.id )
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = { range = self.MaximalRange }
	end
	self.detectionRange = self.saved.range
	
	self.network:sendToClients( "cl_setRange", { range = self.detectionRange } )
	refresh = true
	self.lastUnitCount = 0
end

function Fant_RobotDetector.client_onCreate( self )
	self.cl_updatetime = 0
	self.PoseValue = 0
	self.PoseDir = 1
	self.cl_detectionRange = 512
	self.network:sendToServer( "sv_getRange" )
	for i, k in pairs( cl_g_units ) do
		if k ~= nil then
			if cl_guis[ i ] ~= nil then
				if cl_guis[ i ].gui ~= nil then
					cl_guis[ i ].gui:close()
					cl_guis[ i ].gui = nil
					cl_guis[ i ] = nil
				end
			end
		end
	end
	g_robot_detector[ self.shape:getId() ] = { shape = self.shape, range = self.cl_detectionRange }
end

function Fant_RobotDetector.sv_getRange( self )
	self.network:sendToClients( "cl_setRange", { range = self.detectionRange } )	
end

function Fant_RobotDetector.server_onDestroy( self )
	self.saved = { range = self.detectionRange }
	self.storage:save( self.saved )
end

function Fant_RobotDetector.client_onDestroy( self )
	g_robot_detector[ self.shape:getId() ] = nil
	local robotdetectoramount = 0
	for i, k in pairs( g_robot_detector ) do
		robotdetectoramount = robotdetectoramount + 1
	end
	if robotdetectoramount <= 0 then
		for i, element in pairs( cl_guis ) do
			if element.gui ~= nil then
				element.gui:close()
				element = nil
			end
		end
	end
end

function Fant_RobotDetector.server_onFixedUpdate( self, dt )

	if g_units ~= nil then

		local c = 0
		for i, k in pairs( g_units ) do				
			if k ~= nil then			
				c = c + 1
			end		
		end	
		
		if self.lastUnitCount ~= c then
			refresh = true
			self.lastUnitCount = c
		end
		if refresh == true then
			refresh = false
			local clearList = {}
			self.network:sendToClients( "client_resetset_g_units" )	
			--print( "Fant_RobotDetector refresh", self.shape.id )
			local c = 0
			for i, k in pairs( g_units ) do				
				if k ~= nil then			
					if sm.exists( k.character ) then
						if k.health ~= nil then
							if k.health > 0 then
								c = c + 1
								clearList[ i ] = k
								self.network:sendToClients( "client_set_by_index_g_units", { index = i, character = k.character, shape = nil, health = k.health, maxhealth = k.maxhealth } )		
							end
						end
					end
					if sm.exists( k.shape ) then
						if k.health ~= nil then
							if k.health > 0 then
								c = c + 1
								clearList[ i ] = k
								--print(k)
								self.network:sendToClients( "client_set_by_index_g_units", { index = i, character = nil, shape = k.shape, health = k.health, maxhealth = k.maxhealth } )		
							end
						end
					end
				end		
			end	
			--print( "Fant_RobotDetector refreshed Units", c )
			g_units = clearList
		end
	end
	local OnOff = false
	for i, k in pairs( g_units ) do
		if sm.exists( k.character ) then
			if k.health > 0 then
				if not k.character:isTumbling() then
					local distance = sm.vec3.length( self.shape.worldPosition - k.character.worldPosition ) * 4
					if distance ~= nil and self.detectionRange ~= nil then
						if distance <= self.detectionRange then
							local typeString = tostring( k.character:getCharacterType() )
							if typeString ~= tostring( unit_woc ) and typeString ~= tostring( unit_worm ) and typeString ~= tostring( unit_babywoc ) and typeString ~= tostring( unit_fant_gary )then
								OnOff = true
							end
						end
					end
				end
			end
		elseif sm.exists( k.shape ) then
			if k.health > 0 then
				local distance = sm.vec3.length( self.shape.worldPosition - k.shape.worldPosition ) * 4
				if distance ~= nil and self.detectionRange ~= nil then
					if distance <= self.detectionRange then
						OnOff = true						
					end
				end
			end
		end
	end
	

	
	if self.shape:getBody():isStatic() ~= self.lastStatic then
		self.lastStatic = self.shape:getBody():isStatic()
		refresh = true
		sm.interactable.setActive( self.interactable, OnOff )
		self.LastOnOff = OnOff
	end
	if OnOff ~= self.lastState then
		refresh = true
		sm.interactable.setActive( self.interactable, OnOff )
		self.LastOnOff = OnOff
	end
	 
end

function Fant_RobotDetector.client_onUpdate( self, dt )
	self.PoseValue = self.PoseValue + ( dt * self.PoseDir )
	if self.PoseValue >= 1 then
		self.PoseValue = 1
		self.PoseDir = -1
	end
	if self.PoseValue <= 0 then
		self.PoseValue = 0
		self.PoseDir = 1
	end
	self.shape:getInteractable():setPoseWeight( 0, self.PoseValue )
	if self.cl_updatetime == nil then
		self.cl_updatetime = 0
	end
	if self.cl_updatetime > 0 then
		self.cl_updatetime = self.cl_updatetime -  dt
		return
	end
	self.cl_updatetime = 0.25
	
	local newGuis = {}
	for i, k in pairs( cl_g_units ) do
		if k ~= nil then
			local hasGuiElemet = false
			for rd, detector in pairs( g_robot_detector ) do
				if sm.exists( k.character ) then
					local distance = sm.vec3.length( detector.shape.worldPosition - k.character.worldPosition ) * 4
					if distance ~= nil and detector.range ~= nil then
						if distance <= detector.range then							
							if cl_guis[ i ] == nil then
								cl_guis[ i ] = {}
								cl_guis[ i ].gui = sm.gui.createNameTagGui()
								cl_guis[ i ].gui:setRequireLineOfSight( false )
								cl_guis[ i ].gui:open()
								cl_guis[ i ].gui:setMaxRenderDistance( 128 )	
								cl_guis[ i ].character = k.character	
							end		
							if cl_guis[ i ] ~= nil then
								if cl_guis[ i ].character ~= nil and sm.exists( cl_guis[ i ].character ) then	
									if cl_guis[ i ].gui ~= nil then									
										if k.health ~= nil then
											if k.health > 0 then
												local Name = ""
												for uuid, unitName in pairs( UnitData ) do							
													if tostring( uuid ) == tostring( cl_guis[ i ].character:getCharacterType() ) then
														Name = unitName
													end
												end					
												if Name ~= "Snail" and Name ~= "Glowbug" then
													cl_guis[ i ].gui:setWorldPosition( cl_guis[ i ].character.worldPosition + sm.vec3.new( 0, 0, 1.5 ) )
												else
													cl_guis[ i ].gui:setWorldPosition( cl_guis[ i ].character.worldPosition + sm.vec3.new( 0, 0, 0.5 ) )
												end
												if Name ~= "Woc" and Name ~= "Glowbug" and Name ~= "Baby Woc" and Name ~= "Snail" then
													cl_guis[ i ].gui:setText( "Text", "#ff0000".. "" .. Name .. " | " .. tostring( math.floor( k.health ) ) )
												else
													cl_guis[ i ].gui:setText( "Text", "#00ff00".. "" .. Name .. " | " .. tostring( math.floor( k.health ) ) )
												end
												hasGuiElemet = true
											end
										end
									end								
								end
							end
						end
					end
				end
				if sm.exists( k.shape ) then					
					local distance = sm.vec3.length( detector.shape.worldPosition - k.shape.worldPosition ) * 4
					if distance ~= nil and detector.range ~= nil then
						if distance <= detector.range then
							if cl_guis[ i ] == nil then
								cl_guis[ i ] = {}
								cl_guis[ i ].gui = sm.gui.createNameTagGui()
								cl_guis[ i ].gui:setRequireLineOfSight( false )
								cl_guis[ i ].gui:open()
								cl_guis[ i ].gui:setMaxRenderDistance( 128 )	
								cl_guis[ i ].shape = k.shape	
							
							end
							if cl_guis[ i ].shape ~= nil then	
								if cl_guis[ i ].gui ~= nil then
									cl_guis[ i ].gui:setWorldPosition( cl_guis[ i ].shape.worldPosition + sm.vec3.new( 0, 0, 1.5 ) )
									
									local name = "Strawdog"
									if cl_guis[ i ].shape:getShapeUuid() == fant_beebot then
										name = "Beebot"
									end
									
									cl_guis[ i ].gui:setText( "Text", "#ff0000".. name .. " | " .. tostring( math.floor( k.health ) ) )	
									if k.health > 0 then
										hasGuiElemet = true
									end
									
								end
							end
						end
					end
				end
			end
			if not hasGuiElemet then
				if cl_guis[ i ] ~= nil then
					if cl_guis[ i ].gui ~= nil then
						cl_guis[ i ].gui:close()
						cl_guis[ i ].gui = nil
						cl_guis[ i ] = nil
					end
				end
			else
				newGuis[ i ] = cl_guis[ i ]
			end
		end
	end
	cl_guis = nil
	cl_guis = newGuis
end

function Fant_RobotDetector.client_onInteract( self, character, state )
	if state == true then
		if self.cl_detectionRange ~= nil then
			if self.gui == nil then
				self.gui = sm.gui.createEngineGui()
			end
			
			self.gui:setText( "Name", "Robot Detector" )
			self.gui:setText( "Interaction", "Detection Range" )	
			self.gui:setSliderData( "Setting",self.MaximalRange + 1, self.cl_detectionRange )
			self.gui:setText( "SubTitle", "Range: " .. tostring( self.cl_detectionRange ) )
			self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
			self.gui:setOnCloseCallback( "cl_onGuiClosed" )
			self.gui:setIconImage( "Icon", obj_interactive_fant_robotScanner )
			self.gui:setVisible( "FuelContainer", false )
			self.gui:open()
		end
	end
end

function Fant_RobotDetector.cl_onSliderChange( self, sliderName, sliderPos )
	self.cl_detectionRange = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "SubTitle", "Range: " .. tostring(self.cl_detectionRange ) )
	end
	
end

function Fant_RobotDetector.sv_setRange( self, range )
	self.detectionRange = range
	self.saved = { range = self.detectionRange }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_setRange", { range = self.detectionRange } )	
	refresh = true
end

function Fant_RobotDetector.cl_setRange( self, data )
	self.cl_detectionRange = data.range
	if self.cl_detectionRange == nil then
		self.cl_detectionRange = self.MaximalRange
	end
	if self.gui ~= nil then
		self.gui:setText( "SubTitle", "Range: " .. tostring(self.cl_detectionRange ) )
		--self.gui:setSliderData( "Setting",self.MaximalRange + 1, self.cl_detectionRange  )
	end
	g_robot_detector[ self.shape:getId() ] = { shape = self.shape, range = self.cl_detectionRange }
end


function Fant_RobotDetector.cl_onGuiClosed( self )
	self.network:sendToServer( "sv_setRange", self.cl_detectionRange )	
	if self.gui ~= nil then
		self.gui:destroy()
		self.gui = nil
	end
end

function Fant_RobotDetector_Add_Unit( id, data )
	g_units[ id ] = data
	refresh = true
	--print( "Fant_RobotDetector_Add_Unit", id )
end

function Fant_RobotDetector.client_resetset_g_units( self )
	cl_g_units = nil
	cl_g_units = {}
end

function Fant_RobotDetector.client_set_by_index_g_units( self, data )
	cl_g_units[ data.index ] = data
	--print( "RB - Client Add", data )
end
















