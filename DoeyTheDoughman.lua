-- ═══════════════════════════════════════════════════════════════════
-- DOEY THE DOUGHMAN — NIGHTMARE EVENT v1.0
-- Séquence Poppy Playtime Chapter 4 recréée en LocalScript
-- Doey gentil + Smiling Critters → Nightmare Doey si on tue un critter
-- Bouteilles d'Azote + Grue avec Scie = 2 coups pour le vaincre
-- Style basé sur le système "The Doctor v4.0"
-- ═══════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ═══════════════════════════════════════
-- NETTOYAGE COMPLET
-- ═══════════════════════════════════════
local function FullClean()
	for _, v in pairs(player.PlayerGui:GetChildren()) do
		if v.Name == "DoeyEventGui" then v:Destroy() end
	end
	for _, v in pairs(Lighting:GetChildren()) do
		if v.Name:sub(1,3) == "DD_" then v:Destroy() end
	end
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:sub(1,3) == "DD_" then v:Destroy() end
	end
end
FullClean()

-- ═══════════════════════════════════════
-- CONFIGURATION & VARIABLES
-- ═══════════════════════════════════════
local eventActive = false
local phase = "NONE"            -- NONE, FRIENDLY, TRANSFORM, NIGHTMARE, DEAD
local doey = nil                -- {model, rig, data}
local nightmare = nil           -- {model, rig, data}
local critters = {}
local nitroBottles = {}
local craneModel = nil
local sawBlade = nil
local eventConnections = {}
local jumpscareActive = false
local playerHasWeapon = false
local weaponModel = nil
local canSwing = true
local guiOpen = false
local sliceCount = 0
local doeyHasNitro = false
local doeyFrozen = false

local FRIENDLY_SPEED_STEP = 1.2      -- pas de Doey gentil
local FRIENDLY_STEP_INTERVAL = 0.3
local WAVE_DIST = 30                 -- distance pour faire coucou
local NIGHTMARE_STEP = 3.4           -- pas du Nightmare
local NIGHTMARE_STEP_FROZEN = 0
local NIGHTMARE_STEP_NITRO = 2.0     -- ralenti quand il a gobé l'azote
local TP_INTERVAL = 0.22
local ATTACK_RANGE = 6
local GOBBLE_RANGE = 10              -- distance pour gober une bouteille
local SAW_RANGE = 9                  -- distance de la scie pour trancher
local FREEZE_TIME = 7                -- durée du gel après un coup de scie
local SLICES_TO_KILL = 2
local WEAPON_RANGE = 150
local SWING_COOLDOWN = 0.8
local MAX_BOTTLES = 2

local COLORS = {
	bg = Color3.fromRGB(10, 8, 14),
	card = Color3.fromRGB(18, 15, 24),
	accent = Color3.fromRGB(255, 120, 40),
	doughBlue = Color3.fromRGB(45, 190, 200),
	doughYellow = Color3.fromRGB(235, 220, 60),
	doughOrange = Color3.fromRGB(240, 150, 40),
	doughRed = Color3.fromRGB(190, 45, 55),
	hatNavy = Color3.fromRGB(40, 50, 90),
	nmOrange = Color3.fromRGB(235, 90, 25),
	nmTeal = Color3.fromRGB(20, 90, 90),
	nmDark = Color3.fromRGB(15, 45, 45),
	nmEye = Color3.fromRGB(255, 140, 30),
	iceBlue = Color3.fromRGB(150, 230, 255),
	nitroCyan = Color3.fromRGB(0, 230, 255),
	green = Color3.fromRGB(0, 200, 80),
	neonRed = Color3.fromRGB(255, 0, 40),
	text = Color3.fromRGB(235, 230, 240),
	dim = Color3.fromRGB(110, 105, 125),
	metal = Color3.fromRGB(120, 110, 40),
	metalDark = Color3.fromRGB(45, 45, 50),
}

local CRITTER_COLORS = {
	{name = "CatNap",   body = Color3.fromRGB(120, 80, 200), ear = "cat"},
	{name = "DogDay",   body = Color3.fromRGB(235, 130, 40), ear = "dog"},
	{name = "Hoppy",    body = Color3.fromRGB(90, 210, 70),  ear = "rabbit"},
	{name = "Bobby",    body = Color3.fromRGB(220, 60, 90),  ear = "bear"},
}

local SND = {
	static = "rbxassetid://140217414944350",
	alert = "rbxassetid://138020803748019",
	chase = "rbxassetid://139063675026894",
	pickup = "rbxassetid://137641526158265",
	explode = "rbxassetid://138951531981888",
	electric = "rbxassetid://140585731847176",
	jumpscare = "rbxassetid://135095313743369",
	heartbeat = "rbxassetid://139481207162657",
	footstep = "rbxassetid://139303972367422",
	victory = "rbxassetid://132919665409307",
	hit = "rbxassetid://140721035016341",
	weaponSwing = "rbxassetid://93806155622808",
	machineHum = "rbxassetid://88423610384477",
	wakeUp = "rbxassetid://137614563859074",
	ambient = "rbxassetid://131190991150526",
	breathing = "rbxassetid://139358149909471",
	growl = "rbxassetid://138016581135405",
	powerDown = "rbxassetid://133973844653286",
}

-- ═══════════════════════════════════════
-- UTILITAIRES
-- ═══════════════════════════════════════
local function snd(id, vol, loop)
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol or 1; s.Looped = loop or false
	s.Name = "DD_Sound"; s.Parent = SoundService
	return s
end

local function playSnd(id, vol, loop)
	local s = snd(id, vol, loop)
	s:Play()
	if not loop then Debris:AddItem(s, 10) end
	return s
end

local function cleanSounds()
	for _, s in pairs(SoundService:GetChildren()) do
		if s.Name == "DD_Sound" then pcall(function() s:Stop(); s:Destroy() end) end
	end
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a; w.Part1 = b; w.Parent = a; return w
end

local function createPart(par, name, sz, col, mat, tr)
	local p = Instance.new("Part")
	p.Name = "DD_"..name; p.Size = sz; p.Color = col
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = tr or 0
	p.Anchored = false; p.CanCollide = false; p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = par; return p
end

local function createAnchoredPart(par, name, sz, col, mat, tr)
	local p = createPart(par, name, sz, col, mat, tr)
	p.Anchored = true; p.CanCollide = true; return p
end

local function getRayParams()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {character}
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:sub(1,3) == "DD_" then table.insert(ex, v) end
	end
	rp.FilterDescendantsInstances = ex
	return rp
end

local function findGround(x, z)
	local r = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -600, 0), getRayParams())
	if r then return r.Position end
	return Vector3.new(x, rootPart.Position.Y - 3, z)
end

local function findSafeGround(maxAttempts, minDist, maxDist)
	maxAttempts = maxAttempts or 25
	for _ = 1, maxAttempts do
		local ang = math.rad(math.random(0, 360))
		local dist = math.random(minDist or 40, maxDist or 180)
		local x = rootPart.Position.X + math.cos(ang) * dist
		local z = rootPart.Position.Z + math.sin(ang) * dist
		local r = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -600, 0), getRayParams())
		if r and r.Normal.Y > 0.7 then
			local up = workspace:Raycast(r.Position + Vector3.new(0, 0.5, 0), Vector3.new(0, 5, 0), getRayParams())
			if not up then return r.Position end
		end
	end
	return findGround(rootPart.Position.X + 40, rootPart.Position.Z + 40)
end

-- Bulle de dialogue au-dessus d'un modèle
local function speak(adorneePart, text, color, dur)
	if not adorneePart or not adorneePart.Parent then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "DD_Speech"
	bb.Adornee = adorneePart
	bb.Size = UDim2.new(0, 260, 0, 60)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 200
	bb.Parent = adorneePart

	local f = Instance.new("Frame", bb)
	f.Size = UDim2.new(1, 0, 1, 0)
	f.BackgroundColor3 = Color3.fromRGB(20, 18, 26)
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	local st = Instance.new("UIStroke", f)
	st.Color = color or COLORS.doughBlue; st.Thickness = 2

	local t = Instance.new("TextLabel", f)
	t.Size = UDim2.new(1, -14, 1, -8)
	t.Position = UDim2.new(0, 7, 0, 4)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or COLORS.doughBlue
	t.TextScaled = true; t.TextWrapped = true
	t.Font = Enum.Font.GothamBold
	t.TextStrokeTransparency = 0.5

	Debris:AddItem(bb, dur or 3)
end

-- Forward declarations
local triggerRage
local doJumpscare
local spawnNitroBottle
local sliceHit
local nightmareDeath
local stopEvent
local startEvent

-- ═══════════════════════════════════════════════════════════════════
-- ATMOSPHÈRE (Usine Playtime Co. sombre)
-- ═══════════════════════════════════════════════════════════════════

local originalLighting = {}
local atmoActive = false

local function activateAtmosphere(nightmareMode)
	if not atmoActive then
		originalLighting.FogColor = Lighting.FogColor
		originalLighting.FogEnd = Lighting.FogEnd
		originalLighting.FogStart = Lighting.FogStart
		originalLighting.ClockTime = Lighting.ClockTime
		originalLighting.Ambient = Lighting.Ambient
		originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
		originalLighting.Brightness = Lighting.Brightness
		atmoActive = true
	end

	for _, n in pairs({"DD_Atmosphere","DD_CC","DD_Bloom"}) do
		local c = Lighting:FindFirstChild(n)
		if c then c:Destroy() end
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "DD_Atmosphere"
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "DD_CC"
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "DD_Bloom"
	bloom.Intensity = 0.35; bloom.Size = 24; bloom.Threshold = 0.85

	if nightmareMode then
		-- Ambiance cauchemar : rouge/orange sombre
		atmo.Density = 0.45; atmo.Offset = 0.2
		atmo.Color = Color3.fromRGB(60, 25, 15)
		atmo.Decay = Color3.fromRGB(40, 10, 5)
		atmo.Haze = 10
		cc.Brightness = -0.08; cc.Contrast = 0.25; cc.Saturation = -0.15
		cc.TintColor = Color3.fromRGB(255, 180, 150)
		Lighting.ClockTime = 0
		Lighting.FogColor = Color3.fromRGB(35, 12, 8)
		Lighting.FogEnd = 220; Lighting.FogStart = 10
		Lighting.Ambient = Color3.fromRGB(50, 20, 15)
		Lighting.OutdoorAmbient = Color3.fromRGB(40, 15, 10)
		Lighting.Brightness = 0.6
	else
		-- Ambiance amicale : chaude, légèrement brumeuse
		atmo.Density = 0.25; atmo.Offset = 0.15
		atmo.Color = Color3.fromRGB(70, 60, 50)
		atmo.Decay = Color3.fromRGB(45, 40, 35)
		atmo.Haze = 4
		cc.Brightness = 0; cc.Contrast = 0.08; cc.Saturation = 0.05
		cc.TintColor = Color3.fromRGB(255, 240, 220)
		Lighting.ClockTime = 16
		Lighting.FogColor = Color3.fromRGB(60, 55, 50)
		Lighting.FogEnd = 500; Lighting.FogStart = 40
		Lighting.Brightness = 1.4
	end

	atmo.Parent = Lighting; cc.Parent = Lighting; bloom.Parent = Lighting
end

local function deactivateAtmosphere()
	if not atmoActive then return end
	Lighting.FogColor = originalLighting.FogColor or Color3.new(0.75,0.75,0.75)
	Lighting.FogEnd = originalLighting.FogEnd or 100000
	Lighting.FogStart = originalLighting.FogStart or 0
	Lighting.ClockTime = originalLighting.ClockTime or 14
	Lighting.Ambient = originalLighting.Ambient or Color3.fromRGB(128,128,128)
	Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.fromRGB(128,128,128)
	Lighting.Brightness = originalLighting.Brightness or 2
	for _, n in pairs({"DD_Atmosphere","DD_CC","DD_Bloom"}) do
		local c = Lighting:FindFirstChild(n)
		if c then c:Destroy() end
	end
	atmoActive = false
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSTRUCTION DU RIG DOEY THE DOUGHMAN (pâte à modeler)
-- Tête turquoise ronde + chapeau melon + long cou + gros corps patché
-- ═══════════════════════════════════════════════════════════════════

