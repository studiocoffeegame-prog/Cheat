-- ═══════════════════════════════════════════════════════════════════
-- THE DOCTOR — ELECTRO-NIGHTMARE EVENT v4.0
-- Basé sur le système CatNap v3.0, redesigné pour The Doctor
-- Statues TV-Head + Éveil progressif + Batteries + Machine centrale
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
		if v.Name == "DoctorEventGui" then v:Destroy() end
	end
	for _, v in pairs(Lighting:GetChildren()) do
		if v.Name:sub(1,3) == "TD_" then v:Destroy() end
	end
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:sub(1,3) == "TD_" then v:Destroy() end
	end
end
FullClean()

-- ═══════════════════════════════════════
-- CONFIGURATION & VARIABLES
-- ═══════════════════════════════════════
local eventActive = false
local batteriesFound = 0
local batteriesRequired = 3
local activeDoctors = {}
local doctorConnections = {}
local eventConnections = {}
local doctorRoom = nil
local jumpscareActive = false
local playerHasWeapon = false
local weaponModel = nil
local canSwing = true
local guiOpen = false
local machineActivated = false

local DOCTOR_SPEED = 28
local WAKE_DIST = 40
local CHASE_DIST = 25
local ATTACK_RANGE = 5
local WEAPON_RANGE = 200
local SWING_COOLDOWN = 0.8
local MAX_DOCTORS = 8
local DOCTOR_SPAWN_INTERVAL = 12
local TP_DISTANCE = 3.0
local TP_INTERVAL = 0.25

local COLORS = {
	bg = Color3.fromRGB(8, 8, 12),
	card = Color3.fromRGB(15, 15, 22),
	cardH = Color3.fromRGB(25, 25, 35),
	accent = Color3.fromRGB(200, 0, 40),
	accentG = Color3.fromRGB(255, 50, 50),
	neonRed = Color3.fromRGB(255, 0, 40),
	neonYellow = Color3.fromRGB(255, 220, 0),
	neonCyan = Color3.fromRGB(0, 255, 255),
	neonBlue = Color3.fromRGB(0, 120, 255),
	metal = Color3.fromRGB(35, 35, 40),
	metalLight = Color3.fromRGB(55, 55, 65),
	metalDark = Color3.fromRGB(20, 20, 25),
	cloak = Color3.fromRGB(160, 150, 140),
	cloakDark = Color3.fromRGB(80, 75, 70),
	screenOff = Color3.fromRGB(5, 5, 8),
	screenYellow = Color3.fromRGB(255, 200, 0),
	screenRed = Color3.fromRGB(255, 0, 30),
	green = Color3.fromRGB(0, 200, 80),
	text = Color3.fromRGB(230, 230, 240),
	dim = Color3.fromRGB(100, 100, 120),
	darkBg = Color3.fromRGB(5, 5, 8),
	wire = Color3.fromRGB(180, 30, 30),
}

local SND = {
	static = "rbxassetid://140217414944350",
	hum = "rbxassetid://140387147907236",
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
	powerDown = "rbxassetid://133973844653286",
	machineHum = "rbxassetid://88423610384477",
	wakeUp = "rbxassetid://137614563859074",
	ambient = "rbxassetid://131190991150526",
	breathing = "rbxassetid://139358149909471",
	growl = "rbxassetid://138016581135405",
}

-- ═══════════════════════════════════════
-- UTILITAIRES
-- ═══════════════════════════════════════
local function snd(id, vol, loop)
	local s = Instance.new("Sound")
	s.SoundId = id; s.Volume = vol or 1; s.Looped = loop or false
	s.Name = "TD_Sound"; s.Parent = SoundService
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
		if s.Name == "TD_Sound" then pcall(function() s:Stop(); s:Destroy() end) end
	end
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a; w.Part1 = b; w.Parent = a; return w
end

local function createPart(par, name, sz, col, mat, tr)
	local p = Instance.new("Part")
	p.Name = "TD_"..name; p.Size = sz; p.Color = col
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

-- ═══════════════════════════════════════════════════════════════════
-- FUMÉE / ATMOSPHÈRE ÉLECTRIQUE
-- ═══════════════════════════════════════════════════════════════════

local smokeFolder = nil
local originalLighting = {}

local function createElectricAtmosphere()
	local folder = Instance.new("Folder")
	folder.Name = "TD_SmokeFolder"
	folder.Parent = workspace

	-- Brouillard sombre avec teinte bleutée/grise
	local gridSize = 6
	local spacing = 50

	for x = -gridSize, gridSize do
		for z = -gridSize, gridSize do
			local smokePart = Instance.new("Part")
			smokePart.Name = "SmokePt"
			smokePart.Size = Vector3.new(1,1,1)
			smokePart.Transparency = 1; smokePart.Anchored = true
			smokePart.CanCollide = false
			smokePart.Position = Vector3.new(x * spacing, 5, z * spacing)
			smokePart.Parent = folder

			local pe = Instance.new("ParticleEmitter")
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 50)),
				ColorSequenceKeypoint.new(0.3, Color3.fromRGB(20, 20, 40)),
				ColorSequenceKeypoint.new(0.7, Color3.fromRGB(15, 15, 30)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 15)),
			})
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 10),
				NumberSequenceKeypoint.new(0.5, 22),
				NumberSequenceKeypoint.new(1, 35),
			})
			pe.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.5, 0.6),
				NumberSequenceKeypoint.new(1, 1),
			})
			pe.Lifetime = NumberRange.new(6, 12)
			pe.Rate = 2; pe.Speed = NumberRange.new(0.3, 1.5)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.RotSpeed = NumberRange.new(-15, 15)
			pe.Rotation = NumberRange.new(0, 360)
			pe.LightEmission = 0.1; pe.LightInfluence = 0.3
			pe.Texture = "rbxassetid://241685484"
			pe.Parent = smokePart
		end
	end

	-- Brouillard au sol
	for i = 1, 20 do
		local gPart = Instance.new("Part")
		gPart.Name = "GroundFog"..i
		gPart.Size = Vector3.new(1,1,1); gPart.Transparency = 1
		gPart.Anchored = true; gPart.CanCollide = false
		gPart.Position = Vector3.new(math.random(-250, 250), 0.5, math.random(-250, 250))
		gPart.Parent = folder

		local pe2 = Instance.new("ParticleEmitter")
		pe2.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 25, 45)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 25)),
		})
		pe2.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 15),
			NumberSequenceKeypoint.new(0.5, 28),
			NumberSequenceKeypoint.new(1, 40),
		})
		pe2.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(0.5, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		})
		pe2.Lifetime = NumberRange.new(8, 15)
		pe2.Rate = 2; pe2.Speed = NumberRange.new(0.2, 0.8)
		pe2.SpreadAngle = Vector2.new(180, 0)
		pe2.RotSpeed = NumberRange.new(-10, 10)
		pe2.LightEmission = 0.05
		pe2.Texture = "rbxassetid://241685484"
		pe2.Parent = gPart
	end

	-- Effets de lumière
	local atmo = Instance.new("Atmosphere")
	atmo.Name = "TD_Atmosphere"
	atmo.Density = 0.4; atmo.Offset = 0.2
	atmo.Color = Color3.fromRGB(20, 20, 40)
	atmo.Decay = Color3.fromRGB(10, 10, 30)
	atmo.Glare = 0.1; atmo.Haze = 8
	atmo.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "TD_CC"
	cc.Brightness = -0.05; cc.Contrast = 0.15
	cc.Saturation = -0.2
	cc.TintColor = Color3.fromRGB(180, 180, 220)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "TD_Bloom"
	bloom.Intensity = 0.3; bloom.Size = 24
	bloom.Threshold = 0.85; bloom.Parent = Lighting

	local sky = Instance.new("Sky")
	sky.Name = "TD_Sky"
	sky.CelestialBodiesShown = false
	sky.SkyboxBk = "rbxassetid://1012890"
	sky.SkyboxDn = "rbxassetid://1012890"
	sky.SkyboxFt = "rbxassetid://1012890"
	sky.SkyboxLf = "rbxassetid://1012890"
	sky.SkyboxRt = "rbxassetid://1012890"
	sky.SkyboxUp = "rbxassetid://1012890"
	sky.StarCount = 0; sky.Parent = Lighting

	Lighting.ClockTime = 2
	Lighting.FogColor = Color3.fromRGB(10, 10, 20)
	Lighting.FogEnd = 300; Lighting.FogStart = 15
	Lighting.Ambient = Color3.fromRGB(15, 15, 30)
	Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 25)
	Lighting.Brightness = 0.8

	return folder
end

local function activateAtmosphere()
	originalLighting.FogColor = Lighting.FogColor
	originalLighting.FogEnd = Lighting.FogEnd
	originalLighting.FogStart = Lighting.FogStart
	originalLighting.ClockTime = Lighting.ClockTime
	originalLighting.Ambient = Lighting.Ambient
	originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
	originalLighting.Brightness = Lighting.Brightness
	smokeFolder = createElectricAtmosphere()
end

local function deactivateAtmosphere()
	if smokeFolder then smokeFolder:Destroy(); smokeFolder = nil end
	Lighting.FogColor = originalLighting.FogColor or Color3.new(0.75,0.75,0.75)
	Lighting.FogEnd = originalLighting.FogEnd or 100000
	Lighting.FogStart = originalLighting.FogStart or 0
	Lighting.ClockTime = originalLighting.ClockTime or 14
	Lighting.Ambient = originalLighting.Ambient or Color3.fromRGB(128,128,128)
	Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient or Color3.fromRGB(128,128,128)
	Lighting.Brightness = originalLighting.Brightness or 2
	for _, n in pairs({"TD_Atmosphere","TD_CC","TD_Sky","TD_Bloom"}) do
		local c = Lighting:FindFirstChild(n)
		if c then c:Destroy() end
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- CONSTRUCTION DU RIG THE DOCTOR (TV HEAD + CORPS ROBOTIQUE + CAPE)
-- ═══════════════════════════════════════════════════════════════════

