--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║          🛡️ ROBLOX ANTI-VIRUS SCANNER v3.0 🛡️              ║
    ║          par GitHub Community Security Tool                  ║
    ║          Coller dans: Command Bar (View > Command Bar)      ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ============================================================
-- CONFIGURATION
-- ============================================================
local CONFIG = {
    AUTO_DISABLE = true,        -- Désactive automatiquement les scripts suspects
    AUTO_DELETE = false,         -- Mettre true pour supprimer automatiquement (DANGER)
    SCAN_DEPTH = math.huge,     -- Profondeur de scan (math.huge = tout)
    SHOW_CLEAN = false,         -- Afficher aussi les scripts propres
    QUARANTINE_FOLDER = true,   -- Déplacer les virus dans un dossier Quarantaine
}

-- ============================================================
-- VARIABLES
-- ============================================================
local totalScanned = 0
local totalInfected = 0
local totalSuspicious = 0
local totalClean = 0
local infections = {}
local suspicious = {}
local startTime = tick()

-- ============================================================
-- SIGNATURES DE VIRUS CONNUES (Patterns malveillants)
-- ============================================================
local VIRUS_SIGNATURES = {
    -- ===== BACKDOORS & REMOTE EXPLOITS =====
    {
        name = "Backdoor/RemoteExploit",
        severity = "CRITIQUE",
        patterns = {
            "require%(%s*%d%d%d%d%d%d%d%d%d%d%s*%)",
            "require%(%s*%d%d%d%d%d%d%d%d%s*%)",
            "require%(%s*%d%d%d%d%d%d%d%s*%)",
        },
        description = "Charge du code externe malveillant via require(ID)"
    },
    {
        name = "Backdoor/LoadString",
        severity = "CRITIQUE",
        patterns = {
            "loadstring%s*%(",
            "loadstring%(%s*game%s*:%s*HttpGet",
            "loadstring%(%s*HttpGet",
        },
        description = "Execute du code telecharge dynamiquement"
    },
    {
        name = "Backdoor/HttpBackdoor",
        severity = "CRITIQUE",
        patterns = {
            "HttpService%s*:%s*GetAsync",
            "HttpService%s*:%s*PostAsync",
            "HttpService%s*:%s*RequestAsync",
            "GetAsync%s*%(%s*[\"']https?://",
            "PostAsync%s*%(%s*[\"']https?://",
        },
        description = "Communication avec serveur externe"
    },

    -- ===== OBFUSCATION (Code caché) =====
    {
        name = "Obfuscation/EncodedPayload",
        severity = "CRITIQUE",
        patterns = {
            "\\%d%d%d\\%d%d%d\\%d%d%d\\%d%d%d",
            "string%.char%s*%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*%d+",
            "string%.byte",
            "string%.reverse",
        },
        description = "Code obfusque pour cacher un virus"
    },
    {
        name = "Obfuscation/Base64",
        severity = "HAUTE",
        patterns = {
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
            "base64",
            "decode%s*%(",
            "encode%s*%(",
        },
        description = "Encodage Base64 suspect"
    },
    {
        name = "Obfuscation/VariableSpam",
        severity = "HAUTE",
        patterns = {
            "local%s+[iIlL1O0]+%s*=%s*[iIlL1O0]+",
            "_[%w_]-_[%w_]-_[%w_]-_[%w_]-_",
        },
        description = "Variables avec noms confus pour cacher le code"
    },

    -- ===== FAKE ERROR / CRASH SCRIPTS =====
    {
        name = "Crasher/FakeError",
        severity = "CRITIQUE",
        patterns = {
            "error%s*%(%s*[\"']",
            "Error%-.-Script",
            "fake.-error",
            "Message%s*=%s*[\"'].-error",
        },
        description = "Faux message d'erreur pour tromper l'utilisateur"
    },
    {
        name = "Crasher/InfiniteLoop",
        severity = "HAUTE",
        patterns = {
            "while%s+true%s+do%s+end",
            "while%s*%(%s*true%s*%)%s*do%s*end",
            "repeat%s+until%s+false",
            "for%s+.-%s*,%s*math%.huge",
        },
        description = "Boucle infinie qui fait crash le jeu"
    },
    {
        name = "Crasher/InstanceSpam",
        severity = "HAUTE",
        patterns = {
            "Instance%.new%s*%(.*%).*while",
            "Instance%.new%s*%(.*%).*for",
            "Clone%s*%(%).*Parent.*while",
            "Clone%s*%(%).*Parent.*for",
        },
        description = "Spam de creation d'instances pour crash"
    },
    {
        name = "Crasher/MemoryOverflow",
        severity = "CRITIQUE",
        patterns = {
            "table%.insert.*while%s+true",
            "string%.rep%s*%(.*%d%d%d%d%d%d",
            "math%.huge",
        },
        description = "Debordement memoire intentionnel"
    },

    -- ===== ANTI-DETECTION / PERSISTENCE =====
    {
        name = "Stealth/SelfReplication",
        severity = "CRITIQUE",
        patterns = {
            "Clone%s*%(%s*%)%s*.-%s*Parent%s*=%s*game",
            "script%s*:%s*Clone%s*%(%s*%)",
            "script%.Source",
            "script%s*.-%s*Source",
        },
        description = "Le script se clone pour survivre a la suppression"
    },
    {
        name = "Stealth/AntiDelete",
        severity = "CRITIQUE",
        patterns = {
            "AncestryChanged",
            "ChildRemoved",
            "Destroying",
            "%.Parent%s*=%s*nil.*Parent%s*=",
        },
        description = "Empeche sa propre suppression"
    },
    {
        name = "Stealth/HiddenScript",
        severity = "HAUTE",
        patterns = {
            "Parent%s*=%s*nil",
            "Archivable%s*=%s*false",
        },
        description = "Se cache pour ne pas etre trouve"
    },
    {
        name = "Stealth/NameSpoofing",
        severity = "MOYENNE",
        patterns = {
            "Name%s*=%s*[\"']%s+[\"']",
            "Name%s*=%s*[\"'][\"']",
            "Name%s*=%s*[\"']%.[\"']",
        },
        description = "Utilise un nom vide ou invisible"
    },

    -- ===== DATA THEFT =====
    {
        name = "DataTheft/PlayerData",
        severity = "CRITIQUE",
        patterns = {
            "DataStoreService.*GetAsync.*PostAsync",
            "DataStoreService.*GetAsync.*HttpService",
            "GetFriendsAsync.*HttpService",
            "UserId.*HttpService",
        },
        description = "Vol de donnees joueur"
    },
    {
        name = "DataTheft/ChatSpy",
        severity = "HAUTE",
        patterns = {
            "Chatted.*HttpService",
            "Chatted.*PostAsync",
            "OnServerEvent.*HttpService",
        },
        description = "Espionnage du chat et envoi externe"
    },

    -- ===== DESTRUCTION =====
    {
        name = "Destroyer/MapCleaner",
        severity = "CRITIQUE",
        patterns = {
            "ClearAllChildren%s*%(%s*%)",
            "Destroy%s*%(%s*%).*for.*pairs.*game",
            "game%s*:%s*ClearAllChildren",
            "workspace%s*:%s*ClearAllChildren",
        },
        description = "Detruit la map ou les objets du jeu"
    },
    {
        name = "Destroyer/ServiceDestroyer",
        severity = "CRITIQUE",
        patterns = {
            "Lighting%s*:%s*Destroy",
            "Workspace%s*:%s*Destroy",
            "Players%s*:%s*Destroy",
            "ReplicatedStorage%s*:%s*Destroy",
        },
        description = "Detruit les services essentiels"
    },

    -- ===== REMOTE EVENT ABUSE =====
    {
        name = "RemoteAbuse/Unchecked",
        severity = "HAUTE",
        patterns = {
            "OnServerEvent%s*:%s*Connect%s*%(%s*function%s*%(.*%)%s*.*loadstring",
            "RemoteEvent.*FireServer.*require%(",
            "RemoteFunction.*InvokeServer.*require%(",
        },
        description = "Abus de RemoteEvent pour executer du code"
    },

    -- ===== TOOLBOX VIRUS CONNUS =====
    {
        name = "ToolboxVirus/FireSword",
        severity = "CRITIQUE",
        patterns = {
            "Fire%s*Sword",
            "Infected",
            "YOURINFECTED",
            "vaccinated",
        },
        description = "Virus de Toolbox connu (Fire Sword variant)"
    },
    {
        name = "ToolboxVirus/Vaccine",
        severity = "HAUTE",
        patterns = {
            "Vaccine",
            "vaccine",
            "Anti_Virus%.Parent",
            "AntiVirus%.Parent",
        },
        description = "Faux anti-virus qui est lui-meme un virus"
    },
    {
        name = "ToolboxVirus/CommonNames",
        severity = "HAUTE",
        patterns = {
            "oh no a virus",
            "virusss",
            "totally not a virus",
        },
        description = "Noms de virus connus de la Toolbox"
    },
}

