# Building a new payload

This guide explains how to adapt the verified Rambo ACE dialogue into a different payload. It assumes you have a legal copy of **Rambo (USA) (Rev 1)** and can run MesenCE 2.2.1. It does not include the ROM. This is a game- and revision-specific exploit, not a general NES loader or turnkey assembler.

## Start from the verified run

1. Use the ROM revision above and verify its SHA-256 against the value in the [technical handoff](README.md).
2. Open `rambo-dialogue-fast/rambo-ace-fast.mmo` in MesenCE 2.2.1. The movie embeds its starting state and confirms the emulator, ROM and published result work together.
3. To repeat the controller-input run, use the original slot-1 password-screen baseline and follow `rambo-dialogue-fast/README.md` with `controller-replay.lua`. The movie is for playback; the replay script actively supplies input.
4. Run `python rambo-dialogue-fast/verify-payload.py` to check the byte-level receiver simulation and dialogue data. Run `python rambo-dialogue-fast/build-payload.py` to regenerate `payload.json`.

Keep a clean copy of the baseline and known-good files. Change one layer at a time and keep a copy of each passing payload.

## The delivery chain

The controller inputs do not directly type a program into the game. The password path creates a malformed but usable state; unchecked script dispatch lets a small bootstrap build a legal stage in RAM. That stage installs a receiver, which reads controller data into RAM before jumping to native code:

```text
mission code
  → password-decoded script/bootstrap
  → 81-byte synthesized stage at $01A7–$01F7
  → first receiver at $0191 gets 256 bytes at $0606–$0705
  → first block contains the second receiver
  → second receiver gets 512 bytes at $0400–$05FF
  → native initializer at $0640 starts the dialogue VM
```

The mission code and 81-byte stage are tailored to this game's decoder, interpreter and stack-return behavior. The builder does not synthesize arbitrary bootstraps. For a first adaptation, leave the front end and both receivers unchanged; modify the second 512-byte block, then the native initializer if needed.

## Memory layout and adaptation

The reference builder is `rambo-dialogue-fast/build-payload.py`. It builds a 512-byte image at $0400:

| Address | Reference contents | Adaptation notes |
| --- | --- | --- |
| $0400–$0552 | Encoded dialogue text | Use the game's tile encoding, VM terminators and line limits when retaining the stock dialogue system. |
| $0554–$0563 | Stock mouth-animation wrapper | Keep if the VM calls $0554; otherwise update the script and verify the replacement. |
| $0564–$05BA | 87-byte dialogue VM script | Update text pointers and control flow together if pages change. |
| $05D0–$05F1 | Slash/percent glyph data | Needed only if the new text uses those custom glyphs. |
| $0606–$063F | 58-byte second receiver (in first block) | Receives the second block at $0400–$05FF. |
| $0640–$06C1 | Native initializer/page loop (in first block) | Assumes the dialogue layout and stock routines; adapt for a different effect. |

The second receiver always writes exactly 512 bytes at $0400–$05FF, then jumps to $0640. Data can be code, tables, graphics or text, but the native entry code must agree with every address and format. The builder zero-fills unused bytes; do not assume padding is harmless if your code scans the whole range.

The second-block protocol reads four bits per frame from A, B, Select and Start, high nibble first. Two nibbles reconstruct a byte; the D-pad stays neutral. The receiver begins with `LDX #$FF / TXS` to reset the stack. A low stack can overlap fixed sound variables at $0180/$0181 during NMI and corrupt return addresses; keep the reset unless another stack arrangement is independently proven safe.

## Changing the dialogue

Start with `PAGES` and the text encoder in the builder. Each page allows up to four lines, with at most 19 characters per line. The encoder maps characters to game tile codes and inserts $FF separators and terminators. The builder recomputes VM text pointers, asserts the text ends before $05D0, and checks the script remains 87 bytes.

If page count, speaker, layout or timing changes, review the VM script and native code together. The current initializer selects stock Colonel/Rambo palettes, requests music ID $0E, calls stock dialogue routines and waits 301 NMI frames per page. The wrapper at $0554 preserves the timer while calling the stock mouth routine. The verifier checks receiver behavior, timer, wrapper, wording and URL placement; update its expectations for new dialogue and keep the checks meaningful.

For a non-dialogue program, replace the text/VM layer with native code and data that fit the transferred image. Update the second receiver's final jump target in the first block and the replay/observer expectations. Reusing the verified receivers avoids changing the riskiest delivery layer.

## Constraints and test order

The recording transfers a fixed 256-byte first block and 512-byte second block. There is no length field: the receivers always read those amounts. Keep block sizes unless you redesign and reverify the receivers. The first block contains the receiver at $0606, so do not overwrite its code or transfer path.

1. Regenerate and check builder assertions and address ranges.
2. Extend the offline verifier for any changed receiver or code. Static checks do not prove NES execution.
3. Test with a RAM-installed caller or emulator harness. Label this diagnostic; it does not prove controller-only delivery.
4. Run the controller replay from the clean password-screen baseline. Check every received byte and the native entry address.
5. Save a movie and play it independently with the read-only observer. Verify the final behavior as well as transfer.

The stack-overlap trace in the technical handoff can help diagnose intermittent failures and reset-path escapes. A RAM-installed test proves code can work after installation; only the full controller run verifies the password bootstrap, synthesis, transfer and native handoff together.

## Scope

The repo includes the fixed mission code, payload source/data, replay and observer scripts, movie and checks for this dialogue. It does not include a general assembler, general payload packer, ROM, or a recipe for synthesizing a new password/bootstrap stage. A different entry path, receiver size or game behavior needs new analysis and emulator verification. The original password-screen baseline is needed for live controller replay; the movie's embedded state is enough for movie playback.
