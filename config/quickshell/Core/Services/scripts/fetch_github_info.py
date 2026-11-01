#!/usr/bin/env python3
"""Fetch GitHub profile, repositories and activity counts for the dashboard (prints JSON).

usage: fetch_github_info.py <username>      token comes from MINFLAIR_GITHUB_TOKEN
"""
import sys

sys.dont_write_bytecode = True

import json
import os
import urllib.error
import urllib.parse
import urllib.request

TOKEN_ENV_VAR = "MINFLAIR_GITHUB_TOKEN"
API = os.environ.get("MINFLAIR_GITHUB_API", "https://api.github.com")  # override only for tests
MAX_PAGES = 5  # 500 repositories


def sanitize_token(value):
    if not value:
        return ""
    return "".join(c for c in value if c.isprintable() and not c.isspace()).strip()


def resolve_token(argv):
    # The environment keeps the credential out of /proc/<pid>/cmdline.
    token = sanitize_token(os.environ.get(TOKEN_ENV_VAR, ""))
    if token:
        return token
    return sanitize_token(argv[2]) if len(argv) > 2 else ""


class Api:
    def __init__(self, token):
        self.token = token
        self.rate = {}
        self.error = ""  # first meaningful error (shown in the widget)

    def get(self, path, authed=True, accept="application/vnd.github+json"):
        """Return (status, parsed_json). status 0 means the network failed."""
        req = urllib.request.Request(API + path)
        req.add_header("User-Agent", "Minflair-Shell")
        req.add_header("Accept", accept)
        req.add_header("X-GitHub-Api-Version", "2022-11-28")
        if authed and self.token:
            req.add_header("Authorization", f"Bearer {self.token}")
        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                self._note_rate(resp.headers)
                return resp.status, json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            self._note_rate(e.headers)
            try:
                body = json.loads(e.read().decode("utf-8"))
            except Exception:
                body = {}
            self._note_error(e.code, body, e.headers)
            return e.code, body
        except Exception as e:
            self._note_error(0, {"message": str(e)}, {})
            return 0, {}

    def _note_rate(self, headers):
        try:
            self.rate = {
                "limit": int(headers.get("X-RateLimit-Limit", 0)),
                "remaining": int(headers.get("X-RateLimit-Remaining", 0)),
            }
        except Exception:
            pass

    def _note_error(self, code, body, headers):
        if self.error:
            return
        msg = (body or {}).get("message", "")
        if code == 0:
            self.error = "network"
        elif code == 401:
            self.error = "bad_token"
        elif code in (403, 429) and (headers.get("X-RateLimit-Remaining") == "0" or "rate limit" in msg.lower()):
            self.error = "rate_limited"
        elif code == 403:
            self.error = "forbidden"
        elif code == 404:
            self.error = "not_found"
        else:
            self.error = f"http_{code}"


def download_avatar(url, dest):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Minflair-Shell"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = resp.read()
        tmp = dest + ".tmp"
        with open(tmp, "wb") as f:
            f.write(data)
        os.replace(tmp, dest)
        return True
    except Exception:
        return False


def compact_repo(r):
    return {
        "name": r.get("name", ""),
        "description": r.get("description") or "",
        "language": r.get("language") or "",
        "stars": r.get("stargazers_count", 0),
        "forks": r.get("forks_count", 0),
        "issues": r.get("open_issues_count", 0),
        "private": bool(r.get("private")),
        "fork": bool(r.get("fork")),
        "archived": bool(r.get("archived")),
        "pushed": r.get("pushed_at") or r.get("updated_at") or "",
        "url": r.get("html_url", ""),
    }


def fetch_repos(api, user, use_token):
    if use_token:
        path = "/user/repos?per_page=100&sort=pushed&affiliation=owner&page="
    else:
        path = f"/users/{urllib.parse.quote(user)}/repos?per_page=100&sort=pushed&page="
    repos = []
    for page in range(1, MAX_PAGES + 1):
        status, data = api.get(path + str(page), authed=use_token)
        if status != 200 or not isinstance(data, list):
            break
        repos.extend(compact_repo(r) for r in data if isinstance(r, dict))
        if len(data) < 100:
            break
    return repos


def search_count(api, query, authed):
    status, data = api.get("/search/issues?per_page=1&q=" + urllib.parse.quote(query), authed=authed)
    return data.get("total_count", 0) if status == 200 and isinstance(data, dict) else 0


def main():
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print(json.dumps({"error": "no_user"}))
        return

    user = sys.argv[1].strip()
    api = Api(resolve_token(sys.argv))
    result = {"hasToken": False, "tokenStatus": "none" if not api.token else "unknown", "tokenUser": ""}

    cache_dir = os.path.expanduser("~/.cache/quickshell")
    os.makedirs(cache_dir, exist_ok=True)
    clean = "".join(c for c in user if c.isalnum() or c in ("-", "_"))
    avatar = os.path.join(cache_dir, f"github_avatar_{clean}.png" if clean else "github_avatar.png")

    use_token = False
    profile = {}
    if api.token:
        status, me = api.get("/user")
        if status == 200 and isinstance(me, dict) and me.get("login"):
            result["tokenUser"] = me["login"]
            if me["login"].lower() == user.lower():
                use_token = True
                profile = me
                result["tokenStatus"] = "valid"
            else:
                result["tokenStatus"] = "other_user"
        elif status == 401:
            result["tokenStatus"] = "invalid"
        else:
            result["tokenStatus"] = "error"
        if not use_token:
            api.error = "" if result["tokenStatus"] == "other_user" else api.error

    if not profile:
        status, profile = api.get(f"/users/{urllib.parse.quote(user)}", authed=False)
        if status != 200 or not isinstance(profile, dict) or not profile.get("login"):
            result["error"] = api.error or "not_found"
            result["rate"] = api.rate
            print(json.dumps(result))
            return

    result["hasToken"] = use_token
    result["profile"] = profile

    avatar_url = profile.get("avatar_url") or f"https://github.com/identicons/{urllib.parse.quote(user)}.png"
    if download_avatar(avatar_url, avatar) or os.path.exists(avatar):
        result["avatar_path"] = avatar

    result["repos"] = fetch_repos(api, user, use_token)

    q = urllib.parse.quote(user)
    result["commits"] = {"total_count": 0}
    status, commits = api.get(f"/search/commits?per_page=1&q=author:{q}", authed=use_token)
    if status == 200 and isinstance(commits, dict):
        result["commits"] = commits
    result["openPRs"] = search_count(api, f"author:{user} type:pr state:open", use_token)
    result["openIssues"] = search_count(api, f"author:{user} type:issue state:open", use_token)

    result["rate"] = api.rate
    # Search endpoints may fail on their own (secondary limits) without invalidating the rest.
    result["error"] = api.error if api.error in ("rate_limited", "network") else ""
    print(json.dumps(result))


if __name__ == "__main__":
    main()
