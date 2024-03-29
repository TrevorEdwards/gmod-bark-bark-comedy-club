AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("constants.lua")

include("game_states.lua")
include("shared.lua")
include("state_updates.lua")
include("util.lua")
include("sql_interface.lua")

-- nets
util.AddNetworkString("game_state")
util.AddNetworkString("cheers")
util.AddNetworkString("boos")
util.AddNetworkString("comedian")
util.AddNetworkString("mining")
util.AddNetworkString("coins")

-- GM FUNCTIONS
function GM:Initialize()
    self.BaseClass.Initialize(self)
    GAMEMODE.boos = 0
    GAMEMODE.cheers = 0
    GAMEMODE.comedian = nil
    GAMEMODE.comedianQuit = false
    GAMEMODE.stateTimestamp = nil
    GAMEMODE.previousState = -1
    GAMEMODE.state = GAME_STATE.WAITING_FOR_PLAYERS
    GAMEMODE.lastCoinQuery = 0
    MsgN("bbcc initializing...")
end

function GM:Tick()
    STATE_UPDATES.updateState()
    keepPlayersInCheck()
    updateCoins()
end

-- Cheers and boos activation
function GM:PlayerButtonDown(ply, button)
    if button == 107 then -- mouseleft
        if ply == GAMEMODE.comedian then
        else
            if playNoise(ply, table.Random(CONSTANTS.SOUND_CHEERS)) then
                incCheers()
            end
        end
    elseif button == 108 then -- mouseright
        if ply == GAMEMODE.comedian then
            -- quitting
            GAMEMODE.comedianQuit = true
        else
            if playNoise(ply, table.Random(CONSTANTS.SOUND_BOOS)) then
                incBoos()
            end
        end
    end
end

function GM:PlayerCanSeePlayersChat(text, teamOnly, listener, speaker)
    return canHear(listener, speaker)
end

-- Default model
function GM:PlayerSetModel(ply)
    ply:SetModel("models/player/Group01/Male_01.mdl")
end

-- Prevent player collision
function GM:ShouldCollide( ent1, ent2 )
    if ( IsValid( ent1 ) and IsValid( ent2 ) and ent1:IsPlayer() and ent2:IsPlayer() ) then return false end
    return true
end

-- Entrypoint for player mining
function GM:PlayerSay(sender, text, teamChat)
    if string.match(text, "!mine") then
        net.Start("mining")
        net.Send(sender)
    end
end

-- Hooks
hook.Add("PlayerCanHearPlayersVoice", "Game Logic", canHear)

local function spawn(ply)
    ply:GodEnable()
    GAMEMODE:SetPlayerSpeed(ply, 70, 70)
    ply:SetCustomCollisionCheck( true )
    ply:SetNoCollideWithTeammates( true )
    ply.lastNoised = 0
    SQL_INTERFACE.getPlayerCoins(ply)
end

hook.Add("PlayerInitialSpawn", "some_unique_name", spawn)

-- Helpers
-- CanHear: Can allow only comedian to talk for non-rowdy comedy
function canHear(listener, talker)
    return true
    --    if GAMEMODE.state ~= GAME_STATE.TELLING_JOKES then
    --        return true
    --    else
    --        return listener == GAMEMODE.comedian or talker == GAMEMODE.comedian
    --    end
end

-- Laughing/booing
function playNoise(ply, noise)
    local now = CurTime()
    if ply.lastNoised == nil then
        ply.lastNoised = -CONSTANTS.NOISE_DELAY_SECOND
    end
    if ply.lastNoised + CONSTANTS.NOISE_DELAY_SECOND < now then
        ply:EmitSound(noise)
        ply.lastNoised = now
        return true
    end
    return false
end

function incCheers()
    if GAMEMODE.state == GAME_STATE.TELLING_JOKES then
        GAMEMODE.cheers = GAMEMODE.cheers + 1
        GAMEMODE.comedyTime = GAMEMODE.comedyTime + CONSTANTS.COMEDY_SECONDS * (1.0 / (player.GetCount()-1)) * (CONSTANTS.COMEDY_SECONDS * 1.0/ CONSTANTS.NOISE_DELAY_SECOND)
        net.Start("cheers")
        net.WriteInt(GAMEMODE.comedyTime, 32)
        net.Broadcast()
    end
end

function incBoos()
    if GAMEMODE.state == GAME_STATE.TELLING_JOKES then
        GAMEMODE.boos = GAMEMODE.boos + 1
        net.Start("boos")
        net.WriteInt(GAMEMODE.boos, 32)
        net.Broadcast()
    end
end

function keepPlayersInCheck()
    local players = player.GetAll()
    for k, v in pairs(players) do
        if IsValid(v) and v ~= GAMEMODE.comedian then
            local ppos = v:GetPos()
            if ppos.y < CONSTANTS.COMEDIAN_BOX_Y then
                ppos.y = 0
                v:SetPos(ppos)
            end
        end
    end
end

-- Query coin db
function updateCoins()
    local nao = CurTime()
    if nao - GAMEMODE.lastCoinQuery > 60 then
        GAMEMODE.lastCoinQuery = nao
        UTIL.printAnnounce("Type !mine to mine coins! Values updated every minute.")
        local players = player.GetAll()
        for k, v in pairs(players) do
            if IsValid(v) then
                SQL_INTERFACE.getPlayerCoins(v)
            end
        end
    end
end
