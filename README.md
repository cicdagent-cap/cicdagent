# iOS CI/CD Pipeline with GitHub Actions, Fastlane & Firebase

A complete, production-ready iOS CI/CD pipeline using GitHub Actions, Fastlane, and Firebase App Distribution with Microsoft Teams notifications.

<<<<<<< HEAD
## First Step For Any New Project

Before using CICD agent modes (`Create Pipeline` or `Trigger Build`) in a new repository, run the standard onboarding checklist in:

- `CICD_HOT_RUN_SETUP.md`

Fast path (recommended):

```bash
./scripts/bootstrap_new_ios_repo.sh <target-repo-path> <bundle-id>
```

Example:

```bash
./scripts/bootstrap_new_ios_repo.sh /Users/you/projects/MyiOSApp com.example.myiosapp
```

## Quick Start
=======
## ⚡ Quick Status
>>>>>>> 0d22cc920dff921e8edc7f6eca902593478b9e11

| Component | Status | Notes |
|-----------|--------|-------|
| **Xcodebuild Timeout** | ✅ FIXED | 180s timeout, 10 retries configured |
| **Firebase Distribution** | ✅ FIXED | Full Firebase CLI integration |
| **Teams Notifications** | ✅ FIXED | Smart status notifications (started/success/failure/cancelled) |
| **Build Trigger** | ✅ FIXED | Manual + push/PR triggers enabled |
| **Swift Packages** | ✅ FIXED | Auto-resolution step included |
| **Code Signing** | ✅ READY | Match-based certificate management |

---

## 📁 Project Structure

```
cicdagent/
├── .github/
│   └── workflows/
│       └── ios-ci.yml              # Main CI/CD workflow (FIXED)
├── fastlane/
│   ├── Fastfile                    # Fastlane lanes (FIXED with timeouts)
│   ├── Appfile                     # Apple credentials config
│   ├── Matchfile                   # Code signing config
│   └── Pluginfile                  # Fastlane plugins
├── .env.example                    # All environment variables (UPDATED)
├── .notification.local.env         # Local-only secrets (git-ignored)
├── cicd/                           # iOS app source code
├── cicdTests/                      # Unit tests
└── README.md                       # This file
```

---

## 🔧 Part A: Fix Xcodebuild Timeout Error

### Problem
```
xcodebuild -showBuildSettings timed out after 4 retries with a base timeout of 3 seconds
```

### Solution: ✅ ALREADY FIXED

**In `.github/workflows/ios-ci.yml`:**
```yaml
env:
  FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT: 180      # 3 seconds → 180 seconds
  FASTLANE_XCODEBUILD_SETTINGS_RETRIES: 10       # 4 retries → 10 retries
  XCBUILD_TIMEOUT: 300                            # 5 minutes max per build
```

**In `fastlane/Fastfile` (before_all block):**
```ruby
before_all do
  ENV["FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT"] = "180"
  ENV["FASTLANE_XCODEBUILD_SETTINGS_RETRIES"] = "10"
  ENV["XCBUILD_TIMEOUT"] = "300"
end
```

---

## 🔥 Part B: Firebase App Distribution Setup

### Prerequisites
- Firebase project created at https://console.firebase.google.com
- Firebase CLI installed: `npm install -g firebase-tools`

### Step 1: Generate Firebase CLI Token

Run this **locally** (not in CI/CD):
```bash
firebase login:ci
```

Output will be:
```
✔ Success! Use this token to login on a CI server:

1//0gF1X2Z3a4b5c6d7e8f9g0h1i2j3k4l5m6n7o8...
```

**Copy this token** — you'll need it for GitHub Secrets.

### Step 2: Get Firebase App ID

1. Open https://console.firebase.google.com
2. Select your project
3. **Project Settings** (gear icon, top left)
4. **General** tab
5. Under "Your apps" section, find iOS app
6. Copy the **App ID** (format: `1:000000000000:ios:xxxxxxxxxxxxxxxx`)

### Step 3: Create Firebase Testing Groups

1. In Firebase Console → **App Distribution** (left sidebar)
2. **Testers & Groups** tab
3. Click **Create Group**
4. Name: `testers` (or your preferred name)
5. Add tester email addresses
6. Click **Create**

### Step 4: Add GitHub Secrets

