local WowAPI = {}

WowAPI._state = {
    locale = "enUS",
    inCombat = false,
    isLoggedIn = false,
    buildInfo = {"11.0.0", "55000", "Jan 1 2025", 110000},
    metadata = {},
}

WowAPI.frames = {}

local function createMockFrame(frameType, name, parent)
    local frame = {
        _type = frameType or "Frame",
        _name = name,
        _parent = parent,
        _events = {},
        _unitEvents = {},
        _scripts = {},
        queue = {},
    }

    function frame:RegisterEvent(event)
        self._events[event] = true
    end

    function frame:RegisterUnitEvent(event, ...)
        self._unitEvents[event] = {...}
        self._events[event] = true
    end

    function frame:UnregisterEvent(event)
        self._events[event] = nil
        self._unitEvents[event] = nil
    end

    function frame:SetScript(scriptType, handler)
        self._scripts[scriptType] = handler
    end

    function frame:GetScript(scriptType)
        return self._scripts[scriptType]
    end

    function frame:IsEventRegistered(event)
        return self._events[event] ~= nil
    end

    table.insert(WowAPI.frames, frame)
    return frame
end

function WowAPI.FireEvent(event, ...)
    for _, frame in ipairs(WowAPI.frames) do
        if frame._events[event] and frame._scripts["OnEvent"] then
            frame._scripts["OnEvent"](frame, event, ...)
        end
    end
end

function WowAPI.reset()
    WowAPI.frames = {}
    WowAPI._state = {
        locale = "enUS",
        inCombat = false,
        isLoggedIn = false,
        buildInfo = {"11.0.0", "55000", "Jan 1 2025", 110000},
        metadata = {},
    }
    WowAPI._capturedErrors = {}
end

function WowAPI.install()
    table.wipe = function(t)
        for k in pairs(t) do
            t[k] = nil
        end
        return t
    end

    _G.CreateFrame = createMockFrame

    _G.GetAddOnMetadata = function(addon, field)
        local addonMeta = WowAPI._state.metadata[addon] or {}
        return addonMeta[field]
    end

    _G.C_AddOns = {
        GetAddOnMetadata = _G.GetAddOnMetadata
    }

    _G.GetBuildInfo = function()
        return unpack(WowAPI._state.buildInfo)
    end

    _G.geterrorhandler = function()
        return function(err)
            table.insert(WowAPI._capturedErrors, err)
        end
    end

    _G.GetLocale = function()
        return WowAPI._state.locale
    end

    _G.InCombatLockdown = function()
        return WowAPI._state.inCombat
    end

    _G.IsLoggedIn = function()
        return WowAPI._state.isLoggedIn
    end

    _G.Mixin = function(target, ...)
        for i = 1, select("#", ...) do
            local source = select(i, ...)
            if source then
                for k, v in pairs(source) do
                    target[k] = v
                end
            end
        end
        return target
    end

    _G.UIParent = createMockFrame("Frame", "UIParent", nil)

    _G.WOW_PROJECT_ID = 1
    _G.WOW_PROJECT_MAINLINE = 1
    _G.WOW_PROJECT_CLASSIC = 2
    _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5
    _G.WOW_PROJECT_WRATH_CLASSIC = 11
    _G.WOW_PROJECT_CATACLYSM_CLASSIC = 14
    _G.WOW_PROJECT_MISTS_CLASSIC = 15

    _G.print = _G.print or function(...) end

    WowAPI._capturedErrors = {}
end

return WowAPI
