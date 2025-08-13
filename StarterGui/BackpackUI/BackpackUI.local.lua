-- BackpackUI.local.lua (updated: prompt Sell Anywhere if not owned)
-- Assumptions:
-- - This script lives under: StarterGui/BackpackUI/BackpackUI.local.lua
-- - The ScreenGui contains a main Frame with a Sell button named "SellButton"
-- - Existing inventory rendering remains unchanged; we only modify Sell behavior
-- - Remotes exist (created by server):
--      ReplicatedStorage.RequestBackpack            : RemoteEvent   (client -> server request)
--      ReplicatedStorage.BackpackData              : RemoteEvent   (server -> client payload)
--      ReplicatedStorage.RemoveBackpackItem        : RemoteEvent   (client -> server request)
--      ReplicatedStorage.SetUILockState            : RemoteEvent
--      ReplicatedStorage.SellAnywhere              : RemoteEvent   (client -> server request to sell if allowed)
--      ReplicatedStorage.CheckSellAnywhere         : RemoteFunction (client -> server ownership check)
--      ReplicatedStorage.GetGamepassIds            : RemoteFunction (client -> server returns PASS ids)
-- - This file ensures only ONE Sell button exists and wires the correct click behavior.

local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local MPS     = game:GetService("MarketplaceService")

local LOCAL   = Players.LocalPlayer

-- ===== Remotes =====
local RequestBackpack     = RS:WaitForChild("RequestBackpack")
local BackpackData        = RS:WaitForChild("BackpackData")
local RemoveItemRE        = RS:WaitForChild("RemoveBackpackItem")
local SetUILockState      = RS:WaitForChild("SetUILockState")
local SellAnywhereRE      = RS:WaitForChild("SellAnywhere")
local CheckSellAnywhereRF = RS:WaitForChild("CheckSellAnywhere")
local GetGamepassIdsRF    = RS:WaitForChild("GetGamepassIds")

-- ===== UI References =====
local gui = script.Parent
assert(gui and gui:IsA("ScreenGui"), "BackpackUI.local.lua must be parented to a ScreenGui")

-- Try to be robust to different frame names; prefer "Main" or first Frame child
local mainFrame = gui:FindFirstChild("Main") or gui:FindFirstChildWhichIsA("Frame")
assert(mainFrame, "BackpackUI: could not find main frame")

-- Find or create a single Sell button in the top-right area (left of any 'X' Close button)
local sellButton = mainFrame:FindFirstChild("SellButton")
if not sellButton then
    -- Create a clean TextButton if not present
    sellButton = Instance.new("TextButton")
    sellButton.Name = "SellButton"
    sellButton.Text = "Sell"
    sellButton.AutoButtonColor = true
    sellButton.Size = UDim2.new(0, 90, 0, 34)
    sellButton.AnchorPoint = Vector2.new(1, 0)
    sellButton.Position = UDim2.new(1, -60, 0, 12) -- left of an assumed Close 'X' in the corner
    sellButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- green
    sellButton.TextColor3 = Color3.new(1, 1, 1)
    sellButton.Font = Enum.Font.GothamBold
    sellButton.TextSize = 16
    sellButton.Parent = mainFrame
else
    -- Ensure only one visible instance (clean up duplicates by name under the same parent)
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name == "SellButton" and child ~= sellButton then
            child:Destroy()
        end
    end
    -- Nudge to a sensible position in case older layouts overlap
    sellButton.AnchorPoint = Vector2.new(1, 0)
    sellButton.Position = UDim2.new(1, -60, 0, 12)
    sellButton.Size = UDim2.new(0, 90, 0, 34)
    sellButton.Text = "Sell"
end

-- Debounce clicks
local clicking = false

local function promptSellAnywhereIfNeeded()
    -- 1) Ask server if this player owns the Sell Anywhere pass
    local owns = false
    local ok1, res1 = pcall(function()
        return CheckSellAnywhereRF:InvokeServer()
    end)
    if ok1 then owns = res1 == true end

    if owns then
        -- 2) Owner → request server to sell immediately
        SellAnywhereRE:FireServer()
        return
    end

    -- 3) Non-owner → get PASS ids and prompt to buy Sell Anywhere
    local passIds = nil
    local ok2, res2 = pcall(function()
        return GetGamepassIdsRF:InvokeServer()
    end)
    if ok2 and type(res2) == "table" then
        passIds = res2
    end

    local sellPassId = (passIds and passIds.SELL_ANYWHERE) or 0
    if type(sellPassId) == "number" and sellPassId > 0 then
        -- Prompt purchase on client
        pcall(function()
            MPS:PromptGamePassPurchase(LOCAL, sellPassId)
        end)
    else
        -- Fallback message via SetUILockState as a toast (optional)
        -- (If you have a GameMessage remote on client, you could fire it instead.)
        -- Leaving silent per your earlier request.
    end
end

-- Disconnect existing connections on this button to avoid duplicates (best effort)
-- We cannot forcibly disconnect unknown external connections, but we can replace the button with a clone to reset signals.
local function resetConnections(btn)
    local parent = btn.Parent
    local props = {
        Name = btn.Name,
        Text = btn.Text,
        Size = btn.Size,
        Position = btn.Position,
        AnchorPoint = btn.AnchorPoint,
        BackgroundColor3 = btn.BackgroundColor3,
        TextColor3 = btn.TextColor3,
        Font = btn.Font,
        TextSize = btn.TextSize,
        Visible = btn.Visible,
        ZIndex = btn.ZIndex,
        AutoButtonColor = btn.AutoButtonColor,
    }
    local newBtn = btn:Clone()
    newBtn.Parent = parent
    btn:Destroy()
    for k,v in pairs(props) do
        newBtn[k] = v
    end
    return newBtn
end

sellButton = resetConnections(sellButton)

sellButton.MouseButton1Click:Connect(function()
    if clicking then return end
    clicking = true
    task.defer(function()
        promptSellAnywhereIfNeeded()
        task.wait(0.25)
        clicking = false
    end)
end)

-- Keep existing inventory UI behavior intact
-- If your old script had more logic below (populate list, close button, hotkey, etc.),
-- keep it in this file underneath this block. This update only changes Sell behavior.
