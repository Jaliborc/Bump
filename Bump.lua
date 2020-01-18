--[[
Copyright 2009-2020 João Cardoso
Bump is distributed under the terms of the GNU General Public License (or the Lesser GPL).
This file is part of Bump.

Bump is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Bump is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Bump. If not, see <http://www.gnu.org/licenses/>.
--]]

local Bump = CreateFrame('Frame', 'Bump')
local MatchReputation = FACTION_STANDING_INCREASED:gsub('%%s', '(%.+)'):gsub('%%d', '(%%d+)')
local CurrencyList = {HONOR_CURRENCY, CONQUEST_CURRENCY, JUSTICE_CURRENCY, VALOR_CURRENCY}
local L = Bump_Locals


--[[ Startup ]]--

function Bump:Startup()
	self:SetScript('OnEvent', function(self, event, ...) self[event](self, ...) end)
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self.Startup = nil
end

function Bump:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('ZONE_CHANGED_NEW_AREA')

	self.PLAYER_ENTERING_WORLD = nil
	self:ZONE_CHANGED_NEW_AREA()

	Bump_Currency = Bump_Currency or {}
	Bump_Rep = Bump_Rep or {}
end


--[[ Events ]]--

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
	if increase then
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
	if GetCurrencyInfo then
		for _, id in pairs(CurrencyList) do
			Bump_Currency[id] = select(2, GetCurrencyInfo(id))
		end
	end

	wipe(Bump_Rep)
	Bump_Instance = GetRealZoneText()
	Bump_Money = GetMoney()
	Bump_XP = 0
end

function Bump:PrintValues()
	for faction, increase in pairs(Bump_Rep) do
		self:Print('COMBAT_FACTION_CHANGE', L.Reputation, faction, increase, Bump_Instance)
	end

	for id, value in pairs(Bump_Currency) do
		local name, newValue = GetCurrencyInfo(id)
		if newValue - value > 0 then
			self:Print('LOOT', L.Currency, newValue - value, name, Bump_Instance)
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


--[[ Start Addon ]]--

Bump:Startup()
