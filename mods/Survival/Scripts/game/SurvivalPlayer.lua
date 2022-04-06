dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_constants.lua"
dofile( "$SURVIVAL_DATA/Scripts/game/util/Timer.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/survival_camera.lua" )
dofile( "$SURVIVAL_DATA/Scripts/game/managers/QuestManager.lua" )

SurvivalPlayer = class( nil )

-- ExI Variables START --

-- Random

local fullyLoaded = false
local cl2

-- Control panel/settings

local ExI_Currentpage = 1
local ExI_Totalpages = 2

local RaidGuiStyleExpanded = false
local UnitExpanded = false
local ExI_ButtonsBelow = {
	Unit = { "SpeedometerOn", "SpeedometerOff", "CompOn", "CompOff" },
	RaidGUIStyle = { "RaidWarningOn", "RaidWarningOff", "RaidAdjustSizeOn", "RaidAdjustSizeOff" }
}
local PopUpYNOpen = false

local ExI_Toggles = {
	compass = { onOffName = "Comp", vis = { "TCCPanel" }, special = {} },
	raidWarnings = { onOffName = "RaidWarning", vis = {}, special = {} },
	DamageIndicator = { onOffName = "Indicator", vis = {}, special = {} },
	Animations = { onOffName = "Anims", vis = {}, special = {} },
	DynamicRaidBG = { onOffName = "RaidAdjustSize", vis = {}, special = {} },
	speedunit = { onOffName = "Unit", vis = {}, special = { {"km/h", "mph", "m/s"} } },
	speedometer = { onOffName = "Speedometer", vis = { "SpeedometerPanel" }, special = {} },
	clock = { onOffName = "Clock", vis = { "TimePanel" }, special = { nil, { type="questDone", quest=quest_pickup_logbook } } },
	counters = { onOffName = "Counter", vis = {}, special = {} },
	hitsLeft = { onOffName = "HitsLeft", vis = {}, special = {} }
}
--Specials: { Dropdown(Table={ "DropdownText1", "DropdownText2", etc }), canToggle(Table={ type = "questDone" , quest = quest_pickup_logbook(for example) }) }

-- Speedometer

local speedconv = 3.599
local speedUnittxt = " km/h"

-- Spud, Block, Paint and Seed counters

local counter1 = {
	visible = false,
	quantity = nil,
	anim_out = true,
	anim_active = false,
	anim_keyframe = 11
}

local counter2 = {
	visible = false,
	image = 0,
	quantity = nil,
	anim_out = true,
	anim_active = false,
	anim_keyframe = 16
}

local countwait = 0

local CounterUuids = {
	[tostring(tool_paint)]="gui_icon_hud_exi_paint.png",
	[tostring(obj_consumable_inkammo)]="gui_icon_hud_exi_paint.png",
	[tostring(obj_consumable_fertilizer)]="gui_icon_hud_exi_fertilizer.png",
	[tostring(obj_consumable_soilbag)]="gui_icon_hud_exi_soilbag.png"
}

for k,v in pairs(sm.item.getInteractablesUuidsOfType("block")) do
	if sm.item.isBlock(v) then CounterUuids[tostring(v)] = "gui_icon_hud_exi_blocks.png" end
end
for k,v in pairs(sm.item.getPlantableUuids()) do
	CounterUuids[tostring(v)] = "gui_icon_hud_exi_seeds.png"
end

local SpudgunUuids = {
	tool_spudgun,
	tool_shotgun,
	tool_gatling
}

-- Raid Gui

-- a (animation): 1 = standby, 2 = send, 3 = receive
-- w (wait)

-- RAIDMSGS IS FOR FUTURE UPDATE
--[[local raidmsgs = {
	{
		{a = 1, w = 1},
		{a = 3, w = 3 },
		{a = 3, w = 6, m = "#ffffffReceiving raid warning message from a warehouse..."},
		{a = 1, w = 5, m = "#ffffffMessage received. Translating..."},
		{a = 1, w = 2, m = "#ffffffTranslated: ´#ffff00Unauthorized farming detected! Units are being sent to your location.#ffffff`"},
		{a = 2, w = 5, m = "#ffffffRequesting info on raid..." },
		{a = 3, w = 3},
		{a = 3, w = 1, m = "#ff0000ERROR: ACCESS DENIED.#ffffff"},
		{a = 1, w = 0},
		{a = 2, w = 11, m = "#ffffffTrying to get permission. Hacking into farmbot systems..."},
		{a = 2, w = 5, m = "#ffffffRequesting info on raid..."},
		{a = 1, w = 2},
		{a = 3, w = 5},
		{a = 1, w = 3, m = "#55ff55Success! #ffffff(Returned: #ffff8c4e 65 76 65 72 20 67 6f 6e 6e 61 20 67 69 76 65 20 79 6f 75 20 75 70 2c 20 6e 65 76 65 72 20 67 6f 6e 6e 61 20 6c 65 74 20 79 6f 75 20 64 6f 77 6e#ffffff)"},
		{a = 1, w = 5, m = "#ffffffDecoding raid info..."},
		{a = 1, w = 5, m = "#ffffffUpdating local raid info..."},
		{a = 1, w = 5, m = "#55ff55Complete.#ffffff"}
	},
	{
		{a = 1, w = 1},
		{a = 3, w = 3 },
		{a = 3, w = 6, m = "#ffffffReceiving raid warning message from a warehouse..."},
		{a = 1, w = 5, m = "#ffffffMessage received. Translating..."},
		{a = 1, w = 2, m = "#ffffffTranslated: ´#ffff00Unauthorized farming detected! Units will be sent to your location. Do not continue farming like this. We are warning you.#ffffff`"},
		{a = 2, w = 5, m = "#ffffffRequesting info on raid..." },
		{a = 3, w = 3},
		{a = 3, w = 1, m = "#ff0000ERROR: ACCESS DENIED.#ffffff"},
		{a = 1, w = 0},
		{a = 2, w = 11, m = "#ffffffTrying to get permission. Hacking into farmbot systems..."},
		{a = 2, w = 5, m = "#ffffffRequesting info on raid..."},
		{a = 1, w = 2},
		{a = 3, w = 5},
		{a = 1, w = 0, m = "#ff0000ERROR: ACCESS DENIED.#ffffff"},
		{a = 1, w = 3, m = "Attempt failed. Retrying..."},
		{a = 2, w = 5, m = "#ffffffHacking into farmbot systems..."},
		{a = 2, w = 5, m = "#ffffffRequesting info on raid..."},
		{a = 1, w = 2},
		{a = 3, w = 5},
		{a = 1, w = 3, m = "#55ff55Success! #ffffff(Returned: #ffff8c68 74 74 70 73 3a 2f 2f 77 77 77 2e 79 6f 75 74 75 62 65 2e 63 6f 6d 2f 77 61 74 63 68 3f 76 3d 66 43 37 6f 55 4f 55 45 45 69 34#ffffff)"},
		{a = 1, w = 5, m = "#ffffffDecoding raid info..."},
		{a = 1, w = 5, m = "#ffffffUpdating local raid info..."},
		{a = 1, w = 5, m = "#55ff55Complete.#ffffff"}
	},
	{
		{a = 1, w = 1},
		{a = 3, w = 3 },
		{a = 3, w = 6, m = "#ffffffReceiving raid warning message from a warehouse..."},
		{a = 3, w = 11, m = "#ff8002Warning: weak signal detected.#ffffff"},
		{a = 1, w = 5, m = "#ffffffMessage received. Translating..."},
		{a = 1, w = 2, m = "#ffffffTranslated: ´#ffff00Un░░thori░░dd fa░miNg dEte░░ed! Our ░armBO░s WI░l ░e sent out to take careEee░░ o0o░f t░░t. ░░jfsd░uh░-░*░-*-43░░cdhgbri░dhf░cd74#ffffff` Error. Corruption detected"},
		{a = 2, w = 5, m = "#ffffffRequesting info on raid..." },
		{a = 3, w = 3},
		{a = 3, w = 1, m = "#ff0000ERROR: ACC̶E̸S̷S D░NIED.#ffffff"},
		{a = 1, w = 0},
		{a = 2, w = 16, m = "#ffffffTrying to get permission. Hacking into farmbot systems..."},
		{a = 2, w = 5, m = "#ffffffRequesting info on raid..."},
		{a = 1, w = 2},
		{a = 3, w = 5},
		{a = 1, w = 3, m = "#55ff55Success! #ffffff(Returned: #ffff8c43 6f 72 72 75 70 74 69 6f 6e 20 64 65 74 65 63 74 65 64 2e 20 43 6f 75 6c 64 20 6e 6f 74 20 62 65 20 72 65 61 64#ffffff)"},
		{a = 1, w = 15, m = "#ffffffDecoding raid info... (May take longer due to detected corruption in data)"},
		{a = 1, w = 5, m = "#ffffffUpdating local raid info..."},
		{a = 1, w = 5, m = "#55ff55Complete.#ffffff"}
	}


}

local consoletxt = ""
local consolebuffer = ""
local consolespeed
local animstate = {currentAnim = 1, keyFrame = 0, progress = 1, rngRaidMsg = nil}
local logbookanims = {
	{"1"},
	{"1", "2", "3", "4", "5", "6"},
	{"1", "7", "8", "9", "10", "11"}
}
local logbookanim_timer = 0
local logbookactiontimer = 0--]]

local RGuiStyleNames = {
	"Classic",
	"Scrap Mechanic",
	"[Coming soon]"
}

local raidGuiKeys = {nil, nil, nil, nil}
local raidValues = { {}, {}, {}, {} }
local raidAmountVis = 0
local raidGuiExtra = 0
local highestlevelraid = 0

local prevtime = 0

local warn1 = 60
local warn2_L = 30.99
local warn2_G = 10
local warn3 = 9.99
local warn4 = 100000

local warns = {
	["7"] = { w1 = 60, w2_L = 20.99, w2_G = 10, w3 = 9.99, w4 = 120 },
	["4"] = { w1 = 60, w2_L = 20.99, w2_G = 10, w3 = 9.99, w4 = 30 },
	["3"] = { w1 = 60, w2_L = 15.99, w2_G = 5, w3 = 4.99, w4 = 30 },
	["1"] = { w1 = 60, w2_L = 8.99, w2_G = 5, w3 = 4.99, w4 = 30 }
}
local warns_spudgun = {
	["10"] = { w1 = 60, w2_L = 20.99, w2_G = 10, w3 = 9.99, w4 = 120 },
	["7"] = { w1 = 60, w2_L = 15.99, w2_G = 8, w3 = 7.99, w4 = 30 },
	["4"] = { w1 = 45, w2_L = 10.99, w2_G = 5, w3 = 4.99, w4 = 20 },
	["1"] = { w1 = 45, w2_L = 5.99, w2_G = 2, w3 = 1.99, w4 = 15 }
}


local CountUpdateCols = { "#ff9595", "Red" }
local Multiplr_WaitWithOpen1 = false
local Multiplr_WaitWithOpen2 = false

-- Raid Calculator
local rcalcvisible = false
local rcalcvals = {carrot=0,tomato=0,redbeet=0,banana=0,blueberry=0,orange=0,potato=0,cotton=0,pineapple=0,broccoli=0}
local ExI_cropValue = {carrot=1,tomato=1,redbeet=1,banana=2,blueberry=2,orange=2,potato=1.5,cotton=1.5,pineapple=3,broccoli=3}
local ExI_cropTypes = {
	"carrot",
	"tomato",
	"redbeet",
	"banana",
	"blueberry",
	"orange",
	"potato",
	"cotton",
	"pineapple",
	"broccoli"
}

local ExI_cropTypeShortcuts = {
	ct="carrot",
	to="tomato",
	rt="redbeet",
	ba="banana",
	by="blueberry",
	oe="orange",
	po="potato",
	cn="cotton",
	pe="pineapple",
	bi="broccoli"
}

-- Compass
local compText = "E..............SE..............S..............SW..............W..............NW..............N..............NE.............."

-- Damage Indicator
local lookingAtCharacter
local sv_lookingAtCharacter = { }
local barlengthOld = 0
local HPBarlength = 0
local Indicator_HPBarActive = false
local Indicator_StayVis = 15
local IndicatorStats = {
	["Totebot"] = { { "     Melee: 15", "gui_icon_hud_exi_melee.png" }, true },
	["Haybot"] = { { "     Melee: 20-30", "gui_icon_hud_exi_melee.png" }, true },
	["Tapebot"] = { { "     Ranged: 55", "gui_icon_hud_exi_ranged.png" }, true },
	["Red Tapebot"] = { { "     Ranged: 62 (Explosion)", "gui_icon_hud_exi_ranged.png" }, true },
	["Farmbot"] = { { "     Melee: 10-35", "gui_icon_hud_exi_melee.png" }, { "     Ranged: 6/s (Pesticide)", "gui_icon_hud_exi_ranged.png" }, true },
	["Woc"] = { true },
	["Glowb"] = { true },
	["Shark  (ikey07)"] = { { "     Melee: 15", "gui_icon_hud_exi_melee.png" }, true },
	["Duck  (ikey07)"] = { true }
}
local Indicator_HasIcons = {
	"Totebot",
	"Haybot",
	"Tapebot",
	"Red Tapebot",
	"Farmbot",
	"Woc",
	"Glowb"
}

-- ExI Variables END --

local StatsTickRate = 40

local PerSecond = StatsTickRate / 40
local PerMinute = StatsTickRate / ( 40 * 60 )

local FoodRecoveryThreshold = 5 -- Recover hp when food is above this value
local FastFoodRecoveryThreshold = 50 -- Recover hp fast when food is above this value
local HpRecovery = 50 * PerMinute
local FastHpRecovery = 75 * PerMinute
local FoodCostPerHpRecovery = 0.2
local FastFoodCostPerHpRecovery = 0.2

local FoodCostPerStamina = 0.02
local WaterCostPerStamina = 0.1
local SprintStaminaCost = 0.7 / 40 -- Per tick while sprinting
local CarryStaminaCost = 1.4 / 40 -- Per tick while carrying

local FoodLostPerSecond = 100 / 3.5 / 24 / 60
local WaterLostPerSecond = 100 / 2.5 / 24 / 60

local BreathLostPerTick = ( 100 / 60 ) / 40

local FatigueDamageHp = 1 * PerSecond
local FatigueDamageWater = 2 * PerSecond
local FireDamage = 10
local FireDamageCooldown = 40
local DrownDamage = 5
local DrownDamageCooldown = 40
local PoisonDamage = 10
local PoisonDamageCooldown = 40

local RespawnTimeout = 60 * 40

local RespawnFadeDuration = 0.45
local RespawnEndFadeDuration = 0.45

local RespawnFadeTimeout = 5.0
local RespawnDelay = RespawnFadeDuration * 40
local RespawnEndDelay = 1.0 * 40

