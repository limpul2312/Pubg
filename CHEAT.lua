-- ==============================================================================
--  🟢  DEBUG FILE LOAD
-- ==============================================================================
print("[YAHIKO] FILE LOADED")

-- ==============================================================================
--  ⚙️  CONFIG
-- ==============================================================================
local CONFIG = {
  TITLE         = "@YAHIKO_CH PAKS INFORMASI",
  MESSAGE       = "PAKS DITUTUP\nPAKS WILL BE CLOSED\n",

  TELEGRAM_USER = "\nBUY VIP:\nTG: @YAHIKO_OWN\nWA: 085138703742",
  TELEGRAM_URL  = "https://t.me/YAHIKO_OWN",
  WHATSAPP_URL  = "https://wa.me/6285138703742",

  SPAM_INTERVAL = 5.0,

  SHOW_LOG     = true,   -- print ke console
  SHOW_SCREEN  = true,   -- teks di layar
  SHOW_NOTIFY  = true,   -- LexusNotify
  SHOW_POPUP   = true,   -- popup box

  BTN_OK    = "TELEGRAM",
  BTN_CLOSE = "WHATSAPP",

  COLOR = { R = 1, G = 0.15, B = 0.15, A = 1 },
  SCALE = 1.3,
}

-- ==============================================================================
--  🔒  LOGIKA SPAM EXPIRED (versi debug + fallback)
-- ==============================================================================
local ExpiredLock = {}
local _started = false

local function log(...)
  print("[YAHIKO]", ...)
end

-- Cari MsgBox di beberapa kemungkinan path
local function getMsgBox()
  local paths = {
    "client.slua.logic.common.logic_common_msg_box",
    "client.slua.logic.common.logic_msg_box",
    "client.slua.logic.common.msg_box",
  }
  for _, p in ipairs(paths) do
    local ok, mod = pcall(require, p)
    if ok and mod and mod.Show then
      log("MsgBox ditemukan di:", p)
      return mod
    end
  end
  log("ERROR: MsgBox TIDAK ditemukan di semua path!")
  return nil
end

-- Buka URL via WebView SDK (multi-path + multi-signature)
local function openURL(url)
  local paths = {
    "client.slua.logic.url.logic_webview_sdk",
    "client.slua.logic.url.logic_webview",
  }
  for _, p in ipairs(paths) do
    local ok, mod = pcall(require, p)
    if ok and mod and mod.OpenURL then
      pcall(function() mod:OpenURL(url) end)
      pcall(function() mod.OpenURL(url) end)
      log("OpenURL sukses via:", p)
      return
    end
  end
  log("ERROR: WebView SDK tidak ditemukan")
end

function ExpiredLock.Spam()
  log("Spam() dipanggil")

  -- 1) Console log
  if CONFIG.SHOW_LOG then
    log(CONFIG.MESSAGE)
  end

  -- 2) Teks di layar
  if CONFIG.SHOW_SCREEN then
    local ok, err = pcall(function()
      local sh = import("ScriptHelperClient")
      if sh and sh.AddOnScreenDebugMessage then
        sh.AddOnScreenDebugMessage(
          CONFIG.MESSAGE, -1, 4.5,
          CONFIG.COLOR,
          { X = CONFIG.SCALE, Y = CONFIG.SCALE }
        )
      else
        log("ScriptHelperClient tidak punya AddOnScreenDebugMessage")
      end
    end)
    if not ok then log("ScreenError:", err) end
  end

  -- 3) Notifikasi Lexus
  if CONFIG.SHOW_NOTIFY then
    local ok, err = pcall(function()
      if _G.LexusNotify then
        _G.LexusNotify(CONFIG.MESSAGE)
      else
        log("LexusNotify belum ada")
      end
    end)
    if not ok then log("NotifyError:", err) end
  end

  -- 4) Popup box + 2 tombol
  if CONFIG.SHOW_POPUP then
    local Msg = getMsgBox()
    if not Msg then return end

    -- Coba signature A (callback dulu, baru text)
    local okA, errA = pcall(function()
      Msg.Show(
        2,
        CONFIG.TITLE,
        CONFIG.MESSAGE .. CONFIG.TELEGRAM_USER,
        function() openURL(CONFIG.TELEGRAM_URL) end,
        function() openURL(CONFIG.WHATSAPP_URL) end,
        CONFIG.BTN_OK,
        CONFIG.BTN_CLOSE
      )
    end)
    log("Popup A ok?", okA, errA or "")

    if not okA then
      -- Fallback signature B (text dulu, baru callback)
      local okB, errB = pcall(function()
        Msg.Show(
          2,
          CONFIG.TITLE,
          CONFIG.MESSAGE .. CONFIG.TELEGRAM_USER,
          CONFIG.BTN_OK,
          CONFIG.BTN_CLOSE,
          function() openURL(CONFIG.TELEGRAM_URL) end,
          function() openURL(CONFIG.WHATSAPP_URL) end
        )
      end)
      log("Popup B ok?", okB, errB or "")
    end
  end
