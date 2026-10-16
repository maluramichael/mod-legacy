--[[
    GlobalTools_Legacy - Legacy system (mod-legacy) as a STANDALONE addon
    WoW 3.3.5a (AzerothCore with mod-legacy)

    Works two ways, with no configuration:
      * With the GlobalTools hub installed: it integrates on its own (a "Legacy
        System" tab, a dropdown-menu category and syncing via /gt sync).
      * Without the hub: it opens its own window with /glegacy.

    All player-facing text is in Locale.lua (loaded first); this file holds the
    logic only. The tree/node structure is in L.TREES; the matching text lives in
    L.T.trees keyed by the same ids.

    NOTE: the chat patterns in L:ProcessChat match the SERVER's responses, which
    are English, so they stay in English on purpose.
]]

local ADDON = "GlobalTools_Legacy"

GlobalToolsLegacy = GlobalToolsLegacy or {}
local L = GlobalToolsLegacy
local T = L.T  -- active translation table, built in Locale.lua

-- ============================================================================
-- LIVE DATA
-- ============================================================================
L.data = {
    points = 0,
    ranks = {
        [1] = { [1] = 0, [2] = 0, [3] = 0 }, -- Adventure
        [2] = { [1] = 0, [2] = 0, [3] = 0 }, -- Professions
        [3] = { [1] = 0, [2] = 0, [3] = 0 }, -- Resourcefulness
    },
    loaded = false,
}
if GlobalTools then GlobalTools.LegacyData = L.data end -- compatibility with older code

local ICON_MAIN = "Interface\\Icons\\Spell_Holy_ChampionsGrace"

-- ============================================================================
-- TREES AND NODES (structure only; text comes from L.T.trees)
-- Each node is bought with: .legacy buy <tree> <node>
-- ============================================================================
L.TREES = {
    {
        idx = 1, id = "tree_adventure",
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        nodes = {
            { id = "leg_adv_1", name = "Swift Boots",  icon = "Interface\\Icons\\Ability_Rogue_Sprint" },
            { id = "leg_adv_2", name = "Quick Study",  icon = "Interface\\Icons\\Spell_Holy_BorrowedTime" },
            { id = "leg_adv_3", name = "Wanderlust",   icon = "Interface\\Icons\\Ability_Spy" },
        },
    },
    {
        idx = 2, id = "tree_professions",
        icon = "Interface\\Icons\\Trade_BlackSmithing",
        nodes = {
            { id = "leg_prof_1", name = "Steady Hands",      icon = "Interface\\Icons\\INV_Pick_02" },
            { id = "leg_prof_2", name = "Master Crafter",    icon = "Interface\\Icons\\Trade_BlackSmithing" },
            { id = "leg_prof_3", name = "Bountiful Harvest", icon = "Interface\\Icons\\Spell_Nature_NatureBlessing", locked = true },
        },
    },
    {
        idx = 3, id = "tree_resources",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        nodes = {
            { id = "leg_res_1", name = "Grave Robber",   icon = "Interface\\Icons\\INV_Misc_Coin_01" },
            { id = "leg_res_2", name = "Haggler",        icon = "Interface\\Icons\\INV_Misc_Bag_07_Black" },
            { id = "leg_res_3", name = "Frugal Repairs", icon = "Interface\\Icons\\INV_Hammer_15" },
        },
    },
}

-- Localized text for a tree / node, by id
local function TreeT(tree) return T.trees[tree.id] end
local function NodeT(tree, node) return T.trees[tree.id].nodes[node.id] end

local function BuyCmd(tree, node) return ".legacy buy " .. tree.idx .. " " .. node end

-- ============================================================================
-- OWN SETTINGS (SavedVariables: GlobalToolsLegacyDB)
-- ============================================================================
local function DB()
    GlobalToolsLegacyDB = GlobalToolsLegacyDB or {}
    if GlobalToolsLegacyDB.hideChat == nil then GlobalToolsLegacyDB.hideChat = true end
    return GlobalToolsLegacyDB
end

-- Should the server's answers be hidden from chat? With the hub, use its option.
function L:ShouldHide()
    if GlobalToolsDB and GlobalToolsDB.hideChatMessages ~= nil then
        return GlobalToolsDB.hideChatMessages
    end
    return DB().hideChat
end

-- ============================================================================
-- COMMAND SENDING AND CONFIRMATIONS
-- ============================================================================
StaticPopupDialogs["GTLEGACY_CONFIRM"] = {
    text = "%s",
    button1 = T.CONFIRM_ACCEPT,
    button2 = T.CONFIRM_CANCEL,
    OnAccept = function(self, data)
        if data then L:Send(data) end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

function L:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Legacy]|r " .. tostring(msg))
end

function L:Send(cmd)
    if not cmd or cmd == "" then return end
    if UnitAffectingCombat("player") then
        UIErrorsFrame:AddMessage(T.COMBAT_WARN, 1.0, 0.2, 0.2, 1.0)
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
    SendChatMessage(cmd, "SAY")
end

function L:Run(cmd, confirm)
    if confirm then
        local dialog = StaticPopup_Show("GTLEGACY_CONFIRM", confirm)
        if dialog then dialog.data = cmd end
    else
        L:Send(cmd)
    end
end

-- Ask the server for points and ranks (the answer is read by ProcessChat)
function L:Sync()
    SendChatMessage(".legacy", "SAY")
end

-- After a buy or refund, re-sync once (the same message can arrive both via the
-- chat filter and via the event)
local lastTrigger = 0
local function TriggerSync()
    local now = GetTime()
    if now - lastTrigger < 0.5 then return end
    lastTrigger = now
    L:Sync()
end

-- ============================================================================
-- READING THE SERVER'S RESPONSES (English, see note at the top)
-- Returns true if the line is a Legacy line (so it can be hidden from chat)
-- ============================================================================
function L:ProcessChat(msg)
    if not msg then return false end
    local clean = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")

    -- 1. Refund: "[Legacy] 3 point(s) refunded to the account pool."
    --    (checked before "points available": both start the same and clashed)
    if clean:match("%[Legacy%]%s*(%d+)%s*point%(s%) refunded") then
        for t = 1, 3 do
            for n = 1, 3 do L.data.ranks[t][n] = 0 end
        end
        L:Update()
        TriggerSync()
        return false
    end

    -- 2. Successful buy: "[Legacy] Swift Boots raised to rank 2: +move speed."
    if clean:match("%[Legacy%]%s*(.-)%s*raised to rank%s*(%d+)") then
        TriggerSync()
        return false -- let the congratulation message show
    end

    -- 3. Points available: "[Legacy] 5 point(s) available"
    local pts = clean:match("%[Legacy%]%s*(%d+)%s*point")
    if pts then
        L.data.points = tonumber(pts)
        L.data.loaded = true
        L:Update()
        return true
    end

    -- 4. Node rank: "  1.1 Swift Boots - +move speed (rank 1/3, next rank costs 2)"
    local tree, node, rank = clean:match("^%s*(%d+)%.(%d+)%s+.-%(rank%s+(%d+)/")
    if tree and node and rank then
        tree, node, rank = tonumber(tree), tonumber(node), tonumber(rank)
        if L.data.ranks[tree] then L.data.ranks[tree][node] = rank end
        L.data.loaded = true
        L:Update()
        return true
    end

    -- Legacy headers and help (hidden when the silence option is on)
    if clean:find("^%-%- Adventure %-%-") or clean:find("^%-%- Professions %-%-")
        or clean:find("^%-%- Resourcefulness %-%-") or clean:find("Use '%.legacy buy") then
        return true
    end

    return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg, ...)
    if L:ProcessChat(msg) and L:ShouldHide() then
        return true
    end
    return false, msg, ...
