-- ClientHUD.local.lua (disabled)
-- Purpose: prevent duplicate "You just caught a ..." or journal toasts.
-- Catch/Journal lines are rendered elsewhere as text-only.

local gui = script.Parent  -- ScreenGui "MagnetHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- Clean up any leftover HUD toasts this script might have created in older sessions
for _, child in ipairs(gui:GetChildren()) do
	if child:IsA("TextLabel") or child:IsA("Frame") then
		local n = child.Name:lower()
		if n:find("toast") or n:find("catch") or n:find("journal") then
			child:Destroy()
		end
	end
end

-- No event connections here by design.
