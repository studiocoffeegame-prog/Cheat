--[[
╔════════════════════════════════════════════════════════════════╗
║           📺 TÉLÉ HANTÉE V4 - SONS + FIXES ROTATION         ║
║         LocalScript → StarterGui ou StarterPlayerScripts      ║
╚════════════════════════════════════════════════════════════════╝
]]

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ============================================
-- NETTOYAGE
-- ============================================
if workspace:FindFirstChild("HauntedTV_Folder") then
	workspace:FindFirstChild("HauntedTV_Folder"):Destroy()
end
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("HauntedTV_GUI") then
	playerGui:FindFirstChild("HauntedTV_GUI"):Destroy()
end
wait(0.15)

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
local tvFolder = Instance.new("Folder")
tvFolder.Name = "HauntedTV_Folder"
tvFolder.Parent = workspace

local placedTV = nil
local placedTVBasePos = nil
local placingMode = false
local previewModel = nil
local eventRunning = false
local tvRotation = 0
local guiMinimized = false

-- ============================================
-- SYSTÈME DE SONS
-- ============================================
--[[
    CATALOGUE DE SONS - IDs Roblox
    Pour changer un son, remplace juste l'ID
    Format : rbxassetid://NUMERO
]]

local SOUNDS = {
	-- === AMBIANCE ===
	tvStatic      = "rbxassetid://101950628492250",    -- Grésillement TV
	tvHum         = "rbxassetid://100092171472139"; --"rbxassetid://157843220",      -- Bourdonnement électrique
	ambientDread  = "rbxassetid://136842145725004",   -- Ambiance terrifiante
	heartbeat     = "rbxassetid://139481207162657",   -- Battement de coeur
	windHowl      = "rbxassetid://87881866459911",   -- Vent sinistre

	-- === CRÉATURE / MONSTRE ===
	creatureGrowl   = "rbxassetid://139934330820371",  -- Grognement créature
	creatureScream  = "rbxassetid://140028279221307",  -- Cri de créature
	demonRoar       = "rbxassetid://139756811230831",  -- Rugissement démoniaque
	monsterBreath   = "rbxassetid://9113984054",  -- Respiration lourde monstre
	footstepCreepy  = "rbxassetid://91493603199302",  -- Pas lourds creepy
	bonesCrack      = "rbxassetid://119056540163015",  -- Os qui craquent

	-- === JUMP SCARES / IMPACTS ===
	jumpScare1   = "rbxassetid://140669892908919",   -- Jump scare classique
	jumpScare2   = "rbxassetid://139051312337338",   -- Jump scare variant
	loudBang     = "rbxassetid://96203159091417",   -- Explosion / bang
	glassBreak   = "rbxassetid://138817960173178",   -- Verre qui casse
	metalImpact  = "rbxassetid://9117180053",   -- Impact métal

	-- === GLITCH / ÉLECTRIQUE ===
	glitchSound    = "rbxassetid://140346488699490",   -- Son glitch
	electricShock  = "rbxassetid://135103601014582",  -- Décharge électrique
	electricBuzz   = "rbxassetid://136758740736300",      -- Buzz électrique
	tvTurnOn       = "rbxassetid://132962839063890",   -- TV qui s'allume
	tvTurnOff      = "rbxassetid://132962839063890",  -- TV qui s'éteint

	-- === HORREUR ===
	whisper1     = "rbxassetid://139651609143656",   -- Chuchotement
	whisper2     = "rbxassetid://138342054751814",   -- Chuchotement variant
	childLaugh   = "rbxassetid://97815876592965",   -- Rire d'enfant sinistre
	screamFemale = "rbxassetid://80683978823486",   -- Cri féminin
	screamMale   = "rbxassetid://100643480811079",   -- Cri masculin
	cryingSound  = "rbxassetid://140620656253783",   -- Pleurs
	doorCreak    = "rbxassetid://99809341410998",   -- Porte qui grince

	-- === GAMEPLAY ===
	countdown    = "rbxassetid://134094893126219",   -- Bip compte à rebours
	warningAlarm = "rbxassetid://140047654906018",   -- Alarme d'avertissement
	deathSound   = "rbxassetid://140539866173088",   -- Son de mort
	vortexSound  = "rbxassetid://137345281743694",   -- Son vortex aspirant
	spiderSkitter = "rbxassetid://177429377",  -- Araignées qui grouillent
	bloodDrip    = "rbxassetid://136038559178753",   -- Gouttes de sang

	-- === MUSIQUE ===
	chaseMusic   = "rbxassetid://88275367596456",   -- Musique de poursuite
	horrorTheme  = "rbxassetid://97460960711268",   -- Thème horreur
	silenceAfter = "rbxassetid://140533822783920",   -- Silence pesant après événement
}

-- Conteneur de sons
local soundFolder = Instance.new("Folder")
soundFolder.Name = "HauntedTV_Sounds"
soundFolder.Parent = playerGui

-- Cache de sons créés
local soundCache = {}

local function playSound(soundId, config)
	config = config or {}
	local volume = config.volume or 1
	local pitch = config.pitch or 1
	local looped = config.looped or false
	local parent = config.parent or soundFolder
	local maxDist = config.maxDist or 100
	local is3D = config.position ~= nil
	local name = config.name or "HauntedSound"
	local fadeIn = config.fadeIn or 0
	local duration = config.duration or 0

	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = fadeIn > 0 and 0 or volume
	sound.PlaybackSpeed = pitch
	sound.Looped = looped

	if is3D then
		local part = Instance.new("Part")
		part.Size = Vector3.new(0.1, 0.1, 0.1)
		part.Position = config.position
		part.Anchored = true
		part.CanCollide = false
		part.Transparency = 1
		part.Parent = tvFolder
		sound.Parent = part

		sound.RollOffMaxDistance = maxDist
		sound.RollOffMinDistance = 5

		if not looped then
			Debris:AddItem(part, math.max(duration, 30))
		end
	else
		sound.Parent = parent
		if not looped then
			Debris:AddItem(sound, math.max(duration, 30))
		end
	end

	sound:Play()

	-- Fade in
	if fadeIn > 0 then
		spawn(function()
			local steps = math.floor(fadeIn / 0.05)
			for i = 1, steps do
				sound.Volume = (i / steps) * volume
				wait(0.05)
			end
			sound.Volume = volume
		end)
	end

	-- Auto-stop après durée
	if duration > 0 then
		spawn(function()
			wait(duration)
			if sound and sound.Parent then
				-- Fade out rapide
				for i = 10, 0, -1 do
					if sound and sound.Parent then
						sound.Volume = (i / 10) * volume
						wait(0.03)
					end
				end
				if sound and sound.Parent then
					sound:Stop()
					sound:Destroy()
				end
			end
		end)
	end

	return sound
end

local function stopSound(sound)
	if sound and sound.Parent then
		spawn(function()
			local vol = sound.Volume
			for i = 10, 0, -1 do
				if sound and sound.Parent then
					sound.Volume = (i / 10) * vol
					wait(0.03)
				end
			end
			if sound and sound.Parent then
				sound:Stop()
				if sound.Parent and sound.Parent:IsA("Part") and sound.Parent.Transparency == 1 then
					sound.Parent:Destroy()
				else
					sound:Destroy()
				end
			end
		end)
	end
end

local function stopAllSounds()
	for _, child in pairs(soundFolder:GetChildren()) do
		if child:IsA("Sound") then
			child:Stop()
			child:Destroy()
		end
	end
	-- Sons 3D dans tvFolder
	for _, desc in pairs(tvFolder:GetDescendants()) do
		if desc:IsA("Sound") then
			desc:Stop()
		end
	end
end

local function playTVSound(soundId, config)
	config = config or {}
	if placedTV then
		local tvBody = placedTV:FindFirstChild("TVBody")
		if tvBody then
			config.position = tvBody.Position
		end
	end
	return playSound(soundId, config)
end

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

local function moveParts(model, delta)
	if not model or not model.Parent then return end
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CFrame = part.CFrame + delta
		end
	end
end

local function setAllTransparency(model, t)
	if not model then return end
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "Aura" or part.Name == "Aura2" then
				part.Transparency = math.max(0.6, t)
			else
				part.Transparency = t
			end
		end
	end
end

local function getScreenLabel()
	if not placedTV then return nil end
	local screen = placedTV:FindFirstChild("TVScreen")
	if not screen then return nil end
	local gui = screen:FindFirstChild("ScreenGUI")
	if not gui then return nil end
	return gui:FindFirstChild("ScreenText")
end

local function setScreenText(text, color, bgColor)
	local label = getScreenLabel()
	if label then
		label.Text = text or ""
		if color then label.TextColor3 = color end
		if bgColor then label.BackgroundColor3 = bgColor end
	end
end

local function setScreenNeon(on)
	if not placedTV then return end
	local screen = placedTV:FindFirstChild("TVScreen")
	if screen then
		screen.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
		screen.BrickColor = on and BrickColor.new("Institutional white") or BrickColor.new("Dark stone grey")
	end
end

local function getPlayerPos()
	local c = player.Character
	if c and c:FindFirstChild("HumanoidRootPart") then
		return c.HumanoidRootPart.Position
	end
	return nil
end

local function getPlayerAlive()
	local c = player.Character
	if c and c:FindFirstChild("Humanoid") and c:FindFirstChild("HumanoidRootPart") then
		return c.Humanoid.Health > 0
	end
	return false
end

local function killPlayer()
	local c = player.Character
	if c and c:FindFirstChild("Humanoid") then
		playSound(SOUNDS.deathSound, {volume = 2, pitch = 0.8})
		c.Humanoid.Health = 0
	end
end

-- ============================================
-- EFFETS VISUELS
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HauntedTV_GUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local overlayFrame = Instance.new("Frame")
overlayFrame.Name = "Overlay"
overlayFrame.Size = UDim2.new(1, 0, 1, 0)
overlayFrame.BackgroundTransparency = 1
overlayFrame.ZIndex = 100
overlayFrame.Parent = screenGui

local function flashScreen(color, duration)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = color or Color3.fromRGB(255, 0, 0)
	flash.BackgroundTransparency = 0
	flash.ZIndex = 110
	flash.Parent = overlayFrame
	spawn(function()
		for i = 1, 20 do
			flash.BackgroundTransparency = i / 20
			wait((duration or 0.5) / 20)
		end
		flash:Destroy()
	end)
end

local function shakeScreen(intensity, duration)
	spawn(function()
		local t = 0
		while t < (duration or 1) do
			camera.CFrame = camera.CFrame * CFrame.new(
				math.random(-100,100)/100 * intensity,
				math.random(-100,100)/100 * intensity, 0)
			t = t + 0.03
			wait(0.03)
		end
	end)
end

local function glitchScreen(duration)
	spawn(function()
		local gf = Instance.new("Frame")
		gf.Size = UDim2.new(1,0,1,0)
		gf.BackgroundColor3 = Color3.fromRGB(0,0,0)
		gf.BackgroundTransparency = 0.7
		gf.ZIndex = 108
		gf.Parent = overlayFrame
		local t = 0
		while t < duration do
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(1,0,0,math.random(2,25))
			bar.Position = UDim2.new(0, math.random(-30,30), math.random(0,100)/100, 0)
			bar.BackgroundColor3 = Color3.fromRGB(math.random(150,255), math.random(0,30), math.random(0,30))
			bar.BackgroundTransparency = math.random(0,5)/10
			bar.ZIndex = 109
			bar.Parent = gf
			Debris:AddItem(bar, 0.1)
			gf.BackgroundTransparency = 0.4 + math.random(0,5)/10
			t = t + 0.05
			wait(0.05)
		end
		gf:Destroy()
	end)
end

local function redVignette(dur)
	local v = Instance.new("Frame")
	v.Size = UDim2.new(1,0,1,0)
	v.BackgroundColor3 = Color3.fromRGB(200,0,0)
	v.BackgroundTransparency = 0.5
	v.ZIndex = 107
	v.Parent = overlayFrame
	spawn(function()
		wait(dur or 1)
		for i = 0, 10 do
			v.BackgroundTransparency = 0.5 + i/20
			wait(0.05)
		end
		v:Destroy()
	end)
end

-- ============================================
-- CRÉATION DE LA TÉLÉ
-- ============================================

