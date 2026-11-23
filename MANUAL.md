# StringSelectorApp — The Luthier's Manual

**A comprehensive guide to string tension calculation, workshop reporting, and instrument setup with StringSelectorApp.**

Written for guitar techs, luthiers, bass players, and anyone who needs to calculate string tension accurately.

---

## Table of Contents

1. [What is StringSelectorApp?](#1-what-is-stringselectorapp)
2. [The Physics of String Tension](#2-the-physics-of-string-tension)
3. [Getting Started](#3-getting-started)
4. [The Interface](#4-the-interface)
5. [String Database (strings.ini)](#5-string-database-stringsini)
6. [Tuning Presets (tunings.ini)](#6-tuning-presets-tuningsini)
5. [Reading the Results](#7-reading-the-results)
6. [Workshop Reports](#8-workshop-reports)
7. [Truss Rod Adjustment](#9-truss-rod-adjustment)
8. [Practical Workflows](#10-practical-workflows)
9. [Tips from the Workbench](#11-tips-from-the-workbench)
10. [Technical Reference](#12-technical-reference)

---

## 1. What is StringSelectorApp?

StringSelectorApp is a **string tension calculator** for guitars and basses. It answers the question every guitar tech and luthier faces:

> "If I put these strings on this instrument in this tuning, what will the tension be — and will it be balanced?"

It does this by combining:
- **String data** (gauge and unit weight from `strings.ini`)
- **Tuning data** (note names from `tunings.ini`)
- **Scale length** (treble and bass side)
- **Physics** (the string tension formula)

The result is a real-time table showing the tension of every string, a visual tension curve, and a workshop report you can print or archive.

---

## 2. The Physics of String Tension

### The formula

String tension is calculated using:

> **T = (W × (2 × L × f)²) / 386.4**

Where:
- **T** = tension in pounds (lbs)
- **W** = unit weight of the string (lbs per inch)
- **L** = scale length (inches)
- **f** = frequency (Hz)
- **386.4** = gravitational constant (in/s²) — converts to pounds-force

### Frequency from note name

Each note is converted to a frequency using equal temperament:

> **f = A4 × 2^(n/12)**

Where:
- **A4** = reference pitch (440 Hz by default, adjustable)
- **n** = semitones from A4 (e.g., E4 = +5 semitones, A2 = -24 semitones)

### Why unit weight matters

Two strings with the same gauge (e.g., .010") can have different unit weights depending on:
- **Material** (plain steel, nickel-wound, stainless)
- **Core shape** (hex core, round core)
- **Winding** (flatwound, roundwound, tapewound)

That's why `strings.ini` stores the **unit weight** (W) for each string, not just the gauge. A .010" plain steel string has a different unit weight than a .010" nickel-wound string.

### Unit weight vs. gauge

| String | Gauge | Unit Weight (lbs/in) | Why different? |
|---|---|---|---|
| Plain steel .010 | 0.010" | 0.00002215 | Solid steel, no winding |
| Nickel wound .010 | 0.010" | 0.00002680 | Steel core + nickel wrap |
| Flatwound .010 | 0.010" | 0.00003100 | Flat wrap, more material |

This is why StringSelectorApp uses unit weight — it's the actual physical property that determines tension, not the gauge alone.

---

## 3. Getting Started

### Launch the app

```
StringSelectorApp.exe
```

### First calculation

1. **Select instrument type** (Guitar / Bass / Custom)
2. **Select a tuning** from the dropdown (e.g., "Guitar: 6-String E-Standard")
3. **Enter scale length** — treble side (e.g., 25.5") and bass side (e.g., 34.5" for bass)
5. **Select a string pack** from the database
6. **Click Calculate**

The results grid shows every string with its gauge, frequency, tension, and a visual tension curve.

---

## 4. The Interface

### Top row: Instrument and tuning

| Control | What it does |
|---|---|
| Instrument combo | Select Guitar, Bass, or Custom |
| Tuning combo | Select a tuning preset from `tunings.ini` |
| String count spin | Number of strings (4–9) |
| Scale treble | Scale length treble side (inches) |
| Scale bass | Scale length bass side (inches, for multiscale/fanned-fret) |

### Middle row: String packs

| Control | What it does |
|---|---|
| String pack list | All packs from `strings.ini` |
| ISO checkbox | Toggle between lbs and kg/N |
| Transpose spin | Transpose tuning by semitones |
| Pitch spin | Adjust A4 reference (440 Hz default) |

### Results grid

| Column | What it shows |
|---|---|
| Product / Pack Name | String pack name |
| Tuning | Note name (e.g., E4) |
| Frequency (Hz) | Calculated frequency |
| String Position | String number (1 = high E) |
| Exact Gauge | Gauge in inches and mm |
| Tension (lbs or kg/N) | Calculated tension |
| Scale (Inches) | Scale length used |
| Tension Visual Curve | Bar graph showing relative tension |

### Bottom row: Actions

| Button | What it does |
|---|---|
| Calculate | Run the tension calculation |
| Export CSV | Export results to CSV file |
| Save Tuning | Save current tuning as custom preset |
| Print PDF | Generate HTML workshop report |

---

## 5. String Database (strings.ini)

The string database is a plain text INI file. Each section is a string pack:

```ini
[ErnieBall_Regular_2221]
Name=Ernie Ball 2221 Regular Slinky (10-46)
StringCount=6
G1=0.010
W1=0.00002215
G2=0.013
W2=0.00003737
...
```

### Fields

| Field | Meaning |
|---|---|
| `Name` | Display name (brand + gauge) |
| `StringCount` | Number of strings in the pack |
| `G1`, `G2`, ... | Gauge of each string (inches) |
| `W1`, `W2`, ... | Unit weight of each string (lbs/inch) |

### Adding your own strings

1. Open `strings.ini` in any text editor
2. Copy an existing section
3. Paste at the end, change the section name and values
4. Save — the app picks up changes on next launch

### Where to find unit weight data

- **Manufacturer websites**: Ernie Ball, D'Addario, Elixir publish unit weights
- **String tension calculators**: Many online tools list unit weights
- **DIY measurement**: Weigh a known length of string on a precision scale

---

## 6. Tuning Presets (tunings.ini)

The tuning database is also a plain text INI file:

```ini
[Tuning_0]
Name=Guitar: 6-String E-Standard (Default)
StringCount=6
N1=E4
N2=B3
N3=G3
N4=D3
N5=A2
N6=E2
```

### Fields

| Field | Meaning |
|---|---|
| `Name` | Display name |
| `StringCount` | Number of strings |
| `N1`, `N2`, ... | Note name of each string (1 = highest string) |

### Note name format

Notes are written as letter + octave: `E4`, `A2`, `C#3`, `Bb3`, `F#4`.

The octave number is the scientific pitch notation — `A4 = 440 Hz`, `A2 = 110 Hz`.

### Adding custom tunings

1. Open `tunings.ini`
2. Add a new `[Tuning_N]` section
3. Set `Name`, `StringCount`, and `N1`–`N9`
4. Save — the app picks up changes on next launch

Or use the **Save Tuning** button in the app to save the current tuning as a preset.

---

## 7. Reading the Results

### Tension values

The tension column shows the calculated tension per string. Typical values:

| Instrument | Tuning | String | Tension (lbs) |
|---|---|---|---|
| Guitar 25.5" | E-Standard | Low E (.046) | ~17 lbs |
| Guitar 25.5" | E-Standard | High E (.010) | ~16 lbs |
| Bass 34.5" | E-Standard | Low E (.105) | ~40 lbs |
| Bass 34.5" | E-Standard | High G (.045) | ~35 lbs |

### Visual tension curve

The last column shows a bar graph. A **balanced set** has bars of similar height. A **heavy-bottom** set has a tall low-string bar and shorter high-string bars.

### Total tension

The app also shows the **total tension** across all strings — useful for checking truss rod load and neck relief.

### ISO units

Check the ISO checkbox to see tension in kg and N instead of lbs:
- 1 lb = 0.4536 kg = 4.448 N

---

## 8. Workshop Reports

Click **Print PDF** to generate an HTML workshop report. The report includes:

- Instrument name and date
- Tuning and scale length
- String pack and gauges
- Tension per string (lbs and kg)
- Total tension
- Visual tension curve
- Truss rod adjustment recommendation

The report opens in your browser. Use **Ctrl+P → Save as PDF** to archive it or print it for the client.

### Report contents

| Section | What it shows |
|---|---|
| Header | App name, version, date |
| Instrument info | Type, tuning, scale, string count |
| String table | Per-string: note, gauge, frequency, tension |
| Tension curve | Visual bar graph |
| Total tension | Sum of all strings |
| Truss rod | Adjustment recommendation (turns) |
| Footer | Disclaimer |

---

## 9. Truss Rod Adjustment

The app includes a **truss rod adjustment assistant**. Based on the total tension and the reference tension (from `settings.ini`), it calculates:

- **Tension difference** vs. reference
- **Estimated turns** needed (1 turn = 1/8" of neck relief change)

### How it works

1. Set a **reference tension** in `settings.ini` (the tension your neck is set up for)
2. Load a new string set or tuning
5. The app shows the tension difference and estimated truss rod turns
6. Positive = tighten (clockwise), Negative = loosen (counterclockwise)

### Reference tension

The reference tension is the total tension the neck is currently adjusted for. Measure it by:
1. Installing the current strings
2. Tuning to pitch
3. Running a calculation with the current strings
4. Note the total tension — that's your reference

### Truss rod adjustment table

| Tension difference | Estimated turns | Action |
|---|---|---|
| +5 lbs | +0.25 turns | Slight tighten |
| +10 lbs | +0.5 turns | Tighten |
| -5 lbs | -0.25 turns | Slight loosen |
| -10 lbs | -0.5 turns | Loosen |

> **Warning:** Truss rod adjustments should be made in small increments (1/8 turn at a time). Always check neck relief after each adjustment. When in doubt, consult a professional luthier.

---

## 10. Practical Workflows

### Choosing strings for a new tuning

1. Select the target tuning
2. Enter scale length
3. Try different string packs
4. Compare tension curves — pick the one with the most balanced curve
5. Check total tension is within your neck's range

### Setting up a multiscale (fanned-fret) instrument

1. Enter treble scale (e.g., 25.5")
2. Enter bass scale (e.g., 26.5" or wider)
3. Select tuning and string pack
5. The app calculates tension per string using the appropriate scale length
5. Check that the tension curve is smooth across strings

### Checking tension before a truss rod adjustment

1. Calculate current strings' total tension
2. Calculate new strings' total tension
4. Compare — the difference tells you how much to adjust
5. Use the truss rod assistant for estimated turns

### Transposing for different keys

1. Set the transpose spin to the number of semitones
2. The app shifts all notes by that amount
5. Useful for checking tension in alternate tunings (e.g., Eb, D, Drop C)

### Creating a custom tuning

1. Select a close preset
2. Modify notes using the transpose/pitch controls
5. Click **Save Tuning** to save as a new preset
5. The preset is added to `tunings.ini`

---

## 11. Tips from the Workbench

### String selection

- **Balanced tension is not always equal tension** — many players prefer slightly heavier bass strings for rhythm playing
- **Scale length matters** — a 25.5" scale has ~10% more tension than a 24.75" scale with the same strings
- **Unit weight > gauge** — two .010" strings from different brands can have 20% different tension
- **Wound vs. plain** — the 3rd string (G) is often the highest tension string because it's wound but tuned high

### Setup

- **Always calculate before buying strings** — a set that feels right on one guitar may be too tight on another
- **Check total tension** — adding a string or tuning up can push total tension beyond the neck's design
- **Truss rod adjustments are iterative** — adjust, tune, measure, repeat
- **Temperature and humidity affect tension** — wood expands/contracts, changing effective scale length

### Workshop reports

- **Archive every setup** — the HTML report is a permanent record of what strings/tuning you used
- **Compare before/after** — run calculations for old and new strings to show the client the difference
- **Include the tension curve** — it's a great visual for explaining why a setup feels different

### Data files

- **Back up your INI files** — they contain your custom strings and tunings
- **Share with other techs** — the INI format is plain text, easy to email
- **Version control** — keep old versions when you make changes

---

## 12. Technical Reference

### Calculation formulas

| What | Formula |
|---|---|
| Frequency | `f = A4 × 2^(n/12)` |
| Tension (lbs) | `T = (W × (2 × L × f)²) / 386.4` |
| Tension (kg) | `T_kg = T_lbs × 0.4536` |
| Tension (N) | `T_N = T_lbs × 4.448` |

### File formats

**strings.ini:**
```ini
[Section_Name]
Name=Display Name
StringCount=6
G1=0.010
W1=0.00002215
G2=0.013
W2=0.00003737
```

**tunings.ini:**
```ini
[Tuning_N]
Name=Display Name
StringCount=6
N1=E4
N2=B3
N3=G3
N4=D3
N5=A2
N6=E2
```

### Note name to frequency

| Note | Semitones from A4 | Frequency (Hz) |
|---|---|---|
| C4 | -9 | 261.63 |
| D4 | -7 | 293.66 |
| E4 | -5 | 329.63 |
| F4 | -4 | 349.23 |
| G4 | -2 | 392.00 |
| A4 | 0 | 440.00 |
| B4 | +2 | 493.88 |
| C5 | +3 | 523.25 |
| E2 | -29 | 82.41 |
| A2 | -24 | 110.00 |
| D2 | -19 | 73.42 |
| G2 | -14 | 98.00 |

### Glossary

| Term | Definition |
|---|---|
| Scale length | Vibrating string length (nut to bridge) |
| Unit weight | Mass per unit length of string (lbs/inch) |
| Gauge | String diameter (inches) |
| Tension | Force pulling on the string (lbs or kg) |
| Truss rod | Adjustable metal rod in the neck that counteracts string tension |
| Neck relief | Amount of bow in the neck (measured at 7th fret) |
| Multiscale | Fanned-fret design with different scale lengths per string |
| Action | String height above the fretboard |
| Intonation | Tuning accuracy across the fretboard |