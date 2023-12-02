# UncollatedHades
A mod to interleave multiple runs of Hades into each other.

# How to use
This is not an installation guide. Please see other existing resources on installing mods if you are unfamiliar.

* Load up a Hades file.
* Go to the Courtyard, pick your aspect, keepsake, mirror.
* Upon interacting with the pact, you'll open up the mod settings menu.
* Select your options, and press "Go!"
* Upon leaving Chamber 1, you will go back to the House of Hades, where you can select new mirror configuration, new aspect, new keepsake, and new heat as desired.
* Proceed with gameplay "like normal".

## Notes
* Do not give up or quit out in the middle of a collated run.
* If you wish to end the run, die in the next available chamber. This will allow the mod to tear its state down correctly. Failure to do so may have unintended consequnces for the savefile.
* If you run into issues with the savefile as a result of using this mod, go into your `Saved Games` folder, and delete the `_Temp.sav` associated with the file, and continue.

# How to extend
For mod developers or curious folks that want to add more functionality to the Uncollated Mod experience, see behavior registration in UncollatedHades.lua. Support for behavioral extension exists for run selection, run validation, and death behavior.

## Selection Behaviors
By default the mod comes with 2 run selection (run order) behaviors. "Linear" and "Random". These determine the order in which you play your runs, precisely what they say on the tin.

`UncollatedHades.RegisterSelectionBehavior` is the API endpoint for your own Selection behavior. The registered function must return the next valid run that is meant to be played. The run must also pass `UncollatedHades.ValidateRun`, so do not provide conflicting selection behaviors and validators or the UncollatedRun will tear down.

For convenience, `UncollatedHades.GetAllValidRuns` will give you all eligible runs as a starting point for your selection behavior.

## Run validators
To determine if the whole uncollated run series is still valid, validators are processed on a per-run basis. The run will continue as long as one valid inner run can continue. You can register your own validation functions to determine if you want runs to behave a different way.

`UncollatedHades.RegisterValidation` is the API endpoint for this behavior. See `UncollatedHades.lua` for the registration of the default mod behavior -- Cleared runs cannot be continued.

return `true` if the run can be continued, and `false` if you want to disable selection of the run until some other point.

## Death behaviors
By default, death will end the entire series of runs.

## Hooks
If you want more granular updates to mod state during the progression of the run, see `UncollatedHades.RegisterCallbacks`.

There are 8 callback events that you can register behavior to: SETUP, PRE_SAVE, POST_SAVE, PRE_LOAD, POST_LOAD, RUN_CREATION, RUN_COMPLETION, TEARDOWN. You can access these event names through `UncollatedHades.Constants.Callbacks` for forward compatibility. See instances of `UncollatedHades.RunCallbacks` in `UncollatedHadesMain.lua` for exact details on callbacks at each stage of the mod.

Register your behavior like so: `UncollatedHades.RegisterCallback(UncollatedHades.Constants.Callbacks.SETUP, mySetupFunction)`

