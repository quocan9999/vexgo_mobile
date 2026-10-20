# Flutter CI

Workflow: `.github/workflows/flutter-ci.yml`. It runs for PRs into `develop` and pushes to `develop`. Adding it to the existing PR triggers a `synchronize` run; it does not require merging first. Manual dispatch is also declared, but GitHub requires the workflow to exist on the repository's default branch before the manual trigger is available. This change does not modify `main` or merge the PR to enable that trigger.

The candidate is the exact PR **head SHA**, not GitHub's synthetic merge commit. `Format, analyze and tests` must pass before `Debug APK and artifact` starts. Both jobs use Flutter **3.38.7**, Dart **3.10.7**; Android uses Java **17**. Dependencies are restored with `--enforce-lockfile`, never upgraded. Format scans `.` on the clean checkout before tests/build generate build directories.

Permissions are `contents: read`; checkout credentials are not persisted. The workflow uses `pull_request`, never privileged `pull_request_target`, and does not read secrets, deploy, merge or alter branch protection. Top-level actions are pinned to verified full commit SHAs. A failing gate fails the job; APK upload is not allowed to silently succeed with a missing file.

## APK for reviewers

After successful CI, open the run's **Artifacts** section and download `vexgo-debug-<head-sha>-<attempt>`. It contains `app-debug.apk`, `build-metadata.json` and `SHA256SUMS`. The metadata records source SHA, toolchain, run/attempt, byte count and the APK's SHA256 (different from the uploaded archive digest). Retention is 14 days. GitHub authentication/access may be required to download.

This is a debug **Real Mode** APK, not a release or proof of bank settlement. The runner has no Backend/DB/OTP account or Android device. CI passing does not close live E2E gates.

Optional repository **variables**, all public build settings:

| Variable | Meaning |
|---|---|
| `MOBILE_API_BASE_URL` | Device-reachable API base including `/api/v1`. If absent, the app retains its local development default; a physical device needs ADB reverse or a reachable URL. |
| `SEPAY_BANK_ID` | Backend-approved public receiving-bank identifier |
| `SEPAY_ACCOUNT_NUMBER` | Public receiving account, matched to Backend configuration |
| `SEPAY_ACCOUNT_NAME` | Public receiving-account name |

No fake receiving account is injected. Missing bank variables leave positive-amount checkout blocked by existing app validation; tests/build can still run. Variables are passed as environment data and serialized to an ignored local defines file, not interpolated as shell commands. The raw file is not uploaded and metadata includes flags only, but supplied public values are compiled into the APK and are readable from it. Never add tokens, passwords or webhook/provider secrets to these variables or APK defines. Repository variables should be configured by the owner for the intended test environment; this change does not configure them.

The repo owner can require both workflow checks through branch protection after observing a successful run. This workflow does not change those repository settings. Lead review and live fare/device/provider evidence remain required before approving a merge candidate.
