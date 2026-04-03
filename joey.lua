local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TARGET_USERID = 4483107606
local FACE_TEXTURE = "rbxasset://textures/face.png"
local NAME_TEXT = "Joey"
local SPAWN_Y_OFFSET = 15

local activeCharacters = {}
local spawnCounts = {}

local function isTargetPlayer(player)
	return player.UserId == TARGET_USERID
end

local function hideOriginalCharacter(character)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			if obj.Name ~= "HumanoidRootPart" then
				obj.Transparency = 1
				obj.CastShadow = false
			end
		elseif obj:IsA("Decal") then
			obj.Transparency = 1
		elseif obj:IsA("Accessory") then
			local handle = obj:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				handle.Transparency = 1
				handle.CastShadow = false
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
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
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

local function cleanupCharacter(character)
	activeCharacters[character] = nil
end

local function buildJoey(player, character)
	if not isTargetPlayer(player) or activeCharacters[character] then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not root then
		return
	end

	hideOriginalCharacter(character)

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HipHeight = 2
	root.Transparency = 1

	spawnCounts[player.UserId] = (spawnCounts[player.UserId] or 0) + 1
	local yOffset = spawnCounts[player.UserId] * SPAWN_Y_OFFSET
	character:PivotTo(character:GetPivot() + Vector3.new(0, yOffset, 0))

	local color = BrickColor.new("Bright yellow").Color

	local cube = makePart("CubeBody", character, Vector3.new(4, 4, 4), color)
	local leftLeg = makePart("LeftLeg", character, Vector3.new(1.2, 4, 1.2), color)
	local rightLeg = makePart("RightLeg", character, Vector3.new(1.2, 4, 1.2), color)

	cube.CFrame = root.CFrame
	leftLeg.CFrame = cube.CFrame * CFrame.new(-1, -4, 0)
	rightLeg.CFrame = cube.CFrame * CFrame.new(1, -4, 0)

	local rootBaseC0 = CFrame.new(0, 0, 0)
	local leftBaseC0 = CFrame.new(-1, -2, 0)
	local rightBaseC0 = CFrame.new(1, -2, 0)

	local rootMotor = makeMotor("CubeRoot", root, cube, rootBaseC0, CFrame.new(), root)
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
	tag.StudsOffset = Vector3.new(0, 3.5, 0)
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

	activeCharacters[character] = {
		humanoid = humanoid,
		rootMotor = rootMotor,
		rootBaseC0 = rootBaseC0,
		leftHip = leftHip,
		rightHip = rightHip,
		leftBaseC0 = leftBaseC0,
		rightBaseC0 = rightBaseC0,
	}

	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			cleanupCharacter(character)
		end
	end)

	print("Joey rig applied to UserId", player.UserId)
end

local function setupPlayer(player)
	if not isTargetPlayer(player) then
		return
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.25)
		buildJoey(player, character)
	end)

	if player.Character then
		task.defer(function()
			task.wait(0.25)
			buildJoey(player, player.Character)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

RunService.Heartbeat:Connect(function()
	for character, data in pairs(activeCharacters) do
		if not character.Parent then
			activeCharacters[character] = nil
			continue
		end

		local humanoid = data.humanoid
		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		local moving = humanoid.MoveDirection.Magnitude > 0.05
		local speedScale = math.clamp(humanoid.WalkSpeed / 16, 0.6, 2)
		local t = os.clock()

		if moving then
			local swing = math.sin(t * 8 * speedScale) * math.rad(35)
			local bob = math.abs(math.sin(t * 8 * speedScale)) * 0.45

			data.rootMotor.C0 = data.rootBaseC0 * CFrame.new(0, bob, 0)
			data.leftHip.C0 = data.leftBaseC0 * CFrame.Angles(swing, 0, 0)
			data.rightHip.C0 = data.rightBaseC0 * CFrame.Angles(-swing, 0, 0)
		else
			local idleBob = math.sin(t * 2) * 0.08
			local idleSwing = math.sin(t * 2) * math.rad(4)

			data.rootMotor.C0 = data.rootBaseC0 * CFrame.new(0, idleBob, 0)
			data.leftHip.C0 = data.leftBaseC0 * CFrame.Angles(idleSwing, 0, 0)
			data.rightHip.C0 = data.rightBaseC0 * CFrame.Angles(-idleSwing, 0, 0)
		end
	end
end)
