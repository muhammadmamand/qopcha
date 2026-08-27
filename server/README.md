# قۆپچە Contabo API

See root [DEPLOY.md](../DEPLOY.md) for full Contabo + GitHub auto-deploy.

## Local (this PC)

```bash
cp .env.example .env
# edit JWT_SECRET
npm install
PORT=8090 PUBLIC_URL=http://127.0.0.1:8090 node src/index.js
```

Seed demo products:

```bash
node scripts/seed_demo.js http://127.0.0.1:8090
```

## VPS (Docker)

```bash
bash install_on_vps.sh
bash update.sh   # after git push / manual refresh
```

Default admin (change after first login):

- email: `admin@qopcha.com`
- password: `Admin123456`
- phone: `07500000000`
