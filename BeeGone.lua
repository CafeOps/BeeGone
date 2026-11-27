-- Bee Gone: every B typed into the chat box becomes a C (b -> c, B -> C).
-- Lines that start with "/" are left alone so slash commands and
-- whisper names still work. Links, colors and icons are left alone (see Swap.lua).
-- In dungeons, raids, boss fights and PvP it stands down (see ChatLocked).

local _, ns = ...
local hooked = {}
local ready = false -- true once BeeGoneDB is set up at login
local toldLocked = false -- the "sitting this one out" note, once per session

-- Blizzard locks chat in dungeons, raids, boss fights, keystones and PvP
-- matches. In there, a line an addon changed with SetText is blocked from
-- sending (the player's message just vanishes), so Bee Gone leaves the text
-- alone while any of that is on. A B that gets through beats no message.
local RESTRICTIONS = { "Chat", "Encounter", "ChallengeMode", "PvPMatch", "Map" }

local function ChatLocked()
	if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
		return true
	end
	local types = Enum and Enum.AddOnRestrictionType
	local isActive = C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive
	if types and isActive then
		for _, name in ipairs(RESTRICTIONS) do
			if types[name] and isActive(types[name]) then
				return true
			end
		end
	end
	return false
end

local LOCKED_NOTE = "|cff33ff99Bee Gone|r is sitting this one out: Blizzard locks chat in dungeons, "
	.. "raids, boss fights and PvP, and a changed line would not send. Your B's go through until you leave."

local function SwapEditBox(editBox)
	if ChatLocked() then
		if not toldLocked then
			toldLocked = true
			print(LOCKED_NOTE)
		end
		return
	end
	local text = editBox:GetText()
	if type(text) ~= "string" or (issecretvalue and issecretvalue(text)) or not text:find("[Bb]") then
		return
	end
	-- A "/" line is a slash command, except in boxes that send it as plain
	-- text (the Guild & Communities window has no slash commands).
	if text:sub(1, 1) == "/" and editBox.supportsSlashCommands ~= false then
		return
	end
	local newText = ns.Swap(text)
	if newText == text then
		return -- only B's inside links: nothing to change
	end
	local cursor = editBox:GetCursorPosition()
	editBox:SetText(newText)
	editBox:SetCursorPosition(cursor) -- same length, so the cursor stays put
end

-- Any change to the text: typed, pasted, recalled from history or put there
-- by the game. Our own SetText comes back through here once and finds
-- nothing left to swap.
local function OnTextChanged(editBox)
	if BeeGoneDB.enabled then
		SwapEditBox(editBox)
	end
end

-- Right before sending: Blizzard fires this for addons after it reads the
-- channel prefix and before it takes the text, so any B still in a chat
-- window's box goes out as a C.
local function OnPreSendText(_, editBox)
	if BeeGoneDB.enabled and editBox then
		SwapEditBox(editBox)
	end
end

local function Hook(editBox)
	if type(editBox) == "table" and editBox.HookScript and not hooked[editBox] then
		editBox:HookScript("OnTextChanged", OnTextChanged)
		hooked[editBox] = true
	end
end

local function HookAll()
	for i = 1, (NUM_CHAT_WINDOWS or 10) do
		Hook(_G["ChatFrame" .. i .. "EditBox"])
	end
	-- Whisper pop-out windows are ChatFrame11 and up, past NUM_CHAT_WINDOWS.
	-- CHAT_FRAMES lists every chat frame, those included.
	for _, name in ipairs(CHAT_FRAMES or {}) do
		Hook(_G[name .. "EditBox"])
	end
end

-- The Guild & Communities window has its own chat box. It sends guild chat
-- straight to the server, without the chat window's send step, so the
-- pre-send catch never sees it. Swapping as the text changes covers it.
local function HookCommunities()
	if CommunitiesFrame then
		Hook(CommunitiesFrame.ChatEditBox)
	end
end

-- Any chat window box that gets focus, in case one was made some other way.
local function OnFocusGained(_, editBox)
	Hook(editBox)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" then
		-- The Guild & Communities window loads the first time it opens.
		if ready and name == "Blizzard_Communities" then
			HookCommunities()
		end
		return
	end
	BeeGoneDB = BeeGoneDB or {}
	if BeeGoneDB.enabled == nil then
		BeeGoneDB.enabled = true
	end
	ready = true
	HookAll()
	HookCommunities()
	-- Whisper pop-out windows create new edit boxes later.
	if FCF_OpenTemporaryWindow then
		hooksecurefunc("FCF_OpenTemporaryWindow", HookAll)
	end
	-- A box outside the chat windows (the Guild & Communities one) claims
	-- chat focus when clicked, before anything is typed in it.
	if ChatFrameUtil and ChatFrameUtil.SetChatFocusOverride then
		hooksecurefunc(ChatFrameUtil, "SetChatFocusOverride", Hook)
	end
	if EventRegistry then
		EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", OnPreSendText, ns)
		EventRegistry:RegisterCallback("ChatFrame.OnEditBoxFocusGained", OnFocusGained, ns)
	end
end)

SLASH_BEEGONE1 = "/beegone"
SlashCmdList.BEEGONE = function()
	BeeGoneDB.enabled = not BeeGoneDB.enabled
	local state = BeeGoneDB.enabled and "on" or "off"
	if BeeGoneDB.enabled and ChatLocked() then
		state = state .. " (sitting out until you leave: Blizzard locks chat in here)"
	end
	print("|cff33ff99Bee Gone|r " .. state)
end
