blocked = false
blocks = blocks or {}
Blocked_Data_Path = "$SURVIVAL_DATA/Objects/00fant/scripts/Blocked_Data.json"

function FantBlock_server_onCreate( self, data )
	print( "\nServer Blocked Player Manager Loaded!\n" )
	blocks = sm.json.open( Blocked_Data_Path )
	if blocks == nil then
		blocks = {}
		sm.json.save( blocks, Blocked_Data_Path )
	end
end

function FantBlock_sv_block( self, data )
	self.network:sendToClients( "cl_block", data )
	local character = data.player:getCharacter()
	character:setTumbling( true )
	character:setDowned( true )
	table.insert( blocks, data.player.name )
	sm.json.save( blocks, Blocked_Data_Path )
end

function FantBlock_cl_block( self, data )
	if data.player == sm.localPlayer.getPlayer() then
		sm.localPlayer.setLockedControls( 1 )
		sm.camera.setCameraState( sm.camera.state.cutsceneFP )
		sm.camera.setPosition( sm.vec3.new( 0, 0, -500 ) )
		sm.camera.setDirection( sm.vec3.new( 0, 0, -1 ) )
		g_survivalHud:close()
		--sm.game.setTimeOfDay( 0 )
		--sm.render.setOutdoorLighting( 0 )
		blocked = true
		if not sm.isHost then
			sm.gui.hideGui( 1 )
		end
		print( "You got Blocked!" )
	end
end

function FantBlock_sv_unblock( self, data )
	self.network:sendToClients( "cl_unblock", data )
	local character = data.player:getCharacter()
	character:setTumbling( false )
	character:setDowned( false )
	local newblock = {}
	for i, playername in pairs( blocks ) do 
		if data.player ~= nil and string.lower( data.player.name ) ~= string.lower( playername ) then
			table.insert( newblock, data.player.name )
		end
	end
	blocks = newblock
	sm.json.save( blocks, Blocked_Data_Path )
end

function FantBlock_cl_unblock( self, data )
	if data.player == sm.localPlayer.getPlayer() then
		sm.localPlayer.setLockedControls( 0 )
		sm.camera.setCameraState( sm.camera.state.default )
		g_survivalHud:open()
		--sm.game.setTimeOfDay( 0 )
		--sm.render.setOutdoorLighting( 0 )
		blocked = false
		sm.gui.hideGui( 0 )
		print( "You are Unblocked now!" )
	end
end

function FantBlock_server_onFixedUpdate( self, timeStep )
	if sm.isHost then
		if blocks ~= nil and #blocks > 0 then
			for i, playername in pairs( blocks ) do
				for i, listPlayer in pairs( sm.player.getAllPlayers( ) ) do 
					if listPlayer ~= nil and playername ~= nil and playername ~= "" then
						if listPlayer.name == playername then
							self.network:sendToClients( "cl_block", { player = listPlayer } )
							local character = listPlayer:getCharacter()
							if character ~= nil then
								character:setTumbling( true )
								character:setDowned( true )
							end
						end
					end
				end
			end
		end
	end
end


