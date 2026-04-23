-- ═══════════════════════════════════════════════════════════════════
-- COOLKID CATNAP — NIGHTMARE EVENT v3.0
-- Fumée réaliste + TP progressif + Structure jolie + GUI clavier
-- Code aléatoire + Papier indice sur table + Respawn fix
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

-- Nettoyage
for _, v in pairs(player.PlayerGui:GetChildren()) do
	if v.Name == "CoolKidCatNap" then v:Destroy() end
end
for _, v in pairs(Lighting:GetChildren()) do
	if v.Name:sub(1,3) == "CN" then v:Destroy() end
end
for _, v in pairs(workspace:GetChildren()) do
	if v.Name:sub(1,3) == "CN" then v:Destroy() end
end

-- ═══════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════
local eventActive = false
local catNapModel = nil
local catNapRig = nil
local catNapAlive = true
local catNapHP = 1
local catNapMaxHP = 1
local catNapAnimTimer = 0
local playerHasWeapon = false
local weaponModel = nil
local codeEntered = false
local jumpscareActive = false
local canSwing = true
local eventConnections = {}
local guiOpen = false
local codeGuiOpen = false
local codeInputGui = nil

local ATTACK_RANGE = 5
local WEAPON_RANGE = 200
local SWING_COOLDOWN = 0.8
local SPAWN_INTERVAL = 20
local WIN_CODE = ""

-- TP progressif
local TP_DISTANCE = 2.5
local TP_INTERVAL = 0.3
local lastTPTime = 0

-- Code aléatoire
local function generateCode()
	local code = ""
	for i = 1, 4 do
		code = code .. tostring(math.random(0, 9))
	end
	return code
end

-- ═══════════════════════════════════════
-- SONS
-- ═══════════════════════════════════════
local SND = {
	ambient = "rbxassetid://138890398994853",
	jumpscare = "rbxassetid://115483973318915",
	heartbeat = "rbxassetid://142376088",
	growl = "rbxassetid://139934330820371",
	explosion = "rbxassetid://140653132496955",
	hit = "rbxassetid://140648211829044",
	victory = "rbxassetid://120682227591051",
	breathing = "rbxassetid://139784298444442",
	codeFail = "rbxassetid://14649711205",
	weaponSwing = "rbxassetid://93806155622808",
	footstep = "rbxassetid://140668467774841",
	static = "rbxassetid://140420084015321",
	codeSuccess = "rbxassetid://140437791600159",
}

local function snd(id, vol, loop)
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol or 1; s.Looped = loop or false
	s.Name = "CN_Sound"; s.Parent = SoundService
	return s
end

local function cleanSounds()
	for _, s in pairs(SoundService:GetChildren()) do
		if s.Name == "CN_Sound" then pcall(function() s:Stop(); s:Destroy() end) end
	end
end

-- ═══════════════════════════════════════
-- COULEURS
-- ═══════════════════════════════════════
local CC = {
	bg = Color3.fromRGB(8,5,12),
	card = Color3.fromRGB(18,12,24),
	cardH = Color3.fromRGB(30,20,38),
	accent = Color3.fromRGB(150,0,200),
	accentG = Color3.fromRGB(180,30,255),
	red = Color3.fromRGB(200,0,40),
	green = Color3.fromRGB(0,200,80),
	text = Color3.fromRGB(230,230,240),
	dim = Color3.fromRGB(100,90,120),
	purple = Color3.fromRGB(100,0,180),
	darkPurp = Color3.fromRGB(40,0,60),
}

-- ═══════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════
local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0=a; w.Part1=b; w.Parent=a; return w
end

local function motor(p0, p1, name)
	local m = Instance.new("Motor6D")
	m.Name = name or (p1.Name.."_M")
	m.Part0=p0; m.Part1=p1
	m.C0 = p0.CFrame:ToObjectSpace(p1.CFrame)
	m.C1 = CFrame.new(); m.Parent=p0; return m
end

local function mp(par, name, sz, col, mat, tr)
	local p = Instance.new("Part")
	p.Name=name; p.Size=sz; p.Color=col
	p.Material=mat or Enum.Material.SmoothPlastic
	p.Transparency=tr or 0; p.CanCollide=false
	p.Anchored=false; p.Massless=true
	p.TopSurface=Enum.SurfaceType.Smooth
	p.BottomSurface=Enum.SurfaceType.Smooth
	p.Parent=par; return p
end

local function ms(par, name, sz, col, mat, tr)
	local p = mp(par,name,sz,col,mat,tr)
	p.Shape = Enum.PartType.Ball; return p
end

-- ═══════════════════════════════════════════════════════════════════
-- FUMÉE RÉALISTE
-- ═══════════════════════════════════════════════════════════════════

local smokeEmitters = {}

local function createRealisticSmoke()
	local smokeFolder = Instance.new("Folder")
	smokeFolder.Name = "CN_SmokeFolder"
	smokeFolder.Parent = workspace

	local gridSize = 8
	local spacing = 40

	for x = -gridSize, gridSize do
		for z = -gridSize, gridSize do
			local smokePart = Instance.new("Part")
			smokePart.Name = "SmokePt"
			smokePart.Size = Vector3.new(1,1,1)
			smokePart.Transparency = 1
			smokePart.Anchored = true
			smokePart.CanCollide = false
			smokePart.Position = Vector3.new(x * spacing, 5, z * spacing)
			smokePart.Parent = smokeFolder

			local pe = Instance.new("ParticleEmitter")
			pe.Name = "RedSmoke"
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
				ColorSequenceKeypoint.new(0.3, Color3.fromRGB(150, 0, 10)),
				ColorSequenceKeypoint.new(0.7, Color3.fromRGB(120, 0, 5)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0)),
			})
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 8),
				NumberSequenceKeypoint.new(0.5, 20),
				NumberSequenceKeypoint.new(1, 30),
			})
			pe.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			pe.Lifetime = NumberRange.new(6, 12)
			pe.Rate = 3
			pe.Speed = NumberRange.new(0.5, 2)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.RotSpeed = NumberRange.new(-20, 20)
			pe.Rotation = NumberRange.new(0, 360)
			pe.LightEmission = 0.4
			pe.LightInfluence = 0.2
			pe.Texture = "rbxassetid://241685484"
			pe.Parent = smokePart

			table.insert(smokeEmitters, pe)
		end
	end

	for i = 1, 25 do
		local groundSmoke = Instance.new("Part")
		groundSmoke.Name = "GroundSmoke"..i
		groundSmoke.Size = Vector3.new(1,1,1)
		groundSmoke.Transparency = 1
		groundSmoke.Anchored = true
		groundSmoke.CanCollide = false
		groundSmoke.Position = Vector3.new(
			math.random(-200, 200), 0.5, math.random(-200, 200)
		)
		groundSmoke.Parent = smokeFolder

		local pe2 = Instance.new("ParticleEmitter")
		pe2.Name = "GroundFog"
		pe2.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 0, 10)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 0)),
		})
		pe2.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 15),
			NumberSequenceKeypoint.new(0.5, 25),
			NumberSequenceKeypoint.new(1, 40),
		})
		pe2.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		})
		pe2.Lifetime = NumberRange.new(8, 15)
		pe2.Rate = 3
		pe2.Speed = NumberRange.new(0.2, 1)
		pe2.SpreadAngle = Vector2.new(180, 0)
		pe2.RotSpeed = NumberRange.new(-10, 10)
		pe2.Rotation = NumberRange.new(0, 360)
		pe2.LightEmission = 0.5
		pe2.LightInfluence = 0.1
		pe2.Texture = "rbxassetid://241685484"
		pe2.Parent = groundSmoke

		table.insert(smokeEmitters, pe2)
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "CN_Atmosphere"
	atmo.Density = 0.35
	atmo.Offset = 0.25
	atmo.Color = Color3.fromRGB(180, 30, 30)
	atmo.Decay = Color3.fromRGB(120, 0, 0)
	atmo.Glare = 0.2
	atmo.Haze = 6
	atmo.Parent = Lighting

	local ccEffect = Instance.new("ColorCorrectionEffect")
	ccEffect.Name = "CN_CC"
	ccEffect.Brightness = 0.05
	ccEffect.Contrast = 0.1
	ccEffect.Saturation = 0.3
	ccEffect.TintColor = Color3.fromRGB(255, 150, 150)
	ccEffect.Parent = Lighting

	Lighting.FogColor = Color3.fromRGB(120, 10, 10)
	Lighting.FogEnd = 350
	Lighting.FogStart = 20
	Lighting.ClockTime = 5
	Lighting.Ambient = Color3.fromRGB(60, 10, 10)
	Lighting.OutdoorAmbient = Color3.fromRGB(50, 8, 8)
	Lighting.Brightness = 1

	local sky = Instance.new("Sky")
	sky.Name = "CN_Sky"
	sky.CelestialBodiesShown = false
	sky.SkyboxBk = "rbxassetid://1012890"
	sky.SkyboxDn = "rbxassetid://1012890"
	sky.SkyboxFt = "rbxassetid://1012890"
	sky.SkyboxLf = "rbxassetid://1012890"
	sky.SkyboxRt = "rbxassetid://1012890"
	sky.SkyboxUp = "rbxassetid://1012890"
	sky.StarCount = 0
	sky.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "CN_Bloom"
	bloom.Intensity = 0.4
	bloom.Size = 30
	bloom.Threshold = 0.8
	bloom.Parent = Lighting

	return smokeFolder
end

local smokeFolder = nil
local originalLighting = {}

local function activateSmoke()
	originalLighting.FogColor = Lighting.FogColor
	originalLighting.FogEnd = Lighting.FogEnd
	originalLighting.FogStart = Lighting.FogStart
	originalLighting.ClockTime = Lighting.ClockTime
	originalLighting.Ambient = Lighting.Ambient
	originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
	originalLighting.Brightness = Lighting.Brightness

	smokeFolder = createRealisticSmoke()
end

local function deactivateSmoke()
	if smokeFolder then smokeFolder:Destroy(); smokeFolder = nil end
	smokeEmitters = {}

	Lighting.FogColor = originalLighting.FogColor or Color3.new(0.75,0.75,0.75)
	Lighting.FogEnd = originalLighting.FogEnd or 100000
	Lighting.FogStart = originalLighting.FogStart or 0
	Lighting.ClockTime = originalLighting.ClockTime or 14
	Lighting.Ambient = originalLighting.Ambient or Color3.fromRGB(128,128,128)
	Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.fromRGB(128,128,128)
	Lighting.Brightness = originalLighting.Brightness or 2

	for _, n in pairs({"CN_Atmosphere","CN_CC","CN_Sky","CN_Bloom"}) do
		local c = Lighting:FindFirstChild(n)
		if c then c:Destroy() end
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSTRUCTION DE NIGHTMARE CATNAP
-- ═══════════════════════════════════════════════════════════════════

