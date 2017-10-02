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
                UTIL.printAnnounce("Starting next round in " .. CONSTANTS.WAITING_FOR_NEXT_ROUND_SECONDS .. " seconds.")
                reset()
            end

            if player.GetCount() < CONSTANTS.MIN_PLAYERS then
                setGameState(GAME_STATE.WAITING_FOR_PLAYERS)
            elseif CurTime() > GAMEMODE.stateTimestamp + CONSTANTS.WAITING_FOR_NEXT_ROUND_SECONDS then
                setGameState(GAME_STATE.TELLING_JOKES)
            end
        elseif GAMEMODE.state == GAME_STATE.TELLING_JOKES then
            if GAMEMODE.previousState ~= GAMEMODE.state then
                UTIL.printAnnounce("telling jokes")
                -- assign comedian
                GAMEMODE.comedian = table.Random(player.GetAll())
                PrintMessage(4, GAMEMODE.comedian:Nick() .. " is the comedian!")
                GAMEMODE.comedian:PrintMessage(3, "lol im the comedian :P")
                GAMEMODE.comedian:SetPos( CONSTANTS.POS_COMEDIAN )
            end

            if CurTime() > GAMEMODE.stateTimestamp + CONSTANTS.COMEDY_SECONDS or GAMEMODE.comedianQuit then
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
    GAMEMODE.comedian = nil
    GAMEMODE.comedianQuit = false
    GAMEMODE.boos = 0
    GAMEMODE.cheers = 0
end

function setGameState(state)
    if state ~= GAMEMODE.state then
        GAMEMODE.state = state
        net.Start("game_state")
        net.WriteInt(state, 16)
        net.Broadcast()
    end
end
