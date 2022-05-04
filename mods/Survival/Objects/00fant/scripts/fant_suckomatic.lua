dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"

Fant_SuckOmatic = class()
Fant_SuckOmatic.poseWeightCount = 1
Fant_SuckOmatic.maxParentCount = 3
Fant_SuckOmatic.connectionInput = sm.interactable.connectionType.logic
Fant_SuckOmatic.ForceMultiplier = 5
Fant_SuckOmatic.SliderSteps = 25
Fant_SuckOmatic.colorNormal = sm.color.new( 0x800000ff )
Fant_SuckOmatic.colorHighlight = sm.color.new( 0xff0000ff )

RocksAndTrees = {
	obj_harvests_stones_p01,
	obj_harvests_stones_p02,
	obj_harvests_stones_p03,
	obj_harvests_stones_p04,
	obj_harvests_stones_p05,
	obj_harvests_stones_p06,
	obj_harvest_stonechunk01,
	obj_harvest_stonechunk02,
	obj_harvest_stonechunk03,
	obj_harvest_log_s01,
	obj_harvest_log_m01,
	obj_harvest_log_l01,
	obj_harvest_log_l02a,
	obj_harvest_log_l02b,
	obj_harvests_trees_spruce02_p00,
	obj_harvests_trees_spruce02_p01,
	obj_harvests_trees_spruce02_p02,
	obj_harvests_trees_spruce02_p03,
	obj_harvests_trees_spruce02_p04,
	obj_harvests_trees_spruce01_p05,
	obj_harvests_trees_spruce02_p05,
	obj_harvests_trees_spruce03_p05,
	obj_harvests_trees_leafy01_p00,
	obj_harvests_trees_leafy01_p01,
	obj_harvests_trees_leafy01_p02,
	obj_harvests_trees_leafy01_p03,
	obj_harvests_trees_leafy01_p04,
	obj_harvests_trees_leafy02_p00,
	obj_harvests_trees_leafy02_p01,
	obj_harvests_trees_leafy02_p02,
	obj_harvests_trees_leafy02_p03,
	obj_harvests_trees_leafy02_p04,
	obj_harvests_trees_leafy02_p05,
	obj_harvests_trees_leafy02_p06,
	obj_harvests_trees_leafy02_p07,
	obj_harvests_trees_leafy03_p00,
	obj_harvests_trees_leafy03_p01,
	obj_harvests_trees_leafy03_p02,
	obj_harvests_trees_leafy03_p03,
	obj_harvests_trees_leafy03_p04,
	obj_harvests_trees_leafy03_p05,
	obj_harvests_trees_leafy03_p06,
	obj_harvests_trees_leafy03_p07,
	obj_harvests_trees_leafy03_p08,
	obj_harvests_trees_leafy03_p09,
	obj_harvests_trees_birch01_p00,
	obj_harvests_trees_birch01_p01,
	obj_harvests_trees_birch01_p02,
	obj_harvests_trees_birch01_p03,
	obj_harvests_trees_birch01_p04,
	obj_harvests_trees_birch01_p05,
	obj_harvests_trees_birch02_p00,
	obj_harvests_trees_birch02_p01,
	obj_harvests_trees_birch02_p02,
	obj_harvests_trees_birch02_p03,
	obj_harvests_trees_birch02_p04,
	obj_harvests_trees_birch02_p05,
	obj_harvests_trees_birch02_p06,
	obj_harvests_trees_birch03_p00,
	obj_harvests_trees_birch03_p01,
	obj_harvests_trees_birch03_p02,
	obj_harvests_trees_birch03_p03,
	obj_harvests_trees_birch03_p04,
	obj_harvests_trees_birch03_p05,
	obj_harvests_trees_birch03_p06,
	obj_harvests_trees_pine01_p00,
	obj_harvests_trees_pine01_p01,
	obj_harvests_trees_pine01_p02,
	obj_harvests_trees_pine01_p03,
	obj_harvests_trees_pine01_p04,
	obj_harvests_trees_pine01_p05,
	obj_harvests_trees_pine01_p06,
	obj_harvests_trees_pine01_p07,
	obj_harvests_trees_pine01_p08,
	obj_harvests_trees_pine01_p09,
	obj_harvests_trees_pine01_p10,
	obj_harvests_trees_pine01_p11,
	obj_harvests_trees_pine02_p00,
	obj_harvests_trees_pine02_p01,
	obj_harvests_trees_pine02_p02,
	obj_harvests_trees_pine02_p03,
	obj_harvests_trees_pine02_p04,
	obj_harvests_trees_pine02_p05,
	obj_harvests_trees_pine02_p06,
	obj_harvests_trees_pine02_p07,
	obj_harvests_trees_pine02_p08,
	obj_harvests_trees_pine02_p09,
	obj_harvests_trees_pine02_p10,
	obj_harvests_trees_pine03_p00,
	obj_harvests_trees_pine03_p01,
	obj_harvests_trees_pine03_p02,
	obj_harvests_trees_pine03_p03,
	obj_harvests_trees_pine03_p04,
	obj_harvests_trees_pine03_p05,
	obj_harvests_trees_pine03_p06,
	obj_harvests_trees_pine03_p07,
	obj_harvests_trees_pine03_p08,
	obj_harvests_trees_pine03_p09,
	obj_harvests_trees_pine03_p10
}

