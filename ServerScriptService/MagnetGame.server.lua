-- MagnetGame.server.lua  v4.6 (HIT cue: 2s before reel; unified SearchStatus states)
-- SearchStatus states:
--   "searching" = show "Searching for item..."
--   "hit"       = show big red "HIT!" + sound
--   "clear"     = hide searching/HIT UI (used for reel start/end, manual reel, tether break)

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local Terrain = Workspace.Terrain

-- ===== Remotes =====
local function ensureRE(n)
	local r = RS:FindFirstChild(n)
	if r and r:IsA("RemoteEvent") then return r end
	if r then r:Destroy() end
	r = Instance.new("RemoteEvent"); r.Name = n; r.Parent = RS
	return r
end
local function ensureRF(n)
	local r = RS:FindFirstChild(n)
	if r and r:IsA("RemoteFunction") then return r end
	if r then r:Destroy() end
	r = Instance.new("RemoteFunction"); r.Name = n; r.Parent = RS
	return r
end

local CastMagnet            = ensureRE("CastMagnet")
local RequestReelIn         = ensureRE("RequestReelIn")
local OpenReelRE            = ensureRE("OpenReel")
local ReelResultRE          = ensureRE("ReelResult")
local ReelEndedRE           = ensureRE("ReelEnded")
local CatchResult           = ensureRE("CatchResult")
local GameMessageRE         = ensureRE("GameMessage")
local OpenShopRE            = ensureRE("OpenShop")
local BuyUpgradeRE          = ensureRE("BuyUpgrade")
local SellAllResult         = ensureRE("SellAllResult")
local RequestBackpack       = ensureRE("RequestBackpack")
local BackpackData          = ensureRE("BackpackData")
local RemoveItemRE          = ensureRE("RemoveBackpackItem")
local SellAnywhereRE      = ensureRE("SellAnywhere")
local CheckSellAnywhereRF = ensureRF("CheckSellAnywhere")
local GetGamepassIdsRF    = ensureRF("GetGamepassIds")
local GetProductIdsRF    = ensureRF("GetProductIds")

local XPUpdateRE            = ensureRE("XPUpdate")
local RequestJournal        = ensureRE("RequestJournal")
local JournalData           = ensureRE("JournalData")
local JournalDiscover       = ensureRE("JournalDiscover")
local SetUILockState        = ensureRE("SetUILockState")
local RequestJournalDetails = ensureRF("RequestJournalDetails")
local SearchStatus          = ensureRE("SearchStatus")

-- ===== Config =====
local BACKPACK_CAPACITY = 25
local MAX_LEVEL = 100
local DATA_VERSION = 3
local MAX_TETHER_DIST = 70
local MAX_THROW_DIST  = 20
local H_SPEED         = 20
local GRAV            = Vector3.new(0, -Workspace.Gravity, 0)