end)

-- ============================================================================
-- INTERFACE: PANEL (used both for the hub tab and for the own window)
-- ============================================================================
local ui = {}  -- references to the texts refreshed live

local function CreateActionButton(parent, width, height, text, iconTexture, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetWidth(width or 130)
    btn:SetHeight(height or 28)
    btn:SetText(text or T.BTN_DEFAULT)
    if iconTexture then
        local icon = btn:CreateTexture(nil, "OVERLAY")
        icon:SetWidth(height - 8)
        icon:SetHeight(height - 8)
        icon:SetPoint("LEFT", btn, "LEFT", 5, 0)
        icon:SetTexture(iconTexture)
        local fs = btn:GetFontString()
        if fs then
            fs:ClearAllPoints()
            fs:SetPoint("LEFT", icon, "RIGHT", 4, 0)
            fs:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        end
    end
    if onClick then
        btn:SetScript("OnClick", function(self)
            PlaySound("igMainMenuOptionCheckBoxOn")
            onClick(self)
        end)
    end
    return btn
end

function L:BuildPanel(p)
    ui.nodeRows = {}

    local headerCard = CreateFrame("Frame", nil, p)
    headerCard:SetWidth(536)
    headerCard:SetHeight(48)
    headerCard:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -8)

    local cardBg = headerCard:CreateTexture(nil, "BACKGROUND")
    cardBg:SetAllPoints()
    cardBg:SetTexture(0.08, 0.22, 0.35, 0.6)

    local title = headerCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", headerCard, "TOPLEFT", 10, -8)
    title:SetText(T.PANEL_TITLE)

    ui.points = headerCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.points:SetPoint("BOTTOMLEFT", headerCard, "BOTTOMLEFT", 10, 8)
    ui.points:SetText(T.POINTS_LOADING)

    local syncBtn = CreateActionButton(headerCard, 140, 26, T.BTN_SYNC, ICON_MAIN, function() L:Sync() end)
    syncBtn:SetPoint("RIGHT", headerCard, "RIGHT", -8, 0)

    local y = -62
    for _, tree in ipairs(L.TREES) do
        local tt = TreeT(tree)
        local treeTitle = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        treeTitle:SetPoint("TOPLEFT", p, "TOPLEFT", 14, y)
        treeTitle:SetText(tt.tabTitle)
        y = y - 18

        for nodeIdx, n in ipairs(tree.nodes) do
            local nt = NodeT(tree, n)
            local row = CreateFrame("Frame", nil, p)
            row:SetWidth(536)
            row:SetHeight(32)
            row:SetPoint("TOPLEFT", p, "TOPLEFT", 12, y)

            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0.12, 0.12, 0.15, 0.35)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetWidth(24)
            icon:SetHeight(24)
            icon:SetPoint("LEFT", row, "LEFT", 6, 0)
            icon:SetTexture(n.icon)
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

            local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nameLabel:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            nameLabel:SetText(n.name .. " |cff808080(" .. nt.tabDesc .. ")|r")

            local badge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            badge:SetPoint("RIGHT", row, "RIGHT", -95, 0)
            badge:SetText(n.locked and T.BADGE_LOCKED or T.BADGE_RANK0)

            ui.nodeRows[tree.idx .. "_" .. nodeIdx] = { badge = badge, locked = n.locked }

            if not n.locked then
                local buyBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                buyBtn:SetWidth(85)
                buyBtn:SetHeight(22)
                buyBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
                buyBtn:SetText(T.BTN_BUY)
                local cmd, nodeName = BuyCmd(tree, nodeIdx), n.name
                buyBtn:SetScript("OnClick", function()
                    L:Run(cmd, string.format(T.CONFIRM_BUY_FMT, nodeName))
                end)
            end

            y = y - 34
        end
        y = y - 4
    end

    local resetBtn = CreateActionButton(p, 250, 26, T.BTN_RESET,
        "Interface\\Icons\\Spell_Shadow_SacrificialShield", function()
            L:Run(".legacy reset", T.CONFIRM_RESET)
        end)
    resetBtn:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 14, 10)

    L:Update()
