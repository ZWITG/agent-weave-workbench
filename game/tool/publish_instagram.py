"""Publishes the day's Instagram posts from a batch's instagram_schedule.json
through the Instagram API with Instagram Login (graph.instagram.com).

The token comes from the cloud environment: either a network secret for
graph.instagram.com (the proxy adds the Authorization header, so this
script sends a placeholder), or the IG_ACCESS_TOKEN environment variable.
Media is fetched by Instagram from the public repo through jsDelivr.

  python3 tool/publish_instagram.py media/social/batch3/instagram_schedule.json --check
  python3 tool/publish_instagram.py media/social/batch3/instagram_schedule.json --date 2026-11-16
  python3 tool/publish_instagram.py ... --date 2026-11-16 --dry-run

Posts already on the account (same caption opening) are skipped, so a run
can be repeated safely. Stories are not checked that way; a story is only
posted when --date matches exactly. "manual_story" items (poll and question
stickers, which the API can't add) are printed as reminders, not posted.
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

API = 'https://graph.instagram.com/v21.0'
TOKEN = os.environ.get('IG_ACCESS_TOKEN', '')


def call(method, path, **params):
    url = f'{API}/{path}'
    if TOKEN:
        params['access_token'] = TOKEN
    data = None
    if method == 'GET':
        url += '?' + urllib.parse.urlencode(params)
    else:
        data = urllib.parse.urlencode(params).encode()
    req = urllib.request.Request(url, data=data, method=method)
    if not TOKEN:
        req.add_header('Authorization', 'Bearer placeholder-replaced-by-proxy')
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors='replace')
        raise SystemExit(f'{method} {path} failed ({e.code}): {body}')


def media_url(sched, name):
    return f"https://cdn.jsdelivr.net/gh/{sched['repo']}@{sched['ref']}/{sched['dir']}/{name}"


def wait_ready(cid, video):
    for _ in range(60 if video else 12):
        st = call('GET', cid, fields='status_code').get('status_code')
        if st == 'FINISHED':
            return
        if st in ('ERROR', 'EXPIRED'):
            raise SystemExit(f'container {cid} {st}: {call("GET", cid, fields="status")}')
        time.sleep(10 if video else 3)
    raise SystemExit(f'container {cid} not ready in time')


def publish(me, sched, post, caption):
    kind, files = post['kind'], post['files']
    if kind == 'image':
        cid = call('POST', f'{me}/media', image_url=media_url(sched, files[0]), caption=caption)['id']
    elif kind == 'story':
        cid = call('POST', f'{me}/media', media_type='STORIES', image_url=media_url(sched, files[0]))['id']
    elif kind == 'reel':
        cid = call('POST', f'{me}/media', media_type='REELS', video_url=media_url(sched, files[0]),
                   caption=caption, share_to_feed='true')['id']
    elif kind == 'carousel':
        kids = []
        for f in files:
            k = call('POST', f'{me}/media', image_url=media_url(sched, f), is_carousel_item='true')['id']
            wait_ready(k, False)
            kids.append(k)
        cid = call('POST', f'{me}/media', media_type='CAROUSEL', children=','.join(kids), caption=caption)['id']
    else:
        raise SystemExit(f'unknown kind {kind}')
    wait_ready(cid, kind == 'reel')
    return call('POST', f'{me}/media_publish', creation_id=cid)['id']


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('schedule')
    ap.add_argument('--date', help='YYYY-MM-DD (default: today, UTC)')
    ap.add_argument('--check', action='store_true', help='only check the token and the media links')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()
    sched = json.load(open(a.schedule))
    who = call('GET', 'me', fields='user_id,username')
    me = who['user_id']
    print(f"Signed in as @{who['username']} ({me})")
    if a.check:
        bad = 0
        for p in sched['posts']:
            for f in p['files']:
                req = urllib.request.Request(media_url(sched, f), method='HEAD')
                try:
                    urllib.request.urlopen(req, timeout=60)
                except Exception as e:  # noqa: BLE001
                    bad += 1
                    print('unreachable:', f, e)
        print('media links ok' if not bad else f'{bad} media links failed')
        return
    day = a.date or time.strftime('%Y-%m-%d', time.gmtime())
    todays = [p for p in sched['posts'] if p['date'] == day]
    if not todays:
        print(f'nothing scheduled for {day}')
        return
    recent = call('GET', f'{me}/media', fields='caption', limit=50).get('data', [])
    seen = {(m.get('caption') or '')[:60] for m in recent}
    for p in todays:
        cap = sched['captions'].get(p.get('caption', ''), '')
        label = f"{p['kind']}: {', '.join(p['files'][:2])}{'…' if len(p['files']) > 2 else ''}"
        if p['kind'] == 'manual_story':
            print(f"REMINDER (post by hand): {p['files'][0]}: {p['note']}")
            continue
        if cap and cap[:60] in seen:
            print(f'already posted, skipping {label}')
            continue
        if a.dry_run:
            print(f'would post {label}')
            continue
        pid = publish(me, sched, p, cap)
        print(f'posted {label} -> {pid}')


if __name__ == '__main__':
    sys.exit(main())
