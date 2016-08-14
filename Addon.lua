--[[--------------------------------------------------------------------
	HandyNotes: Higher Learning
	Shows the books you still need for the Higher Learning achievement.
	Copyright (c) 2014-2016 Phanx <addons@phanx.net>. All rights reserved.
	http://www.wowinterface.com/downloads/info23267-HandyNotes-HigherLearning.html
	https://mods.curse.com/addons/wow/handynotes-higher-learning
	https://github.com/Phanx/HandyNotes_HigherLearning
----------------------------------------------------------------------]]

local L = {}
if GetLocale() == "deDE" then
	L["<Right-Click to set a waypoint in TomTom>"] = "<Rechtsklick, um eine Zielpunkt in TomTom zu setzen>"
	L["<Ctrl-Right-Click to set waypoints for all unread books>"] = "<STRG-Rechtsklick, um Zielpunkte für alle ungelesenen Bücher zu setzen>"
	L["In the Teleportation Crystal room, on the floor next to the bookshelf"] = "Im Teleportationskristallsraum, auf dem Boden neben dem Bücherregal"
	L["Downstairs, on the floor next to the table"] = "Im Erdgeschoss, auf dem Boden neben dem Tisch"
	L["On the bookshelf on the left"] = "Auf dem linken Bücherregal"
	L["Upstairs, on the floor to the left of the Caverns of Time portal"] = "Nach oben, auf dem Boden links von dem Portal zum Höhlen der Zeit"
	L["On a crate on the balcony"] = "Auf einer Kiste auf dem Balkon"
	L["On the crate next to the wine glass"] = "Auf der Kiste neben dem Weinglas"
	L["Upstairs, on the bookshelf in the west bedroom"] = "Nach oben, auf dem Bücherregal in dem westlichen Schlafzimmer"
	L["Downstairs, on the bookshelf in the west corner"] = "Im Erdgeschoss, auf dem Bücherregal in der westlichen Ecke"
elseif GetLocale():match("^es") then
	L["<Right-Click to set a waypoint in TomTom>"] = "<Clic derecho para establecer un waypoint en TomTom>"
	L["<Ctrl-Right-Click to set waypoints for all unread books>"] = "<Ctrl-clic derecho para establecer waypoints de todos libros no leídos>"
	L["In the Teleportation Crystal room, on the floor next to the bookshelf"] = "En la sala del Cristal de Teletransporte, en el piso al lado de la estantería"
	L["Downstairs, on the floor next to the table"] = "En la planta baja, en el piso al lado de la mesa"
	L["On the bookshelf on the left"] = "En la estantería a la izquierda"
	L["Upstairs, on the floor to the left of the Caverns of Time portal"] = "En la planta alta, en el piso a la izquierda del portal a las Cavernas del Tiempo"
	L["On a crate on the balcony"] = "En un cajón en el balcón"
	L["On the crate next to the wine glass"] = "En el cajón al lado del vaso de vino"
	L["Upstairs, on the bookshelf in the west bedroom"] = "En la planta alta, en la estantería en el dormitorio occidental"
	L["Downstairs, on the bookshelf in the west corner"] = "En la planta baja, en la estantería en la esquina occidental"
end

------------------------------------------------------------------------

local books = {
	[56684560] = { 7236, "Introduction",  "In the Teleportation Crystal room, on the floor next to the bookshelf" },
	[52385476] = { 7237, "Abjuration",    "Downstairs, on the floor next to the table" },
	[30784589] = { 7238, "Conjuration",   "On the bookshelf on the left" },
	[26525220] = { 7239, "Divination",    "Upstairs, on the floor to the left of the Caverns of Time portal" },
	[43564671] = { 7240, "Enchantment",   "On a crate on the balcony" },
	[64425237] = { 7241, "Illusion",      "On the crate next to the wine glass" },
	[46693905] = { 7242, "Necromancy",    "Upstairs, on the bookshelf in the west bedroom" },
	[46834001] = { 7243, "Transmutation", "Downstairs, on the bookshelf in the west corner" },
}

local waypoints = {}

local ADDON_NAME = ...
local MAPFILE, MAP_ID, ACHIEVEMENT_ID = "Dalaran", 504, 1956
local ICON = "Interface\\Minimap\\Tracking\\Class"
local ADDON_TITLE = GetAddOnMetadata(ADDON_NAME, "Title")
local ACHIEVEMENT_NAME = select(2, GetAchievementInfo(ACHIEVEMENT_ID))
local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")