end

-- Refresh the texts with the current data (no-op if the panel does not exist yet)
function L:Update()
    if ui.points then
        ui.points:SetText(string.format(T.POINTS_FMT, L.data.points or 0))
    end
    if not ui.nodeRows then return end
    for key, row in pairs(ui.nodeRows) do
        if row.badge and not row.locked then
            local t, n = key:match("(%d+)_(%d+)")
            local rank = (L.data.ranks[tonumber(t)] and L.data.ranks[tonumber(t)][tonumber(n)]) or 0
            if rank >= 3 then
                row.badge:SetText(T.BADGE_MAX)
            else
                row.badge:SetText(string.format(T.BADGE_RANK_FMT, rank, rank + 1))
            end
        end
    end
end

-- ============================================================================
-- HUB DROPDOWN MENU (generated from L.TREES)
-- ============================================================================
function L:BuildMenuCategory()
    local items = {
        {
            id = "legacy_status", name = T.MENU_STATUS_NAME,
            desc = T.MENU_STATUS_DESC,
            icon = ICON_MAIN, cmd = ".legacy", enabled = true,
        },
    }
    for _, tree in ipairs(L.TREES) do
        local tt = TreeT(tree)
        local subs = {}
        for nodeIdx, n in ipairs(tree.nodes) do
            local nt = NodeT(tree, n)
            if n.locked then
                subs[#subs + 1] = { id = n.id, name = nt.menuName, desc = nt.menuDesc, icon = n.icon,
                                    cmd = "", disabled = true, enabled = true }
            else
                subs[#subs + 1] = { id = n.id, name = nt.menuName, desc = nt.menuDesc, icon = n.icon,
                                    cmd = BuyCmd(tree, nodeIdx),
                                    confirm = string.format(T.CONFIRM_MENU_BUY_FMT, n.name), enabled = true }
            end
        end
        items[#items + 1] = { id = tree.id, name = tt.menuName, desc = tt.menuDesc, icon = tree.icon,
                              hasSubmenu = true, enabled = true, subitems = subs }
    end
    items[#items + 1] = {
        id = "legacy_reset", name = T.MENU_RESET_NAME,
        desc = T.MENU_RESET_DESC,
        icon = "Interface\\Icons\\Spell_Shadow_SacrificialShield", cmd = ".legacy reset",
        confirm = T.CONFIRM_MENU_RESET,
        enabled = true,
    }
    return {
        id = "legacy", name = T.MENU_ROOT_NAME, icon = ICON_MAIN,
        tooltip = T.MENU_ROOT_TOOLTIP,
        enabled = true, order = 3, items = items,
    }
