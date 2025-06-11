if SERVER then
    AddCSLuaFile("scp_panel/cl_init.lua")
    AddCSLuaFile("autorun/sh_scp_panel.lua")
end

HYPERCAT = HYPERCAT or {}

HYPERCAT.Config = {
    Access = {
        Groups = {
            ["superadmin"] = true,
            ["admin"] = true,
            ["operator"] = true
        },
        Jobs = {
            ["Site Director"] = true,
            ["Security Chief"] = true,
            ["Senior Researcher"] = true,
            ["Facility Manager"] = true
        }
    },

    Panel = {
        Command = "!codepanel",
        Keybind = KEY_F6,
        Title = "SCP Facility Control Panel"
    },

    Alerts = {
        Cooldown = 3,
        Volume = 0.8,
        Sound = "ambient/alarms/klaxon1.wav",
        Codes = {
            [0] = {name = "Code 0 - All Clear", desc = "Situation resolved", color = Color(40, 167, 69)},
            [1] = {name = "Code 1 - Minor Alert", desc = "Minor incident", color = Color(255, 193, 7)},
            [2] = {name = "Code 2 - Security Alert", desc = "Security breach", color = Color(255, 140, 0)},
            [3] = {name = "Code 3 - Containment Warning", desc = "Containment compromised", color = Color(255, 100, 0)},
            [4] = {name = "Code 4 - Site Emergency", desc = "Major emergency", color = Color(255, 30, 0)},
            [5] = {name = "Code 5 - SCP Breach", desc = "Containment breach", color = Color(255, 0, 0)}
        }
    },

    Emergency = {
        Medical = {
            ["Emergency Medic"] = true,
            ["Field Doctor"] = true
        },
        Security = {
            ["MTF Unit"] = true,
            ["Security Chief"] = true,
            ["Emergency Response"] = true
        }
    },

    Announcements = {
        Categories = {
            ["General"] = {
                "Keep all containment doors closed",
                "Security escorts required for D-Class",
                "Scheduled maintenance in progress",
                "Hazardous materials transport active",
                "Security sweep in progress"
            },
            ["Security"] = {
                "Random inspections in progress",
                "ID verification at all checkpoints",
                "Increased vigilance required"
            },
            ["Medical"] = {
                "Report to medical if exposed",
                "Mandatory health screenings today",
                "Possible contamination detected"
            }
        }
    },

    UI = {
        Text = Color(200, 200, 200),
        TextDim = Color(150, 150, 150),
        Background = Color(35, 39, 43),
        BackgroundLight = Color(40, 44, 48),
        ButtonNormal = Color(45, 49, 53),
        ButtonHover = Color(50, 54, 58)
    },

    Messages = {
        Prefix = "[SCP] ",
        NoAccess = "Access denied: Insufficient clearance",
        Cooldown = "Please wait before issuing another alert",
        AlertSet = "Alert status changed: %s",
        AlertClear = "Alert status cleared",
        Announce = "%s"
    }
}

HYPERCAT.HOOKS = {
    ALERT = "SCP_AlertChanged",
    ANNOUNCE = "SCP_AnnouncementMade",
    ACCESS = "SCP_AccessChanged"
}

if SERVER then
    include("scp_panel/sv_init.lua")
else
    include("scp_panel/cl_init.lua")
end 