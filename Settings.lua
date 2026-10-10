--!strict
--==============================================================================
-- [SomethingNew] Settings.lua
-- Pure Progression Configuration Store
--==============================================================================

return {
    
	AutoProgress = {
	
	   ["Node 0"] = {
            TowerToBuy = { "Soldier" }, -- Node 0 goal: Buy Assassin before moving to Node 1
            [1] = {
                Level = 0, -- Level required: 0 or above
                TowersCheck = {},
                TowersToEquip = { },
                TowerToBuy = { "Assassin" },
                StoryMode = { "Boot Camp", "Live Fire", "Breach Protocol", "Brute Force" }, -- Story Missions
                scripts = {
                    ["Boot Camp"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node0/Bootcamp.lua",
                    ["Live Fire"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node0/LiveFire.lua",
                    ["Breach Protocol"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node0/BreachProtocol.lua",
                    ["Brute Force"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node0/BruteForce.lua",
                }
            }
        },
	  ["Node 1"] = {
            TowerToBuy = { "Assassin" }, 
            LevelGoals = 15,
            [1] = {
                Level = 0, -- Level required: 0 or above
                LevelGoals = 15,
                TowersCheck = { "Scout" },
                TowersToEquip = { "Scout" },
                Modes = "Easy", -- Match difficulty / mode
                TowerToBuy = { "Assassin" }, -- Node 1 things to do: Grind coins until Soldier is purchased
                Maps = { "Simplicity", "Meltdown", "Midnight Issue", "Spring Fever", "Stained Temple" }, -- Available Maps
                scripts = {
                    ["Simplicity"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node1/simplicity.lua",
                    ["Meltdown"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node1/meltdown.lua",
                    ["Midnight Issue"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node1/midnight_issue.lua",
                    ["Spring Fever"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node1/spring_fever.lua",
                    ["Stained Temple"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node1/stained_temple.lua",
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
                    ["Lighthaos"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node2/lighthaos.lua",
                    ["Midnight Issue"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node2/midnight_issue.lua",
                    ["Nether"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node2/nether.lua",
                    ["Wrecked Battlefield II"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg-/main/Nodes/Node2/wrecked_battlefield_ii.lua",
                }
            }
        },
	},
	
	AutoCurrency = {
      Coins = {
            Lose = {
                Level_0 = {
                    Level = 0,
                    Mode = "Casual",
                    TowerRequirments = {"Scout", "Sniper"},
                    Towers = {"Scout", "Soldier"},
                    Golden = {},
                    SkillTree = {},
					TowersToBuy = { "Assassin", "Soldier" },
                    Maps = {"Simplicity", "Meltdown", "Midnight Issue", "Spring Fever", "Stained Temple"},
                    Scripts = {
                        ["Simplicity"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/refs/heads/main/Strats/AutoCurrency/Coins/Lose/simplicity.lua",
                        ["Meltdown"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/refs/heads/main/Strats/AutoCurrency/Coins/Lose/meltdown.lua",
						["Midnight Issue"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/refs/heads/main/Strats/AutoCurrency/Coins/Lose/midnight_issue.lua",
                        ["Spring Fever"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/refs/heads/main/Strats/AutoCurrency/Coins/Lose/sprint_fever.lua",
						["Stained Temple"] = "https://raw.githubusercontent.com/Texrtes/-AutoProg--Updated/refs/heads/main/Strats/AutoCurrency/Coins/Lose/stained_temple.lua",
                    },
                },
                Level_15 = {
                    Level = 15,
                    Mode = "Molten",
                    TowerRequirments = {"Assassin", "Soldier"},
                    Towers = {"Assassin", "Soldier"},
                    Golden = {},
                    SkillTree = {},
                    Maps = {"Simplicity", "Winter Abyss"},
                    Scripts = {
                        ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/Simplicity.lua",
                        ["Winter Abyss"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/WinterAbyss.lua",
                    },
                },
            },
            Win = {
                Level = 175,
                Mode = "Fallen",
				TowerRequirments = {"Gatling Gun", "Trapper", "Medic", "Mercenary Base", "Hacker"}, -- towers to check if owned if not well display 
                Towers = {"Gatling Gun", "Trapper", "Medic", "Mercenary Base", "Hacker"},
                Golden = {},
                SkillTree = {},
                Maps = {"Lay By"},
                Modifiers = {
                HiddenEnemies = true, 
                Fog = true, 
                Limitation = true, 
                Committed = false, 
                ExplodingEnemies = true
            },
                Scripts = {
                    ["Lay By"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Fallbacks/FallenLayby.lua", -- done
                },
            },
        },
        Gems = {
            Lose = {
                Level = 50,
                Mode = "hardcore",
                Towers = {"Farm", "Boomerang", "Crook Boss"},
                Golden = {},
                SkillTree = {},
                Maps = {"Wretched Front"},
                Scripts = {
                    ["Wretched Front"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Gems/Lose/WretchedFront.lua", -- done
                },
            },
            Win = {
                Level = 1705,
                Mode = "hardcore",
                Towers = {"Gatling Gun", "Pyromancer", "Medic", "Mercenary Base", "Hacker"},
                Golden = {"Pyromancer"},
                SkillTree = {},
                Maps = {"Wretched Front"},
                Scripts = {
                    ["Wretched Front"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Gems/Lose/WretchedFront.lua", -- done
                },
            },
        },
    },
	AutoLevelsCurrency = "Coins",
	
	
	AutoTimescale = {
    ["Speedy Enemies"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Tesla", "Gatling Gun", "Medic", "Mercenary Base", "Trapper"},
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Speedy.lua", -- done
        }
    },
    ["Glass"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Medic", "Gatling Gun", "Militant", "Mercenary Base", "Trapper"},
			["Tower 2"] = {"Hacker", "Gatling Gun", "Medic", "Mercenary Base", "Trapper"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Glass.lua", --done
			["Tower 2"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Premium/Glass.lua" -- done
        }
    },
    ["Quarantine"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Trapper", "Gatling Gun", "Militant", "Mercenary Base", "Medic"},
			["Tower 2"] = {"Hacker", "Gatling Gun", "Militant", "Mercenary Base", "Medic"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Quarantine.lua", -- done
			["Tower 2"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Premium/Quarantine.lua" -- done
        }
    },
    ["Fog"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Trapper", "Militant", "Gatling Gun", "Mercenary Base", "Medic"},
			["Tower 2"] = {"Trapper", "Hacker", "Gatling Gun", "Mercenary Base", "Medic"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Fog.lua", --done
			["Tower 2"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Premium/Fog.lua" -- done
        }
    },
    ["Limitation"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Trapper", "Medic", "Gatling Gun", "Mercenary Base", "DJ Booth"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Limitation.lua"
        }
    },
    ["Flying Enemies"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Militant", "Gatling Gun", "Medic", "Mercenary Base", "DJ Booth"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Flying.lua"
        }
    },
    ["Jailed"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Assassin", "Scout", "Paintballer", "DJ Booth", "Gatling Gun"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Jailed.lua" -- done
        }
    },
    ["Exploding Enemies"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Militant", "Gatling Gun", "Medic", "Mercenary Base", "Trapper"},
			["Tower 2"] = {"Hacker", "Gatling Gun", "Medic", "Mercenary Base", "Trapper"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Exploading.lua", -- done
			["Tower 2"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Premium/Exploading.lua" --done
        }
    },
    ["Inflation"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Ace Pilot", "Trapper", "Gatling Gun", "Tesla", "Medic"},
			["Tower 2"] = {"Ace Pilot", "Trapper", "Gatling Gun", "Hacker", "Medic"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Inflation.lua", -- done
			["Tower 2"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Premium/Inflation.lua", -- done
        }
    },
    ["Committed"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Hacker", "Gatling Gun", "Medic", "Scout", "Demoman"}
        },
        Golden = {"Scout", "Demoman"},
        SkillTree = {
            ["Bigger Budget"] = 25,
            ["Fortify"] = 40,
            ["Stonks"] = 20,
            ["Over-Heal"] = 25,
            ["Bandages"] = 25,
            ["Accelerator"] = 25,
            ["Enhanced Optics"] = 20,
            ["Scavenger"] = 20,
            ["Improved Gunpowder"] = 25,
            ["Fight Dirty"] = 25,
            ["Precision"] = 15,
            ["Re-enforcements"] = 10,
            ["Extreme Conditioning"] = 25,
        },
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Committed.lua" -- done
        }
    },
    ["Hidden Enemies"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Gatling Gun", "Medic", "Mercenary Base", "Militant", "DJ Booth"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Hidden.lua"
        }
    },
    ["Broke"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Gatling Gun", "Trapper", "Militant", "Mercenary Base", "Medic"},
            ["Tower 2"] = {"Gatling Gun", "Hacker", "Militant", "Mercenary Base", "Medic"}
        },
        Golden = {},
        SkillTree = {},
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Broke.lua", -- done
            ["Tower 2"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Premium/Broke.lua" -- done
        }
    },
    ["Healthy Enemies"] = {
        Level = 175,
        Towers = {
            ["Tower 1"] = {"Ace Pilot", "Mercenary Base", "DJ Booth", "Gatling Gun", "Medic"}
        },
        Golden = {},
        SkillTree = {
            ["Bigger Budget"] = 10,
            ["Fortify"] = 10,
            ["Stonks"] = 10,
            ["Over-Heal"] = 10,
            ["Bandages"] = 10,
            ["Accelerator"] = 10,
            ["Enhanced Optics"] = 10,
            ["Resourcefulness"] = 10,
        },
        scripts = {
            ["Tower 1"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Free/Healthy.lua" -- done
        }
    },
},

	    Fallback = {
        ["Molten"] = {
            Level = 175,
            Towers = {"Gatling Gun", "Trapper", "Medic", "", "Mercenary Base"},
            Golden = {},
            SkillTree = {},
            Maps = {"Lay By"},
             Modifiers = {
                HiddenEnemies = true, 
                Glass = false, 
                Fog = true, 
                Limitation = true, 
                Committed = true, 
                Quarantine = true, 
                ExplodingEnemies = true
            },
            Scripts = {
                ["Lay By"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Fallbacks/MoltenLayby.lua", -- done
            },
        },
        ["Fallen"] = {
            Level = 175,
            Towers = {"Gatling Gun", "Trapper", "Medic", "", "Mercenary Base"},
            Golden = {},
            SkillTree = {},
            Maps = {"Lay By"},
             Modifiers = {
                HiddenEnemies = true, 
                Broke = true, 
                Fog = true, 
                Limitation = true, 
                Committed = true, 
                Quarantine = true, 
                ExplodingEnemies = true
            },
            Scripts = {
                ["Lay By"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Trials/Fallbacks/FallenLayby.lua", --done
            },
        },
    },
	
	
	
	EvoData = {
    ["Scout"] = { Evo = "EvolvedOperator", Coins = 15000, Gems = 4500, Order = 1 },
    ["Shotgunner"] = { Evo = "EvolvedEnforcer", Coins = 15000, Gems = 4750, Order = 2 },
    ["Crook Boss"] = { Evo = "EvolvedKingpin", Coins = 15000, Gems = 5500, Order = 3 },
    ["Minigunner"] = { Evo = "EvolvedJuggernaut", Coins = 15000, Gems = 6000, Order = 4 },
},

AutoEvoConfigs = {
	           Coins = {
            Lose = {
                Level_0 = {
                    Level = 0,
                    Mode = "Casual",
                    TowerRequirments = {"Scout", "Sniper"},
                    Towers = {"Scout", "Soldier"},
                    Golden = {},
                    SkillTree = {},
                    Maps = {"Simplicity", "Winter Abyss"},
                    Scripts = {
                        ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/Simplicity.lua",
                        ["Winter Abyss"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/WinterAbyss.lua",
                    },
                },
                Level_5 = {
                    Level = 5,
                    Mode = "Intermediate",
                    TowerRequirments = {"Scout", "Sniper"},
                    Towers = {"Scout", "Sniper"},
                    Golden = {},
                    SkillTree = {},
                    Maps = {"Simplicity", "Winter Abyss"},
                    Scripts = {
                        ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/Simplicity.lua",
                        ["Winter Abyss"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/WinterAbyss.lua",
                    },
                },
                Level_15 = {
                    Level = 15,
                    Mode = "Molten",
                    TowerRequirments = {"Assassin", "Soldier"},
                    Towers = {"Assassin", "Soldier"},
                    Golden = {},
                    SkillTree = {},
                    Maps = {"Simplicity", "Winter Abyss"},
                    Scripts = {
                        ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/Simplicity.lua",
                        ["Winter Abyss"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/WinterAbyss.lua",
                    },
                },
            },
            Win = {
            Level = 50,
            Mode = "Fallen",
            Golden = {},
            SkillTree = {},
            Maps = {"Lay By"},
			Modifiers = {
                HiddenEnemies = true, 
                Fog = true, 
                Limitation = true, 
                Committed = true, 
                Quarantine = true, 
                ExplodingEnemies = true
            },
            Towers = {
                ["Scout"] = {"Gatling Gun", "Trapper", "Hacker"},
                ["Shotgunner"] = {"Gatling Gun", "Trapper", "Hacker"},
                ["Crook Boss"] = {"Gatling Gun", "Trapper", "Hacker"},
                ["Minigunner"] = {"Gatling Gun", "Trapper", "Hacker"}
            },
            Scripts = {
                ["Scout"] = {
                    ["Lay By"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Coins/Win/Operator.lua",--done
                },
                ["Shotgunner"] = {
                    ["Lay By"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Coins/Win/Enforcer.lua",--done
                },
                ["Crook Boss"] = {
                    ["Lay By"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Coins/Win/Kingpin.lua",--done
                },
                ["Minigunner"] = {
                    ["Lay By"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Coins/Win/Juggernaut.lua",--done
                }
            }
        },
    },
    Gems = {
        Lose = {
            Level = 50,
            Mode = "hardcore",
            Golden = {},
            SkillTree = {},
            Maps = {"Wretched Front"},
            Towers = {
                ["Scout"] = {"Farm", "Boomerang", "Crook Boss"},
                ["Shotgunner"] = {"Farm", "Boomerang", "Crook Boss"},
                ["Crook Boss"] = {"Farm", "Boomerang", "Crook Boss"},
                ["Minigunner"] = {"Farm", "Boomerang", "Crook Boss"}
            },
            Scripts = {
                ["Scout"] = {
                    ["Wretched Front"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Gems/Lose/Operator.lua",--done
                },
                ["Shotgunner"] = {
                    ["Wretched Front"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Gems/Lose/Enforcer.lua",--done
                },
                ["Crook Boss"] = {
                    ["Wretched Front"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Gems/Lose/Kingpin.lua",--done
                },
                ["Minigunner"] = {
                    ["Wretched Front"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Gems/Lose/Juggernaut.lua",--done
                }
            }
        }
    }
},

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

}
