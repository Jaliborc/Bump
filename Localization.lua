Bump_Locals = {}
local L = Bump_Locals
local Language = GetLocale()

if Language == "ruRU" then
    -- Russian -- ZamestoTV
    L.Reputation = 'Репутация с %s увеличена на %d в %s.'
    L.Currency = 'Вы получили %d %s в %s.'
    L.Experience = 'Вы получили %d опыта в %s.'
    L.Money = 'Вы получили %s в %s.'
else
    -- English --
    L.Reputation = 'Reputation with %s increased by %d in %s.'
    L.Currency = 'You have been awarded %d %s in %s.'
    L.Experience = 'You gained %d experience in %s.'
    L.Money = 'You received %s in %s.'
end