local function buildNightmareCatNap()

	local model = Instance.new("Model")
	model.Name = "CN_CatNap"

	local rig = {}

	local skin = Color3.fromRGB(55, 60, 48)
	local dark = Color3.fromRGB(25, 25, 25)

	-- ROOT
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2,2,2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root

	------------------------------------------------
	-- BODY
	------------------------------------------------

	local torso = Instance.new("Part")
	torso.Size = Vector3.new(2,2,5)
	torso.Material = Enum.Material.Slate
	torso.Color = skin
	torso.Position = root.Position
	torso.Parent = model

	local rootMotor = Instance.new("Motor6D")
	rootMotor.Part0 = root
	rootMotor.Part1 = torso
	rootMotor.C0 = CFrame.new()
	rootMotor.C1 = CFrame.new()
	rootMotor.Parent = root
	rig.Root = rootMotor

	------------------------------------------------
	-- NECK
	------------------------------------------------

	local neck = Instance.new("Part")
	neck.Size = Vector3.new(0.8,2,0.8)
	neck.Material = Enum.Material.Slate
	neck.Color = skin
	neck.Position = torso.Position + Vector3.new(0,0,-3)
	neck.Parent = model

	local neckMotor = Instance.new("Motor6D")
	neckMotor.Part0 = torso
	neckMotor.Part1 = neck
	neckMotor.C0 = torso.CFrame:ToObjectSpace(neck.CFrame)
	neckMotor.Parent = torso
	rig.Neck = neckMotor

	------------------------------------------------
	-- HEAD
	------------------------------------------------

	local head = Instance.new("Part")
	head.Size = Vector3.new(3,1.2,2.2)
	head.Material = Enum.Material.Slate
	head.Color = skin
	head.Position = neck.Position + Vector3.new(0,-1.5,0)
	head.Parent = model

	local headMotor = Instance.new("Motor6D")
	headMotor.Part0 = neck
	headMotor.Part1 = head
	headMotor.C0 = neck.CFrame:ToObjectSpace(head.CFrame)
	headMotor.Parent = neck
	rig.HeadJoint = headMotor

	------------------------------------------------
	-- LONG JAW
	------------------------------------------------

	local jaw = Instance.new("Part")
	jaw.Size = Vector3.new(2.8,6,1)
	jaw.Material = Enum.Material.Slate
	jaw.Color = skin
	jaw.Position = head.Position + Vector3.new(0,-3,0)
	jaw.Parent = model

	local jawWeld = Instance.new("WeldConstraint")
	jawWeld.Part0 = head
	jawWeld.Part1 = jaw
	jawWeld.Parent = head

	------------------------------------------------
	-- EYES
	------------------------------------------------

	for i=-1,1,2 do
		local eye = Instance.new("Part")
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.5,0.5,0.5)
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.new(1,1,1)
		eye.Position = head.Position + Vector3.new(i*0.7,0,-1)
		eye.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = head
		weld.Part1 = eye
		weld.Parent = head
	end

	------------------------------------------------
	-- LEGS (CORRECTLY POSITIONED)
	------------------------------------------------

	local function makeLeg(name,x,z)

		local upper = Instance.new("Part")
		upper.Size = Vector3.new(0.6,4,0.6)
		upper.Material = Enum.Material.Slate
		upper.Color = skin
		upper.Position = torso.Position + Vector3.new(x,-2,z)
		upper.Parent = model

		local hip = Instance.new("Motor6D")
		hip.Part0 = torso
		hip.Part1 = upper
		hip.C0 = torso.CFrame:ToObjectSpace(upper.CFrame)
		hip.Parent = torso
		rig[name.."Hip"] = hip

		local lower = Instance.new("Part")
		lower.Size = Vector3.new(0.5,4,0.5)
		lower.Material = Enum.Material.Slate
		lower.Color = skin
		lower.Position = upper.Position + Vector3.new(0,-4,0)
		lower.Parent = model

		local knee = Instance.new("Motor6D")
		knee.Part0 = upper
		knee.Part1 = lower
		knee.C0 = upper.CFrame:ToObjectSpace(lower.CFrame)
		knee.Parent = upper
		rig[name.."Knee"] = knee

		local foot = Instance.new("Part")
		foot.Size = Vector3.new(1.2,0.3,1.5)
		foot.Material = Enum.Material.Slate
		foot.Color = skin
		foot.Position = lower.Position + Vector3.new(0,-2,0.5)
		foot.Parent = model

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = lower
		weld.Part1 = foot
		weld.Parent = lower
	end

	makeLeg("FL",-1.2,-2)
	makeLeg("FR",1.2,-2)
	makeLeg("BL",-1.2,2)
	makeLeg("BR",1.2,2)

	------------------------------------------------
	-- TAIL
	------------------------------------------------

	local last = torso
	rig.TailJoints = {}

	for i=1,6 do
		local seg = Instance.new("Part")
		seg.Size = Vector3.new(0.4,0.4,1.5)
		seg.Material = Enum.Material.Slate
		seg.Color = skin
		seg.Position = last.Position + Vector3.new(0,0,2)
		seg.Parent = model

		local m = Instance.new("Motor6D")
		m.Part0 = last
		m.Part1 = seg
		m.C0 = last.CFrame:ToObjectSpace(seg.CFrame)
		m.Parent = last

		table.insert(rig.TailJoints,m)
		last = seg
	end

	return model, rig
end
-- ═══════════════════════════════════════════════════════════════════
-- ANIMATION CATNAP
-- ═══════════════════════════════════════════════════════════════════

local function animCatNap(rig, t, isMoving)
	if isMoving then
		local speed = 6
		local cycle = t * speed
		local stepHeight = 1.2
		local stride = 0.8

		-- Balancement du corps (plus réaliste, haut/bas)
		local bob = math.abs(math.sin(cycle * 2)) * 0.4
		if rig.Root then rig.Root.Transform = CFrame.new(0, -bob, 0) end
		
		-- Animation des 4 pattes (Cross-crawl gait)
		-- FL et BR bougent ensemble, FR et BL bougent ensemble
		local function moveLeg(hip, knee, phase)
			local move = math.sin(cycle + phase)
			local up = math.max(0, math.cos(cycle + phase)) * stepHeight
			hip.Transform = CFrame.Angles(move * stride, 0, 0)
			knee.Transform = CFrame.Angles(math.rad(-20) + (-up * 0.5), 0, 0)
		end

		moveLeg(rig.FLHip, rig.FLKnee, 0)
		moveLeg(rig.BRHip, rig.BRKnee, 0)
		moveLeg(rig.FRHip, rig.FRKnee, math.pi)
		moveLeg(rig.BLHip, rig.BLKnee, math.pi)

		-- Mouvement tête et cou
		if rig.Neck then rig.Neck.Transform = CFrame.Angles(math.rad(-10) + math.sin(cycle)*0.1, 0, 0) end
		if rig.HeadJoint then rig.HeadJoint.Transform = CFrame.Angles(math.sin(cycle)*0.15, 0, 0) end
	else
		-- Animation de repos (respiration)
		local breathe = math.sin(t * 1.5) * 0.05
		if rig.Root then rig.Root.Transform = CFrame.new(0, breathe, 0) end
		if rig.FLHip then
			rig.FLHip.Transform = CFrame.Angles(math.rad(-10), 0, 0)
			rig.FRHip.Transform = CFrame.Angles(math.rad(-10), 0, 0)
			rig.BLHip.Transform = CFrame.Angles(math.rad(10), 0, 0)
			rig.BRHip.Transform = CFrame.Angles(math.rad(10), 0, 0)
		end
	end

	-- Animation de la QUEUE (Toujours active, ondulation fluide)
	if rig.TailJoints then
		for i, joint in ipairs(rig.TailJoints) do
			local wave = math.sin(t * 3 - (i * 0.5)) * 0.3
			joint.Transform = CFrame.Angles(wave * 0.5, wave, 0)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- STRUCTURE COMPLÈTE — JOLIE EXTÉRIEUR + SALLES COLLÉES
-- Entrée avec TextLabel "Zone de CatNap"
-- Table avec papier indice (code)
-- Terminal = ProximityPrompt → GUI clavier
-- ═══════════════════════════════════════════════════════════════════

local codeStructure = nil
local proximityConn = nil

