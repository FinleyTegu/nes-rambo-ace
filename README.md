# Rambo NES ACE: technical handoff

**Status:** Complete controller-only delivery and independent movie playback verified in MesenCE 2.2.1 on October 18, 2026. This document captures the final mission code, the exploit path, the receiver and dialogue layout, measured timing, reproduction steps, and evidence files.

## Final mission code

```text
F?0fizk7Gp4fFbsGGWm2XdACr0Y4GHWX
```

The code is case-sensitive and applies to **Rambo (USA) (Rev 1)**. The ROM SHA-256 used for verification is `1C621C11761C56B1167ED3302F2A2BB8E4F0D64742D11CF539447EAE2199A1AB`.

## Result

The mission-code path bootstraps arbitrary controller-fed data into RAM and enters a custom nine-page dialogue implemented with the game's own graphics, text, and dialogue routines. The delivered scene uses the characters' stock palettes, white text, the stock dialogue music, and stock mouth animation for the speaking character. Each page waits 301 NMI frames, approximately five seconds, before advancing.

The faster recording contains 10,177 input samples. The prior verified recording contained 54,692, so the complete movie is 5.37 times faster. The payload portion takes 5,122 samples, compared with 49,145 previously, or 9.59 times faster. At normal NTSC playback speed, the full recording takes about 2:49; the payload transfer takes about 85 seconds. The scene's five-second reading pauses are unchanged.

## How the ACE works

The password is accepted by the game's normal mission-code screen. The game decodes it into a compact state in RAM, including bytes that later act as a script. The relevant bug is that those decoded values are not fully validated before the script interpreter uses them. The resulting values steer the interpreter into its own decoded RAM data and let that data alter execution. This is more precise than saying only “unsanitized password inputs”: the weakness is the missing validation at the boundary between password decoding and script interpretation.

The verified control-flow chain is:

1. The selected mission code decodes to the compact save/script state in RAM near `$0100`. In the observed baseline, the interpreter enters at `$0101` with `A=$00`, `X=$5C`, `Y=$09`, and `SP=$F7`.
2. The game's normal clamp changes the map byte at `$0114` to `$63` and sets `$0117=$01`. The decoded script begins around `$010B`.
3. Script opcode `$18` writes `$10,$5A` to `$00A5/$00A6`, producing a `BPL` instruction that branches to `$0101`. An unchecked `$2E` dispatch reaches that code and returns control to the password-resident bootstrap.
4. The bootstrap synthesizes a legal 81-byte stage at `$01A7–$01F7`. Its values satisfy the game's unusual stack-return and arithmetic constraints; the stage ends with `$01,$A6` and enters natively with carry set.
5. The stage constructs a 22-byte receiver at `$0191–$01A6`. That receiver sets `SP=$00`, then uses the stock fresh-press/release routine at `$87BC` to receive 256 controller-fed bytes into `$0606–$0705` before jumping there.
6. The first block installs the second receiver and the dialogue payload. The second receiver sets `SP=$FF`, reads four controller bits per NMI frame, receives the remaining 512 bytes, and jumps to the native initializer at `$0640`.

### Stack safety finding

An earlier synthesized reader left the stack at `$96`. During NMI, a `JSR` saved its return address at `$017F/$0180`, where the sound routine also keeps state. The sound code changed `$0180`, corrupting the return address. The sound routine returned to `$EE81`; an `RTS` then read `$0080` and transferred execution to `$0081`, where opcode `$00` was observed before the diagnostic stopped. The receiver repair explicitly resets the stack: the first receiver uses `SP=$00` to place stack traffic at the top of page-one RAM, and the second receiver starts with `SP=$FF`. This avoids the fixed sound variables in the verified run.

## Faster controller protocol

The 81-byte synthesis stage and original 256-byte receiver were kept. Their controller pulse timing changed from four input samples pressed plus four released to one pressed plus one released. This cut that first bitwise transfer from 64 to 16 frames per byte. One-frame password-menu taps were tested and dropped because a repeated character could be missed; mission-code entry retains the verified four-frame press and release.

The first block installs a 58-byte receiver. It synchronizes against the game's NMI counter at `$0124` and samples the controller through the stock routine at `$8E4E`. A frame carries four bits in A, B, Select, and Start; the D-pad remains neutral. The high nibble is read first and the low nibble second. Two nibbles form each unrestricted byte. The recorded run used 1,027 samples for 1,024 nibble reads because three held samples crossed frame boundaries.

