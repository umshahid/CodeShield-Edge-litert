# Kaggle Writeup Draft

## CodeShield Edge: Local Gift-Card Scam Firewall

CodeShield Edge is a private, on-device safety layer that warns people before an irreversible gift-card code leaves their device. It is built for one common and painful scam pattern: an unknown caller or texter pressures an older adult to buy gift cards and send a photo, PIN, or redemption code.

The key idea is simple: scam detection should happen at the last safe moment, before the code is sent, without uploading private messages, calls, or gift-card images to the cloud.

## The Problem

Gift-card scams work because the payment rail is instant, emotional, and hard to reverse. The attacker does not need the victim's bank password. They only need a redeemable code. Once the code is sent, the money can disappear quickly.

Existing defenses usually arrive too late or require too much trust:

- A bank may warn after the purchase, but the scam often happens after the victim already has the card.
- Family members may not know until after the code is shared.
- Cloud safety services can feel invasive because they imply someone is monitoring private messages, images, or calls.

CodeShield Edge focuses on the exact irreversible moment: the user is about to send or say the code.

## What We Built

We built a macOS prototype that behaves like a real messaging and call app.

In the messaging flow, the user receives scam messages from an unknown number, replies normally, and chooses a synthetic gift-card image from the Mac. CodeShield runs OCR locally, detects the visible redemption code, analyzes the conversation context, and displays a large pre-send warning before the image leaves the device.

In the audio flow, the app simulates a live call. The scammer can speak aloud, the user can type or dictate a spoken response, and CodeShield checks the transcript locally before delivering a gift-card PIN to the caller.

The warning is intentionally high-friction but not mysterious. The user sees:

- "Do Not Send This Code"
- proof that the code has not left the Mac
- a redacted version of the detected code
- Gemma 4 E4B's structured local risk analysis
- a safe next step, such as calling the family member through a saved contact
- a safe cancel path and a deliberate two-step override

## Why Gemma 4 and LiteRT Matter

The product only makes sense if it can run locally. People who would benefit from scam protection may not want a large company or third-party service reading their private messages, family calls, and photos of gift cards. LiteRT makes Gemma 4 practical for this kind of edge safety workflow.

Gemma 4 E4B is used in two places:

1. Local risk classification. Given the conversation or call context and the attempted outgoing payload, Gemma returns structured JSON with the risk level, scam category, requested payment type, claimed identity, warning signals, and safe next step.
2. Demo scammer generation. The Scammer Console can generate realistic incoming scammer messages and caller lines locally, which makes the demo interactive instead of scripted.

The app also includes a deterministic local safety core. That core detects gift-card codes, redacts them, and applies a conservative scam-risk policy. This combination matters for safety: Gemma provides flexible reasoning and explanation, while the deterministic layer makes the final code-detection gate reliable.

## Architecture

The prototype is implemented as a SwiftUI macOS app.

Flow:

1. User receives scam pressure in the Messages or Audio Call surface.
2. User attempts to send a message, image, or spoken response.
3. Local OCR or local speech transcription extracts text from the payload.
4. The CodeShield core detects redeemable gift-card codes and analyzes scam pressure signals.
5. Gemma 4 E4B runs locally through LiteRT-LM and returns structured risk JSON.
6. If the context is risky and a code is present, the app holds the send and shows a warning.
7. The user can cancel or explicitly override.

Technical components:

- SwiftUI for the desktop app.
- Apple Vision OCR for image/PDF text extraction.
- Apple Speech and AVAudioEngine for local speech capture.
- AVSpeechSynthesizer for the simulated caller voice.
- Gemma 4 E4B `.litertlm` model through the LiteRT-LM CLI.
- Shared `CodeShieldCore` Swift module for deterministic detection, risk scoring, and redaction.

## What Works Today

- Real message conversation UI.
- Real image/PDF attachment picker.
- Local OCR on actual gift-card images.
- Detection of labeled PINs and unlabeled Apple-style redemption codes.
- Large pre-send warning with redacted code preview.
- Local Gemma 4 E4B classification JSON shown in the app.
- Separate Scammer Console for live demo control.
- AI-generated scammer messages and caller lines using local Gemma.
- Audio-call surface with caller speech and local speech capture.
- Smoke tests for high-risk scam cases and benign code-sharing cases.

## Why This Is Different

This is not another generic safety chatbot. The user does not paste a suspicious message into a scanner and wait for advice. CodeShield Edge sits inside the workflow and intervenes at the last safe moment before an irreversible code leaves the device.

It also avoids the core privacy problem of safety monitoring. The app does not need to send the message, image, or call transcript to a cloud API. That makes the concept much easier to imagine inside operating systems, messaging apps, carrier tools, senior-friendly devices, or family safety products.

## Limitations and Next Steps

This prototype is a standalone macOS app, not an OS-level Messages or phone integration. That is intentional for the hackathon: it makes the safety interaction demoable without private APIs.

Next steps:

- Android and iOS versions using platform-native share sheets and accessibility-safe integrations where allowed.
- A browser extension for gift-card images shared through web chat.
- Multilingual scam-pressure detection and warnings.
- Caregiver-approved contacts and "verify with family" flows.
- Larger evaluation set with synthetic and real-world scam/benign examples.
- Optional fine-tuning or LoRA for scam taxonomy and warning phrasing, while keeping deterministic code detection as the final gate.

## Track Fit

CodeShield Edge is strongest for the LiteRT Special Technology Track because the use case depends on local Gemma inference. It also fits Safety & Trust in the Impact Track because the model output is transparent, the code is redacted, and the user receives an explainable warning before taking an irreversible action.
