function dprint(...)
    print("[PICKLE_LIB] ".. (IS_CLIENT and "CLIENT" or "SERVER") .. " LOG: ", ...)
end

Lib = {}
Lib.Intervals = {}
Lib.ShutdownFunctions = {}
Lib.Objects = {}
Lib.CreateInterval = function(func, ms)
    local inputTimer = Timer.SetInterval(func, ms)
    Lib.Intervals[inputTimer] = true
    return inputTimer
end
Lib.ClearInterval = function(thread)
    Timer.ClearInterval(thread)
    Lib.Intervals[thread] = nil
end
Lib.CreateThread = function(func)
    Timer.CreateThread(func)
end
Lib.Wait = function(ms)
    Timer.Wait(ms)
end
Lib.ClearThread = function(thread)
    ClearThread(thread)
end
Lib.startShutdown = function()
    for k, v in pairs(Lib.ShutdownFunctions) do
        v()
    end
    Lib.ShutdownFunctions = {}
end
Lib.onShutdown = function(func)
    table.insert(Lib.ShutdownFunctions, func)
end
Lib.print = function(...)
    print(...)
end
Lib.CreateObject = function(model, position, rotation)
    local object = StaticMesh(
        Vector(position.X, position.Y, position.Z),
        Rotator(rotation.X, rotation.Y, rotation.Z),
        model,
        CollisionType.StaticOnly
    )
    Lib.Objects[object] = true
    return object
end
Lib.AttachEntityToCharacter = function(object, character, boneName, coords, rotation, args)
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
Lib.DetachEntity = function(object, character, args)
    args = args or {}
    args.physics = args.physics or false
    args.collision = args.collision or CollisionType.StaticOnly
    local objectComponent = object:K2_GetRootComponent()
    object:K2_DetachFromActor(UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld, UE.EDetachmentRule.KeepWorld)
    objectComponent:SetCollisionEnabled(args.collision)
end
Lib.DeleteObject = function(object)
    DeleteEntity(object)
    Lib.Objects[object] = nil
end
function onShutdown()
    Lib.startShutdown()
    for k, v in pairs(Lib.Intervals) do
        Lib.ClearInterval(k)
    end
    Lib.Intervals = {}
    for k, v in pairs(Lib.Objects) do
        Lib.DeleteObject(k)
    end
    Lib.Objects = {}
end
