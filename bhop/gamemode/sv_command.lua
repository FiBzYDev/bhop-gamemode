-- Utility Functions

-- Case-insensitive replace function
local function replaceCaseInsensitive(s, pat, repl, n)
    pat = string.gsub(pat, '(%a)', function(v) return string.upper(v) .. string.lower(v) end)
    return n and string.gsub(s, pat, repl, n) or string.gsub(s, pat, repl)
end

-- Handle RTV Command
local function handleRTVCommand(ply, message)
    if message == "rtv" then
        RTV:Vote(ply)
        return ""
    end
end
hook.Add("PlayerSay", "RTVFix", handleRTVCommand)

-- Gamemode Functions
function GM:PlayerSay(ply, text, team)
    local prefix = string.sub(text, 1, 1)

    if prefix ~= "!" and prefix ~= "/" then
        local filteredText = self:FilterText(ply, text)
        return team and Admin:HandleTeamChat(ply, filteredText, text) or filteredText
    end

    local command = string.lower(string.sub(text, 2))
    local reply = Command:Trigger(ply, command, text)
    return reply and type(reply) == "string" and reply or ""
end

function GM:FilterText(ply, text)
    for input, output in pairs(varFilter) do
        text = replaceCaseInsensitive(text, input, output)
    end
    return text
end

function GM:ShowTeam(ply)
    Core:Send(ply, "GUI_Open", { "Spectate" })
end

function GM:ShowHelp(ply)
    Core:Send(ply, "MainMenu")
end

function GM:ShowSpare2(ply)
    Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
end

-- Command System
Command = {}
Command.Functions = {}
Command.TimeLimit = 0.8
Command.Limiter = {}

local HelpData, HelpLength