Rods = {
	obj_harvest_wood,
	obj_harvest_wood2,
	obj_harvest_metal,
	obj_harvest_metal2,
	obj_harvest_stone
}

FarmerAndCrates = {
	obj_crates_banana,
	obj_crates_blueberry,
	obj_crates_orange,
	obj_crates_pineapple,
	obj_crates_carrot,
	obj_crates_redbeet,
	obj_crates_tomato,
	obj_crates_broccoli,
	obj_survivalobject_farmerball
}

function Fant_SuckOmatic.isRockOrTree( self, uuid )
	for i, k in pairs( RocksAndTrees ) do
		if uuid == k then
			return true
		end
	end
	return false
end

function Fant_SuckOmatic.isRod( self, uuid )
	for i, k in pairs( Rods ) do
		if uuid == k then
			return true
		end
	end
	return false
end

function Fant_SuckOmatic.isFarmerAndCrate( self, uuid )
	for i, k in pairs( FarmerAndCrates ) do
		if uuid == k then
			return true
		end
	end
	return false
end

function Fant_SuckOmatic.server_onCreate( self )
	self.iSucked = false
	self.changeRangeToggle = 0
	self.lastChange = 0
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { sliderValue = 5, sliderValue2 = 15, mode = "All" } 
		self.storage:save( self.sv.storage )
	end
	self.sliderValue = self.sv.storage.sliderValue or 0
	self.sliderValue2 = self.sv.storage.sliderValue2 or 0
	self.mode = self.sv.storage.mode
	
	self.network:sendToClients( "cl_set_data", { sliderValue = self.sliderValue, sliderValue2 = self.sliderValue2, mode = self.mode } )
	
	local BlockSize = sm.construction.constants.subdivideRatio	
	local Pos = sm.vec3.new( 0, 4, 0 )
	local areaSize = sm.vec3.new( BlockSize * (1+self.sliderValue2), BlockSize * 35, BlockSize * (1+self.sliderValue2) ) 
	local areaTriggerSize = sm.vec3.new( BlockSize * 15, BlockSize * 40, BlockSize * 15 ) 
	self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), areaTriggerSize * 0.5, Pos, sm.quat.identity(), sm.areaTrigger.filter.all )
	--self.network:sendToClients( "cl_BoxAreaTrigger", { Pos = Pos, Size = -areaSize } )
end

function Fant_SuckOmatic.cl_BoxAreaTrigger( self, data )
	if self.effect ~= nil then
		self.effect:stop()
		self.effect = nil
	end
	self.effect = sm.effect.createEffect( "ShapeRenderable", self.interactable )				
	self.effect:setParameter( "uuid", sm.uuid.new("f7881097-9320-4667-b2ba-4101c72b8730") )
	self.effect:start()
	self.deleteTimer = 2
	self.effect:setOffsetPosition( data.Pos )	
	self.effect:setScale( data.Size )

end

function Fant_SuckOmatic.client_onUpdate( self, dt )
	if self.effect ~= nil then
		if self.deleteTimer > 0 then
			self.deleteTimer = self.deleteTimer - dt
		else
			self.effect:stop()
			self.effect = nil
		end
	end
end

function Fant_SuckOmatic.cl_set_data( self, data )
	self.sliderValue = data.sliderValue
	self.sliderValue2 = data.sliderValue2
	self.cl_mode = data.mode
end

