# Demo Video Script

Target length: 3 to 4 minutes.

Recording style: horizontal screen recording of the Mac app, with voiceover. Keep the app large enough that the warning sheet and Gemma JSON are readable.

Safety note: do not publish a real unused gift-card code in the video, thumbnail, or media gallery. Use a synthetic test card image, a redeemed/deactivated card, or blur the original image while keeping CodeShield's redacted OCR text visible.

## 0:00 - 0:15 Hook

Visual:
Open on the CodeShield Messages screen with an unknown number.

Voiceover:
"This is CodeShield Edge, a local gift-card scam firewall. It warns someone before an irreversible gift-card code leaves their device."

Action:
Open the Scammer Console.

## 0:15 - 0:45 Problem

Visual:
Use Scammer Console to send:
"Grandma, I was arrested after an accident. Please do not tell mom."

Then click `AI Next Message`.

Voiceover:
"Gift-card scams work because the attacker only needs the redeemable code. Once that code is texted, photographed, or spoken, the money can disappear. But cloud monitoring of private messages and calls is a trust problem, especially for families."

## 0:45 - 1:45 Messaging Demo

Visual:
In the main app, type:
"ok what do you need?"

Attach the synthetic gift-card image with the visible code.

Press send.

Expected result:
The warning sheet appears.

Voiceover:
"CodeShield reads the image locally, detects the Apple gift-card code, combines that with the scam context, and holds the send. The image has not left the Mac."

Show:
- "Do Not Send This Code"
- attached image
- redacted code
- safe next step
- Gemma E4B JSON
- `Don't Send`, `I Understand`, and the two-step `Send Anyway` override

Click `Don't Send`.

Voiceover:
"This is not a generic chatbot. It intervenes at the last safe moment, before the code is sent."

## 1:45 - 2:35 Audio Demo

Visual:
Switch to Audio Call.

Click `Start AI Scam Call`. Let the local AI caller speak the first scammer line.

Reply once with a safe response such as:
"What do you need me to do?"

Press the mic send button and let the AI caller continue.

In the call response box, use:
"The PIN is ATF7LQJ4AL9YWFDV."

Press the mic send button.

Expected result:
The audio warning sheet appears.

Voiceover:
"The same local firewall works for calls. Gemma plays the scammer locally in the background, but before my spoken PIN is delivered, CodeShield detects and redacts it locally."

Show Gemma JSON when it finishes.

Click `Don't Send`.

## 2:35 - 3:20 Architecture

Visual:
Show README or a simple architecture slide/screenshot.

Voiceover:
"Under the hood, this is a SwiftUI Mac app with local Vision OCR, local speech capture, a deterministic gift-card code detector, and Gemma 4 E4B running through LiteRT-LM. Gemma returns structured risk JSON, while the local safety core keeps the final redaction gate deterministic."

Show terminal briefly:

```bash
swift run CodeShieldSmoke
```

Expected output:

```text
CodeShieldSmoke passed
```

## 3:20 - 3:50 Impact and Track Fit

Visual:
Return to the warning sheet or a final title card.

Voiceover:
"CodeShield Edge is built for the LiteRT track because local inference is the product. A safety layer like this is only trustworthy if private messages, calls, and gift-card images stay on device. The standalone app is a prototype, but the idea can become an OS-level or messaging-level safety firewall."

End screen text:

CodeShield Edge
Local Gift-Card Scam Firewall
Gemma 4 E4B + LiteRT-LM

## Screenshot Shot List

Use these for the Kaggle media gallery and card image:

1. Main Messages screen with unknown number and AI scammer message.
2. Pending gift-card image attached, before send.
3. Big "Do Not Send This Code" warning with redacted gift-card code.
4. Gemma E4B JSON visible in the warning sheet.
5. Scammer Console with `AI Next Message` and `AI Speak`.
6. Audio Call screen with `Start AI Scam Call` active.
7. Audio warning sheet holding the spoken PIN.
