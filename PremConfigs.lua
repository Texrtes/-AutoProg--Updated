--[[
    PremConfigs.lua
    Node Progression & Tower Definitions for AutoProg
]]--

local Config = {
    -- -----------------------------------------------------------------
    -- Node Progression Configuration
    -- -----------------------------------------------------------------
    Nodes = {
        ["Node 0"] = {
            TowerToBuy = { "Assassin" }, -- Node 0 goal: Buy Assassin before moving to Node 1
            [1] = {
                Level = 0, -- Level required: 0 or above
                TowersCheck = { "Scout", "Sniper" },
                TowersToEquip = { "Scout", "Sniper" },
                TowerToBuy = { "Assassin" },
                StoryMode = { "Boot Camp", "Live Fire", "Breach Protocol", "Brute Force" }, -- Story Missions
                scripts = {
                    ["Boot Camp"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node0/Bootcamp.lua",
                    ["Live Fire"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node0/LiveFire.lua",
                    ["Breach Protocol"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node0/BreachProtocol.lua",
                    ["Brute Force"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node0/BruteForce.lua",
                }
            }
        },
        ["Node 1"] = {
            TowerToBuy = { "Soldier" }, -- Node 1 goal
            LevelGoals = 15, -- Level target for Node 1
            [1] = {
                Level = 0, -- Level required: 0 or above
                LevelGoals = 15,
                TowersCheck = { "Scout" },
                TowersToEquip = { "Scout" },
                Modes = "Easy", -- Match difficulty / mode
                TowerToBuy = { "Soldier" }, -- Node 1 things to do: Grind coins until Soldier is purchased
                Maps = { "Simplicity", "Meltdown", "Midnight Issue", "Spring Fever", "Stained Temple" }, -- Available Maps
                scripts = {
                    ["Simplicity"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node1/simplicity.lua",
                    ["Meltdown"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node1/meltdown.lua",
                    ["Midnight Issue"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node1/midnight_issue.lua",
                    ["Spring Fever"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node1/spring_fever.lua",
                    ["Stained Temple"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node1/stained_temple.lua",
                }
            }
        },
        ["Node 2"] = {
            TowerToBuy = { "Farm", "Boomerang" }, -- Node 2 goal
            TowersToClaim = { "Crook Boss" }, -- Claim Crook Boss (unlocked at Level 30)
            LevelGoals = 50, -- Level target for Node 2
            [1] = {
                Level = 15, -- Level required: 15 or above
                LevelGoals = 50,
                TowersCheck = { "Soldier" },
                TowersToEquip = { "Soldier" },
                Modes = "Molten", -- Match difficulty / mode
                TowerToBuy = { "Farm", "Boomerang" },
                TowersToClaim = { "Crook Boss" },
                Maps = { "Lighthaos", "Midnight Issue", "Nether", "Wrecked Battlefield II" }, -- Available Maps
                scripts = {
                    ["Lighthaos"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node2/lighthaos.lua",
                    ["Midnight Issue"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node2/midnight_issue.lua",
                    ["Nether"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node2/nether.lua",
                    ["Wrecked Battlefield II"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Nodes/Node2/wrecked_battlefield_ii.lua",
                }
            }
        },
        ["Node 3"] = {
            TowerToBuy = { "Brawler", "Necromancer", "Accelerator", "Engineer", "Hacker" }, -- Node 3 goal
			  LevelGoals = 5000, -- Level target for Node 2
            [1] = {
                Level = 50, -- Level required: 50 or above
				 LevelGoals = 5000,
                TowersCheck = { "Pyromancer", "Hunter" },
                TowersToEquip = { "Pyromancer", "Hunter" },
                Modes = "hardcore", -- Match difficulty / mode
                Difficulty = "Easy",
                TowerToBuy = { "Brawler", "Necromancer", "Accelerator", "Engineer", "Hacker" }, 
                Maps = { "Wretched Front" }, -- Available Maps
                scripts = {
                    ["Wretched Front"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/main/Recording/Node3/wretched_front.lua",
                }
            }
        }
    },
	
	 -- -----------------------------------------------------------------
    -- Modifers & Bonus Rewards & Maps Rewards Scaling
    -- -----------------------------------------------------------------
	
	 Modifiers = {
	 -- Modifiers name    --Multiplyer bonus WIN only  STACKS if multiple is choiced 
	 ["Speedy Enemies"] = 0.25,
	 ["Glass"] = 0.05, -- this is % 0.05 > 100% + 5% get it?
	 ["Quarantine"] = 0.20,
	 ["Fog"] = 0.20,
	 ["Limitation"] = 0.10,
	 ["Flying Enemies"] = 0.15,
	 ["Jailed Towers"] = 0.20,
	 ["Exploading Enemies"] = 0.2,
	 ["Inflation"] = 0.30,
	 ["Committed"] = 0.10,
	 ["Hidden Enemies"] = 0.10,
	 ["Broke"] = 0.30,
	 ["Healthy Enemies"] = 0.30,
	 },
	 
	 -- DOES NOT APPLY IN HARDCORE/GEMS remember!
	 MapScaling = {
	 ["Very Easy"] = 0.5,
	 ["Easy"] = 0.85, -- 
	 ["Normal"] = 1, -- Normal Rewards 
	 ["Hard"] = 1.25,
	 ["Insane"] = 1.5, -- rewards is 150% coins stack with mods  example 150% = 0.95% = ? 
	 },
	
    -- -----------------------------------------------------------------
    -- Tower Lists & Costs (Buyable, Claimable & Unlock Requirements)
    -- -----------------------------------------------------------------
    TowerList = {
        ["Coins"] = {
            { Name = "Scout", Cost = 0, Type = "Coins", Action = "Buy" },
            { Name = "Sniper", Cost = 50, Type = "Coins", Action = "Buy" },
            { Name = "Paintballer", Cost = 100, Type = "Coins", Action = "Buy" },
            { Name = "Demoman", Cost = 200, Type = "Coins", Action = "Buy" },
            { Name = "Boomerang", Cost = 300, Type = "Coins", Action = "Buy" },
            { Name = "Slime Trooper", Cost = 300, Type = "Coins", Action = "Buy" },
            { Name = "Soldier", Cost = 350, Type = "Coins", Action = "Buy" },
            { Name = "Freezer", Cost = 650, Type = "Coins", Action = "Buy" },
            { Name = "Militant", Cost = 800, Type = "Coins", Action = "Buy" },
            { Name = "Assassin", Cost = 800, Type = "Coins", Action = "Buy" },
            { Name = "Shotgunner", Cost = 850, Type = "Coins", Action = "Buy" },
            { Name = "Hunter", Cost = 1000, Type = "Coins", Action = "Buy" },
            { Name = "Pyromancer", Cost = 1250, Type = "Coins", Action = "Buy" },
            { Name = "Ace Pilot", Cost = 1500, Type = "Coins", Action = "Buy" },
            { Name = "Farm", Cost = 2000, Type = "Coins", Action = "Buy" },
            { Name = "Medic", Cost = 2000, Type = "Coins", Action = "Buy" },
            { Name = "Rocketeer", Cost = 2500, Type = "Coins", Action = "Buy" },
            { Name = "Electroshocker", Cost = 2500, Type = "Coins", Action = "Buy" },
            { Name = "Trapper", Cost = 3000, Type = "Coins", Action = "Buy" },
            { Name = "Pulse Trooper", Cost = 3250, Type = "Coins", Action = "Buy" },
            { Name = "Commander", Cost = 4000, Type = "Coins", Action = "Buy" },
            { Name = "Military Base", Cost = 4000, Type = "Coins", Action = "Buy" },
            { Name = "DJ Booth", Cost = 5000, Type = "Coins", Action = "Buy" },
            { Name = "Tesla", Cost = 6000, Type = "Coins", Action = "Buy" },
            { Name = "Minigunner", Cost = 8000, Type = "Coins", Action = "Buy" },
            { Name = "Ranger", Cost = 12000, Type = "Coins", Action = "Buy" },
            { Name = "Pursuit", Cost = 15000, Type = "Coins", Action = "Buy", LevelReq = 100 },
            { Name = "Gatling Gun", Cost = 35000, Type = "Coins", Action = "Buy", LevelReq = 175 },
        },
        ["Levels"] = {
            { Name = "Crook Boss", Cost = 0, Type = "Levels", Action = "Claim", LevelReq = 30 },
            { Name = "Turret", Cost = 0, Type = "Levels", Action = "Claim", LevelReq = 50 },
            { Name = "Mortar", Cost = 0, Type = "Levels", Action = "Claim", LevelReq = 75 },
            { Name = "Mercenary Base", Cost = 0, Type = "Levels", Action = "Claim", LevelReq = 150 },
            { Name = "Mercnedary base", Cost = 0, Type = "Levels", Action = "Claim", LevelReq = 150 },
        },
        ["Gems"] = {
            { Name = "Accelerator", Cost = 2500, Type = "Gems", Action = "Buy" },
            { Name = "Brawler", Cost = 1250, Type = "Gems", Action = "Buy" },
            { Name = "Necromancer", Cost = 2250, Type = "Gems", Action = "Buy" },
            { Name = "Engineer", Cost = 4500, Type = "Gems", Action = "Buy" },
            { Name = "Hacker", Cost = 5500, Type = "Gems", Action = "Buy" },
        },
        ["Evo"] = {
            { Name = "EvolvedOperator", Coins = 15000, Gems = 4500, Type = "Evo", Action = "Craft" },
            { Name = "EvolvedEnforcer", Coins = 15000, Gems = 5000, Type = "Evo", Action = "Craft" },
            { Name = "EvolvedKingpin", Coins = 15000, Gems = 5500, Type = "Evo", Action = "Craft" },  
            { Name = "EvolvedJuggernaut", Coins = 15000, Gems = 6000, Type = "Evo", Action = "Craft" },
        },
        ["Golden"] = {
            { Name = "Golden Scout", Cost = 50000, Type = "Golden", Action = "Buy" },
            { Name = "Golden Demoman", Cost = 50000, Type = "Golden", Action = "Buy" },
            { Name = "Golden Soldier", Cost = 50000, Type = "Golden", Action = "Buy" },
            { Name = "Golden Pyromancer", Cost = 50000, Type = "Golden", Action = "Buy" },
            { Name = "Golden Crook Boss", Cost = 50000, Type = "Golden", Action = "Buy" },
            { Name = "Golden Minigunner", Cost = 50000, Type = "Golden", Action = "Buy" },
            { Name = "Golden Cowboy", Cost = 50000, Type = "Golden", Action = "Buy" },
        },
    },

    -- -----------------------------------------------------------------
    -- Skill Tree Priority Upgrade (Late Game Progression)
    -- -----------------------------------------------------------------
    SkillTreePrioUpgrad = {
        NodeIds = {
            1, 2, 3, 4, 5, 6, 7, 8, 9,
            10, 11, 12, 13, 14, 15, 16, 17
        },

        Names = {
            [1] = "Enhanced Optics",
            [2] = "Resourcefulness",
            [3] = "Fortify",
            [4] = "Over-Heal",
            [5] = "Fight Dirty",
            [6] = "Extreme Conditioning",
            [7] = "Stonks",
            [8] = "Expanded Barracks",
            [9] = "Improved Gunpowder",
            [10] = "Beefed Up Minions",
            [11] = "Precision",
            [12] = "Scavenger",
            [13] = "Accelerator",
            [14] = "Re-enforcements",
            [15] = "Bigger Budget",
            [16] = "Bandages",
            [17] = "Scholar"
        },

        Priority = {
            {Id = 2, TargetLevel = 10},
            {Id = 15, TargetLevel = 10},
            {Id = 7, TargetLevel = 10},
            {Id = 13, TargetLevel = 10},
            {Id = 1, TargetLevel = 10},
            {Id = 8, TargetLevel = 10},
            {Id = 9, TargetLevel = 10},
            {Id = 5, TargetLevel = 10},
            {Id = 3, TargetLevel = 10},
            {Id = 4, TargetLevel = 10},
            {Id = 16, TargetLevel = 10},
            {Id = 6, TargetLevel = 10},
            {Id = 10, TargetLevel = 10},
            {Id = 15, TargetLevel = 25},
            {Id = 9, TargetLevel = 25},
            {Id = 10, TargetLevel = 25},
            {Id = 7, TargetLevel = 20},
            {Id = 13, TargetLevel = 25},
            {Id = 1, TargetLevel = 20},
            {Id = 8, TargetLevel = 20},
            {Id = 2, TargetLevel = 25},
            {Id = 5, TargetLevel = 25},
            {Id = 4, TargetLevel = 25},
            {Id = 16, TargetLevel = 25},
            {Id = 6, TargetLevel = 25},
            {Id = 3, TargetLevel = 40},
            {Id = 11, TargetLevel = 15},
            {Id = 17, TargetLevel = 20},
            {Id = 12, TargetLevel = 20},
            {Id = 14, TargetLevel = 10}
        }
    },
}

-- Alias for convenience
Config.SkillTreePrioUpgrade = Config.SkillTreePrioUpgrad

-- Support numeric index indexing: Nodes[0] == Nodes["Node 0"], Nodes[1] == Nodes["Node 1"], Nodes[2] == Nodes["Node 2"], Nodes[3] == Nodes["Node 3"]
Config.Nodes[0] = Config.Nodes["Node 0"]
Config.Nodes[1] = Config.Nodes["Node 1"]
Config.Nodes[2] = Config.Nodes["Node 2"]
Config.Nodes[3] = Config.Nodes["Node 3"]

-- Alias for Claim towers lookup
Config.TowerList["Claim"] = Config.TowerList["Levels"]

return Config
