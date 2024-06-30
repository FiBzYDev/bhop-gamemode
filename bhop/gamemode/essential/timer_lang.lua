Lang = {}

function Lang:Get(szIdentifier, varArgs)
    varArgs = varArgs or {}  -- Ensure varArgs is a table

    local szText = Lang[szIdentifier]

    if not szText then
        return ""  -- Return empty string if szText is nil
    end

    if type(szText) == "table" then
        local tbl = table.Copy(szText)
        for k, v in ipairs(szText) do
            if type(v) == "string" then
                for nParamID, szArg in pairs(varArgs) do
                    v = string.gsub(v, nParamID .. ";", szArg)
                end
                tbl[k] = v
            end
        end
        szText = tbl
    else
        for nParamID, szArg in pairs(varArgs) do
            szText = string.gsub(szText, nParamID .. ";", szArg)
        end
    end

    return szText
end

Lang.TimerFinish = {
    _C["Prefixes"].Timer,
    "You ",
	color_white,
	"completed the map in ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	"! ",
	Color(107,142,35),
	"2;",
}

Lang.TimerPBFirst = {
	_C["Prefixes"].Timer,
	"2;",
	color_white,
	" beat the map in ",
	_C["Prefixes"].Timer,
	"4;",
	color_white,
    " on ",
	_C["Prefixes"].Timer,
    "1;",
	color_white,
	" placing ",
	_C["Prefixes"].Timer,
	"[#6;]",
	color_white,
	" ",
	_C["Prefixes"].Timer,
	"(-5;)"
}

Lang.TimerPBNext = {
	_C["Prefixes"].Timer,
	"2;",
	color_white,
	" beat the map in ",
	_C["Prefixes"].Timer,
	"4;",
	color_white,
    " on ",
	_C["Prefixes"].Timer,
    "1;",
	color_white,
	" placing ",
	_C["Prefixes"].Timer,
	"[#6;]",
	color_white,
	" ",
	_C["Prefixes"].Timer,
	"(-5;)"
}

Lang.TimerWRFirst = {
	_C["Prefixes"].Timer,
	"2;",
	color_white,
	" beat the map in ",
	_C["Prefixes"].Timer,
	"4;",
	color_white,
    " on ",
	_C["Prefixes"].Timer,
    "1;",
	color_white,
	" placing ",
	_C["Prefixes"].Timer,
	"[#6;]",
	color_white,
	" ",
	_C["Prefixes"].Timer,
	"(-5;)"
}

Lang.TimerWRNext = {
	_C["Prefixes"].Timer,
	"2;",
	color_white,
	" beat the map in ",
	_C["Prefixes"].Timer,
	"4;",
	color_white,
    " on ",
	_C["Prefixes"].Timer,
    "1;",
	color_white,
	" placing ",
	_C["Prefixes"].Timer,
	"[#6;]",
	color_white,
	" ",
	_C["Prefixes"].Timer,
	"(-5;)"
}

Lang.StyleEqual = {
	"Your Style is already set to ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	".",
}

Lang.StyleChange = {
	"Your Style is changed to ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	"!",
}

Lang.SegmentSet = {
	"New ",
	_C["Prefixes"].Timer,
	"checkpoint",
	color_white,
	" set.",
}

Lang.StopTimer = {
	"Your timer has been stopped due to the use of ",
	Color(255,0,0),
	"checkpoints",
	color_white,
	".",
}

Lang.DacTimer = {
	"Warning: using checkpoint will ",
	Color(255,0,0),
	"deactivate",
	color_white,
	" your timer.",
}

Lang.StyleLimit = {
    "You can't use those Movements in your selected ",
    _C["Prefixes"].Timer,
    "Style",
    color_white,
    ".",
}

Lang.StyleBonusNone = {
	"There are no available ",
	_C["Prefixes"].Timer,
	"bonus ",
	color_white,
	"to play."
}

Lang.StyleBonusFinish = {
	_C["Prefixes"].Timer,
    "You ",
	color_white,
	"finished the Bonus in ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	"! ",
	Color(107,142,35),
	"2;",
}