local function buildTheDoctor()
	local model = Instance.new("Model")
	model.Name = "TD_Doctor"

	local rig = {}

	-- ROOT (invisible)
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1; root.Anchored = true
	root.CanCollide = false; root.Parent = model
	model.PrimaryPart = root

	-- ══════════════════════════════════
	-- TORSE ROBOTIQUE
	-- ══════════════════════════════════
	local torso = createPart(model, "Torso", Vector3.new(2.2, 2.8, 1.2), COLORS.metal, Enum.Material.Metal)
	torso.CFrame = root.CFrame

	local rootMotor = Instance.new("Motor6D")
	rootMotor.Part0 = root; rootMotor.Part1 = torso
	rootMotor.C0 = CFrame.new(); rootMotor.C1 = CFrame.new()
	rootMotor.Parent = root
	rig.Root = rootMotor

	-- Détails torse (plaque pectorale)
	local chestPlate = createPart(model, "ChestPlate", Vector3.new(1.8, 2, 0.3), COLORS.metalLight, Enum.Material.Metal)
	chestPlate.CFrame = torso.CFrame * CFrame.new(0, 0, -0.7)
	weld(torso, chestPlate)

	-- Lumière torse (petit indicateur)
	local chestLight = createPart(model, "ChestLight", Vector3.new(0.3, 0.3, 0.15), COLORS.neonRed, Enum.Material.Neon)
	chestLight.CFrame = chestPlate.CFrame * CFrame.new(0, 0.5, -0.15)
	weld(chestPlate, chestLight)

	-- Câbles sortant du torse
	for i = -1, 1, 2 do
		local cable = createPart(model, "Cable"..i, Vector3.new(0.15, 0.15, 1.5), COLORS.wire, Enum.Material.SmoothPlastic)
		cable.CFrame = torso.CFrame * CFrame.new(i * 0.8, 0.5, -0.3) * CFrame.Angles(math.rad(20), math.rad(i * 15), 0)
		weld(torso, cable)
	end

	-- ══════════════════════════════════
	-- COU / CONNECTEUR
	-- ══════════════════════════════════
	local neck = createPart(model, "Neck", Vector3.new(0.6, 0.8, 0.6), COLORS.metalDark, Enum.Material.Metal)
	neck.CFrame = torso.CFrame * CFrame.new(0, 1.8, 0)

	local neckMotor = Instance.new("Motor6D")
	neckMotor.Part0 = torso; neckMotor.Part1 = neck
	neckMotor.C0 = torso.CFrame:ToObjectSpace(neck.CFrame)
	neckMotor.Parent = torso
	rig.Neck = neckMotor

	-- Câbles du cou
	for i = -1, 1, 2 do
		local nCable = createPart(model, "NeckCable"..i, Vector3.new(0.1, 0.6, 0.1), COLORS.wire, Enum.Material.SmoothPlastic)
		nCable.CFrame = neck.CFrame * CFrame.new(i * 0.3, 0, 0.2)
		weld(neck, nCable)
	end

	-- ══════════════════════════════════
	-- TÊTE TV (La pièce maîtresse)
	-- ══════════════════════════════════
	-- Boîtier principal de la TV
	local tvBody = createPart(model, "TVBody", Vector3.new(2.4, 1.8, 1.6), COLORS.metalDark, Enum.Material.Metal)
	tvBody.CFrame = neck.CFrame * CFrame.new(0, 1.3, 0)

	local headMotor = Instance.new("Motor6D")
	headMotor.Part0 = neck; headMotor.Part1 = tvBody
	headMotor.C0 = neck.CFrame:ToObjectSpace(tvBody.CFrame)
	headMotor.Parent = neck
	rig.HeadJoint = headMotor

	-- Cadre de l'écran (bordure)
	local tvFrame = createPart(model, "TVFrame", Vector3.new(2.5, 1.9, 0.15), COLORS.metalLight, Enum.Material.Metal)
	tvFrame.CFrame = tvBody.CFrame * CFrame.new(0, 0, -0.85)
	weld(tvBody, tvFrame)

	-- L'ÉCRAN (la face avant de la TV)
	local screen = createPart(model, "Screen", Vector3.new(2.0, 1.4, 0.1), COLORS.screenOff, Enum.Material.Glass)
	screen.CFrame = tvBody.CFrame * CFrame.new(0, 0, -0.9)
	weld(tvBody, screen)

	-- SurfaceGui pour l'écran
	local sg = Instance.new("SurfaceGui", screen)
	sg.Name = "ScreenGui"; sg.Face = Enum.NormalId.Back
	sg.PixelsPerStud = 50

	local screenFrame = Instance.new("Frame", sg)
	screenFrame.Name = "ScreenFrame"
	screenFrame.Size = UDim2.new(1,0,1,0)
	screenFrame.BackgroundColor3 = Color3.new(0,0,0)
	screenFrame.BorderSizePixel = 0

	-- L'OEIL (commence invisible)
	local eyeFrame = Instance.new("Frame", screenFrame)
	eyeFrame.Name = "EyeFrame"
	eyeFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	eyeFrame.Position = UDim2.new(0.15, 0, 0.15, 0)
	eyeFrame.BackgroundTransparency = 1

	-- Oeil central
	local eyeOuter = Instance.new("Frame", eyeFrame)
	eyeOuter.Name = "EyeOuter"
	eyeOuter.Size = UDim2.new(0.8, 0, 0.8, 0)
	eyeOuter.Position = UDim2.new(0.1, 0, 0.1, 0)
	eyeOuter.BackgroundColor3 = COLORS.neonRed
	eyeOuter.BackgroundTransparency = 1
	eyeOuter.BorderSizePixel = 0
	Instance.new("UICorner", eyeOuter).CornerRadius = UDim.new(1, 0)

	-- Pupille
	local pupil = Instance.new("Frame", eyeOuter)
	pupil.Name = "Pupil"
	pupil.Size = UDim2.new(0.4, 0, 0.4, 0)
	pupil.Position = UDim2.new(0.3, 0, 0.3, 0)
	pupil.BackgroundColor3 = Color3.new(0, 0, 0)
	pupil.BackgroundTransparency = 1
	pupil.BorderSizePixel = 0
	Instance.new("UICorner", pupil).CornerRadius = UDim.new(1, 0)

	-- Lignes de static (effet TV)
	for i = 1, 5 do
		local line = Instance.new("Frame", screenFrame)
		line.Name = "StaticLine"..i
		line.Size = UDim2.new(1, 0, 0.01, 0)
		line.Position = UDim2.new(0, 0, i * 0.18, 0)
		line.BackgroundColor3 = Color3.new(1,1,1)
		line.BackgroundTransparency = 1
		line.BorderSizePixel = 0
	end

	-- Antenne sur la TV
	local antenna1 = createPart(model, "Antenna1", Vector3.new(0.1, 1.5, 0.1), COLORS.metalLight, Enum.Material.Metal)
	antenna1.CFrame = tvBody.CFrame * CFrame.new(-0.5, 1.2, 0) * CFrame.Angles(0, 0, math.rad(-20))
	weld(tvBody, antenna1)

	local antenna2 = createPart(model, "Antenna2", Vector3.new(0.1, 1.2, 0.1), COLORS.metalLight, Enum.Material.Metal)
	antenna2.CFrame = tvBody.CFrame * CFrame.new(0.5, 1.1, 0) * CFrame.Angles(0, 0, math.rad(25))
	weld(tvBody, antenna2)

	-- Petites boules au bout des antennes
	local antTip1 = createPart(model, "AntTip1", Vector3.new(0.2, 0.2, 0.2), COLORS.neonRed, Enum.Material.Neon, 0.5)
	antTip1.Shape = Enum.PartType.Ball
	antTip1.CFrame = antenna1.CFrame * CFrame.new(0, 0.75, 0)
	weld(antenna1, antTip1)

	local antTip2 = createPart(model, "AntTip2", Vector3.new(0.2, 0.2, 0.2), COLORS.neonRed, Enum.Material.Neon, 0.5)
	antTip2.Shape = Enum.PartType.Ball
	antTip2.CFrame = antenna2.CFrame * CFrame.new(0, 0.6, 0)
	weld(antenna2, antTip2)

	-- ══════════════════════════════════
	-- BRAS ROBOTIQUES
	-- ══════════════════════════════════
	for side = -1, 1, 2 do
		local prefix = side == -1 and "L" or "R"

		-- Épaule (joint sphérique)
		local shoulder = createPart(model, prefix.."Shoulder", Vector3.new(0.6, 0.6, 0.6), COLORS.metalLight, Enum.Material.Metal)
		shoulder.Shape = Enum.PartType.Ball
		shoulder.CFrame = torso.CFrame * CFrame.new(side * 1.4, 0.8, 0)
		weld(torso, shoulder)

		-- Bras supérieur
		local upperArm = createPart(model, prefix.."UpperArm", Vector3.new(0.5, 2, 0.5), COLORS.metal, Enum.Material.Metal)
		upperArm.CFrame = shoulder.CFrame * CFrame.new(0, -1.2, 0)

		local armMotor = Instance.new("Motor6D")
		armMotor.Part0 = torso; armMotor.Part1 = upperArm
		armMotor.C0 = torso.CFrame:ToObjectSpace(upperArm.CFrame)
		armMotor.Parent = torso
		rig[prefix.."ArmMotor"] = armMotor

		-- Coude
		local elbow = createPart(model, prefix.."Elbow", Vector3.new(0.4, 0.4, 0.4), COLORS.metalLight, Enum.Material.Metal)
		elbow.Shape = Enum.PartType.Ball
		elbow.CFrame = upperArm.CFrame * CFrame.new(0, -1.2, 0)
		weld(upperArm, elbow)

		-- Avant-bras
		local lowerArm = createPart(model, prefix.."LowerArm", Vector3.new(0.4, 1.8, 0.4), COLORS.metal, Enum.Material.Metal)
		lowerArm.CFrame = elbow.CFrame * CFrame.new(0, -1.1, 0)
		weld(elbow, lowerArm)

		-- Main (griffes robotiques)
		local hand = createPart(model, prefix.."Hand", Vector3.new(0.5, 0.5, 0.3), COLORS.metalDark, Enum.Material.Metal)
		hand.CFrame = lowerArm.CFrame * CFrame.new(0, -1.1, 0)
		weld(lowerArm, hand)

		-- Doigts
		for f = -1, 1 do
			local finger = createPart(model, prefix.."Finger"..f, Vector3.new(0.1, 0.6, 0.1), COLORS.metalLight, Enum.Material.Metal)
			finger.CFrame = hand.CFrame * CFrame.new(f * 0.15, -0.4, 0) * CFrame.Angles(math.rad(10), 0, 0)
			weld(hand, finger)
		end
	end

	-- ══════════════════════════════════
	-- CAPE / CLOAK (Lambeaux)
	-- ══════════════════════════════════
	-- Cape principale
	local cloakMain = createPart(model, "CloakMain", Vector3.new(2.8, 3.5, 0.2), COLORS.cloak, Enum.Material.Fabric)
	cloakMain.Transparency = 0.15
	cloakMain.CFrame = torso.CFrame * CFrame.new(0, -0.5, 0.6)

	local cloakMotor = Instance.new("Motor6D")
	cloakMotor.Part0 = torso; cloakMotor.Part1 = cloakMain
	cloakMotor.C0 = torso.CFrame:ToObjectSpace(cloakMain.CFrame)
	cloakMotor.Parent = torso
	rig.CloakMotor = cloakMotor

	-- Lambeaux de cape
	for i = 1, 4 do
		local tear = createPart(model, "CloakTear"..i, 
			Vector3.new(math.random(5,12)/10, math.random(8,20)/10, 0.1), 
			COLORS.cloakDark, Enum.Material.Fabric)
		tear.Transparency = 0.2
		tear.CFrame = cloakMain.CFrame * CFrame.new(
			math.random(-10,10)/10, 
			-1.5 + math.random(-5,5)/10, 
			math.random(-2,2)/10
		)
		weld(cloakMain, tear)
	end

	-- Cape sur les épaules
	local cloakTop = createPart(model, "CloakTop", Vector3.new(3.2, 0.8, 1.5), COLORS.cloak, Enum.Material.Fabric)
	cloakTop.Transparency = 0.1
	cloakTop.CFrame = torso.CFrame * CFrame.new(0, 1.2, 0.2)
	weld(torso, cloakTop)

	-- ══════════════════════════════════
	-- JAMBES ROBOTIQUES (Fines et longues)
	-- ══════════════════════════════════
	rig.LegMotors = {}

	for side = -1, 1, 2 do
		local prefix = side == -1 and "L" or "R"

		-- Hanche
		local hipJoint = createPart(model, prefix.."Hip", Vector3.new(0.5, 0.5, 0.5), COLORS.metalLight, Enum.Material.Metal)
		hipJoint.Shape = Enum.PartType.Ball
		hipJoint.CFrame = torso.CFrame * CFrame.new(side * 0.6, -1.6, 0)
		weld(torso, hipJoint)

		-- Cuisse
		local thigh = createPart(model, prefix.."Thigh", Vector3.new(0.5, 2.5, 0.5), COLORS.metal, Enum.Material.Metal)
		thigh.CFrame = hipJoint.CFrame * CFrame.new(0, -1.5, 0)

		local thighMotor = Instance.new("Motor6D")
		thighMotor.Part0 = torso; thighMotor.Part1 = thigh
		thighMotor.C0 = torso.CFrame:ToObjectSpace(thigh.CFrame)
		thighMotor.Parent = torso
		rig[prefix.."ThighMotor"] = thighMotor

		-- Genou
		local knee = createPart(model, prefix.."Knee", Vector3.new(0.45, 0.45, 0.45), COLORS.metalLight, Enum.Material.Metal)
		knee.Shape = Enum.PartType.Ball
		knee.CFrame = thigh.CFrame * CFrame.new(0, -1.5, 0)

		local kneeMotor = Instance.new("Motor6D")
		kneeMotor.Part0 = thigh; kneeMotor.Part1 = knee
		kneeMotor.C0 = thigh.CFrame:ToObjectSpace(knee.CFrame)
		kneeMotor.Parent = thigh
		rig[prefix.."KneeMotor"] = kneeMotor

		-- Tibia
		local shin = createPart(model, prefix.."Shin", Vector3.new(0.4, 2.5, 0.4), COLORS.metal, Enum.Material.Metal)
		shin.CFrame = knee.CFrame * CFrame.new(0, -1.5, 0)
		weld(knee, shin)

		-- Pied
		local foot = createPart(model, prefix.."Foot", Vector3.new(1.0, 0.3, 1.5), COLORS.metalDark, Enum.Material.Metal)
		foot.CFrame = shin.CFrame * CFrame.new(0, -1.5, 0.3)
		weld(shin, foot)

		table.insert(rig.LegMotors, {thighMotor, kneeMotor, prefix})
	end

	-- Point de lumière sur l'écran (éteint par défaut)
	local screenGlow = Instance.new("PointLight")
	screenGlow.Name = "ScreenGlow"
	screenGlow.Color = COLORS.screenOff
	screenGlow.Brightness = 0; screenGlow.Range = 0
	screenGlow.Parent = screen

	-- Données du Doctor
	local data = {
		screenFrame = screenFrame,
		eyeOuter = eyeOuter,
		pupil = pupil,
		screen = screen,
		screenGlow = screenGlow,
		tvBody = tvBody,
		state = "IDLE", -- IDLE, WAKING, CHASE, DEAD
		lastTPTime = tick(),
		animTimer = 0,
		chaseSound = nil,
		staticLines = {},
	}

	-- Récupérer les lignes de static
	for _, child in pairs(screenFrame:GetChildren()) do
		if child.Name:sub(1, 10) == "StaticLine" then
			table.insert(data.staticLines, child)
		end
	end

	return model, rig, data
end

-- ═══════════════════════════════════════════════════════════════════
-- ANIMATION THE DOCTOR
-- ═══════════════════════════════════════════════════════════════════

local function animDoctor(rig, t, isMoving, state)
	if isMoving then
		local speed = 8
		local cycle = t * speed

		-- Bobbing du corps
		local bob = math.abs(math.sin(cycle * 2)) * 0.3
		if rig.Root then
			rig.Root.Transform = CFrame.new(0, -bob, 0)
		end

		-- Animation bras
		if rig.LArmMotor then
			rig.LArmMotor.Transform = CFrame.Angles(math.sin(cycle) * 0.6, 0, math.rad(-5))
		end
		if rig.RArmMotor then
			rig.RArmMotor.Transform = CFrame.Angles(math.sin(cycle + math.pi) * 0.6, 0, math.rad(5))
		end

		-- Animation jambes
		for _, legData in ipairs(rig.LegMotors or {}) do
			local thighMotor = legData[1]
			local kneeMotor = legData[2]
			local prefix = legData[3]
			local phase = prefix == "L" and 0 or math.pi

			local move = math.sin(cycle + phase)
			thighMotor.Transform = CFrame.Angles(move * 0.5, 0, 0)
			kneeMotor.Transform = CFrame.Angles(math.max(0, -move) * 0.4, 0, 0)
		end

		-- Cape qui bouge
		if rig.CloakMotor then
			rig.CloakMotor.Transform = CFrame.Angles(math.sin(cycle * 0.7) * 0.15, math.sin(cycle * 0.5) * 0.05, 0)
		end

		-- Tête qui oscille
		if rig.HeadJoint then
			rig.HeadJoint.Transform = CFrame.Angles(math.sin(cycle * 0.5) * 0.05, math.sin(cycle * 0.3) * 0.08, 0)
		end

	elseif state == "WAKING" then
		-- Vibration de réveil
		local shake = math.sin(t * 20) * 0.02
		if rig.HeadJoint then
			rig.HeadJoint.Transform = CFrame.Angles(shake, shake, 0)
		end
		if rig.Root then
			rig.Root.Transform = CFrame.new(shake * 2, 0, 0)
		end

	else -- IDLE
		-- Respiration mécanique subtile
		local breathe = math.sin(t * 0.8) * 0.02
		if rig.Root then
			rig.Root.Transform = CFrame.new(0, breathe, 0)
		end

		-- Bras au repos
		if rig.LArmMotor then
			rig.LArmMotor.Transform = CFrame.Angles(math.rad(5), 0, math.rad(-8))
		end
		if rig.RArmMotor then
			rig.RArmMotor.Transform = CFrame.Angles(math.rad(5), 0, math.rad(8))
		end

		-- Jambes droites
		for _, legData in ipairs(rig.LegMotors or {}) do
			legData[1].Transform = CFrame.Angles(0, 0, 0)
			legData[2].Transform = CFrame.Angles(0, 0, 0)
		end
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- IA DU DOCTOR (Statue → Éveil → Chasse)
-- ═══════════════════════════════════════════════════════════════════

