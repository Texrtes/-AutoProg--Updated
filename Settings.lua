--!strict
--==============================================================================
-- [SomethingNew] Settings.lua
-- Pure Progression Configuration Store
--==============================================================================

return {
    -- Tier Definitions & Descriptions
    Tiers = {
        Free = {
            Name = "Free",
            Badge = "FREE TIER",
            Summary = "Standard Progression",
            Descriptions = "Unlocks all towers all hardcore towers",
            Features = {
                "Unlocks all towers",
                "Unlocks all hardcore towers",
            },
        },
        Premium = {
            Name = "Premium",
            Badge = "PREMIUM VIP",
            Summary = "Advanced Progression Engine",
            Descriptions = "Offers as the free but better prog",
            Features = {
                "Offers as the free but better prog",
                "Unlock all evo",
                "Unlock all golden skins",
                "Unlock all Skill tree",
                "Unlock Special Towers",
            },
        },
    },

    -- Progression Status & State
    Enabled = false,
    CurrentlyDoing = "Idle",
    Target = "None",
    SelectedTier = "Free", -- "Free" or "Premium"

    -- Tower & Feature Unlock Flags
    UnlocksAllTowers = true,
    UnlocksHardcoreTowers = true,
    BetterProg = false,
    UnlockAllEvo = false,
    UnlockAllGoldenSkins = false,
    UnlockAllSkillTree = false,
    UnlockSpecialTowers = false,

    -- Tuning Configs
    StepDelay = 1.0,
    AutoAdvance = true,
    AutoRetry = true,
    Difficulty = "Normal",
    TargetStage = 100,
	
	AutoCurrency = {
        Coins = {
            Lose = {
                Level = 15, --< level check
                Mode = "Molten", -- Mode
				TowerRequirments = {"Assassin", "Soldier"}, -- towers to check if owned if not well display 
                Towers = {"Assassin", "Soldier"}, -- towers to equip
                Golden = {}, -- < required goldem=n
                SkillTree = {}, -- < reqired skill tree 
                Maps = {"Simplicity", "Winter Abyss"}, --maps to select when ingame map voting 
                Scripts = {
                    ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/Simplicity.lua", -- done
					["Winter Abyss"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Currency/Coins/Lose/WinterAbyss.lua", -- done
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
                Committed = true, 
                Quarantine = true, 
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
            Level = 15,
            Mode = "Molten",
            Golden = {},
            SkillTree = {},
            Maps = {"Simplicity"},
            
            -- You can now customize the Towers for each specific Evo target!
            Towers = {
                ["Scout"] = {"Assassin", "Soldier"},
                ["Shotgunner"] = {"Assassin", "Soldier"},
                ["Crook Boss"] = {"Assassin", "Soldier"},
                ["Minigunner"] = {"Assassin", "Soldier"}
            },
            
            -- Dynamic scripts based on the active tower you are farming
          Scripts = {
                ["Scout"] = {
                    ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Coins/Lose/Operator.lua",--done
                },
                ["Shotgunner"] = {
                    ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Coins/Lose/Enforcer.lua",--done
                },
                ["Crook Boss"] = {
                    ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Coins/Lose/Kingpin.lua",--done
                },
                ["Minigunner"] = {
                    ["Simplicity"] = "https://raw.githubusercontent.com/Atxvy/Main/refs/heads/main/Evo/Coins/Lose/Juggernaut.lua",--done
                }
            }
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
}
