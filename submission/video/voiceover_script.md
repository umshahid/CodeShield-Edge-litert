# CodeShield Edge Video Voiceover

Target length: about 3 minutes.

## 0:00 - 0:15

This is CodeShield Edge, a local scam firewall for messages and calls. It warns someone before an irreversible gift-card code leaves their device.

## 0:15 - 0:40

Gift-card scams work because the attacker does not need a bank password. They only need the redeemable code. Once that code is texted, photographed, or spoken, the money can disappear.

The hard part is privacy. Families want protection, but they do not want a cloud service reading private messages, calls, or photos of gift cards.

## 0:40 - 1:45

Here is the messaging flow. An unknown number pressures the user with urgency and secrecy. CodeShield shows warning signs, but it does not interrupt every message.

Now the user attaches a real image from the Mac. In this video, it is a synthetic test gift card, not a real redeemable card. CodeShield runs OCR locally, detects the visible PIN, combines it with the scam context, and holds the send.

This warning appears before the code leaves the Mac. The user sees the image, the redacted code, the safe next step, and Gemma 4 E4B's local risk analysis. The user can cancel, or explicitly override in two steps.

This is the core product idea: intervene at the last safe moment.

## 1:45 - 2:35

The same idea works for calls. I click Start AI Scam Call, and Gemma generates the scammer's side locally. I can talk back or type what I would say.

If my response is safe, the call continues and the AI caller keeps pressuring me. But when I try to say a gift-card PIN, CodeShield holds the audio before it is transmitted, redacts the code, and shows the same warning flow.

## 2:35 - 3:10

Under the hood, CodeShield Edge is a SwiftUI Mac app with local Vision OCR, local speech capture, deterministic gift-card code detection, and Gemma 4 E4B running through LiteRT-LM.

Gemma provides flexible scam reasoning and structured JSON. The deterministic safety core keeps the final code-detection gate reliable.

## 3:10 - 3:30

This is built for the LiteRT track because local inference is the product. A scam firewall is only trustworthy if private messages, calls, and card images stay on device.

Today it is a standalone prototype. The bigger vision is an OS-level or messaging-level safety layer for families.

