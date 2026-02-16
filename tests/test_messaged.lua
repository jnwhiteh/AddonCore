local Harness = require("tests.harness.init")
local A = Harness.Assertions

local Tests = {}

local addon, WowAPI

function Tests.setup()
    addon, WowAPI = Harness.loadAddonCore("TestAddon")
    Harness.triggerAddonLoaded("TestAddon")
end

function Tests.test_fire_message_calls_handler()
    local called = false
    local receivedMessage = nil
    local receivedArg = nil

    addon:RegisterMessage("TEST_MSG", function(msg, arg1)
        called = true
        receivedMessage = msg
        receivedArg = arg1
    end)

    addon:FireMessage("TEST_MSG", "payload")

    A.assertTrue(called, "Handler should be called")
    A.assertEquals("TEST_MSG", receivedMessage, "Message name")
    A.assertEquals("payload", receivedArg, "Message argument")
end

function Tests.test_unregister_message_stops_delivery()
    local callCount = 0

    local handler = function()
        callCount = callCount + 1
    end

    addon:RegisterMessage("UNREG_MSG", handler)
    addon:FireMessage("UNREG_MSG")
    A.assertEquals(1, callCount, "Called before unregister")

    addon:UnregisterMessage("UNREG_MSG", handler)
    addon:FireMessage("UNREG_MSG")
    A.assertEquals(1, callCount, "Not called after unregister")
end

function Tests.test_fire_message_with_no_handlers_is_noop()
    A.assertNoError(function()
        addon:FireMessage("NONEXISTENT_MSG", "arg")
    end, "FireMessage with no handlers should not error")
end

function Tests.test_method_handler_receives_self()
    local receivedSelf = nil

    addon.OnMessage = function(self, msg, arg)
        receivedSelf = self
    end

    addon:RegisterMessage("SELF_MSG", "OnMessage")
    addon:FireMessage("SELF_MSG")

    A.assertEquals(addon, receivedSelf, "Self should be addon")
end

function Tests.test_multiple_message_handlers()
    local callOrder = {}

    addon:RegisterMessage("MULTI_MSG", function()
        table.insert(callOrder, 1)
    end)
    addon:RegisterMessage("MULTI_MSG", function()
        table.insert(callOrder, 2)
    end)

    addon:FireMessage("MULTI_MSG")

    A.assertEquals(2, #callOrder, "Both handlers called")
    A.assertEquals(1, callOrder[1], "First handler first")
    A.assertEquals(2, callOrder[2], "Second handler second")
end

function Tests.test_duplicate_message_registration_throws()
    local handler = function() end

    addon:RegisterMessage("DUP_MSG", handler)

    A.assertError(function()
        addon:RegisterMessage("DUP_MSG", handler)
    end, "Duplicate registration should throw")
end

function Tests.test_message_handler_defaults_to_message_name()
    local called = false

    addon.DEFAULT_MSG = function(self, msg)
        called = true
    end

    addon:RegisterMessage("DEFAULT_MSG")
    addon:FireMessage("DEFAULT_MSG")

    A.assertTrue(called, "Handler named after message should be called")
end

return Tests