-- Ajoute des taches de pâte colorées sur une part (style plasticine)
local function addDoughPatches(model, basePart, count)
	local patchColors = {COLORS.doughYellow, COLORS.doughOrange, COLORS.doughRed}
	for i = 1, count do
		local col = patchColors[math.random(1, #patchColors)]
		local sz = basePart.Size
		local patch = createPart(model, "Patch"..basePart.Name..i,
			Vector3.new(math.random(8, 16)/10, math.random(8, 16)/10, 0.25),
			col, Enum.Material.Slate)
		patch.Shape = Enum.PartType.Ball
		patch.Size = Vector3.new(math.random(10, 20)/10, math.random(8, 14)/10, math.random(4, 7)/10)
		-- Position aléatoire sur la surface
		local ox = (math.random() - 0.5) * sz.X * 0.8
		local oy = (math.random() - 0.5) * sz.Y * 0.8
		local face = math.random() > 0.5 and 1 or -1
		patch.CFrame = basePart.CFrame * CFrame.new(ox, oy, face * sz.Z * 0.45)
			* CFrame.Angles(math.random() * 0.5, math.random() * 0.5, math.random() * 3)
		weld(basePart, patch)
	end
end

local function buildDoey()
	local model = Instance.new("Model")
	model.Name = "DD_Doey"
	local rig = {}

	-- ROOT
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1; root.Anchored = true
	root.CanCollide = false; root.Parent = model
	model.PrimaryPart = root

	-- ══════════════════════════════
	-- CORPS (gros, en forme de poire — pâte à modeler)
	-- ══════════════════════════════
	local belly = createPart(model, "Belly", Vector3.new(5.2, 4.6, 4.2), COLORS.doughBlue, Enum.Material.Slate)
	belly.Shape = Enum.PartType.Ball
	belly.CFrame = root.CFrame * CFrame.new(0, 0.5, 0)

	local rootMotor = Instance.new("Motor6D")
	rootMotor.Part0 = root; rootMotor.Part1 = belly
	rootMotor.C0 = CFrame.new(0, 0.5, 0)
	rootMotor.Parent = root
	rig.Root = rootMotor

	-- Bas du corps rouge (comme sur l'image : bas rouge/bordeaux)
	local lowerBelly = createPart(model, "LowerBelly", Vector3.new(4.8, 2.6, 3.9), COLORS.doughRed, Enum.Material.Slate)
	lowerBelly.Shape = Enum.PartType.Ball
	lowerBelly.CFrame = belly.CFrame * CFrame.new(0, -1.4, 0)
	weld(belly, lowerBelly)

	-- Poitrine (transition vers le cou)
	local chest = createPart(model, "Chest", Vector3.new(3.4, 2.8, 2.9), COLORS.doughBlue, Enum.Material.Slate)
	chest.Shape = Enum.PartType.Ball
	chest.CFrame = belly.CFrame * CFrame.new(0, 2.2, 0)
	weld(belly, chest)

	addDoughPatches(model, belly, 5)
	addDoughPatches(model, chest, 3)
	addDoughPatches(model, lowerBelly, 2)

	-- ══════════════════════════════
	-- COU (long et fin comme l'image)
	-- ══════════════════════════════
	local neck = createPart(model, "Neck", Vector3.new(1.1, 3.2, 1.1), COLORS.doughBlue, Enum.Material.Slate)
	neck.CFrame = chest.CFrame * CFrame.new(0, 2.6, 0)

	local neckMotor = Instance.new("Motor6D")
	neckMotor.Part0 = chest; neckMotor.Part1 = neck
	neckMotor.C0 = chest.CFrame:ToObjectSpace(neck.CFrame)
	neckMotor.Parent = chest
	rig.Neck = neckMotor

	-- Tache jaune sur le cou
	local neckPatch = createPart(model, "NeckPatch", Vector3.new(1.0, 1.2, 0.5), COLORS.doughYellow, Enum.Material.Slate)
	neckPatch.Shape = Enum.PartType.Ball
	neckPatch.CFrame = neck.CFrame * CFrame.new(0.3, -0.6, -0.4)
	weld(neck, neckPatch)

	-- ══════════════════════════════
	-- TÊTE (boule turquoise + grand sourire noir + yeux)
	-- ══════════════════════════════
	local head = createPart(model, "Head", Vector3.new(2.8, 2.8, 2.8), COLORS.doughBlue, Enum.Material.Slate)
	head.Shape = Enum.PartType.Ball
	head.CFrame = neck.CFrame * CFrame.new(0, 2.6, 0)

	local headMotor = Instance.new("Motor6D")
	headMotor.Part0 = neck; headMotor.Part1 = head
	headMotor.C0 = neck.CFrame:ToObjectSpace(head.CFrame)
	headMotor.Parent = neck
	rig.HeadJoint = headMotor

	-- GRANDE BOUCHE souriante (noire, ovale)
	local mouth = createPart(model, "Mouth", Vector3.new(1.7, 1.1, 0.6), Color3.fromRGB(8, 8, 10), Enum.Material.SmoothPlastic)
	mouth.Shape = Enum.PartType.Ball
	mouth.CFrame = head.CFrame * CFrame.new(0, -0.55, -1.15)
	weld(head, mouth)
	rig.Mouth = mouth

	-- Lèvre supérieure (arc de sourire)
	local lip = createPart(model, "Lip", Vector3.new(1.9, 0.35, 0.5), COLORS.doughBlue, Enum.Material.Slate)
	lip.Shape = Enum.PartType.Ball
	lip.CFrame = mouth.CFrame * CFrame.new(0, 0.55, 0.05)
	weld(mouth, lip)

	-- YEUX (petites fentes sombres avec point rouge, comme l'image)
	for side = -1, 1, 2 do
		local eyeSocket = createPart(model, "EyeSocket"..side, Vector3.new(0.55, 0.3, 0.3), Color3.fromRGB(10, 25, 28), Enum.Material.SmoothPlastic)
		eyeSocket.Shape = Enum.PartType.Ball
		eyeSocket.CFrame = head.CFrame * CFrame.new(side * 0.55, 0.45, -1.25)
		weld(head, eyeSocket)

		local eyeDot = createPart(model, "EyeDot"..side, Vector3.new(0.15, 0.12, 0.1), Color3.fromRGB(220, 60, 50), Enum.Material.Neon)
		eyeDot.Shape = Enum.PartType.Ball
		eyeDot.CFrame = eyeSocket.CFrame * CFrame.new(0, 0, -0.12)
		weld(eyeSocket, eyeDot)
		rig["EyeDot"..(side == -1 and "L" or "R")] = eyeDot
	end

	-- ══════════════════════════════
	-- CHAPEAU MELON bleu marine (signature de Doey)
	-- ══════════════════════════════
	local hatBrim = createPart(model, "HatBrim", Vector3.new(1.3, 0.18, 1.3), COLORS.hatNavy, Enum.Material.Fabric)
	hatBrim.Shape = Enum.PartType.Cylinder
	hatBrim.Size = Vector3.new(0.18, 1.35, 1.35)
	hatBrim.CFrame = head.CFrame * CFrame.new(0.15, 1.35, 0) * CFrame.Angles(0, 0, math.rad(90 - 8))
	weld(head, hatBrim)

	local hatTop = createPart(model, "HatTop", Vector3.new(0.95, 0.75, 0.95), COLORS.hatNavy, Enum.Material.Fabric)
	hatTop.Shape = Enum.PartType.Ball
	hatTop.CFrame = head.CFrame * CFrame.new(0.15, 1.65, 0) * CFrame.Angles(0, 0, math.rad(-8))
	weld(head, hatTop)

	-- ══════════════════════════════
	-- BRAS (gros bras de pâte — gauche jaune, droit orange comme l'image)
	-- ══════════════════════════════
	for side = -1, 1, 2 do
		local prefix = side == -1 and "L" or "R"
		local armCol = side == -1 and COLORS.doughYellow or COLORS.doughOrange

		local shoulder = createPart(model, prefix.."Shoulder", Vector3.new(1.6, 1.6, 1.6), COLORS.doughBlue, Enum.Material.Slate)
		shoulder.Shape = Enum.PartType.Ball
		shoulder.CFrame = chest.CFrame * CFrame.new(side * 2.0, 0.5, 0)

		local upperArm = createPart(model, prefix.."UpperArm", Vector3.new(1.3, 2.6, 1.3), armCol, Enum.Material.Slate)
		upperArm.CFrame = shoulder.CFrame * CFrame.new(side * 0.4, -1.4, 0) * CFrame.Angles(0, 0, side * math.rad(-12))

		local armMotor = Instance.new("Motor6D")
		armMotor.Part0 = chest; armMotor.Part1 = upperArm
		armMotor.C0 = chest.CFrame:ToObjectSpace(upperArm.CFrame)
		armMotor.Parent = chest
		rig[prefix.."ArmMotor"] = armMotor
		weld(upperArm, shoulder) -- épaule suit le bras visuellement

		local lowerArm = createPart(model, prefix.."LowerArm", Vector3.new(1.15, 2.4, 1.15), armCol, Enum.Material.Slate)
		lowerArm.CFrame = upperArm.CFrame * CFrame.new(0, -2.3, 0)
		weld(upperArm, lowerArm)

		-- Grosse main de pâte (mitaine)
		local hand = createPart(model, prefix.."Hand", Vector3.new(1.5, 1.3, 0.9), armCol, Enum.Material.Slate)
		hand.Shape = Enum.PartType.Ball
		hand.CFrame = lowerArm.CFrame * CFrame.new(0, -1.5, 0)
		weld(lowerArm, hand)

		-- Pouce
		local thumb = createPart(model, prefix.."Thumb", Vector3.new(0.5, 0.8, 0.5), armCol, Enum.Material.Slate)
		thumb.Shape = Enum.PartType.Ball
		thumb.CFrame = hand.CFrame * CFrame.new(side * -0.7, 0.2, -0.2) * CFrame.Angles(0, 0, side * math.rad(30))
		weld(hand, thumb)
	end

	-- ══════════════════════════════
	-- PETITS PIEDS rouges (comme l'image)
	-- ══════════════════════════════
	for side = -1, 1, 2 do
		local prefix = side == -1 and "L" or "R"
		local foot = createPart(model, prefix.."Foot", Vector3.new(1.4, 0.9, 1.7), COLORS.doughRed, Enum.Material.Slate)
		foot.Shape = Enum.PartType.Ball
		foot.CFrame = lowerBelly.CFrame * CFrame.new(side * 1.1, -1.3, -0.2)

		local footMotor = Instance.new("Motor6D")
		footMotor.Part0 = belly; footMotor.Part1 = foot
		footMotor.C0 = belly.CFrame:ToObjectSpace(foot.CFrame)
		footMotor.Parent = belly
		rig[prefix.."FootMotor"] = footMotor
	end

	local data = {
		state = "WALK",       -- WALK, WAVE, INTERACT, ANGRY
		animTimer = 0,
		lastStepTime = tick(),
		lastInteract = 0,
		waveCooldown = 0,
		head = head,
		belly = belly,
		mouth = mouth,
	}

	return model, rig, data
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSTRUCTION DES SMILING CRITTERS (petites peluches qui marchent)
-- ═══════════════════════════════════════════════════════════════════

local function buildCritter(info)
	local model = Instance.new("Model")
	model.Name = "DD_Critter_"..info.name
	local rig = {}

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1; root.Anchored = true
	root.CanCollide = false; root.Parent = model
	model.PrimaryPart = root

	-- Corps peluche
	local body = createPart(model, "CritBody", Vector3.new(1.3, 1.5, 1.1), info.body, Enum.Material.Fabric)
	body.Shape = Enum.PartType.Ball
	local bodyMotor = Instance.new("Motor6D")
	bodyMotor.Part0 = root; bodyMotor.Part1 = body
	bodyMotor.C0 = CFrame.new(0, 0.2, 0)
	bodyMotor.Parent = root
	rig.Root = bodyMotor

	-- Tête ronde
	local head = createPart(model, "CritHead", Vector3.new(1.4, 1.4, 1.3), info.body, Enum.Material.Fabric)
	head.Shape = Enum.PartType.Ball
	head.CFrame = body.CFrame * CFrame.new(0, 1.15, 0)
	local headMotor = Instance.new("Motor6D")
	headMotor.Part0 = body; headMotor.Part1 = head
	headMotor.C0 = body.CFrame:ToObjectSpace(head.CFrame)
	headMotor.Parent = body
	rig.Head = headMotor

	-- GRAND SOURIRE noir (signature Smiling Critters)
	local smile = createPart(model, "CritSmile", Vector3.new(1.0, 0.85, 0.4), Color3.fromRGB(5, 5, 8), Enum.Material.SmoothPlastic)
	smile.Shape = Enum.PartType.Ball
	smile.CFrame = head.CFrame * CFrame.new(0, -0.28, -0.55)
	weld(head, smile)

	-- Gros yeux noirs brillants
	for side = -1, 1, 2 do
		local eye = createPart(model, "CritEye"..side, Vector3.new(0.35, 0.42, 0.2), Color3.fromRGB(10, 10, 12), Enum.Material.Glass)
		eye.Shape = Enum.PartType.Ball
		eye.CFrame = head.CFrame * CFrame.new(side * 0.33, 0.28, -0.58)
		weld(head, eye)
		local shine = createPart(model, "CritShine"..side, Vector3.new(0.1, 0.1, 0.06), Color3.new(1,1,1), Enum.Material.Neon)
		shine.Shape = Enum.PartType.Ball
		shine.CFrame = eye.CFrame * CFrame.new(0.07, 0.1, -0.08)
		weld(eye, shine)
	end

	-- Oreilles selon le type
	if info.ear == "cat" then
		for side = -1, 1, 2 do
			local ear = createPart(model, "CritEar"..side, Vector3.new(0.4, 0.55, 0.2), info.body, Enum.Material.Fabric)
			ear.CFrame = head.CFrame * CFrame.new(side * 0.5, 0.75, 0) * CFrame.Angles(0, 0, side * math.rad(-20))
			weld(head, ear)
		end
	elseif info.ear == "dog" then
		for side = -1, 1, 2 do
			local ear = createPart(model, "CritEar"..side, Vector3.new(0.35, 0.8, 0.25), info.body, Enum.Material.Fabric)
			ear.Shape = Enum.PartType.Ball
			ear.CFrame = head.CFrame * CFrame.new(side * 0.62, 0.35, 0) * CFrame.Angles(0, 0, side * math.rad(-50))
			weld(head, ear)
		end
	elseif info.ear == "rabbit" then
		for side = -1, 1, 2 do
			local ear = createPart(model, "CritEar"..side, Vector3.new(0.3, 1.3, 0.2), info.body, Enum.Material.Fabric)
			ear.Shape = Enum.PartType.Ball
			ear.CFrame = head.CFrame * CFrame.new(side * 0.3, 1.1, 0) * CFrame.Angles(0, 0, side * math.rad(-8))
			weld(head, ear)
		end
	else -- bear
		for side = -1, 1, 2 do
			local ear = createPart(model, "CritEar"..side, Vector3.new(0.45, 0.45, 0.25), info.body, Enum.Material.Fabric)
			ear.Shape = Enum.PartType.Ball
			ear.CFrame = head.CFrame * CFrame.new(side * 0.5, 0.68, 0)
			weld(head, ear)
		end
	end

	-- Petits bras & jambes
	for side = -1, 1, 2 do
		local arm = createPart(model, "CritArm"..side, Vector3.new(0.35, 0.8, 0.35), info.body, Enum.Material.Fabric)
		arm.Shape = Enum.PartType.Ball
		arm.CFrame = body.CFrame * CFrame.new(side * 0.72, 0.15, 0)
		local am = Instance.new("Motor6D")
		am.Part0 = body; am.Part1 = arm
		am.C0 = body.CFrame:ToObjectSpace(arm.CFrame)
		am.Parent = body
		rig[(side == -1 and "L" or "R").."Arm"] = am

		local leg = createPart(model, "CritLeg"..side, Vector3.new(0.4, 0.7, 0.4), info.body, Enum.Material.Fabric)
		leg.Shape = Enum.PartType.Ball
		leg.CFrame = body.CFrame * CFrame.new(side * 0.35, -0.85, 0)
		local lm = Instance.new("Motor6D")
		lm.Part0 = body; lm.Part1 = leg
		lm.C0 = body.CFrame:ToObjectSpace(leg.CFrame)
		lm.Parent = body
		rig[(side == -1 and "L" or "R").."Leg"] = lm
	end

	-- Pendentif coeur
	local pendant = createPart(model, "CritPendant", Vector3.new(0.25, 0.25, 0.1), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)
	pendant.Shape = Enum.PartType.Ball
	pendant.CFrame = body.CFrame * CFrame.new(0, 0.35, -0.55)
	weld(body, pendant)

	local data = {
		name = info.name,
		alive = true,
		animTimer = math.random() * 10,
		offset = CFrame.new(math.random(-60, 60)/10, 0, math.random(30, 60)/10),
		head = head,
		body = body,
	}

	return model, rig, data
end

-- ═══════════════════════════════════════════════════════════════════
-- ANIMATIONS DOEY (gentil) — dandine, coucou, interactions
-- ═══════════════════════════════════════════════════════════════════

local function animDoeyFriendly(rig, t, state)
	if state == "WALK" then
		local cycle = t * 3.2
		-- Dandinement lourd de pâte
		local sway = math.sin(cycle) * 0.09
		local bob = math.abs(math.sin(cycle)) * 0.35
		if rig.Root then
			rig.Root.Transform = CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, sway)
		end
		-- Bras qui balancent mollement
		if rig.LArmMotor then rig.LArmMotor.Transform = CFrame.Angles(math.sin(cycle) * 0.35, 0, math.rad(-4)) end
		if rig.RArmMotor then rig.RArmMotor.Transform = CFrame.Angles(math.sin(cycle + math.pi) * 0.35, 0, math.rad(4)) end
		-- Petits pieds
		if rig.LFootMotor then rig.LFootMotor.Transform = CFrame.new(0, math.max(0, math.sin(cycle)) * 0.3, 0) end
		if rig.RFootMotor then rig.RFootMotor.Transform = CFrame.new(0, math.max(0, math.sin(cycle + math.pi)) * 0.3, 0) end
		-- Cou et tête qui suivent le rythme
		if rig.Neck then rig.Neck.Transform = CFrame.Angles(0, 0, -sway * 0.7) end
		if rig.HeadJoint then rig.HeadJoint.Transform = CFrame.Angles(math.sin(cycle * 0.5) * 0.04, 0, -sway * 0.5) end

	elseif state == "WAVE" then
		-- COUCOU ! Bras droit levé qui salue
		local waveT = t * 6
		if rig.RArmMotor then
			rig.RArmMotor.Transform = CFrame.Angles(math.rad(-160), 0, math.sin(waveT) * 0.45)
		end
		if rig.LArmMotor then
			rig.LArmMotor.Transform = CFrame.Angles(math.rad(8), 0, math.rad(-6))
		end
		-- Tête penchée gentiment
		if rig.HeadJoint then
			rig.HeadJoint.Transform = CFrame.Angles(math.rad(-5), 0, math.sin(t * 2) * 0.1 + math.rad(10))
		end
		if rig.Root then
			rig.Root.Transform = CFrame.new(0, math.sin(t * 2) * 0.08, 0)
		end
		if rig.Neck then rig.Neck.Transform = CFrame.Angles(0, 0, math.rad(5)) end

	elseif state == "DANCE" then
		-- Petite danse rigolote
		local d = t * 5
		if rig.Root then
			rig.Root.Transform = CFrame.new(0, math.abs(math.sin(d)) * 0.4, 0) * CFrame.Angles(0, math.sin(d * 0.5) * 0.3, math.sin(d) * 0.12)
		end
		if rig.LArmMotor then rig.LArmMotor.Transform = CFrame.Angles(math.rad(-90) + math.sin(d) * 0.6, 0, math.rad(-30)) end
		if rig.RArmMotor then rig.RArmMotor.Transform = CFrame.Angles(math.rad(-90) + math.sin(d + math.pi) * 0.6, 0, math.rad(30)) end
		if rig.HeadJoint then rig.HeadJoint.Transform = CFrame.Angles(0, 0, math.sin(d) * 0.15) end

	elseif state == "PAT" then
		-- Se penche pour caresser un critter
		if rig.Neck then rig.Neck.Transform = CFrame.Angles(math.rad(28), 0, 0) end
		if rig.HeadJoint then rig.HeadJoint.Transform = CFrame.Angles(math.rad(20), 0, 0) end
		if rig.RArmMotor then rig.RArmMotor.Transform = CFrame.Angles(math.rad(45), 0, math.rad(-15) + math.sin(t * 4) * 0.1) end
		if rig.Root then rig.Root.Transform = CFrame.Angles(math.rad(10), 0, 0) end

	elseif state == "IDLE" then
		-- Respiration douce de pâte
		local breathe = math.sin(t * 1.2) * 0.06
		if rig.Root then rig.Root.Transform = CFrame.new(0, breathe, 0) end
		if rig.LArmMotor then rig.LArmMotor.Transform = CFrame.Angles(breathe * 0.5, 0, math.rad(-4)) end
		if rig.RArmMotor then rig.RArmMotor.Transform = CFrame.Angles(breathe * 0.5, 0, math.rad(4)) end
		if rig.HeadJoint then rig.HeadJoint.Transform = CFrame.Angles(math.sin(t * 0.6) * 0.04, math.sin(t * 0.4) * 0.08, 0) end

	elseif state == "ANGRY" then
		-- Tremblement de colère montante
		local shake = math.sin(t * 30) * 0.04
		if rig.Root then rig.Root.Transform = CFrame.new(shake, 0, 0) * CFrame.Angles(0, shake, 0) end
		if rig.HeadJoint then rig.HeadJoint.Transform = CFrame.Angles(math.rad(15) + shake * 2, shake * 3, 0) end
		if rig.LArmMotor then rig.LArmMotor.Transform = CFrame.Angles(math.rad(20), 0, math.rad(-15) + shake) end
		if rig.RArmMotor then rig.RArmMotor.Transform = CFrame.Angles(math.rad(20), 0, math.rad(15) - shake) end
	end
end

local function animCritter(rig, t, isMoving)
	local cycle = t * 7
	if isMoving then
		local hop = math.abs(math.sin(cycle)) * 0.25
		if rig.Root then rig.Root.Transform = CFrame.new(0, hop, 0) * CFrame.Angles(0, 0, math.sin(cycle) * 0.08) end
		if rig.LArm then rig.LArm.Transform = CFrame.Angles(math.sin(cycle) * 0.7, 0, 0) end
		if rig.RArm then rig.RArm.Transform = CFrame.Angles(math.sin(cycle + math.pi) * 0.7, 0, 0) end
		if rig.LLeg then rig.LLeg.Transform = CFrame.Angles(math.sin(cycle + math.pi) * 0.6, 0, 0) end
		if rig.RLeg then rig.RLeg.Transform = CFrame.Angles(math.sin(cycle) * 0.6, 0, 0) end
		if rig.Head then rig.Head.Transform = CFrame.Angles(0, 0, math.sin(cycle * 0.5) * 0.06) end
	else
		local breathe = math.sin(t * 2) * 0.04
		if rig.Root then rig.Root.Transform = CFrame.new(0, breathe, 0) end
		if rig.Head then rig.Head.Transform = CFrame.Angles(math.sin(t * 0.8) * 0.05, math.sin(t * 0.5) * 0.15, 0) end
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSTRUCTION DE NIGHTMARE DOEY (version monstre — orange/teal)
-- Inspiré du boss : corps difforme, 6 bras, bouche béante pleine d'yeux
-- ═══════════════════════════════════════════════════════════════════

local function buildNightmareDoey()
	local model = Instance.new("Model")
	model.Name = "DD_Nightmare"
	local rig = {}

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1; root.Anchored = true
	root.CanCollide = false; root.Parent = model
	model.PrimaryPart = root

	-- ══════════════════════════════
	-- CORPS MASSIF DIFFORME (orange avec plaques teal)
	-- ══════════════════════════════
	local body = createPart(model, "NmBody", Vector3.new(7.5, 6.5, 6.0), COLORS.nmOrange, Enum.Material.Slate)
	body.Shape = Enum.PartType.Ball
	local rootMotor = Instance.new("Motor6D")
	rootMotor.Part0 = root; rootMotor.Part1 = body
	rootMotor.C0 = CFrame.new(0, 1.5, 0)
	rootMotor.Parent = root
	rig.Root = rootMotor

	-- Plaques teal (pâte mélangée)
	for i = 1, 7 do
		local plate = createPart(model, "NmPlate"..i,
			Vector3.new(math.random(15, 30)/10, math.random(12, 25)/10, math.random(5, 9)/10),
			COLORS.nmTeal, Enum.Material.Slate)
		plate.Shape = Enum.PartType.Ball
		local ang = math.rad(i * 51)
		plate.CFrame = body.CFrame * CFrame.new(math.cos(ang) * 3.2, math.sin(i * 2.1) * 2.4, math.sin(ang) * 2.6)
			* CFrame.Angles(math.random(), math.random(), math.random())
		weld(body, plate)
	end

	-- ══════════════════════════════
	-- LA GRANDE BOUCHE VERTICALE (gueule béante teal pleine d'yeux)
	-- ══════════════════════════════
	local maw = createPart(model, "NmMaw", Vector3.new(4.2, 5.2, 1.4), COLORS.nmDark, Enum.Material.SmoothPlastic)
	maw.Shape = Enum.PartType.Ball
	maw.CFrame = body.CFrame * CFrame.new(0, 0.4, -2.7)
	weld(body, maw)
	rig.Maw = maw

	-- Anneau de la gueule (bordure teal)
	local mawRing = createPart(model, "NmMawRing", Vector3.new(4.8, 5.8, 0.9), COLORS.nmTeal, Enum.Material.Slate)
	mawRing.Shape = Enum.PartType.Ball
	mawRing.CFrame = maw.CFrame * CFrame.new(0, 0, 0.5)
	weld(maw, mawRing)

	-- YEUX MULTIPLES dans la gueule (orange lumineux — horreur)
	rig.MawEyes = {}
	local eyePositions = {
		{0, 1.4}, {-1.0, 0.5}, {1.0, 0.6}, {-0.5, -0.8}, {0.7, -1.0}, {0, -0.1},
	}
	for i, pos in ipairs(eyePositions) do
		local mEye = createPart(model, "NmMawEye"..i, Vector3.new(0.7, 0.55, 0.3), Color3.fromRGB(10, 15, 15), Enum.Material.SmoothPlastic)
		mEye.Shape = Enum.PartType.Ball
		mEye.CFrame = maw.CFrame * CFrame.new(pos[1], pos[2], -0.6)
		weld(maw, mEye)
		local mPupil = createPart(model, "NmMawPupil"..i, Vector3.new(0.28, 0.2, 0.15), COLORS.nmEye, Enum.Material.Neon)
		mPupil.Shape = Enum.PartType.Ball
		mPupil.CFrame = mEye.CFrame * CFrame.new(0, 0, -0.15)
		weld(mEye, mPupil)
		table.insert(rig.MawEyes, mPupil)
	end

	-- DENTS / griffes autour de la gueule
	for i = 1, 10 do
		local ang = math.rad(i * 36)
		local tooth = createPart(model, "NmTooth"..i, Vector3.new(0.3, 1.1, 0.3), COLORS.nmDark, Enum.Material.Slate)
		tooth.CFrame = maw.CFrame * CFrame.new(math.cos(ang) * 2.0, math.sin(ang) * 2.4, -0.4)
			* CFrame.Angles(0, 0, ang + math.rad(90)) * CFrame.Angles(math.rad(25), 0, 0)
		weld(maw, tooth)
	end

	-- Lueur de la gueule
	local mawGlow = Instance.new("PointLight")
	mawGlow.Color = COLORS.nmEye; mawGlow.Brightness = 3; mawGlow.Range = 22
	mawGlow.Parent = maw
	rig.MawGlow = mawGlow

	-- ══════════════════════════════
	-- 6 BRAS DIFFORMES (longs, griffus)
	-- ══════════════════════════════
	rig.ArmMotors = {}
	local armConfigs = {
		{side = -1, y = 1.8, backZ = 0.5},
		{side = 1,  y = 1.8, backZ = 0.5},
		{side = -1, y = 0.2, backZ = 1.2},
		{side = 1,  y = 0.2, backZ = 1.2},
		{side = -1, y = -1.5, backZ = 0.8},
		{side = 1,  y = -1.5, backZ = 0.8},
	}
	for i, cfg in ipairs(armConfigs) do
		local upperArm = createPart(model, "NmArm"..i, Vector3.new(0.95, 3.6, 0.95), COLORS.nmOrange, Enum.Material.Slate)
		upperArm.CFrame = body.CFrame * CFrame.new(cfg.side * 3.6, cfg.y, cfg.backZ)
			* CFrame.Angles(0, 0, cfg.side * math.rad(-55))

		local am = Instance.new("Motor6D")
		am.Part0 = body; am.Part1 = upperArm
		am.C0 = body.CFrame:ToObjectSpace(upperArm.CFrame)
		am.Parent = body
		table.insert(rig.ArmMotors, {motor = am, side = cfg.side, phase = i * 1.1})

		local lowerArm = createPart(model, "NmForearm"..i, Vector3.new(0.8, 3.2, 0.8), COLORS.nmOrange, Enum.Material.Slate)
		lowerArm.CFrame = upperArm.CFrame * CFrame.new(0, -3.2, 0) * CFrame.Angles(math.rad(20), 0, 0)
		weld(upperArm, lowerArm)

		-- Rayures teal sur le bras
		local stripe = createPart(model, "NmStripe"..i, Vector3.new(0.85, 0.6, 0.85), COLORS.nmTeal, Enum.Material.Slate)
		stripe.CFrame = lowerArm.CFrame * CFrame.new(0, 0.8, 0)
		weld(lowerArm, stripe)

		-- Main griffue
		local claw = createPart(model, "NmClaw"..i, Vector3.new(1.1, 0.9, 0.7), COLORS.nmOrange, Enum.Material.Slate)
		claw.Shape = Enum.PartType.Ball
		claw.CFrame = lowerArm.CFrame * CFrame.new(0, -1.9, 0)
		weld(lowerArm, claw)
		for f = -1, 1 do
			local finger = createPart(model, "NmFinger"..i..f, Vector3.new(0.22, 1.0, 0.22), COLORS.nmOrange, Enum.Material.Slate)
			finger.CFrame = claw.CFrame * CFrame.new(f * 0.35, -0.7, 0) * CFrame.Angles(math.rad(15) * f, 0, 0)
			weld(claw, finger)
		end
	end

	-- ══════════════════════════════
	-- JAMBES TRAPUES
	-- ══════════════════════════════
	rig.LegMotors = {}
	for side = -1, 1, 2 do
		local leg = createPart(model, "NmLeg"..side, Vector3.new(1.6, 3.2, 1.6), COLORS.nmOrange, Enum.Material.Slate)
		leg.CFrame = body.CFrame * CFrame.new(side * 1.8, -4.0, 0)
		local lm = Instance.new("Motor6D")
		lm.Part0 = body; lm.Part1 = leg
		lm.C0 = body.CFrame:ToObjectSpace(leg.CFrame)
		lm.Parent = body
		table.insert(rig.LegMotors, {motor = lm, side = side})

		local foot = createPart(model, "NmFoot"..side, Vector3.new(2.0, 0.8, 2.6), COLORS.nmTeal, Enum.Material.Slate)
		foot.Shape = Enum.PartType.Ball
		foot.CFrame = leg.CFrame * CFrame.new(0, -1.9, -0.4)
		weld(leg, foot)
	end

	-- Restes du chapeau melon (accroché de travers — détail tragique)
	local hatRemains = createPart(model, "NmHat", Vector3.new(0.9, 0.6, 0.9), COLORS.hatNavy, Enum.Material.Fabric)
	hatRemains.Shape = Enum.PartType.Ball
	hatRemains.CFrame = body.CFrame * CFrame.new(1.8, 3.2, -0.5) * CFrame.Angles(0, 0, math.rad(35))
	weld(body, hatRemains)

	local data = {
		state = "CHASE",           -- CHASE, GOBBLE, FROZEN, DYING
		animTimer = 0,
		lastTPTime = tick(),
		chaseSound = nil,
		frozenUntil = 0,
		iceParts = {},
		body = body,
		maw = maw,
	}

	return model, rig, data
end

-- ═══════════════════════════════════════════════════════════════════
-- ANIMATION NIGHTMARE DOEY
-- ═══════════════════════════════════════════════════════════════════

local function animNightmare(rig, t, isMoving, state)
	if state == "FROZEN" then
		-- Complètement figé, micro-tremblements
		local tremble = math.sin(t * 40) * 0.008
		if rig.Root then rig.Root.Transform = CFrame.new(tremble, 0, 0) end
		return
	end

	if isMoving then
		local cycle = t * 6
		local lurch = math.abs(math.sin(cycle)) * 0.5
		if rig.Root then
			rig.Root.Transform = CFrame.new(0, lurch, 0) * CFrame.Angles(math.rad(8), 0, math.sin(cycle) * 0.12)
		end
		-- 6 bras qui rament frénétiquement
		for _, armData in ipairs(rig.ArmMotors or {}) do
			armData.motor.Transform = CFrame.Angles(
				math.sin(cycle + armData.phase) * 0.8,
				0,
				armData.side * math.sin(cycle * 1.3 + armData.phase) * 0.3
			)
		end
		for _, legData in ipairs(rig.LegMotors or {}) do
			local ph = legData.side == -1 and 0 or math.pi
			legData.motor.Transform = CFrame.Angles(math.sin(cycle + ph) * 0.55, 0, 0)
		end
	else
		-- Respiration monstrueuse, bras qui ondulent
		local breathe = math.sin(t * 1.5) * 0.15
		if rig.Root then rig.Root.Transform = CFrame.new(0, breathe, 0) end
		for _, armData in ipairs(rig.ArmMotors or {}) do
			armData.motor.Transform = CFrame.Angles(math.sin(t * 2 + armData.phase) * 0.2, 0, armData.side * math.sin(t * 1.5 + armData.phase) * 0.12)
		end
	end

	-- Yeux de la gueule qui pulsent
	for i, eye in ipairs(rig.MawEyes or {}) do
		if eye.Parent then
			eye.Transparency = 0.1 + math.abs(math.sin(t * 3 + i)) * 0.25
		end
	end
	if rig.MawGlow then
		rig.MawGlow.Brightness = 2.5 + math.sin(t * 5) * 1.2
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- PHASE AMICALE — Doey se balade avec ses critters, coucou & interactions
-- ═══════════════════════════════════════════════════════════════════

local wanderTarget = nil
local lastWanderChange = 0

local function setupFriendlyAI()
	local model, rig, data = doey.model, doey.rig, doey.data

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not eventActive or phase ~= "FRIENDLY" or not model.Parent then return end
		if not rootPart or not rootPart.Parent then return end

		local now = tick()
		data.animTimer = data.animTimer + dt
		local doeyPos = model.PrimaryPart.Position
		local toPlayer = rootPart.Position - doeyPos
		local distToPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z).Magnitude

		-- ══ COUCOU quand le joueur s'approche ══
		if data.state == "WALK" or data.state == "IDLE" then
			if distToPlayer < WAVE_DIST and now > data.waveCooldown then
				data.state = "WAVE"
				data.stateUntil = now + 3.5
				data.waveCooldown = now + 15
				data.animTimer = 0
				speak(data.head, "👋 Salut copain ! Bienvenue !", COLORS.doughBlue, 3.5)
				playSnd(SND.pickup, 0.8)
			end
		end

		if data.state == "WAVE" or data.state == "DANCE" or data.state == "PAT" then
			-- Tourner vers le joueur pendant l'interaction
			local lookCF = CFrame.lookAt(doeyPos, Vector3.new(rootPart.Position.X, doeyPos.Y, rootPart.Position.Z))
			model:PivotTo(lookCF)
			if now > (data.stateUntil or 0) then
				data.state = "WALK"
			end
			pcall(function() animDoeyFriendly(rig, data.animTimer, data.state) end)

		elseif data.state == "WALK" then
			-- Errance douce sur la map
			if not wanderTarget or now - lastWanderChange > 12 or (doeyPos - wanderTarget).Magnitude < 6 then
				lastWanderChange = now
				local g = findSafeGround(15, 25, 70)
				wanderTarget = Vector3.new(g.X, doeyPos.Y, g.Z)
			end

			if now - data.lastStepTime >= FRIENDLY_STEP_INTERVAL then
				data.lastStepTime = now
				local dir = (wanderTarget - doeyPos)
				dir = Vector3.new(dir.X, 0, dir.Z)
				if dir.Magnitude > 1 then
					dir = dir.Unit
					local newPos = doeyPos + dir * FRIENDLY_SPEED_STEP
					local ground = findGround(newPos.X, newPos.Z)
					newPos = Vector3.new(newPos.X, ground.Y + 4.2, newPos.Z)
					model:PivotTo(CFrame.lookAt(newPos, newPos + dir))
				end
			end
			pcall(function() animDoeyFriendly(rig, data.animTimer, "WALK") end)

			-- Interactions aléatoires spontanées
			if now - data.lastInteract > 20 and math.random() < dt * 0.15 then
				data.lastInteract = now
				local roll = math.random(1, 3)
				if roll == 1 then
					data.state = "DANCE"; data.stateUntil = now + 4; data.animTimer = 0
					speak(data.head, "🎵 Hé hé, regarde-moi danser !", COLORS.doughYellow, 4)
				elseif roll == 2 then
					data.state = "PAT"; data.stateUntil = now + 3; data.animTimer = 0
					speak(data.head, "❤️ Mes petits amis adorés...", COLORS.doughOrange, 3)
				else
					data.state = "IDLE"; data.stateUntil = now + 4; data.animTimer = 0
					speak(data.head, "😊 Quelle belle journée à l'usine !", COLORS.doughBlue, 4)
				end
			end

		elseif data.state == "IDLE" then
			if now > (data.stateUntil or 0) then data.state = "WALK" end
			pcall(function() animDoeyFriendly(rig, data.animTimer, "IDLE") end)
		end

		-- ══ CRITTERS qui suivent Doey ══
		for _, cr in ipairs(critters) do
			if cr.data.alive and cr.model.Parent then
				cr.data.animTimer = cr.data.animTimer + dt
				local targetPos = model.PrimaryPart.CFrame * cr.data.offset
				local crPos = cr.model.PrimaryPart.Position
				local crDir = (targetPos.Position - crPos)
				crDir = Vector3.new(crDir.X, 0, crDir.Z)
				local moving = crDir.Magnitude > 2

				if moving then
					local step = math.min(crDir.Magnitude, 0.35)
					local newPos = crPos + crDir.Unit * step
					local g = findGround(newPos.X, newPos.Z)
					newPos = Vector3.new(newPos.X, g.Y + 1.6, newPos.Z)
					cr.model:PivotTo(CFrame.lookAt(newPos, newPos + crDir.Unit))
				end
				pcall(function() animCritter(cr.rig, cr.data.animTimer, moving) end)
			end
		end
	end)
	table.insert(eventConnections, conn)
end

-- ═══════════════════════════════════════════════════════════════════
-- INTERACTIONS PROXIMITY PROMPT sur Doey (câlin, high-five, danse)
-- ═══════════════════════════════════════════════════════════════════

local function setupDoeyPrompts()
	local model, rig, data = doey.model, doey.rig, doey.data

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Dire bonjour à Doey 👋"
	prompt.ObjectText = "Doey the Doughman"
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0.4
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.Parent = data.belly

	local interactionIdx = 0
	local interactions = {
		{state = "WAVE", text = "👋 Coucou toi ! Content de te voir !", col = COLORS.doughBlue, dur = 3.5},
		{state = "DANCE", text = "🎵 Tu veux danser avec moi ?!", col = COLORS.doughYellow, dur = 4},
		{state = "PAT", text = "🤗 Un gros câlin de pâte !", col = COLORS.doughOrange, dur = 3},
		{state = "WAVE", text = "⭐ Tu es mon ami préféré !", col = COLORS.doughBlue, dur = 3.5},
		{state = "DANCE", text = "😄 La vie est belle avec des amis !", col = COLORS.doughYellow, dur = 4},
	}

	prompt.Triggered:Connect(function(plr)
		if plr ~= player or phase ~= "FRIENDLY" then return end
		interactionIdx = interactionIdx % #interactions + 1
		local it = interactions[interactionIdx]
		data.state = it.state
		data.stateUntil = tick() + it.dur
		data.animTimer = 0
		speak(data.head, it.text, it.col, it.dur)
		playSnd(SND.pickup, 0.7)
	end)

	doey.prompt = prompt
end

-- ═══════════════════════════════════════════════════════════════════
-- ARME DU JOUEUR (batte) — ⚠️ frapper un critter déclenche la RAGE
-- ═══════════════════════════════════════════════════════════════════

local function createWeapon()
	if weaponModel then return end
	local tool = Instance.new("Model"); tool.Name = "DD_Weapon"

	local handle = createPart(tool, "Handle", Vector3.new(0.3, 4.2, 0.3), Color3.fromRGB(90, 60, 35), Enum.Material.Wood)
	local batHead = createPart(tool, "BatHead", Vector3.new(0.65, 1.4, 0.65), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
	batHead.CFrame = handle.CFrame * CFrame.new(0, 2.6, 0)
	weld(handle, batHead)

	tool.PrimaryPart = handle; tool.Parent = workspace
	weaponModel = tool; playerHasWeapon = true

	local rh = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
	if rh then
		handle.CFrame = rh.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
		weld(rh, handle)
	end
end

local function removeWeapon()
	if weaponModel then weaponModel:Destroy(); weaponModel = nil end
	playerHasWeapon = false
end

-- ═══════════════════════════════════════════════════════════════════
-- TUER UN CRITTER → mort du critter + RAGE DE DOEY
-- ═══════════════════════════════════════════════════════════════════

local function killCritter(cr)
	if not cr.data.alive then return end
	cr.data.alive = false

	playSnd(SND.hit, 1.5)
	playSnd(SND.powerDown, 1.2)

	-- Le critter tombe et devient gris (mort tragique)
	for _, p in pairs(cr.model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.9 then
			TweenService:Create(p, TweenInfo.new(1.2), {
				Color = Color3.fromRGB(80, 80, 85)
			}):Play()
		end
	end

	-- Bascule sur le côté
	local pos = cr.model.PrimaryPart.Position
	local fallCF = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.new(0, -0.8, 0)
	local pivotTween = 0
	task.spawn(function()
		for i = 1, 12 do
			cr.model:PivotTo(cr.model.PrimaryPart.CFrame:Lerp(fallCF, i / 12))
			task.wait(0.04)
		end
	end)

	-- Petites particules d'âme
	local soulPart = Instance.new("Part")
	soulPart.Size = Vector3.new(1,1,1); soulPart.Transparency = 1
	soulPart.Anchored = true; soulPart.CanCollide = false
	soulPart.Position = pos; soulPart.Name = "DD_Soul"; soulPart.Parent = workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(150, 150, 255))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(1.5, 2.5); pe.Rate = 20
	pe.Speed = NumberRange.new(1, 3); pe.SpreadAngle = Vector2.new(20, 20)
	pe.LightEmission = 1; pe.Texture = "rbxassetid://241685484"
	pe.Parent = soulPart
	task.delay(1.5, function() pe.Enabled = false end)
	Debris:AddItem(soulPart, 4)

	-- ⚠️ DÉCLENCHER LA RAGE DE DOEY
	task.delay(1.2, function()
		if eventActive and phase == "FRIENDLY" then
			triggerRage(cr.data.name)
		end
	end)
end

local function swingWeapon()
	if not canSwing or not playerHasWeapon then return end
	canSwing = false
	playSnd(SND.weaponSwing, 1)

	local mouse = player:GetMouse()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {character}
	if weaponModel then table.insert(ex, weaponModel) end
	rp.FilterDescendantsInstances = ex

	local result = workspace:Raycast(ray.Origin, ray.Direction * WEAPON_RANGE, rp)
	if result and result.Instance then
		local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
		if hitModel then
			-- Frapper un CRITTER = le tuer = RAGE
			if hitModel.Name:sub(1, 11) == "DD_Critter_" then
				for _, cr in ipairs(critters) do
					if cr.model == hitModel and cr.data.alive then
						killCritter(cr)
						break
					end
				end
			-- Frapper Doey gentil = il s'énerve un peu (avertissement)
			elseif hitModel.Name == "DD_Doey" and phase == "FRIENDLY" then
				local data = doey.data
				data.state = "ANGRY"
				data.stateUntil = tick() + 2.5
				data.animTimer = 0
				speak(data.head, "😠 Hé ! Ça ne se fait pas ça...", COLORS.doughRed, 3)
				playSnd(SND.growl, 1)
				-- Yeux qui virent au rouge un instant
				if doey.rig.EyeDotL then
					doey.rig.EyeDotL.Color = COLORS.neonRed
					doey.rig.EyeDotR.Color = COLORS.neonRed
					task.delay(2.5, function()
						pcall(function()
							doey.rig.EyeDotL.Color = Color3.fromRGB(220, 60, 50)
							doey.rig.EyeDotR.Color = Color3.fromRGB(220, 60, 50)
						end)
					end)
				end
			end
		end
	end

	task.wait(SWING_COOLDOWN)
	canSwing = true
end

-- ═══════════════════════════════════════════════════════════════════
-- TRANSFORMATION — Doey s'enfonce dans le sol avec une belle animation
-- puis ressort en NIGHTMARE DOEY
-- ═══════════════════════════════════════════════════════════════════

triggerRage = function(critterName)
	if phase ~= "FRIENDLY" then return end
	phase = "TRANSFORM"

	local model, rig, data = doey.model, doey.rig, doey.data
	data.state = "ANGRY"

	-- 1) Doey se fige et fixe le joueur
	playSnd(SND.growl, 2)
	playSnd(SND.heartbeat, 1, true)
	speak(data.head, "💔 " .. critterName .. "... NON... QU'AS-TU FAIT ?!", COLORS.neonRed, 5)

	-- Yeux rouges vif
	pcall(function()
		rig.EyeDotL.Color = COLORS.neonRed
		rig.EyeDotL.Size = Vector3.new(0.3, 0.25, 0.15)
		rig.EyeDotR.Color = COLORS.neonRed
		rig.EyeDotR.Size = Vector3.new(0.3, 0.25, 0.15)
	end)

	-- Ambiance qui bascule
	activateAtmosphere(true)

	local doeyPos = model.PrimaryPart.Position
	model:PivotTo(CFrame.lookAt(doeyPos, Vector3.new(rootPart.Position.X, doeyPos.Y, rootPart.Position.Z)))

	task.spawn(function()
		-- 2) Tremblement de rage (3 secondes)
		local shakeStart = tick()
		while tick() - shakeStart < 3 do
			pcall(function() animDoeyFriendly(rig, tick(), "ANGRY") end)
			task.wait()
		end
		if not eventActive then return end

		playSnd(SND.alert, 2)
		speak(data.head, "😡 TU VAS LE REGRETTER...", COLORS.neonRed, 3)

		-- 3) ENFONCEMENT DANS LE SOL — la pâte fond et coule
		local sinkPos = model.PrimaryPart.Position

		-- Flaque de pâte qui s'élargit au sol
		local puddle = Instance.new("Part")
		puddle.Name = "DD_Puddle"
		puddle.Shape = Enum.PartType.Cylinder
		puddle.Size = Vector3.new(0.3, 2, 2)
		puddle.Color = COLORS.doughBlue
		puddle.Material = Enum.Material.Slate
		puddle.Anchored = true; puddle.CanCollide = false
		local groundY = findGround(sinkPos.X, sinkPos.Z).Y
		puddle.CFrame = CFrame.new(sinkPos.X, groundY + 0.1, sinkPos.Z) * CFrame.Angles(0, 0, math.rad(90))
		puddle.Parent = workspace

		TweenService:Create(puddle, TweenInfo.new(3.5, Enum.EasingStyle.Quad), {
			Size = Vector3.new(0.3, 16, 16),
			Color = COLORS.nmOrange
		}):Play()

		-- Bulles de pâte qui remontent
		local bubblePart = Instance.new("Part")
		bubblePart.Size = Vector3.new(1,1,1); bubblePart.Transparency = 1
		bubblePart.Anchored = true; bubblePart.CanCollide = false
		bubblePart.Position = Vector3.new(sinkPos.X, groundY + 0.5, sinkPos.Z)
		bubblePart.Name = "DD_Bubbles"; bubblePart.Parent = workspace
		local bpe = Instance.new("ParticleEmitter")
		bpe.Color = ColorSequence.new(COLORS.doughBlue, COLORS.nmOrange)
		bpe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(0.5, 1.5), NumberSequenceKeypoint.new(1, 0)})
		bpe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
		bpe.Lifetime = NumberRange.new(0.8, 1.5); bpe.Rate = 40
		bpe.Speed = NumberRange.new(2, 6); bpe.SpreadAngle = Vector2.new(40, 40)
		bpe.Texture = "rbxassetid://241685484"
		bpe.Parent = bubblePart

		-- Descente fluide du modèle dans le sol (avec torsion — beau et dérangeant)
		local sinkDur = 3.5
		local sinkStart = tick()
		playSnd(SND.static, 1.2)
		while tick() - sinkStart < sinkDur do
			local a = (tick() - sinkStart) / sinkDur
			local ease = a * a * (3 - 2 * a) -- smoothstep
			local twist = a * math.rad(540)  -- il tourne sur lui-même en fondant
			local depth = ease * 11
			model:PivotTo(CFrame.new(sinkPos - Vector3.new(0, depth, 0)) * CFrame.Angles(0, twist, 0))
			-- Le corps se déforme (écrasement progressif)
			if rig.Root then
				rig.Root.Transform = CFrame.Angles(math.sin(tick() * 12) * 0.05 * a, 0, 0)
			end
			task.wait()
		end
		if not eventActive then puddle:Destroy(); bubblePart:Destroy() return end

		-- Doey a disparu sous terre
		model:Destroy()
		doey = nil

		-- 4) SILENCE... puis ÉRUPTION
		bpe.Rate = 5
		task.wait(1.5)
		if not eventActive then puddle:Destroy(); bubblePart:Destroy() return end

		-- Grondement sous terre
		playSnd(SND.growl, 2.5)
		bpe.Rate = 120
		bpe.Speed = NumberRange.new(8, 18)

		-- Secousse de caméra
		task.spawn(function()
			local hum = character:FindFirstChildOfClass("Humanoid")
			for i = 1, 25 do
				camera.CFrame = camera.CFrame * CFrame.Angles(
					math.rad(math.random(-10, 10)/10),
					math.rad(math.random(-10, 10)/10), 0)
				task.wait(0.05)
			end
		end)

		task.wait(1.5)
		if not eventActive then puddle:Destroy(); bubblePart:Destroy() return end

		-- 5) NIGHTMARE DOEY JAILLIT DU SOL
		playSnd(SND.explode, 3)
		playSnd(SND.jumpscare, 1.5)

		local nmModel, nmRig, nmData = buildNightmareDoey()
		nightmare = {model = nmModel, rig = nmRig, data = nmData}

		local riseFrom = Vector3.new(sinkPos.X, groundY - 12, sinkPos.Z)
		nmModel:PivotTo(CFrame.new(riseFrom))
		nmModel.Parent = workspace

		-- Débris de pâte projetés
		for i = 1, 25 do
			local db = Instance.new("Part")
			db.Name = "DD_EruptDebris"..i
			db.Size = Vector3.new(math.random(4,12)/10, math.random(4,12)/10, math.random(4,12)/10)
			db.Color = math.random() > 0.5 and COLORS.nmOrange or COLORS.nmTeal
			db.Material = Enum.Material.Slate
			db.Shape = Enum.PartType.Ball
			db.Anchored = false; db.CanCollide = true
			db.CFrame = CFrame.new(sinkPos.X, groundY + 2, sinkPos.Z) * CFrame.new(math.random(-3,3), 0, math.random(-3,3))
			db.Velocity = Vector3.new(math.random(-45,45), math.random(30,70), math.random(-45,45))
			db.Parent = workspace
			Debris:AddItem(db, 4)
		end

		-- Montée du monstre
		local riseDur = 1.8
		local riseStart = tick()
		local targetY = groundY + 5.5
		while tick() - riseStart < riseDur do
			local a = (tick() - riseStart) / riseDur
			local ease = 1 - (1 - a) ^ 3
			local y = riseFrom.Y + (targetY - riseFrom.Y) * ease
			local lookCF = CFrame.lookAt(
				Vector3.new(sinkPos.X, y, sinkPos.Z),
				Vector3.new(rootPart.Position.X, y, rootPart.Position.Z))
			nmModel:PivotTo(lookCF)
			task.wait()
		end

		TweenService:Create(puddle, TweenInfo.new(2), {Transparency = 1}):Play()
		Debris:AddItem(puddle, 2.5)
		bpe.Enabled = false
		Debris:AddItem(bubblePart, 3)

		-- Rugissement final
		playSnd(SND.growl, 3)
		speak(nmData.maw, "🩸 TU AS BRISÉ MA FAMILLE.", COLORS.nmEye, 4)

		-- Les critters survivants s'enfuient (disparaissent)
		for _, cr in ipairs(critters) do
			if cr.data.alive and cr.model.Parent then
				task.spawn(function()
					for _, p in pairs(cr.model:GetDescendants()) do
						if p:IsA("BasePart") then
							TweenService:Create(p, TweenInfo.new(1.5), {Transparency = 1}):Play()
						end
					end
					task.wait(1.6)
					pcall(function() cr.model:Destroy() end)
				end)
			end
		end

		-- Mise à jour GUI
		local gui = player.PlayerGui:FindFirstChild("DoeyEventGui")
		if gui then
			local objLabel = gui:FindFirstChild("ObjectiveLabel", true)
			if objLabel then
				objLabel.Text = "🧊 OBJECTIF : Attire-le sur une BOUTEILLE D'AZOTE, puis vers la SCIE de la grue ! (" .. SLICES_TO_KILL .. " coups)"
				objLabel.TextColor3 = COLORS.nitroCyan
			end
		end

		task.wait(2)
		if not eventActive then return end

		-- 6) DÉMARRER LA PHASE NIGHTMARE
		phase = "NIGHTMARE"
		nmData.chaseSound = playSnd(SND.chase, 0.7, true)
		playSnd(SND.heartbeat, 0.8, true)

		-- Spawn des bouteilles d'azote
		for i = 1, MAX_BOTTLES do
			spawnNitroBottle()
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- BOUTEILLES D'AZOTE (spawn aléatoire, glow visible à travers les murs)
-- ═══════════════════════════════════════════════════════════════════

