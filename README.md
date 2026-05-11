# Euclidean Arpeggiator

**Euclidean Arpeggiator** is a MIDI arpeggiator for REAPER based on Euclidean rhythms.  
It combines a ReaScript/ReaImGui interface with a JSFX real-time MIDI engine, allowing both offline MIDI generation and live arpeggiation inside REAPER.

## Features

- Euclidean rhythm generation using steps and pulses.
- Offline mode for generating MIDI patterns into selected MIDI items.
- Live mode using a JSFX MIDI processor.
- ReaImGui-based user interface.
- Note ordering modes:
  - Ascending
  - Descending
  - Ping-Pong
  - Random
- Pattern rotation.
- Note cycling.
- Octave shifting pattern.
- Jumping pattern.
- Support for multiple chords in offline mode.

## Requirements

- REAPER
- ReaImGui
- ReaPack

## Installation with ReaPack

1. Open REAPER.
2. Go to:

   `Extensions → ReaPack → Import repositories`

3. Add this repository URL:

   `https://raw.githubusercontent.com/jaaviieeer/Euclidean-Arpeggiator/main/index.xml`

4. Synchronize packages:

   `Extensions → ReaPack → Synchronize packages`

5. Install both packages:

   - `Euclidean Arpeggiator`
   - `MIDI Euclidean Arpeggiator JSFX`

## Usage

### Offline mode

Offline mode generates MIDI notes directly into a selected MIDI item.

1. Select a MIDI item in REAPER.
2. Run the Euclidean Arpeggiator script from the Action List.
3. Choose `Offline Mode`.
4. Adjust the parameters.
5. Press `Generate`.

### Live mode

Live mode processes incoming MIDI in real time using the JSFX engine.

1. Select a track.
2. Add a virtual instrument after the JSFX in the FX chain.
3. Run the Euclidean Arpeggiator script.
4. Choose `Live Mode`.
5. Press `Connect`.
6. Play MIDI notes or chords.

The JSFX should be placed before the instrument plugin in the FX chain so that the generated MIDI reaches the instrument.

## Recording live output

By default, REAPER records the MIDI input before FX processing.  
This means that, in live mode, the recorded item may contain the original held notes instead of the arpeggiated output.

To record the generated arpeggio, set the track recording mode to:

`Record: output (MIDI)`

## Project structure

```text
Effects/
└── EuclideanArp/
    └── euclideanArp.jsfx

Scripts/
└── EuclideanArp/
    ├── adapter/
    │   ├── liveAdapter.lua
    │   └── offlineAdapter.lua
    ├── controller/
    │   └── controller.lua
    ├── core/
    │   ├── bjorklund.lua
    │   ├── generator.lua
    │   ├── pitch.lua
    │   └── time.lua
    └── ui/
        └── ui.lua
