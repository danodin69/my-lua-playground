-- DAN ODIN ,  28 July 25, Journey To The Lua 
print(_VERSION)
--[[ Note: It has been a long time coming. Tonight the future shines bright. 
One small step for me, One Huge Step For My Future Self ]]
-- These notes here is me already starting to learn the language, first I learnt how to
-- ..Do a single Line Comment 
--[[And 
A 
multi 
Line 
comment
..]]

--Now the next lesson as God intended, a place to store things

-- 1. Variables

myString = "String"
myNumber = 69 -- HaHa
myFloat = 4.20 -- Laugh, I am funny. 
myBool = true -- Truth Nuke
theVoid = nil -- It is not the void because it is empty, it is void because we don't know what is inside. oooh spooky

--[[ Learning Note: So, uh, it is going to take some getting used to not being able to assign types
to variables. But then, I have a python brain. Though been busy with C++ lately, Unreal Engine, sweet stuff. ]]

-- 2. Tables

myArray = {8,4,7} -- Though it is called tables in Lua, it is the same thing as arrays in this state. Apparently these things are super powerful in Lua!

-- 2.1 Map-Like Tables
myProfile = {
    name = "Dan",
    age = 84,
    ["Favourite Team"] = "Manchester United" -- if you laugh

}


-- 2.2 Mixed Table

tableOfThings = {
    "Ball", -- Implicit item in a mixed table
    "Pot", -- The key is defined by the position (tableOfThings[2]). It insists upon itself.
    carItem = "Door", -- It has an Explicit key!! IT HAS AN EXPLICIT KEY!!!!! carItem
    [4] = "May the 4th Be with you", -- Dude.. it is july.. anyway, an explicit key as well but numeric.
    tableBeyondThings = {
        kitchenItem = "Spartular" -- Spongebob mi boy .. Oh another table inside this table.. A fractal lets you glimpse at infinity 
    }
} 
--[[
Learning Note: Mixed tables essentially are a super powered form of arrays. A table can do so much more..
    can not wait to get to that point!
]]
-- 3. Control
-- easy myNumber update

myNumber = myNumber - 67 -- Comment out to use original

if myNumber > myFloat then
    print("Something Happened\n") 
elseif tableOfThings.carItem == "Door" then -- Reducing myNumber to be less will run this
    print("Opening " .. tableOfThings.carItem .. "...\n") -- Concatenation example, Joining strings
else
    print("Nothing Happened\n")
end
if myFloat < myProfile.age then
    print("Something is happening\n")
end

--[[ Learning Note: "Control... without control, there would be no pattern in the chaos.
Control is Logical , it is what makes the infinite -- finite" - Dan Odin

I love the way if statements are structured in Lua, [if condition then do command, end].
feels like writing a spell... well if you think about it, making computers do what they do is..
    witchcraft.. so Lua is moon magic? woah!

]]

-- 4. Loops
--[["Controlling the infinite is what makes man God" - Dan Odin
 I have a confession, [for] loops always troubled my brain until I enrolled for Harvard CS50X
 They are ensentially [while] loops on steriods.
]]

-- 4.1 While Loop

local x = 1 -- Local variables make sense in classes, Loops, Functions (Lua does not have classes but they can be made with tables .. tables are powerful!)

while x <= myNumber do
    x = x + 1
    print("I am an X-man\n")
end

-- 4.2 Repeat Loop

repeat
    x = x + 1
    print("Keep Moving Forward!\n")
until x >= myNumber
-- Essentially a [do while] loop, but [repeat..until] is cold!! reminds me of Ruby's "unless" keyword.

-- 4.3 For Loop (Numeric)
for y = 1, myNumber, 1 do -- see, it is essentially the same code in the while loop.. 
    print("On My Way To Interspace\n")
end
--[[Learning Note: 
the formular for for loops
-- for start(setting the variable y = 1), end(the boundary = 5), step(= 1 , that is how much of it will run in every iteration also optional)
]]

-- 4.4 For Loop (Generic, for tables)

for oIndex, value in ipairs(myArray) do
    print(oIndex .. ": " .. tostring(value))
end

for key, value in pairs(myProfile) do 
    print(key .. " > " .. tostring(value))
end

--[[
Learning Note: Digging deep into this, Lua uses while loops in the background! OMG. 

i think it goes something like 
-- ipair() : used for ordered lists, optimised for arrays
local aVal = myArray -- inserted by a function
local i = 1 -- this serves a position indicator that would be incremented
while aVal[i] not nil do
    print(i, aVal[i])
    i = i + 1 -- increment
end

-- How it works for pairs() would be similar. 
Yet to wrap my head around it as it seems to be a little bit complex
I mean.. pairs() is chaotic perhaps it is because I do not understand functions in Lua yet..
    I will come back here. 
-- But in case i dont come bacK: pairs() finds no order ,   ipairs() move in order. 

]]

