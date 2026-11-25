# Erroneus architecture

## Goal

Erroneus should behave like an instrument, not an effects-rack preset: capture sound continuously, transform it, and selectively feed the resulting audio back into its own history. Gestures should be able to disturb a musical state and produce meaningful, sometimes unpredictable, consequences.

The design borrows broad behaviors from the Torso S-4 while leaving routing, modulation, and algorithms open to new experiments.

## v0.1 signal flow

```text
                     +-----------------------------+
                     |                             |
internal/live source |                             v
       |             |                   mono capture buffer
       +----> record mix <--- filtered feedback    |
       |                                           |
       v                                           v
       +------------> direct / granular playback <-+
                              |
                        resonator bank
                              |
                         waveshaper ----> buffered feedback
                              |
                         stereo reverb
                              |
                         output limiter
                              |
                          track out
```

Each of the four tracks is a separate instance of the same SynthDef, with its own capture buffer. `RecordBuf` and `GrainBuf` use the same buffer by design. This is a delayed buffer-history feedback system, not a zero-delay audio cycle.

## Emerging design principles

- Keep tempo synchronization optional: stable pulse, independently modulated timelines, and fully free-running behavior must coexist.
- Support mono or stereo samples and synchronized native-rate stereo stems without making stem remixing the only workflow.
- Treat A/B configuration interpolation as a primary performance gesture, not an afterthought.
- Preserve audio safety and the ability to capture happy accidents while allowing unpredictable musical results.

## Near-term decisions

1. Keep the first version monolithic until the combination of grain, resonance, and recirculation sounds worthwhile.
2. Separate the language-level SynthDef factory from server startup using `~erroneusMakeTrackDef`; this allows headless compilation tests without an audio device.
3. Keep DSP on the server. In the SuperCollider prototype, manage buffers, scenes, MIDI/OSC, and persistence in `sclang`, but expose their behavior through a portable control contract rather than making `sclang` the permanent application runtime.
4. Add buses and deterministic group ordering as soon as cross-track and per-stage routing enter the engine.
5. Provide a budget for grains/partials and use bounded feedback, DC blocking, and output limiting.
6. Distinguish freeze (stopping buffer writes) from scan (moving the granular read position).

## Cross-platform desktop application: design for portability

**Direction, not an immediate migration.** Continue experimenting and validating audio in stock SuperCollider. Preserve the option to ship a standalone Erroneus application on Windows, macOS, and Linux without requiring the end user to install or operate the SuperCollider IDE.

The preferred incremental route is a native desktop shell/controller (C++ with Qt is a promising, **provisional** choice) that launches or manages a bundled `scsynth` server, loads compiled `.scsyndef` files, and communicates over OSC. An interim package may still run `sclang` internally if needed; that is a transitional option, not a requirement for the final app. Reimplementing DSP in native code is **not** a prerequisite. Reconsider a DSP rewrite only for demonstrated performance, integration, licensing, or distribution reasons. Do not commit to a particular UI toolkit or plugin format before a functioning end-to-end prototype.

### Boundaries to preserve now

- **DSP and musical timing belong to the audio engine.** Keep grains, modulation, feedback safety, timing-critical clock/transport phase, and sample-accurate decisions in `scsynth`. A GUI or controller may request tempo/transport changes or schedule musical events, but must not become the authoritative audio clock. Keep optional free-running operation.
- **Use a replaceable controller layer.** `sclang` may continue to orchestrate startup, buffers, routing, sample loading, and tests during exploration. Separate the *meaning* of those operations from `sclang` globals, GUI callbacks, and platform-dependent file paths so another process can perform them via OSC.
- **Specify stable commands and parameter metadata.** Define track/parameter IDs, units, ranges, defaults, smoothing, normalization, modulation destinations, and state changes in a documented interface. Commands should include track selection, parameter updates, sample load/use/unload, freeze, transport/tempo, panic/mute, and eventually scene recall and morph. Avoid different meanings for the same control in different GUIs.
- **One authoritative performance state.** Scene values, morph positions, base parameters, modulation routes, sample references, and transport state should have an explicit owner and a way to publish changes. Qt controls, keyboard, mouse/tablet, MIDI/NRPN, OSC, and automation should all dispatch through the same action model, so they cannot silently diverge after external input. The existing test GUIs need not implement this immediately.
- **Design clock and interpolation as engine-facing services.** Represent tempo, beat/bar phase, quantization, transport, and future external sync without tying them to an `AppClock`, window, or MIDI device. Keep A/B interpolation state independent of the gesture that drives it; apply bounded, appropriately smoothed parameter changes in the server and avoid per-sample messages from the UI.
- **Keep project files portable.** When persistence arrives, use an explicitly versioned, documented data format and separate stored musical settings from runtime handles such as Synth IDs, bus numbers, and buffer IDs. Resolve user sample paths through a configurable library/project location; handle missing samples and cross-platform path conventions.
- **Treat dependencies and audio backends as shipping concerns.** Favor stock SuperCollider UGens initially. Any additional UGen or native dependency must be available and packageable on all intended targets or carry an explicit compatibility fallback. Account for bundled library licenses, Windows/macOS/Linux audio and MIDI backend differences, device loss, shutdown cleanup, and audio safety; do not assume successful compilation means a releasable instrument.