function Fant_SuckOmatic.client_onCreate( self )
	self.shootEffect = sm.effect.createEffect( "Vacuumpipe - Suction", self.interactable )
	self.shootEffect:setOffsetRotation( sm.quat.angleAxis( math.pi*0.5, sm.vec3.new( -1, 0, 0 ) ) )
	self.sliderValue = self.sliderValue or 0
	self.sliderValue2 = self.sliderValue2 or 0
	self.cl_mode = self.cl_mode or "All"
	self.network:sendToServer( "sv_getData" )
end

function Fant_SuckOmatic.sv_getData( self )
	self.network:sendToClients( "cl_set_data", { sliderValue = self.sliderValue, sliderValue2 = self.sliderValue2, mode = self.mode } )
end

function Fant_SuckOmatic.cl_Suck( self )
	self.shootEffect:start()
	self.shape:getInteractable():setPoseWeight( 0, 1 )
end	

function Fant_SuckOmatic.cl_Release( self )
	self.shape:getInteractable():setPoseWeight( 0, 0 )
end	

function Fant_SuckOmatic.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Settings" )
	return true
end

function Fant_SuckOmatic.GetMode( self )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_SuckOmatic.sv_setMode( self, mode )
	self.mode = mode	
	self.saved = { sliderValue = self.sliderValue, sliderValue2 = self.sliderValue2, mode = self.mode }
	self.storage:save( self.saved )
	
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_SuckOmatic.cl_setMode( self, mode )
	self.cl_mode = mode
end

function Fant_SuckOmatic.client_canInteract( self, character )
	if self.cl_mode == nil then
		self.network:sendToServer( "GetMode" )	
		return true
	end
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. tostring( self.cl_mode ) )
	return true
end

function Fant_SuckOmatic.client_onTinker( self, character, state )
	if state then
		if self.cl_mode == "All" then
			self.cl_mode = "Creations and Parts"
		elseif self.cl_mode == "Creations and Parts" then
			self.cl_mode = "Rocks and Trees"
		elseif self.cl_mode == "Rocks and Trees" then
			self.cl_mode = "Rods"
		elseif self.cl_mode == "Rods" then
			self.cl_mode = "Crates And Farmer"
		elseif not sm.game.getEnableAmmoConsumption() and self.cl_mode == "Crates And Farmer" then
			self.cl_mode = "Robots"
		else
			self.cl_mode = "All"
		end
		self.network:sendToServer( "sv_setMode", self.cl_mode )	
	end
end

function Fant_SuckOmatic.client_onInteract( self, character, state )
	if state == true then
		if self.gui == nil then
			self.gui = sm.gui.createSteeringBearingGui()
		end
		self.gui:setText( "Name", "SuckOmatic" )
		self.gui:setText( "SubTitle", "Settings" )
		self.gui:setText( "Interaction", "Length: ".. tostring( self.sliderValue ) )
		self.gui:setSliderData( "LeftAngle",self.SliderSteps+1, self.sliderValue )
		self.gui:setSliderCallback( "LeftAngle", "cl_onSliderChange" )
		self.gui:setSliderData( "RightAngle",self.SliderSteps+1, self.sliderValue2 )
		self.gui:setSliderCallback( "RightAngle", "cl_onSliderChange2" )
		self.gui:setText( "LeftAngleText", tostring( self.sliderValue ) )		
		self.gui:setText( "RightAngleText", tostring( self.sliderValue2 ) )
		self.gui:setText( "TurnTextLeft", "Length" )
		self.gui:setText( "TurnTextRight", "Width" )
		self.gui:setVisible( "LeftSpeed", false )
		self.gui:setVisible( "RightSpeed", false )
		self.gui:setVisible( "On", false )
		self.gui:setVisible( "Off", false )
		self.gui:setVisible( "Bearingtext", false )
		self.gui:setImage( "IconPic", "$GAME_DATA/Gui/Layouts/suckomatic.png" )
		self.gui:setVisible( "LeftRotation", false )
		self.gui:setVisible( "RightRotation", false )
		self.gui:setVisible( "TurnSpeedTextLeft", false )
		self.gui:setVisible( "TurnSpeedTextRight", false )
		self.gui:setIconImage( "Icon", obj_interactive_fant_anchor )
		self.gui:setVisible( "FuelContainer", false )
		self.gui:open()
	end
end

function Fant_SuckOmatic.cl_onSliderChange( self, sliderName, sliderPos )
	self.sliderValue = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Length: ".. tostring( self.sliderValue ) )
		self.gui:setText( "LeftAngleText", tostring( self.sliderValue ) )		
		self.gui:setText( "RightAngleText", tostring( self.sliderValue2 ) )
	end
	self.network:sendToServer( "setSliderValue", { sliderValue = self.sliderValue, sliderValue2 = self.sliderValue2 } )
