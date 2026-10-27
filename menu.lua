pcall(function()
    local url

    -- Blox Fruits: Sea 1 / Sea 2 / Sea 3
    if game.PlaceId == 2753915549 or game.PlaceId == 4442272183 or game.PlaceId == 7449423635 then
        url = "https://raw.githubusercontent.com/ngocbachkhongchoi-eng/Gumball_protected.lua/refs/heads/main/Gumball_protected.lua"
    end

    if url then
        loadstring(game:HttpGet(url))()
    end
end)