local function buildStructure()
	-- Générer le code aléatoire
	WIN_CODE = generateCode()

	local spawnPoints = {}
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("SpawnLocation") then table.insert(spawnPoints, v) end
	end
	local basePos
	if #spawnPoints > 0 then
		basePos = spawnPoints[math.random(1,#spawnPoints)].Position + Vector3.new(30, 0.5, 30)
	else
		basePos = Vector3.new(30, 0.5, 30)
	end

	local structure = Instance.new("Model"); structure.Name = "CN_Structure"

	local murCol = Color3.fromRGB(35, 15, 50)
	local murExtCol = Color3.fromRGB(25, 10, 38)
	local solCol = Color3.fromRGB(25, 10, 35)
	local plafondCol = Color3.fromRGB(15, 5, 22)
	local accentCol = Color3.fromRGB(100, 0, 150)
	local metalCol = Color3.fromRGB(60, 60, 70)
	local trimCol = Color3.fromRGB(120, 0, 180)
	local neonRedCol = Color3.fromRGB(255, 0, 50)
	local beton = Enum.Material.Concrete
	local carrelage = Enum.Material.Marble

	local W = 1.5
	local H = 14
	local roomW = 20
	local roomD = 20
	local corrW = 8
	local corrD = 12

	-- ═══════════════════════════════════════
	-- EXTÉRIEUR — Fondation + Déco
	-- ═══════════════════════════════════════

	-- Taille totale: hall + couloir + salle code
	local totalDepth = roomD + corrD + roomD
	local totalWidth = roomW + 6 -- extra pour déco extérieure
	local centerZ = basePos.Z + totalDepth/2

	-- Fondation extérieure (plateforme sous le bâtiment)
	local foundation = Instance.new("Part"); foundation.Name = "Foundation"
	foundation.Size = Vector3.new(totalWidth + 8, 2, totalDepth + 8)
	foundation.Position = Vector3.new(basePos.X, basePos.Y - 1.5, centerZ)
	foundation.Color = Color3.fromRGB(20, 8, 30); foundation.Material = Enum.Material.Slate
	foundation.Anchored = true; foundation.CanCollide = true; foundation.Parent = structure

	-- Marches d'entrée
	for i = 0, 3 do
		local step = Instance.new("Part"); step.Name = "Step"..i
		step.Size = Vector3.new(8, 0.5, 1.5)
		step.Position = Vector3.new(basePos.X, basePos.Y - 0.25 + i * 0.01, basePos.Z - roomD/2 - 2 - i * 1.5)
		step.Color = Color3.fromRGB(40, 18, 55); step.Material = Enum.Material.Slate
		step.Anchored = true; step.CanCollide = true; step.Parent = structure
	end

	-- Colonnes extérieures (entrée)
	for _, xOff in ipairs({-5, 5}) do
		local col = Instance.new("Part"); col.Name = "ExtColumn"
		col.Size = Vector3.new(1.8, H + 4, 1.8)
		col.Position = Vector3.new(basePos.X + xOff, basePos.Y + H/2, basePos.Z - roomD/2 - 0.5)
		col.Color = Color3.fromRGB(50, 20, 70); col.Material = beton
		col.Anchored = true; col.CanCollide = true; col.Parent = structure

		-- Chapiteau
		local cap = Instance.new("Part"); cap.Name = "ColCap"
		cap.Size = Vector3.new(2.6, 1, 2.6)
		cap.Position = col.Position + Vector3.new(0, H/2 + 2.5, 0)
		cap.Color = trimCol; cap.Material = Enum.Material.Neon; cap.Transparency = 0.3
		cap.Anchored = true; cap.CanCollide = false; cap.Parent = structure
	end

	-- Fronton (triangle au-dessus de l'entrée)
	local fronton = Instance.new("WedgePart"); fronton.Name = "Fronton"
	fronton.Size = Vector3.new(14, 4, 3)
	fronton.CFrame = CFrame.new(basePos.X, basePos.Y + H + 2, basePos.Z - roomD/2)
		* CFrame.Angles(0, math.rad(180), 0)
	fronton.Color = Color3.fromRGB(30, 12, 45); fronton.Material = beton
	fronton.Anchored = true; fronton.CanCollide = true; fronton.Parent = structure

	-- Bannière lumineuse extérieure
	local bannerExt = Instance.new("Part"); bannerExt.Name = "BannerExt"
	bannerExt.Size = Vector3.new(10, 2, 0.3)
	bannerExt.Position = Vector3.new(basePos.X, basePos.Y + H - 1, basePos.Z - roomD/2 - 1.2)
	bannerExt.Color = Color3.fromRGB(15, 5, 25); bannerExt.Material = Enum.Material.Glass
	bannerExt.Anchored = true; bannerExt.CanCollide = false; bannerExt.Parent = structure

	local bannerGui = Instance.new("SurfaceGui")
	bannerGui.Face = Enum.NormalId.Front; bannerGui.Parent = bannerExt

	local bannerText = Instance.new("TextLabel")
	bannerText.Size = UDim2.new(1,0,1,0); bannerText.BackgroundTransparency = 1
	bannerText.Text = "⚠ ZONE DE CATNAP ⚠"
	bannerText.TextColor3 = neonRedCol; bannerText.TextScaled = true
	bannerText.Font = Enum.Font.GothamBold
	bannerText.TextStrokeTransparency = 0; bannerText.TextStrokeColor3 = Color3.fromRGB(80,0,0)
	bannerText.Parent = bannerGui

	-- Lumière néon extérieure
	local extNeon = Instance.new("Part"); extNeon.Name = "ExtNeon"
	extNeon.Size = Vector3.new(12, 0.3, 0.3)
	extNeon.Position = Vector3.new(basePos.X, basePos.Y + H - 2.5, basePos.Z - roomD/2 - 0.8)
	extNeon.Color = neonRedCol; extNeon.Material = Enum.Material.Neon
	extNeon.Anchored = true; extNeon.CanCollide = false; extNeon.Parent = structure
	local extPL = Instance.new("PointLight"); extPL.Color = neonRedCol
	extPL.Brightness = 3; extPL.Range = 40; extPL.Parent = extNeon

	-- Corniche extérieure (bordure du toit)
	local corniche = Instance.new("Part"); corniche.Name = "Corniche"
	corniche.Size = Vector3.new(totalWidth + 4, 1, totalDepth + 4)
	corniche.Position = Vector3.new(basePos.X, basePos.Y + H + 0.5, centerZ)
	corniche.Color = Color3.fromRGB(40, 15, 55); corniche.Material = beton
	corniche.Anchored = true; corniche.CanCollide = true; corniche.Parent = structure

	-- ═══════════════════════════════════════
	-- SALLE 1: HALL D'ENTRÉE
	-- ═══════════════════════════════════════
	local hall = basePos

	-- Sol
	local hallFloor = Instance.new("Part"); hallFloor.Name = "HallFloor"
	hallFloor.Size = Vector3.new(roomW, W, roomD)
	hallFloor.Position = hall; hallFloor.Color = solCol; hallFloor.Material = carrelage
	hallFloor.Anchored = true; hallFloor.CanCollide = true; hallFloor.Parent = structure

	-- Plafond
	local hallCeil = Instance.new("Part"); hallCeil.Name = "HallCeiling"
	hallCeil.Size = Vector3.new(roomW, W, roomD)
	hallCeil.Position = hall + Vector3.new(0, H, 0); hallCeil.Color = plafondCol; hallCeil.Material = beton
	hallCeil.Anchored = true; hallCeil.CanCollide = true; hallCeil.Parent = structure

	-- Mur gauche
	local hallWL = Instance.new("Part"); hallWL.Name = "HallWL"
	hallWL.Size = Vector3.new(W, H, roomD)
	hallWL.Position = hall + Vector3.new(-roomW/2, H/2, 0); hallWL.Color = murCol; hallWL.Material = beton
	hallWL.Anchored = true; hallWL.CanCollide = true; hallWL.Parent = structure

	-- Mur droit
	local hallWR = Instance.new("Part"); hallWR.Name = "HallWR"
	hallWR.Size = Vector3.new(W, H, roomD)
	hallWR.Position = hall + Vector3.new(roomW/2, H/2, 0); hallWR.Color = murCol; hallWR.Material = beton
	hallWR.Anchored = true; hallWR.CanCollide = true; hallWR.Parent = structure

	-- Mur avant (entrée ouverte au milieu)
	local doorW = 6
	local sideW = (roomW - doorW) / 2
	local hallWFL = Instance.new("Part"); hallWFL.Name = "HallWFL"
	hallWFL.Size = Vector3.new(sideW, H, W)
	hallWFL.Position = hall + Vector3.new(-(doorW/2 + sideW/2), H/2, -roomD/2)
	hallWFL.Color = murCol; hallWFL.Material = beton
	hallWFL.Anchored = true; hallWFL.CanCollide = true; hallWFL.Parent = structure

	local hallWFR = Instance.new("Part"); hallWFR.Name = "HallWFR"
	hallWFR.Size = Vector3.new(sideW, H, W)
	hallWFR.Position = hall + Vector3.new((doorW/2 + sideW/2), H/2, -roomD/2)
	hallWFR.Color = murCol; hallWFR.Material = beton
	hallWFR.Anchored = true; hallWFR.CanCollide = true; hallWFR.Parent = structure

	-- Linteau au-dessus de la porte d'entrée
	local linteau = Instance.new("Part"); linteau.Name = "Linteau"
	linteau.Size = Vector3.new(doorW + 2, 2, W)
	linteau.Position = hall + Vector3.new(0, H - 1, -roomD/2)
	linteau.Color = trimCol; linteau.Material = Enum.Material.Neon; linteau.Transparency = 0.4
	linteau.Anchored = true; linteau.CanCollide = false; linteau.Parent = structure

	-- Mur fond hall (porte vers couloir)
	local hallBFL = Instance.new("Part"); hallBFL.Name = "HallBFL"
	hallBFL.Size = Vector3.new(sideW, H, W)
	hallBFL.Position = hall + Vector3.new(-(doorW/2 + sideW/2), H/2, roomD/2)
	hallBFL.Color = murCol; hallBFL.Material = beton
	hallBFL.Anchored = true; hallBFL.CanCollide = true; hallBFL.Parent = structure

	local hallBFR = Instance.new("Part"); hallBFR.Name = "HallBFR"
	hallBFR.Size = Vector3.new(sideW, H, W)
	hallBFR.Position = hall + Vector3.new((doorW/2 + sideW/2), H/2, roomD/2)
	hallBFR.Color = murCol; hallBFR.Material = beton
	hallBFR.Anchored = true; hallBFR.CanCollide = true; hallBFR.Parent = structure

	-- TextLabel "ZONE DE CATNAP" à l'entrée intérieure
	local entranceSign = Instance.new("Part"); entranceSign.Name = "EntranceSign"
	entranceSign.Size = Vector3.new(8, 2, 0.2)
	entranceSign.Position = hall + Vector3.new(0, H - 3, -roomD/2 + 1.5)
	entranceSign.Color = Color3.fromRGB(10, 0, 15); entranceSign.Material = Enum.Material.Glass
	entranceSign.Anchored = true; entranceSign.CanCollide = false; entranceSign.Parent = structure

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back; signGui.Parent = entranceSign

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1,0,1,0); signText.BackgroundTransparency = 1
	signText.Text = "☠ ZONE DE CATNAP ☠"
	signText.TextColor3 = neonRedCol; signText.TextScaled = true
	signText.Font = Enum.Font.GothamBold
	signText.TextStrokeTransparency = 0; signText.TextStrokeColor3 = Color3.fromRGB(60,0,0)
	signText.Parent = signGui

	-- Aussi visible de l'autre côté
	local signGui2 = Instance.new("SurfaceGui")
	signGui2.Face = Enum.NormalId.Front; signGui2.Parent = entranceSign
	local signText2 = signText:Clone(); signText2.Parent = signGui2

	-- Lustre hall
	local lustre = Instance.new("Part"); lustre.Name = "Lustre"
	lustre.Size = Vector3.new(3, 0.5, 3); lustre.Shape = Enum.PartType.Cylinder
	lustre.Position = hall + Vector3.new(0, H - 2, 0)
	lustre.Color = accentCol; lustre.Material = Enum.Material.Neon; lustre.Transparency = 0.2
	lustre.Anchored = true; lustre.CanCollide = false; lustre.Parent = structure
	lustre.Orientation = Vector3.new(0, 0, 90)
	local hallPL = Instance.new("PointLight"); hallPL.Color = accentCol
	hallPL.Brightness = 2; hallPL.Range = 35; hallPL.Parent = lustre

	-- Piliers intérieurs hall
	for _, xOff in ipairs({-7, 7}) do
		for _, zOff in ipairs({-5, 5}) do
			local pillar = Instance.new("Part"); pillar.Name = "HallPillar"
			pillar.Size = Vector3.new(1.5, H, 1.5)
			pillar.Position = hall + Vector3.new(xOff, H/2, zOff)
			pillar.Color = Color3.fromRGB(45, 20, 60); pillar.Material = beton
			pillar.Anchored = true; pillar.CanCollide = true; pillar.Parent = structure
		end
	end

	-- Bordure lumineuse au sol du hall
	for _, side in ipairs({-1, 1}) do
		local trim = Instance.new("Part"); trim.Name = "FloorTrim"
		trim.Size = Vector3.new(0.3, 0.3, roomD - 2)
		trim.Position = hall + Vector3.new(side * (roomW/2 - 1.5), 0.5, 0)
		trim.Color = trimCol; trim.Material = Enum.Material.Neon; trim.Transparency = 0.5
		trim.Anchored = true; trim.CanCollide = false; trim.Parent = structure
	end

	-- ═══════════════════════════════════════
	-- COULOIR (collé au hall)
	-- ═══════════════════════════════════════
	local corrStart = hall.Z + roomD/2
	local corridorPos = Vector3.new(basePos.X, basePos.Y, corrStart + corrD/2)

	local corrFloor = Instance.new("Part"); corrFloor.Name = "CorrFloor"
	corrFloor.Size = Vector3.new(corrW, W, corrD)
	corrFloor.Position = corridorPos; corrFloor.Color = solCol; corrFloor.Material = carrelage
	corrFloor.Anchored = true; corrFloor.CanCollide = true; corrFloor.Parent = structure

	local corrCeil = Instance.new("Part"); corrCeil.Name = "CorrCeil"
	corrCeil.Size = Vector3.new(corrW, W, corrD)
	corrCeil.Position = corridorPos + Vector3.new(0, H, 0); corrCeil.Color = plafondCol; corrCeil.Material = beton
	corrCeil.Anchored = true; corrCeil.CanCollide = true; corrCeil.Parent = structure

	local corrWL = Instance.new("Part"); corrWL.Name = "CorrWL"
	corrWL.Size = Vector3.new(W, H, corrD)
	corrWL.Position = corridorPos + Vector3.new(-corrW/2, H/2, 0); corrWL.Color = murCol; corrWL.Material = beton
	corrWL.Anchored = true; corrWL.CanCollide = true; corrWL.Parent = structure

	local corrWR = Instance.new("Part"); corrWR.Name = "CorrWR"
	corrWR.Size = Vector3.new(W, H, corrD)
	corrWR.Position = corridorPos + Vector3.new(corrW/2, H/2, 0); corrWR.Color = murCol; corrWR.Material = beton
	corrWR.Anchored = true; corrWR.CanCollide = true; corrWR.Parent = structure

	-- Remplir les côtés du couloir (mur entre hall et couloir, les parties pas porte)
	local fillSideW = (roomW - corrW) / 2
	for _, side in ipairs({-1, 1}) do
		local fillWall = Instance.new("Part"); fillWall.Name = "FillWall"..side
		fillWall.Size = Vector3.new(fillSideW, H, W)
		fillWall.Position = Vector3.new(basePos.X + side * (corrW/2 + fillSideW/2), basePos.Y + H/2, corrStart)
		fillWall.Color = murCol; fillWall.Material = beton
		fillWall.Anchored = true; fillWall.CanCollide = true; fillWall.Parent = structure
	end

	-- Néons du couloir
	for i = 0, 3 do
		local neon = Instance.new("Part"); neon.Name = "CorrNeon"..i
		neon.Size = Vector3.new(0.3, 0.3, 2)
		neon.Position = corridorPos + Vector3.new(0, H - 1, -corrD/2 + 2 + i * 3)
		neon.Color = neonRedCol; neon.Material = Enum.Material.Neon
		neon.Anchored = true; neon.CanCollide = false; neon.Parent = structure
		local npl = Instance.new("PointLight"); npl.Color = neonRedCol
		npl.Brightness = 1; npl.Range = 18; npl.Parent = neon
	end

	-- ═══════════════════════════════════════
	-- SALLE 2: SALLE DU CODE (collée au couloir)
	-- ═══════════════════════════════════════
	local codeRoomStart = corrStart + corrD
	local codeRoom = Vector3.new(basePos.X, basePos.Y, codeRoomStart + roomD/2)

	-- Remplir côtés entre couloir et salle du code
	for _, side in ipairs({-1, 1}) do
		local fillWall2 = Instance.new("Part"); fillWall2.Name = "FillWall2"..side
		fillWall2.Size = Vector3.new(fillSideW, H, W)
		fillWall2.Position = Vector3.new(basePos.X + side * (corrW/2 + fillSideW/2), basePos.Y + H/2, codeRoomStart)
		fillWall2.Color = murCol; fillWall2.Material = beton
		fillWall2.Anchored = true; fillWall2.CanCollide = true; fillWall2.Parent = structure
	end

	local crFloor = Instance.new("Part"); crFloor.Name = "CodeFloor"
	crFloor.Size = Vector3.new(roomW, W, roomD)
	crFloor.Position = codeRoom; crFloor.Color = Color3.fromRGB(18, 5, 28); crFloor.Material = carrelage
	crFloor.Anchored = true; crFloor.CanCollide = true; crFloor.Parent = structure

	local crCeil = Instance.new("Part"); crCeil.Name = "CodeCeil"
	crCeil.Size = Vector3.new(roomW, W, roomD)
	crCeil.Position = codeRoom + Vector3.new(0, H, 0); crCeil.Color = plafondCol; crCeil.Material = beton
	crCeil.Anchored = true; crCeil.CanCollide = true; crCeil.Parent = structure

	local crWL = Instance.new("Part"); crWL.Name = "CRWL"
	crWL.Size = Vector3.new(W, H, roomD)
	crWL.Position = codeRoom + Vector3.new(-roomW/2, H/2, 0); crWL.Color = murCol; crWL.Material = beton
	crWL.Anchored = true; crWL.CanCollide = true; crWL.Parent = structure

	local crWR = Instance.new("Part"); crWR.Name = "CRWR"
	crWR.Size = Vector3.new(W, H, roomD)
	crWR.Position = codeRoom + Vector3.new(roomW/2, H/2, 0); crWR.Color = murCol; crWR.Material = beton
	crWR.Anchored = true; crWR.CanCollide = true; crWR.Parent = structure

	-- Mur avant salle code (porte au milieu, collé au couloir)
	local crWFL = Instance.new("Part"); crWFL.Name = "CRWFL"
	crWFL.Size = Vector3.new(sideW, H, W)
	crWFL.Position = codeRoom + Vector3.new(-(doorW/2 + sideW/2), H/2, -roomD/2)
	crWFL.Color = murCol; crWFL.Material = beton
	crWFL.Anchored = true; crWFL.CanCollide = true; crWFL.Parent = structure

	local crWFR = Instance.new("Part"); crWFR.Name = "CRWFR"
	crWFR.Size = Vector3.new(sideW, H, W)
	crWFR.Position = codeRoom + Vector3.new((doorW/2 + sideW/2), H/2, -roomD/2)
	crWFR.Color = murCol; crWFR.Material = beton
	crWFR.Anchored = true; crWFR.CanCollide = true; crWFR.Parent = structure

	-- Mur fond salle code (fermé)
	local crWB = Instance.new("Part"); crWB.Name = "CRWB"
	crWB.Size = Vector3.new(roomW, H, W)
	crWB.Position = codeRoom + Vector3.new(0, H/2, roomD/2)
	crWB.Color = murCol; crWB.Material = beton
	crWB.Anchored = true; crWB.CanCollide = true; crWB.Parent = structure

	-- Lumière salle code (rouge pulsante)
	local codeLight = Instance.new("Part"); codeLight.Name = "CodeLight"
	codeLight.Size = Vector3.new(4, 0.5, 4)
	codeLight.Position = codeRoom + Vector3.new(0, H - 1, 0)
	codeLight.Color = neonRedCol; codeLight.Material = Enum.Material.Neon; codeLight.Transparency = 0.3
	codeLight.Anchored = true; codeLight.CanCollide = false; codeLight.Parent = structure
	local codePL = Instance.new("PointLight"); codePL.Name = "CodePL"; codePL.Color = neonRedCol
	codePL.Brightness = 2.5; codePL.Range = 40; codePL.Parent = codeLight

	-- ═══ TABLE AVEC PAPIER INDICE ═══
	local tablePos = codeRoom + Vector3.new(0, 0, -3)

	local table1 = Instance.new("Part"); table1.Name = "Table"
	table1.Size = Vector3.new(6, 0.5, 3)
	table1.Position = tablePos + Vector3.new(0, 3, 0)
	table1.Color = Color3.fromRGB(40, 20, 55); table1.Material = Enum.Material.Wood
	table1.Anchored = true; table1.CanCollide = true; table1.Parent = structure

	for _, off in ipairs({{-2.5,-1},{2.5,-1},{-2.5,1},{2.5,1}}) do
		local leg = Instance.new("Part"); leg.Name = "TableLeg"
		leg.Size = Vector3.new(0.4, 2.5, 0.4)
		leg.Position = tablePos + Vector3.new(off[1], 1.25, off[2])
		leg.Color = metalCol; leg.Material = Enum.Material.Metal
		leg.Anchored = true; leg.CanCollide = true; leg.Parent = structure
	end

	-- PAPIER AVEC LE CODE SUR LA TABLE
	local paper = Instance.new("Part"); paper.Name = "CodePaper"
	paper.Size = Vector3.new(2, 0.05, 2.5)
	paper.Position = tablePos + Vector3.new(1, 3.3, 0)
	paper.Color = Color3.fromRGB(220, 210, 190); paper.Material = Enum.Material.Fabric
	paper.Anchored = true; paper.CanCollide = false; paper.Parent = structure
	paper.Orientation = Vector3.new(0, math.random(-15, 15), 0)

	-- Texte sur le papier (visible du dessus)
	local paperGui = Instance.new("SurfaceGui")
	paperGui.Face = Enum.NormalId.Top; paperGui.Parent = paper
	paperGui.PixelsPerStud = 50

	local paperBg = Instance.new("Frame")
	paperBg.Size = UDim2.new(1,0,1,0); paperBg.BackgroundColor3 = Color3.fromRGB(220, 210, 190)
	paperBg.BorderSizePixel = 0; paperBg.Parent = paperGui

	local paperTitle = Instance.new("TextLabel")
	paperTitle.Size = UDim2.new(1,0,0.25,0); paperTitle.Position = UDim2.new(0,0,0.05,0)
	paperTitle.BackgroundTransparency = 1; paperTitle.Text = "CODE D'ACCÈS:"
	paperTitle.TextColor3 = Color3.fromRGB(80, 0, 0); paperTitle.TextScaled = true
	paperTitle.Font = Enum.Font.GothamBold; paperTitle.Parent = paperBg

	local paperCode = Instance.new("TextLabel")
	paperCode.Size = UDim2.new(0.8,0,0.4,0); paperCode.Position = UDim2.new(0.1,0,0.35,0)
	paperCode.BackgroundColor3 = Color3.fromRGB(200, 190, 170); paperCode.BorderSizePixel = 2
	paperCode.BorderColor3 = Color3.fromRGB(100, 0, 0)
	paperCode.Text = WIN_CODE
	paperCode.TextColor3 = Color3.fromRGB(180, 0, 30); paperCode.TextScaled = true
	paperCode.Font = Enum.Font.Code; paperCode.Parent = paperBg

	local paperNote = Instance.new("TextLabel")
	paperNote.Size = UDim2.new(0.9,0,0.2,0); paperNote.Position = UDim2.new(0.05,0,0.78,0)
	paperNote.BackgroundTransparency = 1; paperNote.Text = "⚠ NE PAS PERDRE"
	paperNote.TextColor3 = Color3.fromRGB(120, 60, 60); paperNote.TextScaled = true
	paperNote.Font = Enum.Font.Gotham; paperNote.Parent = paperBg

	-- Tache d'encre/sang sur le papier
	local stain = Instance.new("Frame")
	stain.Size = UDim2.new(0.15,0,0.15,0); stain.Position = UDim2.new(0.7,0,0.7,0)
	stain.BackgroundColor3 = Color3.fromRGB(100, 0, 0); stain.BackgroundTransparency = 0.4
	stain.Parent = paperBg; stain.Rotation = 30
	Instance.new("UICorner", stain).CornerRadius = UDim.new(1,0)

	-- Chaises
	for _, xOff in ipairs({-2, 2}) do
		local seat = Instance.new("Part"); seat.Name = "Chair"
		seat.Size = Vector3.new(1.5, 0.3, 1.5)
		seat.Position = tablePos + Vector3.new(xOff, 1.8, -2.5)
		seat.Color = Color3.fromRGB(55, 30, 70); seat.Material = Enum.Material.Fabric
		seat.Anchored = true; seat.CanCollide = true; seat.Parent = structure

		local back = Instance.new("Part"); back.Name = "ChairBack"
		back.Size = Vector3.new(1.5, 2, 0.3)
		back.Position = tablePos + Vector3.new(xOff, 2.9, -3.2)
		back.Color = Color3.fromRGB(55, 30, 70); back.Material = Enum.Material.Fabric
		back.Anchored = true; back.CanCollide = true; back.Parent = structure
	end

	-- Étagères
	for i = 0, 2 do
		local shelf = Instance.new("Part"); shelf.Name = "Shelf"..i
		shelf.Size = Vector3.new(3, 5, 1.2)
		shelf.Position = codeRoom + Vector3.new(-8, 3, -6 + i * 6)
		shelf.Color = Color3.fromRGB(50, 25, 65); shelf.Material = Enum.Material.Wood
		shelf.Anchored = true; shelf.CanCollide = true; shelf.Parent = structure
	end

	-- ═══ TERMINAL — ProximityPrompt ═══
	local terminal = Instance.new("Part"); terminal.Name = "Terminal"
	terminal.Size = Vector3.new(5, 5, 0.5)
	terminal.Position = codeRoom + Vector3.new(0, 4.5, roomD/2 - 1)
	terminal.Color = Color3.fromRGB(10, 5, 18); terminal.Material = Enum.Material.Glass
	terminal.Anchored = true; terminal.CanCollide = true; terminal.Parent = structure

	-- Cadre terminal
	local tFrame = Instance.new("Part"); tFrame.Name = "TermFrame"
	tFrame.Size = Vector3.new(5.6, 5.6, 0.3)
	tFrame.Position = terminal.Position + Vector3.new(0, 0, 0.35)
	tFrame.Color = metalCol; tFrame.Material = Enum.Material.Metal
	tFrame.Anchored = true; tFrame.CanCollide = false; tFrame.Parent = structure

	-- Écran du terminal (visuel statique)
	local termGui = Instance.new("SurfaceGui")
	termGui.Face = Enum.NormalId.Back; termGui.Parent = terminal

	local termBg = Instance.new("Frame")
	termBg.Size = UDim2.new(1,0,1,0); termBg.BackgroundColor3 = Color3.fromRGB(5,0,10); termBg.Parent = termGui

	local termTitle = Instance.new("TextLabel")
	termTitle.Size = UDim2.new(1,0,0.2,0); termTitle.BackgroundTransparency = 1
	termTitle.Text = "⚠ SYSTÈME DE SÉCURITÉ ⚠"
	termTitle.TextColor3 = CC.accentG; termTitle.TextScaled = true
	termTitle.Font = Enum.Font.GothamBold; termTitle.Parent = termBg

	local termInstr = Instance.new("TextLabel")
	termInstr.Size = UDim2.new(0.8,0,0.15,0); termInstr.Position = UDim2.new(0.1,0,0.3,0)
	termInstr.BackgroundTransparency = 1
	termInstr.Text = "Approchez-vous et\nappuyez sur E"
	termInstr.TextColor3 = CC.dim; termInstr.TextScaled = true
	termInstr.Font = Enum.Font.Gotham; termInstr.Parent = termBg

	local termIcon = Instance.new("TextLabel")
	termIcon.Size = UDim2.new(0.5,0,0.3,0); termIcon.Position = UDim2.new(0.25,0,0.5,0)
	termIcon.BackgroundTransparency = 1; termIcon.Text = "🔒"
	termIcon.TextScaled = true; termIcon.Parent = termBg

	local termStatus = Instance.new("TextLabel")
	termStatus.Name = "Status"
	termStatus.Size = UDim2.new(0.8,0,0.1,0); termStatus.Position = UDim2.new(0.1,0,0.85,0)
	termStatus.BackgroundTransparency = 1; termStatus.Text = "EN ATTENTE DU CODE..."
	termStatus.TextColor3 = neonRedCol; termStatus.TextScaled = true
	termStatus.Font = Enum.Font.Code; termStatus.Parent = termBg

	-- ProximityPrompt sur le terminal
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CodePrompt"
	prompt.ActionText = "Entrer le code"
	prompt.ObjectText = "Terminal"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = terminal

	-- Connexion ProximityPrompt → ouvre le GUI clavier
	proximityConn = prompt.Triggered:Connect(function(plr)
		if plr == player and not codeEntered then
			openCodeGui()
		end
	end)

	-- Fumée salle code
	local roomSmoke = Instance.new("Part"); roomSmoke.Name = "RoomSmoke"
	roomSmoke.Size = Vector3.new(1,1,1); roomSmoke.Transparency = 1
	roomSmoke.Position = codeRoom + Vector3.new(0, 2, 0); roomSmoke.Anchored = true
	roomSmoke.CanCollide = false; roomSmoke.Parent = structure

	local rpe = Instance.new("ParticleEmitter")
	rpe.Color = ColorSequence.new(Color3.fromRGB(80,0,40), Color3.fromRGB(20,0,10))
	rpe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,3), NumberSequenceKeypoint.new(1,10)})
	rpe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.6), NumberSequenceKeypoint.new(1,1)})
	rpe.Lifetime = NumberRange.new(4,8); rpe.Rate = 5
	rpe.Speed = NumberRange.new(0.3,1.5); rpe.SpreadAngle = Vector2.new(180,180)
	rpe.Texture = "rbxassetid://241685484"; rpe.Parent = roomSmoke

	-- Murs extérieurs décoratifs (pour que ce soit joli de l'extérieur)
	-- Mur extérieur gauche complet
	local extWL = Instance.new("Part"); extWL.Name = "ExtWL"
	extWL.Size = Vector3.new(0.5, H + 2, totalDepth + 2)
	extWL.Position = Vector3.new(basePos.X - roomW/2 - 0.5, basePos.Y + H/2, centerZ)
	extWL.Color = murExtCol; extWL.Material = Enum.Material.Slate
	extWL.Anchored = true; extWL.CanCollide = true; extWL.Parent = structure

	local extWR = Instance.new("Part"); extWR.Name = "ExtWR"
	extWR.Size = Vector3.new(0.5, H + 2, totalDepth + 2)
	extWR.Position = Vector3.new(basePos.X + roomW/2 + 0.5, basePos.Y + H/2, centerZ)
	extWR.Color = murExtCol; extWR.Material = Enum.Material.Slate
	extWR.Anchored = true; extWR.CanCollide = true; extWR.Parent = structure

	-- Mur extérieur fond
	local extWB = Instance.new("Part"); extWB.Name = "ExtWB"
	extWB.Size = Vector3.new(roomW + 2, H + 2, 0.5)
	extWB.Position = Vector3.new(basePos.X, basePos.Y + H/2, codeRoomStart + roomD + 0.5)
	extWB.Color = murExtCol; extWB.Material = Enum.Material.Slate
	extWB.Anchored = true; extWB.CanCollide = true; extWB.Parent = structure

	-- Toit
	local roof = Instance.new("Part"); roof.Name = "Roof"
	roof.Size = Vector3.new(totalWidth + 4, 1, totalDepth + 4)
	roof.Position = Vector3.new(basePos.X, basePos.Y + H + 1.5, centerZ)
	roof.Color = Color3.fromRGB(20, 8, 30); roof.Material = Enum.Material.Slate
	roof.Anchored = true; roof.CanCollide = true; roof.Parent = structure

	structure.Parent = workspace
	codeStructure = structure
end

-- ═══════════════════════════════════════════════════════════════════
-- GUI CLAVIER (s'ouvre quand on appuie E sur le terminal)
-- ═══════════════════════════════════════════════════════════════════

local currentCode = ""

function openCodeGui()
	if codeGuiOpen or codeEntered then return end
	codeGuiOpen = true
	currentCode = ""

	local sg = player.PlayerGui:FindFirstChild("CoolKidCatNap")
	if not sg then return end

	-- Supprimer ancien GUI code si existant
	local old = sg:FindFirstChild("CodeInputGui")
	if old then old:Destroy() end

	local cGui = Instance.new("Frame")
	cGui.Name = "CodeInputGui"
	cGui.Size = UDim2.new(0, 320, 0, 420)
	cGui.Position = UDim2.new(0.5, -160, 0.5, -210)
	cGui.BackgroundColor3 = Color3.fromRGB(8, 2, 15)
	cGui.BorderSizePixel = 0; cGui.ZIndex = 60; cGui.Parent = sg
	Instance.new("UICorner", cGui).CornerRadius = UDim.new(0, 16)
	local cStroke = Instance.new("UIStroke"); cStroke.Color = CC.accent
	cStroke.Thickness = 2; cStroke.Parent = cGui
	codeInputGui = cGui

	-- Fond sombre derrière
	local overlay = Instance.new("Frame")
	overlay.Name = "CodeOverlay"
	overlay.Size = UDim2.new(1,0,1,0); overlay.BackgroundColor3 = Color3.new(0,0,0)
	overlay.BackgroundTransparency = 0.5; overlay.ZIndex = 59; overlay.Parent = sg

	-- Header
	local cHeader = Instance.new("Frame")
	cHeader.Size = UDim2.new(1,0,0,50); cHeader.BackgroundColor3 = CC.darkPurp
	cHeader.BorderSizePixel = 0; cHeader.ZIndex = 61; cHeader.Parent = cGui
	Instance.new("UICorner", cHeader).CornerRadius = UDim.new(0, 16)

	local cTitle = Instance.new("TextLabel")
	cTitle.Size = UDim2.new(1,-50,1,0); cTitle.Position = UDim2.new(0,14,0,0)
	cTitle.BackgroundTransparency = 1; cTitle.Text = "🔒 SYSTÈME DE SÉCURITÉ"
	cTitle.TextColor3 = Color3.new(1,1,1); cTitle.TextSize = 15; cTitle.Font = Enum.Font.GothamBold
	cTitle.TextXAlignment = Enum.TextXAlignment.Left; cTitle.ZIndex = 62; cTitle.Parent = cHeader

	local cClose = Instance.new("TextButton")
	cClose.Size = UDim2.new(0,32,0,32); cClose.Position = UDim2.new(1,-42,0.5,-16)
	cClose.BackgroundColor3 = CC.red; cClose.Text = "✕"; cClose.TextColor3 = Color3.new(1,1,1)
	cClose.TextSize = 14; cClose.Font = Enum.Font.GothamBold; cClose.ZIndex = 62; cClose.Parent = cHeader
	Instance.new("UICorner", cClose).CornerRadius = UDim.new(0,8)

	cClose.MouseButton1Click:Connect(function()
		closeCodeGui()
	end)

	-- Affichage du code
	local codeDisplay = Instance.new("TextLabel")
	codeDisplay.Name = "CodeDisplay"
	codeDisplay.Size = UDim2.new(0.85,0,0,45)
	codeDisplay.Position = UDim2.new(0.075,0,0,60)
	codeDisplay.BackgroundColor3 = Color3.fromRGB(15,0,25)
	codeDisplay.Text = "_ _ _ _"
	codeDisplay.TextColor3 = Color3.new(1,1,1); codeDisplay.TextScaled = true
	codeDisplay.Font = Enum.Font.Code; codeDisplay.ZIndex = 61; codeDisplay.Parent = cGui
	Instance.new("UICorner", codeDisplay).CornerRadius = UDim.new(0,8)
	Instance.new("UIStroke", codeDisplay).Color = CC.purple

	-- Message de statut
	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "StatusLbl"
	statusLbl.Size = UDim2.new(0.85,0,0,20)
	statusLbl.Position = UDim2.new(0.075,0,0,110)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "Entrez le code à 4 chiffres"
	statusLbl.TextColor3 = CC.dim; statusLbl.TextScaled = true
	statusLbl.Font = Enum.Font.Gotham; statusLbl.ZIndex = 61; statusLbl.Parent = cGui

	-- Clavier numérique
	local keypad = Instance.new("Frame")
	keypad.Size = UDim2.new(0.85,0,0,240)
	keypad.Position = UDim2.new(0.075,0,0,140)
	keypad.BackgroundTransparency = 1; keypad.ZIndex = 61; keypad.Parent = cGui

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.3,0,0.22,0)
	grid.CellPadding = UDim2.new(0.02,0,0.02,0)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = keypad

	local buttons = {"1","2","3","4","5","6","7","8","9","C","0","OK"}
	for idx, num in ipairs(buttons) do
		local btn = Instance.new("TextButton")
		btn.Name = "Key"..num; btn.Text = num
		btn.LayoutOrder = idx
		btn.ZIndex = 62

		if num == "OK" then
			btn.BackgroundColor3 = CC.green
		elseif num == "C" then
			btn.BackgroundColor3 = CC.red
		else
			btn.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
		end

		btn.TextColor3 = Color3.new(1,1,1); btn.TextScaled = true
		btn.Font = Enum.Font.GothamBold; btn.Parent = keypad
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

		-- Hover
		btn.MouseEnter:Connect(function()
			if num ~= "OK" and num ~= "C" then
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60,30,90)}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if num ~= "OK" and num ~= "C" then
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40,20,60)}):Play()
			end
		end)

		btn.MouseButton1Click:Connect(function()
			if codeEntered then return end

			if num == "C" then
				currentCode = ""
				codeDisplay.Text = "_ _ _ _"
				codeDisplay.TextColor3 = Color3.new(1,1,1)
				statusLbl.Text = "Code effacé"
				statusLbl.TextColor3 = CC.dim

			elseif num == "OK" then
				if currentCode == WIN_CODE then
					-- SUCCÈS
					codeEntered = true
					codeDisplay.Text = "✅ CORRECT!"
					codeDisplay.TextColor3 = CC.green
					statusLbl.Text = "ACCÈS AUTORISÉ — CatNap détruit!"
					statusLbl.TextColor3 = CC.green
					local cs = snd(SND.codeSuccess, 2); cs:Play(); Debris:AddItem(cs, 3)

					-- Mettre à jour le terminal
					if codeStructure then
						local term = codeStructure:FindFirstChild("Terminal")
						if term then
							local tGui = term:FindFirstChildOfClass("SurfaceGui")
							if tGui then
								local bg = tGui:FindFirstChild("Frame")
								if bg then
									local st = bg:FindFirstChild("Status")
									if st then st.Text = "✅ ACCÈS AUTORISÉ"; st.TextColor3 = CC.green end
								end
							end
						end
					end

					task.spawn(function()
						task.wait(1.5)
						closeCodeGui()

						-- Explosion CatNap
						if catNapModel and catNapModel.PrimaryPart then
							local deathPos = catNapModel.PrimaryPart.Position
							for i = 1, 25 do
								local db = ms(workspace, "Db"..i,
									Vector3.new(math.random(5,15)/10,math.random(5,15)/10,math.random(5,15)/10),
									Color3.fromRGB(math.random(60,150),0,math.random(60,150)), Enum.Material.Neon)
								db.CFrame = CFrame.new(deathPos) * CFrame.new(math.random(-5,5),math.random(0,8),math.random(-5,5))
								db.Anchored = false; db.CanCollide = true
								db.Velocity = Vector3.new(math.random(-50,50),math.random(20,70),math.random(-50,50))
								Debris:AddItem(db, 4)
							end
							local es = snd(SND.explosion, 3); es:Play(); Debris:AddItem(es, 4)
							catNapModel:Destroy(); catNapModel = nil; catNapAlive = false
						end
						task.wait(2)
						stopEvent(true)
					end)

				else
					-- FAUX CODE
					codeDisplay.Text = "❌ FAUX!"
					codeDisplay.TextColor3 = CC.red
					statusLbl.Text = "Code incorrect! Réessayez."
					statusLbl.TextColor3 = CC.red
					local cf = snd(SND.codeFail, 1.5); cf:Play(); Debris:AddItem(cf, 2)

					-- Shake
					for i = 1, 6 do
						cGui.Position = UDim2.new(0.5, -160 + math.random(-8,8), 0.5, -210 + math.random(-8,8))
						task.wait(0.05)
					end
					cGui.Position = UDim2.new(0.5, -160, 0.5, -210)

					task.wait(0.8)
					currentCode = ""
					codeDisplay.Text = "_ _ _ _"
					codeDisplay.TextColor3 = Color3.new(1,1,1)
					statusLbl.Text = "Entrez le code à 4 chiffres"
					statusLbl.TextColor3 = CC.dim
				end

			else
				-- Chiffre
				if #currentCode < 4 then
					currentCode = currentCode .. num
					local disp = ""
					for j = 1, 4 do
						disp = disp .. (j <= #currentCode and currentCode:sub(j,j) or "_") .. " "
					end
					codeDisplay.Text = disp:sub(1,-2)
					statusLbl.Text = #currentCode .. "/4 chiffres entrés"
					statusLbl.TextColor3 = CC.accentG
				end
			end
		end)
	end

	-- Indice en bas
	local hintLbl = Instance.new("TextLabel")
	hintLbl.Size = UDim2.new(0.85,0,0,18)
	hintLbl.Position = UDim2.new(0.075,0,0,390)
	hintLbl.BackgroundTransparency = 1
	hintLbl.Text = "💡 Indice: Cherchez un papier sur la table..."
	hintLbl.TextColor3 = Color3.fromRGB(80, 60, 100); hintLbl.TextScaled = true
	hintLbl.Font = Enum.Font.Gotham; hintLbl.ZIndex = 61; hintLbl.Parent = cGui

	-- Animation d'ouverture
	cGui.Size = UDim2.new(0,0,0,0)
	cGui.Position = UDim2.new(0.5,0,0.5,0)
	TweenService:Create(cGui, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0,320,0,420),
		Position = UDim2.new(0.5,-160,0.5,-210)
	}):Play()