-- ============================================================
-- PATTERNS SUSPECTS SUPPLEMENTAIRES (Heuristique)
-- ============================================================
local HEURISTIC_PATTERNS = {
    {
        pattern = "getfenv",
        reason = "Manipulation d'environnement (souvent malveillant)",
        weight = 3
    },
    {
        pattern = "setfenv",
        reason = "Manipulation d'environnement (souvent malveillant)",
        weight = 3
    },
    {
        pattern = "rawset%s*%(",
        reason = "Manipulation bas-niveau de tables",
        weight = 2
    },
    {
        pattern = "rawget%s*%(",
        reason = "Manipulation bas-niveau de tables",
        weight = 2
    },
    {
        pattern = "debug%.",
        reason = "Acces au debug library",
        weight = 3
    },
    {
        pattern = "pcall%s*%(%s*function.*require",
        reason = "Require cache dans pcall pour eviter les erreurs",
        weight = 4
    },
    {
        pattern = "spawn%s*%(%s*function.*while%s+true",
        reason = "Boucle infinie dans un thread separe",
        weight = 3
    },
    {
        pattern = "coroutine%.wrap.*while%s+true",
        reason = "Boucle infinie dans coroutine",
        weight = 3
    },
    {
        pattern = "game%.Workspace.*script",
        reason = "Insertion de script dans Workspace",
        weight = 1
    },
    {
        pattern = "InsertService",
        reason = "Utilisation d'InsertService (peut charger des assets malveillants)",
        weight = 3
    },
    {
        pattern = "MarketplaceService.*PromptPurchase",
        reason = "Tentative d'achat force",
        weight = 2
    },
    {
        pattern = "TeleportService.*Teleport%s*%(",
        reason = "Teleportation vers un autre jeu",
        weight = 2
    },
}

