dofile( "$SURVIVAL_DATA/Scripts/game/survival_items.lua")
dofile( "$SURVIVAL_DATA/Scripts/util.lua")
Fant_SunShakeVendingMachine = class()

FrontRow = 0.35
BackRow = 0.1
Left = -0.25
Middle = 0
Right = -Left
Top = 0.3
Center = 0.05
Bottom = -0.2

SlotOffsets = {
	sm.vec3.new( FrontRow, Left, Bottom ),
	sm.vec3.new( BackRow, Left, Bottom ),
	sm.vec3.new( FrontRow, Middle, Bottom ),
	sm.vec3.new( BackRow, Middle, Bottom ),
	sm.vec3.new( FrontRow, Right, Bottom ),
	sm.vec3.new( BackRow, Right, Bottom ),
	sm.vec3.new( FrontRow, Left, Center ),
	sm.vec3.new( BackRow, Left, Center ),
	sm.vec3.new( FrontRow, Middle, Center ),
	sm.vec3.new( BackRow, Middle, Center ),
	sm.vec3.new( FrontRow, Right, Center ),
	sm.vec3.new( BackRow, Right, Center ),
	sm.vec3.new( FrontRow, Left, Top ),
	sm.vec3.new( BackRow, Left, Top ),
	sm.vec3.new( FrontRow, Middle, Top ),
	sm.vec3.new( BackRow, Middle, Top ),
	sm.vec3.new( FrontRow, Right, Top ),
	sm.vec3.new( BackRow, Right, Top ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 ),
	sm.vec3.new( 0, 0, 0 )
}

function Fant_SunShakeVendingMachine.server_onCreate( self )	
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 18, 256 )
	end
end

function Fant_SunShakeVendingMachine.client_onCreate( self )
	self.effects = {}
	self.container = self.shape:getInteractable():getContainer(0)
	if self.container == nil then
		return
	end
	for slot = 0, self.container:getSize() - 1 do	
		table.insert( self.effects, { effect = nil, uuid = nil } )
	end
end

function Fant_SunShakeVendingMachine.client_onDestroy( self )
	for index = 0, #self.effects do	
		if self.effects[ index + 1 ] ~= nil then
			if self.effects[ index + 1 ].effect ~= nil then
				self.effects[ index + 1 ].effect:stop()
				self.effects[ index + 1 ].uuid = nil
				self.effects[ index + 1 ].effect = nil
			end
		end
	end
end

function Fant_SunShakeVendingMachine.client_canCarry( self )
	self.container = self.shape.interactable:getContainer( 0 )
	if self.container and sm.exists( self.container ) then
		return not self.container:isEmpty()
	end
	return false
end

function Fant_SunShakeVendingMachine.client_onInteract(self, character, state)
	self.container = self.shape.interactable:getContainer( 0 )
	if state == true then
		self.gui = sm.gui.createContainerGui( true )
			
		self.gui:setText( "UpperName", "Sun Shake" )
		self.gui:setContainer( "UpperGrid", self.container )	

		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		
		self.gui:open()			
	end
end

function Fant_SunShakeVendingMachine.getItemUUID( self, item )
	if item == nil then
		return nil, false
	end
	if item.uuid == tool_handbook then
		return nil, false
	end
	if item.uuid == tool_sledgehammer then
		return nil, false
	end
	if item.uuid == tool_lift then
		return nil, false
	end
	local externFuncResult = GetToolProxyItem( item.uuid )
	if externFuncResult ~= nil and externFuncResult ~= sm.uuid.getNil() then
		return externFuncResult, true
	end
	-- if item.uuid == tool_paint then
		-- return obj_tool_paint, true
	-- end
	-- if item.uuid == tool_weld then
		-- return obj_tool_weld, true
	-- end
	-- if item.uuid == tool_spudgun then
		-- return obj_tool_spudgun, true
	-- end
	-- if item.uuid == tool_shotgun then
		-- return obj_tool_frier, true
	-- end
	-- if item.uuid == tool_gatling then
		-- return obj_tool_spudling, true
	-- end
	return item.uuid, false
end

function Fant_SunShakeVendingMachine.client_onUpdate( self, dt )
	self.container = self.shape:getInteractable():getContainer(0)
	if self.container == nil then
		return
	end
	for index = 0, self.container:getSize() - 1 do	
		local item = self.container:getItem( index )
		if item then
			if item.quantity > 0 then
				local ItemUUID, isTool = self:getItemUUID( item )
				if ItemUUID ~= nil then
					if self.effects == nil then
						self.effects = {}
					end
					if self.effects[ index + 1 ] == nil then
						self.effects[ index + 1 ] = { effect = nil, uuid = nil }
					end
					if self.effects[ index + 1 ].uuid ~= ItemUUID then
						self.effects[ index + 1 ].uuid = ItemUUID
						self.effects[ index + 1 ].effect = sm.effect.createEffect( "ShapeRenderable", self.interactable  )		
						if self.effects[ index + 1 ].effect ~= nil then
							self.effects[ index + 1 ].effect:setParameter( "uuid", self.effects[ index + 1 ].uuid )
							local bounds = sm.item.getShapeSize( self.effects[ index + 1 ].uuid ) * 1.25
							if isTool then
								self.effects[ index + 1 ].effect:setScale( sm.vec3.new( sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio ) / ( bounds * 2.5 )  )
							else
								self.effects[ index + 1 ].effect:setScale( sm.vec3.new( sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio ) / bounds )
							end
							
							self.effects[ index + 1 ].effect:start()
							--print( "Created Item Effect Slot: ".. tostring(index + 1) )
						end
					end
					if self.effects[ index + 1 ] ~= nil then
						local pos = sm.vec3.new( -0.1, 0, 0.1 )--self.shape:getWorldPosition()			
		
						local offset = sm.vec3.new( SlotOffsets[index+1].z, SlotOffsets[index+1].y, SlotOffsets[index+1].x )
						pos = pos + offset			
						self.effects[ index + 1 ].effect:setOffsetPosition( pos )
						
						local angle = sm.quat.identity( )--self.shape:getWorldRotation()
						if isTool and ItemUUID ~= weapon_fant_bazooka and ItemUUID ~= weapon_fant_totebotmace and ItemUUID ~= weapon_fant_fork then
							angle = self.shape.worldRotation * sm.vec3.getRotation( sm.vec3.new( 0, -1, 0 ), sm.vec3.new( 0, 1, 0 ) )
						end
						self.effects[ index + 1 ].effect:setOffsetRotation( angle )
					end
				end
			else
				if self.effects[ index + 1 ] then
					if self.effects[ index + 1 ].uuid ~= nil then
						self.effects[ index + 1 ].effect:stop()
						self.effects[ index + 1 ].uuid = nil
						--print( "Destroy Item Effect Slot: ".. tostring(index + 1) )
					end
				end
			end
		else
			if self.effects[ index + 1 ] then
				if self.effects[ index + 1 ].uuid ~= nil then
					self.effects[ index + 1 ].effect:stop()
					self.effects[ index + 1 ].uuid = nil
					--print( "Destroy Item Effect Slot: ".. tostring(index + 1) )
				end
			end
		end
	end
end


