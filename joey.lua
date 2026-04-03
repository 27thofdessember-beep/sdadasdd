local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TARGET_USERID = 4483107606
local FACE_TEXTURE = "rbxasset://textures/face.png"
local NAME_TEXT = "Joey"
local SPAWN_Y_OFFSET = 15

local active = {}

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

local function hideOriginalCharacter(character)
	for _, obj in ipairs(character:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = 1
			obj.CastShadow = false
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

local function clearMorph(character)
	local old = character:FindFirstChild("JoeyMorph")
	if old then
		old:Destroy()
	end
	active[character] = nil
end

local function applyMorph(player, character)
	if player.UserId ~= TARGET_USERID then
		return
	end

	clearMorph(character)

	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not root then
		return
	end

	local leftFoot = character:FindFirstChild("LeftFoot")
	local rightFoot = character:FindFirstChild("RightFoot")
	local upperTorso = character:FindFirstChild("UpperTorso")

	local isR6 = false
	if not (leftFoot and rightFoot and upperTorso) then
		leftFoot = character:FindFirstChild("Left Leg")
		rightFoot = character:FindFirstChild("Right Leg")
		upperTorso = character:FindFirstChild("Torso")
		isR6 = true
	end

	if not (leftFoot and rightFoot and upperTorso) then
		warn("Joey morph could not find required rig parts for", player.Name)
		return
	end

	character:PivotTo(character:GetPivot() + Vector3.new(0, SPAWN_Y_OFFSET, 0))
	hideOriginalCharacter(character)

	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	root.Transparency = 1

	local model = Instance.new("Model")
	model.Name = "JoeyMorph"
	model.Parent = character

	local yellow = BrickColor.new("Bright yellow").Color

	local body = makePart("CubeBody", model, Vector3.new(4, 4, 4), yellow)
	body.CFrame = upperTorso.CFrame

	local bodyMotor = Instance.new("Motor6D")
	bodyMotor.Name = "BodyMotor"
	bodyMotor.Part0 = root
	bodyMotor.Part1 = body
	bodyMotor.C0 = CFrame.new(0, 0, 0)
	bodyMotor.C1 = CFrame.new()
	bodyMotor.Parent = root

	local bodyBaseC0 = bodyMotor.C0

	local leftLeg = makePart("LeftLeg", model, Vector3.new(1.2, 4, 1.2), yellow)
	local rightLeg = makePart("RightLeg", model, Vector3.new(1.2, 4, 1.2), yellow)

	leftLeg.CFrame = leftFoot.CFrame * CFrame.new(0, 2, 0)
	rightLeg.CFrame = rightFoot.CFrame * CFrame.new(0, 2, 0)

	local leftMotor = Instance.new("Motor6D")
	leftMotor.Name = "LeftLegMotor"
	leftMotor.Part0 = body
	leftMotor.Part1 = leftLeg
	leftMotor.C0 = CFrame.new(-1, -2, 0)
	leftMotor.C1 = CFrame.new(0, 2, 0)
	leftMotor.Parent = body

	local rightMotor = Instance.new("Motor6D")
	rightMotor.Name = "RightLegMotor"
	rightMotor.Part0 = body
	rightMotor.Part1 = rightLeg
	rightMotor.C0 = CFrame.new(1, -2, 0)
	rightMotor.C1 = CFrame.new(0, 2, 0)
	rightMotor.Parent = body

	local face = Instance.new("Decal")
	face.Name = "Face"
	face.Texture = FACE_TEXTURE
	face.Face = Enum.NormalId.Front
	face.Parent = body

	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.new(0, 140, 0, 36)
	tag.StudsOffset = Vector3.new(0, 3.5, 0)
	tag.AlwaysOnTop = true
	tag.Parent = body

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = NAME_TEXT
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Parent = tag

	active[character] = {
		humanoid = humanoid,
		bodyMotor = bodyMotor,
		bodyBaseC0 = bodyBaseC0,
		leftMotor = leftMotor,
		rightMotor = rightMotor,
		leftBaseC0 = leftMotor.C0,
		rightBaseC0 = rightMotor.C0,
		isR6 = isR6,
	}

	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			active[character] = nil
		end
	end)
end

local function setupPlayer(player)
	if player.UserId ~= TARGET_USERID then
		return
	end

	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		applyMorph(player, character)
	end)

	if player.Character then
		task.defer(function()
			task.wait(0.2)
			applyMorph(player, player.Character)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

RunService.Heartbeat:Connect(function()
	for character, data in pairs(active) do
		if not character.Parent then
			active[character] = nil
			continue
		end

		local humanoid = data.humanoid
		if not humanoid or humanoid.Health <= 0 then
			continue
		end

		local moving = humanoid.MoveDirection.Magnitude > 0.05
		local t = os.clock()
		local speedScale = math.clamp(humanoid.WalkSpeed / 16, 0.6, 2)

		if moving then
			local swing = math.sin(t * 8 * speedScale) * math.rad(35)
			local bob = math.abs(math.sin(t * 8 * speedScale)) * 0.35

			data.bodyMotor.C0 = data.bodyBaseC0 * CFrame.new(0, bob, 0)
			data.leftMotor.C0 = data.leftBaseC0 * CFrame.Angles(swing, 0, 0)
			data.rightMotor.C0 = data.rightBaseC0 * CFrame.Angles(-swing, 0, 0)
		else
			local idleBob = math.sin(t * 2) * 0.05
			local idleSwing = math.sin(t * 2) * math.rad(4)

			data.bodyMotor.C0 = data.bodyBaseC0 * CFrame.new(0, idleBob, 0)
			data.leftMotor.C0 = data.leftBaseC0 * CFrame.Angles(idleSwing, 0, 0)
			data.rightMotor.C0 = data.rightBaseC0 * CFrame.Angles(-idleSwing, 0, 0)
		end
	end
end)