1. Go to GitHub: **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add these secrets:

| Name | Value |
|------|-------|
| `FIREBASE_TOKEN` | Paste the token from `firebase login:ci` |
| `FIREBASE_APP_ID` | Your Firebase App ID from Firebase Console |

### Step 5: Add GitHub Variables

1. In the same location: **Secrets and variables** → **Variables**
2. Add these variables:

| Name | Value |
|------|-------|
| `FIREBASE_GROUPS` | `testers` (or your group name) |

### Workflow Lanes

**Build & distribute to Firebase:**
```bash
bundle exec fastlane ios firebase_distribute
```

Internally:
1. Builds IPA with ad-hoc provisioning
2. Authenticates with Firebase
3. Uploads to Firebase App Distribution
4. Notifies testers

---

## 💬 Part C: Microsoft Teams Notification Setup

### Prerequisites
- Microsoft Teams account
- Access to a Teams channel where you want build notifications

### Step 1: Create Incoming Webhook

1. Open your Teams channel
2. **⋯ More options** (top right) → **Connectors**
3. Search for **"Incoming Webhook"** → **Configure**
4. Give it a name: `iOS CI/CD Pipeline`
5. Optionally upload an icon (e.g., Apple logo)
6. Click **Create**
7. **Copy the webhook URL** — looks like:
   ```
   https://outlook.webhook.office.com/webhookb2/abc123...
   ```

### Step 2: Add GitHub Secret

1. Go to GitHub: **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add:
   - **Name:** `TEAMS_WEBHOOK_URL`
   - **Value:** Paste the webhook URL from Teams

### Step 3: Test the Webhook

You can test locally:
```bash
# Source your local env
source .notification.local.env

# Send a test message
curl -X POST -H "Content-Type: application/json" \
  -d '{
    "@type": "MessageCard",
    "@context": "https://schema.org/extensions",
    "summary": "Test Message",
    "themeColor": "0078D4",
    "sections": [{"activityTitle": "✅ iOS Build Test", "text": "Webhook is working!"}]
  }' \
  "$TEAMS_WEBHOOK_URL"
```

### Notifications You'll Receive

| Event | Color | Emoji |
|-------|-------|-------|
| Build Started | 🔵 Blue | 🚀 |
| Build Success | 🟢 Green | ✅ |
| Build Failed | 🔴 Red | ❌ |
| Build Cancelled | 🟡 Yellow | ⏹️ |

Each notification includes:
- Workflow name
- Run number
- Branch name
- Direct link to workflow run

---

## 🎯 Part D: Manual Build Trigger from GitHub UI

### Method 1: Manual Trigger (Recommended)

1. Go to GitHub: **Actions** tab
2. On the left: Select **iOS CI/CD Pipeline**
3. Click **Run workflow** button (right side)
4. Choose environment from dropdown:
   - `development` (default)
   - `staging`
   - `production`
5. Click **Run workflow** (green button)
6. **Workflow starts immediately**

### Method 2: Via CLI

```bash
gh workflow run ios-ci.yml -f environment=development
```

### Method 3: Automatic Triggers

The workflow automatically triggers on:
- **Push to `main` or `develop` branch**
- **Pull request to `main` branch**

---

## 📋 Part E: All Required GitHub Secrets & Variables

### Required Secrets
Store in: **Settings** → **Secrets and variables** → **Actions** → **Secrets**

```yaml
FIREBASE_TOKEN:           # From: firebase login:ci
FIREBASE_APP_ID:          # From: Firebase Console
TEAMS_WEBHOOK_URL:        # From: Teams Incoming Webhook
MATCH_GIT_URL:            # Your certificate repository URL
MATCH_PASSWORD:           # Password to decrypt certificates
FASTLANE_TEAM_ID:         # Apple Developer Team ID
FASTLANE_ITC_TEAM_ID:     # App Store Connect Team ID
```

### Required Variables
Store in: **Settings** → **Secrets and variables** → **Actions** → **Variables**

```yaml
CICD_PROJECT_FILE:        # cicd.xcodeproj
CICD_DEFAULT_SCHEME:      # cicd
CICD_DEFAULT_CONFIGURATION: # Debug
CICD_TEST_DESTINATION:    # platform=iOS Simulator,name=iPhone 15,OS=latest
FIREBASE_GROUPS:          # testers (comma-separated)
```