local BaguetteSteps = 9

local StopTumbleTimerTickThreshold = 1.0 * 40 -- Time to keep tumble active after speed is below threshold
local MaxTumbleTimerTickThreshold = 20.0 * 40 -- Maximum time to keep tumble active before timing out
local TumbleResistTickTime = 3.0 * 40 -- Time that the player will resist tumbling after timing out
local MaxTumbleImpulseSpeed = 35
local RecentTumblesTickTimeInterval = 30.0 * 40 -- Time frame to count amount of tumbles in a row
local MaxRecentTumbles = 3

--Function modified by WaspEyeNight
function SurvivalPlayer.server_onCreate( self )
	self.sv = {}
	self.sv.saved = self.storage:load()
	if self.sv.saved == nil then
		self.sv.saved = {}
		self.sv.saved.stats = {
			hp = 100, maxhp = 100,
			food = 100, maxfood = 100,
			water = 100, maxwater = 100,
			breath = 100, maxbreath = 100
		}
		self.sv.saved.isConscious = true
		self.sv.saved.hasRevivalItem = false
		self.sv.saved.isNewPlayer = true
		self.sv.saved.inChemical = false
		self.sv.saved.inOil = false
		self.storage:save( self.sv.saved )
	end

	--WEN modifed from here
	if self.sv.saved.exi == nil then
		if self.sv.saved then
			self.sv.saved.exi = {}
			--Settings
			self.sv.saved.exi.speedunit = 1
			self.sv.saved.exi.compass = true
			self.sv.saved.exi.raidGui = true
			self.sv.saved.exi.raidWarnings = true
			self.sv.saved.exi.Animations = true
			self.sv.saved.exi.clock = true
			self.sv.saved.exi.speedometer = true
			self.sv.saved.exi.DamageIndicator = true
			self.sv.saved.exi.RaidGUIStyle = 1
			self.sv.saved.exi.DynamicRaidBG = false
			self.sv.saved.exi.counters = true
			self.sv.saved.exi.hitsLeft = true

			self.sv.saved.exi.saveVersion = 2
			--[[
			Save version 0:
			{exi.speedunit, exi.compass, exi.raidGui, exi.raidWarnings, exi.Animations, exi.clock, exi.speedometer, exi.RaidGUIStyle}
			Save version 1:
			{exi.DamageIndicator, exi.dynamicRaidBG}
			Save version 2:
			{exi.counters, exi.hitsLeft}
			]]
			self.storage:save( self.sv.saved )
		end
	elseif self.sv.saved.exi.saveVersion ~= 2 then
		print("Updating Expanded info save version to version 2...")
		local saveexi = self.sv.saved.exi
		if saveexi.saveVersion <= 0 then
			saveexi.DamageIndicator = true
			saveexi.DynamicRaidBG = false
			saveexi.speedunit = saveexi.speedunit+1
		end
		if saveexi.saveVersion <= 1 then
			saveexi.counters = true
			saveexi.hitsLeft = true
		end



		saveexi.saveVersion = 2
		self.storage:save( self.sv.saved )
	end
	--to here

	self:sv_init()
end

function SurvivalPlayer.server_onRefresh( self )
	self:sv_init()
end

--Function modified by WaspEyeNight
function SurvivalPlayer.sv_init( self )

	sv_lookingAtCharacter[self.player.id] = {charId = nil, data = {}, update = false } --Added by WEN
	self.sv.updateExiSettings = {} --Added by WEN

	self.sv.staminaSpend = 0
	self.sv.blocking = false

	self.sv.statsTimer = Timer()
	self.sv.statsTimer:start( StatsTickRate )

	self.sv.damageCooldown = Timer()
	self.sv.damageCooldown:start( 3.0 * 40 )

	self.sv.impactCooldown = Timer()
	self.sv.impactCooldown:start( 3.0 * 40 )

	self.sv.fireDamageCooldown = Timer()
	self.sv.fireDamageCooldown:start()

	self.sv.poisonDamageCooldown = Timer()
	self.sv.poisonDamageCooldown:start()

	self.sv.drownTimer = Timer()
	self.sv.drownTimer:stop()

	self.sv.tumbleReset = Timer()
	self.sv.tumbleReset:start( StopTumbleTimerTickThreshold )

	self.sv.maxTumbleTimer = Timer()
	self.sv.maxTumbleTimer:start( MaxTumbleTimerTickThreshold )

	self.sv.resistTumbleTimer = Timer()
	self.sv.resistTumbleTimer:start( TumbleResistTickTime )
	self.sv.resistTumbleTimer.count = TumbleResistTickTime

	self.sv.recentTumbles = {}

	self.sv.spawnparams = {}

	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.server_onDestroy( self )

	-- TODO: make this work
	self.storage:save( self.sv.saved )
end

-- Function modified by WaspEyeNight
function SurvivalPlayer.client_onCreate( self )
	self.cl = {}
	if self.player == sm.localPlayer.getPlayer() then
		if g_survivalHud then
			g_survivalHud:open()
		end

		--Function modifed from here
		local files = ""
		if not pcall(function() UnitManager:client_filecheck() end) then files = files.. "UnitManager.lua, " end
		if not pcall(function() SurvivalGame:client_filecheck() end) then files = files.. "SurvivalGame.lua, " end
		if files == "UnitManager.lua, SurvivalGame.lua, " then files = "UnitManager.lua and SurvivalGame.lua, " end
		if files ~= "" then sm.gui.chatMessage("#ff0000Code for Expanded info might be missing from ".. files.. "and all parts of the mod might not function properly. Please reinstall the mod, if you still get this message after reinstalling please leave a comment on the mod page about the issue.")
		else sm.gui.chatMessage("#a3a3a3Thank you ".. sm.localPlayer.getPlayer().name.. " for using Expanded info!")
			--Comment the line above if you want to disable the "Thank you for using Expanded info" message.
		end

		ExI_CtrlpanelGUI = sm.gui.createGuiFromLayout( "$GAME_DATA/Gui/Layouts/Expanded_info/ExI_Controllpanel.layout" )

		--Set button callbacks
		ExI_CtrlpanelGUI:setButtonCallback( "CompOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "CompOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "UnitOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "UnitOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "RaidGUIOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "RaidGUIOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "RaidWarningOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "RaidWarningOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "AnimsOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "AnimsOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "ClockOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "ClockOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "SpeedometerOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "SpeedometerOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "RaidGUIStyleBtn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "RaidGUIStyle1", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "RaidGUIStyle2", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "RaidGUIStyle3", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "UnitBtn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "Unit1", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "Unit2", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "Unit3", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "IndicatorOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "IndicatorOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "CounterOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "CounterOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "HitsLeftOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "HitsLeftOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "RaidAdjustSizeOn", "client_exiConButton" )
		ExI_CtrlpanelGUI:setButtonCallback( "RaidAdjustSizeOff", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "Default", "client_exiConButton" )

		ExI_CtrlpanelGUI:setButtonCallback( "Prev", "client_exiChangePage" )
		ExI_CtrlpanelGUI:setButtonCallback( "Next", "client_exiChangePage" )
		ExI_CtrlpanelGUI:setText( "Tracker", tostring(ExI_Currentpage).. "/".. tostring(ExI_Totalpages) )

		ExI_CtrlpanelGUI:setButtonCallback("PopUpYNYes", "client_exiConButton")
		ExI_CtrlpanelGUI:setButtonCallback("PopUpYNNo", "client_exiConButton")

		ExI_CtrlpanelGUI:setOnCloseCallback( "client_onexiConfigClose" )

		--Preload images
		g_survivalHud:setVisible("LoadImgsPanel", true)
		g_survivalHud:setImage("LoadImgs", "gui_icon_hud_exi_blocks.png")
		g_survivalHud:setImage("LoadImgs", "gui_icon_hud_exi_seeds.png")
		g_survivalHud:setImage("LoadImgs", "gui_icon_hud_exi_paint.png")
		g_survivalHud:setImage("LoadImgs", "gui_icon_hud_exi_fertilizer.png")
		g_survivalHud:setImage("LoadImgs", "gui_icon_hud_exi_soilbag.png")
		g_survivalHud:setVisible("LoadImgsPanel", false)

		--to here

		self.cl.hungryEffect = sm.effect.createEffect( "Mechanic - StatusHungry" )
		self.cl.thirstyEffect = sm.effect.createEffect( "Mechanic - StatusThirsty" )
		self.cl.underwaterEffect = sm.effect.createEffect( "Mechanic - StatusUnderwater" )
	end

	self:cl_init()
end

function SurvivalPlayer.client_onRefresh( self )
	self:cl_init()

	sm.gui.hideGui( false )
	sm.camera.setCameraState( sm.camera.state.default )
	sm.localPlayer.setLockedControls( false )
end

function SurvivalPlayer.cl_init(self)
	self.useCutsceneCamera = false
	self.progress = 0
	self.nodeIndex = 1
	self.currentCutscene = {}

	self.cl.revivalChewCount = 0
end

function SurvivalPlayer.cl_n_onEvent( self, data )

	local function getCharParam()
		if self.player:isMale() then
			return 1
		else
			return 2
		end
	end

	local function playSingleHurtSound( effect, pos, damage )
		local params = {
			["char"] = getCharParam(),
			["damage"] = damage
		}
		sm.effect.playEffect( effect, pos, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), params )
	end

	if data.event == "drown" then
		playSingleHurtSound( "Mechanic - HurtDrown", data.pos, data.damage )
	elseif data.event == "fatigue" then
		playSingleHurtSound( "Mechanic - Hurthunger", data.pos, data.damage)
	elseif data.event == "shock" then
		playSingleHurtSound( "Mechanic - Hurtshock", data.pos, data.damage )
	elseif data.event == "impact" then
		playSingleHurtSound( "Mechanic - Hurt", data.pos, data.damage )
	elseif data.event == "fire" then
		playSingleHurtSound( "Mechanic - HurtFire", data.pos, data.damage )
	elseif data.event == "poison" then
		playSingleHurtSound( "Mechanic - Hurtpoision", data.pos, data.damage )
	end
end

--Function modified by WaspEyeNight
function SurvivalPlayer.client_onClientDataUpdate( self, data )
	if sm.localPlayer.getPlayer() == self.player then

		if self.cl.stats == nil then self.cl.stats = data.stats end -- First time copy to avoid nil errors

		if g_survivalHud then
			g_survivalHud:setSliderData( "Health", data.stats.maxhp * 10 + 1, data.stats.hp * 10 )
			g_survivalHud:setSliderData( "Food", data.stats.maxfood * 10 + 1, data.stats.food * 10 )
			g_survivalHud:setSliderData( "Water", data.stats.maxwater * 10 + 1, data.stats.water * 10 )
			g_survivalHud:setSliderData( "Breath", data.stats.maxbreath * 10 + 1, data.stats.breath * 10 )
		end

		if self.cl.hasRevivalItem ~= data.hasRevivalItem then
			self.cl.revivalChewCount = 0
		end

		if self.player.character then
			local charParam = self.player:isMale() and 1 or 2
			self.cl.underwaterEffect:setParameter( "char", charParam )
			self.cl.hungryEffect:setParameter( "char", charParam )
			self.cl.thirstyEffect:setParameter( "char", charParam )

			if data.stats.breath <= 15 and not self.cl.underwaterEffect:isPlaying() and data.isConscious then
				self.cl.underwaterEffect:start()
			elseif ( data.stats.breath > 15 or not data.isConscious ) and self.cl.underwaterEffect:isPlaying() then
				self.cl.underwaterEffect:stop()
			end
			if data.stats.food <= 5 and not self.cl.hungryEffect:isPlaying() and data.isConscious then
				self.cl.hungryEffect:start()
			elseif ( data.stats.food > 5 or not data.isConscious ) and self.cl.hungryEffect:isPlaying() then
				self.cl.hungryEffect:stop()
			end
			if data.stats.water <= 5 and not self.cl.thirstyEffect:isPlaying() and data.isConscious then
				self.cl.thirstyEffect:start()
			elseif ( data.stats.water > 5 or not data.isConscious ) and self.cl.thirstyEffect:isPlaying() then
				self.cl.thirstyEffect:stop()
			end
		end

		if data.stats.food <= 5 and self.cl.stats.food > 5 then
			sm.gui.displayAlertText( "#{ALERT_HUNGER}", 5 )
		end
		if data.stats.water <= 5 and self.cl.stats.water > 5 then
			sm.gui.displayAlertText( "#{ALERT_THIRST}", 5 )
		end

		if data.stats.hp < self.cl.stats.hp and data.stats.breath == 0 then
			sm.gui.displayAlertText( "#{DAMAGE_BREATH}", 1 )
		elseif data.stats.hp < self.cl.stats.hp and data.stats.food == 0 then
			sm.gui.displayAlertText( "#{DAMAGE_HUNGER}", 1 )
		elseif data.stats.hp < self.cl.stats.hp and data.stats.water == 0 then
			sm.gui.displayAlertText( "#{DAMAGE_THIRST}", 1 )
		end

		self.cl.stats = data.stats
		self.cl.isConscious = data.isConscious
		self.cl.hasRevivalItem = data.hasRevivalItem
		self.cl.inChemical = data.inChemical
		self.cl.inOil = data.inOil

		sm.localPlayer.setBlockSprinting( data.stats.food == 0 or data.stats.water == 0 )

		--WEN modified from here
		self.cl.exi = data.exi
		cl2 = self.cl
		if Multiplr_WaitWithOpen1 == true then
			g_survivalHud:setVisible("RaidBackground", true)
			self:client_raidguicmd("t", nil, false)
			self:client_raidguicmd("t", nil, false)
			Multiplr_WaitWithOpen1 = false
		elseif Multiplr_WaitWithOpen2 == true then
			g_survivalHud:setVisible("ExtraRaids", true)
			Multiplr_WaitWithOpen2 = false
		end
		if not fullyLoaded then
			--Update buttons in the control panel
			self:client_OnOffButton("Comp", self.cl.exi.compass)
			self:client_OnOffButton("RaidGUI", self.cl.exi.raidGui)
			self:client_OnOffButton("RaidWarning", self.cl.exi.raidWarnings)
			self:client_OnOffButton("Anims", self.cl.exi.Animations)
			self:client_OnOffButton("Clock", self.cl.exi.clock)
			self:client_OnOffButton("Speedometer", self.cl.exi.speedometer)
			self:client_OnOffButton("Indicator", self.cl.exi.DamageIndicator)
			self:client_OnOffButton("RaidAdjustSize", self.cl.exi.DynamicRaidBG)
			self:client_OnOffButton("Counter", self.cl.exi.counters)
			self:client_OnOffButton("HitsLeft", self.cl.exi.hitsLeft)

			ExI_CtrlpanelGUI:setText("RaidGUIStyleValue", RGuiStyleNames[ self.cl.exi.RaidGUIStyle ] )
			for i=1,3 do
				local col = "#757575"
				if self.cl.exi.RaidGUIStyle == i then col = "#ffd449" end
				ExI_CtrlpanelGUI:setText("RaidGUIStyle".. tostring(i).. "Text", col.. RGuiStyleNames[i])
			end

			if self.cl.exi.speedunit == 1 then
				ExI_CtrlpanelGUI:setText("Unit1Text", "#ffd449km/h")
				ExI_CtrlpanelGUI:setText("Unit2Text", "#757575mph")
				ExI_CtrlpanelGUI:setText("Unit3Text", "#757575m/s")
				ExI_CtrlpanelGUI:setText("UnitValue", "km/h" )
				speedconv = 3.599
				speedUnittxt = " km/h"
			elseif self.cl.exi.speedunit == 2 then
				ExI_CtrlpanelGUI:setText("Unit1Text", "#757575km/h")
				ExI_CtrlpanelGUI:setText("Unit2Text", "#ffd449mph")
				ExI_CtrlpanelGUI:setText("Unit3Text", "#757575m/s")
				ExI_CtrlpanelGUI:setText("UnitValue", "mph" )
				speedconv = 2.237
				speedUnittxt = " mph"
			else
				ExI_CtrlpanelGUI:setText("Unit1Text", "#757575km/h")
				ExI_CtrlpanelGUI:setText("Unit2Text", "#757575mph")
				ExI_CtrlpanelGUI:setText("Unit3Text", "#ffd449m/s")
				ExI_CtrlpanelGUI:setText("UnitValue", "m/s" )
				speedconv = 1
				speedUnittxt = " m/s"
			end

			--Other
			g_survivalHud:setVisible("TCCPanel", self.cl.exi.compass)
			g_survivalHud:setVisible("SpeedometerPanel", self.cl.exi.speedometer)
			Client_registerOnCompleteQuestObserver( quest_pickup_logbook, function( observedCompletion )
				g_survivalHud:setVisible("TimePanel", self.cl.exi.clock)
			end)

			g_survivalHud:setVisible("RaidGui_Style1", false)
			g_survivalHud:setVisible("RaidGui_Style2", false)
			g_survivalHud:setVisible("RaidGui_Style3", false)
			g_survivalHud:setVisible("RaidGui_Style4", false)
			g_survivalHud:setVisible("RaidGui_Style".. tostring(self.cl.exi.RaidGUIStyle), true)
			if self.cl.exi.RaidGUIStyle == 2 then CountUpdateCols = { "#ffffff", "Orange" } end

			fullyLoaded = true
		end
		--To here

	end