spawnNitroBottle = function()
	local bottle = Instance.new("Model")
	bottle.Name = "DD_NitroBottle"

	local pos = findSafeGround(25, 40, 160)

	-- Corps de la bouteille (cylindre)
	local body = createAnchoredPart(bottle, "NitroBody", Vector3.new(1.2, 3, 1.2), Color3.fromRGB(190, 200, 210), Enum.Material.Metal)
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(3, 1.2, 1.2)
	body.CFrame = CFrame.new(pos + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	bottle.PrimaryPart = body

	-- Bande cyan (azote liquide)
	local band = createAnchoredPart(bottle, "NitroBand", Vector3.new(0.8, 1.25, 1.25), COLORS.nitroCyan, Enum.Material.Neon)
	band.Shape = Enum.PartType.Cylinder
	band.CFrame = body.CFrame
	band.CanCollide = false

	-- Valve
	local valve = createAnchoredPart(bottle, "NitroValve", Vector3.new(0.4, 0.6, 0.4), COLORS.metalDark, Enum.Material.Metal)
	valve.CFrame = CFrame.new(pos + Vector3.new(0, 3.4, 0))
	valve.CanCollide = false

	-- ⭐ Highlight visible à travers les murs
	local hl = Instance.new("Highlight")
	hl.Adornee = bottle; hl.Parent = bottle
	hl.FillColor = COLORS.nitroCyan
	hl.FillTransparency = 0.55
	hl.OutlineColor = COLORS.nitroCyan
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	-- Billboard ❄ + distance
	local bbAnchor = Instance.new("Part")
	bbAnchor.Size = Vector3.new(0.1, 0.1, 0.1); bbAnchor.Transparency = 1
	bbAnchor.Anchored = true; bbAnchor.CanCollide = false
	bbAnchor.Position = pos + Vector3.new(0, 5, 0)
	bbAnchor.Name = "DD_NitroBB"; bbAnchor.Parent = bottle

	local bb = Instance.new("BillboardGui")
	bb.Adornee = bbAnchor; bb.Parent = bbAnchor
	bb.Size = UDim2.new(0, 70, 0, 70)
	bb.AlwaysOnTop = true; bb.MaxDistance = 600; bb.LightInfluence = 0

	local circle = Instance.new("Frame", bb)
	circle.Size = UDim2.new(0.6, 0, 0.6, 0)
	circle.Position = UDim2.new(0.2, 0, 0.1, 0)
	circle.BackgroundColor3 = COLORS.nitroCyan
	circle.BackgroundTransparency = 0.15
	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

	local icon = Instance.new("TextLabel", circle)
	icon.Size = UDim2.new(1, 0, 1, 0); icon.BackgroundTransparency = 1
	icon.Text = "❄"; icon.TextColor3 = Color3.new(1,1,1)
	icon.TextScaled = true; icon.Font = Enum.Font.GothamBold

	local dl = Instance.new("TextLabel", bb)
	dl.Size = UDim2.new(1, 0, 0.25, 0); dl.Position = UDim2.new(0, 0, 0.75, 0)
	dl.BackgroundTransparency = 1; dl.Text = "?m"
	dl.TextColor3 = COLORS.nitroCyan; dl.TextScaled = true
	dl.Font = Enum.Font.Code; dl.TextStrokeTransparency = 0

	-- Vapeur froide
	local vape = Instance.new("ParticleEmitter")
	vape.Color = ColorSequence.new(COLORS.iceBlue, Color3.new(1,1,1))
	vape.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2)})
	vape.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
	vape.Lifetime = NumberRange.new(1, 2); vape.Rate = 12
	vape.Speed = NumberRange.new(0.5, 2); vape.SpreadAngle = Vector2.new(30, 30)
	vape.LightEmission = 0.5; vape.Texture = "rbxassetid://241685484"
	vape.Parent = valve

	local pl = Instance.new("PointLight")
	pl.Color = COLORS.nitroCyan; pl.Brightness = 3; pl.Range = 18
	pl.Parent = body

	bottle.Parent = workspace

	local bData = {model = bottle, body = body, consumed = false}
	table.insert(nitroBottles, bData)

	-- Animation pulse + distance
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not bottle.Parent or bData.consumed then conn:Disconnect() return end
		local t = tick()
		hl.FillTransparency = 0.5 + math.sin(t * 3) * 0.15
		pl.Brightness = 2.5 + math.sin(t * 4) * 1.2
		if rootPart and rootPart.Parent then
			dl.Text = math.floor((rootPart.Position - body.Position).Magnitude) .. "m"
		end
	end)
	table.insert(eventConnections, conn)

	return bData