-- ===== Loot / rarity =====
local Loot = {
	Common = {
		{name="Rusty Nail", base=3, minW=0.02, maxW=0.10, rollWeight=12},
		{name="Old Boot", base=4, minW=0.40, maxW=0.90, rollWeight=10},
		{name="Tin Can", base=4, minW=0.10, maxW=0.25, rollWeight=10},
		{name="Bent Spoon", base=3, minW=0.03, maxW=0.08, rollWeight=12},
		{name="Bottle Cap", base=2, minW=0.01, maxW=0.03, rollWeight=14},
		{name="Scrap Bolt", base=3, minW=0.03, maxW=0.12, rollWeight=11},
		{name="Wire Coil", base=5, minW=0.15, maxW=0.45, rollWeight=8},
		{name="Soda Tab Chain", base=3, minW=0.04, maxW=0.12, rollWeight=12},
		{name="Fishing Hook (Rusty)", base=3, minW=0.02, maxW=0.05, rollWeight=11},
		{name="Bike Chain Link", base=5, minW=0.08, maxW=0.20, rollWeight=9},
		{name="Steel Washer", base=3, minW=0.03, maxW=0.10, rollWeight=12},
		{name="Paperclip Bundle", base=2, minW=0.02, maxW=0.06, rollWeight=13},
		{name="Copper Penny Stack", base=6, minW=0.06, maxW=0.20, rollWeight=8},
		{name="Bottle Opener", base=4, minW=0.05, maxW=0.12, rollWeight=10},
		{name="Worn Fork", base=4, minW=0.06, maxW=0.12, rollWeight=10},
		{name="Small Padlock", base=6, minW=0.10, maxW=0.30, rollWeight=8},
		{name="Key Fragment", base=5, minW=0.02, maxW=0.05, rollWeight=10},
		{name="Metal Tag", base=4, minW=0.03, maxW=0.08, rollWeight=10},
		{name="Nuts & Screws Mix", base=6, minW=0.12, maxW=0.35, rollWeight=8},
		{name="Rust Flake Lump", base=2, minW=0.05, maxW=0.20, rollWeight=14},
		{name="Rusty Wrench", base=8, minW=0.27, maxW=0.34, rollWeight=12},
		{name="Bottle Cap Chain", base=5, minW=0.13, maxW=0.61, rollWeight=10},
		{name="Nail Cluster", base=5, minW=0.12, maxW=0.66, rollWeight=9},
		{name="Bent Key", base=6, minW=0.06, maxW=0.19, rollWeight=8},
		{name="Old Hinge", base=6, minW=0.24, maxW=0.83, rollWeight=12},
		{name="Wire Snip", base=7, minW=0.25, maxW=0.80, rollWeight=10},
		{name="Broken Spring", base=2, minW=0.22, maxW=0.76, rollWeight=13},
		{name="Metal Shard", base=4, minW=0.15, maxW=0.26, rollWeight=11},
		{name="Twisted Rebar", base=4, minW=0.19, maxW=0.74, rollWeight=12},
		{name="Small Bracket", base=5, minW=0.14, maxW=0.48, rollWeight=8},
		{name="Dented Spoon", base=8, minW=0.28, maxW=0.83, rollWeight=8},
		{name="Steel Nut", base=7, minW=0.26, maxW=0.70, rollWeight=14},
		{name="Bolt Pair", base=7, minW=0.20, maxW=0.59, rollWeight=14},
		{name="Fishing Swivel", base=8, minW=0.11, maxW=0.56, rollWeight=13},
		{name="Tackle Piece", base=8, minW=0.04, maxW=0.59, rollWeight=9},
		{name="Old Lure Body", base=3, minW=0.24, maxW=0.37, rollWeight=12},
		{name="Rusty Hook", base=5, minW=0.05, maxW=0.65, rollWeight=12},
		{name="Thin Chain", base=5, minW=0.05, maxW=0.40, rollWeight=13},
		{name="Large Washer", base=2, minW=0.17, maxW=0.67, rollWeight=12},
		{name="Mini Padlock", base=3, minW=0.29, maxW=0.67, rollWeight=12},
		{name="Badge Clip", base=4, minW=0.14, maxW=0.52, rollWeight=11},
		{name="Drawer Handle", base=4, minW=0.18, maxW=0.39, rollWeight=9},
		{name="Pipe Clamp", base=8, minW=0.07, maxW=0.46, rollWeight=13},
		{name="Door Stop Plate", base=4, minW=0.15, maxW=0.25, rollWeight=14},
		{name="Bike Spoke", base=3, minW=0.27, maxW=0.83, rollWeight=14},
		{name="Tent Stake", base=2, minW=0.27, maxW=0.83, rollWeight=12},
		{name="Wire Hanger Piece", base=7, minW=0.13, maxW=0.57, rollWeight=10},
		{name="Cabinet Knob", base=6, minW=0.25, maxW=0.77, rollWeight=13},
		{name="Horseshoe Nail", base=6, minW=0.25, maxW=0.53, rollWeight=10},
		{name="Picture Hanger", base=5, minW=0.16, maxW=0.56, rollWeight=13},
	},
	Rare = {
		{name="Silver Ring", base=50, minW=0.01, maxW=0.03, rollWeight=6},
		{name="Ancient Coin", base=55, minW=0.02, maxW=0.05, rollWeight=5},
		{name="Pocket Watch", base=60, minW=0.08, maxW=0.18, rollWeight=4},
		{name="Old Key Bundle", base=45, minW=0.10, maxW=0.25, rollWeight=6},
		{name="Small Lockbox", base=58, minW=0.30, maxW=0.80, rollWeight=4},
		{name="Brass Compass", base=52, minW=0.10, maxW=0.22, rollWeight=5},
		{name="Ornate Brooch", base=54, minW=0.02, maxW=0.06, rollWeight=5},
		{name="Vintage Lighter", base=48, minW=0.05, maxW=0.12, rollWeight=6},
		{name="Antique Gear", base=46, minW=0.20, maxW=0.60, rollWeight=6},
		{name="Collector’s Badge", base=50, minW=0.06, maxW=0.14, rollWeight=5},
		{name="Silver Locket", base=65, minW=0.21, maxW=0.83, rollWeight=4},
		{name="Old Car Emblem", base=55, minW=0.31, maxW=0.95, rollWeight=5},
		{name="Pocket Knife", base=47, minW=0.06, maxW=0.61, rollWeight=5},
		{name="Steel Flail Head", base=51, minW=0.41, maxW=1.04, rollWeight=4},
		{name="Decorative Hinge", base=43, minW=0.40, maxW=1.71, rollWeight=5},
		{name="Bronze Brooch", base=41, minW=0.42, maxW=1.44, rollWeight=4},
		{name="Railroad Spike (Stamped)", base=40, minW=0.11, maxW=0.56, rollWeight=4},
		{name="Antique Key", base=52, minW=0.09, maxW=1.37, rollWeight=4},
		{name="Service Medal", base=41, minW=0.32, maxW=0.77, rollWeight=5},
		{name="Compass Case", base=62, minW=0.11, maxW=0.58, rollWeight=4},
		{name="Steel Horseshoe", base=61, minW=0.06, maxW=0.81, rollWeight=4},
		{name="Brass Bell", base=48, minW=0.08, maxW=0.37, rollWeight=6},
		{name="Locked Padlock", base=51, minW=0.25, maxW=0.53, rollWeight=7},
		{name="Vintage Bottle Opener", base=41, minW=0.32, maxW=1.43, rollWeight=7},
		{name="Old Door Knocker", base=46, minW=0.17, maxW=1.55, rollWeight=7},
		{name="Stamped Dog Tag", base=58, minW=0.13, maxW=1.20, rollWeight=4},
		{name="Watch Bezel", base=65, minW=0.35, maxW=1.65, rollWeight=6},
		{name="Old Pistol Hammer", base=56, minW=0.16, maxW=1.14, rollWeight=7},
		{name="Ship Nail (Wrought)", base=61, minW=0.13, maxW=0.94, rollWeight=7},
		{name="Cannonball Fragment", base=58, minW=0.44, maxW=1.83, rollWeight=6},
		{name="Cast Iron Toy Wheel", base=52, minW=0.43, maxW=0.96, rollWeight=4},
		{name="Bike Hub", base=54, minW=0.38, maxW=1.02, rollWeight=4},
		{name="Brass Weight", base=57, minW=0.18, maxW=0.69, rollWeight=7},
		{name="Brass Door Plate", base=51, minW=0.32, maxW=1.40, rollWeight=5},
		{name="Steel Pulley", base=62, minW=0.19, maxW=1.36, rollWeight=4},
		{name="Copper Bracelet", base=40, minW=0.32, maxW=1.43, rollWeight=5},
		{name="Brass Buckle", base=47, minW=0.15, maxW=0.93, rollWeight=7},
		{name="Metal Flask", base=41, minW=0.23, maxW=1.34, rollWeight=7},
		{name="Flint Striker", base=64, minW=0.35, maxW=0.61, rollWeight=7},
		{name="Candlestick Base", base=42, minW=0.17, maxW=0.57, rollWeight=7},
	},
	Epic = {
		{name="Small Gold Bar", base=170, minW=0.10, maxW=0.35, rollWeight=3},
		{name="Golden Pocket Watch", base=160, minW=0.10, maxW=0.25, rollWeight=3},
		{name="Antique Telescope", base=150, minW=0.60, maxW=1.60, rollWeight=4},
		{name="Jeweled Crown Fragment", base=165, minW=0.15, maxW=0.40, rollWeight=3},
		{name="Royal Seal Plate", base=180, minW=0.40, maxW=1.20, rollWeight=2},
		{name="Ancient Relic Core", base=185, minW=0.30, maxW=0.90, rollWeight=2},
		{name="Treasure Coffer (Small)", base=195, minW=0.80, maxW=2.00, rollWeight=2},
		{name="Small Strongbox Plate", base=208, minW=0.81, maxW=2.44, rollWeight=2},
		{name="Ornate Door Plate", base=181, minW=0.59, maxW=2.35, rollWeight=2},
		{name="Collector Coin Roll", base=201, minW=1.04, maxW=3.00, rollWeight=3},
		{name="Brass Sextant Arm", base=162, minW=0.79, maxW=2.73, rollWeight=2},
		{name="Antique Pistol Frame", base=203, minW=0.95, maxW=2.93, rollWeight=3},
		{name="Old Anchor Fluke", base=210, minW=0.91, maxW=1.88, rollWeight=2},
		{name="Bronze Figurine", base=150, minW=0.95, maxW=1.45, rollWeight=4},
		{name="Steel Safe Dial", base=183, minW=0.85, maxW=1.64, rollWeight=4},
		{name="Treasure Coffer Plate", base=191, minW=0.48, maxW=1.43, rollWeight=4},
		{name="Ship’s Compass Bowl", base=161, minW=0.39, maxW=2.17, rollWeight=3},
		{name="Guild Sign Emblem", base=190, minW=0.37, maxW=1.28, rollWeight=3},
		{name="Royal Seal Medallion", base=201, minW=1.01, maxW=2.80, rollWeight=2},
		{name="Bronze Idol Fragment", base=191, minW=0.77, maxW=2.25, rollWeight=3},
	},
		
Legendary = {
	{name="Golden Anchor", base=800, minW=2.0, maxW=6.0, rollWeight=1},
	{name="Sunken Compass", base=1200, minW=0.40, maxW=1.60, rollWeight=1},
	{name="Cursed Crown", base=700, minW=0.6, maxW=1.4, rollWeight=1},
	{name="Royal Scepter", base=900, minW=0.8, maxW=1.8, rollWeight=1},
},
Mythic = {
	{name="Meteoric Iron Idol", base=5000, minW=3.0, maxW=8.0, rollWeight=1},
},
}
-- ===== Auto-descriptions ============================================
local function simpleDescription(name: string): string
	name = tostring(name or "")

	local lower = string.lower(name)
	local phrases = {}

	local function add(p) table.insert(phrases, p) end

	-- Base material/condition
	if lower:find("rust") or lower:find("rusty") then add("A metal item with a reddish-brown, flaky rust coating.") end
	if lower:find("gold") or lower:find("golden") then add("A bright metallic object with a warm golden sheen.") end
	if lower:find("silver") then add("A cool, silvery metallic object with a soft shine.") end
	if lower:find("bronze") then add("A dark golden-brown metal object with aged patina.") end
	if lower:find("iron") then add("A heavy iron piece with a dark, worn surface.") end
	if lower:find("steel") then add("A sturdy steel item with a dull, scratched finish.") end
	if lower:find("copper") or lower:find("penny") then add("A reddish metal item with spots of tarnish.") end

	-- Shape/type
	if lower:find("nail") then add("A small, thin fastener with a pointed tip and flat head.") end
	if lower:find("hook") then add("A curved piece of metal designed to catch or hold.") end
	if lower:find("ring") then add("A circular band of metal.") end
	if lower:find("coin") then add("A small, flat, round piece of metal used as currency.") end
	if lower:find("watch") then add("A compact timepiece with delicate internal parts.") end
	if lower:find("key") then add("A toothed metal key used to open locks.") end
	if lower:find("lock") then add("A sturdy locking mechanism made of metal.") end
	if lower:find("anchor") then add("A heavy, fluked anchor meant to hold fast underwater.") end
	if lower:find("crown") then add("An ornate headpiece decorated with metal and detail.") end
	if lower:find("scepter") then add("A ceremonial rod with decorative metalwork.") end
	if lower:find("compass") then add("A navigational tool with a magnetized needle in a case.") end
	if lower:find("chain") then add("Linked metal loops forming a flexible chain.") end
	if lower:find("washer") then add("A flat, circular disc with a hole in the center.") end
	if lower:find("spoon") or lower:find("fork") then add("A simple utensil with signs of wear.") end
	if lower:find("can") then add("A thin-walled metal container, dented from age.") end
	if lower:find("bolt") or lower:find("screw") then add("A threaded fastener with worn edges.") end
	if lower:find("tag") then add("A small metal tag stamped with faint markings.") end
	if lower:find("telescope") then add("A brass tube with lenses for viewing distant objects.") end
	if lower:find("crown") or lower:find("royal") then add("An ornate piece with decorative flourishes.") end
	if lower:find("idol") then add("A small sculpted figure with a mysterious aura.") end
	if lower:find("lockbox") or lower:find("box") then add("A compact metal box with a simple latch.") end
	if lower:find("plate") or lower:find("seal") then add("A flat piece of engraved metal.") end
	if lower:find("fragment") then add("A broken fragment from a larger item.") end
	if lower:find("bar") then add("A solid, rectangular bar of dense metal.") end
	if lower:find("cap") then add("A small metal cap with ridges.") end
	if lower:find("washer") then add("A thin metal washer with a central hole.") end
	if lower:find("opener") then add("A small hand tool for opening bottles.") end
	if lower:find("anchor") then add("A heavy anchor designed to bite into the ground.") end
	if lower:find("idol") then add("A sculpted figure with sharp edges and weight.") end

	-- Fallback if nothing matched
	if #phrases == 0 then
		return ("A simple %s made of metal, showing light wear."):format(name:lower())
	end
	return table.concat(phrases, " ")