Lang.NoClip = {
	"Your timer has been ",
	Color(255,0,0),
	"disabled",
	color_white,
	" due to ",
	_C["Prefixes"].Timer,
	"nocliping",
	color_white,
	".",
}

Lang.NoClipSegment = {
	"Your noclip has been ",
	Color(255,0,0),
	"disabled",
	color_white,
	" due to ",
	_C["Prefixes"].Timer,
	"Segmented Style",
	color_white,
	".",
}

Lang.SetSpawn = {
	"You have set a ",
	_C["Prefixes"].Timer,
	"spawn point",
	color_white,
	".",
}

Lang.StyleFreestyle = {
    "You have ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " Freestyle Zone.",
    _C["Prefixes"].Timer,
    "2;",
}

Lang.BotEnter = {
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	" Style Replay has been spawned."
}

Lang.BotSlow = {
    "Your time was not good enough to be displayed by the WR Replay ",
	_C["Prefixes"].Timer,
    "(+1;)",
    color_white,
    ".",
}

Lang.BotInstRecord = {
    "You are now being Recorded by the WR Replay",
	_C["Prefixes"].Timer,
    "1;",
    color_white,
    ".",
}

Lang.BotInstFull = {
    "You couldn't be Recorded by the Replay because the list is already full!",
}

Lang.BotClear = {
    "You are now no longer being Recorded by the Replay.",
}

Lang.BotStatus = {
    "You are currently ",
	_C["Prefixes"].Timer,
    "1;",
	color_white,
    " Recorded by the Replay.",
}

Lang.BotAlready = {
    "You are already being Recorded by the WR Replay.",
}

Lang.BotStyleForce = {
    "Your ",
	_C["Prefixes"].Timer,
    "1;",
	color_white,
    " run wasn't Recorded because this map is forced to ",
	_C["Prefixes"].Timer,
    "2;",
    " Style.",
}

Lang.BotSaving = {
	_C["Prefixes"].Timer,
	"Replays",
	color_white,
	" will now be saved, a short period of",
	Color(255,0,0),
	" lag ",
	color_white,
	"may occur."
}

Lang.BotMultiWait = "The Replay must have at least finished playback once before it can be changed."
Lang.BotMultiInvalid = "The entered Style was invalid or there are no Replays for this Style."
Lang.BotMultiNone = "There are no WR Replays of different Styles to display."
Lang.BotMultiError = "An error occurred when trying to retrieve data to display. Please wait and try again."
Lang.BotMultiSame = "The Replay is already playing this Style."
Lang.BotMultiExclude = "The Replay can not display the Normal Style Run. Check the main Replay for that!"
Lang.BotDetails = "The Replay run was done by 1; [2;] on the 3; Style in a time of 4; at this date: 5;"

Lang.ZoneStart = {
	"You are now placing a",
	_C["Prefixes"].Timer,
	" Zone",
	color_white,
	". Move around to see the box in real-time. Press",
	Color(255,0,0),
	" Set Zone",
	color_white,
	" again to save.",
}


Lang.ZoneFinish = {
	"The",
	_C["Prefixes"].Timer,
	" Zone ",
	color_white,
	"has been placed.",
}

Lang.ZoneCancel = {
	_C["Prefixes"].Timer,
	"Zone ",
	color_white,
	"Placement has been ",
	Color(255,0,0),
	"cancelled",
	color_white,
	".",
}

Lang.ZoneNoEdit = "You are not setting any Zones at the moment."

Lang.ZoneSpeed = {
	"You can't leave this ",
	_C["Prefixes"].Timer,
	"Zone",
	color_white,
	" with that ",
	Color(255,0,0),
	"speed",
	color_white,
	"."
}

Lang.VotePlayer = {
    _C["Prefixes"].Timer,
    "1; ",
    color_white,
    "wants a map change. ",
    color_white,
    "(",
    _C["Prefixes"].Timer,
    "2; 3; required",
    color_white,
    ")",
}

Lang.VoteStart = {
	"A",
	_C["Prefixes"].Timer,
	" vote ",
	color_white,
	"to change map has started, choose your ",
	Color(255,0,0),
	"maps",
	color_white,
	"!"
}

