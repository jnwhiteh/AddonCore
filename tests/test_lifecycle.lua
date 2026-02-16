local Harness = require("tests.harness.init")
local A = Harness.Assertions

local Tests = {}

function Tests.test_initialize_called_on_addon_loaded()
    local addon = Harness.loadAddonCore("TestAddon")
    local initCalled = false

    addon.Initialize = function(self)
        initCalled = true
    end

    A.assertFalse(addon:IsInitialized(), "Not initialized before ADDON_LOADED")

    Harness.triggerAddonLoaded("TestAddon")

    A.assertTrue(initCalled, "Initialize should be called")
    A.assertTrue(addon:IsInitialized(), "IsInitialized should return true")
end

function Tests.test_enable_called_on_player_login()
    local addon = Harness.loadAddonCore("TestAddon")
    local enableCalled = false

    addon.Enable = function(self)
        enableCalled = true
    end

    Harness.triggerAddonLoaded("TestAddon")
    A.assertFalse(enableCalled, "Enable not called before PLAYER_LOGIN")

    Harness.triggerPlayerLogin()
    A.assertTrue(enableCalled, "Enable should be called on PLAYER_LOGIN")
end

function Tests.test_late_loaded_addon_calls_enable_immediately()
    local addon = Harness.loadAddonCore("TestAddon", {isLoggedIn = true})
    local initCalled = false
    local enableCalled = false

    addon.Initialize = function(self)
        initCalled = true
    end
    addon.Enable = function(self)
        enableCalled = true
    end

    Harness.triggerAddonLoaded("TestAddon")

    A.assertTrue(initCalled, "Initialize should be called")
    A.assertTrue(enableCalled, "Enable should be called immediately for late-loaded addon")
end

function Tests.test_initialize_only_responds_to_own_addon()
    local addon = Harness.loadAddonCore("TestAddon")
    local initCalled = false

    addon.Initialize = function(self)
        initCalled = true
    end

    Harness.triggerAddonLoaded("SomeOtherAddon")

    A.assertFalse(initCalled, "Should not initialize for other addon")
    A.assertFalse(addon:IsInitialized(), "Should not be initialized")
end

function Tests.test_initialize_and_enable_order()
    local addon = Harness.loadAddonCore("TestAddon")
    local callOrder = {}

    addon.Initialize = function(self)
        table.insert(callOrder, "init")
    end
    addon.Enable = function(self)
        table.insert(callOrder, "enable")
    end

    Harness.triggerAddonLoaded("TestAddon")
    Harness.triggerPlayerLogin()

    A.assertEquals(2, #callOrder, "Both should be called")
    A.assertEquals("init", callOrder[1], "Initialize first")
    A.assertEquals("enable", callOrder[2], "Enable second")
end

function Tests.test_enable_not_called_twice()
    local addon = Harness.loadAddonCore("TestAddon")
    local enableCount = 0

    addon.Enable = function(self)
        enableCount = enableCount + 1
    end

    Harness.triggerAddonLoaded("TestAddon")
    Harness.triggerPlayerLogin()
    Harness.triggerPlayerLogin()

    A.assertEquals(1, enableCount, "Enable should only be called once")
end

return Tests
