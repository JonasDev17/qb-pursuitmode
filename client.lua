local QBCore = exports["qb-core"]:GetCoreObject()

local gear = 1
local currentVehicle = 0
local currentVehicleMode = Config.VehicleModes[1]
local playerJob = {['name'] = 'unemployed'}
local hashModelMap = {}

function GetVehicleMode()
    return currentVehicleMode
end

local function fixVehicleHandling(veh)
    -- Necessary to apply the HandlingFloat
    -- Source: https://forum.cfx.re/t/cant-change-setvehiclehandlingfloat-transforming-vehicle-to-awd-fivem-bug/3393188/2

    SetVehicleModKit(veh,0)

    SetVehicleMod(veh,0,GetVehicleMod(veh,0),false)

    SetVehicleMod(veh,1,GetVehicleMod(veh,1),false)

    SetVehicleMod(veh,2,GetVehicleMod(veh,2),false)

    SetVehicleMod(veh,3,GetVehicleMod(veh,3),false)

    SetVehicleMod(veh,4,GetVehicleMod(veh,4),false)

    SetVehicleMod(veh,5,GetVehicleMod(veh,5),false)

    SetVehicleMod(veh,6,GetVehicleMod(veh,6),false)

    SetVehicleMod(veh,7,GetVehicleMod(veh,7),false)

    SetVehicleMod(veh,8,GetVehicleMod(veh,8),false)

    SetVehicleMod(veh,9,GetVehicleMod(veh,9),false)

    SetVehicleMod(veh,10,GetVehicleMod(veh,10),false)

    SetVehicleMod(veh,11,GetVehicleMod(veh,11),false)

    SetVehicleMod(veh,12,GetVehicleMod(veh,12),false)

    SetVehicleMod(veh,13,GetVehicleMod(veh,13),false)

    SetVehicleMod(veh,15,GetVehicleMod(veh,15),false)

    SetVehicleMod(veh,16,GetVehicleMod(veh,16),false)

    SetVehicleMod(veh,25,GetVehicleMod(veh,25),false)

    SetVehicleMod(veh,27,GetVehicleMod(veh,27),false)

    SetVehicleMod(veh,28,GetVehicleMod(veh,28),false)

    SetVehicleMod(veh,30,GetVehicleMod(veh,30),false)

    SetVehicleMod(veh,33,GetVehicleMod(veh,33),false)

    SetVehicleMod(veh,34,GetVehicleMod(veh,34),false)

    SetVehicleMod(veh,35,GetVehicleMod(veh,35),false)

    SetVehicleWheelIsPowered(veh,0,true)

    SetVehicleWheelIsPowered(veh,1,true)

    SetVehicleWheelIsPowered(veh,2,true)

    SetVehicleWheelIsPowered(veh,3,true)
end

-- this maps the configured model names to their respective hashes
-- this is required because you cannot get the model from a car reliably
local function setupModelHashMap()
    for k,v in pairs(Config.VehiclesConfig) do
        hashModelMap[GetHashKey(k)] = k
    end
end

local function getModelFromHash(hash)
    return hashModelMap[hash]
end

local function isValidVehicle(vehicle)
    if Config.UseGeneralVehicleConfig then 
        if Config.EmergencyVehiclesOnly then
            return GetVehicleClass(vehicle) == 17
        end
        return true
    end
    local vehicleHash = GetEntityModel(vehicle)
    local vehicleModel = getModelFromHash(vehicleHash)
    return Config.VehiclesConfig[vehicleModel]
end

local function getHandlingConfig(vehicleHash)
    local vehicleModel = getModelFromHash(vehicleHash)
    if Config.VehiclesConfig[vehicleModel] then
        return Config.VehiclesConfig[vehicleModel][currentVehicleMode]
    end
end

local function getGeneralHandlingConfig()
    if Config.GeneralVehicleConfig then
        return Config.GeneralVehicleConfig[currentVehicleMode]
    end
end

