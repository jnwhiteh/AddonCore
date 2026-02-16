local Harness = require("tests.harness.init")
local A = Harness.Assertions

local Tests = {}

local addon, WowAPI

function Tests.setup()
    addon, WowAPI = Harness.loadAddonCore("TestAddon")
    Harness.triggerAddonLoaded("TestAddon")
end

function Tests.test_register_with_function_handler()
    local called = false
    local receivedEvent = nil
    local receivedArg = nil

    addon:RegisterEvent("TEST_EVENT", function(event, arg1)
        called = true
        receivedEvent = event
        receivedArg = arg1
    end)

    WowAPI.FireEvent("TEST_EVENT", "argValue")

    A.assertTrue(called, "Handler should be called")
    A.assertEquals("TEST_EVENT", receivedEvent, "Event name")
    A.assertEquals("argValue", receivedArg, "Event argument")
end

function Tests.test_register_with_method_name_handler()
    local called = false
    local receivedSelf = nil

    addon.OnTestEvent = function(self, event, arg1)
        called = true
        receivedSelf = self
    end

    addon:RegisterEvent("TEST_EVENT", "OnTestEvent")
    WowAPI.FireEvent("TEST_EVENT", "arg")

    A.assertTrue(called, "Handler should be called")
    A.assertEquals(addon, receivedSelf, "Self should be addon")
end

function Tests.test_register_defaults_to_event_name_as_handler()
    local called = false

    addon.MY_EVENT = function(self, event)
        called = true
    end

    addon:RegisterEvent("MY_EVENT")
    WowAPI.FireEvent("MY_EVENT")

    A.assertTrue(called, "Handler named after event should be called")
end

function Tests.test_multiple_handlers_called_in_order()
    local callOrder = {}

    addon:RegisterEvent("MULTI_EVENT", function()
        table.insert(callOrder, 1)
    end)
    addon:RegisterEvent("MULTI_EVENT", function()
        table.insert(callOrder, 2)
    end)
    addon:RegisterEvent("MULTI_EVENT", function()
        table.insert(callOrder, 3)
    end)

    WowAPI.FireEvent("MULTI_EVENT")

    A.assertEquals(3, #callOrder, "All handlers called")
    A.assertEquals(1, callOrder[1], "First handler first")
    A.assertEquals(2, callOrder[2], "Second handler second")
    A.assertEquals(3, callOrder[3], "Third handler third")
end

function Tests.test_unregister_removes_handler()
    local callCount = 0

    local handler = function()
        callCount = callCount + 1
    end

    addon:RegisterEvent("UNREG_EVENT", handler)
    WowAPI.FireEvent("UNREG_EVENT")
    A.assertEquals(1, callCount, "Called once before unregister")

    addon:UnregisterEvent("UNREG_EVENT", handler)
    WowAPI.FireEvent("UNREG_EVENT")
    A.assertEquals(1, callCount, "Not called after unregister")
end

function Tests.test_duplicate_registration_throws_error()
    local handler = function() end

    addon:RegisterEvent("DUP_EVENT", handler)

    local threw, err = A.assertError(function()
        addon:RegisterEvent("DUP_EVENT", handler)
    end, "Duplicate registration should throw")

    A.assertTrue(threw, "Should throw error")
end

function Tests.test_register_unit_event()
    local called = false
    local receivedUnit = nil

    addon:RegisterUnitEvent("UNIT_HEALTH", function(event, unit)
        called = true
        receivedUnit = unit
    end, "player")

    WowAPI.FireEvent("UNIT_HEALTH", "player")

    A.assertTrue(called, "UnitEvent handler called")
    A.assertEquals("player", receivedUnit, "Unit passed through")
end

function Tests.test_error_in_handler_doesnt_break_others()
    local secondCalled = false

    addon:RegisterEvent("ERR_EVENT", function()
        error("Intentional error")
    end)
    addon:RegisterEvent("ERR_EVENT", function()
        secondCalled = true
    end)

    WowAPI.FireEvent("ERR_EVENT")

    A.assertTrue(secondCalled, "Second handler should still be called")
    A.assertTrue(#WowAPI._capturedErrors > 0, "Error should be captured")
end

function Tests.test_cannot_mix_unit_and_non_unit_handlers()
    addon:RegisterUnitEvent("MIX_EVENT", function() end, "player")

    A.assertError(function()
        addon:RegisterEvent("MIX_EVENT", function() end)
    end, "Should error when mixing unit and non-unit")
end

function Tests.test_cannot_add_unit_to_non_unit_event()
    addon:RegisterEvent("NON_UNIT_EVENT", function() end)

    A.assertError(function()
        addon:RegisterUnitEvent("NON_UNIT_EVENT", function() end, "player")
    end, "Should error when adding unit handler to non-unit event")
end

function Tests.test_unit_event_filters_by_registered_unit()
    local playerCalls = {}
    local targetCalls = {}

    addon:RegisterUnitEvent("UNIT_HEALTH", function(event, unit)
        table.insert(playerCalls, unit)
    end, "player")

    addon:RegisterUnitEvent("UNIT_HEALTH", function(event, unit)
        table.insert(targetCalls, unit)
    end, "target")

    WowAPI.FireEvent("UNIT_HEALTH", "player")

    A.assertEquals(1, #playerCalls, "Player handler should be called once")
    A.assertEquals("player", playerCalls[1], "Player handler got player unit")
    A.assertEquals(0, #targetCalls, "Target handler should NOT be called for player event")
end

return Tests
