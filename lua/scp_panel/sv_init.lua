local cfg = HYPERCAT.Config
local activeAlert = 0
local lastAlert = 0
local attempts = {}

util.AddNetworkString("scp_alert")
util.AddNetworkString("scp_announce")
util.AddNetworkString("scp_notify")
util.AddNetworkString("scp_logs")

sql.Query([[CREATE TABLE IF NOT EXISTS scp_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type VARCHAR(16),
    steamid VARCHAR(32),
    data TEXT,
    time INTEGER
)]])

local function Log(type, ply, data)
    if not IsValid(ply) then return end
    sql.Query(string.format(
        "INSERT INTO scp_logs (type, steamid, data, time) VALUES (%s, %s, %s, %d)",
        sql.SQLStr(type),
        sql.SQLStr(ply:SteamID()),
        sql.SQLStr(util.TableToJSON(data)),
        os.time()
    ))
end

local function Notify(ply, msg)
    net.Start("scp_notify")
    net.WriteString(msg)
    net.Send(ply)
end

local function CheckAccess(ply)
    if not IsValid(ply) then return false end
    
    local sid = ply:SteamID()
    local time = CurTime()
    
    attempts[sid] = attempts[sid] or {count = 0, reset = time}
    
    if time - attempts[sid].reset > 300 then
        attempts[sid].count = 0
        attempts[sid].reset = time
    end
    
    if attempts[sid].count >= 5 then
        Notify(ply, "Too many attempts. Please wait.")
        return false
    end
    
    attempts[sid].count = attempts[sid].count + 1
    
    if cfg.Access.Groups[ply:GetUserGroup()] then
        Log("access", ply, {type = "group", granted = true})
        hook.Run(HYPERCAT.HOOKS.ACCESS, ply, true)
        return true
    end
    
    if cfg.Access.Jobs[team.GetName(ply:Team())] then
        Log("access", ply, {type = "job", granted = true})
        hook.Run(HYPERCAT.HOOKS.ACCESS, ply, true)
        return true
    end
    
    Log("access", ply, {type = "denied", granted = false})
    hook.Run(HYPERCAT.HOOKS.ACCESS, ply, false)
    return false
end

local function Alert(code, ply)
    if not cfg.Alerts.Codes[code] then return end
    
    activeAlert = code
    lastAlert = CurTime()
    
    net.Start("scp_alert")
    net.WriteUInt(code, 8)
    net.Broadcast()
    
    if code > 0 then
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) then
                p:EmitSound(cfg.Alerts.Sound, 75, 100, cfg.Alerts.Volume, CHAN_STATIC)
            end
        end
    end
    
    local alert = cfg.Alerts.Codes[code]
    local msg = code > 0 and 
        string.format(cfg.Messages.AlertSet, alert.name) or 
        cfg.Messages.AlertClear
    
    PrintMessage(HUD_PRINTTALK, cfg.Messages.Prefix .. msg)
    
    if IsValid(ply) then
        Log("alert", ply, {
            code = code,
            name = alert.name
        })
    end
    
    hook.Run(HYPERCAT.HOOKS.ALERT, code, ply)
end

local function Announce(ply, cat, id, custom)
    local text = custom or cfg.Announcements.Categories[cat][id]
    if not text then return end
    
    net.Start("scp_announce")
    net.WriteString(cat)
    net.WriteString(text)
    net.Broadcast()
    
    PrintMessage(HUD_PRINTTALK, cfg.Messages.Prefix .. string.format(cfg.Messages.Announce, text))
    
    if IsValid(ply) then
        Log("announce", ply, {
            category = cat,
            text = text,
            custom = custom ~= nil
        })
    end
    
    hook.Run(HYPERCAT.HOOKS.ANNOUNCE, cat, text, ply)
end

net.Receive("scp_alert", function(len, ply)
    if not CheckAccess(ply) then
        Notify(ply, cfg.Messages.NoAccess)
        return
    end
    
    if CurTime() - lastAlert < cfg.Alerts.Cooldown then
        Notify(ply, cfg.Messages.Cooldown)
        return
    end
    
    Alert(net.ReadUInt(8), ply)
end)

net.Receive("scp_announce", function(len, ply)
    if not CheckAccess(ply) then
        Notify(ply, cfg.Messages.NoAccess)
        return
    end
    
    local cat = net.ReadString()
    local id = net.ReadUInt(8)
    local custom = net.ReadString()
    
    Announce(ply, cat, id, custom ~= "" and custom or nil)
end)

net.Receive("scp_logs", function(len, ply)
    if not CheckAccess(ply) then
        Notify(ply, cfg.Messages.NoAccess)
        return
    end
    
    local type = net.ReadString()
    local limit = math.Clamp(net.ReadUInt(8), 1, 100)
    
    local query = type ~= "all" and 
        string.format(
            "SELECT * FROM scp_logs WHERE type = %s ORDER BY time DESC LIMIT %d",
            sql.SQLStr(type), limit
        ) or
        string.format(
            "SELECT * FROM scp_logs ORDER BY time DESC LIMIT %d",
            limit
        )
    
    net.Start("scp_logs")
    net.WriteTable(sql.Query(query) or {})
    net.Send(ply)
end)

concommand.Add("scp_alert", function(ply, cmd, args)
    if IsValid(ply) and not CheckAccess(ply) then
        Notify(ply, cfg.Messages.NoAccess)
        return
    end
    Alert(tonumber(args[1]) or 0, ply)
end)

concommand.Add("scp_announce", function(ply, cmd, args)
    if IsValid(ply) and not CheckAccess(ply) then
        Notify(ply, cfg.Messages.NoAccess)
        return
    end
    
    local cat, id, custom = args[1], tonumber(args[2]), args[3]
    if not cat or not id then
        Notify(ply, "Usage: scp_announce <category> <id> [custom_text]")
        return
    end
    
    Announce(ply, cat, id, custom)
end)

hook.Add("PlayerDisconnected", "scp_cleanup", function(ply)
    attempts[ply:SteamID()] = nil
end)

hook.Add("ShutDown", "scp_cleanup", function()
    activeAlert = 0
end) 