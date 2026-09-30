# ArioUI

A modern, mobile-friendly Roblox UI library inspired by contemporary dark UI libraries.

## Features
- Animated window open/close
- Animated moving gradient title/accent
- Sidebar tabs with animated indicator
- Search/filter
- Sections and separators
- Buttons, toggles, sliders, dropdowns, textboxes
- Keybind control
- Color picker
- Tags/badges
- Notifications/toasts
- Dialogs/confirmations
- Config save/load/export/import hooks
- Theme system
- Settings panel
- Responsive/mobile-friendly layout
- Icons via text/emoji labels
- Clean Luau API
- Example showcase

## Quick start

```lua
local ArioUI = loadstring(game:HttpGet("YOUR_RAW_GITHUB_URL/src/ArioUI.lua"))()

local Window = ArioUI:CreateWindow({
    Title = "ArioUI",
    Subtitle = "Modern Interface",
    Theme = "Midnight",
    Acrylic = true,
    Animated = true
})

local Main = Window:AddTab("Main", "⌂")
local Settings = Window:AddTab("Settings", "⚙")

local Section = Main:AddSection("Features")

Section:AddButton({
    Name = "Hello",
    Description = "Test a button",
    Tag = "NEW",
    Callback = function()
        Window:Notify({
            Title = "Hello",
            Content = "ArioUI is working!",
            Duration = 3
        })
    end
})

Section:AddToggle({
    Name = "Example Toggle",
    Default = false,
    Callback = function(value)
        print(value)
    end
})
```

See `examples/Showcase.lua` for a larger example.