local function createTV(position, rotY)
	local tvModel = Instance.new("Model")
	tvModel.Name = "HauntedTV"

	local rotCF = CFrame.Angles(0, math.rad(rotY or 0), 0)
	local baseCF = CFrame.new(position) * rotCF

	local function mp(name, size, localPos, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = baseCF * CFrame.new(localPos)
		p.Anchored = true
		p.CanCollide = true
		p.BrickColor = BrickColor.new(color or "Really black")
		p.Material = material or Enum.Material.SmoothPlastic
		if shape then p.Shape = shape end
		p.Parent = tvModel
		return p
	end

	local body = mp("TVBody", Vector3.new(6, 4, 0.6), Vector3.new(0, 3, 0))
	mp("TVBorder", Vector3.new(5.6, 3.6, 0.1), Vector3.new(0, 3, 0.36), "Dark stone grey")

	local screen = mp("TVScreen", Vector3.new(5.2, 3.2, 0.08), Vector3.new(0, 3, 0.38), "Dark stone grey")
	screen.CanCollide = false

	local surfGui = Instance.new("SurfaceGui")
	surfGui.Name = "ScreenGUI"
	surfGui.Face = Enum.NormalId.Front
	surfGui.LightInfluence = 0
	surfGui.Parent = screen

	local sLabel = Instance.new("TextLabel")
	sLabel.Name = "ScreenText"
	sLabel.Size = UDim2.new(1,0,1,0)
	sLabel.BackgroundColor3 = Color3.fromRGB(10,10,10)
	sLabel.TextColor3 = Color3.fromRGB(255,255,255)
	sLabel.Text = ""
	sLabel.TextScaled = true
	sLabel.Font = Enum.Font.Code
	sLabel.Parent = surfGui

	mp("Btn1", Vector3.new(0.18,0.18,0.1), Vector3.new(2.7, 2.5, 0.36), "Medium stone grey")
	mp("Btn2", Vector3.new(0.18,0.18,0.1), Vector3.new(2.7, 2.8, 0.36), "Really red", Enum.Material.Neon)
	mp("Btn3", Vector3.new(0.18,0.18,0.1), Vector3.new(2.7, 3.1, 0.36), "Medium stone grey")

	mp("LegLeft", Vector3.new(0.3, 1.5, 0.3), Vector3.new(-2, 0.75, 0))
	mp("LegRight", Vector3.new(0.3, 1.5, 0.3), Vector3.new(2, 0.75, 0))
	mp("Base", Vector3.new(5, 0.25, 1.5), Vector3.new(0, 0.125, 0))

	local aL = mp("AntennaL", Vector3.new(0.08, 1.8, 0.08), Vector3.new(-1.3, 5.9, 0), "Medium stone grey", Enum.Material.Metal)
	aL.CFrame = aL.CFrame * CFrame.Angles(0, 0, math.rad(25))
	local aR = mp("AntennaR", Vector3.new(0.08, 1.8, 0.08), Vector3.new(1.3, 5.9, 0), "Medium stone grey", Enum.Material.Metal)
	aR.CFrame = aR.CFrame * CFrame.Angles(0, 0, math.rad(-25))

	mp("AntBall1", Vector3.new(0.22,0.22,0.22), Vector3.new(-1.7, 6.75, 0), "Really red", Enum.Material.Neon, Enum.PartType.Ball)
	mp("AntBall2", Vector3.new(0.22,0.22,0.22), Vector3.new(1.7, 6.75, 0), "Really red", Enum.Material.Neon, Enum.PartType.Ball)

	tvModel.PrimaryPart = body
	tvModel.Parent = tvFolder

	-- Son ambiant de la TV
	playTVSound(SOUNDS.tvHum, {volume = 0.3, looped = true, name = "TVHum", position = position + Vector3.new(0,3,0)})

	return tvModel
end

-- ============================================
-- PRÉVIEW
-- ============================================

local function createPreview()
	if previewModel then previewModel:Destroy() end
	previewModel = Instance.new("Model")
	previewModel.Name = "TVPreview"

	local pvBody = Instance.new("Part")
	pvBody.Name = "PVBody"
	pvBody.Size = Vector3.new(6, 4, 0.6)
	pvBody.Anchored = true
	pvBody.CanCollide = false
	pvBody.Transparency = 0.55
	pvBody.BrickColor = BrickColor.new("Really red")
	pvBody.Material = Enum.Material.Neon
	pvBody.CastShadow = false
	pvBody.Parent = previewModel

	local pvScreen = Instance.new("Part")
	pvScreen.Name = "PVScreen"
	pvScreen.Size = Vector3.new(5.2, 3.2, 0.08)
	pvScreen.Anchored = true
	pvScreen.CanCollide = false
	pvScreen.Transparency = 0.6
	pvScreen.BrickColor = BrickColor.new("Crimson")
	pvScreen.Material = Enum.Material.Neon
	pvScreen.Parent = previewModel

	local arrowShaft = Instance.new("Part")
	arrowShaft.Name = "ArrowShaft"
	arrowShaft.Size = Vector3.new(0.3, 0.15, 3)
	arrowShaft.Anchored = true
	arrowShaft.CanCollide = false
	arrowShaft.Transparency = 0.3
	arrowShaft.BrickColor = BrickColor.new("Lime green")
	arrowShaft.Material = Enum.Material.Neon
	arrowShaft.Parent = previewModel

	local arrowHead = Instance.new("WedgePart")
	arrowHead.Name = "ArrowHead"
	arrowHead.Size = Vector3.new(1, 0.15, 1.5)
	arrowHead.Anchored = true
	arrowHead.CanCollide = false
	arrowHead.Transparency = 0.3
	arrowHead.BrickColor = BrickColor.new("Lime green")
	arrowHead.Material = Enum.Material.Neon
	arrowHead.Parent = previewModel

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "RotateHint"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = pvBody
	billboard.Parent = previewModel

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Size = UDim2.new(1,0,1,0)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Text = "🔄 Appuyez R pour tourner"
	hintLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	hintLabel.TextStrokeTransparency = 0.3
	hintLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	hintLabel.TextScaled = true
	hintLabel.Font = Enum.Font.GothamBold
	hintLabel.Parent = billboard

	local angleLabel = Instance.new("TextLabel")
	angleLabel.Name = "AngleLabel"
	angleLabel.Size = UDim2.new(1,0,0.6,0)
	angleLabel.Position = UDim2.new(0,0,1,0)
	angleLabel.BackgroundTransparency = 1
	angleLabel.Text = "0°"
	angleLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	angleLabel.TextStrokeTransparency = 0.3
	angleLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	angleLabel.TextScaled = true
	angleLabel.Font = Enum.Font.GothamBold
	angleLabel.Parent = billboard

	previewModel.PrimaryPart = pvBody
	previewModel.Parent = tvFolder

	return previewModel
end

local function updatePreview(pos)
	if not previewModel then return end
	local pvBody = previewModel:FindFirstChild("PVBody")
	local pvScreen = previewModel:FindFirstChild("PVScreen")
	local arrow = previewModel:FindFirstChild("ArrowShaft")
	local arrowHead = previewModel:FindFirstChild("ArrowHead")
	if not pvBody then return end

	local rotCF = CFrame.Angles(0, math.rad(tvRotation), 0)
	local baseCF = CFrame.new(pos) * rotCF

	pvBody.CFrame = baseCF * CFrame.new(0, 3, 0)
	if pvScreen then pvScreen.CFrame = baseCF * CFrame.new(0, 3, 0.38) end
	if arrow then arrow.CFrame = baseCF * CFrame.new(0, 0.2, 2.5) end
	if arrowHead then arrowHead.CFrame = baseCF * CFrame.new(0, 0.2, 4.5) * CFrame.Angles(0, math.rad(180), 0) end

	local bb = previewModel:FindFirstChild("RotateHint")
	if bb then
		local al = bb:FindFirstChild("AngleLabel")
		if al then al.Text = tostring(math.floor(tvRotation)) .. "°" end
	end
end

local function destroyPreview()
	if previewModel then previewModel:Destroy(); previewModel = nil end
end

-- ============================================
-- CRÉATION DES MONSTRES
-- ============================================

local function createCreature(spawnPos, facingDir)
	local fig = Instance.new("Model")
	fig.Name = "CreepyFigure"

	local function mp(name, size, offset, col, mat, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(spawnPos + offset)
		p.Anchored = true
		p.CanCollide = false
		p.BrickColor = BrickColor.new(col or "Really black")
		p.Material = mat or Enum.Material.SmoothPlastic
		if shape then p.Shape = shape end
		p.Parent = fig
		return p
	end

	local torso = mp("Torso", Vector3.new(1.8, 3.2, 0.7), Vector3.new(0, 1.6, 0))
	local head = mp("Head", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 4.1, 0), "Really black", nil, Enum.PartType.Ball)
	mp("Mouth", Vector3.new(0.6, 0.08, 0.05), Vector3.new(0, 3.5, 0.7), "Dark stone grey")

	local armL = mp("ArmLeft", Vector3.new(0.4, 3.2, 0.4), Vector3.new(-1.3, 1.2, 0))
	local armR = mp("ArmRight", Vector3.new(0.4, 3.2, 0.4), Vector3.new(1.3, 1.2, 0))

	mp("HandL", Vector3.new(0.35, 0.35, 0.35), Vector3.new(-1.3, -0.5, 0), "Really black", nil, Enum.PartType.Ball)
	mp("HandR", Vector3.new(0.35, 0.35, 0.35), Vector3.new(1.3, -0.5, 0), "Really black", nil, Enum.PartType.Ball)

	for i = 1, 3 do
		mp("FingerL"..i, Vector3.new(0.06, 0.5, 0.06), Vector3.new(-1.3 - 0.12 + (i-1)*0.12, -0.9, 0.05), "Really black")
		mp("FingerR"..i, Vector3.new(0.06, 0.5, 0.06), Vector3.new(1.3 - 0.12 + (i-1)*0.12, -0.9, 0.05), "Really black")
	end

	local legL = mp("LegLeft", Vector3.new(0.5, 2.8, 0.5), Vector3.new(-0.45, -1.8, 0))
	local legR = mp("LegRight", Vector3.new(0.5, 2.8, 0.5), Vector3.new(0.45, -1.8, 0))

	mp("FootL", Vector3.new(0.55, 0.2, 0.9), Vector3.new(-0.45, -3.3, 0.2), "Really black")
	mp("FootR", Vector3.new(0.55, 0.2, 0.9), Vector3.new(0.45, -3.3, 0.2), "Really black")

	local aura = mp("Aura", Vector3.new(5, 7, 5), Vector3.new(0, 1, 0), "Really black", Enum.Material.ForceField, Enum.PartType.Ball)
	aura.Transparency = 0.8

	fig.PrimaryPart = torso
	fig.Parent = tvFolder

	return fig, {
		torso = torso, head = head,
		eyeL = nil, eyeR = nil,
		armL = armL, armR = armR,
		legL = legL, legR = legR,
		aura = aura
	}
end

local function createNightmare(spawnPos)
	local fig = Instance.new("Model")
	fig.Name = "NightmareMonster"

	local function mp(name, size, offset, col, mat, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = CFrame.new(spawnPos + offset)
		p.Anchored = true
		p.CanCollide = false
		p.BrickColor = BrickColor.new(col or "Crimson")
		p.Material = mat or Enum.Material.SmoothPlastic
		if shape then p.Shape = shape end
		p.Parent = fig
		return p
	end

	local torso = mp("Torso", Vector3.new(2.8, 4.5, 1.2), Vector3.new(0, 2.25, 0), "Crimson")

	for i = 1, 4 do
		mp("RibL"..i, Vector3.new(0.08, 0.12, 0.6), Vector3.new(-1.2, 3.5 - i*0.6, 0.3), "Maroon")
		mp("RibR"..i, Vector3.new(0.08, 0.12, 0.6), Vector3.new(1.2, 3.5 - i*0.6, 0.3), "Maroon")
	end

	for i = 1, 6 do
		mp("Spine"..i, Vector3.new(0.2, 0.2, 0.15), Vector3.new(0, 4.2 - i*0.55, -0.55), "Maroon", nil, Enum.PartType.Ball)
	end

	local head = mp("Head", Vector3.new(2.2, 2.2, 2), Vector3.new(0, 5.6, 0), "Crimson", nil, Enum.PartType.Ball)

	local eyeL = mp("EyeL", Vector3.new(0.35, 0.2, 0.15), Vector3.new(-0.4, 5.75, 0.9), "Really red", Enum.Material.Neon)
	local eyeR = mp("EyeR", Vector3.new(0.35, 0.2, 0.15), Vector3.new(0.4, 5.75, 0.9), "Really red", Enum.Material.Neon)

	mp("OrbitL", Vector3.new(0.5, 0.4, 0.1), Vector3.new(-0.4, 5.75, 0.85), "Really black")
	mp("OrbitR", Vector3.new(0.5, 0.4, 0.1), Vector3.new(0.4, 5.75, 0.85), "Really black")
	mp("MouthBG", Vector3.new(1.2, 0.5, 0.2), Vector3.new(0, 5.1, 0.85), "Really black")

	for i = 1, 6 do
		mp("ToothUp"..i, Vector3.new(0.1, 0.25, 0.08), Vector3.new(-0.55 + (i-1)*0.22, 5.25, 0.9), "Institutional white")
		mp("ToothDn"..i, Vector3.new(0.1, 0.2, 0.08), Vector3.new(-0.55 + (i-1)*0.22, 4.95, 0.9), "Institutional white")
	end

	local hornL1 = mp("HornL1", Vector3.new(0.25, 1.2, 0.25), Vector3.new(-0.7, 6.8, -0.1), "Maroon")
	hornL1.CFrame = hornL1.CFrame * CFrame.Angles(math.rad(-15), 0, math.rad(-20))
	local hornL2 = mp("HornL2", Vector3.new(0.18, 0.9, 0.18), Vector3.new(-1.1, 7.6, -0.3), "Maroon")
	hornL2.CFrame = hornL2.CFrame * CFrame.Angles(math.rad(-30), 0, math.rad(-35))
	mp("HornLTip", Vector3.new(0.1, 0.5, 0.1), Vector3.new(-1.4, 8.1, -0.5), "Really black")

	local hornR1 = mp("HornR1", Vector3.new(0.25, 1.2, 0.25), Vector3.new(0.7, 6.8, -0.1), "Maroon")
	hornR1.CFrame = hornR1.CFrame * CFrame.Angles(math.rad(-15), 0, math.rad(20))
	local hornR2 = mp("HornR2", Vector3.new(0.18, 0.9, 0.18), Vector3.new(1.1, 7.6, -0.3), "Maroon")
	hornR2.CFrame = hornR2.CFrame * CFrame.Angles(math.rad(-30), 0, math.rad(35))
	mp("HornRTip", Vector3.new(0.1, 0.5, 0.1), Vector3.new(1.4, 8.1, -0.5), "Really black")

	local armL = mp("ArmLeft", Vector3.new(0.6, 4.5, 0.6), Vector3.new(-2.2, 1.5, 0), "Crimson")
	local armR = mp("ArmRight", Vector3.new(0.6, 4.5, 0.6), Vector3.new(2.2, 1.5, 0), "Crimson")

	mp("ForeArmL", Vector3.new(0.5, 2.5, 0.5), Vector3.new(-2.5, -1.5, 0.3), "Crimson")
	mp("ForeArmR", Vector3.new(0.5, 2.5, 0.5), Vector3.new(2.5, -1.5, 0.3), "Crimson")
	mp("HandL", Vector3.new(0.55, 0.55, 0.55), Vector3.new(-2.6, -3, 0.4), "Maroon", nil, Enum.PartType.Ball)
	mp("HandR", Vector3.new(0.55, 0.55, 0.55), Vector3.new(2.6, -3, 0.4), "Maroon", nil, Enum.PartType.Ball)

	for c = 1, 5 do
		local clL = mp("ClawL"..c, Vector3.new(0.07, 0.8, 0.07), Vector3.new(-2.8 - c*0.08, -3.6, 0.15 + c*0.08), "Really black")
		clL.CFrame = clL.CFrame * CFrame.Angles(math.rad(25), 0, math.rad(10))
		local clR = mp("ClawR"..c, Vector3.new(0.07, 0.8, 0.07), Vector3.new(2.8 + c*0.08, -3.6, 0.15 + c*0.08), "Really black")
		clR.CFrame = clR.CFrame * CFrame.Angles(math.rad(25), 0, math.rad(-10))
	end

	local legL = mp("LegLeft", Vector3.new(0.75, 3.5, 0.75), Vector3.new(-0.7, -2.75, 0), "Crimson")
	local legR = mp("LegRight", Vector3.new(0.75, 3.5, 0.75), Vector3.new(0.7, -2.75, 0), "Crimson")

	mp("KneeL", Vector3.new(0.35, 0.35, 0.35), Vector3.new(-0.7, -1.5, 0.3), "Maroon", nil, Enum.PartType.Ball)
	mp("KneeR", Vector3.new(0.35, 0.35, 0.35), Vector3.new(0.7, -1.5, 0.3), "Maroon", nil, Enum.PartType.Ball)
	mp("FootL", Vector3.new(0.8, 0.4, 1.5), Vector3.new(-0.7, -4.7, 0.4), "Maroon")
	mp("FootR", Vector3.new(0.8, 0.4, 1.5), Vector3.new(0.7, -4.7, 0.4), "Maroon")

	for toe = 1, 3 do
		mp("ToeL"..toe, Vector3.new(0.08, 0.15, 0.4), Vector3.new(-0.9 + toe*0.2, -4.85, 1.3), "Really black")
		mp("ToeR"..toe, Vector3.new(0.08, 0.15, 0.4), Vector3.new(0.5 + toe*0.2, -4.85, 1.3), "Really black")
	end

		-- QUEUE - part du DOS (+Z = dos car -Z = visage après rotation)
	for seg = 1, 6 do
		local tailSeg = mp("Tail"..seg,
			Vector3.new(0.2 - seg*0.015, 0.2 - seg*0.015, 0.8),
			Vector3.new(0, 0.5 - seg*0.15, 0.6 + seg*0.7),
			"Crimson")
		tailSeg.CFrame = tailSeg.CFrame * CFrame.Angles(math.rad(-seg * 5), math.rad(-seg * 3), 0)
	end
	local tailTip = mp("TailTip", Vector3.new(0.35, 0.05, 0.5),
		Vector3.new(0, -0.5, 5), "Really black")
	tailTip.CFrame = tailTip.CFrame * CFrame.Angles(0, 0, math.rad(45))

	-- SPIKES - sur le dos aussi (+Z)
	for s = 1, 4 do
		local spike = mp("Spike"..s, Vector3.new(0.2, 1.0 + s*0.2, 0.2),
			Vector3.new(-0.6 + s*0.4, 3.8 + math.sin(s)*0.3, 0.7), "Maroon")
		spike.CFrame = spike.CFrame * CFrame.Angles(math.rad(-20 + math.random(-10,10)), 0, math.rad(math.random(-8,8)))
	end

	local aura = mp("Aura", Vector3.new(10, 12, 10), Vector3.new(0, 2, 0), "Really black", Enum.Material.ForceField, Enum.PartType.Ball)
	aura.Transparency = 0.7

	local aura2 = mp("Aura2", Vector3.new(7, 9, 7), Vector3.new(0, 2, 0), "Crimson", Enum.Material.ForceField, Enum.PartType.Ball)
	aura2.Transparency = 0.85

	fig.PrimaryPart = torso
	fig.Parent = tvFolder

	return fig, {
		torso = torso, head = head,
		eyeL = eyeL, eyeR = eyeR,
		armL = armL, armR = armR,
		legL = legL, legR = legR,
		aura = aura, aura2 = aura2
	}
end

-- ============================================
-- ROTATION HELPER (convention Roblox : -Z = front)
-- Le visage du monstre est sur +Z local, MAIS
-- ToEulerAnglesYXZ mesure le yaw par rapport à -Z (LookVector)
-- Donc pour orienter le visage (+Z) vers dir, on cible -dir
-- ============================================

local function rotateModelToward(model, pivotPart, targetPos, factor)
	if not model or not model.Parent or not pivotPart or not pivotPart.Parent then return end
	local myPos = pivotPart.Position
	local dir = (targetPos - myPos) * Vector3.new(1, 0, 1)
	if dir.Magnitude < 0.1 then return end
	dir = dir.Unit

	-- Visage = +Z, mais Roblox yaw convention = -Z
	-- Pour que +Z pointe vers dir, on fait atan2(-dir.X, -dir.Z)
	local targetAngle = math.atan2(-dir.X, -dir.Z)
	local _, currentAngle, _ = pivotPart.CFrame:ToEulerAnglesYXZ()
	local angleDiff = targetAngle - currentAngle
	while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
	while angleDiff < -math.pi do angleDiff = angleDiff + math.pi * 2 end

	local rotAmount = angleDiff * (factor or 0.25)
	if math.abs(rotAmount) < 0.001 then return end

	local pivot = pivotPart.Position
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local relPos = part.CFrame.Position - pivot
			local rotatedPos = CFrame.Angles(0, rotAmount, 0):PointToWorldSpace(relPos)
			part.CFrame = CFrame.new(pivot + rotatedPos) * (part.CFrame - part.CFrame.Position) * CFrame.Angles(0, rotAmount, 0)
		end
	end
end

local function forceRotateModelToward(model, pivotPart, targetPos)
	if not model or not model.Parent or not pivotPart or not pivotPart.Parent then return end
	local myPos = pivotPart.Position
	local dir = (targetPos - myPos) * Vector3.new(1, 0, 1)
	if dir.Magnitude < 0.1 then return end
	dir = dir.Unit

	local targetAngle = math.atan2(-dir.X, -dir.Z)
	local _, currentAngle, _ = pivotPart.CFrame:ToEulerAnglesYXZ()
	local angleDiff = targetAngle - currentAngle
	while angleDiff > math.pi do angleDiff = angleDiff - math.pi * 2 end
	while angleDiff < -math.pi do angleDiff = angleDiff + math.pi * 2 end

	if math.abs(angleDiff) < 0.01 then return end

	local pivot = pivotPart.Position
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local relPos = part.CFrame.Position - pivot
			local rotatedPos = CFrame.Angles(0, angleDiff, 0):PointToWorldSpace(relPos)
			part.CFrame = CFrame.new(pivot + rotatedPos) * (part.CFrame - part.CFrame.Position) * CFrame.Angles(0, angleDiff, 0)
		end
	end
end

-- ============================================
-- FONCTIONS D'ANIMATION
-- ============================================

local function animWalkStep(parts, model, targetPos, speed)
	if not parts.torso or not parts.torso.Parent then return false end

	local myPos = parts.torso.Position
	local dir = (targetPos - myPos) * Vector3.new(1, 0, 1)
	local dist = dir.Magnitude
	if dist < 0.5 then return true end
	dir = dir.Unit

	-- TOUJOURS avancer directement vers la cible
	moveParts(model, dir * speed)

	-- Rotation visuelle
	rotateModelToward(model, parts.torso, targetPos, 0.25)

	-- ANIMATIONS DE MARCHE
	local t = tick()
	local walkCycle = math.sin(t * 10)

	if parts.legL and parts.legL.Parent then
		local pos = parts.legL.Position
		local _, ry, _ = parts.legL.CFrame:ToEulerAnglesYXZ()
		parts.legL.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(walkCycle * 0.35, 0, 0)
	end
	if parts.legR and parts.legR.Parent then
		local pos = parts.legR.Position
		local _, ry, _ = parts.legR.CFrame:ToEulerAnglesYXZ()
		parts.legR.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-walkCycle * 0.35, 0, 0)
	end
	if parts.armL and parts.armL.Parent then
		local pos = parts.armL.Position
		local _, ry, _ = parts.armL.CFrame:ToEulerAnglesYXZ()
		parts.armL.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-walkCycle * 0.4, 0, math.rad(10))
	end
	if parts.armR and parts.armR.Parent then
		local pos = parts.armR.Position
		local _, ry, _ = parts.armR.CFrame:ToEulerAnglesYXZ()
		parts.armR.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(walkCycle * 0.4, 0, math.rad(-10))
	end

	if parts.eyeL and parts.eyeL.Parent then
		local eyeS = 0.35 + math.abs(math.sin(t*6)) * 0.1
		parts.eyeL.Size = Vector3.new(eyeS, eyeS, 0.15)
	end
	if parts.eyeR and parts.eyeR.Parent then
		local eyeS = 0.35 + math.abs(math.sin(t*6)) * 0.1
		parts.eyeR.Size = Vector3.new(eyeS, eyeS, 0.15)
	end

	if parts.aura and parts.aura.Parent then
		local s = 6 + math.sin(t*4)*1.5
		parts.aura.Size = Vector3.new(s, s+2, s)
		parts.aura.Transparency = 0.65 + math.sin(t*3)*0.1
	end
	if parts.aura2 and parts.aura2.Parent then
		local s = 8 + math.sin(t*4+1)*1
		parts.aura2.Size = Vector3.new(s, s+2, s)
	end

	return false
