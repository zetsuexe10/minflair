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

-- cursor: Vimix if installed, otherwise Adwaita
local cursor = "Adwaita"
local found = false
for _, name in ipairs({ "Vimix-cursors", "Vimix-white-cursors" }) do
	for _, d in ipairs({ home .. "/.local/share/icons", home .. "/.icons", "/usr/share/icons" }) do
		if exists(d .. "/" .. name .. "/index.theme") then
			cursor = name
			found = true
			break
		end
	end
	if found then break end
end
hl.env("XCURSOR_SIZE", "16")
hl.env("HYPRCURSOR_SIZE", "16")
hl.env("XCURSOR_THEME", cursor)
hl.env("HYPRCURSOR_THEME", cursor)

-- cursor theme/size chosen in Shell Settings > App Appearance (kept in ~/.minflair/theme.json)
do
	local sf = io.open(home .. "/.minflair/theme.json", "r")
	if sf then
		local s = sf:read("a") or ""
		sf:close()
		local g = s:match('"gtk_theme"%s*:%s*"([^"]+)"')
		if g then
			hl.env("GTK_THEME", g)
		end
		local c = s:match('"cursor"%s*:%s*"([^"]+)"')
		local z = s:match('"cursor_size"%s*:%s*(%d+)')
		if c then
			hl.env("XCURSOR_THEME", c)
			hl.env("HYPRCURSOR_THEME", c)
		end
		if z then
			hl.env("XCURSOR_SIZE", z)
			hl.env("HYPRCURSOR_SIZE", z)
		end
	end
end
