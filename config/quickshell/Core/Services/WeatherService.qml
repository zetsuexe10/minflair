pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services

// Weather for the dashboard (Open-Meteo, located by IP or by the city in settings).
Item {
    id: root

    property bool loaded: false
    property string error: ""
    property string city: ""
    property int temp: 0
    property int feels: 0
    property int humidity: 0
    property int wind: 0
    property int code: 0
    property bool isDay: true
    property string sunrise: ""
    property string sunset: ""
    property string unit: "°C"
    property string windUnit: "km/h"
    property var days: []
    readonly property string description: describe(code)
    readonly property string glyph: glyphFor(code, isDay)
    readonly property string errorText: {
        switch (error) {
        case "":
            return "";
        case "city_not_found": return "City not found";
        case "no_location": return "Could not work out your location";
        default: return "No connection";
        }
    }

    function describe(c) {
        if (c === 0) return "Clear sky";
        if (c <= 2) return "Partly cloudy";
        if (c === 3) return "Overcast";
        if (c === 45 || c === 48) return "Fog";
        if (c >= 51 && c <= 57) return "Drizzle";
        if (c >= 61 && c <= 67) return "Rain";
        if (c >= 71 && c <= 77) return "Snow";
        if (c >= 80 && c <= 82) return "Showers";
        if (c === 85 || c === 86) return "Snow showers";
        if (c >= 95) return "Thunderstorm";
        return "Unknown";
    }

    function glyphFor(c, day) {
        if (c === 0) return day ? "☀" : "☾";
        if (c <= 3) return "⛅";
        if (c === 45 || c === 48) return "≋";
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "☂";
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "❄";
        if (c >= 95) return "⚡";
        return "☁";
    }

    function refresh() {
        proc.running = false;
        const cmd = ["python3", Quickshell.shellDir + "/Core/Services/scripts/fetch_weather.py", SettingsService.weatherCity];
        if (SettingsService.weatherFahrenheit)
            cmd.push("--fahrenheit");
        proc.command = cmd;
        proc.running = true;
    }

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim());
                    root.error = d.error || "";
                    if (d.error)
                        return ;
                    root.city = d.city;
                    root.temp = d.temp;
                    root.feels = d.feels;
                    root.humidity = d.humidity;
                    root.wind = d.wind;
                    root.code = d.code;
                    root.isDay = d.isDay;
                    root.sunrise = d.sunrise;
                    root.sunset = d.sunset;
                    root.unit = d.unit;
                    root.windUnit = d.windUnit;
                    root.days = d.days;
                    root.loaded = true;
                } catch (e) {
                    root.error = "network";
                }
            }
        }
    }

    Connections {
        target: SettingsService

        function onWeatherCityChanged() { root.refresh(); }
        function onWeatherFahrenheitChanged() { root.refresh(); }
        function onSettingsLoadedChanged() { if (SettingsService.settingsLoaded) root.refresh(); }
    }

    Timer {
        interval: 1800000
        running: SettingsService.settingsLoaded
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
