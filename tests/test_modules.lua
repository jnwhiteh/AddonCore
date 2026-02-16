local Harness = require("tests.harness.init")
local A = Harness.Assertions

local Tests = {}

local addon, WowAPI

function Tests.setup()
    addon, WowAPI = Harness.loadAddonCore("TestAddon")
end

function Tests.test_module_receives_evented_mixin()
    Harness.triggerAddonLoaded("TestAddon")

    local module = {}
    addon:RegisterModule(module, "TestModule")

    A.assertNotNil(module.RegisterEvent, "Module should have RegisterEvent")
    A.assertNotNil(module.UnregisterEvent, "Module should have UnregisterEvent")
    A.assertNotNil(module.RegisterUnitEvent, "Module should have RegisterUnitEvent")
end

function Tests.test_module_receives_messaged_mixin()
    Harness.triggerAddonLoaded("TestAddon")

    local module = {}
    addon:RegisterModule(module, "TestModule")

    A.assertNotNil(module.RegisterMessage, "Module should have RegisterMessage")
    A.assertNotNil(module.UnregisterMessage, "Module should have UnregisterMessage")
    A.assertNotNil(module.FireMessage, "Module should have FireMessage")
end

function Tests.test_module_receives_lifecycle_callbacks()
    local moduleInitCalled = false
    local moduleEnableCalled = false

    local module = {
        Initialize = function(self)
            moduleInitCalled = true
        end,
        Enable = function(self)
            moduleEnableCalled = true
        end
    }

    addon:RegisterModule(module, "LifecycleModule")
    Harness.triggerAddonLoaded("TestAddon")
    Harness.triggerPlayerLogin()

    A.assertTrue(moduleInitCalled, "Module Initialize should be called")
    A.assertTrue(moduleEnableCalled, "Module Enable should be called")
end

function Tests.test_late_registered_module_gets_init_immediately()
    Harness.triggerAddonLoaded("TestAddon")
    Harness.triggerPlayerLogin()

    local moduleInitCalled = false
    local moduleEnableCalled = false

    local module = {
        Initialize = function(self)
            moduleInitCalled = true
        end,
        Enable = function(self)
            moduleEnableCalled = true
        end
    }

    addon:RegisterModule(module, "LateModule")

    A.assertTrue(moduleInitCalled, "Late module Initialize should be called immediately")
    A.assertTrue(moduleEnableCalled, "Late module Enable should be called immediately")
end

function Tests.test_duplicate_module_registration_throws()
    Harness.triggerAddonLoaded("TestAddon")

    local module = {}
    addon:RegisterModule(module, "DupModule")

    A.assertError(function()
        addon:RegisterModule(module, "DupModule")
    end, "Duplicate module registration should throw")
end

function Tests.test_module_event_registration()
    Harness.triggerAddonLoaded("TestAddon")

    local module = {}
    addon:RegisterModule(module, "EventModule")

    local eventReceived = false
    module:RegisterEvent("MODULE_EVENT", function()
        eventReceived = true
    end)

    WowAPI.FireEvent("MODULE_EVENT")

    A.assertTrue(eventReceived, "Module event handler should be called")
end

function Tests.test_module_message_registration()
    Harness.triggerAddonLoaded("TestAddon")

    local module = {}
    addon:RegisterModule(module, "MsgModule")

    local messageReceived = false
    module:RegisterMessage("MODULE_MSG", function()
        messageReceived = true
    end)

    addon:FireMessage("MODULE_MSG")

    A.assertTrue(messageReceived, "Module message handler should be called")
end

function Tests.test_module_gets_name_set()
    Harness.triggerAddonLoaded("TestAddon")

    local module = {}
    addon:RegisterModule(module, "NamedModule")

    A.assertEquals("NamedModule", module.name, "Module name should be set")
end

function Tests.test_module_initialize_fires_after_addon()
    local callOrder = {}

    addon.Initialize = function()
        table.insert(callOrder, "addon")
    end

    local module = {
        Initialize = function()
            table.insert(callOrder, "module")
        end
    }
    addon:RegisterModule(module, "OrderModule")

    Harness.triggerAddonLoaded("TestAddon")

    A.assertEquals(2, #callOrder, "Both should be called")
    A.assertEquals("addon", callOrder[1], "Addon Initialize first")
    A.assertEquals("module", callOrder[2], "Module Initialize second")
end

function Tests.test_module_enable_fires_after_addon()
    local callOrder = {}

    addon.Enable = function()
        table.insert(callOrder, "addon")
    end

    local module = {
        Enable = function()
            table.insert(callOrder, "module")
        end
    }
    addon:RegisterModule(module, "OrderModule")

    Harness.triggerAddonLoaded("TestAddon")
    Harness.triggerPlayerLogin()

    A.assertEquals(2, #callOrder, "Both should be called")
    A.assertEquals("addon", callOrder[1], "Addon Enable first")
    A.assertEquals("module", callOrder[2], "Module Enable second")
end

function Tests.test_modules_initialize_in_registration_order()
    local callOrder = {}

    local module1 = {
        Initialize = function()
            table.insert(callOrder, "first")
        end
    }
    local module2 = {
        Initialize = function()
            table.insert(callOrder, "second")
        end
    }
    local module3 = {
        Initialize = function()
            table.insert(callOrder, "third")
        end
    }

    addon:RegisterModule(module1, "First")
    addon:RegisterModule(module2, "Second")
    addon:RegisterModule(module3, "Third")

    Harness.triggerAddonLoaded("TestAddon")

    A.assertEquals(3, #callOrder, "All modules called")
    A.assertEquals("first", callOrder[1], "First module first")
    A.assertEquals("second", callOrder[2], "Second module second")
    A.assertEquals("third", callOrder[3], "Third module third")
end

return Tests
