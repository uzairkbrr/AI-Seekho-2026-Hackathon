import httpx
import hashlib
import datetime
import asyncio
from app.core.models import Signal

_last = {}

def hash_content(src, txt):
    return hashlib.sha256(f"{src}:{txt}".encode()).hexdigest()[:32]

def is_dup(db, src, txt):
    h = hash_content(src, txt)
    return db.query(Signal).filter(Signal.content_hash == h).first() is not None

def add_sig(db, src, txt, lat, lng):
    if is_dup(db, src, txt): return None
    if lat is None or lng is None: lat, lng = 33.6844, 73.0479
    sig = Signal(source=src, content=txt, content_hash=hash_content(src, txt), lat=lat, lng=lng)
    db.add(sig)
    return sig

async def fetch_weather(db, lat, lng):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current_weather=true"
    async with httpx.AsyncClient(timeout=15.0) as c:
        try:
            res = await c.get(url)
            if res.status_code == 200:
                d = res.json()["current_weather"]
                txt = f"Weather: {d['temperature']}C, Wind: {d['windspeed']}km/h. Code: {d['weathercode']}."
                s = add_sig(db, "weather", txt, lat, lng)
                if s: 
                    db.commit()
                    db.refresh(s)
                _last["weather"] = datetime.datetime.utcnow()
                return [s] if s else []
        except: pass
    return []

async def fetch_nasa(db):
    url = "https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=10"
    sigs = []
    async with httpx.AsyncClient(timeout=15.0) as c:
        try:
            res = await c.get(url)
            if res.status_code == 200:
                for e in res.json().get("events", []):
                    txt = f"NASA: {e['title']}. Cat: {e['categories'][0]['title']}."
                    geo = e.get("geometry", [])
                    if geo:
                        pts = geo[0]["coordinates"]
                        s = add_sig(db, "nasa", txt, pts[1], pts[0])
                        if s: sigs.append(s)
                if sigs: db.commit()
                _last["nasa"] = datetime.datetime.utcnow()
        except: pass
    return sigs

async def fetch_quakes(db, lat, lng):
    url = f"https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&latitude={lat}&longitude={lng}&maxradiuskm=500&minmagnitude=3&limit=10"
    sigs = []
    async with httpx.AsyncClient(timeout=15.0) as c:
        try:
            res = await c.get(url)
            if res.status_code == 200:
                for f in res.json().get("features", []):
                    p = f["properties"]
                    pts = f["geometry"]["coordinates"]
                    txt = f"USGS: M{p['mag']} at {p['place']}."
                    s = add_sig(db, "quakes", txt, pts[1], pts[0])
                    if s: sigs.append(s)
                if sigs: db.commit()
                _last["quakes"] = datetime.datetime.utcnow()
        except: pass
    return sigs

async def ingest_all(db, lat=33.6844, lng=73.0479):
    tasks = [fetch_weather(db, lat, lng), fetch_nasa(db), fetch_quakes(db, lat, lng)]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    all_s = []
    for r in results:
        if not isinstance(r, Exception): all_s.extend(r)
    return {"count": len(all_s), "signals": all_s}
