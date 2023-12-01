-- TODO: UncollatedHades.Data
function UncollatedHades.InitilizeCollatedRun()
    UncollatedHades.CurrentRunIndex = 1
	UncollatedHades.RunState[UncollatedHades.CurrentRunIndex] = {}
	
	-- set run state for each run expected to run
	for i = 1, UncollatedHades.config.NumRuns, 1 do
		UncollatedHades.RunState[i] = {
			Initialized = false,
		}
	end
	
	UncollatedHades.Initialized = true
	UncollatedHades.RunCallbacks(UncollatedHades.Constants.Callbacks.SETUP)
end

function UncollatedHades.SaveRun()
	if not UncollatedHades.Initialized then
		return
	end
	local run = UncollatedHades.GetCurrentRunState()
	
	UncollatedHades.RunCallbacks(UncollatedHades.Constants.Callbacks.PRE_SAVE, run)

    run.CurrentRun = DeepCopyTable(CurrentRun)
	run.MetaUpgrades = DeepCopyTable(GameState.MetaUpgrades)
	run.MetaUpgradeState = DeepCopyTable(GameState.MetaUpgradeState)
	run.MetaUpgradesSelected = DeepCopyTable(GameState.MetaUpgradesSelected)
	run.LastAwardTrait = DeepCopyTable(GameState.LastAwardTrait)
	run.LastAssistTrait = DeepCopyTable(GameState.LastAssistTrait)
	-- TODO: fix this hack, saving a run can't possibly mean it isn't initialized but this
	-- shouldn't happen here. or maybe it should? maybe it's not a hack? idk man
	run.Initialized = true

	
	UncollatedHades.RunCallbacks(UncollatedHades.Constants.Callbacks.POST_SAVE)
end

function UncollatedHades.LoadRun()
	if not UncollatedHades.Initialized then
		return
	end
	local run = UncollatedHades.GetCurrentRunState()
	
	UncollatedHades.RunCallbacks(UncollatedHades.Constants.Callbacks.PRE_LOAD, run)
	
	-- TODO: what else is set in GameState?
	CurrentRun = run.CurrentRun
	GameState.MetaUpgrades = run.MetaUpgrades
	GameState.MetaUpgradeState = run.MetaUpgradeState
	GameState.MetaUpgradesSelected = run.MetaUpgradesSelected
	GameState.LastAwardTrait = run.LastAwardTrait
	GameState.LastAssistTrait = run.LastAssistTrait

	UncollatedHades.RunCallbacks(UncollatedHades.Constants.Callbacks.POST_LOAD, run)
	
end

function UncollatedHades.ValidateRun(run)
	for _, validator in ipairs(UncollatedHades.Validators) do
		if type(validator) == "function" then
			if not validator(run) then
				return false
			end
		else
			DebugPrint { Text = "UncollatedHades: found improperly formatted validator: " .. ModUtil.ToString.Shallow(validator) }
		end
	end

	return true

end

function UncollatedHades.AdvanceToNextRun()
	if not UncollatedHades.Initialized then
		return
	end
	local behavior = UncollatedHades.config.SelectionBehavior or UncollatedHades.Constants.SelectionBehaviors.LINEAR
	local eligibleRunFound = false
	local runsChecked = 0
	while not eligibleRunFound and runsChecked < UncollatedHades.config.NumRuns do
		-- attempt to get next run and validate run compatibility
		local selector = UncollatedHades.SelectionBehaviors[behavior]
		local runState = selector()

		if runState and UncollatedHades.ValidateRun(runState) then
			eligibleRunFound = true
		end
		runsChecked = runsChecked + 1
	end

	if runsChecked == UncollatedHades.config.NumRuns and not eligibleRunFound then
		DebugPrint { Text = "All runs checked, no eligible runs found. Tearing down."}
		return UncollatedHades.Teardown()
	end

end

function UncollatedHades.GetCurrentRunState()
	return UncollatedHades.RunState[UncollatedHades.CurrentRunIndex]
end
 
-- spawns you in the death area to configure your next run
function UncollatedHades.StartNextRun()
	if not UncollatedHades.Initialized then
		return
	end
	local nextRun = UncollatedHades.GetCurrentRunState()
	-- idk why this is needed. We shouldn't be getting here. But we are. whatever.
	if nextRun.Initialized == true then
		return UncollatedHades.AdvanceNextRunRoom()
	end
    UncollatedHades.CurrentStatus = UncollatedHades.Constants.Status.PROCESSING
	nextRun.Initialized = true

    LoadMap({ Name = "DeathArea", ResetBinks = true, ResetWeaponBinks = true })
	ClearUpgrades()
    UncollatedHades.CurrentStatus = UncollatedHades.Constants.Status.IDLE

	UncollatedHades.RunCallbacks(UncollatedHades.Constants.Callbacks.RUN_CREATION, nextRun)

end

