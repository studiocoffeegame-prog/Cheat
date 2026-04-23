-- ═══════════════════════════════════════════════════════════════════
-- COOLKID MORPH SYSTEM v5.0 — MOTOR6D COMPLET
-- ═══════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Nettoyage
for _, v in pairs(player.PlayerGui:GetChildren()) do
	if v.Name == "CoolKidMorph" then v:Destroy() end
end
for _, v in pairs(Lighting:GetChildren()) do
	if v.Name:sub(1,4) == "CKM_" then v:Destroy() end
end
if workspace:FindFirstChild("CKM_MorphModel") then workspace.CKM_MorphModel:Destroy() end

-- ═══════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════
local isMorphed = false
local currentMorphName = ""
local morphModel = nil
local currentRig = nil
local morphYOffset = 0
local animConn = nil
local posConn = nil
local animTimer = 0
local animState = "idle"
local isGrabbing = false
local jumpscareActive = false
local soundsEnabled = true
local GRAB_RANGE = 18
local JUMPSCARE_DURATION = 3.5

-- ═══════════════════════════════════════
-- SONS
-- ═══════════════════════════════════════
local SND = {
	jumpscare1 = "rbxassetid://138327151986755",
	jumpscare2 = "rbxassetid://137800374619679",
	jumpscare3 = "rbxassetid://137120797573299",
	transform  = "rbxassetid://127835842316773",
	grab       = "rbxassetid://139548232423621",
	growl      = "rbxassetid://137846139742751",
	laugh      = "rbxassetid://140445930084397",
	static     = "rbxassetid://130218336377793",
	scream     = "rbxassetid://140136241788259",
	bone       = "rbxassetid://138367509087203",
	ambient    = "rbxassetid://140698715847574",
	heartbeat  = "rbxassetid://139481207162657",
	whoosh     = "rbxassetid://140334012603496",
	distortion = "rbxassetid://132547462300216",
}

local function snd(id, vol, loop)
	if not soundsEnabled then return {Play=function()end,Stop=function()end,Destroy=function()end} end
	local s = Instance.new("Sound")
	s.SoundId = id or ""; s.Volume = vol or 1; s.Looped = loop or false
	s.Name = "CKM_Sound"; s.Parent = SoundService
	return s
end

local function cleanSounds()
	for _, s in pairs(SoundService:GetChildren()) do
		if s.Name == "CKM_Sound" then pcall(function() s:Stop() s:Destroy() end) end
	end
end

-- ═══════════════════════════════════════
-- COULEURS
-- ═══════════════════════════════════════
local C = {
	bg=Color3.fromRGB(8,8,14), sidebar=Color3.fromRGB(6,6,10),
	card=Color3.fromRGB(18,18,26), cardH=Color3.fromRGB(28,28,40),
	accent=Color3.fromRGB(255,0,60), accentG=Color3.fromRGB(255,30,80),
	accent2=Color3.fromRGB(180,0,255), accent3=Color3.fromRGB(0,200,255),
	orange=Color3.fromRGB(255,120,0), green=Color3.fromRGB(0,255,120),
	yellow=Color3.fromRGB(255,220,0), text=Color3.fromRGB(230,230,240),
	dim=Color3.fromRGB(100,100,120), tOn=Color3.fromRGB(255,0,60),
	tOff=Color3.fromRGB(50,50,60), blood=Color3.fromRGB(139,0,0),
	bone=Color3.fromRGB(230,220,200),
}

local MC = {
	HuggyWuggy  = {p=Color3.fromRGB(0,80,200),   s=Color3.fromRGB(200,30,30),  a=Color3.fromRGB(255,220,0)},
	CartoonCat  = {p=Color3.fromRGB(20,20,20),    s=Color3.fromRGB(255,255,255), a=Color3.fromRGB(255,0,0)},
	SirenHead   = {p=Color3.fromRGB(100,80,60),   s=Color3.fromRGB(60,50,40),    a=Color3.fromRGB(255,200,0)},
	Wendigo     = {p=Color3.fromRGB(80,60,50),    s=Color3.fromRGB(200,180,160), a=Color3.fromRGB(200,0,0)},
	SkinWalker  = {p=Color3.fromRGB(180,150,120), s=Color3.fromRGB(100,70,50),   a=Color3.fromRGB(0,0,0)},
	TheRake     = {p=Color3.fromRGB(200,190,180), s=Color3.fromRGB(150,140,130), a=Color3.fromRGB(0,0,0)},
	Slenderman  = {p=Color3.fromRGB(30,30,30),    s=Color3.fromRGB(240,240,240), a=Color3.fromRGB(0,0,0)},
}

local FootOffsets = {
	HuggyWuggy=7.9, CartoonCat=9.5, SirenHead=8.8,
	Wendigo=8.3, SkinWalker=7.8, TheRake=4.0, Slenderman=10.6,
}

local AmbSounds = {
	HuggyWuggy=SND.growl, CartoonCat=SND.laugh, SirenHead=SND.static,
	Wendigo=SND.scream, SkinWalker=SND.bone, TheRake=SND.growl, Slenderman=SND.ambient,
}

local MorphSpeeds = {
	HuggyWuggy={w=28,j=70}, CartoonCat={w=32,j=80}, SirenHead={w=24,j=60},
	Wendigo={w=35,j=90}, SkinWalker={w=40,j=85}, TheRake={w=45,j=100}, Slenderman={w=22,j=50},
}

-- ═══════════════════════════════════════
-- HELPERS CONSTRUCTION
-- ═══════════════════════════════════════

-- WeldConstraint pour les détails fixes (yeux, dents, poils)
local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a; w.Part1 = b; w.Parent = a
	return w
end

-- Motor6D pour les membres animables (bras, jambes, tête, etc.)
local function motor(part0, part1, name)
	local m = Instance.new("Motor6D")
	m.Name = name or (part1.Name.."_Motor")
	m.Part0 = part0; m.Part1 = part1
	m.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	m.C1 = CFrame.new()
	m.Parent = part0
	return m
end

local function mp(par, name, sz, col, mat, tr)
	local p = Instance.new("Part")
	p.Name = name; p.Size = sz; p.Color = col
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = tr or 0
	p.CanCollide = false; p.Anchored = false; p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = par
	return p
end

local function ms(par, name, sz, col, mat, tr)
	local p = mp(par, name, sz, col, mat, tr)
	p.Shape = Enum.PartType.Ball
	return p
end

-- ═══════════════════════════════════════════════════════════════════
-- BUILDERS (Motor6D pour membres, WeldConstraint pour détails)
-- ═══════════════════════════════════════════════════════════════════

local function buildHuggyWuggy()
	local model = Instance.new("Model"); model.Name = "HuggyWuggy"
	local col = MC.HuggyWuggy; local rig = {}

	-- Couleurs
	local bleu = col.p -- bleu principal
	local rouge = col.s -- rouge (bouche)
	local jaune = col.a -- jaune (yeux, mains, pieds)
	local noir = Color3.fromRGB(15, 15, 20)
	local bleuF = Color3.fromRGB(0, 50, 150) -- bleu foncé pour fourrure
	local bleuC = Color3.fromRGB(30, 120, 255) -- bleu clair pour fourrure

	-- ═══ ROOT ═══
	local root = mp(model, "HumanoidRootPart", Vector3.new(3,4.5,2), bleu, nil, 1)
	root.Anchored = true; model.PrimaryPart = root

	-- ═══ CORPS ═══
	local body = mp(model, "Body", Vector3.new(3.2, 5, 2.2), bleu)
	body.CFrame = root.CFrame
	rig.Root = motor(root, body, "Root")

	-- Ventre légèrement plus clair
	local belly = mp(model, "Belly", Vector3.new(2.4, 2.5, 0.4), bleuC)
	belly.CFrame = body.CFrame * CFrame.new(0, -0.5, -1.1)
	weld(body, belly)

	-- ═══ TÊTE (sculptée avec plusieurs parts) ═══
	-- Crâne principal (plus rond)
	local head = mp(model, "Head", Vector3.new(3.8, 3.2, 3.2), bleu)
	head.CFrame = root.CFrame * CFrame.new(0, 4.5, 0)
	rig.Neck = motor(body, head, "Neck")

	-- Haut du crâne (arrondi)
	local skullTop = ms(model, "SkullTop", Vector3.new(3.4, 2.2, 3), bleu)
	skullTop.CFrame = head.CFrame * CFrame.new(0, 1.2, -0.1)
	weld(head, skullTop)

	-- Joues (gonflées)
	local cheekL = ms(model, "CheekL", Vector3.new(1.2, 1, 1), bleu)
	cheekL.CFrame = head.CFrame * CFrame.new(-1.6, -0.3, -0.8)
	weld(head, cheekL)

	local cheekR = ms(model, "CheekR", Vector3.new(1.2, 1, 1), bleu)
	cheekR.CFrame = head.CFrame * CFrame.new(1.6, -0.3, -0.8)
	weld(head, cheekR)

	-- Menton
	local chin = ms(model, "Chin", Vector3.new(1.8, 0.8, 1), bleu)
	chin.CFrame = head.CFrame * CFrame.new(0, -1.6, -0.6)
	weld(head, chin)

	-- ═══ YEUX (sur la face avant) ═══
	-- Contour des yeux (creux noir)
	local eyeSocketL = ms(model, "EyeSocketL", Vector3.new(1.2, 1.4, 0.6), noir)
	eyeSocketL.CFrame = head.CFrame * CFrame.new(-0.75, 0.4, -1.5)
	weld(head, eyeSocketL)

	local eyeSocketR = ms(model, "EyeSocketR", Vector3.new(1.2, 1.4, 0.6), noir)
	eyeSocketR.CFrame = head.CFrame * CFrame.new(0.75, 0.4, -1.5)
	weld(head, eyeSocketR)

	-- Yeux jaunes (devant les sockets)
	local eyeL = ms(model, "EyeL", Vector3.new(0.95, 1.2, 0.45), jaune, Enum.Material.Neon)
	eyeL.CFrame = head.CFrame * CFrame.new(-0.75, 0.45, -1.65)
	weld(head, eyeL)

	local eyeR = ms(model, "EyeR", Vector3.new(0.95, 1.2, 0.45), jaune, Enum.Material.Neon)
	eyeR.CFrame = head.CFrame * CFrame.new(0.75, 0.45, -1.65)
	weld(head, eyeR)

	-- Pupilles noires
	local pupL = ms(model, "PupL", Vector3.new(0.4, 0.55, 0.3), noir)
	pupL.CFrame = eyeL.CFrame * CFrame.new(0, 0, -0.15)
	weld(eyeL, pupL)

	local pupR = ms(model, "PupR", Vector3.new(0.4, 0.55, 0.3), noir)
	pupR.CFrame = eyeR.CFrame * CFrame.new(0, 0, -0.15)
	weld(eyeR, pupR)

	-- ═══ LÈVRES / BOUCHE (sur la face avant) ═══
	-- Lèvre supérieure
	local lipTop = mp(model, "LipTop", Vector3.new(2.6, 0.35, 0.6), rouge)
	lipTop.CFrame = head.CFrame * CFrame.new(0, -0.55, -1.5)
	weld(head, lipTop)

	-- Lèvre inférieure (animable via Jaw)
	local lipBottom = mp(model, "LipBottom", Vector3.new(2.4, 0.3, 0.5), rouge)
	lipBottom.CFrame = head.CFrame * CFrame.new(0, -1.1, -1.4)
	rig.Jaw = motor(head, lipBottom, "Jaw")

	-- Intérieur de la bouche (noir profond)
	local mouthInside = mp(model, "MouthInside", Vector3.new(2.2, 0.8, 1.2), Color3.fromRGB(30, 5, 5))
	mouthInside.CFrame = head.CFrame * CFrame.new(0, -0.8, -1.1)
	weld(head, mouthInside)

	-- ═══ DENTS (sur la face avant, pointues) ═══
	-- Dents du haut
	for i = -4, 4 do
		local tSize = (math.abs(i) <= 1) and Vector3.new(0.22, 0.55, 0.2) or Vector3.new(0.18, 0.4, 0.18)
		local tooth = mp(model, "TU"..i, tSize, Color3.new(1,1,1))
		tooth.CFrame = head.CFrame * CFrame.new(i * 0.28, -0.55, -1.65)
			* CFrame.Angles(math.rad(5), 0, 0)
		weld(head, tooth)
	end

	-- Dents du bas (sur la lèvre inférieure)
	for i = -3, 3 do
		local tSize = (math.abs(i) <= 1) and Vector3.new(0.2, 0.5, 0.18) or Vector3.new(0.16, 0.35, 0.16)
		local tooth = mp(model, "TD"..i, tSize, Color3.new(1,1,1))
		tooth.CFrame = lipBottom.CFrame * CFrame.new(i * 0.3, 0.25, -0.15)
			* CFrame.Angles(math.rad(-5), 0, 0)
		weld(lipBottom, tooth)
	end

	-- ═══ NEZ (petit, sur la face avant) ═══
	local nose = ms(model, "Nose", Vector3.new(0.5, 0.35, 0.3), noir)
	nose.CFrame = head.CFrame * CFrame.new(0, 0, -1.7)
	weld(head, nose)

	-- ═══ BRAS GAUCHE ═══
	local armL1 = mp(model, "ArmL1", Vector3.new(1.3, 4.5, 1.3), bleu)
	armL1.CFrame = root.CFrame * CFrame.new(-2.6, 1.2, 0)
	rig.ShoulderL = motor(body, armL1, "ShoulderL")

	local armL2 = mp(model, "ArmL2", Vector3.new(1.05, 4.5, 1.05), bleu)
	armL2.CFrame = armL1.CFrame * CFrame.new(0, -4.5, 0)
	rig.ElbowL = motor(armL1, armL2, "ElbowL")

	-- Main JAUNE gauche
	local handL = mp(model, "HandL", Vector3.new(1.6, 1.8, 1), jaune)
	handL.CFrame = armL2.CFrame * CFrame.new(0, -3, 0)
	rig.WristL = motor(armL2, handL, "WristL")

	-- Doigts gauche (jaunes)
	for i = -2, 2 do
		local finger = mp(model, "FingerL"..i, Vector3.new(0.18, 1.1, 0.18), jaune)
		finger.CFrame = handL.CFrame * CFrame.new(i * 0.32, -1.2, 0)
			* CFrame.Angles(math.rad(math.random(-8, 8)), 0, math.rad(i * 4))
		weld(handL, finger)
	end

	-- ═══ BRAS DROIT ═══
	local armR1 = mp(model, "ArmR1", Vector3.new(1.3, 4.5, 1.3), bleu)
	armR1.CFrame = root.CFrame * CFrame.new(2.6, 1.2, 0)
	rig.ShoulderR = motor(body, armR1, "ShoulderR")

	local armR2 = mp(model, "ArmR2", Vector3.new(1.05, 4.5, 1.05), bleu)
	armR2.CFrame = armR1.CFrame * CFrame.new(0, -4.5, 0)
	rig.ElbowR = motor(armR1, armR2, "ElbowR")

	-- Main JAUNE droite
	local handR = mp(model, "HandR", Vector3.new(1.6, 1.8, 1), jaune)
	handR.CFrame = armR2.CFrame * CFrame.new(0, -3, 0)
	rig.WristR = motor(armR2, handR, "WristR")

	-- Doigts droite (jaunes)
	for i = -2, 2 do
		local finger = mp(model, "FingerR"..i, Vector3.new(0.18, 1.1, 0.18), jaune)
		finger.CFrame = handR.CFrame * CFrame.new(i * 0.32, -1.2, 0)
			* CFrame.Angles(math.rad(math.random(-8, 8)), 0, math.rad(i * 4))
		weld(handR, finger)
	end

	-- ═══ JAMBE GAUCHE ═══
	local legL = mp(model, "LegL", Vector3.new(1.4, 5.5, 1.4), bleu)
	legL.CFrame = root.CFrame * CFrame.new(-1, -5.2, 0)
	rig.HipL = motor(body, legL, "HipL")

	-- Pied JAUNE gauche
	local footL = mp(model, "FootL", Vector3.new(1.8, 0.7, 2.4), jaune)
	footL.CFrame = legL.CFrame * CFrame.new(0, -3.1, 0.4)
	rig.AnkleL = motor(legL, footL, "AnkleL")

	-- Orteils gauche
	for i = -1, 1 do
		local toe = mp(model, "ToeL"..i, Vector3.new(0.4, 0.35, 0.6), jaune)
		toe.CFrame = footL.CFrame * CFrame.new(i * 0.5, 0, -1.3)
		weld(footL, toe)
	end

	-- ═══ JAMBE DROITE ═══
	local legR = mp(model, "LegR", Vector3.new(1.4, 5.5, 1.4), bleu)
	legR.CFrame = root.CFrame * CFrame.new(1, -5.2, 0)
	rig.HipR = motor(body, legR, "HipR")

	-- Pied JAUNE droit
	local footR = mp(model, "FootR", Vector3.new(1.8, 0.7, 2.4), jaune)
	footR.CFrame = legR.CFrame * CFrame.new(0, -3.1, 0.4)
	rig.AnkleR = motor(legR, footR, "AnkleR")

	-- Orteils droit
	for i = -1, 1 do
		local toe = mp(model, "ToeR"..i, Vector3.new(0.4, 0.35, 0.6), jaune)
		toe.CFrame = footR.CFrame * CFrame.new(i * 0.5, 0, -1.3)
		weld(footR, toe)
	end

	-- ═══ FOURRURE (effet poils subtils) ═══
	-- Poils sur le corps (quantité modérée)
	local furPositions = {
		-- Corps
		{parent = body, offset = CFrame.new(-1.4, 1.5, 0.5), size = Vector3.new(0.25, 0.7, 0.25)},
		{parent = body, offset = CFrame.new(1.2, 1.8, 0.6), size = Vector3.new(0.3, 0.6, 0.25)},
		{parent = body, offset = CFrame.new(-0.8, -1.5, 0.8), size = Vector3.new(0.2, 0.65, 0.2)},
		{parent = body, offset = CFrame.new(0.5, 0.5, 0.9), size = Vector3.new(0.25, 0.55, 0.2)},
		{parent = body, offset = CFrame.new(-1.3, 0, 0.7), size = Vector3.new(0.2, 0.7, 0.2)},
		{parent = body, offset = CFrame.new(1.5, -0.8, 0.5), size = Vector3.new(0.25, 0.6, 0.22)},
		{parent = body, offset = CFrame.new(0, 2, 0.6), size = Vector3.new(0.3, 0.5, 0.25)},
		{parent = body, offset = CFrame.new(-0.3, -2, 0.7), size = Vector3.new(0.2, 0.6, 0.2)},
		-- Côtés du corps
		{parent = body, offset = CFrame.new(-1.6, 0.5, 0), size = Vector3.new(0.2, 0.6, 0.3)},
		{parent = body, offset = CFrame.new(1.6, 1, 0), size = Vector3.new(0.2, 0.55, 0.3)},
		{parent = body, offset = CFrame.new(-1.5, -1, -0.3), size = Vector3.new(0.22, 0.5, 0.25)},
		{parent = body, offset = CFrame.new(1.4, -1.5, 0.2), size = Vector3.new(0.25, 0.6, 0.2)},
		-- Tête
		{parent = head, offset = CFrame.new(-1.5, 0.8, 0), size = Vector3.new(0.25, 0.5, 0.25)},
		{parent = head, offset = CFrame.new(1.5, 0.8, 0), size = Vector3.new(0.25, 0.5, 0.25)},
		{parent = head, offset = CFrame.new(0, 1.5, 0.5), size = Vector3.new(0.3, 0.45, 0.25)},
		{parent = head, offset = CFrame.new(-0.8, 1.3, 0.6), size = Vector3.new(0.2, 0.5, 0.2)},
		{parent = head, offset = CFrame.new(0.8, 1.3, 0.6), size = Vector3.new(0.2, 0.5, 0.2)},
		-- Bras
		{parent = armL1, offset = CFrame.new(-0.6, 0.5, 0.3), size = Vector3.new(0.2, 0.55, 0.2)},
		{parent = armL1, offset = CFrame.new(-0.5, -1.5, 0.4), size = Vector3.new(0.2, 0.5, 0.2)},
		{parent = armR1, offset = CFrame.new(0.6, 0.5, 0.3), size = Vector3.new(0.2, 0.55, 0.2)},
		{parent = armR1, offset = CFrame.new(0.5, -1.5, 0.4), size = Vector3.new(0.2, 0.5, 0.2)},
		-- Jambes
		{parent = legL, offset = CFrame.new(-0.6, 0, 0.4), size = Vector3.new(0.2, 0.55, 0.2)},
		{parent = legL, offset = CFrame.new(-0.5, -2, 0.5), size = Vector3.new(0.22, 0.5, 0.2)},
		{parent = legR, offset = CFrame.new(0.6, 0, 0.4), size = Vector3.new(0.2, 0.55, 0.2)},
		{parent = legR, offset = CFrame.new(0.5, -2, 0.5), size = Vector3.new(0.22, 0.5, 0.2)},
	}

	for idx, furData in ipairs(furPositions) do
		-- Alterner les couleurs de fourrure
		local furColor
		local roll = math.random(1, 3)
		if roll == 1 then furColor = bleu
		elseif roll == 2 then furColor = bleuF
		else furColor = bleuC end

		local fur = mp(model, "Fur"..idx, furData.size, furColor)
		fur.CFrame = furData.parent.CFrame * furData.offset
			* CFrame.Angles(math.rad(math.random(-15, 15)), math.rad(math.random(-15, 15)), math.rad(math.random(-10, 10)))
		weld(furData.parent, fur)
	end

	-- ═══ SOURCILS (froncement menaçant) ═══
	local browL = mp(model, "BrowL", Vector3.new(0.9, 0.2, 0.35), noir)
	browL.CFrame = head.CFrame * CFrame.new(-0.75, 1.05, -1.55)
		* CFrame.Angles(0, 0, math.rad(12))
	weld(head, browL)

	local browR = mp(model, "BrowR", Vector3.new(0.9, 0.2, 0.35), noir)
	browR.CFrame = head.CFrame * CFrame.new(0.75, 1.05, -1.55)
		* CFrame.Angles(0, 0, math.rad(-12))
	weld(head, browR)

	return model, FootOffsets.HuggyWuggy, rig