### Portability checkpoints

1. Continue developing and listening in SuperCollider; keep headless SynthDef compilation part of CI.
2. As the clock, modulation, and scene systems mature, write down their externally observable OSC command and state contracts before adding more device-specific GUI logic. In particular, preserve the server-owned musical clock introduced by the clock work.
3. Build a small **external-controller proof of concept**: from a non-`sclang` process, start or attach to `scsynth`, load exported SynthDefs, allocate buffers/groups in the correct order, change parameters/tempo, exercise panic, and shut down cleanly. This should work without the SuperCollider IDE and eventually without `sclang` at runtime.
4. Add contract tests for state synchronization and buffer lifetime, plus repeatable audio renders or captured reference output to catch behavioral changes. Validate timing, feedback safety, CPU budget, and real MIDI/audio I/O on actual hardware separately.
5. Only after that proof works, prototype a desktop shell and release build on each target OS. Investigate app packaging, signing/notarization on macOS, runtime dependencies, automated builds, and the applicable SuperCollider/GUI licensing obligations before making distribution promises.

**Guiding rule:** A future native application may replace the GUI and controller, but should not have to rediscover the instrument's musical semantics or rewrite its working DSP merely to ship.

## Near-term roadmap

- [ ] Verify headless SynthDef compilation in GitHub Actions
- [ ] Listen and profile on a Latitude 7300; measure CPU and audio dropouts
- [x] Add non-destructive mono/stereo sample loading with independent track buffers (v0.6; hardware validation pending)
- [ ] Exercise audio-recording and live-input paths end-to-end on the Latitude
- [x] Add split-channel stereo file granulation (pending listening/CPU validation)
- [ ] Expand the independent live capture history to stereo (deferred, not part of the current stereo-file work)
- [ ] Add click-free sample switching, stereo-to-mono downmix and sample normalization
- [x] Add a first-pass GUI panel for listening to parameter sweeps (not a production GUI)
- [x] Introduce four per-track modulators with source/target/rate/depth routing
- [ ] Evaluate modulation listening, CPU overhead, and control ranges on the Latitude
- [ ] Add modulation-to-modulation routing or per-source envelopes based on listening
- [ ] Introduce scenes, macros, and OSC/MIDI control
- [ ] Explore safe cross-track sends and recursive spectral processing

## Control fluidity experiments

The basic Qt slider panel exists to expose discontinuities and zippering before choosing control smoothing. Keep GUI-driven values distinct from audio-engine smoothing: sliders send numerical Synth.set messages directly, and the engine does not yet apply a dedicated lag stage to every parameter. This is deliberate so audible discontinuities can be identified. The GUI retains the values commanded from that panel per track but does not query parameters back from the Synths.

## Live-input level control

`SoundIn.ar([0, 1])` feeds a per-track `inputGain` control (default 0.25, range 0–2) smoothed by `Lag.kr` over 40 ms. The gain is applied before `material` is used for direct playback, buffer recording, granular processing, and feedback. It does not affect the built-in internal source. This avoids conflating input attenuation with track output level and provides safe testing headroom for external audio.

This is post-capture software gain, **not** an analog interface preamp control. ADC or operating-system clipping must be addressed upstream.

## First modulation matrix (v0.2)

Each track SynthDef contains four modulation slots with four controls per slot: wave, target, rate, and depth. Default depth and target are zero to preserve the v0.1 sound.

Each slot produces a control-rate waveform. Its selected target determines where it is applied; slots with the same target are summed and clipped to a normalized +/-1. Destination-specific amounts are musical, not unrestricted offsets: relative buffer-position shifts, mix offsets, bounded scan and density changes, octave-like exponential pitch/length/frequency changes.

