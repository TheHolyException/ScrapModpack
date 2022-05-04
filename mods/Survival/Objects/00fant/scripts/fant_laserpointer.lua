Fant_Laserpointer = class()
Fant_Laserpointer.MaximalRange = 10
Fant_Laserpointer.DefaultColor = "df7f01ff"
Fant_Laserpointer.poseWeightCount = 2
Fant_Laserpointer.maxParentCount = 1
Fant_Laserpointer.connectionInput = sm.interactable.connectionType.logic
Fant_Laserpointer.maxChildCount = 256
Fant_Laserpointer.connectionOutput = sm.interactable.connectionType.logic
Fant_Laserpointer.colorNormal = sm.color.new( 0x0000680ff )
Fant_Laserpointer.colorHighlight = sm.color.new( 0x0000ff0ff )


function Fant_Laserpointer.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { MaximalRange = 10, mode = "All Units" } 
		self.storage:save( self.sv.storage )
	end
	self.MaximalRange = self.sv.storage.MaximalRange
	self.range = self.MaximalRange
	self.lastrange = 0
	self.timer = 0
	self.lastUnitHit = false

	self.mode = self.sv.storage.mode
	self.network:sendToClients( "cl_setMode", self.mode )
	
	self.lastrange = self.range
	self.network:sendToClients( "cl_setPoseWeight", self.range )
end

function Fant_Laserpointer.client_onCreate( self )
	self.MaximalRange = self.MaximalRange
	self.network:sendToServer( "GetData" )

	self.cl_mode = self.cl_mode or "All Units"
	self.network:sendToServer( "GetMode" )	
	self:cl_setPoseWeight( self.MaximalRange )
end

function Fant_Laserpointer.GetData( self )	
	self.network:sendToClients( "SetData", { MaximalRange = self.MaximalRange, mode = self.mode } )	
end

function Fant_Laserpointer.client_onDestroy( self )
	if self.gui then
		self.gui:close()
		self.gui:destroy()
		self.gui = nil
	end
end

function Fant_Laserpointer.GetMode( self )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_Laserpointer.sv_setMode( self, mode )
	self.mode = mode
	self.sv.storage.mode = self.mode
	self.storage:save( self.sv.storage )
	self.network:sendToClients( "cl_setMode", self.mode )	
end

function Fant_Laserpointer.cl_setMode( self, mode )
	self.cl_mode = mode
end

function Fant_Laserpointer.server_onFixedUpdate( self, dt )
	if self.timer > 0 then
		self.timer = self.timer - dt
		return
	end
	self.timer = dt * 2
	
	local canHitPlayer = false
	if self.mode == "All Units" then
		canHitPlayer = true
	end
	local hideRay = false
	local UnitHit = false
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() then
			hideRay = true
		end
	end
	
	local start = self.shape:getWorldPosition()
	local stop = self.shape:getWorldPosition() - sm.shape.getUp( self.shape ) * self.MaximalRange
	local valid, result = sm.physics.raycast( start, stop, self.shape )
	if result then
		self.range = ( sm.vec3.length( result.pointWorld - start ) / sm.construction.constants.subdivideRatio ) - 0.2
		if self.range > self.MaximalRange then
			self.range = self.MaximalRange
		else
			if result.type then
				if self.mode ~= "Rods" then
					if self.mode == "Distance" then
						UnitHit = true
					else					
						if result.type == "character" then
							local character = result:getCharacter()
							local typeString = tostring( character:getCharacterType() )

							if character then
								if self.mode ~= "All Units" then
									if not character:getPlayer() then

										if self.mode == "Totebots" and ( typeString == tostring( unit_totebot_green ) or typeString == tostring( unit_totebot_blue ) ) then
											UnitHit = true
										end
										if self.mode == "Haybots" and ( typeString == tostring( unit_haybot ) or typeString == tostring( unit_heavy_haybot ) ) then
											UnitHit = true
										end
										if self.mode == "Tapebots" and ( typeString == tostring( unit_tapebot ) or typeString == tostring( unit_tapebot_taped_1 ) or typeString == tostring( unit_tapebot_taped_2 ) or typeString == tostring( unit_tapebot_taped_3 ) or typeString == tostring( unit_tapebot_red ) ) then
											UnitHit = true
										end
										if self.mode == "Farmbots" and typeString == tostring( unit_farmbot ) then
											UnitHit = true
										end
										if self.mode == "ExplosiveTotebots" and typeString == tostring( unit_totebot_red ) then
											UnitHit = true
										end
										if self.mode == "Wocs" and typeString == tostring( unit_woc ) then
											UnitHit = true
										end
										
										if self.mode == "Only non Player" then
											UnitHit = true
										end
									end
								else
									UnitHit = true
								end
							end
						elseif result.type == "body" then
							local shapes = sm.body.getShapes( result:getBody() )
							if shapes and fant_straw_dog == sm.shape.getShapeUuid( shapes[1] )  then
								if self.mode == "All Units" or self.mode == "Strawdogs" or  self.mode == "Only non Player"  then
									UnitHit = true
								end
							end
							if shapes and fant_beebot == sm.shape.getShapeUuid( shapes[1] ) then								
								if self.mode == "All Units" or  self.mode == "Only non Player"  then
									UnitHit = true
								end
							end
						end
					end
				else
					if result.type == "body" then
						local shapes = sm.body.getShapes( result:getBody() )
						if shapes then
							if "968de65c-75f3-471b-954e-6165a4b6d3d6" == tostring( sm.shape.getShapeUuid( shapes[1] ) ) then
								UnitHit = true
							end
							if "f99ebc34-4821-4b39-a625-b839c5802ed5" == tostring( sm.shape.getShapeUuid( shapes[1] ) ) then
								UnitHit = true
							end
							if "5cb39ea5-554d-4c40-9d9a-6b2dd59de953" == tostring( sm.shape.getShapeUuid( shapes[1] ) ) then
								UnitHit = true
							end
							if "7468db55-b29d-4ce0-82b9-2414f493a376" == tostring( sm.shape.getShapeUuid( shapes[1] ) ) then
								UnitHit = true
							end
							if "02ee2a98-bd8d-4a09-bb69-38edaf66b8e1" == tostring( sm.shape.getShapeUuid( shapes[1] ) ) then
								UnitHit = true
							end
						end
					end
				end
			end
		end
	else
		self.range = self.MaximalRange
	end
	if hideRay then
		self.range = 0
	end
	if self.lastrange ~= self.range then
		self.lastrange = self.range
		self.network:sendToClients( "cl_setPoseWeight", self.range )
		sm.interactable.setPublicData( sm.shape.getInteractable( self.shape ), { value = self.range } )
	end
	if self.shape:getBody():isStatic() then
		self.lastUnitHit = not UnitHit
	end
	
	if self.lastUnitHit ~= UnitHit then
		self.lastUnitHit = UnitHit
		sm.interactable.setActive( self.interactable, UnitHit )
	end