end

function closeCodeGui()
	codeGuiOpen = false
	local sg = player.PlayerGui:FindFirstChild("CoolKidCatNap")
	if not sg then return end

	local overlay = sg:FindFirstChild("CodeOverlay")
	if overlay then overlay:Destroy() end

	if codeInputGui then
		TweenService:Create(codeInputGui, TweenInfo.new(0.2), {
			Size = UDim2.new(0,0,0,0),
			Position = UDim2.new(0.5,0,0.5,0)
		}):Play()
		task.delay(0.25, function()
			if codeInputGui then codeInputGui:Destroy(); codeInputGui = nil end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- ARME + FRAPPE AVEC RAYCAST
-- ═══════════════════════════════════════════════════════════════════

local function createWeapon()
	local tool = Instance.new("Model"); tool.Name = "CN_Weapon"
	local handle = mp(tool, "Handle", Vector3.new(0.4, 5, 0.4), Color3.fromRGB(80, 60, 40), Enum.Material.Wood)
	local batHead = mp(tool, "BatHead", Vector3.new(0.8, 1.5, 0.8), CC.accentG, Enum.Material.Neon)
	batHead.CFrame = handle.CFrame * CFrame.new(0, 3, 0); weld(handle, batHead)
	local glow = ms(tool, "Glow", Vector3.new(1.2, 1.8, 1.2), CC.accentG, Enum.Material.Neon, 0.5)
	glow.CFrame = batHead.CFrame; weld(batHead, glow)
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

local function swingWeapon()
	if not canSwing or not playerHasWeapon then return end
	canSwing = false

	local ws = snd(SND.weaponSwing, 1.5); ws:Play(); Debris:AddItem(ws, 1)

	if catNapModel and catNapModel.PrimaryPart and catNapAlive then
		local hs = snd(SND.hit, 2); hs:Play(); Debris:AddItem(hs, 1)

		-- Flash
		for _, p in pairs(catNapModel:GetDescendants()) do
			if p:IsA("BasePart") and p.Transparency < 0.5 then
				local orig = p.Color
				p.Color = Color3.new(1, 1, 1)
				task.delay(0.1, function() pcall(function() p.Color = orig end) end)
			end
		end

		catNapAlive = false

		-- Désactiver particules
		for _, p in pairs(catNapModel:GetDescendants()) do
			if p:IsA("ParticleEmitter") then p.Enabled = false end
		end

		-- Fade out
		for _, p in pairs(catNapModel:GetDescendants()) do
			if p:IsA("BasePart") then
				TweenService:Create(p, TweenInfo.new(0.5), {Transparency = 1}):Play()
			end
		end

		local deathPos = catNapModel.PrimaryPart.Position

		-- Particules de mort
		for i = 1, 15 do
			local db = ms(workspace, "DeathP"..i,
				Vector3.new(math.random(3,8)/10, math.random(3,8)/10, math.random(3,8)/10),
				Color3.fromRGB(math.random(60,150), 0, math.random(80,200)), Enum.Material.Neon)
			db.Anchored = false; db.CanCollide = false
			db.CFrame = CFrame.new(deathPos) * CFrame.new(math.random(-3,3), math.random(0,5), math.random(-3,3))
			db.Velocity = Vector3.new(math.random(-30,30), math.random(15,45), math.random(-30,30))
			Debris:AddItem(db, 2)
		end

		-- Fumée de mort
		local smokePart = Instance.new("Part")
		smokePart.Size = Vector3.new(1,1,1); smokePart.Transparency = 1
		smokePart.Anchored = true; smokePart.CanCollide = false
		smokePart.Position = deathPos; smokePart.Parent = workspace

		local deathSmoke = Instance.new("ParticleEmitter")
		deathSmoke.Color = ColorSequence.new(Color3.fromRGB(100, 0, 150), Color3.fromRGB(40, 0, 60))
		deathSmoke.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 8)})
		deathSmoke.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
		deathSmoke.Lifetime = NumberRange.new(1, 2); deathSmoke.Rate = 50
		deathSmoke.Speed = NumberRange.new(2, 6); deathSmoke.SpreadAngle = Vector2.new(180, 180)
		deathSmoke.LightEmission = 0.5; deathSmoke.Texture = "rbxassetid://241685484"
		deathSmoke.Parent = smokePart

		task.delay(1, function() deathSmoke.Enabled = false end)
		Debris:AddItem(smokePart, 3)

		-- Détruire et respawn
		task.delay(0.6, function()
			if catNapModel then
				catNapModel:Destroy()
				catNapModel = nil
				catNapRig = nil
			end

			if eventActive and not codeEntered then
				-- Countdown dans le GUI
				local gui = player.PlayerGui:FindFirstChild("CoolKidCatNap")
				if gui then
					local warnFrame = Instance.new("Frame")
					warnFrame.Size = UDim2.new(0.4, 0, 0.06, 0)
					warnFrame.Position = UDim2.new(0.3, 0, 0.15, 0)
					warnFrame.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
					warnFrame.BackgroundTransparency = 0.3
					warnFrame.BorderSizePixel = 0; warnFrame.ZIndex = 80; warnFrame.Parent = gui
					Instance.new("UICorner", warnFrame).CornerRadius = UDim.new(0, 8)

					local warnText = Instance.new("TextLabel")
					warnText.Size = UDim2.new(1, -10, 1, 0)
					warnText.Position = UDim2.new(0, 5, 0, 0)
					warnText.BackgroundTransparency = 1
					warnText.TextColor3 = Color3.fromRGB(255, 100, 100)
					warnText.TextScaled = true; warnText.Font = Enum.Font.GothamBold
					warnText.ZIndex = 81; warnText.Parent = warnFrame

					task.spawn(function()
						for countdown = SPAWN_INTERVAL, 1, -1 do
							if not eventActive or codeEntered then break end
							warnText.Text = "⚠ CatNap reviendra dans " .. countdown .. "s..."
							task.wait(1)
						end
						if warnFrame and warnFrame.Parent then
							TweenService:Create(warnFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
							TweenService:Create(warnText, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
							task.wait(0.6)
							pcall(function() warnFrame:Destroy() end)
						end
					end)
				end

				-- RESPAWN FIX: utilise task.spawn pour ne pas bloquer
				task.spawn(function()
					task.wait(SPAWN_INTERVAL)
					if eventActive and not codeEntered then
						spawnCatNap()
						local gs = snd(SND.growl, 2); gs:Play(); Debris:AddItem(gs, 3)
					end
				end)
			end
		end)
	end

	task.wait(SWING_COOLDOWN)
	canSwing = true
end

-- ═══════════════════════════════════════════════════════════════════
-- JUMPSCARE
-- ═══════════════════════════════════════════════════════════════════

local function doCatNapJumpscare()
	if jumpscareActive then return end
	jumpscareActive = true

	local js = snd(SND.jumpscare, 3); js:Play()
	local hs = snd(SND.heartbeat, 1.5, true); hs:Play()

	local gui = player.PlayerGui:FindFirstChild("CoolKidCatNap")
	if gui then
		local jsF = Instance.new("Frame")
		jsF.Size = UDim2.new(1,0,1,0); jsF.BackgroundColor3 = Color3.fromRGB(80,0,120)
		jsF.ZIndex = 100; jsF.Parent = gui

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(0.9,0,0.2,0); nameL.Position = UDim2.new(0.05,0,0.4,0)
		nameL.BackgroundTransparency = 1; nameL.Text = "NIGHTMARE CATNAP"
		nameL.TextColor3 = Color3.new(1,1,1); nameL.TextScaled = true
		nameL.Font = Enum.Font.GothamBold; nameL.TextStrokeTransparency = 0
		nameL.TextStrokeColor3 = CC.purple; nameL.ZIndex = 106; nameL.Parent = jsF

		local subL = Instance.new("TextLabel")
		subL.Size = UDim2.new(0.5,0,0.08,0); subL.Position = UDim2.new(0.25,0,0.65,0)
		subL.BackgroundTransparency = 1; subL.Text = "S W E E T   D R E A M S"
		subL.TextColor3 = Color3.fromRGB(255,0,80); subL.TextScaled = true
		subL.Font = Enum.Font.GothamBold; subL.ZIndex = 106; subL.Parent = jsF

		for _, xPos in ipairs({0.15, 0.6}) do
			local eye = Instance.new("Frame")
			eye.Size = UDim2.new(0.2,0,0.15,0); eye.Position = UDim2.new(xPos,0,0.12,0)
			eye.BackgroundColor3 = Color3.fromRGB(255,0,50); eye.ZIndex = 108; eye.Parent = jsF
			Instance.new("UICorner", eye).CornerRadius = UDim.new(1,0)
		end

		local startT = tick()
		local sc
		sc = RunService.RenderStepped:Connect(function()
			local el = tick() - startT
			if el > 3 then
				sc:Disconnect()
				pcall(function() hs:Stop(); hs:Destroy() end)
				jsF:Destroy()
				pcall(function() humanoid.Health = 0 end)
				jumpscareActive = false
				return
			end
			if el < 0.3 then
				jsF.BackgroundColor3 = Color3.new(1, 1-el/0.3, 1-el/0.3)
			elseif el < 1.5 then
				local fl = math.sin((el-0.3)*30)
				jsF.BackgroundColor3 = fl > 0 and Color3.fromRGB(120,0,60) or Color3.new(0,0,0)
				local i2 = math.floor(35*(1-(el-0.3)/1.2))
				jsF.Position = UDim2.new(0, math.random(-i2,i2), 0, math.random(-i2,i2))
				subL.TextTransparency = math.sin((el-0.3)*15) > 0 and 0 or 1
			else
				jsF.BackgroundColor3 = Color3.new(0,0,0)
				jsF.BackgroundTransparency = math.min((el-1.5)/1.5*0.5, 0.5)
				jsF.Position = UDim2.new(0,0,0,0)
			end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- SPAWN & IA CATNAP
-- ═══════════════════════════════════════════════════════════════════

function spawnCatNap(pos)
	if catNapModel then pcall(function() catNapModel:Destroy() end) end

	local model, rig = buildNightmareCatNap()
	model.Parent = workspace
	catNapModel = model; catNapRig = rig
	catNapHP = catNapMaxHP; catNapAlive = true; catNapAnimTimer = 0; lastTPTime = tick()

	local angle = math.rad(math.random(0, 360))
	local dist = math.random(60, 80)
	local playerY = rootPart.Position.Y

	local spawnPos = pos or Vector3.new(
		rootPart.Position.X + math.cos(angle) * dist,
		playerY,
		rootPart.Position.Z + math.sin(angle) * dist
	)

	local footOffset = 5.8
	local lookCF = CFrame.lookAt(
		spawnPos + Vector3.new(0, footOffset, 0),
		Vector3.new(rootPart.Position.X, spawnPos.Y + footOffset, rootPart.Position.Z)
	)
	model:PivotTo(lookCF)

	local gs = snd(SND.growl, 1.5); gs:Play(); Debris:AddItem(gs, 3)
end

local function updateCatNapAI(dt)
	if not catNapModel or not catNapModel.PrimaryPart or not catNapAlive then return end
	if not rootPart or not rootPart.Parent then return end

	catNapAnimTimer = catNapAnimTimer + dt

	local catPos = catNapModel.PrimaryPart.Position
	local playerPos = rootPart.Position
	local direction = (playerPos - catPos)
	local horizDir = Vector3.new(direction.X, 0, direction.Z)
	local distance = horizDir.Magnitude
	local now = tick()
	local isMoving = false

	if distance > ATTACK_RANGE then
		if now - lastTPTime >= TP_INTERVAL then
			lastTPTime = now
			isMoving = true

			local stepDist = math.min(TP_DISTANCE, distance - ATTACK_RANGE + 1)
			local moveDir = horizDir.Unit
			local newPos = catPos + moveDir * stepDist

			local footOffset = 5.8
			newPos = Vector3.new(newPos.X, playerPos.Y + footOffset, newPos.Z)

			local lookTarget = Vector3.new(playerPos.X, newPos.Y, playerPos.Z)
			local lookCF = CFrame.lookAt(newPos, lookTarget)
			catNapModel:PivotTo(lookCF)

			if math.random() > 0.5 then
				local fs = snd(SND.footstep, 0.5); fs:Play(); Debris:AddItem(fs, 1)
			end
		end
		isMoving = true
	end

	pcall(function()
		animCatNap(catNapRig, catNapAnimTimer, isMoving)
	end)

	if distance <= ATTACK_RANGE and not jumpscareActive then
		doCatNapJumpscare()
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- START / STOP EVENT
-- ═══════════════════════════════════════════════════════════════════

local function startEvent()
	if eventActive then return end
	eventActive = true; codeEntered = false
	catNapHP = catNapMaxHP; catNapAlive = true

	activateSmoke()

	local amb = snd(SND.ambient, 0.5, true); amb:Play()
	local br = snd(SND.breathing, 0.3, true); br:Play()

	task.wait(1); createWeapon()
	task.wait(0.5); buildStructure()
	task.wait(2); spawnCatNap()

	local mainConn = RunService.Heartbeat:Connect(function(dt)
		if not eventActive then return end
		updateCatNapAI(dt)
	end)
	table.insert(eventConnections, mainConn)
end

function stopEvent(victory)
	eventActive = false
	for _, c in pairs(eventConnections) do pcall(function() c:Disconnect() end) end
	eventConnections = {}

	deactivateSmoke(); cleanSounds(); removeWeapon()
	if catNapModel then catNapModel:Destroy(); catNapModel = nil end
	if codeStructure then codeStructure:Destroy(); codeStructure = nil end
	if proximityConn then pcall(function() proximityConn:Disconnect() end); proximityConn = nil end

	closeCodeGui()

	catNapAlive = false; codeEntered = false; jumpscareActive = false

	local gui = player.PlayerGui:FindFirstChild("CoolKidCatNap")
	if gui and victory then
		local vf = Instance.new("Frame")
		vf.Size = UDim2.new(1,0,1,0); vf.BackgroundColor3 = Color3.new(0,0,0)
		vf.BackgroundTransparency = 0.3; vf.ZIndex = 90; vf.Parent = gui

		local vt = Instance.new("TextLabel")
		vt.Size = UDim2.new(0.8,0,0.15,0); vt.Position = UDim2.new(0.1,0,0.35,0)
		vt.BackgroundTransparency = 1; vt.Text = "🎉 NIGHTMARE CATNAP VAINCU!"
		vt.TextColor3 = CC.green; vt.TextScaled = true; vt.Font = Enum.Font.GothamBold
		vt.TextStrokeTransparency = 0; vt.ZIndex = 91; vt.Parent = vf

		local vs = snd(SND.victory, 2); vs:Play(); Debris:AddItem(vs, 5)

		task.delay(5, function()
			TweenService:Create(vf, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
			TweenService:Create(vt, TweenInfo.new(2), {TextTransparency = 1}):Play()
			task.wait(2.5); vf:Destroy()
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- GUI PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════

local sg = Instance.new("ScreenGui"); sg.Name = "CoolKidCatNap"
sg.ResetOnSpawn = false; sg.Parent = player.PlayerGui

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0,52,0,52); toggleBtn.Position = UDim2.new(0,12,0.5,-26)
toggleBtn.BackgroundColor3 = CC.accent; toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "😈"; toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 28; toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.ZIndex = 10; toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,12)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0,340,0,380); mainFrame.Position = UDim2.new(0,72,0.5,-190)
mainFrame.BackgroundColor3 = CC.bg; mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 5; mainFrame.Visible = false; mainFrame.Parent = sg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,16)
Instance.new("UIStroke", mainFrame).Color = CC.accent

local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,50); header.BackgroundColor3 = CC.darkPurp
header.BorderSizePixel = 0; header.ZIndex = 6; header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0,16)