end

-- ═══════════════════════════════════════════════════════════════════
-- LA GRUE AVEC LA SCIE (structure fixe sur la map)
-- ═══════════════════════════════════════════════════════════════════

local function buildCrane()
	local crane = Instance.new("Model")
	crane.Name = "DD_Crane"

	local base = findSafeGround(30, 60, 120)

	-- Socle
	local pedestal = createAnchoredPart(crane, "CraneBase", Vector3.new(8, 2, 8), COLORS.metalDark, Enum.Material.DiamondPlate)
	pedestal.Position = base + Vector3.new(0, 1, 0)
	crane.PrimaryPart = pedestal

	-- Mât vertical jaune (grue industrielle)
	local mast = createAnchoredPart(crane, "CraneMast", Vector3.new(2, 22, 2), COLORS.metal, Enum.Material.Metal)
	mast.Position = base + Vector3.new(0, 13, 0)

	-- Croisillons
	for i = 1, 5 do
		local cross = createAnchoredPart(crane, "CraneCross"..i, Vector3.new(2.4, 0.4, 2.4), COLORS.metalDark, Enum.Material.Metal)
		cross.Position = base + Vector3.new(0, 3 + i * 4, 0)
		cross.CanCollide = false
	end

	-- Flèche horizontale
	local jib = createAnchoredPart(crane, "CraneJib", Vector3.new(2, 1.6, 18), COLORS.metal, Enum.Material.Metal)
	jib.Position = base + Vector3.new(0, 23, 7)

	-- Câble qui descend
	local cable = createAnchoredPart(crane, "CraneCable", Vector3.new(0.25, 12, 0.25), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
	cable.Position = base + Vector3.new(0, 17, 14)
	cable.CanCollide = false

	-- ══════════════════════════════
	-- LA SCIE CIRCULAIRE (au bout du câble, à hauteur de monstre)
	-- ══════════════════════════════
	local sawHub = createAnchoredPart(crane, "SawHub", Vector3.new(1.2, 1.2, 0.8), COLORS.metalDark, Enum.Material.Metal)
	sawHub.Position = base + Vector3.new(0, 10.5, 14)
	sawHub.CanCollide = false

	local saw = createAnchoredPart(crane, "SawBlade", Vector3.new(0.35, 7, 7), Color3.fromRGB(200, 200, 210), Enum.Material.Metal)
	saw.Shape = Enum.PartType.Cylinder
	saw.Position = base + Vector3.new(0, 8, 14)
	saw.CanCollide = false
	sawBlade = saw

	-- Dents de la scie
	for i = 1, 12 do
		local ang = math.rad(i * 30)
		local tooth = createAnchoredPart(crane, "SawTooth"..i, Vector3.new(0.4, 0.9, 0.7), Color3.fromRGB(160, 160, 170), Enum.Material.Metal)
		tooth.Position = saw.Position + Vector3.new(0, math.sin(ang) * 3.8, math.cos(ang) * 3.8)
		tooth.CanCollide = false
		tooth.Orientation = Vector3.new(math.deg(ang), 0, 0)
	end

	-- Highlight rouge sur la scie
	local sawHl = Instance.new("Highlight")
	sawHl.Adornee = saw; sawHl.Parent = saw
	sawHl.FillColor = COLORS.neonRed; sawHl.FillTransparency = 0.7
	sawHl.OutlineColor = COLORS.neonRed; sawHl.OutlineTransparency = 0.2
	sawHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	-- Billboard 🪚
	local bbA = Instance.new("Part")
	bbA.Size = Vector3.new(0.1,0.1,0.1); bbA.Transparency = 1
	bbA.Anchored = true; bbA.CanCollide = false
	bbA.Position = base + Vector3.new(0, 26, 7)
	bbA.Name = "DD_CraneBB"; bbA.Parent = crane

	local bb = Instance.new("BillboardGui")
	bb.Adornee = bbA; bb.Parent = bbA
	bb.Size = UDim2.new(0, 110, 0, 45)
	bb.AlwaysOnTop = true; bb.MaxDistance = 800

	local lbl = Instance.new("TextLabel", bb)
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3 = Color3.fromRGB(40, 10, 0)
	lbl.BackgroundTransparency = 0.3
	lbl.Text = "🪚 GRUE-SCIE"
	lbl.TextColor3 = COLORS.neonRed; lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold; lbl.TextStrokeTransparency = 0
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)

	-- Rotation permanente de la scie
	local sawConn
	sawConn = RunService.Heartbeat:Connect(function(dt)
		if not saw.Parent then sawConn:Disconnect() return end
		saw.CFrame = saw.CFrame * CFrame.Angles(dt * 12, 0, 0)
	end)
	table.insert(eventConnections, sawConn)

	crane.Parent = workspace
	craneModel = crane
	return crane
