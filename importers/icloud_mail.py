#!/usr/bin/env python3
"""Pull iCloud Mail threads (e.g. everything with Joe/John Smollen) into Markdown files.

Works in two places:
  * On your Mac (recommended, permanent): run it hourly with launchd and point --out at a
    Google Drive folder, so every Claude session can read the mail through the Drive connector.
  * In a Claude cloud session: once the environment allows imap.mail.me.com and has the
    ICLOUD_EMAIL / ICLOUD_APP_PASSWORD secrets (see importers/README.md). Goes through the
    session's HTTPS proxy automatically when HTTPS_PROXY is set.

Credentials (never on the command line):
  ICLOUD_EMAIL         your Apple ID mail address (e.g. you@icloud.com)
  ICLOUD_APP_PASSWORD  an app-specific password from account.apple.com
  On a Mac you can instead keep the password in the Keychain:
    security add-generic-password -a "$ICLOUD_EMAIL" -s icloud-imap -w
  and the script reads it from there when ICLOUD_APP_PASSWORD is unset.

Usage:
  python3 icloud_mail.py --match smollen --out "~/Google Drive/My Drive/AI Inbox/iCloud Mail"
  python3 icloud_mail.py --match smollen --match "american perpetual" --since 2024-01-01

Each message becomes <out>/<YYYY-MM-DD>__<subject>__<uid>.md; <out>/_index.json lists them and
remembers what was already pulled, so reruns only fetch new mail.
"""

from __future__ import annotations

import argparse
import base64
import email
import email.policy
import imaplib
import json
import os
import re
import socket
import ssl
import subprocess
import sys
from datetime import datetime, timezone
from email.message import EmailMessage
from email.utils import getaddresses, parsedate_to_datetime
from pathlib import Path
from urllib.parse import urlparse

HOST = "imap.mail.me.com"
PORT = 993
CA_BUNDLE = "/root/.ccr/ca-bundle.crt"  # the Claude cloud proxy's CA; ignored when absent


def password_for(user: str) -> str:
    pw = os.environ.get("ICLOUD_APP_PASSWORD")
    if pw:
        return pw
    if sys.platform == "darwin":
        try:
            return subprocess.run(
                ["security", "find-generic-password", "-a", user, "-s", "icloud-imap", "-w"],
                check=True, capture_output=True, text=True,
            ).stdout.strip()
        except (OSError, subprocess.CalledProcessError):
            pass
    sys.exit("Set ICLOUD_APP_PASSWORD (or, on a Mac, add it to the Keychain as service 'icloud-imap').")


def tunnel_socket(host: str, port: int) -> socket.socket:
    """TCP socket to host:port, through HTTPS_PROXY with HTTP CONNECT when one is set."""
    proxy = os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy")
    if not proxy:
        return socket.create_connection((host, port), timeout=30)
    p = urlparse(proxy if "://" in proxy else f"http://{proxy}")
    sock = socket.create_connection((p.hostname, p.port or 80), timeout=30)
    request = f"CONNECT {host}:{port} HTTP/1.1\r\nHost: {host}:{port}\r\n"
    if p.username:
        token = base64.b64encode(f"{p.username}:{p.password or ''}".encode()).decode()
        request += f"Proxy-Authorization: Basic {token}\r\n"
    sock.sendall((request + "\r\n").encode())
    response = b""
    while b"\r\n\r\n" not in response:
        chunk = sock.recv(4096)
        if not chunk:
            break
        response += chunk
    status = response.split(b"\r\n", 1)[0].decode(errors="replace")
    if " 200" not in status:
        sock.close()
        sys.exit(f"The proxy refused {host}:{port} ({status}). Add {host} to the environment's allowed domains.")
    return sock


class TunnelIMAP4_SSL(imaplib.IMAP4_SSL):
    def _create_socket(self, timeout):  # noqa: D401 (imaplib hook)
        ctx = ssl.create_default_context()
        if os.environ.get("HTTPS_PROXY") and Path(CA_BUNDLE).exists():
            ctx.load_verify_locations(CA_BUNDLE)
        return ctx.wrap_socket(tunnel_socket(self.host, self.port), server_hostname=self.host)


def connect(user: str, password: str) -> imaplib.IMAP4_SSL:
    imap = TunnelIMAP4_SSL(HOST, PORT)
    imap.login(user, password)
    return imap


def list_folders(imap: imaplib.IMAP4_SSL) -> list[str]:
    typ, data = imap.list()
    folders = []
    for raw in data or []:
        line = raw.decode(errors="replace") if isinstance(raw, bytes) else str(raw)
        if "\\Noselect" in line:
            continue
        m = re.search(r'"([^"]+)"\s*$', line) or re.search(r"\s(\S+)\s*$", line)
        if m:
            folders.append(m.group(1))
    return folders


