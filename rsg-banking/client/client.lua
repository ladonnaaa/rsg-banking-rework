local RSGCore = exports['rsg-core']:GetCoreObject()
local BankOpen = false
local SpawnedBankBlips = {}
local cinematicCam = nil
local activeClerkPed = nil

lib.locale()

CreateThread(function()
    for _,v in pairs(Config.BankLocations) do
        if not Config.UseTarget then
            exports['rsg-core']:createPrompt(v.bankid, v.coords, RSGCore.Shared.Keybinds[Config.Keybind], locale('open_bank'), {
                type = 'client',
                event = 'rsg-banking:client:OpenBanking',
                args = { v.moneytype },
            })
        end
        if v.showblip then
            local blip = BlipAddForCoords(1664425300, v.coords)
            SetBlipSprite(blip, joaat(v.blipsprite), true)
            SetBlipScale(blip, v.blipscale)
            SetBlipName(blip, v.name)
            table.insert(SpawnedBankBlips, blip)
        end
    end

    for _,v in pairs(Config.BankDoors) do
        AddDoorToSystemNew(v.door, 1, 1, 0, 0, 0, 0)
        DoorSystemSetDoorState(v.door, v.state)
    end
end)

local function GetBankHours()
    local hour = GetClockHours()
    local isClosed = not Config.AlwaysOpen and (hour < Config.OpenTime or hour >= Config.CloseTime)
    
    for _, blip in pairs(SpawnedBankBlips) do
        if isClosed then
            BlipAddModifier(blip, joaat('BLIP_MODIFIER_MP_COLOR_2'))
        else
            BlipAddModifier(blip, joaat('BLIP_MODIFIER_MP_COLOR_8'))
        end
    end
end

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', GetBankHours)

CreateThread(function()
    while true do
        GetBankHours()
        Wait(60000)
    end
end)

local function EnableCinematicCamera(npcCoords)
    local playerPed = cache.ped
    local pCoords = GetEntityCoords(playerPed)
    
    cinematicCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local forward = GetEntityForwardVector(playerPed)
    local camCoords = pCoords + (forward * 1.5) + vector3(0.5, 0.0, 0.6)
    
    SetCamCoord(cinematicCam, camCoords.x, camCoords.y, camCoords.z)
    PointCamAtCoord(cinematicCam, pCoords.x, pCoords.y, pCoords.z + 0.3)
    SetCamActive(cinematicCam, true)
    RenderScriptCams(true, true, 1200, true, true)
    
    SetTimecycleModifier('hud_def_blur')
    SetTimecycleModifierStrength(1.0)
end

local function CloseBank()
    SendNUIMessage({action = "CLOSE_BANK"})
    SetNuiFocus(false, false)
    BankOpen = false
    
    ClearPedTasks(cache.ped)
    if activeClerkPed and DoesEntityExist(activeClerkPed) then
        ClearPedTasks(activeClerkPed)
    end
    
    RenderScriptCams(false, true, 1000, true, false)
    if cinematicCam then
        DestroyCam(cinematicCam, false)
        cinematicCam = nil
    end
    ClearTimecycleModifier()
end

local function OpenBank(moneytype, ped)
    if not Config.AlwaysOpen then
        local hour = GetClockHours()
        if hour < Config.OpenTime or hour >= Config.CloseTime then
            lib.notify({ title = locale('bank_closed'), description = locale('come_back_at') .. ' ' .. Config.OpenTime .. ':00', type = 'error', icon = 'fa-solid fa-lock', duration = 5000 })
            return
        end
    end

    RSGCore.Functions.TriggerCallback('rsg-banking:getBankingInformation', function(data)
        if data then
            activeClerkPed = ped
            
            TaskStartScenarioInPlace(cache.ped, joaat('WORLD_HUMAN_STAND_WAITING'), -1, true, false, false, false)
            if activeClerkPed then
                TaskStartScenarioInPlace(activeClerkPed, joaat('WORLD_HUMAN_WRITE_NOTEBOOK'), -1, true, false, false, false)
            end
            
            EnableCinematicCamera()

            SendNUIMessage({
                action = "OPEN_BANK", 
                balance = data.bank, 
                savings = data.savings,
                cash = data.cash, 
                loan = data.loan,
                blacklisted = data.blacklisted,
                logs = data.logs,
                id = moneytype, 
                playerName = data.name,
                chargeRate = Config.WithdrawChargeRate
            })
            
            SetNuiFocus(true, true)
            BankOpen = true

            CreateThread(function()
                local startCoords = GetEntityCoords(cache.ped)
                while BankOpen do
                    Wait(1000)
                    if #(GetEntityCoords(cache.ped) - startCoords) > 2.0 then
                        CloseBank()
                        lib.notify({ title = locale('walked_away'), type = 'warning'})
                    end
                end
            end)
        end
    end, moneytype)
end

RegisterNUICallback('CloseNUI', function(_, cb)
    CloseBank()
    cb('ok')
end)

RegisterNUICallback('SafeDeposit', function(_, cb)
    CloseBank()
    TriggerEvent('rsg-banking:client:safedeposit')
    cb('ok')
end)

RegisterNUICallback('Transact', function(data, cb)
    TriggerServerEvent('rsg-banking:server:transact', data.type, data.amount, data.id)
    cb('ok')
end)

RegisterNetEvent('rsg-banking:client:UpdateUI', function(data)
    if not BankOpen then return end
    SendNUIMessage({
        action = "UPDATE_DATA",
        balance = data.bank,
        cash = data.cash,
        savings = data.savings,
        loan = data.loan,
        logs = data.logs
    })
end)

RegisterNetEvent('rsg-banking:client:UIMessage', function(title, desc, colorType)
    if not BankOpen then return end
    SendNUIMessage({
        action = "SHOW_STAMP",
        text = title,
        subtext = desc,
        color = colorType
    })
end)

AddEventHandler('rsg-banking:client:OpenBanking', function(moneytype)
    OpenBank(moneytype, nil)
end)

AddEventHandler('rsg-banking:client:InteractBanker', function(data)
    OpenBank(data.moneytype, data.entity)
end)

RegisterNetEvent('rsg-banking:client:safedeposit', function()
    local x, y, z = table.unpack(GetEntityCoords(cache.ped))
    local town = GetMapZoneAtCoords(x, y, z, 1)

    local zones = {
        [-744494798] = 'Armadillo',
        [1053078005] = 'Blackwater',
        [2046780049] = 'Rhodes',[-765540529] = 'SaintDenis',[459833523] = 'Valentine'
    }

    town = zones[town] or town
    TriggerServerEvent('rsg-banking:server:opensafedeposit', town)
end)

exports['ox_target']:addGlobalPlayer({
    {
        name = 'give_money',
        label = locale('give_money'),
        icon = 'fas fa-money-bill-wave',
        distance = 2.0,
        onSelect = function(data)
            local targetEntity = data.entity
            if IsEntityAPed(targetEntity) and IsPedAPlayer(targetEntity) then
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetEntity))
                if targetServerId and targetServerId > 0 then
                    local input = lib.inputDialog(locale('give_money_title'), {{ type = 'number', label = locale('amount') }})
                    if input and input[1] and tonumber(input[1]) > 0 then
                        TriggerServerEvent('rsg-banking:server:givemoney', targetServerId, tonumber(input[1]))
                    else
                        lib.notify({ title = locale('invalid_amount'), type = 'error' })
                    end
                end
            end
        end,
    }
})