local function run(binary, command)
	hl.exec_cmd("sh -c 'command -v " .. binary .. " >/dev/null 2>&1 && exec " .. (command or binary) .. "'")
end

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	run("hypridle")
	run("wl-paste", "wl-paste --type text --watch cliphist store")
	run("wl-paste", "wl-paste --type image --watch cliphist store")
	run("gnome-keyring-daemon", "gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("$HOME/.minflair/hypr/scripts/polkit-agent.sh")
	hl.exec_cmd("$HOME/.minflair/hypr/scripts/wallpaper-restore.sh")
	hl.exec_cmd("qs")
end)
