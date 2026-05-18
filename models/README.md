# Models

CodeShield Edge expects a local Gemma 4 E4B LiteRT-LM model at:

```text
models/gemma-4-E4B-it.litertlm
```

The model file is not committed to this repository because it is several gigabytes. Download the Gemma 4 E4B LiteRT-LM model from the official Gemma/LiteRT distribution you are using, accept the model license, and place the `.litertlm` file at the path above.

You can also point the app at a different location:

```bash
export CODESHIELD_GEMMA_MODEL="/absolute/path/to/gemma-4-E4B-it.litertlm"
```

If `litert-lm` is not in the default locations, set:

```bash
export CODESHIELD_LITERT_CLI="/absolute/path/to/litert-lm"
```

Quick CLI check:

```bash
litert-lm run models/gemma-4-E4B-it.litertlm \
  --backend=gpu \
  --enable-speculative-decoding=auto \
  --max-num-tokens=2048 \
  --temperature=0 \
  --prompt 'Return exactly this JSON and nothing else: {"risk_level":"low","score":0}'
```
