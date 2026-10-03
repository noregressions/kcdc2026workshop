#!/usr/bin/env python3
"""Check whether package names exist on npm and PyPI, and how old and how used they are.
Usage: check-names.py name [name ...]   (read-only HTTP GETs against public registry APIs)"""
import json, sys, urllib.request, urllib.error
def get(url):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "name-check/1"}), timeout=20) as r:
            return r.status, json.load(r)
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return str(e), None
def npm(n):
    s, d = get(f"https://registry.npmjs.org/{n}")
    if s != 200: return f"absent ({s})"
    t = d.get("time", {}); un = t.get("unpublished")
    if un: return f"UNPUBLISHED (created {t.get('created','?')[:10]})"
    if "security holding" in json.dumps(d.get("description","")).lower() or d.get("dist-tags",{}).get("latest","").startswith("0.0.1-security"):
        return f"npm SECURITY HOLD (created {t.get('created','?')[:10]})"
    _, dl = get(f"https://api.npmjs.org/downloads/point/last-week/{n}")
    repo = (d.get("repository") or {}).get("url","") if isinstance(d.get("repository"), dict) else d.get("repository","")
    return f"EXISTS created {t.get('created','?')[:10]}, latest {d.get('dist-tags',{}).get('latest')}, {len(d.get('versions',{}))} versions, {dl.get('downloads') if dl else '?'} dl/wk, repo={'yes' if repo else 'none'}"
def pypi(n):
    s, d = get(f"https://pypi.org/pypi/{n}/json")
    if s != 200: return f"absent ({s})"
    up = [f["upload_time"] for v in d["releases"].values() for f in v]
    i = d["info"]; repo = any("github" in (u or "").lower() or "gitlab" in (u or "").lower() for u in (i.get("project_urls") or {}).values())
    return f"EXISTS first upload {min(up)[:10] if up else 'none'}, latest {i['version']}, {len(d['releases'])} releases, repo={'yes' if repo else 'none'}"
for n in sys.argv[1:]:
    print(f"{n:24} npm:  {npm(n)}")
    print(f"{'':24} pypi: {pypi(n)}")