end


local RARITY_ORDER = {Mythic=0, Legendary=1, Epic=2, Rare=3, Common=4}
local ITEM_RARITY = {} do for rar, list in pairs(Loot) do for _,it in ipairs(list) do ITEM_RARITY[it.name]=rar end end end
local rarityWeightBonus = {Common=0.25,Rare=0.20,Epic=0.15,Legendary=0.10,Mythic=0.05}

local function rarityOdds(luck)
	local c,r,e,l,m = 70,20,9,0.9,0.1 -- Mythic starts at 0.1%
	local rb,eb,lb,mb = 1.0*luck, 0.3*luck, 0.1*luck, 0.02*luck
	local tot = rb+eb+lb+mb
	c = math.max(0, c-tot); r = r+rb; e = e+eb; l = l+lb; m = m+mb
	return {Common=c,Rare=r,Epic=e,Legendary=l,Mythic=m}
end
local function pickRarity(plr)
	local odds = rarityOdds(plr:GetAttribute("Luck") or 0)
	-- Apply server-wide luck multiplier to higher rarities (renormalize to 100)
	local mult = 1.0
	if Boosts and Boosts.GetLuckMultiplierForPlayer then
		mult = Boosts.GetLuckMultiplierForPlayer(plr) or 1.0
	end
	if mult and mult > 1.0 then
		local rarList = {"Rare","Epic","Legendary","Mythic"}
		local sum = 0
		for k,v in pairs(odds) do sum += v end
		for _,r in ipairs(rarList) do odds[r] = (odds[r] or 0) * mult end
		-- renormalize to 100 total
		local newSum = 0
		for _,v in pairs(odds) do newSum += v end
		if newSum > 0 then
			for k,v in pairs(odds) do odds[k] = v * (100/newSum) end
		end
	end
	local roll = math.random()*100
	local acc = 0
	for _,rar in ipairs({"Common","Rare","Epic","Legendary","Mythic"}) do
		acc += odds[rar]
		if roll <= acc then return rar end
	end
	return "Common"