function Command:Init()

    -- Define a function to handle the "change" command for admins
    local function ChangeMap(ply, args)
        if not ply:IsAdmin() then
            return
        end

        if not args then
            Core:Send(ply, "Print", { "Notification", Lang:Get("MapChangeSyntax") })
            return
        end

        local targetMap = args[1]
        if not targetMap then
            Core:Send(ply, "Print", { "Notification", Lang:Get("MapChangeSyntax") })
            return
        end

        if not string.find(targetMap, "bhop_") then
            targetMap = "bhop_" .. targetMap
        end

        game.ConsoleCommand("changelevel " .. targetMap .. "\n")
    end

    -- Register the "change" command for admins with the appropriate aliases and description
    self:Register({ "change" }, function(ply, args)
        ChangeMap(ply, args)
    end, "Change the current map to the specified map (Admin only)", "<mapname>")

    -- Register common commands
    self:Register({ "menu", "mainmenu", "settings", "options" }, function(ply)
        Core:Send(ply, "MainMenu")
    end)

    self:Register({ "serverules", "rules" }, function(ply)
        Core:Send(ply, "Rules")
    end)

    self:Register({ "serversettings", "movement" }, function(ply)
        Core:Send(ply, "SettingsMenu")
    end)

    self:Register({ "help", "howto" }, function(ply)
        Core:Send(ply, "Help")
    end)

    self:Register({ "theme", "themeeditor", "themes" }, function(pl)
        pl:ConCommand("kawaii_thememanager")
    end)

    self:Register({ "jhud", "jhudoptions" }, function(ply)
        Core:Send(ply, "MainMenu")
    end)

    self:Register({ "restart", "r", "respawn", "kill" }, function(ply)
        if (ply.Tn or ply.Tb) and (not ply:GetNWInt("inPractice", false)) and (not ply.TnF) and (not ply.TbF) then
            local time = ply.Tn and (CurTime() - ply.Tn or 0) or (ply.Tb and CurTime() - ply.Tb or 0) or 0
            if (time > 300) and (not ply.informedReset) then
                Core:Send(ply, "Print", {"Timer", "Due to your long play time, could you please confirm you want to reset by doing this command again."})
                ply.informedReset = true

                timer.Simple(4, function()
                    ply.informedReset = false
                end)

                return
            end
        end
        ply.informedReset = false

        Command:RemoveLimit(ply)
        Command.Restart(ply)
    end)

    self:Register({ "spectate", "spec", "watch", "view" }, function(ply, args)
        Command:RemoveLimit(ply)
        if #args > 0 then
            if type(args[1]) == "string" then
                local ar, target, tname = Spectator:GetAlive(), nil, nil
                for id, p in pairs(ar) do
                    if string.find(string.lower(p:Name()), string.lower(args[1]), 1, true) then
                        target = p:SteamID()
                        tname = p:Name()
                        break
                    end
                end
                if target then
                    if ply.Spectating then
                        return Spectator:NewById(ply, target, true, tname)
                    else
                        args[1] = target
                    end
                end
            end

            Command.Spectate(ply, nil, args)
        else
            Command.Spectate(ply)
        end
    end)

    self:Register({ "noclip", "freeroam", "clip", "wallhack" }, Command.NoClip)
    self:Register({ "lj", "ljstats", "wj", "longjump", "stats" }, function(ply) Stats:ToggleStatus(ply) end)
    self:Register({ "strafetrainer", "jcstrainer" }, StrafeTrainer_CMD)
    self:Register({ "tp", "tpto", "goto", "teleport", "tele" }, Command.Teleport)

    self:Register({ "rtv", "vote", "votemap" }, function(ply, args)
        if #args > 0 then
            if args[1] == "who" or args[1] == "list" then
                RTV:Who(ply)
            elseif args[1] == "check" or args[1] == "left" then
                RTV:Check(ply)
            elseif args[1] == "revoke" then
                RTV:Revoke(ply)
            elseif args[1] == "extend" then
                Admin.VIPProcess(ply, { "extend" })
            else
                Core:Send(ply, "Print", { "Notification", args[1] .. " is an invalid subcommand of the rtv command. Valid: who, list, check, left, revoke, extend" })
            end
        else
            RTV:Vote(ply)
        end
    end)

    self:Register({"revote", "openrtv"}, function(ply, args)
        if not RTV.VotePossible then
            Core:Send(ply, "Print", { "Notification", "There is no vote currently active." })
        else
            local RTVSend = {}

            for _, map in pairs(RTV.Selections) do
                table.insert(RTVSend, RTV:GetMapData(map))
            end

            UI:SendToClient(false, "rtv", "Revote", RTVSend)
            UI:SendToClient(false, "rtv", "VoteList", RTV.MapVoteList)
        end
    end)

    self:Register({ "revoke", "retreat", "revokertv" }, function(ply)
        RTV:Revoke(ply)
    end)

    self:Register({ "checkvotes", "votecount" }, function(ply)
        RTV:Check(ply)
    end)

    self:Register({ "votelist", "listrtv" }, function(ply)
        RTV:Who(ply)
    end)

    self:Register({ "timeleft", "time", "remaining" }, function(ply)
        Core:Send(ply, "Print", { "Notification", Lang:Get("TimeLeft", { Timer:Convert(RTV.MapEnd - CurTime()) }) })
    end)

    self:Register({ "edithud", "hudedit", "sethud", "movehud" }, function(ply)
        Core:Send(ply, "Client", { "HUDEditToggle" })
    end)

    self:Register({ "restorehud", "hudrestore", "huddefault" }, function(ply)
        Core:Send(ply, "Client", { "HUDEditRestore", { 20, 115 } })
    end)

    self:Register({ "opacity", "hudopacity", "visibility", "hudvisibility" }, function(ply, args)
        if not tonumber(args[1]) then
            return Core:Send(ply, "Print", { "Notification", Lang:Get("MissingArgument", { "an extra numeric" }) })
        end

        Core:Send(ply, "Client", { "HUDOpacity", math.Clamp(tonumber(args[1]), 0, 255) })
    end)

    self:Register({ "showgui", "showhud", "hidegui", "hidehud", "togglegui", "togglehud" }, function(ply, args)
        if string.sub(args.Key, 1, 4) == "show" or string.sub(args.Key, 1, 4) == "hide" then
            Core:Send(ply, "Client", { "GUIVisibility", string.sub(args.Key, 1, 4) == "hide" and 0 or 1 })
        else
            Core:Send(ply, "Client", { "GUIVisibility", -1 })
        end
    end)

    self:Register({ "sync", "showsync", "sink", "strafe", "monitor" }, function(ply)
        SMgrAPI:ToggleSyncState(ply)
    end)

    self:Register({ "style", "mode", "bhop", "styles", "modes" }, function(ply)
        Command:RemoveLimit(ply)
        Core:Send(ply, "GUI_Open", { "Style" })
    end)

    self:Register({ "nominate", "rtvmap", "playmap", "addmap", "maps" }, function(ply, args)
        if #args > 0 then
            Command:RemoveLimit(ply)
            Command.Nominate(ply, nil, args)
        else
            Core:Send(ply, "GUI_Open", { "Nominate", { RTV.MapListVersion } })
        end
    end)

    self:Register({ "wr", "wrlist", "records" }, function(ply, args)
        local nStyle, nPage = ply.Style, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            UI:SendToClient(ply, "wr", Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle))
        end
    end)

    self:Register({ "rank", "ranks", "ranklist" }, function(ply)
        local bAngled = Player:GetRankType(ply.Style)
        Core:Send(ply, "GUI_Open", { "Ranks", { ply.Rank or 1, ply.RankSum or 0, bAngled, (bAngled and Player.AngledScalar or Player.NormalScalar) or 0.0001 } })
    end)

    self:Register({ "top", "toplist", "top100", "bestplayers" }, function(ply)
        local nPage = 1
        Core:Send(ply, "GUI_Open", { "Top", { 2, Player:GetTopPage(nPage, ply.Style), nPage, Player:GetTopCount(ply.Style), Player:GetRankType(ply.Style, true) } })
    end)

    self:Register({ "mapsbeat", "beatlist", "listbeat", "mapsdone", "mapscompleted", "beat", "done", "completed", "howgoodami" }, function(ply)
        Player:GetMapsBeat(ply, 'Completed')
    end)

    self:Register({ "mapsleft", "left", "leftlist", "listleft", "notbeat", "howbadami" }, function(ply)
        Player:GetMapsBeat(ply, 'Left')
    end)

    self:Register({ "mywr", "mywrs", "wr1", "wr#1", "wrcount", "wrcounter", "countwr", "wramount" }, function(ply)
        MySQL:Start("SELECT t2.* FROM game_times AS t2 INNER JOIN (SELECT szUID, nStyle, szPlayer, MIN(nTime) AS nMin, szMap FROM game_times GROUP BY szMap, nStyle) AS t1 ON t2.szUID = t1.szUID AND t2.nTime = t1.nMin WHERE t2.szUID = '" .. ply:SteamID() .. "'", function(Query)
            if not Query then
                Core:Send(ply, "Print", { "Notification", "You have no #1 times." })
            else
                local tab = {}
                for _, d in pairs(Query) do
                    table.insert(tab, { d["szMap"], tonumber(d["nTime"]), tonumber(d["nStyle"]), { d["szDate"], d["vData"], tonumber(d["nPoints"]), d["szPlayer"] } })
                end
                Core:Send(ply, "GUI_Open", { "Maps", { "WR", tab } })
            end
        end)
    end)

    self:Register({ "crosshair", "cross", "togglecrosshair", "togglecross", "setcross" }, function(ply, args)
        if #args > 0 then
            local szType = args[1]
            if szType == "color" then
                if not (#args == 4 or tonumber(args[2]) or tonumber(args[3]) or tonumber(args[4])) then
                    return Core:Send(ply, "Print", { "Notification", "You need to supply 4 parameters: !crosshair color r g b - Where r, g and b are numbers [0-255]" })
                end
                Core:Send(ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = args[2], ["sl_cross_color_g"] = args[3], ["sl_cross_color_b"] = args[4] } })
            elseif szType == "length" then
                if not (#args == 2 or tonumber(args[2])) then
                    return Core:Send(ply, "Print", { "Notification", "You need to supply 2 parameters: !crosshair length number" })
                end
                Core:Send(ply, "Client", { "Crosshair", { ["sl_cross_length"] = args[2] } })
            elseif szType == "gap" then
                if not (#args == 2 or tonumber(args[2])) then
                    return Core:Send(ply, "Print", { "Notification", "You need to supply 2 parameters: !crosshair gap number" })
                end
                Core:Send(ply, "Client", { "Crosshair", { ["sl_cross_gap"] = args[2] } })
            elseif szType == "thick" then
                if not (#args == 2 or tonumber(args[2])) then
                    return Core:Send(ply, "Print", { "Notification", "You need to supply 2 parameters: !crosshair thick number" })
                end
                Core:Send(ply, "Client", { "Crosshair", { ["sl_cross_thick"] = args[2] } })
            elseif szType == "opacity" then
                if not (#args == 2 or tonumber(args[2])) then
                    return Core:Send(ply, "Print", { "Notification", "You need to supply 2 parameters: !crosshair opacity number - Where number is [0-255]" })
                end
                Core:Send(ply, "Client", { "Crosshair", { ["sl_cross_opacity"] = args[2] } })
            elseif szType == "default" then
                Core:Send(ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = 0, ["sl_cross_color_g"] = 255, ["sl_cross_color_b"] = 0, ["sl_cross_length"] = 1, ["sl_cross_gap"] = 1, ["sl_cross_thick"] = 0, ["sl_cross_opacity"] = 255 } })
            elseif szType == "random" then
                Core:Send(ply, "Client", { "Crosshair", { ["sl_cross_color_r"] = math.random(0, 255), ["sl_cross_color_g"] = math.random(0, 255), ["sl_cross_color_b"] = math.random(0, 255), ["sl_cross_length"] = math.random(1, 50), ["sl_cross_gap"] = math.random(1, 35), ["sl_cross_thick"] = math.random(0, 10), ["sl_cross_opacity"] = math.random(70, 255) } })
            else
                Core:Send(ply, "Print", { "Notification", "Available commands: color [red green blue], length [scalar], gap [scalar], thick [scalar], opacity [alpha], default, random" })
            end
        else
            Core:Send(ply, "Client", { "Crosshair" })
        end
    end)

    self:Register({ "glock", "usp", "knife", "p90", "mp5", "deagle", "fiveseven", "m4a1", "ump45", "scout", "awp", "test" }, function(ply, args)
        if ply.Spectating or ply:Team() == TEAM_SPECTATOR then
            return Core:Send(ply, "Print", { "Notification", Lang:Get("SpectateWeapon") })
        else
            local bFound = false
            for _, ent in pairs(ply:GetWeapons()) do
                if ent:GetClass() == "weapon_" .. args.Key then
                    bFound = true
                    break
                end
            end
            if not bFound then
                ply.WeaponPickup = true
                ply:Give("weapon_" .. args.Key)
                ply:SelectWeapon("weapon_" .. args.Key)
                ply.WeaponPickup = nil
                Core:Send(ply, "Print", { "Notification", Lang:Get("PlayerGunObtain", { args.Key }) })
            else
                Core:Send(ply, "Print", { "Notification", Lang:Get("PlayerGunFound", { args.Key }) })
            end
        end
    end)

    self:Register({ "acs", "anticheats", "showanticheats", "toggleanticheats", "toggleacs" }, function(pl)
        pl:ConCommand("_toggleanticheats")

        Core:Send(pl, "Print", { "Notification", "You have toggled anti-cheat zone visibility." })
    end)

    self:Register({ "gunsounds", "shotsounds", "weaponsounds" }, function(pl)
        pl:ConCommand("_togglegunsounds")

        Core:Send(pl, "Print", { "Notification", "You have toggled gunsounds." })
    end)

    self:Register({ "remove", "strip", "stripweapons" }, function(ply)
        if not ply.Spectating and not ply:IsBot() then
            ply:StripWeapons()
        else
            return Core:Send(ply, "Print", { "Notification", Lang:Get("SpectateWeapon") })
        end
    end)

    self:Register({ "flip", "leftweapon", "leftwep", "lefty", "flipwep", "flipweapon" }, function(ply)
        ply.WeaponsFlipped = not ply.WeaponsFlipped
        Core:Send(ply, "Client", { "WeaponFlip" })
    end)

    self:Register({ "show", "hide", "showplayers", "hideplayers", "toggleplayers", "seeplayers", "noplayers" }, function(ply, args)
        if string.sub(args.Key, 1, 4) == "show" or string.sub(args.Key, 1, 4) == "hide" then
            Core:Send(ply, "Client", { "PlayerVisibility", string.sub(args.Key, 1, 4) == "hide" and 0 or 1 })
        else
            Core:Send(ply, "Client", { "PlayerVisibility", -1 })
        end
    end)

    self:Register({ "showspec", "hidespec", "togglespec" }, function(ply, args)
        local key = string.sub(args.Key, 1, 1)
        if key == "s" then Core:Send(ply, "Client", { "SpecVisibility", 1 })
        elseif key == "h" then Core:Send(ply, "Client", { "SpecVisibility", 0 })
        elseif key == "t" then Core:Send(ply, "Client", { "SpecVisibility", nil })
        end
    end)

    self:Register({ "chat", "togglechat", "hidechat", "showchat" }, function(ply)
        Core:Send(ply, "Client", { "Chat" })
    end)

    self:Register({ "muteall", "muteplayers", "unmuteall", "unmuteplayers" }, function(ply, args)
        Core:Send(ply, "Client", { "Mute", string.sub(args.Key, 1, 2) == "mu" and true or nil })
    end)

    self:Register({ "playernames", "playername", "player", "playertag", "targetids", "targetid", "labels" }, function(ply)
        Core:Send(ply, "Client", { "TargetIDs" })
    end)

    self:Register({ "water", "fixwater", "reflection", "refraction" }, function(ply)
        Core:Send(ply, "Client", { "Water" })
    end)

    self:Register({ "sky", "disablesky", "blacksky" }, function(ply)
        Core:Send(ply, "Client", { "Sky" })
    end)

    self:Register({ "fog", "disablefog", "nofog", "removefog" }, function(ply)
        Core:Send(ply, "Client", { "Fog" })
    end)

    self:Register({ "simple", "simpletextures" }, function(ply)
        Core:Send(ply, "Client", { "Simple" })
    end)

    self:Register({ "decals", "blood", "shots", "removedecals" }, function(ply)
        Core:Send(ply, "Client", { "Decals" })
    end)

    self:Register({ "vipnames", "disguise", "disguises", "reveal" }, function(ply)
        Core:Send(ply, "Client", { "Reveal" })
    end)

    self:Register({ "space", "spacetoggle", "holdtoggle", "auto" }, function(ply)
        ply.SpaceToggle = not ply.SpaceToggle
        Core:Send(ply, "Print", { "Notification", "Holding space will now" .. (not ply.SpaceToggle and " no longer" or "") .. " toggle" })
        Core:Send(ply, "Client", { "Space", true })
    end)

    self:Register({ "gravityboosterfix", "boosterfix2" }, function(ply, args)
        local pBFix = ply.Boosterfix
        pBFix.Enabled = not pBFix.Enabled
        Core:Send(ply, "Print", { "Notification", "You have " .. (pBFix.Enabled and "Enabled" or "Disabled") .. " Gravity Boosterfix." })
    end)

    self:Register({ "bot" }, function(ply, args)
        Core:Send(ply, "Print", { "Notification", "This command has been renamed, please do !runs" })
    end)

    self:Register({ "replay", "setbot", "setrun", "runs", "botset" }, function(ply, args)
        if not args[1] then
            local list = Bot:GetMultiBots()
            if #list > 0 then
                return Core:Send(ply, "Print", { "Notification", "Runs on these styles are recorded and playable: " .. string.Implode(", ", list) .. " (Use !setbot Style to start playback.)" })
            else
                return Core:Send(ply, "Print", { "Notification", "There are no other bots available for playback." })
            end
        end

        local nStyle = tonumber(args[1])
        if not nStyle then
            local szStyle = string.Implode(" ", args.Upper)

            local a = Core:GetStyleID(szStyle)
            if not Core:IsValidStyle(a) then
                return Core:Send(ply, "Print", { "Notification", "You have entered an invalid style name. Use the exact name shown on !styles or use their respective ID." })
            else
                nStyle = a
            end
        end

        local Change = Bot:ChangeMultiBot(nStyle)
        if string.len(Change) > 10 then
            Core:Send(ply, "Print", { "Notification", Change })
        else
            Core:Send(ply, "Print", { "Notification", Lang:Get("BotMulti" .. Change) })
        end
    end)

    self:Register({ "commands", "command" }, function(ply, args)
        Command:GetHelp()
        Core:Send(ply, "CommandsMenu")

        if #args > 0 then
            local mainArg, th = "", table.HasValue
            for main, data in pairs(Command.Functions) do
                if th(data[1], string.lower(args[1])) then
                    mainArg = main
                    break
                end
            end

            if mainArg ~= "" then
                local data = Lang.Commands[mainArg]
                if data then
                    if string.sub(data, 1, 7) == "A quick" or string.sub(data, 1, 7) == "For VIP" then
                        Core:Send(ply, "Print", { "Notification", "The !" .. mainArg .. " command is " .. data:gsub("%a", string.lower, 1) })
                    else
                        Core:Send(ply, "Print", { "Notification", "The !" .. mainArg .. " command " .. data:gsub("%a", string.lower, 1) })
                    end
                else
                    Core:Send(ply, "Print", { "Notification", "The command '" .. mainArg .. "' has no documentation" })
                end
            else
                Core:Send(ply, "Print", { "Notification", "The command '" .. mainArg .. "' isn't available or has no documentation" })
            end
        else
            net.Start(Core.Protocol2)
            net.WriteString("Help")

            if ply.HelpReceived then
                net.WriteUInt(0, 32)
            else
                net.WriteUInt(HelpLength, 32)
                net.WriteData(HelpData, HelpLength)
                ply.HelpReceived = true
            end

            net.Send(ply)
        end
    end)

    self:Register({ "map", "points", "mapdata", "mapinfo", "difficulty", "tier" }, function(ply, args)
        if #args > 0 then
            if not args[1] then return end
            if RTV:MapExists(args[1]) then
                local data = RTV:GetMapData(args[1])
                Core:Send(ply, "Print", { "Notification", Lang:Get("MapInfo", { data[1], data[2] or 1, "No more details available", "" }) })
            else
                Core:Send(ply, "Print", { "Notification", Lang:Get("MapInavailable", { args[1] }) })
            end
        else
            local nMult, bMult = Timer.Multiplier or 1, Timer.BonusMultiplier or 1
            local szBonus = Zones.BonusPoint and " (Bonus has a multiplier of " .. bMult .. ")" or ""
            local nPoints = Timer:GetPointsForMap(ply.Record, ply.Style)
            local szPoints = "Obtained " .. math.floor(nPoints) .. " / " .. nMult .. " pts"

            Core:Send(ply, "Print", { "Notification", Lang:Get("MapInfo", { game.GetMap(), Timer.Multiplier or 1, szPoints, szBonus }) })
        end
    end)

    self:Register({ "plays", "playcount", "timesplayed", "howoften", "overplayed" }, function(ply)
        Core:Send(ply, "Print", { "Notification", Lang:Get("MapPlayed", { Timer.PlayCount or 1 }) })
    end)

    self:Register({ "end", "goend", "gotoend", "tpend" }, function(ply)
        if ply:GetNWInt("inPractice", false) then
            local vPoint = Zones:GetCenterPoint(Zones.Type["Normal End"])
            if vPoint then
                ply:SetPos(vPoint)
                Core:Send(ply, "Print", { "Timer", Lang:Get("PlayerTeleport", { "the normal end zone!" }) })
            else
                Core:Send(ply, "Print", { "Timer", Lang:Get("MiscZoneNotFound", { "normal end" }) })
            end
        else
            Core:Send(ply, "Print", { "Timer", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." })
        end
    end)

    self:Register({ "endbonus", "endb", "bend", "gotobonus", "tpbonus" }, function(ply)
        if ply:GetNWInt("inPractice", false) then
            local vPoint = Zones:GetCenterPoint(Zones.Type["Bonus End"])
            if vPoint then
                ply:SetPos(vPoint)
                Core:Send(ply, "Print", { "Timer", Lang:Get("PlayerTeleport", { "the bonus end zone!" }) })
            else
                Core:Send(ply, "Print", { "Timer", Lang:Get("MiscZoneNotFound", { "bonus end" }) })
            end
        else
            Core:Send(ply, "Print", { "Timer", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport." })
        end
    end)

    self:Register({ "hop", "switch", "server" }, function(ply, args)
        if #args > 0 then
            local data = Lang.Servers[args[1]]
            if data then
                ply.DCReason = "Player hopped to " .. data[2]
                Core:Send(ply, "Client", { "Server", data })
                timer.Simple(10, function()
                    if IsValid(ply) then
                        ply.DCReason = nil
                    end
                end)
            else
                Core:Send(ply, "Print", { "Notification", "The server '" .. args[1] .. "' is not a valid server." })
            end
        else
            local servers = "None"
            local tab = {}

            for server, data in pairs(Lang.Servers) do
                table.insert(tab, server)
            end

            if #tab > 0 then
                servers = string.Implode(", ", tab)
            end

            Core:Send(ply, "Print", { "Notification", "Usage: !hop [server id]\nAvailable servers to !hop to: " .. servers })
        end
    end)

    self:Register({ "about", "info", "credits", "author", "owner" }, function(ply)
        Core:Send(ply, "Print", { "Notification", Lang:Get("MiscAbout") })
    end)

    self:Register({ "tutorial", "tut", "howto", "helppls", "plshelp" }, function(ply)
        Core:Send(ply, "Client", { "Tutorial", Lang.TutorialLink })
    end)

    self:Register({ "website", "flow", "surfline", "fl", "flweb", "web" }, function(ply)
        Core:Send(ply, "Client", { "Tutorial", Lang.WebsiteLink })
    end)

    self:Register({ "youtube", "speedruns", "videos", "video" }, function(ply)
        Core:Send(ply, "Client", { "Tutorial", Lang.ChannelLink })
    end)

    self:Register({ "discord", "ds", "chatwithus" }, function(ply)
        Core:Send(ply, "Client", { "Tutorial", Lang.DiscordLink })
    end)

    self:Register({ "forum", "forums", "community" }, function(ply)
        Core:Send(ply, "Client", { "Tutorial", Lang.ForumLink })
    end)

    self:Register({ "donate", "donation", "sendmoney", "givemoney", "gibepls" }, function(ply)
        Core:Send(ply, "Client", { "Tutorial", Lang.DonateLink .. "&steam=" .. ply:SteamID() })
    end)

    self:Register({ "version", "lastchange" }, function(ply)
        Core:Send(ply, "Client", { "Tutorial", Lang.ChangeLink })
    end)

    self:Register({ "main", "normal", "default", "standard", "n", "auto" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.Normal })
    end)

    self:Register({ "sideways", "sw" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.SW })
    end)

    self:Register({ "halfsideways", "halfsw", "hsw", "h" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.HSW })
    end)

    self:Register({ "wonly", "w" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style["W-Only"] })
    end)

    self:Register({ "aonly", "a" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style["A-Only"] })
    end)

    self:Register({ "legit", "l" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.Legit })
    end)

    self:Register({ "scroll", "s", "easy", "easyscroll", "e", "ez" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style["Easy Scroll"] })
    end)

    self:Register({ "u", "unreal", "ur", "unrea", "boost" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.Unreal })
    end)

    self:Register({ "swift", "vitesse", "swifer", "swi" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.Swift })
    end)

    self:Register({ "shsw", "shalf", "sch", "grospd" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.SHSW })
    end)

    self:Register({ "wtf", "wat", "romanmebranle", "watzefuk" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.WTF })
    end)

    self:Register({ "donly", "d" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style["D-Only"] })
    end)

    self:Register({ "bonus", "extra", "b" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.Bonus })
    end)

    self:Register({ "as", "autostrafer", "autostrafe" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.AutoStrafe })
    end)

    self:Register({ "lg", "lowgravity" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style["Low Gravity"] })
    end)

    self:Register({ "moonman", "moon", "mm" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style["Moon Man"] })
    end)

    self:Register({ "bw", "backwards" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.Backwards })
    end)

    self:Register({ "stam", "stamina" }, function(ply)
        Command:RemoveLimit(ply)
        Command.Style(ply, nil, { _C.Style.Stamina })
    end)

    self:Register({ "practice", "try", "free", "p" }, function(ply)
        Core:Send(ply, "Print", {"Timer", "This feature has been removed, using checkpoint or noclip will now disable your timer instead."})
    end)

    self:Register({ "wrn", "wrnormal", "nwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.Normal, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrsw", "wrsideways", "swwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.SW, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrhsw", "wrhalf", "wrhalfsw", "wrhalfsideways", "hswwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.HSW, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrw", "wrwonly", "wwr", "wonlywr" }, function(ply, args)
        local nStyle, nPage = _C.Style["W-Only"], 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wra", "wraonly", "awr", "aonlywr" }, function(ply, args)
        local nStyle, nPage = _C.Style["A-Only"], 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrl", "wrlegit", "lwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.Legit, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrs", "wrscroll", "swr", "scrollwr", "wre", "ewr" }, function(ply, args)
        local nStyle, nPage = _C.Style["Easy Scroll"], 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrb", "wrbonus", "bwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.Bonus, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrunreal", "wrun", "unrealwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.Unreal, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrseg", "wrsegment", "segwr", "segmentwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.Segment, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrswi", "wrswift", "swiftwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.Swift, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrshsw", "wrshalf", "shswwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.SHSW, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrwtf", "wrwat", "wtfwr" }, function(ply, args)
        local nStyle, nPage = _C.Style.WTF, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrd", "wrdonly", "dwr", "donlywr" }, function(ply, args)
        local nStyle, nPage = _C.Style["D-Only"], 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "swtop", "hswtop", "wtop", "atop" }, function(ply)
        local nPage = 1
        Core:Send(ply, "GUI_Open", { "Top", { 2, Player:GetTopPage(nPage, _C.Style.SW), nPage, Player:GetTopCount(_C.Style.SW), Player:GetRankType(_C.Style.SW, true) } })
    end)

    self:Register({ "wras", "wrautostrafe" }, function(ply, args)
        local nStyle, nPage = _C.Style.AutoStrafe, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrlg", "wrlowgravity" }, function(ply, args)
        local nStyle, nPage = _C.Style["Low Gravity"], 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrmoonman", "wrrmoon" }, function(ply, args)
        local nStyle, nPage = _C.Style["Moon Man"], 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrbw", "wrbackwards" }, function(ply, args)
        local nStyle, nPage = _C.Style.Backwards, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register({ "wrstam", "wrstamina" }, function(ply, args)
        local nStyle, nPage = _C.Style.Stamina, 1
        if #args > 0 then
            Player:SendRemoteWRList(ply, args[1], nStyle, nPage)
        else
            Core:Send(ply, "GUI_Open", { "WR", { 2, Timer:GetRecordList(nStyle, nPage), nStyle, nPage, Timer:GetRecordCount(nStyle) } })
        end
    end)

    self:Register("extend", function(ply)
        Admin.VIPProcess(ply, { "extend" })
    end)

    self:Register({ "emote", "me", "say" }, function(ply, args)
        Admin.VIPProcess(ply, { "me", args.Upper }, true)
    end)

    self:Register({ "hug", "ily", "iloveyou", "ifuckingloveyou" }, function(ply)
        if ply.HugRateLimit and ((ply.HugRateLimit + 30) >= CurTime()) then return end

        ply.HugRateLimit = CurTime()

        local trace = ply:GetEyeTrace()
        local pos = ply:GetPos()
        local distance = pos:Distance(trace.HitPos)
        local target = trace.Entity

        if not IsValid(target) or not target:IsPlayer() or target:IsBot() or (distance > 600) then
            Core:Send(ply, "Print", { "Notification", "You feel so incredibly lonely and tentatively, yet with purpose put your arms around yourself.\nIt is in this moment you gently hug yourself knowing your own warmth is all you seemingly have." })
            return
        end

        local username = ply:Nick()
        local targetname = target:Nick()

        Core:Send(ply, "Print", { "Notification", "You have given " .. targetname .. " a big warm hug!" })
        Core:Send(target, "Print", { "Notification", username .. " has given you a big warm hug!" })
    end)

    self:Register({ "timescale" }, function(ply, args)
        local isVIP = (ply.VIPLevel >= Admin.Level.Base)
        if not isVIP then return end

        local hasArgs = (args and #args > 0)
        local timescale = tonumber(args[1])
        if not hasArgs or not timescale then return end

        local isPractice = ply:GetNWBool("inPractice")
        if not isPractice then
            ply:SetNWBool("inPractice", true)
        end

        timescale = math.Clamp(timescale, 0.25, 5)

        ply:SetLaggedMovementValue(timescale)
    end)

    local playSounds = { ["bongo"] = "ambient/music/bongo.wav", ["country"] = "ambient/music/country_rock_am_radio_loop.wav", ["cuban"] = "ambient/music/cubanmusic1.wav", ["dust"] = "ambient/music/dustmusic1.wav", ["dusttwo"] = "ambient/music/dustmusic2.wav", ["dustthree"] = "ambient/music/dustmusic3.wav", ["flamenco"] = "ambient/music/flamenco.wav", ["latin"] = "ambient/music/latin.wav", ["mirame"] = "ambient/music/mirame_radio_thru_wall.wav", ["piano"] = "ambient/music/piano1.wav", ["pianotwo"] = "ambient/music/piano2.wav", ["radio"] = "looping_radio_mix.wav", ["guit"] = "ambient/guit1.wav", ["bubblegum"] = "bubblegum.wav", }
    for name, dest in pairs(playSounds) do
        sound.Add({ name = name, channel = CHAN_STATIC, volume = 1, level = 100, pitch = 100, sound = dest })
    end

    self:Register({ "playsound", "emitsound" }, function(ply, args)
        local isVIP = (ply.VIPLevel >= Admin.Level.Base)
        if not isVIP then return end

        local hasArgs = (args and #args > 0)
        local soundrequest = string.lower(args[1])
        local soundfile = playSounds[soundrequest]
        if not hasArgs or (soundrequest ~= "stop" and not soundfile) then return end

        if ply.EmittingSound and (soundrequest == "stop") then
            ply:StopSound(ply.EmittingSound)
            ply.EmittingSound = nil
            return
        end

        Command.EmitSound(ply, soundrequest)
        ply.EmittingSound = soundrequest
    end)

    self:Register("admin", Admin.CommandProcess)
    self:Register("vip", Admin.VIPProcess)
    self:Register("_invalid", function(ply, args) end)
end


function Command:Register(varCommand, varFunc, description, syntax)
    local mainCommand, commandList = "undefined", { "undefined" }
    if type(varCommand) == "table" then
        mainCommand = varCommand[1]
        commandList = varCommand
    elseif type(varCommand) == "string" then
        mainCommand = varCommand
        commandList = { varCommand }
    end

    Command.Functions[mainCommand] = { commandList, varFunc, description, syntax }
end

function Command:Trigger(ply, szCommand, szText)
    if not Command:Possible(ply) then return nil end

    local szFunc, mainCommand, commandArgs = nil, szCommand, {}

    if string.find(szCommand, " ", 1, true) then
        local splitData = string.Explode(" ", szCommand)
        mainCommand = splitData[1]

        local splitDataUpper = string.Explode(" ", szText)
        commandArgs.Upper = {}

        for i = 2, #splitData do
            table.insert(commandArgs, splitData[i])
            table.insert(commandArgs.Upper, splitDataUpper[i])
        end
    end

    for _, data in pairs(Command.Functions) do
        for __, alias in pairs(data[1]) do
            if mainCommand == alias then
                szFunc = data[1][1]
                break
            end
        end
    end

    szFunc = szFunc or "_invalid"
    commandArgs.Key = mainCommand

    local varFunc = Command.Functions[szFunc]
    if varFunc then
        varFunc = varFunc[2]
        return varFunc(ply, commandArgs)
    end

    return nil
end

function Command:GetHelp()
    if not HelpData or not HelpLength then
        local tab = {}

        for command, data in pairs(Command.Functions) do
            if not Lang.Commands[command] then continue end
            table.insert(tab, { Lang.Commands[command], data[1] })
        end

        HelpData = util.Compress(util.TableToJSON(tab))
        HelpLength = #HelpData
    end
end

function Command:Possible(ply)
    return true
end

function Command:RemoveLimit(ply)
    Command.Limiter[ply] = nil
end

function Command.Restart(ply)
    if not Command:Possible(ply) then return end
    if ply:Team() ~= _C.Team.Spectator then
        local szWeapon = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or _C.Player.DefaultWeapon
        ply.ReceiveWeapons = not not szWeapon
        ply:Spawn()
        ply:ResetTimer()
        ply.ReceiveWeapons = nil

        if szWeapon and ply:HasWeapon(szWeapon) then
            ply:SelectWeapon(szWeapon)
        end

        if ply.WeaponsFlipped then
            Core:Send(ply, "Client", { "WeaponFlip", true })
        end
    else
        Core:Send(ply, "Print", { "Timer", Lang:Get("SpectateRestart") })
    end
end

function Command.Style(ply, _, varArgs)
    if not Command:Possible(ply) then return end
    if not varArgs[1] or not tonumber(varArgs[1]) then return end

    if ply.Style == _C.Style.Segment and tonumber(varArgs[1]) ~= _C.Style.Segment then 
        Segment:Reset(ply)
        Segment:Exit(ply)
    end

    if tonumber(varArgs[1]) == ply.Style then
        if ply.Style == _C.Style.Bonus then
            Command:RemoveLimit(ply)
            return Command.Restart(ply)
        else
            return Core:Send(ply, "Print", { "Timer", Lang:Get("StyleEqual", { Core:StyleName(ply.Style) }) })
        end
    end

    local nStyle = tonumber(varArgs[1]) or _C.Style.Normal
    if nStyle == _C.Style.Bonus and not Zones.BonusPoint then
        return Core:Send(ply, "Print", { "Timer", Lang:Get("StyleBonusNone") })
    elseif nStyle == _C.Style.Bonus then
        ply:ResetTimer()
    elseif ply.Style == _C.Style.Bonus then
        ply:BonusReset()
    elseif ply:GetNWInt("inPractice", false) then
        ply.Tn = nil
        Core:Send(ply, "Timer", { "Start", ply.Tn })
    end

    Player:LoadStyle(ply, nStyle)
end

function Command.Spectate(ply, _, varArgs)
    if not Command:Possible(ply) then return end

    if ply.Spectating and varArgs and varArgs[1] then
        return Spectator:NewById(ply, varArgs[1], true, varArgs[2])
    elseif ply.Spectating then
        local target = ply:GetObserverTarget()
        ply:SetTeam(_C.Team.Players)
        Command:RemoveLimit(ply)
        Command.Restart(ply)
        ply.Spectating = false
        ply:SetNWInt("Spectating", 0)
        Core:Send(ply, "Spectate", { "Clear" })
        Core:Send(ply, "Client", { "Display" })
        Spectator:End(ply, target)

        if Admin:CanAccess(ply, Admin.Level.Admin) then
            SMgrAPI:SendSyncData(ply, {})
        end
    else
        ply:SetNWInt("Spectating", 1)
        Core:Send(ply, "Spectate", { "Clear" })
        ply.Spectating = true
        ply:KillSilent()
        ply:ResetTimer()
        GAMEMODE:PlayerSpawnAsSpectator(ply)
        ply:SetTeam(TEAM_SPECTATOR)

        if varArgs and varArgs[1] then
            return Spectator:NewById(ply, varArgs[1], nil, varArgs[2])
        end

        Spectator:New(ply)
    end
end

function Command.Teleport(ply, _, varArgs)
    if not ply:GetNWInt("inPractice", false) then
        Core:Send(ply, "Print", {"Notification", "You have to disable your timer first, either use noclip or enable checkpoints to allow for teleport."})
        return
    end

    if #varArgs > 0 then
        local target = Spectator:GetPlayerByName(varArgs[1])
        if IsValid(target) then
            if ply.Spectating then
                Core:Send(ply, "Print", {"Notification", "Your target player is in spectator mode."})
                return
            end

            ply:SetPos(target:GetPos())
            ply:SetEyeAngles(target:EyeAngles())
            ply:SetLocalVelocity(Vector(0, 0, 0))
            Core:Send(ply, "Print", {"Notification", "You have been teleported to " .. target:Name()})
        else
            Core:Send(ply, "Print", {"Notification", "Couldn't find a valid player with search terms: " .. varArgs[1]})
        end
    else
        Core:Send(ply, "Print", {"Notification", "No player name entered. Usage: !tp PlayerName"})
    end
end

function Command.NoClip(ply, _, varArgs)
    if not ply:GetNWInt("inPractice") and ply.Tn or ply.Tb then
        Core:Send(ply, "Print", {"Timer", "Your Timer has been stopped due to the use of Noclip."})
        ply:StopAnyTimer()
        ply:SetNWInt("inPractice", true)
        ply:ConCommand("noclip")
    elseif not ply:GetNWInt("inPractice") then
        Core:Send(ply, "Print", {"Timer", "You cannot use noclip in the Start Zone."})
        return
    end

    ply:ConCommand("noclip")
end

function Command.EmitSound(ply, varArgs)
    if ply.EmittingSound then
        ply:StopSound(ply.EmittingSound)
    end

    ply:EmitSound(varArgs)
end

function Command.ServerCommand(ply, szCmd, varArgs)
    local bConsole = not IsValid(ply) and not ply.Name and not ply.Team
    if not bConsole then return end

    if szCmd == "gg" then
        Core:Unload(true)
        RunConsoleCommand("changelevel", game.GetMap())
    elseif szCmd == "botsave" or szCmd == "savebot" then
        Bot:Save()
    elseif szCmd == "stop" then
        RunConsoleCommand("exit")
    elseif szCmd == "dodebug" then
        if CommandIncomplete then
            PrintTable(CommandIncomplete)
        end
    end
end

-- Add other command registrations as needed...

concommand.Add("reset", Command.Restart)
concommand.Add("spectate", Command.Spectate)
concommand.Add("style", Command.Style)
concommand.Add("nominate", Command.Nominate)
concommand.Add("pnoclip", Command.NoClip)
concommand.Add("cpload", Command.Checkpoint)
concommand.Add("cpsave", Command.Checkpoint)
concommand.Add("gg", Command.ServerCommand)
concommand.Add("botsave", Command.ServerCommand)
concommand.Add("stop", Command.ServerCommand)
concommand.Add("dodebug", Command.ServerCommand)
