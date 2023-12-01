--[[
    Uncollated Hades
    - Author: Zyruvias
    - dependencies
        - ModUtil 2.8.x
        - ErumiUILib
]]--f

ModUtil.Mod.Register("UncollatedHades")
local config = {
    Enabled = true,
    NumRuns = 2,
    SelectionBehavior = "Linear",
}
UncollatedHades.config = config
UncollatedHades.Initialized = false

UncollatedHades.RunState = {
    
}

-- Constants
UncollatedHades.Constants = {
    Status = {
        PROCESSING = "PROCESSING",
        IDLE = "IDLE",
    },
    Callbacks = {
        SETUP = "SETUP",
        PRE_SAVE = "PRE_SAVE",
        POST_SAVE = "POST_SAVE",
        PRE_LOAD = "PRE_LOAD",
        POST_LOAD = "POST_LOAD",
        RUN_CREATION = "RUN_CREATION",
        RUN_COMPLETION = "RUN_COMPLETION",
        TEARDOWN = "TEARDOWN",
    },
    SelectionBehaviors = {
        LINEAR = "Linear",
        RANDOM = "Random",
    }
}

-- API
UncollatedHades.Callbacks = {
    [UncollatedHades.Constants.Callbacks.SETUP] = {},
    [UncollatedHades.Constants.Callbacks.PRE_SAVE] = {},
    [UncollatedHades.Constants.Callbacks.POST_SAVE] = {},
    [UncollatedHades.Constants.Callbacks.PRE_LOAD] = {},
    [UncollatedHades.Constants.Callbacks.POST_LOAD] = {},
    [UncollatedHades.Constants.Callbacks.RUN_CREATION] = {},
    [UncollatedHades.Constants.Callbacks.RUN_COMPLETION] = {},
    [UncollatedHades.Constants.Callbacks.TEARDOWN] = {},
}

function UncollatedHades.RegisterCallback(hookType, hook)
    table.insert(UncollatedHades.Callbacks[hookType], hook)
end

function UncollatedHades.RunCallbacks(hookType, args)
    DebugPrint { Text = "UncollatedHades: running callbacks for " .. hookType}
    for _, hook in ipairs(UncollatedHades.Callbacks[hookType]) do
        hook(args)
    end
end

UncollatedHades.Validators = {}
function UncollatedHades.RegisterRunValidator(validator)
    table.insert(UncollatedHades.Validators, validator)
end


UncollatedHades.SelectionBehaviors = {}
function UncollatedHades.RegisterSelectionBehavior(name, behavior)
    UncollatedHades.SelectionBehaviors[name] = behavior
end

-- Example registrations / default behaviors
UncollatedHades.RegisterSelectionBehavior(
    UncollatedHades.Constants.SelectionBehaviors.LINEAR,
    function ()
        UncollatedHades.CurrentRunIndex = UncollatedHades.CurrentRunIndex % UncollatedHades.config.NumRuns + 1
        return UncollatedHades.GetCurrentRunState()
    end
)

UncollatedHades.RegisterSelectionBehavior(
    UncollatedHades.Constants.SelectionBehaviors.RANDOM,
    function ()
        UncollatedHades.CurrentRunIndex = RandomInt(1, UncollatedHades.config.NumRuns)
        return UncollatedHades.GetCurrentRunState()
    end
)

-- runs that already cleared dad are not eligible for future selection
UncollatedHades.RegisterRunValidator(function (run) return not run.Cleared end)