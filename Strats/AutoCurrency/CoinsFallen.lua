
local Globals = getgenv()
Globals.AutoMercenary = true

TDS:Loadout("Trapper", "Gatling Gun", "Medic", "Mercenary Base", "Hacker")
TDS:Place("Trapper", 3.4956111907958984, 243, 206.29818725585938, true)
TDS:Ready()

-- [ Wave 2 ] --
TDS:Place("Trapper", -3.1409835815429688, 242.99998474121094, 206.28526306152344, true)
TDS:Upgrade(2)

-- [ Wave 3 ] --
TDS:Upgrade(1)

-- [ Wave 8 ] --
TDS:VoteSkip(8)
TDS:VoteSkip(8)
TDS:Place("Gatling Gun", 3.021298408508301, 243, 156.37335205078125, true)

-- [ Wave 10 ] --
TDS:Upgrade(3)

-- [ Wave 13 ] --
TDS:Upgrade(3)

-- [ Wave 17 ] --
TDS:Upgrade(3)

-- [ Wave 22 ] --
TDS:Upgrade(3)

-- [ Wave 24 ] --
TDS:Place("Medic", 3.1640725135803223, 243, 159.32357788085938, true)
TDS:Place("Medic", 3.1878535747528076, 243, 160.68592834472656, true)
TDS:Place("Medic", 3.0250463485717773, 243, 161.92108154296875, true)
TDS:Place("Medic", 3.082469940185547, 243, 163.3067626953125, true)

-- [ Wave 25 ] --
TDS:Upgrade(4)
TDS:Upgrade(4)
TDS:Upgrade(4)
TDS:Upgrade(5)
TDS:Upgrade(5)
TDS:Upgrade(5)
TDS:Upgrade(6)
TDS:Upgrade(6)
TDS:Upgrade(6)
TDS:Upgrade(7)
TDS:Upgrade(7)
TDS:Upgrade(7)
Globals.AutoMedic = true
TDS:VoteSkip(25)

-- [ Wave 26 ] --
TDS:Upgrade(1)
TDS:Upgrade(1)
TDS:Upgrade(1)

-- [ Wave 27 ] --
TDS:SetOption(1, "Trap", "Bear Traps")
TDS:VoteSkip(27)

-- [ Wave 29 ] --
TDS:VoteSkip(29)

-- [ Wave 30 ] --
TDS:Upgrade(3)
TDS:VoteSkip(30)

-- [ Wave 31 ] --
TDS:Upgrade(2)
TDS:Upgrade(2)
TDS:Upgrade(2)
TDS:SetOption(2, "Trap", "Bear Traps")

-- [ Wave 32 ] --
TDS:VoteSkip(32)

-- [ Wave 33 ] --
TDS:Upgrade(3)

-- [ Wave 35 ] --
TDS:Upgrade(4)
TDS:Upgrade(4)
TDS:Upgrade(5)
TDS:Upgrade(5)
TDS:Upgrade(6)
TDS:Upgrade(6)
TDS:Upgrade(7)
TDS:Upgrade(7)

-- [ Wave 36 ] --
TDS:Place("Trapper", 3.423664093017578, 242.99996948242188, 235.2234344482422, true)
TDS:Place("Trapper", -3.4279937744140625, 242.99996948242188, 235.2905731201172, true)
TDS:Upgrade(8)
TDS:Upgrade(8)
TDS:Upgrade(8)
TDS:Upgrade(8)
TDS:SetOption(8, "Trap", "Bear Traps")
TDS:Upgrade(9)
TDS:Upgrade(9)
TDS:Upgrade(9)
TDS:Upgrade(9)

-- [ Wave 37 ] --
TDS:SetOption(9, "Trap", "Bear Traps")
TDS:Place("Trapper", 2.997600555419922, 243, 222.71986389160156, true)
TDS:Place("Trapper", 3.059817314147949, 243, 221.2209014892578, true)
TDS:Place("Trapper", 3.1596527099609375, 243, 219.84791564941406, true)
TDS:Upgrade(10)
TDS:Upgrade(10)
TDS:Upgrade(10)
TDS:Upgrade(10)
TDS:SetOption(10, "Trap", "Landmine")
TDS:Upgrade(11)
TDS:Upgrade(11)
TDS:Upgrade(11)
TDS:Upgrade(11)
TDS:SetOption(11, "Trap", "Landmine")
TDS:Upgrade(12)
TDS:Upgrade(12)
TDS:Upgrade(12)
TDS:Upgrade(12)
TDS:SetOption(12, "Trap", "Landmine")

-- [ Wave 38 ] --
TDS:Place("Mercenary Base", -3.273420810699463, 243, 155.74484252929688, true)
TDS:Place("Mercenary Base", -3.2582650184631348, 243, 158.3777618408203, true)
TDS:Place("Mercenary Base", -3.102426767349243, 243, 160.8690643310547, true)
TDS:Upgrade(13)
TDS:Upgrade(13)
TDS:Upgrade(13)
TDS:Upgrade(13)
TDS:Upgrade(13)
TDS:Upgrade(13)
TDS:SetOption(13, "Unit 1", "Riot Guard")
TDS:SetOption(13, "Unit 2", "Riot Guard")
TDS:SetOption(13, "Unit 3", "Riot Guard")
TDS:Upgrade(14)
TDS:Upgrade(14)
TDS:Upgrade(14)
TDS:Upgrade(14)
TDS:Upgrade(14)
TDS:Upgrade(14)

-- [ Wave 39 ] --
TDS:Upgrade(15)
TDS:Upgrade(15)
TDS:Upgrade(15)
TDS:Upgrade(15)
TDS:Upgrade(15)
TDS:Upgrade(15)

-- [ Wave 40 ] --
TDS:Place("Hacker", -3.786302089691162, 242.99998474121094, 280.66259765625, true)
TDS:Place("Hacker", 3.7088184356689453, 242.99998474121094, 271.8018798828125, true)
TDS:Upgrade(17)
TDS:Upgrade(17)
TDS:Upgrade(17)
TDS:Upgrade(17)
TDS:Upgrade(16)
TDS:Upgrade(16)
TDS:Upgrade(16)
TDS:Upgrade(16)
TDS:Ability(17, "Hologram Tower", {towerPosition = Vector3.new( 3.021298408508301, 263, 156.37335205078125), towerToClone = 3}, true)
TDS:Ability(16, "Hologram Tower", {towerPosition = Vector3.new(2.6769356727600098, 263, 161.93191528320312), towerToClone = 3}, true)