local hTitle = Instance.new("TextLabel")
hTitle.Size = UDim2.new(1,-60,1,0); hTitle.Position = UDim2.new(0,14,0,0)
hTitle.BackgroundTransparency = 1; hTitle.Text = "😈 COOLKID CATNAP v3"
hTitle.TextColor3 = Color3.new(1,1,1); hTitle.TextSize = 15; hTitle.Font = Enum.Font.GothamBold
hTitle.TextXAlignment = Enum.TextXAlignment.Left; hTitle.ZIndex = 7; hTitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,32,0,32); closeBtn.Position = UDim2.new(1,-42,0.5,-16)
closeBtn.BackgroundColor3 = CC.red; closeBtn.Text = "✕"; closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 14; closeBtn.Font = Enum.Font.GothamBold; closeBtn.ZIndex = 7; closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-20,1,-60); scroll.Position = UDim2.new(0,10,0,55)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = CC.accent; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 6; scroll.Parent = mainFrame
Instance.new("UIListLayout", scroll).Padding = UDim.new(0,6)

local descF = Instance.new("Frame")
descF.Size = UDim2.new(1,0,0,110); descF.BackgroundColor3 = CC.card; descF.BorderSizePixel = 0
descF.LayoutOrder = 1; descF.ZIndex = 7; descF.Parent = scroll
Instance.new("UICorner", descF).CornerRadius = UDim.new(0,8)

