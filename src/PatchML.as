// Places where we'll add code

// add supporting functions
const string P_FUNCSTART = """// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
// Functions
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ //
""";

// add stuff for each frame -- inject after it gets race pending events
const string P_PLAYLOOP_START = """
***Match_PlayLoop***
***
// Manage race events
declare RacePendingEvents = Race::GetPendingEvents();
""";

// reset for each round
const string P_ROUND_START = """
***Match_StartRound***
***
""";

const string P_ROUND_INIT = """
***Match_InitRound***
***
""";

const string P_ROUND_END = """
***Match_EndRound***
***
""";


// Things we'll inject


const string P_ACTIVATE_RECORDS = """
Race::SetupRecord(
	MenuConsts::C_ScopeType_Season,
	MenuConsts::C_ScopeType_PersonalBest,
	MenuConsts::C_GameMode_TimeAttack,
	"",
	C_UploadRecord,
	C_DisplayRecordGhost,
	C_DisplayRecordMedal,
	C_CelebrateRecordGhost,
	C_CelebrateRecordMedal,
	( // Do not display the world records on the training campaign
		S_CampaignId != CampaignStruct::C_Campaign_NullId &&
		S_CampaignId != CampaignStore::GetTrainingCampaign().Id
	)
);
""";

const string P_DEACTIVATE_RECORDS = """

Race::SetupRecord(
	MenuConsts::C_ScopeType_Season,
	MenuConsts::C_ScopeType_PersonalBest,
	MenuConsts::C_GameMode_TimeAttack,
	"",
	False,
	False,
	False,
	False,
	False,
	( // Do not display the world records on the training campaign
		S_CampaignId != CampaignStruct::C_Campaign_NullId &&
		S_CampaignId != CampaignStore::GetTrainingCampaign().Id
	)
);

// Race::SetupRecord(
// 	MenuConsts::C_ScopeType_Season,
// 	MenuConsts::C_ScopeType_PersonalBest,
// 	MenuConsts::C_GameMode_TimeAttack,
// 	"",
// 	False,
// 	False,
// 	False,
// 	Flase,
// 	Flase,
// 	False
// );
""";

const string EnableRecordsFunc = "Void EnableRecords() {\n" + P_ACTIVATE_RECORDS + "\n}\n";
const string DisableRecordsFunc = "Void DisableRecords() {\n" + P_DEACTIVATE_RECORDS + "\n}\n";

const string ExtraFunctions =
	EnableRecordsFunc + DisableRecordsFunc + CustomFuncs;
    // EnableRecordsFunc + DisableRecordsFunc; // + CustomFuncs; // +
