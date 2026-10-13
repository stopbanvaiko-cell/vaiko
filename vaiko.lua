-- Machula (custom UI)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local E = Enum
local LP = Players.LocalPlayer
local OWNERS = {3064558341}
if not (table.find(OWNERS, LP.UserId) or (game.CreatorType == E.CreatorType.User and LP.UserId == game.CreatorId)) then
warn("[Machula] not an owner")
return
end
local S = {
Enabled = false,
TeamCheck = false,
ShowNames = true,
FillColor = Color3.fromRGB(255, 60, 60),
OutlineColor = Color3.fromRGB(255, 255, 255),
FillTransparency = 0.5,
OutlineTransparency = 0,
MaxDistance = 1000,
NameSize = 11,
DeathCheck = true,
}
local K = {}
local function isTeammate(player)
if player == LP then return false end
local myTeam, theirTeam = LP.Team, player.Team
if myTeam ~= nil and theirTeam ~= nil then
return myTeam == theirTeam
end
if not LP.Neutral and not player.Neutral then
return LP.TeamColor == player.TeamColor
end
return false
end
local function isAlive(character, check)
local hum = character and character:FindFirstChildOfClass("Humanoid")
if not hum then return false end
if not check then return true end
if hum.Health <= 0 then return false end
local fx = character:FindFirstChild("BodyEffects")
if fx then
local ko, dead = fx:FindFirstChild("K.O"), fx:FindFirstChild("Dead")
if (ko and ko.Value == true) or (dead and dead.Value == true) then return false end
end
if character:GetAttribute("KO") == true or character:GetAttribute("Knocked") == true or character:GetAttribute("Dead") == true then return false end
return true
end
local container = Instance.new("Folder")
container.Name = "MachulaHighlights"
container.Parent = workspace
local tracked = {}
local function removeFor(player)
local data = tracked[player]
if not data then return end
if data.Highlight then data.Highlight:Destroy() end
if data.Tag then data.Tag:Destroy() end
tracked[player] = nil
end
local function createFor(player)
removeFor(player)
if player == LP or not S.Enabled then return end
if S.TeamCheck and isTeammate(player) then return end
local character = player.Character
if not character then return end
local data = {}
local highlight = Instance.new("Highlight")
highlight.Name = player.Name
highlight.Adornee = character
highlight.FillColor = S.FillColor
highlight.OutlineColor = S.OutlineColor
highlight.FillTransparency = S.FillTransparency
highlight.OutlineTransparency = S.OutlineTransparency
highlight.DepthMode = E.HighlightDepthMode.AlwaysOnTop
highlight.Parent = container
data.Highlight = highlight
if S.ShowNames then
local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
if root then
local tag = Instance.new("BillboardGui")
tag.Name = player.Name .. "_Tag"
tag.Adornee = root
tag.Size = UDim2.fromOffset(100, 16)
tag.StudsOffset = Vector3.new(0, 3, 0)
tag.AlwaysOnTop = true
tag.MaxDistance = S.MaxDistance
tag.Parent = container
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = player.DisplayName
label.TextColor3 = S.OutlineColor
label.TextStrokeTransparency = 0.3
label.Font = E.Font.GothamMedium
label.TextScaled = false
label.TextSize = S.NameSize
label.Parent = tag
data.Tag = tag
end
end
tracked[player] = data
end
local function refreshAll()
for _, player in ipairs(Players:GetPlayers()) do
createFor(player)
end
end
local function clearAll()
for player in pairs(tracked) do
removeFor(player)
end
end
K[#K + 1] = RunService.Heartbeat:Connect(function()
if not S.Enabled then return end
local myChar = LP.Character
local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
if not myRoot then return end
for player, data in pairs(tracked) do
local char = player.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
if root and data.Highlight then
local visible = (root.Position - myRoot.Position).Magnitude <= S.MaxDistance and isAlive(char, S.DeathCheck)
data.Highlight.Enabled = visible
if data.Tag then data.Tag.Enabled = visible end
end
end
end)
local function hookPlayer(player)
K[#K + 1] = player.CharacterAdded:Connect(function()
task.wait(0.2)
createFor(player)
end)
K[#K + 1] = player.CharacterRemoving:Connect(function()
removeFor(player)
end)
K[#K + 1] = player:GetPropertyChangedSignal("Team"):Connect(function()
createFor(player)
end)
if player.Character then
createFor(player)
end
end
for _, player in ipairs(Players:GetPlayers()) do
hookPlayer(player)
end
K[#K + 1] = Players.PlayerAdded:Connect(hookPlayer)
K[#K + 1] = Players.PlayerRemoving:Connect(removeFor)
K[#K + 1] = LP:GetPropertyChangedSignal("Team"):Connect(function()
if S.Enabled then refreshAll() end
end)
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local aim = {
Enabled = false,
Smoothness = 50,
HitPart = "Head",
AimMode = "Hold Bind",
Bind = E.UserInputType.MouseButton2,
Active = false,
Binding = false,
Sticky = false,
Locked = nil,
TeamCheck = true,
DeathCheck = true,
OffsetX = 0,
OffsetY = 0,
AutoUnlock = true,
TargetPlayer = nil,
PauseUntil = 0,
WallCheck = false,
FOV = 200,
FOVMode = "Free Look",
SmoothCurve = 1,
ShowFOV = true,
PredictX = 0,
PredictY = 0,
EaseStyle = "None",
EaseDir = "In",
FallOffset = false,
FallOffsetY = 0,
FallThreshold = 10,
Filter = 50,
ResX = 0,
ResY = 0,
ResZ = 0,
}
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "MachulaFOV"
fovGui.IgnoreGuiInset = true
fovGui.ResetOnSpawn = false
fovGui.Parent = LP:WaitForChild("PlayerGui")
local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Visible = false
fovCircle.Parent = fovGui
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle
local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(220, 30, 40)
fovStroke.Thickness = 1
fovStroke.Parent = fovCircle
local rayParams = RaycastParams.new()
rayParams.FilterType = E.RaycastFilterType.Exclude
local function aimOrigin()
local base
if aim.FOVMode == "Mouse" then
base = UIS:GetMouseLocation()
else
local cam = workspace.CurrentCamera
base = cam and (cam.ViewportSize / 2) or UIS:GetMouseLocation()
end
return Vector2.new(base.X + aim.OffsetX, base.Y + aim.OffsetY)
end
local function isVisible(part, camera)
rayParams.FilterDescendantsInstances = { LP.Character }
local origin = camera.CFrame.Position
local result = workspace:Raycast(origin, part.Position - origin, rayParams)
return result == nil or result.Instance:IsDescendantOf(part.Parent)
end
local function getBodyPart(character, choice, center, camera)
if choice == "Torso" then
return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
elseif choice == "Closest Part" then
local best, bestDist
for _, part in ipairs(character:GetChildren()) do
if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 then
local pos, onScreen = camera:WorldToViewportPoint(part.Position)
if onScreen then
local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
if not bestDist or d < bestDist then
best, bestDist = part, d
end
end
end
end
return best
end
return character:FindFirstChild(choice)
end
local function getTarget(camera)
local center = aimOrigin()
local bestPart, bestPlayer, bestDist = nil, nil, aim.FOV
for _, player in ipairs(Players:GetPlayers()) do
local character = player.Character
if player ~= LP and character then
local sameTeam = aim.TeamCheck and isTeammate(player)
local humanoid = character:FindFirstChildOfClass("Humanoid")
if not sameTeam and humanoid and isAlive(character, aim.DeathCheck) then
local part = getBodyPart(character, aim.HitPart, center, camera)
if part then
local pos, onScreen = camera:WorldToViewportPoint(part.Position)
if onScreen then
local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
if dist < bestDist and (not aim.WallCheck or isVisible(part, camera)) then
bestPart, bestPlayer, bestDist = part, player, dist
end
end
end
end
end
end
return bestPart, bestPlayer
end
RunService:BindToRenderStep("MachulaAim", E.RenderPriority.Camera.Value + 1, function(dt)
local camera = workspace.CurrentCamera
fovCircle.Visible = aim.Enabled and aim.ShowFOV
if fovCircle.Visible and camera then
local center = aimOrigin()
fovCircle.Size = UDim2.fromOffset(aim.FOV * 2, aim.FOV * 2)
fovCircle.Position = UDim2.fromOffset(center.X, center.Y)
end
if not aim.Enabled or not camera then
aim.Locked = nil
aim.FilterTarget = nil
aim.TargetPlayer = nil
return
end
if not isAlive(LP.Character, aim.DeathCheck) then
aim.Locked = nil
aim.FilterTarget = nil
aim.TargetPlayer = nil
return
end
if aim.AimMode ~= "Always On" and not aim.Active then
aim.Locked = nil
aim.FilterTarget = nil
aim.TargetPlayer = nil
return
end
if aim.AutoUnlock and aim.TargetPlayer and not isAlive(aim.TargetPlayer.Character, true) then
aim.TargetPlayer = nil
aim.Locked = nil
aim.FilterTarget = nil
if aim.AimMode == "Always On" then
aim.PauseUntil = os.clock() + 1
else
aim.Active = false
end
return
end
if os.clock() < aim.PauseUntil then return end
local target
if aim.Sticky and aim.Locked then
local lockedPlayer = aim.Locked
local character = lockedPlayer.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
if lockedPlayer.Parent == Players
and isAlive(character, aim.DeathCheck)
and not (aim.TeamCheck and isTeammate(lockedPlayer)) then
target = getBodyPart(character, aim.HitPart, aimOrigin(), camera)
if target then aim.TargetPlayer = lockedPlayer end
end
if not target then
aim.Locked = nil
end
end
if not target then
local part, player = getTarget(camera)
target = part
aim.TargetPlayer = player
if aim.Sticky then
aim.Locked = player
end
end
if not target then return end
if aim.Sticky and aim.WallCheck and not isVisible(target, camera) then
return
end
local t = 1 - (math.clamp(aim.Smoothness, 0, 100) / 100) ^ aim.SmoothCurve
if aim.EaseStyle ~= "None" then
t = math.clamp(TweenService:GetValue(t, E.EasingStyle[aim.EaseStyle], E.EasingDirection[aim.EaseDir]), 0, 1)
end
local rawVel = target.AssemblyLinearVelocity
local newTarget = aim.FilterTarget ~= target
local fa = 1 - math.exp(-math.min(dt, 0.1) * (80 * (1 - aim.Filter / 100) + 4))
if newTarget then
aim.FilterTarget = target
aim.FilterVel = rawVel
end
aim.FilterVel = aim.FilterVel:Lerp(rawVel, fa)
local vel = aim.FilterVel
local aimPos = target.Position + Vector3.new(vel.X * aim.PredictX, vel.Y * aim.PredictY, vel.Z * aim.PredictX)
if aim.FallOffset and vel.Y < -aim.FallThreshold then
aimPos = aimPos + Vector3.new(0, aim.FallOffsetY, 0)
end
if newTarget then aim.FilterPos = aimPos end
aim.FilterPos = aim.FilterPos:Lerp(aimPos, fa)
local camPos = camera.CFrame.Position
local o = aimOrigin()
local ray = camera:ViewportPointToRay(o.X, o.Y)
local dist = (aim.FilterPos - camPos).Magnitude
local cur = camPos + ray.Direction.Unit * dist
local d = aim.FilterPos - cur
local pulled = cur + Vector3.new(d.X * (1 - aim.ResX / 100), d.Y * (1 - aim.ResY / 100), d.Z * (1 - aim.ResZ / 100))
local fromDir = (cur - camPos).Unit
local toDir = (pulled - camPos).Unit
local axis = fromDir:Cross(toDir)
local goal = camera.CFrame
if axis.Magnitude > 1e-6 then
local ang = math.acos(math.clamp(fromDir:Dot(toDir), -1, 1))
goal = CFrame.new(camPos) * CFrame.fromAxisAngle(axis.Unit, ang) * camera.CFrame.Rotation
end
local speed = 3 * 100 ^ t
local alpha = 1 - math.exp(-speed * math.min(dt, 0.1))
camera.CFrame = camera.CFrame:Lerp(goal, math.clamp(alpha, 0, 1))
end)
K[#K + 1] = {Disconnect = function() RunService:UnbindFromRenderStep("MachulaAim") end}
local function matchesBind(input)
if aim.Bind.EnumType == E.KeyCode then
return input.KeyCode == aim.Bind
end
return input.UserInputType == aim.Bind
end
K[#K + 1] = UIS.InputBegan:Connect(function(input, gameProcessed)
if aim.Binding or not aim.Enabled or not matchesBind(input) then return end
if gameProcessed and aim.Bind.EnumType == E.KeyCode then return end
if aim.AimMode == "Hold Bind" then
aim.Active = true
elseif aim.AimMode == "Toggle Bind" then
aim.Active = not aim.Active
end
end)
K[#K + 1] = UIS.InputEnded:Connect(function(input)
if aim.AimMode == "Hold Bind" and matchesBind(input) then
aim.Active = false
end
end)
-- ESP: boxes + traces (drawn with GUI frames)
S.Boxes = false
S.Traces = false
S.BoxColor = Color3.fromRGB(255, 255, 255)
S.TraceColor = Color3.fromRGB(255, 60, 60)
S.TraceOrigin = "Bottom"
local espGui = Instance.new("ScreenGui")
espGui.Name = "MachulaESP"
espGui.IgnoreGuiInset = true
espGui.ResetOnSpawn = false
espGui.DisplayOrder = 50
espGui.Parent = LP:WaitForChild("PlayerGui")
local espObjs = {}
local function getEsp(player)
local o = espObjs[player]
if o then return o end
local box = Instance.new("Frame")
box.BackgroundTransparency = 1
box.BorderSizePixel = 0
box.Visible = false
box.Parent = espGui
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1
stroke.Color = S.BoxColor
stroke.LineJoinMode = E.LineJoinMode.Miter
stroke.Parent = box
local line = Instance.new("Frame")
line.AnchorPoint = Vector2.new(0.5, 0.5)
line.BorderSizePixel = 0
line.BackgroundColor3 = S.TraceColor
line.Visible = false
line.Parent = espGui
o = {Box = box, Stroke = stroke, Line = line}
espObjs[player] = o
return o
end
local function hideEsp(o)
o.Box.Visible = false
o.Line.Visible = false
end
local function removeEsp(player)
local o = espObjs[player]
if o then
o.Box:Destroy()
o.Line:Destroy()
espObjs[player] = nil
end
end
K[#K + 1] = Players.PlayerRemoving:Connect(removeEsp)
K[#K + 1] = RunService.RenderStepped:Connect(function()
local camera = workspace.CurrentCamera
if not camera or not (S.Boxes or S.Traces) then
for _, o in pairs(espObjs) do hideEsp(o) end
return
end
local viewport = camera.ViewportSize
local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
for _, player in ipairs(Players:GetPlayers()) do
if player ~= LP then
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = character and character:FindFirstChild("HumanoidRootPart")
local o = getEsp(player)
local show = root ~= nil and isAlive(character, S.DeathCheck)
if show and S.TeamCheck and isTeammate(player) then show = false end
if show and myRoot and (root.Position - myRoot.Position).Magnitude > S.MaxDistance then show = false end
if not show then
hideEsp(o)
else
if S.Boxes then
local cf, size = character:GetBoundingBox()
local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
local inFront = true
for x = -1, 1, 2 do
for y = -1, 1, 2 do
for z = -1, 1, 2 do
local p = camera:WorldToViewportPoint(cf:PointToWorldSpace(size / 2 * Vector3.new(x, y, z)))
if p.Z <= 0 then inFront = false end
minX, minY = math.min(minX, p.X), math.min(minY, p.Y)
maxX, maxY = math.max(maxX, p.X), math.max(maxY, p.Y)
end
end
end
o.Box.Visible = inFront
if inFront then
o.Stroke.Color = S.BoxColor
o.Box.Position = UDim2.fromOffset(minX, minY)
o.Box.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
end
else
o.Box.Visible = false
end
if S.Traces then
local p = camera:WorldToViewportPoint(root.Position)
if p.Z > 0 then
local from
if S.TraceOrigin == "Center" then
from = Vector2.new(viewport.X / 2, viewport.Y / 2)
elseif S.TraceOrigin == "Mouse" then
from = UIS:GetMouseLocation()
else
from = Vector2.new(viewport.X / 2, viewport.Y)
end
local to = Vector2.new(p.X, p.Y)
local d = to - from
o.Line.BackgroundColor3 = S.TraceColor
o.Line.Size = UDim2.fromOffset(d.Magnitude, 1)
o.Line.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
o.Line.Rotation = math.deg(math.atan2(d.Y, d.X))
o.Line.Visible = true
else
o.Line.Visible = false
end
else
o.Line.Visible = false
end
end
end
end
end)
-- MAP: material changer + world visuals
local Lighting = game:GetService("Lighting")
local M = {ChangeMaterial = false, Material = "None", Fullbright = false, NoFog = false}
local origLight = {
Brightness = Lighting.Brightness,
ClockTime = Lighting.ClockTime,
Ambient = Lighting.Ambient,
OutdoorAmbient = Lighting.OutdoorAmbient,
FogEnd = Lighting.FogEnd,
FogStart = Lighting.FogStart,
}
local function restoreLight(keys)
for _, k in ipairs(keys) do Lighting[k] = origLight[k] end
end
local matNames = {"None", "CrackedLava", "Neon", "Glass", "ForceField", "Ice", "Glacier", "Slate", "Marble", "Granite", "Basalt", "Brick", "WoodPlanks", "DiamondPlate", "Metal", "Foil", "Grass", "Sand", "Snow", "Concrete", "SmoothPlastic"}
local origMat = setmetatable({}, {__mode = "k"})
local function isCharacterPart(part)
local m = part:FindFirstAncestorOfClass("Model")
while m do
if m:FindFirstChildOfClass("Humanoid") then return true end
m = m.Parent and m.Parent:FindFirstAncestorOfClass("Model")
end
return false
end
local function applyMat(part)
if M.Material == "None" then return end
if not part:IsA("BasePart") or part == workspace.Terrain or isCharacterPart(part) then return end
if origMat[part] == nil then origMat[part] = part.Material end
part.Material = E.Material[M.Material]
end
local function restoreMat()
for part, mat in pairs(origMat) do
if part.Parent then part.Material = mat end
origMat[part] = nil
end
end
local function applyAllMat()
if M.Material == "None" then
restoreMat()
return
end
task.spawn(function()
local n = 0
for _, d in ipairs(workspace:GetDescendants()) do
if not M.ChangeMaterial then return end
applyMat(d)
n = n + 1
if n % 400 == 0 then task.wait() end
end
end)
end
K[#K + 1] = workspace.DescendantAdded:Connect(function(d)
if M.ChangeMaterial then applyMat(d) end
end)
K[#K + 1] = RunService.Heartbeat:Connect(function()
if M.Fullbright then
Lighting.Brightness = 2
Lighting.ClockTime = 14
Lighting.Ambient = Color3.fromRGB(255, 255, 255)
Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
end
if M.NoFog then
Lighting.FogStart = 1e6
Lighting.FogEnd = 1e6
end
end)
-- PLAYER: walk speed + fly
local walk = {Name = "Walk", Enabled = false, Mode = "Hold Bind", Bind = E.KeyCode.LeftShift, Value = 32, Active = false, Binding = false}
local fly = {Name = "Fly", Enabled = false, Mode = "Toggle Bind", Bind = E.KeyCode.F, Value = 60, Active = false, Binding = false}
local jump = {Name = "Jump", Enabled = false, Mode = "Toggle Bind", Bind = E.KeyCode.X, Value = 100, Active = false, Binding = false}
local moves = {walk, fly, jump}
local function bindMatches(st, input)
if st.Bind.EnumType == E.KeyCode then
return input.KeyCode == st.Bind
end
return input.UserInputType == st.Bind
end
K[#K + 1] = UIS.InputBegan:Connect(function(input, gp)
for _, st in ipairs(moves) do
if st.Binding then
local ut = input.UserInputType
local nb
if ut == E.UserInputType.Keyboard then
if input.KeyCode == E.KeyCode.Escape then
st.Binding = false
st.Label:Set(st.Name .. " Bind: " .. st.Bind.Name)
return
end
nb = input.KeyCode
elseif ut == E.UserInputType.MouseButton1 or ut == E.UserInputType.MouseButton2 or ut == E.UserInputType.MouseButton3 then
nb = ut
end
if nb then
st.Bind = nb
st.Binding = false
st.Active = false
st.Label:Set(st.Name .. " Bind: " .. nb.Name)
end
return
end
end
for _, st in ipairs(moves) do
if st.Enabled and bindMatches(st, input) and not (gp and st.Bind.EnumType == E.KeyCode) then
if st.Mode == "Hold Bind" then
st.Active = true
else
st.Active = not st.Active
end
end
end
end)
K[#K + 1] = UIS.InputEnded:Connect(function(input)
for _, st in ipairs(moves) do
if st.Mode == "Hold Bind" and bindMatches(st, input) then
st.Active = false
end
end
end)
local function restoreWalk()
if walk.Applied then
if walk.Applied.Parent then walk.Applied.WalkSpeed = walk.Orig end
walk.Applied = nil
end
end
local function restoreJump()
if jump.Applied then
if jump.Applied.Parent then
if jump.OrigMode then jump.Applied.JumpPower = jump.Orig else jump.Applied.JumpHeight = jump.Orig end
end
jump.Applied = nil
end
end
local function stopFly()
if fly.BV then fly.BV:Destroy() fly.BV = nil end
if fly.BG then fly.BG:Destroy() fly.BG = nil end
if fly.Hum and fly.Hum.Parent then fly.Hum.PlatformStand = false end
fly.Hum = nil
end
K[#K + 1] = RunService.Heartbeat:Connect(function()
local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
if hum and walk.Enabled and walk.Active then
if walk.Applied ~= hum then
restoreWalk()
walk.Orig = hum.WalkSpeed
walk.Applied = hum
end
hum.WalkSpeed = walk.Value
else
restoreWalk()
end
if hum and jump.Enabled and jump.Active then
if jump.Applied ~= hum then
restoreJump()
jump.OrigMode = hum.UseJumpPower
jump.Orig = hum.UseJumpPower and hum.JumpPower or hum.JumpHeight
jump.Applied = hum
end
if hum.UseJumpPower then
hum.JumpPower = jump.Value
else
hum.JumpHeight = jump.Value ^ 2 / (2 * workspace.Gravity)
end
else
restoreJump()
end
end)
K[#K + 1] = RunService.RenderStepped:Connect(function()
local camera = workspace.CurrentCamera
local char = LP.Character
local root = char and char:FindFirstChild("HumanoidRootPart")
local hum = char and char:FindFirstChildOfClass("Humanoid")
if fly.Enabled and fly.Active and camera and root and hum and hum.Health > 0 then
if not fly.BV or fly.BV.Parent ~= root then
stopFly()
fly.BV = Instance.new("BodyVelocity")
fly.BV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
fly.BV.Velocity = Vector3.zero
fly.BV.Parent = root
fly.BG = Instance.new("BodyGyro")
fly.BG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
fly.BG.P = 9e4
fly.BG.Parent = root
fly.Hum = hum
end
hum.PlatformStand = true
local cf = camera.CFrame
local dir = Vector3.zero
if not UIS:GetFocusedTextBox() then
if UIS:IsKeyDown(E.KeyCode.W) then dir = dir + cf.LookVector end
if UIS:IsKeyDown(E.KeyCode.S) then dir = dir - cf.LookVector end
if UIS:IsKeyDown(E.KeyCode.D) then dir = dir + cf.RightVector end
if UIS:IsKeyDown(E.KeyCode.A) then dir = dir - cf.RightVector end
if UIS:IsKeyDown(E.KeyCode.Space) then dir = dir + Vector3.yAxis end
if UIS:IsKeyDown(E.KeyCode.LeftControl) then dir = dir - Vector3.yAxis end
end
fly.BV.Velocity = dir.Magnitude > 0 and dir.Unit * fly.Value or Vector3.zero
fly.BG.CFrame = cf
elseif fly.BV then
stopFly()
end
end)
local U, UO, US, RGB = UDim2.new, UDim2.fromOffset, UDim2.fromScale, Color3.fromRGB
local RED, BG, PNL, DIM, GRY, WHT = RGB(225, 35, 50), RGB(11, 11, 13), RGB(19, 19, 22), RGB(60, 12, 18), RGB(130, 130, 136), RGB(255, 255, 255)
local L, R = E.TextXAlignment.Left, E.TextXAlignment.Right
local MB1, TCH = E.UserInputType.MouseButton1, E.UserInputType.Touch
local CFG = {ctl = {}}
function CFG.reg(box, name, get, set)
CFG.ctl[#CFG.ctl + 1] = {id = box.Name .. "/" .. name, get = get, set = set}
end
local ord = 0
local drag, ds, sp
local function new(c, p, par)
local i = Instance.new(c)
if i:IsA("GuiObject") then
i.BorderSizePixel = 0
i.BackgroundTransparency = p.BackgroundColor3 and 0 or 1
ord = ord + 1
i.LayoutOrder = ord
end
if c == "TextLabel" or c == "TextButton" then
i.Font = E.Font.Code
i.TextSize = 13
end
for k, v in pairs(p) do i[k] = v end
i.Parent = par
return i
end
local function round(i, r) new("UICorner", {CornerRadius = UDim.new(0, r)}, i) end
local function list(par, pad, ha)
return new("UIListLayout", {Padding = UDim.new(0, pad), SortOrder = E.SortOrder.LayoutOrder, HorizontalAlignment = ha or E.HorizontalAlignment.Left}, par)
end
local function text(par, t, col, al, size, pos)
return new("TextLabel", {Text = t, TextColor3 = col, TextXAlignment = al or L, Size = size or US(1, 1), Position = pos or U()}, par)
end
local function clk(i) return i.UserInputType == MB1 or i.UserInputType == TCH end
local gui = new("ScreenGui", {Name = "MachulaUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 100}, LP:WaitForChild("PlayerGui"))
local win = new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = US(0.5, 0.5), Size = UO(680, 440), BackgroundColor3 = BG}, gui)
round(win, 8)
new("UIStroke", {Color = RGB(45, 12, 16)}, win)
local title = new("TextLabel", {Active = true, Text = "machula", Font = E.Font.Arcade, TextSize = 28, TextColor3 = RED, Size = U(1, 0, 0, 46)}, win)
local side = new("Frame", {Position = UO(0, 46), Size = U(0, 64, 1, -46)}, win)
list(side, 5, E.HorizontalAlignment.Center)
new("Frame", {Position = UO(68, 52), Size = U(0, 1, 1, -62), BackgroundColor3 = RGB(28, 12, 15)}, win)
local body = new("Frame", {Position = UO(76, 50), Size = U(1, -88, 1, -60), ClipsDescendants = true}, win)
local tabs = {}
local function pick(t)
for _, o in ipairs(tabs) do
o.page.Visible = o == t
o.bar.Visible = o == t
o.btn.TextColor3 = o == t and RED or GRY
end
end
local function addTab(name)
local t = {col = {}, name = name}
t.btn = new("TextButton", {Text = name, Font = E.Font.Arcade, TextSize = 14, Size = UO(58, 40)}, side)
t.bar = new("Frame", {Size = U(0, 3, 0.7, 0), Position = US(0, 0.15), BackgroundColor3 = RED}, t.btn)
t.page = new("ScrollingFrame", {Size = US(1, 1), ScrollBarThickness = 3, ScrollBarImageColor3 = RED, AutomaticCanvasSize = E.AutomaticSize.Y, CanvasSize = U(), Visible = false}, body)
for i = 1, 2 do
t.col[i] = new("Frame", {Size = U(0.5, -5, 0, 0), Position = U((i - 1) * 0.5, (i - 1) * 5, 0, 0), AutomaticSize = E.AutomaticSize.Y}, t.page)
list(t.col[i], 8)
end
function t:section(col, name)
local w = new("Frame", {Size = U(1, 0, 0, 0), AutomaticSize = E.AutomaticSize.Y}, t.col[col])
list(w, 4)
text(w, name, GRY, nil, U(1, 0, 0, 14))
local box = new("Frame", {Name = t.name .. "." .. name, Size = U(1, 0, 0, 0), AutomaticSize = E.AutomaticSize.Y, BackgroundColor3 = PNL}, w)
round(box, 6)
new("UIPadding", {PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 7), PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)}, box)
list(box, 5)
return box
end
t.btn.MouseButton1Click:Connect(function() pick(t) end)
tabs[#tabs + 1] = t
if #tabs == 1 then pick(t) end
return t
end
local function tg(box, name, def, cb)
local b = new("TextButton", {Size = U(1, 0, 0, 22), Text = ""}, box)
local sq = new("Frame", {Size = UO(13, 13), Position = UO(0, 4), BackgroundColor3 = BG}, b)
round(sq, 3)
text(b, name, WHT, nil, U(1, -22, 1, 0), UO(22, 0))
local on
local o = {}
function o:Set(v)
on = v
sq.BackgroundColor3 = v and RED or RGB(30, 30, 34)
end
o:Set(def)
b.MouseButton1Click:Connect(function()
o:Set(not on)
cb(on)
end)
CFG.reg(box, name, function() return on end, function(x) o:Set(x == true) cb(on) end)
end
local function dd(box, name, opts, def, cb)
local b = new("TextButton", {Size = U(1, 0, 0, 22), Text = ""}, box)
text(b, name, WHT, nil, U(0.5, 0, 1, 0))
local v = text(b, "", RED, R, U(0.5, 0, 1, 0), US(0.5, 0))
local i = table.find(opts, def) or 1
v.Text = opts[i] .. " >"
b.MouseButton1Click:Connect(function()
i = i % #opts + 1
v.Text = opts[i] .. " >"
cb(opts[i])
end)
CFG.reg(box, name, function() return opts[i] end, function(x)
local k = table.find(opts, x)
if k then
i = k
v.Text = opts[i] .. " >"
cb(opts[i])
end
end)
end
local function dl(box, name, opts, def, cb)
local b = new("TextButton", {Size = U(1, 0, 0, 22), Text = ""}, box)
text(b, name, WHT, nil, U(0.4, 0, 1, 0))
local v = text(b, "", RED, R, U(0.6, 0, 1, 0), US(0.4, 0))
local cur = table.find(opts, def) and def or opts[1]
local lst = new("ScrollingFrame", {Size = U(1, 0, 0, 120), BackgroundColor3 = BG, ScrollBarThickness = 3, ScrollBarImageColor3 = RED, AutomaticCanvasSize = E.AutomaticSize.Y, CanvasSize = U(), Visible = false}, box)
round(lst, 4)
new("UIPadding", {PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3)}, lst)
list(lst, 2)
local items = {}
local function refresh()
v.Text = cur .. (lst.Visible and "  ^" or "  v")
for n, it in pairs(items) do
it.TextColor3 = n == cur and RED or WHT
end
end
for _, n in ipairs(opts) do
local it = new("TextButton", {Text = n, TextColor3 = WHT, Size = U(1, -6, 0, 20), BackgroundColor3 = PNL}, lst)
round(it, 3)
items[n] = it
it.MouseButton1Click:Connect(function()
cur = n
lst.Visible = false
refresh()
cb(n)
end)
end
b.MouseButton1Click:Connect(function()
lst.Visible = not lst.Visible
refresh()
end)
refresh()
CFG.reg(box, name, function() return cur end, function(x)
if items[x] then
cur = x
lst.Visible = false
refresh()
cb(x)
end
end)
end
local function bt(box, name, cb)
local b = new("TextButton", {Text = name, TextColor3 = RED, Size = U(1, 0, 0, 24), BackgroundColor3 = RGB(30, 13, 16)}, box)
round(b, 4)
local o = {}
function o:Set(t) b.Text = t end
b.MouseButton1Click:Connect(cb)
return o
end
local function sl(box, name, min, max, def, step, cb)
local row = new("Frame", {Size = U(1, 0, 0, 34)}, box)
text(row, name, WHT, nil, U(0.7, 0, 0, 16))
local val = text(row, "", GRY, R, U(0.3, 0, 0, 16), US(0.7, 0))
local bar = new("Frame", {Position = UO(0, 23), Size = U(1, 0, 0, 4), BackgroundColor3 = DIM}, row)
local fill = new("Frame", {Size = US(0, 1), BackgroundColor3 = RED}, bar)
new("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = US(1, 0.5), Size = UO(6, 11), BackgroundColor3 = RED}, fill)
local cur = def
local fmt = step < 1 and "%.2f" or "%.0f"
local function set(v)
fill.Size = US((v - min) / (max - min), 1)
val.Text = string.format(fmt, v)
cur = v
end
local function upd(x)
local v = min + math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1) * (max - min)
v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
set(v)
cb(v)
end
set(def)
new("TextButton", {Text = "", Position = UO(0, 15), Size = U(1, 0, 0, 18)}, row).InputBegan:Connect(function(i)
if clk(i) then
drag = upd
upd(i.Position.X)
end
end)
CFG.reg(box, name, function() return cur end, function(x)
x = math.clamp(tonumber(x) or def, min, max)
set(x)
cb(x)
end)
end
K[#K + 1] = UIS.InputChanged:Connect(function(i)
if i.UserInputType == E.UserInputType.MouseMovement or i.UserInputType == TCH then
if drag then
drag(i.Position.X)
elseif ds then
local d = i.Position - ds
win.Position = U(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
end
end
end)
K[#K + 1] = UIS.InputEnded:Connect(function(i)
if clk(i) then drag, ds = nil, nil end
end)
title.InputBegan:Connect(function(i)
if clk(i) then ds, sp = i.Position, win.Position end
end)
local menuKey, menuBinding, MB = E.KeyCode.RightShift, false
K[#K + 1] = UIS.InputBegan:Connect(function(i, gp)
if menuBinding then
if i.UserInputType == E.UserInputType.Keyboard then
menuBinding = false
if i.KeyCode ~= E.KeyCode.Escape then menuKey = i.KeyCode end
MB:Set("Menu Bind: " .. menuKey.Name)
end
elseif not gp and not aim.Binding and i.KeyCode == menuKey then
win.Visible = not win.Visible
end
end)
local colors = {Red = RGB(255, 60, 60), Green = RGB(60, 255, 90), Blue = RGB(60, 120, 255), Yellow = RGB(255, 220, 50), Purple = RGB(170, 70, 255), White = WHT}
local cn = {"Red", "Green", "Blue", "Yellow", "Purple", "White"}
local A = addTab("AIM")
local m = A:section(1, "MAIN")
tg(m, "Aimbot", false, function(v) aim.Enabled = v end)
dd(m, "Aim Mode", {"Hold Bind", "Toggle Bind", "Always On"}, "Hold Bind", function(v)
aim.AimMode = v
aim.Active = false
end)
local BB
BB = bt(m, "Aim Bind: " .. aim.Bind.Name, function()
aim.Binding = true
aim.Active = false
BB:Set("press a key... (Esc = cancel)")
end)
dd(m, "Hit Part", {"Head", "Torso", "HumanoidRootPart", "Closest Part"}, "Head", function(v) aim.HitPart = v end)
sl(m, "Smoothness", 0, 100, aim.Smoothness, 0.5, function(v) aim.Smoothness = v end)
sl(m, "Smooth Curve", 0.3, 3, aim.SmoothCurve, 0.1, function(v) aim.SmoothCurve = v end)
sl(m, "Jitter Filter", 0, 100, aim.Filter, 1, function(v) aim.Filter = v end)
local pr = A:section(1, "PREDICTION")
sl(pr, "Prediction X", 0, 1, aim.PredictX, 0.01, function(v) aim.PredictX = v end)
sl(pr, "Prediction Y", 0, 1, aim.PredictY, 0.01, function(v) aim.PredictY = v end)
local fo = A:section(1, "FALL OFFSETS")
tg(fo, "Fall Offset", false, function(v) aim.FallOffset = v end)
sl(fo, "Offset Y", -10, 10, aim.FallOffsetY, 0.1, function(v) aim.FallOffsetY = v end)
sl(fo, "Fall Speed Threshold", 1, 100, aim.FallThreshold, 1, function(v) aim.FallThreshold = v end)
local rs = A:section(1, "PULL RESISTANCE")
sl(rs, "Resistance X", 0, 100, aim.ResX, 1, function(v) aim.ResX = v end)
sl(rs, "Resistance Y", 0, 100, aim.ResY, 1, function(v) aim.ResY = v end)
sl(rs, "Resistance Z", 0, 100, aim.ResZ, 1, function(v) aim.ResZ = v end)
local tc = A:section(2, "TARGET CHECKS")
tg(tc, "Sticky Aim (lock on)", false, function(v)
aim.Sticky = v
aim.Locked = nil
end)
tg(tc, "Team Check", aim.TeamCheck, function(v) aim.TeamCheck = v end)
tg(tc, "Wall Check", false, function(v) aim.WallCheck = v end)
tg(tc, "Auto Unlock On Death", aim.AutoUnlock, function(v)
aim.AutoUnlock = v
aim.TargetPlayer = nil
end)
tg(tc, "Death Check", aim.DeathCheck, function(v)
aim.DeathCheck = v
aim.Locked = nil
end)
local fv = A:section(2, "FOV")
dd(fv, "FOV Mode", {"Free Look", "Mouse"}, aim.FOVMode, function(v) aim.FOVMode = v end)
sl(fv, "FOV Radius", 50, 800, aim.FOV, 10, function(v) aim.FOV = v end)
tg(fv, "Show FOV Circle", true, function(v) aim.ShowFOV = v end)
local ao = A:section(2, "AIM OFFSET")
sl(ao, "Offset X (px)", -200, 200, aim.OffsetX, 1, function(v) aim.OffsetX = v end)
sl(ao, "Offset Y (px)", -200, 200, aim.OffsetY, 1, function(v) aim.OffsetY = v end)
local es = A:section(2, "EASING")
dl(es, "Easing Style", {"None", "Linear", "Sine", "Quad", "Cubic", "Quart", "Quint", "Exponential", "Circular", "Back", "Bounce", "Elastic"}, aim.EaseStyle, function(v) aim.EaseStyle = v end)
dl(es, "Direction", {"In", "Out", "InOut"}, aim.EaseDir, function(v) aim.EaseDir = v end)
K[#K + 1] = UIS.InputBegan:Connect(function(i)
if not aim.Binding then return end
local nb
local ut = i.UserInputType
if ut == E.UserInputType.Keyboard then
if i.KeyCode == E.KeyCode.Escape then
aim.Binding = false
BB:Set("Aim Bind: " .. aim.Bind.Name)
return
end
nb = i.KeyCode
elseif ut == MB1 or ut == E.UserInputType.MouseButton2 or ut == E.UserInputType.MouseButton3 then
nb = ut
end
if nb then
aim.Bind = nb
aim.Binding = false
aim.Active = false
BB:Set("Aim Bind: " .. nb.Name)
end
end)
local ES = addTab("ESP")
local em = ES:section(1, "MAIN")
tg(em, "Highlight Players", false, function(v)
S.Enabled = v
if v then refreshAll() else clearAll() end
end)
tg(em, "Team Check", false, function(v)
S.TeamCheck = v
if S.Enabled then refreshAll() end
end)
tg(em, "Death Check", S.DeathCheck, function(v)
S.DeathCheck = v
if S.Enabled then refreshAll() end
end)
tg(em, "Show Names", true, function(v)
S.ShowNames = v
if S.Enabled then refreshAll() end
end)
tg(em, "Boxes", false, function(v) S.Boxes = v end)
tg(em, "Traces", false, function(v) S.Traces = v end)
dd(em, "Trace Origin", {"Bottom", "Center", "Mouse"}, "Bottom", function(v) S.TraceOrigin = v end)
sl(ES:section(1, "RANGE"), "Max Distance", 50, 5000, S.MaxDistance, 50, function(v)
S.MaxDistance = v
for _, d in pairs(tracked) do
if d.Tag then d.Tag.MaxDistance = v end
end
end)
local ea = ES:section(2, "APPEARANCE")
sl(ea, "Name Size", 8, 24, S.NameSize, 1, function(v)
S.NameSize = v
for _, d in pairs(tracked) do
local l = d.Tag and d.Tag:FindFirstChildOfClass("TextLabel")
if l then l.TextSize = v end
end
end)
dd(ea, "Fill Color", cn, "Red", function(n)
S.FillColor = colors[n]
for _, d in pairs(tracked) do d.Highlight.FillColor = colors[n] end
end)
dd(ea, "Outline Color", cn, "White", function(n)
S.OutlineColor = colors[n]
for _, d in pairs(tracked) do
d.Highlight.OutlineColor = colors[n]
local l = d.Tag and d.Tag:FindFirstChildOfClass("TextLabel")
if l then l.TextColor3 = colors[n] end
end
end)
dd(ea, "Box Color", cn, "White", function(n) S.BoxColor = colors[n] end)
dd(ea, "Trace Color", cn, "Red", function(n) S.TraceColor = colors[n] end)
sl(ea, "Fill Transparency", 0, 1, S.FillTransparency, 0.05, function(v)
S.FillTransparency = v
for _, d in pairs(tracked) do d.Highlight.FillTransparency = v end
end)
sl(ea, "Outline Transparency", 0, 1, S.OutlineTransparency, 0.05, function(v)
S.OutlineTransparency = v
for _, d in pairs(tracked) do d.Highlight.OutlineTransparency = v end
end)
local MP = addTab("MAP")
local mm = MP:section(1, "MATERIAL")
tg(mm, "Change Material", false, function(v)
M.ChangeMaterial = v
if v then applyAllMat() else restoreMat() end
end)
dl(mm, "Material", matNames, M.Material, function(n)
M.Material = n
if M.ChangeMaterial then applyAllMat() end
end)
local mw = MP:section(2, "WORLD")
tg(mw, "Fullbright", false, function(v)
M.Fullbright = v
if not v then restoreLight({"Brightness", "ClockTime", "Ambient", "OutdoorAmbient"}) end
end)
tg(mw, "No Fog", false, function(v)
M.NoFog = v
if not v then restoreLight({"FogStart", "FogEnd"}) end
end)
local PT = addTab("PLAYER")
local function moveSection(st, col, title, label, slName, min, max)
local sec = PT:section(col, title)
tg(sec, label, false, function(v)
st.Enabled = v
st.Active = false
end)
dd(sec, "Mode", {"Hold Bind", "Toggle Bind"}, st.Mode, function(v)
st.Mode = v
st.Active = false
end)
st.Label = bt(sec, st.Name .. " Bind: " .. st.Bind.Name, function()
st.Binding = true
st.Active = false
st.Label:Set("press a key... (Esc = cancel)")
end)
sl(sec, slName, min, max, st.Value, 1, function(v) st.Value = v end)
end
moveSection(walk, 1, "WALK SPEED", "Walk Speed", "Speed", 16, 200)
moveSection(jump, 1, "JUMP POWER", "Jump Power", "Power", 50, 300)
moveSection(fly, 2, "FLY", "Fly", "Speed", 10, 300)
local sc = addTab("SET"):section(1, "SCRIPT")
MB = bt(sc, "Menu Bind: " .. menuKey.Name, function()
menuBinding = true
MB:Set("press a key... (Esc = cancel)")
end)
bt(sc, "Close Script", function()
S.Enabled = false
S.Boxes = false
S.Traces = false
M.ChangeMaterial = false
M.Fullbright = false
M.NoFog = false
walk.Enabled = false
fly.Enabled = false
jump.Enabled = false
restoreWalk()
restoreJump()
stopFly()
aim.Enabled = false
clearAll()
for _, c in ipairs(K) do c:Disconnect() end
container:Destroy()
fovGui:Destroy()
espGui:Destroy()
restoreMat()
restoreLight({"Brightness", "ClockTime", "Ambient", "OutdoorAmbient", "FogStart", "FogEnd"})
gui:Destroy()
end)
do
local function build()
local HttpService = game:GetService("HttpService")
local okEnv, fenv = pcall(getfenv)
if not okEnv or type(fenv) ~= "table" then fenv = {} end
local WF, RF, IF, LF, DF = fenv.writefile, fenv.readfile, fenv.isfile, fenv.listfiles, fenv.delfile
local IFo, MF = fenv.isfolder, fenv.makefolder
local FS = type(WF) == "function" and type(RF) == "function" and type(IF) == "function" and type(LF) == "function" and type(DF) == "function"
local FOLDER = "MachulaConfigs"
local mem = {}
if FS and type(IFo) == "function" and type(MF) == "function" then
pcall(function() if not IFo(FOLDER) then MF(FOLDER) end end)
end
local function bindStr(b)
return (b.EnumType == E.KeyCode and "K:" or "U:") .. b.Name
end
local function strBind(s)
if type(s) ~= "string" then return nil end
local kind, n = s:match("^(%a):(.+)$")
local enum = (kind == "K" and E.KeyCode) or (kind == "U" and E.UserInputType) or nil
if not enum then return nil end
local ok, v = pcall(function() return enum[n] end)
return ok and v or nil
end
local function collect()
local d = {version = 1, controls = {}, binds = {}}
for _, c in ipairs(CFG.ctl) do d.controls[c.id] = c.get() end
d.binds.aim = bindStr(aim.Bind)
d.binds.walk = bindStr(walk.Bind)
d.binds.fly = bindStr(fly.Bind)
d.binds.jump = bindStr(jump.Bind)
d.binds.menu = bindStr(menuKey)
return d
end
local function apply(d)
if type(d) ~= "table" then return false end
for _, c in ipairs(CFG.ctl) do
local v = type(d.controls) == "table" and d.controls[c.id] or nil
if v ~= nil then pcall(c.set, v) end
end
local b = d.binds
if type(b) == "table" then
local nb = strBind(b.aim)
if nb then
aim.Bind = nb
aim.Active = false
BB:Set("Aim Bind: " .. nb.Name)
end
for _, st in ipairs({walk, fly, jump}) do
local k = strBind(b[st.Name:lower()])
if k then
st.Bind = k
st.Active = false
st.Label:Set(st.Name .. " Bind: " .. k.Name)
end
end
local mk = strBind(b.menu)
if mk and mk.EnumType == E.KeyCode then
menuKey = mk
MB:Set("Menu Bind: " .. mk.Name)
end
end
return true
end
local function clean(s)
s = tostring(s or "")
s = s:gsub("[^%w_%- ]", "")
s = s:gsub("^%s+", "")
s = s:gsub("%s+$", "")
return s:sub(1, 32)
end
local function listNames()
local out = {}
if FS then
local ok, files = pcall(LF, FOLDER)
if ok and type(files) == "table" then
for _, f in ipairs(files) do
local n = tostring(f):match("([^/\\]+)%.json$")
if n then out[#out + 1] = n end
end
end
else
for n in pairs(mem) do out[#out + 1] = n end
end
table.sort(out, function(a, b) return a:lower() < b:lower() end)
return out
end
local function readCfg(name)
local path = FOLDER .. "/" .. name .. ".json"
if FS then
local ok, raw = pcall(function()
if not IF(path) then return nil end
return RF(path)
end)
return ok and raw or nil
end
return mem[name]
end

local box = tabs[#tabs]:section(2, "CONFIGS")
text(box, FS and ("storage: files (" .. FOLDER .. ")") or "storage: session only", GRY, nil, U(1, 0, 0, 14)).TextSize = 11
local nameBox = new("TextBox", {Size = U(1, 0, 0, 24), BackgroundColor3 = BG, Text = "", PlaceholderText = "config name", PlaceholderColor3 = GRY, TextColor3 = WHT, Font = E.Font.Code, TextSize = 13, ClearTextOnFocus = false}, box)
round(nameBox, 4)
local lst = new("ScrollingFrame", {Size = U(1, 0, 0, 110), BackgroundColor3 = BG, ScrollBarThickness = 3, ScrollBarImageColor3 = RED, AutomaticCanvasSize = E.AutomaticSize.Y, CanvasSize = U()}, box)
round(lst, 4)
new("UIPadding", {PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3)}, lst)
list(lst, 2)
local status
local function say(t) status.Text = t end
local function rebuild()
for _, c in ipairs(lst:GetChildren()) do
if c:IsA("TextButton") then c:Destroy() end
end
for _, n in ipairs(listNames()) do
local it = new("TextButton", {Text = n, TextColor3 = (n == clean(nameBox.Text)) and RED or WHT, Size = U(1, -6, 0, 20), BackgroundColor3 = PNL}, lst)
round(it, 3)
it.MouseButton1Click:Connect(function()
nameBox.Text = n
rebuild()
end)
end
end
bt(box, "Save", function()
local name = clean(nameBox.Text)
if name == "" then say("enter a name first") return end
local ok, json = pcall(function() return HttpService:JSONEncode(collect()) end)
if not ok then say("save failed (encode)") return end
if FS then
if not pcall(WF, FOLDER .. "/" .. name .. ".json", json) then say("save failed (write)") return end
else
mem[name] = json
end
nameBox.Text = name
say("saved: " .. name)
rebuild()
end)
bt(box, "Load", function()
local name = clean(nameBox.Text)
if name == "" then say("pick or type a name") return end
local raw = readCfg(name)
if not raw then say("not found: " .. name) return end
local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
if not ok or not apply(data) then say("load failed (bad file)") return end
say("loaded: " .. name)
end)
bt(box, "Delete", function()
local name = clean(nameBox.Text)
if name == "" then say("pick or type a name") return end
if FS then
if not pcall(function() DF(FOLDER .. "/" .. name .. ".json") end) then say("delete failed") return end
else
mem[name] = nil
end
say("deleted: " .. name)
rebuild()
end)
bt(box, "Refresh List", function()
rebuild()
say("list refreshed")
end)
status = text(box, "", GRY, nil, U(1, 0, 0, 14))
status.TextSize = 11
status.TextTruncate = E.TextTruncate.AtEnd
rebuild()
end
build()
end
print("[Machula] loaded")
