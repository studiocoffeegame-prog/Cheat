--[[
    🗑️ SUPPRESSEUR FORCE DE VIRUS
    Coller dans Command Bar APRES le scan
    Supprime tous les scripts desactives qui sont tagges comme virus
]]

print("🗑️ SUPPRESSEUR FORCE - Demarrage...")

local destroyed = 0
local errors = 0

-- Methode 1: Chercher tous les scripts désactivés avec tag
for _, desc in ipairs(game:GetDescendants()) do
    pcall(function()
        if (desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript")) then
            local tag = desc:FindFirstChild("DetectedAs")
            if tag then
                local path = desc:FindFirstChild("OriginalLocation")
                local pathStr = path and path.Value or "inconnu"
                
                print("🗑️ Suppression: " .. desc.Name .. " (" .. pathStr .. ")")
                
                -- Désactiver d'abord
                pcall(function() desc.Disabled = true end)
                
                -- Vider le source
                pcall(function() desc.Source = "" end)
                
                -- Supprimer
                pcall(function() desc:Destroy() end)
                
                destroyed = destroyed + 1
            end
        end
    end)
end

-- Methode 2: Chercher les scripts avec noms suspects connus
local virusNames = {
    "Infected", "Vaccine", "AntiVirus", "Anti_Virus",
    "FireSword", "Virus", "Malware", "Backdoor",
}

for _, desc in ipairs(game:GetDescendants()) do
    pcall(function()
        if (desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript")) then
            for _, vName in ipairs(virusNames) do
                if string.lower(desc.Name) == string.lower(vName) then
                    print("🗑️ Suppression (nom suspect): " .. desc.Name)
                    pcall(function() desc.Disabled = true end)
                    pcall(function() desc.Source = "" end)
                    pcall(function() desc:Destroy() end)
                    destroyed = destroyed + 1
                    break
                end
            end
        end
    end)
end

-- Nettoyer le dossier quarantaine
pcall(function()
    local q = game.ServerStorage:FindFirstChild("_QUARANTINE_")
    if q then q:Destroy() end
end)

print("")
print("═══════════════════════════════════════════════")
print("🗑️ SUPPRESSION TERMINEE")
print("✅ Scripts supprimes: " .. destroyed)
print("💡 Sauvegardez votre jeu maintenant !")
print("💡 Relancez le scanner pour verifier")
print("═══════════════════════════════════════════════")
