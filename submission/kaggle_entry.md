# Kaggle Submission Entry

## Title

CodeShield Edge: Local Gift-Card Scam Firewall for Messages and Calls

## Short Pitch

CodeShield Edge uses Gemma 4 E4B running locally through LiteRT-LM to warn a user before an irreversible gift-card code leaves their Mac. It combines private on-device message/call context, local OCR, local speech capture, deterministic gift-card code redaction, and Gemma's structured scam reasoning.

## Suggested Tracks

- Special Technology Track: LiteRT
- Impact Track: Safety & Trust
- Main Track

## Public Links

- GitHub: https://github.com/umshahid/CodeShield-Edge-litert
- Demo video: add your final video URL here

## Full Writeup

Gift-card scams are painfully specific: the attacker does not need a bank password, a card number, or account access. They only need a redeemable gift-card code. Once that code is texted, photographed, or spoken, the money can disappear quickly.

Most defenses arrive too late or create a privacy problem. A bank warning can happen after purchase. A family member may not know until after the code is shared. Cloud safety services can feel invasive because they imply someone is reading private messages, images, or calls.

CodeShield Edge focuses on the last safe moment: the moment before the gift-card code leaves the device.

We built a macOS prototype that behaves like a real messaging and call app. In the messaging flow, an unknown number pressures the user with urgency, secrecy, and a gift-card request. The user can reply normally and attach a gift-card image from the Mac. CodeShield runs OCR locally, detects the visible redemption code, combines that code with the scam context, and shows a large pre-send warning before the image is transmitted.

In the audio flow, the user starts an AI scam call. Gemma generates the scammer's side locally. Safe replies continue, but if the user tries to speak a gift-card PIN, CodeShield holds the audio before delivery, redacts the code, and shows the same warning pattern.

The warning is high-friction by design. It tells the user that the code has not left the Mac, shows a redacted version of the detected code, gives a safe next step, and displays Gemma 4 E4B's local structured risk analysis. The user can cancel immediately or use a deliberate two-step override.

## Why Gemma 4 and LiteRT Matter

Local inference is not just an implementation detail here. It is the product.

The people who need scam protection most may also be the least comfortable with a cloud service monitoring private family messages, call transcripts, and photos of gift cards. LiteRT-LM lets Gemma 4 E4B run on device, so the safety layer can reason over sensitive context without sending it away.

Gemma is used in two ways:

1. Local structured risk analysis. Gemma returns JSON describing the risk level, scam category, requested payment type, claimed identity, warning signals, and recommended next step.
2. Local demo scammer generation. The app can generate realistic scammer messages and caller lines without relying on a scripted transcript or remote API.

The deterministic CodeShield core remains the final safety gate. It detects and redacts gift-card codes, scores scam pressure, flags suspicious links, and blocks risky sends when a redeemable code is present. This pairing is important: Gemma gives flexible reasoning and explanation, while deterministic code detection keeps the irreversible safety decision reliable.

## Technical Architecture

- SwiftUI macOS app.
- Shared `CodeShieldCore` Swift module for scam-pressure scoring, suspicious-link detection, gift-card code detection, and redaction.
- Apple Vision OCR for image and PDF attachments.
- Apple Speech and AVAudioEngine for local spoken-response capture.
- AVSpeechSynthesizer for the audible AI caller demo.
- Gemma 4 E4B `.litertlm` model through the LiteRT-LM CLI.
- Environment-configurable model and CLI paths via `CODESHIELD_GEMMA_MODEL` and `CODESHIELD_LITERT_CLI`.
- Smoke-test target that verifies high-risk scams, benign gift-card mentions, compact Apple redemption codes, and suspicious-link behavior.

## What Works Today

- Real conversation UI, not a paste-in scanner.
- Real file picker for gift-card images and PDFs.
- Local OCR on the attached image.
- Detection of visible Apple-style redemption codes.
- Passive warnings for scam pressure even before a code is found.
- High-friction pre-send warning when a risky context and redeemable code meet.
- Two-step override for user agency.
- AI-generated scammer messages and calls using local Gemma.
- Audio call demo where a spoken PIN is held before transmission.
- No network dependency in the app flow.

## Why This Is Different

This is not a generic scam chatbot. The user does not paste suspicious text into a scanner and then decide what to do. CodeShield Edge sits in the communication workflow and intervenes only when the irreversible payload appears.

That creates a more realistic product path: an OS-level safety layer, messaging-app integration, share-sheet extension, browser extension, carrier call feature, or family safety mode for older adults.

## Limitations

This prototype is not integrated with Apple Messages, FaceTime, Android Messages, or a carrier phone stack. It is a standalone macOS app so the full interaction can be demonstrated without private APIs. Future versions should explore mobile share sheets, multilingual warnings, caregiver verification flows, and broader evaluation against synthetic and real scam/benign examples.

## Why We Did Not Fine-Tune

For this prototype, the biggest risk is not domain knowledge. It is reliability at the irreversible boundary. Fine-tuning could improve taxonomy or tone later, but the core safety requirement is deterministic: if a gift-card code appears in scam context, hold it before transmission. We therefore used Gemma 4 E4B locally for flexible reasoning and explanation, while keeping the final redaction gate deterministic.

## Closing

CodeShield Edge shows why edge AI matters for safety. A scam firewall is only trustworthy if private messages, calls, and gift-card images stay on device. Gemma 4 E4B through LiteRT-LM makes that local protection practical.
