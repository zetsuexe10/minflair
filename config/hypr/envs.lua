local home = os.getenv("HOME")

local function exists(p)
	local f = io.open(p, "r")
	if f then
		f:close()
		return true
	end
	return false
end

-- Minflair keeps its GTK/Qt theme in ~/.minflair (see scripts/minflair-env.sh), so nothing in
-- ~/.config/gtk-*, qt*ct or gsettings is changed. Apps started from this session use it.
if os.execute then
	pcall(os.execute, '"' .. home .. '/.config/hypr/scripts/minflair-env.sh" >/dev/null 2>&1')
end

local dark = true
local f = io.open(home .. "/.minflair/theme.json", "r")
if f then
	local t = f:read("a") or ""
	f:close()
	if t:find('"is_dark"%s*:%s*false') then
		dark = false
	end
end

if exists(home .. "/.minflair/xdg/gtk-3.0/settings.ini") then
	hl.env("XDG_CONFIG_HOME", home .. "/.minflair/xdg")
end
hl.env("GTK_THEME", dark and "adw-gtk3-dark" or "adw-gtk3")
hl.env("ADW_DEBUG_COLOR_SCHEME", dark and "prefer-dark" or "prefer-light")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- cursor: use Bibata if installed, otherwise Adwaita
local cursor = "Adwaita"
for _, d in ipairs({ home .. "/.local/share/icons", home .. "/.icons", "/usr/share/icons" }) do
	if exists(d .. "/Bibata-Modern-Classic/index.theme") then
		cursor = "Bibata-Modern-Classic"
		break
	end
end
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", cursor)
hl.env("HYPRCURSOR_THEME", cursor)
