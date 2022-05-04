dofile "$SURVIVAL_DATA/Objects/00fant/scripts/fant_autocrafter.lua"

Fant_Itemframe = class()
Fant_Itemframe.maxParentCount = 1
Fant_Itemframe.connectionInput = sm.interactable.connectionType.logic

function Fant_Itemframe.server_onCreate( self )
	self.sv = {}
	self.sv.storage = self.storage:load()
	if self.sv.storage == nil then
		self.sv.storage = { rotationIndex = 1 } 
		self.storage:save( self.sv.storage )
	end
	self.rotationIndex = self.sv.storage.rotationIndex
	self.container = self.shape:getInteractable():getContainer(0)
	if not self.container then
		self.container = self.shape:getInteractable():addContainer( 0, 1, 1 )
	end
end

function Fant_Itemframe.client_onCreate( self )
	self.cl_updatetimer = 0
	self.effect = nil
	self.effectUUID = nil
	self.istool = false
	self.cl_rotationIndex = self.cl_rotationIndex or 1
	self.network:sendToServer( "sv_getData" )
	self:InitScaleRotations()
end

function Fant_Itemframe.InitScaleRotations( self )
	local Thickness = 0.05
	self.ratioVecs = {
		sm.vec3.new( sm.construction.constants.subdivideRatio, Thickness, sm.construction.constants.subdivideRatio ),
		sm.vec3.new( Thickness, sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio ),
		sm.vec3.new( sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio, Thickness ),
		
		sm.vec3.new( sm.construction.constants.subdivideRatio, Thickness, sm.construction.constants.subdivideRatio ),
		sm.vec3.new( Thickness, sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio ),
		sm.vec3.new( sm.construction.constants.subdivideRatio, Thickness, sm.construction.constants.subdivideRatio ),

		sm.vec3.new( Thickness, sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio ),
		sm.vec3.new( sm.construction.constants.subdivideRatio, Thickness, sm.construction.constants.subdivideRatio ),
		sm.vec3.new( sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio, Thickness ),
		
		sm.vec3.new( sm.construction.constants.subdivideRatio, Thickness, sm.construction.constants.subdivideRatio ),
		sm.vec3.new( sm.construction.constants.subdivideRatio, sm.construction.constants.subdivideRatio, Thickness ),
		sm.vec3.new( sm.construction.constants.subdivideRatio, Thickness, sm.construction.constants.subdivideRatio )
	}
	
	self.rotations = {
		nil,
		sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( -1, 0, 0 ) ),
		sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ),
		
		sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 1, 0, 0 ) ),
		sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 0, 1, 0 ) ),
		sm.vec3.getRotation( sm.vec3.new( 1, 0, 0 ), sm.vec3.new( 0, 0, 1 ) ),
		
		sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 1, 0, 0 ) ),
		sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 0, 1, 0 ) ),
		sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.vec3.new( 0, 0, 1 ) ),
		
		sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 1, 0, 0 ) ),
		sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) ),
		sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 0, 1 ) )
	}
end

function Fant_Itemframe.sv_getData( self )
	self.network:sendToClients( "cl_setData", { rotationIndex = self.rotationIndex } )	
end

function Fant_Itemframe.cl_setData( self, data )
	self.cl_rotationIndex = data.rotationIndex
end

function Fant_Itemframe.sv_setData( self, data )
	self.rotationIndex = data.rotationIndex
	self.sv.storage = { rotationIndex = self.rotationIndex } 
	self.storage:save( self.sv.storage )
end

function Fant_Itemframe.client_onDestroy( self )
	if self.effect ~= nil then
		self.effect:stop()
		self.effect:destroy()
		self.effect = nil
		self.effectUUID = nil
	end
end

function Fant_Itemframe.client_canInteract( self, character )
	sm.gui.setCenterIcon( "Use" )
	local keyBindingText =  sm.gui.getKeyBinding( "Use" )
	sm.gui.setInteractionText( "", keyBindingText, "Open Item Frame" )
	local keyBindingText =  sm.gui.getKeyBinding( "Tinker" )
	sm.gui.setInteractionText( "", keyBindingText, "Change Orientation" )
	return true
end

function Fant_Itemframe.client_onInteract(self, character, state)
	self.container = self.shape.interactable:getContainer( 0 )
	if state == true then
		self.gui = sm.gui.createContainerGui( true )
			
		self.gui:setText( "UpperName", "Item Frame" )
		self.gui:setContainer( "UpperGrid", self.container )	

		self.gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
		self.gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
		
		self.gui:open()			
	end
end

function Fant_Itemframe.client_onTinker( self, character, state )
	if state then
		self.cl_rotationIndex = self.cl_rotationIndex + 1
		if self.cl_rotationIndex > #self.ratioVecs then
			self.cl_rotationIndex = 1
		end
		--print( "cl_rotationIndex: ".. tostring( self.cl_rotationIndex ) )
		self.network:sendToServer( "sv_setData", { rotationIndex = self.cl_rotationIndex } )	
	end