local function setupDoctorAI(model, rig, data)
	local connection

	connection = RunService.Heartbeat:Connect(function(dt)
		if not eventActive or not model.Parent or data.state == "DEAD" then
			if connection then connection:Disconnect() end
			return
		end

		if not rootPart or not rootPart.Parent then return end

		local catPos = model.PrimaryPart.Position
		local playerPos = rootPart.Position
		local direction = (playerPos - catPos)
		local horizDir = Vector3.new(direction.X, 0, direction.Z)
		local distance = horizDir.Magnitude
		local now = tick()

		data.animTimer = data.animTimer + dt

		-- ══════════════════════════════
		-- ÉTAT: IDLE (Statue éteinte)
		-- ══════════════════════════════
		if data.state == "IDLE" then
			if distance < WAKE_DIST then
				data.state = "WAKING"
				data.wakeStart = now

				-- Écran s'allume en JAUNE
				TweenService:Create(data.screenFrame, TweenInfo.new(0.5), {
					BackgroundColor3 = Color3.fromRGB(40, 35, 0)
				}):Play()

				-- Oeil jaune apparaît
				TweenService:Create(data.eyeOuter, TweenInfo.new(0.8), {
					BackgroundTransparency = 0,
					BackgroundColor3 = COLORS.neonYellow
				}):Play()
				TweenService:Create(data.pupil, TweenInfo.new(1), {
					BackgroundTransparency = 0
				}):Play()

				-- Lueur jaune
				data.screenGlow.Color = COLORS.neonYellow
				TweenService:Create(data.screenGlow, TweenInfo.new(0.5), {
					Brightness = 2, Range = 15
				}):Play()

				-- Static TV
				for _, line in pairs(data.staticLines) do
					TweenService:Create(line, TweenInfo.new(0.3), {
						BackgroundTransparency = 0.6
					}):Play()
				end

				-- Son d'éveil
				playSnd(SND.wakeUp, 1.5)
				playSnd(SND.static, 0.8)
			end

			pcall(function() animDoctor(rig, data.animTimer, false, "IDLE") end)

		-- ══════════════════════════════
		-- ÉTAT: WAKING (Réveil - Écran jaune)
		-- ══════════════════════════════
		elseif data.state == "WAKING" then
			local wakeTime = now - (data.wakeStart or now)

			-- Animation des lignes de static
			for i, line in pairs(data.staticLines) do
				line.Position = UDim2.new(0, 0, math.fmod(line.Position.Y.Scale + dt * (1 + i * 0.3), 1), 0)
				line.BackgroundTransparency = 0.5 + math.sin(now * 10 + i) * 0.3
			end

			-- Après 2 secondes ou si trop proche → CHASE
			if wakeTime > 2 or distance < CHASE_DIST then
				data.state = "CHASE"

				-- Écran devient ROUGE
				TweenService:Create(data.screenFrame, TweenInfo.new(0.3), {
					BackgroundColor3 = Color3.fromRGB(30, 0, 0)
				}):Play()

				-- Oeil ROUGE
				TweenService:Create(data.eyeOuter, TweenInfo.new(0.3), {
					BackgroundColor3 = COLORS.neonRed
				}):Play()

				-- Lueur rouge
				data.screenGlow.Color = COLORS.neonRed
				TweenService:Create(data.screenGlow, TweenInfo.new(0.3), {
					Brightness = 4, Range = 25
				}):Play()

				-- Cacher les lignes de static
				for _, line in pairs(data.staticLines) do
					TweenService:Create(line, TweenInfo.new(0.2), {
						BackgroundTransparency = 1
					}):Play()
				end

				-- Son d'alerte
				playSnd(SND.alert, 2)

				-- Son de chasse en boucle
				data.chaseSound = playSnd(SND.chase, 0.6, true)
			end

			-- Tourner vers le joueur
			local lookTarget = Vector3.new(playerPos.X, catPos.Y, playerPos.Z)
			local lookCF = CFrame.lookAt(catPos, lookTarget)
			model:PivotTo(lookCF)

			pcall(function() animDoctor(rig, data.animTimer, false, "WAKING") end)

		-- ══════════════════════════════
		-- ÉTAT: CHASE (Poursuite agressive)
		-- ══════════════════════════════
		elseif data.state == "CHASE" then
			local isMoving = false

			if distance > ATTACK_RANGE then
				if now - data.lastTPTime >= TP_INTERVAL then
					data.lastTPTime = now
					isMoving = true

					local stepDist = math.min(TP_DISTANCE, distance - ATTACK_RANGE + 1)
					local moveDir = horizDir.Unit
					local newPos = catPos + moveDir * stepDist

					-- Hauteur du pied
					local footOffset = 4.5
					newPos = Vector3.new(newPos.X, playerPos.Y + footOffset, newPos.Z)

					local lookTarget = Vector3.new(playerPos.X, newPos.Y, playerPos.Z)
					local lookCF = CFrame.lookAt(newPos, lookTarget)
					model:PivotTo(lookCF)

					-- Pas mécaniques
					if math.random() > 0.4 then
						playSnd(SND.footstep, 0.6)
					end
				end
				isMoving = true
			end

			-- Pulsation de l'oeil
			local pulse = math.sin(now * 6) * 0.2
			data.eyeOuter.BackgroundTransparency = pulse
			data.screenGlow.Brightness = 3 + math.sin(now * 4) * 1.5

			-- Static rapide
			for i, line in pairs(data.staticLines) do
				if math.random() > 0.7 then
					line.BackgroundTransparency = math.random(60, 90) / 100
					line.Position = UDim2.new(0, 0, math.random() * 0.9, 0)
				end
			end

			pcall(function() animDoctor(rig, data.animTimer, isMoving, "CHASE") end)

			-- ATTAQUE
			if distance <= ATTACK_RANGE and not jumpscareActive then
				doDoctorJumpscare()
			end

			-- Si le joueur s'éloigne beaucoup, redevenir statue
			if distance > WAKE_DIST * 2.5 then
				data.state = "IDLE"

				-- Éteindre l'écran
				TweenService:Create(data.screenFrame, TweenInfo.new(1), {
					BackgroundColor3 = Color3.new(0,0,0)
				}):Play()
				TweenService:Create(data.eyeOuter, TweenInfo.new(1), {
					BackgroundTransparency = 1
				}):Play()
				TweenService:Create(data.pupil, TweenInfo.new(1), {
					BackgroundTransparency = 1
				}):Play()
				TweenService:Create(data.screenGlow, TweenInfo.new(1), {
					Brightness = 0, Range = 0
				}):Play()
				for _, line in pairs(data.staticLines) do
					TweenService:Create(line, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
				end

				if data.chaseSound then
					pcall(function() data.chaseSound:Stop(); data.chaseSound:Destroy() end)
					data.chaseSound = nil
				end
			end
		end
	end)

	table.insert(doctorConnections, connection)
end

-- ═══════════════════════════════════════════════════════════════════
-- JUMPSCARE THE DOCTOR
-- ═══════════════════════════════════════════════════════════════════

function doDoctorJumpscare()
	if jumpscareActive then return end
	jumpscareActive = true

	local js = playSnd(SND.jumpscare, 3)
	local hs = playSnd(SND.heartbeat, 1.5, true)
	local el = playSnd(SND.electric, 2)

	local gui = player.PlayerGui:FindFirstChild("DoctorEventGui")
	if gui then
		local jsF = Instance.new("Frame")
		jsF.Size = UDim2.new(1,0,1,0)
		jsF.BackgroundColor3 = Color3.new(0,0,0)
		jsF.ZIndex = 100; jsF.Parent = gui

		-- Grand oeil rouge
		local bigEye = Instance.new("Frame")
		bigEye.Size = UDim2.new(0.3, 0, 0.4, 0)
		bigEye.Position = UDim2.new(0.35, 0, 0.2, 0)
		bigEye.BackgroundColor3 = COLORS.neonRed
		bigEye.ZIndex = 108; bigEye.Parent = jsF
		Instance.new("UICorner", bigEye).CornerRadius = UDim.new(1, 0)

		-- Pupille noire
		local bigPupil = Instance.new("Frame")
		bigPupil.Size = UDim2.new(0.35, 0, 0.35, 0)
		bigPupil.Position = UDim2.new(0.325, 0, 0.325, 0)
		bigPupil.BackgroundColor3 = Color3.new(0, 0, 0)
		bigPupil.ZIndex = 109; bigPupil.Parent = bigEye
		Instance.new("UICorner", bigPupil).CornerRadius = UDim.new(1, 0)

		-- Texte
		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(0.9, 0, 0.15, 0)
		nameL.Position = UDim2.new(0.05, 0, 0.65, 0)
		nameL.BackgroundTransparency = 1
		nameL.Text = "THE DOCTOR"
		nameL.TextColor3 = COLORS.neonRed
		nameL.TextScaled = true
		nameL.Font = Enum.Font.GothamBold
		nameL.TextStrokeTransparency = 0
		nameL.TextStrokeColor3 = Color3.new(0.3, 0, 0)
		nameL.ZIndex = 106; nameL.Parent = jsF

		local subL = Instance.new("TextLabel")
		subL.Size = UDim2.new(0.5, 0, 0.06, 0)
		subL.Position = UDim2.new(0.25, 0, 0.82, 0)
		subL.BackgroundTransparency = 1
		subL.Text = "N O   S I G N A L"
		subL.TextColor3 = Color3.fromRGB(255, 100, 100)
		subL.TextScaled = true
		subL.Font = Enum.Font.Code
		subL.ZIndex = 106; subL.Parent = jsF

		-- Lignes de static
		for i = 1, 15 do
			local staticLine = Instance.new("Frame")
			staticLine.Size = UDim2.new(1, 0, 0.005, 0)
			staticLine.Position = UDim2.new(0, 0, math.random() * 0.95, 0)
			staticLine.BackgroundColor3 = Color3.new(1,1,1)
			staticLine.BackgroundTransparency = math.random(30, 70) / 100
			staticLine.ZIndex = 107; staticLine.Parent = jsF
		end

		local startT = tick()
		local sc
		sc = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startT
			if elapsed > 3.5 then
				sc:Disconnect()
				pcall(function() hs:Stop(); hs:Destroy() end)
				jsF:Destroy()
				pcall(function() humanoid.Health = 0 end)
				jumpscareActive = false
				return
			end

			if elapsed < 0.2 then
				jsF.BackgroundColor3 = Color3.new(1, 1, 1)
			elseif elapsed < 0.5 then
				jsF.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
			elseif elapsed < 2 then
				local fl = math.sin((elapsed - 0.5) * 25)
				jsF.BackgroundColor3 = fl > 0 and Color3.fromRGB(40, 0, 0) or Color3.new(0, 0, 0)
				local shake = math.floor(30 * (1 - (elapsed - 0.5) / 1.5))
				jsF.Position = UDim2.new(0, math.random(-shake, shake), 0, math.random(-shake, shake))

				-- Oeil qui pulse
				bigEye.Size = UDim2.new(0.3 + math.sin(elapsed * 8) * 0.05, 0, 0.4 + math.sin(elapsed * 8) * 0.05, 0)

				subL.TextTransparency = math.sin(elapsed * 12) > 0 and 0 or 1
			else
				jsF.BackgroundColor3 = Color3.new(0, 0, 0)
				jsF.BackgroundTransparency = math.min((elapsed - 2) / 1.5 * 0.5, 0.5)
				jsF.Position = UDim2.new(0, 0, 0, 0)
			end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- ARME DU JOUEUR
-- ═══════════════════════════════════════════════════════════════════

local function createWeapon()
	local tool = Instance.new("Model"); tool.Name = "TD_Weapon"

	local handle = createPart(tool, "Handle", Vector3.new(0.3, 4.5, 0.3), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	local batHead = createPart(tool, "BatHead", Vector3.new(0.7, 1.2, 0.7), COLORS.neonCyan, Enum.Material.Neon)
	batHead.CFrame = handle.CFrame * CFrame.new(0, 2.8, 0)
	weld(handle, batHead)

	-- Anneau d'énergie
	local ring = createPart(tool, "Ring", Vector3.new(1.0, 0.15, 1.0), COLORS.neonCyan, Enum.Material.Neon, 0.3)
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = batHead.CFrame * CFrame.Angles(0, 0, math.rad(90))
	weld(batHead, ring)

	local glow = Instance.new("PointLight")
	glow.Color = COLORS.neonCyan; glow.Brightness = 2; glow.Range = 12
	glow.Parent = batHead

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

local function killDoctor(model, rig, data)
	if data.state == "DEAD" then return end
	data.state = "DEAD"

	-- Son
	playSnd(SND.hit, 2)
	playSnd(SND.electric, 1.5)

	-- Arrêter le son de chasse
	if data.chaseSound then
		pcall(function() data.chaseSound:Stop(); data.chaseSound:Destroy() end)
		data.chaseSound = nil
	end

	-- Flash blanc
	for _, p in pairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.5 then
			local orig = p.Color
			p.Color = Color3.new(1, 1, 1)
			task.delay(0.1, function() pcall(function() p.Color = orig end) end)
		end
	end

	-- Écran explose
	TweenService:Create(data.screenFrame, TweenInfo.new(0.3), {
		BackgroundColor3 = Color3.new(1, 1, 1)
	}):Play()

	task.delay(0.3, function()
		-- Particules de mort
		if model.PrimaryPart then
			local deathPos = model.PrimaryPart.Position
			for i = 1, 20 do
				local db = Instance.new("Part")
				db.Name = "TD_Debris"..i
				db.Size = Vector3.new(math.random(3,10)/10, math.random(3,10)/10, math.random(3,10)/10)
				db.Color = Color3.fromRGB(math.random(20,80), math.random(20,80), math.random(20,80))
				db.Material = Enum.Material.Metal
				db.Shape = Enum.PartType.Ball
				db.Anchored = false; db.CanCollide = true
				db.CFrame = CFrame.new(deathPos) * CFrame.new(math.random(-3,3), math.random(0,5), math.random(-3,3))
				db.Velocity = Vector3.new(math.random(-40,40), math.random(15,50), math.random(-40,40))
				db.Parent = workspace
				Debris:AddItem(db, 3)
			end

			-- Étincelles électriques
			local sparkPart = Instance.new("Part")
			sparkPart.Size = Vector3.new(1,1,1); sparkPart.Transparency = 1
			sparkPart.Anchored = true; sparkPart.CanCollide = false
			sparkPart.Position = deathPos; sparkPart.Parent = workspace

			local sparks = Instance.new("ParticleEmitter")
			sparks.Color = ColorSequence.new(COLORS.neonCyan, COLORS.neonBlue)
			sparks.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0)
			})
			sparks.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			})
			sparks.Lifetime = NumberRange.new(0.3, 0.8)
			sparks.Rate = 100; sparks.Speed = NumberRange.new(10, 25)
			sparks.SpreadAngle = Vector2.new(180, 180)
			sparks.LightEmission = 1
			sparks.Texture = "rbxassetid://241685484"
			sparks.Parent = sparkPart

			task.delay(0.5, function() sparks.Enabled = false end)
			Debris:AddItem(sparkPart, 2)
		end

		-- Fade et destruction
		for _, p in pairs(model:GetDescendants()) do
			if p:IsA("BasePart") then
				TweenService:Create(p, TweenInfo.new(0.5), {Transparency = 1}):Play()
			end
		end

		task.delay(0.6, function()
			-- Retirer de la liste
			for i, doc in ipairs(activeDoctors) do
				if doc == model then
					table.remove(activeDoctors, i)
					break
				end
			end
			model:Destroy()
		end)
	end)
end

local function swingWeapon()
	if not canSwing or not playerHasWeapon then return end
	canSwing = false

	playSnd(SND.weaponSwing, 1.2)

	-- Vérifier si on touche un Doctor
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
		if hitModel and hitModel.Name == "TD_Doctor" then
			-- Trouver les données du doctor
			for _, doc in ipairs(activeDoctors) do
				if doc.model == hitModel then
					killDoctor(hitModel, doc.rig, doc.data)
					break
				end
			end
		end
	end

	task.wait(SWING_COOLDOWN)
	canSwing = true
end

-- ═══════════════════════════════════════════════════════════════════
-- SYSTÈME DE BATTERIES — GLOW VISIBLE À TRAVERS LES MURS
-- ═══════════════════════════════════════════════════════════════════

local function findSafeGround(centerX, centerZ, maxAttempts)
	maxAttempts = maxAttempts or 30

	for attempt = 1, maxAttempts do
		local x = centerX + math.random(-250, 250)
		local z = centerZ + math.random(-250, 250)

		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {}
		for _, v in pairs(workspace:GetChildren()) do
			if v.Name:sub(1,3) == "TD_" then
				table.insert(excludeList, v)
			end
		end
		rayParams.FilterDescendantsInstances = excludeList

		local rayResult = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -600, 0), rayParams)

		if rayResult then
			local hitPos = rayResult.Position
			local hitNormal = rayResult.Normal

			if hitNormal.Y > 0.7 then
				local upCheck = workspace:Raycast(hitPos + Vector3.new(0, 0.5, 0), Vector3.new(0, 3, 0), rayParams)
				if not upCheck then
					local blocked = false
					for _, dir in ipairs({Vector3.new(2,0,0), Vector3.new(-2,0,0), Vector3.new(0,0,2), Vector3.new(0,0,-2)}) do
						local sideCheck = workspace:Raycast(hitPos + Vector3.new(0, 1, 0), dir, rayParams)
						if sideCheck and sideCheck.Distance < 1.5 then
							blocked = true; break
						end
					end
					if not blocked then
						return hitPos
					end
				end
			end
		end
	end

	return rootPart.Position + Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
end

-- ═══════════════════════════════════════════════════════════════════
-- SPAWN BATTERY AVEC GLOW QUI TRAVERSE LES MURS
-- ═══════════════════════════════════════════════════════════════════

