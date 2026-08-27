# App Store + Codemagic (Windows) — do these in your browser
# Repo: https://github.com/muhammadmamand/qopcha
# Bundle ID: com.qopcha.Qopcha
# API (release): https://169-58-230-144.sslip.io

## A) App Store Connect API key (required for Codemagic)
1. Open https://appstoreconnect.apple.com
2. Users and Access → Integrations → App Store Connect API
3. Click + to Generate API Key
   - Name: Codemagic
   - Access: App Manager
4. Download the .p8 file (only once)
5. Copy and save:
   - Issuer ID (top of the page)
   - Key ID
   - .p8 file

## B) Codemagic
1. Open https://codemagic.io → Sign up with GitHub
2. Add application → select muhammadmamand/qopcha
3. Teams → Integrations → App Store Connect
   - Upload .p8
   - Paste Key ID + Issuer ID
   - Integration name must be: codemagic  (matches codemagic.yaml)
4. Code signing → iOS
   - Bundle ID: com.qopcha.Qopcha
   - Distribution: App Store
   - Enable automatic signing via App Store Connect
5. App settings → open codemagic.yaml workflow "ios-testflight"
6. Edit codemagic.yaml (in repo or UI) and set:
   - YOUR_EMAIL@example.com → your real email
   - APP_STORE_APPLE_ID: 0000000000 → numeric Apple ID
     (App Store Connect → Qopcha → App Information → Apple ID)
7. Start build → wait for TestFlight upload

## C) After Codemagic succeeds
1. App Store Connect → TestFlight → wait until build is Ready
2. Install TestFlight on iPhone → test Qopcha against HTTPS API
3. Distribution → version 1.0 → Build → + → select build
4. Finish screenshots / privacy / pricing → Add for Review

## Firebase (push)
Firebase Console → Project settings → Add iOS app
Bundle ID: com.qopcha.Qopcha → download GoogleService-Info.plist → replace ios/Runner/GoogleService-Info.plist → push again
