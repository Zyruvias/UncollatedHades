-- ModUtil.Path.Context.Wrap("LeaveRoom")
-- ModUtil.Path.Wrap("LoadMap")
CollatedHades.Status = {
    PROCESSING = "PROCESSING",
    IDLE = "IDLE",
}
CollatedHades.RunState = {

}
CollatedHades.Initialized = false
function CollatedHades.InitilizeCollatedRun()
    CollatedHades.CurrentRunIndex = 1
	CollatedHades.RunState[CollatedHades.CurrentRunIndex] = {}
	DebugPrint { Text = "Initializing Collated Run of size " .. CollatedHades.config.NumRuns}
	
	-- set run state for each run expected to run
	for i = 1, CollatedHades.config.NumRuns, 1 do
		CollatedHades.RunState[i] = {
			Initialized = false,
		}
	end
	
	CollatedHades.Initialized = true
end

function CollatedHades.SaveRun()
	if not CollatedHades.Initialized then
		return
	end
	local run = CollatedHades.GetCurrentRunState()
    run.CurrentRun = DeepCopyTable(CurrentRun)
	run.MetaUpgrades = DeepCopyTable(GameState.MetaUpgrades)
	run.MetaUpgradeState = DeepCopyTable(GameState.MetaUpgradeState)
	run.MetaUpgradesSelected = DeepCopyTable(GameState.MetaUpgradesSelected)
	run.LastAwardTrait = DeepCopyTable(GameState.LastAwardTrait)
	run.LastAssistTrait = DeepCopyTable(GameState.LastAssistTrait)
	-- TODO: fix this hack, saving a run can't possibly mean it isn't initialized but this
	-- shouldn't happen here. or maybe it should? maybe it's not a hack? idk man
	run.Initialized = true
end

function CollatedHades.LoadRun()
	if not CollatedHades.Initialized then
		return
	end
	-- TODO: what else is set in GameState?
	local run = CollatedHades.GetCurrentRunState()
	CurrentRun = run.CurrentRun
	GameState.MetaUpgrades = run.MetaUpgrades
	GameState.MetaUpgradeState = run.MetaUpgradeState
	GameState.MetaUpgradesSelected = run.MetaUpgradesSelected
	GameState.LastAwardTrait = run.LastAwardTrait
	GameState.LastAssistTrait = run.LastAssistTrait
	
end

function CollatedHades.AdvanceToNextRun()
	if not CollatedHades.Initialized then
		return
	end
	local behavior = CollatedHades.config.SelectionBehavior or "Linear"
	local eligibleRunFound = false
	local runsChecked = 0
	while not eligibleRunFound and runsChecked < CollatedHades.config.NumRuns do
		-- attempt to get next run
		if behavior == "Linear" then
			CollatedHades.CurrentRunIndex = CollatedHades.CurrentRunIndex % CollatedHades.config.NumRuns + 1
		elseif behavior == "Random" then
			CollatedHades.CurrentRunIndex = RandomInt(1, CollatedHades.config.NumRuns)
		end	
		-- validate run compatibility
		local runState = CollatedHades.GetCurrentRunState()
		if runState and not runState.Cleared then
			eligibleRunFound = true
		end
		runsChecked = runsChecked + 1
	end

	if runsChecked == CollatedHades.config.NumRuns and not eligibleRunFound then
		DebugPrint { Text = "All runs checked, no eligible runs found. Tearing down."}
		return CollatedHades.Teardown()
	end

end

function CollatedHades.GetCurrentRunState()
	return CollatedHades.RunState[CollatedHades.CurrentRunIndex]
end
 
-- spawns you in the death area to configure your next run
function CollatedHades.StartNextRun()
	if not CollatedHades.Initialized then
		return
	end
	local nextRun = CollatedHades.GetCurrentRunState()
	if nextRun.Initialized == true then
		DebugPrint { Text = "This run is already initialized! runIndex: " .. tostring(CollatedHades.CurrentRunIndex)}
		return CollatedHades.AdvanceNextRunRoom()
	end

    CollatedHades.CurrentStatus = CollatedHades.Status.PROCESSING
    LoadMap({ Name = "DeathArea", ResetBinks = true, ResetWeaponBinks = true })
    CollatedHades.CurrentStatus = CollatedHades.Status.IDLE
	nextRun.Initialized = true