end

-- ═══════════════════════════════════════════════════════════════════
-- JUMPSCARE — caméra arrachée vers la gueule du monstre (comme le jeu)
-- ═══════════════════════════════════════════════════════════════════

doJumpscare = function()
	if jumpscareActive or not nightmare then return end
	jumpscareActive = true

	playSnd(SND.jumpscare, 3)
	playSnd(SND.growl, 2.5)
	local hs = playSnd(SND.heartbeat, 2, true)

	local nmModel = nightmare.model
	local maw = nightmare.data.maw

	-- ══ CAMÉRA ARRACHÉE : la caméra est tirée vers la gueule ══
	camera.CameraType = Enum.CameraType.Scriptable
	local startCF = camera.CFrame

	local gui = player.PlayerGui:FindFirstChild("DoeyEventGui")
	local jsF
	if gui then
		jsF = Instance.new("Frame")
		jsF.Size = UDim2.new(1,0,1,0)
		jsF.BackgroundColor3 = Color3.new(0,0,0)
		jsF.BackgroundTransparency = 1
		jsF.ZIndex = 100; jsF.Parent = gui
	end

	task.spawn(function()
		-- Phase 1 : la caméra fonce vers la gueule (0.5s) avec tremblement violent
		local dur = 0.5
		local t0 = tick()
		while tick() - t0 < dur do
			if not maw or not maw.Parent then break end
			local a = (tick() - t0) / dur
			local targetCF = CFrame.lookAt(
				maw.Position - maw.CFrame.LookVector * (8 - a * 5.5),
				maw.Position)
			local shake = CFrame.Angles(
				math.rad(math.random(-30, 30)/10) * a,
				math.rad(math.random(-30, 30)/10) * a, 0)
			camera.CFrame = startCF:Lerp(targetCF, a * a) * shake
			task.wait()
		end

		-- Phase 2 : face à la gueule, les mâchoires se referment (1.2s)
		local t1 = tick()
		while tick() - t1 < 1.2 do
			if not maw or not maw.Parent then break end
			local a = (tick() - t1) / 1.2
			camera.CFrame = CFrame.lookAt(
				maw.Position - maw.CFrame.LookVector * (2.5 - a * 1.8),
				maw.Position)
				* CFrame.Angles(math.rad(math.random(-15,15)/10), math.rad(math.random(-15,15)/10), math.rad(math.random(-20,20)/10))
			if jsF then
				jsF.BackgroundTransparency = math.max(0, 1 - a * 1.4)
			end
			task.wait()
		end

		-- Phase 3 : ÉCRAN NOIR + texte
		if jsF then
			jsF.BackgroundTransparency = 0
			local nameL = Instance.new("TextLabel")
			nameL.Size = UDim2.new(0.9, 0, 0.15, 0)
			nameL.Position = UDim2.new(0.05, 0, 0.4, 0)
			nameL.BackgroundTransparency = 1
			nameL.Text = "DOEY THE DOUGHMAN"
			nameL.TextColor3 = COLORS.nmOrange
			nameL.TextScaled = true; nameL.Font = Enum.Font.GothamBold
			nameL.TextStrokeTransparency = 0
			nameL.TextStrokeColor3 = Color3.fromRGB(60, 20, 0)
			nameL.ZIndex = 106; nameL.Parent = jsF

			local subL = Instance.new("TextLabel")
			subL.Size = UDim2.new(0.5, 0, 0.05, 0)
			subL.Position = UDim2.new(0.25, 0, 0.58, 0)
			subL.BackgroundTransparency = 1
			subL.Text = "T U   A S   B R I S É   S A   F A M I L L E"
			subL.TextColor3 = Color3.fromRGB(200, 100, 60)
			subL.TextScaled = true; subL.Font = Enum.Font.Code
			subL.ZIndex = 106; subL.Parent = jsF
		end

		task.wait(2)
		pcall(function() hs:Stop(); hs:Destroy() end)
		camera.CameraType = Enum.CameraType.Custom
		if jsF then jsF:Destroy() end
		pcall(function() humanoid.Health = 0 end)
		jumpscareActive = false
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- MÉCANIQUE DE COMBAT : Azote gobée + Scie = 1 tranche. 2 tranches = mort
-- ═══════════════════════════════════════════════════════════════════

local function freezeNightmare()
	local nmModel, nmRig, nmData = nightmare.model, nightmare.rig, nightmare.data
	nmData.state = "FROZEN"
	nmData.frozenUntil = tick() + FREEZE_TIME
	doeyFrozen = true

	playSnd(SND.electric, 2)
	playSnd(SND.powerDown, 1.5)

	-- Tout le corps devient glacé
	nmData.iceParts = {}
	for _, p in pairs(nmModel:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.9 then
			table.insert(nmData.iceParts, {part = p, color = p.Color, mat = p.Material})
			TweenService:Create(p, TweenInfo.new(0.6), {Color = COLORS.iceBlue}):Play()
			task.delay(0.6, function() pcall(function() p.Material = Enum.Material.Ice end) end)
		end
	end

	-- Brume de gel
	local frost = Instance.new("Part")
	frost.Size = Vector3.new(1,1,1); frost.Transparency = 1
	frost.Anchored = true; frost.CanCollide = false
	frost.Position = nmModel.PrimaryPart.Position
	frost.Name = "DD_Frost"; frost.Parent = workspace
	local fpe = Instance.new("ParticleEmitter")
	fpe.Color = ColorSequence.new(COLORS.iceBlue, Color3.new(1,1,1))
	fpe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 6)})
	fpe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)})
	fpe.Lifetime = NumberRange.new(1.5, 3); fpe.Rate = 50
	fpe.Speed = NumberRange.new(2, 6); fpe.SpreadAngle = Vector2.new(180, 180)
	fpe.LightEmission = 0.6; fpe.Texture = "rbxassetid://241685484"
	fpe.Parent = frost
	task.delay(1.5, function() fpe.Enabled = false end)
	Debris:AddItem(frost, 5)

	speak(nmData.maw, "🧊 GELÉ ! (" .. sliceCount .. "/" .. SLICES_TO_KILL .. " tranches)", COLORS.iceBlue, 4)

	-- Dégel après FREEZE_TIME (si pas encore mort)
	task.delay(FREEZE_TIME, function()
		if not eventActive or not nightmare or nightmare.data.state == "DYING" then return end
		local d = nightmare.data
		if d.state == "FROZEN" then
			d.state = "CHASE"
			doeyFrozen = false
			doeyHasNitro = false
			playSnd(SND.growl, 2)
			for _, ice in ipairs(d.iceParts) do
				if ice.part.Parent then
					TweenService:Create(ice.part, TweenInfo.new(0.8), {Color = ice.color}):Play()
					task.delay(0.8, function() pcall(function() ice.part.Material = ice.mat end) end)
				end
			end
			speak(d.maw, "🔥 GRRRAAAAH !! ENCORE TOI !", COLORS.nmEye, 3)
		end
	end)