end

function Fant_SuckOmatic.cl_onSliderChange2( self, sliderName, sliderPos )
	self.sliderValue2 = sliderPos
	if self.gui ~= nil then
		self.gui:setText( "Interaction", "Width: ".. tostring( self.sliderValue2 ) )
		self.gui:setText( "LeftAngleText", tostring( self.sliderValue ) )		
		self.gui:setText( "RightAngleText", tostring( self.sliderValue2 ) )
	end
	self.network:sendToServer( "setSliderValue", { sliderValue = self.sliderValue, sliderValue2 = self.sliderValue2 } )
end

function Fant_SuckOmatic.setSliderValue( self, data )
	self.sliderValue = data.sliderValue
	self.sliderValue2 = data.sliderValue2
	self.saved = { sliderValue = self.sliderValue, sliderValue2 = self.sliderValue2, mode = self.mode }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_set_data", self.saved )
	if self.areaTrigger ~= nil then
		sm.areaTrigger.destroy( self.areaTrigger )
		self.areaTrigger = nil
	end
	local BlockSize = sm.construction.constants.subdivideRatio	
	local areaPos = sm.vec3.new( 0, 4, 0 )
	local areaTriggerSize = sm.vec3.new( BlockSize * 15, BlockSize * 40, BlockSize * 15 ) 
	self.areaTrigger = sm.areaTrigger.createAttachedBox( self.shape:getInteractable(), areaTriggerSize * 0.5, areaPos, sm.quat.identity(), sm.areaTrigger.filter.all )
	
	local Pos = sm.vec3.new( 0, (1+self.sliderValue) * BlockSize * 0.5, 0 )
	local areaSize = sm.vec3.new( BlockSize * (1+self.sliderValue2), BlockSize * (1+self.sliderValue), BlockSize * (1+self.sliderValue2) ) 
	self.network:sendToClients( "cl_BoxAreaTrigger", { Pos = Pos, Size = -areaSize } )
end

function Fant_SuckOmatic.getInputs( self )
	local parents = self.interactable:getParents()
	local Active = false
	local ChangeRange = 0
	for i = 1, #parents do
		if parents[i] then
			if parents[i]:hasOutputType( sm.interactable.connectionType.logic ) then
				if tostring( parents[i].shape.color ) == "df7f01ff" then
					Active = parents[i].active	
				end
				if tostring( parents[i].shape.color ) == "0a3ee2ff" then  --blue
					if parents[i].active then
						ChangeRange = 1
					end
				end
				if tostring( parents[i].shape.color ) == "d02525ff" then --red
					if parents[i].active then
						ChangeRange = -1
					end
				end
			end		
		end
	end	
	if self.changeRangeToggle == ChangeRange then
		ChangeRange = 0
	else
		self.changeRangeToggle = ChangeRange
	end
	return Active, ChangeRange
end 