end

-- Animation SORTIE DE LA TÉLÉ
local function animExitTV(model, parts, tvModel)
	if not model or not model.Parent then return end
	if not tvModel or not tvModel.Parent then return end

	local tvScreen = tvModel:FindFirstChild("TVScreen")
	local tvBody = tvModel:FindFirstChild("TVBody")
	if not tvScreen or not tvBody then return end

	local front = -tvBody.CFrame.LookVector
	local right = tvBody.CFrame.RightVector
	local up = Vector3.new(0, 1, 0)

	local screenPos = tvScreen.Position
	local groundY = tvBody.Position.Y - 3

	local function cfAt(origin, x, y, z)
		return CFrame.lookAt(
			origin + right * x + up * y + front * z,
			origin + right * x + up * y + front * (z + 1),
			up
		)
	end

	local crawlCenter = screenPos - front * 3.6 + Vector3.new(0, -0.05, 0)
	local currentPos = parts.torso.Position
	moveParts(model, crawlCenter - currentPos)
	setAllTransparency(model, 1)

	local torsoLift = 0.72
	local headLift = 0.78
	local armLift = 0.34
	local legLift = 0.05
	local handLift = 0.30
	local footLift = -0.06

	if parts.torso and parts.torso.Parent then
		parts.torso.Size = Vector3.new(1.8, 0.7, 3.0)
		parts.torso.CFrame = cfAt(crawlCenter, 0, torsoLift, 0)
	end
	if parts.head and parts.head.Parent then
		parts.head.CFrame = cfAt(crawlCenter, 0, headLift, 2.0)
	end
	if parts.armL and parts.armL.Parent then
		parts.armL.Size = Vector3.new(0.4, 0.4, 2.6)
		parts.armL.CFrame = cfAt(crawlCenter, -0.85, armLift, 1.25)
	end
	if parts.armR and parts.armR.Parent then
		parts.armR.Size = Vector3.new(0.4, 0.4, 2.6)
		parts.armR.CFrame = cfAt(crawlCenter, 0.85, armLift, 1.25)
	end
	if parts.legL and parts.legL.Parent then
		parts.legL.Size = Vector3.new(0.5, 0.5, 2.4)
		parts.legL.CFrame = cfAt(crawlCenter, -0.42, legLift, -1.6)
	end
	if parts.legR and parts.legR.Parent then
		parts.legR.Size = Vector3.new(0.5, 0.5, 2.4)
		parts.legR.CFrame = cfAt(crawlCenter, 0.42, legLift, -1.6)
	end

	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name:find("Hand") or part.Name:find("Finger") or part.Name:find("Claw") then
				if part.Name:find("L") then
					part.CFrame = cfAt(crawlCenter, -1.15, handLift, 2.15)
				else
					part.CFrame = cfAt(crawlCenter, 1.15, handLift, 2.15)
				end
			elseif part.Name:find("Foot") or part.Name:find("Knee") or part.Name:find("Toe") then
				if part.Name:find("L") then
					part.CFrame = cfAt(crawlCenter, -0.45, footLift, -2.65)
				else
					part.CFrame = cfAt(crawlCenter, 0.45, footLift, -2.65)
				end
			elseif part.Name:find("Mouth") or part.Name:find("Eye") or part.Name:find("Pupil") or part.Name:find("Orbit") or part.Name:find("Tooth") then
				part.CFrame = cfAt(crawlCenter, 0, headLift, 2.25)
			end
		end
	end

	wait(0.25)

	-- Son de sortie TV
	playTVSound(SOUNDS.tvStatic, {volume = 1.5, pitch = 0.6, duration = 8})
	playTVSound(SOUNDS.creatureGrowl, {volume = 0.5, pitch = 0.5, duration = 5, fadeIn = 1})

	-- PHASE 1 : rampe vers l'écran
	for step = 1, 20 do
		if not model or not model.Parent then return end
		moveParts(model, front * 0.17)
		if parts.armL and parts.armL.Parent then
			parts.armL.CFrame = parts.armL.CFrame + front * (math.sin(step * 0.65) * 0.05)
		end
		if parts.armR and parts.armR.Parent then
			parts.armR.CFrame = parts.armR.CFrame + front * (math.sin(step * 0.65 + math.pi) * 0.05)
		end
		if step > 8 then
			setScreenText(string.rep("█", math.random(1, 4)), Color3.fromRGB(math.random(80, 150), 0, 0), Color3.fromRGB(math.random(0, 10), 0, 0))
			shakeScreen(0.08, 0.03)
		end
		wait(0.05)
	end

	-- PHASE 2 : bras sortent
	playTVSound(SOUNDS.bonesCrack, {volume = 1, pitch = 0.7, duration = 3})
	for step = 1, 18 do
		if not model or not model.Parent then return end
		if parts.armL and parts.armL.Parent then
			parts.armL.CFrame = parts.armL.CFrame + front * 0.10
			parts.armL.Transparency = math.max(0, 1 - step / 9)
		end
		if parts.armR and parts.armR.Parent then
			parts.armR.CFrame = parts.armR.CFrame + front * 0.10
			parts.armR.Transparency = math.max(0, 1 - step / 9)
		end
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name:find("Hand") or part.Name:find("Finger") or part.Name:find("Claw")) then
				part.CFrame = part.CFrame + front * 0.10
				part.Transparency = math.max(0, 1 - step / 9)
			end
		end
		if step > 7 then
			if parts.armL and parts.armL.Parent then parts.armL.CFrame = parts.armL.CFrame - right * 0.03 end
			if parts.armR and parts.armR.Parent then parts.armR.CFrame = parts.armR.CFrame + right * 0.03 end
		end
		setScreenText(string.rep("░", math.random(2, 8)), Color3.fromRGB(math.random(150, 255), 0, 0), Color3.fromRGB(math.random(0, 25), 0, 0))
		shakeScreen(0.12, 0.04)
		wait(0.06)
	end

	wait(0.6)

	-- PHASE 3 : tête sort
	playTVSound(SOUNDS.monsterBreath, {volume = 1.2, pitch = 0.6, duration = 6, fadeIn = 0.5})
	for step = 1, 22 do
		if not model or not model.Parent then return end
		if parts.head and parts.head.Parent then
			parts.head.CFrame = parts.head.CFrame + front * 0.12
			parts.head.Transparency = math.max(0, 1 - step / 11)
		end
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name:find("Mouth") or part.Name:find("Eye") or part.Name:find("Pupil") or part.Name:find("Orbit") or part.Name:find("Tooth")) then
				part.CFrame = part.CFrame + front * 0.12
				part.Transparency = math.max(0, 1 - step / 11)
			end
		end
		if parts.armL and parts.armL.Parent then
			parts.armL.CFrame = parts.armL.CFrame + Vector3.new(math.random(-4,4)/55, math.random(-4,4)/55, 0)
		end
		if parts.armR and parts.armR.Parent then
			parts.armR.CFrame = parts.armR.CFrame + Vector3.new(math.random(-4,4)/55, math.random(-4,4)/55, 0)
		end
		setScreenText(string.rep("▓", math.random(1, 10)), Color3.fromRGB(255, math.random(0, 40), math.random(0, 40)), Color3.fromRGB(math.random(0, 30), 0, 0))
		shakeScreen(step / 75, 0.04)
		wait(0.055)
	end

	flashScreen(Color3.fromRGB(200, 0, 0), 0.2)
	shakeScreen(0.5, 0.3)
	playSound(SOUNDS.jumpScare1, {volume = 1.5, pitch = 0.8, duration = 2})
	wait(0.3)

	-- PHASE 4 : torse sort
	for step = 1, 22 do
		if not model or not model.Parent then return end
		if parts.torso and parts.torso.Parent then
			parts.torso.CFrame = parts.torso.CFrame + front * 0.12
			parts.torso.Transparency = math.max(0, 1 - step / 11)
		end
		if parts.aura and parts.aura.Parent then
			parts.aura.CFrame = parts.aura.CFrame + front * 0.12
			parts.aura.Transparency = math.max(0.75, 1 - step / 30)
		end
		local pull = math.sin(step * 0.7) * 0.05
		if parts.armL and parts.armL.Parent then parts.armL.CFrame = parts.armL.CFrame + front * pull end
		if parts.armR and parts.armR.Parent then parts.armR.CFrame = parts.armR.CFrame + front * (-pull) end
		if parts.head and parts.head.Parent then parts.head.CFrame = parts.head.CFrame + front * 0.04 end
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name:find("Mouth") or part.Name:find("Eye") or part.Name:find("Tooth") or part.Name:find("Orbit") or part.Name:find("Pupil")) then
				part.CFrame = part.CFrame + front * 0.04
			end
		end
		shakeScreen(0.2, 0.04)
		wait(0.05)
	end

	-- PHASE 5 : jambes sortent
	playTVSound(SOUNDS.bonesCrack, {volume = 0.8, pitch = 0.5, duration = 2})
	for step = 1, 20 do
		if not model or not model.Parent then return end
		if parts.legL and parts.legL.Parent then
			parts.legL.CFrame = parts.legL.CFrame + front * 0.15
			parts.legL.Transparency = math.max(0, 1 - step / 10)
		end
		if parts.legR and parts.legR.Parent then
			parts.legR.CFrame = parts.legR.CFrame + front * 0.15
			parts.legR.Transparency = math.max(0, 1 - step / 10)
		end
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name:find("Foot") or part.Name:find("Knee") or part.Name:find("Toe")) then
				part.CFrame = part.CFrame + front * 0.15
				part.Transparency = math.max(0, 1 - step / 10)
			end
		end
		moveParts(model, front * 0.02)
		wait(0.05)
	end

	-- Retomber au sol
	local desiredCrawlY = groundY + 0.92
	local dropAmount = parts.torso.Position.Y - desiredCrawlY
	if math.abs(dropAmount) > 0.05 then
		for i = 1, 16 do
			if not model or not model.Parent then return end
			moveParts(model, Vector3.new(0, -dropAmount / 16, 0))
			wait(0.03)
		end
	end

	wait(0.45)

	-- PHASE 6 : Se relever
	playTVSound(SOUNDS.bonesCrack, {volume = 1.2, pitch = 0.4, duration = 3})
	local _, yaw, _ = parts.torso.CFrame:ToEulerAnglesYXZ()

	if parts.torso and parts.torso.Parent then parts.torso.Size = Vector3.new(1.8, 3.2, 0.7) end
	if parts.armL and parts.armL.Parent then parts.armL.Size = Vector3.new(0.4, 3.2, 0.4) end
	if parts.armR and parts.armR.Parent then parts.armR.Size = Vector3.new(0.4, 3.2, 0.4) end
	if parts.legL and parts.legL.Parent then parts.legL.Size = Vector3.new(0.5, 2.8, 0.5) end
	if parts.legR and parts.legR.Parent then parts.legR.Size = Vector3.new(0.5, 2.8, 0.5) end

	local torsoH = parts.torso.Size.Y
	local legH = parts.legL and parts.legL.Size.Y or 2.8
	local headR = parts.head and parts.head.Size.Y / 2 or 0.75

	local feetY = groundY + 0.1
	local torsoY = feetY + legH + torsoH / 2
	local currentY = parts.torso.Position.Y
	local riseNeeded = torsoY - currentY

	for step = 1, 35 do
		if not model or not model.Parent then return end
		moveParts(model, Vector3.new(0, riseNeeded / 35, 0))
		if step % 5 == 0 then shakeScreen(step/35 * 0.2, 0.05) end
		wait(0.06)
	end

	local torsoPos = parts.torso.Position
	local faceCF = CFrame.new(torsoPos) * CFrame.Angles(0, yaw, 0)
	local fwd = faceCF.LookVector
	local rt = faceCF.RightVector

	if parts.head and parts.head.Parent then
		parts.head.CFrame = CFrame.new(torsoPos + Vector3.new(0, torsoH / 2 + headR + 0.15, 0))
	end
	if parts.armL and parts.armL.Parent then
		parts.armL.CFrame = CFrame.new(torsoPos + rt * (-1.3) + Vector3.new(0, -0.3, 0)) * CFrame.Angles(0, yaw, 0)
	end
	if parts.armR and parts.armR.Parent then
		parts.armR.CFrame = CFrame.new(torsoPos + rt * 1.3 + Vector3.new(0, -0.3, 0)) * CFrame.Angles(0, yaw, 0)
	end
	if parts.legL and parts.legL.Parent then
		parts.legL.CFrame = CFrame.new(torsoPos + rt * (-0.45) + Vector3.new(0, -torsoH / 2 - legH / 2, 0)) * CFrame.Angles(0, yaw, 0)
	end
	if parts.legR and parts.legR.Parent then
		parts.legR.CFrame = CFrame.new(torsoPos + rt * 0.45 + Vector3.new(0, -torsoH / 2 - legH / 2, 0)) * CFrame.Angles(0, yaw, 0)
	end

	if parts.head and parts.head.Parent then
		local headPos = parts.head.Position
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				if part.Name:find("Mouth") or part.Name:find("Tooth") then
					part.CFrame = CFrame.new(headPos + fwd * 0.7 + Vector3.new(0, -0.5, 0))
				elseif part.Name:find("Eye") or part.Name:find("Pupil") or part.Name:find("Orbit") then
					local isLeft = part.Name:find("L")
					local side = isLeft and -0.35 or 0.35
					part.CFrame = CFrame.new(headPos + fwd * 0.7 + rt * side + Vector3.new(0, 0.1, 0))
				end
			end
		end
	end

	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name:find("Hand") or part.Name:find("Finger") or part.Name:find("Claw") then
				local isLeft = part.Name:find("L")
				local armPart = isLeft and parts.armL or parts.armR
				if armPart and armPart.Parent then
					part.CFrame = CFrame.new(armPart.Position + Vector3.new(0, -armPart.Size.Y / 2 - 0.2, 0))
				end
			elseif part.Name:find("Foot") or part.Name:find("Toe") or part.Name:find("Knee") then
				local isLeft = part.Name:find("L")
				local legPart = isLeft and parts.legL or parts.legR
				if legPart and legPart.Parent then
					part.CFrame = CFrame.new(legPart.Position + Vector3.new(0, -legPart.Size.Y / 2 - 0.1, 0) + fwd * 0.2)
				end
			end
		end
	end

	if parts.aura and parts.aura.Parent then parts.aura.CFrame = CFrame.new(torsoPos) end

	setAllTransparency(model, 0)
	if parts.aura then parts.aura.Transparency = 0.75 end

	flashScreen(Color3.fromRGB(255, 0, 0), 0.35)
	shakeScreen(0.7, 0.45)
	playSound(SOUNDS.creatureScream, {volume = 2, pitch = 0.6, duration = 3})
