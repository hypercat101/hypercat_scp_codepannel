local cfg = HYPERCAT.Config
local frame
local alert
local active = 0

local PANEL = {}

function PANEL:CreateButton(parent, text, fn)
    local btn = parent:Add("DButton")
    btn:Dock(TOP)
    btn:SetTall(40)
    btn:DockMargin(0, 0, 0, 5)
    btn:SetText("")
    
    function btn:Paint(w, h)
        surface.SetDrawColor(self:IsHovered() and cfg.UI.ButtonHover or cfg.UI.ButtonNormal)
        surface.DrawRect(0, 0, w, h)
        draw.SimpleText(text, "Trebuchet18", 10, h/2, cfg.UI.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    
    function btn:DoClick()
        surface.PlaySound("buttons/button9.wav")
        fn()
    end
    
    return btn
end

function PANEL:CreateAlertButtons(scroll)
    for code, data in SortedPairs(cfg.Alerts.Codes) do
        local btn = scroll:Add("DButton")
        btn:Dock(TOP)
        btn:SetTall(50)
        btn:DockMargin(0, 0, 0, 5)
        btn:SetText("")
        
        function btn:Paint(w, h)
            surface.SetDrawColor(self:IsHovered() and cfg.UI.ButtonHover or cfg.UI.ButtonNormal)
            surface.DrawRect(0, 0, w, h)
            draw.SimpleText(data.name, "Trebuchet24", 10, h/2 - 8, cfg.UI.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(data.desc, "Trebuchet18", 10, h/2 + 8, cfg.UI.TextDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        function btn:DoClick()
            surface.PlaySound("buttons/button9.wav")
            net.Start("scp_alert")
            net.WriteUInt(code, 8)
            net.SendToServer()
        end
    end
end

function PANEL:CreateAnnouncementTab(cat, items)
    local tab = vgui.Create("DPanel")
    function tab:Paint(w, h)
        surface.SetDrawColor(cfg.UI.Background)
        surface.DrawRect(0, 0, w, h)
    end
    
    local scroll = tab:Add("DScrollPanel")
    scroll:Dock(FILL)
    scroll:DockMargin(5, 5, 5, 5)
    
    for id, text in ipairs(items) do
        self:CreateButton(scroll, text, function()
            net.Start("scp_announce")
            net.WriteString(cat)
            net.WriteUInt(id, 8)
            net.WriteString("")
            net.SendToServer()
        end)
    end
    
    return tab
end

function PANEL:Init()
    self:SetSize(800, 600)
    self:Center()
    self:SetTitle(cfg.Panel.Title)
    self:ShowCloseButton(true)
    self:SetDraggable(true)
    
    local container = self:Add("DPanel")
    container:Dock(FILL)
    container:DockMargin(5, 5, 5, 5)
    function container:Paint(w, h) end
    
    local left = container:Add("DPanel")
    left:Dock(LEFT)
    left:SetWide(380)
    left:DockMargin(0, 0, 5, 0)
    function left:Paint(w, h)
        surface.SetDrawColor(cfg.UI.BackgroundLight)
        surface.DrawRect(0, 0, w, h)
    end
    
    local alertLabel = left:Add("DLabel")
    alertLabel:Dock(TOP)
    alertLabel:SetTall(30)
    alertLabel:SetText("Alert Codes")
    alertLabel:SetTextColor(cfg.UI.Text)
    alertLabel:SetFont("Trebuchet24")
    alertLabel:DockMargin(10, 5, 5, 5)
    
    local alertScroll = left:Add("DScrollPanel")
    alertScroll:Dock(FILL)
    alertScroll:DockMargin(5, 5, 5, 5)
    
    self:CreateAlertButtons(alertScroll)
    
    local right = container:Add("DPanel")
    right:Dock(FILL)
    function right:Paint(w, h)
        surface.SetDrawColor(cfg.UI.BackgroundLight)
        surface.DrawRect(0, 0, w, h)
    end
    
    local announceLabel = right:Add("DLabel")
    announceLabel:Dock(TOP)
    announceLabel:SetTall(30)
    announceLabel:SetText("Announcements")
    announceLabel:SetTextColor(cfg.UI.Text)
    announceLabel:SetFont("Trebuchet24")
    announceLabel:DockMargin(10, 5, 5, 5)
    
    local tabs = right:Add("DPropertySheet")
    tabs:Dock(FILL)
    tabs:DockMargin(5, 5, 5, 5)
    
    for cat, items in pairs(cfg.Announcements.Categories) do
        tabs:AddSheet(cat, self:CreateAnnouncementTab(cat, items))
    end
end

function PANEL:Paint(w, h)
    Derma_DrawBackgroundBlur(self)
    surface.SetDrawColor(cfg.UI.Background)
    surface.DrawRect(0, 0, w, h)
end

vgui.Register("scp_panel", PANEL, "DFrame")

local function CreateNewAlert()
    alert = vgui.Create("DPanel")
    alert:SetSize(ScrW(), 40)
    alert:SetPos(0, ScrH() - 40)
    alert:SetAlpha(0)
    alert:AlphaTo(255, 0.5, 0)
    
    local lastText = ""
    
    function alert:Paint(w, h)
        local data = cfg.Alerts.Codes[active]
        if not data then return end
        
        local text = data.name .. " - " .. data.desc
        if text ~= lastText then
            lastText = text
            surface.SetFont("Trebuchet24")
            local tw, _ = surface.GetTextSize(text)
            self.textX = w/2 - tw/2
        end
        
        draw.SimpleText(text, "Trebuchet24", self.textX, h/2, cfg.UI.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

local function CreateAlert()
    if IsValid(alert) then 
        alert:AlphaTo(0, 0.3, 0, function()
            if IsValid(alert) then alert:Remove() end
            CreateNewAlert()
        end)
        return
    end
    CreateNewAlert()
end

local function UpdateAlert(code)
    if active == code then return end
    active = code
    
    if IsValid(alert) then
        alert:AlphaTo(0, 0.3, 0, function()
            if IsValid(alert) then alert:Remove() end
            if code > 0 then CreateAlert() end
        end)
    elseif code > 0 then
        CreateAlert()
    end
end

net.Receive("scp_alert", function()
    UpdateAlert(net.ReadUInt(8))
end)

net.Receive("scp_announce", function()
    local cat = net.ReadString()
    local text = net.ReadString()
    chat.AddText(Color(255, 170, 0), cfg.Messages.Prefix, cfg.UI.Text, text)
end)

net.Receive("scp_notify", function()
    notification.AddLegacy(net.ReadString(), NOTIFY_GENERIC, 4)
end)

hook.Add("OnPlayerChat", "scp_cmd", function(ply, text)
    if not IsValid(ply) or ply ~= LocalPlayer() or text:lower() ~= cfg.Panel.Command then return end
    
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("scp_panel")
    frame:MakePopup()
    
    return true
end)

local keyDown = false
hook.Add("Think", "scp_key", function()
    if input.IsKeyDown(cfg.Panel.Keybind) then
        if not keyDown then
            keyDown = true
            if IsValid(frame) then frame:Remove() end
            frame = vgui.Create("scp_panel")
            frame:MakePopup()
        end
    else
        keyDown = false
    end
end)

hook.Add("ShutDown", "scp_cleanup", function()
    if IsValid(alert) then alert:Remove() end
    if IsValid(frame) then frame:Remove() end
end) 