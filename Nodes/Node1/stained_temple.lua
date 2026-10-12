if TDS and TDS.RemoveIndex then pcall(function() TDS:RemoveIndex() end) end
TDS:Loadout("Scout", "None", "None", "None", "None")

TDS:Mode("Easy")
TDS:GameInfo("Stained Temple")

TDS:VoteSkip()

TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --1
TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --2
TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --3
TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --4
TDS:Ready()

TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --5
TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --6
TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --7
TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --8
TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --9
TDS:Place("Scout", -0.7996654510498047, -1.545204997062683, -22.47845458984375, true) --10

for _ = 1, 4 do
    for index = 1, 10 do
        TDS:Upgrade(index)
    end
end

TDS:WaitForWave(19)
task.wait(5)

for index = 1, 10 do
    TDS:Sell(index)
end

