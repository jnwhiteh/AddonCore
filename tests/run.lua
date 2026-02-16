#!/usr/bin/env lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local Assertions = require("tests.harness.assertions")

local function discoverTestFiles()
    local files = {}
    local handle = io.popen("ls tests/test_*.lua 2>/dev/null")
    if handle then
        for line in handle:lines() do
            table.insert(files, line)
        end
        handle:close()
    end
    return files
end

local function collectTests(module)
    local tests = {}
    for name, fn in pairs(module) do
        if type(fn) == "function" and name:match("^test_") then
            table.insert(tests, {name = name, fn = fn})
        end
    end
    table.sort(tests, function(a, b) return a.name < b.name end)
    return tests
end

local function runTestFile(filepath)
    local moduleName = filepath:gsub("%.lua$", ""):gsub("/", ".")
    package.loaded[moduleName] = nil

    local ok, module = pcall(require, moduleName)
    if not ok then
        print(string.format("  LOAD ERROR: %s", module))
        return 0, 1
    end

    local tests = collectTests(module)
    local passed = 0
    local failed = 0

    for _, test in ipairs(tests) do
        Assertions.reset()

        local skipTest = false
        if module.setup then
            local setupOk, setupErr = pcall(module.setup)
            if not setupOk then
                print(string.format("  SETUP ERROR in %s: %s", test.name, setupErr))
                failed = failed + 1
                skipTest = true
            end
        end

        if not skipTest then
            local testOk, testErr = pcall(test.fn)
            if not testOk then
                print(string.format("  FAIL %s: %s", test.name, testErr))
                failed = failed + 1
            else
                local results = Assertions.getResults()
                if results.failed > 0 then
                    print(string.format("  FAIL %s:", test.name))
                    for _, err in ipairs(results.errors) do
                        print(string.format("       %s", err))
                    end
                    failed = failed + 1
                else
                    print(string.format("  PASS %s", test.name))
                    passed = passed + 1
                end
            end

            if module.teardown then
                pcall(module.teardown)
            end
        end
    end

    return passed, failed
end

local function main()
    print("AddonCore Test Suite")
    print(string.rep("-", 40))

    local files = discoverTestFiles()
    if #files == 0 then
        print("No test files found matching tests/test_*.lua")
        os.exit(1)
    end

    local totalPassed = 0
    local totalFailed = 0

    for _, filepath in ipairs(files) do
        print(string.format("\n%s:", filepath))
        local passed, failed = runTestFile(filepath)
        totalPassed = totalPassed + passed
        totalFailed = totalFailed + failed
    end

    print(string.rep("-", 40))
    print(string.format("Results: %d passed, %d failed", totalPassed, totalFailed))

    if totalFailed > 0 then
        os.exit(1)
    else
        os.exit(0)
    end
end

main()
