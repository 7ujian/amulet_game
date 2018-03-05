require "animation"

local game = {}
local letters = {}

local screenWidth = 640
local screenHeight = 480

-- window
local win = am.window{
    title = "Alphabeta",
    width = screenWidth,
    height = screenHeight,
    clear_color = vec4(0,0,0,1)
}

win.scene = am.group{
    -- am.translate(0,50)^am.text"ABCDEFG", 
    -- am.text"HIJKLMN",
    -- am.translate(0,-50)^am.text"OPQRST",
    am.translate(0,0):tag"player_position"^am.text("Player")
}


-- 世界
function World()
    local world = {
        player = nil,
        passengers = {},
        lights = {},
        cars = {},
        layers = {
            background = nil,
            player = nil,
            foreground = nil
        }      
    }
    
    world.add = function(self, entity)
        if (entity.graphic ~= nil) then
            
            if (entity.layer == "player") then
                self.layers.player:append(entity.graphic)
            end
            
        end
    end

  return world
end




-- 街道
local streetWidth = 60
local streetColor = vec4(0.75, 0.75, 0.75, 1)
local pavementWidth = 30
local pavementColor = vec4(0.85, 0.85, 0.85, 1)
win.scene:append(am.group{
    -- 路面
    am.rect(-screenWidth*0.5, -streetWidth*0.5, screenWidth * 0.5,streetWidth*0.5, streetColor),
    -- 分隔线
    am.line(vec2(-screenWidth*0.5, 0), vec2(screenWidth * 0.5,0), 2, vec4(0.25,0.25,0.25,1)),
    -- 人行道-
    am.rect(-screenWidth *0.5, streetWidth*0.5, screenWidth * 0.5,streetWidth*0.5+pavementWidth, pavementColor)
})

-- 房屋
local houseWidth = 60
local houseHeightBase = 100
local houseHeightVariant = 50
local houseSpace = 40
local houseStreetSpace = 20

local housecCount = math.ceil(screenWidth / (houseWidth + houseSpace))

for i= 1,housecCount do
    local houseHeight = houseHeightBase + math.random() * houseHeightVariant
    local houseColor = vec4(math.random(), math.random(), math.random(), 1)
    local x1 = (i-1)*(houseWidth+houseSpace)-screenWidth * 0.5
    local x2 = x1 + houseWidth
    local y1 = streetWidth * 0.5 + houseStreetSpace
    local y2 = y1 + houseHeight
    win.scene:append(am.rect(x1,y1,x2,y2,houseColor))
end

-- 车辆
function spawn_car()
    local carDirection = math.random(0,1)*2-1
    local carSpeed = 20
    local car = am.translate(screenWidth *0.5*carDirection, streetWidth * 0.25*carDirection)^am.rect(-20,-10, 20, 10, vec4(1,0,0,1))
    win.scene:append(car)
    car:action(function(car)
        car.position2d = car.position2d + vec2(-carSpeed * carDirection * am.delta_time, 0)
    end)    
end

local car_spawn_interval = 3
local car_spawn_time = 0

function spawn_car_tick()
    if (am.frame_time - car_spawn_time > car_spawn_interval) then
        spawn_car()
        car_spawn_time = am.frame_time
    end    
end

-- 红绿灯
local lights = am.group{
    am.rect(-8,-18,8,18, vec4(0.25,0.25,0.25,1)),
    am.rect(-2,-18,2,-40, vec4(0.25,0.25,0.25,1)),
    am.translate(0,10):tag"red"^am.group{
        am.circle(vec2(0,0),5,vec4(1,0,0,1)):tag"on",
        am.circle(vec2(0,0),5,vec4(0.5,0,0,1)):tag"off"
    },
    am.translate(0,0):tag"yellow"^am.group{
        am.circle(vec2(0,0),5,vec4(1,1,0,1)):tag"on",
        am.circle(vec2(0,0),5,vec4(0.5,0.5,0,1)):tag"off"
    },
    am.translate(0,-10):tag"green"^am.group{
        am.circle(vec2(0,0),5,vec4(0,1,0,1)):tag"on",
        am.circle(vec2(0,0),5,vec4(0,0.5,0,1)):tag"off"
    },
}

local lights_toggle_time = 1
lights.frame_time = 0
lights.current = 0

function update_lights(lights)
    lights"red""on".hidden = lights.current ~= 0
    lights"red""off".hidden = lights.current == 0
    lights"yellow""on".hidden = lights.current ~= 1
    lights"yellow""off".hidden = lights.current == 1
    lights"green""on".hidden = lights.current ~= 2
    lights"green""off".hidden = lights.current == 2
end

update_lights(lights)

lights:action(function(lights)
    if (am.frame_time - lights.frame_time > lights_toggle_time) then
        lights.frame_time = am.frame_time
        lights.current = (lights.current +1)%3
        update_lights(lights)
    end
end)



win.scene:append(am.translate(-240,70)^lights)

-- 行人

