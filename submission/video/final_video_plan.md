# CodeShield Edge Final Video Plan

## Goal

Make the first 20 seconds instantly legible: CodeShield Edge stops a gift-card code before it leaves the device, while messages, calls, and images stay local.

## Recommended Final Cut

Target length: 2:30 to 3:15.

1. Title card: CodeShield Edge, local scam firewall.
2. One sentence problem: gift-card scams are irreversible once the code is sent.
3. Messaging demo:
   - Unknown sender creates urgency and secrecy.
   - User attaches the synthetic gift-card image.
   - CodeShield holds the send, redacts the code, and shows Gemma E4B local analysis.
4. Audio demo:
   - Start AI Scam Call.
   - Safe reply goes through.
   - Spoken PIN is held and redacted before transmission.
5. Architecture card:
   - SwiftUI Mac app.
   - Vision OCR and speech capture.
   - deterministic gift-card code gate.
   - Gemma 4 E4B through LiteRT-LM for local scam reasoning.
6. Closing: standalone prototype today, OS-level safety layer tomorrow.

## Assets

- Voiceover script: `submission/video/voiceover_script.md`
- Recording checklist: `submission/video/recording_checklist.md`
- Synthetic gift card: `submission/video/assets/synthetic_gift_card.png`
- Captured frames: use clean screenshots from your final recording.

## Must Say

- The code has not left this Mac.
- Gemma 4 E4B is running locally through LiteRT-LM.
- CodeShield only escalates when risky context and a redeemable code meet.
- Messages, photos, and call transcripts stay on device.

## Avoid

- Do not show real unused gift-card codes.
- Do not spend more than 15 seconds on setup.
- Do not lead with implementation details. Lead with the blocked scam moment.
