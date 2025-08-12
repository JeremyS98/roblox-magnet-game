-- DayNight.server.lua
-- 10-minute full day cycle (600s), following the DevForum guide:
-- Advance MinutesAfterMidnight steadily and ease Lighting properties with sine/cosine.

local Lighting = game:GetService("Lighting")

local TICK_SECONDS = 1
local DAY_LENGTH_SECONDS = 600 -- 10 minutes
local TIME_SHIFT = 1440 / (DAY_LENGTH_SECONDS / TICK_SECONDS) -- minutes advanced per tick

-- Brightness ease (night low, day high)
local BRIGHT_MIN, BRIGHT_MAX = 1.7, 3.2
local AMP_B = (BRIGHT_MAX - BRIGHT_MIN) / 2
local OFF_B = BRIGHT_MIN + AMP_B

-- Shadow softness (crisper at noon/midnight, softer at sunrise/sunset)
local SHADOW_MIN, SHADOW_MAX = 0.6, 1.0
local AMP_S = (SHADOW_MAX - SHADOW_MIN) / 2
local OFF_S = SHADOW_MIN + AMP_S

-- Optional OutdoorAmbient (greyscale) sway — set USE_OUTDOOR = true if you want it
local USE_OUTDOOR = true
local OA_MIN, OA_MAX = 110, 160
local AMP_O = (OA_MAX - OA_MIN) / 2
local OFF_O = OA_MIN + AMP_O

local function skyTint(hours)
	-- Subtle color shift across the day; keep tiny to avoid over-coloring
	local t = math.cos((hours - 12) * math.pi/12)
	local warm = 0.02 * math.max(0, -t)   -- noon-ish
	local cool = 0.04 * math.max(0,  t)   -- night
	Lighting.ColorShift_Top    = Color3.fromRGB(255*(0.02+warm), 255*(0.02), 255*(0.02+cool))
	Lighting.ColorShift_Bottom = Color3.fromRGB(255*(0.01+warm), 255*(0.01), 255*(0.01+cool))
end

while true do
	-- advance clock
	local mam = Lighting:GetMinutesAfterMidnight() + TIME_SHIFT
	Lighting:SetMinutesAfterMidnight(mam)
	local h = (mam/60) % 24

	-- brightness curve (phase so darkest at midnight)
	Lighting.Brightness = AMP_B * math.cos(h * (math.pi/12) + math.pi) + OFF_B

	-- shadow softness (double frequency)
	Lighting.ShadowSoftness = AMP_S * math.cos(2 * h * (math.pi/12)) + OFF_S

	if USE_OUTDOOR then
		local v = AMP_O * math.cos(h * (math.pi/12) + math.pi) + OFF_O
		Lighting.OutdoorAmbient = Color3.fromRGB(v, v, v)
	end

	skyTint(h)
	task.wait(TICK_SECONDS)
end
