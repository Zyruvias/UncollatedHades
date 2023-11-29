--[[
    Collated Hades
    - Author: Zyruvias
    - dependencies
        - ModUtil 2.8.x
        - ErumiUILib
        - ZyrUvIas Util
]]--f

ModUtil.Mod.Register("CollatedHades")
local config = {
    Enabled = true,
    NumRuns = 2,
    SelectionBehavior = "Linear",
}
CollatedHades.config = config
CollatedHades.Initialized = false

CollatedHades.RunState = {
    
}

-- Constants
CollatedHades.Constants = {
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
CollatedHades.Callbacks = {
    [CollatedHades.Constants.Callbacks.SETUP] = {},
    [CollatedHades.Constants.Callbacks.PRE_SAVE] = {},
    [CollatedHades.Constants.Callbacks.POST_SAVE] = {},
    [CollatedHades.Constants.Callbacks.PRE_LOAD] = {},
    [CollatedHades.Constants.Callbacks.POST_LOAD] = {},
    [CollatedHades.Constants.Callbacks.RUN_CREATION] = {},
    [CollatedHades.Constants.Callbacks.RUN_COMPLETION] = {},
    [CollatedHades.Constants.Callbacks.TEARDOWN] = {},
}

function CollatedHades.RegisterCallback(hookType, hook)
    table.insert(CollatedHades.Callbacks[hookType], hook)
end

function CollatedHades.RunCallbacks(hookType, args)
    DebugPrint { Text = "CollatedHades: running callbacks for " .. hookType}
    for _, hook in ipairs(CollatedHades.Callbacks[hookType]) do
        hook(args)
    end
end

CollatedHades.Validators = {}
function CollatedHades.RegisterRunValidator(validator)
    table.insert(CollatedHades.Validators, validator)
end


CollatedHades.SelectionBehaviors = {}
function CollatedHades.RegisterSelectionBehavior(name, behavior)
    CollatedHades.SelectionBehaviors[name] = behavior
end

-- Example registrations / default behaviors
CollatedHades.RegisterSelectionBehavior(
    CollatedHades.Constants.SelectionBehaviors.LINEAR,
    function ()
        CollatedHades.CurrentRunIndex = CollatedHades.CurrentRunIndex % CollatedHades.config.NumRuns + 1
        return CollatedHades.GetCurrentRunState()
    end
)

CollatedHades.RegisterSelectionBehavior(
    CollatedHades.Constants.SelectionBehaviors.RANDOM,
    function ()
        CollatedHades.CurrentRunIndex = RandomInt(1, CollatedHades.config.NumRuns)
        return CollatedHades.GetCurrentRunState()
    end
)

-- runs that already cleared dad are not eligible for future selection
CollatedHades.RegisterRunValidator(function (run) return not run.Cleared end)