Final destination limits are enforced after summing modulation, especially feedback. No language-side high-frequency scheduling is required. Stepped random can intentionally produce discontinuities.

Limitations: envelope modes are free-running periodic decays, not audio-following or externally gated; no clock synchronization, modulation-to-modulation routing, phase reset, or persistent scenes.

## Loaded samples versus capture history (v0.3, extended in v0.6)

Each track has an eight-second mono circular capture buffer (`buf`) and
optionally a loaded sample. Mono samples use one mono file buffer for L/R
playback. Stereo samples use a pair of **independent mono** file buffers
(`sampleBuf` for left and `sampleRightBuf` for right), because stock
`GrainBuf` reads mono material. Both channel granulators receive the same
trigger, read position, pitch and envelope for coherent stereo processing.
`BufRd` separately reads the two file channels at a shared frame position
and original rate; direct and granular signals mix before the existing stereo
effects. Capture retains the original stereo-granule panning behavior from
its mono history, and the record/feedback path continues to downmix to mono.

The capture buffer is never overwritten by loading a file. In sample mode,
its `RecordBuf` stops writing regardless of freeze, preserving its history.
Returning to Capture restores that history and the previous freeze semantics.
No request here expands or allocates stereo capture.

`SoundFile` checks metadata; paired `Buffer.readChannel` operations load
the complete file into memory, with a configurable session budget (default
768 MiB) and a hard `BufRd` frame-addressing guard at 2^24 frames.
The budget reserves **new, resident, and retiring** sample allocations
so replacement does not silently exceed the intended cap. File loads
are asynchronous, with generation and engine-session tokens to reject
stale callbacks. Both stereo channel buffers are installed in a single
Synth parameter message only after both have loaded. Retired buffers
are freed after a server sync. A read failure before its completion
callback may need improved error recovery in a future iteration.

`samplePlayback = 3` adds native-rate stem mode. Its full-file Phasor is
driven by the shared transport running gate and the server clock reset
pulse; it does **not** wrap at the 64-beat rhythmic grid. The bundled
`~erroneusLaunchStems` control sets every loaded track to sample/stem
mode and triggers one shared clock reset to start their read cursors in
the same processing block. This is a common launch/reset for loaded
stems, not beat quantization of arbitrary future track switching.

**Limitations:** in-RAM audio only (no disk streaming), no crossfaded
source changes, no normalization, no persistent file references, no
pitch-preserving time stretching. The 2^24-frame guard prevents unsafe
long-file reads but rejects files longer than about 5m50s at 48 kHz.
For synchronized looping the source files should be aligned and the
same length: their independent full-length loops repeat on each
file's own boundary. Hardware listening, GUI responsiveness,
stereo separation, rapid reload/unload and four-stem CPU remain to be
verified on the Latitude 7300. See issue #17 for controlled profiling.

## Position reference and input gestures (v0.4 exploration)

Position references:

- Input capture: normalized look-back distance from the capture write head, allowing the same delay behind live input to move with newly recorded material.
- Internal synthesized capture: unchanged absolute address in the circular capture buffer.
- Loaded file: unchanged absolute address in the loaded buffer.
- Frozen live capture: look-back is anchored to the stopped write head, so navigation stays stable.

The implementation mirrors the capture write head using an audio-rate Phasor driven by the same recordEnabled gate as RecordBuf. It stops during freeze or sample mode and resumes together with the recorder. The mirror is downsampled to control rate for GrainBuf position selection. A physical write-head readback is not exposed by RecordBuf; live audio tests must confirm that the two advance consistently across pause and resume transitions. Scan Hz defaults to 0 so that a nonmodulated look-back offset is stationary in time; modulation and scan remain additive offsets to the reference.

### Device-independent performance controls

Design the next gesture layer around normalized actions, not assumptions about devices. Start with keyboard shortcuts for track selection, freeze, safe mute and scene/gesture engagement, and a mouse XY performance surface. Later, an Intuos/Bamboo pen can act as a mouse for XY and optionally feed pressure, pen-tip state, and available buttons into the same gesture dispatcher via a Linux-to-OSC bridge. Pressure, tilt and touch features must be detected rather than assumed for an older tablet.

Potential mappings (experiments, not fixed canon): X = state A/B morph, Y = chaos depth; pressure = grain intensity, distortion, or modulation gain; pen-down = engage, pen-up = hold/release; recorded drawn paths = loopable modulation trajectories. When we implement interpolation, that shared control state should be canonical so external MIDI or OSC does not desynchronize Qt sliders or other controllers.