local function spawnBattery(index)
	local battery = Instance.new("Model")
	battery.Name = "TD_Battery"..index

	-- ══════════════════════════════
	-- CORPS DE LA BATTERIE
	-- ══════════════════════════════
	local body = createAnchoredPart(battery, "BatteryBody", Vector3.new(1, 2, 0.6), Color3.fromRGB(25, 25, 30), Enum.Material.Metal)
	body.CanCollide = true
	battery.PrimaryPart = body

	-- Bandes de couleur néon
	local band1 = createAnchoredPart(battery, "Band1", Vector3.new(1.05, 0.2, 0.65), COLORS.neonCyan, Enum.Material.Neon)
	band1.CanCollide = false
	band1.CFrame = body.CFrame * CFrame.new(0, 0.5, 0)

	local band2 = createAnchoredPart(battery, "Band2", Vector3.new(1.05, 0.2, 0.65), COLORS.neonCyan, Enum.Material.Neon)
	band2.CanCollide = false
	band2.CFrame = body.CFrame * CFrame.new(0, -0.5, 0)

	local band3 = createAnchoredPart(battery, "Band3", Vector3.new(1.05, 0.1, 0.65), COLORS.neonCyan, Enum.Material.Neon)
	band3.CanCollide = false
	band3.CFrame = body.CFrame * CFrame.new(0, 0, 0)

	-- Borne positive
	local terminal = createAnchoredPart(battery, "Terminal", Vector3.new(0.3, 0.4, 0.3), COLORS.metalLight, Enum.Material.Metal)
	terminal.CanCollide = false
	terminal.CFrame = body.CFrame * CFrame.new(0, 1.2, 0)

	-- Symbole sur la batterie
	local plusGui = Instance.new("SurfaceGui", body)
	plusGui.Face = Enum.NormalId.Front; plusGui.PixelsPerStud = 40
	local plusText = Instance.new("TextLabel", plusGui)
	plusText.Size = UDim2.new(1,0,1,0); plusText.BackgroundTransparency = 1
	plusText.Text = "⚡"; plusText.TextColor3 = COLORS.neonCyan
	plusText.TextScaled = true; plusText.Font = Enum.Font.GothamBold

	local plusGui2 = Instance.new("SurfaceGui", body)
	plusGui2.Face = Enum.NormalId.Back; plusGui2.PixelsPerStud = 40
	local plusText2 = plusText:Clone(); plusText2.Parent = plusGui2

	local plusGui3 = Instance.new("SurfaceGui", body)
	plusGui3.Face = Enum.NormalId.Left; plusGui3.PixelsPerStud = 40
	local plusText3 = plusText:Clone(); plusText3.Parent = plusGui3

	local plusGui4 = Instance.new("SurfaceGui", body)
	plusGui4.Face = Enum.NormalId.Right; plusGui4.PixelsPerStud = 40
	local plusText4 = plusText:Clone(); plusText4.Parent = plusGui4

	-- ══════════════════════════════════════════════════════════════
	-- ⭐ HIGHLIGHT — GLOW QUI TRAVERSE LES MURS ⭐
	-- C'est ÇA qui rend la batterie visible à travers les murs!
	-- ══════════════════════════════════════════════════════════════
	local highlight = Instance.new("Highlight")
	highlight.Name = "TD_BatteryHighlight"
	highlight.Parent = battery
	highlight.Adornee = battery
	highlight.FillColor = COLORS.neonCyan
	highlight.FillTransparency = 0.5      -- Semi-transparent pour l'effet glow
	highlight.OutlineColor = COLORS.neonCyan
	highlight.OutlineTransparency = 0      -- Contour bien visible
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  -- ⭐ VISIBLE À TRAVERS LES MURS
	highlight.Enabled = true

	-- ══════════════════════════════════════════════════════════════
	-- ⭐ BILLBOARD GUI — ICÔNE VISIBLE À TRAVERS LES MURS ⭐
	-- Un gros indicateur lumineux visible de partout
	-- ══════════════════════════════════════════════════════════════
	local billboardPart = Instance.new("Part")
	billboardPart.Name = "TD_BillboardAnchor"
	billboardPart.Size = Vector3.new(0.1, 0.1, 0.1)
	billboardPart.Transparency = 1; billboardPart.Anchored = true
	billboardPart.CanCollide = false
	billboardPart.Position = body.Position + Vector3.new(0, 3, 0)
	billboardPart.Parent = battery

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TD_BatteryBillboard"
	billboard.Parent = billboardPart
	billboard.Adornee = billboardPart
	billboard.Size = UDim2.new(0, 80, 0, 80)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = true               -- ⭐ VISIBLE À TRAVERS LES MURS
	billboard.MaxDistance = 500                  -- Visible de très loin
	billboard.LightInfluence = 0               -- Pas affecté par la lumière
	billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Cercle de glow extérieur (halo)
	local outerGlow = Instance.new("ImageLabel")
	outerGlow.Name = "OuterGlow"
	outerGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
	outerGlow.Position = UDim2.new(-0.25, 0, -0.25, 0)
	outerGlow.BackgroundTransparency = 1
	outerGlow.Image = "rbxassetid://131771103592634" -- Cercle radial glow
	outerGlow.ImageColor3 = COLORS.neonCyan
	outerGlow.ImageTransparency = 0.3
	outerGlow.ZIndex = 1
	outerGlow.Parent = billboard

	-- Cercle principal
	local mainGlow = Instance.new("Frame")
	mainGlow.Name = "MainGlow"
	mainGlow.Size = UDim2.new(0.5, 0, 0.5, 0)
	mainGlow.Position = UDim2.new(0.25, 0, 0.25, 0)
	mainGlow.BackgroundColor3 = COLORS.neonCyan
	mainGlow.BackgroundTransparency = 0.1
	mainGlow.BorderSizePixel = 0
	mainGlow.ZIndex = 2
	mainGlow.Parent = billboard
	Instance.new("UICorner", mainGlow).CornerRadius = UDim.new(1, 0)

	-- Icône batterie au centre
	local batteryIcon = Instance.new("TextLabel")
	batteryIcon.Name = "BatteryIcon"
	batteryIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
	batteryIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
	batteryIcon.BackgroundTransparency = 1
	batteryIcon.Text = "⚡"
	batteryIcon.TextColor3 = Color3.new(1, 1, 1)
	batteryIcon.TextScaled = true
	batteryIcon.Font = Enum.Font.GothamBold
	batteryIcon.ZIndex = 3
	batteryIcon.Parent = mainGlow

	-- Anneau extérieur pulsant
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.Size = UDim2.new(0.7, 0, 0.7, 0)
	ring.Position = UDim2.new(0.15, 0, 0.15, 0)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.ZIndex = 2
	ring.Parent = billboard
	local ringStroke = Instance.new("UIStroke")
	ringStroke.Color = COLORS.neonCyan
	ringStroke.Thickness = 2
	ringStroke.Transparency = 0.3
	ringStroke.Parent = ring
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)

	-- Texte de distance
	local distLabel = Instance.new("TextLabel")
	distLabel.Name = "DistLabel"
	distLabel.Size = UDim2.new(1, 0, 0, 20)
	distLabel.Position = UDim2.new(0, 0, 1, 5)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = "? m"
	distLabel.TextColor3 = COLORS.neonCyan
	distLabel.TextScaled = true
	distLabel.Font = Enum.Font.Code
	distLabel.TextStrokeTransparency = 0
	distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	distLabel.ZIndex = 3
	distLabel.Parent = billboard

	-- ══════════════════════════════════════════════════════════════
	-- ⭐ ANIMATION DE PULSATION DU GLOW ⭐
	-- ══════════════════════════════════════════════════════════════
	local glowConnection
	glowConnection = RunService.Heartbeat:Connect(function()
		if not battery.Parent then
			glowConnection:Disconnect()
			return
		end

		local t = tick()

		-- Pulsation du Highlight
		local pulse = math.sin(t * 3) * 0.15
		highlight.FillTransparency = 0.45 + pulse
		highlight.OutlineTransparency = 0.1 + pulse * 0.5

		-- Pulsation du Billboard
		local scale = 1 + math.sin(t * 2.5) * 0.15
		billboard.Size = UDim2.new(0, 80 * scale, 0, 80 * scale)

		-- Rotation de l'anneau
		ring.Rotation = (t * 60) % 360

		-- Pulsation du glow extérieur
		outerGlow.ImageTransparency = 0.25 + math.sin(t * 2) * 0.2

		-- Pulsation du cercle principal
		mainGlow.BackgroundTransparency = 0.05 + math.sin(t * 3) * 0.15

		-- Pulsation du stroke de l'anneau
		ringStroke.Transparency = 0.2 + math.sin(t * 4) * 0.3
		ringStroke.Thickness = 2 + math.sin(t * 3) * 1

		-- Distance du joueur
		if rootPart and rootPart.Parent and body and body.Parent then
			local dist = math.floor((rootPart.Position - body.Position).Magnitude)
			distLabel.Text = dist .. "m"

			-- Le glow devient plus intense quand on est proche
			if dist < 30 then
				mainGlow.BackgroundColor3 = Color3.new(
					COLORS.neonCyan.R + math.sin(t * 5) * 0.1,
					COLORS.neonCyan.G + math.sin(t * 5) * 0.1,
					COLORS.neonCyan.B
				)
				highlight.FillTransparency = 0.3 + pulse * 0.5
				billboard.MaxDistance = 500
			elseif dist < 80 then
				billboard.MaxDistance = 500
			else
				billboard.MaxDistance = 500
			end

			-- Effet de "respiration" des bandes néon
			if band1 and band1.Parent then
				local neonPulse = math.sin(t * 4) * 0.3
				band1.Transparency = math.max(0, neonPulse)
				band2.Transparency = math.max(0, math.sin(t * 4 + 1) * 0.3)
				band3.Transparency = math.max(0, math.sin(t * 4 + 2) * 0.3)
			end
		end
	end)

	-- ══════════════════════════════════════════════════════════════
	-- PARTICULES PHYSIQUES (en plus du glow à travers les murs)
	-- ══════════════════════════════════════════════════════════════
	local glowPart = Instance.new("Part")
	glowPart.Name = "TD_BatteryGlowPart"
	glowPart.Size = Vector3.new(1,1,1); glowPart.Transparency = 1
	glowPart.Anchored = true; glowPart.CanCollide = false
	glowPart.Position = body.Position + Vector3.new(0, 0.5, 0)
	glowPart.Parent = battery

	-- Particules qui montent (énergie)
	local energyParticles = Instance.new("ParticleEmitter")
	energyParticles.Name = "EnergyUp"
	energyParticles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.neonCyan),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255)),
	})
	energyParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	energyParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	energyParticles.Lifetime = NumberRange.new(1.5, 3)
	energyParticles.Rate = 20
	energyParticles.Speed = NumberRange.new(1, 3)
	energyParticles.SpreadAngle = Vector2.new(30, 30)
	energyParticles.RotSpeed = NumberRange.new(-30, 30)
	energyParticles.Rotation = NumberRange.new(0, 360)
	energyParticles.LightEmission = 1
	energyParticles.LightInfluence = 0
	energyParticles.Texture = "rbxassetid://241685484"
	energyParticles.Parent = glowPart

	-- Particules qui tournent (orbite)
	local orbitParticles = Instance.new("ParticleEmitter")
	orbitParticles.Name = "Orbit"
	orbitParticles.Color = ColorSequence.new(COLORS.neonCyan)
	orbitParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	orbitParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	orbitParticles.Lifetime = NumberRange.new(1, 2)
	orbitParticles.Rate = 12
	orbitParticles.Speed = NumberRange.new(2, 4)
	orbitParticles.SpreadAngle = Vector2.new(180, 180)
	orbitParticles.LightEmission = 1
	orbitParticles.LightInfluence = 0
	orbitParticles.Texture = "rbxassetid://241685484"
	orbitParticles.Parent = glowPart

	-- Éclairs électriques (petites étincelles)
	local sparkParticles = Instance.new("ParticleEmitter")
	sparkParticles.Name = "Sparks"
	sparkParticles.Color = ColorSequence.new(Color3.new(1, 1, 1), COLORS.neonCyan)
	sparkParticles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkParticles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkParticles.Lifetime = NumberRange.new(0.1, 0.4)
	sparkParticles.Rate = 8
	sparkParticles.Speed = NumberRange.new(5, 12)
	sparkParticles.SpreadAngle = Vector2.new(180, 180)
	sparkParticles.LightEmission = 1
	sparkParticles.Texture = "rbxassetid://241685484"
	sparkParticles.Parent = glowPart

	-- Lumière ponctuelle forte
	local pl = Instance.new("PointLight")
	pl.Name = "BatteryLight"
	pl.Color = COLORS.neonCyan
	pl.Brightness = 4
	pl.Range = 25
	pl.Parent = body

	-- Deuxième lumière plus diffuse
	local pl2 = Instance.new("PointLight")
	pl2.Name = "BatteryLightDiffuse"
	pl2.Color = Color3.fromRGB(0, 180, 220)
	pl2.Brightness = 2
	pl2.Range = 40
	pl2.Parent = glowPart

	-- ══════════════════════════════════════════════════════════════
	-- COLONNE DE LUMIÈRE (Beam vertical visible de loin)
	-- ══════════════════════════════════════════════════════════════
	local beamBottom = Instance.new("Part")
	beamBottom.Name = "TD_BeamBottom"
	beamBottom.Size = Vector3.new(0.1, 0.1, 0.1)
	beamBottom.Transparency = 1; beamBottom.Anchored = true
	beamBottom.CanCollide = false
	beamBottom.Position = body.Position + Vector3.new(0, -0.5, 0)
	beamBottom.Parent = battery

	local beamBottomAttach = Instance.new("Attachment")
	beamBottomAttach.Parent = beamBottom

	local beamTop = Instance.new("Part")
	beamTop.Name = "TD_BeamTop"
	beamTop.Size = Vector3.new(0.1, 0.1, 0.1)
	beamTop.Transparency = 1; beamTop.Anchored = true
	beamTop.CanCollide = false
	beamTop.Position = body.Position + Vector3.new(0, 30, 0)  -- 30 studs de haut
	beamTop.Parent = battery

	local beamTopAttach = Instance.new("Attachment")
	beamTopAttach.Parent = beamTop

	local beam = Instance.new("Beam")
	beam.Name = "TD_EnergyBeam"
	beam.Attachment0 = beamBottomAttach
	beam.Attachment1 = beamTopAttach
	beam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.neonCyan),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200)),
	})
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.Width0 = 2
	beam.Width1 = 0.3
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.FaceCamera = true
	beam.Segments = 20
	beam.TextureLength = 2
	beam.TextureSpeed = 1
	beam.Texture = "rbxassetid://241685484"
	beam.Parent = battery

	-- ══════════════════════════════════════════════════════════════
	-- ANNEAUX TOURNANTS AU SOL
	-- ══════════════════════════════════════════════════════════════
	local groundRing1 = createAnchoredPart(battery, "GroundRing1", Vector3.new(4, 0.05, 4), COLORS.neonCyan, Enum.Material.Neon)
	groundRing1.Shape = Enum.PartType.Cylinder
	groundRing1.CFrame = CFrame.new(body.Position + Vector3.new(0, -0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	groundRing1.CanCollide = false; groundRing1.Transparency = 0.5

	local groundRing2 = createAnchoredPart(battery, "GroundRing2", Vector3.new(5.5, 0.03, 5.5), Color3.fromRGB(0, 180, 220), Enum.Material.Neon)
	groundRing2.Shape = Enum.PartType.Cylinder
	groundRing2.CFrame = CFrame.new(body.Position + Vector3.new(0, -0.45, 0)) * CFrame.Angles(0, 0, math.rad(90))
	groundRing2.CanCollide = false; groundRing2.Transparency = 0.6

	-- Animation des anneaux
	local ringConnection
	ringConnection = RunService.Heartbeat:Connect(function()
		if not battery.Parent then
			ringConnection:Disconnect()
			return
		end
		local t = tick()
		if groundRing1 and groundRing1.Parent then
			groundRing1.CFrame = CFrame.new(body.Position + Vector3.new(0, -0.4, 0)) 
				* CFrame.Angles(0, 0, math.rad(90))
			groundRing1.Transparency = 0.4 + math.sin(t * 3) * 0.2
		end
		if groundRing2 and groundRing2.Parent then
			groundRing2.CFrame = CFrame.new(body.Position + Vector3.new(0, -0.45, 0)) 
				* CFrame.Angles(0, 0, math.rad(90))
			groundRing2.Transparency = 0.5 + math.sin(t * 2 + 1) * 0.2
		end

		-- Pulsation de la lumière
		if pl and pl.Parent then
			pl.Brightness = 3 + math.sin(t * 4) * 1.5
		end
		if pl2 and pl2.Parent then
			pl2.Brightness = 1.5 + math.sin(t * 3) * 1
		end

		-- Pulsation du beam
		if beam and beam.Parent then
			beam.Width0 = 1.5 + math.sin(t * 3) * 0.8
			beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2 + math.sin(t * 2) * 0.15),
				NumberSequenceKeypoint.new(0.3, 0.4 + math.sin(t * 2.5) * 0.1),
				NumberSequenceKeypoint.new(0.7, 0.65),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
	end)

	-- ══════════════════════════════════════════════════════════════
	-- PLACEMENT SÛR
	-- ══════════════════════════════════════════════════════════════
	local safePos = findSafeGround(rootPart.Position.X, rootPart.Position.Z)
	local batteryPos = safePos + Vector3.new(0, 1, 0)

	battery:PivotTo(CFrame.new(batteryPos))
	battery.Parent = workspace

	-- Repositionner tous les éléments d'effet
	glowPart.Position = batteryPos + Vector3.new(0, 0.5, 0)
	billboardPart.Position = batteryPos + Vector3.new(0, 3, 0)
	beamBottom.Position = batteryPos + Vector3.new(0, -0.5, 0)
	beamTop.Position = batteryPos + Vector3.new(0, 30, 0)
	groundRing1.CFrame = CFrame.new(batteryPos + Vector3.new(0, -0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	groundRing2.CFrame = CFrame.new(batteryPos + Vector3.new(0, -0.45, 0)) * CFrame.Angles(0, 0, math.rad(90))

-- ══════════════════════════════════════════════════════════════
-- PROXIMITY PROMPT — VISIBLE ET INTERACTIF À TRAVERS LES MURS
-- ══════════════════════════════════════════════════════════════
local prompt = Instance.new("ProximityPrompt", body)
prompt.ActionText = "Ramasser la Batterie ⚡"
prompt.ObjectText = "Batterie Haute Tension"
prompt.MaxActivationDistance = 12                    -- Distance augmentée
prompt.HoldDuration = 0.6                            -- Un peu plus rapide
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.RequiresLineOfSight = false                   -- ⭐ PEUT INTERAGIR À TRAVERS LES MURS
prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
prompt.Style = Enum.ProximityPromptStyle.Default

-- Style personnalisé du prompt (couleur cyan pour matcher le glow)
prompt.UIOffset = Vector2.new(0, -50)                -- Décalage vers le haut pour pas cacher le glow

prompt.Triggered:Connect(function(plr)
    if plr ~= player then return end
    batteriesFound = batteriesFound + 1

    playSnd(SND.pickup, 1.5)
    playSnd(SND.electric, 0.8)

    -- Déconnecter les animations
    if glowConnection then pcall(function() glowConnection:Disconnect() end) end
    if ringConnection then pcall(function() ringConnection:Disconnect() end) end

    -- Mise à jour du GUI
    local gui = player.PlayerGui:FindFirstChild("DoctorEventGui")
    if gui then
        local batLabelGui = gui:FindFirstChild("BatteryLabel", true)
        if batLabelGui then
            batLabelGui.Text = "⚡ BATTERIES : " .. batteriesFound .. " / " .. batteriesRequired

            -- Flash de couleur
            TweenService:Create(batLabelGui, TweenInfo.new(0.2), {TextColor3 = Color3.new(1, 1, 1)}):Play()
            task.delay(0.2, function()
                if batLabelGui and batLabelGui.Parent then
                    TweenService:Create(batLabelGui, TweenInfo.new(0.3), {TextColor3 = COLORS.neonCyan}):Play()
                end
            end)

            if batteriesFound >= batteriesRequired then
                TweenService:Create(batLabelGui, TweenInfo.new(0.5), {TextColor3 = COLORS.green}):Play()

                -- Notification toutes batteries trouvées
                local notif = Instance.new("Frame")
                notif.Size = UDim2.new(0.6, 0, 0.1, 0)
                notif.Position = UDim2.new(0.2, 0, 0.18, 0)
                notif.BackgroundColor3 = Color3.fromRGB(0, 40, 0)
                notif.BackgroundTransparency = 0.2
                notif.BorderSizePixel = 0; notif.ZIndex = 50; notif.Parent = gui
                Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)
                local notifStroke = Instance.new("UIStroke")
                notifStroke.Color = COLORS.green; notifStroke.Thickness = 2; notifStroke.Parent = notif

                local notifText = Instance.new("TextLabel")
                notifText.Size = UDim2.new(1, -20, 1, 0)
                notifText.Position = UDim2.new(0, 10, 0, 0)
                notifText.BackgroundTransparency = 1
                notifText.Text = "✅ TOUTES LES BATTERIES TROUVÉES ! Allez à la Machine Centrale !"
                notifText.TextColor3 = COLORS.green
                notifText.TextScaled = true; notifText.Font = Enum.Font.GothamBold
                notifText.TextStrokeTransparency = 0
                notifText.ZIndex = 51; notifText.Parent = notif

                -- Animation d'apparition
                notif.Position = UDim2.new(0.2, 0, 0.1, 0)
                notif.BackgroundTransparency = 1; notifText.TextTransparency = 1
                TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
                    Position = UDim2.new(0.2, 0, 0.18, 0),
                    BackgroundTransparency = 0.2
                }):Play()
                TweenService:Create(notifText, TweenInfo.new(0.4), {TextTransparency = 0}):Play()

                task.delay(6, function()
                    if notif and notif.Parent then
                        TweenService:Create(notif, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
                        TweenService:Create(notifText, TweenInfo.new(1), {TextTransparency = 1}):Play()
                        task.wait(1.1); pcall(function() notif:Destroy() end)
                    end
                end)
            end
        end
    end

    -- ══════════════════════════════════════════════════════════
    -- EFFET DE COLLECTE SPECTACULAIRE
    -- ══════════════════════════════════════════════════════════
    local collectPos = body.Position

    -- Flash blanc
    local flashPart = Instance.new("Part")
    flashPart.Size = Vector3.new(1,1,1); flashPart.Transparency = 1
    flashPart.Anchored = true; flashPart.CanCollide = false
    flashPart.Position = collectPos; flashPart.Parent = workspace
    flashPart.Name = "TD_CollectFlash"

    local flashPL = Instance.new("PointLight")
    flashPL.Color = Color3.new(1, 1, 1)
    flashPL.Brightness = 10; flashPL.Range = 40
    flashPL.Parent = flashPart

    -- Particules d'explosion de collecte
    local collectPE = Instance.new("ParticleEmitter")
    collectPE.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.3, COLORS.neonCyan),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 80, 200)),
    })
    collectPE.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(0.3, 1.5),
        NumberSequenceKeypoint.new(1, 0)
    })
    collectPE.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    collectPE.Lifetime = NumberRange.new(0.5, 1.2)
    collectPE.Rate = 150; collectPE.Speed = NumberRange.new(8, 20)
    collectPE.SpreadAngle = Vector2.new(180, 180)
    collectPE.LightEmission = 1; collectPE.Texture = "rbxassetid://241685484"
    collectPE.Parent = flashPart

    -- Étincelles rapides
    local sparksPE = Instance.new("ParticleEmitter")
    sparksPE.Color = ColorSequence.new(Color3.new(1, 1, 1))
    sparksPE.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0)
    })
    sparksPE.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    sparksPE.Lifetime = NumberRange.new(0.2, 0.5)
    sparksPE.Rate = 200; sparksPE.Speed = NumberRange.new(15, 30)
    sparksPE.SpreadAngle = Vector2.new(180, 180)
    sparksPE.LightEmission = 1; sparksPE.Texture = "rbxassetid://241685484"
    sparksPE.Parent = flashPart

    -- Fade out de la lumière
    task.spawn(function()
        for i = 1, 10 do
            flashPL.Brightness = 10 * (1 - i/10)
            flashPL.Range = 40 * (1 - i/10)
            task.wait(0.05)
        end
    end)

    task.delay(0.3, function()
        collectPE.Enabled = false
        sparksPE.Enabled = false
    end)
    Debris:AddItem(flashPart, 2)

    -- Détruire la batterie
    battery:Destroy()