local face = [[
    ...KKK...
    ...KKK...
    ....K....
    .KKKKKKK.
    ...KKK...
    ...KKK...
    ...K.K...
    ...K.K...
]]    

function Passenger()
    local passenger = am.translate(0, streetWidth *0.5 +10)^am.scale(2) ^ am.sprite(face)
    
    function choose_destination()
        return vec2((math.random() - 0.5)*screenWidth, streetWidth *0.5 +10)
    end

    local move_frame_time = 0
    local move_frame_interval = 1
      
    destination = choose_destination()

    passenger:action(function(passenger)
        
        if (am.frame_time - move_frame_time > move_frame_interval) then
            move_frame_time = am.frame_time
            passenger"translate".position2d = choose_destination()
        end

    end)

    return passenger
end

local passenger1 = Passenger()
local passenger2 = Passenger()

passenger1"translate".position2d = vec2(-50, streetWidth *0.5 +10)
passenger2"translate".position2d = vec2(50, streetWidth *0.5 +10)

win.scene:append(passenger1)
win.scene:append(passenger2)



-- 玩家
local hero_spritesheet = am.texture2d("hero.png")
local hero_spec_d_1 = {
    texture = hero_spritesheet,
    s1 = 0, t1 = 1/4, s2 = 1/3, t2 = 2/4,
    x1 = 0, y1 = 0, x2 = 16, y2 = 16,
    width = 16, height = 16    
}
local hero_spec_d_2 = {
    texture = hero_spritesheet,
    s1 = 1/3, t1 = 1/4, s2 = 2/3, t2 = 2/4,
    x1 = 0, y1 = 0, x2 = 16, y2 = 16,
    width = 16, height = 16    
}
local hero_spec_d_3 = {
    texture = hero_spritesheet,
    s1 = 2/3, t1 = 1/4, s2 = 1, t2 = 2/4,
    x1 = 0, y1 = 0, x2 = 16, y2 = 16,
    width = 16, height = 16    
}

local animation_spec = {
    framerate=4,
    frames = {
        hero_spec_d_1,
        --hero_spec_d_2,
        hero_spec_d_3
    }
}

function Player()
    local animation = am.animation(animation_spec)
    animation:play()

    local self = {
        position = vec2(0,0),
        speed = 50,  
        graphic = am.translate(0,0)^am.scale(2)^animation
    }

    local action = function(player)
        local vertical = 0
        local horizontal = 0
        if(win:key_down("left")) then
            horizontal = horizontal - 1
        end
        if(win:key_down("right")) then
            horizontal = horizontal + 1
        end
        if(win:key_down("up")) then
            vertical = vertical + 1
        end
        if(win:key_down("down")) then
            vertical = vertical - 1
        end

        if (vertical ~= 0 or horizontal ~= 0) then
            local direction = math.normalize(vec2(horizontal, vertical))    
            player.position2d = player.position2d + self.speed * direction * am.delta_time
            -- * player.speed
        end
    end

    self.graphic:action(action)

    return self
end

local world = World()
world.layers.player = win.scene:append(am.group())

local player = Player()
player.layer = "player"

local player2 = Player()
player2.layer = "player"
player2.graphic.position2d = vec2(100,0)

world.player = player
world:add(player)
world:add(player2)

-- 动画



local animation = am.animation(animation_spec)
win.scene:append(am.scale(4)^animation)
win.scene:action(coroutine.create(function(node)
    while(true) do
        animation:play()
        am.wait(am.delay(3))
        animation:stop()
    end
end 
))


-- 雪花

local frame_time = am.frame_time
win.scene"player_position":action(function(node)
    if(am.frame_time-frame_time>1) then
        frame_time=am.frame_time
        node.hidden =not node.hidden
    end
end)

function letter_behavior(letter)
    letter.x = letter.x + math.sin(am.frame_time * 4 + letter.init_phase)
end


local spawn_time = am.frame_time

win.scene:action(function(scene) 
    spawn_car_tick()

    for i, letter in ipairs(letters) do
        letter.script(letter)
    end

    if(am.frame_time - spawn_time > 1) then
        spawn_time = am.frame_time
        local letter = {
            character="*",
            x = (math.random() -0.5)*screenWidth,
            y = screenHeight * 0.5,
            vy = -math.random() * 20 - 10,
            init_phase = math.random() * 3.14,
            amplitude_x = math.random() * 5, 
            graphic = am.translate(0,0)^am.text("*"),
            script = letter_behavior
        }
        table.insert(letters, letter)
        scene:append(letter.graphic)
    end

    for i, letter in ipairs(letters) do
        letter.y = letter.y + letter.vy * am.delta_time
    end

    for i, letter in ipairs(letters) do
        letter.graphic"translate".position2d = vec2(letter.x, letter.y)
    end

    local new_letters = {}
    for i, letter in ipairs(letters) do
        if(letter.y < 0 ) then
            scene:remove(letter.graphic)
        else
            table.insert(new_letters, letter)
        end
    end

    letters = new_letters
end)