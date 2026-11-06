#!/usr/bin/env python3
import sys

import gi

gi.require_version("GLib", "2.0")
gi.require_version("Gio", "2.0")

from gi.repository import Gio, GLib

FILTERS = [
    ("Images", [(0, "*.png"), (0, "*.jpg"), (0, "*.jpeg"), (0, "*.webp"), (0, "*.gif"), (0, "*.bmp"), (0, "*.svg")]),
]


def main():
    try:
        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    except GLib.Error:
        return 1

    token = "minflair_pick_%d" % GLib.get_monotonic_time()
    sender = bus.get_unique_name().lstrip(":").replace(".", "_")
    expected = "/org/freedesktop/portal/desktop/request/%s/%s" % (sender, token)
    state = {"code": 1, "uri": ""}
    loop = GLib.MainLoop()

    def on_response(conn, sender_name, obj_path, iface, signal, params):
        code, results = params.unpack()
        if code == 0:
            uris = results.get("uris", [])
            if uris:
                state["uri"] = uris[0]
                state["code"] = 0
            else:
                state["code"] = 2
        else:
            state["code"] = 2
        loop.quit()

    def on_timeout():
        loop.quit()
        return False

    sub = bus.signal_subscribe(
        "org.freedesktop.portal.Desktop",
        "org.freedesktop.portal.Request",
        "Response",
        expected,
        None,
        Gio.DBusSignalFlags.NONE,
        on_response,
    )
    timeout = GLib.timeout_add_seconds(300, on_timeout)

    options = {
        "handle_token": GLib.Variant("s", token),
        "modal": GLib.Variant("b", True),
        "multiple": GLib.Variant("b", False),
        "directory": GLib.Variant("b", False),
        "filters": GLib.Variant("a(sa(us))", FILTERS),
        "current_filter": GLib.Variant("(sa(us))", FILTERS[0]),
    }

    try:
        bus.call_sync(
            "org.freedesktop.portal.Desktop",
            "/org/freedesktop/portal/desktop",
            "org.freedesktop.portal.FileChooser",
            "OpenFile",
            GLib.Variant("(ssa{sv})", ("", "Choose profile picture", options)),
            None,
            Gio.DBusCallFlags.NONE,
            -1,
            None,
        )
    except GLib.Error:
        bus.signal_unsubscribe(sub)
        GLib.source_remove(timeout)
        return 1

    loop.run()
    bus.signal_unsubscribe(sub)
    GLib.source_remove(timeout)

    if state["code"] == 0 and state["uri"]:
        print(state["uri"])
        return 0

    return 2


if __name__ == "__main__":
    sys.exit(main())
