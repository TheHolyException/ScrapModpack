FANT_MOD_VERSION = "Fant Mod 9.6"

dofile( "$SURVIVAL_DATA/mod_0.lua" )
dofile( "$SURVIVAL_DATA/mod_1.lua" )
dofile( "$SURVIVAL_DATA/mod_2.lua" )
dofile( "$SURVIVAL_DATA/mod_3.lua" )
dofile( "$SURVIVAL_DATA/mod_4.lua" )
dofile( "$SURVIVAL_DATA/mod_5.lua" )
dofile( "$SURVIVAL_DATA/mod_6.lua" )
dofile( "$SURVIVAL_DATA/mod_7.lua" )
dofile( "$SURVIVAL_DATA/mod_8.lua" )
dofile( "$SURVIVAL_DATA/mod_9.lua" )
function getMods()
	local ModText = "Mods:\n"
	
	ModText = ModText .. FANT_MOD_VERSION .. "\n"
	if EXTERN_MOD_0 ~= "" then
		ModText = ModText .. EXTERN_MOD_0 .. "\n"
	end
	if EXTERN_MOD_1 ~= "" then
		ModText = ModText .. EXTERN_MOD_1 .. "\n"
	end
	if EXTERN_MOD_2 ~= "" then
		ModText = ModText .. EXTERN_MOD_2 .. "\n"
	end
	if EXTERN_MOD_3 ~= "" then
		ModText = ModText .. EXTERN_MOD_3 .. "\n"
	end
	if EXTERN_MOD_4 ~= "" then
		ModText = ModText .. EXTERN_MOD_4 .. "\n"
	end
	if EXTERN_MOD_5 ~= "" then
		ModText = ModText .. EXTERN_MOD_5 .. "\n"
	end
	if EXTERN_MOD_6 ~= "" then
		ModText = ModText .. EXTERN_MOD_6 .. "\n"
	end
	if EXTERN_MOD_7 ~= "" then
		ModText = ModText .. EXTERN_MOD_7 .. "\n"
	end
	if EXTERN_MOD_8 ~= "" then
		ModText = ModText .. EXTERN_MOD_8 .. "\n"
	end
	if EXTERN_MOD_9 ~= "" then
		ModText = ModText .. EXTERN_MOD_9 .. "\n"
	end

	return ModText
end

