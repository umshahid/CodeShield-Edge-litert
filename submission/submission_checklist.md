# Submission Checklist

## Kaggle Fields

- Title: `CodeShield Edge: Local Gift-Card Scam Firewall for Messages and Calls`
- Track: LiteRT Special Technology Track
- Additional fit: Safety & Trust Impact Track and Main Track
- Public repository: `https://github.com/umshahid/CodeShield-Edge-litert`
- Video: add final video URL
- Card image: upload `submission/card_image.png`
- Media gallery: use your final video thumbnail or clean screenshots you capture during the final recording.

## Before Final Submit

- Confirm the GitHub repo opens in an incognito/private browser.
- Confirm the README shows the warning screenshot.
- Confirm `submission/kaggle_entry.md` is pasted into the Kaggle writeup.
- Add the final video URL in the Kaggle form and in `submission/kaggle_entry.md`.
- Upload `submission/card_image.png` as the card image.
- Mention "Gemma 4 E4B through LiteRT-LM" in the video and writeup.
- Mention "the code has not left this Mac" in the video.
- Do not include a real redeemable gift-card code anywhere public.

## Local Verification Commands

```bash
swift build
swift run CodeShieldSmoke
swift run CodeShieldOCRDebug submission/video/assets/synthetic_gift_card.png
```

Expected smoke-test output:

```text
CodeShieldSmoke passed
```

Expected OCR debug behavior:

- detects `ATF7LQJ4AL9YWFDV`
- redacts it to `[GIFT CARD CODE BLOCKED]`
- marks the scam-context send as blocked

## Repository Hygiene

- Do not commit `.build/`.
- Do not commit `dist/`.
- Do not commit `.litertlm` model files.
- Keep `models/README.md` with model placement instructions.
- Keep synthetic demo assets only.
