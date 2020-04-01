--[[
    Convert a number from 0 to 9999 to 4-digit string
  ]]
function to_bcstring(n)
    local s = tostring(n)
    while #s < 4 do
        s = "0"..s
    end
    return s
end

--[[
    Return true if the string consists of 4 digits
--]]
function validate_try(s)
    if #s ~= 4 then
        return false
    end
    for i = 1, 4 do
        -- All bytes must be '0' to '9'
        if s:byte(i) < 48 or s:byte(i) > 57 then
            return false
        end
    end
    return true
end

--[[
    Return true if the string consists of 4 different digits
--]]
function validate_secret(s)
    if #s ~= 4 then
        return false
    end
    for i = 1, 4 do
        -- All bytes must be '0' to '9'
        if s:byte(i) < 48 or s:byte(i) > 57 then
            return false
        end
        for j = 1, 4 do
            if i ~= j and s:byte(i) == s:byte(j) then
                return false
            end
        end
    end
    return true
end

--[[
    Generate a random string consisting of 4 different digits
--]]
function generate_secret()
    local s = ""
    local n
    repeat
        repeat
            -- A random number from 0 to 9.
            n = math.random(10) - 1
        until not string.find(s, tostring(n))
        s = s .. tostring(n)
    until #s == 4
    return s
end

--[[
    Generate a random string consisting of 4 digits
--]]
function generate_try()
    local s = ""
    local n
    repeat
        n = math.random(10) - 1
        s = s .. tostring(n)
    until #s == 4
    return s
end

--[[
    Return the number of bulls and cows.
--]]
function compare(s, t)
    local bulls = 0
    local cows = 0
    for i = 1, 4 do
        for j = 1, 4 do
            if s:byte(i) == t:byte(j) then
                if i == j then
                    bulls = bulls + 1
                else
                    cows = cows + 1
                end
            end
        end
    end
    return bulls, cows
end

--[[
    Main loop for a stupid computer opponent. It will try a random
    number until get 4 bulls.
--]]
function stupid_opponent_loop()
    local bulls = 0
    local cows = 0
    local s = ""
    repeat
        s = generate_try()
        bulls, cows = coroutine.yield(s)
    until bulls == 4
    return s
end

--[[
    Main loop for an average computer opponent. It starts with the list of
    all 4-digit numbers. After every try, it removes all numbers proved
    impossible numbers from the list and then tries a number randomly
    selected from within remaining ones and so on. It actually plays quite
    well and usually takes less than 10 tries to win.

    This function should run as coroutine and will yielda new 4-digit
    string on each call. The numbers of bulls and cows should be given
    to it on resume.
--]]
function average_opponent_loop()
    local possible = {}
    local bulls = 0
    local cows = 0
    local s = ""
    local try = ""
    for i = 0, 9999 do
        possible[to_bcstring(i)] = true
    end
    repeat
        repeat
            try = generate_try()
        until possible[try]
        bulls, cows = coroutine.yield(try)
        for i = 0, 9999 do
            local s = to_bcstring(i)
            local b
            local c
            b, c = compare(try, s)
            if b ~= bulls or c ~= cows then
                possible[s] = false
            end
        end
    until bulls == 4
    return try
end

--[[
    Main loop for the human player.

    This function should run as coroutine and will yielda new 4-digit
    string on each call. The numbers of bulls and cows should be given
    to it on resume.
--]]
function player_loop()
    local bulls = 0
    local cows = 0
    local s = ""
    local i = 0
    repeat
        i = i + 1
        io.write("This is your try " .. i .. "\n")
        repeat
            io.write("Enter the number: ")
            s = io.read()
        until validate_try(s)
        bulls, cows = coroutine.yield(s)
    until bulls == 4
    return s
end

--[[
    Returns the number of tries and the type of computer opponent
    that may be either 'stupid' or 'average'. If posix.unistd.getopt
    library available it parses the command line options. Otherwise
    it always returns the default values
--]]
function get_options()
    if posix and posix.unistd and posix.unistd.getopt then
        return 20, "average"
    else
        return 20, "average"
    end
end

--[[
    Returns the main loop function for the specified opponent type.
    The opponent_type string may be 'stupid' or 'average' and the
    corresponding coroutine will be returned.
--]]
function get_opponent_loop(opponent_type)
    if opponent_type == 'stupid' then
        return stupid_opponent_loop
    elseif opponent_type == 'average' then
        return average_opponent_loop
    else
        assert(false, "Opponent type may be either 'stupid' or 'average'")
    end
end

--[[
    Main game loop

    Returns
    *   true if secret string found successfully, false if tries expired or
        the computer opponent guesses your string first.
--]]
function play()
    local num_tries
    local opponent_type
    num_tries, opponent_type = get_options()
    local players = {
        {
            name = 'Player',
            thread = coroutine.create(player_loop)
        },
        {
            name = 'Computer opponent',
            secret = generate_secret(),
            thread = coroutine.create(get_opponent_loop(opponent_type))
        }
    }
    local status
    local try
    local bulls
    local cows
    repeat
        io.write("Your secret number: ")
        players[1]['secret'] = io.read()
    until validate_secret(players[1]['secret'])
    io.write("Maximum number of tries is set to "..num_tries.."\n")
    for n = 1, num_tries do
        status, try = coroutine.resume(
            players[1]['thread'],
            players[1]['last_bulls'],
            players[1]['last_cows']
        )
        bulls, cows = compare(players[2]['secret'], try)
        if bulls == 4 then
            io.write("This is right! You win at try no. " .. n .. " out of " .. num_tries .. "\n")
            coroutine.resume(players[1]['thread'], 4, 0)
            return true
        else
            io.write(tostring(bulls) .. " bulls " .. tostring(cows) .. " cows\n")
            players[1]['last_bulls'] = bulls
            players[1]['last_cows'] = cows
        end
        status, try = coroutine.resume(
            players[2]['thread'],
            players[2]['last_bulls'],
            players[2]['last_cows']
        )
        bulls, cows = compare(players[1]['secret'], try)
        if bulls == 4 then
            io.write("Computer opponent tried number " .. try .. " and won!\n")
            coroutine.resume(players[2]['thread'], 4, 0)
            return false
        else
            io.write("Computer opponent tried number " .. try .. " and got " .. tostring(bulls) .. " bulls " .. tostring(cows) .. " cows\n")
        end
        players[2]['last_bulls'] = bulls
        players[2]['last_cows'] = cows
    end
    io.write("You used all your tries, actual number was " .. secret .. "\n")
    return false
end

math.randomseed(os.time())
play()
