local Harness = require("tests.harness.init")
local A = Harness.Assertions

local Tests = {}

function Tests.test_L_auto_vivifies_missing_keys()
    local addon = Harness.loadAddonCore("TestAddon")
    Harness.triggerAddonLoaded("TestAddon")

    local result = addon.L["MISSING_KEY"]

    A.assertEquals("MISSING_KEY", result, "Missing key returns itself")
end

function Tests.test_L_caches_auto_vivified_keys()
    local addon = Harness.loadAddonCore("TestAddon")
    Harness.triggerAddonLoaded("TestAddon")

    local _ = addon.L["CACHE_KEY"]
    local cached = rawget(addon.L, "CACHE_KEY")

    A.assertEquals("CACHE_KEY", cached, "Key should be cached")
end

function Tests.test_register_locale_enUS_always_applied()
    local addon = Harness.loadAddonCore("TestAddon", {locale = "deDE"})
    Harness.triggerAddonLoaded("TestAddon")

    addon:RegisterLocale("enUS", {
        GREETING = "Hello"
    })

    A.assertEquals("Hello", addon.L["GREETING"], "enUS always applied")
end

function Tests.test_register_locale_matching_applied()
    local addon = Harness.loadAddonCore("TestAddon", {locale = "deDE"})
    Harness.triggerAddonLoaded("TestAddon")

    addon:RegisterLocale("deDE", {
        GREETING = "Hallo"
    })

    A.assertEquals("Hallo", addon.L["GREETING"], "Matching locale applied")
end

function Tests.test_register_locale_non_matching_ignored()
    local addon = Harness.loadAddonCore("TestAddon", {locale = "enUS"})
    Harness.triggerAddonLoaded("TestAddon")

    addon:RegisterLocale("frFR", {
        GREETING = "Bonjour"
    })

    local result = addon.L["GREETING"]
    A.assertEquals("GREETING", result, "Non-matching locale ignored, returns key")
end

function Tests.test_true_value_maps_key_to_itself()
    local addon = Harness.loadAddonCore("TestAddon")
    Harness.triggerAddonLoaded("TestAddon")

    addon:RegisterLocale("enUS", {
        SELF_KEY = true
    })

    A.assertEquals("SELF_KEY", addon.L["SELF_KEY"], "true maps key to itself")
end

function Tests.test_metatable_newindex_handles_true()
    local addon = Harness.loadAddonCore("TestAddon")
    Harness.triggerAddonLoaded("TestAddon")

    addon.L["DIRECT_TRUE"] = true

    A.assertEquals("DIRECT_TRUE", addon.L["DIRECT_TRUE"], "Direct true assignment maps to key")
end

function Tests.test_register_locale_string_value()
    local addon = Harness.loadAddonCore("TestAddon")
    Harness.triggerAddonLoaded("TestAddon")

    addon:RegisterLocale("enUS", {
        BUTTON_OK = "OK",
        BUTTON_CANCEL = "Cancel"
    })

    A.assertEquals("OK", addon.L["BUTTON_OK"], "String value applied")
    A.assertEquals("Cancel", addon.L["BUTTON_CANCEL"], "String value applied")
end

return Tests
