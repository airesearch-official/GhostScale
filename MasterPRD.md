### 📋 Master PRD v2.0: "GhostScale" - Premium Offline Upscaler
**Target System:** Android (Flutter)
**Agent Role:** Senior Product Engineer & UI/UX Designer.

#### 1. Project Vision
* **Core Identity:** A premium, privacy-first AI tool. It must feel like a "Cyberpunk/Hacker" utility—sleek, dark, and powerful.
* **The User Promise:** "Your photos never leave this device. Infinite free upscaling. No internet required."

#### 2. Technical Architecture (Strict Constraints)
* **Framework:** Flutter (Latest Stable).
* **AI Engine:** `tflite_flutter` running **Real-ESRGAN-x4plus_quant.tflite**.
* **State Management:** `flutter_riverpod` or `provider` (Agent's choice for cleanliness).
* **Local Storage:** `shared_preferences` (to track "Rate Us" logic and "Onboarding Complete" state).

#### 3. UI/UX Requirements (The "Premium" Feel)

**A. The Onboarding Flow (First Launch Only)**
* **Instruction:** Create a 3-slide introduction using `introduction_screen` or a custom PageView.
* **Slide 1:** *Icon:* 🛡️ (Shield). *Title:* "100% Private." *Text:* "Your photos never leave this phone. No cloud uploads. No spying."
* **Slide 2:** *Icon:* 🚀 (Rocket). *Title:* "Offline AI Power." *Text:* "Uses your phone's processor. Works in Airplane Mode."
* **Slide 3:** *Icon:* ✨ (Sparkles). *Title:* "Unlimited & Free." *Text:* "No subscriptions. No credit cards. Just clean pixels."
* **Action:** "Get Started" button saves `seenOnboarding = true` to local storage so it never shows again.

**B. Main Screen (The Dashboard)**
* **Header:** "GhostScale" logo (top left) + "Settings/Info" Gear Icon (top right).
* **Status Indicator:** A small badge saying "🟢 OFFLINE READY" to reassure the user.
* **Center Area:**
    * If empty: Large, modern "Drop Zone" style button with a neon glow effect. Text: "Tap to Select Image."
    * If processing: A sleek progress bar with "AI Enhancing... (Do not close)" text.
    * If done: "Before / After" slider view (use `before_after` package).
* **Bottom Bar:** "Save to Gallery" (Primary Action) + "Discard" (Secondary).

**C. Settings & About Page**
* **Section 1: About.**
    * App Version (e.g., v1.0.0).
    * "Built with Real-ESRGAN."
    * "Privacy Policy" button (Opens a simple text dialog: *"This app runs locally. No data is collected."*).
* **Section 2: Support Us.**
    * "Rate this App" button.
    * "Share with Friends" button.

#### 4. Feature Logic (The "Brains")

**Feature: The Smart "Rate Us" Trigger**
* *Do not* show a popup on startup (users hate that).
* **Logic:** Track a variable `successful_upscales` in `shared_preferences`.
* **Trigger:** When `successful_upscales == 3` (after the user has actually received value), show a polite dialog: *"Loving the privacy? Rate us 5 stars to keep this app free forever."*

**Feature: Image Upscaling (The Engine)**
* **Input:** Allow picking from Gallery.
* **Pre-Processing:** Check image resolution. If > 2000px width, warn user: *"Image is large. Processing may be slow on older phones."*
* **Processing:** Run TFLite inference in an **Isolate** (background thread). This is mandatory to prevent UI freeze.
* **Output:** Save result to `Pictures/GhostScale` folder.

#### 5. Google Play Compliance Checklist (Agent Must Implement)
* **Android 13+ Permissions:** Use `READ_MEDIA_IMAGES` instead of `READ_EXTERNAL_STORAGE`.
* **Offline Policy:** Since we don't use the internet, strictly **remove** `android.permission.INTERNET` from `AndroidManifest.xml`.
    * *Why:* When Google reviews the app, seeing "No Internet Permission" guarantees automatic approval for many privacy checks.
* **Privacy Policy URL:** Add a placeholder string in the code for a website URL (Google Play requires a URL even for offline apps).

#### 6. Asset Instructions for the Agent
* "I (the user) will manually place `real_esrgan.tflite` in `assets/models/`. You (the Agent) just write the code to load it."
* "Use `google_fonts` (specifically 'Orbitron' or 'Roboto Mono') for that techy/AI look."

---