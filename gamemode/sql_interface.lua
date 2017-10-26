if SQL_INTERFACE == nil then

    SQL_INTERFACE = {}

    function SQL_INTERFACE.getPlayerCoins(ply)
        local function callback(body)
            body = string.sub(body, 10)
            body = string.sub(body,0,string.len(body)-1)
            net.Start("coins")
            net.WriteString(body, 64)
            net.Send(ply)
        end
        local function failure()
            Msg("Failed")
        end
        http.Fetch( "http://your-app-endpoint-here.com/coins/"..ply:SteamID(), callback, failure)
    end
end