end

-- Animation TV SE TRANSFORME
local function animTVTransform(tvModel)
	if not tvModel or not tvModel.Parent then return end
	local tvBody = tvModel:FindFirstChild("TVBody")
	if not tvBody then return end

	for _, name in pairs({"LegLeft","LegRight","Base"}) do
		local p = tvModel:FindFirstChild(name)
		if p then p:Destroy() end
	end

	playTVSound(SOUNDS.metalImpact, {volume = 1.5, pitch = 0.5, duration = 3})
	playTVSound(SOUNDS.glitchSound, {volume = 1, pitch = 0.3, duration = 4})

	for shake = 1, 30 do
		local s = Vector3.new(math.random(-8,8)/20, math.random(-6,6)/20, math.random(-8,8)/20)
		moveParts(tvModel, s)
		wait(0.04)
		moveParts(tvModel, -s)
	end

	local bodyCF = tvBody.CFrame
	local chunks = {}

	local chunkLL = Instance.new("Part"); chunkLL.Name = "ChunkLL"; chunkLL.Size = Vector3.new(0.8,0.5,0.5)
	chunkLL.CFrame = bodyCF * CFrame.new(-2,-1.5,0); chunkLL.Anchored = true; chunkLL.CanCollide = false
	chunkLL.BrickColor = BrickColor.new("Really black"); chunkLL.Parent = tvModel
	table.insert(chunks, {part = chunkLL, targetLocalPos = Vector3.new(-1.5,-3.5,0), targetSize = Vector3.new(0.7,3,0.7)})

	local chunkLR = Instance.new("Part"); chunkLR.Name = "ChunkLR"; chunkLR.Size = Vector3.new(0.8,0.5,0.5)
	chunkLR.CFrame = bodyCF * CFrame.new(2,-1.5,0); chunkLR.Anchored = true; chunkLR.CanCollide = false
	chunkLR.BrickColor = BrickColor.new("Really black"); chunkLR.Parent = tvModel
	table.insert(chunks, {part = chunkLR, targetLocalPos = Vector3.new(1.5,-3.5,0), targetSize = Vector3.new(0.7,3,0.7)})

	local chunkAL = Instance.new("Part"); chunkAL.Name = "ChunkAL"; chunkAL.Size = Vector3.new(0.5,0.8,0.5)
	chunkAL.CFrame = bodyCF * CFrame.new(-2.8,0.5,0); chunkAL.Anchored = true; chunkAL.CanCollide = false
	chunkAL.BrickColor = BrickColor.new("Really black"); chunkAL.Parent = tvModel
	table.insert(chunks, {part = chunkAL, targetLocalPos = Vector3.new(-4,0,0), targetSize = Vector3.new(0.55,3,0.55)})

	local chunkAR = Instance.new("Part"); chunkAR.Name = "ChunkAR"; chunkAR.Size = Vector3.new(0.5,0.8,0.5)
	chunkAR.CFrame = bodyCF * CFrame.new(2.8,0.5,0); chunkAR.Anchored = true; chunkAR.CanCollide = false
	chunkAR.BrickColor = BrickColor.new("Really black"); chunkAR.Parent = tvModel
	table.insert(chunks, {part = chunkAR, targetLocalPos = Vector3.new(4,0,0), targetSize = Vector3.new(0.55,3,0.55)})

	flashScreen(Color3.fromRGB(100,0,0), 0.3); shakeScreen(0.8, 1)
	playSound(SOUNDS.bonesCrack, {volume = 1.5, pitch = 0.4, duration = 2})

	for d = 1, 15 do
		local debris = Instance.new("Part"); debris.Size = Vector3.new(0.15,0.15,0.15)
		debris.CFrame = bodyCF * CFrame.new(math.random(-3,3),math.random(-2,2),math.random(-1,1))
		debris.Anchored = false; debris.CanCollide = false; debris.BrickColor = BrickColor.new("Really black")
		debris.Velocity = Vector3.new(math.random(-15,15),math.random(5,20),math.random(-15,15))
		debris.Parent = tvFolder; Debris:AddItem(debris, 2)
	end

	for animStep = 1, 30 do
		local progress = animStep / 30
		for _, chunk in pairs(chunks) do
			if chunk.part and chunk.part.Parent then
				local targetPos = bodyCF * CFrame.new(chunk.targetLocalPos)
				chunk.part.CFrame = chunk.part.CFrame:Lerp(targetPos, progress * 0.15)
				chunk.part.Size = Vector3.new(0.5,0.5,0.5):Lerp(chunk.targetSize, progress)
			end
		end
		tvBody.Size = Vector3.new(6 - progress * 0.4, 4 - progress * 0.2, 0.6)
		wait(0.04)
	end

	chunkLL.Name = "TVLegL"; chunkLR.Name = "TVLegR"; chunkAL.Name = "TVArmL"; chunkAR.Name = "TVArmR"

	local footL = Instance.new("Part"); footL.Name = "TVFootL"; footL.Size = Vector3.new(0.9,0.4,1.5)
	footL.CFrame = chunkLL.CFrame * CFrame.new(0,-1.7,0.4); footL.Anchored = true; footL.CanCollide = false
	footL.BrickColor = BrickColor.new("Really black"); footL.Parent = tvModel

	local footR = Instance.new("Part"); footR.Name = "TVFootR"; footR.Size = Vector3.new(0.9,0.4,1.5)
	footR.CFrame = chunkLR.CFrame * CFrame.new(0,-1.7,0.4); footR.Anchored = true; footR.CanCollide = false
	footR.BrickColor = BrickColor.new("Really black"); footR.Parent = tvModel

	local handL = Instance.new("Part"); handL.Name = "TVHandL"; handL.Shape = Enum.PartType.Ball
	handL.Size = Vector3.new(0.9,0.9,0.9); handL.CFrame = chunkAL.CFrame * CFrame.new(0,-1.8,0)
	handL.Anchored = true; handL.CanCollide = false; handL.BrickColor = BrickColor.new("Really black"); handL.Parent = tvModel

	local handR = Instance.new("Part"); handR.Name = "TVHandR"; handR.Shape = Enum.PartType.Ball
	handR.Size = Vector3.new(0.9,0.9,0.9); handR.CFrame = chunkAR.CFrame * CFrame.new(0,-1.8,0)
	handR.Anchored = true; handR.CanCollide = false; handR.BrickColor = BrickColor.new("Really black"); handR.Parent = tvModel

	setScreenText("👁️  👁️", Color3.fromRGB(255,0,0), Color3.fromRGB(0,0,0))
	playSound(SOUNDS.creatureGrowl, {volume = 1.5, pitch = 0.3, duration = 3})

	return {legL=chunkLL, legR=chunkLR, armL=chunkAL, armR=chunkAR, footL=footL, footR=footR, handL=handL, handR=handR}
end