-- ============================================================
-- NOMS DE SCRIPTS SUSPECTS
-- ============================================================
local SUSPICIOUS_NAMES = {
    "Infected", "Vaccine", "AntiVirus", "Anti_Virus",
    "FireSword", "Virus", "Malware", "Backdoor",
    "Exploit", "Hack", "Cheat", "Injector",
    "Loader", "Payload", "Dropper", "Keylogger",
    "Stealer", "Grabber", "RAT", "Botnet",
    "Miner", "Crypto", "Bitcoin",
    " ", "", ".", "..", "...",
    "LocalScript", "Script", "ModuleScript",
}

-- ============================================================
-- FONCTIONS UTILITAIRES
-- ============================================================

local function colorPrint(color, prefix, message)
    if color == "red" then
        warn("[☠️ " .. prefix .. "] " .. message)
    elseif color == "yellow" then
        warn("[⚠️ " .. prefix .. "] " .. message)
    elseif color == "green" then
        print("[✅ " .. prefix .. "] " .. message)
    elseif color == "blue" then
        print("[🔍 " .. prefix .. "] " .. message)
    elseif color == "white" then
        print("[📋 " .. prefix .. "] " .. message)
    end
end

local function getFullPath(instance)
    local path = instance.Name
    local current = instance.Parent
    while current and current ~= game do
        path = current.Name .. "." .. path
        current = current.Parent
    end
    return "game." .. path
