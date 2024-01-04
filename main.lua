local _, ns = ...

local EventFrame = CreateFrame("Frame")

local Screenshotter = {}
Screenshotter.ADDON_NAME = "Screenshotter"
Screenshotter.VERSION = "@project-version@"
Screenshotter.COLOR = "245DC6FF"


---@class Event
---@field name string Event name as defiend in https://wowpedia.fandom.com/wiki/Category:API_events
---@field enabled boolean Whether or not the user has enabled this event
---@field checkboxText string Value displayed in AddOn options checkbox for togglign

---@alias friendlyEventName string Key use to define the event that Screenshotter can listen to. Unique.

---@class ScreenshotterDatabase
---@field screenshottableEvents { [friendlyEventName]: Event }

---@type ScreenshotterDatabase
local DB_DEFAULTS = {
  screenshottableEvents = {
    login = {
      name = "PLAYER_LOGIN",
      enabled = false,
      checkboxText = "On login"
    },
    channelChat = {
      name = "CHAT_MSG_CHANNEL",
      enabled = false,
      checkboxText = "On message in channel"
    },
    movementStart = {
      name = "PLAYER_STARTED_MOVING",
      enabled = false,
      checkboxText = "On start moving"
    },
    levelUp = {
      name = "PLAYER_LEVEL_UP",
      enabled = true,
      checkboxText = "On level up"
    },
    readyCheck = {
      name = "READY_CHECK",
      enabled = false,
      checkboxText = "On ready check"
    }
  }
}

--- Print formatted message to chat
---@param message string
---@return nil
local function printToChat(message)
  print(format("%s: %s", WrapTextInColorCode(Screenshotter.ADDON_NAME, Screenshotter.COLOR), message))
end

ns.PrintToChat = printToChat

--- Creates or gets the SavedVariable for this addon
---@param defaults any
---@return ScreenshotterDatabase
local function fetchOrCreateDatabase(defaults)
  local db = ScreenshotterDB or {}

  for k, v in pairs(defaults) do
    if db[k] == nil then
      db[k] = v
    end
  end

  -- Table keys may already exist so let's make sure we pick up any new events
  for k, v in pairs(defaults.screenshottableEvents) do
    if db.screenshottableEvents[k] == nil then
      db.screenshottableEvents[k] = v
    end
  end

  return db
end

local screenshotFrame = CreateFrame("Frame")
screenshotFrame:SetScript("OnEvent", function(_, event)
  printToChat(format("Got event %s, taking screenshot", event))

  Screenshot()
end)

function screenshotFrame:registerUnregisterEvent(event)
  if event.enabled then
    self:RegisterEvent(event.name)
    printToChat(format("Will screenshot for event %s", event.name))
  else
    self:UnregisterEvent(event.name)
  end
end

local function EventHandler(self, event, addOnName)
  if addOnName ~= Screenshotter.ADDON_NAME then
    return
  end

  if event ~= "ADDON_LOADED" then
    printToChat(format("Got unknown event %s", event))
    return
  end

  local db = fetchOrCreateDatabase(DB_DEFAULTS)

  ns.InitializeOptions(self, db, screenshotFrame, Screenshotter.ADDON_NAME, Screenshotter.VERSION)

  --- Persist DB as SavedVariable since we've been using it as a local
  ScreenshotterDB = db

  for _, e in pairs(db.screenshottableEvents) do
    screenshotFrame:registerUnregisterEvent(e)
  end

  self:UnregisterEvent(event)

  printToChat("v" .. Screenshotter.VERSION .. " loaded")
end

EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:SetScript("OnEvent", EventHandler)