Rate-limit/decimate incoming GUI or tablet events in the control layer, then smooth appropriate parameters on the audio server. Do not send per-sample OSC events. Keep a keyboard-accessible panic/mute action independent of controller focus whenever possible.

## Shared master tempo clock (v0.5)

The four tracks share a single server-side fixed-4/4 musical timeline. A dedicated \erroneusClock SynthDef advances a 64-beat Phasor at audio rate using BPM / 60 and SampleDur. The clock publishes five *non-audible* audio-bus signals: normalized beat phase, normalized bar phase, a reset downbeat pulse, the transport running gate, and a 64-beat cycle phase. The clock Synth is the head node of the execution group, before every track Synth, so their grid boundaries use the same block-aligned timebase. These buses must never be routed to hardware outputs.

Global tempo is 30–300 BPM (120 default). A tempo change adjusts the phasor increment without resetting its phase. Pause stops musical-phase advancement and suppresses quantized grain events; resume continues from the held phase. An explicit reset trigger moves phase to bar 1, beat 1. When playing, reset generates a downbeat event; when paused, it sets phase to the downbeat without firing events. Engine stop/restart initializes a new transport at phase zero. Meter is fixed at four beats per bar in this prototype.

Each track defaults to clockDivision=0 and keeps its original probabilistic Dust.kr grain triggering. Clock divisions of 1, 2, 4, 8 or 16 specify evenly spaced *grains per beat*. Grain onsets derive from audio-rate phase discontinuities. Changing a division mid-beat can cause an extra trigger; parameter changes are not yet bar-quantized. Free-mode direct file playback, capture, scan and granular read position remain independent of transport.

Each of four per-track modulators independently defaults to *free-running Hz* mode. Optional modNSyncDivision controls accept 1, 2, 4, 8 or 16 **cycles per four-beat bar** (or 0 for Hz mode). Sine/triangle waves derive phase from the shared clock; step/smooth-random and decay-envelope sources trigger on shared subdivisions. Smooth-random interpolation time and envelope decay are fixed in seconds for now; they do not scale with tempo. During transport pause, periodic phase is held and new grid events cease, but existing envelopes and smoothing tails may decay.

Public sclang functions: ~erroneusSetTempo, ~erroneusSetClockRunning, ~erroneusResetClock, ~erroneusSetTrackDivision and ~erroneusSetModSyncDivision. This is intentionally device independent. MPD32, keyboard, GUI, OSC and external synchronization must eventually call these common transport APIs, not introduce independent clocks.

The internal clock remains the only timing authority. An eventual MIDI clock follower (24 PPQN) should estimate/filter external tempo and phase, translate start/continue/stop/song-position messages into transport commands, and discipline the single server clock rather than giving each track its own scheduler. Latency, jitter, dropout/relock and phase-reset policy need hardware measurements before promising external sync accuracy. Future work also includes configurable meter, bar-quantized scenes/capture, pitch-preserving time stretching, phase offsets and swing. Native-rate stem playback now uses the clock reset/run signals without inheriting the 64-beat loop length.

### Deterministic direct playback

The clock phase now spans 64 beats and is published on a fifth private audio bus channel; beat and four-beat bar phase remain normalized. Supported loop lengths divide the master cycle exactly. Direct sample Sync maps loop phase onto sample frames, while Retrigger uses grid boundaries and a native-rate frame counter with end-of-file silence. Both obey transport pause; Free mode remains independent. The optional accented click reads the same clock and has matching output limiter latency. Granular reading and direct playback remain separate paths, mixed by Grain Mix. This is varispeed, not pitch-preserving time stretch; switching modes or lengths is not launch-quantized.

## Clock verification boundaries

The headless compiler and pure math reference test cover graph construction, command existence and intended subdivision arithmetic; they do not verify scsynth trigger timing or hardware latency. On Latitude 7300, compare audible transients at 80, 128 and 170 BPM; verify pause/resume/reset; confirm unsynced grains and modulators remain independent; and record CPU/headroom. Hardware verification is required before claiming timing accuracy.

## Testing strategy

The CI check compiles the actual SynthDef with `.asBytes`, which catches language parsing and SynthDef graph construction errors. Since CI has no reliable audio device, real-time signal behavior and audible feedback stability must be checked separately on a configured SuperCollider server.
