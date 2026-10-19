**Verified end to end:** controller-only recording and independent MMO playback passed in MesenCE 2.2.1 on October 18, 2026. All bytes, nibble reads, nine pages, palettes/music, mouth animation, and five-second waits matched.

# Faster Rambo ACE dialogue delivery

Open `rambo-ace-fast.mmo` with Tools → Movies → Play in MesenCE 2.2.1, with Rambo (USA) (Rev 1) loaded. Stop Lua first. The movie embeds a clean password-screen starting state and needs no separate slot-1 save or Lua input generator. Use Normal speed for the five-second dialogue holds.

The previous animated movie remains preserved in `../rambo-dialogue-animated/`.

## Protocol changes

Password menu entry retains the verified four-frame hold and four-frame release. One-frame menu taps were rejected after a missed character in a recording test.

The existing 81-byte synthesis stage and first 256-byte receiver remain unchanged. Their controller pulses now hold for one input sample and release for one, reducing this bitwise transfer from 64 to 16 frames per byte.

The first block installs a new 58-byte receiver. It synchronizes with the native NMI counter $0124 and reads the controller through stock routine $8E4E. Each frame carries four bits using A, B, Select, and Start; the D-pad stays neutral. The high nibble arrives first, followed by the low nibble. Zero is a neutral sample; no release sample is needed. Two nibble reads reconstruct each unrestricted byte. A read crossing a frame boundary can repeat its held nibble for an extra sample; the recorded movie captures those holds.

The 512-byte second block used 1,027 input samples in the recorded run (1,024 nibble samples plus three extra holds at frame boundaries), about 17 seconds at normal NTSC speed, versus 32,768 frames (about nine minutes) previously: a 32-fold improvement for that block. Together, the 768 payload bytes use approximately 5,120 transfer frames instead of 49,152, a 9.6-fold improvement in payload transfer. Password entry and the intentionally paced dialogue remain additional time.

## Native layout

- $0191: original synthesized stack-safe bit receiver
- $0400–$0552: dialogue text
- $0554–$0563: native stock-mouth wrapper
- $0564–$05BA: relocated 87-byte VM script
- $05D0–$05F1: white slash/percent glyph block
- $0606–$063F: four-bit-per-frame receiver and its frame/read helper
- $0640–$06C1: relocated native dialogue initialization/timer

Zero-page $06/$07 holds the destination pointer. The raw controller routine preserves X/Y and uses $00/$01/$02/$0B; NMI preserves the working zero-page values. The receiver resets SP=$FF and writes $0400–$05FF before jumping to $0640. The conversation retains all nine requested pages, stock palettes/music, white text, stock speaking animation, and 301-frame holds.

## Reproduction and verification

`controller-replay.lua` generates controller input and verifies the run from the original slot-1 baseline. Its fast input generation schedules the next nibble before the receiver waits for the next NMI; the MMO stores the resulting controller samples, so replay needs no callbacks.

`movie-observer.lua` is an optional read-only checker for independent MMO playback. It sets no input, RAM bytes, registers, or execution pointers. It verifies native entry, all 81 synthesized bytes, both payload blocks, every received nibble, all nine rendered pages, palettes/music/glyphs, 301-frame waits, and speaker mouth changes.

`build-payload.py` regenerates `payload.json`. `verify-payload.py` independently simulates the new receiver with the dialogue bytes and a deterministic all-byte-pattern stream, and checks the native timer, mouth wrapper, exact wording, and single-box URL.

ROM SHA-256: `1C621C11761C56B1167ED3302F2A2BB8E4F0D64742D11CF539447EAE2199A1AB`.

## Measured recording

The complete movie has 10,177 input samples, versus 54,692 in the previous version: approximately 2:49 versus 15:10 at normal NTSC speed (5.37 times faster overall). Native dialogue entry occurs at input sample 7,325, approximately 2:02 from the password-screen start. The actual payload interval spans 5,122 samples, approximately 85 seconds, versus 49,145 samples previously (9.59 times faster). The five-second dialogue holds are unchanged.

`movie-audit.json` records the exact payload match, archive integrity, embedded initial-state size, and SHA-256. The previous MMO remains unchanged.
