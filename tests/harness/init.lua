local WowAPI = require("tests.harness.wow_api")
local Assertions = require("tests.harness.assertions")

local Harness = {}

Harness.WowAPI = WowAPI
Harness.Assertions = Assertions

function Harness.loadAddonCore(addonName, options)
    options = options or {}

    WowAPI.reset()
    WowAPI.install()

    if options.metadata then
        WowAPI._state.metadata[addonName] = options.metadata
    end

    if options.locale then
        WowAPI._state.locale = options.locale
    end

    if options.isLoggedIn ~= nil then
        WowAPI._state.isLoggedIn = options.isLoggedIn
    end

    if options.inCombat ~= nil then
        WowAPI._state.inCombat = options.inCombat
    end

    local chunk, err = loadfile("AddonCore.lua")
    if not chunk then
        error("Failed to load AddonCore.lua: " .. tostring(err))
    end

    local addonTable = {}
    chunk(addonName, addonTable)

    local addon = _G[addonName]
    return addon, WowAPI
end

function Harness.triggerAddonLoaded(addonName)
    WowAPI.FireEvent("ADDON_LOADED", addonName)
end

function Harness.triggerPlayerLogin()
    WowAPI._state.isLoggedIn = true
    WowAPI.FireEvent("PLAYER_LOGIN")
end

function Harness.enterCombat()
    WowAPI._state.inCombat = true
end

function Harness.exitCombat()
    WowAPI._state.inCombat = false
    WowAPI.FireEvent("PLAYER_REGEN_ENABLED")
end

return Harness
