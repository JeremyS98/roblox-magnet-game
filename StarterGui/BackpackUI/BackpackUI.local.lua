-- BackpackUI.local.lua (Minimal Sell Prompt Hook, no root warnings)
-- Purpose:
--   Keep your existing Backpack UI intact. Only adds the Sell button behavior:
--     - Owners: sell immediately (server handles it)
--     - Non-owners: show Roblox purchase prompt for Sell Anywhere pass
-- Notes:
--   No assumptions about frame names; no visibility toggles; no warnings.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local LOCAL = Players.LocalPlayer

-- Remotes
local RequestBackpackRE   = RS:WaitForChild("RequestBackpack")
local SellAnywhereRE      = RS:WaitForChild("SellAnywhere")
local CheckSellAnywhereRF = RS:WaitForChild("CheckSellAnywhere")
local GetGamepassIdsRF    = RS:WaitForChild("GetGamepassIds")

-- Find the BackpackUI ScreenGui (wait up to 5s)
local function getBackpackGui()
    local pg = LOCAL:WaitForChild("PlayerGui")
    local gui = pg:FindFirstChild("BackpackUI")
    if not gui then
        gui = pg:WaitForChild("BackpackUI", 5)
    end
    return gui
end

local function isSellButton(inst)
    if not inst or not inst:IsA("TextButton") then return false end
    if inst.Name == "SellButton" then return true end
    local t = (inst.Text or ""):lower()
    return t == "sell" or t:find("sell") ~= nil
end

local function attachSell(btn)
    if not btn or not btn:IsA("TextButton") then return end
    if btn:GetAttribute("SellHooked") then return end
    btn:SetAttribute("SellHooked", true)

    btn.MouseButton1Click:Connect(function()
        -- Check ownership with the server
        local owns = false
        local okOwn, resOwn = pcall(function()
            return CheckSellAnywhereRF:InvokeServer()
        end)
        if okOwn then owns = (resOwn == true) end

        if owns then
            -- Owner: trigger server sell
            SellAnywhereRE:FireServer()
            return
        end

        -- Non-owner: prompt purchase
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

-- Bootstrap
local gui = getBackpackGui()
if gui then
    -- Hook any existing Sell buttons
    for _,d in ipairs(gui:GetDescendants()) do
        if isSellButton(d) then
            attachSell(d)
        end
    end
    -- Hook future buttons when UI rebuilds
    gui.DescendantAdded:Connect(function(d)
        if isSellButton(d) then
            attachSell(d)
        end
    end)

    -- Optional: small initial refresh
    task.delay(0.25, function()
        pcall(function() RequestBackpackRE:FireServer() end)
    end)
end