end

function Fant_Laserpointer.cl_setPoseWeight( self, range )
	self.shape:getInteractable():setPoseWeight( 0, sm.util.clamp( range / 1000, 0, 1 ) )
end

function Fant_Laserpointer.server_onDestroy( self )
	self:SaveData()
end

function Fant_Laserpointer.sv_SetData( self, data )
	self.MaximalRange = data.MaximalRange
	self:SaveData()
	--print( "self.MaximalRange", self.MaximalRange )
end	

function Fant_Laserpointer.SaveData( self )
	self.sv.storage.MaximalRange = self.MaximalRange
	self.storage:save( self.sv.storage )
end


function Fant_Laserpointer.client_canInteract( self, character )
	if self.cl_mode == nil then
		self.network:sendToServer( "GetMode" )	
		return true
	end
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Open" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Mode: " .. tostring( self.cl_mode ) )
	return true
end


function Fant_Laserpointer.client_onTinker( self, character, state )
	if state then
		if self.cl_mode == "All Units" then
			self.cl_mode = "Only non Player"
		elseif self.cl_mode == "Only non Player" then
			self.cl_mode = "Rods"
		elseif self.cl_mode == "Rods" then
			self.cl_mode = "Distance"
		elseif self.cl_mode == "Distance" then
			self.cl_mode = "Totebots"
		elseif self.cl_mode == "Totebots" then
			self.cl_mode = "Haybots"
		elseif self.cl_mode == "Haybots" then
			self.cl_mode = "Tapebots"
		elseif self.cl_mode == "Tapebots" then
			self.cl_mode = "Farmbots"
		elseif self.cl_mode == "Farmbots" then
			self.cl_mode = "ExplosiveTotebots"
		elseif self.cl_mode == "ExplosiveTotebots" then
			self.cl_mode = "Strawdogs"
		elseif self.cl_mode == "Strawdogs" then
			self.cl_mode = "Wocs"
		else
			self.cl_mode = "All Units"
		end
		self.network:sendToServer( "sv_setMode", self.cl_mode )	
	end
end


function Fant_Laserpointer.client_onInteract(self, _, state)
	if state == true then	
		if self.gui == nil then
			self.gui = sm.gui.createEngineGui()
		end
		self.gui:setText( "Name", "Laserpointer" )	
		self:ClientInterfaceSetting()	
		self.gui:setIconImage( "Icon", self.shape:getShapeUuid() )
		self.gui:setOnCloseCallback( "cl_onGuiClosed" )
		self.gui:setSliderCallback( "Setting", "cl_onSliderChange" )
		self.gui:setText( "Interaction", "Use Mousewheel for Small Adjustments!" )
		self.gui:open()		
	end
end

function Fant_Laserpointer.cl_onGuiClosed( self )
	self.gui:destroy()
	self.gui = nil
	self.network:sendToServer( "sv_SetData", { MaximalRange = self.MaximalRange } )
end

function Fant_Laserpointer.cl_onSliderChange( self, sliderName, sliderPos )
	self.MaximalRange = sm.util.clamp( sliderPos, 1, 1000 )
	self:ClientInterfaceSetting()
	--self.network:sendToServer( "sv_SetData", { MaximalRange = self.MaximalRange } )
end

function Fant_Laserpointer.SetData( self, data )
	self.MaximalRange = data.MaximalRange
	self.cl_mode = data.mode
	if self.gui then
		self:ClientInterfaceSetting()
	end
end

function Fant_Laserpointer.ClientInterfaceSetting( self )
	self.gui:setText( "SubTitle", "Range " .. tostring( self.MaximalRange ) )			
	self.gui:setSliderData( "Setting", 1001, self.MaximalRange )
end








