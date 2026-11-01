#!/usr/bin/env python3
"""Current weather and a 7 day forecast from Open-Meteo.

usage: fetch_weather.py [city] [--fahrenheit]
Without a city the location comes from the IP address. Prints one JSON object; on failure
{"error": "..."}. MINFLAIR_WEATHER_API overrides the API host (tests).
"""
import json
import os
import sys
import urllib.parse
import urllib.request

API = os.environ.get("MINFLAIR_WEATHER_API", "https://api.open-meteo.com")
GEO = os.environ.get("MINFLAIR_WEATHER_GEO", "https://geocoding-api.open-meteo.com")
IPLOC = os.environ.get("MINFLAIR_WEATHER_IP", "https://ipwho.is/")


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "minflair-shell"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.load(r)


def locate(city):
    if city:
        res = get(f"{GEO}/v1/search?name={urllib.parse.quote(city)}&count=1")
        hit = (res.get("results") or [None])[0]
        if not hit:
            raise LookupError("city_not_found")
        return hit["latitude"], hit["longitude"], hit.get("name", city)
    res = get(IPLOC)
    if res.get("success") is False or "latitude" not in res:
        raise LookupError("no_location")
    return res["latitude"], res["longitude"], res.get("city", "")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    fahrenheit = "--fahrenheit" in sys.argv
    city = args[0].strip() if args else ""
    try:
        lat, lon, name = locate(city)
        unit = "&temperature_unit=fahrenheit&wind_speed_unit=mph" if fahrenheit else ""
        data = get(
            f"{API}/v1/forecast?latitude={lat}&longitude={lon}&timezone=auto&forecast_days=7{unit}"
            "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
            "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset"
        )
        cur = data["current"]
        daily = data["daily"]
        days = []
        for i, day in enumerate(daily["time"]):
            days.append({
                "date": day,
                "code": daily["weather_code"][i],
                "max": round(daily["temperature_2m_max"][i]),
                "min": round(daily["temperature_2m_min"][i]),
            })
        print(json.dumps({
            "city": name,
            "temp": round(cur["temperature_2m"]),
            "feels": round(cur["apparent_temperature"]),
            "humidity": cur["relative_humidity_2m"],
            "wind": round(cur["wind_speed_10m"]),
            "code": cur["weather_code"],
            "isDay": bool(cur.get("is_day", 1)),
            "sunrise": (daily.get("sunrise") or [""])[0][-5:],
            "sunset": (daily.get("sunset") or [""])[0][-5:],
            "unit": "°F" if fahrenheit else "°C",
            "windUnit": "mph" if fahrenheit else "km/h",
            "days": days,
        }))
    except LookupError as e:
        print(json.dumps({"error": str(e)}))
    except Exception:
        print(json.dumps({"error": "network"}))


main()
