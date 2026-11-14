-- SketchyBar auto-show: カーソルがスクリーン下端に触れたらバーを表示し、
-- そこから十分離れたら隠す。隠れている間はクリックが裏のウィンドウに通る。
--
-- 前提: Hammerspoon.app を起動済みで、システム設定 >
-- プライバシーとセキュリティ > アクセシビリティ で有効化されていること。

-- `hs` CLI から制御できるようにする (reload など)。
require("hs.ipc")

local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"

-- カーソル Y が「スクリーン下端からこの距離以内」で表示
local SHOW_WITHIN_PX = 2
-- カーソル Y が「スクリーン下端からこの距離を超える」で非表示
-- SHOW より十分大きくすることでヒステリシスを持たせ、ちらつきを防ぐ
local HIDE_BEYOND_PX = 60

local function setBarHidden(hidden)
    hs.execute(SKETCHYBAR .. " --bar hidden=" .. (hidden and "on" or "off"))
end

-- 起動直後はまず隠した状態にする
setBarHidden(true)

local barVisible = false

local mouseWatcher = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
    local pos = hs.mouse.absolutePosition()
    local screen = hs.mouse.getCurrentScreen() or hs.screen.mainScreen()
    local frame = screen:fullFrame()
    local distanceFromBottom = (frame.y + frame.h) - pos.y

    if not barVisible and distanceFromBottom <= SHOW_WITHIN_PX then
        setBarHidden(false)
        barVisible = true
    elseif barVisible and distanceFromBottom > HIDE_BEYOND_PX then
        setBarHidden(true)
        barVisible = false
    end

    return false
end)

mouseWatcher:start()

-- 設定リロード時のクリーンアップ
hs.shutdownCallback = function()
    if mouseWatcher then
        mouseWatcher:stop()
    end
    -- シャットダウン時はバーを常時表示に戻して閉じ忘れを防ぐ
    setBarHidden(false)
end

hs.alert.show("SketchyBar auto-hide enabled")