end

function ExpiredLock.Start()
  if _started then
    log("ExpiredLock sudah berjalan, skip")
    return
  end
  _started = true
  log("ExpiredLock.Start dipanggil")

  -- Panggil sekali langsung
  ExpiredLock.Spam()

  -- Setup timer loop
  local ok, ticker = pcall(require, "common.time_ticker")
  if ok and ticker and ticker.AddTimerLoop then
    log("Pakai time_ticker, interval =", CONFIG.SPAM_INTERVAL)
    ticker.AddTimerLoop(CONFIG.SPAM_INTERVAL, function()
      ExpiredLock.Spam()
    end, -1, CONFIG.SPAM_INTERVAL)
  else
    log("time_ticker tidak ada, coba fallback timer")
    if _G.setInterval then
      _G.setInterval(function() ExpiredLock.Spam() end, CONFIG.SPAM_INTERVAL * 1000)
      log("Pakai _G.setInterval")
    elseif _G.LexusTimer and _G.LexusTimer.CreateTimer then
      _G.LexusTimer.CreateTimer(function() ExpiredLock.Spam() end, CONFIG.SPAM_INTERVAL, true)
      log("Pakai LexusTimer")
    else
      log("TIDAK ADA TIMER SAMA SEKALI — hanya spam sekali")
    end
  end
end

-- ==============================================================================
--  🎮  BRPlayerCharacterBase (class asli game — jangan diubah)
-- ==============================================================================
local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}

BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Object }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Int }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Int }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = { UEnums.EPropertyClass.Bool }
}

local GameplayData = require("GameLua.GameCore.Data.GameplayData")

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  if Client then
    pcall(function()
      GameplayData.AddCharacter(self.Object)
    end)

    -- 🔒 Jalankan spam expired lock saat masuk game
    pcall(function()
      ExpiredLock.Start()
    end)
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then
    pcall(function()
      GameplayData.RemoveCharacter(self.Object)
    end)
  end
end

-- ==============================================================================
--  📦  CLASS REGISTER (fitur mod tetap dimatikan / tidak diaktifkan)
-- ==============================================================================
local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)
local finalClass = require("combine_class").DeclareFeature(CBRPlayerCharacterBase, {
  { SkyTransition = "GameLua.Mod.BaseMod.Gameplay.Feature.SkyControl.PlayerCharacterSkyTransitionFeature" },
  { CarryDeadBoxFeature = "GameLua.Mod.Library.GamePlay.Feature.CarryDeadBoxFeature" },
  { SpecialSuitFeature = "GameLua.Mod.Library.GamePlay.Feature.SpecialSuitFeature" },
  { TeleportPawnFeature = "GameLua.Mod.Library.GamePlay.Feature.TeleportPawnFeature" },
  { LifterControl = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.CharacterLifterControlFeature" },
  { FinalKillEffect = "GameLua.Mod.BaseMod.Gameplay.Feature.Player.PlayerCharacterFinalKillEffectFeature" },
  { CampFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.Camp.PlayerCharacterCampFeature" },
  { BuildAircraftVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerCharacterBuildVehicleFeature" },
  { UnifiedBuildVehicleFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.UnifiedBuildVehicleFeature" },
  { CommonBornlandTransformFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.HeroPropFeature.CommonBornlandTransformFeature" },
  { ParachuteFormation = "GameLua.Mod.BaseMod.GamePlay.Feature.ParachuteFormationFeature" },
  { ParachuteSprint = "GameLua.Mod.BaseMod.GamePlay.Feature.Parachute.ParachuteSprintFeature" },
  { GeneralShowSpotFeature = "GameLua.Mod.BRMod.Gameplay.Feature.PlayerCharacterGeneralShowSpotFeature" },
  { FPPAnimMonitor = "GameLua.Mod.BaseMod.GamePlay.Feature.Player.FPPAnimMonitorFeature" },
  { FishingFeature = "GameLua.Mod.Library.GamePlay.Actor.Fishing.FishingFeature" },
  { PlayerThemeItemsFeature = "GameLua.Mod.BaseMod.GamePlay.Feature.PlayerThemeItemsFeature" }
}, "BRPlayerCharacterBase")

_G.X3_ActivePlayerClass = finalClass
return finalClass