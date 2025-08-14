--// FloatingTabs (CoreGui, single-file, HttpGet-friendly)
--// Features: Floating draggable tabs with +/- collapse, hardcoded Settings dropdown (Rename, Title/Background colors, Auto-Darker toggle, Font size),
--// Elements: Sections, Labels, Separators, Buttons, Toggles, Sliders, Dropdowns, Textboxes, Keybinds (standalone or bound to button/toggle).
--// Public API: Library:CreateTab(name, options); Section:AddLabel/AddSeparator/AddButton/AddToggle/AddSlider/AddDropdown/AddTextbox/AddKeybind
--// Keybinds: standalone callback OR bind to a button/toggle handle (so the same action fires). Click keybind box to listen to next key.

--==================================================
-- Setup & Utils (compact)
--==================================================
local CoreGui             = game:GetService("CoreGui")
local UIS                 = game:GetService("UserInputService")
local TS                  = game:GetService("TweenService")

local SG = Instance.new("ScreenGui")
SG.Name = "FloatingTabs_Library"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Global
SG.Parent = CoreGui

local Z, functionZ = 50, function() Z += 10; return Z end
local function tween(o,t,props) TS:Create(o, TweenInfo.new(t or .15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() end
local function round(o,r) local c=Instance.new("UICorner"); c.CornerRadius = UDim.new(0,r or 10); c.Parent=o end
local function pad(o,p) local a=Instance.new("UIPadding"); a.PaddingTop,a.PaddingBottom,a.PaddingLeft,a.PaddingRight=UDim.new(0,p),UDim.new(0,p),UDim.new(0,p),UDim.new(0,p); a.Parent=o end
local function vlist(o,g) local l=Instance.new("UIListLayout"); l.Padding=UDim.new(0,g or 6); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=o return l end
local function text(parent, str, size, color, left)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Gotham
	t.Text = str or ""
	t.TextSize = size or 14
	t.TextColor3 = color or Color3.fromRGB(230,235,245)
	t.TextXAlignment = left and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
	t.Parent = parent
	return t
end
local function button(parent, str, size)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = Color3.fromRGB(38,42,50)
	b.Font = Enum.Font.Gotham
	b.Text = str or "Button"
	b.TextSize = size or 14
	b.TextColor3 = Color3.fromRGB(230,235,245)
	round(b, 8); b.Parent = parent
	return b
end
local function shadow(parent, alpha)
	local s=Instance.new("ImageLabel"); s.BackgroundTransparency=1; s.Image="rbxassetid://5028857084"; s.ImageTransparency=alpha or .25
	s.ScaleType=Enum.ScaleType.Slice; s.SliceCenter=Rect.new(24,24,276,276); s.Size=UDim2.new(1,30,1,30); s.Position=UDim2.fromOffset(-15,-15); s.ZIndex=0; s.Parent=parent
end
local function makeDraggable(frame, handle)
	handle = handle or frame
	local drag=false, start, startPos
	local function update(input)
		local d = input.Position - start
		frame.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
	end
	handle.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			drag=true; start=i.Position; startPos=frame.Position; frame.ZIndex=functionZ()
			i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i) end
	end)
end

-- Color parsing & helpers
local function clamp01(x) return math.clamp(x,0,1) end
local function parseHex(h)
	h = h:gsub("#","")
	if #h==3 then
		local r=tonumber(h:sub(1,1)..h:sub(1,1),16)
		local g=tonumber(h:sub(2,2)..h:sub(2,2),16)
		local b=tonumber(h:sub(3,3)..h:sub(3,3),16)
		return Color3.fromRGB(r,g,b)
	elseif #h==6 then
		local r=tonumber(h:sub(1,2),16); local g=tonumber(h:sub(3,4),16); local b=tonumber(h:sub(5,6),16)
		return Color3.fromRGB(r,g,b)
	end
end
local function parseRGB(s)
	local r,g,b = s:match("RGB%((%d+)%s*,%s*(%d+)%s*,%s*(%d+)%)")
	if r and g and b then return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)) end
end
local function parseColor(s)
	if not s or s=="" then return nil end
	s = s:upper()
	return parseHex(s) or parseRGB(s)