end

local function buildCartoonCat()
	local model = Instance.new("Model"); model.Name = "CartoonCat"
	local col = MC.CartoonCat; local rig = {}

	-- Couleurs
	local noir = col.p -- noir principal
	local blanc = col.s -- blanc (yeux, dents)
	local rouge = col.a -- rouge (bouche, sourire)
	local gris = Color3.fromRGB(40, 40, 45)
	local grisClair = Color3.fromRGB(70, 70, 75)
	local gantBlanc = Color3.fromRGB(245, 245, 245) -- gants Mickey
	local rosePatte = Color3.fromRGB(60, 30, 40) -- intérieur oreilles

	-- ═══ ROOT ═══
	local root = mp(model, "HumanoidRootPart", Vector3.new(3.5,6,2.5), noir, nil, 1)
	root.Anchored = true; model.PrimaryPart = root

	-- ═══ CORPS ═══
	local body = mp(model, "Body", Vector3.new(3.5, 6.5, 2.5), noir)
	body.CFrame = root.CFrame
	rig.Root = motor(root, body, "Root")

	-- Ventre (légèrement plus gris pour donner du relief)
	local belly = mp(model, "Belly", Vector3.new(2.5, 3, 0.3), gris)
	belly.CFrame = body.CFrame * CFrame.new(0, -0.5, -1.25)
	weld(body, belly)

	-- ═══ TÊTE (grosse tête de chat cartoon) ═══
	local head = mp(model, "Head", Vector3.new(4.2, 3.8, 3.8), noir)
	head.CFrame = root.CFrame * CFrame.new(0, 5.8, 0)
	rig.Neck = motor(body, head, "Neck")

	-- Arrondi du crâne
	local skullTop = ms(model, "SkullTop", Vector3.new(3.8, 2.5, 3.4), noir)
	skullTop.CFrame = head.CFrame * CFrame.new(0, 1.3, -0.1)
	weld(head, skullTop)

	-- Joues
	local cheekL = ms(model, "CheekL", Vector3.new(1.3, 1, 1.2), noir)
	cheekL.CFrame = head.CFrame * CFrame.new(-1.7, -0.4, -0.9)
	weld(head, cheekL)
	local cheekR = ms(model, "CheekR", Vector3.new(1.3, 1, 1.2), noir)
	cheekR.CFrame = head.CFrame * CFrame.new(1.7, -0.4, -0.9)
	weld(head, cheekR)

	-- ═══ OREILLES (triangulaires, style chat) ═══
	-- Oreille gauche
	local earL = mp(model, "EarL", Vector3.new(1.4, 2.8, 0.5), noir)
	earL.CFrame = head.CFrame * CFrame.new(-1.4, 2.5, 0) * CFrame.Angles(0, 0, math.rad(-18))
	weld(head, earL)

	-- Pointe de l'oreille gauche
	local earTipL = mp(model, "EarTipL", Vector3.new(0.8, 1.2, 0.4), noir)
	earTipL.CFrame = earL.CFrame * CFrame.new(-0.2, 1.8, 0) * CFrame.Angles(0, 0, math.rad(-10))
	weld(earL, earTipL)

	-- Intérieur oreille gauche
	local earInL = mp(model, "EarInL", Vector3.new(0.8, 2, 0.2), rosePatte)
	earInL.CFrame = earL.CFrame * CFrame.new(0, 0.3, -0.2)
	weld(earL, earInL)

	-- Oreille droite
	local earR = mp(model, "EarR", Vector3.new(1.4, 2.8, 0.5), noir)
	earR.CFrame = head.CFrame * CFrame.new(1.4, 2.5, 0) * CFrame.Angles(0, 0, math.rad(18))
	weld(head, earR)

	local earTipR = mp(model, "EarTipR", Vector3.new(0.8, 1.2, 0.4), noir)
	earTipR.CFrame = earR.CFrame * CFrame.new(0.2, 1.8, 0) * CFrame.Angles(0, 0, math.rad(10))
	weld(earR, earTipR)

	local earInR = mp(model, "EarInR", Vector3.new(0.8, 2, 0.2), rosePatte)
	earInR.CFrame = earR.CFrame * CFrame.new(0, 0.3, -0.2)
	weld(earR, earInR)

	-- ═══ YEUX (TRÈS GÉANTS, poussés vers l'avant) ═══
	-- Orbites noires
	local eyeSocketL = ms(model, "EyeSocketL", Vector3.new(3.2, 3.4, 0.8), gris)
	eyeSocketL.CFrame = head.CFrame * CFrame.new(-1.1, 0.5, -1.9)
	weld(head, eyeSocketL)

	local eyeSocketR = ms(model, "EyeSocketR", Vector3.new(3.2, 3.4, 0.8), gris)
	eyeSocketR.CFrame = head.CFrame * CFrame.new(1.1, 0.5, -1.9)
	weld(head, eyeSocketR)

	-- Yeux blancs TRÈS GÉANTS (sortent de la tête)
	local eyeL = ms(model, "EyeL", Vector3.new(3, 3.2, 0.7), blanc, Enum.Material.Neon)
	eyeL.CFrame = head.CFrame * CFrame.new(-1.1, 0.55, -2.1)
	weld(head, eyeL)

	local eyeR = ms(model, "EyeR", Vector3.new(3, 3.2, 0.7), blanc, Enum.Material.Neon)
	eyeR.CFrame = head.CFrame * CFrame.new(1.1, 0.55, -2.1)
	weld(head, eyeR)

	-- Pupilles noires
	local pupilL = ms(model, "PupilL", Vector3.new(1.5, 1.8, 0.5), Color3.new(0,0,0))
	pupilL.CFrame = eyeL.CFrame * CFrame.new(0, 0, -0.15)
	weld(eyeL, pupilL)

	local pupilR = ms(model, "PupilR", Vector3.new(1.5, 1.8, 0.5), Color3.new(0,0,0))
	pupilR.CFrame = eyeR.CFrame * CFrame.new(0, 0, -0.15)
	weld(eyeR, pupilR)

	-- Reflets DANS la pupille
	local reflectL = ms(model, "ReflectL", Vector3.new(0.4, 0.45, 0.25), blanc, Enum.Material.Neon)
	reflectL.CFrame = pupilL.CFrame * CFrame.new(-0.2, 0.3, -0.05)
	weld(pupilL, reflectL)

	local reflectR = ms(model, "ReflectR", Vector3.new(0.4, 0.45, 0.25), blanc, Enum.Material.Neon)
	reflectR.CFrame = pupilR.CFrame * CFrame.new(-0.2, 0.3, -0.05)
	weld(pupilR, reflectR)

	-- Deuxième reflet
	local reflect2L = ms(model, "Reflect2L", Vector3.new(0.2, 0.22, 0.15), blanc, Enum.Material.Neon)
	reflect2L.CFrame = pupilL.CFrame * CFrame.new(0.15, -0.2, -0.05)
	weld(pupilL, reflect2L)

	local reflect2R = ms(model, "Reflect2R", Vector3.new(0.2, 0.22, 0.15), blanc, Enum.Material.Neon)
	reflect2R.CFrame = pupilR.CFrame * CFrame.new(0.15, -0.2, -0.05)
	weld(pupilR, reflect2R)
	-- ═══ NEZ ═══
	local nose = ms(model, "Nose", Vector3.new(0.6, 0.45, 0.35), rosePatte)
	nose.CFrame = head.CFrame * CFrame.new(0, -0.15, -1.9)
	weld(head, nose)

		-- ═══ SOURIRE (grand sourire de chat sinistre — face avant) ═══
	-- Le sourire est composé de plusieurs parts pour faire la courbe

	-- Ligne centrale du sourire
	local smileCenter = mp(model, "SmileCenter", Vector3.new(2.5, 0.15, 0.2), blanc, Enum.Material.Neon)
	smileCenter.CFrame = head.CFrame * CFrame.new(0, -0.8, -1.85)
	weld(head, smileCenter)

	-- Courbe gauche du sourire (remonte vers l'œil)
	local smileCurveL1 = mp(model, "SmileCurveL1", Vector3.new(0.8, 0.15, 0.2), blanc, Enum.Material.Neon)
	smileCurveL1.CFrame = head.CFrame * CFrame.new(-1.5, -0.55, -1.8)
		* CFrame.Angles(0, 0, math.rad(-35))
	weld(head, smileCurveL1)

	local smileCurveL2 = mp(model, "SmileCurveL2", Vector3.new(0.5, 0.13, 0.18), blanc, Enum.Material.Neon)
	smileCurveL2.CFrame = head.CFrame * CFrame.new(-1.8, -0.25, -1.75)
		* CFrame.Angles(0, 0, math.rad(-55))
	weld(head, smileCurveL2)

	-- Courbe droite du sourire
	local smileCurveR1 = mp(model, "SmileCurveR1", Vector3.new(0.8, 0.15, 0.2), blanc, Enum.Material.Neon)
	smileCurveR1.CFrame = head.CFrame * CFrame.new(1.5, -0.55, -1.8)
		* CFrame.Angles(0, 0, math.rad(35))
	weld(head, smileCurveR1)

	local smileCurveR2 = mp(model, "SmileCurveR2", Vector3.new(0.5, 0.13, 0.18), blanc, Enum.Material.Neon)
	smileCurveR2.CFrame = head.CFrame * CFrame.new(1.8, -0.25, -1.75)
		* CFrame.Angles(0, 0, math.rad(55))
	weld(head, smileCurveR2)

	-- ═══ BOUCHE (mâchoire animable) ═══
	local mouth = mp(model, "Mouth", Vector3.new(2.8, 0.6, 1.2), Color3.fromRGB(50, 0, 0))
	mouth.CFrame = head.CFrame * CFrame.new(0, -1.2, -1.1)
	rig.Jaw = motor(head, mouth, "Jaw")

	-- Intérieur de la bouche
	local mouthInside = mp(model, "MouthInside", Vector3.new(2.4, 0.5, 1), Color3.fromRGB(20, 0, 0))
	mouthInside.CFrame = mouth.CFrame * CFrame.new(0, 0.05, 0.1)
	weld(mouth, mouthInside)

	-- Dents du haut (fixes sur la tête, pointues, blanc neon)
	for i = -4, 4 do
		local tSize = (math.abs(i) <= 1) and Vector3.new(0.28, 0.8, 0.22) or Vector3.new(0.22, 0.55, 0.18)
		local tooth = mp(model, "TU"..i, tSize, blanc, Enum.Material.Neon)
		tooth.CFrame = head.CFrame * CFrame.new(i * 0.3, -1.0, -1.65)
			* CFrame.Angles(math.rad(5), 0, 0)
		weld(head, tooth)
	end

	-- Dents du bas (sur la mâchoire, bougent avec, blanc neon)
	for i = -3, 3 do
		local tSize = (math.abs(i) <= 1) and Vector3.new(0.25, 0.65, 0.2) or Vector3.new(0.2, 0.45, 0.16)
		local tooth = mp(model, "TD"..i, tSize, blanc, Enum.Material.Neon)
		tooth.CFrame = mouth.CFrame * CFrame.new(i * 0.32, 0.3, -0.35)
			* CFrame.Angles(math.rad(-5), 0, 0)
		weld(mouth, tooth)
	end

	-- ═══ MOUSTACHES ═══
	for side = -1, 1, 2 do
		for j = 0, 2 do
			local whisker = mp(model, "Whisker"..side..j, Vector3.new(3, 0.06, 0.06), Color3.fromRGB(60,60,60))
			whisker.CFrame = nose.CFrame * CFrame.new(side * 2, -0.2 + j * 0.25, 0)
				* CFrame.Angles(0, 0, math.rad(side * (-5 + j * 5)))
			weld(nose, whisker)
		end
	end

	-- ═══ BRAS GAUCHE (3 segments + GANT MICKEY) ═══
	local armL1 = mp(model, "ArmL1", Vector3.new(1, 5, 1), noir)
	armL1.CFrame = root.CFrame * CFrame.new(-3, 2, 0)
	rig.ShoulderL = motor(body, armL1, "ShoulderL")

	local armL2 = mp(model, "ArmL2", Vector3.new(0.8, 5, 0.8), noir)
	armL2.CFrame = armL1.CFrame * CFrame.new(0, -5, 0)
	rig.ElbowL = motor(armL1, armL2, "ElbowL")

	local armL3 = mp(model, "ArmL3", Vector3.new(0.6, 4, 0.6), noir)
	armL3.CFrame = armL2.CFrame * CFrame.new(0, -4.5, 0)
	rig.ForearmL = motor(armL2, armL3, "ForearmL")

	-- Gant Mickey gauche (boule blanche + poignet)
	-- Poignet du gant
	local gloveWristL = mp(model, "GloveWristL", Vector3.new(1.4, 0.6, 1.4), gantBlanc)
	gloveWristL.CFrame = armL3.CFrame * CFrame.new(0, -2.2, 0)
	weld(armL3, gloveWristL)

	-- Main du gant (grosse sphère blanche)
	local handL = ms(model, "HandL", Vector3.new(2.2, 2.2, 2.2), gantBlanc)
	handL.CFrame = armL3.CFrame * CFrame.new(0, -3.5, 0)
	rig.WristL = motor(armL3, handL, "WristL")

	-- Pouce gauche
	local thumbL = ms(model, "ThumbL", Vector3.new(0.6, 0.8, 0.6), gantBlanc)
	thumbL.CFrame = handL.CFrame * CFrame.new(-1, 0.2, -0.3)
		* CFrame.Angles(0, 0, math.rad(-25))
	weld(handL, thumbL)

	-- Doigts gauche (3 gros doigts style cartoon)
	for i = -1, 1 do
		local finger = ms(model, "FingerL"..i, Vector3.new(0.5, 0.9, 0.5), gantBlanc)
		finger.CFrame = handL.CFrame * CFrame.new(i * 0.45, -1.1, -0.2)
		weld(handL, finger)
	end

	-- Lignes du gant (les 3 lignes noires sur le dessus)
	for i = -1, 1 do
		local line = mp(model, "GLineL"..i, Vector3.new(0.06, 0.06, 1.2), noir)
		line.CFrame = handL.CFrame * CFrame.new(i * 0.35, 0.3, -0.5)
		weld(handL, line)
	end

	-- ═══ BRAS DROIT (3 segments + GANT MICKEY) ═══
	local armR1 = mp(model, "ArmR1", Vector3.new(1, 5, 1), noir)
	armR1.CFrame = root.CFrame * CFrame.new(3, 2, 0)
	rig.ShoulderR = motor(body, armR1, "ShoulderR")

	local armR2 = mp(model, "ArmR2", Vector3.new(0.8, 5, 0.8), noir)
	armR2.CFrame = armR1.CFrame * CFrame.new(0, -5, 0)
	rig.ElbowR = motor(armR1, armR2, "ElbowR")

	local armR3 = mp(model, "ArmR3", Vector3.new(0.6, 4, 0.6), noir)
	armR3.CFrame = armR2.CFrame * CFrame.new(0, -4.5, 0)
	rig.ForearmR = motor(armR2, armR3, "ForearmR")

	-- Poignet du gant droit
	local gloveWristR = mp(model, "GloveWristR", Vector3.new(1.4, 0.6, 1.4), gantBlanc)
	gloveWristR.CFrame = armR3.CFrame * CFrame.new(0, -2.2, 0)
	weld(armR3, gloveWristR)

	-- Main du gant droit
	local handR = ms(model, "HandR", Vector3.new(2.2, 2.2, 2.2), gantBlanc)
	handR.CFrame = armR3.CFrame * CFrame.new(0, -3.5, 0)
	rig.WristR = motor(armR3, handR, "WristR")

	-- Pouce droit
	local thumbR = ms(model, "ThumbR", Vector3.new(0.6, 0.8, 0.6), gantBlanc)
	thumbR.CFrame = handR.CFrame * CFrame.new(1, 0.2, -0.3)
		* CFrame.Angles(0, 0, math.rad(25))
	weld(handR, thumbR)

	-- Doigts droit
	for i = -1, 1 do
		local finger = ms(model, "FingerR"..i, Vector3.new(0.5, 0.9, 0.5), gantBlanc)
		finger.CFrame = handR.CFrame * CFrame.new(i * 0.45, -1.1, -0.2)
		weld(handR, finger)
	end

	-- Lignes du gant droit
	for i = -1, 1 do
		local line = mp(model, "GLineR"..i, Vector3.new(0.06, 0.06, 1.2), noir)
		line.CFrame = handR.CFrame * CFrame.new(i * 0.35, 0.3, -0.5)
		weld(handR, line)
	end

	-- ═══ JAMBES ═══
	local legL = mp(model, "LegL", Vector3.new(1.2, 6, 1.2), noir)
	legL.CFrame = root.CFrame * CFrame.new(-1, -6.5, 0)
	rig.HipL = motor(body, legL, "HipL")

	-- Pied gauche (chaussure cartoon noire)
	local footL = mp(model, "FootL", Vector3.new(1.6, 0.8, 2.5), gris)
	footL.CFrame = legL.CFrame * CFrame.new(0, -3.4, 0.3)
	rig.AnkleL = motor(legL, footL, "AnkleL")

	-- Bout du pied arrondi
	local toeTipL = ms(model, "ToeTipL", Vector3.new(1.4, 0.8, 1), gris)
	toeTipL.CFrame = footL.CFrame * CFrame.new(0, 0, -1)
	weld(footL, toeTipL)

	local legR = mp(model, "LegR", Vector3.new(1.2, 6, 1.2), noir)
	legR.CFrame = root.CFrame * CFrame.new(1, -6.5, 0)
	rig.HipR = motor(body, legR, "HipR")

	local footR = mp(model, "FootR", Vector3.new(1.6, 0.8, 2.5), gris)
	footR.CFrame = legR.CFrame * CFrame.new(0, -3.4, 0.3)
	rig.AnkleR = motor(legR, footR, "AnkleR")

	local toeTipR = ms(model, "ToeTipR", Vector3.new(1.4, 0.8, 1), gris)
	toeTipR.CFrame = footR.CFrame * CFrame.new(0, 0, -1)
	weld(footR, toeTipR)

	-- ═══ QUEUE (longue et fine) ═══
	local tail = mp(model, "Tail", Vector3.new(0.4, 0.4, 4.5), noir)
	tail.CFrame = root.CFrame * CFrame.new(0, -1.5, 2.5)
		* CFrame.Angles(math.rad(-15), 0, 0)
	rig.Tail = motor(body, tail, "Tail")

	-- Bout de la queue (arrondi)
	local tailTip = ms(model, "TailTip", Vector3.new(0.6, 0.6, 0.6), noir)
	tailTip.CFrame = tail.CFrame * CFrame.new(0, 0, 2.5)
	weld(tail, tailTip)

	return model, FootOffsets.CartoonCat, rig
end
local function buildSirenHead()
	local model = Instance.new("Model"); model.Name = "SirenHead"
	local col = MC.SirenHead; local rig = {}

	-- Couleurs
	local bois = col.p -- brun principal (peau/bois)
	local boisF = Color3.fromRGB(70, 55, 40) -- brun foncé
	local boisC = Color3.fromRGB(120, 100, 75) -- brun clair
	local metal = Color3.fromRGB(80, 80, 90) -- métal sirènes
	local metalF = Color3.fromRGB(50, 50, 60) -- métal foncé
	local noir = Color3.fromRGB(10, 10, 10)
	local rouge = Color3.fromRGB(200, 0, 0)
	local rouille = Color3.fromRGB(140, 80, 40)

	-- ═══ ROOT ═══
	local root = mp(model, "HumanoidRootPart", Vector3.new(2.5,5,2), bois, Enum.Material.Concrete, 1)
	root.Anchored = true; model.PrimaryPart = root

	-- ═══ CORPS (torse décharné, côtes visibles) ═══
	local body = mp(model, "Body", Vector3.new(2.8, 5.5, 2), bois, Enum.Material.Concrete)
	body.CFrame = root.CFrame
	rig.Root = motor(root, body, "Root")

	-- Colonne vertébrale visible (dos)
	for i = 0, 6 do
		local vert = mp(model, "Vert"..i, Vector3.new(0.5, 0.4, 0.5), boisF, Enum.Material.Concrete)
		vert.CFrame = body.CFrame * CFrame.new(0, 2.5 - i*0.8, 1.1)
		weld(body, vert)
	end

	-- Côtes (les 2 côtés, forme arrondie)
	for i = 0, 5 do
		-- Côte gauche
		local ribL = mp(model, "RibL"..i, Vector3.new(0.18, 0.18, 1.8), boisC, Enum.Material.Concrete)
		ribL.CFrame = body.CFrame * CFrame.new(-1.3, 2.2 - i*0.8, 0.3)
			* CFrame.Angles(0, math.rad(-20), math.rad(-35))
		weld(body, ribL)

		-- Côte droite
		local ribR = mp(model, "RibR"..i, Vector3.new(0.18, 0.18, 1.8), boisC, Enum.Material.Concrete)
		ribR.CFrame = body.CFrame * CFrame.new(1.3, 2.2 - i*0.8, 0.3)
			* CFrame.Angles(0, math.rad(20), math.rad(35))
		weld(body, ribR)
	end

	-- Trous / fissures dans le torse
	local crack1 = mp(model, "Crack1", Vector3.new(0.15, 2, 0.15), noir, Enum.Material.Concrete)
	crack1.CFrame = body.CFrame * CFrame.new(-0.8, 0, -0.95)
		* CFrame.Angles(0, 0, math.rad(8))
	weld(body, crack1)

	local crack2 = mp(model, "Crack2", Vector3.new(0.12, 1.5, 0.12), noir, Enum.Material.Concrete)
	crack2.CFrame = body.CFrame * CFrame.new(0.5, -1, -0.9)
		* CFrame.Angles(0, 0, math.rad(-12))
	weld(body, crack2)

	-- ═══ COU (3 segments, texture bois/organique) ═══
	-- Segment 1 (base du cou)
	local neck1 = mp(model, "Neck1", Vector3.new(1.2, 4.5, 1.2), bois, Enum.Material.Concrete)
	neck1.CFrame = root.CFrame * CFrame.new(0, 5.2, 0)
	rig.Neck1 = motor(body, neck1, "Neck1")

	-- Fils/câbles sur le cou 1
	local wire1a = mp(model, "Wire1a", Vector3.new(0.1, 4.5, 0.1), noir)
	wire1a.CFrame = neck1.CFrame * CFrame.new(-0.5, 0, 0.3)
		* CFrame.Angles(0, 0, math.rad(5))
	weld(neck1, wire1a)
	local wire1b = mp(model, "Wire1b", Vector3.new(0.08, 4, 0.08), rouille)
	wire1b.CFrame = neck1.CFrame * CFrame.new(0.4, 0.2, -0.4)
		* CFrame.Angles(0, 0, math.rad(-3))
	weld(neck1, wire1b)

	-- Segment 2 (milieu)
	local neck2 = mp(model, "Neck2", Vector3.new(0.9, 4.5, 0.9), boisF, Enum.Material.Concrete)
	neck2.CFrame = neck1.CFrame * CFrame.new(0, 4.5, 0)
	rig.Neck2 = motor(neck1, neck2, "Neck2")

	-- Fils sur cou 2
	local wire2a = mp(model, "Wire2a", Vector3.new(0.08, 4, 0.08), noir)
	wire2a.CFrame = neck2.CFrame * CFrame.new(-0.35, 0, 0.2)
	weld(neck2, wire2a)
	local wire2b = mp(model, "Wire2b", Vector3.new(0.12, 3.5, 0.12), rouille)
	wire2b.CFrame = neck2.CFrame * CFrame.new(0.3, -0.5, -0.25)
		* CFrame.Angles(math.rad(4), 0, math.rad(6))
	weld(neck2, wire2b)

	-- Segment 3 (haut, se sépare en fourche)
	local neck3 = mp(model, "Neck3", Vector3.new(0.8, 4, 0.8), boisC, Enum.Material.Concrete)
	neck3.CFrame = neck2.CFrame * CFrame.new(0, 4.5, 0)
	rig.Neck3 = motor(neck2, neck3, "Neck3")

	-- Fils pendants depuis le haut du cou
	local wire3a = mp(model, "Wire3a", Vector3.new(0.06, 3, 0.06), noir)
	wire3a.CFrame = neck3.CFrame * CFrame.new(-0.3, -0.5, 0.15)
		* CFrame.Angles(math.rad(10), 0, math.rad(-8))
	weld(neck3, wire3a)

	-- ═══ FOURCHE (le cou se sépare en V vers l'extérieur) ═══
	-- Le V doit s'ouvrir vers le HAUT et vers l'EXTÉRIEUR
	
	-- Branche gauche (part vers la gauche ET vers le haut)
	local forkL = mp(model, "ForkL", Vector3.new(0.6, 3.5, 0.6), bois, Enum.Material.Concrete)
	forkL.CFrame = neck3.CFrame * CFrame.new(-0.4, 2, 0)
		* CFrame.Angles(0, 0, math.rad(30)) -- penche vers la GAUCHE
	rig.ForkL = motor(neck3, forkL, "ForkL")

	-- Branche droite (part vers la droite ET vers le haut)
	local forkR = mp(model, "ForkR", Vector3.new(0.6, 3.5, 0.6), bois, Enum.Material.Concrete)
	forkR.CFrame = neck3.CFrame * CFrame.new(0.4, 2, 0)
		* CFrame.Angles(0, 0, math.rad(-30)) -- penche vers la DROITE
	rig.ForkR = motor(neck3, forkR, "ForkR")

	-- ═══ SIRÈNE GAUCHE (TÊTE 1) — Bien séparée et détaillée ═══
	-- Corps de la sirène
-- ═══ SIRÈNE GAUCHE — positionnée au bout de la branche gauche ═══
	local sirenBodyL = mp(model, "Head", Vector3.new(2.8, 2.8, 4), metal, Enum.Material.Metal)
	sirenBodyL.CFrame = forkL.CFrame * CFrame.new(-1, 2.5, 0)
		* CFrame.Angles(0, 0, math.rad(30)) -- remet droit pour que la sirène soit horizontale
	rig.SirenL = motor(forkL, sirenBodyL, "SirenL")


	-- Pavillon (la partie évasée, face avant)
	local hornL = mp(model, "HornL", Vector3.new(3.2, 3.2, 1.2), metalF, Enum.Material.Metal)
	hornL.CFrame = sirenBodyL.CFrame * CFrame.new(0, 0, -2.2)
	weld(sirenBodyL, hornL)

	-- Bord du pavillon (anneau)
	local rimL = mp(model, "RimL", Vector3.new(3.6, 3.6, 0.3), metal, Enum.Material.Metal)
	rimL.CFrame = hornL.CFrame * CFrame.new(0, 0, -0.6)
	weld(hornL, rimL)

	-- Intérieur noir du pavillon
	local insideL = mp(model, "InsideL", Vector3.new(2.6, 2.6, 0.4), noir)
	insideL.CFrame = hornL.CFrame * CFrame.new(0, 0, -0.3)
	weld(hornL, insideL)

	-- Grille de la sirène (barres horizontales)
	for i = -2, 2 do
		local bar = mp(model, "BarL"..i, Vector3.new(2.4, 0.12, 0.15), metalF, Enum.Material.Metal)
		bar.CFrame = insideL.CFrame * CFrame.new(0, i * 0.5, -0.15)
		weld(insideL, bar)
	end

	-- Arrière de la sirène (boîtier)
	local backL = mp(model, "BackL", Vector3.new(2.2, 2.2, 1), metalF, Enum.Material.Metal)
	backL.CFrame = sirenBodyL.CFrame * CFrame.new(0, 0, 2)
	weld(sirenBodyL, backL)

	-- Support/fixation sur la fourche
	local mountL = mp(model, "MountL", Vector3.new(0.8, 0.8, 1.5), rouille, Enum.Material.Metal)
	mountL.CFrame = sirenBodyL.CFrame * CFrame.new(0, -1.2, 0)
		* CFrame.Angles(0, 0, math.rad(25))
	weld(sirenBodyL, mountL)

	-- Lumière rouge clignotante
	local lightL = ms(model, "LightL", Vector3.new(0.6, 0.6, 0.6), rouge, Enum.Material.Neon)
	lightL.CFrame = sirenBodyL.CFrame * CFrame.new(0, 1.6, 0)
	weld(sirenBodyL, lightL)

	-- Fils pendants de la sirène gauche
	local wireSL1 = mp(model, "WireSL1", Vector3.new(0.06, 2.5, 0.06), noir)
	wireSL1.CFrame = sirenBodyL.CFrame * CFrame.new(-1, -0.5, 0.5)
		* CFrame.Angles(math.rad(15), 0, math.rad(-10))
	weld(sirenBodyL, wireSL1)
	local wireSL2 = mp(model, "WireSL2", Vector3.new(0.08, 1.8, 0.08), rouille)
	wireSL2.CFrame = sirenBodyL.CFrame * CFrame.new(0.8, -0.8, -0.5)
		* CFrame.Angles(math.rad(20), 0, math.rad(5))
	weld(sirenBodyL, wireSL2)

	-- ═══ SIRÈNE DROITE — positionnée au bout de la branche droite ═══
	local sirenBodyR = mp(model, "SirenR", Vector3.new(2.8, 2.8, 4), metal, Enum.Material.Metal)
	sirenBodyR.CFrame = forkR.CFrame * CFrame.new(1, 2.5, 0)
		* CFrame.Angles(0, 0, math.rad(-30)) -- remet droit
	rig.SirenR = motor(forkR, sirenBodyR, "SirenR")
    
	-- Pavillon droit
	local hornR = mp(model, "HornR", Vector3.new(3.2, 3.2, 1.2), metalF, Enum.Material.Metal)
	hornR.CFrame = sirenBodyR.CFrame * CFrame.new(0, 0, -2.2)
	weld(sirenBodyR, hornR)

	-- Bord du pavillon
	local rimR = mp(model, "RimR", Vector3.new(3.6, 3.6, 0.3), metal, Enum.Material.Metal)
	rimR.CFrame = hornR.CFrame * CFrame.new(0, 0, -0.6)
	weld(hornR, rimR)

	-- Intérieur noir
	local insideR = mp(model, "InsideR", Vector3.new(2.6, 2.6, 0.4), noir)
	insideR.CFrame = hornR.CFrame * CFrame.new(0, 0, -0.3)
	weld(hornR, insideR)

	-- Grille
	for i = -2, 2 do
		local bar = mp(model, "BarR"..i, Vector3.new(2.4, 0.12, 0.15), metalF, Enum.Material.Metal)
		bar.CFrame = insideR.CFrame * CFrame.new(0, i * 0.5, -0.15)
		weld(insideR, bar)
	end

	-- Arrière
	local backR = mp(model, "BackR", Vector3.new(2.2, 2.2, 1), metalF, Enum.Material.Metal)
	backR.CFrame = sirenBodyR.CFrame * CFrame.new(0, 0, 2)
	weld(sirenBodyR, backR)

	-- Support
	local mountR = mp(model, "MountR", Vector3.new(0.8, 0.8, 1.5), rouille, Enum.Material.Metal)
	mountR.CFrame = sirenBodyR.CFrame * CFrame.new(0, -1.2, 0)
		* CFrame.Angles(0, 0, math.rad(-25))
	weld(sirenBodyR, mountR)

	-- Lumière rouge
	local lightR = ms(model, "LightR", Vector3.new(0.6, 0.6, 0.6), rouge, Enum.Material.Neon)
	lightR.CFrame = sirenBodyR.CFrame * CFrame.new(0, 1.6, 0)
	weld(sirenBodyR, lightR)

	-- Fils pendants sirène droite
	local wireSR1 = mp(model, "WireSR1", Vector3.new(0.06, 2.2, 0.06), noir)
	wireSR1.CFrame = sirenBodyR.CFrame * CFrame.new(1, -0.5, 0.5)
		* CFrame.Angles(math.rad(12), 0, math.rad(8))
	weld(sirenBodyR, wireSR1)
	local wireSR2 = mp(model, "WireSR2", Vector3.new(0.08, 2, 0.08), rouille)
	wireSR2.CFrame = sirenBodyR.CFrame * CFrame.new(-0.7, -0.7, -0.4)
		* CFrame.Angles(math.rad(18), 0, math.rad(-6))
	weld(sirenBodyR, wireSR2)

	-- ═══ BRAS (longs, décharnés, en bois/organique) ═══
	-- Bras gauche
	local armL = mp(model, "ArmL", Vector3.new(0.9, 7, 0.9), bois, Enum.Material.Concrete)
	armL.CFrame = root.CFrame * CFrame.new(-2.5, 0, 0)
	rig.ShoulderL = motor(body, armL, "ShoulderL")

	-- Texture bras gauche
	local armTexL1 = mp(model, "ArmTexL1", Vector3.new(0.12, 3, 0.12), boisF, Enum.Material.Concrete)
	armTexL1.CFrame = armL.CFrame * CFrame.new(-0.35, 1, 0.2)
		* CFrame.Angles(0, 0, math.rad(3))
	weld(armL, armTexL1)
	local armTexL2 = mp(model, "ArmTexL2", Vector3.new(0.1, 2, 0.1), boisC, Enum.Material.Concrete)
	armTexL2.CFrame = armL.CFrame * CFrame.new(0.3, -1.5, -0.2)
	weld(armL, armTexL2)

	-- Avant-bras gauche
	local forearmL = mp(model, "ForearmL", Vector3.new(0.7, 6, 0.7), boisF, Enum.Material.Concrete)
	forearmL.CFrame = armL.CFrame * CFrame.new(0, -6.5, 0)
	rig.ElbowL = motor(armL, forearmL, "ElbowL")

	-- Main gauche (griffes squelettiques)
	local handL = mp(model, "HandL", Vector3.new(0.9, 0.5, 1), boisC, Enum.Material.Concrete)
	handL.CFrame = forearmL.CFrame * CFrame.new(0, -3.5, 0)
	rig.WristL = motor(forearmL, handL, "WristL")

	for i = -1, 1 do
		local claw = mp(model, "ClawL"..i, Vector3.new(0.1, 1.5, 0.1), boisF, Enum.Material.Concrete)
		claw.CFrame = handL.CFrame * CFrame.new(i * 0.3, -1, -0.2)
			* CFrame.Angles(math.rad(15), 0, math.rad(i * 8))
		weld(handL, claw)
	end

	-- Bras droit
	local armR = mp(model, "ArmR", Vector3.new(0.9, 7, 0.9), bois, Enum.Material.Concrete)
	armR.CFrame = root.CFrame * CFrame.new(2.5, 0, 0)
	rig.ShoulderR = motor(body, armR, "ShoulderR")

	-- Texture bras droit
	local armTexR1 = mp(model, "ArmTexR1", Vector3.new(0.12, 3, 0.12), boisF, Enum.Material.Concrete)
	armTexR1.CFrame = armR.CFrame * CFrame.new(0.35, 1, 0.2)
		* CFrame.Angles(0, 0, math.rad(-3))
	weld(armR, armTexR1)
	local armTexR2 = mp(model, "ArmTexR2", Vector3.new(0.1, 2, 0.1), boisC, Enum.Material.Concrete)
	armTexR2.CFrame = armR.CFrame * CFrame.new(-0.3, -1.5, -0.2)
	weld(armR, armTexR2)

	-- Avant-bras droit
	local forearmR = mp(model, "ForearmR", Vector3.new(0.7, 6, 0.7), boisF, Enum.Material.Concrete)
	forearmR.CFrame = armR.CFrame * CFrame.new(0, -6.5, 0)
	rig.ElbowR = motor(armR, forearmR, "ElbowR")

	-- Main droite
	local handR = mp(model, "HandR", Vector3.new(0.9, 0.5, 1), boisC, Enum.Material.Concrete)
	handR.CFrame = forearmR.CFrame * CFrame.new(0, -3.5, 0)
	rig.WristR = motor(forearmR, handR, "WristR")

	for i = -1, 1 do
		local claw = mp(model, "ClawR"..i, Vector3.new(0.1, 1.5, 0.1), boisF, Enum.Material.Concrete)
		claw.CFrame = handR.CFrame * CFrame.new(i * 0.3, -1, -0.2)
			* CFrame.Angles(math.rad(15), 0, math.rad(i * 8))
		weld(handR, claw)
	end

	-- ═══ JAMBES (longues et fines, style poteau) ═══
	-- Jambe gauche
	local legL = mp(model, "LegL", Vector3.new(1.3, 7, 1.3), bois, Enum.Material.Concrete)
	legL.CFrame = root.CFrame * CFrame.new(-0.9, -6.5, 0)
	rig.HipL = motor(body, legL, "HipL")

	-- Texture jambe gauche
	local legTexL = mp(model, "LegTexL", Vector3.new(0.1, 4, 0.1), boisF, Enum.Material.Concrete)
	legTexL.CFrame = legL.CFrame * CFrame.new(-0.5, 0, 0.3)
		* CFrame.Angles(0, 0, math.rad(2))
	weld(legL, legTexL)

	-- Genou gauche (renflement)
	local kneeL = ms(model, "KneeL", Vector3.new(1.1, 1.1, 1.1), boisC, Enum.Material.Concrete)
	kneeL.CFrame = legL.CFrame * CFrame.new(0, -0.5, -0.3)
	weld(legL, kneeL)

	-- Pied gauche (base large)
	local footL = mp(model, "FootL", Vector3.new(1.5, 0.8, 2.2), boisF, Enum.Material.Concrete)
	footL.CFrame = legL.CFrame * CFrame.new(0, -3.8, 0.3)
	rig.AnkleL = motor(legL, footL, "AnkleL")

	-- Jambe droite
	local legR = mp(model, "LegR", Vector3.new(1.3, 7, 1.3), bois, Enum.Material.Concrete)
	legR.CFrame = root.CFrame * CFrame.new(0.9, -6.5, 0)
	rig.HipR = motor(body, legR, "HipR")

	-- Texture jambe droite
	local legTexR = mp(model, "LegTexR", Vector3.new(0.1, 4, 0.1), boisF, Enum.Material.Concrete)
	legTexR.CFrame = legR.CFrame * CFrame.new(0.5, 0, 0.3)
		* CFrame.Angles(0, 0, math.rad(-2))
	weld(legR, legTexR)

	-- Genou droit
	local kneeR = ms(model, "KneeR", Vector3.new(1.1, 1.1, 1.1), boisC, Enum.Material.Concrete)
	kneeR.CFrame = legR.CFrame * CFrame.new(0, -0.5, -0.3)
	weld(legR, kneeR)

	-- Pied droit
	local footR = mp(model, "FootR", Vector3.new(1.5, 0.8, 2.2), boisF, Enum.Material.Concrete)
	footR.CFrame = legR.CFrame * CFrame.new(0, -3.8, 0.3)
	rig.AnkleR = motor(legR, footR, "AnkleR")

	-- ═══ FILS PENDANTS SUPPLÉMENTAIRES (entre les jambes et le corps) ═══
	local hangWire1 = mp(model, "HangWire1", Vector3.new(0.06, 4, 0.06), noir)
	hangWire1.CFrame = body.CFrame * CFrame.new(-1.2, -1, 0.5)
		* CFrame.Angles(math.rad(25), math.rad(10), math.rad(-8))
	weld(body, hangWire1)

	local hangWire2 = mp(model, "HangWire2", Vector3.new(0.08, 3.5, 0.08), rouille)
	hangWire2.CFrame = body.CFrame * CFrame.new(0.8, -0.5, -0.6)
		* CFrame.Angles(math.rad(20), math.rad(-5), math.rad(6))
	weld(body, hangWire2)

	local hangWire3 = mp(model, "HangWire3", Vector3.new(0.05, 5, 0.05), noir)
	hangWire3.CFrame = neck1.CFrame * CFrame.new(0.6, 0, 0.5)
		* CFrame.Angles(math.rad(8), 0, math.rad(4))
	weld(neck1, hangWire3)

	-- ═══ DÉTAILS DE ROUILLE / USURE ═══
	-- Taches de rouille sur les sirènes
	local rustL1 = mp(model, "RustL1", Vector3.new(0.8, 0.5, 0.15), rouille, Enum.Material.Concrete)
	rustL1.CFrame = sirenBodyL.CFrame * CFrame.new(-0.8, 0.5, -1.8)
	weld(sirenBodyL, rustL1)

	local rustR1 = mp(model, "RustR1", Vector3.new(0.6, 0.7, 0.15), rouille, Enum.Material.Concrete)
	rustR1.CFrame = sirenBodyR.CFrame * CFrame.new(0.6, -0.3, -1.8)
	weld(sirenBodyR, rustR1)

	-- Taches sur le corps
	local rustBody1 = mp(model, "RustBody1", Vector3.new(0.8, 1.2, 0.15), boisF, Enum.Material.Concrete)
	rustBody1.CFrame = body.CFrame * CFrame.new(0.9, 1, -1)
	weld(body, rustBody1)

	local rustBody2 = mp(model, "RustBody2", Vector3.new(1, 0.8, 0.15), boisC, Enum.Material.Concrete)
	rustBody2.CFrame = body.CFrame * CFrame.new(-0.7, -1.5, -0.95)
	weld(body, rustBody2)

	return model, FootOffsets.SirenHead, rig
end

local function buildWendigo()
	local model = Instance.new("Model"); model.Name = "Wendigo"
	local col = MC.Wendigo; local rig = {}

	local root = mp(model,"HumanoidRootPart",Vector3.new(2.5,5,1.8),col.p,Enum.Material.Concrete,1)
	root.Anchored = true; model.PrimaryPart = root

	local body = mp(model,"Body",Vector3.new(2.5,5,1.8),col.p,Enum.Material.Concrete)
	body.CFrame = root.CFrame
	rig.Root = motor(root, body, "Root")

	local skull = mp(model,"Head",Vector3.new(2.5,3,3),col.s,Enum.Material.Concrete)
	skull.CFrame = root.CFrame*CFrame.new(0,4.5,0)
	rig.Neck = motor(body, skull, "Neck")

	-- Snout, yeux, bois, dents (fixes)
	local snout = mp(model,"Snout",Vector3.new(1.2,1.2,2.5),col.s,Enum.Material.Concrete)
	snout.CFrame = skull.CFrame*CFrame.new(0,-0.5,-2.2); weld(skull,snout)

	local eyeL = ms(model,"EyeL",Vector3.new(0.6,0.8,0.4),col.a,Enum.Material.Neon)
	eyeL.CFrame = skull.CFrame*CFrame.new(-0.6,0.3,-1.2); weld(skull,eyeL)
	local eyeR = ms(model,"EyeR",Vector3.new(0.6,0.8,0.4),col.a,Enum.Material.Neon)
	eyeR.CFrame = skull.CFrame*CFrame.new(0.6,0.3,-1.2); weld(skull,eyeR)

	local antL = mp(model,"AntlerL",Vector3.new(0.3,3,0.3),C.bone,Enum.Material.Concrete)
	antL.CFrame = skull.CFrame*CFrame.new(-0.8,2.5,0)*CFrame.Angles(0,0,math.rad(-20)); weld(skull,antL)
	local antR = mp(model,"AntlerR",Vector3.new(0.3,3,0.3),C.bone,Enum.Material.Concrete)
	antR.CFrame = skull.CFrame*CFrame.new(0.8,2.5,0)*CFrame.Angles(0,0,math.rad(20)); weld(skull,antR)

	-- Mâchoire (animable)
	local jaw = mp(model,"Jaw",Vector3.new(1.3,0.5,2),col.p,Enum.Material.Concrete)
	jaw.CFrame = snout.CFrame*CFrame.new(0,-0.7,0)
	rig.Jaw = motor(snout, jaw, "Jaw")

	for i=-2,2 do
		local f = mp(model,"F"..i,Vector3.new(0.15,0.6,0.15),C.bone)
		f.CFrame = snout.CFrame*CFrame.new(i*0.25,-0.8,-0.8); weld(snout,f)
	end

	-- Côtes (fixes)
	for i=0,5 do
		local rl = mp(model,"RL"..i,Vector3.new(0.15,0.15,1.5),C.bone,Enum.Material.Concrete)
		rl.CFrame = body.CFrame*CFrame.new(-1.2,2-i*0.7,0)*CFrame.Angles(0,0,math.rad(-30)); weld(body,rl)
		local rr = mp(model,"RR"..i,Vector3.new(0.15,0.15,1.5),C.bone,Enum.Material.Concrete)
		rr.CFrame = body.CFrame*CFrame.new(1.2,2-i*0.7,0)*CFrame.Angles(0,0,math.rad(30)); weld(body,rr)
	end

	-- Bras
	local armL = mp(model,"ArmL",Vector3.new(0.6,5,0.6),col.p,Enum.Material.Concrete)
	armL.CFrame = root.CFrame*CFrame.new(-2.2,0.5,0)
	rig.ShoulderL = motor(body, armL, "ShoulderL")

	local clawL = mp(model,"ClawL",Vector3.new(1.2,0.6,1.5),col.p,Enum.Material.Concrete)
	clawL.CFrame = armL.CFrame*CFrame.new(0,-3,0)
	rig.WristL = motor(armL, clawL, "WristL")

	for i=-1,1 do
		local c = mp(model,"WCL"..i,Vector3.new(0.1,1.5,0.1),C.bone)
		c.CFrame = clawL.CFrame*CFrame.new(i*0.35,-1,-0.3); weld(clawL,c)
	end

	local armR = mp(model,"ArmR",Vector3.new(0.6,5,0.6),col.p,Enum.Material.Concrete)
	armR.CFrame = root.CFrame*CFrame.new(2.2,0.5,0)
	rig.ShoulderR = motor(body, armR, "ShoulderR")

	local clawR = mp(model,"ClawR",Vector3.new(1.2,0.6,1.5),col.p,Enum.Material.Concrete)
	clawR.CFrame = armR.CFrame*CFrame.new(0,-3,0)
	rig.WristR = motor(armR, clawR, "WristR")

	for i=-1,1 do
		local c = mp(model,"WCR"..i,Vector3.new(0.1,1.5,0.1),C.bone)
		c.CFrame = clawR.CFrame*CFrame.new(i*0.35,-1,-0.3); weld(clawR,c)
	end

	-- Jambes
	local legL = mp(model,"LegL",Vector3.new(0.9,5.5,0.9),col.p,Enum.Material.Concrete)
	legL.CFrame = root.CFrame*CFrame.new(-0.9,-5.5,0)
	rig.HipL = motor(body, legL, "HipL")

	local hoofL = mp(model,"HoofL",Vector3.new(1.1,0.6,1.8),Color3.fromRGB(20,20,20),Enum.Material.Concrete)
	hoofL.CFrame = legL.CFrame*CFrame.new(0,-3,0.3)
	rig.AnkleL = motor(legL, hoofL, "AnkleL")

	local legR = mp(model,"LegR",Vector3.new(0.9,5.5,0.9),col.p,Enum.Material.Concrete)
	legR.CFrame = root.CFrame*CFrame.new(0.9,-5.5,0)
	rig.HipR = motor(body, legR, "HipR")

	local hoofR = mp(model,"HoofR",Vector3.new(1.1,0.6,1.8),Color3.fromRGB(20,20,20),Enum.Material.Concrete)
	hoofR.CFrame = legR.CFrame*CFrame.new(0,-3,0.3)
	rig.AnkleR = motor(legR, hoofR, "AnkleR")

	return model, FootOffsets.Wendigo, rig
end

local function buildSkinWalker()
	local model = Instance.new("Model"); model.Name = "SkinWalker"
	local col = MC.SkinWalker; local rig = {}

	local root = mp(model,"HumanoidRootPart",Vector3.new(3,4.5,2),col.p,nil,1)
	root.Anchored = true; model.PrimaryPart = root

	local body = mp(model,"Body",Vector3.new(3,4.5,2),col.p)
	body.CFrame = root.CFrame
	rig.Root = motor(root, body, "Root")

	local head = mp(model,"Head",Vector3.new(2.8,3,2.8),col.p)
	head.CFrame = root.CFrame*CFrame.new(0,4.2,0)
	rig.Neck = motor(body, head, "Neck")

	-- Visage (fixe)
	local face = mp(model,"Face",Vector3.new(2.5,2.5,0.4),Color3.fromRGB(200,160,130))
	face.CFrame = head.CFrame*CFrame.new(0,0,-1.4); weld(head,face)
	local eyeL = ms(model,"EyeL",Vector3.new(0.6,0.8,0.4),Color3.fromRGB(255,255,200),Enum.Material.Neon)
	eyeL.CFrame = head.CFrame*CFrame.new(-0.6,0.4,-1.5); weld(head,eyeL)
	local eyeR = ms(model,"EyeR",Vector3.new(0.4,0.6,0.35),Color3.fromRGB(255,255,200),Enum.Material.Neon)
	eyeR.CFrame = head.CFrame*CFrame.new(0.7,0.1,-1.5); weld(head,eyeR)

	-- Peau pendante (animable)
	local sf1 = mp(model,"SkinFlap1",Vector3.new(1.5,2,0.15),Color3.fromRGB(190,150,120))
	sf1.CFrame = body.CFrame*CFrame.new(1.6,0.5,0)*CFrame.Angles(0,0,math.rad(30))
	rig.Flap1 = motor(body, sf1, "Flap1")

	-- Chair (fixe)
	local flesh = mp(model,"Flesh",Vector3.new(0.8,1.8,0.3),Color3.fromRGB(180,60,60))
	flesh.CFrame = body.CFrame*CFrame.new(-1.3,0.3,0); weld(body,flesh)

	-- Bras
	local armL1 = mp(model,"ArmL1",Vector3.new(1.1,3.5,1.1),col.p)
	armL1.CFrame = root.CFrame*CFrame.new(-2.5,0.8,0)*CFrame.Angles(0,0,math.rad(-15))
	rig.ShoulderL = motor(body, armL1, "ShoulderL")

	local armL2 = mp(model,"ArmL2",Vector3.new(0.9,3.5,0.9),col.s)
	armL2.CFrame = armL1.CFrame*CFrame.new(-0.3,-3.5,0)
	rig.ElbowL = motor(armL1, armL2, "ElbowL")

	local handL = ms(model,"HandL",Vector3.new(1.3,1.3,1.3),col.p)
	handL.CFrame = armL2.CFrame*CFrame.new(0,-2.5,0)
	rig.WristL = motor(armL2, handL, "WristL")

	for i=0,4 do
		local f = mp(model,"FL"..i,Vector3.new(0.12,1.8,0.12),Color3.fromRGB(160,120,90))
		f.CFrame = handL.CFrame*CFrame.new(-0.3+i*0.15,-1.2,-0.2); weld(handL,f)
	end

	local armR1 = mp(model,"ArmR1",Vector3.new(1.1,3.5,1.1),col.p)
	armR1.CFrame = root.CFrame*CFrame.new(2.5,0.8,0)*CFrame.Angles(0,0,math.rad(15))
	rig.ShoulderR = motor(body, armR1, "ShoulderR")

	local armR2 = mp(model,"ArmR2",Vector3.new(0.9,3.5,0.9),col.s)
	armR2.CFrame = armR1.CFrame*CFrame.new(0.3,-3.5,0)
	rig.ElbowR = motor(armR1, armR2, "ElbowR")

	local handR = ms(model,"HandR",Vector3.new(1.3,1.3,1.3),col.p)
	handR.CFrame = armR2.CFrame*CFrame.new(0,-2.5,0)
	rig.WristR = motor(armR2, handR, "WristR")

	for i=0,4 do
		local f = mp(model,"FR"..i,Vector3.new(0.12,1.8,0.12),Color3.fromRGB(160,120,90))
		f.CFrame = handR.CFrame*CFrame.new(-0.3+i*0.15,-1.2,-0.2); weld(handR,f)
	end

	-- Jambes
	local legL = mp(model,"LegL",Vector3.new(1.2,5,1.2),col.p)
	legL.CFrame = root.CFrame*CFrame.new(-0.9,-5,0)
	rig.HipL = motor(body, legL, "HipL")

	local footL = mp(model,"FootL",Vector3.new(1.3,0.5,2.2),col.p)
	footL.CFrame = legL.CFrame*CFrame.new(0,-2.8,0.3)
	rig.AnkleL = motor(legL, footL, "AnkleL")

	local legR = mp(model,"LegR",Vector3.new(1.2,5,1.2),col.s)
	legR.CFrame = root.CFrame*CFrame.new(0.9,-5,0)
	rig.HipR = motor(body, legR, "HipR")

	local footR = mp(model,"FootR",Vector3.new(1.3,0.5,2.2),col.s)
	footR.CFrame = legR.CFrame*CFrame.new(0,-2.8,0.3)
	rig.AnkleR = motor(legR, footR, "AnkleR")

	return model, FootOffsets.SkinWalker, rig
end

local function buildTheRake()
	local model = Instance.new("Model"); model.Name = "TheRake"
	local col = MC.TheRake; local rig = {}

	local root = mp(model,"HumanoidRootPart",Vector3.new(2.5,3,4),col.p,nil,1)
	root.Anchored = true; model.PrimaryPart = root

	local body = mp(model,"Body",Vector3.new(2.5,3,4),col.p)
	body.CFrame = root.CFrame
	rig.Root = motor(root, body, "Root")

	local head = mp(model,"Head",Vector3.new(2.2,2.5,2.8),col.p)
	head.CFrame = root.CFrame*CFrame.new(0,0,-3.5)*CFrame.Angles(math.rad(-20),0,0)
	rig.Neck = motor(body, head, "Neck")

	-- Yeux (fixes)
	local eyeL = ms(model,"EyeL",Vector3.new(0.7,0.9,0.5),Color3.new(1,1,1),Enum.Material.Neon)
	eyeL.CFrame = head.CFrame*CFrame.new(-0.5,0.3,-1.2); weld(head,eyeL)
	local eyeR = ms(model,"EyeR",Vector3.new(0.7,0.9,0.5),Color3.new(1,1,1),Enum.Material.Neon)
	eyeR.CFrame = head.CFrame*CFrame.new(0.5,0.3,-1.2); weld(head,eyeR)

	-- Bouche (animable)
	local mouth = mp(model,"Mouth",Vector3.new(1.8,1.2,0.5),Color3.fromRGB(30,0,0))
	mouth.CFrame = head.CFrame*CFrame.new(0,-0.8,-1.3)
	rig.Jaw = motor(head, mouth, "Jaw")

	for i=-3,3 do
		local t1 = mp(model,"RT"..i,Vector3.new(0.12,1,0.12),Color3.fromRGB(220,215,205))
		t1.CFrame = mouth.CFrame*CFrame.new(i*0.25,0.5,-0.2); weld(mouth,t1)
		local t2 = mp(model,"RTB"..i,Vector3.new(0.12,0.8,0.12),Color3.fromRGB(220,215,205))
		t2.CFrame = mouth.CFrame*CFrame.new(i*0.25,-0.5,-0.2); weld(mouth,t2)
	end

	-- Vertèbres (fixes)
	for i=0,6 do
		local v = mp(model,"V"..i,Vector3.new(0.6,0.4,0.6),col.s)
		v.CFrame = body.CFrame*CFrame.new(0,1.5,-2.8+i*0.9); weld(body,v)
	end

	-- 4 pattes (Motor6D)
	local fl1 = mp(model,"FL1",Vector3.new(0.7,3.5,0.7),col.p)
	fl1.CFrame = root.CFrame*CFrame.new(-1.8,-0.5,-2)*CFrame.Angles(0,0,math.rad(-10))
	rig.FrontShoulderL = motor(body, fl1, "FrontShoulderL")

	local fl2 = mp(model,"FL2",Vector3.new(0.5,3,0.5),col.s)
	fl2.CFrame = fl1.CFrame*CFrame.new(0,-3.2,0.3)*CFrame.Angles(math.rad(15),0,0)
	rig.FrontElbowL = motor(fl1, fl2, "FrontElbowL")

	for i=-1,1 do
		local c = mp(model,"FLC"..i,Vector3.new(0.12,1.5,0.12),col.a)
		c.CFrame = fl2.CFrame*CFrame.new(i*0.2,-2,-0.4); weld(fl2,c)
	end

	local fr1 = mp(model,"FR1",Vector3.new(0.7,3.5,0.7),col.p)
	fr1.CFrame = root.CFrame*CFrame.new(1.8,-0.5,-2)*CFrame.Angles(0,0,math.rad(10))
	rig.FrontShoulderR = motor(body, fr1, "FrontShoulderR")

	local fr2 = mp(model,"FR2",Vector3.new(0.5,3,0.5),col.s)
	fr2.CFrame = fr1.CFrame*CFrame.new(0,-3.2,0.3)*CFrame.Angles(math.rad(15),0,0)
	rig.FrontElbowR = motor(fr1, fr2, "FrontElbowR")

	for i=-1,1 do
		local c = mp(model,"FRC"..i,Vector3.new(0.12,1.5,0.12),col.a)
		c.CFrame = fr2.CFrame*CFrame.new(i*0.2,-2,-0.4); weld(fr2,c)
	end

	local bl1 = mp(model,"BL1",Vector3.new(0.7,3.5,0.7),col.p)
	bl1.CFrame = root.CFrame*CFrame.new(-1.8,-0.5,1.5)*CFrame.Angles(0,0,math.rad(-10))
	rig.BackHipL = motor(body, bl1, "BackHipL")

	local bl2 = mp(model,"BL2",Vector3.new(0.5,3,0.5),col.s)
	bl2.CFrame = bl1.CFrame*CFrame.new(0,-3.2,0)*CFrame.Angles(math.rad(-10),0,0)
	rig.BackKneeL = motor(bl1, bl2, "BackKneeL")

	local br1 = mp(model,"BR1",Vector3.new(0.7,3.5,0.7),col.p)
	br1.CFrame = root.CFrame*CFrame.new(1.8,-0.5,1.5)*CFrame.Angles(0,0,math.rad(10))
	rig.BackHipR = motor(body, br1, "BackHipR")

	local br2 = mp(model,"BR2",Vector3.new(0.5,3,0.5),col.s)
	br2.CFrame = br1.CFrame*CFrame.new(0,-3.2,0)*CFrame.Angles(math.rad(-10),0,0)
	rig.BackKneeR = motor(br1, br2, "BackKneeR")

	return model, FootOffsets.TheRake, rig
end

local function buildSlenderman()
	local model = Instance.new("Model"); model.Name = "Slenderman"
	local col = MC.Slenderman; local rig = {}

	local root = mp(model,"HumanoidRootPart",Vector3.new(2.8,6,2),Color3.fromRGB(30,30,35),nil,1)
	root.Anchored = true; model.PrimaryPart = root

	local suit = mp(model,"Suit",Vector3.new(3,6.2,2.2),Color3.fromRGB(15,15,20))
	suit.CFrame = root.CFrame
	rig.Root = motor(root, suit, "Root")

	local tie = mp(model,"Tie",Vector3.new(0.4,4,0.15),Color3.fromRGB(20,20,20))
	tie.CFrame = root.CFrame*CFrame.new(0,0.5,-1.1); weld(suit,tie)

	local head = mp(model,"Head",Vector3.new(2.5,3,2.5),col.s)
	head.CFrame = root.CFrame*CFrame.new(0,5.5,0)
	rig.Neck = motor(suit, head, "Neck")

	local glow = ms(model,"Glow",Vector3.new(3,3.5,3),Color3.new(1,1,1),Enum.Material.Neon,0.85)
	glow.CFrame = head.CFrame; weld(head,glow)

		-- Tentacules (Motor6D) — sortent du DOS (Z positif = arrière)
	for i = 1, 4 do
		local side = (i % 2 == 0) and 1 or -1
		local xO = (i <= 2) and 2 or 1.5
		local yO = (i <= 2) and 2 or 1

		local tA = mp(model, "T"..i.."A", Vector3.new(0.35, 4, 0.35), col.p)
		tA.CFrame = root.CFrame * CFrame.new(side * xO, yO, 1)
			* CFrame.Angles(math.rad(30), 0, side * math.rad(-30))
		rig["T"..i.."A"] = motor(suit, tA, "T"..i.."A")

		local tB = mp(model, "T"..i.."B", Vector3.new(0.25, 3.5, 0.25), col.p)
		tB.CFrame = tA.CFrame * CFrame.new(side * 0.5, 3, 0.5)
			* CFrame.Angles(math.rad(15), 0, side * math.rad(-10))
		rig["T"..i.."B"] = motor(tA, tB, "T"..i.."B")

		local tC = mp(model, "T"..i.."C", Vector3.new(0.15, 2.5, 0.15), col.p)
		tC.CFrame = tB.CFrame * CFrame.new(0, 2.5, 0.3)
			* CFrame.Angles(math.rad(10), 0, side * math.rad(-5))
		rig["T"..i.."C"] = motor(tB, tC, "T"..i.."C")
	end

	-- Bras
	local armL1 = mp(model,"ArmL1",Vector3.new(0.9,5,0.9),Color3.fromRGB(25,25,30))
	armL1.CFrame = root.CFrame*CFrame.new(-2.5,1.5,0)
	rig.ShoulderL = motor(suit, armL1, "ShoulderL")

	local armL2 = mp(model,"ArmL2",Vector3.new(0.7,5,0.7),Color3.fromRGB(25,25,30))
	armL2.CFrame = armL1.CFrame*CFrame.new(-0.2,-5,0)
	rig.ElbowL = motor(armL1, armL2, "ElbowL")

	local handL = mp(model,"HandL",Vector3.new(0.6,0.6,0.6),col.s)
	handL.CFrame = armL2.CFrame*CFrame.new(0,-3,0)
	rig.WristL = motor(armL2, handL, "WristL")

	for i=0,5 do
		local f = mp(model,"FgL"..i,Vector3.new(0.1,2.5,0.1),col.s)
		f.CFrame = handL.CFrame*CFrame.new(-0.35+i*0.14,-1.5,0); weld(handL,f)
	end

	local armR1 = mp(model,"ArmR1",Vector3.new(0.9,5,0.9),Color3.fromRGB(25,25,30))
	armR1.CFrame = root.CFrame*CFrame.new(2.5,1.5,0)
	rig.ShoulderR = motor(suit, armR1, "ShoulderR")

	local armR2 = mp(model,"ArmR2",Vector3.new(0.7,5,0.7),Color3.fromRGB(25,25,30))
	armR2.CFrame = armR1.CFrame*CFrame.new(0.2,-5,0)
	rig.ElbowR = motor(armR1, armR2, "ElbowR")

	local handR = mp(model,"HandR",Vector3.new(0.6,0.6,0.6),col.s)
	handR.CFrame = armR2.CFrame*CFrame.new(0,-3,0)
	rig.WristR = motor(armR2, handR, "WristR")

	for i=0,5 do
		local f = mp(model,"FgR"..i,Vector3.new(0.1,2.5,0.1),col.s)
		f.CFrame = handR.CFrame*CFrame.new(-0.35+i*0.14,-1.5,0); weld(handR,f)
	end

	-- Jambes
	local legL = mp(model,"LegL",Vector3.new(1,7,1),Color3.fromRGB(20,20,25))
	legL.CFrame = root.CFrame*CFrame.new(-0.9,-6.8,0)
	rig.HipL = motor(suit, legL, "HipL")

	local shoeL = mp(model,"ShoeL",Vector3.new(1.2,0.6,2.5),Color3.fromRGB(10,10,10))
	shoeL.CFrame = legL.CFrame*CFrame.new(0,-3.8,0.3)
	rig.AnkleL = motor(legL, shoeL, "AnkleL")

	local legR = mp(model,"LegR",Vector3.new(1,7,1),Color3.fromRGB(20,20,25))
	legR.CFrame = root.CFrame*CFrame.new(0.9,-6.8,0)
	rig.HipR = motor(suit, legR, "HipR")

	local shoeR = mp(model,"ShoeR",Vector3.new(1.2,0.6,2.5),Color3.fromRGB(10,10,10))
	shoeR.CFrame = legR.CFrame*CFrame.new(0,-3.8,0.3)
	rig.AnkleR = motor(legR, shoeR, "AnkleR")

	return model, FootOffsets.Slenderman, rig
end

-- ═══════════════════════════════════════════════════════════════════
-- REGISTRE
-- ═══════════════════════════════════════════════════════════════════

local Builders = {
	HuggyWuggy  = buildHuggyWuggy,
	CartoonCat  = buildCartoonCat,
	SirenHead   = buildSirenHead,
	Wendigo     = buildWendigo,
	SkinWalker  = buildSkinWalker,
	TheRake     = buildTheRake,
	Slenderman  = buildSlenderman,
}

-- ═══════════════════════════════════════════════════════════════════
-- ANIMATIONS VIA Motor6D.Transform
-- ═══════════════════════════════════════════════════════════════════

-- Fonction générique d'animation pour bipèdes (Huggy, CartoonCat, Wendigo, SkinWalker, Slenderman)
local function animateBiped(rig, t, speed, name)
	local isIdle = speed < 1
	local isRun = speed > 20
	local cycle = t * math.clamp(speed / 6, 0.5, 3)
	local swing = math.sin(cycle)
	local bounce = math.abs(math.sin(cycle * 2))

	if isIdle then
		local b = math.sin(t * 2) * 0.05
		if rig.Root then rig.Root.Transform = CFrame.new(0,b,0) end
		if rig.Neck then rig.Neck.Transform = CFrame.Angles(b*0.5, math.sin(t*0.3)*0.04, 0) end
		if rig.ShoulderL then rig.ShoulderL.Transform = CFrame.Angles(b, 0, math.rad(-5)+b) end
		if rig.ShoulderR then rig.ShoulderR.Transform = CFrame.Angles(-b, 0, math.rad(5)-b) end
		if rig.ElbowL then rig.ElbowL.Transform = CFrame.Angles(math.rad(6), 0, 0) end
		if rig.ElbowR then rig.ElbowR.Transform = CFrame.Angles(math.rad(6), 0, 0) end
		if rig.ForearmL then rig.ForearmL.Transform = CFrame.new() end
		if rig.ForearmR then rig.ForearmR.Transform = CFrame.new() end
		if rig.WristL then rig.WristL.Transform = CFrame.new() end
		if rig.WristR then rig.WristR.Transform = CFrame.new() end
		if rig.HipL then rig.HipL.Transform = CFrame.new() end
		if rig.HipR then rig.HipR.Transform = CFrame.new() end
		if rig.AnkleL then rig.AnkleL.Transform = CFrame.new() end
		if rig.AnkleR then rig.AnkleR.Transform = CFrame.new() end
		if rig.Jaw then rig.Jaw.Transform = CFrame.Angles(math.sin(t*8)*0.02, 0, 0) end
		if rig.Tail then rig.Tail.Transform = CFrame.Angles(0, math.sin(t*2.5)*0.5, 0) end
		if rig.Flap1 then rig.Flap1.Transform = CFrame.Angles(0, 0, math.sin(t*2)*0.08) end
	else
		local mult = isRun and 1.4 or 1.0
		local armAmp = 0.8 * mult
		local legAmp = 0.7 * mult
		local elbowBend = 0.3 * mult

		if rig.Root then rig.Root.Transform = CFrame.new(0, -bounce*0.15*mult, 0) end
		if rig.Neck then rig.Neck.Transform = CFrame.Angles(math.rad(8)*mult, 0, math.sin(cycle*0.5)*0.04) end

		-- Bras (opposé aux jambes)
		if rig.ShoulderL then rig.ShoulderL.Transform = CFrame.Angles(-swing*armAmp, 0, math.rad(-8)) end
		if rig.ShoulderR then rig.ShoulderR.Transform = CFrame.Angles(swing*armAmp, 0, math.rad(8)) end
		if rig.ElbowL then rig.ElbowL.Transform = CFrame.Angles(math.rad(10) + math.max(0,swing)*elbowBend, 0, 0) end
		if rig.ElbowR then rig.ElbowR.Transform = CFrame.Angles(math.rad(10) + math.max(0,-swing)*elbowBend, 0, 0) end
		if rig.ForearmL then rig.ForearmL.Transform = CFrame.Angles(math.max(0,swing)*0.2, 0, 0) end
		if rig.ForearmR then rig.ForearmR.Transform = CFrame.Angles(math.max(0,-swing)*0.2, 0, 0) end
		if rig.WristL then rig.WristL.Transform = CFrame.new() end
		if rig.WristR then rig.WristR.Transform = CFrame.new() end

		-- Jambes
		if rig.HipL then rig.HipL.Transform = CFrame.Angles(swing*legAmp, 0, 0) end
		if rig.HipR then rig.HipR.Transform = CFrame.Angles(-swing*legAmp, 0, 0) end
		if rig.AnkleL then rig.AnkleL.Transform = CFrame.Angles(-math.max(0,swing)*0.35, 0, 0) end
		if rig.AnkleR then rig.AnkleR.Transform = CFrame.Angles(-math.max(0,-swing)*0.35, 0, 0) end

		-- Mâchoire
		if rig.Jaw then rig.Jaw.Transform = CFrame.Angles(math.abs(swing)*0.1, 0, 0) end

		-- Queue
		if rig.Tail then rig.Tail.Transform = CFrame.Angles(0.2, math.sin(cycle*2)*0.8, 0) end

		-- SkinFlap
		if rig.Flap1 then rig.Flap1.Transform = CFrame.Angles(0, 0, math.sin(cycle*1.5)*0.15) end
	end
end

-- Animation spéciale pour SirenHead (cou articulé)
local function animateSirenHead(rig, t, speed)
	local isIdle = speed < 1
	local cycle = t * math.clamp(speed / 5, 0.3, 2)
	local swing = math.sin(cycle)

	if isIdle then
		local sway = math.sin(t*0.5)*0.06
		if rig.Root then rig.Root.Transform = CFrame.new() end
		if rig.Neck1 then rig.Neck1.Transform = CFrame.Angles(sway*0.3, 0, sway*0.2) end
		if rig.Neck2 then rig.Neck2.Transform = CFrame.Angles(sway*0.4, math.sin(t*0.3)*0.05, 0) end
		if rig.Neck3 then rig.Neck3.Transform = CFrame.Angles(sway*0.3, math.sin(t*0.4)*0.08, sway*0.2) end
		if rig.SirenL then rig.SirenL.Transform = CFrame.Angles(0, math.sin(t*0.7)*0.25, 0) end
		if rig.SirenR then rig.SirenR.Transform = CFrame.Angles(0, math.sin(t*0.7+math.pi)*0.25, 0) end
		if rig.ShoulderL then rig.ShoulderL.Transform = CFrame.Angles(math.sin(t*0.6)*0.08, 0, 0) end
		if rig.ShoulderR then rig.ShoulderR.Transform = CFrame.Angles(math.sin(t*0.6+1)*0.08, 0, 0) end
		if rig.HipL then rig.HipL.Transform = CFrame.new() end
		if rig.HipR then rig.HipR.Transform = CFrame.new() end
	else
		if rig.Root then rig.Root.Transform = CFrame.new(0, -math.abs(swing)*0.15, 0) end
		if rig.Neck1 then rig.Neck1.Transform = CFrame.Angles(0.04, swing*0.03, 0) end
		if rig.Neck2 then rig.Neck2.Transform = CFrame.Angles(swing*0.04, swing*0.04, 0) end
		if rig.Neck3 then rig.Neck3.Transform = CFrame.Angles(0, swing*0.06, 0) end
		if rig.ShoulderL then rig.ShoulderL.Transform = CFrame.Angles(-swing*0.4, 0, 0) end
		if rig.ShoulderR then rig.ShoulderR.Transform = CFrame.Angles(swing*0.4, 0, 0) end
		if rig.ElbowL then rig.ElbowL.Transform = CFrame.Angles(math.max(0,swing)*0.3, 0, 0) end
		if rig.ElbowR then rig.ElbowR.Transform = CFrame.Angles(math.max(0,-swing)*0.3, 0, 0) end
		if rig.HipL then rig.HipL.Transform = CFrame.Angles(swing*0.4, 0, 0) end
		if rig.HipR then rig.HipR.Transform = CFrame.Angles(-swing*0.4, 0, 0) end
	end
end

-- Animation spéciale pour TheRake (4 pattes)
local function animateRake(rig, t, speed)
	local isIdle = speed < 1
	local cycle = t * math.clamp(speed / 4, 0.5, 3.5)
	local swing = math.sin(cycle)

	if isIdle then
		local b = math.sin(t*4)*0.04
		if rig.Root then rig.Root.Transform = CFrame.new(0,b,0) end
		if rig.Neck then rig.Neck.Transform = CFrame.Angles(b*0.2, math.sin(t*0.4)*0.12, 0) end
		if rig.Jaw then rig.Jaw.Transform = CFrame.Angles(math.sin(t*6)*0.03, 0, 0) end
		if rig.FrontShoulderL then rig.FrontShoulderL.Transform = CFrame.new() end
		if rig.FrontShoulderR then rig.FrontShoulderR.Transform = CFrame.new() end
		if rig.BackHipL then rig.BackHipL.Transform = CFrame.new() end
		if rig.BackHipR then rig.BackHipR.Transform = CFrame.new() end
	else
		local mult = speed > 20 and 1.4 or 1.0
		local amp = 0.7 * mult

		if rig.Root then rig.Root.Transform = CFrame.new(0, -math.abs(swing)*0.1*mult, 0) end
		if rig.Neck then rig.Neck.Transform = CFrame.Angles(-0.05*mult, 0, 0) end

		-- Pattes avant (diagonale)
		if rig.FrontShoulderL then rig.FrontShoulderL.Transform = CFrame.Angles(swing*amp, 0, 0) end
		if rig.FrontElbowL then rig.FrontElbowL.Transform = CFrame.Angles(math.max(0,swing)*0.4*mult, 0, 0) end
		if rig.FrontShoulderR then rig.FrontShoulderR.Transform = CFrame.Angles(-swing*amp, 0, 0) end
		if rig.FrontElbowR then rig.FrontElbowR.Transform = CFrame.Angles(math.max(0,-swing)*0.4*mult, 0, 0) end

		-- Pattes arrière (opposé diagonal)
		if rig.BackHipL then rig.BackHipL.Transform = CFrame.Angles(-swing*amp*0.8, 0, 0) end
		if rig.BackKneeL then rig.BackKneeL.Transform = CFrame.Angles(math.max(0,-swing)*0.3*mult, 0, 0) end
		if rig.BackHipR then rig.BackHipR.Transform = CFrame.Angles(swing*amp*0.8, 0, 0) end
		if rig.BackKneeR then rig.BackKneeR.Transform = CFrame.Angles(math.max(0,swing)*0.3*mult, 0, 0) end

		if rig.Jaw then rig.Jaw.Transform = CFrame.Angles(math.abs(swing)*0.08, 0, 0) end
	end
end

-- Animation spéciale pour Slenderman (tentacules)
local function animateSlenderman(rig, t, speed)
	-- Base bipède
	animateBiped(rig, t, speed, "Slenderman")

	-- Tentacules
	for i = 1, 4 do
		local side = (i%2==0) and 1 or -1
		local ang = math.sin(t*1.2 + i*1.5) * (speed > 1 and 0.45 or 0.25)

		local tA = rig["T"..i.."A"]
		if tA then tA.Transform = CFrame.Angles(ang, math.sin(t+i)*0.2, ang*0.3) end

		local tB = rig["T"..i.."B"]
		if tB then tB.Transform = CFrame.Angles(ang*0.6, 0, 0) end

		local tC = rig["T"..i.."C"]
		if tC then tC.Transform = CFrame.Angles(ang*0.3, 0, 0) end
	end

	-- Glow glitch
	if morphModel then
		local glow = morphModel:FindFirstChild("Glow")
		if glow then
			glow.Transparency = math.sin(t*0.15) > 0.93 and 0.3+math.sin(t*35)*0.3 or 0.85
		end
	end
end

-- Dispatch d'animation par monstre
local AnimDispatchers = {
	HuggyWuggy  = function(rig, t, speed) animateBiped(rig, t, speed, "HuggyWuggy") end,
	CartoonCat  = function(rig, t, speed) animateBiped(rig, t, speed, "CartoonCat") end,
	SirenHead   = animateSirenHead,
	Wendigo     = function(rig, t, speed) animateBiped(rig, t, speed, "Wendigo") end,
	SkinWalker  = function(rig, t, speed) animateBiped(rig, t, speed, "SkinWalker") end,
	TheRake     = animateRake,
	Slenderman  = animateSlenderman,
}

-- ═══════════════════════════════════════════════════════════════════
-- MORPH SYSTEM
-- ═══════════════════════════════════════════════════════════════════

local function removeMorph()
	if animConn then animConn:Disconnect(); animConn = nil end
	if posConn then posConn:Disconnect(); posConn = nil end
	if morphModel then morphModel:Destroy(); morphModel = nil end
	currentRig = nil
	cleanSounds()
	for _, p in pairs(character:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Transparency = (p.Name == "HumanoidRootPart") and 1 or 0
		elseif p:IsA("Decal") then
			p.Transparency = 0
		end
	end
	isMorphed = false; currentMorphName = ""; morphYOffset = 0
	animTimer = 0; animState = "idle"
	humanoid.WalkSpeed = 16; humanoid.JumpPower = 50
end

local function applyMorph(morphName)
	removeMorph()

	local builder = Builders[morphName]
	if not builder then return end

	-- Son
	local ts = snd(SND.transform, 1.5); ts:Play(); Debris:AddItem(ts, 4)

	-- Cacher le joueur
	for _, p in pairs(character:GetDescendants()) do
		if p:IsA("BasePart") then p.Transparency = 1
		elseif p:IsA("Decal") then p.Transparency = 1 end
	end

	-- Construire
	local model, footOffset, rig = builder()
	model.Name = "CKM_MorphModel"
	model.Parent = workspace

	morphModel = model
	currentRig = rig
	currentMorphName = morphName
	isMorphed = true
	animTimer = 0
	morphYOffset = footOffset - 3

	-- Vitesse
	local sp = MorphSpeeds[morphName]
	if sp then humanoid.WalkSpeed = sp.w; humanoid.JumpPower = sp.j end

	-- Son ambiant
	local amb = snd(AmbSounds[morphName] or SND.ambient, 0.4, true); amb:Play()

	-- Position chaque frame
	posConn = RunService.RenderStepped:Connect(function()
		if not isMorphed or not morphModel or not morphModel.PrimaryPart then return end
		pcall(function()
			morphModel:PivotTo(rootPart.CFrame * CFrame.new(0, morphYOffset, 0))
		end)
	end)

	-- Animation chaque frame
	local dispatcher = AnimDispatchers[morphName]
	if dispatcher then
		animConn = RunService.RenderStepped:Connect(function(dt)
			if not isMorphed or not currentRig then return end
			animTimer = animTimer + dt

			local vel = rootPart.AssemblyLinearVelocity
			local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude

			pcall(function()
				dispatcher(currentRig, animTimer, speed)
			end)

			-- Effets SirenHead
			if morphName == "SirenHead" and morphModel then
				local lL = morphModel:FindFirstChild("LightL")
				local lR = morphModel:FindFirstChild("LightR")
				local tf = tick()
				if lL then lL.Color = (math.floor(tf*2.5)%2==0) and Color3.fromRGB(255,0,0) or Color3.fromRGB(30,0,0) end
				if lR then lR.Color = (math.floor(tf*2.5+1)%2==0) and Color3.fromRGB(255,0,0) or Color3.fromRGB(30,0,0) end
			end
		end)
	end
end

-- ═══════════════════════════════════════════════════════════════════
-- JUMPSCARE
-- ═══════════════════════════════════════════════════════════════════

local function doJumpscare(targetPlayer)
	if jumpscareActive or not isMorphed then return end
	jumpscareActive = true

	local tChar = targetPlayer and targetPlayer.Character
	if not tChar then jumpscareActive = false; return end
	local tRoot = tChar:FindFirstChild("HumanoidRootPart")
	if not tRoot then jumpscareActive = false; return end

	-- TP victime devant le monstre
	tRoot.CFrame = rootPart.CFrame * CFrame.new(0, 0, -4)

	-- Bloquer victime
	local tHum = tChar:FindFirstChildOfClass("Humanoid")
	if tHum then tHum.WalkSpeed = 0; tHum.JumpPower = 0 end

	-- Sons
	local ws = snd(SND.whoosh, 2); ws:Play(); Debris:AddItem(ws, 2)
	task.wait(0.15)
	local jsList = {SND.jumpscare1, SND.jumpscare2, SND.jumpscare3}
	local js = snd(jsList[math.random(1,3)], 3); js:Play(); Debris:AddItem(js, JUMPSCARE_DURATION+1)
	local hs = snd(SND.heartbeat, 1.2, true); hs:Play()

	-- GUI visuel
	local gui = player.PlayerGui:FindFirstChild("CoolKidMorph")
	if gui then
		local jsF = Instance.new("Frame")
		jsF.Name = "JsFrame"; jsF.Size = UDim2.new(1,0,1,0)
		jsF.BackgroundColor3 = Color3.new(1,0,0); jsF.ZIndex = 100; jsF.Parent = gui

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(0.8,0,0.25,0); nameL.Position = UDim2.new(0.1,0,0.38,0)
		nameL.BackgroundTransparency = 1; nameL.Text = currentMorphName:upper()
		nameL.TextColor3 = Color3.new(1,1,1); nameL.TextScaled = true
		nameL.Font = Enum.Font.GothamBold; nameL.TextStrokeTransparency = 0
		nameL.TextStrokeColor3 = C.blood; nameL.ZIndex = 105; nameL.Parent = jsF

		local startT = tick()
		local shakeConn
		shakeConn = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startT
			if elapsed > JUMPSCARE_DURATION then
				shakeConn:Disconnect()
				TweenService:Create(jsF, TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
				TweenService:Create(nameL, TweenInfo.new(0.5), {TextTransparency=1}):Play()
				pcall(function() hs:Stop(); hs:Destroy() end)
				task.delay(1, function() pcall(function() jsF:Destroy() end) end)
				return
			end

			if elapsed < 0.3 then
				local t2 = elapsed/0.3
				jsF.BackgroundColor3 = Color3.new(1,1-t2,1-t2)
				jsF.BackgroundTransparency = 0
			elseif elapsed < 1.5 then
				local t2 = elapsed-0.3
				local fl = math.sin(t2*30)
				jsF.BackgroundColor3 = fl>0 and Color3.fromRGB(180,0,0) or Color3.new(0,0,0)
				jsF.BackgroundTransparency = 0.1
				local intensity = math.floor(40*(1-t2/1.2))
				jsF.Position = UDim2.new(0,math.random(-intensity,intensity),0,math.random(-intensity,intensity))
			elseif elapsed < 2.5 then
				jsF.BackgroundColor3 = Color3.fromRGB(30,0,0)
				jsF.BackgroundTransparency = 0.3
				local intensity = math.floor(10*(1-(elapsed-1.5)))
				jsF.Position = UDim2.new(0,math.random(-intensity,intensity),0,math.random(-intensity,intensity))
			else
				local t2 = (elapsed-2.5)/1.0
				jsF.BackgroundColor3 = Color3.new(0,0,0)
				jsF.BackgroundTransparency = math.min(t2,1)
				jsF.Position = UDim2.new(0,0,0,0)
				nameL.TextTransparency = math.min(t2*2,1)
				pcall(function() hs.Volume = 1.2*(1-t2) end)
			end
		end)
	end

	task.wait(JUMPSCARE_DURATION + 0.5)

	-- Libérer
	if tHum then tHum.WalkSpeed = 16; tHum.JumpPower = 50 end
	jumpscareActive = false
end

-- ═══════════════════════════════════════════════════════════════════
-- GUI
-- ═══════════════════════════════════════════════════════════════════

local sg = Instance.new("ScreenGui"); sg.Name = "CoolKidMorph"
sg.ResetOnSpawn = false; sg.Parent = player.PlayerGui

-- Toggle
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0,52,0,52); toggleBtn.Position = UDim2.new(0,12,0.5,-26)
toggleBtn.BackgroundColor3 = C.accent; toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "☠"; toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 28; toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.ZIndex = 10; toggleBtn.Parent = sg
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,12)

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0,520,0,620); mainFrame.Position = UDim2.new(0,72,0.5,-310)
mainFrame.BackgroundColor3 = C.bg; mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 5; mainFrame.Visible = false; mainFrame.Parent = sg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,16)
local mStroke = Instance.new("UIStroke"); mStroke.Color = C.accent; mStroke.Thickness = 2; mStroke.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,60); header.BackgroundColor3 = C.sidebar
header.BorderSizePixel = 0; header.ZIndex = 6; header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0,16)

