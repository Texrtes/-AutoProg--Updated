if TDS and TDS.RemoveIndex then pcall(function() TDS:RemoveIndex() end) end
TDS:Loadout("Scout", "None", "None", "None", "None")

TDS:Mode("Easy")
TDS:GameInfo("Spring Fever")

TDS:VoteSkip()

TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --1
TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --2
TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --3
TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --4
TDS:Ready()

TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --5
TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --6
TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --7
TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --8
TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --9
TDS:Place("Scout", -5.293452262878418, 1.0229387283325195, -22.20737075805664, true) --10

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

