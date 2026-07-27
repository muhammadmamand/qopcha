# Firebase setup for Shik Posh (project: qopchaapp)

Your Flutter code is ready for **Auth + Firestore + Storage**.
You must finish these steps once on your PC.

## Android package name
`com.shikposh.shik_posh`

## 1) Log in & configure
Open PowerShell:

```powershell
cd "c:\xampp\htdocs\Shik Posh"
firebase login
flutterfire configure --project=qopchaapp
```

If `flutterfire` is not found:

```powershell
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
flutterfire configure --project=qopchaapp
```

Select:
- Android app with package `com.shikposh.shik_posh`
- iOS only if you need it

This overwrites `lib/firebase_options.dart` and adds `android/app/google-services.json`.

## 2) Enable products in Firebase Console
Project **qopchaapp**:

1. **Authentication** → Sign-in method → enable **Email/Password**
2. **Firestore Database** → Create database → start in **test mode** (or paste `firestore.rules`)
3. **Storage** → Get started → paste `storage.rules` (or test mode)

## 3) Publish rules (recommended)
Firestore Console → Firestore → Rules → paste contents of `firestore.rules` → Publish  
Storage → Rules → paste `storage.rules` → Publish

## 4) Run the app
```powershell
flutter clean
flutter pub get
flutter run
```

## Collections used
- `users` — profiles (role, shopTier, shop fields)
- `products` — marketplace products
- `orders` — customer orders
- `product_images/` — Storage folder for uploads

## Note
Old demo accounts (`customer@demo.com`) will **not** work until you register real users in Firebase.