Lang.VoteExtend = {
    "The vote has decided that the map is to be extended by ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " minutes!",
}

Lang.VoteChange = {
	"Changing map to ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	" in ",
	_C["Prefixes"].Timer,
	"10",
	color_white,
	" seconds."
}

Lang.VoteMissing = {
    "The map ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " is not available on the server so it can't be played right now.",
}


Lang.VoteLimit = {
	"Please wait for",
	_C["Prefixes"].Timer,
	" 1; ",
	color_white,
	_C["Prefixes"].Timer,
	"seconds before voting again.",
}

Lang.VoteAlready = {
    "You have already Rocked the Vote.",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.VotePeriod = {
    "A map vote has already started. You cannot vote right now.",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.VoteRevoke = {
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " has revoked his Rock the Vote. (",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
    " ",
    _C["Prefixes"].Timer,
    "3;",
    color_white,
    " left)",
}

Lang.VoteList = {
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " vote(s) needed to change maps.\nVoted (",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
    "): ",
    _C["Prefixes"].Timer,
    "3;",
    color_white,
    "\nHaven't voted (",
    _C["Prefixes"].Timer,
    "4;",
    color_white,
    "): ",
    _C["Prefixes"].Timer,
    "5;",
    color_white,
}

Lang.VoteCheck = {
    "There are ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " ",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
    " needed to change maps.",
}

Lang.VoteCancelled = {
    "The vote was cancelled by an Admin, the map will not change.",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.VoteFailure = {
	"Something went wrong while trying to change maps. Please ",
	_C["Prefixes"].Timer,
	" !rtv ",
	color_white,
	_C["Prefixes"].Timer,
	"again.",
}

Lang.VoteVIPExtend = {
    "We need help of the VIPs! The extend limit is ",
    _C["Prefixes"].Timer,
    "2;",
    " do you wish to start a vote to extend anyway? Type !extend or !vip extend.",
    color_white,
    _C["Prefixes"].Timer,
}

Lang.RevokeFail = "You can not revoke your vote because you have not Rocked the Vote yet."

Lang.Nomination = {
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	" has nominated ",
	color_white,
	_C["Prefixes"].Timer,
	"2;",
	color_white,
	" to be played next.",
}

Lang.NominationChange = {
	_C["Prefixes"].Timer,
	"1; ",
	color_white,
	" has changed his nomination from ",
	_C["Prefixes"].Timer,
	"2;",
	color_white,
	" to ",
	_C["Prefixes"].Timer,
	"3;",
}

Lang.NominationAlready = {
    "You have already nominated this map!",
    color_white,
}

Lang.NominateOnMap = {
    "You are currently playing this map so you can't nominate it.",
    color_white,
}

Lang.MapInfo = {
    "The map '1;' has a weight of ",
    _C["Prefixes"].Timer,
    "2; points (",
    _C["Prefixes"].Timer,
    "3;)",
    color_white,
    "4;",
}

Lang.MapInavailable = {
    "This map does not exist, not added or not zoned. Please contact an administrator if you feel this is incorrect.",
    color_white,
}

Lang.MapPlayed = {
    "This map has been played ",
    _C["Prefixes"].Timer,
    "1; times.",
    color_white,
}

Lang.TimeLeft = {
    "There is ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
	" left on this map.",
    color_white,
}

Lang.PlayerGunObtain = {
	"You have obtained a ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	".",
}

Lang.PlayerGunFound = {
	"You already have a ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	".",
}

Lang.PlayerSyncStatus = {
	"Your sync is ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	" being displayed.",
}

Lang.PlayerTeleport = {
	"You have been teleported to ",
	_C["Prefixes"].Timer,
	"1;",
	color_white,
	".",
}

Lang.SpectateRestart = {
    "You have to be alive in order to reset yourself to the start.",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.SpectateTargetInvalid = {
    "You are unable to spectate this player right now.",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.SpectateWeapon = {
    "You can't obtain a weapon in Spectator.",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.AdminInvalidFormat = {
    "The supplied value ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " is not of the requested type ",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
}

Lang.AdminMisinterpret = {
    "The supplied string ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " could not be interpreted. Make sure the format is correct.",
}

Lang.AdminSetValue = {
    "The ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " setting has successfully been changed to ",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
}

Lang.AdminOperationComplete = {
    "The Operation has completed successfully.",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.AdminHierarchy = {
    "The target's permission is greater than or equal to your permission level, thus you cannot perform this action.",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.AdminDataFailure = {
    "The server can't load essential data! If you can, contact an admin to make him identify the issue: ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.AdminMissingArgument = {
    "The ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " argument was missing. It must be of type ",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
    " and have a format of ",
    _C["Prefixes"].Timer,
    "3;",
    color_white,
}

Lang.AdminErrorCode = {
    "An error occurred while executing statement: ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.AdminFNACReport = {
    "FNAC ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.AdminPlayerKick = {
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " has been kicked. (Reason: ",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
    ")",
}

Lang.AdminPlayerBan = {
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " has been banned for ",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
    " minutes. (Reason: ",
    _C["Prefixes"].Timer,
    "3;",
    color_white,
    ")",
}

Lang.AdminChat = {
    "[",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    "] ",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
    " says: ",
    _C["Prefixes"].Timer,
    "3;",
    color_white,
}

Lang.MissingArgument = {
    "You have to add ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " argument to the command.",
}

Lang.CommandLimiter = {
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " Wait a bit before trying again (",
    _C["Prefixes"].Timer,
    "2;",
    color_white,
    "s).",
}

Lang.MiscZoneNotFound = {
    "The ",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
    " zone couldn't be found.",
}

Lang.MiscVIPRequired = {
    "This command is exclusively for vips. Type !donate to find out more!",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.MiscVIPGradient = {
    "To efficiently use space on the VIP panel we are making use of the two existing color pickers already on the panel.\nThe tag color will be the start point of your gradient\nand the name color will be the end point of your gradient.\nYou can also pick a custom name if you wish.\nTo set your gradient, press this button again when done selecting (this will close the panel)",
    _C["Prefixes"].Timer,
    "1;",
    color_white,
}

Lang.MiscAbout = {
	"This Gamemode, Bunny Hop Version ",
	_C["Prefixes"].Timer,
	"7.26",
	color_white,
	", was developed By FiBzY - justa - Gravoius.",
}

Lang.TutorialLink = "http://www.youtube.com/watch?v=Q3j9ftTk4C8"
Lang.WebsiteLink = "kawaii.site.nfoservers.com"
Lang.DiscordLink = "https://discord.gg/UFvQxqwkve"
Lang.ChannelLink = "http://www.youtube.com/user/GMSpeedruns/videos"
Lang.ForumLink = "kawaii.site.nfoservers.com"
Lang.DonateLink = "kawaii.site.nfoservers.com"
Lang.ChangeLink = "kawaii.site.nfoservers.com"
Lang.Commands = {["restart"] = "Resets the player to the start of the map",["spectate"] = "Brings the player to spectator mode. Also possible via F2",["noclip"] = "Toggles noclip on the player. Practice style required. Also possible via noclip bind.",["tp"] = "Allows you to teleport to another player",["rtv"] = "Calls a Rock the Vote. Subcommands: !rtv [who/list/check/revoke/extend]",["revoke"] = "Allows the player to revoke their RTV",["checkvotes"] = "Prints the requirements for a map vote to happen",["votelist"] = "Prints a list of all players and their vote status",["timeleft"] = "Displays for how long the map will still be on",["edithud"] = "Allows the user to move the HUD around on the screen",["restorehud"] = "Restores the HUD to its initial position",["opacity"] = "Allows the user to change the opacity of the HUD",["showgui"] = "Allows the user to change the visibility of the GUI",["sync"] = "Toggles visibility of sync on their GUI",["checkpoint"] = "Opens a window for the checkpoint system menu",["style"] = "Opens a window for the player to select a style",["nominate"] = "Opens a window for the player to nominate a map for a vote",["wr"] = "Opens the WR list for the style you're currently playing on",["rank"] = "Opens a window that shows a list of ranks",["top"] = "Opens a window that shows the best players in the server",["mapsbeat"] = "Opens a window that shows the maps you have completed and your time on it",["mapsleft"] = "Opens a window that shows the maps you haven't completed and their difficulty",["mywr"] = "Opens a window that shows all your #1 WRs on your current style",["crosshair"] = "Toggles the crosshair for the player OR changes settings; type !crosshair help",["glock"] = "These commands allow you to spawn in certain weapons",["remove"] = "Strip yourself of all weapons",["flip"] = "Switches your weapons to the other hand",["show"] = "Sets or toggles the visibililty of the players. Output depends on given command",["showtriggers"] = "Sets or toggles the visibililty of show map triggers. Output depends on given command",["showclips"] = "Sets or toggles the visibililty of show map clips you can't see. Output depends on given command",["showspec"] = "Allows you to change the visibility of the spectator list",["chat"] = "Sets or toggles the visibility of the chat. Output depends on given command",["muteall"] = "Sets mute status of players. Output depends on given command",["playernames"] = "Toggles targetted player labels visibility.",["water"] = "Toggles the state of water reflection and water refraction.",["decals"] = "Clears the map of all bulletholes and blood",["vipnames"] = "Shows the name of the VIP behind their custom name",["space"] = "Allows you to toggle holding space",["bot"] = "Show your bot status. Subcommands: !bot [add/remove]",["botsave"] = "A quick access function: Saves your own bot (Same as !bot save)",["help"] = "The command you just entered. Shows a list of commands and their functions",["map"] = "Prints the details about the map that is currently on",["plays"] = "Shows how often the map has been played",["end"] = "Go to the end zone of the normal timer",["endbonus"] = "Go to the end zone of the bonus",["hop"] = "Allows you to change server within our network",["about"] = "Shows information about the gamemode you're playing",["tutorial"] = "Opens a YouTube Video Tutorial in the Steam Browser",["website"] = "Opens our website in the Steam Browser",["youtube"] = "Opens a YouTube Channel where a lot of our runs are uploaded",["forum"] = "Opens our forum in the Steam Browser",["donate"] = "Opens our site with the donate page opened",["version"] = "Opens the latest change log in the Steam Browser",["normal"] = "A quick access function: Change style to Normal",["sideways"] = "A quick access function: Change style to Sideways",["halfsideways"] = "A quick access function: Change style to Half-Sideways",["wonly"] = "A quick access function: Change style to W-Only",["aonly"] = "A quick access function: Change style to A-Only",["legit"] = "A quick access function: Change style to Legit",["scroll"] = "A quick access function: Change style to Easy Scroll",["bonus"] = "A quick access function: Change style to Bonus",["segment"] = "A quick access function: Change style to Segmented",["unreal"] = "A quick access function: Change style to Unreal",["donly"] = "A quick access function: Change style to D-Only",["shsw"] = "A quick access function: Change style to Surf Half-Sideways",["swift"] = "A quick access function: Change style to Swift",["wtf"] = "A quick access function: Change style to WTF",["autostrafe"] = "A quick access function: Change style to Auto Strafer",["lowgravity"] = "A quick access function: Change style to Low Gravity",["practice"] = "A quick access function: Change style to Practice",["wrn"] = "A quick access function: Open Normal WR List",["wrsw"] = "A quick access function: Open Sideways WR List",["wrhsw"] = "A quick access function: Open Half-Sideways WR List",["wrb"] = "A quick access function: Open Bonus WR List",["wrl"] = "A quick access function: Open Legit WR List",["wra"] = "A quick access function: Open A-Only WR List",["wrs"] = "A quick access function: Open Easy Scroll WR List",["wrw"] = "A quick access function: Open W-Only WR List",["swtop"] = "A quick access function: Open Angled Top List",["emote"] = "For VIPs only: sends a status message",["extend"] = "For VIPs only: enables the extend option",["vip"] = "For VIPs only: opens up the VIP panel",}