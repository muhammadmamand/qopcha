"""One-shot Contabo deploy. Reads VPS_PASS / VPS_HOST from env. Do not commit secrets."""
import json
import os
import sys
import time
from pathlib import Path

import paramiko

HOST = os.environ.get("VPS_HOST", "169.58.230.144")
USER = os.environ.get("VPS_USER", "root")
PASSWORD = os.environ.get("VPS_PASS", "")
PUBKEY = os.environ.get("SSH_PUB", "").strip()
ROOT = Path(r"c:\xampp\htdocs\Shik Posh")
LOCAL_SERVER = ROOT / "server"
LOCAL_ADMIN = LOCAL_SERVER / "admin"
BUILD_WEB = ROOT / "build" / "web"

if not PASSWORD:
    sys.exit("VPS_PASS env missing")
if not PUBKEY:
    sys.exit("SSH_PUB env missing")


def main():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print("Connecting...")
    client.connect(
        HOST,
        username=USER,
        password=PASSWORD,
        timeout=45,
        allow_agent=False,
        look_for_keys=False,
    )
    print("SSH connected")

    def run(cmd, timeout=900, check=True):
        print(">", cmd[:140] + ("..." if len(cmd) > 140 else ""))
        _stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
        out = stdout.read().decode("utf-8", "replace")
        err = stderr.read().decode("utf-8", "replace")
        code = stdout.channel.recv_exit_status()
        if out.strip():
            print(out.strip()[:2500])
        if code != 0 and check:
            if err.strip():
                print("ERR:", err.strip()[:1500])
            raise SystemExit(f"Command failed ({code})")
        return out, err, code

    run(
        "mkdir -p /root/.ssh && chmod 700 /root/.ssh && "
        "touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"
    )
    pk = PUBKEY.replace("'", "'\"'\"'")
    run(
        f"grep -qxF '{pk}' /root/.ssh/authorized_keys || "
        f"echo '{pk}' >> /root/.ssh/authorized_keys"
    )
    print("SSH key installed")

    run("command -v docker >/dev/null || (curl -fsSL https://get.docker.com | sh)")
    run("systemctl enable --now docker || true", check=False)
    run("mkdir -p /opt/qopcha-api/admin /opt/qopcha-api/data /opt/qopcha-api/uploads /opt/qopcha-api/src")

    sftp = client.open_sftp()

    def put_file(local: Path, remote: str):
        print(f"upload {local.as_posix()} -> {remote}")
        sftp.put(str(local), remote)

    for name in [
        "docker-compose.yml",
        "Caddyfile",
        "Dockerfile",
        "package.json",
        "package-lock.json",
        "update.sh",
        "install_on_vps.sh",
        "bootstrap_contabo_vnc.sh",
        ".env.example",
    ]:
        p = LOCAL_SERVER / name
        if p.exists():
            put_file(p, f"/opt/qopcha-api/{name}")

    for p in (LOCAL_SERVER / "src").glob("*.js"):
        put_file(p, f"/opt/qopcha-api/src/{p.name}")

    admin_src = LOCAL_ADMIN if (LOCAL_ADMIN / "index.html").exists() else BUILD_WEB
    if not (admin_src / "index.html").exists():
        raise SystemExit("No admin web build found")
    print(f"Uploading admin from {admin_src}")
    for root, _dirs, files in os.walk(admin_src):
        rel = Path(root).relative_to(admin_src).as_posix()
        rdir = "/opt/qopcha-api/admin" if rel == "." else f"/opt/qopcha-api/admin/{rel}"
        run(f"mkdir -p {rdir}")
        for f in files:
            put_file(Path(root) / f, f"{rdir}/{f}")
    print("Admin uploaded")

    run(
        r"""bash -lc 'cd /opt/qopcha-api
if [ ! -f .env ]; then
  JWT=$(openssl rand -hex 32)
  cat > .env <<EOF
PORT=8080
PUBLIC_URL=https://169-58-230-144.sslip.io
JWT_SECRET=$JWT
ADMIN_EMAIL=admin@qopcha.com
ADMIN_PASSWORD=Admin123456
ADMIN_PHONE=07500000000
ALLOWED_ORIGIN=*
STANDING_API_URL=https://gateway.standingtech.com/api/v4/sms/send
VERIFYWAY_API_URL=https://gateway.standingtech.com/api/v4/sms/send
VERIFYWAY_API_TOKEN=
VERIFYWAY_CHANNEL=whatsapp
VERIFYWAY_FALLBACK_CHANNEL=sms
VERIFYWAY_SENDER=QopchaApp
STANDING_SENDER_ID=QopchaApp
STANDING_LANG=en
EOF
  chmod 600 .env
fi
grep -q "^STANDING_API_URL=" .env || echo "STANDING_API_URL=https://gateway.standingtech.com/api/v4/sms/send" >> .env
grep -q "^VERIFYWAY_API_URL=" .env || echo "VERIFYWAY_API_URL=https://gateway.standingtech.com/api/v4/sms/send" >> .env
grep -q "^VERIFYWAY_API_TOKEN=" .env || echo "VERIFYWAY_API_TOKEN=" >> .env
grep -q "^VERIFYWAY_FALLBACK_CHANNEL=" .env || echo "VERIFYWAY_FALLBACK_CHANNEL=sms" >> .env
grep -q "^STANDING_SENDER_ID=" .env || echo "STANDING_SENDER_ID=QopchaApp" >> .env
'"""
    )

    local_env = LOCAL_SERVER / ".env"
    if local_env.exists():
        token = ""
        for line in local_env.read_text(encoding="utf-8", errors="ignore").splitlines():
            if line.startswith("VERIFYWAY_API_TOKEN="):
                token = line.split("=", 1)[1].strip()
                break
        if token:
            tjson = json.dumps(token)
            run(
                "python3 - <<'PY2'\n"
                "from pathlib import Path\n"
                "p=Path('/opt/qopcha-api/.env')\n"
                "lines=p.read_text().splitlines()\n"
                "out=[]; found=False\n"
                "tok=" + tjson + "\n"
                "for line in lines:\n"
                "    if line.startswith('VERIFYWAY_API_TOKEN='):\n"
                "        out.append('VERIFYWAY_API_TOKEN='+tok); found=True\n"
                "    else:\n"
                "        out.append(line)\n"
                "if not found: out.append('VERIFYWAY_API_TOKEN='+tok)\n"
                "p.write_text('\\n'.join(out)+'\\n'); p.chmod(0o600)\n"
                "print('token_set')\n"
                "PY2"
            )

    run(
        "ufw allow OpenSSH || true; ufw allow 80/tcp || true; "
        "ufw allow 443/tcp || true; ufw --force enable || true",
        check=False,
    )
    run("cd /opt/qopcha-api && docker compose up -d --build", timeout=1200)
    time.sleep(4)
    run("curl -s http://127.0.0.1:8080/api/health || true", check=False)
    run(
        'curl -s -o /dev/null -w "staff=%{http_code}\\n" http://127.0.0.1/staff-console/ || true',
        check=False,
    )
    run("docker compose -f /opt/qopcha-api/docker-compose.yml ps", check=False)
    sftp.close()
    client.close()
    print("DONE")


if __name__ == "__main__":
    main()