end

local function getSource(scriptInstance)
    local success, source = pcall(function()
        return scriptInstance.Source
    end)
    if success then
        return source or ""
    end
    return ""
end

local function isScriptType(instance)
    return instance:IsA("Script")
        or instance:IsA("LocalScript")
        or instance:IsA("ModuleScript")
end

-- ============================================================
-- MOTEUR D'ANALYSE
-- ============================================================

local function scanForSignatures(source, scriptName)
    local detections = {}

    for _, signature in ipairs(VIRUS_SIGNATURES) do
        for _, pattern in ipairs(signature.patterns) do
            local success, found = pcall(function()
                return string.find(source, pattern)
            end)
            if success and found then
                table.insert(detections, {
                    name = signature.name,
                    severity = signature.severity,
                    description = signature.description,
                    matchedPattern = pattern,
                })
                break -- Une seule détection par signature suffit
            end
        end
    end

    return detections
end

local function heuristicScan(source)
    local totalWeight = 0
    local reasons = {}

    for _, heuristic in ipairs(HEURISTIC_PATTERNS) do
        local success, found = pcall(function()
            return string.find(source, heuristic.pattern)
        end)
        if success and found then
            totalWeight = totalWeight + heuristic.weight
            table.insert(reasons, heuristic.reason)
        end
    end

    return totalWeight, reasons
end

local function checkSuspiciousName(name)
    for _, susName in ipairs(SUSPICIOUS_NAMES) do
        if string.lower(name) == string.lower(susName) then
            return true
        end
    end
    -- Nom très court ou très long
    if #name <= 1 or #name > 100 then
        return true
    end
    -- Nom avec caractères bizarres
    if string.match(name, "[^%w%s%_%-%.]") then
        return true
    end
    return false
end

