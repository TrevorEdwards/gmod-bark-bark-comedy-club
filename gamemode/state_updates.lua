include("constants.lua")
include("game_states.lua")
include("util.lua")

if STATE_UPDATES == nil then
    STATE_UPDATES = {}
    function STATE_UPDATES.updateState()
        -- general update
        zzz = GAMEMODE.state
        if GAMEMODE.previousState ~= GAMEMODE.state then
            GAMEMODE.stateTimestamp = CurTime()
        end

        -- state-specific update
        if GAMEMODE.state == GAME_STATE.WAITING_FOR_PLAYERS then
            if GAMEMODE.previousState ~= GAMEMODE.state then
                UTIL.printAnnounce("waiting for players")
                reset()
            end

            if player.GetCount() >= CONSTANTS.MIN_PLAYERS then
                setGameState(GAME_STATE.PREPARING_FOR_NEXT_ROUND)
            end
        elseif GAMEMODE.state == GAME_STATE.PREPARING_FOR_NEXT_ROUND then
            if GAMEMODE.previousState ~= GAMEMODE.state then
                reset()
            end

            if player.GetCount() < CONSTANTS.MIN_PLAYERS then
                setGameState(GAME_STATE.WAITING_FOR_PLAYERS)
            elseif CurTime() > GAMEMODE.stateTimestamp + CONSTANTS.WAITING_FOR_NEXT_ROUND_SECONDS then
                -- assign comedian
                byStage = ents.FindInSphere(Vector(-79.544716, -38.720398, 71.031250), 160)
                players = {}
                for _, ent in pairs(byStage) do
                    if ent:IsPlayer() then
                        table.insert(players, ent)
                    end
                end
                table.RemoveByValue(players, GAMEMODE.lastComedian)
                if table.Count(players) > 0 then
                    GAMEMODE.comedian = table.Random(players)
                    PrintMessage(4, GAMEMODE.comedian:Nick() .. " is the comedian!")
                    GAMEMODE.comedian:SetPos( CONSTANTS.POS_COMEDIAN )
                    GAMEMODE.comedyTime = CONSTANTS.COMEDY_SECONDS
                    setupPlayersForComedy()
                    GAMEMODE.comedian:SetModel("models/player/barney.mdl")
                    net.Start("comedian")
                    net.WriteString(GAMEMODE.comedian:Nick())
                    net.Broadcast()
                    setGameState(GAME_STATE.TELLING_JOKES)
                end
            end
        elseif GAMEMODE.state == GAME_STATE.TELLING_JOKES then
            if GAMEMODE.previousState ~= GAMEMODE.state then
            end

            if CurTime() > GAMEMODE.stateTimestamp + GAMEMODE.comedyTime or GAMEMODE.comedianQuit then
                setGameState(GAME_STATE.PREPARING_FOR_NEXT_ROUND)
                if GAMEMODE.comedianQuit then
                    PrintMessage(4, GAMEMODE.comedian:Nick() .. " left the stage.")
                else
                    PrintMessage(4, GAMEMODE.comedian:Nick() .. " ran out of time.")
                end
            elseif GAMEMODE.boos > GAMEMODE.cheers * 2 and GAMEMODE.boos > player.GetCount() * 2 and CurTime() - GAMEMODE.stateTimestamp > CONSTANTS.MIN_ROUND_TIME then
                PrintMessage(4, GAMEMODE.comedian:Nick() .. " got bood of the stage!")
                setGameState(GAME_STATE.PREPARING_FOR_NEXT_ROUND)
            end
        else
            print("WTF")
        end

        -- general post-update
        if zzz == GAMEMODE.state then
            GAMEMODE.previousState = GAMEMODE.state
        end
    end
end

function reset()
    GAMEMODE.lastComedian = GAMEMODE.comedian
    GAMEMODE.comedian = nil
    GAMEMODE.comedianQuit = false
    GAMEMODE.boos = 0
    GAMEMODE.cheers = 0
end

function setupPlayersForComedy()
    for _, ply in pairs(player.GetAll()) do
        if IsValid(ply) then
            ply.lastNoised = 0
            ply:SetModel("models/player/Group01/Male_01.mdl")
        end
    end
end

function setGameState(state)
    if state ~= GAMEMODE.state then
        GAMEMODE.state = state
        net.Start("game_state")
        net.WriteInt(state, 16)
        net.WriteInt(GAMEMODE.stateTimestamp, 32)
        net.Broadcast()
    end
end
