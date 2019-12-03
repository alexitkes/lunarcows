--[[
    Return true if the string consists of 4 different digits
--]]
function validate(s)
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
    Generate a random string consisting of 4 different digits
--]]
function generate()
    s = ""
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
    Main game loop

    Arguments
    *   num_tries - the maximum number of tries, default is 20.

    Returns
    *   true if secret string found successfully, false if tries expired.
--]]
function play(num_tries)
    num_tries = num_tries or 20
    -- The string I should guess
    local secret = generate()
    for n = 1, num_tries do
        io.write("This is your try " .. n .. " of " .. num_tries .. "\n")
        repeat
            io.write("Enter the number: ")
            try = io.read()
        until validate(try)
        bulls, cows = compare(secret, try)
        if bulls == 4 then
            io.write("This is right! You win at try no. " .. n .. "\n")
            return true
        else
            io.write(tostring(bulls) .. " bulls " .. tostring(cows) .. " cows\n")
        end
    end
    io.write("You used all your tries, actual number was " .. secret .. "\n")
    return false
end

math.randomseed(os.time())
play()
