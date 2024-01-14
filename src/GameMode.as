const string CampaignScriptDir = "Scripts/Modes/TrackMania/";
const string CampaignScriptName = "TM_Campaign_Local.Script.txt";
const string CampaignScriptPath = CampaignScriptDir + CampaignScriptName;
const string DocsCampaignScriptDir = IO::FromUserGameFolder(CampaignScriptDir);
const string DocsCampaignScriptPath = IO::FromUserGameFolder(CampaignScriptPath);
const string FakePrefix = "Titles/Trackmania/Scripts/Modes/TrackMania/";

void UpdateGameMode() {
    // SaveThemeOgg();
    auto script = GetCampaignScriptFid();
    if (script is null) {
        throw("script FID null!");
    }
    trace("script fid byte size: " + script.ByteSize);
    // if (script.ByteSize == 0) ;
    auto textNod = cast<CPlugFileTextScript>(Fids::Preload(script));
    if (textNod is null) {
        ExploreNod(script);
        throw("Text nod is null");
    }
    if (textNod.Text.Length == 0) {
        throw("text nod non null but zero length");
    }
    trace('text nod okay');
    textNod.ReGenerate();
    string origScript = textNod.Text;
    string newScript = RunPatchML(origScript);
    if (!IO::FolderExists(DocsCampaignScriptDir)) {
        IO::CreateFolder(DocsCampaignScriptDir);
    }
    IO::File f(DocsCampaignScriptPath, IO::FileMode::Write);
    f.Write(newScript);
    f.Close();
    auto localFid = Fids::GetUser(CampaignScriptPath);
    auto textNod2 = cast<CPlugFileTextScript>(Fids::Preload(localFid));
    textNod2.ReGenerate();
    textNod.Text = newScript;
    textNod.MwAddRef();
}


CSystemFidFile@ GetCampaignScriptFid() {
    return Fids::GetFake(FakePrefix + CampaignScriptName);
}

const string SpoderzoneSongDir = "Media/Sounds/";
const string SpoderzoneSongName = "spoder-zone.ogg";
const string SpoderzoneSongPath = SpoderzoneSongDir + SpoderzoneSongName;


// void SaveThemeOgg() {
//     IO::FileSource f(SpoderzoneSongName);
//     auto destFolder = IO::FromUserGameFolder(SpoderzoneSongDir);
//     if (!IO::FolderExists(destFolder)) IO::CreateFolder(destFolder);
//     trace("Writing out: " + SpoderzoneSongDir + SpoderzoneSongName);
//     IO::File dest(destFolder + SpoderzoneSongName, IO::FileMode::Write);
//     dest.Write(f.Read(f.Size()));
//     dest.Close();
// }