end

-- ============================================================================
-- OWN WINDOW (/glegacy) - works with or without the hub
-- ============================================================================
function L:ToggleWindow()
    if not L.window then
        local f = CreateFrame("Frame", "GlobalToolsLegacyFrame", UIParent)
        f:SetWidth(580)
        f:SetHeight(520)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        f:SetFrameStrata("HIGH")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", f, "TOP", 0, -14)
        title:SetText(T.WINDOW_TITLE)

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

        local content = CreateFrame("Frame", nil, f)
        content:SetWidth(560)
        content:SetHeight(465)
        content:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -40)
        L:BuildPanel(content)

        tinsert(UISpecialFrames, "GlobalToolsLegacyFrame")
        L.window = f
        f:Hide()
    end

    if L.window:IsShown() then
        L.window:Hide()
    else
        L.window:Show()
        L:Sync()
    end
end

SLASH_GLOBALTOOLSLEGACY1 = "/glegacy"
SlashCmdList["GLOBALTOOLSLEGACY"] = function(msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""
    if msg == "sync" then
        L:Sync()
        L:Print(T.PRINT_SYNCING)
    elseif msg == "chat" then
        local db = DB()
        db.hideChat = not db.hideChat
        L:Print(string.format(T.PRINT_HIDECHAT_FMT, db.hideChat and T.PRINT_YES or T.PRINT_NO))
    elseif msg == "help" or msg == "?" then
        L:Print(T.PRINT_HELP)
    else
        L:ToggleWindow()
    end
end

-- ============================================================================
-- EVENTS (also reads chat via event: the filter only runs if the message shows)
-- ============================================================================
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("CHAT_MSG_SYSTEM")
ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        DB()
    elseif event == "CHAT_MSG_SYSTEM" then
        L:ProcessChat(arg1)
    end
end)

-- ============================================================================
-- HUB REGISTRATION (if installed)
-- ============================================================================
local GT = GlobalTools
if GT and GT.RegisterModule then
    GT:RegisterModule({
        id = "legacy",
        name = T.HUB_MODULE_NAME,
        icon = ICON_MAIN,
        slot = 3, -- tab position in the hub sidebar
        tab = {
            build = function(parent) L:BuildPanel(parent) end,
            onSelect = function() L:Sync() end,
            onUpdate = function() L:Update() end,
        },
        category = L:BuildMenuCategory(),
        sync = function() L:Sync() end,
        help = { T.HUB_HELP },
    })
end