### Copy-Paste Checklist

- [ ] FIREBASE_TOKEN (from `firebase login:ci`)
- [ ] FIREBASE_APP_ID (from Firebase Console)
- [ ] TEAMS_WEBHOOK_URL (from Teams Incoming Webhook)
- [ ] MATCH_GIT_URL (your certificate repo)
- [ ] MATCH_PASSWORD (certificate encryption password)
- [ ] FASTLANE_TEAM_ID (from Apple Developer account)
- [ ] FASTLANE_ITC_TEAM_ID (from App Store Connect)
- [ ] CICD_PROJECT_FILE=`cicd.xcodeproj`
- [ ] CICD_DEFAULT_SCHEME=`cicd`
- [ ] CICD_DEFAULT_CONFIGURATION=`Debug`
- [ ] CICD_TEST_DESTINATION=`platform=iOS Simulator,name=iPhone 15,OS=latest`
- [ ] FIREBASE_GROUPS=`testers`

---

## 🔐 Secrets Configuration Guide (Step-by-Step User Prompting)

### **SECTION 1: Firebase Configuration**

**Q1: What is your Firebase Project ID?**
- Go to: https://console.firebase.google.com
- Select your project
- **Project Settings** → **General** tab
- Find "Project ID" (e.g., `my-app-123456`)
- Your answer: `_____________________`

**Q2: What is your Firebase App ID?**
- In Project Settings → **General** tab
- Under "Your apps" → Select iOS app
- Copy the **App ID** (format: `1:123456789:ios:abcdef123456`)
- Your answer: `_____________________`
- **GitHub Secret Name:** `FIREBASE_APP_ID`

**Q3: Generate Firebase CLI Token**
- Run locally (not in CI/CD):
  ```bash
  npm install -g firebase-tools
  firebase login:ci
  ```
- Copy the generated token (e.g., `1//0gF1X2Z3a4b5c6...`)
- Your answer: `_____________________`
- **GitHub Secret Name:** `FIREBASE_TOKEN`
- ⚠️ **SECURITY:** This token is sensitive—store ONLY in GitHub Secrets, never in code

**Q4: What Firebase tester groups do you have?**
- Firebase Console → **App Distribution** → **Testers & Groups**
- List your groups (e.g., `testers`, `internal`, `qa-team`, `beta-users`)
- Your answer: `_____________________`
- **GitHub Variable Name:** `FIREBASE_GROUPS`

---

### **SECTION 2: Apple Developer Account**

**Q5: What is your Apple Developer Team ID?**
- Go to: https://developer.apple.com/account
- **Membership** section
- Find "Team ID" (e.g., `ABC1234567`)
- Your answer: `_____________________`
- **GitHub Secret Name:** `FASTLANE_TEAM_ID`

**Q6: What is your App Store Connect Team ID?**
- Go to: https://appstoreconnect.apple.com
- **Users and Access**
- Find "Provider ID" or "Team ID"
- Your answer: `_____________________`
- **GitHub Secret Name:** `FASTLANE_ITC_TEAM_ID`

**Q7: What is your iOS App Bundle Identifier?**
- Xcode → **Build Settings** → Search "Bundle Identifier"
- Or: Info.plist → Bundle Identifier (e.g., `com.yourcompany.appname`)
- Your answer: `_____________________`
- **GitHub Variable Name:** `FASTLANE_BUNDLE_IDENTIFIER`

---

### **SECTION 3: Code Signing (Fastlane Match)**

**Q8: Do you have a Fastlane Match certificates repository?**
- [ ] Yes, I have one: `git@github.com:yourorg/certificates.git`
- [ ] No, I need to create one

If **YES**:

**Q9: What is your Match repository URL?**
- Format: `git@github.com:yourorg/certificates.git` (SSH) 
- Or: `https://github.com/yourorg/certificates.git` (HTTPS)
- Your answer: `_____________________`
- **GitHub Secret Name:** `MATCH_GIT_URL`

**Q10: What is your Match encryption password?**
- You created this when setting up match initially
- Your answer: `_____________________`
- **GitHub Secret Name:** `MATCH_PASSWORD`
- ⚠️ **SECURITY:** This password is sensitive—store ONLY in GitHub Secrets

