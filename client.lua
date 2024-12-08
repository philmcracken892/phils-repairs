local RSGCore = exports['rsg-core']:GetCoreObject()

-- Function to spawn repair NPC
function SpawnRepairNPC(location)
    -- Define the NPC model
    local npcModel = "msp_braithwaites1_males_01" -- Updated to a guaranteed valid model
    local modelHash = GetHashKey(npcModel)

    -- Validate model hash
    if not IsModelValid(modelHash) then
        print("Invalid NPC model!")
        return nil
    end

    -- Load the model
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            print("Failed to load NPC model!")
            return nil
        end
    end

    
    local distanceBehind = -0.5
    local radians = math.rad(location.heading)
    local offsetX = -distanceBehind * math.sin(radians)
    local offsetY = distanceBehind * math.cos(radians)

    local spawnX = location.coords.x - offsetX
    local spawnY = location.coords.y - offsetY
    local spawnZ = location.coords.z + 0.0 

    
    local npc = CreatePed(modelHash, spawnX, spawnY, spawnZ, location.heading, false, false, false, false)

    
    if not npc or npc == 0 then
        print("Failed to create NPC!")
        return nil
    end

    
    PlaceObjectOnGroundProperly(npc)

    
    SetEntityAlpha(npc, 255, false) 
    SetEntityAsMissionEntity(npc, true, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    SetRandomOutfitVariation(npc, true) 
    SetEntityVisible(npc, true, 0) 
    Citizen.InvokeNative(0x283978A15512B2FE, npc, true) 

   
    SetModelAsNoLongerNeeded(modelHash)

   
    return npc
end

local function addBlipForCoords(blipName, blipHash, coords)
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords[1], coords[2], coords[3])
    SetBlipSprite(blip, blipHash, true)
    SetBlipScale(blip, 0.8)  
	BlipAddModifier(blip, joaat('BLIP_MODIFIER_MP_COLOR_8'))
	SetBlipName(blip, "Weapon Repair")
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipName)  -- Set the blip name
end

local repairNPCLocation = {
    coords = vector3(-277.19, 778.21, 119.50 -1),
    heading = 90.0
}





CreateThread(function()
    
    
    
    Wait(5000)
    
   
    
    local repairNPC = SpawnRepairNPC(repairNPCLocation)
    
    if repairNPC and DoesEntityExist(repairNPC) then
		addBlipForCoords("Weapon Repair", GetHashKey("BLIP_AMBIENT_HORSE"), repairNPCLocation.coords)	
        
        
       
        if exports['rsg-target'] then
            exports['rsg-target']:AddTargetEntity(repairNPC, {
                options = {
                    {
                        type = "client",
                        event = "rsg-weapons:client:triggerWeaponRepairMenu",
                        icon = "fas fa-wrench",
                        label = "Repair Weapon",
                    }
                },
                distance = 2.5
            })
        end
    else
        
    end
end)

RegisterNetEvent('rsg-weapons:client:triggerWeaponRepairMenu', function()
    local Player = RSGCore.Functions.GetPlayerData()
    local weapons = {}

    -- Collect repairable weapons
    for _, item in pairs(Player.items) do
        if item.type == "weapon" and item.info and item.info.quality < 100 then
            local repairCost = math.floor((100 - item.info.quality) * 2.5) -- Adjust multiplier as needed
            table.insert(weapons, {
                label = item.label .. " (Quality: " .. item.info.quality .. "%, Cost: $" .. repairCost .. ")",
                serial = item.info.serie,
                cost = repairCost
            })
        end
    end

    -- Notify if no weapons need repair
    if #weapons == 0 then
        lib.notify({
            title = "No Repairable Weapons",
            description = "You have no damaged weapons in your inventory.",
            type = 'error',
            duration = 5000
        })
        return
    end

    -- Prepare menu options
    local options = {}
    for _, weapon in ipairs(weapons) do
        table.insert(options, {
            title = weapon.label,
            description = "Repair this weapon for $" .. weapon.cost .. ".",
            icon = "fas fa-wrench",
            onSelect = function()
                -- Display Progress Bar
                lib.progressBar({
                    duration = Config.RepairTime or 5000, -- Time in ms
                    label = "Repairing Weapon...",
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        move = true,
                        car = true,
                        combat = true,
                        mouse = false,
                        sprint = true,
                    }
                })
                -- Trigger Server-Side Repair
                TriggerServerEvent('rsg-weapons:server:repairweapon', weapon.serial, weapon.cost)
            end
        })
    end

    -- Add cancel option
    table.insert(options, {
        title = "Cancel",
        icon = "fas fa-times",
        onSelect = function()
            lib.notify({
                title = "Action Cancelled",
                description = "You decided not to repair any weapons.",
                type = 'inform',
                duration = 3000
            })
        end
    })

    -- Display the menu
    lib.registerContext({
        id = 'repair_weapon_menu',
        title = "Repair Weapon",
        options = options
    })
    lib.showContext('repair_weapon_menu')
end)




RegisterNetEvent('rsg-weapons:client:refreshInventory', function()
    RSGCore.Functions.GetPlayerData() 
end)


RegisterNetEvent('rsg-weapons:client:triggerWeaponRepair', function()
    local Player = RSGCore.Functions.GetPlayerData()
    local weaponToRepair = nil
    local weaponSerial = nil

    
    for _, item in pairs(Player.items) do
        if item.type == "weapon" and item.info and item.info.quality < 100 then
            weaponToRepair = item
            weaponSerial = item.info.serie
            break 
        end
    end

    if weaponToRepair and weaponSerial then
        
        lib.progressBar({
            duration = Config.RepairTime,
            label = "Repairing Weapon...",
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = true,
                car = true,
                combat = true,
                mouse = false,
                sprint = true,
            }
        })

        -- Trigger the server-side repair event with the weapon's serial
        TriggerServerEvent('rsg-weapons:server:repairweapon', weaponSerial)
    else
        -- Notify the player if no repairable weapons are found
        lib.notify({
            title = "No Repairable Weapons",
            description = "You have no damaged weapons in your inventory.",
            type = 'error',
            duration = 5000
        })
    end
end)



RegisterNetEvent('rsg-weapons:client:receiveRepairedWeapon', function(repairedWeapon)
    GiveWeaponToPed(cache.ped, repairedWeapon.hash, 0, false, true)
    --SetWeaponDurability(repairedWeapon.hash, repairedWeapon.durability)
end)
