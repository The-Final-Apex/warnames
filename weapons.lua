-- Define missile item for each team
minetest.register_craftitem("warnames:ussr_missile", {
    description = "USSR Missile",
    inventory_image = "ussr_missile.png",
    on_use = function(itemstack, user, pointed_thing)
        -- Launch the missile
        local pos = user:get_pos()
        local dir = user:get_look_dir()
        local missile = minetest.add_entity(pos, "warnames:ussr_missile_entity")
        missile:set_velocity(vector.multiply(dir, 10))  -- adjust speed as necessary

        -- Return the item stack unchanged
        return itemstack
    end,
})

minetest.register_craftitem("warnames:allied_missile", {
    description = "Allied Missile",
    inventory_image = "allied_missile.png",
    on_use = function(itemstack, user, pointed_thing)
        -- Launch the missile
        local pos = user:get_pos()
        local dir = user:get_look_dir()
        local missile = minetest.add_entity(pos, "warnames:allied_missile_entity")
        missile:set_velocity(vector.multiply(dir, 10))  -- adjust speed as necessary

        -- Return the item stack unchanged
        return itemstack
    end,
})

-- Define the missile entities
minetest.register_entity("warnames:ussr_missile_entity", {
    hp_max = 1,
    physical = false,
    visual = "sprite",
    visual_size = {x = 0.5, y = 0.5},
    textures = {"ussr_missile.png"},
    
    on_step = function(self, dtime)
        self:set_yaw(math.atan2(self.object:get_velocity().x, self.object:get_velocity().z))

        -- Check for collisions
        local pos = self.object:get_pos()
        local node = minetest.get_node(pos)
        if node.name ~= "air" then
            -- Explode
            local explosion_radius = 5
            minetest.add_particle({
                pos = pos,
                velocity = {x = 0, y = 0, z = 0},
                acceleration = {x = 0, y = 0, z = 0},
                expirationtime = 1,
                size = 10,
                collisiondetection = true,
                object = nil,
            })
            minetest.set_node(pos, {name = "air"})
            minetest.sound_play("explosion_sound", {pos = pos, gain = 1.0, max_hear_distance = 10})
            -- Damage nearby entities (optional)
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, explosion_radius)) do
                if obj:is_player() or obj:get_luaentity() then
                    obj:set_hp(obj:get_hp() - 5)  -- adjust damage as necessary
                end
            end
            self.object:remove()  -- Remove missile after explosion
        end
    end,
})

minetest.register_entity("warnames:allied_missile_entity", {
    hp_max = 1,
    physical = false,
    visual = "sprite",
    visual_size = {x = 0.5, y = 0.5},
    textures = {"allied_missile.png"},
    
    on_step = function(self, dtime)
        self:set_yaw(math.atan2(self.object:get_velocity().x, self.object:get_velocity().z))

        -- Check for collisions
        local pos = self.object:get_pos()
        local node = minetest.get_node(pos)
        if node.name ~= "air" then
            -- Explode
            local explosion_radius = 5
            minetest.add_particle({
                pos = pos,
                velocity = {x = 0, y = 0, z = 0},
                acceleration = {x = 0, y = 0, z = 0},
                expirationtime = 1,
                size = 10,
                collisiondetection = true,
                object = nil,
            })
            minetest.set_node(pos, {name = "air"})
            minetest.sound_play("explosion_sound", {pos = pos, gain = 1.0, max_hear_distance = 10})
            -- Damage nearby entities (optional)
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, explosion_radius)) do
                if obj:is_player() or obj:get_luaentity() then
                    obj:set_hp(obj:get_hp() - 5)  -- adjust damage as necessary
                end
            end
            self.object:remove()  -- Remove missile after explosion
        end
    end,
})

-- Crafting recipes (optional)
minetest.register_craft({
    output = "warnames:ussr_missile 3",
    recipe = {
        {"default:steel_ingot", "default:gold_ingot", "default:steel_ingot"},
        {"default:stone", "default:stick", "default:stone"},
        {"default:steel_ingot", "default:gold_ingot", "default:steel_ingot"},
    }
})

minetest.register_craft({
    output = "warnames:allied_missile 3",
    recipe = {
        {"default:diamond", "default:gold_ingot", "default:diamond"},
        {"default:stone", "default:stick", "default:stone"},
        {"default:diamond", "default:gold_ingot", "default:diamond"},
    }
})

-- Define a function to create turrets
local function create_turret(name, texture, damage)
    minetest.register_entity(name, {
        initial_properties = {
            physical = false,
            visual = "mesh",
            mesh = "turret.b3d",  -- replace with your turret mesh filename
            textures = {texture},  -- replace with the texture filename
            pointable = false,
        },
        hp_max = 100,
        last_shoot_time = 0,
        target = nil,
        accuracy = 0.75,  -- 75% accuracy

        -- Function to find a player within range
        find_target = function(self)
            local pos = self.object:get_pos()
            for _, player in ipairs(minetest.get_connected_players()) do
                local player_pos = player:get_pos()
                -- Check if the player is within a specific distance (e.g., 20)
                if vector.distance(pos, player_pos) < 20 then
                    self.target = player
                    return
                end
            end
            self.target = nil  -- No target found
        end,

        on_step = function(self, dtime)
            self:find_target()  -- Try to find a target on each step

            if self.target and (minetest.get_gametime() - self.last_shoot_time > 1) then  -- Fire every second
                local player_pos = self.target:get_pos()
                local pos = self.object:get_pos()

                -- Calculate aiming direction
                local direction = vector.subtract(player_pos, pos)
                local distance = vector.length(direction)

                -- Normalize the direction vector
                direction = vector.multiply(direction, 1 / distance)

                -- Determine if the shot hits based on accuracy
                if math.random() < self.accuracy then
                    -- If successful, create a projectile or deal direct damage
                    local bullet = minetest.add_entity(pos, "warnames:bullet_entity")
                    bullet:set_velocity(vector.multiply(direction, 20))  -- Adjust speed as necessary
                    self.last_shoot_time = minetest.get_gametime()
                end
            end
        end,
    })
end

-- Create the turrets for each team
create_turret("warnames:ussr_turret", "ussr_turret.png", 5)
create_turret("warnames:allied_turret", "allied_turret.png", 5)

-- Define the bullet entity that the turrets fire
minetest.register_entity("warnames:bullet_entity", {
    visual = "sprite",
    visual_size = {x = 0.5, y = 0.5},
    textures = {"bullet.png"},  -- Replace with your bullet texture
    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        
        -- Check for collision with nodes
        local node = minetest.get_node(pos)
        if node.name ~= "air" then
            minetest.set_node(pos, {name = "air"})  -- Remove the node hit (optional)
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
                if obj:is_player() then
                    obj:set_hp(obj:get_hp() - 5)  -- Damage the player (adjust as necessary)
                end
            end
            self.object:remove()  -- Remove bullet after hitting something
        end
    end,
})

-- Create crafting for the turrets or any other systems to allow players to place them
minetest.register_craft({
    output = "warnames:ussr_turret",
    recipe = {
        {"default:steel_ingot", "default:stone", "default:steel_ingot"},
        {"default:stone", "default:gold_ingot", "default:stone"},
        {"default:steel_ingot", "default:stone", "default:steel_ingot"},
    }
})

minetest.register_craft({
    output = "warnames:allied_turret",
    recipe = {
        {"default:gold_ingot", "default:stone", "default:gold_ingot"},
        {"default:stone", "default:diamond", "default:stone"},
        {"default:gold_ingot", "default:stone", "default:gold_ingot"},
    }
})
