local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local remote = ReplicatedStorage:FindFirstChild("JoeyPoseSync")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "JoeyPoseSync"
	remote.Parent = ReplicatedStorage
end

local starterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
if not starterPlayerScripts then
	starterPlayerScripts = Instance.new("StarterPlayerScripts")
	starterPlayerScripts.Parent = StarterPlayer
end

local localScriptSource = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("JoeyPoseSync")

local TARGET_USERNAME = "Huwswhssou2"
local FACE_TEXTURE = "rbxasset://textures/face.png"
local NAME_TEXT = "Joey"
local SPAWN_HEIGHT_OFFSET = 15

local activeData

local function hideOriginalCharacter(character)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name ~= "HumanoidRootPart" then
				obj.Transparency = 1
				obj.CanCollide = false
				obj.CanQuery = false
				obj.CanTouch = false
			end
			obj.CastShadow = false
		elseif obj:IsA("Decal") then
			obj.Transparency = 1
		elseif obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle then
				handle.Transparency = 1
				handle.CanCollide = false
				handle.CanQuery = false
				handle.CanTouch = false
			end
		end
	end
end

local function makePart(name, parent, size, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Anchored = false
	part.Massless = true
	part.Parent = parent
	return part
end

local function makeMotor(name, part0, part1, c0, c1, parent)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.C1 = c1
	motor.Parent = parent
	return motor
end

local function buildLocalJoey(character)
	if player.Name ~= TARGET_USERNAME then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end

	character:PivotTo(character:GetPivot() + Vector3.new(0, SPAWN_HEIGHT_OFFSET, 0))
	hideOriginalCharacter(character)

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.AutoRotate = true
	humanoid.HipHeight = 2.5

	root.Transparency = 1
	root.CanCollide = false

	local color = BrickColor.new("Bright yellow").Color

	local cube = makePart("CubeBody", character, Vector3.new(4, 4, 4), color)
	cube.CFrame = root.CFrame + Vector3.new(0, 0.5, 0)

	makeMotor("CubeRoot", root, cube, CFrame.new(0, 0.5, 0), CFrame.new(), root)

	local face = Instance.new("Decal")
	face.Name = "SmileFace"
	face.Texture = FACE_TEXTURE
	face.Face = Enum.NormalId.Front
	face.Parent = cube

	local tag = Instance.new("BillboardGui")
	tag.Name = "CubeNametag"
	tag.Size = UDim2.new(0, 140, 0, 36)
	tag.StudsOffset = Vector3.new(0, 3.6, 0)
	tag.AlwaysOnTop = true
	tag.Parent = cube

	local tagLabel = Instance.new("TextLabel")
	tagLabel.BackgroundTransparency = 1
	tagLabel.Size = UDim2.fromScale(1, 1)
	tagLabel.Font = Enum.Font.GothamBold
	tagLabel.Text = NAME_TEXT
	tagLabel.TextColor3 = Color3.new(1, 1, 1)
	tagLabel.TextStrokeTransparency = 0
	tagLabel.TextScaled = true
	tagLabel.Parent = tag

	local leftLeg = makePart("LeftLeg", character, Vector3.new(1.2, 4, 1.2), color)
	local rightLeg = makePart("RightLeg", character, Vector3.new(1.2, 4, 1.2), color)

	leftLeg.CFrame = cube.CFrame * CFrame.new(-1, -4, 0)
	rightLeg.CFrame = cube.CFrame * CFrame.new(1, -4, 0)

	local leftBaseC0 = CFrame.new(-1, -2, 0)
	local rightBaseC0 = CFrame.new(1, -2, 0)

	local leftHip = makeMotor("LeftHip", cube, leftLeg, leftBaseC0, CFrame.new(0, 2, 0), cube)
	local rightHip = makeMotor("RightHip", cube, rightLeg, rightBaseC0, CFrame.new(0, 2, 0), cube)

	activeData = {
		character = character,
		humanoid = humanoid,
		root = root,
		leftHip = leftHip,
		rightHip = rightHip,
		leftBaseC0 = leftBaseC0,
		rightBaseC0 = rightBaseC0,
		lastSend = 0,
	}
end

local function onCharacterAdded(character)
	activeData = nil
	task.wait(0.2)
	buildLocalJoey(character)
end

if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

RunService.RenderStepped:Connect(function()
	local data = activeData
	if not data or not data.character or not data.character.Parent then
		return
	end

	local humanoid = data.humanoid
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local moving = humanoid.MoveDirection.Magnitude > 0.05
	local speedScale = math.clamp(humanoid.WalkSpeed / 16, 0.6, 2)
	local t = os.clock()

	if moving then
		local swing = math.sin(t * 8 * speedScale) * math.rad(35)
		data.leftHip.C0 = data.leftBaseC0 * CFrame.Angles(swing, 0, 0)
		data.rightHip.C0 = data.rightBaseC0 * CFrame.Angles(-swing, 0, 0)
	else
		local idleSwing = math.sin(t * 2) * math.rad(4)
		data.leftHip.C0 = data.leftBaseC0 * CFrame.Angles(idleSwing, 0, 0)
		data.rightHip.C0 = data.rightBaseC0 * CFrame.Angles(-idleSwing, 0, 0)
	end

	local now = tick()
	if now - data.lastSend >= 0.05 then
		data.lastSend = now
		remote:FireServer({
			rootCFrame = data.root.CFrame,
			leftHipC0 = data.leftHip.C0,
			rightHipC0 = data.rightHip.C0,
		})
	end
end)
]==]

