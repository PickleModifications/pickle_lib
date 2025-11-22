---@diagnostic disable: lowercase-global


local function caller_id(index)
    local info = debug.getinfo(index, "Sl")
    local short_src = info.source
    if #short_src > 60 then
        short_src = "..." .. short_src:sub(-57)
    end
    return ("%s:%d"):format(short_src, info.currentline)
end

local _print = print
function print(...)
    _print("[INFO] [".. (IS_CLIENT and "CLIENT" or "SERVER") .. "] ", ..., "(" .. tostring(caller_id(3)) .. ")")
end

local _error = error
function error(msg, level)
    _error("[ERROR] [".. (IS_CLIENT and "CLIENT" or "SERVER") .. "] " .. msg .. " (" .. tostring(caller_id(3)) .. ")", level)
end

---Prints a formatted string to the console.
---@param msg string the message to format
---@param args table<string,any>? the arguments to replace in the message. Use {key} in the message to denote where to replace.
---@diagnostic disable-next-line: lowercase-global
function printf(msg, args)
    for k, v in pairs(args or {}) do
        msg = msg:gsub("{" .. k .. "}", tostring(v))
    end
    print(msg)
end

---@class Lib
Lib = {}

---@type table<number,boolean>
local Intervals = {}

---@type table<fun()>
local ShutdownFunctions = {}

---@type table<any,boolean>
local Objects = {}

---Creates a new interval that calls the given function every `ms` milliseconds.
---This interval will be automatically cleared on shutdown.
---@param func fun() the function to call every interval
---@param ms number the interval in milliseconds
---@return number threadId the thread id of the created interval
function Lib.CreateInterval(func, ms)
    local inputTimer = Timer.SetInterval(func, ms)
    Intervals[inputTimer] = true
    return inputTimer
end

---Clears the given interval.
---@param thread number the thread id of the interval to clear
Lib.ClearInterval = function(thread)
    Timer.ClearInterval(thread)
    Intervals[thread] = nil
end

---Creates a new thread that runs the given function.
---This just calles `Timer.CreateThread` internally.
---@param func fun() the function to run in the new thread
function Lib.CreateThread(func)
    Timer.CreateThread(func)
end

---Waits for the given amount of milliseconds.
---This just calles `Timer.Wait` internally.
---@param ms number the amount of milliseconds to wait
function Lib.Wait(ms)
    Timer.Wait(ms)
end

---Clears the given thread.
---@param thread number the thread id of the thread to clear
function Lib.ClearThread(thread)
    ClearThread(thread)
end

---Starts the shutdown process by calling all registered shutdown functions.
function Lib.startShutdown()
    for _, v in ipairs(ShutdownFunctions) do
        v()
    end
    ShutdownFunctions = {}
end

---Registers a function to be called on shutdown.
---@param func fun() the function to call on shutdown
function Lib.onShutdown(func)
    table.insert(ShutdownFunctions, func)
end

---Performs a simple print.
---This just calls the global `print` function.
---@param ... any the values to print
function Lib.print(...)
    print(...)
end

---Creates a new static object in the world.
---This will also track the object for deletion on shutdown.
---@nodiscard
---@param model string the model to use for the object
---@param position Vector the position to spawn the object at
---@param rotation Vector the rotation to spawn the object with
---@return StaticMesh object the created object
function Lib.CreateObject(model, position, rotation)
    local object = StaticMesh(
        Vector(position.X, position.Y, position.Z),
        Rotator(rotation.X, rotation.Y, rotation.Z),
        model,
        CollisionType.StaticOnly
    )
    Objects[object] = true
    return object
end

---Attaches the given object to the given character at the specified bone.
---@param object StaticMesh the object to attach
---@param character HCharacter the character to attach the object to
---@param boneName string the name of the bone to attach the object to
---@param offset Vector the relative coordinates to attach the object at
---@param rotation Vector the relative rotation to attach the object with
---@param args {scale:Vector?,collision:CollisionType?}? additional arguments
function Lib.AttachEntityToCharacter(object, character, boneName, offset, rotation, args)
    args = args or {}
    args.scale = args.scale or vector3(1.0, 1.0, 1.0)
    args.collision = args.collision or CollisionType.NoCollision
    local mesh = character:GetCharacterBaseMesh()
    local objectComponent = object:K2_GetRootComponent()
    objectComponent:SetCollisionEnabled(CollisionType.NoCollision)
    objectComponent:SetMobility(UE.EComponentMobility.Movable)
    objectComponent:K2_AttachToComponent(mesh, boneName or 'hand_r', UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, true)
    object:K2_SetActorRelativeLocation(Vector(coords.X, coords.Y, coords.Z), false, nil, true)
    object:K2_SetActorRelativeRotation(Rotator(rotation.X, rotation.Y, rotation.Z), false, nil, true)
    object:SetActorScale3D(Vector(args.scale.X, args.scale.Y, args.scale.Z))
end

---Detaches the given object from any actor it is attached to.
---@param object StaticMesh the object to detach
---@param args {physics:boolean?,collision:CollisionType?}? additional arguments
function Lib.DetachEntity(object, args)
    args = args or {}
    args.physics = args.physics or false
    args.collision = args.collision or CollisionType.StaticOnly
    local objectComponent = object:K2_GetRootComponent()
    object:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
    objectComponent:SetCollisionEnabled(args.collision)
end

---Deletes the given object from the world.
---This will also remove the object from the tracked objects for shutdown.
---@param object StaticMesh the object to delete
function Lib.DeleteObject(object)
    DeleteEntity(object)
    Objects[object] = nil
end

function onShutdown()
    Lib.startShutdown()
    for k, v in pairs(Intervals) do
        Lib.ClearInterval(k)
    end
    Intervals = {}
    for k, v in pairs(Objects) do
        Lib.DeleteObject(k)
    end
    Objects = {}
end