The payload consists of 768 bytes: a 256-byte first block and a 512-byte second block. The first block takes 4,095 samples in the audited movie. The second takes 1,027. The movie audit records all 768 bytes matching, no opposing directions, no cheats, and a valid archive.

## Native dialogue payload

The code installs the conversation and invokes the game's own dialogue machinery. Key addresses in the final layout:

| Address | Contents |
| --- | --- |
| `$0191` | Original synthesized stack-safe bit receiver |
| `$0400–$0552` | Dialogue text |
| `$0554–$0563` | Wrapper for the stock mouth animation routine |
| `$0564–$05BA` | Relocated 87-byte dialogue VM script |
| `$05D0–$05F1` | Custom white slash/percent glyphs |
| `$0606–$063F` | Four-bit-per-frame receiver and frame/read helper |
| `$0640–$06C1` | Native dialogue initializer and timer |

Zero-page `$06/$07` holds the destination pointer. The second receiver writes `$0400–$05FF`, resets `SP=$FF`, and enters the initializer at `$0640`. The initializer sets the stock character palettes, loads dialogue music ID `$0E` through the game's music routine, and starts the stock VM. Character colors were compared with the original scene; text is white.

The text and animation were checked across all nine pages. The complete URL remains together in one box. The mouth wrapper calls the stock animation routine without resetting the dialogue timer. Playback evidence records 301 NMI frames for each page and open/closed mouth states for the active speaker, while the inactive character remains still.

## Reproduction

Use MesenCE 2.2.1 and the matching ROM revision and SHA-256 above.

For an already recorded playback, open `rambo-dialogue-fast/rambo-ace-fast.mmo` in Mesen's movie player and play at Normal speed. The movie has a clean password-screen initial state embedded and does not need a Lua input generator. Stop any active Lua script before playback. The observer is optional and read-only; it supplies no input or memory/register changes.

To reproduce the live controller-driven run, restore the untouched slot-1 password-screen baseline and run `rambo-dialogue-fast/controller-replay.lua`. It generates the inputs and verifies the transfer. Then play the saved MMO independently with `rambo-dialogue-fast/movie-observer.lua` enabled to check the recording without supplying input. `rambo-dialogue-fast/README.md` has the concise procedure and protocol notes.

The independent payload checker can be run with Python:

```text
python rambo-dialogue-fast/verify-payload.py
```

It simulates the receiver and checks the payload, timer, mouth wrapper, dialogue wording, and URL placement. `build-payload.py` regenerates the payload JSON. These are analysis/build helpers; replay of the MMO itself needs no Lua script.

## Evidence and deliverables

- `rambo-dialogue-fast/rambo-ace-fast.mmo` — final accelerated movie.
- `rambo-dialogue-fast/README.md` — concise replay and protocol guide.
- `rambo-dialogue-fast/final-mission-code.txt` — standalone mission-code reference.
- `rambo-dialogue-fast/controller-replay.lua` — controller input generation and live run checks.
- `rambo-dialogue-fast/movie-observer.lua` — read-only independent movie observer.
- `rambo-dialogue-fast/movie-audit.json` — movie hash, exact sample counts, transfer checks, and archive integrity.
- `rambo-dialogue-fast/verification.txt` — observed verification log for all nine pages, per-page waits, and mouth animation.
- `rambo-dialogue-fast/verify-payload.py`, `build-payload.py`, and `payload.json` — offline payload validation and source data.
- `rambo-dialogue-fast/recording-transfer-log.jpg`, `recording-final-log.jpg`, and the three `movie-playback-*-log.jpg` files — visible Mesen logs from recording and independent playback.
- `rambo-dialogue-animated/rambo-ace-dialogue.mmo` — earlier, slower verified movie, preserved for comparison.

The fast MMO SHA-256 is `c5eed0b95f97fac4a1f8289c947a86a42c162a09e0e4acb5b016cd0a93f4493c`.

## Scope and limits

Verification was performed in MesenCE 2.2.1 using the named ROM revision. No physical-console test is claimed. No ROM bytes were modified and slot 1 was not overwritten. The movie is a Mesen version 3 movie with its initial state embedded; it does not include the copyrighted ROM. The 81-byte synthesis stage was selected from exploratory search and verified in the emulator; no proof of globally minimal code size or maximum possible transfer speed was established. The measured speed is for this exact recording and protocol.
