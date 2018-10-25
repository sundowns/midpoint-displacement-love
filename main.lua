love.math.setRandomSeed(os.time())
Util = require("util")

debug = false

-- dimensions of thegrid must be 2N+1 (to ensure we have a midpoint for each edge)
local n = 64
assert(n % 2 == 0, "Must be a power of 2") ---uhhhh
local GRID_WIDTH = (2*n)+1
local GRID_HEIGHT = (2*n)+1
local STEP_DURATION = 0.5
local SPREAD = 0.5

local coloured = false
local normalised = false
local current_step = 1
local finished = false
local step_timer = 0
local grid = {}
local nextSquares = {}
local newSquares = {}

function jitter(value)
    return value + love.math.random(SPREAD*-1, SPREAD)
end

function average2(a, b)
    return (a+b)/2
end

function average4(a, b, c, d)
    return (a+b+c+d)/4
end

--1) Initialize the four corners of the heightmap to random values.
--2) Set the midpoints of each edge to the average of the two corners it’s between, plus or minus a random amount.
--3) Set the center of the square to the average of those edge midpoints you just set, again with a random jitter.
--4) Recurse on the four squares inside this one, reducing the jitter.
function midpointDisplacement(square)

    -- 2) set midpoints of each edge to average of the two corners values (+ some random spread)
    local m1 = grid[average2(square.topLeft.x, square.topRight.x)][square.topLeft.y] -- top 
    local m2 = grid[square.topLeft.x][average2(square.topLeft.y, square.bottomLeft.y)] -- left
    local m3 = grid[square.topRight.x][average2(square.topRight.y, square.bottomRight.y)] -- right
    local m4 = grid[average2(square.topLeft.x, square.topRight.x)][square.bottomLeft.y] -- bottom
    m1.height = jitter(average2(square.topLeft.height, square.topRight.height))           -- top edge
    m2.height = jitter(average2(square.topLeft.height, square.bottomLeft.height))        -- left edge
    m3.height = jitter(average2(square.topRight.height, square.bottomRight.height))    -- right edge
    m4.height = jitter(average2(square.bottomLeft.height, square.bottomRight.height)) -- bottom edge

    --3) Set the center of the square to the average of those edge midpoints you just set, again with a random jitter.
    local cX, cY = average2(square.topLeft.x, square.topRight.x), average2(square.topLeft.y, square.bottomLeft.y)
    local centre = grid[cX][cY]
    centre.height = average4(m1.height, m2.height, m3.height, m4.height)

    --4) Prepare values for next recursion
    -- If there is more than 1 tile in between
    -- print(m1.x - square.topLeft.x )
    if current_step < math.log(n, 2) + 1 then
        --add 4 new squares
        addNewSquare(square.topLeft, m1, centre, m2) -- top left square
        addNewSquare(m1, square.topRight, m3, centre) -- top right square
        addNewSquare(m2, centre, m4, square.bottomLeft) -- bottom left square
        addNewSquare(centre, m3, square.bottomRight, m4) -- bottom right square
    else 
        finished = true
    end    
end

function step()
    for i=#nextSquares, 1, -1 do
        midpointDisplacement(nextSquares[i])
        table.remove(nextSquares, i)
    end
    nextSquares = newSquares
    newSquares = {}
    current_step = current_step + 1
end

function normaliseGrid() 
    local min = 100000
    local max = -100000
    for i = 0, GRID_WIDTH, 1 do
        for j = 0, GRID_HEIGHT, 1 do
            if grid[i][j].height < min then
                min = grid[i][j].height
            elseif grid[i][j].height > max then
                max = grid[i][j].height
            end
        end
    end

    print("min: "..min.. " max: "..max)
    --TODO: Iterate over the grid and normalize the values using our known min and max
end

function love.load()
    grid = {}
    for i = 0, GRID_WIDTH, 1 do
        grid[i] = {}
        for j = 0, GRID_HEIGHT, 1 do
            grid[i][j] = {
                x = i,
                y = j,
                height = 0
            }
        end
    end

    -- 1) set corners to random variables
    grid[0][0].height = love.math.random(100) -- top left
    grid[GRID_WIDTH-1][0].height = love.math.random(100) -- top right
    grid[0][GRID_HEIGHT-1].height = love.math.random(100) -- bottom left
    grid[GRID_WIDTH-1][GRID_HEIGHT-1].height = love.math.random(100) -- bottom right

    table.insert(nextSquares, {
        topLeft = grid[0][0],
        topRight = grid[GRID_WIDTH-1][0],
        bottomRight = grid[GRID_WIDTH-1][GRID_HEIGHT-1],
        bottomLeft = grid[0][GRID_HEIGHT-1]
    })
end

function addNewSquare(topLeft, topRight, bottomRight, bottomLeft)
    local newSquare = {
        topLeft = topLeft,
        topRight = topRight,
        bottomRight = bottomRight,
        bottomLeft = bottomLeft
    }

    table.insert(newSquares, newSquare)
end;

function love.update(dt)
    if not finished then
        step_timer = step_timer - dt

        if step_timer <= 0 then
            step()
            step_timer = step_timer + STEP_DURATION
        end
    elseif not normalised then
        normalised = true
        normaliseGrid()
    end
end

function love.draw()
    local width = love.graphics.getWidth()/GRID_WIDTH
    local height = love.graphics.getHeight()/GRID_HEIGHT
    
    for i = 0, GRID_WIDTH, 1 do
        for j = 0, GRID_HEIGHT, 1 do
            local tile = grid[i][j]
            if coloured then
                setColour(tile.height)
            else
                love.graphics.setColor(1,0,0,tile.height/100)
            end

            love.graphics.rectangle('fill', tile.x*width, tile.y*height, width, height)
        end
    end
end

function setColour(height)
    if height <= 45 then
        love.graphics.setColor(0,0,1)
        --water
    elseif height > 45 and height <= 50 then 
        love.graphics.setColor(1,1,0)
        --sand 
    elseif height > 50 and height <= 65 then 
        love.graphics.setColor(0,200/255,0)
        --grass 
    elseif height > 65 and height <= 75 then 
        love.graphics.setColor(0,100/255,0)
        --dark grass 
    elseif height > 75 and height <= 90 then 
        love.graphics.setColor(139/255,69/255,19/255)
        --rocks
    elseif height > 90 then 
        love.graphics.setColor(245/255, 1, 250/255)
        --snow 
    end

end;

function love.keypressed(key)
    if key == "space" then
        love.event.quit('restart')
    elseif key == "d" then
        debug = not debug
    elseif key == "escape" then
        love.event.quit()
    elseif key == "c" then
        coloured = not coloured
    end
end