local hTitle = Instance.new("TextLabel")
hTitle.Size = UDim2.new(1,-80,1,0); hTitle.Position = UDim2.new(0,14,0,0)
hTitle.BackgroundTransparency = 1; hTitle.Text = "☠ COOLKID MORPH v5.0"
hTitle.TextColor3 = Color3.new(1,1,1); hTitle.TextSize = 16
hTitle.Font = Enum.Font.GothamBold; hTitle.TextXAlignment = Enum.TextXAlignment.Left
hTitle.ZIndex = 7; hTitle.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,36,0,36); closeBtn.Position = UDim2.new(1,-46,0.5,-18)
closeBtn.BackgroundColor3 = C.accent; closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold; closeBtn.ZIndex = 7; closeBtn.Parent = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)

-- Content scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-20,1,-70); scroll.Position = UDim2.new(0,10,0,65)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = C.accent; scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ZIndex = 6; scroll.Parent = mainFrame
Instance.new("UIListLayout", scroll).Padding = UDim.new(0,6)

-- Status
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1,0,0,32); statusBar.BackgroundColor3 = C.card
statusBar.BorderSizePixel = 0; statusBar.LayoutOrder = 1; statusBar.ZIndex = 7; statusBar.Parent = scroll
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0,8)

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,-16,1,0); statusLbl.Position = UDim2.new(0,12,0,0)
statusLbl.BackgroundTransparency = 1; statusLbl.Text = "Prêt — [M] pour ouvrir"
statusLbl.TextColor3 = C.dim; statusLbl.TextSize = 11
statusLbl.Font = Enum.Font.Gotham; statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.ZIndex = 8; statusLbl.Parent = statusBar

