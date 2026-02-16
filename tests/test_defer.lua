local Harness = require("tests.harness.init")
local A = Harness.Assertions

local Tests = {}

local addon, WowAPI

function Tests.setup()
    addon, WowAPI = Harness.loadAddonCore("TestAddon")
    Harness.triggerAddonLoaded("TestAddon")
end

function Tests.test_defer_runs_immediately_outside_combat()
    local called = false

    addon:Defer(function()
        called = true
    end)

    A.assertTrue(called, "Should run immediately when not in combat")
end

function Tests.test_defer_queues_during_combat()
    local called = false

    Harness.enterCombat()

    addon:Defer(function()
        called = true
    end)

    A.assertFalse(called, "Should not run while in combat")
end

function Tests.test_queue_executes_on_regen_enabled()
    local called = false

    Harness.enterCombat()

    addon:Defer(function()
        called = true
    end)

    A.assertFalse(called, "Not called during combat")

    Harness.exitCombat()

    A.assertTrue(called, "Should be called when combat ends")
end

function Tests.test_defer_with_method_name()
    local called = false

    addon.DeferredMethod = function(self)
        called = true
    end

    Harness.enterCombat()
    addon:Defer("DeferredMethod")
    A.assertFalse(called, "Not called during combat")

    Harness.exitCombat()
    A.assertTrue(called, "Method should be called when combat ends")
end

function Tests.test_defer_rejects_invalid_types()
    A.assertError(function()
        addon:Defer(123)
    end, "Should reject number")

    A.assertError(function()
        addon:Defer({})
    end, "Should reject table")

    A.assertError(function()
        addon:Defer(nil)
    end, "Should reject nil")
end

function Tests.test_multiple_deferred_functions_execute_in_order()
    local callOrder = {}

    Harness.enterCombat()

    addon:Defer(function()
        table.insert(callOrder, 1)
    end)
    addon:Defer(function()
        table.insert(callOrder, 2)
    end)
    addon:Defer(function()
        table.insert(callOrder, 3)
    end)

    Harness.exitCombat()

    A.assertEquals(3, #callOrder, "All deferred functions called")
    A.assertEquals(1, callOrder[1], "First deferred first")
    A.assertEquals(2, callOrder[2], "Second deferred second")
    A.assertEquals(3, callOrder[3], "Third deferred third")
end

function Tests.test_queue_cleared_after_execution()
    local callCount = 0

    Harness.enterCombat()

    addon:Defer(function()
        callCount = callCount + 1
    end)

    Harness.exitCombat()
    A.assertEquals(1, callCount, "Called once")

    Harness.exitCombat()
    A.assertEquals(1, callCount, "Not called again on second regen")
end

return Tests