const string CustomFuncs = """
declare Boolean SpoderizeStarted;
declare Boolean SpoderizeActive;
declare Integer _SpoderizeLastCheck;
declare Integer _SpoderizeLastRedo;
declare Integer Starting_StartAt;
declare Boolean Starting_Waiting;

Void NotifySpoderizeMode() {
	if (Players[0] != Null) {
    	declare netwrite Boolean Net_Spoderize_ModeIsRunning for Players[0] = False;
		Net_Spoderize_ModeIsRunning = True;
	}
}

Boolean ShouldEnableSpoderize() {
	if (SpoderizeStarted) return False;
	if (Players[0] == Null || Players[0].SpawnStatus != CSmPlayer::ESpawnStatus::Spawned || Players[0].StartTime > Now) return False;
	if (_SpoderizeLastCheck + 100 < Now) {
		_SpoderizeLastCheck = Now;
		return ML::Rand(0.0, 1.0) <= 0.001;
	}
	return False;
}

Void ResetSpoderize() {
	if (Players[0] != Null)	SetPlayer_Delayed_Reset(Players[0]);
	SpoderizeStarted = False;
	SpoderizeActive = False;
	EnableRecords();
	_SpoderizeLastCheck = Now;
	_SpoderizeLastRedo = Now;
	Starting_Waiting = False;
	Starting_StartAt = -1;

	UIManager.UIAll.BigMessage = "";

	declare netwrite Integer Net_Spoderize_Nonce for Players[0] = 0;
	declare netwrite Integer Net_Spoderize_Started for Players[0] = 0;
	declare netwrite Boolean Net_Spoderize_SongPlaying for Players[0] = False;
	declare netwrite Integer Net_Spoderize_SongNonce for Players[0] = 0;
	declare netwrite Boolean Net_Spoderize_Warning for Players[0] = False;
	declare netwrite Integer Net_Spoderize_WarningNonce for Players[0] = 0;

	Net_Spoderize_Nonce += 1;
	Net_Spoderize_Started = 0;
	Net_Spoderize_SongPlaying = False;
	Net_Spoderize_SongNonce += 1;
	Net_Spoderize_WarningNonce += 1;
	Net_Spoderize_Warning = False;
}

Void RunSpoderize() {
	if (Players[0] != Null) {
		SetPlayer_Delayed_AdherenceCoef(Players[0], ML::Rand(.15, .5));
		SetPlayer_Delayed_ControlCoef(Players[0], ML::Rand(0.6, 1.0));
		SetPlayer_Delayed_AccelCoef(Players[0], ML::Rand(0.6, 1.0));
		declare CarTo = CSmMode::EVehicleTransformType::Reset;
		if (ML::Rand(0.0, 1.0) < 0.5) {
			CarTo = CSmMode::EVehicleTransformType::CarSnow;
		}
		SetPlayer_Delayed_VehicleTransform(Players[0], CarTo);
	}
	SpoderizeStarted = True;
	SpoderizeActive = True;
	DisableRecords();
	_SpoderizeLastRedo = Now;

	// UIManager.UIAll.BigMessage = "SPODERIZER ACTIVATING...";

	declare netwrite Integer Net_Spoderize_Nonce for Players[0] = 0;
	declare netwrite Integer Net_Spoderize_Started for Players[0] = 0;
	Net_Spoderize_Nonce += 1;
	Net_Spoderize_Started = Now;
}

Void StartSpoderize() {
	SpoderizeStarted = True;
	Starting_StartAt = Now + 10000;
	Starting_Waiting = True;

	declare netwrite Boolean Net_Spoderize_Warning for Players[0] = False;
	declare netwrite Integer Net_Spoderize_WarningNonce for Players[0] = 0;
	declare netwrite Boolean Net_Spoderize_SongPlaying for Players[0] = False;
	declare netwrite Integer Net_Spoderize_SongNonce for Players[0] = 0;

	Net_Spoderize_SongPlaying = True;
	Net_Spoderize_SongNonce += 1;
	Net_Spoderize_WarningNonce += 1;
	Net_Spoderize_Warning = True;
}

Void CheckSpoderizeEachFrame() {
	if (!SpoderizeStarted) return;
	if (Players[0] == Null || Players[0].SpawnStatus != CSmPlayer::ESpawnStatus::Spawned) return;
	if (Starting_Waiting) {
		if (Starting_StartAt < Now) {
			Starting_Waiting = False;
			RunSpoderize();
		}
	} else if (SpoderizeActive) {
		if (_SpoderizeLastRedo + 10000 < Now) {
			_SpoderizeLastRedo = Now;
			RunSpoderize();
		}
	}
}

Void CheckSpoderizeOnRespawn() {
	if (!SpoderizeStarted) return;
	_SpoderizeLastRedo = Now;
	RunSpoderize();
}

""";


const string ExtraRoundInit = """
NotifySpoderizeMode();
ResetSpoderize();
""";

const string ExtraRoundStart = """
NotifySpoderizeMode();
ResetSpoderize();
""";

const string ExtraPlayLoop = """
//ResetSpoderize();
if (ShouldEnableSpoderize()) {
	StartSpoderize();
}
CheckSpoderizeEachFrame();
for (Event in RacePendingEvents) {
	if (Event.Type == Events::C_Type_StartLine) {
		if (Event.Player != Null) {
			ResetSpoderize();
		}
	} else if (Event.Type == Events::C_Type_Respawn) {
		if (Event.Player != Null) {
			ResetSpoderize();
		}
	} else if (Event.Type == Events::C_Type_GiveUp) {
		if (Event.Player != Null) {
			ResetSpoderize();
		}
	}
}
""";

const string ExtraRoundEnd = """
if (SpoderizeActive) GhostUpload::ForceUploadWaiting(1);
""";

// The Logic

string RunPatchML(const string &in script) {
	return script.Replace(P_FUNCSTART, string::Join({
		P_FUNCSTART,
		ExtraFunctions
	}, "\n")).Replace(P_PLAYLOOP_START, string::Join({
		P_PLAYLOOP_START,
		ExtraPlayLoop
	}, "\n")).Replace(P_ROUND_START, string::Join({
		P_ROUND_START,
		ExtraRoundStart
	}, "\n")).Replace(P_ROUND_INIT, string::Join({
		P_ROUND_INIT,
		ExtraRoundInit
	}, "\n")).Replace(P_ROUND_END, string::Join({
		P_ROUND_END,
		ExtraRoundEnd
	}, "\n"));
}