local function updateHandling(vehicle)
    local handlingConfig = getHandlingConfig(GetEntityModel(vehicle))
    if Config.UseGeneralVehicleConfig and not handlingConfig then
        handlingConfig = getGeneralHandlingConfig()
    end
    for k,v in pairs(handlingConfig) do
        if math.type(v) == 'float' then
            SetVehicleHandlingFloat(vehicle, "CHandlingData", k, v)
        elseif math.type(v) == 'integer' then
            SetVehicleHandlingInt(vehicle, "CHandlingData", k, v)
        elseif type(v) == 'vector3' then
            SetVehicleHandlingVector(vehicle, "CHandlingData", k, v)
        end
    end
    fixVehicleHandling(vehicle)
end

local function applyVehicleMods(vehicle)
    local vehicleMode = Config.VehicleModes[gear]
    
    ToggleVehicleMod(vehicle, 18, Config["VehicleModifications"][vehicleMode]["Turbo"]) -- Turbo
    ToggleVehicleMod(vehicle, 22, Config["VehicleModifications"][vehicleMode]["XenonHeadlights"]) -- Xenon Headlights
    SetVehicleMod(vehicle, 11, Config["VehicleModifications"][vehicleMode]["Engine"], false) -- Engine
    SetVehicleMod(vehicle, 12, Config["VehicleModifications"][vehicleMode]["Brakes"], false) -- Brakes
    SetVehicleMod(vehicle, 13, Config["VehicleModifications"][vehicleMode]["Transmission"], false) -- Transmission
    SetVehicleXenonLightsColour(vehicle, Config["VehicleModifications"][vehicleMode]["XenonHeadlightsColor"]) -- Xenon Headlights Color

    if Config.SlowdownOnSwitch then
        local speed = GetEntitySpeed(vehicle)
        SetVehicleForwardSpeed(vehicle, speed * (1.0 - Config.SlowdownPercentage))
    end
end

local function changeVehicleMode(vehicle)
    gear = gear % #Config.VehicleModes + 1
    if vehicle ~= currentVehicle then
        gear = 1
    end
    currentVehicle = vehicle
    currentVehicleMode = Config.VehicleModes[gear]
    TriggerEvent('qb-pursuitmode:vehicleModeChanged', currentVehicleMode)
end

local function updatePlayerInfo()
    local playerData = QBCore.Functions.GetPlayerData()
    playerJob = playerData.job
end

local function isAuthorizedToSwitchMode()
    if next(Config.AuthorizedJobs) == nil then -- No jobs defined
        return true
    end
    for i, v in ipairs(Config.AuthorizedJobs) do
        if playerJob.name == v then
            return true
        end
    end
    return false
end

local function playSound(vehicle)
    if Config.PlayServerSyncedSound then
        local maxSoundDistance = Config.MaxSoundDistance
        local speed = GetEntitySpeed(vehicle)
        if speed > 30.0 then
            maxSoundDistance = Config.MaxSoundDistanceAtMediumSpeeds
        elseif speed > 70.0 then 
            maxSoundDistance = Config.MaxSoundDistanceAtHighSpeeds
        end
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', maxSoundDistance, Config.SoundFile, Config.SoundVolume)
    else
        TriggerEvent('InteractSound_CL:PlayOnOne', Config.SoundFile, Config.SoundVolume)
    end
end

RegisterNetEvent('qb-pursuitmode:client:changeVehicleMode')
AddEventHandler('qb-pursuitmode:client:changeVehicleMode', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local vehicle = GetVehiclePedIsIn(ped)
        if DoesEntityExist(vehicle) and isValidVehicle(vehicle) and isAuthorizedToSwitchMode() then
            changeVehicleMode(vehicle)
            updateHandling(vehicle)
            applyVehicleMods(vehicle)
            if Config.PlaySoundOnSwitch then playSound(vehicle) end
            QBCore.Functions.Notify((Config.SwitchNotification):format(currentVehicleMode))
        end
    end
end)

-- used for when restarting the script, will fetch the players job again and update the modelHashMap
AddEventHandler('onClientResourceStart', function (resourceName)
    if(GetCurrentResourceName() ~= resourceName) then
      return
    end
    updatePlayerInfo()
    setupModelHashMap()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    playerJob = JobInfo
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    updatePlayerInfo()
    setupModelHashMap()
end)


RegisterCommand("pursuitmode", function(source, args, rawCommand)
    TriggerEvent('qb-pursuitmode:client:changeVehicleMode')
end, false)

RegisterKeyMapping('pursuitmode', 'Change pursuitmode (POLICE ONLY)', 'keyboard', Config.DefaultKey)
