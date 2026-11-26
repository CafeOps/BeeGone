-- Bee Gone: every B typed into the chat box becomes a C (b -> c, B -> C).
-- Lines that start with "/" are left alone so slash commands and
-- whisper names still work. Links, colors and icons are left alone (see Swap.lua).

local _, ns = ...
local hooked = {}

local function SwapEditBox(editBox)
	local text = editBox:GetText()
	if text:sub(1, 1) == "/" or not text:find("[Bb]") then
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

-- As you type: the B turns into a C on screen.
local function OnTextChanged(editBox, userInput)
	if userInput and BeeGoneDB.enabled then
		SwapEditBox(editBox)
	end
end

-- Right before sending: Blizzard fires this for addons after it reads the
-- channel prefix and before it takes the text, so any B the typing hook
-- missed (a keystroke WoW didn't count as typed, a paste, a recalled line)
-- still goes out as a C.
local function OnPreSendText(_, editBox)
	if BeeGoneDB.enabled and editBox then
		SwapEditBox(editBox)
	end
end

local function Hook(editBox)
	if editBox and not hooked[editBox] then
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

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
	BeeGoneDB = BeeGoneDB or {}
	if BeeGoneDB.enabled == nil then
		BeeGoneDB.enabled = true
	end
	HookAll()
	-- Whisper pop-out windows create new edit boxes later.
	if FCF_OpenTemporaryWindow then
		hooksecurefunc("FCF_OpenTemporaryWindow", HookAll)
	end
	if EventRegistry then
		EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", OnPreSendText, ns)
	end
end)

SLASH_BEEGONE1 = "/beegone"
SlashCmdList.BEEGONE = function()
	BeeGoneDB.enabled = not BeeGoneDB.enabled
	print("|cff33ff99Bee Gone|r " .. (BeeGoneDB.enabled and "on" or "off"))
end