local function updateStatus(t, col)
	statusLbl.Text = t; statusLbl.TextColor3 = col or C.dim
end

-- Morph section
local morphLbl = Instance.new("TextLabel")
morphLbl.Size = UDim2.new(1,0,0,20); morphLbl.BackgroundTransparency = 1
morphLbl.Text = "▸ CHOISIR UN MONSTRE"; morphLbl.TextColor3 = C.accent
morphLbl.TextSize = 11; morphLbl.Font = Enum.Font.GothamBold
morphLbl.TextXAlignment = Enum.TextXAlignment.Left
morphLbl.LayoutOrder = 2; morphLbl.ZIndex = 7; morphLbl.Parent = scroll

local morphGrid = Instance.new("Frame")
morphGrid.Size = UDim2.new(1,0,0,0); morphGrid.BackgroundTransparency = 1
morphGrid.AutomaticSize = Enum.AutomaticSize.Y
morphGrid.LayoutOrder = 3; morphGrid.ZIndex = 7; morphGrid.Parent = scroll

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.48,0,0,80)
gridLayout.CellPadding = UDim2.new(0.02,0,0,6); gridLayout.Parent = morphGrid

local morphData = {
	{name="HuggyWuggy",  emoji="🔵", desc="Bras longs, fourrure bleue",    col=MC.HuggyWuggy.p},
	{name="CartoonCat",  emoji="🐱", desc="Chat cartoon horrifique",        col=MC.CartoonCat.p},
	{name="SirenHead",   emoji="📢", desc="Sirènes, cou articulé",          col=MC.SirenHead.a},
	{name="Wendigo",     emoji="🦌", desc="Crâne de cerf, griffes",         col=MC.Wendigo.a},
	{name="SkinWalker",  emoji="👁", desc="Peau arrachée, mouvements glitch", col=MC.SkinWalker.p},
	{name="TheRake",     emoji="🕷", desc="4 pattes, ultra rapide",          col=MC.TheRake.p},
	{name="Slenderman",  emoji="🎩", desc="Tentacules, sans visage",        col=MC.Slenderman.s},
}

