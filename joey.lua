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

	local character = player.Character
	if not character then
		return
	end

	if rigs[player] then
		rigs[player].model:Destroy()
		rigs[player] = nil
	end

	local folder = Instance.new("Model")
	folder.Name = "ServerJoey"
	folder.Parent = workspace

	local color = BrickColor.new("Bright yellow").Color

	local root = makePart("Root", folder, Vector3.new(1, 1, 1), color)
	root.Transparency = 1

	local cube = makePart("CubeBody", folder, Vector3.new(4, 4, 4), color)
	local leftLeg = makePart("LeftLeg", folder, Vector3.new(1.2, 4, 1.2), color)
	local rightLeg = makePart("RightLeg", folder, Vector3.new(1.2, 4, 1.2), color)

	folder.PrimaryPart = root

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
		model = folder,
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
