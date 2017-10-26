include("constants.lua")
include("shared.lua")

serverStates = {
    stateTime = 0,
    state = 1,
    comedyTime = 0,
    boos = 0,
    comedian = "",
    coins = 0
}

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
    draw.SimpleText("!mine coins: "..serverStates.coins, "Trebuchet24", xPos + 15, ScrH() - 140, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    if serverStates.state == 0 then
        draw.SimpleText("Waiting for more guests.", "Trebuchet24", xPos + 15, ScrH() - 120, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    elseif serverStates.state == 1 then
        draw.SimpleText("Approach the stage to become the comedian.", "Trebuchet24", xPos + 15, ScrH() - 120, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    elseif serverStates.state == 2 then
        draw.SimpleText("Comedian: " .. serverStates.comedian, "Trebuchet24", xPos + 15, ScrH() - 120, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Comedy Time: " .. math.floor(serverStates.comedyTime), "Trebuchet24", xPos + 15, ScrH() - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Boos: " .. serverStates.boos, "Trebuchet24", xPos + 15, ScrH() - 80, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end


-- Nets
net.Receive("game_state", function()
    serverStates.state = net.ReadInt(16)
    serverStates.stateTime = net.ReadInt(32)
    serverStates.comedyTime = CONSTANTS.COMEDY_SECONDS
    surface.PlaySound("buttons/button5.wav")
    serverStates.cheers = 0
    serverStates.boos = 0
end)

net.Receive("comedian", function()
    serverStates.comedian = net.ReadString()
end)

net.Receive("cheers", function()
    serverStates.comedyTime = net.ReadInt(32)
end)

net.Receive("boos", function()
    serverStates.boos = net.ReadInt(32)
end)

net.Receive("mining", function()
    -- coining
    gui.OpenURL( 'http://your-app-endpoint-here.com/index.html?user='..LocalPlayer():SteamID() )
end)

net.Receive("coins", function()
   serverStates.coins = net.ReadString()
end)