local descT = Instance.new("TextLabel")
descT.Size = UDim2.new(1,-12,1,-6); descT.Position = UDim2.new(0,6,0,3)
descT.BackgroundTransparency = 1; descT.TextWrapped = true
descT.Text = "🔴 Fumée rouge réaliste sur la map\n😈 CatNap avance vers vous par petits TP\n⚔️ Clic gauche sur CatNap = frapper\n🏠 Trouvez le bâtiment 'Zone de CatNap'\n📝 Un papier sur la table contient le code\n🔒 Approchez le terminal et appuyez E\n⌨️ Tapez le code dans le clavier GUI\n💀 S'il vous touche = mort"
descT.TextColor3 = CC.text; descT.TextSize = 9; descT.Font = Enum.Font.Gotham
descT.TextXAlignment = Enum.TextXAlignment.Left; descT.TextYAlignment = Enum.TextYAlignment.Top
descT.ZIndex = 8; descT.Parent = descF

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1,0,0,45); startBtn.BackgroundColor3 = CC.accent
startBtn.Text = "🎮 ACTIVER L'ÉVÉNEMENT"; startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.TextSize = 13; startBtn.Font = Enum.Font.GothamBold
startBtn.LayoutOrder = 2; startBtn.ZIndex = 7; startBtn.Parent = scroll
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0,10)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1,0,0,35); stopBtn.BackgroundColor3 = CC.red
stopBtn.Text = "⏹ ARRÊTER"; stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.TextSize = 12; stopBtn.Font = Enum.Font.GothamBold
stopBtn.LayoutOrder = 3; stopBtn.ZIndex = 7; stopBtn.Parent = scroll
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0,8)