end)

table.insert(batteryModels, battery)
end

-- ═══════════════════════════════════════════════════════════════════
-- LA SALLE DU DOCTOR & MACHINE CENTRALE
-- (identique à avant, inchangé)
-- ═══════════════════════════════════════════════════════════════════

local function buildDoctorRoom()
	local room = Instance.new("Model", workspace)
	room.Name = "TD_DoctorRoom"

	local spawnPoints = {}
	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA("SpawnLocation") then table.insert(spawnPoints, v) end
	end
	local basePos
	if #spawnPoints > 0 then
		basePos = spawnPoints[math.random(1,#spawnPoints)].Position + Vector3.new(40, 0.5, 40)
	else
		basePos = rootPart.Position + Vector3.new(80, 0.5, 80)
	end

	local roomW = 30
	local roomD = 30
	local H = 16
	local W = 1.5

	local floorCol = Color3.fromRGB(12, 12, 18)
	local wallCol = Color3.fromRGB(18, 18, 25)
	local ceilCol = Color3.fromRGB(8, 8, 12)
	local neonCol = COLORS.neonRed

	-- ══════════════════════════════
	-- SOL
	-- ══════════════════════════════
	local floor = createAnchoredPart(room, "Floor", Vector3.new(roomW, W, roomD), floorCol, Enum.Material.Concrete)
	floor.Position = basePos

	for x = -12, 12, 4 do
		for z = -12, 12, 4 do
			local grate = createAnchoredPart(room, "Grate", Vector3.new(3.5, 0.1, 3.5), Color3.fromRGB(20, 20, 28), Enum.Material.DiamondPlate)
			grate.Position = basePos + Vector3.new(x, 0.6, z)
			grate.CanCollide = true
		end
	end

	-- ══════════════════════════════
	-- PLAFOND
	-- ══════════════════════════════
	local ceil = createAnchoredPart(room, "Ceiling", Vector3.new(roomW, W, roomD), ceilCol, Enum.Material.Concrete)
	ceil.Position = basePos + Vector3.new(0, H, 0)

	-- ══════════════════════════════
	-- MURS AVEC ÉCRANS
	-- ══════════════════════════════
	local doorW = 6

	for wallIdx = 1, 4 do
		local wallPos, wallSize

		if wallIdx == 1 then
			wallPos = basePos + Vector3.new(-roomW/2, H/2, 0)
			wallSize = Vector3.new(W, H, roomD)
		elseif wallIdx == 2 then
			wallPos = basePos + Vector3.new(roomW/2, H/2, 0)
			wallSize = Vector3.new(W, H, roomD)
		elseif wallIdx == 3 then
			wallPos = basePos + Vector3.new(0, H/2, roomD/2)
			wallSize = Vector3.new(roomW, H, W)
		elseif wallIdx == 4 then
			local sideW = (roomW - doorW) / 2
			local wallL = createAnchoredPart(room, "WallFrontL", Vector3.new(sideW, H, W), wallCol, Enum.Material.Concrete)
			wallL.Position = basePos + Vector3.new(-(doorW/2 + sideW/2), H/2, -roomD/2)

			local wallR = createAnchoredPart(room, "WallFrontR", Vector3.new(sideW, H, W), wallCol, Enum.Material.Concrete)
			wallR.Position = basePos + Vector3.new((doorW/2 + sideW/2), H/2, -roomD/2)

			local linteau = createAnchoredPart(room, "Linteau", Vector3.new(doorW + 2, 2, W), neonCol, Enum.Material.Neon)
			linteau.Position = basePos + Vector3.new(0, H - 1, -roomD/2)
			linteau.CanCollide = false; linteau.Transparency = 0.3

			local signPart = createAnchoredPart(room, "EntranceSign", Vector3.new(8, 2, 0.2), Color3.fromRGB(5, 5, 10), Enum.Material.Glass)
			signPart.Position = basePos + Vector3.new(0, H - 4, -roomD/2 - 1.5)
			signPart.CanCollide = false

			local signGui = Instance.new("SurfaceGui", signPart)
			signGui.Face = Enum.NormalId.Back; signGui.PixelsPerStud = 40
			local signBg = Instance.new("Frame", signGui)
			signBg.Size = UDim2.new(1,0,1,0); signBg.BackgroundColor3 = Color3.fromRGB(5,0,0)
			signBg.BorderSizePixel = 0
			local signText = Instance.new("TextLabel", signBg)
			signText.Size = UDim2.new(1,0,1,0); signText.BackgroundTransparency = 1
			signText.Text = "⚡ SALLE DU DOCTOR ⚡"
			signText.TextColor3 = COLORS.neonRed; signText.TextScaled = true
			signText.Font = Enum.Font.GothamBold
			signText.TextStrokeTransparency = 0; signText.TextStrokeColor3 = Color3.fromRGB(80,0,0)

			local signGui2 = Instance.new("SurfaceGui", signPart)
			signGui2.Face = Enum.NormalId.Front; signGui2.PixelsPerStud = 40
			local signBg2 = signBg:Clone(); signBg2.Parent = signGui2

			continue
		end

		local wall = createAnchoredPart(room, "Wall"..wallIdx, wallSize, wallCol, Enum.Material.Concrete)
		wall.Position = wallPos

		local numScreensH = 5
		local numScreensV = 3
		local screenW = 3.5
		local screenH = 2.5

		for sx = 1, numScreensH do
			for sy = 1, numScreensV do
				local offsetH = (sx - (numScreensH + 1) / 2) * (screenW + 0.8)
				local offsetV = (sy - 1) * (screenH + 1) + 3

				local screenPart = createAnchoredPart(room, "Monitor"..wallIdx..sx..sy, 
					Vector3.new(screenW, screenH, 0.15), Color3.fromRGB(8, 8, 12), Enum.Material.Glass)
				screenPart.CanCollide = false

				if wallIdx == 1 then
					screenPart.Size = Vector3.new(0.15, screenH, screenW)
					screenPart.Position = wallPos + Vector3.new(0.8, -H/2 + offsetV, offsetH)
				elseif wallIdx == 2 then
					screenPart.Size = Vector3.new(0.15, screenH, screenW)
					screenPart.Position = wallPos + Vector3.new(-0.8, -H/2 + offsetV, offsetH)
				else
					screenPart.Position = wallPos + Vector3.new(offsetH, -H/2 + offsetV, -0.8)
				end

				local monFrame
				if wallIdx <= 2 then
					monFrame = createAnchoredPart(room, "MonFrame", Vector3.new(0.2, screenH + 0.3, screenW + 0.3), COLORS.metalDark, Enum.Material.Metal)
				else
					monFrame = createAnchoredPart(room, "MonFrame", Vector3.new(screenW + 0.3, screenH + 0.3, 0.2), COLORS.metalDark, Enum.Material.Metal)
				end
				monFrame.Position = screenPart.Position
				monFrame.CanCollide = false

				local face = (wallIdx == 1) and Enum.NormalId.Right or 
							  (wallIdx == 2) and Enum.NormalId.Left or Enum.NormalId.Back

				local monGui = Instance.new("SurfaceGui", screenPart)
				monGui.Face = face; monGui.PixelsPerStud = 30

				local monBg = Instance.new("Frame", monGui)
				monBg.Size = UDim2.new(1,0,1,0)
				monBg.BackgroundColor3 = Color3.fromRGB(math.random(0,5), math.random(0,8), math.random(0,5))
				monBg.BorderSizePixel = 0

				local contentType = math.random(1, 4)
				if contentType == 1 then
					local eye = Instance.new("Frame", monBg)
					eye.Size = UDim2.new(0.5, 0, 0.5, 0)
					eye.Position = UDim2.new(0.25, 0, 0.25, 0)
					eye.BackgroundColor3 = COLORS.neonRed
					eye.BackgroundTransparency = 0.3
					Instance.new("UICorner", eye).CornerRadius = UDim.new(1, 0)
					local pup = Instance.new("Frame", eye)
					pup.Size = UDim2.new(0.3, 0, 0.3, 0)
					pup.Position = UDim2.new(0.35, 0, 0.35, 0)
					pup.BackgroundColor3 = Color3.new(0, 0, 0)
					Instance.new("UICorner", pup).CornerRadius = UDim.new(1, 0)
				elseif contentType == 2 then
					local dataText = Instance.new("TextLabel", monBg)
					dataText.Size = UDim2.new(1,0,1,0); dataText.BackgroundTransparency = 1
					dataText.Text = math.random() > 0.5 and "NO SIGNAL" or "ERROR 404"
					dataText.TextColor3 = COLORS.neonRed; dataText.TextScaled = true
					dataText.Font = Enum.Font.Code
				elseif contentType == 3 then
					local codeLines = Instance.new("TextLabel", monBg)
					codeLines.Size = UDim2.new(1,0,1,0); codeLines.BackgroundTransparency = 1
					codeLines.Text = "01001\n11010\n00101\n10110"
					codeLines.TextColor3 = Color3.fromRGB(0, 180, 0); codeLines.TextScaled = true
					codeLines.Font = Enum.Font.Code
				end

				if math.random() > 0.6 then
					local monPL = Instance.new("PointLight")
					monPL.Color = math.random() > 0.5 and COLORS.neonRed or Color3.fromRGB(0, 150, 0)
					monPL.Brightness = 0.5; monPL.Range = 6
					monPL.Parent = screenPart
				end
			end
		end
	end

	-- ══════════════════════════════
	-- LUMIÈRES
	-- ══════════════════════════════
	local mainLight = createAnchoredPart(room, "MainLight", Vector3.new(4, 0.3, 4), COLORS.neonRed, Enum.Material.Neon)
	mainLight.Position = basePos + Vector3.new(0, H - 1, 0)
	mainLight.CanCollide = false; mainLight.Transparency = 0.3
	local mainPL = Instance.new("PointLight"); mainPL.Color = COLORS.neonRed
	mainPL.Brightness = 2; mainPL.Range = 40; mainPL.Parent = mainLight

	for i = 1, 4 do
		local angle = math.rad(i * 90)
		local ambLight = createAnchoredPart(room, "AmbLight"..i, Vector3.new(0.5, 0.5, 0.5), COLORS.neonRed, Enum.Material.Neon)
		ambLight.Position = basePos + Vector3.new(math.cos(angle) * 10, H - 1, math.sin(angle) * 10)
		ambLight.CanCollide = false; ambLight.Transparency = 0.5
		local apl = Instance.new("PointLight"); apl.Color = COLORS.neonRed
		apl.Brightness = 1; apl.Range = 20; apl.Parent = ambLight
	end

	-- ══════════════════════════════
	-- MACHINE CENTRALE (avec Highlight visible à travers les murs aussi)
	-- ══════════════════════════════
	local machinePos = basePos

	local machineBase = createAnchoredPart(room, "MachineBase", Vector3.new(8, 1, 8), COLORS.metalDark, Enum.Material.Metal)
	machineBase.Position = machinePos + Vector3.new(0, 1, 0)

	for i = 1, 4 do
		local angle = math.rad(i * 90 + 45)
		local pillar = createAnchoredPart(room, "MachinePillar"..i, Vector3.new(1, 8, 1), COLORS.metal, Enum.Material.Metal)
		pillar.Position = machinePos + Vector3.new(math.cos(angle) * 3, 5.5, math.sin(angle) * 3)
		local cable = createAnchoredPart(room, "PillarCable"..i, Vector3.new(0.15, 6, 0.15), COLORS.wire, Enum.Material.SmoothPlastic)
		cable.Position = pillar.Position + Vector3.new(0.5, 0, 0); cable.CanCollide = false
	end

	local core = createAnchoredPart(room, "Core", Vector3.new(3, 6, 3), COLORS.neonRed, Enum.Material.Neon)
	core.Shape = Enum.PartType.Cylinder
	core.CFrame = CFrame.new(machinePos + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	core.Transparency = 0.6; core.CanCollide = false

	local corePL = Instance.new("PointLight"); corePL.Color = COLORS.neonRed
	corePL.Brightness = 4; corePL.Range = 30; corePL.Parent = core

	-- ⭐ HIGHLIGHT sur la machine (visible à travers les murs)
	local machineHighlight = Instance.new("Highlight")
	machineHighlight.Name = "TD_MachineHighlight"
	machineHighlight.Parent = room
	machineHighlight.Adornee = room
	machineHighlight.FillColor = COLORS.neonRed
	machineHighlight.FillTransparency = 0.85
	machineHighlight.OutlineColor = COLORS.neonRed
	machineHighlight.OutlineTransparency = 0.3
	machineHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	machineHighlight.Enabled = true

	-- Billboard pour la salle (visible de loin à travers les murs)
	local roomBillboardPart = Instance.new("Part")
	roomBillboardPart.Name = "TD_RoomBillboardAnchor"
	roomBillboardPart.Size = Vector3.new(0.1,0.1,0.1); roomBillboardPart.Transparency = 1
	roomBillboardPart.Anchored = true; roomBillboardPart.CanCollide = false
	roomBillboardPart.Position = basePos + Vector3.new(0, H + 5, 0)
	roomBillboardPart.Parent = room

	local roomBillboard = Instance.new("BillboardGui")
	roomBillboard.Parent = roomBillboardPart
	roomBillboard.Adornee = roomBillboardPart
	roomBillboard.Size = UDim2.new(0, 120, 0, 50)
	roomBillboard.StudsOffset = Vector3.new(0, 3, 0)
	roomBillboard.AlwaysOnTop = true
	roomBillboard.MaxDistance = 800

	local roomLabel = Instance.new("TextLabel")
	roomLabel.Size = UDim2.new(1, 0, 0.6, 0)
	roomLabel.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
	roomLabel.BackgroundTransparency = 0.3
	roomLabel.Text = "🏭 SALLE DU DOCTOR"
	roomLabel.TextColor3 = COLORS.neonRed
	roomLabel.TextScaled = true; roomLabel.Font = Enum.Font.GothamBold
	roomLabel.TextStrokeTransparency = 0
	roomLabel.ZIndex = 2; roomLabel.Parent = roomBillboard
	Instance.new("UICorner", roomLabel).CornerRadius = UDim.new(0, 6)

	local roomDist = Instance.new("TextLabel")
	roomDist.Name = "RoomDist"
	roomDist.Size = UDim2.new(1, 0, 0.35, 0)
	roomDist.Position = UDim2.new(0, 0, 0.65, 0)
	roomDist.BackgroundTransparency = 1
	roomDist.Text = "? m"
	roomDist.TextColor3 = COLORS.neonRed
	roomDist.TextScaled = true; roomDist.Font = Enum.Font.Code
	roomDist.TextStrokeTransparency = 0
	roomDist.ZIndex = 2; roomDist.Parent = roomBillboard

	-- Mise à jour distance de la salle
	local roomDistConn
	roomDistConn = RunService.Heartbeat:Connect(function()
		if not room.Parent or not eventActive then
			if roomDistConn then roomDistConn:Disconnect() end
			return
		end
		if rootPart and rootPart.Parent then
			local dist = math.floor((rootPart.Position - basePos).Magnitude)
			roomDist.Text = dist .. "m"

			-- Pulsation du highlight machine
			local t = tick()
			machineHighlight.FillTransparency = 0.8 + math.sin(t * 2) * 0.1
			machineHighlight.OutlineTransparency = 0.2 + math.sin(t * 3) * 0.2
		end
	end)
	table.insert(eventConnections, roomDistConn)

	for i = 1, 3 do
		local angle = math.rad(i * 120)
		local ring = createAnchoredPart(room, "CoreRing"..i, Vector3.new(5, 0.3, 5), COLORS.metalLight, Enum.Material.Metal)
		ring.Position = machinePos + Vector3.new(0, 3 + i * 2, 0)
		ring.CanCollide = false; ring.Transparency = 0.2
	end

	for i = 1, 6 do
		local angle = math.rad(i * 60)
		local mScreen = createAnchoredPart(room, "MachineScreen"..i, Vector3.new(2, 1.5, 0.15), Color3.fromRGB(5, 5, 10), Enum.Material.Glass)
		mScreen.Position = machinePos + Vector3.new(math.cos(angle) * 3.5, 8, math.sin(angle) * 3.5)
		mScreen.CFrame = CFrame.lookAt(mScreen.Position, machinePos + Vector3.new(0, 8, 0))
		mScreen.CanCollide = false

		local msGui = Instance.new("SurfaceGui", mScreen)
		msGui.Face = Enum.NormalId.Back; msGui.PixelsPerStud = 30
		local msBg = Instance.new("Frame", msGui)
		msBg.Size = UDim2.new(1,0,1,0); msBg.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
		msBg.BorderSizePixel = 0
		local msText = Instance.new("TextLabel", msBg)
		msText.Size = UDim2.new(1,0,1,0); msText.BackgroundTransparency = 1
		msText.Text = "⚡"; msText.TextColor3 = COLORS.neonRed
		msText.TextScaled = true; msText.Font = Enum.Font.Code
	end

	-- Particules du noyau
	local coreSmoke = Instance.new("Part")
	coreSmoke.Name = "TD_CoreSmoke"; coreSmoke.Size = Vector3.new(1,1,1)
	coreSmoke.Transparency = 1; coreSmoke.Anchored = true; coreSmoke.CanCollide = false
	coreSmoke.Position = machinePos + Vector3.new(0, 5, 0); coreSmoke.Parent = room

	local corePE = Instance.new("ParticleEmitter")
	corePE.Color = ColorSequence.new(COLORS.neonRed, Color3.fromRGB(100, 0, 0))
	corePE.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4)})
	corePE.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
	corePE.Lifetime = NumberRange.new(2, 4); corePE.Rate = 10
	corePE.Speed = NumberRange.new(1, 3); corePE.SpreadAngle = Vector2.new(180, 180)
	corePE.LightEmission = 0.6; corePE.Texture = "rbxassetid://241685484"
	corePE.Parent = coreSmoke

	-- ══════════════════════════════
	-- SLOTS + PROMPT
	-- ══════════════════════════════
	local batterySlots = {}
	for i = 1, 3 do
		local angle = math.rad(i * 120)
		local slotPos = machinePos + Vector3.new(math.cos(angle) * 4, 2, math.sin(angle) * 4)

		local slot = createAnchoredPart(room, "BatterySlot"..i, Vector3.new(1.2, 2.5, 0.8), Color3.fromRGB(15, 15, 20), Enum.Material.Metal)
		slot.Position = slotPos

		local indicator = createAnchoredPart(room, "SlotIndicator"..i, Vector3.new(0.5, 0.5, 0.15), COLORS.neonRed, Enum.Material.Neon)
		indicator.Position = slotPos + Vector3.new(0, 1.5, -0.5); indicator.CanCollide = false

		local slotGui = Instance.new("SurfaceGui", indicator)
		slotGui.Face = Enum.NormalId.Back; slotGui.PixelsPerStud = 30
		local slotText = Instance.new("TextLabel", slotGui)
		slotText.Size = UDim2.new(1,0,1,0); slotText.BackgroundTransparency = 1
		slotText.Text = tostring(i); slotText.TextColor3 = Color3.new(1,1,1)
		slotText.TextScaled = true; slotText.Font = Enum.Font.GothamBold

		table.insert(batterySlots, {slot = slot, indicator = indicator, filled = false})
	end

	local machinePrompt = Instance.new("ProximityPrompt", machineBase)
	machinePrompt.ActionText = "Insérer les batteries ⚡"
	machinePrompt.ObjectText = "Machine Centrale"
	machinePrompt.MaxActivationDistance = 10
	machinePrompt.HoldDuration = 1.5
	machinePrompt.KeyboardKeyCode = Enum.KeyCode.E

	machinePrompt.Triggered:Connect(function(plr)
		if plr ~= player then return end
		if machineActivated then return end

		if batteriesFound < batteriesRequired then
			playSnd(SND.static, 1.5)
			local gui = player.PlayerGui:FindFirstChild("DoctorEventGui")
			if gui then
				local errNotif = Instance.new("TextLabel")
				errNotif.Size = UDim2.new(0.5, 0, 0.06, 0)
				errNotif.Position = UDim2.new(0.25, 0, 0.25, 0)
				errNotif.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
				errNotif.BackgroundTransparency = 0.3
				errNotif.Text = "❌ Il manque " .. (batteriesRequired - batteriesFound) .. " batterie(s) !"
				errNotif.TextColor3 = COLORS.neonRed
				errNotif.TextScaled = true; errNotif.Font = Enum.Font.GothamBold
				errNotif.ZIndex = 50; errNotif.Parent = gui
				Instance.new("UICorner", errNotif).CornerRadius = UDim.new(0, 8)
				task.delay(3, function()
					if errNotif.Parent then
						TweenService:Create(errNotif, TweenInfo.new(0.5), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
						task.wait(0.6); pcall(function() errNotif:Destroy() end)
					end
				end)
			end
			return
		end

		-- ═══ SÉQUENCE DE VICTOIRE ═══
		machineActivated = true
		machinePrompt.Enabled = false

		-- Désactiver le highlight de la machine
		machineHighlight.Enabled = false

		for i, slotData in ipairs(batterySlots) do
			task.delay(i * 0.5, function()
				TweenService:Create(slotData.indicator, TweenInfo.new(0.3), {Color = COLORS.green}):Play()
				playSnd(SND.electric, 1)
				local insertedBat = createAnchoredPart(room, "InsertedBat"..i, Vector3.new(0.8, 1.5, 0.5), Color3.fromRGB(25, 25, 30), Enum.Material.Metal)
				insertedBat.Position = slotData.slot.Position + Vector3.new(0, 0.5, 0); insertedBat.CanCollide = false
				local batGlow = createAnchoredPart(room, "InsertedBatGlow"..i, Vector3.new(0.85, 0.2, 0.55), COLORS.neonCyan, Enum.Material.Neon)
				batGlow.Position = insertedBat.Position + Vector3.new(0, 0.3, 0); batGlow.CanCollide = false
			end)
		end

		task.wait(2)
		playSnd(SND.machineHum, 2)
		TweenService:Create(core, TweenInfo.new(2), {Color = COLORS.neonCyan, Transparency = 0.3}):Play()
		corePL.Color = COLORS.neonCyan

		for _, child in pairs(room:GetDescendants()) do
			if child:IsA("TextLabel") and child.Text == "⚡" then
				child.Text = "✅"; child.TextColor3 = COLORS.green
			end
		end

		task.wait(2)
		playSnd(SND.alert, 3)

		task.spawn(function()
			for i = 1, 10 do
				mainPL.Brightness = mainPL.Brightness > 1 and 0 or 5
				task.wait(0.2)
			end
		end)

		task.wait(2)
		playSnd(SND.explode, 4)
		playSnd(SND.electric, 3)

		local explosion = Instance.new("Explosion")
		explosion.Position = machinePos + Vector3.new(0, 5, 0)
		explosion.BlastRadius = 40; explosion.BlastPressure = 0
		explosion.DestroyJointRadiusPercent = 0; explosion.Parent = workspace

		local expPart = Instance.new("Part")
		expPart.Size = Vector3.new(1,1,1); expPart.Transparency = 1
		expPart.Anchored = true; expPart.CanCollide = false
		expPart.Position = machinePos + Vector3.new(0, 5, 0); expPart.Parent = workspace
		expPart.Name = "TD_ExpPart"

		local expPE = Instance.new("ParticleEmitter")
		expPE.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.3, COLORS.neonCyan),
			ColorSequenceKeypoint.new(0.7, COLORS.neonBlue),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 50)),
		})
		expPE.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 20)})
		expPE.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
		expPE.Lifetime = NumberRange.new(1, 3); expPE.Rate = 200
		expPE.Speed = NumberRange.new(20, 50); expPE.SpreadAngle = Vector2.new(180, 180)
		expPE.LightEmission = 1; expPE.Texture = "rbxassetid://241685484"
		expPE.Parent = expPart
		task.delay(0.5, function() expPE.Enabled = false end)
		Debris:AddItem(expPart, 4)

		for i = 1, 40 do
			local db = Instance.new("Part")
			db.Name = "TD_ExpDebris"..i
			db.Size = Vector3.new(math.random(3,15)/10, math.random(3,15)/10, math.random(3,15)/10)
			db.Color = Color3.fromRGB(math.random(20,80), math.random(20,80), math.random(20,80))
			db.Material = Enum.Material.Metal; db.Anchored = false; db.CanCollide = true
			db.CFrame = CFrame.new(machinePos + Vector3.new(0, 5, 0)) * CFrame.new(math.random(-3,3), math.random(-2,5), math.random(-3,3))
			db.Velocity = Vector3.new(math.random(-60,60), math.random(30,80), math.random(-60,60))
			db.Parent = workspace; Debris:AddItem(db, 5)
		end

		for _, docData in ipairs(activeDoctors) do
			if docData.model and docData.model.Parent then
				docData.data.state = "DEAD"
				if docData.data.chaseSound then
					pcall(function() docData.data.chaseSound:Stop(); docData.data.chaseSound:Destroy() end)
				end
				for _, p in pairs(docData.model:GetDescendants()) do
					if p:IsA("BasePart") then
						TweenService:Create(p, TweenInfo.new(1), {Transparency = 1}):Play()
					end
				end
				task.delay(1.1, function() pcall(function() docData.model:Destroy() end) end)
			end
		end

		for _, child in pairs(room:GetDescendants()) do
			if child:IsA("BasePart") and (child.Name:find("Machine") or child.Name:find("Core") or child.Name:find("Inserted") or child.Name:find("Slot")) then
				TweenService:Create(child, TweenInfo.new(1), {Transparency = 1}):Play()
			end
		end

		task.wait(2)
		stopEvent(true)
	end)

	local roomHum = Instance.new("Sound")
	roomHum.Name = "TD_Sound"; roomHum.SoundId = SND.machineHum
	roomHum.Volume = 0.5; roomHum.Looped = true
	roomHum.Parent = core; roomHum:Play()

	doctorRoom = room
	return room