local serverScriptSource = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("JoeyPoseSync")

local TARGET_USERNAME = "Huwswhssou2"
local FACE_TEXTURE = "rbxasset://textures/face.png"
local NAME_TEXT = "Joey"

local rigs = {}

local function makePart(name, parent, size, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Anchored = false
	part.Massless = true
	part.Parent = parent
	return part
end

local function makeMotor(name, part0, part1, c0, c1, parent)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.C1 = c1
	motor.Parent = parent
	return motor
end

local function createServerJoey(player)
	if player.Name ~= TARGET_USERNAME then
		return
	end

	if rigs[player] then
		rigs[player].model:Destroy()
		rigs[player] = nil
	end

	local model = Instance.new("Model")
	model.Name = "ServerJoey"
	model.Parent = workspace

	local color = BrickColor.new("Bright yellow").Color

	local root = makePart("Root", model, Vector3.new(1, 1, 1), color)
	root.Transparency = 1

	local cube = makePart("CubeBody", model, Vector3.new(4, 4, 4), color)
	local leftLeg = makePart("LeftLeg", model, Vector3.new(1.2, 4, 1.2), color)
	local rightLeg = makePart("RightLeg", model, Vector3.new(1.2, 4, 1.2), color)

	model.PrimaryPart = root

	makeMotor("CubeRoot", root, cube, CFrame.new(0, 0.5, 0), CFrame.new(), root)

	local leftBaseC0 = CFrame.new(-1, -2, 0)
	local rightBaseC0 = CFrame.new(1, -2, 0)

	local leftHip = makeMotor("LeftHip", cube, leftLeg, leftBaseC0, CFrame.new(0, 2, 0), cube)
	local rightHip = makeMotor("RightHip", cube, rightLeg, rightBaseC0, CFrame.new(0, 2, 0), cube)

	local face = Instance.new("Decal")
	face.Name = "SmileFace"
	face.Texture = FACE_TEXTURE
	face.Face = Enum.NormalId.Front
	face.Parent = cube

	local tag = Instance.new("BillboardGui")
	tag.Name = "CubeNametag"
	tag.Size = UDim2.new(0, 140, 0, 36)
	tag.StudsOffset = Vector3.new(0, 3.6, 0)
	tag.AlwaysOnTop = true
	tag.Parent = cube

	local tagLabel = Instance.new("TextLabel")
	tagLabel.BackgroundTransparency = 1
	tagLabel.Size = UDim2.fromScale(1, 1)
	tagLabel.Font = Enum.Font.GothamBold
	tagLabel.Text = NAME_TEXT
	tagLabel.TextColor3 = Color3.new(1, 1, 1)
	tagLabel.TextStrokeTransparency = 0
	tagLabel.TextScaled = true
	tagLabel.Parent = tag

	rigs[player] = {
		model = model,
		root = root,
		leftHip = leftHip,
		rightHip = rightHip,
	}
end

local function cleanup(player)
	if rigs[player] then
		rigs[player].model:Destroy()
		rigs[player] = nil
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		createServerJoey(player)
	end)

	player.AncestryChanged:Connect(function(_, parent)
		if not parent then
			cleanup(player)
		end
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(function()
			task.wait(0.2)
			createServerJoey(player)
		end)
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		createServerJoey(player)
	end)
end

remote.OnServerEvent:Connect(function(player, pose)
	if player.Name ~= TARGET_USERNAME then
		return
	end

	local rig = rigs[player]
	if not rig or not pose then
		return
	end

	if typeof(pose.rootCFrame) == "CFrame" then
		rig.root.CFrame = pose.rootCFrame
	end

	if typeof(pose.leftHipC0) == "CFrame" then
		rig.leftHip.C0 = pose.leftHipC0
	end

	if typeof(pose.rightHipC0) == "CFrame" then
		rig.rightHip.C0 = pose.rightHipC0
	end
end)
]==]

local localScript = starterPlayerScripts:FindFirstChild("JoeyClient")
if not localScript then
	localScript = Instance.new("LocalScript")
	localScript.Name = "JoeyClient"
	localScript.Parent = starterPlayerScripts
end
localScript.Source = localScriptSource

local serverScript = ServerScriptService:FindFirstChild("JoeyServer")
if not serverScript then
	serverScript = Instance.new("Script")
	serverScript.Name = "JoeyServer"
	serverScript.Parent = ServerScriptService
end
serverScript.Source = serverScriptSource

print("Created JoeyClient, JoeyServer, and JoeyPoseSync.")
