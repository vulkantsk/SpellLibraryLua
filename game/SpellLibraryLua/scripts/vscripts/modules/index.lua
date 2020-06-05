local classesInit = {}
for k,v in pairs({
    'CreepSpawner',
    'AbilityInfo',
}) do 
    table.insert(classesInit,ModuleRequire(...,v .. '/index'))
end 

function InitModules()
    for k,v in pairs(classesInit) do
        if v.Init then 
            v:Init()
        end
    end
end