end

-- ═══════════════════════════════════════════════════════════════════
-- SPAWN DES DOCTORS (Armée de clones)
-- ═══════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════
-- SYSTÈME DE SPAWN INTELLIGENT — DOCTORS DANS LE CHAMP DE VISION
-- Spawn devant le joueur, derrière les coins, quand il avance
-- ═══════════════════════════════════════════════════════════════════

local lastPlayerPos = nil
local lastSpawnTime = 0
local playerMoveDistance = 0
local SPAWN_ON_MOVE_DISTANCE = 30        -- Spawn un doctor tous les 30 studs parcourus
local SPAWN_COOLDOWN = 3                  -- Minimum 3 secondes entre chaque spawn
local VISION_SPAWN_CHANCE = 0.4           -- 40% chance de spawn dans le champ de vision
local BEHIND_SPAWN_CHANCE = 0.25          -- 25% chance de spawn derrière le joueur
local SIDE_SPAWN_CHANCE = 0.35            -- 35% chance de spawn sur les côtés

local function isPositionVisible(pos)
	-- Vérifie si une position est dans le champ de vision de la caméra
	local screenPoint, onScreen = camera:WorldToScreenPoint(pos)
	return onScreen
end

local function isPositionBehindWall(pos)
	-- Vérifie s'il y a un mur entre le joueur et la position
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local excludeList = {character}
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:sub(1,3) == "TD_" then table.insert(excludeList, v) end
	end
	rayParams.FilterDescendantsInstances = excludeList
	
	local direction = (pos - rootPart.Position)
	local rayResult = workspace:Raycast(rootPart.Position, direction, rayParams)
	
	if rayResult then
		return rayResult.Distance < direction.Magnitude - 2
	end
	return false