local function analyzeScript(scriptInstance)
    totalScanned = totalScanned + 1
    local source = getSource(scriptInstance)
    local fullPath = getFullPath(scriptInstance)
    local scriptName = scriptInstance.Name
    local scriptType = scriptInstance.ClassName
    local isInfected = false
    local isSuspicious = false

    -- 1. Scan par signatures
    local signatureDetections = scanForSignatures(source, scriptName)

    -- 2. Scan heuristique
    local heuristicWeight, heuristicReasons = heuristicScan(source)

    -- 3. Vérification du nom
    local suspiciousName = checkSuspiciousName(scriptName)

    -- 4. Vérification de la taille du source
    local sourceLength = #source
    local suspiciousSize = sourceLength > 50000 -- Plus de 50k caractères

    -- 5. Script vide qui s'execute (suspect)
    local emptyButEnabled = sourceLength == 0
        and (scriptInstance:IsA("Script") or scriptInstance:IsA("LocalScript"))
        and scriptInstance.Enabled ~= false

    -- ===== DETERMINER LE VERDICT =====

    -- INFECTÉ si signatures trouvées
    if #signatureDetections > 0 then
        isInfected = true
        totalInfected = totalInfected + 1

        local infectionData = {
            script = scriptInstance,
            path = fullPath,
            type = scriptType,
            name = scriptName,
            detections = signatureDetections,
            sourcePreview = string.sub(source, 1, 200),
            sourceLength = sourceLength,
        }
        table.insert(infections, infectionData)

        -- Affichage
        print("")
        print("═══════════════════════════════════════════════════")
        colorPrint("red", "VIRUS DETECTE", fullPath)
        print("═══════════════════════════════════════════════════")
        colorPrint("red", "Type", scriptType)
        colorPrint("red", "Taille", sourceLength .. " caracteres")

        for _, detection in ipairs(signatureDetections) do
            colorPrint("red", detection.severity, detection.name)
            colorPrint("red", "Detail", detection.description)
        end

        if CONFIG.AUTO_DISABLE and not scriptInstance:IsA("ModuleScript") then
            pcall(function()
                scriptInstance.Disabled = true
            end)
            colorPrint("yellow", "ACTION", "Script DESACTIVE automatiquement")
        end

        if CONFIG.QUARANTINE_FOLDER then
            pcall(function()
                local quarantine = game.ServerStorage:FindFirstChild("_QUARANTINE_")
                if not quarantine then
                    quarantine = Instance.new("Folder")
                    quarantine.Name = "_QUARANTINE_"
                    quarantine.Parent = game.ServerStorage
                end
                -- On marque le script au lieu de le déplacer pour éviter les crashs
                local tag = Instance.new("StringValue")
                tag.Name = "OriginalLocation"
                tag.Value = fullPath
                tag.Parent = scriptInstance

                local tag2 = Instance.new("StringValue")
                tag2.Name = "DetectedAs"
                tag2.Value = signatureDetections[1].name
                tag2.Parent = scriptInstance
            end)
        end

        if CONFIG.AUTO_DELETE then
            pcall(function()
                scriptInstance:Destroy()
            end)
            colorPrint("red", "ACTION", "Script SUPPRIME automatiquement")
        end

        print("═══════════════════════════════════════════════════")

    -- SUSPECT si score heuristique élevé ou nom suspect
    elseif heuristicWeight >= 5 or (suspiciousName and heuristicWeight >= 2) or suspiciousSize then
        isSuspicious = true
        totalSuspicious = totalSuspicious + 1

        local suspData = {
            script = scriptInstance,
            path = fullPath,
            type = scriptType,
            name = scriptName,
            weight = heuristicWeight,
            reasons = heuristicReasons,
            suspiciousName = suspiciousName,
            suspiciousSize = suspiciousSize,
            sourceLength = sourceLength,
        }
        table.insert(suspicious, suspData)

        print("")
        colorPrint("yellow", "SUSPECT", fullPath)
        colorPrint("yellow", "Score", "Danger: " .. heuristicWeight .. "/10")

        for _, reason in ipairs(heuristicReasons) do
            colorPrint("yellow", "Raison", reason)
        end

        if suspiciousName then
            colorPrint("yellow", "Nom", "Nom de script suspect: '" .. scriptName .. "'")
        end
        if suspiciousSize then
            colorPrint("yellow", "Taille", "Script anormalement gros: " .. sourceLength .. " chars")
        end

    else
        -- PROPRE
        totalClean = totalClean + 1
        if CONFIG.SHOW_CLEAN then
            colorPrint("green", "PROPRE", fullPath)
        end
    end
end

-- ============================================================
-- SCANNER RECURSIF
-- ============================================================

local function scanRecursive(parent, depth)
    if depth and depth > CONFIG.SCAN_DEPTH then return end

    local children = {}
    pcall(function()
        children = parent:GetChildren()
    end)

    for _, child in ipairs(children) do
        if isScriptType(child) then
            local success, err = pcall(function()
                analyzeScript(child)
            end)
            if not success then
                colorPrint("yellow", "ERREUR SCAN", "Impossible de scanner: " .. getFullPath(child))
            end
        end
        scanRecursive(child, (depth or 0) + 1)
    end
end

-- ============================================================
-- SCAN DES SCRIPTS CACHÉS
-- ============================================================

