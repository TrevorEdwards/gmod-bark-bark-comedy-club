include("shared.lua")

serverStates = {}

-- GMs
function GM:HUDShouldDraw(name)
    if (name == "CHudHealth" or name == "CHudAmmo" or name == "CHudWeapon" or name == "CHudBattery") then
        return false
    end
    return true
end

function GM:HUDPaint()
    Scrw, Scrh = ScrW(), ScrH()
    RelativeX, RelativeY = 0, Scrh
    xPos = 25
    yPos = ScrH() - 125
    --    draw.RoundedBox(5, xPos, yPos, 250, 100, bcol)

    if serverStates.state == 2 then
        draw.SimpleText("Cheers: " .. serverStates.cheers, "Trebuchet24", xPos + 15, ScrH() - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Boos: " .. serverStates.boos, "Trebuchet24", xPos + 15, ScrH() - 80, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        --        draw.SimpleText("Next game starts in: " .. nexttime, "TargetID", xPos + 15, ScrH() - 60, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        --        draw.SimpleText("Ready players: " .. readyplayers, "TargetID", xPos + 15, ScrH() - 40, Color(0, 255, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end

-- Nets
net.Receive("game_state", function()
    serverStates.state = net.ReadInt(16)
    surface.PlaySound("buttons/button5.wav")
    serverStates.cheers = 0
    serverStates.boos = 0
end)

net.Receive("cheers", function()
    serverStates.cheers = net.ReadInt(32)
end)

net.Receive("boos", function()
    serverStates.boos = net.ReadInt(32)
end)
