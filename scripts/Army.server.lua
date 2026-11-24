-- Each player has an army that follows them in formation. Server-owned.
-- Player attribute ArmySize = how many units they own (upgradable).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(RS:WaitForChild("Config"))

local armies = {} -- player -> {units = {model, ...}}

local folder = Instance.new("Folder")
folder.Name = "Armies"
folder.Parent = workspace

local function newPart(parent, name, size, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end

-- Simple blocky unit models (placeholders until real models are made)
local function buildUnit(kind, owner)
	local def = Config.Units[kind]
	local m = Instance.new("Model")
	m.Name = kind
	local body = newPart(m, "Body", def.Size, def.Color)
	m.PrimaryPart = body
	local head = newPart(m, "Head", Vector3.new(def.Size.X * 0.8, def.Size.X * 0.8, def.Size.X * 0.8), def.Color:Lerp(Color3.new(1, 1, 1), 0.2))
	head.CFrame = body.CFrame * CFrame.new(0, def.Size.Y / 2 + def.Size.X * 0.4, -def.Size.Z * 0.1)
	local eye = newPart(m, "Eyes", Vector3.new(def.Size.X * 0.6, 0.35, 0.2), Color3.new(0, 0, 0))
	eye.CFrame = head.CFrame * CFrame.new(0, 0.1, -def.Size.X * 0.4)
	if kind == "Bee" then
		for _, s in ipairs({-1, 1}) do
			local w = newPart(m, "Wing", Vector3.new(0.2, 1.6, 2.2), Color3.fromRGB(220, 240, 255))
			w.Transparency = 0.4
			w.CFrame = body.CFrame * CFrame.new(s * 1.2, 1, 0.3) * CFrame.Angles(0, 0, s * math.rad(25))
		end
	elseif kind == "Knight" then
		local helm = newPart(m, "Plume", Vector3.new(0.4, 1.2, 0.8), Color3.fromRGB(200, 40, 40))
		helm.CFrame = head.CFrame * CFrame.new(0, def.Size.X * 0.4 + 0.5, 0)
	elseif kind == "Boxer" then
		for _, s in ipairs({-1, 1}) do
			local g = newPart(m, "Glove", Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(240, 240, 240))
			g.CFrame = body.CFrame * CFrame.new(s * (def.Size.X / 2 + 0.6), 0.3, -0.9)
		end
	elseif kind == "Spider" then
		for _, s in ipairs({-1, 1}) do
			for i = 1, 3 do
				local l = newPart(m, "Leg", Vector3.new(2.2, 0.3, 0.3), def.Color)
				l.CFrame = body.CFrame * CFrame.new(s * 2.2, -0.2, (i - 2) * 0.9) * CFrame.Angles(0, (i - 2) * 0.3 * s, s * math.rad(-20))
			end
		end
	end
	-- weld everything to the body (so PivotTo moves it all)
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("BasePart") and p ~= body then
			local w = Instance.new("WeldConstraint")
			w.Part0 = body
			w.Part1 = p
			w.Parent = p
			p.Anchored = false
		end
	end
	body.Anchored = true
	m:SetAttribute("Kind", kind)
	m:SetAttribute("Hp", def.Hp)
	m:SetAttribute("Owner", owner.UserId)
	return m
end

local function unitKind(i)
	return Config.UnitOrder[(i - 1) % #Config.UnitOrder + 1]
end

local function syncArmy(player)
	local a = armies[player]
	if not a then return end
	local want = math.clamp(player:GetAttribute("ArmySize") or Config.StartArmySize, 0, Config.MaxArmySize)
	while #a.units < want do
		local i = #a.units + 1
		local m = buildUnit(unitKind(i), player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then m:PivotTo(root.CFrame * CFrame.new(0, 0, 6)) end
		m.Parent = folder
		a.units[i] = m
	end
	while #a.units > want do
		a.units[#a.units]:Destroy()
		a.units[#a.units] = nil
	end
end

local function setupPlayer(player)
	armies[player] = {units = {}}
	player:SetAttribute("ArmySize", Config.StartArmySize)
	player:GetAttributeChangedSignal("ArmySize"):Connect(function() syncArmy(player) end)
	syncArmy(player)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in Players:GetPlayers() do setupPlayer(p) end
Players.PlayerRemoving:Connect(function(player)
	local a = armies[player]
	if a then for _, m in a.units do m:Destroy() end end
	armies[player] = nil
end)

-- slot positions behind the player: rows of up to 4, spreading wider each row
local function slotOffset(i)
	local row = math.ceil(i / 4)
	local col = (i - 1) % 4
	local x = (col - 1.5) * 4.5
	local z = 5 + (row - 1) * 5
	return x, z
end

RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	for player, a in armies do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		syncArmy(player)
		for i, m in a.units do
			local def = Config.Units[m:GetAttribute("Kind")]
			local x, z = slotOffset(i)
			local ground = root.Position.Y - 3 + def.Size.Y / 2
			if def.Flying then ground += 3 + math.sin(t * 3 + i) * 0.6 end
			local target = (root.CFrame * CFrame.new(x, 0, z)).Position
			target = Vector3.new(target.X, ground, target.Z)
			local cur = m:GetPivot()
			local dist = (target - cur.Position).Magnitude
			local speed = math.max(def.Speed, dist * 3) -- catch up when far
			local step = math.min(dist, speed * dt)
			local pos = dist > 0.01 and (cur.Position + (target - cur.Position).Unit * step) or cur.Position
			-- face where the player faces
			local look = root.CFrame.LookVector
			m:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(look.X, 0, look.Z)))
		end
	end
end)