end
local function darker(c, factor) -- factor in [0,1], 0.2 -> 20% darker
	factor = factor or 0.18
	local r,g,b = c.R*(1-factor), c.G*(1-factor), c.B*(1-factor)
	return Color3.new(clamp01(r),clamp01(g),clamp01(b))
end

--==================================================
-- Library
--==================================================
local Theme = {
	BG      = Color3.fromRGB(24,27,33),
	Panel   = Color3.fromRGB(32,36,44),
	Line    = Color3.fromRGB(55,60,70),
	Text    = Color3.fromRGB(230,235,245),
	Accent  = Color3.fromRGB(90,150,255),
	Good    = Color3.fromRGB(85,205,120),
	Bad     = Color3.fromRGB(240,75,95)
}

local Library = {}; Library.__index = Library

--==================================================
-- CreateTab
--==================================================
function Library:CreateTab(tabName, opts)
	opts = opts or {}
	local name = tostring(tabName or "Tab")
	local root = Instance.new("Frame")
	root.Name = "Tab_"..name
	root.BackgroundColor3 = Theme.BG
	root.Size = opts.Size or UDim2.fromOffset(340, 280)
	root.Position = opts.Position or UDim2.fromOffset(80, 80)
	root.BorderSizePixel = 0
	root.Active = true
	root.Visible = true
	root.ZIndex = functionZ()
	round(root, 12); root.Parent = SG; shadow(root, .35)

	-- Title bar
	local bar = Instance.new("Frame")
	bar.Name = "TopBar"
	bar.BackgroundColor3 = Theme.Panel
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(1, 0, 0, 36)
	bar.ZIndex = root.ZIndex + 1
	round(bar, 12); bar.Parent = root

	local title = text(bar, name, 16, Theme.Text, true)
	title.Size = UDim2.new(1, -90, 1, 0); title.Position = UDim2.fromOffset(12,0); title.ZIndex = bar.ZIndex + 1

	local toggleBtn = button(bar, "−", 18)
	toggleBtn.Size = UDim2.fromOffset(32, 26)
	toggleBtn.Position = UDim2.new(1, -38, 0.5, -13)
	toggleBtn.ZIndex = bar.ZIndex + 2

	-- Content
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundColor3 = Theme.BG
	content.BorderSizePixel = 0
	content.Position = UDim2.fromOffset(10, 46)
	content.Size = UDim2.new(1, -20, 1, -56)
	content.ZIndex = root.ZIndex + 2
	round(content, 10); content.Parent = root

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Active = true
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.Size = UDim2.fromScale(1,1)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.ZIndex = content.ZIndex + 1
	scroll.Parent = content
	vlist(scroll, 8)

	makeDraggable(root, bar)

	local open = (opts.StartOpen ~= false)
	local function setOpen(state, anim)
		open = state; local t=state and UDim2.new(1,-20,1,-56) or UDim2.new(1,-20,0,0)
		if anim then tween(content,.18,{Size=t}) else content.Size=t end
		toggleBtn.Text = state and "−" or "+"
	end
	setOpen(open,false)
	toggleBtn.MouseButton1Click:Connect(function() setOpen(not open,true) end)

	-- simple factory helpers for rows/elements
	local order=0; local function nextOrder() order+=1; return order end
	local function makeRow(height)
		local row=Instance.new("Frame")
		row.BackgroundColor3 = Theme.Panel
		row.BorderSizePixel=0
		row.Size=UDim2.new(1,0,0,height or 36)
		row.LayoutOrder=nextOrder()
		row.AutomaticSize = Enum.AutomaticSize.None
		row.ZIndex = scroll.ZIndex + 1
		round(row, 8); pad(row,8); row.Parent=scroll
		return row
	end
	local function leftRight(row, labelText)
		local L = text(row, labelText or "", 14, Theme.Text, true)
		L.Size = UDim2.new(1, -160, 1, 0)
		local R = Instance.new("Frame"); R.BackgroundTransparency=1; R.Size=UDim2.new(0,150,1,0); R.Position=UDim2.new(1,-150,0,0); R.Parent=row
		return L,R
	end

	-- Section API
	local Section = {}; Section.__index = Section
	function Section:AddLabel(str)
		local row = makeRow(28); local t = text(row, tostring(str), 14, Theme.Text, true); t.Size = UDim2.new(1,0,1,0); return t
	end
	function Section:AddSeparator()
		local sep = Instance.new("Frame"); sep.BackgroundColor3=Theme.Line; sep.BorderSizePixel=0; sep.Size=UDim2.new(1,0,0,1); sep.LayoutOrder=nextOrder(); sep.Parent=scroll; return sep
	end
	function Section:AddButton(lbl, callback)
		local row = makeRow(36); leftRight(row, lbl)
		local b = button(row, tostring(lbl), 14); b.Size=UDim2.new(0,150,1,-10); b.Position=UDim2.new(1,-160,0,5)
		b.MouseButton1Click:Connect(function()
			tween(b,.08,{BackgroundColor3=Theme.Accent}); task.delay(.12,function() tween(b,.15,{BackgroundColor3=Theme.Panel}) end)
			if typeof(callback)=="function" then task.spawn(callback) end
		end)
		local handle = {
			Instance = b,
			Fire = function() b:ReleaseCapture(); if typeof(callback)=="function" then task.spawn(callback) end end,
			BindKey = function(_, kc) Keybinds:Attach(kc, function() handle.Fire() end) end
		}
		return handle
	end
	function Section:AddToggle(lbl, default, callback)
		local state = default and true or false
		local row = makeRow(36); leftRight(row, lbl)
		local R = row:FindFirstChildOfClass("Frame")
		local tgl = Instance.new("Frame"); tgl.BackgroundColor3=Theme.BG; tgl.Size=UDim2.fromOffset(46,24); tgl.Parent=R; round(tgl,12)
		local knob = Instance.new("Frame"); knob.BackgroundColor3 = state and Theme.Good or Theme.Bad; knob.Size=UDim2.fromOffset(20,20)
		knob.Position = state and UDim2.fromOffset(24,2) or UDim2.fromOffset(2,2); knob.Parent=tgl; round(knob,10)
		local function set(v, fire)
			state = v and true or false
			tween(knob,.12,{Position=state and UDim2.fromOffset(24,2) or UDim2.fromOffset(2,2), BackgroundColor3 = state and Theme.Good or Theme.Bad})
			if fire and typeof(callback)=="function" then task.spawn(callback, state) end
		end
		tgl.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then set(not state, true) end
		end)
		if typeof(callback)=="function" then task.defer(callback, state) end
		local handle = {
			Instance = tgl,
			Get = function() return state end,
			Set = function(_,v) set(v,true) end,
			BindKey = function(_, kc) Keybinds:Attach(kc, function() set(not state, true) end) end
		}
		return handle
	end
	function Section:AddSlider(lbl, min, max, default, callback)
		min=tonumber(min) or 0; max=tonumber(max) or 100
		local val = math.clamp(tonumber(default) or min, min, max)
		local row = makeRow(40)
		local LT,RT = leftRight(row, string.format("%s  <font color=\"#B4BAC4\">(%s)</font>", tostring(lbl), tostring(val)))
		LT.RichText=true
		local bar = Instance.new("Frame"); bar.BackgroundColor3=Theme.BG; bar.Size=UDim2.new(1,0,0,8); bar.Position=UDim2.new(0,0,.5,-4); bar.Parent=RT; round(bar,6)
		local fill=Instance.new("Frame"); fill.BackgroundColor3=Theme.Accent; fill.Size=UDim2.new((val-min)/(max-min),0,1,0); fill.Parent=bar; round(fill,6)
		local dragging=false
		local function setFrom(px, fire)
			local ax, w = bar.AbsolutePosition.X, bar.AbsoluteSize.X
			local a = math.clamp((px-ax)/math.max(1,w),0,1)
			val = math.floor(min + a*(max-min) + .5)
			fill.Size = UDim2.new((val-min)/(max-min),0,1,0)
			LT.Text = string.format("%s  <font color=\"#B4BAC4\">(%s)</font>", tostring(lbl), tostring(val))
			if fire and typeof(callback)=="function" then task.spawn(callback,val) end
		end
		bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; setFrom(i.Position.X,true) end end)
		UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then setFrom(i.Position.X,true) end end)
		UIS.InputEnded:Connect(function() dragging=false end)
		if typeof(callback)=="function" then task.defer(callback,val) end
		return {
			Set=function(_,v) v=math.clamp(tonumber(v) or val,min,max); val=v; fill.Size=UDim2.new((val-min)/(max-min),0,1,0); LT.Text=string.format("%s  <font color=\"#B4BAC4\">(%s)</font>", tostring(lbl), tostring(val)); if typeof(callback)=="function" then task.spawn(callback,val) end end,
			Get=function() return val end,
			Instance=bar
		}
	end
	function Section:AddDropdown(lbl, items, default, callback)
		items = items or {}
		local cur = default or (items[1] or "")
		local row = makeRow(36)
		local LT,RT = leftRight(row, string.format("%s  <font color=\"#B4BAC4\">(%s)</font>", tostring(lbl), tostring(cur)))
		LT.RichText=true
		local dropBtn = button(RT, tostring(cur), 14); dropBtn.Size=UDim2.new(1,0,1,-10); dropBtn.Position=UDim2.fromOffset(0,5)
		local list = Instance.new("Frame"); list.BackgroundColor3=Theme.Panel; list.BorderSizePixel=0; list.Size=UDim2.new(1,0,0,0); list.Position=UDim2.new(0,0,1,4)
		list.ClipsDescendants=true; list.Visible=false; list.ZIndex=RT.ZIndex+50; round(list,8); pad(list,6); list.Parent=RT; vlist(list,4)
		local function rebuild()
			for _,c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			for _,it in ipairs(items) do
				local opt=button(list, tostring(it), 14); opt.Size=UDim2.new(1,-4,0,26)
				opt.MouseButton1Click:Connect(function()
					cur=it; dropBtn.Text=tostring(it); LT.Text=string.format("%s  <font color=\"#B4BAC4\">(%s)</font>", tostring(lbl), tostring(cur))
					if typeof(callback)=="function" then task.spawn(callback,cur) end
					tween(list,.12,{Size=UDim2.new(1,0,0,0)}); task.delay(.13,function() list.Visible=false end)
				end)
			end
		end
		rebuild()
		local openList=false
		dropBtn.MouseButton1Click:Connect(function()
			openList = not openList
			if openList then
				list.Visible=true; local count=math.clamp(#items,1,6); tween(list,.12,{Size=UDim2.new(1,0,0,count*30+6)})
			else tween(list,.12,{Size=UDim2.new(1,0,0,0)}); task.delay(.13,function() list.Visible=false end) end
		end)
		return {
			SetList=function(_,new) items=new or {}; rebuild() end,
			Set=function(_,v) if table.find(items,v) then cur=v; dropBtn.Text=tostring(v); LT.Text=string.format("%s  <font color=\"#B4BAC4\">(%s)</font>", tostring(lbl), tostring(cur)); if typeof(callback)=="function" then task.spawn(callback,cur) end end end,
			Get=function() return cur end,
			Instance=list
		}
	end
	function Section:AddTextbox(lbl, placeholder, callback)
		local row = makeRow(36); leftRight(row, lbl)
		local box = Instance.new("TextBox"); box.BackgroundColor3=Theme.BG; box.PlaceholderText=placeholder or ""; box.Text=""; box.TextColor3=Theme.Text; box.TextSize=14; box.Font=Enum.Font.Gotham
		box.Size=UDim2.new(0,150,1,-10); box.Position=UDim2.new(1,-160,0,5); round(box,8); box.Parent=row
		box.FocusLost:Connect(function(enter) if typeof(callback)=="function" then task.spawn(callback, box.Text, enter) end end)
		return {Instance=box, Get=function() return box.Text end, Set=function(_,v) box.Text=tostring(v or "") end}
	end

	-- Keybind manager (per tab)
	local Keybinds = { _map = {} }
	function Keybinds:Attach(kc, fn)
		if typeof(kc)~="EnumItem" then return end
		self._map[kc] = self._map[kc] or {}
		table.insert(self._map[kc], fn)
	end
	function Keybinds:Detach(kc)
		self._map[kc] = nil
	end
	local listeningBox = nil
	UIS.InputBegan:Connect(function(i,gp)
		if gp then return end
		if listeningBox and i.KeyCode and i.KeyCode ~= Enum.KeyCode.Unknown then
			local box = listeningBox; listeningBox = nil
			box.Text = i.KeyCode.Name
			box:_apply(i.KeyCode, true)
			return
		end
		if i.KeyCode and i.KeyCode ~= Enum.KeyCode.Unknown then
			local arr = Keybinds._map[i.KeyCode]; if arr then for _,fn in ipairs(arr) do task.spawn(fn) end end
		end
	end)

	-- Standalone/Bound Keybind element
	function Section:AddKeybind(lbl, defaultKeyCode, callbackOrHandle)
		local row = makeRow(36); leftRight(row, lbl)
		local R = row:FindFirstChildOfClass("Frame")
		local bindBtn = button(R, (defaultKeyCode and defaultKeyCode.Name) or "Set Key", 14); bindBtn.Size=UDim2.new(1,0,1,-10); bindBtn.Position=UDim2.fromOffset(0,5)
		local current = defaultKeyCode
		local function fire()
			if typeof(callbackOrHandle)=="function" then
				task.spawn(callbackOrHandle, current, "fired")
			elseif type(callbackOrHandle)=="table" and callbackOrHandle.Fire then
				callbackOrHandle.Fire()
			elseif type(callbackOrHandle)=="table" and callbackOrHandle.Set then -- toggle handle
				callbackOrHandle.Set(callbackOrHandle, not callbackOrHandle.Get())
			end
		end
		function bindBtn:_apply(kc, fireRebound)
			if current then Keybinds:Detach(current) end
			current = kc
			if kc then Keybinds:Attach(kc, fire) end
			if fireRebound and typeof(callbackOrHandle)=="function" then task.spawn(callbackOrHandle, current) end
		end
		if defaultKeyCode then bindBtn:_apply(defaultKeyCode, false) end
		bindBtn.MouseButton1Click:Connect(function()
			bindBtn.Text = "Press a key..."
			listeningBox = bindBtn
		end)
		return {
			Set=function(_, kc) bindBtn.Text = kc and kc.Name or "Set Key"; bindBtn:_apply(kc, true) end,
			Get=function() return current end,
			Button=bindBtn
		}
	end

	-- Public: add sections
	local TabAPI = {}; TabAPI.__index=TabAPI
	function TabAPI:AddSection(header)
		if header and header~="" then
			local h = makeRow(30); local t=text(h, tostring(header), 15, Theme.Text, true); t.Size=UDim2.new(1,0,1,0); t.FontFace.Weight=Enum.FontWeight.Bold
		end
		return setmetatable({}, Section)
	end

	--==================================================
	-- Hardcoded Settings dropdown (end of every tab)
	--==================================================
	local function settingsBlock()
		local row = makeRow(40)
		local L,R = leftRight(row, "Settings")
		L.FontFace.Weight = Enum.FontWeight.Bold
		local openBtn = button(R, "Open", 14); openBtn.Size=UDim2.new(1,0,1,-10); openBtn.Position=UDim2.fromOffset(0,5)

		local panel = Instance.new("Frame")
		panel.BackgroundColor3 = Theme.Panel; panel.BorderSizePixel=0; panel.Size=UDim2.new(1,0,0,0); panel.ClipsDescendants=true
		panel.LayoutOrder = nextOrder(); panel.ZIndex = row.ZIndex + 1
		round(panel, 8); pad(panel, 8); panel.Parent = scroll
		vlist(panel, 6)

		local function rowLine(lbl)
			local f=Instance.new("Frame"); f.BackgroundColor3=Theme.BG; f.Size=UDim2.new(1,0,0,34); f.ZIndex=panel.ZIndex+1
			round(f,8); pad(f,6); f.Parent=panel
			local l=text(f, lbl, 14, Theme.Text, true); l.Size=UDim2.new(1,-170,1,0)
			local r=Instance.new("Frame"); r.BackgroundTransparency=1; r.Size=UDim2.new(0,160,1,0); r.Position=UDim2.new(1,-160,0,0); r.Parent=f
			return f,l,r
		end

		-- Rename
		do
			local _,_,r = rowLine("Rename Tab")
			local box = Instance.new("TextBox"); box.BackgroundColor3=Theme.BG; box.PlaceholderText=name; box.Text=""; box.TextColor3=Theme.Text; box.TextSize=14; box.Font=Enum.Font.Gotham
			box.Size=UDim2.new(1,-60,1,-10); box.Position=UDim2.fromOffset(0,5); round(box,8); box.Parent=r
			local set = button(r,"Set",14); set.Size=UDim2.new(0,54,1,-10); set.Position=UDim2.new(1,-54,0,5)
			set.MouseButton1Click:Connect(function()
				if box.Text~="" then name=box.Text; title.Text=name; box.PlaceholderText=name; box.Text="" end
			end)
		end

		-- Title Color
		local titleColor = bar.BackgroundColor3
		do
			local _,_,r = rowLine("Title Color (HEX or RGB)")
			local box = Instance.new("TextBox"); box.BackgroundColor3=Theme.BG; box.PlaceholderText="#5A96FF"; box.Text=""; box.TextColor3=Theme.Text; box.TextSize=14; box.Font=Enum.Font.Gotham
			box.Size=UDim2.new(1,-60,1,-10); box.Position=UDim2.fromOffset(0,5); round(box,8); box.Parent=r
			local set = button(r,"Set",14); set.Size=UDim2.new(0,54,1,-10); set.Position=UDim2.new(1,-54,0,5)
			set.MouseButton1Click:Connect(function()
				local c = parseColor(box.Text); if c then titleColor = c; bar.BackgroundColor3=c; toggleBtn.BackgroundColor3=Theme.Panel; box.Text="" end
				if autoDark then local bg = darker(titleColor, .2); root.BackgroundColor3=bg; content.BackgroundColor3=bg end
			end)
		end

		-- Background Color (+ Auto-Darker toggle)
		local _,_,rLine = rowLine("Auto-Darker Background")
		local autoToggle = Instance.new("Frame"); autoToggle.BackgroundColor3=Theme.BG; autoToggle.Size=UDim2.fromOffset(46,24); autoToggle.Parent=rLine; autoToggle.Position=UDim2.fromOffset(0,5); round(autoToggle,12)
		local autoKnob = Instance.new("Frame"); round(autoKnob,10); autoKnob.Size=UDim2.fromOffset(20,20); autoKnob.Parent=autoToggle
		local autoDark = true
		local function autoSet(v)
			autoDark = v
			autoKnob.Position = v and UDim2.fromOffset(24,2) or UDim2.fromOffset(2,2)
			autoKnob.BackgroundColor3 = v and Theme.Good or Theme.Bad
		end
		autoSet(true)
		autoToggle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then autoSet(not autoDark) bgRowInteract() end end)

		local bgRow,_,bgRight = rowLine("Background Color (HEX or RGB)")
		local bgBox = Instance.new("TextBox"); bgBox.BackgroundColor3=Theme.BG; bgBox.PlaceholderText="#1E222A"; bgBox.Text=""; bgBox.TextColor3=Theme.Text; bgBox.TextSize=14; bgBox.Font=Enum.Font.Gotham
		bgBox.Size=UDim2.new(1,-60,1,-10); bgBox.Position=UDim2.fromOffset(0,5); round(bgBox,8); bgBox.Parent=bgRight
		local bgSet = button(bgRight,"Set",14); bgSet.Size=UDim2.new(0,54,1,-10); bgSet.Position=UDim2.new(1,-54,0,5)

		local function bgRowInteract()
			local disabled = autoDark
			bgBox.TextEditable = not disabled
			bgBox.Active = not disabled
			bgBox.BackgroundColor3 = disabled and Color3.fromRGB(40,44,52) or Theme.BG
			bgSet.AutoButtonColor = not disabled
			bgSet.BackgroundColor3 = disabled and Color3.fromRGB(45,49,58) or Color3.fromRGB(38,42,50)
			if autoDark then
				local bg = darker(titleColor, .2); root.BackgroundColor3=bg; content.BackgroundColor3=bg
			end
		end
		bgRowInteract()

		bgSet.MouseButton1Click:Connect(function()
			if autoDark then return end
			local c = parseColor(bgBox.Text); if c then root.BackgroundColor3=c; content.BackgroundColor3=c; bgBox.Text="" end
		end)

		-- Font Size (title)
		do
			local _,_,r = rowLine("Title Font Size")
			local box = Instance.new("TextBox"); box.BackgroundColor3=Theme.BG; box.PlaceholderText=tostring(title.TextSize); box.Text=""; box.TextColor3=Theme.Text; box.TextSize=14; box.Font=Enum.Font.Gotham
			box.Size=UDim2.new(1,-60,1,-10); box.Position=UDim2.fromOffset(0,5); round(box,8); box.Parent=r
			local set = button(r,"Set",14); set.Size=UDim2.new(0,54,1,-10); set.Position=UDim2.new(1,-54,0,5)
			set.MouseButton1Click:Connect(function()
				local n = tonumber(box.Text); if n and n>=10 and n<=36 then title.TextSize = n; box.PlaceholderText=tostring(n); box.Text="" end
			end)
		end

		openBtn.MouseButton1Click:Connect(function()
			local openNow = panel.Size.Y.Offset > 0
			if openNow then tween(panel,.15,{Size=UDim2.new(1,0,0,0)}); openBtn.Text="Open" else
				local rows = 4 + 1 + 1 -- approx visible rows; adjust height
				tween(panel,.15,{Size=UDim2.new(1,0,0, (34+6)*5 + 8)}) -- simple compact height
				openBtn.Text="Close"
			end
		end)
	end
	settingsBlock()

	-- Notification (per tab)
	function Library:Notify(textStr, duration)
		duration = tonumber(duration) or 2
		local f=Instance.new("Frame"); f.BackgroundColor3=Theme.Panel; f.Size=UDim2.fromOffset(260,40); f.Position=UDim2.new(1,-280,0,20); f.Parent=SG; round(f,10); shadow(f,.35)
		local lbl = text(f, tostring(textStr), 14, Theme.Text, true); lbl.Size=UDim2.new(1,-16,1,0); lbl.Position=UDim2.fromOffset(8,0)
		f.Visible=true; f.BackgroundTransparency=1; lbl.TextTransparency=1
		tween(f,.18,{BackgroundTransparency=0}); tween(lbl,.18,{TextTransparency=0})
		task.delay(duration,function() tween(f,.18,{BackgroundTransparency=1}); tween(lbl,.18,{TextTransparency=1}); task.delay(.2,function() f:Destroy() end) end)
	end

	-- API Surface for Tab
	local TabPublic = {
		_root = root, _scroll = scroll,
		SetOpen = function(_, v) setOpen(v and true or false, true) end,
		IsOpen = function() return open end,
		Focus = function() root.ZIndex=functionZ() end,
		Destroy = function() root:Destroy() end
	}
	function TabPublic:AddSection(header) return setmetatable({}, Section) end

	return setmetatable(TabPublic, TabAPI)