-- Animation MONSTRE SORT DU SOL (Event 15)
local function animRiseFromGround(model, parts, tvModel)
	if not tvModel or not tvModel.Parent then return end
	local tvBody = tvModel:FindFirstChild("TVBody")
	if not tvBody then return end
	local tvPos = tvBody.Position

	local frontDir = -tvBody.CFrame.LookVector
	local rightDir = tvBody.CFrame.RightVector
	local groundY = tvBody.Position.Y - 3

	local spawnDistance = 8
	local crackCenter = tvPos + frontDir * spawnDistance

	local function moveModelToPos(targetPos)
		if parts.torso and parts.torso.Parent then
			moveParts(model, targetPos - parts.torso.Position)
		end
	end

	moveModelToPos(crackCenter + Vector3.new(0, -10, 0))
	setAllTransparency(model, 0.85)

	-- Orienter dos à la TV au début
	if parts.torso and parts.torso.Parent then
		forceRotateModelToward(model, parts.torso, crackCenter + frontDir * 5)
	end

	-- Phase 1 : Fissures
	playTVSound(SOUNDS.ambientDread, {volume = 1.5, looped = false, duration = 20, fadeIn = 2, name = "DreadAmbient"})

	local cracks = {}
	for i = 1, 8 do
		local crack = Instance.new("Part")
		crack.Size = Vector3.new(0.1, 0.05, math.random(2, 5))
		crack.CFrame = CFrame.new(crackCenter.X + math.random(-3,3), groundY + 0.05, crackCenter.Z + math.random(-3,3))
			* CFrame.Angles(0, math.rad(math.random(0,360)), 0)
		crack.Anchored = true; crack.CanCollide = false
		crack.BrickColor = BrickColor.new("Really red"); crack.Material = Enum.Material.Neon
		crack.Parent = tvFolder; table.insert(cracks, crack)
		shakeScreen(0.15, 0.1)
		playSound(SOUNDS.metalImpact, {volume = 0.5 + i*0.1, pitch = 0.3 + math.random()*0.3, duration = 1, position = crackCenter})
		wait(0.12)
	end

	-- Phase 2 : Montée du sol
	playSound(SOUNDS.demonRoar, {volume = 0.8, pitch = 0.3, duration = 6, fadeIn = 2, position = crackCenter})

	for rise = 1, 55 do
		if not model or not model.Parent then break end
		moveParts(model, Vector3.new(0, 0.19, 0))

		local emerged = rise / 55
		setAllTransparency(model, math.max(0, 0.85 - emerged * 0.85))
		if parts.aura and parts.aura.Parent then parts.aura.Transparency = math.max(0.7, 1 - emerged * 0.35) end
		if parts.aura2 and parts.aura2.Parent then parts.aura2.Transparency = math.max(0.85, 1 - emerged * 0.18) end

		if emerged > 0.25 then
			if parts.armL and parts.armL.Parent then
				local pos = parts.armL.Position
				local _, ry, _ = parts.armL.CFrame:ToEulerAnglesYXZ()
				parts.armL.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(math.sin(rise * 0.45) * 0.12, 0, 0)
			end
			if parts.armR and parts.armR.Parent then
				local pos = parts.armR.Position
				local _, ry, _ = parts.armR.CFrame:ToEulerAnglesYXZ()
				parts.armR.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-math.sin(rise * 0.45) * 0.12, 0, 0)
			end
		end

		if rise % 5 == 0 then
			for d = 1, 3 do
				local debris = Instance.new("Part")
				debris.Size = Vector3.new(math.random()*0.5+0.1, math.random()*0.5+0.1, math.random()*0.5+0.1)
				debris.CFrame = CFrame.new(crackCenter.X + math.random(-3,3), groundY + 0.2, crackCenter.Z + math.random(-3,3))
				debris.Anchored = false; debris.CanCollide = false; debris.BrickColor = BrickColor.new("Dark stone grey")
				debris.Velocity = Vector3.new(math.random(-10,10), math.random(15,35), math.random(-10,10))
				debris.Parent = tvFolder; Debris:AddItem(debris, 3)
			end
		end

		if rise % 4 == 0 then
			setScreenText(string.rep("░", math.random(2,10)), Color3.fromRGB(math.random(100,255),0,math.random(0,50)), Color3.fromRGB(math.random(0,20),0,0))
		end

		shakeScreen(emerged * 0.55, 0.05)
		wait(0.05)
	end

	-- Repositionner correctement debout
	if parts.torso and parts.torso.Parent then
		local torsoH = parts.torso.Size.Y
		local legH = parts.legL and parts.legL.Size.Y or 3.5
		local headR = parts.head and parts.head.Size.Y / 2 or 1.1

		local feetY = groundY + 0.1
		local wantedTorsoY = feetY + legH + torsoH / 2
		local diffY = wantedTorsoY - parts.torso.Position.Y
		moveParts(model, Vector3.new(0, diffY, 0))

		local torsoPos = parts.torso.Position
		local _, yaw, _ = parts.torso.CFrame:ToEulerAnglesYXZ()
		local faceCF = CFrame.new(torsoPos) * CFrame.Angles(0, yaw, 0)
		local fwd = faceCF.LookVector
		local rt = faceCF.RightVector

		if parts.head and parts.head.Parent then
			parts.head.CFrame = CFrame.new(torsoPos + Vector3.new(0, torsoH/2 + headR + 0.15, 0))
		end
		if parts.armL and parts.armL.Parent then
			parts.armL.CFrame = CFrame.new(torsoPos + rt * (-2.2) + Vector3.new(0,-0.3,0)) * CFrame.Angles(0, yaw, 0)
		end
		if parts.armR and parts.armR.Parent then
			parts.armR.CFrame = CFrame.new(torsoPos + rt * 2.2 + Vector3.new(0,-0.3,0)) * CFrame.Angles(0, yaw, 0)
		end
		if parts.legL and parts.legL.Parent then
			parts.legL.CFrame = CFrame.new(torsoPos + rt * (-0.7) + Vector3.new(0, -torsoH/2 - legH/2, 0)) * CFrame.Angles(0, yaw, 0)
		end
		if parts.legR and parts.legR.Parent then
			parts.legR.CFrame = CFrame.new(torsoPos + rt * 0.7 + Vector3.new(0, -torsoH/2 - legH/2, 0)) * CFrame.Angles(0, yaw, 0)
		end

		if parts.head and parts.head.Parent then
			local headPos = parts.head.Position
			for _, part in pairs(model:GetDescendants()) do
				if part:IsA("BasePart") then
					if part.Name:find("Mouth") or part.Name:find("Tooth") then
						part.CFrame = CFrame.new(headPos + fwd * 0.85 + Vector3.new(0,-0.5,0))
					elseif part.Name:find("Eye") or part.Name:find("Pupil") or part.Name:find("Orbit") then
						local isLeft = part.Name:find("L")
						local side = isLeft and -0.4 or 0.4
						part.CFrame = CFrame.new(headPos + fwd * 0.85 + rt * side + Vector3.new(0,0.1,0))
					elseif part.Name:find("Horn") then
						local isLeft = part.Name:find("L")
						local side = isLeft and -0.7 or 0.7
						local height = part.Name:find("2") and 1.8 or 1.2
						if part.Name:find("Tip") then height = 2.2; side = isLeft and -1.4 or 1.4 end
						part.CFrame = CFrame.new(headPos + rt * side + Vector3.new(0, height, 0) - fwd * 0.1)
					end
				end
			end
		end

		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				if part.Name:find("Hand") or part.Name:find("Claw") or part.Name:find("ForeArm") then
					local isLeft = part.Name:find("L")
					local armPart = isLeft and parts.armL or parts.armR
					if armPart and armPart.Parent then
						part.CFrame = CFrame.new(armPart.Position + Vector3.new(0, -armPart.Size.Y/2 - 0.3, 0))
					end
				elseif part.Name:find("Foot") or part.Name:find("Toe") or part.Name:find("Knee") then
					local isLeft = part.Name:find("L")
					local legPart = isLeft and parts.legL or parts.legR
					if legPart and legPart.Parent then
						part.CFrame = CFrame.new(legPart.Position + Vector3.new(0, -legPart.Size.Y/2 - 0.1, 0) + fwd * 0.2)
					end
				end
			end
		end

		if parts.aura and parts.aura.Parent then parts.aura.CFrame = CFrame.new(torsoPos) end
		if parts.aura2 and parts.aura2.Parent then parts.aura2.CFrame = CFrame.new(torsoPos) end
	end

	setAllTransparency(model, 0)
	if parts.aura then parts.aura.Transparency = 0.7 end
	if parts.aura2 then parts.aura2.Transparency = 0.85 end

	playSound(SOUNDS.creatureScream, {volume = 2.5, pitch = 0.4, duration = 4})
	wait(0.5)

	-- Phase 3 : Se retourne vers la TV
	setScreenText("NON!", Color3.fromRGB(255,0,0), Color3.fromRGB(60,0,0))
	wait(0.3)

	for turnStep = 1, 30 do
		if not model or not model.Parent then break end
		if not parts.torso or not parts.torso.Parent then break end
		rotateModelToward(model, parts.torso, tvPos, 0.25)
		wait(0.04)
	end

	wait(0.2)

	-- Phase 4 : Marche vers la TV
	playSound(SOUNDS.footstepCreepy, {volume = 1, pitch = 0.4, looped = true, name = "MonsterSteps", duration = 8})

	for approach = 1, 22 do
		if not model or not model.Parent then break end
		if not parts.torso or not parts.torso.Parent then break end

		local toTV = (tvPos - parts.torso.Position) * Vector3.new(1,0,1)
		if toTV.Magnitude > 2.5 then
			local dir = toTV.Unit
			moveParts(model, dir * 0.35)
			rotateModelToward(model, parts.torso, tvPos, 0.3)

			local walk = math.sin(approach * 0.9)
			if parts.legL and parts.legL.Parent then
				local pos = parts.legL.Position; local _, ry, _ = parts.legL.CFrame:ToEulerAnglesYXZ()
				parts.legL.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(walk * 0.3, 0, 0)
			end
			if parts.legR and parts.legR.Parent then
				local pos = parts.legR.Position; local _, ry, _ = parts.legR.CFrame:ToEulerAnglesYXZ()
				parts.legR.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-walk * 0.3, 0, 0)
			end
			if parts.armL and parts.armL.Parent then
				local pos = parts.armL.Position; local _, ry, _ = parts.armL.CFrame:ToEulerAnglesYXZ()
				parts.armL.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-walk * 0.25, 0, 0)
			end
			if parts.armR and parts.armR.Parent then
				local pos = parts.armR.Position; local _, ry, _ = parts.armR.CFrame:ToEulerAnglesYXZ()
				parts.armR.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(walk * 0.25, 0, 0)
			end
		end
		wait(0.045)
	end

	-- Phase 5 : Frappe la TV
	for windUp = 1, 10 do
		if not model or not model.Parent then break end
		if parts.armL and parts.armL.Parent then parts.armL.CFrame = parts.armL.CFrame * CFrame.Angles(-0.08, 0, 0) end
		if parts.armR and parts.armR.Parent then parts.armR.CFrame = parts.armR.CFrame * CFrame.Angles(-0.08, 0, 0) end
		wait(0.03)
	end

	wait(0.15)
	playSound(SOUNDS.loudBang, {volume = 3, pitch = 0.5, duration = 3})
	playSound(SOUNDS.glassBreak, {volume = 2, pitch = 0.7, duration = 2})

	for strike = 1, 5 do
		if parts.armL and parts.armL.Parent then parts.armL.CFrame = parts.armL.CFrame * CFrame.Angles(0.2, 0, 0) end
		if parts.armR and parts.armR.Parent then parts.armR.CFrame = parts.armR.CFrame * CFrame.Angles(0.2, 0, 0) end
		wait(0.02)
	end

	flashScreen(Color3.fromRGB(255, 100, 0), 0.5); shakeScreen(2, 1)

	local tvPartsTable = {}
	for _, part in pairs(tvModel:GetDescendants()) do
		if part:IsA("BasePart") then table.insert(tvPartsTable, part) end
	end
	for idx, part in ipairs(tvPartsTable) do
		if idx <= #tvPartsTable / 2 and part.Name ~= "TVBody" and part.Name ~= "TVScreen" then
			local clone = part:Clone(); clone.Anchored = false; clone.CanCollide = true
			clone.Velocity = Vector3.new(math.random(-30,30), math.random(10,40), math.random(-30,30))
			clone.RotVelocity = Vector3.new(math.random(-10,10), math.random(-10,10), math.random(-10,10))
			clone.Parent = tvFolder; Debris:AddItem(clone, 5)
		end
	end

	setScreenText("████\n████\n████", Color3.fromRGB(0,0,0), Color3.fromRGB(30,30,30))

	for d = 1, 20 do
		local debris = Instance.new("Part")
		debris.Size = Vector3.new(math.random()*0.8+0.1, math.random()*0.8+0.1, math.random()*0.8+0.1)
		debris.CFrame = CFrame.new(tvPos + Vector3.new(math.random(-2,2), math.random(0,3), math.random(-2,2)))
		debris.Anchored = false; debris.CanCollide = true
		debris.BrickColor = BrickColor.new(math.random() > 0.5 and "Really black" or "Dark stone grey")
		debris.Velocity = Vector3.new(math.random(-25,25), math.random(10,30), math.random(-25,25))
		debris.Parent = tvFolder; Debris:AddItem(debris, 6)
	end

	for _, crack in pairs(cracks) do if crack and crack.Parent then Debris:AddItem(crack, 3) end end

	-- Phase 6 : Se retourne LENTEMENT vers le joueur
	wait(1)
	setScreenText("derrière toi...", Color3.fromRGB(100,0,0), Color3.fromRGB(10,0,0))
	playSound(SOUNDS.whisper1, {volume = 2, pitch = 0.5, duration = 4})
	playSound(SOUNDS.heartbeat, {volume = 1.5, looped = true, name = "Heartbeat", duration = 15})

	for turnStep = 1, 40 do
		if not model or not model.Parent then break end
		if not parts.torso or not parts.torso.Parent then break end

		local pPos = getPlayerPos()
		if pPos then
			rotateModelToward(model, parts.torso, pPos, 0.06)
		end

		if turnStep % 10 == 0 then shakeScreen(0.1, 0.08) end

		if parts.eyeL and parts.eyeL.Parent then
			local eyeS = 0.35 + math.abs(math.sin(tick() * 2)) * 0.15
			parts.eyeL.Size = Vector3.new(eyeS, eyeS * 0.6, 0.15)
		end
		if parts.eyeR and parts.eyeR.Parent then
			local eyeS = 0.35 + math.abs(math.sin(tick() * 2)) * 0.15
			parts.eyeR.Size = Vector3.new(eyeS, eyeS * 0.6, 0.15)
		end

		wait(0.08)
	end

	wait(0.5)

	-- Tête penchée (creepy)
	playSound(SOUNDS.bonesCrack, {volume = 0.8, pitch = 0.3, duration = 2})
	if parts.head and parts.head.Parent then
		for tilt = 1, 12 do
			if not model or not model.Parent then break end
			parts.head.CFrame = parts.head.CFrame * CFrame.Angles(0, 0, math.rad(1.5))
			for _, part in pairs(model:GetDescendants()) do
				if part:IsA("BasePart") and (part.Name:find("Eye") or part.Name:find("Mouth") or part.Name:find("Tooth") or part.Name:find("Orbit") or part.Name:find("Pupil") or part.Name:find("Horn")) then
					part.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(1.5))
				end
			end
			wait(0.05)
		end
	end

	wait(1.2)

	flashScreen(Color3.fromRGB(255,0,0), 0.3)
	setScreenText("COURS.", Color3.fromRGB(255,0,0), Color3.fromRGB(0,0,0))
	shakeScreen(0.5, 0.5)
	playSound(SOUNDS.jumpScare2, {volume = 2.5, pitch = 0.6, duration = 2})
	playSound(SOUNDS.demonRoar, {volume = 2, pitch = 0.5, duration = 3})

	-- Remet la tête droite
	if parts.head and parts.head.Parent then
		for tilt = 1, 12 do
			if not model or not model.Parent then break end
			parts.head.CFrame = parts.head.CFrame * CFrame.Angles(0, 0, math.rad(-1.5))
			for _, part in pairs(model:GetDescendants()) do
				if part:IsA("BasePart") and (part.Name:find("Eye") or part.Name:find("Mouth") or part.Name:find("Tooth") or part.Name:find("Orbit") or part.Name:find("Pupil") or part.Name:find("Horn")) then
					part.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(-1.5))
				end
			end
			wait(0.025)
		end
	end

	wait(0.3)
end

-- ============================================
-- GUI PRINCIPAL
-- ============================================

local guiContainer = Instance.new("Frame")
guiContainer.Name = "GUIContainer"
guiContainer.Size = UDim2.new(0, 310, 0, 580)
guiContainer.Position = UDim2.new(0.5, -155, 0, 5)
guiContainer.BackgroundTransparency = 1
guiContainer.Parent = screenGui

local headerFrame = Instance.new("Frame")
headerFrame.Name = "Header"
headerFrame.Size = UDim2.new(1, 0, 0, 30)
headerFrame.BackgroundColor3 = Color3.fromRGB(60, 0, 0)
headerFrame.BorderSizePixel = 0
headerFrame.Parent = guiContainer
Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 10)

local dragging = false
local dragStart = nil
local startPos = nil

headerFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true; dragStart = input.Position; startPos = guiContainer.Position
	end
end)
headerFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		guiContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

local dragLabel = Instance.new("TextLabel")
dragLabel.Size = UDim2.new(0.7,0,1,0); dragLabel.Position = UDim2.new(0,5,0,0)
dragLabel.BackgroundTransparency = 1; dragLabel.Text = "☰ TÉLÉ HANTÉE V4"
dragLabel.TextColor3 = Color3.fromRGB(255,180,180); dragLabel.TextScaled = true
dragLabel.Font = Enum.Font.GothamBold; dragLabel.TextXAlignment = Enum.TextXAlignment.Left
dragLabel.Parent = headerFrame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"; minimizeBtn.Size = UDim2.new(0,25,0,25)
minimizeBtn.Position = UDim2.new(1,-55,0,2.5); minimizeBtn.BackgroundColor3 = Color3.fromRGB(200,150,0)
minimizeBtn.Text = "—"; minimizeBtn.TextColor3 = Color3.fromRGB(0,0,0)
minimizeBtn.TextScaled = true; minimizeBtn.Font = Enum.Font.GothamBold; minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = headerFrame; Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 5)

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"; closeBtn.Size = UDim2.new(0,25,0,25)
closeBtn.Position = UDim2.new(1,-27,0,2.5); closeBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true; closeBtn.Font = Enum.Font.GothamBold; closeBtn.BorderSizePixel = 0
closeBtn.Parent = headerFrame; Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)

local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"; contentFrame.Size = UDim2.new(1,0,1,-30)
contentFrame.Position = UDim2.new(0,0,0,30); contentFrame.BackgroundColor3 = Color3.fromRGB(12,12,12)
contentFrame.BorderSizePixel = 0; contentFrame.ClipsDescendants = true; contentFrame.Parent = guiContainer
Instance.new("UICorner", contentFrame).CornerRadius = UDim.new(0, 10)
local contentStroke = Instance.new("UIStroke"); contentStroke.Color = Color3.fromRGB(180,0,0)
contentStroke.Thickness = 2; contentStroke.Parent = contentFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1,0,0,35); titleLabel.Position = UDim2.new(0,0,0,5)
titleLabel.BackgroundTransparency = 1; titleLabel.Text = "📺  TÉLÉ HANTÉE V4"
titleLabel.TextColor3 = Color3.fromRGB(255,40,40); titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold; titleLabel.Parent = contentFrame

local subLabel = Instance.new("TextLabel")
subLabel.Name = "SubLabel"; subLabel.Size = UDim2.new(1,0,0,20)
subLabel.Position = UDim2.new(0,0,0,38); subLabel.BackgroundTransparency = 1
subLabel.Text = "Activez le mode placement"; subLabel.TextColor3 = Color3.fromRGB(180,180,180)
subLabel.TextScaled = true; subLabel.Font = Enum.Font.Gotham; subLabel.Parent = contentFrame

local rotLabel = Instance.new("TextLabel")
rotLabel.Name = "RotLabel"; rotLabel.Size = UDim2.new(1,0,0,15)
rotLabel.Position = UDim2.new(0,0,0,56); rotLabel.BackgroundTransparency = 1
rotLabel.Text = "🔄 Appuyez R pour tourner"; rotLabel.TextColor3 = Color3.fromRGB(100,200,100)
rotLabel.TextScaled = true; rotLabel.Font = Enum.Font.Gotham; rotLabel.Visible = false; rotLabel.Parent = contentFrame

local placeBtn = Instance.new("TextButton")
placeBtn.Name = "PlaceBtn"; placeBtn.Size = UDim2.new(1,-20,0,35)
placeBtn.Position = UDim2.new(0,10,0,75); placeBtn.BackgroundColor3 = Color3.fromRGB(160,0,0)
placeBtn.Text = "🖱️  ACTIVER LE PLACEMENT"; placeBtn.TextColor3 = Color3.fromRGB(255,255,255)
placeBtn.TextScaled = true; placeBtn.Font = Enum.Font.GothamBold; placeBtn.BorderSizePixel = 0
placeBtn.Parent = contentFrame; Instance.new("UICorner", placeBtn).CornerRadius = UDim.new(0, 8)

local deleteBtn = Instance.new("TextButton")
deleteBtn.Name = "DeleteBtn"; deleteBtn.Size = UDim2.new(1,-20,0,28)
deleteBtn.Position = UDim2.new(0,10,0,114); deleteBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
deleteBtn.Text = "🗑️  SUPPRIMER LA TÉLÉ"; deleteBtn.TextColor3 = Color3.fromRGB(200,200,200)
deleteBtn.TextScaled = true; deleteBtn.Font = Enum.Font.GothamBold; deleteBtn.BorderSizePixel = 0
deleteBtn.Visible = false; deleteBtn.Parent = contentFrame
Instance.new("UICorner", deleteBtn).CornerRadius = UDim.new(0, 8)

-- ============================================
-- PANNEAU ÉVÉNEMENTS
-- ============================================

local eventsFrame = Instance.new("Frame")
eventsFrame.Name = "EventsFrame"; eventsFrame.Size = UDim2.new(1,-10,0,390)
eventsFrame.Position = UDim2.new(0,5,0,147); eventsFrame.BackgroundColor3 = Color3.fromRGB(8,8,8)
eventsFrame.BorderSizePixel = 0; eventsFrame.Visible = false; eventsFrame.ClipsDescendants = true
eventsFrame.Parent = contentFrame
Instance.new("UICorner", eventsFrame).CornerRadius = UDim.new(0, 10)
local evStroke = Instance.new("UIStroke"); evStroke.Color = Color3.fromRGB(100,0,0)
evStroke.Thickness = 1.5; evStroke.Parent = eventsFrame

