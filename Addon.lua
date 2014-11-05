--[[--------------------------------------------------------------------
	HandyNotes: Higher Learning
	Shows the books you still need for the Higher Learning achievement.
	Copyright (c) 2014 Phanx <addons@phanx.net>. All rights reserved.
	http://www.wowinterface.com/downloads/info23267-HandyNotes-HigherLearning.html
	http://www.curse.com/addons/wow/handynotes-higher-learning

	Please DO NOT upload this addon to other websites, or post modified
	versions of it. However, you are welcome to use any/all of its code
	in your own addon, as long as you do not use my name or the name of
	this addon ANYWHERE in your addon outside of an optional attribution.
	You are also welcome to include a copy of this addon WITHOUT CHANGES
	in compilations uploaded on Curse and/or WoWInterface.
----------------------------------------------------------------------]]

local ADDON_NAME = ...
local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")

local MAPFILE, MAP_ID, ACHIEVEMENT_ID = "Dalaran", 504, 1956
local ICON = "Interface\\Minimap\\Tracking\\Class"
local ADDON_TITLE = GetAddOnMetadata(ADDON_NAME, "Title")
local ACHIEVEMENT_NAME = select(2, GetAchievementInfo(ACHIEVEMENT_ID))

local L = {
	["<Right-Click to set a waypoint in TomTom.>"] = "<Right-Click to set a waypoint in TomTom.>",
	["<Ctrl-Right-Click to set waypoints for all unread books.>"] = "<Ctrl-Right-Click to set waypoints for all unread books.>",
}
if GetLocale() == "deDE" then
	L["<Right-Click to set a waypoint in TomTom.>"] = "<Rechtsklick, um eine Zielpunkt in TomTom zu setzen.>"
	L["<Ctrl-Right-Click to set waypoints for all unread books.>"] = "<STRG-Rechtsklick, um Zielpunkte für allen ungelesenen Bücher zu setzen.>"
elseif GetLocale():match("^es") then
	L["<Right-Click to set a waypoint in TomTom.>"] = "<Clic derecho para establecer un waypoint en TomTom.>"
	L["<Ctrl-Right-Click to set waypoints for all unread books.>"] = "<Ctrl-clic derecho para waypoints de todos libros no leídos.>"
end

local books = {
	[56684560] = 7236, -- Introduction
	[52385476] = 7237, -- Abjuration
	[30784589] = 7238, -- Conjuration
	[23495221] = 7239, -- Divination
	[43564671] = 7240, -- Enchantment
	[64425237] = 7241, -- Illusion
	[46693905] = 7242, -- Necromancy
	[46693905] = 7243, -- Transmutation
}

local waypoints = {}

------------------------------------------------------------------------

local pluginHandler = {}

function pluginHandler:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	if self:GetCenter() > UIParent:GetCenter() then
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	local criteriaID = books[coord]
	if criteriaID then
		tooltip:AddLine(ACHIEVEMENT_NAME, 1, 1, 1)
		tooltip:AddLine(GetAchievementCriteriaInfoByID(ACHIEVEMENT_ID, criteriaID), 1, 1, 1)
		if TomTom then
			tooltip:AddLine(L["<Right-Click to set a waypoint in TomTom.>"])
			tooltip:AddLine(L["<Ctrl-Right-Click to set waypoints for all unread books.>"])
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
		local criteria = GetAchievementCriteriaInfoByID(ACHIEVEMENT_ID, books[coord])
		waypoints[coord] = TomTom:AddMFWaypoint(MAP_ID, nil, x, y, {
			title = criteria,
			persistent = nil,
			minimap = true,
			world = true
		})
	end

	function pluginHandler:OnClick(button, down, mapFile, coord)
		if button ~= "RightButton" or not TomTom then
			return
		end
		if IsCtrlKeyDown() then
			for coord in pairs(books) do
				setWaypoint(coord)
			end
			local data = waypoints[coord]
			TomTom:SetCrazyArrow(data, TomTom.profile.arrow.arrival, data.title)
		else
			setWaypoint(coord)
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
	self:RegisterEvent("CRITERIA_COMPLETE")
	self:CRITERIA_COMPLETE()
end

function Addon:CRITERIA_COMPLETE(...)
	--print("CRITERIA_COMPLETE", ...)
	local changed
	for coord, criteriaID in pairs(books) do
		local name, _, complete = GetAchievementCriteriaInfoByID(ACHIEVEMENT_ID, criteriaID)
		if complete then
			--print("COMPLETED:", name)
			books[coord] = nil
			if waypoints[coord] then
				if TomTom:IsValidWaypoint(waypoints[coord]) then
					TomTomTom:RemoveWaypoint(waypoints[coord])
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