end
local function pickItem(rarity)
	local pool = Loot[rarity]; local tw=0
	for _,it in ipairs(pool) do tw += (it.rollWeight or 1) end
	local roll = math.random()*tw; local acc=0
	for _,it in ipairs(pool) do
		acc += (it.rollWeight or 1)
		if roll <= acc then return it end
	end
	return pool[#pool]
end
local function rollWeightAndValue(rarity, def)
	local minW,maxW=def.minW,def.maxW
	local w = math.random()*(maxW-minW)+minW
	local t = (w-minW)/math.max(1e-6,(maxW-minW))
	local k = rarityWeightBonus[rarity] or 0.2
	local value = math.floor(def.base*(1+k*t))
	local sway=0.95+math.random()*0.10
	value = math.max(1, math.floor(value*sway+0.5))
	return w, value
end
local function kgToLbRounded(kg) return math.floor(kg*2.20462*100+0.5)/100 end

-- ===== Runtime / inventory / XP =====
local liveData = {}
local runtime = {}
local function getRT(plr)
	runtime[plr.UserId] = runtime[plr.UserId] or {
		inv = {items={}},
		journalDiscovered = {},
		journalDetails = {},
		nextId = 1
	}
	return runtime[plr.UserId]
end
local function getInv(plr) return getRT(plr).inv end
local function rawCount(inv) return #inv.items end
local function addCatch(plr, name, rarity, kg, value)
	local rt=getRT(plr)
	if rawCount(rt.inv) >= BACKPACK_CAPACITY then
		GameMessageRE:FireClient(plr,"BACKPACK_FULL"); return false
	end
	local id=rt.nextId; rt.nextId+=1
	table.insert(rt.inv.items, {_id=id,name=name,rarity=rarity,kg=kg,lbRounded=kgToLbRounded(kg),value=value})
	return true
end
local function removeById(inv, id)
	for i,e in ipairs(inv.items) do if e._id==id then table.remove(inv.items,i) return true end end
	return false
end
local function viewItems(inv)
	local arr={}
	for _,e in ipairs(inv.items) do
		table.insert(arr,{id=e._id,name=e.name,lb=e.lbRounded or kgToLbRounded(e.kg),rarity=ITEM_RARITY[e.name] or e.rarity or "Common"})
	end
	table.sort(arr,function(a,b)
		local ar,br=(RARITY_ORDER[a.rarity] or 99),(RARITY_ORDER[b.rarity] or 99)
		if ar~=br then return ar<br end
		if a.name~=b.name then return a.name<b.name end
		return (a.lb or 0)>(b.lb or 0)
	end)
	return arr
end

local function xpToNext(level) return math.floor(100 + 15*level + 5*(level*level)) end
local function ensureLeaderstats(plr)
	local ls=plr:FindFirstChild("leaderstats") or Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=plr
	local c=ls:FindFirstChild("Coins") or Instance.new("IntValue"); c.Name="Coins"; c.Parent=ls
	local L=ls:FindFirstChild("Level") or Instance.new("IntValue"); L.Name="Level"; L.Parent=ls
	return c,L
end
local BASE_CATCH_XP, MAX_CATCH_XP = 8,150
local function sellXPFromValue(total) return math.clamp(math.floor(math.sqrt(math.max(0,total))),0,250) end
local function pushXP(plr, delta)
	local curXP=plr:GetAttribute("XP") or 0
	local curLv=plr:GetAttribute("Level") or 1
	XPUpdateRE:FireClient(plr,{delta=math.floor(delta or 0), level=curLv, xp=curXP, need=xpToNext(curLv)})
end
local function addXP(plr, amount)
amount = (XPAdjust and XPAdjust.Adjust and XPAdjust.Adjust(plr, amount)) or amount
	amount = math.max(0, math.floor(amount or 0))
	if amount==0 then pushXP(plr,0) return end
	local curXP=plr:GetAttribute("XP") or 0
	local curLv=plr:GetAttribute("Level") or 1
	curXP+=amount
	while curLv<MAX_LEVEL do
		local need=xpToNext(curLv)
		if curXP>=need then curXP-=need; curLv+=1 else break end
	end
	plr:SetAttribute("XP",curXP); plr:SetAttribute("Level",curLv)
	local _,L=ensureLeaderstats(plr); L.Value=curLv
	pushXP(plr,amount)
end

local function getCoins(plr) local ls=plr:FindFirstChild("leaderstats"); return ls and ls:FindFirstChild("Coins") end

-- Backpack push
local function sendBackpack(plr)
	local inv = getInv(plr)
	BackpackData:FireClient(plr, {items = viewItems(inv), capacity = BACKPACK_CAPACITY, count = rawCount(inv)})
end
local function sellAll(plr)
	local inv=getInv(plr); local pre=0
	for _,e in ipairs(inv.items) do pre += (e.value or 0) end
	local total=pre
	local strength=plr:GetAttribute("Strength") or 0
	if strength>0 then total=math.floor(total*(1+0.05*strength)+0.5) end
	inv.items={}
	local c=getCoins(plr); if c then c.Value=c.Value+total end
	SellAllResult:FireClient(plr,total)
	addXP(plr, sellXPFromValue(pre))
	sendBackpack(plr)
end
-- Sell Anywhere handler (gamepass-gated)
if SellAnywhereRE and SellAnywhereRE.OnServerEvent ~= nil then
	SellAnywhereRE.OnServerEvent:Connect(function(plr)
	if (GamepassService and GamepassService.HasSellAnywhere and GamepassService.HasSellAnywhere(plr.UserId)) then
			sellAll(plr)
		else
			local GM = ensureRE("GameMessage")
			GM:FireClient(plr, "Sell Anywhere requires the gamepass.")
		end
	end)
end


local function upgradeCost(which, level)
	if which=="Luck" then return 100+level*100
	elseif which=="Reel" then return 75+level*75
	elseif which=="Strength" then return 125+level*125 end
	return math.huge
end
BuyUpgradeRE.OnServerEvent:Connect(function(plr,which)
	if not ({Luck=true,Reel=true,Strength=true})[which] then return end
	local lvl=plr:GetAttribute(which) or 0
	if lvl>=10 then OpenShopRE:FireClient(plr,{error=which.." is already max."}); return end
	local c=getCoins(plr); if not c then return end
	local price=upgradeCost(which,lvl)
	if c.Value<price then OpenShopRE:FireClient(plr,{error="Not enough coins."}); return end
	c.Value-=price
	plr:SetAttribute(which,lvl+1)
	OpenShopRE:FireClient(plr,{ok=true, which=which, level=lvl+1, nextCost=(lvl+1)<10 and upgradeCost(which,lvl+1) or "MAX", coins=c.Value})
end)

-- ===== Water detect (voxel + rays) =====
local function terrainHasWaterAround(pos)
	local half = Vector3.new(3,3,3)
	local p0 = pos - half
	local p1 = pos + half
	local minV = Vector3.new(math.min(p0.X,p1.X), math.min(p0.Y,p1.Y), math.min(p0.Z,p1.Z))
	local maxV = Vector3.new(math.max(p0.X,p1.X), math.max(p0.Y,p1.Y), math.max(p0.Z,p1.Z))
	local region = Region3.new(minV, maxV):ExpandToGrid(4)
	local materials, occ = Terrain:ReadVoxels(region, 4)
	for x=1, materials.Size.X do
		for y=1, materials.Size.Y do
			for z=1, materials.Size.Z do
				if occ[x][y][z] > 0 and materials[x][y][z] == Enum.Material.Water then return true end
			end
		end
	end
	return false
end
local function fallbackRayWater(pos, plr)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.IgnoreWater = false
	if plr and plr.Character then params.FilterDescendantsInstances = { plr.Character } end
	local origin = pos + Vector3.new(0, 500, 0)
	local dir    = Vector3.new(0,-1000,0)
	local res = workspace:Raycast(origin, dir, params)
	if res and res.Material == Enum.Material.Water then return true end
	local offsets = {Vector3.new(0,0,0), Vector3.new(2,0,0), Vector3.new(-2,0,0), Vector3.new(0,0,2), Vector3.new(0,0,-2)}
	for _,off in ipairs(offsets) do
		local o = pos + off + Vector3.new(0, 250, 0)
		local r = workspace:Raycast(o, Vector3.new(0,-800,0), params)
		if r and r.Material == Enum.Material.Water then return true end
	end
	return false
end
local function partMarkedAsWater(hit)
	local cur=hit
	while cur do
		if cur:GetAttribute("IsWater")==true then return true end
		if CollectionService:HasTag(cur,"Water") then return true end
		if type(cur.Name)=="string" and cur.Name:lower():find("water") then return true end
		cur=cur.Parent
	end
	return false
end
local function isWaterAt(pos, plr, hitPart)
	if hitPart and partMarkedAsWater(hitPart) then return true end
	if terrainHasWaterAround(pos) then return true end
	return fallbackRayWater(pos, plr)
end

-- ===== Cast visuals / spawnCast =====
local CastFolder = workspace:FindFirstChild("MagnetCasts") or Instance.new("Folder"); CastFolder.Name="MagnetCasts"; CastFolder.Parent=workspace
local CastV2 = { byPlayer = {} }
local function cleanupCast(plr)
	local rec = CastV2.byPlayer[plr]
	if rec then
		if rec.tConn then rec.tConn:Disconnect() end
		if rec.rope then rec.rope:Destroy() end
		if rec.thrown then rec.thrown:Destroy() end
		if rec.handHandle and rec.origTrans ~= nil and rec.handHandle.Parent then
			rec.handHandle.Transparency = rec.origTrans
			local oc = rec.handHandle:FindFirstChild("OriginalColor"); if oc then oc:Destroy() end
		end
		CastV2.byPlayer[plr] = nil
	end
end
local function startTetherMonitor(plr)
	task.spawn(function()
		while true do
			task.wait(0.12)
			local rec = CastV2.byPlayer[plr]; if not rec or not rec.thrown or not rec.thrown.Parent then break end
			local char = plr.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then break end
			local d = (hrp.Position - rec.thrown.Position).Magnitude
			if d > MAX_TETHER_DIST then
				SearchStatus:FireClient(plr, "clear") -- do not play HIT on tether break
				if ReelEndedRE then ReelEndedRE:FireClient(plr) end
				plr:SetAttribute("CastingLock", nil)
				cleanupCast(plr)
				break
			end
		end
	end)
end
local function launchVelocity(startPos, targetPos, t)
	t = math.max(0.35,t)
	local disp=targetPos-startPos
	return (disp - 0.5*GRAV*(t*t))/t
end
local NoRollProps = PhysicalProperties.new(1.0, 1.0, 0.0)
local function spawnCast(plr, targetPos, flightTime)
	local char = plr.Character if not char then return nil end
	local tool = char:FindFirstChild("Magnet") or char:FindFirstChildOfClass("Tool") if not tool then return nil end
	local handHandle = tool:FindFirstChild("Handle") if not (handHandle and handHandle:IsA("BasePart")) then return nil end
	cleanupCast(plr)
	local attA = handHandle:FindFirstChild("MagnetAttach")
	if not attA then attA=Instance.new("Attachment"); attA.Name="MagnetAttach"; attA.Position=Vector3.new(0,-0.3,0); attA.Parent=handHandle end
	local thrown=handHandle:Clone(); thrown.Name="ThrownMagnet_"..plr.UserId; thrown.Anchored=false; thrown.CanCollide=true; thrown.Massless=false; thrown.CFrame=handHandle.CFrame
	for _,d in ipairs(thrown:GetDescendants()) do if d:IsA("Weld") or d:IsA("Motor6D") or d:IsA("WeldConstraint") then d:Destroy() end end
	thrown.CustomPhysicalProperties = NoRollProps; thrown.Parent = CastFolder
	local attB=Instance.new("Attachment"); attB.Name="ThrownAttach"; attB.Parent=thrown
	local rope=Instance.new("RopeConstraint"); rope.Attachment0=attA; rope.Attachment1=attB; rope.Thickness=0.03; rope.Visible=true; rope.Length=(handHandle.Position-targetPos).Magnitude; rope.Parent=handHandle
	local origTrans=handHandle.Transparency; handHandle.Transparency=1
	local oc=handHandle:FindFirstChild("OriginalColor") or Instance.new("Color3Value"); oc.Name="OriginalColor"; oc.Value=handHandle.Color; oc.Parent=handHandle
	local t=flightTime or 0.7 local v0=launchVelocity(handHandle.Position,targetPos,t) thrown.AssemblyLinearVelocity=v0
	task.delay(0.20,function() if rope and rope.Parent then rope.Length=1000 end end)
	local rec={thrown=thrown, rope=rope, handHandle=handHandle, origTrans=origTrans, landed=false}; CastV2.byPlayer[plr]=rec
	rec.tConn = thrown.Touched:Connect(function(hit)
		if rec.landed then return end
		if hit and plr.Character and hit:IsDescendantOf(plr.Character) then return end
		rec.landed=true
		thrown.AssemblyLinearVelocity=Vector3.zero; thrown.AssemblyAngularVelocity=Vector3.zero; thrown.Anchored=true
		local inWater = isWaterAt(thrown.Position, plr, hit)
		if inWater then
			-- Show "searching" while waiting for a bite
			SearchStatus:FireClient(plr, "searching")
			local waitSec=math.random(2,10)
			task.delay(waitSec,function()
				local rec2=CastV2.byPlayer[plr]; if not rec2 or rec2.thrown~=thrown then return end
				if isWaterAt(thrown.Position, plr, nil) then
					-- BITE: flash HIT now (sound plays client-side), open reel after 2 seconds
					SearchStatus:FireClient(plr, "hit")
					task.delay(2.0, function()
						local rec3=CastV2.byPlayer[plr]; if not rec3 or rec3.thrown~=thrown then return end
						if not isWaterAt(thrown.Position, plr, nil) then return end
						SearchStatus:FireClient(plr, "clear")
						local function rarityParams(rarity, reelLvl, strength)
							local fishBase, fishJitter, requiredFill, initialFillFrac, drainRate, movementMode, sineSpeed
							if rarity=="Common" then fishBase,fishJitter=0.28,0.04; requiredFill=2.0-0.08*reelLvl; initialFillFrac=0.35; drainRate=0.35; movementMode="sine"; sineSpeed=0.9
							elseif rarity=="Rare" then fishBase,fishJitter=0.45,0.10; requiredFill=2.4-0.07*reelLvl; initialFillFrac=0.22; drainRate=0.45; movementMode="hybrid"; sineSpeed=1.2
							elseif rarity=="Epic" then fishBase,fishJitter=0.63,0.18; requiredFill=2.9-0.06*reelLvl; initialFillFrac=0.12; drainRate=0.58; movementMode="target"; sineSpeed=1.0
							else fishBase,fishJitter=0.80,0.26; requiredFill=3.3-0.05*reelLvl; initialFillFrac=0.06; drainRate=0.70; movementMode="target"; sineSpeed=1.0 end
							requiredFill = math.max(1.6, requiredFill)
							return fishBase, fishJitter, requiredFill, initialFillFrac, drainRate, movementMode, sineSpeed
						end
						local rarity=pickRarity(plr)
						local strength=plr:GetAttribute("Strength") or 0
						local reelLvl=plr:GetAttribute("Reel") or 0
						local barRise=0.85+0.02*reelLvl
						local barFall=math.max(0.55,0.80-0.02*reelLvl)
						local barHeight=0.18+0.012*strength
						local fishBase,fishJitter,requiredFill,initialFillFrac,drainRate,movementMode,sineSpeed=rarityParams(rarity,reelLvl,strength)
						OpenReelRE:FireClient(plr,{rarity=rarity,barRise=barRise,barFall=barFall,barHeight=barHeight,fishBase=fishBase,fishJitter=fishJitter,requiredFill=requiredFill,initialFillFrac=initialFillFrac,drainRate=drainRate,movementMode=movementMode,sineSpeed=sineSpeed})
					end)
				else
					-- No bite: just clear (no HIT, no sound)
					SearchStatus:FireClient(plr, "clear")
				end
			end)
		end
	end)
	startTetherMonitor(plr)
	return thrown
end

-- ===== Gameplay =====
CastMagnet.OnServerEvent:Connect(function(plr, targetPos, power)
	if plr:GetAttribute("UILocked") or plr:GetAttribute("UILockedServer") then return end
	if typeof(targetPos)~="Vector3" then return end
	if (#getInv(plr).items) >= BACKPACK_CAPACITY then GameMessageRE:FireClient(plr,"BACKPACK_FULL"); return end
	if plr:GetAttribute("CastingLock") then return end
	plr:SetAttribute("CastingLock", true)
	local char=plr.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
	local origin=hrp and (hrp.Position+Vector3.new(0,2.5,0)) or targetPos
	local dir=(targetPos-origin); local dist=dir.Magnitude
	if dist>1e-3 and dist>MAX_THROW_DIST then dir=dir.Unit*MAX_THROW_DIST; targetPos=origin+dir end
	local horiz=Vector3.new(dir.X,0,dir.Z).Magnitude
	local t=math.clamp(horiz/H_SPEED,0.45,1.00)
	local thrown=spawnCast(plr,targetPos,t)
	if not thrown then plr:SetAttribute("CastingLock", nil) return end
end)

-- Server-side dedupe for CatchResult (per player)
local lastCatchSent = {}  -- [userId] = {t = os.clock(), name = "Rusty Nail"}

ReelResultRE.OnServerEvent:Connect(function(plr, result)
	plr:SetAttribute("CastingLock", nil)
	SearchStatus:FireClient(plr, "clear")

	if typeof(result)~="table" or result.success==nil or type(result.rarity)~="string" then
		ReelEndedRE:FireClient(plr); cleanupCast(plr); return
	end
	if result.success then
		local def=pickItem(result.rarity)
		local kg,value=rollWeightAndValue(result.rarity,def)
		if addCatch(plr, def.name, result.rarity, kg, value) then
			local rt=getRT(plr)
			rt.journalDiscovered[def.name] = true
			local det = rt.journalDetails[def.name] or {firstAt=0, maxLb=0, world="World One"}
			det.firstAt = det.firstAt ~= 0 and det.firstAt or os.time()
			det.world   = det.world or "World One"
			det.maxLb   = math.max(tonumber(det.maxLb or 0), kgToLbRounded(kg))
			rt.journalDetails[def.name] = det
			if not det._toasted then
				JournalDiscover:FireClient(plr,{name=def.name, rarity=result.rarity})
				det._toasted = true
			end

			local mult=(result.rarity=="Common" and 1.0) or (result.rarity=="Rare" and 2.0) or (result.rarity=="Epic" and 3.5) or 6.0
			addXP(plr, math.min(MAX_CATCH_XP, math.floor(BASE_CATCH_XP*mult)))

			local uid = plr.UserId
			local now = os.clock()
			local last = lastCatchSent[uid]
			if not (last and last.name==def.name and (now - last.t) <= 0.4) then
				CatchResult:FireClient(plr, def.name, result.rarity, kg)
				lastCatchSent[uid] = {t = now, name = def.name}
			end

			sendBackpack(plr)
		end
	end
	ReelEndedRE:FireClient(plr); cleanupCast(plr)
end)

RequestReelIn.OnServerEvent:Connect(function(plr)
	plr:SetAttribute("CastingLock", nil)
	SearchStatus:FireClient(plr, "clear")
	ReelEndedRE:FireClient(plr)
	cleanupCast(plr)
end)

-- ===== Crate / Booth =====
local function hookSellCrate(root)
	if not root or root.Name~="SellCrate" then return end
	local prompt=root:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt or prompt:GetAttribute("Hooked") then return end
	prompt:SetAttribute("Hooked", true)
	prompt.Triggered:Connect(function(player) sellAll(player) end)
end
local function hookUpgradeBooth(root)
	if not root or root.Name~="UpgradeBooth" then return end
	local prompt=root:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt or prompt:GetAttribute("Hooked") then return end
	prompt:SetAttribute("Hooked", true)
	if prompt.ActionText=="" then prompt.ActionText="Open Upgrades" end
	if prompt.ObjectText=="" then prompt.ObjectText="Booth" end
	prompt.MaxActivationDistance = math.max(12, prompt.MaxActivationDistance)
	prompt.HoldDuration=0; prompt.RequiresLineOfSight=false
	prompt.Triggered:Connect(function(plr)
		local ls=plr:FindFirstChild("leaderstats"); local c=ls and ls:FindFirstChild("Coins")
		local L=plr:GetAttribute("Luck") or 0
		local R=plr:GetAttribute("Reel") or 0
		local S=plr:GetAttribute("Strength") or 0
		OpenShopRE:FireClient(plr,{coins=c and c.Value or 0, Luck=L, Reel=R, Strength=S,
			costLuck=(L<10) and (100+L*100) or "MAX",
			costReel=(R<10) and (75+R*75) or "MAX",
			costStrength=(S<10) and (125+S*125) or "MAX",
			max=10})
	end)
end
for _,inst in ipairs(Workspace:GetDescendants()) do
	if inst.Name=="SellCrate" then hookSellCrate(inst) end
	if inst.Name=="UpgradeBooth" then hookUpgradeBooth(inst) end
end
Workspace.DescendantAdded:Connect(function(inst)
	if inst.Name=="SellCrate" then hookSellCrate(inst) end
	if inst.Name=="UpgradeBooth" then hookUpgradeBooth(inst) end
end)

-- ===== Journal / Data =====
local function mkOrder(r) return (r=="Mythic" and 0) or (r=="Legendary" and 1) or (r=="Epic" and 2) or (r=="Rare" and 3) or 4 end
local function buildCatalog()
	local cat = {}
	for rarity, list in pairs(Loot) do
		for _, it in ipairs(list) do
			table.insert(cat, {name = it.name, rarity = rarity})
		end
	end
	table.sort(cat, function(a, b)
		local ar, br = mkOrder(a.rarity), mkOrder(b.rarity)
		if ar ~= br then return ar < br end
		return a.name < b.name
	end)
	return cat
end
local CATALOG = buildCatalog()

RequestJournal.OnServerEvent:Connect(function(plr)
	local rt=getRT(plr)
	local payload={}
	for _,e in ipairs(CATALOG) do
		local found = rt.journalDiscovered[e.name] == true
		table.insert(payload,{name=e.name,rarity=e.rarity,found=found})
	end
	JournalData:FireClient(plr, payload)
end)

RequestJournalDetails.OnServerInvoke = function(plr,itemName)
	local rt=getRT(plr)
	local det = rt.journalDetails[itemName]
	if type(det)=="table" then
		return {found=true, firstAt=tonumber(det.firstAt) or 0, maxLb=tonumber(det.maxLb) or 0, world=det.world or "World One", desc=simpleDescription(itemName)}
	end
	return {found=false, world="World One", desc=simpleDescription(itemName)}
end

RequestBackpack.OnServerEvent:Connect(function(plr) sendBackpack(plr) end)

-- ===== Data store lifecycle =====
local storeV3 = DataStoreService:GetDataStore("PlayerData_v"..DATA_VERSION)
local storeV2 = DataStoreService:GetDataStore("PlayerData_v2")

local function migrateLegacyJournalToNewFields(d)
	local jd = {}
	local det = {}
	if type(d.journal)=="table" then
		for name, v in pairs(d.journal) do
			if v == true then
				jd[name] = true
				det[name] = det[name] or {firstAt=0, maxLb=0, world="World One"}
			elseif type(v)=="table" then
				if v.found == true then jd[name] = true end
				det[name] = {
					firstAt = tonumber(v.firstAt or 0) or 0,
					maxLb   = tonumber(v.maxLb or 0) or 0,
					world   = v.world or "World One"
				}
			end
		end
	end
	d.journalDiscovered = d.journalDiscovered or jd
	d.journalDetails    = d.journalDetails or det
end

local function defaultData()
	return {
		coins=0,
		attrs={Luck=0,Reel=0,Strength=0},
		items={},
		xp=0, level=1,
		journal={},
		journalDiscovered = {},
		journalDetails    = {}
	}
end

local function sanitizeLoaded(data)
	if type(data)~="table" then return defaultData() end
	data.coins = tonumber(data.coins) or 0
	data.attrs = data.attrs or {}; data.attrs.Luck=tonumber(data.attrs.Luck) or 0; data.attrs.Reel=tonumber(data.attrs.Reel) or 0; data.attrs.Strength=tonumber(data.attrs.Strength) or 0
	data.items = type(data.items)=="table" and data.items or {}
	data.xp = tonumber(data.xp) or 0; data.level = math.clamp(tonumber(data.level) or 1, 1, MAX_LEVEL)
	migrateLegacyJournalToNewFields(data)
	local cleaned = {}
	for _,e in ipairs(data.items) do
		if type(e)=="table" and type(e.name)=="string" and type(e.rarity)=="string" and tonumber(e.kg) and tonumber(e.value) then
			table.insert(cleaned, {name=e.name, rarity=e.rarity, kg=tonumber(e.kg), value=math.max(1, math.floor(e.value))})
		end
	end
	data.items = cleaned
	return data
end

local function tryLoad(store,key)
	local ok,res=pcall(function() return store:GetAsync(key) end)
	if ok then return res end
	warn("[Data] Load failed",key,res) return nil
end

local function loadPlayer(plr)
	local key="u_"..plr.UserId
	local data=tryLoad(storeV3,key)
	data=sanitizeLoaded(data or defaultData())
	local looksEmpty=(data.coins==0) and (#data.items==0) and (data.level==1) and (data.xp==0)
	if looksEmpty then
		local old=tryLoad(storeV2,key)
		if type(old)=="table" then
			local m=sanitizeLoaded(old)
			data.coins,data.attrs,data.items,data.xp,data.level =
				m.coins,m.attrs,m.items,m.xp,m.level
			data.journalDiscovered = m.journalDiscovered or {}
			data.journalDetails    = m.journalDetails or {}
			pcall(function() storeV3:SetAsync(key, data) end)
			print("[Data] Migrated v2→v3 for", plr.UserId)
		end
	end
	return data
end

local function savePlayer(plr,data)
	local key="u_"..plr.UserId
	for i=1,5 do
		local ok,err=pcall(function()
			storeV3:UpdateAsync(key,function() return data end)
		end)
		if ok then return true else warn("[Data] Save failed",i,plr.UserId,err) task.wait(1+math.random()) end
	end
	return false
end

local function snapshot(plr)
	local data = liveData[plr.UserId] or defaultData()
	local rt = getRT(plr)
	local ls=plr:FindFirstChild("leaderstats"); local c=ls and ls:FindFirstChild("Coins")
	data.coins = (c and c.Value) or 0
	data.attrs = {Luck=plr:GetAttribute("Luck") or 0, Reel=plr:GetAttribute("Reel") or 0, Strength=plr:GetAttribute("Strength") or 0}
	data.xp = plr:GetAttribute("XP") or 0; data.level = plr:GetAttribute("Level") or 1
	data.items = {}
	for _,e in ipairs(rt.inv.items) do table.insert(data.items,{name=e.name,rarity=e.rarity,kg=e.kg,value=e.value}) end
	data.journalDiscovered = rt.journalDiscovered or {}
	data.journalDetails    = rt.journalDetails or {}
	data.journal = data.journal or {}
	return data
end

Players.PlayerAdded:Connect(function(plr)
	local data = loadPlayer(plr); liveData[plr.UserId]=data
	local inv={items={}}; local nextId=1
	for _,e in ipairs(data.items) do
		table.insert(inv.items,{_id=nextId,name=e.name,rarity=e.rarity,kg=e.kg,lbRounded=kgToLbRounded(e.kg),value=e.value}); nextId+=1
	end
	runtime[plr.UserId]={
		inv=inv,
		journalDiscovered = data.journalDiscovered or {},
		journalDetails    = data.journalDetails or {},
		nextId=nextId
	}
	local Coins,LevelVal=ensureLeaderstats(plr); Coins.Value=data.coins or 0; LevelVal.Value=data.level or 1
	plr:SetAttribute("Luck", data.attrs.Luck or 0); plr:SetAttribute("Reel", data.attrs.Reel or 0); plr:SetAttribute("Strength", data.attrs.Strength or 0)
	plr:SetAttribute("XP", data.xp or 0); plr:SetAttribute("Level", data.level or 1)
	plr:SetAttribute("UILockedServer", false)
	pushXP(plr, 0)
end)

Players.PlayerRemoving:Connect(function(plr)
	savePlayer(plr, snapshot(plr))
	runtime[plr.UserId]=nil
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _,plr in ipairs(Players:GetPlayers()) do
			savePlayer(plr, snapshot(plr))
		end
	end
end)

game:BindToClose(function()
	for _,plr in ipairs(Players:GetPlayers()) do
		savePlayer(plr, snapshot(plr))
	end
end)

print("[MagnetGame] Server ready v4.6 (HIT cue + 2s pre-reel).")

if CheckSellAnywhereRF then
	CheckSellAnywhereRF.OnServerInvoke = function(plr)
	if Admins.IsAdmin(plr.UserId) then return true end
	if GamepassService and GamepassService.HasSellAnywhere then
		return GamepassService.HasSellAnywhere(plr.UserId) == true
	end
	return false
end
		return false
	end
end

if GetGamepassIdsRF then
	GetGamepassIdsRF.OnServerInvoke = function(plr)
		if GamepassService and GamepassService.PASS_IDS then
			return GamepassService.PASS_IDS()
		end
		return { SELL_ANYWHERE = 0, DOUBLE_XP = 0, SUPPORTER = 0 }
	end
end

if GetProductIdsRF then
	GetProductIdsRF.OnServerInvoke = function(plr)
		if GamepassService and GamepassService.PRODUCT_IDS then
			return GamepassService.PRODUCT_IDS()
		end
		return { SERVER_LUCK_2X_15MIN = 0 }
	end
end
