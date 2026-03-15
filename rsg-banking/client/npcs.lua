local spawnedPeds = {}
local spawnedGuards = {}

CreateThread(function()
    while true do
        Wait(1000)
        local playerCoords = GetEntityCoords(cache.ped)
        
        for k, v in pairs(Config.BankLocations) do
            local distance = #(playerCoords - v.npccoords.xyz)

            if distance < Config.DistanceSpawn and not spawnedPeds[k] then
                RequestModel(v.npcmodel)
                while not HasModelLoaded(v.npcmodel) do Wait(10) end
                
                local ped = CreatePed(v.npcmodel, v.npccoords.x, v.npccoords.y, v.npccoords.z - 1.0, v.npccoords.w, false, false, 0, 0)
                SetEntityAlpha(ped, 0, false)
                SetRandomOutfitVariation(ped, true)
                SetEntityCanBeDamaged(ped, false)
                SetEntityInvincible(ped, true)
                FreezeEntityPosition(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                
                if Config.FadeIn then
                    for i = 0, 255, 51 do
                        Wait(50)
                        SetEntityAlpha(ped, i, false)
                    end
                else
                    SetEntityAlpha(ped, 255, false)
                end

                if Config.UseTarget then
                    exports.ox_target:addLocalEntity(ped, {
                        {
                            name = 'banking_npc_' .. k,
                            icon = 'fas fa-coins',
                            label = locale('open_bank'),
                            moneytype = v.moneytype,
                            event = 'rsg-banking:client:InteractBanker',
                            distance = 2.5
                        }
                    })
                end

                spawnedPeds[k] = ped

                if v.hasGuard and v.guardmodel then
                    RequestModel(v.guardmodel)
                    while not HasModelLoaded(v.guardmodel) do Wait(10) end
                    local guard = CreatePed(v.guardmodel, v.guardcoords.x, v.guardcoords.y, v.guardcoords.z - 1.0, v.guardcoords.w, false, false, 0, 0)
                    SetRandomOutfitVariation(guard, true)
                    GiveWeaponToPed_2(guard, joaat('WEAPON_REPEATER_WINCHESTER'), 100, true, true, 0, false, 0.5, 1.0, 0, true, 0, 0)
                    SetCurrentPedWeapon(guard, joaat('WEAPON_REPEATER_WINCHESTER'), true)
                    TaskStartScenarioInPlace(guard, joaat('WORLD_HUMAN_GUARD_STAND'), -1, true, false, false, false)
                    SetEntityInvincible(guard, true)
                    SetBlockingOfNonTemporaryEvents(guard, true)
                    FreezeEntityPosition(guard, true)
                    spawnedGuards[k] = guard
                end
            end
            
            if distance >= Config.DistanceSpawn and spawnedPeds[k] then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedPeds[k], i, false)
                    end
                end
                DeletePed(spawnedPeds[k])
                spawnedPeds[k] = nil
                
                if spawnedGuards[k] then
                    DeletePed(spawnedGuards[k])
                    spawnedGuards[k] = nil
                end
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k, ped in pairs(spawnedPeds) do DeletePed(ped) end
    for k, guard in pairs(spawnedGuards) do DeletePed(guard) end
end)