end

return setmetatable({}, {__index = Library})

--[[ =========================
USAGE (example)
local UI = loadstring(game:HttpGet("https://your.cdn/floating_tabs.lua"))()

local Tab = UI:CreateTab("Main", {Position=UDim2.fromOffset(120,100), StartOpen=true})
local Sec = Tab:AddSection("Controls")
Sec:AddLabel("Welcome")
Sec:AddSeparator()
local btn = Sec:AddButton("Ping", function() UI:Notify("Pong!", 1.2) end)
local tog = Sec:AddToggle("Enable", true, function(state) print("Enable:", state) end)
local sld = Sec:AddSlider("Volume", 0, 100, 50, function(v) print("Vol", v) end)
local dd  = Sec:AddDropdown("Mode", {"Off","Low","Med","High"}, "Med", function(v) print("Mode", v) end)
local tb  = Sec:AddTextbox("Name", "Player", function(text) print("Name", text) end)

-- Standalone keybind that fires the same action as the button:
Sec:AddKeybind("Bind to Ping", Enum.KeyCode.F, btn) -- pressing F runs the button's callback

-- Or bind to toggle:
Sec:AddKeybind("Bind to Enable", Enum.KeyCode.G, tog) -- pressing G toggles it

-- Or standalone callback:
Sec:AddKeybind("Custom Bind", Enum.KeyCode.H, function(_,ev) if ev=="fired" then print("H pressed") end end)
========================= ]]
