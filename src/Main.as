void Main(){
    UpdateGameMode();
    @hookObj = MyHook();
    startnew(initHook);
    startnew(loadAudio);
}
MyHook@ hookObj;

void initHook(){
    MLHook::RegisterMLHook(hookObj);
    yield();
    IO::FileSource uiFile("SpoderizeUI.Script.txt");
    auto uiScript = uiFile.ReadToEnd();
    MLHook::InjectManialinkToPlayground(GD_PageUID, uiScript);
}

void loadAudio() {
    await({
        startnew(DownloadAudio, string[] = {"spoder-zone.ogg", "https://s3.us-east-1.wasabisys.com/xert/TM/Spoderzone/spoder-zone.ogg"}),
        startnew(DownloadAudio, string[] = {"spoder-zone.mp3", "https://s3.us-east-1.wasabisys.com/xert/TM/Spoderzone/spoder-zone.mp3"}),
        startnew(DownloadAudio, string[] = {"spoder-zone.wav", "https://s3.us-east-1.wasabisys.com/xert/TM/Spoderzone/spoder-zone.wav"})
    });
    yield();
    trace('setting song');
    IO::File f(IO::FromUserGameFolder("Media/Sounds/spoder-zone.wav"), IO::FileMode::Read);
    auto buf = f.Read(f.Size());
    trace('setting song');
    f.Close();
    @song = Audio::LoadSample(buf, true);
    trace('song null: ' + (song is null));
}

void DownloadAudio(ref@ _args) {
    auto args = cast<string[]>(_args);
    auto outDir = IO::FromUserGameFolder("Media/Sounds/");
    auto filename = args[0];
    if (IO::FileExists(outDir + filename)) return;
    if (!IO::FolderExists(outDir)) IO::CreateFolder(outDir);
    auto url = args[1];
    trace("Downloading: " + url);
    auto req = Net::HttpGet(url);
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400) throw("Failed to download: " + url);
    IO::File f(outDir + filename, IO::FileMode::Write);
    f.Write(req.Buffer());
    trace("Downloaded: " + url);
}

//remove any hooks
void OnDestroyed() { _Unload(); }
void OnDisabled() { _Unload(); }
void _Unload() {
    MLHook::UnregisterMLHooksAndRemoveInjectedML();
    auto scriptFid = GetCampaignScriptFid();
    hookObj.OnStopPlaying();
    if (scriptFid !is null) {
        auto textNod = cast<CPlugFileTextScript>(Fids::Preload(scriptFid));
        if (textNod !is null) textNod.ReGenerate();
    }
}

Audio::Sample@ song;

const string GD_PageUID = "Spoderized";

class MyHook: MLHook::HookMLEventsByType {
    bool lastWarning = false;
    bool lastStarted = false;
    bool lastPlaying = false;
    MyHook(){
        super(GD_PageUID);
    }
    void OnEvent(MLHook::PendingEvent@ event) override {
        trace("Got event of type: " + event.data[0] + ", value1: " + event.data[1]);
        if ("Started" == event.data[0]) {
            startnew(CoroutineFuncUserdata(this.OnStarted), event);
        } else if ("SongPlaying" == event.data[0]) {
            startnew(CoroutineFuncUserdata(this.OnSong), event);
        } else if ("Warning" == event.data[0]) {
            startnew(CoroutineFuncUserdata(this.OnWarning), event);
        }
    }
    void OnStarted(ref@ _e) {
        MLHook::PendingEvent@ event = cast<MLHook::PendingEvent>(_e);
        bool started = "0" != event.data[1];
        if (started && !lastStarted) SetBlockHelperMessage("THE SPODER ZONE");
        else if (started) SetBlockHelperMessage("SPODERIZED");
        lastStarted = started;
    }
    void OnSong(ref@ _e) {
        MLHook::PendingEvent@ event = cast<MLHook::PendingEvent>(_e);
        bool playing = "True" == event.data[1];
        if (playing && !lastPlaying) {
            trace("Start playing");
            startnew(CoroutineFunc(OnStartPlaying)).WithRunContext(Meta::RunContext::GameLoop);
        } else if (lastPlaying && !playing) {
            OnStopPlaying();
        }
        lastPlaying = playing;
    }
    void OnWarning(ref@ _e) {
        MLHook::PendingEvent@ event = cast<MLHook::PendingEvent>(_e);
        bool warning = "True" == event.data[1];
        if (warning && !lastWarning) {
            OnNewWarning();
        }
        lastWarning = warning;
    }

    void OnNewWarning() {
        SetBlockHelperMessage("YOU ARE ENTERING");
    }

    Audio::Voice@ currVoice;
    // CAudioScriptSound@ songSource;
    void OnStartPlaying() {
        trace('starting song, waiting');
            // file://Media/Config/Nadeo/Trackmania/Credits/Credits.json
            // "file:///" + IO::FromUserGameFolder(SpoderzoneSongPath).Replace("\\", "/")
        // );//, 1.0, false, false, false);
        // songSource.Play();
        while (song is null) yield();
        @currVoice = Audio::Play(song, .4);
        trace('set curr voice');
        startnew(CoroutineFunc(WatchMenuPauseCurrVoice));
    }
    void OnStopPlaying() {
        trace('stopping song');
        if (currVoice is null) return;
        currVoice.SetGain(0.0);
        @currVoice = null;
        // songSource.Stop();
        // @songSource = null;
    }

    void WatchMenuPauseCurrVoice() {
        while (currVoice !is null) {
            auto app = GetApp();
            auto pcsapi = app.Network.PlaygroundClientScriptAPI;
            auto cmap = app.Network.ClientManiaAppPlayground;
            // we are not in the playground anymore
            if (cmap is null || pcsapi is null) {
                OnStopPlaying();
                return;
            }
            auto menuOpen = pcsapi.IsInGameMenuDisplayed;
            if (menuOpen && !currVoice.IsPaused()) currVoice.Pause();
            else if (!menuOpen && currVoice.IsPaused()) currVoice.Play();
            yield();
        }
    }
};





// normal layer type
// #Const C_Id "UIModule_Race_BlockHelper" in BlockHelper_Common.Script.txt
const string BlockHelperLayerId = "UIModule_Race_BlockHelper";
// this is not to be altered (xmlrpc)
const string BlockHelperUIModuleId = "Race_BlockHelper";

const string BlockHelperEventType = "BlockHelper_Event_GameplaySpecial";

void SetBlockHelperMessage(const string &in msg) {
    auto uiLayer = GetBlockHelperLayer();
    if (uiLayer is null) return;
    auto buf = MwFastBuffer<wstring>();
    buf.Add(msg);
    GetApp().Network.ClientManiaAppPlayground.LayerCustomEvent(uiLayer, BlockHelperEventType, buf);
}

CGameUILayer@ GetBlockHelperLayer() {
    try {
        auto cmap = GetApp().Network.ClientManiaAppPlayground;
        for (uint i = 0; i < cmap.UILayers.Length; i++) {
            auto item = cmap.UILayers[i];
            if (item.Type != CGameUILayer::EUILayerType::Normal) continue;
            auto child = item.LocalPage.GetFirstChild(BlockHelperUIModuleId);
            if (child !is null) return item;
        }
    } catch {
        trace('Exception: ' + getExceptionInfo());
    }
    return null;
}
