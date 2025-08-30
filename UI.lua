local g=game
local p=g:GetService("Players").LocalPlayer
local cg=g:GetService("CoreGui")
local ts=g:GetService("TweenService")
local ui=g:GetService("UserInputService")
local Http=g:GetService("HttpService")

local twn=TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local c30,c40,c60,wh=Color3.fromRGB(30,30,30),Color3.fromRGB(40,40,40),Color3.fromRGB(60,60,60),Color3.new(1,1,1)
local pad,btnH=UDim.new(0,4),28

for _,v in pairs(cg:GetChildren()) do if v.Name=="[/\/\]" then v:Destroy() end end
local gUI=Instance.new("ScreenGui")
gUI.Name="[/\/\]"; gUI.ResetOnSpawn=false; gUI.Parent=cg

local L = {}
local activeToggles, activeSliders, activeTextboxes, activeKeybinds = {}, {}, {}, {}
local keybindData = {}
local connections = {}
local ConfigName = "MyUIConfig_"..game.PlaceId..".json"

local function ControlId(winTitle, kind, label)
    return tostring(winTitle or "Window").."::"..kind.."::"..tostring(label or "")
end

local function SaveConfig()
    local data={toggles={},sliders={},textboxes={},keybuttons={}}
    for b, meta in pairs(activeToggles) do data.toggles[meta.id]=b.Text:sub(1,3)=="[X]" end
    for f, meta in pairs(activeSliders) do data.sliders[meta.id]=meta.get() end
    for b, meta in pairs(activeTextboxes) do data.textboxes[meta.id]=b.Text end
    for id, key in pairs(keybindData) do if type(key)=="string" and key~="" then data.keybuttons[id]=key end end
    pcall(function() writefile(ConfigName, Http:JSONEncode(data)) end)
end

local function LoadConfig()
    local success, content = pcall(readfile, ConfigName)
    if not success then return end
    local ok, data = pcall(Http.JSONDecode, Http, content)
    if not ok or type(data)~="table" then return end
    for b, meta in pairs(activeToggles) do local st=data.toggles and data.toggles[meta.id] if st~=nil then b.Text=(st and "[X] " or "[ ] ")..meta.label if meta.cb then meta.cb(st) end end end
    for f, meta in pairs(activeSliders) do local val=data.sliders and data.sliders[meta.id] if val~=nil then meta.set(val) end end
    for b, meta in pairs(activeTextboxes) do local txt=data.textboxes and data.textboxes[meta.id] if txt~=nil then b.Text=txt if meta.cb then meta.cb(txt) end end end
    for b, meta in pairs(activeKeybinds) do local saved=data.keybuttons and data.keybuttons[meta.id] local kb=b:FindFirstChild("KeyBind") if saved and kb then kb.Text=saved keybindData[meta.id]=saved b:SetAttribute("LoadedKeyBind", saved) end end
end

local function Cleanup()
    for _,conn in pairs(connections) do if conn and conn.Disconnect then conn:Disconnect() end end
    connections = {}
    activeToggles, activeSliders, activeTextboxes, activeKeybinds = {}, {}, {}, {}
    keybindData = {}
end

-- Expose internals through L so loadstring works
L.gUI = gUI
L.SaveConfig = SaveConfig
L.LoadConfig = LoadConfig
L.Cleanup = Cleanup

-- Window and controls
function L:Window(title,size,pos)
    local winTitle=title or "Window"
    local w=Instance.new("Frame"); w.Size=size or UDim2.new(0,150,0,30); w.Position=pos or UDim2.new(.4,0,.35,0); w.BackgroundColor3=c30; w.Active=true; w.Parent=gUI
    local h=Instance.new("Frame"); h.Size=UDim2.new(1,0,1,0); h.BackgroundColor3=c30; h.Parent=w
    local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1; tl.Text=winTitle; tl.TextColor3=wh; tl.Font=Enum.Font.SourceSansBold; tl.TextSize=14; tl.TextXAlignment,tl.TextYAlignment=Enum.TextXAlignment.Center,Enum.TextYAlignment.Center; tl.Parent=h
    local cb=Instance.new("TextButton"); cb.Size=UDim2.new(0,25,1,0); cb.Position=UDim2.new(1,-25,0,0); cb.Text="+"; cb.TextColor3=wh; cb.TextSize=14; cb.BackgroundTransparency=1; cb.Parent=h
    local cw=Instance.new("Frame"); cw.Size=UDim2.new(1,0,0,0); cw.Position=UDim2.new(0,0,1,0); cw.BackgroundTransparency=1; cw.Parent=w
    local c=Instance.new("Frame"); c.Size=UDim2.new(1,0,0,0); c.BackgroundColor3=c40; c.ClipsDescendants=true; c.Parent=cw
    local padObj=Instance.new("UIPadding"); padObj.PaddingTop,padObj.PaddingBottom,padObj.PaddingLeft,padObj.PaddingRight=pad,pad,pad,pad; padObj.Parent=c
    local lyt=Instance.new("UIListLayout"); lyt.Padding=pad; lyt.FillDirection=Enum.FillDirection.Vertical; lyt.SortOrder=Enum.SortOrder.LayoutOrder; lyt.Parent=c

    local exp=false
    cb.MouseButton1Click:Connect(function()
        exp=not exp; cb.Text=exp and "-" or "+"
        local h2=0
        for _,v in next,c:GetChildren() do
            if v:IsA("GuiObject") and v~=lyt and v~=padObj then
                h2=h2+v.AbsoluteSize.Y+lyt.Padding.Offset
            end
        end
        local tg=exp and UDim2.new(1,0,0,h2+padObj.PaddingTop.Offset+padObj.PaddingBottom.Offset) or UDim2.new(1,0,0,0)
        ts:Create(c,twn,{Size=tg}):Play(); ts:Create(cw,twn,{Size=tg}):Play()
    end)

    local dr,dx,dy,sx,sy=false,0,0,0,0
    h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true; dx,dy=i.Position.X,i.Position.Y; sx,sy=w.Position.X.Offset,w.Position.Y.Offset end end)
    ui.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
    ui.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then w.Position=UDim2.new(w.Position.X.Scale, sx+(i.Position.X-dx), w.Position.Y.Scale, sy+(i.Position.Y-dy)) end end)

    local o={}
    function o:Button(t,cbk) local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,btnH); b.BackgroundColor3=c60; b.Text=t; b.TextColor3=wh; b.Font=Enum.Font.SourceSans; b.TextSize=14; b.TextXAlignment=Enum.TextXAlignment.Center; b.Parent=c; b.MouseButton1Click:Connect(function() if cbk then cbk() end end); return b end
    -- ... add KeyButton, Toggle, Textbox, Slider from original library here ...
    return o
end

return L