def search_uids(imap: imaplib.IMAP4_SSL, term: str, since: str | None) -> list[bytes]:
    crit = []
    if since:
        crit += ["SINCE", datetime.strptime(since, "%Y-%m-%d").strftime("%d-%b-%Y")]
    # OR FROM / TO / CC / SUBJECT / BODY contain the term.
    q = f'"{term}"'
    crit += ["OR", "OR", "OR", "OR", "FROM", q, "TO", q, "CC", q, "SUBJECT", q, "BODY", q]
    typ, data = imap.uid("SEARCH", None, *crit)
    return (data[0] or b"").split() if typ == "OK" else []


def body_text(msg: EmailMessage) -> str:
    part = msg.get_body(preferencelist=("plain", "html"))
    if part is None:
        return ""
    text = part.get_content()
    if part.get_content_type() == "text/html":
        text = re.sub(r"(?is)<(script|style).*?</\1>", "", text)
        text = re.sub(r"(?i)<br\s*/?>|</p>|</div>", "\n", text)
        text = re.sub(r"<[^>]+>", "", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def attachments(msg: EmailMessage) -> list[str]:
    return [p.get_filename() for p in msg.iter_attachments() if p.get_filename()]


def slug(text: str, n: int = 60) -> str:
    s = re.sub(r"[^A-Za-z0-9]+", "-", text).strip("-")
    return (s[:n] or "no-subject").lower()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--match", action="append", default=[], help="name/address/phrase to match (repeatable); default: smollen")
    ap.add_argument("--since", help="only mail on/after YYYY-MM-DD")
    ap.add_argument("--out", default="icloud-mail", help="output folder")
    ap.add_argument("--folders", help="comma-separated folders (default: all selectable folders)")
    args = ap.parse_args()

    user = os.environ.get("ICLOUD_EMAIL") or sys.exit("Set ICLOUD_EMAIL.")
    terms = args.match or ["smollen"]
    out = Path(os.path.expanduser(args.out))
    out.mkdir(parents=True, exist_ok=True)
    index_path = out / "_index.json"
    index = json.loads(index_path.read_text()) if index_path.exists() else {"messages": {}}
    seen = set(index["messages"])

    imap = connect(user, password_for(user))
    folders = args.folders.split(",") if args.folders else list_folders(imap)
    new = 0
    for folder in folders:
        typ, _ = imap.select(f'"{folder}"', readonly=True)
        if typ != "OK":
            continue
        uids: set[bytes] = set()
        for term in terms:
            uids.update(search_uids(imap, term, args.since))
        for uid in sorted(uids, key=int):
            typ, data = imap.uid("FETCH", uid, "(RFC822)")
            if typ != "OK" or not data or not isinstance(data[0], tuple):
                continue
            msg = email.message_from_bytes(data[0][1], policy=email.policy.default)
            mid = (msg.get("Message-ID") or f"{folder}:{uid.decode()}").strip()
            if mid in seen:
                continue
            try:
                when = parsedate_to_datetime(msg.get("Date")).astimezone(timezone.utc)
            except (TypeError, ValueError):
                when = datetime.now(timezone.utc)
            subject = str(msg.get("Subject") or "(no subject)")
            people = {k: [f"{n} <{a}>" if n else a for n, a in getaddresses(msg.get_all(k, []))] for k in ("From", "To", "Cc")}
            name = f"{when:%Y-%m-%d}__{slug(subject)}__{uid.decode()}.md"
            files = attachments(msg)
            lines = [
                f"# {subject}",
                "",
                f"- **Date:** {when:%Y-%m-%d %H:%M} UTC",
                f"- **From:** {', '.join(people['From'])}",
                f"- **To:** {', '.join(people['To'])}",
                *( [f"- **Cc:** {', '.join(people['Cc'])}"] if people["Cc"] else [] ),
                f"- **Folder:** {folder}",
                *( [f"- **Attachments:** {', '.join(files)}"] if files else [] ),
                f"- **Message-ID:** {mid}",
                "",
                body_text(msg),
                "",
            ]
            (out / name).write_text("\n".join(lines), encoding="utf-8")
            index["messages"][mid] = {"file": name, "date": when.isoformat(), "subject": subject, "folder": folder}
            seen.add(mid)
            new += 1
    imap.logout()
    index["updated"] = datetime.now(timezone.utc).isoformat()
    index["terms"] = terms
    index_path.write_text(json.dumps(index, indent=2), encoding="utf-8")
    print(f"{new} new message(s); {len(index['messages'])} total in {out}")


if __name__ == "__main__":
    main()