**Q11: Does your Match repository require authentication?**
- [ ] No, it's public or I own it
- [ ] Yes, I need basic auth

If **YES**:

**Q12: Generate GitHub Basic Auth Token**
- GitHub Settings → **Developer settings** → **Personal access tokens** → **Generate new token**
- Scopes: `repo`
- Generate token (e.g., `ghp_abc123xyz...`)
- Encode in base64: `echo -n "username:token" | base64`
- Your answer: `_____________________`
- **GitHub Secret Name:** `MATCH_GIT_BASIC_AUTHORIZATION`

If **NO**:

Setup match with: `fastlane match init`

---

### **SECTION 4: Xcode Project Settings**

**Q13: What is your Xcode project file name?**
- Your project folder (e.g., `MyApp.xcodeproj`)
- Your answer: `_____________________`
- **GitHub Variable Name:** `CICD_PROJECT_FILE`

**Q14: What is your default build scheme?**
- Xcode → **Product** → **Manage Schemes**
- Your scheme name (e.g., `MyApp`)
- Your answer: `_____________________`
- **GitHub Variable Name:** `CICD_DEFAULT_SCHEME`

**Q15: What is your default build configuration?**
- Options: `Debug`, `Release`
- Your answer: `_____________________`
- **GitHub Variable Name:** `CICD_DEFAULT_CONFIGURATION`

**Q16: What is your simulator test destination?**
- Default: `platform=iOS Simulator,name=iPhone 15,OS=latest`
- Or custom (e.g., `platform=iOS Simulator,name=iPhone 16,OS=latest`)
- Your answer: `_____________________`
- **GitHub Variable Name:** `CICD_TEST_DESTINATION`

---

### **SECTION 5: Notifications (Microsoft Teams)**

**Q17: Do you want Teams notifications?**
- [ ] Yes, I use Microsoft Teams
- [ ] No, skip Teams setup

If **YES**:

**Q18: Create Teams Incoming Webhook**
1. Open Teams → Your channel
2. **⋯ More options** → **Connectors** → **Incoming Webhook**
3. **Configure** → Name: `iOS CI/CD Pipeline`
4. Copy the webhook URL (e.g., `https://outlook.webhook.office.com/webhookb2/...`)
- Your answer: `_____________________`
- **GitHub Secret Name:** `TEAMS_WEBHOOK_URL`
- ⚠️ **SECURITY:** This URL is sensitive—store ONLY in GitHub Secrets

---

## **FINAL STEP: Add All Secrets to GitHub**

### **How to Add Secrets to GitHub**

1. Open your repository on GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. For each secret below, paste the value from your answers above:

| Secret Name | Your Value | Source |
|------------|-----------|--------|
| `FIREBASE_TOKEN` | Q3 answer | Firebase CLI token |
| `FIREBASE_APP_ID` | Q2 answer | Firebase Console |
| `FASTLANE_TEAM_ID` | Q5 answer | Apple Developer account |
| `FASTLANE_ITC_TEAM_ID` | Q6 answer | App Store Connect |
| `MATCH_GIT_URL` | Q9 answer | Your certificates repo |
| `MATCH_PASSWORD` | Q10 answer | Your encryption password |
| `MATCH_GIT_BASIC_AUTHORIZATION` | Q12 answer | GitHub basic auth (if needed) |
| `TEAMS_WEBHOOK_URL` | Q18 answer | Teams Incoming Webhook |

### **How to Add Variables to GitHub**

1. Same location: **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository variable**
3. For each variable below, paste the value from your answers above:

| Variable Name | Your Value | Source |
|--------------|-----------|--------|
| `CICD_PROJECT_FILE` | Q13 answer | Your Xcode project |
| `CICD_DEFAULT_SCHEME` | Q14 answer | Your build scheme |
| `CICD_DEFAULT_CONFIGURATION` | Q15 answer | Build configuration |
| `CICD_TEST_DESTINATION` | Q16 answer | Simulator destination |
| `FIREBASE_GROUPS` | Q4 answer | Firebase tester groups |
| `FASTLANE_BUNDLE_IDENTIFIER` | Q7 answer | App bundle ID |

### **Security Checklist**