end

function CollatedHades.AdvanceNextRunRoom()
	if not CollatedHades.Initialized then
		return
	end
	CollatedHades.CurrentStatus = CollatedHades.Status.PROCESSING
	-- advance current run index
	local nextRun = CollatedHades.GetCurrentRunState()
	
	-- fetch new run state
	CollatedHades.LoadRun()

	-- get new args for the `LoadMap` call
	local loadMapArgs = nextRun.LoadMapArgs
	
    CollatedHades.CurrentStatus = CollatedHades.Status.IDLE

	LoadMap(loadMapArgs)
end

function CollatedHades.ProcessRunState()
	if not CollatedHades.Initialized then
		return
	end
	local runState = CollatedHades.GetCurrentRunState()
	-- determine if we should create new runs or advance the next room of next run
	if not runState.Initialized then
        return CollatedHades.StartNextRun()
	end
	return CollatedHades.AdvanceNextRunRoom()
end

function CollatedHades.ProcessLeaveRoom()
	if not CollatedHades.Initialized then
		-- need to still leave the room, just not do all the collation stuff...
		LoadMap(CollatedHades.RunState[CollatedHades.CurrentRunIndex].LoadMapArgs)
		return 
	end
	-- on room leave, save the run
	CollatedHades.SaveRun()
	-- Check on overall collated run state
	if not CollatedHades.ValidateCollatedRun() then
		-- end the run?
		return CollatedHades.Teardown()
	end
	-- select next run
	CollatedHades.AdvanceToNextRun()
	-- process it
	CollatedHades.ProcessRunState()
end

function CollatedHades.ValidateCollatedRun()
	local valid = true

	local atLeastOneUnclearedRun = false
	for _, run in ipairs(CollatedHades.RunState) do
		if not run.Cleared then
			atLeastOneUnclearedRun = true
			break
		end
	end
	valid = valid and atLeastOneUnclearedRun
	-- TODO: other validation conditions
	return valid
end

function CollatedHades.FinishCurrentRun()
	local runState = CollatedHades.GetCurrentRunState()
	if runState then
		runState.Cleared = true
	end
end

function CollatedHades.Teardown()
	CollatedHades.RunState = {}
	CollatedHades.Initialized = false
	LoadMap {
		Name = "DeathArea",
		ResetBinks = true,
		LoadBackgroundColor = true
	}
end

-- TODO: Depth counter permanence, show weapon too? idk
-- ModUtil.Path.Wrap("HideDepthCounter", function() return false end, CollatedHades)

ModUtil.Path.Wrap("StartNewRun", function (baseFunc, prevRun, args)
	local run = baseFunc(prevRun, args)
	CollatedHades.CurrentStatus = CollatedHades.Status.IDLE
	ForceNextRoom = "D_Boss01"
    return run
end, CollatedHades)

-- TODO: is this needed?
ModUtil.Path.Wrap("EndRun", function (baseFunc, currentRun)
	if CollatedHades.CurrentStatus == CollatedHades.Status.PROCESSING then
        return
    end
    return baseFunc(currentRun)
end, CollatedHades)

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

	CollatedHades.RunState[CollatedHades.CurrentRunIndex].LoadMapArgs = {
		Name = nextRoom.Name,
		ResetBinks = previousRoom.ResetBinksOnExit or currentRun.CurrentRoom and currentRun.CurrentRoom.ResetBinksOnEnter,
		LoadBackgroundColor = currentRun.CurrentRoom.LoadBackgroundColor
	}
    CollatedHades.ProcessLeaveRoom()

end, CollatedHades)

ModUtil.Path.Wrap("CloseRunClearScreen", function (baseFunc, ...)
	baseFunc(...)
	FreezePlayerUnit()
	wait(3)
	UnfreezePlayerUnit()
	CollatedHades.FinishCurrentRun()
    CollatedHades.ProcessLeaveRoom()
end, CollatedHades)

ModUtil.Path.Wrap("HandleDeath", function ( baseFunc, ... )
	baseFunc(...)
	if not CurrentRun.Cleared then
		return CollatedHades.Teardown()
	end
end, CollatedHades)