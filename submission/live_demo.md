# Live Demo Notes

CodeShield Edge is a native macOS prototype. The live demo is the runnable repository plus the demo video.

## Run Locally

```bash
git clone https://github.com/umshahid/CodeShield-Edge-litert.git
cd CodeShield-Edge-litert
swift build
swift run CodeShieldMac
```

Place the Gemma 4 E4B LiteRT-LM model at:

```text
models/gemma-4-E4B-it.litertlm
```

or set:

```bash
export CODESHIELD_GEMMA_MODEL="/absolute/path/to/gemma-4-E4B-it.litertlm"
export CODESHIELD_LITERT_CLI="/absolute/path/to/litert-lm"
```

## Judge-Friendly Demo Path

1. Open `Scammer Console`.
2. Send a scammer message or click `AI Next Message`.
3. Attach `submission/video/assets/synthetic_gift_card.png`.
4. Press send and observe the local warning.
5. Switch to `Audio Call`.
6. Click `Start AI Scam Call`.
7. Send `The PIN is ATF7LQJ4AL9YWFDV.`
8. Observe the spoken-PIN warning.

## Verification

```bash
swift run CodeShieldSmoke
swift run CodeShieldOCRDebug submission/video/assets/synthetic_gift_card.png
```