function Fant_SuckOmatic.server_onFixedUpdate( self )
	local isActive, changeRange = self:getInputs()
	if self.lastChange ~= changeRange then
		self:inputChangesliderValue( changeRange )
		--print( "lastChange" )
	end
	local HasSuck = false
	if isActive then
		if self.areaTrigger then
			self.body = sm.shape.getBody( self.shape )
			if self.body == nil then
				return
			end
			for _, result in ipairs(  self.areaTrigger:getContents() ) do
				if sm.exists( result ) then	
					if result ~= nil then
						
						if self.mode == "Robots" and not sm.game.getEnableAmmoConsumption() then
							
							if type( result ) == "Character" then
								local Target = result
								if Target ~= nil then
									local Size = 0
									local SuckPos = self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * ( ( Size / 1.25 ) + ( ( self.sliderValue + 1.25 ) * 0.25 ) ) )
									
									if not Target:isTumbling() then	
										local Mass = Target:getMass()
										local RelPos = SuckPos - Target:getWorldPosition()
										local Distance = sm.vec3.length( RelPos ) * 1.25
										local Force = sm.vec3.normalize( RelPos ) * Mass * self.ForceMultiplier * ( Distance * 0.75 )
										local Velocity = -Target:getVelocity() * Mass / 1.5
										sm.physics.applyImpulse( Target, ( Force + Velocity ), true, nil )	
									else										
										local Mass = 1000
										local RelPos = SuckPos - Target:getTumblingWorldPosition()
										local Distance = sm.vec3.length( RelPos ) * 1.25
										local Force = sm.vec3.normalize( RelPos ) * Mass * self.ForceMultiplier * ( Distance * 0.75 ) / 10
										local Velocity = -Target:getVelocity() * Mass * 0.03
										 
										Target:applyTumblingImpulse( Force + Velocity )	
									end
									HasSuck = true
								end					
							end
						else
							if type( result ) == "Body" then
								local calculationCounter = 0
								local Target = result

								if Target == self.body then
									Target = nil
								end
								if Target ~= nil then
									for _, subBody in pairs( sm.body.getCreationBodies( Target ) ) do
										if subBody == self.body then
											Target = nil										
											break
										end
									end	
								end
								if Target ~= nil then	
									for _, subBody in pairs( sm.body.getCreationBodies( self.body ) ) do
										if subBody == Target then
											Target = nil												
											break
										end
									end	
								end
								if Target ~= nil then		
									local shapes = sm.body.getCreationShapes( Target )
									if shapes ~= nil then
										if shapes ~= {} then
											if shapes[1].uuid == fant_straw_dog then
												Target = nil
											end
											if shapes[1].uuid == fant_beebot then
												Target = nil
											end
											
											if self.mode ~= "All" then
												if self.mode == "Creations and Parts" then
													if self:isRockOrTree( shapes[1].uuid ) then
														Target = nil
													end
													if self:isRod( shapes[1].uuid ) then
														Target = nil
													end
													if self:isFarmerAndCrate( shapes[1].uuid ) then
														Target = nil
													end
												else
													if self.mode == "Rocks and Trees" then
														if not self:isRockOrTree( shapes[1].uuid ) then
															Target = nil
														end
													end
													if self.mode == "Rods" then
														if not self:isRod( shapes[1].uuid ) then
															Target = nil
														end
													end
													if self.mode == "Crates And Farmer" then
														if not self:isFarmerAndCrate( shapes[1].uuid ) then
															Target = nil
														end
													end
												end
											end
											
										end								
									end
									
								end
								if Target ~= nil then
									--print( "___________")
									--print(  )
									
									local Size = 0
									-- local AABB1, AABB2 = Target:getWorldAabb()
		
									-- local SizeVec = AABB2 - AABB1--sm.item.getShapeSize( sm.body.getCreationShapes( Target )[1].uuid ) * sm.construction.constants.subdivideRatio
									-- if SizeVec.x >= Size then
										-- Size = SizeVec.x
									-- end
									-- if SizeVec.y >= Size then
										-- Size = SizeVec.y
									-- end
									-- if SizeVec.z >= Size then
										-- Size = SizeVec.z
									-- end
									-- Size = Size - 0.5
									-- if Size > self.sliderValue then
										-- Size = self.sliderValue
									-- end
									--print( Size )
									local Mass = Target:getMass()
									local SuckPos = self.shape.worldPosition + ( sm.shape.getAt( self.shape ) * ( ( Size / 1.25 ) + ( ( self.sliderValue + 1.25 ) * 0.25 ) ) )
									local RelPos = SuckPos - Target:getCenterOfMassPosition()
									local Distance = sm.vec3.length( RelPos ) * 1.25
									local Force = sm.vec3.normalize( RelPos ) * Mass * self.ForceMultiplier * ( Distance * 0.75 )
									local Velocity = -Target:getVelocity() * Mass / 1.5
									sm.physics.applyImpulse( Target, ( Force + Velocity ), true, nil )	
									
									HasSuck = true
								end							
							end
						end
					end
				end
			end
		end
	end
	
	if not HasSuck then
		if self.iSucked then
			self.iSucked = false
			self.network:sendToClients( "cl_Release" )
			--print( "HasSuck" )
		end
	else
		if not self.iSucked then
			self.iSucked = true
			self.network:sendToClients( "cl_Suck" )
			--print( "iSucked" )
		end
	end
end

function Fant_SuckOmatic.inputChangesliderValue( self, value )
	self.sliderValue = self.sliderValue + value
	if self.sliderValue < 0 then
		self.sliderValue = 0
	end
	if self.sliderValue > self.SliderSteps + 1 then
		self.sliderValue = self.SliderSteps + 1
	end
	self.saved = { sliderValue = self.sliderValue, sliderValue2 = self.sliderValue2, mode = self.mode }
	self.storage:save( self.saved )
	self.network:sendToClients( "cl_set_data", self.saved )
end