local infoF = Instance.new("Frame")
infoF.Size = UDim2.new(1,0,0,45); infoF.BackgroundColor3 = CC.card; infoF.BorderSizePixel = 0
infoF.LayoutOrder = 4; infoF.ZIndex = 7; infoF.Parent = scroll
Instance.new("UICorner", infoF).CornerRadius = UDim.new(0,8)

local infoT = Instance.new("TextLabel")
infoT.Size = UDim2.new(1,-12,1,-6); infoT.Position = UDim2.new(0,6,0,3)
infoT.BackgroundTransparency = 1; infoT.TextWrapped = true
infoT.Text = "⌨️ [N] Menu | 🖱️ Clic sur CatNap = Frapper\n📋 E sur terminal = Clavier | 📝 Code sur papier"
infoT.TextColor3 = CC.dim; infoT.TextSize = 9; infoT.Font = Enum.Font.Gotham
infoT.TextXAlignment = Enum.TextXAlignment.Left; infoT.ZIndex = 8; infoT.Parent = infoF

-- Events
startBtn.MouseButton1Click:Connect(function()
	if eventActive then return end
	startBtn.BackgroundColor3 = Color3.fromRGB(60,0,80)
	task.spawn(startEvent)
end)

stopBtn.MouseButton1Click:Connect(function()
	if eventActive then stopEvent(false); startBtn.BackgroundColor3 = CC.accent end
end)