local morphBtns = {}

for _, md in ipairs(morphData) do
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = C.card; btn.BorderSizePixel = 0; btn.Text = ""
	btn.ZIndex = 8; btn.Parent = morphGrid
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = md.col; stroke.Thickness = 1.5; stroke.Transparency = 0.6; stroke.Parent = btn

	local emoji = Instance.new("TextLabel")
	emoji.Size = UDim2.new(0.3,0,0,36); emoji.Position = UDim2.new(0,4,0,6)
	emoji.BackgroundTransparency = 1; emoji.Text = md.emoji; emoji.TextSize = 24
	emoji.ZIndex = 9; emoji.Parent = btn

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(0.68,0,0,18); name.Position = UDim2.new(0.3,0,0,8)
	name.BackgroundTransparency = 1; name.Text = md.name
	name.TextColor3 = Color3.new(1,1,1); name.TextSize = 12
	name.Font = Enum.Font.GothamBold; name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 9; name.Parent = btn

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1,-10,0,14); desc.Position = UDim2.new(0,6,0,42)
	desc.BackgroundTransparency = 1; desc.Text = md.desc
	desc.TextColor3 = C.dim; desc.TextSize = 9; desc.Font = Enum.Font.Gotham
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.ZIndex = 9; desc.Parent = btn

	local sp = MorphSpeeds[md.name]
	local stats = Instance.new("TextLabel")
	stats.Size = UDim2.new(1,-10,0,14); stats.Position = UDim2.new(0,6,0,58)
	stats.BackgroundTransparency = 1; stats.Text = string.format("⚡%d  🦘%d", sp.w, sp.j)
	stats.TextColor3 = md.col; stats.TextSize = 9; stats.Font = Enum.Font.GothamBold
	stats.TextXAlignment = Enum.TextXAlignment.Left
	stats.ZIndex = 9; stats.Parent = btn

	morphBtns[md.name] = {btn=btn, stroke=stroke, col=md.col}

	btn.MouseButton1Click:Connect(function()
		applyMorph(md.name)
		updateStatus("✅ "..md.name.." — Bras/Jambes animés!", md.col)
		for _, v in pairs(morphBtns) do
			v.stroke.Transparency = 0.6; v.btn.BackgroundColor3 = C.card
		end
		stroke.Transparency = 0; btn.BackgroundColor3 = C.cardH
	end)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=C.cardH}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency=0}):Play()
	end)
	btn.MouseLeave:Connect(function()
		if currentMorphName ~= md.name then
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=C.card}):Play()
			TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency=0.6}):Play()
		end
	end)