end

local function findSpawnPositionInVision()
	-- Trouve une position DEVANT le joueur, dans son champ de vision mais pas directement visible
	local camLook = camera.CFrame.LookVector
	local camRight = camera.CFrame.RightVector
	
	for attempt = 1, 15 do
		-- Distance devant le joueur
		local forwardDist = math.random(40, 80)
		-- Décalage latéral (pour spawn sur les côtés du champ de vision)
		local sideDist = math.random(-30, 30)
		
		local spawnPos = rootPart.Position 
			+ camLook * forwardDist 
			+ camRight * sideDist
		
		-- Trouver le sol
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {character}
		for _, v in pairs(workspace:GetChildren()) do
			if v.Name:sub(1,3) == "TD_" then table.insert(excludeList, v) end
		end
		rayParams.FilterDescendantsInstances = excludeList
		
		local rayResult = workspace:Raycast(Vector3.new(spawnPos.X, 500, spawnPos.Z), Vector3.new(0, -600, 0), rayParams)
		
		if rayResult then
			local groundPos = rayResult.Position
			
			-- Vérifier que c'est DERRIÈRE un mur ou obstacle (pas directement visible)
			if isPositionBehindWall(groundPos + Vector3.new(0, 3, 0)) then
				return groundPos
			end
			
			-- Ou que c'est juste au bord du champ de vision
			if not isPositionVisible(groundPos + Vector3.new(0, 3, 0)) then
				return groundPos
			end
		end
	end
	
	return nil
end

local function findSpawnPositionBehind()
	-- Trouve une position DERRIÈRE le joueur
	local camLook = camera.CFrame.LookVector
	local camRight = camera.CFrame.RightVector
	
	for attempt = 1, 10 do
		-- Derrière le joueur
		local backDist = math.random(25, 50)
		local sideDist = math.random(-20, 20)
		
		local spawnPos = rootPart.Position 
			- camLook * backDist 
			+ camRight * sideDist
		
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {character}
		for _, v in pairs(workspace:GetChildren()) do
			if v.Name:sub(1,3) == "TD_" then table.insert(excludeList, v) end
		end
		rayParams.FilterDescendantsInstances = excludeList
		
		local rayResult = workspace:Raycast(Vector3.new(spawnPos.X, 500, spawnPos.Z), Vector3.new(0, -600, 0), rayParams)
		
		if rayResult then
			local groundPos = rayResult.Position
			-- S'assurer que c'est pas visible
			if not isPositionVisible(groundPos + Vector3.new(0, 3, 0)) then
				return groundPos
			end
		end
	end
	
	return nil
end

local function findSpawnPositionSide()
	-- Trouve une position sur les CÔTÉS du joueur
	local camRight = camera.CFrame.RightVector
	local camLook = camera.CFrame.LookVector
	
	for attempt = 1, 10 do
		-- Choisir gauche ou droite
		local side = math.random() > 0.5 and 1 or -1
		local sideDist = math.random(30, 60) * side
		local forwardDist = math.random(-10, 30)
		
		local spawnPos = rootPart.Position 
			+ camRight * sideDist 
			+ camLook * forwardDist
		
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {character}
		for _, v in pairs(workspace:GetChildren()) do
			if v.Name:sub(1,3) == "TD_" then table.insert(excludeList, v) end
		end
		rayParams.FilterDescendantsInstances = excludeList
		
		local rayResult = workspace:Raycast(Vector3.new(spawnPos.X, 500, spawnPos.Z), Vector3.new(0, -600, 0), rayParams)
		
		if rayResult then
			local groundPos = rayResult.Position
			-- Juste hors du champ de vision ou derrière un mur
			if not isPositionVisible(groundPos + Vector3.new(0, 3, 0)) or isPositionBehindWall(groundPos + Vector3.new(0, 3, 0)) then
				return groundPos
			end
		end
	end
	
	return nil
end

local function findSpawnPositionAroundCorner()
	-- Trouve une position DERRIÈRE UN COIN (le plus effrayant!)
	local camLook = camera.CFrame.LookVector
	local camRight = camera.CFrame.RightVector
	
	-- Scanner autour du joueur pour trouver des murs
	for angle = 0, 360, 30 do
		local dir = CFrame.Angles(0, math.rad(angle), 0) * Vector3.new(0, 0, 1)
		
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {character}
		for _, v in pairs(workspace:GetChildren()) do
			if v.Name:sub(1,3) == "TD_" then table.insert(excludeList, v) end
		end
		rayParams.FilterDescendantsInstances = excludeList
		
		-- Chercher un mur
		local rayResult = workspace:Raycast(rootPart.Position, dir * 60, rayParams)
		
		if rayResult and rayResult.Distance > 15 and rayResult.Distance < 50 then
			-- Trouvé un mur! Spawn juste derrière le coin
			local wallPos = rayResult.Position
			local wallNormal = rayResult.Normal
			
			-- Position juste de l'autre côté du mur
			local behindWall = wallPos + wallNormal * -8 -- 8 studs derrière le mur
			
			-- Vérifier le sol
			local groundRay = workspace:Raycast(Vector3.new(behindWall.X, 500, behindWall.Z), Vector3.new(0, -600, 0), rayParams)
			
			if groundRay then
				local groundPos = groundRay.Position
				-- Vérifier que c'est pas visible
				if not isPositionVisible(groundPos + Vector3.new(0, 3, 0)) then
					return groundPos
				end
			end
		end
	end
	
	return nil
end

local function getSmartSpawnPosition()
	-- Choisir une méthode de spawn basée sur les probabilités
	local roll = math.random()
	local spawnPos = nil
	
	-- D'abord essayer de spawn derrière un coin (le plus effrayant)
	if roll < 0.3 then
		spawnPos = findSpawnPositionAroundCorner()
		if spawnPos then return spawnPos, "CORNER" end
	end
	
	-- Ensuite dans le champ de vision mais caché
	if roll < VISION_SPAWN_CHANCE + 0.3 then
		spawnPos = findSpawnPositionInVision()
		if spawnPos then return spawnPos, "VISION" end
	end
	
	-- Derrière le joueur
	if roll < VISION_SPAWN_CHANCE + BEHIND_SPAWN_CHANCE + 0.3 then
		spawnPos = findSpawnPositionBehind()
		if spawnPos then return spawnPos, "BEHIND" end
	end
	
	-- Sur les côtés
	spawnPos = findSpawnPositionSide()
	if spawnPos then return spawnPos, "SIDE" end
	
	-- Fallback: position aléatoire classique
	local angle = math.rad(math.random(0, 360))
	local dist = math.random(50, 90)
	local fallbackPos = rootPart.Position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
	
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local excludeList = {character}
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:sub(1,3) == "TD_" then table.insert(excludeList, v) end
	end
	rayParams.FilterDescendantsInstances = excludeList
	
	local rayResult = workspace:Raycast(Vector3.new(fallbackPos.X, 500, fallbackPos.Z), Vector3.new(0, -600, 0), rayParams)
	if rayResult then
		return rayResult.Position, "RANDOM"
	end
	
	return fallbackPos, "FALLBACK"
end

local function spawnOneDoctor()
	if #activeDoctors >= MAX_DOCTORS then return end
	
	local now = tick()
	if now - lastSpawnTime < SPAWN_COOLDOWN then return end
	lastSpawnTime = now
	
	-- Obtenir une position intelligente
	local spawnPos, spawnType = getSmartSpawnPosition()
	if not spawnPos then return end
	
	local model, rig, data = buildTheDoctor()
	
	local footOffset = 4.5
	local finalPos = spawnPos + Vector3.new(0, footOffset, 0)
	
	-- Regarder vers le joueur
	local lookTarget = Vector3.new(rootPart.Position.X, finalPos.Y, rootPart.Position.Z)
	local lookCF = CFrame.lookAt(finalPos, lookTarget)
	model:PivotTo(lookCF)
	model.Parent = workspace
	
	setupDoctorAI(model, rig, data)
	
	table.insert(activeDoctors, {model = model, rig = rig, data = data})
	
	-- Effet sonore subtil basé sur le type de spawn
	if spawnType == "CORNER" or spawnType == "BEHIND" then
		-- Son plus inquiétant quand il spawn derrière ou dans un coin
		playSnd(SND.static, 0.3)
	end
	
	-- Debug (optionnel)
	-- print("Doctor spawned:", spawnType, "at", math.floor(spawnPos.X), math.floor(spawnPos.Z))
end

local function spawnDoctorArmy()
	lastPlayerPos = rootPart.Position
	playerMoveDistance = 0
	lastSpawnTime = tick()
	
	-- Premier Doctor après un délai
	task.wait(2)
	if eventActive then 
		spawnOneDoctor() 
	end
	
	-- Spawn basé sur le MOUVEMENT du joueur
	task.spawn(function()
		while eventActive do
			task.wait(0.2) -- Check fréquent
			
			if not eventActive then break end
			if not rootPart or not rootPart.Parent then break end
			
			-- Calculer la distance parcourue
			if lastPlayerPos then
				local moved = (rootPart.Position - lastPlayerPos).Magnitude
				playerMoveDistance = playerMoveDistance + moved
			end
			lastPlayerPos = rootPart.Position
			
			-- Spawn quand le joueur a assez bougé
			if playerMoveDistance >= SPAWN_ON_MOVE_DISTANCE then
				playerMoveDistance = 0
				
				if #activeDoctors < MAX_DOCTORS then
					spawnOneDoctor()
				end
			end
		end
	end)
	
	-- Spawn périodique même si le joueur ne bouge pas (mais moins fréquent)
	task.spawn(function()
		while eventActive do
			task.wait(DOCTOR_SPAWN_INTERVAL * 1.5) -- Plus lent que avant
			
			if not eventActive then break end
			
			if #activeDoctors < MAX_DOCTORS then
				-- Spawn seulement si le joueur n'a pas bougé depuis un moment
				if playerMoveDistance < 5 then
					spawnOneDoctor()
					playSnd(SND.static, 0.4)
				end
			end
		end
	end)
	
	-- Spawn quand le joueur REGARDE dans une nouvelle direction (tourne la caméra)
	local lastCamLook = camera.CFrame.LookVector
	task.spawn(function()
		while eventActive do
			task.wait(0.5)
			
			if not eventActive then break end
			
			local currentLook = camera.CFrame.LookVector
			local lookChange = (currentLook - lastCamLook).Magnitude
			
			-- Si le joueur a tourné significativement
			if lookChange > 1.2 then
				-- Chance de spawn quand il se retourne
				if math.random() < 0.3 and #activeDoctors < MAX_DOCTORS then
					-- Spawn dans la direction où il regardait AVANT
					local behindPos = rootPart.Position - lastCamLook * math.random(35, 55)
					
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					local excludeList = {character}
					for _, v in pairs(workspace:GetChildren()) do
						if v.Name:sub(1,3) == "TD_" then table.insert(excludeList, v) end
					end
					rayParams.FilterDescendantsInstances = excludeList
					
					local rayResult = workspace:Raycast(Vector3.new(behindPos.X, 500, behindPos.Z), Vector3.new(0, -600, 0), rayParams)
					
					if rayResult and tick() - lastSpawnTime > SPAWN_COOLDOWN then
						local spawnPos = rayResult.Position
						lastSpawnTime = tick()
						
						local model, rig, data = buildTheDoctor()
						local footOffset = 4.5
						local finalPos = spawnPos + Vector3.new(0, footOffset, 0)
						local lookTarget = Vector3.new(rootPart.Position.X, finalPos.Y, rootPart.Position.Z)
						local lookCF = CFrame.lookAt(finalPos, lookTarget)
						model:PivotTo(lookCF)
						model.Parent = workspace
						
						setupDoctorAI(model, rig, data)
						table.insert(activeDoctors, {model = model, rig = rig, data = data})
						
						-- Son subtil
						playSnd(SND.static, 0.2)
					end
				end
			end
			
			lastCamLook = currentLook
		end
	end)
	
	-- Spawn quand le joueur entre dans une nouvelle "zone"
	local lastZone = Vector3.new(
		math.floor(rootPart.Position.X / 50),
		0,
		math.floor(rootPart.Position.Z / 50)
	)
	task.spawn(function()
		while eventActive do
			task.wait(0.3)
			
			if not eventActive then break end
			if not rootPart or not rootPart.Parent then break end
			
			local currentZone = Vector3.new(
				math.floor(rootPart.Position.X / 50),
				0,
				math.floor(rootPart.Position.Z / 50)
			)
			
			if currentZone ~= lastZone then
				lastZone = currentZone
				
				-- Nouvelle zone! Chance de spawn multiple
				if math.random() < 0.5 and #activeDoctors < MAX_DOCTORS - 1 then
					task.wait(math.random() * 2) -- Délai aléatoire
					if eventActive then
						spawnOneDoctor()
						
						-- Parfois en spawn 2 d'un coup
						if math.random() < 0.3 and #activeDoctors < MAX_DOCTORS then
							task.wait(0.5)
							if eventActive then
								spawnOneDoctor()
							end
						end
					end
				end
			end
		end
	end)
