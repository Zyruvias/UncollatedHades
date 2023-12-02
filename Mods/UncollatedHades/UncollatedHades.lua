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
    DeathBehavior = "Run-by-run",
}
UncollatedHades.config = config
UncollatedHades.Initialized = false
UncollatedHades.RunState = {}

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
    },
    DeathBehaviors = {
        COMPREHENSIVE = "Comprehensive",
        SLICE = "Run-by-run",
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

UncollatedHades.DeathBehaviors = {}
function UncollatedHades.RegisterDeathBehavior(name, behavior)
    UncollatedHades.DeathBehaviors[name] = behavior
end

-- Example registrations / default behaviors
UncollatedHades.RegisterSelectionBehavior(
    UncollatedHades.Constants.SelectionBehaviors.LINEAR,
    -- linearly check through all runs, return next in list that is valid
    function () 
        local eligibleRunFound = false
        local runsChecked = 0
        while not eligibleRunFound and runsChecked < UncollatedHades.config.NumRuns do
            
            UncollatedHades.CurrentRunIndex = UncollatedHades.CurrentRunIndex % UncollatedHades.config.NumRuns + 1
            local runState = UncollatedHades.GetCurrentRunState()
            if UncollatedHades.ValidateRun(runState) then
                return runState
            end
            runsChecked = runsChecked + 1

        end
        return nil
    end
)

UncollatedHades.RegisterSelectionBehavior(
    UncollatedHades.Constants.SelectionBehaviors.RANDOM,
    function ()
        return GetRandomValue(UncollatedHades.GetAllValidRuns())
    end
)

-- runs that already cleared dad are not eligible for future selection
UncollatedHades.RegisterRunValidator(function (run) return not run.Cleared end)

-- Add slice behhavior -- death ends one series of runs
UncollatedHades.RegisterDeathBehaviors(
    UncollatedHades.Constants.DeathBehaviors.SLICE,
    function()
        -- hack to make the default validator think the run is invalid
        UncollatedHades.GetCurrentRunState().Cleared = true
    end
)
-- Add comprehensive behhavior -- death ends the ENTIRE series of runs
UncollatedHades.RegisterDeathBehaviors(
    UncollatedHades.Constants.DeathBehaviors.COMPREHENSIVE,
    function()
        if not CurrentRun.Cleared then
            return UncollatedHades.Teardown()
        end
    end
)