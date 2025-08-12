-- BackgroundMusic.local.lua
-- Loops through a set of chill tracks at low volume.

local SoundService = game:GetService("SoundService")

-- Create a folder to store music
local musicFolder = Instance.new("Folder")
musicFolder.Name = "BGMusic"
musicFolder.Parent = SoundService

-- Your song list (add/remove IDs as you like)
local songIDs = {
	95505239714472, -- Lo-fi loop
	99698348501904, -- Relaxed guitar
 -- Ambient pad
}

-- Settings
local volume = 0.01 -- Low volume
local fadeTime = 2 -- Seconds to fade between tracks

-- Function to fade in/out
local function fade(sound, targetVolume, duration)
	local steps = 20
	local stepTime = duration / steps
	local volStep = (targetVolume - sound.Volume) / steps
	for i = 1, steps do
		sound.Volume = sound.Volume + volStep
		task.wait(stepTime)
	end
end

-- Main loop
task.spawn(function()
	while true do
		local songID = songIDs[math.random(1, #songIDs)]
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. songID
		sound.Volume = 0
		sound.Looped = false
		sound.Parent = musicFolder
		sound:Play()

		fade(sound, volume, fadeTime) -- fade in
		sound.Ended:Wait()
		fade(sound, 0, fadeTime) -- fade out
		sound:Destroy()
	end
end)