- ✅ All secrets are stored in GitHub Secrets (not in code)
- ✅ All sensitive tokens are unique to this project
- ✅ Webhook URL has limited scope to this Teams channel
- ✅ Firebase CLI token can be regenerated if compromised
- ✅ Match password is securely encrypted

---

## 🏗️ Part F: Xcode Scheme Verification

The build will fail if your Xcode scheme is not shared. Here's how to fix it:

### Step 1: Open Xcode
```bash
open cicd.xcodeproj
```

### Step 2: Manage Schemes
1. **Product** menu → **Manage Schemes...**
2. Select your scheme (`cicd`)
3. ✅ Check the **Shared** checkbox
4. Click **Close**

### Step 3: Verify in Git
After sharing, you should see:
```bash
git status
# You'll see new/modified files:
# cicd.xcodeproj/xcshareddata/xcschemes/cicd.xcscheme
```

This file **must be committed** for CI/CD to work:
```bash
git add cicd.xcodeproj/xcshareddata/xcschemes/
git commit -m "Share Xcode scheme for CI/CD"
git push
```

---

## 🚀 Fastlane Lanes Reference

Run these **locally** during development:

```bash
# Install dependencies
bundle install

# Run unit tests
bundle exec fastlane ios test

# Build debug version
bundle exec fastlane ios build

# Build IPA for distribution
bundle exec fastlane ios build_ipa

# Distribute to Firebase (requires signing)
bundle exec fastlane ios firebase_distribute

# Release to TestFlight (requires signing)
bundle exec fastlane ios release

# Send Teams notification
bundle exec fastlane ios notify_teams status:success message:"Build successful"
```

---

## 🔐 Code Signing: Fastlane Match

The pipeline uses **Fastlane Match** for secure certificate management.

### Prerequisites
1. **Create a private GitHub repository** for certificates (e.g., `your-org/certificates`)
2. **Generate a GitHub Personal Access Token** with `repo` access
3. **Set up a Fastfile/Matchfile** (already done in this repo)

### Setup Steps

1. **Create GitHub token** (if not already done):
   - GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Generate new token**
   - Scopes: `repo`
   - Copy the token

2. **Initialize Match locally**:
   ```bash
   fastlane match init
   # Follow prompts to create certificate repository
   ```

3. **Add to GitHub Secrets**:
   - `MATCH_GIT_URL`: Your certificate repository URL
   - `MATCH_PASSWORD`: Encryption password for certificates
   - `MATCH_GIT_BASIC_AUTHORIZATION`: Base64-encoded token (if needed)

4. **First run** (generates certificates):
   ```bash
   bundle exec fastlane match development
   bundle exec fastlane match adhoc
   bundle exec fastlane match appstore
   ```

---

## 📊 Workflow File Structure

The main workflow (`.github/workflows/ios-ci.yml`) includes:

### Steps
1. ✅ **Checkout** — Get latest code
2. ✅ **Setup Ruby** — Install Ruby 3.2
3. ✅ **Notify Teams** — Build started
4. ✅ **Resolve Packages** — Swift package dependencies
5. ✅ **Run Tests** — Unit tests on iOS Simulator
6. ✅ **Build App** — Debug build
7. ✅ **Build IPA** — Ad-hoc provisioned IPA
8. ✅ **Upload Artifact** — Save IPA for 7 days
9. ✅ **Firebase Distribute** — Send to testers
10. ✅ **Notify Teams** — Success/failure status

### Environment Variables
```yaml
FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT: 180   # Prevent timeout errors
FASTLANE_XCODEBUILD_SETTINGS_RETRIES: 10    # Retry failed commands
XCBUILD_TIMEOUT: 300                         # Max 5 minutes per build
FASTLANE_OPT_OUT_USAGE: YES                 # Disable analytics
```

---

## 🛠️ Troubleshooting

### Problem: "xcodebuild -showBuildSettings timed out"
**Solution**: Already fixed! Timeout is now 180 seconds with 10 retries.

### Problem: Firebase distribution fails
**Check:**
- [ ] `FIREBASE_TOKEN` is set in GitHub Secrets
- [ ] `FIREBASE_APP_ID` is correct
- [ ] Firebase CLI is installed: `npm install -g firebase-tools`
- [ ] App is registered in Firebase Console