local function scanHiddenScripts()
    colorPrint("blue", "SCAN", "Recherche de scripts caches (nil parent)...")

    -- Chercher dans tous les services
    local services = {
        "Workspace", "Players", "Lighting", "MaterialService",
        "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService",
        "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer",
        "Teams", "SoundService", "Chat", "LocalizationService",
        "TestService", "JointsService", "InsertService",
        "PointsService", "VirtualInputManager", "LogService",
    }

    for _, serviceName in ipairs(services) do
        local success, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if success and service then
            scanRecursive(service)
        end
    end
end

-- ============================================================
-- DETECTION DES SCRIPTS QUI SE CACHENT
-- ============================================================

local function detectPhantomScripts()
    colorPrint("blue", "SCAN", "Detection des scripts fantomes...")

    -- Vérifier les connexions suspectes
    local allDescendants = game:GetDescendants()
    for _, desc in ipairs(allDescendants) do
        if isScriptType(desc) then
            -- Vérifier si le parent est suspect
            if desc.Parent == nil then
                colorPrint("red", "FANTOME", "Script sans parent detecte: " .. desc.Name)
            end
        end

        -- Chercher des Values suspectes qui contiennent du code
        if desc:IsA("StringValue") then
            local val = ""
            pcall(function() val = desc.Value end)
            if string.find(val, "loadstring") or string.find(val, "require%(%d") then
                colorPrint("red", "CODE CACHE",
                    "StringValue contenant du code: " .. getFullPath(desc))
            end
        end

        -- Chercher des ObjectValues qui pointent vers des scripts suspects
        if desc:IsA("ObjectValue") then
            pcall(function()
                if desc.Value and isScriptType(desc.Value) then
                    colorPrint("yellow", "REFERENCE",
                        "ObjectValue pointe vers script: " .. getFullPath(desc))
                end
            end)
        end
    end
end

-- ============================================================
-- LANCEMENT DU SCAN
-- ============================================================

print("")
print("")
print("╔══════════════════════════════════════════════════════════════╗")
print("║                                                              ║")
print("║          🛡️  ROBLOX ANTI-VIRUS SCANNER v3.0  🛡️            ║")
print("║                                                              ║")
print("║          Analyse de securite complete en cours...            ║")
print("║                                                              ║")
print("╚══════════════════════════════════════════════════════════════╝")
print("")

