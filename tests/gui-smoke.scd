// Opens the real Qt controls in a virtual display, with placeholder tracks.
// No scsynth boot or sound card is required.
(
~erroneusCompileOnly = true;
thisProcess.interpreter.executeFile("erroneus-v0.scd");
~erroneusModGuiCompileOnly = true;
thisProcess.interpreter.executeFile("erroneus-mod-gui.scd");
~erroneusSampleGuiCompileOnly = true;
thisProcess.interpreter.executeFile("erroneus-sample-gui.scd");
~erroneusGuiCompileOnly = true;
thisProcess.interpreter.executeFile("erroneus-gui.scd");
if(~erroneusOpenGUI.isNil, {
    "ERRONEUS_GUI_SMOKE_FAILED: loader".postln;
    1.exit;
}, {
    ~erroneusTracks = [nil, nil, nil, nil];
    ~erroneusTrackDivisions = [0, 4, 0, 0];
    AppClock.sched(0.1, {
        var status = 0;
        try({
            ~erroneusOpenGUI.value;
            if(~erroneusGuiWindow.isNil, {
                Error("GUI did not create a window").throw;
            });
            if(~erroneusGuiRows.size != 16, {
                Error("Expected 16 slider rows including input gain").throw;
            });
            if(~erroneusGuiMakeDefaults.value(0)[\inputGain] != 0.25, {
                Error("Input gain must default to 0.25").throw;
            });
            if(~erroneusGuiMakeDefaults.value(0)[\scanHz] != 0, {
                Error("Scan must default to 0 for stationary input-capture lookback").throw;
            });
            if(~erroneusGuiGrainSyncMenu.items.size != 6, {
                Error("Expected free plus five grain sync choices").throw;
            });
            ~erroneusGuiSelectedTrack = 1;
            ~erroneusGuiRefresh.value;
            if(~erroneusGuiGrainSyncMenu.value != 3 or: { ~erroneusGuiRows[3][1].enabled }, {
                Error("Synced track must show sixteenths and disable density").throw;
            });
            ~erroneusGuiSelectedTrack = 0;
            ~erroneusGuiRefresh.value;
            if(~erroneusGuiGrainSyncMenu.value != 0 or: { ~erroneusGuiRows[3][1].enabled.not }, {
                Error("Free track must restore density slider").throw;
            });
            ~erroneusGuiTempoBox.valueAction_(137.5);
            if(~erroneusBPM != 137.5, { Error("Tempo GUI did not update master BPM").throw; });
            ~erroneusSetTempo.value(96);
            ~erroneusGuiRefreshTransport.value;
            if(~erroneusGuiTempoBox.value != 96, { Error("Tempo GUI did not reflect engine BPM").throw; });
            ~erroneusGuiTransportButton.valueAction_(1);
            if(~erroneusClockRunning != 0, { Error("Pause GUI did not stop clock").throw; });
            ~erroneusGuiTransportButton.valueAction_(0);
            if(~erroneusClockRunning != 1, { Error("Resume GUI did not start clock").throw; });
            ~erroneusOpenModGUI.value;
            if(~erroneusModWindow.isNil, {
                Error("Modulation GUI did not create a window").throw;
            });
            if(~erroneusModRows.size != 4, {
                Error("Expected four modulator rows").throw;
            });
            if(~erroneusModRows[0][1].items.size != 14, {
                Error("Expected Off and thirteen modulation destinations").throw;
            });
            // A new engine session must discard stale values without sending
            // old panel settings to the newly created Synths.
            ~erroneusGuiValues[0][\grainMix] = 0.05;
            ~erroneusGuiValues[1][\pitch] = -3;
            ~erroneusModStates[0][0][\depth] = 0.9;
            ~erroneusModStates[0][0][\target] = 1;
            ~erroneusResetPanelState.value;
            if(~erroneusGuiValues[0][\grainMix] != 0.8 or: {
                ~erroneusGuiValues[1][\pitch] != 0.5
            }, { Error("New session retained stale sound controls").throw; });
            if(~erroneusModStates[0][0][\depth] != 0 or: {
                ~erroneusModStates[0][0][\target] != 0
            }, { Error("New session retained stale modulation controls").throw; });
            ~erroneusGuiRefresh.value;
            ~erroneusModRefresh.value;
            ~erroneusOpenSampleGUI.value;
            if(~erroneusSampleWindow.isNil, {
                Error("Sample manager GUI failed to open").throw;
            });
            if(~erroneusSampleLabels.size != 4, {
                Error("Expected four sample-control rows").throw;
            });
            "ERRONEUS_SAMPLE_GUI_SMOKE_OK".postln;
            ~erroneusSampleWindow.close;
            "ERRONEUS_MOD_GUI_SMOKE_OK".postln;
            ~erroneusModWindow.close;
            "ERRONEUS_GUI_SMOKE_OK".postln;
            ~erroneusGuiWindow.close;
        }, { |error|
            error.reportError;
            "ERRONEUS_GUI_SMOKE_FAILED".postln;
            status = 1;
        });
        status.exit;
        nil;
    });
});
)