**Test locally:**
```bash
firebase appdistribution:distribute cicd.ipa \
  --app 1:000000000000:ios:xxxxxxxxxxxxxxxx \
  --release-notes "Test build" \
  --groups testers \
  --token YOUR_TOKEN
```

### Problem: Teams webhook not receiving notifications
**Check:**
- [ ] `TEAMS_WEBHOOK_URL` is set in GitHub Secrets
- [ ] Webhook URL is valid (test locally with curl)
- [ ] Webhook hasn't expired (Teams webhooks expire after 180 days of inactivity)

**Test webhook:**
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"@type":"MessageCard","@context":"https://schema.org/extensions","summary":"Test","sections":[{"activityTitle":"Test"}]}' \
  "YOUR_WEBHOOK_URL"
```

### Problem: Build fails with "Scheme not found"
**Solution**: Share your Xcode scheme:
1. Xcode → **Product** → **Manage Schemes...**
2. Select `cicd` scheme
3. ✅ Check **Shared**
4. Commit: `git add cicd.xcodeproj/xcshareddata/xcschemes/`

### Problem: "FIREBASE_APP_ID must be set"
**Solution**: Add `FIREBASE_APP_ID` to GitHub Secrets:
1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**
3. **Name:** `FIREBASE_APP_ID`
4. **Value:** Get from Firebase Console → Project Settings → General

---

## 📚 Complete File Reference

### Files Modified
- ✅ `.github/workflows/ios-ci.yml` — Complete workflow with all fixes
- ✅ `fastlane/Fastfile` — Timeout fixes, Firebase, Teams notifications
- ✅ `.env.example` — Comprehensive environment variable documentation

### Key Workflows
```
.github/workflows/ios-ci.yml
├── Trigger: push, pull_request, workflow_dispatch
├── Environment: macOS 14, Ruby 3.2
└── Jobs:
    ├── Checkout
    ├── Setup Ruby + Fastlane
    ├── Resolve Swift packages
    ├── Run tests
    ├── Build app
    ├── Build IPA
    ├── Firebase distribution
    └── Teams notifications (x4 states)
```

### Fastlane Lanes
```
fastlane/Fastfile
├── before_all — Set timeout env vars
├── build — Debug build
├── test — Unit tests
├── build_ipa — Ad-hoc IPA
├── firebase_distribute — Firebase distribution
├── release — TestFlight release
├── notify_teams — Teams notifications
└── error handler — Failure notifications
```

---

## 🎓 Quick Start Checklist

- [ ] 1. Configure GitHub Secrets (8 required)
- [ ] 2. Configure GitHub Variables (6 required)
- [ ] 3. Set up Firebase project + get credentials
- [ ] 4. Set up Teams webhook + get URL
- [ ] 5. Share Xcode scheme (`Product` → `Manage Schemes` → ✅ `Shared`)
- [ ] 6. Commit scheme file: `git add .xcodeproj/xcshareddata/`
- [ ] 7. Run first manual trigger: **Actions** → **Run workflow**
- [ ] 8. Check workflow logs for any errors
- [ ] 9. Verify Teams notification arrives
- [ ] 10. Verify IPA uploaded to Firebase

---

## 📞 Support & Resources

- **Firebase App Distribution Docs**: https://firebase.google.com/docs/app-distribution
- **Fastlane Docs**: https://docs.fastlane.tools/
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Teams Webhooks**: https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using

---

## 📝 Changelog

### Latest (Fixed)
- ✅ Xcodebuild timeout: 3s → 180s with 10 retries
- ✅ Firebase distribution: Full CLI integration
- ✅ Teams notifications: Smart multi-state with rich formatting
- ✅ Build triggers: Push, PR, manual workflow_dispatch
- ✅ Swift packages: Auto-resolution step added
- ✅ Code signing: Match-based infrastructure ready
- ✅ Fastlane lanes: 7 lanes + error handling + Teams integration

---

**Last Updated:** 2026-06-18
**Status:** Production Ready ✅

| Input | Values |
| --- | --- |
| `preset` | `Debug-CICD`, `Release-CICD` |

The workflow runs Fastlane:

- `Debug-CICD` -> `fastlane ios build`
- `Release-CICD` -> `fastlane ios release`

## Fastlane Setup

Fastlane reads configuration from environment variables:

| File | Uses |
| --- | --- |
| `fastlane/Appfile` | `FASTLANE_BUNDLE_IDENTIFIER`, `FASTLANE_TEAM_ID`, `FASTLANE_ITC_TEAM_ID` |
| `fastlane/Fastfile` | `CICD_PROJECT_FILE`, `CICD_DEFAULT_SCHEME`, `CICD_DEFAULT_CONFIGURATION`, `CICD_TEST_DESTINATION`, `RELEASE_NOTES` |
| `fastlane/Matchfile` | `MATCH_GIT_URL`, `FASTLANE_BUNDLE_IDENTIFIER`, `FASTLANE_TEAM_ID` |

Available lanes:

- `ios build`
- `ios test`
- `ios release`

## Trigger Build Locally

Prerequisites:

- GitHub CLI installed: `gh`
- GitHub CLI authenticated: `gh auth login`
- Local env file configured: `.notification.local.env`

Inspect workflow inputs before triggering:

```bash
./scripts/inspect_workflow_inputs.sh https://github.com/example-org/example-repo/actions/workflows/build.yml feature/example
```

Trigger an existing workflow:

```bash
./scripts/trigger_existing_workflow.sh \
  https://github.com/example-org/example-repo/actions/workflows/build.yml \
  feature/example \
  preset=Debug-CICD \
  config_Override=None \
  Release_Notes="Demo build"