end

-- Actions
local actLbl = Instance.new("TextLabel")
actLbl.Size = UDim2.new(1,0,0,20); actLbl.BackgroundTransparency = 1
actLbl.Text = "▸ ACTIONS"; actLbl.TextColor3 = C.accent2
actLbl.TextSize = 11; actLbl.Font = Enum.Font.GothamBold
actLbl.TextXAlignment = Enum.TextXAlignment.Left
actLbl.LayoutOrder = 4; actLbl.ZIndex = 7; actLbl.Parent = scroll

local actFrame = Instance.new("Frame")
actFrame.Size = UDim2.new(1,0,0,42); actFrame.BackgroundTransparency = 1
actFrame.LayoutOrder = 5; actFrame.ZIndex = 7; actFrame.Parent = scroll

local remBtn = Instance.new("TextButton")
remBtn.Size = UDim2.new(0.48,0,0,38)
remBtn.BackgroundColor3 = Color3.fromRGB(60,20,20)
remBtn.Text = "✕  Retirer"; remBtn.TextColor3 = Color3.fromRGB(255,80,80)
remBtn.TextSize = 12; remBtn.Font = Enum.Font.GothamBold
remBtn.ZIndex = 8; remBtn.Parent = actFrame
Instance.new("UICorner", remBtn).CornerRadius = UDim.new(0,8)