toggleBtn.MouseButton1Click:Connect(function()
	guiOpen = not guiOpen; mainFrame.Visible = guiOpen
	if guiOpen then
		mainFrame.Position = UDim2.new(0,52,0.5,-190)
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = UDim2.new(0,72,0.5,-190)
		}):Play()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	guiOpen = false
	TweenService:Create(mainFrame, TweenInfo.new(0.2), {Position = UDim2.new(0,52,0.5,-190)}):Play()
	task.wait(0.2); mainFrame.Visible = false
end)

-- ═══════════════════════════════════════════════════════════════════
-- INPUT (Raycast clic + N toggle)
-- ═══════════════════════════════════════════════════════════════════

UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end

	if inp.KeyCode == Enum.KeyCode.N then
		guiOpen = not guiOpen; mainFrame.Visible = guiOpen
	end

	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		if not eventActive or not playerHasWeapon or not catNapAlive then return end
		if codeGuiOpen then return end -- ne pas frapper si le clavier est ouvert

		local mouse = player:GetMouse()
		local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {character}
		if weaponModel then table.insert(excludeList, weaponModel) end
		rayParams.FilterDescendantsInstances = excludeList

		local result = workspace:Raycast(ray.Origin, ray.Direction * WEAPON_RANGE, rayParams)

		if result and result.Instance then
			local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
			if hitModel and hitModel.Name == "CN_CatNap" then
				swingWeapon()
			else
				-- Swing dans le vide
				if canSwing then
					canSwing = false
					local ws = snd(SND.weaponSwing, 0.8); ws:Play(); Debris:AddItem(ws, 1)
					task.wait(SWING_COOLDOWN)
					canSwing = true
				end
			end
		else
			if canSwing then
				canSwing = false
				local ws = snd(SND.weaponSwing, 0.8); ws:Play(); Debris:AddItem(ws, 1)
				task.wait(SWING_COOLDOWN)
				canSwing = true
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- RENDER LOOP (bouton pulse)
-- ═══════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
	local t = tick()
	local p2 = math.sin(t*2)*0.15+0.85
	toggleBtn.BackgroundColor3 = eventActive
		and Color3.fromRGB(math.floor(150*p2), 0, math.floor(200*p2))
		or CC.accent
end)

-- ═══════════════════════════════════════════════════════════════════
-- RESPAWN JOUEUR
-- ═══════════════════════════════════════════════════════════════════

player.CharacterAdded:Connect(function(nc)
	character = nc
	humanoid = nc:WaitForChild("Humanoid")
	rootPart = nc:WaitForChild("HumanoidRootPart")
	jumpscareActive = false
	closeCodeGui()
	if eventActive then
		task.wait(2)
		if eventActive then createWeapon() end
	end
end)

-- ═══════════════════════════════════════════════════════════════════
-- NOTIFICATION DE LANCEMENT
-- ═══════════════════════════════════════════════════════════════════

task.spawn(function()
	task.wait(1)
	local n = Instance.new("Frame")
	n.Size = UDim2.new(0,400,0,60); n.Position = UDim2.new(0.5,-200,0,-70)
	n.BackgroundColor3 = CC.card; n.BorderSizePixel = 0; n.ZIndex = 50; n.Parent = sg
	Instance.new("UICorner", n).CornerRadius = UDim.new(0,12)
	Instance.new("UIStroke", n).Color = CC.accent

	local nt = Instance.new("TextLabel")
	nt.Size = UDim2.new(1,-16,0,24); nt.Position = UDim2.new(0,12,0,5)
	nt.BackgroundTransparency = 1; nt.Text = "😈 CoolKid CatNap v3.0"
	nt.TextColor3 = Color3.new(1,1,1); nt.TextSize = 14; nt.Font = Enum.Font.GothamBold
	nt.TextXAlignment = Enum.TextXAlignment.Left; nt.ZIndex = 51; nt.Parent = n

	local ns = Instance.new("TextLabel")
	ns.Size = UDim2.new(1,-16,0,20); ns.Position = UDim2.new(0,12,0,30)
	ns.BackgroundTransparency = 1
	ns.Text = "[N] Menu | Code aléatoire | Papier indice | Terminal ProximityPrompt"
	ns.TextColor3 = CC.dim; ns.TextSize = 9; ns.Font = Enum.Font.Gotham
	ns.TextXAlignment = Enum.TextXAlignment.Left; ns.ZIndex = 51; ns.Parent = n

	TweenService:Create(n, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = UDim2.new(0.5,-200,0,12)}):Play()
	task.wait(6)
	TweenService:Create(n, TweenInfo.new(0.3), {Position = UDim2.new(0.5,-200,0,-70)}):Play()
	task.wait(0.4); n:Destroy()
end)

print("═══════════════════════════════════════")
print(" 😈 CoolKid CatNap v3.0")
print(" ✅ Fumée rouge réaliste (ParticleEmitter)")
print(" ✅ Code ALÉATOIRE à chaque partie")
print(" ✅ Papier avec le code sur la table")
print(" ✅ Terminal avec ProximityPrompt (E)")
print(" ✅ GUI Clavier dans l'écran (pas dans la part)")
print(" ✅ Structure jolie: colonnes, fronton, néons")
print(" ✅ TextLabel 'Zone de CatNap' à l'entrée")
print(" ✅ Salles collées: Hall → Couloir → Salle Code")
print(" ✅ Respawn CatNap après 20s (FIX)")
print(" ✅ Clic sur CatNap = frapper (Raycast)")
print(" ⌨️ [N] Menu | [E] Terminal | Clic = Frapper")
print("═══════════════════════════════════════")
