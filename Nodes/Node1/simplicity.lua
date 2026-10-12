if TDS and TDS.RemoveIndex then pcall(function() TDS:RemoveIndex() end) end
TDS:Loadout("Scout", "None", "None", "None", "None")

TDS:Mode("Easy")
TDS:GameInfo("Simplicity")

TDS:VoteSkip()

TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --1
TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --2
TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --3
TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --4
TDS:Ready()

TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --5
TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --6
TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --7
TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --8
TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --9
TDS:Place("Scout", -9.6557102203369, 0.99998462200165, -9.2791118621826, true) --10

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