setmetatable(L, { __index = function(t, k) t[k] = k return k end })

------------------------------------------------------------------------

local pluginHandler = {}

function pluginHandler:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	if self:GetCenter() > UIParent:GetCenter() then
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	local criteria = books[coord]
	if criteria then
		tooltip:AddLine(ACHIEVEMENT_NAME)
		tooltip:AddLine(GetAchievementCriteriaInfoByID(ACHIEVEMENT_ID, criteria[1]), 1, 1, 1)
		tooltip:AddLine(L[criteria[3]] or criteria[3], 1, 1, 1)
		if TomTom and tooltip:GetOwner():GetParent() ~= Minimap then
			-- ^ pins on minimap aren't clickable
			tooltip:AddLine(L["<Right-Click to set a waypoint in TomTom>"])
			tooltip:AddLine(L["<Ctrl-Right-Click to set waypoints for all unread books>"])
		end
		tooltip:Show()
	end
end

function pluginHandler:OnLeave(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	tooltip:Hide()
end

do
	local function setWaypoint(coord)
		if waypoints[coord] and TomTom:IsValidWaypoint(waypoints[coord]) then
			return
		end
		local x, y = HandyNotes:getXY(coord)
		local criteria = GetAchievementCriteriaInfoByID(ACHIEVEMENT_ID, books[coord][1])
		waypoints[coord] = TomTom:AddMFWaypoint(MAP_ID, nil, x, y, {
			title = criteria,
			persistent = nil,
			minimap = true,
			world = true
		})
	end

	local function setAllWaypoints()
		for coord in pairs(books) do
			setWaypoint(coord)
		end
		TomTom:SetClosestWaypoint()
	end

	function pluginHandler:OnClick(button, down, mapFile, coord)
		if button ~= "RightButton" or not TomTom then
			return
		end
		if IsControlKeyDown() then
			setAllWaypoints()
			--local data = waypoints[coord]
			--TomTom:SetCrazyArrow(data, TomTom.profile.arrow.arrival, data.title)
		else
			setWaypoint(coord)
		end
	end

	SLASH_HANDYNOTES_HIGHERLEARNING1 = "/hnhl"
	SLASH_HANDYNOTES_HIGHERLEARNING2 = "/higherlearning"
	SlashCmdList["HANDYNOTES_HIGHERLEARNING"] = function()
		if TomTom then
			setAllWaypoints()
		end
	end
end

do
	local function iterator(t, last)
		if not t then return end
		local k, v = next(t, last)
		while k do
			if v then
				-- coord, mapFile2, iconpath, scale, alpha, level2
				return k, nil, ICON, 1, 1
			end
			k, v = next(t, k)
		end
	end

	function pluginHandler:GetNodes(mapFile, minimap, dungeonLevel)
		return iterator, mapFile == MAPFILE and books or nil
	end
end

------------------------------------------------------------------------

local Addon = CreateFrame("Frame")
Addon:RegisterEvent("PLAYER_LOGIN")
Addon:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)

function Addon:PLAYER_LOGIN()
	--print("PLAYER_LOGIN")
	HandyNotes:RegisterPluginDB(ACHIEVEMENT_NAME, pluginHandler)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:CRITERIA_COMPLETE()
end

function Addon:ZONE_CHANGED_NEW_AREA()
	--print("ZONE_CHANGED_NEW_AREA", GetCurrentMapAreaID(), GetZoneText())
	if GetCurrentMapAreaID() == 504 or GetZoneText() == GetMapNameByID(504) then
		self:RegisterEvent("CRITERIA_COMPLETE")
	else
		self:UnregisterEvent("CRITERIA_COMPLETE")
	end
end

function Addon:CRITERIA_COMPLETE(...)
	--print("CRITERIA_COMPLETE", ...)
	local changed
	for coord, criteria in pairs(books) do
		local name, _, complete = GetAchievementCriteriaInfoByID(ACHIEVEMENT_ID, criteria[1])
		if complete then
			--print("COMPLETED:", name)
			books[coord] = nil
			if waypoints[coord] then
				if TomTom and TomTom:IsValidWaypoint(waypoints[coord]) then
					TomTom:RemoveWaypoint(waypoints[coord])
				end
				waypoints[coord] = nil
			end
			changed = true
		end
	end
	if changed then
		HandyNotes:SendMessage("HandyNotes_NotifyUpdate", ACHIEVEMENT_NAME)
	end
end
