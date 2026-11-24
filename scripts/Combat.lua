-- Damage helper shared by army units and creatures. Server only (ModuleScript in ServerScriptService).
local Combat = {}

local contributors = setmetatable({}, {__mode = "k"}) -- creature -> {player = totalDamage}

-- Returns true if the hit landed (creature alive and not hiding).
function Combat.Damage(target, amount, player)
	local hp = target:GetAttribute("Hp")
	if not hp or hp <= 0 or target:GetAttribute("Hidden") then return false end
	target:SetAttribute("Hp", math.max(0, hp - amount))
	if player then
		local c = contributors[target]
		if not c then c = {} contributors[target] = c end
		c[player] = (c[player] or 0) + amount
	end
	return true
end

function Combat.Contributors(target)
	return contributors[target] or {}
end

return Combat