end

function Fant_Itemframe.client_canCarry( self )
	self.container = self.shape.interactable:getContainer( 0 )
	if self.container and sm.exists( self.container ) then
		return not self.container:isEmpty()
	end
	return false
end

function Fant_Itemframe.getItemUUID( self, item )
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

function Fant_Itemframe.getItemUUID2( self, uuid )
	if uuid == nil then
		return nil, false
	end
	if uuid == tool_handbook then
		return nil, false
	end
	if uuid == tool_sledgehammer then
		return nil, false
	end
	if uuid == tool_lift then
		return nil, false
	end
	local externFuncResult = GetToolProxyItem( uuid )
	if externFuncResult ~= nil and externFuncResult ~= sm.uuid.getNil() then
		return externFuncResult, true
	end

	return uuid, false
end

function Fant_Itemframe.cl_setItem( self )
	if self.effectUUID ~= nil then
		--self:InitScaleRotations()
		if self.effect == nil then
			self.effect = sm.effect.createEffect( "ShapeRenderable", self.interactable )	
			self.effect:start()
			
			self.effect:setParameter( "uuid", self.effectUUID )

			
			--print( size )
				
		end
		local bounds = sm.item.getShapeSize( self.effectUUID )
		local size = bounds.x
		if bounds.y > size then
			size = bounds.y
		end
		if bounds.z > size then
			size = bounds.z
		end
		if self.istool then
			size = size / 0.2
		end
		self.effect:setScale( self.ratioVecs[ self.cl_rotationIndex ] / ( size / 0.6 ) )	
		
		local pos = sm.vec3.new( 0, -0.08, 0 )--self.shape:getWorldPosition()			
		if self.istool then
			pos = pos + ( self.shape.getUp( self.shape ) * -0.05 )
		end	
		self.effect:setOffsetPosition( pos )
		
		local angle = sm.quat.identity( )--self.shape:getWorldRotation()
		if self.cl_rotationIndex > 1 then
			angle = sm.quat.identity( ) * self.rotations[ self.cl_rotationIndex ]
		end
		
		self.effect:setOffsetRotation( angle )
	else
		if self.effect ~= nil then
			self.effect:stop()
			self.effect:destroy()
			self.effect = nil
		end
	end
end


function Fant_Itemframe.client_onUpdate( self, dt )
	
	if self.cl_updatetimer > 0 then
		self.cl_updatetimer = self.cl_updatetimer - dt
		if not sm.shape.getBody( self.shape ):isDynamic() then
			return
		end
	else
		self.cl_updatetimer = 0.25

		
		local Autocrafter = nil
		local parent = self.shape:getInteractable():getSingleParent()
		if parent then
			if sm.exists( parent.shape ) then
				if parent.shape:getShapeUuid() == obj_interactive_fant_autocrafter then
					Autocrafter = parent.shape:getInteractable()
				end
			end
		end

		local item = nil
		if Autocrafter == nil then
			local Container = self.shape:getInteractable():getContainer(0)
			
			if Container ~= nil then
				if Container:getItem( 0 ).uuid ~= sm.uuid.getNil( ) then
					item = Container:getItem( 0 )
				else
					local start = self.shape:getWorldPosition()
					local stop = self.shape:getWorldPosition() - sm.shape.getAt( self.shape ) * 0.25
					local valid, result = sm.physics.raycast( start, stop, self.shape )
					if result then
						local shape = result:getShape()
						if shape then
							local interactable = shape:getInteractable() 
							if interactable then
								Container = interactable:getContainer(0)
								if Container ~= nil then
									item = Container:getItem( 0 )
								end
							end
						end
					end
				end
			end

			self.effectUUID = nil
			self.istool = false

			if item ~= nil and item.quantity > 0 then
				local uuid, newisTool = self:getItemUUID( item )
				if self.effectUUID ~= uuid then
					if self.effect ~= nil then
						self.effect:stop()
						self.effect:destroy()
						self.effect = nil
					end
					self.effectUUID = uuid
					self.istool = newisTool
				end
			end	
		else
			if CL_AUTOCRAFTER_BLUEPRINTS ~= nil then
				if CL_AUTOCRAFTER_BLUEPRINTS[ Autocrafter.shape:getId() ] ~= nil then
					local uuid, istool = self:getItemUUID2( sm.uuid.new( CL_AUTOCRAFTER_BLUEPRINTS[ Autocrafter.shape:getId() ]["itemId"] ) )
					if self.effectUUID ~= uuid then
						if self.effect ~= nil then
							self.effect:stop()
							self.effect:destroy()
							self.effect = nil
						end
						self.effectUUID = uuid
						self.istool = istool
					end
				else
					self.effectUUID = nil
					self.istool = false
				end
			end
		end
		self:cl_setItem()
	end
	
end






