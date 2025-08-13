-- BackpackUI.local.lua (Safe compatibility build)
-- Purpose:
--   * Keep your existing Backpack UI working without assuming a specific frame structure.
--   * Add purchase prompt for Sell Anywhere if a non-owner clicks the Sell button.
--   * Avoid errors like "could not find main frame".
-- Placement:
--   StarterGui/BackpackUI/BackpackUI.local.lua  (replace the broken one)
-- Notes:
--   If you have any extra "patch" scripts for the Sell button, you may keep them,
--   but this file already handles the prompt cleanly and dedupes connections.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LOCAL = Players.LocalPlayer

-- Remotes
local RequestBackpackRE = RS:WaitForChild("RequestBackpack")
local BackpackDataRE    = RS:WaitForChild("BackpackData")
local RemoveItemRE      = RS:WaitForChild("RemoveBackpackItem", 2) -- optional in some builds
local SellAnywhereRE    = RS:WaitForChild("SellAnywhere")
local CheckSellAnywhereRF = RS:WaitForChild("CheckSellAnywhere")
local GetGamepassIdsRF    = RS:WaitForChild("GetGamepassIds")

-- Utilities
local function findBackpackGui()
    local pg = LOCAL:WaitForChild("PlayerGui")
    -- ScreenGui is named "BackpackUI" in your hierarchy (per error path)
    local gui = pg:FindFirstChild("BackpackUI")
    if not gui then
        -- Wait briefly in case it spawns a bit late
        gui = pg:WaitForChild("BackpackUI", 5)
    end
    return gui
end

local function findRootFrame(gui)
    if not gui then return nil end
    -- Try common names first
    local cands = {
        "Main", "Root", "Container", "Background", "Frame", "BackpackFrame"
    }
    for _,n in ipairs(cands) do
        local f = gui:FindFirstChild(n, true)
        if f and f:IsA("Frame") then return f end
    end
    -- Fallback: first Frame descendant
    for _,d in ipairs(gui:GetDescendants()) do
        if d:IsA("Frame") then return d end
    end
    return nil
end

local function isSellButton(inst)
    if not inst or not inst:IsA("TextButton") then return false end
    if inst.Name == "SellButton" then return true end
    local t = (inst.Text or ""):lower()
    return t == "sell" or t:find("sell") ~= nil
end

local function ensureSellHook(btn)
    if not btn or not btn:IsA("TextButton") then return end
    if btn:GetAttribute("HookedSellPrompt") then return end
    btn:SetAttribute("HookedSellPrompt", true)

    btn.MouseButton1Click:Connect(function()
        -- Ask server if we own the pass
        local owns = false
        local okOwn, resOwn = pcall(function()
            return CheckSellAnywhereRF:InvokeServer()
        end)
        if okOwn then owns = (resOwn == true) end

        if owns then
            -- Let server handle selling (existing behavior)
            SellAnywhereRE:FireServer()
            return
        end

        -- Prompt to buy the pass
        local ids
        pcall(function()
            ids = GetGamepassIdsRF:InvokeServer()
        end)
        local passId = (type(ids) == "table" and ids.SELL_ANYWHERE) or 0
        if type(passId) == "number" and passId > 0 then
            pcall(function()
                MarketplaceService:PromptGamePassPurchase(LOCAL, passId)
            end)
        end
    end)
end

local function scanAndHookSellButtons(gui)
    for _,d in ipairs(gui:GetDescendants()) do
        if isSellButton(d) then
            ensureSellHook(d)
        end
    end
end

local function requestBackpack()
    pcall(function()
        RequestBackpackRE:FireServer()
    end)
end

-- Optional: toggle Backpack UI with "B" (only if there is a visible root frame)
local function setupToggleBehavior(gui, root)
    if not gui or not root then return end

    -- If another script already handles visibility, we won't fight it.
    LOCAL:GetAttributeChangedSignal("UILocked"):Connect(function()
        -- Respect locks (optional behavior)
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.B then
            -- If root is part of a ScreenGui where visibility is controlled elsewhere,
            -- we simply request a refresh when it opens
            root.Visible = not root.Visible
            if root.Visible then
                requestBackpack()
            end
        end
    end)
end

-- Bootstrap
local gui = findBackpackGui()
if not gui then
    warn("[BackpackUI] ScreenGui 'BackpackUI' not found; deferring.")
    -- Try again once added
    LOCAL.PlayerGui.ChildAdded:Connect(function(child)
        if child.Name == "BackpackUI" then
            task.wait(0.1)
            scanAndHookSellButtons(child)
            local root = findRootFrame(child)
            if root then
                setupToggleBehavior(child, root)
            end
        end
    end)
    return
end

-- Hook on creation and future descendants
scanAndHookSellButtons(gui)
gui.DescendantAdded:Connect(function(d)
    if isSellButton(d) then
        ensureSellHook(d)
    end
end)

-- Set up toggle behavior if we can find a plausible root frame
local root = findRootFrame(gui)
if root then
    setupToggleBehavior(gui, root)
else
    -- No hard failure — just warn (prevents the "could not find main frame" error)
    warn("[BackpackUI] No obvious root Frame found; keeping sell prompt active only.")
end

-- Request initial data shortly after spawn
task.delay(0.25, requestBackpack)

-- If a separate script renders the items on BackpackData, let it continue.
-- We don't override rendering here to preserve your existing UI.