end

sliceHit = function()
	sliceCount = sliceCount + 1
	playSnd(SND.hit, 2.5)
	playSnd(SND.explode, 1.5)

	local nmModel, nmData = nightmare.model, nightmare.data
	doeyHasNitro = false

	-- Morceaux de pâte gelée tranchés
	local pos = nmModel.PrimaryPart.Position
	for i = 1, 18 do
		local chunk = Instance.new("Part")
		chunk.Name = "DD_SliceChunk"..i
		chunk.Size = Vector3.new(math.random(5,14)/10, math.random(5,14)/10, math.random(5,14)/10)
		chunk.Color = math.random() > 0.4 and COLORS.iceBlue or COLORS.nmOrange
		chunk.Material = Enum.Material.Ice
		chunk.Shape = Enum.PartType.Ball
		chunk.Anchored = false; chunk.CanCollide = true
		chunk.CFrame = CFrame.new(pos) * CFrame.new(math.random(-3,3), math.random(-2,3), math.random(-3,3))
		chunk.Velocity = Vector3.new(math.random(-35,35), math.random(15,45), math.random(-35,35))
		chunk.Parent = workspace
		Debris:AddItem(chunk, 4)
	end

	-- MàJ GUI
	local gui = player.PlayerGui:FindFirstChild("DoeyEventGui")
	if gui then
		local objLabel = gui:FindFirstChild("ObjectiveLabel", true)
		if objLabel then
			objLabel.Text = "🪚 TRANCHES : " .. sliceCount .. " / " .. SLICES_TO_KILL ..
				(sliceCount < SLICES_TO_KILL and " — Refais-lui gober de l'azote !" or "")
		end
	end

	if sliceCount >= SLICES_TO_KILL then
		nightmareDeath()
	else
		freezeNightmare()
		-- Respawn d'une nouvelle bouteille pour le prochain cycle
		task.delay(3, function()
			if eventActive and phase == "NIGHTMARE" then spawnNitroBottle() end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- MORT DU NIGHTMARE — gelé, fissuré, brisé en mille morceaux
-- ═══════════════════════════════════════════════════════════════════

nightmareDeath = function()
	local nmModel, nmRig, nmData = nightmare.model, nightmare.rig, nightmare.data
	nmData.state = "DYING"

	if nmData.chaseSound then
		pcall(function() nmData.chaseSound:Stop(); nmData.chaseSound:Destroy() end)
	end

	playSnd(SND.powerDown, 2)
	playSnd(SND.electric, 2)

	task.spawn(function()
		-- Gel complet
		for _, p in pairs(nmModel:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 0.9 then
				TweenService:Create(p, TweenInfo.new(1), {Color = COLORS.iceBlue}):Play()
				pcall(function() p.Material = Enum.Material.Ice end)
			end
		end

		speak(nmData.maw, "💔 D...oey... voulait juste... des amis...", COLORS.iceBlue, 4)
		task.wait(2.5)
		if not nmModel.Parent then return end

		-- Fissures sonores
		for i = 1, 3 do
			playSnd(SND.hit, 1.5)
			-- Tremblement
			local origCF = nmModel.PrimaryPart.CFrame
			for j = 1, 6 do
				nmModel:PivotTo(origCF * CFrame.new(math.random(-10,10)/100, 0, math.random(-10,10)/100))
				task.wait(0.05)
			end
			task.wait(0.4)
		end

		-- EXPLOSION FINALE en morceaux de glace
		playSnd(SND.explode, 3.5)
		local pos = nmModel.PrimaryPart.Position

		for i = 1, 45 do
			local shard = Instance.new("Part")
			shard.Name = "DD_IceShard"..i
			shard.Size = Vector3.new(math.random(3,16)/10, math.random(3,16)/10, math.random(3,16)/10)
			shard.Color = COLORS.iceBlue
			shard.Material = Enum.Material.Ice
			shard.Transparency = 0.2
			shard.Anchored = false; shard.CanCollide = true
			shard.CFrame = CFrame.new(pos) * CFrame.new(math.random(-4,4), math.random(-3,4), math.random(-4,4))
			shard.Velocity = Vector3.new(math.random(-55,55), math.random(25,70), math.random(-55,55))
			shard.Parent = workspace
			Debris:AddItem(shard, 5)
		end

		local burst = Instance.new("Part")
		burst.Size = Vector3.new(1,1,1); burst.Transparency = 1
		burst.Anchored = true; burst.CanCollide = false
		burst.Position = pos; burst.Name = "DD_Burst"; burst.Parent = workspace
		local bpe = Instance.new("ParticleEmitter")
		bpe.Color = ColorSequence.new(Color3.new(1,1,1), COLORS.iceBlue)
		bpe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 12)})
		bpe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
		bpe.Lifetime = NumberRange.new(1, 2.5); bpe.Rate = 250
		bpe.Speed = NumberRange.new(15, 45); bpe.SpreadAngle = Vector2.new(180, 180)
		bpe.LightEmission = 1; bpe.Texture = "rbxassetid://241685484"
		bpe.Parent = burst
		task.delay(0.5, function() bpe.Enabled = false end)
		Debris:AddItem(burst, 4)

		nmModel:Destroy()
		nightmare = nil

		task.wait(1.5)
		stopEvent(true)
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- IA NIGHTMARE — poursuite, gober l'azote, se faire trancher par la scie
-- ═══════════════════════════════════════════════════════════════════