remBtn.MouseButton1Click:Connect(function()
	removeMorph(); updateStatus("Aucun morph actif")
	for _, v in pairs(morphBtns) do
		v.stroke.Transparency = 0.6; v.btn.BackgroundColor3 = C.card
	end
end)

local jsBtn = Instance.new("TextButton")
jsBtn.Size = UDim2.new(0.48,0,0,38); jsBtn.Position = UDim2.new(0.52,0,0,0)
jsBtn.BackgroundColor3 = Color3.fromRGB(60,10,10)
jsBtn.Text = "👁 Jumpscare [J]"; jsBtn.TextColor3 = C.accent
jsBtn.TextSize = 12; jsBtn.Font = Enum.Font.GothamBold
jsBtn.ZIndex = 8; jsBtn.Parent = actFrame
Instance.new("UICorner", jsBtn).CornerRadius = UDim.new(0,8)

jsBtn.MouseButton1Click:Connect(function()
	if not isMorphed then updateStatus("⚠ Morphez-vous d'abord!", C.orange); return end
	local cl, cd = nil, GRAB_RANGE*2
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local r = p.Character:FindFirstChild("HumanoidRootPart")
			if r then
				local d = (rootPart.Position - r.Position).Magnitude
				if d < cd then cl = p; cd = d end
			end
		end
	end
	if cl then doJumpscare(cl) else updateStatus("⚠ Personne à portée!", C.orange) end
end)

