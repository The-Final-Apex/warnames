local teams = {"USSR", "Allies"}

-- Function to load names from a file
local function load_names(filename)
    local names = {}
    local file_path = minetest.get_modpath("warnames") .. "/" .. filename
    
    minetest.log("info", "Loading names from: " .. file_path)
    
    local file = io.open(file_path, "r")
    if file then
        for line in file:lines() do
            if line and line ~= "" then
                table.insert(names, line)
            end
        end
        file:close()
    else
        minetest.log("error", "Failed to open names file: " .. filename)
    end
    return names
end

-- Load the names into tables
local ussr_names = load_names("ussr_names.txt")
local allied_names = load_names("allied_names.txt")

-- Define the ID card item
minetest.register_craftitem("warnames:id_card", {
    description = "ID Card",
    inventory_image = "id_card.png",
    
    -- Define the on_use function for item usage
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local team = user:get_meta():get_string("team") or "Unknown"
        local real_name = user:get_meta():get_string("real_name") or "Unknown"
        local role = user:get_meta():get_string("role") or "Unknown"

        local id_card_info = "ID Card:\n"
        id_card_info = id_card_info .. "Player: " .. player_name .. "\n"
        id_card_info = id_card_info .. "Real Name: " .. real_name .. "\n"
        id_card_info = id_card_info .. "Team: " .. team .. "\n"
        id_card_info = id_card_info .. "Role: " .. role

        minetest.chat_send_player(player_name, id_card_info)

        -- Prevent the item from being consumed
        return itemstack
    end,
})

-- Function to assign players to teams and roles
local function assign_team(player)
    local player_name = player:get_player_name()

    -- Check if the player has already received an ID card
    if player:get_meta():get_string("has_id_card") ~= "true" then
        -- Assign a random team
        local team = teams[math.random(#teams)]
        
        local real_name, role
        if team == "USSR" then
            real_name = ussr_names[math.random(#ussr_names)]
            role = ({"General", "Comrade", "Spy", "Sniper", "Engineer"})[math.random(5)]
        else
            real_name = allied_names[math.random(#allied_names)]
            role = ({"Commander", "Cadet", "Spy", "Sniper", "Engineer"})[math.random(5)]
        end

        player:get_meta():set_string("team", team)
        player:get_meta():set_string("real_name", real_name)  
        player:get_meta():set_string("role", role)

        -- Function to give players team-specific items
        local function spawn_players(team_name)
            local inventory = player:get_inventory()
            -- Clear previous items to avoid unwanted spawning
            inventory:set_list("main", {}) 

            if team_name == "USSR" then
                minetest.chat_send_player(player_name, "You are on the USSR team!")
                -- Add weapons and ammo directly to the player's inventory
                inventory:add_item("main", "guns4d_pack_1:m4") -- M4 rifle
                for i = 1, 5 do
                    inventory:add_item("main", "guns4d_pack_1:556") -- 5.56 ammo for M4
                end
                for i = 1, 3 do
                    inventory:add_item("main", "guns4d_pack_1:12G") -- 12 gauge ammo
                end
            elseif team_name == "Allies" then
                minetest.chat_send_player(player_name, "You are on the Allies team!")
                -- Add weapons and ammo directly to the player's inventory
                inventory:add_item("main", "guns4d_pack_1:m4") -- M4 rifle for Allies as well
                for i = 1, 5 do
                    inventory:add_item("main", "guns4d_pack_1:45A") -- .45 ACP ammo for Allies
                end
                for i = 1, 3 do
                    inventory:add_item("main", "guns4d_pack_1:12G") -- 12 gauge ammo
                end
            end
        end

        spawn_players(team)

        -- Create and give the ID card item
        local id_card_item = ItemStack("warnames:id_card")
        local meta = id_card_item:get_meta()
        meta:set_string("real_name", real_name)
        meta:set_string("team", team)
        meta:set_string("role", role)

        player:get_inventory():add_item("main", id_card_item)

        -- Set the metadata to indicate that the player has received the ID card
        player:get_meta():set_string("has_id_card", "true")
    else
        minetest.chat_send_player(player_name, "Welcome back, " .. player_name .. "!")
    end
end

-- Register the function to run when a player joins
minetest.register_on_joinplayer(assign_team)

-- Chat command to change teams
minetest.register_chatcommand("change_team", {
    params = "",
    description = "Change your team",
    func = function(name, _)
        local player = minetest.get_player_by_name(name)
        assign_team(player)
    end
})