end
-- ═══════════════════════════════════════════════════════════════════
-- DÉMARRER / ARRÊTER L'ÉVÉNEMENT
-- ═══════════════════════════════════════════════════════════════════

function startEvent()
	if eventActive then return end
	eventActive = true
	batteriesFound = 0
	machineActivated = false
	activeDoctors = {}
	doctorConnections = {}
	batteryModels = {}

	-- Ambiance
	activateAtmosphere()

	-- Sons
	local amb = snd(SND.ambient, 0.4, true); amb:Play()
	local br = snd(SND.breathing, 0.2, true); br:Play()

	-- Arme
	task.wait(1)
	createWeapon()

	-- Construire la salle
	task.wait(0.5)
	buildDoctorRoom()

	-- Spawner les batteries
	task.wait(1)
	for i = 1, batteriesRequired do
		spawnBattery(i)
		task.wait(0.3)
	end

	-- Spawner les Doctors
	spawnDoctorArmy()

	-- Mise à jour du GUI
	local gui = player.PlayerGui:FindFirstChild("DoctorEventGui")
	if gui then
		local batLabel = gui:FindFirstChild("BatteryLabel", true)
		if batLabel then
			batLabel.Text = "⚡ BATTERIES : 0 / " .. batteriesRequired
		end
	end
end

function stopEvent(victory)
	eventActive = false

	-- Déconnecter tout
	for _, c in pairs(eventConnections) do pcall(function() c:Disconnect() end) end
	for _, c in pairs(doctorConnections) do pcall(function() c:Disconnect() end) end
	eventConnections = {}; doctorConnections = {}

	-- Nettoyer
	deactivateAtmosphere(); cleanSounds(); removeWeapon()

	-- Détruire les Doctors
	for _, docData in ipairs(activeDoctors) do
		if docData.data.chaseSound then
			pcall(function() docData.data.chaseSound:Stop(); docData.data.chaseSound:Destroy() end)
		end
		pcall(function() docData.model:Destroy() end)
	end
	activeDoctors = {}

	-- Détruire les batteries
	for _, bat in ipairs(batteryModels) do
		pcall(function() bat:Destroy() end)
	end
	batteryModels = {}

	-- Détruire la salle
	if doctorRoom then doctorRoom:Destroy(); doctorRoom = nil end

	-- Nettoyage final
	for _, v in pairs(workspace:GetChildren()) do
		if v.Name:sub(1,3) == "TD_" then v:Destroy() end
	end

	jumpscareActive = false; machineActivated = false

	-- Écran de victoire
	local gui = player.PlayerGui:FindFirstChild("DoctorEventGui")
	if gui and victory then
		local vf = Instance.new("Frame")
		vf.Size = UDim2.new(1,0,1,0); vf.BackgroundColor3 = Color3.new(0,0,0)
		vf.BackgroundTransparency = 0.2; vf.ZIndex = 90; vf.Parent = gui

		local vt = Instance.new("TextLabel")
		vt.Size = UDim2.new(0.8, 0, 0.1, 0)
		vt.Position = UDim2.new(0.1, 0, 0.3, 0)
		vt.BackgroundTransparency = 1
		vt.Text = "⚡ MACHINE DÉTRUITE ⚡"
		vt.TextColor3 = COLORS.neonCyan; vt.TextScaled = true
		vt.Font = Enum.Font.GothamBold; vt.TextStrokeTransparency = 0
		vt.TextStrokeColor3 = Color3.fromRGB(0, 80, 120)
		vt.ZIndex = 91; vt.Parent = vf

		local vt2 = Instance.new("TextLabel")
		vt2.Size = UDim2.new(0.6, 0, 0.08, 0)
		vt2.Position = UDim2.new(0.2, 0, 0.45, 0)
		vt2.BackgroundTransparency = 1
		vt2.Text = "THE DOCTOR EST ÉLIMINÉ"
		vt2.TextColor3 = COLORS.green; vt2.TextScaled = true
		vt2.Font = Enum.Font.GothamBold; vt2.TextStrokeTransparency = 0
		vt2.ZIndex = 91; vt2.Parent = vf

		local vt3 = Instance.new("TextLabel")
		vt3.Size = UDim2.new(0.5, 0, 0.05, 0)
		vt3.Position = UDim2.new(0.25, 0, 0.55, 0)
		vt3.BackgroundTransparency = 1
		vt3.Text = "Signal terminé."
		vt3.TextColor3 = COLORS.dim; vt3.TextScaled = true
		vt3.Font = Enum.Font.Code; vt3.ZIndex = 91; vt3.Parent = vf

		playSnd(SND.victory, 2)

		task.delay(6, function()
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

local sg = Instance.new("ScreenGui"); sg.Name = "DoctorEventGui"
sg.ResetOnSpawn = false; sg.Parent = player.PlayerGui

-- Bouton toggle
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 52, 0, 52)
toggleBtn.Position = UDim2.new(0, 12, 0.5, -26)
toggleBtn.BackgroundColor3 = COLORS.accent
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "📺"; toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 28; toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.ZIndex = 10; toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

-- Frame principal
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 420)
mainFrame.Position = UDim2.new(0, 72, 0.5, -210)
mainFrame.BackgroundColor3 = COLORS.bg; mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 5; mainFrame.Visible = false; mainFrame.Parent = sg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
local mainStroke = Instance.new("UIStroke"); mainStroke.Color = COLORS.accent
mainStroke.Thickness = 2; mainStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 55)
header.BackgroundColor3 = Color3.fromRGB(15, 5, 5)
header.BorderSizePixel = 0; header.ZIndex = 6; header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local hTitle = Instance.new("TextLabel")
hTitle.Size = UDim2.new(1, -60, 1, 0)
hTitle.Position = UDim2.new(0, 14, 0, 0)
hTitle.BackgroundTransparency = 1
hTitle.Text = "📺 THE DOCTOR v4.0"
hTitle.TextColor3 = COLORS.neonRed; hTitle.TextSize = 16
hTitle.Font = Enum.Font.GothamBold
hTitle.TextXAlignment = Enum.TextXAlignment.Left
hTitle.ZIndex = 7; hTitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 32)
closeBtn.Position = UDim2.new(1, -42, 0.5, -16)
closeBtn.BackgroundColor3 = COLORS.accent
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
descF.Size = UDim2.new(1, 0, 0, 140)
descF.BackgroundColor3 = COLORS.card; descF.BorderSizePixel = 0
descF.LayoutOrder = 1; descF.ZIndex = 7; descF.Parent = scroll
Instance.new("UICorner", descF).CornerRadius = UDim.new(0, 8)

local descT = Instance.new("TextLabel")
descT.Size = UDim2.new(1, -12, 1, -6)
descT.Position = UDim2.new(0, 6, 0, 3)
descT.BackgroundTransparency = 1; descT.TextWrapped = true
descT.Text = "📺 Des robots TV-Head apparaissent en STATUES\n🟡 Approchez → Écran JAUNE (Réveil)\n🔴 Plus proche → Écran ROUGE (Chasse!)\n⚡ Trouvez 3 BATTERIES qui brillent au sol\n🏭 Apportez-les à la SALLE DU DOCTOR\n🔧 Insérez-les dans la MACHINE CENTRALE\n💥 La machine EXPLOSE et détruit The Doctor\n⚔️ Clic gauche = Frapper les Doctors\n💀 S'ils vous touchent = MORT"
descT.TextColor3 = COLORS.text; descT.TextSize = 9
descT.Font = Enum.Font.Gotham
descT.TextXAlignment = Enum.TextXAlignment.Left
descT.TextYAlignment = Enum.TextYAlignment.Top
descT.ZIndex = 8; descT.Parent = descF

-- Compteur de batteries
local batFrame = Instance.new("Frame")
batFrame.Size = UDim2.new(1, 0, 0, 35)
batFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 25)
batFrame.BorderSizePixel = 0; batFrame.LayoutOrder = 2
batFrame.ZIndex = 7; batFrame.Parent = scroll
Instance.new("UICorner", batFrame).CornerRadius = UDim.new(0, 8)

local batLabel = Instance.new("TextLabel")
batLabel.Name = "BatteryLabel"
batLabel.Size = UDim2.new(1, -12, 1, 0)
batLabel.Position = UDim2.new(0, 6, 0, 0)
batLabel.BackgroundTransparency = 1
batLabel.Text = "⚡ BATTERIES : 0 / " .. batteriesRequired
batLabel.TextColor3 = COLORS.neonCyan
batLabel.TextSize = 13; batLabel.Font = Enum.Font.Code
batLabel.TextXAlignment = Enum.TextXAlignment.Left
batLabel.ZIndex = 8; batLabel.Parent = batFrame

-- Bouton Start
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, 0, 0, 48)
startBtn.BackgroundColor3 = COLORS.accent
startBtn.Text = "⚡ DÉMARRER L'INVASION"
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.TextSize = 14; startBtn.Font = Enum.Font.GothamBold
startBtn.LayoutOrder = 3; startBtn.ZIndex = 7; startBtn.Parent = scroll
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

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
infoT.Text = "⌨️ [N] Menu | 🖱️ Clic = Frapper | [E] Interagir\n📺 Les Doctors sont immobiles au début..."
infoT.TextColor3 = COLORS.dim; infoT.TextSize = 9
infoT.Font = Enum.Font.Gotham
infoT.TextXAlignment = Enum.TextXAlignment.Left
infoT.ZIndex = 8; infoT.Parent = infoF

-- ══════════════════════════════
-- ÉVÉNEMENTS GUI
-- ══════════════════════════════
startBtn.MouseButton1Click:Connect(function()
	if eventActive then return end
	startBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 20)
	startBtn.Text = "⚡ EN COURS..."
	task.spawn(startEvent)
end)

stopBtn.MouseButton1Click:Connect(function()
	if eventActive then
		stopEvent(false)
		startBtn.BackgroundColor3 = COLORS.accent
		startBtn.Text = "⚡ DÉMARRER L'INVASION"
	end
end)

toggleBtn.MouseButton1Click:Connect(function()
	guiOpen = not guiOpen
	mainFrame.Visible = guiOpen
	if guiOpen then
		mainFrame.Position = UDim2.new(0, 52, 0.5, -210)
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = UDim2.new(0, 72, 0.5, -210)
		}):Play()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	guiOpen = false
	TweenService:Create(mainFrame, TweenInfo.new(0.2), {
		Position = UDim2.new(0, 52, 0.5, -210)
	}):Play()
	task.wait(0.2); mainFrame.Visible = false
end)

-- ═══════════════════════════════════════════════════════════════════
-- INPUT (Frappe + Toggle)
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

-- ═══════════════════════════════════════════════════════════════════
-- RENDER LOOP (Bouton pulse + effets)
-- ═══════════════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
	local t = tick()
	local pulse = math.sin(t * 3) * 0.15 + 0.85

	if eventActive then
		toggleBtn.BackgroundColor3 = Color3.fromRGB(
			math.floor(200 * pulse), 0, math.floor(40 * pulse)
		)
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
	n.Size = UDim2.new(0, 420, 0, 65)
	n.Position = UDim2.new(0.5, -210, 0, -75)
	n.BackgroundColor3 = COLORS.card; n.BorderSizePixel = 0
	n.ZIndex = 50; n.Parent = sg
	Instance.new("UICorner", n).CornerRadius = UDim.new(0, 12)
	local nStroke = Instance.new("UIStroke"); nStroke.Color = COLORS.accent; nStroke.Parent = n

	local nt = Instance.new("TextLabel")
	nt.Size = UDim2.new(1, -16, 0, 26)
	nt.Position = UDim2.new(0, 12, 0, 5)
	nt.BackgroundTransparency = 1
	nt.Text = "📺 THE DOCTOR — Nightmare Event v4.0"
	nt.TextColor3 = COLORS.neonRed; nt.TextSize = 14
	nt.Font = Enum.Font.GothamBold
	nt.TextXAlignment = Enum.TextXAlignment.Left
	nt.ZIndex = 51; nt.Parent = n

	local ns = Instance.new("TextLabel")
	ns.Size = UDim2.new(1, -16, 0, 22)
	ns.Position = UDim2.new(0, 12, 0, 32)
	ns.BackgroundTransparency = 1
	ns.Text = "[N] Menu | Statues TV-Head | Batteries ⚡ | Machine Centrale"
	ns.TextColor3 = COLORS.dim; ns.TextSize = 9
	ns.Font = Enum.Font.Gotham
	ns.TextXAlignment = Enum.TextXAlignment.Left
	ns.ZIndex = 51; ns.Parent = n

	TweenService:Create(n, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, -210, 0, 12)
	}):Play()
	task.wait(6)
	TweenService:Create(n, TweenInfo.new(0.3), {
		Position = UDim2.new(0.5, -210, 0, -75)
	}):Play()
	task.wait(0.4); n:Destroy()
end)

-- ═══════════════════════════════════════════════════════════════════
-- FIN DU SCRIPT
-- ═══════════════════════════════════════════════════════════════════

print("═══════════════════════════════════════")
print(" 📺 THE DOCTOR — Nightmare Event v4.0")
print(" ✅ Robots TV-Head avec écran dynamique")
print(" ✅ 3 états: IDLE → WAKING → CHASE")
print(" ✅ Écran éteint → Jaune → Rouge")
print(" ✅ Oeil qui apparaît progressivement")
print(" ✅ Armée de clones qui spawn au fur et à mesure")
print(" ✅ 3 Batteries avec effet Glowing (cyan)")
print(" ✅ Batteries spawn sur sol sûr (Raycast)")
print(" ✅ Salle du Doctor avec écrans partout")
print(" ✅ Machine Centrale avec noyau lumineux")
print(" ✅ Séquence d'explosion épique")
print(" ✅ Jumpscare avec oeil rouge et static TV")
print(" ✅ Atmosphère sombre et brumeuse")
print(" ✅ Cape/Cloak avec lambeaux")
print(" ✅ Bras robotiques avec doigts")
print(" ✅ Antennes sur la TV")
print(" ⌨️ [N] Menu | [E] Interagir | Clic = Frapper")
print("═══════════════════════════════════════")