-- Grab list
local grabLbl = Instance.new("TextLabel")
grabLbl.Size = UDim2.new(1,0,0,20); grabLbl.BackgroundTransparency = 1
grabLbl.Text = "▸ GRAB [G]"; grabLbl.TextColor3 = C.accent3
grabLbl.TextSize = 11; grabLbl.Font = Enum.Font.GothamBold
grabLbl.TextXAlignment = Enum.TextXAlignment.Left
grabLbl.LayoutOrder = 6; grabLbl.ZIndex = 7; grabLbl.Parent = scroll

local plFrame = Instance.new("Frame")
plFrame.Size = UDim2.new(1,0,0,0); plFrame.BackgroundColor3 = C.card
plFrame.BorderSizePixel = 0; plFrame.AutomaticSize = Enum.AutomaticSize.Y
plFrame.LayoutOrder = 7; plFrame.ZIndex = 7; plFrame.Parent = scroll
Instance.new("UICorner", plFrame).CornerRadius = UDim.new(0,8)
Instance.new("UIListLayout", plFrame).Padding = UDim.new(0,2)

local function refreshPlayers()
	for _, c in pairs(plFrame:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UICorner") then c:Destroy() end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player then
			local pb = Instance.new("TextButton")
			pb.Size = UDim2.new(1,-8,0,30); pb.BackgroundColor3 = C.cardH
			pb.Text = ""; pb.ZIndex = 8; pb.Parent = plFrame
			Instance.new("UICorner", pb).CornerRadius = UDim.new(0,6)

			local pn = Instance.new("TextLabel")
			pn.Size = UDim2.new(0.6,0,1,0); pn.Position = UDim2.new(0,8,0,0)
			pn.BackgroundTransparency = 1; pn.Text = "👤 "..p.Name
			pn.TextColor3 = C.text; pn.TextSize = 11; pn.Font = Enum.Font.Gotham
			pn.TextXAlignment = Enum.TextXAlignment.Left; pn.ZIndex = 9; pn.Parent = pb

			local gb = Instance.new("TextButton")
			gb.Size = UDim2.new(0,60,0,20); gb.Position = UDim2.new(1,-68,0.5,-10)
			gb.BackgroundColor3 = C.accent; gb.Text = "GRAB"
			gb.TextColor3 = Color3.new(1,1,1); gb.TextSize = 10
			gb.Font = Enum.Font.GothamBold; gb.ZIndex = 9; gb.Parent = pb
			Instance.new("UICorner", gb).CornerRadius = UDim.new(0,5)

			gb.MouseButton1Click:Connect(function()
				if not isMorphed then updateStatus("⚠ Morphez-vous d'abord!", C.orange); return end
				doJumpscare(p)
			end)
		end
	end
end

-- Sound toggle
local sndFrame = Instance.new("Frame")
sndFrame.Size = UDim2.new(1,0,0,30); sndFrame.BackgroundColor3 = C.card
sndFrame.BorderSizePixel = 0; sndFrame.LayoutOrder = 8; sndFrame.ZIndex = 7; sndFrame.Parent = scroll
Instance.new("UICorner", sndFrame).CornerRadius = UDim.new(0,8)

local sndLbl = Instance.new("TextLabel")
sndLbl.Size = UDim2.new(0.7,0,1,0); sndLbl.Position = UDim2.new(0,12,0,0)
sndLbl.BackgroundTransparency = 1; sndLbl.Text = "🔊 Sons"
sndLbl.TextColor3 = C.text; sndLbl.TextSize = 11; sndLbl.Font = Enum.Font.Gotham
sndLbl.TextXAlignment = Enum.TextXAlignment.Left; sndLbl.ZIndex = 8; sndLbl.Parent = sndFrame

local sndTgl = Instance.new("TextButton")
sndTgl.Size = UDim2.new(0,40,0,20); sndTgl.Position = UDim2.new(1,-48,0.5,-10)
sndTgl.BackgroundColor3 = C.tOn; sndTgl.Text = "ON"
sndTgl.TextColor3 = Color3.new(1,1,1); sndTgl.TextSize = 10
sndTgl.Font = Enum.Font.GothamBold; sndTgl.ZIndex = 8; sndTgl.Parent = sndFrame
Instance.new("UICorner", sndTgl).CornerRadius = UDim.new(0,5)

sndTgl.MouseButton1Click:Connect(function()
	soundsEnabled = not soundsEnabled
	sndTgl.Text = soundsEnabled and "ON" or "OFF"
	sndTgl.BackgroundColor3 = soundsEnabled and C.tOn or C.tOff
	if not soundsEnabled then cleanSounds() end
end)

-- Refresh button
local refBtn = Instance.new("TextButton")
refBtn.Size = UDim2.new(1,0,0,26); refBtn.BackgroundColor3 = C.card
refBtn.Text = "🔄 Actualiser joueurs"; refBtn.TextColor3 = C.accent3
refBtn.TextSize = 11; refBtn.Font = Enum.Font.GothamBold
refBtn.LayoutOrder = 9; refBtn.ZIndex = 7; refBtn.Parent = scroll
Instance.new("UICorner", refBtn).CornerRadius = UDim.new(0,6)

refBtn.MouseButton1Click:Connect(function()
	refreshPlayers(); updateStatus("✅ Actualisé", C.green)
end)

-- ═══════════════════════════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════════════════════════

-- Pulse
RunService.RenderStepped:Connect(function()
	local t = tick(); local pulse = math.sin(t*2)*0.15+0.85
	if isMorphed then
		toggleBtn.BackgroundColor3 = Color3.fromRGB(math.floor(255*pulse),0,math.floor(60*pulse))
	else
		toggleBtn.BackgroundColor3 = C.accent
	end
end)

local guiOpen = false

toggleBtn.MouseButton1Click:Connect(function()
	guiOpen = not guiOpen; mainFrame.Visible = guiOpen
	if guiOpen then
		refreshPlayers()
		mainFrame.Position = UDim2.new(0,52,0.5,-310)
		TweenService:Create(mainFrame, TweenInfo.new(0.3,Enum.EasingStyle.Back), {
			Position = UDim2.new(0,72,0.5,-310)
		}):Play()
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	guiOpen = false
	TweenService:Create(mainFrame, TweenInfo.new(0.2), {Position=UDim2.new(0,52,0.5,-310)}):Play()
	task.wait(0.2); mainFrame.Visible = false
end)

UIS.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.M then
		guiOpen = not guiOpen; mainFrame.Visible = guiOpen
		if guiOpen then refreshPlayers() end
	end
	if inp.KeyCode == Enum.KeyCode.G and isMorphed then
		local cl, cd = nil, GRAB_RANGE
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				local r = p.Character:FindFirstChild("HumanoidRootPart")
				if r then
					local d = (rootPart.Position - r.Position).Magnitude
					if d < cd then cl = p; cd = d end
				end
			end
		end
		if cl then doJumpscare(cl) end
	end
	if inp.KeyCode == Enum.KeyCode.J and isMorphed then
		local cl, cd = nil, GRAB_RANGE*2
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player and p.Character then
				local r = p.Character:FindFirstChild("HumanoidRootPart")
				if r then
					local d = (rootPart.Position - r.Position).Magnitude
					if d < cd then cl = p; cd = d end
				end
			end
		end
		if cl then doJumpscare(cl) end
	end
end)

player.CharacterAdded:Connect(function(newChar)
	character = newChar; humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")
	removeMorph(); updateStatus("Aucun morph actif")
	for _, v in pairs(morphBtns) do
		v.stroke.Transparency = 0.6; v.btn.BackgroundColor3 = C.card
	end
end)

Players.PlayerAdded:Connect(function() task.wait(1); refreshPlayers() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); refreshPlayers() end)

-- Notif
task.spawn(function()
	task.wait(1)
	local n = Instance.new("Frame")
	n.Size = UDim2.new(0,380,0,60); n.Position = UDim2.new(0.5,-190,0,-70)
	n.BackgroundColor3 = C.card; n.BorderSizePixel = 0; n.ZIndex = 50; n.Parent = sg
	Instance.new("UICorner", n).CornerRadius = UDim.new(0,12)
	Instance.new("UIStroke", n).Color = C.accent

	local nt = Instance.new("TextLabel")
	nt.Size = UDim2.new(1,-16,0,22); nt.Position = UDim2.new(0,12,0,6)
	nt.BackgroundTransparency = 1; nt.Text = "☠ CoolKid Morph v5.0 — Motor6D!"
	nt.TextColor3 = Color3.new(1,1,1); nt.TextSize = 14
	nt.Font = Enum.Font.GothamBold; nt.TextXAlignment = Enum.TextXAlignment.Left
	nt.ZIndex = 51; nt.Parent = n

	local ns = Instance.new("TextLabel")
	ns.Size = UDim2.new(1,-16,0,18); ns.Position = UDim2.new(0,12,0,30)
	ns.BackgroundTransparency = 1; ns.Text = "[M] Menu | [G] Grab | [J] Jumpscare | Bras/Jambes bougent!"
	ns.TextColor3 = C.dim; ns.TextSize = 9; ns.Font = Enum.Font.Gotham
	ns.TextXAlignment = Enum.TextXAlignment.Left; ns.ZIndex = 51; ns.Parent = n

	TweenService:Create(n, TweenInfo.new(0.4,Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5,-190,0,12)
	}):Play()
	task.wait(5)
	TweenService:Create(n, TweenInfo.new(0.3), {Position=UDim2.new(0.5,-190,0,-70)}):Play()
	task.wait(0.4); n:Destroy()
end)

-- Init
refreshPlayers()
updateStatus("Prêt — [M] pour ouvrir le menu")

print("═══════════════════════════════════════")
print("  ☠ CoolKid Morph v5.0 — MOTOR6D")
print("  ✅ Bras, jambes, tête BOUGENT enfin")
print("  ✅ Motor6D.Transform pour chaque joint")
print("  ✅ idle/walk/run adaptatif à la vitesse")
print("  ✅ 7 monstres articulés")
print("  ✅ Tentacules Slenderman animés")
print("  ✅ 4 pattes The Rake animées")
print("  ✅ Cou articulé SirenHead (3 segments)")
print("  ⌨️  [M] Menu | [G] Grab | [J] Jumpscare")
print("═══════════════════════════════════════")