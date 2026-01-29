# Frontend Tests Structure

This folder groups unit and widget tests by layer and feature:

```
test/
  core/
    config/                # AppConfig tests
    network/               # AdaptiveNetworkManager tests
    utils/                 # Debounce/lock utilities tests
  presentation/
    widgets/               # ControlsPanel UI feedback tests
  providers/
    audio/                 # Playback controller/state/playlist tests
  widget_test.dart         # Theme/UI baseline tests
```

Integration tests live under `integration_test/`.

## Windows integration tests

Running multiple integration tests in a single command can be flaky on Windows.
Prefer running them sequentially with the provided script:

```
powershell -ExecutionPolicy Bypass -File ..\scripts\run_integration_windows.ps1
```

To override the per-test timeout (seconds):

```
powershell -ExecutionPolicy Bypass -File ..\scripts\run_integration_windows.ps1 -TimeoutSeconds 600
```