function UncollatedHades.AdvanceNextRunRoom()
	if not UncollatedHades.Initialized then
		return
	end
	UncollatedHades.CurrentStatus = UncollatedHades.Constants.Status.PROCESSING
	-- advance current run index
	local nextRun = UncollatedHades.GetCurrentRunState()
	
	-- fetch new run state
	UncollatedHades.LoadRun()

	-- get new args for the `LoadMap` call
	local loadMapArgs = nextRun.LoadMapArgs
	
    UncollatedHades.CurrentStatus = UncollatedHades.Constants.Status.IDLE

	LoadMap(loadMapArgs)
end

function UncollatedHades.ProcessRunState()
	if not UncollatedHades.Initialized then
		return
	end
	local runState = UncollatedHades.GetCurrentRunState()
	-- determine if we should create new runs or advance the next room of next run
	if not runState.Initialized then
        return UncollatedHades.StartNextRun()
	end
	return UncollatedHades.AdvanceNextRunRoom()
end

function UncollatedHades.ProcessLeaveRoom()
	if not UncollatedHades.Initialized then
		-- need to still leave the room, just not do all the collation stuff...
		LoadMap(UncollatedHades.RunState[UncollatedHades.CurrentRunIndex].LoadMapArgs)
		return 
	end
	-- on room leave, save the run
	UncollatedHades.SaveRun()
	-- Check on overall collated run state
	if not UncollatedHades.ValidateCollatedRun() then
		-- end the run?
		return UncollatedHades.Teardown()
	end
	-- select next run
	UncollatedHades.AdvanceToNextRun()
	-- process it
	UncollatedHades.ProcessRunState()
end

function UncollatedHades.ValidateCollatedRun()
	-- Collated run will keep going as long as one valid run exists
	for _, run in ipairs(UncollatedHades.RunState) do
		if UncollatedHades.ValidateRun(run) then
			return true
		end
	end
	return false
end

function UncollatedHades.FinishCurrentRun()
	local runState = UncollatedHades.GetCurrentRunState()
	if runState then
		runState.Cleared = true
	end
	
	UncollatedHades.RunCallbacks(UncollatedHades.Constants.Callbacks.RUN_COMPLETION)
end

function UncollatedHades.Teardown()
	UncollatedHades.RunCallbacks(UncollatedHades.Constants.Callbacks.TEARDOWN)
	UncollatedHades.RunState = {}
	UncollatedHades.Initialized = false
	
	LoadMap { Name = "DeathArea", ResetBinks = true, LoadBackgroundColor = true }
	ClearUpgrades()
end

-- WRAPS
ModUtil.Path.Wrap("StartNewRun", function (baseFunc, prevRun, args)
	local run = baseFunc(prevRun, args)
	EnemyData.Hades.MaxHealth = 10
	UncollatedHades.CurrentStatus = UncollatedHades.Constants.Status.IDLE
    return run
end, UncollatedHades)

-- TODO: is this needed?
ModUtil.Path.Wrap("EndRun", function (baseFunc, currentRun)
	if UncollatedHades.CurrentStatus == UncollatedHades.Constants.Status.PROCESSING then
        return
    end
    return baseFunc(currentRun)
end, UncollatedHades)

