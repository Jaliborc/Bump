--[[
Copyright 2009-2025 João Cardoso
All Rights Reserved
--]]

local ADDON, Addon = ...
local C = LibStub('C_Everywhere').CurrencyInfo
local Bump = LibStub('WildAddon-1.1'):NewAddon(ADDON, Addon)

local MatchReputation = FACTION_STANDING_INCREASED:gsub('%%s', '(%.+)'):gsub('%%d', '(%%d+)')
local L = Bump_Locals


--[[ Events ]]--

function Bump:OnLoad()
	Bump_Currency = Bump_Currency or {}
	Bump_Rep = Bump_Rep or {}

	self:ContinueOn('PLAYER_ENTERING_WORLD', function()
		self:RegisterEvent('ZONE_CHANGED_NEW_AREA')
		self:ZONE_CHANGED_NEW_AREA()
	end)
end

function Bump:ZONE_CHANGED_NEW_AREA()
	local IsInstance = IsInInstance()
	if IsInstance then
		if Bump_Instance ~= GetRealZoneText() then
			self:StartValues() -- New Instance
		end
		self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE')
		self:RegisterEvent('CHAT_MSG_COMBAT_XP_GAIN')
		self:UnregisterEvent('PLAYER_UNGHOST')
	else
		if Bump_Instance then
			if UnitIsDeadOrGhost('player') then
				self:RegisterEvent('PLAYER_UNGHOST')
			else
				self:PrintValues() -- Left Instance
			end
		end
		self:UnregisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE')
		self:UnregisterEvent('CHAT_MSG_COMBAT_XP_GAIN')
	end
end

function Bump:PLAYER_UNGHOST()
	self:UnregisterEvent('PLAYER_UNGHOST')
	self:ZONE_CHANGED_NEW_AREA()
end

function Bump:CHAT_MSG_COMBAT_FACTION_CHANGE(message)
	local faction, increase = strmatch(message, MatchReputation)
	if faction and increase then
		Bump_Rep[faction] = (Bump_Rep[faction] or 0) + increase
	end
end

function Bump:CHAT_MSG_COMBAT_XP_GAIN(message)
	local increase = strmatch(message, '(%d+)')
	if increase then
		Bump_XP = Bump_XP + increase
	end
end


--[[ API ]]--

function Bump:StartValues()
	wipe(Bump_Rep)
	wipe(Bump_Currency)

	for id = 1, 5000 do
		local data = C.GetCurrencyInfo(id)
		if data and data.quality > 0 then
			Bump_Currency[id] = data.quantity or 0
		end
	end

	Bump_Instance = GetRealZoneText()
	Bump_Money = GetMoney()
	Bump_XP = 0
end

function Bump:PrintValues()
	for faction, increase in pairs(Bump_Rep) do
		self:Print('COMBAT_FACTION_CHANGE', L.Reputation, faction, increase, Bump_Instance)
	end

	for id, amount in pairs(Bump_Currency) do
		local data = C.GetCurrencyInfo(id)
		if data then
			local change = (data.quantity or 0) - amount
			if change > 0 then
				self:Print('LOOT', L.Currency, change, data.name, Bump_Instance)
			end
		end
	end

	local money = GetMoney() - Bump_Money
	if money > 0 then
		self:Print('MONEY', L.Money, GetMoneyString(money, true), Bump_Instance)
	end

	if Bump_XP > 0 then
		self:Print('COMBAT_XP_GAIN', L.Experience, Bump_XP, Bump_Instance)
	end

	Bump_Instance = nil
end

function Bump:Print(channel, pattern, ...)
 	local channel = 'CHAT_MSG_'..channel
 	for i = 1, 10 do
		local frame = _G['ChatFrame'..i]
		if frame:IsEventRegistered(channel) then
			ChatFrame_MessageEventHandler(frame, channel, pattern:format(...), '', nil, '')
		end
	end
end