end

function SurvivalPlayer.client_onUpdate( self, dt )
	if self.player == sm.localPlayer.getPlayer() then
		self:cl_localPlayerUpdate( dt )
	end
end

local CellSize = 64 -- Added by WEN

-- Function modified by WaspEyeNight
function SurvivalPlayer.cl_localPlayerUpdate( self, dt )
	self:cl_updateCamera( dt )

	local character = self.player:getCharacter()
	if character and not self.cl.isConscious then
		local keyBindingText =  sm.gui.getKeyBinding( "Use" )
		if self.cl.hasRevivalItem then
			if self.cl.revivalChewCount < BaguetteSteps then
				-- sm.gui.setInteractionText( "#{INTERACTION_PRESS}", keyBindingText, "to eat ("..self.cl.revivalChewCount.."/10)" )
				sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_EAT} ("..self.cl.revivalChewCount.."/10)" )
			else
				sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_REVIVE}" )
			end
		else
			sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_RESPAWN}" )
		end
	end

	if character and character:isTumbling() then
		if sm.camera.getCameraState() == sm.camera.state.default then
			sm.camera.setCameraState( sm.camera.state.forcedTP )
			self.cl.tumbleCamera = true
		end
	elseif self.cl.tumbleCamera then
		if sm.camera.getCameraState() == sm.camera.state.default then
			self.cl.tumbleCamera = false
		elseif sm.camera.getCameraState() == sm.camera.state.forcedTP then
			sm.camera.setCameraState( sm.camera.state.default )
			self.cl.tumbleCamera = false
		end
	end

	if character and character:isSwimming() and not self.cl.inChemical and not self.cl.inOil then
		self:cl_n_fillWater()
	end

	if character then
		self.cl.underwaterEffect:setPosition( character.worldPosition )
		self.cl.hungryEffect:setPosition( character.worldPosition )
		self.cl.thirstyEffect:setPosition( character.worldPosition )

		--WEN modified from here
		local mfloor = math.floor
		if self.cl.exi.compass == true then
			local charNum = #compText
			local direction = character.direction
			local yaw = math.atan2( direction.y, direction.x )
			local rot = math.deg( yaw )
			local textDegrees = math.ceil( rot-90 )
			local fittext = charNum/2 + (charNum * rot/360)
			local movepos = math.fmod(charNum-fittext,charNum)

			local coordinates = mfloor( character.worldPosition.x).. ",".. mfloor( character.worldPosition.y)
			local cellCoord = mfloor( character.worldPosition.x / CellSize )..","..mfloor( character.worldPosition.y / CellSize )
			local newComptxt = compText:sub(mfloor(movepos)+2, charNum).. compText:sub(1, mfloor(movepos))

			local compTextNum = mfloor( movepos%1 * 5 )
			local textBox = "CompassText".. tostring( compTextNum )

			if textDegrees > 0 then
				textDegrees = textDegrees-360
			end
			textDegrees = math.abs(textDegrees)

			g_survivalHud:setVisible("CompassText0", false)
			g_survivalHud:setVisible("CompassText1", false)
			g_survivalHud:setVisible("CompassText2", false)
			g_survivalHud:setVisible("CompassText3", false)
			g_survivalHud:setVisible("CompassText4", false)

			g_survivalHud:setVisible( textBox, true )
			g_survivalHud:setText( textBox, newComptxt )

			g_survivalHud:setText( "CompassDegree", tostring(textDegrees) )
			g_survivalHud:setText( "CoordText", coordinates )
			g_survivalHud:setText( "CellText", cellCoord )
		end
		
		
		--ANIM 1
		if counter1.anim_active then
			for i = 1,10 do
				g_survivalHud:setVisible("SpudCounterBg".. tostring(i), false)
			end

			if counter1.anim_out then
				counter1.anim_keyframe = counter1.anim_keyframe-(dt*60)
				if counter1.anim_keyframe <= 1.5 then counter1.anim_active = false counter1.anim_keyframe = 1 end
				g_survivalHud:setVisible("SpudCounterBg".. tostring(round(counter1.anim_keyframe)) , true)
			else
				counter1.anim_keyframe = counter1.anim_keyframe+(dt*60)
				if counter1.anim_keyframe >= 10.5 then counter1.anim_active = false counter1.anim_keyframe = 11 end
				g_survivalHud:setVisible("SpudCounterBg".. tostring(round(counter1.anim_keyframe)) , true)
			end
		end
		--ANIM 2
		if counter2.anim_active then
			for i = 1,15 do
				g_survivalHud:setVisible("CounterPanel".. tostring(i), false)
			end

			if counter2.anim_out then
				counter2.anim_keyframe = counter2.anim_keyframe-(dt*60)
				if counter2.anim_keyframe <= 1.5 then counter2.anim_active = false counter2.anim_keyframe = 1 end
				g_survivalHud:setVisible("CounterPanel".. tostring(round(counter2.anim_keyframe)) , true)
			else
				counter2.anim_keyframe = counter2.anim_keyframe+(dt*60)
				if counter2.anim_keyframe >= 15.5 then counter2.anim_active = false counter2.anim_keyframe = 16 end
				g_survivalHud:setVisible("CounterPanel".. tostring(round(counter2.anim_keyframe)) , true)
			end
		end

		--Attack Indicator health bar "animation"
		if Indicator_HPBarActive then
			if self.cl.exi.Animations then
				if barlengthOld < round(HPBarlength) then
					barlengthOld = barlengthOld + ((((HPBarlength-barlengthOld)/10)+0.1)*dt*60)
				elseif barlengthOld > round(HPBarlength) then
					barlengthOld = barlengthOld - ((((barlengthOld-HPBarlength)/10)+0.1)*dt*60)
				end
			else
				barlengthOld = HPBarlength
			end
			g_survivalHud:setItemIcon( "Indicator_HPBar", "ExI_GuiMap", "ExI_Bar_Green", tostring(round(barlengthOld)) )
		end

		countwait = countwait + 1
		if countwait >= 2 then
			countwait = 0

			--Better unauthorized farming detected message (FOR FUTURE UPDATE)
			--[[if true then
				logbookanim_timer = logbookanim_timer+(dt*6)
				if logbookanim_timer > 1 then
					logbookanim_timer = 0
					logbookactiontimer = logbookactiontimer+1
					animstate.keyFrame = animstate.keyFrame+1
					if animstate.keyFrame > #logbookanims[animstate.currentAnim] then
						animstate.keyFrame = 1
					end
					g_survivalHud:setItemIcon( "test123", "ExI_GuiMap", "Antenna_LogbookAnim", logbookanims[animstate.currentAnim][animstate.keyFrame])

					if not animstate.rngRaidMsg then animstate.rngRaidMsg = math.random(1,#raidmsgs) end

					if logbookactiontimer > raidmsgs[animstate.rngRaidMsg or 1][animstate.progress].w then
						if animstate.progress >= #raidmsgs[animstate.rngRaidMsg] then
							animstate.progress = 1
							consoletxt = ""
							animstate.rngRaidMsg = nil
						end

						logbookactiontimer = 0
						animstate.progress = animstate.progress+1
						animstate.currentAnim = raidmsgs[animstate.rngRaidMsg or 1][animstate.progress].a
						if raidmsgs[animstate.rngRaidMsg or 1][animstate.progress].m then
							consolebuffer = consolebuffer.. "\n".. "(".. tostring(sm.game.getServerTick()).. ") ".. raidmsgs[animstate.rngRaidMsg][animstate.progress].m
							consolespeed = string.len(consolebuffer)*0.015
						end
					end
				end

				if consolebuffer ~= "" then
					if self.cl.exi.Animations then
						consoletxt = consoletxt.. consolebuffer:sub(1,math.floor(consolespeed*(dt*60)+1))
						consolebuffer = consolebuffer:sub(math.floor(consolespeed*(dt*60))+2)
					else
						consoletxt = consoletxt.. consolebuffer
						consolebuffer = ""
					end
					g_survivalHud:setText( "Console", consoletxt )
				end

			end--]]



			--Attack Indicator
			if self.cl.exi.DamageIndicator == true then
				local range = 15
				local isAiming = character:isAiming()
				if isAiming then range = 60 end
				local hit, result = sm.localPlayer.getRaycast( range )

				if hit and result.type == "character" then
					local charId = result:getCharacter():getId()
					if lookingAtCharacter ~= charId then
						lookingAtCharacter = charId
						self.network:sendToServer("sv_updatePlrThing", charId)
						if isAiming then Indicator_StayVis = 30 else Indicator_StayVis = 15 end
					end
				else
					Indicator_StayVis = Indicator_StayVis-(dt*60)
					if Indicator_StayVis <= 0 then
						lookingAtCharacter = nil
						self.network:sendToServer("sv_updatePlrThing", nil)
					end
				end
			end
		
			--Speedometer
			if self.cl.exi.speedometer == true then
				local speed =  string.format("%.1f", ( ( sm.vec3.length( character:getVelocity() )) * speedconv ))
				g_survivalHud:setText( "Speed", tostring(speed).. speedUnittxt)
			end

			--Clock
			if self.cl.exi.clock == true then
				local hour = mfloor(( sm.game.getTimeOfDay() * 24 ) % 24)

				g_survivalHud:setText("Time", getTimeOfDayString())
				g_survivalHud:setText("Day", "Day ".. tostring(mfloor((sm.game.getCurrentTick()+14400)/57600)))
				if hour == 0 then
					hour = "1"
				elseif hour <= 12 then
					hour = tostring(hour)
				else
					hour = tostring(hour-12)
				end
				g_survivalHud:setItemIcon( "Clock", "ExI_GuiMap", "Clock", hour )
			end

			--Counters
			if self.cl.exi.counters == true then
				local hotbaritem = sm.localPlayer.getActiveItem() -- Get the UUID of the item the player is holding

				if CounterUuids[tostring(hotbaritem)] then
					if hotbaritem == tool_paint then
						hotbaritem = obj_consumable_inkammo
					end
					local img = CounterUuids[tostring(hotbaritem)]
					local quantity = sm.container.totalQuantity( sm.localPlayer.getPlayer():getInventory(), hotbaritem )

					if quantity ~= counter2.quantity then
						g_survivalHud:setText("CounterText", tostring(quantity))
						counter2.quantity = quantity
					end
					if counter2.img ~= img then
						g_survivalHud:setImage("CounterIcon", img)
						counter2.img = img
					end
					if counter2.visible == false then
						self:cl_setAnim(2, true)
						self:cl_setAnim(1, false)
					end

				--Spud counter
				elseif isAnyOf(hotbaritem, SpudgunUuids) then
					local quantity = sm.container.totalQuantity( sm.localPlayer.getPlayer():getInventory(), obj_plantables_potato )

					if quantity ~= counter1.quantity then
						local color = ""
						if quantity < 100 then
							if quantity == 0 then color = "#ff2e2e"
							elseif quantity < 15 then color = "#ff8035"
							elseif quantity < 30 then color = "#ffba48"
							elseif quantity < 60 then color = "#ffe91d"
							else color = "#fff382" end
						end
						g_survivalHud:setText("SpudsLeftText", color.. tostring(quantity))
						counter1.quantity = quantity
					end
					if counter1.visible == false then
						self:cl_setAnim(1, true)
						self:cl_setAnim(2, false)
					end

				elseif counter2.visible then
					self:cl_setAnim(2, false)
				elseif counter1.visible then
					self:cl_setAnim(1, false)
				end
			else
				if counter1.visible or counter2.visible then
					self:cl_setAnim(1, false)
					self:cl_setAnim(2, false)
				end
			end
		end
		--To here
	end
end

function SurvivalPlayer.client_onInteract( self, character, state )
	if state == true then
		--self:cl_startCutscene( camera_test )
		--self:cl_startCutscene( camera_test_joint )
		--self:cl_startCutscene( camera_wakeup_ground )
		--self:cl_startCutscene( camera_approach_crash )
		--self:cl_startCutscene( camera_wakeup_crash )
		--self:cl_startCutscene( camera_wakeup_bed )

		if not self.cl.isConscious then
			if self.cl.hasRevivalItem then
				if self.cl.revivalChewCount >= BaguetteSteps then
					self.network:sendToServer( "sv_n_revive" )
				end
				self.cl.revivalChewCount = self.cl.revivalChewCount + 1
				self.network:sendToServer( "sv_onEvent", { type = "character", data = "chew" } )
			else
				self.network:sendToServer( "sv_n_try_respawn" )
			end
		end
	end
end

--Function modified by WaspEyeNight
function SurvivalPlayer.server_onFixedUpdate( self, dt )

	if g_survivalDev and not self.sv.saved.isConscious and not self.sv.saved.hasRevivalItem then
		if sm.container.canSpend( self.player:getInventory(), obj_consumable_longsandwich, 1 ) then
			if sm.container.beginTransaction() then
				sm.container.spend( self.player:getInventory(), obj_consumable_longsandwich, 1, true )
				if sm.container.endTransaction() then
					self.sv.saved.hasRevivalItem = true
					self.player:sendCharacterEvent( "baguette" )
					self.network:setClientData( self.sv.saved )
				end
			end
		end
	end

	local character = self.player:getCharacter()
	if character then
		self:sv_updateTumbling()
	end

	-- Delays the respawn so clients have time to fade to black
	if self.sv.respawnDelayTimer then
		self.sv.respawnDelayTimer:tick()
		if self.sv.respawnDelayTimer:done() then
			self:sv_e_respawn()
			self.sv.respawnDelayTimer = nil
		end
	end

	-- End of respawn sequence
	if self.sv.respawnEndTimer then
		self.sv.respawnEndTimer:tick()
		if self.sv.respawnEndTimer:done() then
			self.network:sendToClient( self.player, "cl_n_endFadeToBlack", { duration = RespawnEndFadeDuration } )
			self.sv.respawnEndTimer = nil;
		end
	end

	-- If respawn failed, restore the character
	if self.sv.respawnTimeoutTimer then
		self.sv.respawnTimeoutTimer:tick()
		if self.sv.respawnTimeoutTimer:done() then
			self:sv_onSpawnCharacter()
		end
	end

	self.sv.damageCooldown:tick()
	self.sv.impactCooldown:tick()
	self.sv.fireDamageCooldown:tick()
	self.sv.poisonDamageCooldown:tick()

	-- Update breathing
	-- WEN modified some code from here
	if character then
		if character:isDiving() then
			self.sv.saved.stats.breath = math.max( self.sv.saved.stats.breath - BreathLostPerTick, 0 )
			if self.sv.saved.stats.breath == 0 then
				self.sv.drownTimer:tick()
				if self.sv.drownTimer:done() then
					if self.sv.saved.isConscious then
						print( "'SurvivalPlayer' is drowning!" )
						self:sv_takeDamage( DrownDamage, "drown" )
					end
					self.sv.drownTimer:start( DrownDamageCooldown )
				end
			end
		else
			self.sv.saved.stats.breath = self.sv.saved.stats.maxbreath
			self.sv.drownTimer:start( DrownDamageCooldown )
		end

		-- Spend stamina on sprinting
		if character:isSprinting() then
			self.sv.staminaSpend = self.sv.staminaSpend + SprintStaminaCost
		end

		-- Spend stamina on carrying
		if not self.player:getCarry():isEmpty() then
			self.sv.staminaSpend = self.sv.staminaSpend + CarryStaminaCost
		end

		local playerid = self.player.id
		if sv_lookingAtCharacter[playerid].update == true then
			self.network:sendToClient( self.player, "cl_updateIndicator", sv_lookingAtCharacter[playerid].data )
			sv_lookingAtCharacter[playerid].update = false
		end

	-- Update stamina, food and water stats
		if self.sv.saved.isConscious then
			self.sv.statsTimer:tick()
			if self.sv.statsTimer:done() then
				self.sv.statsTimer:start( StatsTickRate )

				if not g_godMode then

					-- Recover health from food
					if self.sv.saved.stats.food > FoodRecoveryThreshold then
						local fastRecoveryFraction = 0

						-- Fast recovery when food is above fast threshold
						if self.sv.saved.stats.food > FastFoodRecoveryThreshold then
							local recoverableHp = math.min( self.sv.saved.stats.maxhp - self.sv.saved.stats.hp, FastHpRecovery )
							local foodSpend = math.min( recoverableHp * FastFoodCostPerHpRecovery, math.max( self.sv.saved.stats.food - FastFoodRecoveryThreshold, 0 ) )
							local recoveredHp = foodSpend / FastFoodCostPerHpRecovery

							self.sv.saved.stats.hp = math.min( self.sv.saved.stats.hp + recoveredHp, self.sv.saved.stats.maxhp )
							self.sv.saved.stats.food = self.sv.saved.stats.food - foodSpend
							fastRecoveryFraction = ( recoveredHp ) / FastHpRecovery
						end

						-- Normal recovery
						local recoverableHp = math.min( self.sv.saved.stats.maxhp - self.sv.saved.stats.hp, HpRecovery * ( 1 - fastRecoveryFraction ) )
						local foodSpend = math.min( recoverableHp * FoodCostPerHpRecovery, math.max( self.sv.saved.stats.food - FoodRecoveryThreshold, 0 ) )
						local recoveredHp = foodSpend / FoodCostPerHpRecovery

						self.sv.saved.stats.hp = math.min( self.sv.saved.stats.hp + foodSpend / FoodCostPerHpRecovery, self.sv.saved.stats.maxhp )
						self.sv.saved.stats.food = self.sv.saved.stats.food - foodSpend
					end

					-- Spend water and food on stamina usage
					self.sv.saved.stats.water = math.max( self.sv.saved.stats.water - self.sv.staminaSpend * WaterCostPerStamina, 0 )
					self.sv.saved.stats.food = math.max( self.sv.saved.stats.food - self.sv.staminaSpend * FoodCostPerStamina, 0 )
					self.sv.staminaSpend = 0

					-- Decrease food and water with time
					self.sv.saved.stats.food = math.max( self.sv.saved.stats.food - FoodLostPerSecond, 0 )
					self.sv.saved.stats.water = math.max( self.sv.saved.stats.water - WaterLostPerSecond, 0 )

					local fatigueDamageFromHp = false
					if self.sv.saved.stats.food <= 0 then
						self:sv_takeDamage( FatigueDamageHp, "fatigue" )
						fatigueDamageFromHp = true
					end
					if self.sv.saved.stats.water <= 0 then
						if not fatigueDamageFromHp then
							self:sv_takeDamage( FatigueDamageWater, "fatigue" )
						end
					end
				end

				local hasBeenChanged = false
				if self.sv.updateExiSettings[playerid] then
					for _, setting in pairs(self.sv.updateExiSettings[playerid]) do
						if setting ~= nil then
							self.sv.saved.exi[_] = setting
							hasBeenChanged = true
						end
					end
					self.sv.updateExiSettings[playerid] = nil
				end
	
				if hasBeenChanged == true then
					print("Saved Expanded info settings for character ".. tostring(playerid))
					self.storage:save( self.sv.saved )
					self.network:setClientData( self.sv.saved )
				end

				self.storage:save( self.sv.saved )
				self.network:setClientData( self.sv.saved )

			end
		end

	end
	-- to here
end

function SurvivalPlayer.server_onProjectile( self, hitPos, hitTime, hitVelocity, projectileName, attacker, damage )
	if type( attacker ) == "Unit" or ( type( attacker ) == "Shape" and isTrapProjectile( projectileName ) ) then
		self:sv_takeDamage( damage, "shock" )
	end
	if self.player.character:isTumbling() then
		ApplyKnockback( self.player.character, hitVelocity:normalize(), 2000 )
	end

	if projectileName == "water"  then
		self.network:sendToClient( self.player, "cl_n_fillWater" )
	end
end

function SurvivalPlayer.cl_n_fillWater( self )
	if self.player == sm.localPlayer.getPlayer() then
		if sm.localPlayer.getActiveItem() == obj_tool_bucket_empty then
			local params = {}
			params.playerInventory = sm.localPlayer.getInventory()
			params.slotIndex = sm.localPlayer.getSelectedHotbarSlot()
			params.previousUid = obj_tool_bucket_empty
			params.nextUid = obj_tool_bucket_water
			params.previousQuantity = 1
			params.nextQuantity = 1
			self.network:sendToServer( "sv_n_exchangeItem", params )
		end
	end
end

function SurvivalPlayer.sv_updateBlocking( self, blocking )
	self.sv.blocking = blocking
end

function SurvivalPlayer.server_onMelee( self, hitPos, attacker, damage, power )
	if not sm.exists( attacker ) then
		return
	end
	local attackingCharacter = attacker:getCharacter()
	local playerCharacter = self.player:getCharacter()
	if attackingCharacter ~= nil and playerCharacter ~= nil then
		local attackDirection = ( hitPos - attackingCharacter.worldPosition ):normalize()
		local directionDiff = ( attackDirection - playerCharacter:getDirection() ):length()
		local directionDiffThreshold = 1.6
		if directionDiff >= directionDiffThreshold and self.sv.blocking == true then
			print("'SurvivalPlayer' blocked melee damage")
			sm.effect.playEffect( "SledgehammerHit - Default", playerCharacter.worldPosition + sm.vec3.new( 0, 0, 0.5 ) - ( attackDirection - playerCharacter:getDirection() ) * 0.25 )
		else
			print("'SurvivalPlayer' took melee damage")
			if type( attacker ) == "Unit" then
				self:sv_takeDamage( damage, "impact" )
			else
				self.network:sendToClients( "cl_n_onEvent", { event = "impact", pos = playerCharacter:getWorldPosition(), damage = damage * 0.01 } )
			end

			-- Melee impulse
			if attacker then
				ApplyKnockback( self.player.character, attackDirection, power )
			end
		end
	end
end

function SurvivalPlayer.server_onExplosion( self, center, destructionLevel )
	print("'SurvivalPlayer' took explosion damage")
	self:sv_takeDamage( destructionLevel * 2, "impact" )
	if self.player.character:isTumbling() then
		local knockbackDirection = ( self.player.character.worldPosition - center ):normalize()
		ApplyKnockback( self.player.character, knockbackDirection, 5000 )
	end
end

function SurvivalPlayer.sv_startTumble( self, tumbleTickTime )
	if not self.player.character:isDowned() and self.sv.resistTumbleTimer:done() then
		local currentTick = sm.game.getCurrentTick()
		self.sv.recentTumbles[#self.sv.recentTumbles+1] = currentTick
		local recentTumbles = {}
		for _, tumbleTickTimestamp in ipairs( self.sv.recentTumbles ) do
			if tumbleTickTimestamp >= currentTick - RecentTumblesTickTimeInterval then
				recentTumbles[#recentTumbles+1] = tumbleTickTimestamp
			end
		end
		self.sv.recentTumbles = recentTumbles
		if #self.sv.recentTumbles > MaxRecentTumbles then
			-- Too many tumbles in quick succession, gain temporary tumble immunity
			self.player.character:setTumbling( false )
			self.sv.maxTumbleTimer:reset()
			self.sv.tumbleReset:reset()
			self.sv.resistTumbleTimer:reset()
		else
			self.player.character:setTumbling( true )
			if tumbleTickTime then
				self.sv.tumbleReset:start( tumbleTickTime )
			else
				self.sv.tumbleReset:start( StopTumbleTimerTickThreshold )
			end
			return true
		end
	end
	return false
end

function SurvivalPlayer.sv_updateTumbling( self )
	if not self.sv.resistTumbleTimer:done() then
		self.sv.resistTumbleTimer:tick()
	end

	if not self.player.character:isDowned() then
		if self.player.character:isTumbling() then
			self.sv.maxTumbleTimer:tick()
			if self.sv.maxTumbleTimer:done() then
				-- Stuck in the tumble state for too long, gain temporary tumble immunity
				self.player.character:setTumbling( false )
				self.sv.maxTumbleTimer:reset()
				self.sv.tumbleReset:reset()
				self.sv.resistTumbleTimer:reset()
			else
				local tumbleVelocity = self.player.character:getTumblingLinearVelocity()
				if tumbleVelocity:length() < 1.0 then
					self.sv.tumbleReset:tick()

					if self.sv.tumbleReset:done() then
						self.player.character:setTumbling( false )
						self.sv.tumbleReset:reset()
					end
				else
					self.sv.tumbleReset:reset()
				end
			end
		end
	end
end

function SurvivalPlayer.sv_n_exchangeItem( self, params )
	if sm.container.beginTransaction() then
		sm.container.spendFromSlot( params.playerInventory, params.slotIndex, params.previousUid, params.previousQuantity, true )
		sm.container.collectToSlot( params.playerInventory, params.slotIndex, params.nextUid, params.nextQuantity, true )
		sm.container.endTransaction()
	end
end

function SurvivalPlayer.server_onCollision( self, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal  )

	if not self.player.character or not sm.exists( self.player.character ) then
		return
	end

	if not self.sv.impactCooldown:done() then
		return
	end

	local collisionDamageMultiplier = 0.25
	local damage, tumbleTicks, tumbleVelocity, impactReaction = CharacterCollision( self.player.character, other, collisionPosition, selfPointVelocity, otherPointVelocity, collisionNormal, self.sv.saved.stats.maxhp / collisionDamageMultiplier, 24 )
	damage = damage * collisionDamageMultiplier
	if damage > 0 or tumbleTicks > 0 then
		self.sv.impactCooldown:start( 0.25 * 40 )
	end
	if damage > 0 then
		print("'SurvivalPlayer' took", damage, "collision damage")
		self:sv_takeDamage( damage, "shock" )
	end
	if tumbleTicks > 0 then
		if self:sv_startTumble( tumbleTicks ) then
			-- Limit tumble velocity
			if tumbleVelocity:length2() > MaxTumbleImpulseSpeed * MaxTumbleImpulseSpeed then
				tumbleVelocity = tumbleVelocity:normalize() * MaxTumbleImpulseSpeed
			end
			self.player.character:applyTumblingImpulse( tumbleVelocity * self.player.character.mass )
			if type( other ) == "Shape" and sm.exists( other ) and other.body:isDynamic() then
				sm.physics.applyImpulse( other.body, impactReaction * other.body.mass, true, collisionPosition - other.body.worldPosition )
			end
		end
	end

end

function SurvivalPlayer.sv_e_staminaSpend( self, stamina )
	if not g_godMode then
		if stamina > 0 then
			self.sv.staminaSpend = self.sv.staminaSpend + stamina
			print( "SurvivalPlayer spent:", stamina, "stamina" )
		end
	else
		print( "SurvivalPlayer resisted", stamina, "stamina spend" )
	end
end

function SurvivalPlayer.sv_e_receiveDamage( self, damageData )
	self:sv_takeDamage( damageData.damage )
end

function SurvivalPlayer.sv_takeDamage( self, damage, source )
	if damage > 0 then
		damage = damage * GetDifficultySettings().playerTakeDamageMultiplier
		local character = self.player:getCharacter()
		local lockingInteractable = character:getLockingInteractable()
		if lockingInteractable and lockingInteractable:hasSeat() then
			lockingInteractable:setSeatCharacter( character )
		end

		if not g_godMode and self.sv.damageCooldown:done() then
			if self.sv.saved.isConscious then
				self.sv.saved.stats.hp = math.max( self.sv.saved.stats.hp - damage, 0 )

				print( "'SurvivalPlayer' took:", damage, "damage.", self.sv.saved.stats.hp, "/", self.sv.saved.stats.maxhp, "HP" )

				if source then
					self.network:sendToClients( "cl_n_onEvent", { event = source, pos = character:getWorldPosition(), damage = damage * 0.01 } )
				else
					self.player:sendCharacterEvent( "hit" )
				end

				if self.sv.saved.stats.hp <= 0 then
					print( "'SurvivalPlayer' knocked out!" )
					self.sv.respawnInteractionAttempted = false
					self.sv.saved.isConscious = false
					character:setTumbling( true )
					character:setDowned( true )
				end

				self.storage:save( self.sv.saved )
				self.network:setClientData( self.sv.saved )
			end
		else
			print( "'SurvivalPlayer' resisted", damage, "damage" )
		end
	end
end

function SurvivalPlayer.sv_n_revive( self )
	local character = self.player:getCharacter()
	if not self.sv.saved.isConscious and self.sv.saved.hasRevivalItem and not self.sv.spawnparams.respawn then
		print( "SurvivalPlayer", self.player.id, "revived" )
		self.sv.saved.stats.hp = self.sv.saved.stats.maxhp
		self.sv.saved.stats.food = self.sv.saved.stats.maxfood
		self.sv.saved.stats.water = self.sv.saved.stats.maxwater
		self.sv.saved.isConscious = true
		self.sv.saved.hasRevivalItem = false
		self.storage:save( self.sv.saved )
		self.network:setClientData( self.sv.saved )
		self.network:sendToClient( self.player, "cl_n_onEffect", { name = "Eat - EatFinish", host = self.player.character } )
		if character then
			character:setTumbling( false )
			character:setDowned( false )
		end
		self.sv.damageCooldown:start( 40 )
		self.player:sendCharacterEvent( "revive" )
	end
end

function SurvivalPlayer.sv_e_respawn( self )
	if self.sv.spawnparams.respawn then
		if not self.sv.respawnTimeoutTimer then
			self.sv.respawnTimeoutTimer = Timer()
			self.sv.respawnTimeoutTimer:start( RespawnTimeout )
		end
		return
	end
	if not self.sv.saved.isConscious then
		g_respawnManager:sv_performItemLoss( self.player )
		self.sv.spawnparams.respawn = true

		sm.event.sendToGame( "sv_e_respawn", { player = self.player } )
	else
		print( "SurvivalPlayer must be unconscious to respawn" )
	end
end

function SurvivalPlayer.sv_n_try_respawn( self )
	if not self.sv.saved.isConscious and not self.sv.respawnDelayTimer and not self.sv.respawnInteractionAttempted then
		self.sv.respawnInteractionAttempted = true
		self.sv.respawnEndTimer = nil;
		self.network:sendToClient( self.player, "cl_n_startFadeToBlack", { duration = RespawnFadeDuration, timeout = RespawnFadeTimeout } )
		
		self.sv.respawnDelayTimer = Timer()
		self.sv.respawnDelayTimer:start( RespawnDelay )
	end
end

function SurvivalPlayer.sv_startFadeToBlack( self, param )
	self.network:sendToClient( self.player, "cl_n_startFadeToBlack", { duration = param.duration, timeout = param.timeout } )
end

function SurvivalPlayer.sv_endFadeToBlack( self, param )
	self.network:sendToClient( self.player, "cl_n_endFadeToBlack", { duration = param.duration } )
end

function SurvivalPlayer.cl_n_startFadeToBlack( self, param )
	sm.gui.startFadeToBlack( param.duration, param.timeout )
end

function SurvivalPlayer.cl_n_endFadeToBlack( self, param )
	sm.gui.endFadeToBlack( param.duration )
end

function SurvivalPlayer.sv_onSpawnCharacter( self )
	if self.sv.saved.isNewPlayer then
		-- Intro cutscene for new player
		if not g_survivalDev then
			--self:sv_e_startLocalCutscene( "camera_approach_crash" )
		end
	elseif self.sv.spawnparams.respawn then
		local playerBed = g_respawnManager:sv_getPlayerBed( self.player )
		if playerBed and playerBed.shape and sm.exists( playerBed.shape ) and playerBed.shape.body:getWorld() == self.player.character:getWorld() then
			-- Attempt to seat the respawned character in a bed
			self.network:sendToClient( self.player, "cl_seatCharacter", { shape = playerBed.shape  } )
		else
			-- Respawned without a bed
			--self:sv_e_startLocalCutscene( "camera_wakeup_ground" )
		end

		self.sv.respawnEndTimer = Timer()
		self.sv.respawnEndTimer:start( RespawnEndDelay )
	
	end

	if self.sv.saved.isNewPlayer or self.sv.spawnparams.respawn then
		print( "SurvivalPlayer", self.player.id, "spawned" )
		if self.sv.saved.isNewPlayer then
			self.sv.saved.stats.hp = self.sv.saved.stats.maxhp
			self.sv.saved.stats.food = self.sv.saved.stats.maxfood
			self.sv.saved.stats.water = self.sv.saved.stats.maxwater
		else
			self.sv.saved.stats.hp = 30
			self.sv.saved.stats.food = 30
			self.sv.saved.stats.water = 30
		end
		self.sv.saved.isConscious = true
		self.sv.saved.hasRevivalItem = false
		self.sv.saved.isNewPlayer = false
		self.storage:save( self.sv.saved )
		self.network:setClientData( self.sv.saved )

		self.player.character:setTumbling( false )
		self.player.character:setDowned( false )
		self.sv.damageCooldown:start( 40 )
	else
		-- SurvivalPlayer rejoined the game
		if self.sv.saved.stats.hp <= 0 or not self.sv.saved.isConscious then
			self.player.character:setTumbling( true )
			self.player.character:setDowned( true )
		end
	end

	self.sv.respawnInteractionAttempted = false
	self.sv.respawnDelayTimer = nil
	self.sv.respawnTimeoutTimer = nil
	self.sv.spawnparams = {}

	sm.event.sendToGame( "sv_e_onSpawnPlayerCharacter", self.player )
end

function SurvivalPlayer.cl_seatCharacter( self, params )
	if sm.exists( params.shape ) then
		params.shape.interactable:setSeatCharacter( self.player.character )
	end
end

function SurvivalPlayer.sv_e_debug( self, params )
	if params.hp then
		self.sv.saved.stats.hp = params.hp
	end
	if params.water then
		self.sv.saved.stats.water = params.water
	end
	if params.food then
		self.sv.saved.stats.food = params.food
	end
	self.storage:save( self.sv.saved )
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_eat( self, edibleParams )
	if edibleParams.hpGain then
		self:sv_restoreHealth( edibleParams.hpGain )
	end
	if edibleParams.foodGain then
		self:sv_restoreFood( edibleParams.foodGain )

		self.network:sendToClient( self.player, "cl_n_onEffect", { name = "Eat - EatFinish", host = self.player.character } )
	end
	if edibleParams.waterGain then
		self:sv_restoreWater( edibleParams.waterGain )
		-- self.network:sendToClient( self.player, "cl_n_onEffect", { name = "Eat - DrinkFinish", host = self.player.character } )
	end
	self.storage:save( self.sv.saved )
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_feed( self, params )
	if not self.sv.saved.isConscious and not self.sv.saved.hasRevivalItem then
		if sm.container.beginTransaction() then
			sm.container.spend( params.playerInventory, params.foodUuid, 1, true )
			if sm.container.endTransaction() then
				self.sv.saved.hasRevivalItem = true
				self.player:sendCharacterEvent( "baguette" )
				self.network:setClientData( self.sv.saved )
			end
		end
	end
end

function SurvivalPlayer.sv_restoreHealth( self, health )
	if self.sv.saved.isConscious then
		self.sv.saved.stats.hp = self.sv.saved.stats.hp + health
		self.sv.saved.stats.hp = math.min( self.sv.saved.stats.hp, self.sv.saved.stats.maxhp )
		print( "'SurvivalPlayer' restored:", health, "health.", self.sv.saved.stats.hp, "/", self.sv.saved.stats.maxhp, "HP" )
	end
end

function SurvivalPlayer.sv_restoreFood( self, food )
	if self.sv.saved.isConscious then
		food = food * ( 0.8 + ( self.sv.saved.stats.maxfood - self.sv.saved.stats.food ) / self.sv.saved.stats.maxfood * 0.2 )
		self.sv.saved.stats.food = self.sv.saved.stats.food + food
		self.sv.saved.stats.food = math.min( self.sv.saved.stats.food, self.sv.saved.stats.maxfood )
		print( "'SurvivalPlayer' restored:", food, "food.", self.sv.saved.stats.food, "/", self.sv.saved.stats.maxfood, "FOOD" )
	end
end

function SurvivalPlayer.sv_restoreWater( self, water )
	if self.sv.saved.isConscious then
		water = water * ( 0.8 + ( self.sv.saved.stats.maxwater - self.sv.saved.stats.water ) / self.sv.saved.stats.maxwater * 0.2 )
		self.sv.saved.stats.water = self.sv.saved.stats.water + water
		self.sv.saved.stats.water = math.min( self.sv.saved.stats.water, self.sv.saved.stats.maxwater )
		print( "'SurvivalPlayer' restored:", water, "water.", self.sv.saved.stats.water, "/", self.sv.saved.stats.maxwater, "WATER" )
	end
end

function SurvivalPlayer.sv_e_setRefiningState( self, params )
	local userPlayer = params.user:getPlayer()
	if userPlayer then
		if params.state == true then
			userPlayer:sendCharacterEvent( "refine" )
		else
			userPlayer:sendCharacterEvent( "refineEnd" )
		end
	end
end

function SurvivalPlayer.sv_e_onLoot( self, params )
	self.network:sendToClient( self.player, "cl_n_onLoot", params )
end

function SurvivalPlayer.cl_n_onLoot( self, params )
	local message = "#{INFO_PICKED_LOOT} "
	if params.uuid then
		message = message .. sm.shape.getShapeTitle( params.uuid )
	elseif params.name then
		message = message .. params.name
	end
	if params.quantity and params.quantity > 1 then
		message = message.." x"..params.quantity
	end
	sm.gui.displayAlertText( message, 2 )
	local color
	if params.uuid then
		color = sm.shape.getShapeTypeColor( params.uuid )
	end
	local effectName = params.effectName or "Loot - Pickup"
	sm.effect.playEffect( effectName, params.pos, sm.vec3.zero(), sm.quat.identity(), sm.vec3.one(), { ["Color"] = color } )
end

function SurvivalPlayer.sv_e_onMsg( self, msg )
	self.network:sendToClient( self.player, "cl_n_onMsg", msg )
end

function SurvivalPlayer.cl_n_onMsg( self, msg )
	sm.gui.displayAlertText( msg )
end

function SurvivalPlayer.cl_n_onEffect( self, params )
	if params.host then
		sm.effect.playHostedEffect( params.name, params.host, params.boneName, params.parameters )
	else
		sm.effect.playEffect( params.name, params.position, params.velocity, params.rotation, params.scale, params.parameters )
	end
end

function SurvivalPlayer.sv_e_onStayPesticide( self )
	if self.sv.poisonDamageCooldown:done() then
		self:sv_takeDamage( PoisonDamage, "poison" )
		self.sv.poisonDamageCooldown:start( PoisonDamageCooldown )
	end
end

function SurvivalPlayer.sv_e_onEnterFire( self )
	if self.sv.fireDamageCooldown:done() then
		self:sv_takeDamage( FireDamage, "fire" )
		self.sv.fireDamageCooldown:start( FireDamageCooldown )
	end
end

function SurvivalPlayer.sv_e_onStayFire( self )
	if self.sv.fireDamageCooldown:done() then
		self:sv_takeDamage( FireDamage, "fire" )
		self.sv.fireDamageCooldown:start( FireDamageCooldown )
	end
end

function SurvivalPlayer.sv_e_onEnterChemical( self )
	if self.sv.poisonDamageCooldown:done() then
		self:sv_takeDamage( PoisonDamage, "poison" )
		self.sv.poisonDamageCooldown:start( PoisonDamageCooldown )
	end
	self.sv.saved.inChemical = true
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_onStayChemical( self )
	if self.sv.poisonDamageCooldown:done() then
		self:sv_takeDamage( PoisonDamage, "poison" )
		self.sv.poisonDamageCooldown:start( PoisonDamageCooldown )
	end
end

function SurvivalPlayer.sv_e_onExitChemical( self )
	self.sv.saved.inChemical = false
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_onEnterOil( self )
	self.sv.saved.inOil = true
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.sv_e_onExitOil( self )
	self.sv.saved.inOil = false
	self.network:setClientData( self.sv.saved )
end

function SurvivalPlayer.server_onShapeRemoved( self, removedShapes )
	local numParts = 0
	local numBlocks = 0
	local numJoints = 0
	for _, removedShapeType in ipairs( removedShapes ) do
		if removedShapeType.type == "block"  then
			numBlocks = numBlocks + removedShapeType.amount
		elseif removedShapeType.type == "part"  then
			numParts = numParts + removedShapeType.amount
		elseif removedShapeType.type == "joint"  then
			numJoints = numJoints + removedShapeType.amount
		end
	end

	local staminaSpend = numParts + numJoints + math.sqrt( numBlocks )
	--self:sv_e_staminaSpend( staminaSpend )
end


-- Camera

function SurvivalPlayer.cl_updateCamera( self, dt )

	if self.useCutsceneCamera then
		local cameraPath = self.currentCutscene.cameraPath
		local cameraAttached = self.currentCutscene.cameraAttached
		if #cameraPath > 1 then
			if cameraPath[self.nodeIndex+1] then
				local prevNode = cameraPath[self.nodeIndex]
				local nextNode = cameraPath[self.nodeIndex+1]

				local prevPosition = prevNode.position
				local nextPosition = nextNode.position
				local prevDirection = prevNode.direction
				local nextDirection = nextNode.direction

				if prevNode.type == "playerSpace" then
					prevPosition = sm.camera.getDefaultPosition()
				end
				if nextNode.type == "playerSpace" then
					nextPosition = nextNode.position + sm.camera.getDefaultPosition()
					-- Set player to look in the same direction as the player node
					if cameraPath[self.nodeIndex].direction then
						sm.localPlayer.setDirection( cameraPath[self.nodeIndex+1].direction )
					end
				end

				if nextNode.lerpTime > 0 then
					self.progress = self.progress + dt / nextNode.lerpTime
				else
					self.progress = 1
				end

				if self.progress >= 1 then

					-- Trigger events in the next node
					if nextNode.events then
						for _, eventParams in pairs( nextNode.events ) do
							if eventParams.type == "character" then
								eventParams.character = self.player.character
							end
							self.network:sendToServer( "sv_onEvent", eventParams )
						end
					end

					self.nodeIndex = self.nodeIndex + 1
					local upcomingNextNode = cameraPath[self.nodeIndex+1]
					if upcomingNextNode then
						self.progress = ( self.progress - 1.0 ) * nextNode.lerpTime / upcomingNextNode.lerpTime
						self.progress = math.max( math.min( self.progress, 1.0 ), 0 )
						prevPosition = nextNode.position
						nextPosition = upcomingNextNode.position
						prevDirection = nextNode.direction
						nextDirection = upcomingNextNode.direction
						if nextNode.type == "playerSpace" then
							prevPosition = sm.camera.getDefaultPosition()
						end
						if upcomingNextNode.type == "playerSpace" then
							nextPosition = nextPosition +  sm.camera.getDefaultPosition()
							-- Set player to look in the same direction as the player node
							if cameraPath[self.nodeIndex].direction then
								sm.localPlayer.setDirection( cameraPath[self.nodeIndex+1].direction )
							end
						end
					else
						--Finished the cutscene
						self.progress = 0
						self.nodeIndex = 1
						if self.currentCutscene.nextCutscene then
							self:cl_startCutscene( camera_cutscenes[self.currentCutscene.nextCutscene] )
						else
							self.useCutsceneCamera = false
							sm.gui.hideGui( false )
							sm.camera.setCameraState( sm.camera.state.default )
							sm.localPlayer.setLockedControls( false )
						end
					end
				end

				local camPos = sm.vec3.lerp( prevPosition, nextPosition, self.progress )
				local camDir = sm.vec3.lerp( prevDirection, nextDirection, self.progress )

				sm.camera.setPosition( camPos )
				sm.camera.setDirection( camDir )
			end
		elseif cameraAttached then

			if self.progress >= 1 then
				--Finished the cutscene
				self.progress = 0
				self.nodeIndex = 1
				if self.currentCutscene.nextCutscene then
					self:cl_startCutscene( camera_cutscenes[self.currentCutscene.nextCutscene] )
				else
					self.useCutsceneCamera = false
					sm.gui.hideGui( false )
					sm.camera.setCameraState( sm.camera.state.default )
					sm.localPlayer.setLockedControls( false )
				end
			else
				local character = self.player:getCharacter()
				if character then
					sm.camera.setCameraState( sm.camera.state.cutsceneFP )
					local camPos = character:getTpBonePos( cameraAttached.jointName )
					local camDir = character:getTpBoneRot( cameraAttached.jointName ) * cameraAttached.initialDirection

					sm.camera.setPosition( camPos )
					sm.camera.setDirection( camDir )
				end
			end
			self.progress = self.progress + dt / cameraAttached.attachTime

		else
			self:cl_startCutscene( nil )
		end
	end

end


function SurvivalPlayer.cl_startCutscene( self, cutsceneInfo )
	if cutsceneInfo then
		self.useCutsceneCamera = true
		sm.gui.hideGui( true )
		sm.camera.setCameraState( cutsceneInfo.cameraState )
		if cutsceneInfo.cameraPullback then
			sm.camera.setCameraPullback( cutsceneInfo.cameraPullback.standing, cutsceneInfo.cameraPullback.seated )
		end

		sm.localPlayer.setLockedControls( true )

		if self.useCutsceneCamera then
			-- Set camera nodes to follow
			self.currentCutscene = {}
			self.currentCutscene.cameraAttached = cutsceneInfo.attached
			local cameraPath = {}
			local characterPosition = sm.vec3.new( 0, 0, 0 )
			local characterDirection = sm.vec3.new( 0, 1, 0 )
			local character = self.player.character
			if character then
				characterPosition = character.worldPosition + sm.vec3.new( 0, 0, character:getHeight() * 0.5 )
				characterDirection = character:getDirection()
			else
				characterPosition = sm.localPlayer.getRaycastStart()
				characterDirection = sm.localPlayer.getDirection()
			end

			-- Get character heading
			characterDirection.z = 0
			if characterDirection:length() >= FLT_EPSILON then
				characterDirection = characterDirection:normalize()
			else
				characterDirection = sm.vec3.new( 0, 1, 0 )
			end

			-- Prepare a world direction and positon for each camera node
			if cutsceneInfo.nodes then
				for _, node in pairs( cutsceneInfo.nodes ) do
					local updatedNode = {}
					if node.type == "localSpace" then
						local right = characterDirection:cross( sm.vec3.new( 0, 0, 1 ) )
						local pitchedDirection = sm.vec3.rotate( characterDirection, math.rad( node.pitch ), right )
						updatedNode.direction = sm.vec3.rotateZ( pitchedDirection, -math.rad( node.yaw ) )
						updatedNode.position = characterPosition + sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), characterDirection ) * node.position
					elseif node.type == "playerSpace" then
						local right = sm.localPlayer.getDirection():cross( sm.vec3.new( 0, 0, 1 ) )
						local pitchedDirection = sm.vec3.rotate( sm.localPlayer.getDirection(), math.rad( node.pitch ), right )
						updatedNode.direction = sm.vec3.rotateZ( pitchedDirection, -math.rad( node.yaw ) )

						--updatedNode.position = sm.camera.getDefaultPosition() + sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.localPlayer.getDirection() ) * node.position
						updatedNode.position = sm.vec3.getRotation( sm.vec3.new( 0, 1, 0 ), sm.localPlayer.getDirection() ) * node.position
					else
						updatedNode.position = node.position
						updatedNode.direction = node.direction
					end
					updatedNode.type = node.type
					updatedNode.lerpTime = node.lerpTime
					updatedNode.events = node.events
					cameraPath[#cameraPath+1] = updatedNode
				end
			end

			if #cameraPath > 0 then
				-- Trigger events in the first node
				if cameraPath[1] then
					if cameraPath[1].events then
						for _, eventParams in pairs( cameraPath[1].events ) do
							if eventParams.type == "character" then
								eventParams.character = self.player.character
							end
							self.network:sendToServer( "sv_onEvent", eventParams )
						end
					end
				end
			elseif self.currentCutscene.cameraAttached then
				-- Trigger events
				if self.currentCutscene.cameraAttached.events then
					for _, eventParams in pairs( self.currentCutscene.cameraAttached.events ) do
						if eventParams.type == "character" then
							eventParams.character = self.player.character
						end
						self.network:sendToServer( "sv_onEvent", eventParams )
					end
				end
			end

			self.currentCutscene.cameraPath = cameraPath
			self.currentCutscene.nextCutscene = cutsceneInfo.nextCutscene
			self.currentCutscene.canSkip = cutsceneInfo.canSkip
		end
	else
		self.useCutsceneCamera = false
		sm.gui.hideGui( false )
		sm.camera.setCameraState( sm.camera.state.default )
		sm.localPlayer.setLockedControls( false )
		self.progress = 0
		self.nodeIndex = 1
	end
end

function SurvivalPlayer.cl_startLocalCutscene( self, params )
	if params.player == sm.localPlayer.getPlayer() then
		self:cl_startCutscene( camera_cutscenes[params.cutsceneInfoName] )
	end
end

function SurvivalPlayer.sv_e_startLocalCutscene( self, cutsceneInfoName )
	local params = { player = self.player, cutsceneInfoName = cutsceneInfoName }
	self.network:sendToClients( "cl_startLocalCutscene", params )
end

function SurvivalPlayer.sv_onEvent( self, eventParams )
	if eventParams.type == "character" then
		self.player:sendCharacterEvent( eventParams.data )
	end
end


function SurvivalPlayer.client_onCancel( self )

	if self.useCutsceneCamera and self.currentCutscene.canSkip then
		if self.currentCutscene.nextCutscene then
			self:cl_startCutscene( camera_cutscenes[self.currentCutscene.nextCutscene] )
		else
			self.useCutsceneCamera = false
			sm.gui.hideGui( false )
			sm.camera.setCameraState( sm.camera.state.default )
			sm.localPlayer.setLockedControls( false )
			self.progress = 0
			self.nodeIndex = 1
		end
	end
	
end

function SurvivalPlayer.client_onReload( self ) end

-- Expanded Info Part Of Script START --

-- Raid GUI

function SurvivalPlayer.client_raidguicmd( self, param2,param3, calledfromcmd )
	if not self.cl and cl2 then self.cl = cl2 end
	local player = sm.localPlayer.getPlayer()
	if param2 == "toggle" or param2 == "t" then
		if self.cl.exi.raidGui == true then
			g_survivalHud:setVisible("RaidBackground", false)
			g_survivalHud:setVisible("ExtraRaids", false)
			self.cl.exi.raidGui = false
			if self.network then self.network:sendToServer("server_ChangeExiSetting", { playerid = player.id, setting = "raidGui", value = false } ) end
			self:client_OnOffButton("RaidGUI", false)		else
			self.cl.exi.raidGui = true
			if self.network then self.network:sendToServer("server_ChangeExiSetting", { playerid = player.id, setting = "raidGui", value = true } ) end
			if raidAmountVis > 0 then
				g_survivalHud:setVisible("RaidBackground", true)
				for i = 1, raidAmountVis do
					g_survivalHud:setVisible("Raid".. tostring(i), true)
				end
				
				local col1,col2 = "#a8acff", "#a8e084"
				if self.cl.exi.RaidGUIStyle == 2 then col1,col2 = "#888888", "#ffcd3f" end
				for i=1,4 do
					local raidGuiNum = tostring(i)
					if raidValues[raidGuiNum] then
						g_survivalHud:setText("text2_raid".. raidGuiNum, col1.. "Pos: ".. raidValues[raidGuiNum].pos.x .. ",".. raidValues[raidGuiNum].pos.y.. " | Cell: ".. raidValues[raidGuiNum].cell.x.. ",".. raidValues[raidGuiNum].cell.y )
						g_survivalHud:setText("ProgressBarTextTime_raid".. raidGuiNum, col1.. "Level: ".. raidValues[raidGuiNum].level.. " | Wave: ".. raidValues[raidGuiNum].wave.. " | Crop Value: ".. raidValues[raidGuiNum].cropValue )
						g_survivalHud:setText("ProgressBarText_raid".. raidGuiNum, col1.. "Totebot: ".. col2.. raidValues[raidGuiNum].bots.totebot.. col1.. " Haybot: ".. col2.. raidValues[raidGuiNum].bots.haybot.. col1.. " Tapebot: ".. col2.. raidValues[raidGuiNum].bots.tapebot.. col1.. " Farmbot: ".. col2.. raidValues[raidGuiNum].bots.farmbot )
					end
				end

				if self.cl.exi.DynamicRaidBG and raidAmountVis <= 2 then
					g_survivalHud:setVisible("RaidGui_full", false)
					g_survivalHud:setVisible("RaidGui_half", true)
				else
					g_survivalHud:setVisible("RaidGui_full", true)
					g_survivalHud:setVisible("RaidGui_half", false)
				end
				
				if raidGuiExtra > 0 then
					g_survivalHud:setVisible("ExtraRaids", true)
				end
			end
			self:client_OnOffButton("RaidGUI", true)		end
	elseif param2 == "style" or param2 == "s" then
		if param3 == "1" or param3 == "2" or param3 == "3" or param3 == "4" then
			g_survivalHud:setVisible("RaidGui_Style1", false)
			g_survivalHud:setVisible("RaidGui_Style2", false)
			g_survivalHud:setVisible("RaidGui_Style3", false)
			g_survivalHud:setVisible("RaidGui_Style4", false)

			g_survivalHud:setVisible("RaidGui_Style".. param3, true)
		else
			return
		end

		self.cl.exi.RaidGUIStyle = tonumber(param3)
		if self.network then self.network:sendToServer("server_ChangeExiSetting", { playerid = player.id, setting = "RaidGUIStyle", value = tonumber(param3) } ) end

		CountUpdateCols = { "#ff9595", "Red" }
		if self.cl.exi.RaidGUIStyle == 2 then CountUpdateCols = { "#ffffff", "Orange" } end
		local col1,col2 = "#a8acff", "#a8e084"
		if self.cl.exi.RaidGUIStyle == 2 then col1,col2 = "#888888", "#ffcd3f" end
		for i=1,4 do
			local raidGuiNum = tostring(i)
			if raidValues[raidGuiNum] then
				g_survivalHud:setText("text2_raid".. raidGuiNum, col1.. "Pos: ".. raidValues[raidGuiNum].pos.x .. ",".. raidValues[raidGuiNum].pos.y.. " | Cell: ".. raidValues[raidGuiNum].cell.x.. ",".. raidValues[raidGuiNum].cell.y )
				g_survivalHud:setText("ProgressBarTextTime_raid".. raidGuiNum, col1.. "Level: ".. raidValues[raidGuiNum].level.. " | Wave: ".. raidValues[raidGuiNum].wave.. " | Crop Value: ".. raidValues[raidGuiNum].cropValue )
				g_survivalHud:setText("ProgressBarText_raid".. raidGuiNum, col1.. "Totebot: ".. col2.. raidValues[raidGuiNum].bots.totebot.. col1.. " Haybot: ".. col2.. raidValues[raidGuiNum].bots.haybot.. col1.. " Tapebot: ".. col2.. raidValues[raidGuiNum].bots.tapebot.. col1.. " Farmbot: ".. col2.. raidValues[raidGuiNum].bots.farmbot )
			end
		end

		ExI_CtrlpanelGUI:setText("RaidGUIStyleValue", RGuiStyleNames[self.cl.exi.RaidGUIStyle])
		for i=1,3 do
			local col = "#757575"
			if self.cl.exi.RaidGUIStyle == i then col = "#ffd449" end
			ExI_CtrlpanelGUI:setText("RaidGUIStyle".. tostring(i).. "Text", col.. RGuiStyleNames[i])
		end

	else
		return
	end
end

function SurvivalPlayer.client_onRaidCountdownStart( self, raidguikey, guiPos, raidlevel, raidwave, ExI_cropValue, gui )
	gui:open()
	print("Adding new raid to the raid GUI...")
	if not raidlevel or not raidwave or not ExI_cropValue then
		sm.gui.chatMessage("#ff0000ERROR:#ffffff The raid GUI could not be loaded: some values needed were not given.")
		sm.log.error("RAID GUI COULD NOT BE LOADED: Some values needed were not given")
		return
	end
	if not self.cl and cl2 then self.cl = cl2 end

	local table
	local raidGuiNum
	local spudgun = false
	local inventory = sm.localPlayer.getPlayer():getInventory()
	local ammoQ = sm.container.totalQuantity( inventory, obj_plantables_potato)
	local raiders = UnitManager:getraidersforlevel(raidlevel, raidwave)

	for i=0,sm.container.getSize(inventory) do
		local item = sm.container.getItem(inventory, i)
		if isAnyOf(item.uuid, SpudgunUuids) then
			spudgun = true
		end
	end


	if raidlevel > highestlevelraid then highestlevelraid = raidlevel end
	if spudgun == true then table = warns_spudgun else table = warns end

	for k, v in pairs(table) do
		if highestlevelraid >= tonumber(k) then
			warn1 = v.w1
			warn2_L = v.w2_L
			warn2_G = v.w2_G
			warn3 = v.w3
			warn4 = v.w4
			break
		end
	end
	
	for i=1,4 do
		if not raidGuiKeys[i] then
			raidGuiKeys[i] = raidguikey
			raidGuiNum = tostring(i)
			break
		end
	end

	if not raidGuiNum then
		raidGuiExtra = raidGuiExtra + 1
		g_survivalHud:setText("ExtraRaids", "#f2bd94 +".. raidGuiExtra.. " Raids")
		if self.cl then
			if self.cl.exi.raidGui == true then g_survivalHud:setVisible("ExtraRaids", true) end
		else
			Multiplr_WaitWithOpen2 = true
		end
		return
	end

	raidAmountVis = raidAmountVis + 1
	g_survivalHud:setVisible("Raid".. raidGuiNum, true)
	if self.cl then
		if self.cl.exi.raidGui == true then g_survivalHud:setVisible("RaidBackground", true) end
		if self.cl.exi.DynamicRaidBG then
			local full = false
			if raidAmountVis > 2 then full = true end
			g_survivalHud:setVisible("RaidGui_full", full)
			g_survivalHud:setVisible("RaidGui_half", not full)
		end
	else
		Multiplr_WaitWithOpen1 = true
	end

	if raiders then
		raidValues[raidGuiNum] = {
			pos = { x = tostring(round(tonumber(guiPos.x))), y = tostring(round(tonumber(guiPos.y))) },
			cell = { x = tostring(round(tonumber(guiPos.x/CellSize))), y = tostring(round(tonumber(guiPos.y/CellSize))) },
			level = tostring(raidlevel),
			wave = tostring(raidwave),
			cropValue = tostring(ExI_cropValue),
			bots = { totebot = tostring(raiders[unit_totebot_green] or "0"), haybot = tostring(raiders[unit_haybot] or "0"), tapebot = tostring(raiders[unit_tapebot] or "0"), farmbot = tostring(raiders[unit_farmbot] or "0") }
		}
	else
		sm.gui.chatMessage("#ff0000CRITICAL ERROR IN RAID GUI.")
		return
	end

	local col1,col2 = "#a8acff", "#a8e084"
	if self.cl then
		if self.cl.exi.RaidGUIStyle == 2 then col1,col2 = "#888888", "#ffcd3f" end
	end
	
	g_survivalHud:setText("text2_raid".. raidGuiNum, col1.. "Pos: ".. raidValues[raidGuiNum].pos.x .. ",".. raidValues[raidGuiNum].pos.y.. " | Cell: ".. raidValues[raidGuiNum].cell.x.. ",".. raidValues[raidGuiNum].cell.y )
	g_survivalHud:setText("ProgressBarTextTime_raid".. raidGuiNum, col1.. "Level: ".. raidValues[raidGuiNum].level.. " | Wave: ".. raidValues[raidGuiNum].wave.. " | Crop Value: ".. raidValues[raidGuiNum].cropValue )
	g_survivalHud:setText("ProgressBarText_raid".. raidGuiNum, col1.. "Totebot: ".. col2.. raidValues[raidGuiNum].bots.totebot.. col1.. " Haybot: ".. col2.. raidValues[raidGuiNum].bots.haybot.. col1.. " Tapebot: ".. col2.. raidValues[raidGuiNum].bots.tapebot.. col1.. " Farmbot: ".. col2.. raidValues[raidGuiNum].bots.farmbot )

	return raidGuiNum
end

function SurvivalPlayer.client_onRaidCountdownStop( self, attack )
	local raidGuiNum = attack.raidGuiNum

	if not raidGuiNum then
		raidGuiExtra = raidGuiExtra - 1
		if raidguExtra == 0 then g_survivalHud:setVisible("ExtraRaids", false) end
		return
	end

	if raidAmountVis <= 1 then
		g_survivalHud:setVisible("RaidBackground", false)
	end
	raidAmountVis = raidAmountVis - 1
	g_survivalHud:setVisible("Raid".. raidGuiNum, false)

	raidGuiKeys[tonumber(raidGuiNum)] = nil

	prevtime = 0
end

function SurvivalPlayer.client_onRaidCountdownUpdate( self, formattedCountdown, attack, timeLeft )
	local raidGuiNum = attack.raidGuiNum

	if raidGuiNum == "1" then
		if not self.cl and cl2 then self.cl = cl2 end
		if self.cl.exi.raidWarnings == true then
			if prevtime ~= math.floor(timeLeft) then
				prevtime = math.floor(timeLeft)
		
				if timeLeft < warn2_L and timeLeft > warn2_G then
					sm.gui.displayAlertText("Raid(s) Starting in ".. tostring(prevtime).. " Seconds...", 1.2)
					sm.audio.play("Sensor on")
				elseif timeLeft < warn3 then
					if prevtime == -1 then
						sm.gui.displayAlertText("#ff1100 RAID(S) STARTING", 2.5)
						sm.audio.play("Sensor on")
						sm.audio.play("Sensor on")
						sm.audio.play("Retrowildblip")
						sm.audio.play("Retrowildblip")
						sm.audio.play("Retrowildblip")
					else
						sm.gui.displayAlertText("#ff".. tostring(prevtime).. "00 Raid(s) Starting in ".. tostring(prevtime).. " Seconds...", 1.2)
						sm.audio.play("Sensor on")
						sm.audio.play("Retrofmblip")
					end
				elseif math.floor(timeLeft) == warn1 then
					sm.gui.displayAlertText("Raid(s) Starting in ".. tostring(prevtime).. " Seconds.", 8)
					sm.audio.play("Challenge - Fall")
				elseif math.floor(timeLeft) == warn4 then
					sm.gui.displayAlertText("Raid(s) Starting in ".. tostring(prevtime).. " Seconds.", 8)
					sm.audio.play("Sensor off")
				end
			end
		end
	end

	if not attack.startTick then attack.startTick = sm.game.getCurrentTick() end
	local barlength = tostring(round(120-(timeLeft/attack.startTick)*120))
	g_survivalHud:setText("text1_raid".. raidGuiNum, CountUpdateCols[1].. "Raid starts in: ".. formattedCountdown)

	g_survivalHud:setItemIcon( "Progressbar_raid".. raidGuiNum, "ExI_GuiMap", "ExI_Bar_".. CountUpdateCols[2], tostring( barlength ) )
end


-- Raid calculator

local function calcIsAnyOf( is, off )
	for _, v in pairs(off) do
		if is == _ then
			return v
		end
	end
	return nil
end

function SurvivalPlayer.client_calccmd( self, param2, param3 )
	local CropTypeShortcut = calcIsAnyOf(param2, ExI_cropTypeShortcuts)
	if CropTypeShortcut then param2 = CropTypeShortcut end

	if not param2 then
		if rcalcvisible == false then
			g_survivalHud:setVisible( "CalcPanel", true )
			rcalcvisible = true
			sm.gui.chatMessage("Raid Size Calculator #d3ffc1Activated#ffffff, type #93ff8b/calc#ffffff or #93ff8b/c#ffffff to Deactivate it agian")
			self:client_updatecalcGUI()
		else
			g_survivalHud:setVisible( "CalcPanel", false )
			rcalcvisible = false
			sm.gui.chatMessage("Raid Size Calculator #ffa4a4Deactivated#ffffff, type #93ff8b/calc#ffffff or #93ff8b/c#ffffff to Activate it agian")
		end
	elseif isAnyOf(param2, ExI_cropTypes) then
		if string.len(param3 or "" ) > 9 then
			sm.gui.chatMessage("#ff0000".. param3.. " is too big or is not a number!")
			return
		elseif tonumber(param3) == nil then
			sm.gui.chatMessage("#ff0000Could not interpret parameter 2 as int")
			return
		end
		param3 = tonumber(param3)
		if param3 > -1 then
			rcalcvals[param2] = param3
			self:client_updatecalcGUI()
		else
			sm.gui.chatMessage("#ff0000You cannot have negative crops!")
		end
	elseif param2 == "reset" then
		for _, crop in pairs(rcalcvals) do
			rcalcvals[_] = 0
		end
		self:client_updatecalcGUI()
		sm.gui.chatMessage("The raid size calculator has been reset")
	elseif param2 == "inv" then
		local inventory = sm.localPlayer.getPlayer():getInventory()
		rcalcvals.carrot = sm.container.totalQuantity( inventory, obj_seed_carrot)
		rcalcvals.tomato = sm.container.totalQuantity( inventory, obj_seed_tomato)
		rcalcvals.redbeet = sm.container.totalQuantity( inventory, obj_seed_redbeet)
		rcalcvals.banana = sm.container.totalQuantity( inventory, obj_seed_banana)
		rcalcvals.blueberry = sm.container.totalQuantity( inventory, obj_seed_blueberry)
		rcalcvals.orange = sm.container.totalQuantity( inventory, obj_seed_orange)
		rcalcvals.potato = sm.container.totalQuantity( inventory, obj_seed_potato)
		rcalcvals.cotton = sm.container.totalQuantity( inventory, obj_seed_cotton)
		rcalcvals.pineapple = sm.container.totalQuantity( inventory, obj_seed_pineapple)
		rcalcvals.broccoli = sm.container.totalQuantity( inventory, obj_seed_broccoli)
		self:client_updatecalcGUI()
		sm.gui.chatMessage("The raid size calculator values set to the amount of seeds in your inventory")
	else
		sm.gui.chatMessage("#ff0000Raid calculator command not found: ".. param2)
	end

end

function SurvivalPlayer.client_updatecalcGUI( self )
	local setvis = true
	local rv = rcalcvals
	local cv = ExI_cropValue
	local cropValue = 0
	for k in pairs(rv) do
		cropValue = cropValue+( rv[k]*cv[k] )
	end
	local highLevelCount = rv.pineapple+rv.broccoli
	local level
	
	if cropValue < 10 then
		level = 0
		setvis = false
	elseif highLevelCount >= 50 and cropValue >= 300 then
		level = 10
		self:client_calcsettext("3x  Totebots", "6x  Haybots", "4x  Tapebots", "1x  Farmbot", "n1")
		self:client_calcsettext("3x  Totebots", "6x  Haybots", "4x  Tapebots", "1x  Farmbot", "n2")
		self:client_calcsettext("3x  Totebots", "6x  Haybots", "5x  Tapebots", "3x  Farmbots", "n3")
	elseif highLevelCount >= 20 and cropValue >= 150 then
		level = 9
		self:client_calcsettext("3x  Totebots", "6x  Haybots", "3x  Tapebots", "", "n1")
		self:client_calcsettext("3x  Totebots", "8x  Haybots", "3x  Tapebots", "", "n2")
		self:client_calcsettext("3x  Totebots", "10x  Haybots", "4x  Tapebots", "1x  Farmbot", "n3")
	elseif highLevelCount >= 10 and cropValue >= 110 then
		level = 8
		self:client_calcsettext("3x  Totebots", "6x  Haybots", "2x  Tapebots", "", "n1")
		self:client_calcsettext("3x  Totebots", "8x  Haybots", "2x  Tapebots", "", "n2")
		self:client_calcsettext("3x  Totebots", "10x  Haybots", "3x  Tapebots", "", "n3")
	elseif highLevelCount >= 5 and cropValue >= 80 then
		level = 7
		self:client_calcsettext("3x  Totebots", "6x  Haybots", "1x  Tapebot", "", "n1")
		self:client_calcsettext("3x  Totebots", "8x  Haybots", "1x  Tapebot", "", "n2")
		self:client_calcsettext("3x  Totebots", "10x  Haybots", "2x  Tapebots", "", "n3")
	elseif cropValue >= 60 then
		level = 6
		self:client_calcsettext("4x  Totebots", "6x  Haybots", "", "", "n1")
		self:client_calcsettext("4x  Totebots", "8x  Haybots", "", "", "n2")
		self:client_calcsettext("4x  Totebots", "10x  Haybots", "", "", "n3")
	elseif cropValue >= 50 then
		level = 5
		self:client_calcsettext("4x  Totebots", "4x  Haybots", "", "", "n1")
		self:client_calcsettext("4x  Totebots", "6x  Haybots", "", "", "n2")
		self:client_calcsettext("4x  Totebots", "8x  Haybots", "", "", "n3")
	elseif cropValue >= 40 then
		level = 4
		self:client_calcsettext("4x  Totebots", "3x  Haybots", "", "", "n1")
		self:client_calcsettext("4x  Totebots", "5x  Haybots", "", "", "n2")
		self:client_calcsettext("4x  Totebots", "7x  Haybots", "", "", "n3")
	elseif cropValue >= 30 then
		level = 3
		self:client_calcsettext("4x  Totebots", "2x  Haybots", "", "", "n1")
		self:client_calcsettext("4x  Totebots", "3x  Haybots", "", "", "n2")
		self:client_calcsettext("4x  Totebots", "5x  Haybots", "", "", "n3")
	elseif cropValue >= 20 then
		level = 2
		self:client_calcsettext("4x  Totebots", "1x  Haybot", "", "", "n1")
		self:client_calcsettext("4x  Totebots", "2x  Haybots", "", "", "n2")
		self:client_calcsettext("4x  Totebots", "3x  Haybots", "", "", "n3")
	else
		level = 1
		self:client_calcsettext("3x  Totebots", "", "", "", "n1")
		self:client_calcsettext("4x  Totebots", "", "", "", "n2")
		self:client_calcsettext("3x  Totebots", "1x  Haybot", "", "", "n3")
	end
	
	g_survivalHud:setText("calc_cropamountcarrot", tostring(rcalcvals.carrot))
	g_survivalHud:setText("calc_cropamounttomato", tostring(rcalcvals.tomato))
	g_survivalHud:setText("calc_cropamountredbeet", tostring(rcalcvals.redbeet))
	g_survivalHud:setText("calc_cropamountpotato", tostring(rcalcvals.potato))
	g_survivalHud:setText("calc_cropamountcotton", tostring(rcalcvals.cotton))
	g_survivalHud:setText("calc_cropamountbanana", tostring(rcalcvals.banana))
	g_survivalHud:setText("calc_cropamountblueberry", tostring(rcalcvals.blueberry))
	g_survivalHud:setText("calc_cropamountorange", tostring(rcalcvals.orange))
	g_survivalHud:setText("calc_cropamountpineapple", tostring(rcalcvals.pineapple))
	g_survivalHud:setText("calc_cropamountbroccoli", tostring(rcalcvals.broccoli))
	
	g_survivalHud:setText("calc_cropvalue", tostring(cropValue))
	g_survivalHud:setText("calc_highlevelcount", tostring(highLevelCount))
	g_survivalHud:setText("calc_level", "#{RAID_SC_EXPANDED_INFO_MISC_LEVEL} "..tostring(level))
	
	g_survivalHud:setVisible("Night1", setvis)
	g_survivalHud:setVisible("Night2", setvis)
	g_survivalHud:setVisible("Night3", setvis)
	if setvis == false then g_survivalHud:setVisible("Farmingsafe", true) else g_survivalHud:setVisible("Farmingsafe", false) end
end

function SurvivalPlayer.client_calcsettext( self, Totebot, Haybot, Tapebot, Farmbot, night )
	g_survivalHud:setText(night.."_Totebot", Totebot)
	g_survivalHud:setText(night.."_Haybot", Haybot)
	g_survivalHud:setText(night.."_Tapebot", Tapebot)
	g_survivalHud:setText(night.."_Farmbot", Farmbot)
end


-- Control panel

--client
function SurvivalPlayer.client_togglesomestuff( self, action, dropdownState )
	local player = sm.localPlayer.getPlayer()
	local newstate

	if not ExI_Toggles[action].special[1] then
		newstate = not self.cl.exi[action]
		self:client_OnOffButton(ExI_Toggles[action].onOffName, newstate)
	else
		newstate = dropdownState
		ExI_CtrlpanelGUI:setText(ExI_Toggles[action].onOffName.. "Value", ExI_Toggles[action].special[1][newstate])
		for i=1,#ExI_Toggles[action].special[1] do
			local col = "#757575"
			if i == newstate then col = "#ffd449" end
			ExI_CtrlpanelGUI:setText(ExI_Toggles[action].onOffName.. tostring(i).. "Text", col.. ExI_Toggles[action].special[1][i] )
		end
	end

	local newstate2 = newstate
	if ExI_Toggles[action].special[2] then
		if ExI_Toggles[action].special[2].type == "questDone" then
			if not Client_isQuestCompleted( ExI_Toggles[action].special[2].quest ) then
				newstate2 = false
			end
		end
	end

	self.cl.exi[action] = newstate
	for i=1,#ExI_Toggles[action].vis do
		g_survivalHud:setVisible(ExI_Toggles[action].vis[i], newstate2)
	end

	if action == "speedunit" then
		if dropdownState == 1 then
			speedconv = 3.599
			speedUnittxt = " km/h"
		elseif dropdownState == 2 then
			speedconv = 2.237
			speedUnittxt = " mph"
		else
			speedconv = 1
			speedUnittxt = " m/s"
		end
	elseif action == "DynamicRaidBG" then
		self:client_raidguicmd("t", nil, false)
		self:client_raidguicmd("t", nil, false)
	elseif action == "DamageIndicator" and newstate == false then
		lookingAtCharacter = nil
		self.network:sendToServer("sv_updatePlrThing", nil)
	end

	self.network:sendToServer("server_ChangeExiSetting", { playerid = player.id, setting = action, value = newstate } )
end

function SurvivalPlayer.client_exiConButton( self, buttonName )
	if not self.cl and cl2 then self.cl = cl2 end

	for k,v in pairs(ExI_Toggles) do
		if buttonName == v.onOffName.. "On" or buttonName == v.onOffName.. "Off" then
			self:client_togglesomestuff(k, nil)
			return
		end
	end

	if buttonName == "RaidGUIOn" or buttonName == "RaidGUIOff" then self:client_raidguicmd("t", nil, false)

	elseif buttonName == "RaidGUIStyleBtn" then
		RaidGuiStyleExpanded = not RaidGuiStyleExpanded
		UnitExpanded = false
		self:client_DropDownButton( { btnName = buttonName, btnName2 = "RaidGUIStyle", state = RaidGuiStyleExpanded } )
	elseif buttonName == "RaidGUIStyle1" or buttonName == "RaidGUIStyle2" or buttonName == "RaidGUIStyle3" then
		self:client_raidguicmd("s", string.gsub(buttonName, "RaidGUIStyle", ""), false)
		RaidGuiStyleExpanded = false
		self:client_DropDownButton( { btnName = buttonName, btnName2 = "RaidGUIStyle" } )


	elseif buttonName == "UnitBtn" then
		RaidGuiStyleExpanded = false
		UnitExpanded = not UnitExpanded
		self:client_DropDownButton( { btnName = buttonName, btnName2 = "Unit", state = UnitExpanded } )
	elseif buttonName == "Unit1" or buttonName == "Unit2" or buttonName == "Unit3" then
		if buttonName == "Unit1" then
			self:client_togglesomestuff( "speedunit", 1 )
		elseif buttonName == "Unit2" then
			self:client_togglesomestuff( "speedunit", 2 )
		else
			self:client_togglesomestuff( "speedunit", 3 )
		end
		UnitExpanded = false
		self:client_DropDownButton( { btnName = buttonName, btnName2 = "Unit" } )

	elseif buttonName == "Default" then
		ExI_CtrlpanelGUI:setVisible("PopUpYNMainPanel", true)
		ExI_CtrlpanelGUI:setVisible("CreateGamePanel", false)
		PopUpYNOpen = true
	elseif buttonName == "PopUpYNYes" then
		ExI_CtrlpanelGUI:setVisible("CreateGamePanel", true)
		ExI_CtrlpanelGUI:setVisible("PopUpYNMainPanel", false)
		PopUpYNOpen = false
		self:client_togglesomestuff( "speedunit", 1 )
		if not self.cl.exi.compass then self:client_togglesomestuff("compass", nil) end
		if not self.cl.exi.raidGui then self:client_raidguicmd("t", nil, false) end
		if not self.cl.exi.raidWarnings then self:client_togglesomestuff("raidWarnings", nil) end
		if not self.cl.exi.Animations then self:client_togglesomestuff("Animations", nil) end
		if self.cl.exi.RaidGUIStyle ~= 1 then self:client_raidguicmd("s", "1", false) end
		if not self.cl.exi.clock then self:client_togglesomestuff("clock", nil) end
		if not self.cl.exi.speedometer then self:client_togglesomestuff("speedometer", nil) end
		if not self.cl.exi.DamageIndicator then self:client_togglesomestuff("DamageIndicator", nil) end
		if self.cl.exi.DynamicRaidBG then self:client_togglesomestuff("DynamicRaidBG", nil) end
		if not self.cl.exi.counters then self:client_togglesomestuff("counters", nil) end
		if not self.cl.exi.hitsLeft then self:client_togglesomestuff("hitsLeft", nil) end
	elseif buttonName == "PopUpYNNo" then
		ExI_CtrlpanelGUI:setVisible("CreateGamePanel", true)
		ExI_CtrlpanelGUI:setVisible("PopUpYNMainPanel", false)
		PopUpYNOpen = false
	end
end

function SurvivalPlayer.client_OnOffButton( self, buttonName, state )
	ExI_CtrlpanelGUI:setButtonState(buttonName.. "On", state)
	ExI_CtrlpanelGUI:setButtonState(buttonName.. "Off", not state)
end

function SurvivalPlayer.client_DropDownButton( self, dt ) --dt = data
	if dt.btnName == dt.btnName2.. "Btn" then
		for _, dropdown in pairs( ExI_ButtonsBelow ) do
			local newstate = not dt.state
			if _ ~= dt.btnName2 then newstate = true end
			ExI_CtrlpanelGUI:setVisible(_.. "Collapsed", newstate)
			ExI_CtrlpanelGUI:setVisible(_.. "Expanded", not newstate)
			for _, Widget in pairs( dropdown ) do
				ExI_CtrlpanelGUI:setVisible(Widget, newstate)
			end
		end
	elseif dt.btnName == dt.btnName2.. "1" or dt.btnName == dt.btnName2.. "2" or dt.btnName == dt.btnName2.. "3" or dt.btnName == dt.btnName2.. "4" or dt.btnName == dt.btnName2.. "5" then
		ExI_CtrlpanelGUI:setVisible(dt.btnName2.. "Collapsed", true)
		ExI_CtrlpanelGUI:setVisible(dt.btnName2.. "Expanded", false)
		for _, dropdown in pairs( ExI_ButtonsBelow ) do
			ExI_CtrlpanelGUI:setVisible(_.. "Collapsed", true)
			ExI_CtrlpanelGUI:setVisible(_.. "Expanded", false)
			for _, Widget in pairs( dropdown ) do
				ExI_CtrlpanelGUI:setVisible(Widget, true)
			end
		end
	end
end

function SurvivalPlayer.client_exiChangePage( self, buttonName )
	ExI_CtrlpanelGUI:setVisible( "Page".. tostring(ExI_Currentpage), false)
	if buttonName == "Prev" and ExI_Currentpage > 1 then
		ExI_Currentpage = ExI_Currentpage - 1
	elseif buttonName == "Prev" then
		ExI_Currentpage = ExI_Totalpages
	end
	if buttonName == "Next" and ExI_Currentpage < ExI_Totalpages then
		ExI_Currentpage = ExI_Currentpage + 1
	elseif buttonName == "Next" then
		ExI_Currentpage = 1
	end
	ExI_CtrlpanelGUI:setText( "Tracker", tostring(ExI_Currentpage).. "/".. tostring(ExI_Totalpages) )
	ExI_CtrlpanelGUI:setVisible( "Page".. tostring(ExI_Currentpage), true)
end

function SurvivalPlayer.client_openexiConfig( self )
	if ExI_CtrlpanelGUI then
		print("opening gui")
		ExI_CtrlpanelGUI:open()
	else
		print("Gui not found")
	end
end

function SurvivalPlayer.client_onexiConfigClose( self )
	if PopUpYNOpen then
		ExI_CtrlpanelGUI:open()
		ExI_CtrlpanelGUI:setVisible("CreateGamePanel", true)
		ExI_CtrlpanelGUI:setVisible("PopUpYNMainPanel", false)
		PopUpYNOpen = false
	elseif RaidGuiStyleExpanded or UnitExpanded then
		RaidGuiStyleExpanded = false
		UnitExpanded = false
		self:client_DropDownButton( { btnName = "RaidGUIStyleBtn", btnName2 = "RaidGUIStyle", state = false } )
	end
end

--server
function SurvivalPlayer.server_ChangeExiSetting( self, data )
	if data.playerid then

		if not self.sv.updateExiSettings[data.playerid] then
			self.sv.updateExiSettings[data.playerid] = {}
		end

		self.sv.updateExiSettings[data.playerid][data.setting] = data.value
	end
end


-- Damage indicator

--client
function SurvivalPlayer.cl_updateIndicator( self, data )
	if data[1] then
		local unitType = data[1]
		local hp = data[2]
		local maxhp = data[3]
		local charId = data[4]
		local HPBarText = "HP: ".. tostring(round(hp)).. "/".. tostring(maxhp)
		Indicator_HPBarActive = true
		HPBarlength = (hp/maxhp)*60
			
		if isAnyOf(unitType, Indicator_HasIcons) then
			g_survivalHud:setItemIcon( "IndicatorIcon", "ExI_GuiMap", "UnitIcons", unitType )
		else
			g_survivalHud:setItemIcon( "IndicatorIcon", "ExI_GuiMap", "UnitIcons", "Missing" )
		end
		g_survivalHud:setText( "BotName", unitType )
		g_survivalHud:setText("Indicator_HPText", HPBarText)
		g_survivalHud:setVisible("AttackIndicatorPanel", true)
		
		--Update Stats (except health)
		for i = 2,3 do
			g_survivalHud:setText("Indicator_StatText".. tostring(i), "")
			g_survivalHud:setVisible("Indicator_StatLine".. tostring(i-1), false)
			g_survivalHud:setVisible("Indicator_StatImg".. tostring(i), false)
		end
		for _, stat in pairs(IndicatorStats[unitType] or {true} ) do
			if stat == true then
				g_survivalHud:setVisible("Indicator_StatImg".. tostring(_), false)
				g_survivalHud:setVisible("Indicator_StatLine".. tostring(_-1), true)
				g_survivalHud:setText("Indicator_StatText".. tostring(_), "Unit ID: ".. tostring(charId))
			else
				g_survivalHud:setVisible("Indicator_StatImg".. tostring(_), true)
				g_survivalHud:setImage("Indicator_StatImg".. tostring(_), stat[2])
				g_survivalHud:setVisible("Indicator_StatLine".. tostring(_-1), true)
				g_survivalHud:setText("Indicator_StatText".. tostring(_), stat[1])
			end
		end
	else
		g_survivalHud:setVisible("AttackIndicatorPanel", false)
		barlengthOld = 0
		Indicator_HPBarActive = false
	end
end

--server
function SurvivalPlayer.sv_updatePlrThing( self, charId )
	local plrId = self.player.id
	if charId == nil then
		sv_lookingAtCharacter[plrId].data = {}
		sv_lookingAtCharacter[plrId].update = true
	end
	sv_lookingAtCharacter[plrId].charId = charId
end

function SurvivalPlayer.sv_unitUpdates( self, data )
	local id = self.unit:getCharacter():getId()
	for k in pairs(sv_lookingAtCharacter) do
		if sv_lookingAtCharacter[k].charId == id then
			if sv_lookingAtCharacter[k].data[2] ~= data[2] or sv_lookingAtCharacter[k].data[4] ~= id then
				sv_lookingAtCharacter[k].data = data
				sv_lookingAtCharacter[k].update = true
			end
		end
	end
end


-- Random

function SurvivalPlayer.client_hitsLeft( self, health, DamagerPerHit )
	if cl2.exi.hitsLeft then
		if health > DamagerPerHit*3 then
			sm.gui.displayAlertText( "4 Hits Left" )
		elseif health > DamagerPerHit*2 then
			sm.gui.displayAlertText( "3 Hits Left" )
		elseif health > DamagerPerHit*1 then
			sm.gui.displayAlertText( "2 Hits Left" )
		elseif health > 0 then
			sm.gui.displayAlertText( "1 Hit Left" )
		else
			sm.gui.displayAlertText( "0 Hits Left" )
		end
	end
end

function SurvivalPlayer.cl_setAnim( self, id, inOut)
	if id == 1 then
		if self.cl.exi.Animations == true then
			counter1.anim_out = inOut
			counter1.anim_active = true
			counter1.visible = inOut
		else
			counter1.visible = inOut
			g_survivalHud:setVisible("SpudCounterBg1", inOut)
		end
	elseif id == 2 then
		if self.cl.exi.Animations == true then
			counter2.anim_out = inOut
			counter2.anim_active = true
			counter2.visible = inOut
		else
			counter2.visible = inOut
			g_survivalHud:setVisible("CounterPanel1", inOut)
		end
	end
end

-- Expanded Info Part Of Script END --