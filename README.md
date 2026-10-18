# Agent Weave Workbench

## Install Tensai

The source ZIP is not an installer. End-user packages are:

- **Windows:** `.github/workflows/desktop.yml` produces `Tensai-Setup.exe`, a single-click x64 installer containing Electron and the local server. Node.js is not required on the user's PC. Ollama and an AI model are still separate prerequisites for offline AI. GitHub release metadata supports automatic updates.
- **Android:** `.github/workflows/android.yml` produces a signed `Tensai.apk` using the Capacitor project in `mobile/`. This opens the published online studio; it does **not** implement offline Android AI.

Connect a GitHub repository and run the workflows. Android releases require repository secrets `TENSAI_ANDROID_KEYSTORE_BASE64`, `TENSAI_ANDROID_STORE_PASSWORD`, `TENSAI_ANDROID_KEY_ALIAS`, and `TENSAI_ANDROID_KEY_PASSWORD`. Keep the signing identity stable for future APK updates; never commit it.

After downloading and verifying installation on each target device, set the public HTTPS release URLs in `public/downloads/installers.json` and update the published web app. Until verified URLs exist, downloads remain disabled instead of serving a source archive. Windows unsigned installers may show SmartScreen warnings; trusted code signing requires a signing certificate.

Create an AI app to build, configure, and run individual AI agents that perform tasks together as one coordinated system, featuring custom agent creation (roles, system prompts, skills), workflow chaining to pass tasks between agents, and a central dashboard with real-time execution logs and output tracking.

This project was built with [Lovable](https://lovable.dev).

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/59240457-0686-4918-9b35-706f0cd21c77).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```