-- TODO: Future enhancement -- turn this into a Path.Wrap for more mod compatibility
ModUtil.Path.Override("LeaveRoom", function (currentRun, door)

	local nextRoom = door.Room

	ZeroSuperMeter()
	ClearEffect({ Id = currentRun.Hero.ObjectId, All = true, BlockAll = true, })
	StopCurrentStatusAnimation( currentRun.Hero )
	currentRun.Hero.BlockStatusAnimations = true
	AddTimerBlock( currentRun, "LeaveRoom" )
	SetPlayerInvulnerable( "LeaveRoom" )

	local ammoIds = GetIdsByType({ Name = "AmmoPack" })
	SetObstacleProperty({ Property = "Magnetism", Value = 3000, DestinationIds = ammoIds })
	SetObstacleProperty({ Property = "MagnetismSpeedMax", Value = currentRun.Hero.LeaveRoomAmmoMangetismSpeed, DestinationIds = ammoIds })
	StopAnimation({ DestinationIds = ammoIds, Name = "AmmoReturnTimer" })

	RunUnthreadedEvents( currentRun.CurrentRoom.LeaveUnthreadedEvents, currentRun.CurrentRoom )

	if IsRecordRunDepth( currentRun ) then
		thread( PlayVoiceLines, GlobalVoiceLines.RecordRunDepthVoiceLines )
	end

	ResetObjectives()

	if currentRun.CurrentRoom.ChallengeEncounter ~= nil and currentRun.CurrentRoom.ChallengeEncounter.InProgress then
		currentRun.CurrentRoom.ChallengeEncounter.EndedEarly = true
		currentRun.CurrentRoom.ChallengeEncounter.InProgress = false
		thread( PlayVoiceLines, HeroVoiceLines.FleeingEncounterVoiceLines, false )
	end

	if currentRun.CurrentRoom.CloseDoorsOnUse then
		CloseDoorForRun( currentRun, door )
	end

	RemoveRallyHealth()
	if not nextRoom.BlockDoorHealFromPrevious then
		CheckDoorHealTrait( currentRun )
	end
	local removedTraits = {}
	for _, trait in pairs( currentRun.Hero.Traits ) do
		if trait.RemainingUses ~= nil and trait.UsesAsRooms ~= nil and trait.UsesAsRooms then
			UseTraitData( currentRun.Hero, trait )
			if trait.RemainingUses ~= nil and trait.RemainingUses <= 0 then
				table.insert( removedTraits, trait )
			end
		end
	end
	for _, trait in pairs( removedTraits ) do
		RemoveTraitData( currentRun.Hero, trait )
	end

	local exitFunctionName = currentRun.CurrentRoom.ExitFunctionName or door.ExitFunctionName or "LeaveRoomPresentation"
	local exitFunction = _G[exitFunctionName]
	exitFunction( currentRun, door )

	TeardownRoomArt( currentRun, currentRoom )
	if not currentRun.Hero.IsDead then
		--On Zag death cleanup is already processed
		CleanupEnemies()
	end
	killTaggedThreads( RoomThreadName )
	killWaitUntilThreads( "RequiredKillEnemyKilledOrSpawned" )
	killWaitUntilThreads( "AllRequiredKillEnemiesDead" ) -- Can exist for a TimeChallenge encounter
	killWaitUntilThreads( "RequiredEnemyKilled" ) -- Can exist for a TimeChallenge encounter

	RemoveTimerBlock( currentRun, "LeaveRoom" )
	if currentRun.CurrentRoom.TimerBlock ~= nil then
		RemoveTimerBlock( currentRun, currentRun.CurrentRoom.TimerBlock )
	end
	SetPlayerVulnerable( "LeaveRoom" )

	if currentRun.CurrentRoom.SkipLoadNextMap then
		UncollatedHades.FinishCurrentRun()
		UncollatedHades.ProcessLeaveRoom()
		return
	end

	MoneyObjects = {}
	OfferedExitDoors = {}

	local flipMap = false
	if currentRun.CurrentRoom.ExitDirection ~= nil and nextRoom.EntranceDirection ~= nil and nextRoom.EntranceDirection ~= "LeftRight" then
		flipMap = nextRoom.EntranceDirection ~= currentRun.CurrentRoom.ExitDirection
	else
		flipMap = RandomChance( nextRoom.FlipHorizontalChance or 0.5 )
	end
	nextRoom.Flipped = flipMap

	if nextRoom.Encounter == nil then
		nextRoom.Encounter = ChooseEncounter( CurrentRun, nextRoom )
		RecordEncounter( CurrentRun, nextRoom.Encounter )
	end

	currentRun.CurrentRoom.EndingHealth = currentRun.Hero.Health
	currentRun.CurrentRoom.EndingAmmo = GetWeaponProperty({ Id = currentRun.Hero.ObjectId, WeaponName = "RangedWeapon", Property = "Ammo" })
	table.insert( currentRun.RoomHistory, currentRun.CurrentRoom )
	UpdateRunHistoryCache( currentRun, currentRun.CurrentRoom )
	local previousRoom = currentRun.CurrentRoom
	currentRun.CurrentRoom = nextRoom

	RunShopGeneration( currentRun.CurrentRoom )

	GameState.LocationName = nextRoom.LocationText
	RandomSetNextInitSeed()
	if not nextRoom.SkipSave then
		SaveCheckpoint({ StartNextMap = nextRoom.Name, SaveName = "_Temp", DevSaveName = CreateDevSaveName( currentRun ) })
		ValidateCheckpoint({ Value = true })

	end

	RemoveInputBlock({ Name = "MoveHeroToRoomPosition" })
	AddInputBlock({ Name = "MapLoad" })
	UncollatedHades.RunState[UncollatedHades.CurrentRunIndex].LoadMapArgs = {
		Name = nextRoom.Name,
		ResetBinks = previousRoom.ResetBinksOnExit or currentRun.CurrentRoom and currentRun.CurrentRoom.ResetBinksOnEnter,
		LoadBackgroundColor = currentRun.CurrentRoom.LoadBackgroundColor
	}

    UncollatedHades.ProcessLeaveRoom()

end, UncollatedHades)

ModUtil.Path.Wrap("HandleDeath", function ( baseFunc, ... )
	baseFunc(...)
	if not CurrentRun.Cleared then
		return UncollatedHades.Teardown()
	end
end, UncollatedHades)

-- TODO: Future enhancement -- figure out what to do here for fresh file shenanigans
ModUtil.Path.Wrap("CheckRunEndPresentation", function (baseFunc, currentRun, door)
	
	if TextLinesRecord["Ending01"] ~= nil then
		currentRun.CurrentRoom.SkipLoadNextMap = true
		if UncollatedHades.ValidateCollatedRun() then
			return
		end
	end

	baseFunc(currentRun, door)
end, UncollatedHades)