-- 5. Functions
--Ah, sweet sweet functions.. I love functions!
-- 5.1 Basic

function consoleWrite(aVal)
    print("\n".. aVal)
end

consoleWrite(40 - 20 .. " Made My own print function like C# ".. 30 + 39) --Not quite, but you got the spirit!
consoleWrite([[
    I can now write a poem.
    Roses are Red
    Violets are Blue
    Lets fly to the Moon 
    So I can always be with You
]]) -- This is a multiline print, similar to comments huh, really smart usage from Lua. More lua glazing ahead.

-- 5.2 Multiple Returns

valOne = 120
valTwo = 50
function doCalculation(a, b)
    return {
        add = a + b , 
        sub = a - b, 
        div = a / b, 
        mult = a * b, 
        mod = a % b}
end 
local result = doCalculation(valOne,valTwo)

consoleWrite("Calculates: ".. valOne .. " with " .. valTwo .. " -> \n".."Addition: ".. result.add .. " Subtraction: " .. result.sub .. " Division: " .. result.div .. " Multiplication: " .. result.mult .. " Modulus: " .. result.mod)
-- Wow! This is quite powerful

-- 5.3 Variadic Functions
function printAllThings(...)
    local args = {...} -- Puts args in a list
    consoleWrite("Using: {...}")
    print("Length:", #args)
    for i = 1, #args do -- creates better control and does not shrink like select
        
        print(i, args[i], type(args[i])) -- prints the input along with its type
    end
end

function printAllThingsWithSelect(...)
    consoleWrite("Using: Select(n,...)")
    for i = 1, select("#",...) do -- Counts all arguments (even `nil`s!)
        print(i, (select(i,...))) -- Prints args from position `i` to end
    end
end

printAllThings(1, "hey", nil, tableOfThings.carItem, myNumber, consoleWrite("What, I can even put this here?")) -- Functions will get excecuted first
printAllThingsWithSelect(1, "hey", nil, tableOfThings.carItem, myNumber, consoleWrite("What, I can even put this here?"))
--[[ Super powered type of function.. I have not seen something like this before..
perhaps my programming range is short but this is interesting, I think a lot than I know
can be done with variadic function. It feels kind of similar to final keyword in dart as it only really know what comes into it at run time.. except it is dynamic ]]


-- 5.4 Closures

function sayHello(prefix)
    return function(name) -- returns a function with a new argument 
        consoleWrite(prefix ..", ".. name) -- and it is still able to remember the first function arg
    end
end

function doAdditionMaths(x)
    return function(y)
        consoleWrite(x+y)
    end
end


greet = sayHello("Hallo") -- magic.. 
print(greet) -- tested to see what happens if i print greet as is, it prints the inner function's address function: 0x55b7754c7c10
greet("Dan Odin") -- In OOP this is like extending a class to do something.. wow! WHERE HAS LUA BEEN, I LOVE THIS
adder = doAdditionMaths(5)
adder(64)

-- woah does that mean, it can remember  even beyond itself, even when it ends.. let me make a counter

function counter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end

count = counter()

local i = 0

while i < 5 do
    consoleWrite(count())
    i = i + 1
end
-- what the helly, this feels illegal haha, what a beautiful language!
--[[ Learning Note: I enjoyed using Closures... Closures turn functions into mini-programs with lifelong memories,  I am sure there is more to learn about functions
but most times using the ones I have used here gets the Job done, for now I will move on!]]


-- 6 I/O 

--I.O Read

local file = io.open("textfile.txt","r") -- "r" : reads.
if not file then
    consoleWrite("error, such file does not exist")
    return
end

local content = file:read("*a") -- *a : reads all the file
consoleWrite(content)

file:close()

-- I.O Write

local log = io.open("textfile.txt","a") -- appends with "a" otherwise "w" to override. 
log:write("\nLog [Project].Lua :: ".. os.date() .. "..") -- adds whatever is in the qoutes ".."
log:close()

for line in io.lines("textfile.txt") do -- reads the file line by line.. This will help for reading large text files
    consoleWrite(line)
end


--[[ Learning Note: Classic I/O. Definitely using it in the next Lua project ]]

-- 7. Metatable

-- simple usage
local upgradeBugatti = {
    __add = function(car, newEngine) -- so there are these things called metamethods that have magic inbued in them. __add is one of them. it can add tables!
       return car.engine + newEngine
    end

}
-- Car Upgrader 
local myBugatti = { engine = 8 }
consoleWrite("My Bugatti has a V".. myBugatti.engine .. "Engine. \nBut.. with a bit of magic money..." )


setmetatable(myBugatti,upgradeBugatti)

myBugatti = myBugatti + 8

consoleWrite("My Bugatti Now Has a V".. myBugatti .. " Engine.. HeHe!")

-- Here I forge Robots 

local Robot = {}  -- first I make a robot base, a table. empty table.

local RobotUpgrader={ -- then i make a robot upgrader which is a Metatable
        __add = function(a,b) -- this will be able to combine two robots together to make it a new one
            return Robot.new(a.coreEngine + b.coreEngine) -- otherwise it will return one value if there is no other robot to merge
        end,

        __tostring=function(robot) --  enables me to print a fancy string! 
            return("🤖 CE version ".. robot.coreEngine .. " Engine!")
        end

        

    }

Robot.new = function(coreEngine)
        assert(type(coreEngine) == "number", "Engine must be a number!")
        if coreEngine < 0 then
            error("Not a valid engine number")
        end
        return setmetatable({ coreEngine = coreEngine }, RobotUpgrader) -- this attaches robot upgrader to robot and gives it the ability to upgrade itself by touching another robot.
    end




local pandaRobot = Robot.new(9)
local bibbleBot = Robot.new(60) -- Pronounced as bee-ble . . 
local moonBot = Robot.new(4) -- Love

local astroBot = pandaRobot + bibbleBot

consoleWrite(tostring(bibbleBot)) -- displayes : 🤖 CE version 60 Engine!

--[[ 
Learning Note: Metatables are truly what one must master in Lua. But for the most part i have a feeling I am going to love using closures more due to my nature as a functional programmer. In some cases though using metatables is better and more managable.

Essentially metatables have metamethods that allows making a regular table powerful! It allows for tables to be anything a developer can think of, setmetatable(normalTable,metatable) basically gives the normalTable abilities found in the metatable. SO COOL! like building lego blocks in a way.

]]
-- 8. Coroutines

local function delayInSeconds(seconds)
    startTimer = os.time() ; while os.time() - startTimer < seconds do end
end
    
local function spawnEnemies()
    local e  = 5
    for i = 1, e, 1 do
        consoleWrite("Spawned " .. i .. " Enemy")
        delayInSeconds(0.5)
        coroutine.yield()
    end 
end

local spawner = coroutine.create(spawnEnemies)
local log = io.open("world_log.txt","a")
while coroutine.resume(spawner) do
    
    log:write("\n\nLog [Enemy Spawner].Lua :: ".. os.date() .. "..")
    
end
log:close()

--[[
Learning Note:  Coroutines Rocks! I can already imagine the posibilities. Essentially they allow for things to happen in however order seen fit. Total control on how functions are executed and when. Imagine combining that with metatables and closures ! In a way though coroutines are built on the principles of closures as not only does it remember the function, it knows where it is. 
]]


-- 9. Error Handling
-- Lua's version of `try catch` i suppose
function myFunc()
    local v = 4
    if v < 10 then -- Obvious truth
        error("HMM! NUH UH") -- I am ungovernable 
    else
        return "Success"
    end
end
status, result = pcall(myFunc) -- myFunc basically gets passed to pcall  which means Protected Call, running the function within a protected call allows for sensible error catching. 
if status then consoleWrite(result) else consoleWrite("Error!! -> " .. result) end  -- this does something with pcall 


-- 10. Modules 

local congratulations = require("congratulations")  -- gets the file named congratulations.lua in my folder 
-- typically these are loaded at the top of the program in other languages I know but it is cool in lua that can be anywhere! wow. 

congratulations.congratulate("Dan Odin") -- using a function that was built inside congratulations file

-- 11. Garbage Collector
collectgarbage("collect") -- self explanatory innit? 
local log = io.open("garbage_log","a")
log:write("\n\nLog [Garbage Collector].Lua :: ".. collectgarbage("count") .. " KB :: ".. os.date() .. "..")
log:close() 

--[[
    I HAVE LEARNT ALL MAJOR LUA FEATURES !!!!! 
    This script is more like a cheat cheet for me, I will come here if i ever get stuck in the 
    'real world' 
    Lua is super simple! yet through out the lessons, I see how powerful it can be!

    RECORDS (timelapses)
    TIME SPENT TO UNDERSTAND THE SYNTAX: 10 MINS
    TIME SPENT TO MAKE THIS FILE: 2 HOURS 

    TIME SPENT TO ACTUALLY UNDERSTAND HOW TO THINK IN Lua: 4 HOURS
    TIME SPENT TO MASTER Lua: Forever and For Always - Dido 
    
    ..Just gotta build more stuff with it now haha, I have an idea... a remake of space impact from nokia 3310 with better 2D graphics in the Love2D framework. 

    FUN FUN FUN !!!
]]