local evHeader = Instance.new("Frame"); evHeader.Size = UDim2.new(1,0,0,30)
evHeader.BackgroundColor3 = Color3.fromRGB(80,0,0); evHeader.BorderSizePixel = 0; evHeader.Parent = eventsFrame
Instance.new("UICorner", evHeader).CornerRadius = UDim.new(0, 8)

local evHeaderLabel = Instance.new("TextLabel"); evHeaderLabel.Size = UDim2.new(1,0,1,0)
evHeaderLabel.BackgroundTransparency = 1; evHeaderLabel.Text = "⚡  ÉVÉNEMENTS HANTÉS  ⚡"
evHeaderLabel.TextColor3 = Color3.fromRGB(255,220,220); evHeaderLabel.TextScaled = true
evHeaderLabel.Font = Enum.Font.GothamBold; evHeaderLabel.Parent = evHeader

local scrollFrame = Instance.new("ScrollingFrame"); scrollFrame.Size = UDim2.new(1,-6,1,-35)
scrollFrame.Position = UDim2.new(0,3,0,33); scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0; scrollFrame.ScrollBarThickness = 5
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(180,0,0); scrollFrame.Parent = eventsFrame

local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0,4)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; listLayout.Parent = scrollFrame
Instance.new("UIPadding", scrollFrame).PaddingTop = UDim.new(0, 3)

local eventsList = {
	{id=1,  name="👻 Créature sort de la TV",         c=Color3.fromRGB(130,0,0),  tc=Color3.fromRGB(255,180,180)},
	{id=2,  name="📺 TV jambes + bras",               c=Color3.fromRGB(70,0,70),  tc=Color3.fromRGB(255,180,255)},
	{id=3,  name="💥 Explosion de la TV",             c=Color3.fromRGB(110,40,0), tc=Color3.fromRGB(255,200,150)},
	{id=4,  name="📡 TV s'allume toute seule",        c=Color3.fromRGB(0,50,0),   tc=Color3.fromRGB(150,255,150)},
	{id=5,  name="🔀 Glitch total",                   c=Color3.fromRGB(0,0,90),   tc=Color3.fromRGB(150,150,255)},
	{id=6,  name="🩸 Sang de l'écran",                c=Color3.fromRGB(90,0,0),   tc=Color3.fromRGB(255,100,100)},
	{id=7,  name="👁️ L'oeil te suit",                 c=Color3.fromRGB(50,50,0),  tc=Color3.fromRGB(255,255,100)},
	{id=8,  name="💀 Compte à rebours mortel",        c=Color3.fromRGB(25,25,25), tc=Color3.fromRGB(220,220,220)},
	{id=9,  name="🌀 Vortex aspirant",                c=Color3.fromRGB(50,0,90),  tc=Color3.fromRGB(200,150,255)},
	{id=10, name="⚡ Décharge électrique",            c=Color3.fromRGB(70,70,0),  tc=Color3.fromRGB(255,255,0)},
	{id=11, name="🔊 Cris de la TV",                  c=Color3.fromRGB(70,15,0),  tc=Color3.fromRGB(255,160,100)},
	{id=12, name="👤 Ombre derrière toi",             c=Color3.fromRGB(15,15,35), tc=Color3.fromRGB(180,180,255)},
	{id=13, name="📺 TV se multiplie",                c=Color3.fromRGB(50,0,25),  tc=Color3.fromRGB(255,150,200)},
	{id=14, name="🕷️ Araignées de la TV",             c=Color3.fromRGB(25,25,0),  tc=Color3.fromRGB(200,255,100)},
	{id=15, name="😱 DÉMON CAUCHEMAR [ULTIME]",       c=Color3.fromRGB(170,0,0),  tc=Color3.fromRGB(255,255,255)},
}

for _, ev in ipairs(eventsList) do
	local btn = Instance.new("TextButton")
	btn.Name = "Ev"..ev.id; btn.Size = UDim2.new(1,-8,0,32)
	btn.BackgroundColor3 = ev.c; btn.Text = ev.name; btn.TextColor3 = ev.tc
	btn.TextScaled = true; btn.Font = Enum.Font.GothamBold; btn.BorderSizePixel = 0
	btn.Parent = scrollFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	local bStroke = Instance.new("UIStroke", btn); bStroke.Color = ev.tc; bStroke.Thickness = 1; bStroke.Transparency = 0.7

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.new(
			math.min(ev.c.R+0.15,1), math.min(ev.c.G+0.15,1), math.min(ev.c.B+0.15,1)
		)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = ev.c}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		if not placedTV or eventRunning then return end
		eventRunning = true
		btn.BackgroundColor3 = Color3.fromRGB(255,255,255); wait(0.1); btn.BackgroundColor3 = ev.c
		triggerEvent(ev.id)
	end)
end

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================
-- GUI : MINIMISER / FERMER / ROUVRIR
-- ============================================

local reopenBtn = Instance.new("TextButton")
reopenBtn.Name = "ReopenBtn"; reopenBtn.Size = UDim2.new(0,45,0,45)
reopenBtn.Position = UDim2.new(1,-55,0.5,-22); reopenBtn.BackgroundColor3 = Color3.fromRGB(139,0,0)
reopenBtn.Text = "📺"; reopenBtn.TextScaled = true; reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.BorderSizePixel = 0; reopenBtn.Visible = false; reopenBtn.Parent = screenGui
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 10)
local reopenStroke = Instance.new("UIStroke"); reopenStroke.Color = Color3.fromRGB(255,100,100)
reopenStroke.Thickness = 2; reopenStroke.Parent = reopenBtn

minimizeBtn.MouseButton1Click:Connect(function()
	guiMinimized = not guiMinimized
	if guiMinimized then
		contentFrame.Visible = false; guiContainer.Size = UDim2.new(0,310,0,30); minimizeBtn.Text = "+"
	else
		contentFrame.Visible = true; guiContainer.Size = UDim2.new(0,310,0,580); minimizeBtn.Text = "—"
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	guiContainer.Visible = false; reopenBtn.Visible = true
end)

reopenBtn.MouseButton1Click:Connect(function()
	guiContainer.Visible = true; reopenBtn.Visible = false
end)

-- ============================================
-- LOGIQUE PLACEMENT + ROTATION
-- ============================================

UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.R and placingMode then
		tvRotation = (tvRotation + 45) % 360
	end
end)

RunService.RenderStepped:Connect(function()
	if not placingMode or not previewModel then return end
	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {tvFolder}
	if player.Character then table.insert(filterList, player.Character) end
	rayParams.FilterDescendantsInstances = filterList
	local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 600, rayParams)
	if rayResult then updatePreview(rayResult.Position) end
end)

placeBtn.MouseButton1Click:Connect(function()
	if placedTV then return end
	if placingMode then
		placingMode = false; destroyPreview()
		placeBtn.Text = "🖱️  ACTIVER LE PLACEMENT"; placeBtn.BackgroundColor3 = Color3.fromRGB(160,0,0)
		subLabel.Text = "Activez le mode placement"; rotLabel.Visible = false
	else
		placingMode = true; tvRotation = 0; createPreview()
		placeBtn.Text = "❌  ANNULER"; placeBtn.BackgroundColor3 = Color3.fromRGB(200,80,0)
		subLabel.Text = "Cliquez au sol pour poser la TV"; rotLabel.Visible = true
	end
end)

mouse.Button1Down:Connect(function()
	if not placingMode or placedTV then return end
	local target = mouse.Target
	if not target then return end
	if target:IsDescendantOf(tvFolder) then return end

	local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterList = {tvFolder}
	if player.Character then table.insert(filterList, player.Character) end
	rayParams.FilterDescendantsInstances = filterList
	local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 600, rayParams)

	if rayResult then
		local pos = rayResult.Position
		placedTV = createTV(pos, tvRotation); placedTVBasePos = pos
		placingMode = false; destroyPreview()

		placeBtn.Text = "✅  TV PLACÉE"; placeBtn.BackgroundColor3 = Color3.fromRGB(0,100,0)
		subLabel.Text = "Choisissez un événement !"; rotLabel.Visible = false
		deleteBtn.Visible = true; eventsFrame.Visible = true

		playSound(SOUNDS.tvTurnOn, {volume = 1, pitch = 0.8, duration = 2})

		setAllTransparency(placedTV, 1)
		for i = 1, 12 do setAllTransparency(placedTV, 1 - i/12); wait(0.03) end
		flashScreen(Color3.fromRGB(40,0,0), 0.3)
	end
end)

deleteBtn.MouseButton1Click:Connect(function()
	stopAllSounds()
	for _, child in pairs(tvFolder:GetChildren()) do child:Destroy() end
	placedTV = nil; placedTVBasePos = nil; eventRunning = false
	placeBtn.Text = "🖱️  ACTIVER LE PLACEMENT"; placeBtn.BackgroundColor3 = Color3.fromRGB(160,0,0)
	subLabel.Text = "Activez le mode placement"; deleteBtn.Visible = false; eventsFrame.Visible = false
	playSound(SOUNDS.tvTurnOff, {volume = 0.8, pitch = 1.2, duration = 1})
end)

-- ============================================
-- ANIMATION TITRE
-- ============================================
spawn(function()
	while wait(0.08) do
		local t = tick()
		local r = math.floor(math.sin(t*2)*50 + 200)
		titleLabel.TextColor3 = Color3.fromRGB(math.clamp(r,140,255), math.clamp(math.abs(math.sin(t*2))*30,0,60), 0)
		contentStroke.Color = Color3.fromRGB(math.clamp(r-50,80,200), 0, 0)
	end
end)

-- ============================================
-- RESPAWN
-- ============================================
player.CharacterAdded:Connect(function(newChar)
	character = newChar; humanoid = newChar:WaitForChild("Humanoid")
end)

-- ============================================
-- TOUS LES ÉVÉNEMENTS
-- ============================================

