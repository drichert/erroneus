// Erroneus: non-destructive per-track sample manager.
// Start erroneus-v0.scd first, then evaluate this file in SuperCollider IDE.
// Requires no quarks. SoundFile/Buffer decoding supports WAV and AIFF.
//
// Four tracks retain independent mono capture histories. Selecting Sample
// reads the complete mono/stereo file; Capture returns to the original ring
// buffer. The file buffers are freed only after the Synth switches.

(
~erroneusSampleRefresh = {
    if(~erroneusSampleLabels.notNil, {
        ~erroneusSampleLabels.do({ |label, index|
            var status, mode, indicator;
            status = if(~erroneusSampleStatus.notNil, {
                ~erroneusSampleStatus[index]
            }, { "Start the audio engine" });
            mode = if(~erroneusSampleModes.notNil, {
                ~erroneusSampleModes[index]
            }, { 0 });
            indicator = if(mode == 1, { "[SAMPLE] " }, { "[CAPTURE] " });
            label.string_(indicator ++ status);
            if(~erroneusPlaybackModes.notNil and: { ~erroneusSamplePlaybackMenus.notNil }, {
                ~erroneusSamplePlaybackMenus[index].value_(~erroneusPlaybackModes[index]);
                ~erroneusSampleBeatMenus[index].value_(~erroneusLoopBeats.indexOf(~erroneusPlaybackBeats[index]));
            });
        });
    });
};

~erroneusOpenSampleGUI = {
    var window, heading, note, labels, makeRow;
    if(~erroneusTracks.isNil or: { ~erroneusTracks.size != 4 }, {
        "Start erroneus-v0.scd and wait for all four tracks.".warn;
    }, {
        if(~erroneusSampleWindow.notNil, {
            ~erroneusSampleWindow.front;
        }, {
            window = Window(
                "Erroneus | Sample & Capture",
                Rect(100, 100, 960, 480)
            );
            ~erroneusSampleWindow = window;
            heading = StaticText(window, Rect(18, 12, 900, 27));
            heading.string_("ERRONEUS  |  SAMPLES AND LIVE CAPTURE");
            heading.font_(Font.default.boldVariant);

            labels = Array.newClear(4);
            ~erroneusSamplePlaybackMenus = Array.newClear(4);
            ~erroneusSampleBeatMenus = Array.newClear(4);
            makeRow = { |index|
                var y, trackLabel, loadButton, sampleButton;
                var captureButton, unloadButton, statusLabel, playbackMenu, beatMenu;

                y = 54 + (index * 78);
                trackLabel = StaticText(window, Rect(18, y, 70, 24));
                trackLabel.string_("Track " ++ (index + 1));

                loadButton = Button(window, Rect(92, y, 100, 28));
                loadButton.states_([["Load file..."]]);
                loadButton.action_({
                    Dialog.openPanel({ |selectedPath|
                        ~erroneusLoadSample.value(index, selectedPath);
                    });
                });

                sampleButton = Button(window, Rect(202, y, 105, 28));
                sampleButton.states_([["Use sample"]]);
                sampleButton.action_({
                    ~erroneusUseSample.value(index);
                });

                captureButton = Button(window, Rect(317, y, 112, 28));
                captureButton.states_([["Use capture"]]);
                captureButton.action_({
                    ~erroneusUseCapture.value(index);
                });

                unloadButton = Button(window, Rect(439, y, 91, 28));
                unloadButton.states_([["Unload"]]);
                unloadButton.action_({
                    ~erroneusUnloadSample.value(index);
                });

                statusLabel = StaticText(window, Rect(540, y, 400, 30));
                labels[index] = statusLabel;
                playbackMenu = PopUpMenu(window, Rect(92, y + 34, 145, 25));
                playbackMenu.items_(["Free", "Sync (resample)", "Retrigger", "Stem (native)"]);
                beatMenu = PopUpMenu(window, Rect(247, y + 34, 120, 25));
                beatMenu.items_(~erroneusLoopBeats.collect({ |n| n.asString ++ " beats" }));
                ~erroneusSamplePlaybackMenus[index] = playbackMenu;
                ~erroneusSampleBeatMenus[index] = beatMenu;
                playbackMenu.action_({
                    ~erroneusSetSamplePlayback.value(index, playbackMenu.value, ~erroneusLoopBeats[beatMenu.value]);
                });
                beatMenu.action_({
                    ~erroneusSetSamplePlayback.value(index, playbackMenu.value, ~erroneusLoopBeats[beatMenu.value]);
                });
            };
            4.do({ |index| makeRow.value(index); });
            ~erroneusSampleLabels = labels;

            Button(window, Rect(18, 369, 120, 28))
                .states_([["Click off"], ["Click on"]])
                .action_({ |button| ~erroneusSetMetronome.value(button.value * 0.07); });
            Button(window, Rect(150, 369, 120, 28))
                .states_([["Reset clock"]])
                .action_({ ~erroneusResetClock.value; });
            Button(window, Rect(282, 369, 180, 28))
                .states_([["Launch loaded stems"]])
                .action_({ ~erroneusLaunchStems.value; });
            note = StaticText(window, Rect(18, 405, 918, 64));
            note.string_(
                "Load complete WAV/AIFF files (mono/stereo); no silent truncation.\n"
                ++ "Stem: native pitch, full-file loop, shared downbeat/reset and transport pause.\n"
                ++ "Launch loaded stems aligns every loaded track. Capture stays mono (8 sec). "
                ++ "Sample memory budget: " ++ ~erroneusSampleMemoryBudgetMiB.asString ++ " MiB."
            );

            window.onClose_({
                ~erroneusSampleWindow = nil;
                ~erroneusSampleLabels = nil;
                ~erroneusSamplePlaybackMenus = nil;
                ~erroneusSampleBeatMenus = nil;
            });
            ~erroneusSampleRefresh.value;
            window.front;
        });
    });
};

if(~erroneusSampleGuiCompileOnly != true, {
    ~erroneusOpenSampleGUI.value;
});
)
