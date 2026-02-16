local Assertions = {}

local results = {
    passed = 0,
    failed = 0,
    errors = {}
}

function Assertions.reset()
    results = {
        passed = 0,
        failed = 0,
        errors = {}
    }
end

function Assertions.getResults()
    return results
end

function Assertions.pass()
    results.passed = results.passed + 1
end

function Assertions.fail(message)
    results.failed = results.failed + 1
    table.insert(results.errors, message)
end

local function formatValue(v)
    if type(v) == "string" then
        return string.format("%q", v)
    elseif type(v) == "nil" then
        return "nil"
    else
        return tostring(v)
    end
end

function Assertions.assertEquals(expected, actual, message)
    if expected == actual then
        Assertions.pass()
        return true
    else
        local msg = string.format(
            "%s: expected %s, got %s",
            message or "assertEquals",
            formatValue(expected),
            formatValue(actual)
        )
        Assertions.fail(msg)
        return false
    end
end

function Assertions.assertTrue(value, message)
    if value == true then
        Assertions.pass()
        return true
    else
        local msg = string.format(
            "%s: expected true, got %s",
            message or "assertTrue",
            formatValue(value)
        )
        Assertions.fail(msg)
        return false
    end
end

function Assertions.assertFalse(value, message)
    if value == false then
        Assertions.pass()
        return true
    else
        local msg = string.format(
            "%s: expected false, got %s",
            message or "assertFalse",
            formatValue(value)
        )
        Assertions.fail(msg)
        return false
    end
end

function Assertions.assertNil(value, message)
    if value == nil then
        Assertions.pass()
        return true
    else
        local msg = string.format(
            "%s: expected nil, got %s",
            message or "assertNil",
            formatValue(value)
        )
        Assertions.fail(msg)
        return false
    end
end

function Assertions.assertNotNil(value, message)
    if value ~= nil then
        Assertions.pass()
        return true
    else
        local msg = string.format(
            "%s: expected non-nil value",
            message or "assertNotNil"
        )
        Assertions.fail(msg)
        return false
    end
end

function Assertions.assertError(fn, message)
    local success, err = pcall(fn)
    if not success then
        Assertions.pass()
        return true, err
    else
        local msg = string.format(
            "%s: expected function to throw an error",
            message or "assertError"
        )
        Assertions.fail(msg)
        return false
    end
end

function Assertions.assertNoError(fn, message)
    local success, err = pcall(fn)
    if success then
        Assertions.pass()
        return true
    else
        local msg = string.format(
            "%s: unexpected error: %s",
            message or "assertNoError",
            tostring(err)
        )
        Assertions.fail(msg)
        return false
    end
end

return Assertions