function triggerEvent(id)
	if not placedTV or not placedTV.Parent then eventRunning = false return end
	local tvBody = placedTV:FindFirstChild("TVBody")
	if not tvBody then eventRunning = false return end
	local tvPos = tvBody.Position

	if id == 1 then
		spawn(function()
			setScreenNeon(true)
			playTVSound(SOUNDS.tvStatic, {volume = 1.2, pitch = 0.5, duration = 5})
			for i = 1, 8 do
				setScreenText("̸G̸L̸I̸T̸C̸H̸", Color3.fromRGB(255,0,0), Color3.fromRGB(20,0,0))
				glitchScreen(0.08); wait(0.15)
				setScreenText("", nil, Color3.fromRGB(0,0,0)); wait(0.08)
			end
			setScreenText("IL ARRIVE...", Color3.fromRGB(255,0,0), Color3.fromRGB(15,0,0))
			playTVSound(SOUNDS.whisper2, {volume = 1.5, pitch = 0.6, duration = 3})
			shakeScreen(0.5, 2); wait(2)

			local screenFront = -tvBody.CFrame.LookVector
			local spawnPos = tvPos + screenFront * 0.5
			local fig, parts = createCreature(spawnPos, screenFront)

			animExitTV(fig, parts, placedTV)

			flashScreen(Color3.fromRGB(255,0,0), 0.4)
			shakeScreen(0.7, 0.5)
			setScreenText("COURS!", Color3.fromRGB(255,0,0))

			-- Retournement lent vers le joueur
			playSound(SOUNDS.monsterBreath, {volume = 1, pitch = 0.4, looped = true, name = "CreatureBreath", duration = 20})
			for turnStep = 1, 40 do
				if not fig or not fig.Parent then break end
				local pPos = getPlayerPos()
				if pPos then rotateModelToward(fig, parts.torso, pPos, 0.06) end
				if turnStep % 10 == 0 then shakeScreen(0.08, 0.05) end
				wait(0.08)
			end

			-- Tête penchée
			playSound(SOUNDS.bonesCrack, {volume = 0.6, pitch = 0.4, duration = 1})
			if parts.head and parts.head.Parent then
				for tilt = 1, 10 do
					if not fig or not fig.Parent then break end
					parts.head.CFrame = parts.head.CFrame * CFrame.Angles(0, 0, math.rad(1.5))
					wait(0.05)
				end
				wait(0.8)
				for tilt = 1, 10 do
					if not fig or not fig.Parent then break end
					parts.head.CFrame = parts.head.CFrame * CFrame.Angles(0, 0, math.rad(-1.5))
					wait(0.03)
				end
			end

			wait(0.3)
			flashScreen(Color3.fromRGB(255,0,0), 0.2)
			setScreenText("COURS!", Color3.fromRGB(255,0,0))
			playSound(SOUNDS.creatureScream, {volume = 2, pitch = 0.7, duration = 2})

			-- Forcer orientation avant poursuite
			if fig and fig.Parent and parts.torso and parts.torso.Parent then
				local pPos = getPlayerPos()
				if pPos then forceRotateModelToward(fig, parts.torso, pPos) end
			end

			-- Poursuite
			local chaseSound = playSound(SOUNDS.chaseMusic, {volume = 1.5, looped = true, name = "ChaseMusic"})
			local killed = false
			local t = 0
			while t < 18 do
				if not fig or not fig.Parent or not parts.torso.Parent then break end
				if not getPlayerAlive() then break end
				local pPos = getPlayerPos()
				if pPos then
					local dist = (pPos - parts.torso.Position).Magnitude
					if dist < 4 then
						killed = true; killPlayer()
						playSound(SOUNDS.jumpScare1, {volume = 3, pitch = 0.5, duration = 3})
						flashScreen(Color3.fromRGB(255,0,0), 2)
						shakeScreen(1.5, 2)
						setScreenText("hello", Color3.fromRGB(255,50,50), Color3.fromRGB(0,0,0))
						break
					end
					animWalkStep(parts, fig, pPos, 0.55)
					-- Son de pas périodique
					if math.floor(t * 10) % 8 == 0 then
						playSound(SOUNDS.footstepCreepy, {volume = 0.4, pitch = 0.3 + math.random()*0.2, duration = 0.5, position = parts.torso.Position})
					end
				end
				t = t + 0.03; wait(0.03)
			end

			stopSound(chaseSound)
			wait(0.5)
			if fig and fig.Parent then
				for tr = 0, 1, 0.04 do setAllTransparency(fig, tr); wait(0.02) end
				fig:Destroy()
			end
			playSound(SOUNDS.silenceAfter, {volume = 0.5, pitch = 0.8, duration = 3})
			wait(killed and 4 or 2)
			setScreenText("", nil, Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds()
			eventRunning = false
		end)

	elseif id == 2 then
		spawn(function()
			glitchScreen(1); shakeScreen(0.5, 1)
			playTVSound(SOUNDS.glitchSound, {volume = 1.5, pitch = 0.4, duration = 3})
			for i = 1, 8 do
				setScreenText("MUTATION", Color3.fromRGB(255, math.random(0,80), 0), Color3.fromRGB(15,0,0))
				wait(0.12); setScreenText(""); wait(0.08)
			end
			setScreenText("JE ME LÈVE.", Color3.fromRGB(255,0,0), Color3.fromRGB(8,0,0))
			playTVSound(SOUNDS.creatureGrowl, {volume = 1.5, pitch = 0.3, duration = 4})
			wait(1.5)

			local tvParts = animTVTransform(placedTV)
			flashScreen(Color3.fromRGB(150,0,0), 0.5)
			wait(1)

			local chaseSound = playSound(SOUNDS.chaseMusic, {volume = 1.2, looped = true, name = "TVChase"})
			local chaseT = 0
			while chaseT < 20 do
				if not placedTV or not placedTV.Parent or not tvBody.Parent then break end
				if not getPlayerAlive() then break end
				local pPos = getPlayerPos()
				if pPos then
					local dir = (pPos - tvBody.Position) * Vector3.new(1,0,1)
					local dist = dir.Magnitude
					if dist > 1 then
						dir = dir.Unit
						moveParts(placedTV, dir * 0.42)
						rotateModelToward(placedTV, tvBody, pPos, 0.35)
					end
					local t = tick()
					if tvParts and tvParts.legL and tvParts.legL.Parent then
						local pos = tvParts.legL.Position; local _, ry, _ = tvParts.legL.CFrame:ToEulerAnglesYXZ()
						tvParts.legL.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(math.sin(t*8)*0.3, 0, 0)
					end
					if tvParts and tvParts.legR and tvParts.legR.Parent then
						local pos = tvParts.legR.Position; local _, ry, _ = tvParts.legR.CFrame:ToEulerAnglesYXZ()
						tvParts.legR.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-math.sin(t*8)*0.3, 0, 0)
					end
					if tvParts and tvParts.armL and tvParts.armL.Parent then
						local pos = tvParts.armL.Position; local _, ry, _ = tvParts.armL.CFrame:ToEulerAnglesYXZ()
						tvParts.armL.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(-math.sin(t*8)*0.2, 0, 0)
					end
					if tvParts and tvParts.armR and tvParts.armR.Parent then
						local pos = tvParts.armR.Position; local _, ry, _ = tvParts.armR.CFrame:ToEulerAnglesYXZ()
						tvParts.armR.CFrame = CFrame.new(pos) * CFrame.Angles(0, ry, 0) * CFrame.Angles(math.sin(t*8)*0.2, 0, 0)
					end
					if dist < 6 then
						killPlayer(); flashScreen(Color3.fromRGB(255,0,0), 1.5)
						playSound(SOUNDS.jumpScare2, {volume = 2.5, pitch = 0.6, duration = 2})
						setScreenText("ATTRAPÉ!", Color3.fromRGB(255,0,0)); break
					end
				end
				chaseT = chaseT + 0.03; wait(0.03)
			end

			stopSound(chaseSound)
			wait(1.5)
			if placedTV and placedTV.Parent then
				for _, n in pairs({"TVLegL","TVLegR","TVArmL","TVArmR","TVFootL","TVFootR","TVHandL","TVHandR"}) do
					local p = placedTV:FindFirstChild(n); if p then p:Destroy() end
				end
				if placedTVBasePos and tvBody.Parent then
					local delta = placedTVBasePos + Vector3.new(0,3,0) - tvBody.Position
					moveParts(placedTV, delta)
					local baseCF = CFrame.new(placedTVBasePos) * CFrame.Angles(0, math.rad(tvRotation), 0)
					local function rp(name, size, lp)
						local p = Instance.new("Part"); p.Name = name; p.Size = size
						p.CFrame = baseCF * CFrame.new(lp); p.Anchored = true
						p.BrickColor = BrickColor.new("Really black"); p.Parent = placedTV
					end
					rp("LegLeft", Vector3.new(0.3,1.5,0.3), Vector3.new(-2,0.75,0))
					rp("LegRight", Vector3.new(0.3,1.5,0.3), Vector3.new(2,0.75,0))
					rp("Base", Vector3.new(5,0.25,1.5), Vector3.new(0,0.125,0))
					tvBody.Size = Vector3.new(6,4,0.6)
				end
			end
			setScreenText("", nil, Color3.fromRGB(10,10,10))
			stopAllSounds()
			eventRunning = false
		end)

	elseif id == 3 then
		spawn(function()
			setScreenNeon(true)
			playTVSound(SOUNDS.warningAlarm, {volume = 1.5, looped = true, name = "Alarm", duration = 8})
			for c = 5, 1, -1 do
				setScreenText(c.." ⚠️", Color3.fromRGB(255,100,0), Color3.fromRGB(30,10,0))
				playSound(SOUNDS.countdown, {volume = 1, pitch = 1 + (5-c)*0.1, duration = 0.8})
				shakeScreen(c*0.12, 0.9); flashScreen(Color3.fromRGB(255,50,0), 0.08); wait(1)
			end
			setScreenText("BOOM!", Color3.fromRGB(255,200,0))
			playSound(SOUNDS.loudBang, {volume = 3, pitch = 0.6, duration = 4})
			playSound(SOUNDS.glassBreak, {volume = 2, pitch = 0.8, duration = 2})
			flashScreen(Color3.fromRGB(255,150,0), 1); shakeScreen(1.5, 2)
			for i = 1, 25 do
				local d = Instance.new("Part")
				d.Size = Vector3.new(math.random()*1+0.15, math.random()*1+0.15, math.random()*1+0.15)
				d.CFrame = CFrame.new(tvPos + Vector3.new(math.random(-3,3),math.random(0,3),math.random(-3,3)))
				d.Anchored = false; d.CanCollide = true
				d.BrickColor = BrickColor.new(math.random()>0.5 and "Really black" or "Dark stone grey")
				d.Velocity = Vector3.new(math.random(-70,70),math.random(25,80),math.random(-70,70))
				d.Parent = tvFolder; Debris:AddItem(d, 5)
			end
			local p = player.Character
			if p and p:FindFirstChild("HumanoidRootPart") and p:FindFirstChild("Humanoid") then
				local dist = (p.HumanoidRootPart.Position - tvPos).Magnitude
				if dist < 20 then p.Humanoid:TakeDamage(math.floor(100*(1-dist/20))); redVignette(2) end
			end
			if placedTV then setAllTransparency(placedTV, 1) end
			wait(5)
			if placedTV and placedTV.Parent then for t=0,1,0.05 do setAllTransparency(placedTV,1-t); wait(0.03) end end
			setScreenText("", nil, Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 4 then
		spawn(function()
			local msgs = {"TU ME REGARDES?","JE TE VOIS","DERRIÈRE TOI","NE DORS PAS","JE SUIS LÀ","AIDE MOI","LAISSE MOI SORTIR","VIENS..."}
			local cols = {Color3.fromRGB(255,0,0),Color3.fromRGB(0,255,0),Color3.fromRGB(0,0,255),Color3.fromRGB(255,255,0),Color3.fromRGB(255,0,255)}
			for cycle = 1, 4 do
				setScreenNeon(false); setScreenText("",nil,Color3.fromRGB(0,0,0))
				wait(math.random(10,25)/10)
				playTVSound(SOUNDS.tvTurnOn, {volume = 1, pitch = 0.8 + math.random()*0.4, duration = 1})
				flashScreen(Color3.fromRGB(200,200,200), 0.12); setScreenNeon(true)
				setScreenText(msgs[math.random(1,#msgs)], cols[math.random(1,#cols)])
				playTVSound(SOUNDS.whisper1, {volume = 1.5, pitch = 0.5 + math.random()*0.5, duration = 2})
				shakeScreen(0.2, 0.3); wait(1.5+math.random())
				for f = 1, math.random(3,8) do
					setScreenNeon(false); playTVSound(SOUNDS.electricBuzz, {volume = 0.3, duration = 0.1})
					wait(math.random()*0.1+0.02)
					setScreenNeon(true); wait(math.random()*0.1+0.02)
				end
			end
			setScreenText("BONNE NUIT...", Color3.fromRGB(255,0,0))
			playTVSound(SOUNDS.whisper2, {volume = 2, pitch = 0.4, duration = 3}); wait(2)
			playTVSound(SOUNDS.tvTurnOff, {volume = 0.8, duration = 1})
			setScreenNeon(false); setScreenText("",nil,Color3.fromRGB(10,10,10))
			eventRunning = false
		end)

	elseif id == 5 then
		spawn(function()
			playTVSound(SOUNDS.glitchSound, {volume = 2, pitch = 0.3, looped = true, name = "GlitchLoop", duration = 8})
			glitchScreen(6); shakeScreen(0.5, 6); setScreenNeon(true)
			local ch = {"▓","▒","░","█","▄","▀","╗","╔","╚","╝","║","═"}
			for g = 1, 80 do
				local txt = ""
				for c = 1, math.random(3,10) do txt = txt..ch[math.random(1,#ch)] end
				setScreenText(txt, Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)), Color3.fromRGB(math.random(0,30),0,0))
				if g%10==0 and placedTV then
					local off = Vector3.new(math.random(-5,5),0,math.random(-5,5))
					moveParts(placedTV, off); wait(0.08); moveParts(placedTV, -off)
					playTVSound(SOUNDS.electricShock, {volume = 0.5, pitch = 0.5+math.random()*0.5, duration = 0.3})
				end
				local s = Vector3.new(math.random(-8,8)/25,math.random(-5,5)/25,math.random(-8,8)/25)
				if placedTV then moveParts(placedTV, s) end; wait(0.04)
				if placedTV then moveParts(placedTV, -s) end
			end
			setScreenText("OÙ SUIS-JE?", Color3.fromRGB(255,50,50)); wait(2)
			setScreenText("",nil,Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 6 then
		spawn(function()
			setScreenText("...", Color3.fromRGB(139,0,0), Color3.fromRGB(30,0,0))
			playTVSound(SOUNDS.heartbeat, {volume = 1, looped = true, name = "BloodHeart", duration = 15})
			wait(1.5)
			for drop = 1, 30 do
				local b = Instance.new("Part"); b.Shape = Enum.PartType.Ball
				b.Size = Vector3.new(0.2,0.2,0.2)
				b.CFrame = CFrame.new(tvPos + Vector3.new(math.random(-25,25)/10, 3+math.random(-15,15)/10, 0.5))
				b.Anchored = false; b.CanCollide = false
				b.BrickColor = BrickColor.new("Crimson"); b.Parent = tvFolder
				Debris:AddItem(b, 10)
				if drop % 3 == 0 then
					playSound(SOUNDS.bloodDrip, {volume = 0.5, pitch = 0.8+math.random()*0.4, duration = 0.5, position = tvPos})
				end
				wait(0.12)
			end
			local puddle = Instance.new("Part"); puddle.Size = Vector3.new(5,0.06,4)
			puddle.CFrame = CFrame.new(tvPos + Vector3.new(0,-2.9,0.8))
			puddle.Anchored = true; puddle.BrickColor = BrickColor.new("Crimson"); puddle.Parent = tvFolder
			Debris:AddItem(puddle, 15)
			setScreenText("ÇA FAIT MAL", Color3.fromRGB(255,50,50))
			playTVSound(SOUNDS.cryingSound, {volume = 1.5, pitch = 0.5, duration = 4}); wait(4)
			setScreenText("",nil,Color3.fromRGB(10,10,10))
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 7 then
		spawn(function()
			setScreenText("",nil,Color3.fromRGB(0,0,0)); wait(1)
			for _, s in ipairs({".","o","O","👁️"}) do
				setScreenText(s, Color3.fromRGB(255,220,0)); wait(0.6)
			end
			playTVSound(SOUNDS.ambientDread, {volume = 0.8, looped = true, name = "EyeAmbient", duration = 15})
			for look = 1, 80 do
				local pp = getPlayerPos()
				if pp then
					local diff = pp.X - tvPos.X
					local txt = diff > 4 and "        👁️" or diff < -4 and "👁️        " or "    👁️    "
					if look%20==0 then
						setScreenText("    —    "); playSound(SOUNDS.whisper1, {volume = 0.5, pitch = 0.7, duration = 0.5})
						wait(0.1)
					end
					setScreenText(txt, Color3.fromRGB(255,220,0))
				end
				wait(0.12)
			end
			setScreenText("JE TE VOIS", Color3.fromRGB(255,0,0))
			playSound(SOUNDS.jumpScare1, {volume = 1.5, pitch = 1, duration = 1.5})
			flashScreen(Color3.fromRGB(255,200,0), 0.5); shakeScreen(0.6, 1); wait(3)
			setScreenText("",nil,Color3.fromRGB(10,10,10))
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 8 then
		spawn(function()
			setScreenNeon(true)
			setScreenText("⚠️ TU VAS MOURIR ⚠️", Color3.fromRGB(255,100,0))
			playTVSound(SOUNDS.warningAlarm, {volume = 1, looped = true, name = "DeathAlarm", duration = 15})
			playSound(SOUNDS.heartbeat, {volume = 1.5, looped = true, name = "DeathHeart", duration = 15})
			wait(2)
			for c = 10, 1, -1 do
				setScreenText(c.."...", Color3.fromRGB(255,math.max(0,255-c*25),0))
				playSound(SOUNDS.countdown, {volume = 1.5, pitch = 0.8 + (10-c)*0.05, duration = 0.8})
				shakeScreen(c*0.12, 0.9); flashScreen(Color3.fromRGB(200,0,0), 0.08); wait(1)
			end
			playSound(SOUNDS.jumpScare2, {volume = 3, pitch = 0.4, duration = 3})
			flashScreen(Color3.fromRGB(255,255,255), 1.5); shakeScreen(2, 2)
			local p = player.Character
			if p and p:FindFirstChild("HumanoidRootPart") and p:FindFirstChild("Humanoid") then
				if (p.HumanoidRootPart.Position - tvPos).Magnitude < 40 then killPlayer(); redVignette(2) end
			end
			setScreenText("hello", Color3.fromRGB(255,0,0)); wait(5)
			setScreenText("",nil,Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 9 then
		spawn(function()
			setScreenNeon(true)
			playTVSound(SOUNDS.vortexSound, {volume = 2, looped = true, name = "VortexLoop", duration = 10})
			playSound(SOUNDS.windHowl, {volume = 1.5, looped = true, name = "VortexWind", duration = 10})
			local spins = {"🌀","  🌀","    🌀","  🌀"}; local si = 0
			for pull = 1, 120 do
				si = si+1; if si > #spins then si = 1 end
				setScreenText(spins[si], Color3.fromRGB(180,0,255), Color3.fromRGB(10,0,25))
				local p = player.Character
				if p and p:FindFirstChild("HumanoidRootPart") and p:FindFirstChild("Humanoid") and p.Humanoid.Health > 0 then
					local h = p.HumanoidRootPart
					local dist = (h.Position - tvPos).Magnitude
					if dist < 45 and dist > 3 then
						h.Velocity = (tvPos - h.Position).Unit * ((45-dist)/45*2.5) * 18 + Vector3.new(0,3,0)
					elseif dist <= 3 then p.Humanoid:TakeDamage(4); redVignette(0.3) end
				end
				shakeScreen(0.12, 0.05); wait(0.05)
			end
			setScreenText("BIENVENUE DANS LE VIDE", Color3.fromRGB(200,0,255))
			flashScreen(Color3.fromRGB(80,0,150), 0.5); wait(3)
			setScreenText("",nil,Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 10 then
		spawn(function()
			setScreenText("⚡ SURCHARGE ⚡", Color3.fromRGB(255,255,0)); setScreenNeon(true)
			playTVSound(SOUNDS.electricBuzz, {volume = 2, looped = true, name = "ElecBuzz", duration = 12})
			for bolt = 1, 18 do
				for l = 1, 3 do
					local lt = Instance.new("Part"); lt.Size = Vector3.new(0.08, math.random(4,16), 0.08)
					lt.CFrame = CFrame.new(tvPos + Vector3.new(math.random(-6,6),math.random(0,10),math.random(-6,6)))
						* CFrame.Angles(math.rad(math.random(-60,60)),math.rad(math.random(-60,60)),math.rad(math.random(-60,60)))
					lt.Anchored = true; lt.CanCollide = false
					lt.BrickColor = BrickColor.new("New Yeller"); lt.Material = Enum.Material.Neon
					lt.Parent = tvFolder; Debris:AddItem(lt, 0.2)
				end
				playSound(SOUNDS.electricShock, {volume = 1.5, pitch = 0.5+math.random()*0.8, duration = 0.5, position = tvPos})
				flashScreen(Color3.fromRGB(255,255,150), 0.08); shakeScreen(0.3, 0.2)
				local p = player.Character
				if p and p:FindFirstChild("HumanoidRootPart") and p:FindFirstChild("Humanoid") then
					if (p.HumanoidRootPart.Position - tvPos).Magnitude < 18 then p.Humanoid:TakeDamage(6); redVignette(0.3) end
				end
				wait(math.random()*0.4+0.1)
			end
			flashScreen(Color3.fromRGB(255,255,255), 0.5); wait(3)
			setScreenText("",nil,Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 11 then
		spawn(function()
			setScreenNeon(true)
			playTVSound(SOUNDS.tvStatic, {volume = 0.8, looped = true, name = "ScreamStatic", duration = 15})
			wait(1.5)
			local screams = {"AAAAAAHHHH!","AU SECOURS!","IL EST LÀ!","NE TE RETOURNE PAS!","COURS!!!","TU NE PEUX PAS FUIR","AIDEZ-MOI!!!","J'AI MAL...","DERRIÈRE TOI!!!"}
			local screamSounds = {SOUNDS.screamFemale, SOUNDS.screamMale, SOUNDS.creatureScream, SOUNDS.screamFemale, SOUNDS.screamMale, SOUNDS.whisper1, SOUNDS.cryingSound, SOUNDS.screamFemale, SOUNDS.jumpScare1}
			for idx, scream in ipairs(screams) do
				setScreenText(scream, Color3.fromRGB(math.random(150,255),0,0), Color3.fromRGB(math.random(0,20),0,0))
				playTVSound(screamSounds[idx], {volume = 1.5+math.random()*1, pitch = 0.5+math.random()*0.5, duration = 1})
				shakeScreen(math.random(2,5)/10, 0.4)
				local s = Vector3.new(math.random(-6,6)/12,math.random(-4,4)/12,math.random(-6,6)/12)
				if placedTV then moveParts(placedTV, s) end; wait(0.4+math.random()*0.3)
				if placedTV then moveParts(placedTV, -s) end
				flashScreen(Color3.fromRGB(80,0,0), 0.1); wait(0.08)
			end
			setScreenText("SILENCE.", Color3.fromRGB(255,255,255), Color3.fromRGB(200,0,0))
			flashScreen(Color3.fromRGB(255,0,0), 0.6); wait(3)
			setScreenText("",nil,Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 12 then
		spawn(function()
			setScreenText("RETOURNE-TOI...", Color3.fromRGB(80,80,80), Color3.fromRGB(5,5,5))
			playTVSound(SOUNDS.whisper2, {volume = 2, pitch = 0.4, duration = 3})
			playSound(SOUNDS.ambientDread, {volume = 1, looped = true, name = "ShadowAmbient", duration = 20})
			wait(2.5)
			local p = player.Character
			if not p or not p:FindFirstChild("HumanoidRootPart") then stopAllSounds(); eventRunning = false return end
			local shadow = Instance.new("Model"); shadow.Name = "Shadow"
			local hrpPos = p.HumanoidRootPart.Position
			local behind = hrpPos - p.HumanoidRootPart.CFrame.LookVector * 5
			local function sp(name, size, pos, col, mat, shape)
				local pp = Instance.new("Part"); pp.Name = name; pp.Size = size
				pp.CFrame = CFrame.new(pos); pp.Anchored = true; pp.CanCollide = false
				pp.BrickColor = BrickColor.new(col or "Really black")
				pp.Material = mat or Enum.Material.SmoothPlastic; pp.Transparency = 0.4
				if shape then pp.Shape = shape end; pp.Parent = shadow; return pp
			end
			local sT = sp("Torso", Vector3.new(1.8,3.5,0.7), behind+Vector3.new(0,2,0))
			sp("Head", Vector3.new(1.5,1.5,1.5), behind+Vector3.new(0,5,0), nil, nil, Enum.PartType.Ball)
			local sEL = sp("EyeL", Vector3.new(0.3,0.3,0.2), behind+Vector3.new(-0.3,5.1,0.6), "Really red", Enum.Material.Neon)
			local sER = sp("EyeR", Vector3.new(0.3,0.3,0.2), behind+Vector3.new(0.3,5.1,0.6), "Really red", Enum.Material.Neon)
			sEL.Transparency = 0; sER.Transparency = 0
			sp("ArmL", Vector3.new(0.4,3,0.4), behind+Vector3.new(-1.2,1.5,0))
			sp("ArmR", Vector3.new(0.4,3,0.4), behind+Vector3.new(1.2,1.5,0))
			shadow.PrimaryPart = sT; shadow.Parent = tvFolder

			playSound(SOUNDS.monsterBreath, {volume = 0.8, pitch = 0.3, looped = true, name = "ShadowBreath", duration = 15})
			flashScreen(Color3.fromRGB(0,0,0), 0.4)
			local ft = 0
			while ft < 12 do
				if not shadow or not shadow.Parent then break end
				local c = player.Character
				if c and c:FindFirstChild("HumanoidRootPart") then
					local h = c.HumanoidRootPart
					local tgt = h.Position + (-h.CFrame.LookVector) * 4.5
					local delta = (tgt + Vector3.new(0,2,0)) - sT.Position
					moveParts(shadow, delta * 0.18)
					sEL.Transparency = math.sin(tick()*3) > 0.9 and 1 or 0
					sER.Transparency = sEL.Transparency
				end
				ft = ft + 0.05; wait(0.05)
			end
			setScreenText("TU N'ÉTAIS PAS SEUL", Color3.fromRGB(255,0,0))
			playSound(SOUNDS.jumpScare1, {volume = 1.5, pitch = 0.8, duration = 1.5})
			if shadow and shadow.Parent then
				for t = 0, 1, 0.08 do setAllTransparency(shadow, t); wait(0.04) end
				shadow:Destroy()
			end
			wait(3); setScreenText("",nil,Color3.fromRGB(10,10,10))
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 13 then
		spawn(function()
			setScreenNeon(true); setScreenText("NOUS ARRIVONS", Color3.fromRGB(255,0,0))
			playTVSound(SOUNDS.tvStatic, {volume = 1, looped = true, name = "CloneStatic", duration = 15})
			playSound(SOUNDS.childLaugh, {volume = 1.5, pitch = 0.4, duration = 3}); wait(1.5)
			local clones = {}
			for i = 1, 8 do
				setScreenText(tostring(i), Color3.fromRGB(255,0,0))
				playTVSound(SOUNDS.tvTurnOn, {volume = 0.5, pitch = 0.6+i*0.1, duration = 0.5})
				flashScreen(Color3.fromRGB(100,0,0), 0.1)
				local angle = (i/8)*math.pi*2; local radius = 10+i*2
				local clonePos = tvPos + Vector3.new(math.cos(angle)*radius, 0, math.sin(angle)*radius)
				local cb = Instance.new("Part"); cb.Size = Vector3.new(6,4,0.5)
				cb.CFrame = CFrame.new(clonePos + Vector3.new(0,3,0))
				cb.Anchored = true; cb.BrickColor = BrickColor.new("Really black")
				local cs = Instance.new("Part"); cs.Size = Vector3.new(5.4,3.4,0.1)
				cs.CFrame = CFrame.new(clonePos + Vector3.new(0,3,0.31))
				cs.Anchored = true; cs.Material = Enum.Material.Neon
				cs.BrickColor = BrickColor.new("Really red")
				local clone = Instance.new("Model"); clone.Name = "Clone"..i
				cb.Parent = clone; cs.Parent = clone; clone.PrimaryPart = cb; clone.Parent = tvFolder
				table.insert(clones, {model=clone, body=cb}); wait(0.3)
			end
			setScreenText("PARTOUT", Color3.fromRGB(255,0,0))
			playSound(SOUNDS.chaseMusic, {volume = 1, looped = true, name = "CloneChase", duration = 10}); wait(2)
			for conv = 1, 60 do
				local pp = getPlayerPos()
				if pp then
					for _, data in pairs(clones) do
						if data.model and data.model.Parent and data.body.Parent then
							local dir = (pp - data.body.Position).Unit
							moveParts(data.model, Vector3.new(dir.X*0.5, 0, dir.Z*0.5))
							if (pp - data.body.Position).Magnitude < 6 then
								local c = player.Character
								if c and c:FindFirstChild("Humanoid") then c.Humanoid:TakeDamage(8); redVignette(0.3) end
								playSound(SOUNDS.electricShock, {volume = 0.5, pitch = 1, duration = 0.3})
							end
						end
					end
				end
				wait(0.05)
			end
			flashScreen(Color3.fromRGB(255,0,0), 0.5)
			for _, data in pairs(clones) do if data.model and data.model.Parent then data.model:Destroy() end end
			wait(3); setScreenText("",nil,Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 14 then
		spawn(function()
			setScreenText("🕷️🕷️🕷️🕷️🕷️", Color3.fromRGB(80,80,0), Color3.fromRGB(0,0,0))
			playTVSound(SOUNDS.spiderSkitter, {volume = 1.5, looped = true, name = "SpiderLoop", duration = 15})
			wait(1.5)
			local spiders = {}
			for s = 1, 12 do
				local spider = Instance.new("Model"); spider.Name = "Spider"..s
				local body = Instance.new("Part"); body.Shape = Enum.PartType.Ball
				body.Size = Vector3.new(0.7,0.5,0.9)
				body.CFrame = CFrame.new(tvPos + Vector3.new(math.random(-20,20)/10,-2,math.random(1,3)))
				body.Anchored = true; body.CanCollide = false
				body.BrickColor = BrickColor.new("Really black"); body.Parent = spider
				local se = Instance.new("Part"); se.Shape = Enum.PartType.Ball; se.Size = Vector3.new(0.15,0.15,0.15)
				se.CFrame = CFrame.new(body.Position + Vector3.new(0,0.1,0.35))
				se.Anchored = true; se.CanCollide = false
				se.BrickColor = BrickColor.new("Really red"); se.Material = Enum.Material.Neon; se.Parent = spider
				for leg = 1, 8 do
					local a = (leg/8)*math.pi*2; local lp = Instance.new("Part")
					lp.Size = Vector3.new(0.05,0.5,0.05)
					lp.CFrame = CFrame.new(body.Position + Vector3.new(math.cos(a)*0.4,-0.15,math.sin(a)*0.4))
						* CFrame.Angles(math.rad(math.random(-25,25)),a,math.rad(50))
					lp.Anchored = true; lp.CanCollide = false; lp.BrickColor = BrickColor.new("Really black"); lp.Parent = spider
				end
				spider.PrimaryPart = body; spider.Parent = tvFolder
				table.insert(spiders, {model=spider, body=body})
			end
			setScreenText("ILS ARRIVENT 🕷️", Color3.fromRGB(150,150,0))
			for move = 1, 180 do
				local pp = getPlayerPos()
				for _, data in pairs(spiders) do
					if data.model and data.model.Parent and data.body.Parent and pp then
						local dir = (pp - data.body.Position).Unit
						moveParts(data.model, Vector3.new(dir.X*(0.3+math.random()*0.2), 0, dir.Z*(0.3+math.random()*0.2)))
						if (pp - data.body.Position).Magnitude < 3 then
							local c = player.Character
							if c and c:FindFirstChild("Humanoid") then c.Humanoid:TakeDamage(2); redVignette(0.2) end
						end
					end
				end
				wait(0.04)
			end
			for _, data in pairs(spiders) do if data.model and data.model.Parent then data.model:Destroy() end end
			setScreenText("",nil,Color3.fromRGB(10,10,10))
			stopAllSounds(); eventRunning = false
		end)

	elseif id == 15 then
		spawn(function()
			setScreenNeon(true)
			playTVSound(SOUNDS.tvStatic, {volume = 1.5, pitch = 0.3, duration = 5})
			playTVSound(SOUNDS.ambientDread, {volume = 1, fadeIn = 2, duration = 8})

			for flick = 1, 25 do
				local scr = placedTV:FindFirstChild("TVScreen")
				if scr then
					scr.Material = flick%2==0 and Enum.Material.Neon or Enum.Material.SmoothPlastic
					scr.BrickColor = flick%2==0 and BrickColor.new("Institutional white") or BrickColor.new("Really black")
				end
				glitchScreen(0.06); shakeScreen(0.3, 0.06); wait(0.08)
			end

			local faces = {
				{txt=".",           col=Color3.fromRGB(30,30,30),  bg=Color3.fromRGB(0,0,0),  w=1.2},
				{txt=".  .",        col=Color3.fromRGB(80,80,80),  bg=Color3.fromRGB(0,0,0),  w=1.0},
				{txt="o  o",        col=Color3.fromRGB(150,50,50), bg=Color3.fromRGB(5,0,0),  w=0.8},
				{txt="O  O",        col=Color3.fromRGB(200,0,0),   bg=Color3.fromRGB(10,0,0), w=0.7},
				{txt="O  O\n\n===", col=Color3.fromRGB(240,0,0),   bg=Color3.fromRGB(15,0,0), w=0.6},
				{txt="👁️ 👁️\n\n💀", col=Color3.fromRGB(255,0,0),   bg=Color3.fromRGB(25,0,0), w=0.5},
			}
			for idx, f in ipairs(faces) do
				setScreenText(f.txt, f.col, f.bg); shakeScreen(0.15, f.w)
				if idx >= 3 then
					playTVSound(SOUNDS.heartbeat, {volume = 0.5 + idx*0.2, pitch = 0.8, duration = f.w})
				end
				wait(f.w)
			end

			shakeScreen(1, 3); glitchScreen(3)
			playSound(SOUNDS.creatureScream, {volume = 2, pitch = 0.3, duration = 4})
			for panic = 1, 12 do
				flashScreen(Color3.fromRGB(255,0,0), 0.1)
				setScreenText("IL SORT!", Color3.fromRGB(255,0,0)); wait(0.1)
				setScreenText("COURS!", Color3.fromRGB(255,255,0)); wait(0.1)
			end

			local frontDir2 = -tvBody.CFrame.LookVector
			local spawnPos = tvPos + frontDir2 * 5 + Vector3.new(0, 2.5, 0)
			local monster, parts = createNightmare(spawnPos)

			animRiseFromGround(monster, parts, placedTV)

			flashScreen(Color3.fromRGB(255,0,0), 1); shakeScreen(2, 1.5); glitchScreen(1)
			playSound(SOUNDS.demonRoar, {volume = 3, pitch = 0.3, duration = 4})
			wait(0.3)

			-- Forcer orientation vers le joueur
			if monster and monster.Parent and parts.torso and parts.torso.Parent then
				local pPos = getPlayerPos()
				if pPos then forceRotateModelToward(monster, parts.torso, pPos) end
			end

			setScreenText("TROP TARD.", Color3.fromRGB(255,0,0), Color3.fromRGB(20,0,0))

			local chaseSound = playSound(SOUNDS.chaseMusic, {volume = 2, looped = true, name = "DemonChase"})
			local breathSound = playSound(SOUNDS.monsterBreath, {volume = 1.5, pitch = 0.3, looped = true, name = "DemonBreath"})

			local hasKilled = false
			local chaseTime = 0
			local step = 0

			while chaseTime < 30 do
				if not monster or not monster.Parent or not parts.torso.Parent then break end
				if not getPlayerAlive() then break end

				local pPos = getPlayerPos()
				if pPos then
					local dist = (pPos - parts.torso.Position).Magnitude

					if dist < 5.5 then
						hasKilled = true; killPlayer()
						playSound(SOUNDS.jumpScare1, {volume = 3, pitch = 0.3, duration = 4})
						playSound(SOUNDS.demonRoar, {volume = 2.5, pitch = 0.4, duration = 3})
						flashScreen(Color3.fromRGB(255,0,0), 3)
						shakeScreen(3, 3); glitchScreen(2)
						setScreenText("hello", Color3.fromRGB(255,50,50), Color3.fromRGB(0,0,0))
						for roar = 1, 6 do flashScreen(Color3.fromRGB(200,0,0), 0.1); wait(0.1) end
						break
					end

					local speed = math.min(0.7 + chaseTime * 0.025, 1.4)
					animWalkStep(parts, monster, pPos, speed)

					step = step + 1
					if step % 35 == 0 then
						glitchScreen(0.25); shakeScreen(0.2, 0.15)
						setScreenText(step%70==0 and "COURS!!!" or "👁️", Color3.fromRGB(255,0,0))
						playSound(SOUNDS.creatureGrowl, {volume = 1, pitch = 0.3+math.random()*0.2, duration = 1, position = parts.torso.Position})
					end
					if step % 12 == 0 then
						playSound(SOUNDS.footstepCreepy, {volume = 0.6, pitch = 0.2+math.random()*0.2, duration = 0.4, position = parts.torso.Position})
					end
				end

				chaseTime = chaseTime + 0.03; wait(0.03)
			end

			stopSound(chaseSound); stopSound(breathSound)
			wait(0.8)
			if monster and monster.Parent then
				flashScreen(Color3.fromRGB(0,0,0), 1.5)
				for tr = 0, 1, 0.03 do setAllTransparency(monster, tr); wait(0.02) end
				monster:Destroy()
			end

			playSound(SOUNDS.silenceAfter, {volume = 0.8, pitch = 0.5, duration = 5})
			wait(hasKilled and 5 or 3)
			setScreenText("", nil, Color3.fromRGB(10,10,10)); setScreenNeon(false)
			stopAllSounds(); eventRunning = false
		end)
	end
end

-- ============================================
print("╔══════════════════════════════════════════╗")
print("║   📺 TÉLÉ HANTÉE V4 - CHARGÉ !          ║")
print("║   15 événements + SONS + rotation fixée  ║")
print("║   Rotation R + GUI déplaçable            ║")
print("╚══════════════════════════════════════════╝")
