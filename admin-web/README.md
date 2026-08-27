# Qopcha Admin

React + TypeScript + Tailwind CSS admin console for the Qopcha Firebase
project. It replaces only the Flutter Web admin; the Flutter customer apps are
unchanged.

## Local development

```powershell
cd admin-web
npm install
npm run dev
```

Open the displayed Vite URL at `/staff-console`.

## Checks

```powershell
npm run lint
npm run build
```

## Deployment

Run `scripts\deploy_admin_web.bat` from the repository root. It builds this app
and deploys only the `qopchaapp` Firebase Hosting target.

Firebase configuration defaults to the same project used by Flutter. Production
values can be supplied using:

- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`

Authorization is Firebase Auth plus the `admin` custom claim, Cloud Functions
(`adminAction` / `bootstrapAdminClaim`), and tight Firestore/Storage rules.
The session is browser-tab only and logs out after 15 minutes of idle time.