local function setupNightmareAI()
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not eventActive or phase ~= "NIGHTMARE" then return end
		if not nightmare or not nightmare.model.Parent then return end
		if not rootPart or not rootPart.Parent then return end

		local nmModel, nmRig, nmData = nightmare.model, nightmare.rig, nightmare.data
		if nmData.state == "DYING" then return end

		local now = tick()
		nmData.animTimer = nmData.animTimer + dt
		local nmPos = nmModel.PrimaryPart.Position
		local toPlayer = rootPart.Position - nmPos
		local horiz = Vector3.new(toPlayer.X, 0, toPlayer.Z)
		local dist = horiz.Magnitude

		-- ══ GELÉ ══
		if nmData.state == "FROZEN" then
			pcall(function() animNightmare(nmRig, nmData.animTimer, false, "FROZEN") end)

			-- ⭐ Pendant qu'il est gelé + qu'il a gobé l'azote : la SCIE peut le trancher
			-- (mécanique : gelé = vulnérable, il faut l'avoir attiré près de la scie)
			if sawBlade and sawBlade.Parent then
				local sawDist = (sawBlade.Position - nmPos).Magnitude
				if sawDist < SAW_RANGE then
					-- Tranché automatiquement si gelé sous la scie... déjà géré par sliceHit avant le gel
				end
			end
			return
		end

		-- ══ VÉRIF BOUTEILLE D'AZOTE : s'il passe dessus, il la GOBE ══
		if not doeyHasNitro then
			for _, b in ipairs(nitroBottles) do
				if not b.consumed and b.model.Parent then
					local bDist = (b.body.Position - nmPos).Magnitude
					if bDist < GOBBLE_RANGE then
						b.consumed = true
						doeyHasNitro = true
						playSnd(SND.pickup, 2)
						playSnd(SND.growl, 1.5)

						-- Animation de gobage : la bouteille vole vers la gueule
						task.spawn(function()
							local body = b.body
							for _, p in pairs(b.model:GetDescendants()) do
								if p:IsA("BasePart") and p ~= body then p.Transparency = 1 end
								if p:IsA("Highlight") or p:IsA("BillboardGui") then p:Destroy() end
							end
							local t0 = tick()
							local startP = body.Position
							while tick() - t0 < 0.6 and nmData.maw.Parent do
								local a = (tick() - t0) / 0.6
								body.Position = startP:Lerp(nmData.maw.Position, a)
								body.Size = Vector3.new(3, 1.2, 1.2) * (1 - a * 0.7)
								task.wait()
							end
							b.model:Destroy()
						end)

						speak(nmData.maw, "😈 GLOUPS ! ... ❄ Grr... j'ai froid...", COLORS.nitroCyan, 4)

						-- Vapeur froide qui sort de sa gueule
						local coldPe = Instance.new("ParticleEmitter")
						coldPe.Name = "DD_ColdBreath"
						coldPe.Color = ColorSequence.new(COLORS.iceBlue, Color3.new(1,1,1))
						coldPe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 3)})
						coldPe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)})
						coldPe.Lifetime = NumberRange.new(0.8, 1.5); coldPe.Rate = 25
						coldPe.Speed = NumberRange.new(3, 8); coldPe.SpreadAngle = Vector2.new(25, 25)
						coldPe.Texture = "rbxassetid://241685484"
						coldPe.Parent = nmData.maw

						-- MàJ GUI
						local gui = player.PlayerGui:FindFirstChild("DoeyEventGui")
						if gui then
							local objLabel = gui:FindFirstChild("ObjectiveLabel", true)
							if objLabel then
								objLabel.Text = "🪚 IL A GOBÉ L'AZOTE ! Attire-le vers la SCIE de la grue !"
								objLabel.TextColor3 = COLORS.neonRed
							end
						end
						break
					end
				end
			end
		end

		-- ══ VÉRIF SCIE : s'il a l'azote et touche la scie → TRANCHE ══
		if doeyHasNitro and sawBlade and sawBlade.Parent then
			local sawDist = (sawBlade.Position - nmPos).Magnitude
			if sawDist < SAW_RANGE then
				sliceHit()
				return
			end
		end

		-- ══ POURSUITE ══
		local isMoving = false
		if dist > ATTACK_RANGE then
			if now - nmData.lastTPTime >= TP_INTERVAL then
				nmData.lastTPTime = now
				local step = doeyHasNitro and NIGHTMARE_STEP_NITRO or NIGHTMARE_STEP
				local stepDist = math.min(step, dist - ATTACK_RANGE + 1)
				local moveDir = horiz.Unit
				local newPos = nmPos + moveDir * stepDist
				local g = findGround(newPos.X, newPos.Z)
				newPos = Vector3.new(newPos.X, g.Y + 5.5, newPos.Z)
				nmModel:PivotTo(CFrame.lookAt(newPos, Vector3.new(rootPart.Position.X, newPos.Y, rootPart.Position.Z)))
				if math.random() > 0.5 then playSnd(SND.footstep, 0.8) end
			end
			isMoving = true
		end

		pcall(function() animNightmare(nmRig, nmData.animTimer, isMoving, "CHASE") end)

		-- ══ ATTAQUE → JUMPSCARE ══
		if dist <= ATTACK_RANGE and not jumpscareActive then
			doJumpscare()
		end
	end)
	table.insert(eventConnections, conn)
end

-- ═══════════════════════════════════════════════════════════════════
-- DÉMARRER / ARRÊTER L'ÉVÉNEMENT
-- ═══════════════════════════════════════════════════════════════════

startEvent = function()
	if eventActive then return end
	eventActive = true
	phase = "FRIENDLY"
	sliceCount = 0
	doeyHasNitro = false
	doeyFrozen = false
	critters = {}
	nitroBottles = {}

	activateAtmosphere(false)
	local amb = snd(SND.ambient, 0.3, true); amb:Play()

	-- Arme du joueur (la tentation...)
	task.wait(0.5)
	createWeapon()

	-- Construire la grue (déjà présente sur la map, mystérieuse)
	buildCrane()

	-- ══ SPAWN DE DOEY devant le joueur ══
	local spawnDist = 35
	local look = camera.CFrame.LookVector
	local spawnXZ = rootPart.Position + Vector3.new(look.X, 0, look.Z).Unit * spawnDist
	local g = findGround(spawnXZ.X, spawnXZ.Z)
	local doeyPos = Vector3.new(spawnXZ.X, g.Y + 4.2, spawnXZ.Z)

	local model, rig, data = buildDoey()
	model:PivotTo(CFrame.lookAt(doeyPos, Vector3.new(rootPart.Position.X, doeyPos.Y, rootPart.Position.Z)))
	model.Parent = workspace
	doey = {model = model, rig = rig, data = data}

	playSnd(SND.wakeUp, 1)

	-- ══ SPAWN DES SMILING CRITTERS autour de lui ══
	for i, info in ipairs(CRITTER_COLORS) do
		local crModel, crRig, crData = buildCritter(info)
		local ang = math.rad(i * 80 + 40)
		local crPos = doeyPos + Vector3.new(math.cos(ang) * 6, -2.5, math.sin(ang) * 6)
		local cg = findGround(crPos.X, crPos.Z)
		crModel:PivotTo(CFrame.new(Vector3.new(crPos.X, cg.Y + 1.6, crPos.Z)))
		crModel.Parent = workspace
		table.insert(critters, {model = crModel, rig = crRig, data = crData})
	end

	-- IA
	setupFriendlyAI()
	setupDoeyPrompts()
	setupNightmareAI()

	-- Coucou d'introduction !
	task.delay(1.5, function()
		if eventActive and phase == "FRIENDLY" and doey then
			doey.data.state = "WAVE"
			doey.data.stateUntil = tick() + 4
			doey.data.animTimer = 0
			doey.data.waveCooldown = tick() + 15
			speak(doey.data.head, "👋 Coucou ! Moi c'est DOEY ! Voici mes amis les Smiling Critters !", COLORS.doughBlue, 5)
		end
	end)

	-- Avertissement subtil
	task.delay(8, function()
		if eventActive and phase == "FRIENDLY" and doey then
			speak(doey.data.head, "🥺 Prends soin de mes petits amis, d'accord ? Ils sont fragiles...", COLORS.doughOrange, 5)
		end
	end)

	-- MàJ GUI
	local gui = player.PlayerGui:FindFirstChild("DoeyEventGui")
	if gui then
		local objLabel = gui:FindFirstChild("ObjectiveLabel", true)
		if objLabel then
			objLabel.Text = "😊 Doey est gentil... tant que ses Smiling Critters vont bien. [E] pour interagir"
			objLabel.TextColor3 = COLORS.doughBlue
		end
	end
end

