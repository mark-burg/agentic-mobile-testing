# Agentic mobile automation via AppClaw

## Usage

```bash
appclaw --flow flows/android/wifi-settings.yaml --platform android
appclaw --flow flows/ios/safari-search.yaml --platform ios --device-type simulator
appclaw --flow flows/suites/android-smoke.yaml
appclaw "Open Settings and turn on Wi-Fi"
appclaw --playground --platform ios --device-type simulator
appclaw --playground
```

## Files

```text
flows/android/              Android tests
flows/ios/                  iOS tests
flows/suites/               Multi-flow suites
.env.example                Config example
.github/workflows/          CI test runs
```

## Configuration

| Variable | Description |
|---|---|
| `AGENT_MODE` | Agent mode, e.g. `vision` |
| `VISION_MODE` | Vision mode, e.g. `fallback` |
| `MAX_STEPS` | Step limit for a run |
| `STEP_DELAY` | Delay between steps, in milliseconds |
| `LLM_PROVIDER` | LLM provider for the selected model |
| `LLM_API_KEY` | API key for the selected provider |
| `OPENAI_BASE_URL` | Base URL override for the model API |
| `LLM_MODEL` | Model name to use |
| `MCP_DEBUG` | Set to `1` to enable debug output |
