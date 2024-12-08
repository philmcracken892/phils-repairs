local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-weapons:server:repairweapon', function(serial, cost)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    
    if Player.Functions.RemoveMoney('cash', cost) then
        
        local repairedWeapon = {
            serial = serial,
            hash = GetHashKey(serial), 
            durability = 100
        }

        TriggerClientEvent('rsg-weapons:client:receiveRepairedWeapon', src, repairedWeapon)
        TriggerClientEvent('lib.notify', src, {
            title = "Weapon Repaired",
            description = "Your weapon has been repaired for $" .. cost .. ".",
            type = 'success',
            duration = 5000
        })
    else
        -- Notify the player if they lack funds
        TriggerClientEvent('lib.notify', src, {
            title = "Insufficient Funds",
            description = "You don't have enough money to repair this weapon.",
            type = 'error',
            duration = 5000
        })
    end
end)