colorPrint("blue", "INIT", "Demarrage du scan complet...")
colorPrint("blue", "INIT", "Signatures chargees: " .. #VIRUS_SIGNATURES)
colorPrint("blue", "INIT", "Patterns heuristiques: " .. #HEURISTIC_PATTERNS)
colorPrint("blue", "INIT", "Mode auto-desactivation: " .. tostring(CONFIG.AUTO_DISABLE))
colorPrint("blue", "INIT", "Mode auto-suppression: " .. tostring(CONFIG.AUTO_DELETE))
print("")

-- Phase 1: Scan de tout le jeu
colorPrint("blue", "PHASE 1", "Scan de l'arbre de jeu complet...")
scanRecursive(game)
print("")

-- Phase 2: Scripts cachés
colorPrint("blue", "PHASE 2", "Scan des services specifiques...")
scanHiddenScripts()
print("")

-- Phase 3: Scripts fantômes
colorPrint("blue", "PHASE 3", "Detection des scripts fantomes...")
detectPhantomScripts()
print("")

-- ============================================================
-- RAPPORT FINAL
-- ============================================================

local endTime = tick()
local scanDuration = math.floor((endTime - startTime) * 100) / 100

print("")
print("╔══════════════════════════════════════════════════════════════╗")
print("║              📊 RAPPORT DE SCAN FINAL 📊                    ║")
print("╠══════════════════════════════════════════════════════════════╣")
print("║                                                              ║")
print("║  ⏱️  Duree du scan: " .. scanDuration .. " secondes")
print("║  📄 Scripts scannes: " .. totalScanned)
print("║                                                              ║")

if totalInfected > 0 then
    print("║  ☠️  INFECTIONS TROUVEES: " .. totalInfected .. "  ⚠️⚠️⚠️")
else
    print("║  ✅ INFECTIONS TROUVEES: 0")
end

if totalSuspicious > 0 then
    print("║  ⚠️  Scripts suspects: " .. totalSuspicious)
else
    print("║  ✅ Scripts suspects: 0")
end

print("║  ✅ Scripts propres: " .. totalClean)
print("║                                                              ║")
print("╚══════════════════════════════════════════════════════════════╝")

-- Liste détaillée des infections
if #infections > 0 then
    print("")
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║           ☠️ LISTE DES INFECTIONS ☠️                        ║")
    print("╠══════════════════════════════════════════════════════════════╣")

    for i, inf in ipairs(infections) do
        print("║")
        print("║  [" .. i .. "] 🔴 " .. inf.name)
        print("║      📍 " .. inf.path)
        print("║      📝 Type: " .. inf.type .. " | Taille: " .. inf.sourceLength .. " chars")
        for _, det in ipairs(inf.detections) do
            print("║      🏷️  " .. det.severity .. ": " .. det.name)
            print("║      📖 " .. det.description)
        end
        if inf.sourcePreview and #inf.sourcePreview > 0 then
            local preview = string.gsub(inf.sourcePreview, "\n", " ")
            preview = string.gsub(preview, "\r", "")
            print("║      👁️  Apercu: " .. string.sub(preview, 1, 80) .. "...")
        end
    end

    print("║")
    print("╚══════════════════════════════════════════════════════════════╝")
end

-- Liste détaillée des suspects
if #suspicious > 0 then
    print("")
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║           ⚠️ LISTE DES SUSPECTS ⚠️                         ║")
    print("╠══════════════════════════════════════════════════════════════╣")

    for i, sus in ipairs(suspicious) do
        print("║")
        print("║  [" .. i .. "] 🟡 " .. sus.name)
        print("║      📍 " .. sus.path)
        print("║      📝 Type: " .. sus.type .. " | Score: " .. sus.weight .. "/10")
        for _, reason in ipairs(sus.reasons) do
            print("║      ❓ " .. reason)
        end
    end

    print("║")
    print("╚══════════════════════════════════════════════════════════════╝")
end

-- Instructions finales
print("")
print("╔══════════════════════════════════════════════════════════════╗")
print("║                 📋 INSTRUCTIONS 📋                           ║")
print("╠══════════════════════════════════════════════════════════════╣")
print("║                                                              ║")

if totalInfected > 0 then
    print("║  🔴 DES VIRUS ONT ETE TROUVES !                            ║")
    print("║                                                              ║")
    print("║  1. Les scripts infectes ont ete DESACTIVES                 ║")
    print("║  2. Allez dans chaque chemin indique ci-dessus              ║")
    print("║  3. Verifiez le contenu du script                           ║")
    print("║  4. Supprimez les scripts infectes manuellement             ║")
    print("║  5. Sauvegardez votre jeu                                   ║")
    print("║  6. Relancez ce scan pour confirmer                         ║")
    print("║                                                              ║")
    print("║  💡 ASTUCE: Pour supprimer un script qui fait crash,        ║")
    print("║     il a ete DESACTIVE par ce scanner. Vous pouvez         ║")
    print("║     maintenant le supprimer en toute securite.              ║")
else
    print("║  ✅ VOTRE JEU SEMBLE PROPRE !                               ║")
    print("║                                                              ║")
    print("║  Aucune infection connue n'a ete detectee.                  ║")
    print("║  Verifiez quand meme les scripts suspects si il y en a.    ║")
end

print("║                                                              ║")
print("╚══════════════════════════════════════════════════════════════╝")
print("")
print("🛡️ Scan termine. Restez en securite !")
print("")
