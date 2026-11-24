-- Shared game config (units, army, creatures). Tune numbers here.
local Config = {}

Config.StartCoins = 0
Config.StartArmySize = 3
Config.MaxArmySize = 30
-- cost to go from size N to N+1
function Config.ArmyUpgradeCost(size)
	return math.floor(25 * 1.35 ^ (size - Config.StartArmySize))
end

-- Unit types. Hp / Damage / Speed (studs/s) / Range (studs) / AttackRate (s between hits)
Config.Units = {
	Bee    = {Hp = 40,  Damage = 6,  Speed = 22, Range = 14, AttackRate = 0.8, Flying = true,  Color = Color3.fromRGB(250, 205, 40),  Size = Vector3.new(2, 2, 2.4)},
	Knight = {Hp = 160, Damage = 14, Speed = 12, Range = 5,  AttackRate = 1.1, Flying = false, Color = Color3.fromRGB(150, 155, 165), Size = Vector3.new(2.6, 4.2, 2)},
	Boxer  = {Hp = 90,  Damage = 9,  Speed = 18, Range = 4.5, AttackRate = 0.45, Flying = false, Color = Color3.fromRGB(215, 55, 55),  Size = Vector3.new(2.4, 4, 2)},
	Spider = {Hp = 70,  Damage = 5,  Speed = 20, Range = 10, AttackRate = 1.2, Flying = false, Color = Color3.fromRGB(35, 35, 40),   Size = Vector3.new(3, 1.6, 3), Slows = true},
}
-- order new army slots are filled
Config.UnitOrder = {"Knight", "Boxer", "Bee", "Spider"}

-- Creatures (level 1 = easiest)
Config.Creatures = {
	Cat = {Level = 1, Hp = 300, Reward = 20, SlamDamage = 10, SlamRadius = 14, SlamEvery = 5, HideEvery = 12, HideTime = 4},
}

return Config
