# Kaggle Submission Strategy

## Competition Facts To Optimize Around

- Competition: The Gemma 4 Good Hackathon.
- Host: Google DeepMind on Kaggle.
- Deadline: 2026-05-18 23:59 UTC, which is 2026-05-18 7:59 PM EDT.
- Prize pool: $200,000.
- Submission settings visible from Kaggle: video required, links required, card image required, multiple tracks allowed.
- Strongest tracks for CodeShield Edge:
  - Special Technology Track: LiteRT, $10,000, for the most compelling and effective use case built using Google AI Edge's LiteRT implementation of Gemma 4.
  - Impact Track: Safety & Trust, $10,000, for transparency, reliability, groundedness, and explainability.
  - Main Track: eligible because it has a complete app, clear social impact, and technical execution.

## Positioning

Title:
CodeShield Edge: a local gift-card scam firewall for messages and calls

One-liner:
CodeShield Edge uses Gemma 4 E4B on LiteRT to warn older adults before an irreversible gift-card code leaves their device.

Core claim:
Gift-card scam prevention cannot require uploading private messages, calls, or card images to a cloud safety service. The safety check has to run locally, at the exact moment the user is about to send the code.

Why it can win:

- Specific problem: gift-card scams are concrete, emotional, costly, and irreversible.
- Specific user: older adults and families protecting them.
- Local-first wedge: people do not want Google, Apple, carriers, banks, or random apps reading every message or call.
- Clear demo: unknown number pressures "grandma"; user attaches a synthetic gift-card image from the Mac; CodeShield OCRs and redacts the code; Gemma explains the risk locally; user cancels.
- Multimodal: chat context, image OCR, and audio call transcript.
- LiteRT is essential, not decorative: the point of the product is a low-latency local model on personal hardware.

## What We Should Submit

Required Kaggle fields:

- Card image: use a clean hero screenshot of the warning sheet over the gift-card image.
- Video: 3 to 4 minutes, horizontal, screen recording plus short voiceover.
- Links:
  - Public GitHub repository.
  - Optional downloadable Mac app release zip.
  - Optional short demo video mirror if Kaggle accepts a URL.

Repo polish before final submission:

- Put `codeshield-mac` at the repo root or make the root README point directly to it.
- Add a short architecture diagram image or Mermaid diagram to the README.
- Do not commit the 3.4 GB `.litertlm` model unless the repo host supports it. Prefer instructions that download or place the model at `models/gemma-4-E4B-it.litertlm`.
- Add a small `models/README.md` explaining where to get the model.
- Include smoke-test instructions and expected output.

## Submission Narrative

Use this order everywhere:

1. Problem: gift-card scams are irreversible and target people through trusted-feeling conversations.
2. Trust gap: cloud monitoring of messages/calls is creepy, so many people would reject it.
3. Product: CodeShield Edge checks locally before the code leaves the device.
4. Demo: real message, real image, real OCR, real local Gemma classification, real warning.
5. Technical proof: SwiftUI app, Vision OCR, Speech, LiteRT-LM, Gemma 4 E4B, deterministic redaction fallback.
6. Impact: can become an OS-level or messaging-level safety layer, but the hackathon prototype already works as a standalone app.

## Final Submission Checklist

- Kaggle title and thumbnail are ready.
- Public repo link works in incognito/private browser.
- README has run instructions that a judge can follow.
- Video is under the Kaggle limit if one is shown in the UI.
- Video shows the LiteRT/Gemma local JSON in the app.
- Video says "no message, image, or audio transcript leaves the Mac."
- Writeup explicitly names Gemma 4 E4B and LiteRT-LM.
- Writeup explains why we did not fine-tune for the prototype: the product risk is privacy and timing, not domain facts; deterministic redaction plus local Gemma reasoning is more reliable for a safety gate.
- Future work includes OS-level integrations, caregiver mode, multilingual warnings, and evaluation on synthetic scam/benign corpora.
