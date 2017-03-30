customSchema = class({})

function customSchema:init()

    -- Check the schema_examples folder for different implementations

    -- Flag Example
    statCollection:setFlags({version = _G.AGS_VERSION})

    -- Listen for changes in the current state
    ListenToGameEvent('game_rules_state_change', function(keys)
        local state = GameRules:State_Get()

        -- Send custom stats when the game ends
        if state == DOTA_GAMERULES_STATE_POST_GAME then

            -- Build game array
            local game = BuildGameArray()

            -- Build players array
            local players = BuildPlayersArray()

            -- Print the schema data to the console
            if statCollection.TESTING then
                PrintSchema(game, players)
            end

            -- Send custom stats
            if statCollection.HAS_SCHEMA then
                statCollection:sendCustom({ game = game, players = players })
            end
        end
    end, nil)

    -- Write 'test_schema' on the console to test your current functions instead of having to end the game
    if Convars:GetBool('developer') then
        Convars:RegisterCommand("test_schema", function() PrintSchema(BuildGameArray(), BuildPlayersArray()) end, "Test the custom schema arrays", 0)
        Convars:RegisterCommand("test_end_game", function() GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS) end, "Test the end game", 0)
    end
end



-------------------------------------

-- In the statcollection/lib/utilities.lua, you'll find many useful functions to build your schema.
-- You are also encouraged to call your custom mod-specific functions

-- Returns a table with our custom game tracking.
function BuildGameArray()
    local game = {}

    -- Add game values here as game.someValue = GetSomeGameValue()
    game.gw = _G.GAME_WINNER_TEAM		-- winning team

    return game
end

-- Returns a table containing data for every player in the game
function BuildPlayersArray()
    local players = {}
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then

                local hero = PlayerResource:GetSelectedHeroEntity(playerID)               
                if hero then								
	                local heroTeam = PlayerResource:GetTeam(playerID)
	                if heroTeam == 2 then
	                	heroTeamStr = "Radiant"
	                elseif heroTeam == 3 then
	                	heroTeamStr = "Dire"
	                end
                  local heroName = GetHeroName(playerID)
                  local heroCategory = {"","",""}
                  heroCategory[hero:GetPrimaryAttribute()+1] = heroName
                  local heroDeath = hero:GetDeaths()
                  --if heroName == "pudge" then
                  --  heroDeath = heroDeath - _G.PUDGE_HOOK_SUM
                  --end
                  
	                table.insert(players, {
	                    -- steamID32 required in here
	                    steamID32 = PlayerResource:GetSteamAccountID(playerID) or 0,
	
	                    -- Example functions for generic stats are defined in statcollection/lib/utilities.lua
	                    -- Add player values here as someValue = GetSomePlayerValue(),
	                    ph = heroName,		-- Hero by its short name
	                    pt = heroTeamStr,			-- Team this hero belongs to
	                    pl = hero:GetLevel(),		-- Hero level at the end of the game
	                    pnw = GetNetworth(hero),		-- Sum of hero gold and item worth
	                    pk = hero:GetKills(),		-- Number of kills of this players hero
	                    pa = hero:GetAssists(),		-- Number of deaths of this players hero
	                    pd = heroDeath,		-- Number of deaths of this players hero
	                    
	                    pstr = heroCategory[1],  -- Display hero name if it's primary attribute is strength, which forms winrate sheet of str heroes
	                    pagi = heroCategory[2],  -- Display hero name if it's primary attribute is agility, which forms winrate sheet of agi heroes
	                    pint = heroCategory[3],  -- Display hero name if it's primary attribute is intelligence, which forms winrate sheet of int heroes
	                    pab = _G.AttrBonusStacks[playerID+1], -- the amount of the item Extra Attributes consumed
	                    pms = _G.MoonShardBuff[playerID+1], -- whether Moon Shard is consumed
	                    
	                    -- Item list
	                    is1 = GetItemSlot(hero,0),
	                    is2 = GetItemSlot(hero,1),
	                    is3 = GetItemSlot(hero,2),
	                    is4 = GetItemSlot(hero,3),
	                    is5 = GetItemSlot(hero,4),
	                    is6 = GetItemSlot(hero,5)
	                })
                end
                
            end
        end
    end

    return players
end

-- Prints the custom schema, required to get an schemaID
function PrintSchema(gameArray, playerArray)
    print("-------- GAME DATA --------")
    DeepPrintTable(gameArray)
    print("\n-------- PLAYER DATA --------")
    DeepPrintTable(playerArray)
    print("-------------------------------------")
end

-------------------------------------

-- If your gamemode is round-based, you can use statCollection:submitRound(bLastRound) at any point of your main game logic code to send a round
-- If you intend to send rounds, make sure your settings.kv has the 'HAS_ROUNDS' set to true. Each round will send the game and player arrays defined earlier
-- The round number is incremented internally, lastRound can be marked to notify that the game ended properly
function customSchema:submitRound()

    local winners = BuildRoundWinnerArray()
    local game = BuildGameArray()
    local players = BuildPlayersArray()

    statCollection:sendCustom({ game = game, players = players })
end

-- A list of players marking who won this round
function BuildRoundWinnerArray()
    local winners = {}
    local current_winner_team = GameRules.Winner or 0 --You'll need to provide your own way of determining which team won the round
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then
                winners[PlayerResource:GetSteamAccountID(playerID)] = (PlayerResource:GetTeam(playerID) == current_winner_team) and 1 or 0
            end
        end
    end
    return winners
end

-------------------------------------