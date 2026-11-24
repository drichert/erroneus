// Headless SynthDef validation. Run from repository root with:
// sclang -D tests/compile.scd
(
var exitCode = 0;
~erroneusCompileOnly = true;
try({
    thisProcess.interpreter.executeFile("erroneus-v0.scd");
    if(~erroneusMakeTrackDef.isNil, {
        Error("Erroneus track SynthDef factory was not loaded").throw;
    });
    ~erroneusMakeTrackDef.value.asBytes;
    "ERRONEUS_COMPILE_OK".postln;
    if(~erroneusMakeClockDef.isNil, {
        Error("Shared server clock SynthDef factory was not loaded").throw;
    });
    ~erroneusMakeClockDef.value.asBytes;
    if(~erroneusClockDivisions != [0, 1, 2, 4, 8, 16], {
        Error("Shared clock division options changed").throw;
    });
    if(~erroneusModSyncDivisions != [0, 1, 2, 4, 8, 16], {
        Error("Shared modulation sync divisions changed").throw;
    });
    if(~erroneusResetClock.isNil or: { ~erroneusSetModSyncDivision.isNil }, {
        Error("Clock reset or modulation sync setter missing").throw;
    });
    // Math-only reference test: 120 BPM, 4 grains/beat, 2.1 seconds
    // at 48 kHz has 16 subdivision boundaries. This does NOT prove
    // scsynth scheduling or audio bus/UGen behavior.
    {
        var beatCount = 0.0, lastGrid = 0.0, grid, ticks = 0;
        ((48000 * 2) + 4800).do({
            beatCount = (beatCount + (120 / (60.0 * 48000))).wrap(0, 4);
            grid = (beatCount.frac * 4).frac;
            if(grid < (lastGrid - 0.1), { ticks = ticks + 1; });
            lastGrid = grid;
        });
        if(ticks != 16, {
            Error("Clock reference model missed subdivision boundaries").throw;
        });
    }.value;
    "ERRONEUS_CLOCK_REFERENCE_OK".postln;
    ~erroneusSetTempo.value(136);
    if(~erroneusBPM != 136, {
        Error("Tempo setter failed to store valid BPM").throw;
    });
    ~erroneusSetTempo.value(999);
    if(~erroneusBPM != 136, {
        Error("Tempo setter must reject out-of-range BPM").throw;
    });
    ~erroneusSetClockRunning.value(0);
    if(~erroneusClockRunning != 0, {
        Error("Clock pause setter failed").throw;
    });
    ~erroneusSetClockRunning.value(1);
    "ERRONEUS_CLOCK_COMPILE_OK".postln;
    ~erroneusGuiCompileOnly = true;
    thisProcess.interpreter.executeFile("erroneus-gui.scd");
    if(~erroneusOpenGUI.isNil, {
        Error("Erroneus GUI function was not loaded").throw;
    });
    "ERRONEUS_GUI_COMPILE_OK".postln;
    ~erroneusModGuiCompileOnly = true;
    thisProcess.interpreter.executeFile("erroneus-mod-gui.scd");
    if(~erroneusOpenModGUI.isNil, {
        Error("Erroneus modulation GUI function was not loaded").throw;
    });
    if(~erroneusModTargetNames.size != 14, {
        Error("Expected Off plus 13 modulation destinations").throw;
    });
    if(~erroneusModControlName.value(0, \wave) != \mod1Wave, {
        Error("Modulator control naming mismatch").throw;
    });
    if(~erroneusModControlName.value(3, \depth) != \mod4Depth, {
        Error("Fourth modulator control naming mismatch").throw;
    });
    if(~erroneusModStates.every({ |tracks|
        tracks.every({ |slot| (slot[\depth] == 0) and: { slot[\target] == 0 } })
    }).not, {
        Error("Modulators must start disconnected and silent").throw;
    });
    "ERRONEUS_MOD_COMPILE_OK".postln;
    // The sample manager lives in erroneus-v0.scd and uses the same
    // independently allocated capture buffers regardless of file selection.
    if(~erroneusLoadSample.isNil or: { ~erroneusUseSample.isNil }, {
        Error("Sample loading API was not installed").throw;
    });
    if(~erroneusUseCapture.isNil or: { ~erroneusUnloadSample.isNil }, {
        Error("Sample buffer lifecycle API was not installed").throw;
    });
    if(~erroneusSampleMaxSeconds != 60, {
        Error("Unexpected maximum sample duration").throw;
    });
    if(~erroneusSampleValidTrack.value(0), {
        Error("Track access must be disabled before boot").throw;
    });
    ~erroneusSampleGuiCompileOnly = true;
    thisProcess.interpreter.executeFile("erroneus-sample-gui.scd");
    if(~erroneusOpenSampleGUI.isNil or: { ~erroneusSampleRefresh.isNil }, {
        Error("Sample GUI did not load").throw;
    });
    "ERRONEUS_SAMPLE_COMPILE_OK".postln;
}, { |error|
    "ERRONEUS_COMPILE_FAILED".postln;
    error.reportError;
    exitCode = 1;
});
exitCode.exit;
)
