-- Level 1 creature: the Cat. It never attacks. It wanders, then digs underground to hide
-- (can't be hit while hidden), pops up somewhere else, and repeats until killed.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS:WaitForChild("Config"))
local Combat = require(script.Parent:WaitForChild("Combat"))
local CFG = Config.Creatures.Cat

local folder = Instance.new("Folder")
folder.Name = "Creatures"
folder.Parent = workspace

---------------------------------------------------------------- coins
local function setupPlayer(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = Config.StartCoins
	coins.Parent = stats
	stats.Parent = player
end
Players.PlayerAdded:Connect(setupPlayer)
for _, p in Players:GetPlayers() do setupPlayer(p) end

local function addCoins(player, n)
	local s = player:FindFirstChild("leaderstats")
	if s and s:FindFirstChild("Coins") then s.Coins.Value += n end
end

---------------------------------------------------------------- cat model
local arena = workspace:WaitForChild("Map"):WaitForChild("CatArena")
local SURF_Y = arena.Position.Y + arena.Size.Y / 2   -- floor surface
local BASE_Y = SURF_Y + 2.7                           -- body centre when standing
local HIDE_Y = SURF_Y - 6                             -- body centre when underground

local ORANGE = Color3.fromRGB(240, 150, 50)
local DARK = Color3.fromRGB(190, 105, 30)

local function newPart(parent, name, size, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function buildCat()
	local m = Instance.new("Model")
	m.Name = "Cat"
	local body = newPart(m, "Body", Vector3.new(4, 3, 6), ORANGE)
	m.PrimaryPart = body
	local function add(name, size, color, offset, rot)
		local p = newPart(m, name, size, color)
		p.CFrame = body.CFrame * CFrame.new(offset) * (rot or CFrame.new())
		return p
	end
	add("Head", Vector3.new(3.4, 3, 3), ORANGE, Vector3.new(0, 1.3, -3.9))
	add("EarL", Vector3.new(0.9, 1.1, 0.6), DARK, Vector3.new(-1.1, 3.2, -3.9))
	add("EarR", Vector3.new(0.9, 1.1, 0.6), DARK, Vector3.new(1.1, 3.2, -3.9))
	add("EyeL", Vector3.new(0.6, 0.7, 0.2), Color3.new(0, 0, 0), Vector3.new(-0.8, 1.8, -5.45))
	add("EyeR", Vector3.new(0.6, 0.7, 0.2), Color3.new(0, 0, 0), Vector3.new(0.8, 1.8, -5.45))
	add("Nose", Vector3.new(0.7, 0.5, 0.2), Color3.fromRGB(255, 150, 170), Vector3.new(0, 1.1, -5.45))
	add("Tail", Vector3.new(0.8, 0.8, 4), DARK, Vector3.new(0, 2.2, 4.6), CFrame.Angles(math.rad(35), 0, 0))
	for i, z in ipairs({-1.6, 0, 1.6}) do
		add("Stripe" .. i, Vector3.new(4.1, 0.35, 0.7), DARK, Vector3.new(0, 1.55, z))
	end
	for _, x in ipairs({-1.3, 1.3}) do
		for _, z in ipairs({-2.2, 2.2}) do
			add("Leg", Vector3.new(1, 1.2, 1), DARK, Vector3.new(x, -2.1, z))
		end
	end
	-- weld everything to the body so PivotTo moves it all
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

	m:SetAttribute("Hp", CFG.Hp)
	m:SetAttribute("MaxHp", CFG.Hp)
	m:SetAttribute("Hidden", false)

	local gui = Instance.new("BillboardGui")
	gui.Adornee = body
	gui.Size = UDim2.fromOffset(200, 34)
	gui.StudsOffset = Vector3.new(0, 6, 0)
	gui.MaxDistance = 160
	gui.Parent = body
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 18
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.3
	l.Parent = gui
	local function refresh()
		local hp = m:GetAttribute("Hp") or 0
		l.Text = "Cat  Lv1   HP " .. hp .. "/" .. CFG.Hp
		gui.Enabled = not m:GetAttribute("Hidden")
	end
	refresh()
	m:GetAttributeChangedSignal("Hp"):Connect(refresh)
	m:GetAttributeChangedSignal("Hidden"):Connect(refresh)
	return m
end

---------------------------------------------------------------- behaviour
local function alive(m)
	return m.Parent ~= nil and (m:GetAttribute("Hp") or 0) > 0
end

local function place(m, st, y)
	m:PivotTo(CFrame.new(st.pos.X, y, st.pos.Z) * CFrame.Angles(0, st.yaw, 0))
end

local function randomPoint()
	local hx, hz = arena.Size.X / 2 - 6, arena.Size.Z / 2 - 6
	return Vector3.new(arena.Position.X + (math.random() * 2 - 1) * hx, 0, arena.Position.Z + (math.random() * 2 - 1) * hz)
end

local function mound(pos)
	local p = Instance.new("Part")
	p.Name = "DirtMound"
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.8, 7, 7)
	p.Color = Color3.fromRGB(105, 72, 42)
	p.Material = Enum.Material.Ground
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = CFrame.new(pos.X, SURF_Y + 0.4, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
	p.Parent = folder
	return p
end

local function slide(m, st, fromY, toY, secs)
	local t = 0
	while t < secs and alive(m) do
		t += task.wait()
		place(m, st, fromY + (toY - fromY) * math.min(1, t / secs))
	end
end

local function walkTo(m, st, goal, untilT)
	while alive(m) and os.clock() < untilT do
		local dt = task.wait()
		local d = Vector3.new(goal.X - st.pos.X, 0, goal.Z - st.pos.Z)
		if d.Magnitude < 1 then return end
		st.pos += d.Unit * math.min(CFG.WalkSpeed * dt, d.Magnitude)
		st.yaw = math.atan2(-d.X, -d.Z)
		place(m, st, BASE_Y)
	end
end

local function runCat()
	local m = buildCat()
	local st = {pos = Vector3.new(arena.Position.X, 0, arena.Position.Z), yaw = 0}
	place(m, st, BASE_Y)
	m.Parent = folder

	local rewarded = false
	m:GetAttributeChangedSignal("Hp"):Connect(function()
		if (m:GetAttribute("Hp") or 0) <= 0 and not rewarded then
			rewarded = true
			for plr in Combat.Contributors(m) do
				if plr.Parent then addCoins(plr, CFG.Reward) end
			end
		end
	end)

	while alive(m) do
		-- above ground: wander
		local untilT = os.clock() + CFG.SurfaceTime
		while alive(m) and os.clock() < untilT do
			walkTo(m, st, randomPoint(), untilT)
		end
		if not alive(m) then break end

		-- dig down and hide
		m:SetAttribute("Hidden", true)
		local m1 = mound(st.pos)
		slide(m, st, BASE_Y, HIDE_Y, 0.9)
		task.wait(CFG.HideTime * 0.5)
		m1:Destroy()

		-- travel underground, then pop up somewhere else
		st.pos = randomPoint()
		place(m, st, HIDE_Y)
		local m2 = mound(st.pos)
		task.wait(CFG.HideTime * 0.5)
		slide(m, st, HIDE_Y, BASE_Y, 0.9)
		m:SetAttribute("Hidden", false)
		m2:Destroy()
	end

	-- defeated
	m:SetAttribute("Hidden", true)
	task.wait(0.2)
	m:Destroy()
end

while true do
	runCat()
	task.wait(8)
end
