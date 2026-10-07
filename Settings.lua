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
}