```

The trigger script prints one of these environment statuses before dispatch:


or:

```text
Missing env setup
Run: cp .env.example .notification.local.env
```

After dispatch, the script extracts the exact GitHub Actions run URL, starts a background monitor for that run, and sends the final notification for that specific build only.

## Notifications

Notifications are sent by:

- `scripts/notify.sh`

The notification contains only:

- final status
- build/run link

Required local values:

```bash
TEAM_WEBHOOK_URL=<webhook-url>
CICD_CHAT_PROVIDER=teams
```

Supported providers:

- `teams`
- `slack`
- `generic`

If `TEAM_WEBHOOK_URL` is missing, the scripts skip notification without failing the build trigger.

## CICD Agent Behavior

The workspace CICD agent is defined in:

- `.github/agents/CICD.agent.md`
- `.github/prompts/create-pipeline.prompt.md`
- `.github/prompts/trigger-build.prompt.md`

Trigger Build flow:

1. Ask for workflow URL.
2. Ask for branch name.
3. Inspect workflow inputs with `scripts/inspect_workflow_inputs.sh`.
4. Ask only for inputs discovered in the workflow YAML.
5. Trigger with `scripts/trigger_existing_workflow.sh`.
6. Show the run URL.

The agent should not fetch branch lists and should not infer a branch.

## Create Pipeline Flow

Pipeline creation uses this template:

- `.github/pipeline-templates/ios-fastlane-workflow.template.yml`

The agent should use `.github/pipeline-request.yml` as the request example and should not copy values from existing generated workflows unless explicitly asked.

## File Map

| Path | Purpose |
| --- | --- |
| `.env.example` | Local setup template |
| `.notification.local.env` | Local secrets/config, ignored by git |
| `.github/workflows/cicd-ios.yml` | Current GitHub Actions iOS workflow |
| `.github/cicd.config.yml` | Agent/runtime config and required values |
| `.github/cicd.env.config.yml` | Environment defaults reference |
| `.github/trigger-build-request.yml` | Trigger request example |
| `.github/pipeline-request.yml` | Pipeline creation request example |
| `scripts/inspect_workflow_inputs.sh` | Reads workflow_dispatch inputs from a workflow URL |
| `scripts/trigger_existing_workflow.sh` | Triggers a workflow URL and monitors the exact run |
| `scripts/notify.sh` | Sends status and build link notification |
| `fastlane/Appfile` | Fastlane app/team config from env |
| `fastlane/Fastfile` | Fastlane lanes |
| `fastlane/Matchfile` | Fastlane match config from env |

## Security Rules

- Commit `.env.example` only with placeholders.
- Never commit `.notification.local.env`.
- Store local real values in `.notification.local.env` or shell env.
- Store CI real values in GitHub Secrets and Variables.
- Never hardcode webhook URLs, Apple API keys, tokens, certificates, provisioning profiles, or passwords.