stopEvent = function(victory)
	eventActive = false
	phase = "NONE"

	for _, c in pairs(eventConnections) do pcall(function() c:Disconnect() end) end
	eventConnections = {}

	deactivateAtmosphere(); cleanSounds(); removeWeapon()

	if camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
	end

	if doey then pcall(function() doey.model:Destroy() end); doey = nil end
	if nightmare then
		if nightmare.data.chaseSound then
			pcall(function() nightmare.data.chaseSound:Stop(); nightmare.data.chaseSound:Destroy() end)
		end
		pcall(function() nightmare.model:Destroy() end); nightmare = nil
	end
	for _, cr in ipairs(critters) do pcall(function() cr.model:Destroy() end) end
	critters = {}
	for _, b in ipairs(nitroBottles) do pcall(function() b.model:Destroy() end) end
	nitroBottles = {}
	if craneModel then pcall(function() craneModel:Destroy() end); craneModel = nil end
	sawBlade = nil

	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:sub(1,3) == "DD_" then v:Destroy() end
	end

	jumpscareActive = false; doeyHasNitro = false; doeyFrozen = false; sliceCount = 0

	-- Écran de victoire
	local gui = player.PlayerGui:FindFirstChild("DoeyEventGui")
	if gui and victory then
		local vf = Instance.new("Frame")
		vf.Size = UDim2.new(1,0,1,0); vf.BackgroundColor3 = Color3.new(0,0,0)
		vf.BackgroundTransparency = 0.25; vf.ZIndex = 90; vf.Parent = gui

		local vt = Instance.new("TextLabel")
		vt.Size = UDim2.new(0.8, 0, 0.1, 0)
		vt.Position = UDim2.new(0.1, 0, 0.3, 0)
		vt.BackgroundTransparency = 1
		vt.Text = "🧊 NIGHTMARE DOEY VAINCU 🧊"
		vt.TextColor3 = COLORS.iceBlue; vt.TextScaled = true
		vt.Font = Enum.Font.GothamBold; vt.TextStrokeTransparency = 0
		vt.TextStrokeColor3 = Color3.fromRGB(0, 60, 90)
		vt.ZIndex = 91; vt.Parent = vf

		local vt2 = Instance.new("TextLabel")
		vt2.Size = UDim2.new(0.6, 0, 0.07, 0)
		vt2.Position = UDim2.new(0.2, 0, 0.45, 0)
		vt2.BackgroundTransparency = 1
		vt2.Text = "Azote + Scie = 2 tranches. Bien joué."
		vt2.TextColor3 = COLORS.green; vt2.TextScaled = true
		vt2.Font = Enum.Font.GothamBold; vt2.TextStrokeTransparency = 0
		vt2.ZIndex = 91; vt2.Parent = vf

		local vt3 = Instance.new("TextLabel")
		vt3.Size = UDim2.new(0.5, 0, 0.05, 0)
		vt3.Position = UDim2.new(0.25, 0, 0.55, 0)
		vt3.BackgroundTransparency = 1
		vt3.Text = "\"Doey voulait juste des amis...\""
		vt3.TextColor3 = COLORS.dim; vt3.TextScaled = true
		vt3.Font = Enum.Font.Code; vt3.ZIndex = 91; vt3.Parent = vf

		playSnd(SND.victory, 2)

		task.delay(7, function()
			TweenService:Create(vf, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
			TweenService:Create(vt, TweenInfo.new(2), {TextTransparency = 1}):Play()
			TweenService:Create(vt2, TweenInfo.new(2), {TextTransparency = 1}):Play()
			TweenService:Create(vt3, TweenInfo.new(2), {TextTransparency = 1}):Play()
			task.wait(2.5); pcall(function() vf:Destroy() end)
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- GUI PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════

local sg = Instance.new("ScreenGui"); sg.Name = "DoeyEventGui"
sg.ResetOnSpawn = false; sg.Parent = player.PlayerGui

-- Bouton toggle
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 52, 0, 52)
toggleBtn.Position = UDim2.new(0, 12, 0.5, -26)
toggleBtn.BackgroundColor3 = COLORS.accent
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "🍞"; toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 28; toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.ZIndex = 10; toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

-- Barre d'objectif en haut
local objBar = Instance.new("Frame")
objBar.Size = UDim2.new(0.6, 0, 0, 42)
objBar.Position = UDim2.new(0.2, 0, 0, 8)
objBar.BackgroundColor3 = COLORS.card
objBar.BackgroundTransparency = 0.25
objBar.BorderSizePixel = 0; objBar.ZIndex = 8; objBar.Parent = sg
Instance.new("UICorner", objBar).CornerRadius = UDim.new(0, 10)
local objStroke = Instance.new("UIStroke", objBar)
objStroke.Color = COLORS.accent; objStroke.Thickness = 1.5

local objLabel = Instance.new("TextLabel")
objLabel.Name = "ObjectiveLabel"
objLabel.Size = UDim2.new(1, -16, 1, -6)
objLabel.Position = UDim2.new(0, 8, 0, 3)
objLabel.BackgroundTransparency = 1
objLabel.Text = "🍞 Appuie sur DÉMARRER pour rencontrer Doey..."
objLabel.TextColor3 = COLORS.text
objLabel.TextScaled = true; objLabel.TextWrapped = true
objLabel.Font = Enum.Font.GothamBold
objLabel.ZIndex = 9; objLabel.Parent = objBar

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 430)
mainFrame.Position = UDim2.new(0, 72, 0.5, -215)
mainFrame.BackgroundColor3 = COLORS.bg; mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 5; mainFrame.Visible = false; mainFrame.Parent = sg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = COLORS.accent
mainStroke.Thickness = 2; mainStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 55)
header.BackgroundColor3 = Color3.fromRGB(25, 15, 8)
header.BorderSizePixel = 0; header.ZIndex = 6; header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local hTitle = Instance.new("TextLabel")
hTitle.Size = UDim2.new(1, -60, 1, 0)
hTitle.Position = UDim2.new(0, 14, 0, 0)
hTitle.BackgroundTransparency = 1
hTitle.Text = "🍞 DOEY THE DOUGHMAN v1.0"
hTitle.TextColor3 = COLORS.accent; hTitle.TextSize = 15
hTitle.Font = Enum.Font.GothamBold
hTitle.TextXAlignment = Enum.TextXAlignment.Left
hTitle.ZIndex = 7; hTitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -42, 0.5, -16)
closeBtn.BackgroundColor3 = COLORS.doughRed
closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 14; closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 7; closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Contenu scrollable
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -65)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = COLORS.accent
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 6; scroll.Parent = mainFrame
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 6)

-- Description
local descF = Instance.new("Frame")
descF.Size = UDim2.new(1, 0, 0, 175)
descF.BackgroundColor3 = COLORS.card; descF.BorderSizePixel = 0
descF.LayoutOrder = 1; descF.ZIndex = 7; descF.Parent = scroll
Instance.new("UICorner", descF).CornerRadius = UDim.new(0, 8)

local descT = Instance.new("TextLabel")
descT.Size = UDim2.new(1, -12, 1, -6)
descT.Position = UDim2.new(0, 6, 0, 3)
descT.BackgroundTransparency = 1; descT.TextWrapped = true
descT.Text = "🍞 DOEY se balade avec ses Smiling Critters\n👋 Il te fait coucou et a plein d'interactions [E]\n🎵 Danse, câlins, dialogues...\n\n⚠️ MAIS NE TOUCHE PAS À SES CRITTERS !\n💀 Si tu en tues un → Doey fond dans le sol...\n😈 ...et ressort en NIGHTMARE DOEY (6 bras !)\n📷 S'il t'attrape → jumpscare caméra + MORT\n\n🧊 POUR LE BATTRE (comme dans le vrai jeu) :\n1. Attire-le sur une BOUTEILLE D'AZOTE ❄ (il la gobe)\n2. Attire-le vers la SCIE de la grue 🪚\n3. La scie le tranche → il gèle !\n4. Répète : 2 TRANCHES = victoire !"
descT.TextColor3 = COLORS.text; descT.TextSize = 9
descT.Font = Enum.Font.Gotham
descT.TextXAlignment = Enum.TextXAlignment.Left
descT.TextYAlignment = Enum.TextYAlignment.Top
descT.ZIndex = 8; descT.Parent = descF

-- Bouton Start
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, 0, 0, 48)
startBtn.BackgroundColor3 = COLORS.accent
startBtn.Text = "🍞 RENCONTRER DOEY"
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.TextSize = 14; startBtn.Font = Enum.Font.GothamBold
startBtn.LayoutOrder = 2; startBtn.ZIndex = 7; startBtn.Parent = scroll
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

-- Bouton "provoquer" (raccourci pour tester la rage)
local rageBtn = Instance.new("TextButton")
rageBtn.Size = UDim2.new(1, 0, 0, 38)
rageBtn.BackgroundColor3 = Color3.fromRGB(90, 20, 20)
rageBtn.Text = "😈 [TEST] Déclencher la rage direct"
rageBtn.TextColor3 = Color3.new(1,1,1)
rageBtn.TextSize = 11; rageBtn.Font = Enum.Font.GothamBold
rageBtn.LayoutOrder = 3; rageBtn.ZIndex = 7; rageBtn.Parent = scroll
Instance.new("UICorner", rageBtn).CornerRadius = UDim.new(0, 8)

-- Bouton Stop
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, 0, 0, 38)
stopBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
stopBtn.Text = "⏹ ARRÊTER L'ÉVÉNEMENT"
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.TextSize = 12; stopBtn.Font = Enum.Font.GothamBold
stopBtn.LayoutOrder = 4; stopBtn.ZIndex = 7; stopBtn.Parent = scroll
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

-- Info
local infoF = Instance.new("Frame")
infoF.Size = UDim2.new(1, 0, 0, 40)
infoF.BackgroundColor3 = COLORS.card; infoF.BorderSizePixel = 0
infoF.LayoutOrder = 5; infoF.ZIndex = 7; infoF.Parent = scroll
Instance.new("UICorner", infoF).CornerRadius = UDim.new(0, 8)

local infoT = Instance.new("TextLabel")
infoT.Size = UDim2.new(1, -12, 1, -6)
infoT.Position = UDim2.new(0, 6, 0, 3)
infoT.BackgroundTransparency = 1; infoT.TextWrapped = true
infoT.Text = "⌨️ [N] Menu | 🖱️ Clic = Frapper (batte) | [E] Interagir\n🍞 Sois gentil avec les critters... ou pas 😏"
infoT.TextColor3 = COLORS.dim; infoT.TextSize = 9
infoT.Font = Enum.Font.Gotham
infoT.TextXAlignment = Enum.TextXAlignment.Left
infoT.ZIndex = 8; infoT.Parent = infoF

-- ══════════════════════════════
-- ÉVÉNEMENTS GUI
-- ══════════════════════════════
startBtn.MouseButton1Click:Connect(function()
	if eventActive then return end
	startBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 20)
	startBtn.Text = "🍞 DOEY EST LÀ..."
	task.spawn(startEvent)
end)

rageBtn.MouseButton1Click:Connect(function()
	if eventActive and phase == "FRIENDLY" and #critters > 0 then
		for _, cr in ipairs(critters) do
			if cr.data.alive then killCritter(cr); break end
		end
	end
end)

stopBtn.MouseButton1Click:Connect(function()
	if eventActive then
		stopEvent(false)
		startBtn.BackgroundColor3 = COLORS.accent
		startBtn.Text = "🍞 RENCONTRER DOEY"
	end
end)

toggleBtn.MouseButton1Click:Connect(function()
	guiOpen = not guiOpen
	mainFrame.Visible = guiOpen
	if guiOpen then
		mainFrame.Position = UDim2.new(0, 52, 0.5, -215)
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = UDim2.new(0, 72, 0.5, -215)
		}):Play()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	guiOpen = false
	TweenService:Create(mainFrame, TweenInfo.new(0.2), {
		Position = UDim2.new(0, 52, 0.5, -215)
	}):Play()
	task.wait(0.2); mainFrame.Visible = false
end)

-- ═══════════════════════════════════════════════════════════════════
-- INPUT
-- ═══════════════════════════════════════════════════════════════════

UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.N then
		guiOpen = not guiOpen; mainFrame.Visible = guiOpen
	end
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		if not eventActive or not playerHasWeapon then return end
		task.spawn(swingWeapon)
	end
end)

-- Pulse du bouton
RunService.RenderStepped:Connect(function()
	local t = tick()
	local pulse = math.sin(t * 3) * 0.15 + 0.85
	if eventActive then
		if phase == "NIGHTMARE" then
			toggleBtn.BackgroundColor3 = Color3.fromRGB(math.floor(235 * pulse), math.floor(60 * pulse), 20)
		else
			toggleBtn.BackgroundColor3 = Color3.fromRGB(math.floor(255 * pulse), math.floor(150 * pulse), 40)
		end
	else
		toggleBtn.BackgroundColor3 = COLORS.accent
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- RESPAWN JOUEUR
-- ═══════════════════════════════════════════════════════════════════

player.CharacterAdded:Connect(function(nc)
	character = nc
	humanoid = nc:WaitForChild("Humanoid")
	rootPart = nc:WaitForChild("HumanoidRootPart")
	jumpscareActive = false
	camera.CameraType = Enum.CameraType.Custom
	if eventActive then
		task.wait(2)
		if eventActive then
			removeWeapon()
			createWeapon()
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- NOTIFICATION DE LANCEMENT
-- ═══════════════════════════════════════════════════════════════════

task.spawn(function()
	task.wait(1)
	local n = Instance.new("Frame")
	n.Size = UDim2.new(0, 440, 0, 65)
	n.Position = UDim2.new(0.5, -220, 0, -75)
	n.BackgroundColor3 = COLORS.card; n.BorderSizePixel = 0
	n.ZIndex = 50; n.Parent = sg
	Instance.new("UICorner", n).CornerRadius = UDim.new(0, 12)
	local nStroke = Instance.new("UIStroke"); nStroke.Color = COLORS.accent; nStroke.Parent = n

	local nt = Instance.new("TextLabel")
	nt.Size = UDim2.new(1, -16, 0, 26)
	nt.Position = UDim2.new(0, 12, 0, 5)
	nt.BackgroundTransparency = 1
	nt.Text = "🍞 DOEY THE DOUGHMAN — Nightmare Event v1.0"
	nt.TextColor3 = COLORS.accent; nt.TextSize = 14
	nt.Font = Enum.Font.GothamBold
	nt.TextXAlignment = Enum.TextXAlignment.Left
	nt.ZIndex = 51; nt.Parent = n

	local ns = Instance.new("TextLabel")
	ns.Size = UDim2.new(1, -16, 0, 22)
	ns.Position = UDim2.new(0, 12, 0, 32)
	ns.BackgroundTransparency = 1
	ns.Text = "[N] Menu | Smiling Critters 🐾 | Azote ❄ + Grue-Scie 🪚 = 2 tranches"
	ns.TextColor3 = COLORS.dim; ns.TextSize = 9
	ns.Font = Enum.Font.Gotham
	ns.TextXAlignment = Enum.TextXAlignment.Left
	ns.ZIndex = 51; ns.Parent = n

	TweenService:Create(n, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, -220, 0, 12)
	}):Play()
	task.wait(6)
	TweenService:Create(n, TweenInfo.new(0.3), {
		Position = UDim2.new(0.5, -220, 0, -75)
	}):Play()
	task.wait(0.4); n:Destroy()
end)

-- ═══════════════════════════════════════════════════════════════════
-- FIN DU SCRIPT
-- ═══════════════════════════════════════════════════════════════════

print("═══════════════════════════════════════")
print(" 🍞 DOEY THE DOUGHMAN — Nightmare Event v1.0")
print(" ✅ Doey en pâte à modeler (tête turquoise + chapeau melon)")
print(" ✅ Taches jaunes/orange/rouges style plasticine")
print(" ✅ 4 Smiling Critters qui le suivent en marchant")
print(" ✅ Coucou 👋 + danse + câlins + dialogues [E]")
print(" ✅ Tuer un critter → rage + fonte dans le sol (belle anim)")
print(" ✅ Éruption en NIGHTMARE DOEY : 6 bras, gueule pleine d'yeux")
print(" ✅ Jumpscare : caméra arrachée vers la gueule + mort")
print(" ✅ Bouteilles d'azote ❄ spawn aléatoire (glow à travers murs)")
print(" ✅ Grue avec scie circulaire rotative 🪚")
print(" ✅ Azote gobée + Scie = tranche + gel (2 coups = victoire)")
print(" ✅ Explosion finale en éclats de glace")
print(" ⌨️ [N] Menu | [E] Interagir | Clic = Frapper")
print("═══════════════════════════════════════")
