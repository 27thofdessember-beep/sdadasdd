local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FLICKER_TIME = 2
local BUILDUP_TIME = 30
local KICK_MESSAGE = "#E#A#E#F#G#U#J#G#S#3#5#YH#B#5#H6#J#6#J6JT5TYH#5#H56#HH56H#56#J56JY5#"

local remote = ReplicatedStorage:FindFirstChild("BloodEventFX") or Instance.new("RemoteEvent")
remote.Name = "BloodEventFX"
remote.Parent = ReplicatedStorage

local colorCorrection = Lighting:FindFirstChild("BloodRedFX") or Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "BloodRedFX"
colorCorrection.Parent = Lighting

local blur = Lighting:FindFirstChild("BloodBlurFX") or Instance.new("BlurEffect")
blur.Name = "BloodBlurFX"
blur.Parent = Lighting

local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient

colorCorrection.Brightness = 0
colorCorrection.Contrast = 0
colorCorrection.Saturation = 0
colorCorrection.TintColor = Color3.new(1, 1, 1)

blur.Size = 0

local function addDistortionToSound(sound)
	if not sound:IsA("Sound") then
		return
	end

	local existing = sound:FindFirstChild("BloodDistortion")
	if existing then
		return
	end

	local distortion = Instance.new("DistortionSoundEffect")
	distortion.Name = "BloodDistortion"
	distortion.Level = 0.82
	distortion.Priority = 10
	distortion.Parent = sound
end

local distortionEnabled = false
local soundAddedConnection

local function enableGlobalDistortion()
	if distortionEnabled then
		return
	end
	distortionEnabled = true

	for _, descendant in ipairs(game:GetDescendants()) do
		if descendant:IsA("Sound") then
			addDistortionToSound(descendant)
		end
	end

	soundAddedConnection = game.DescendantAdded:Connect(function(descendant)
		if distortionEnabled and descendant:IsA("Sound") then
			addDistortionToSound(descendant)
		end
	end)
end

local function setupPlayerCameraShake(player)
	local playerGui = player:WaitForChild("PlayerGui")

	if playerGui:FindFirstChild("BloodShakeClient") then
		return
	end

	local localScript = Instance.new("LocalScript")
	localScript.Name = "BloodShakeClient"
	localScript.Source = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remote = ReplicatedStorage:WaitForChild("BloodEventFX")

local shaking = false
local buildStart = 0
local buildDuration = 30
local conn

local function noise(t, scale)
	return (math.noise(t, scale, 0) * 2)
end

remote.OnClientEvent:Connect(function(action, startTime, duration)
	if action ~= "StartShake" then
		return
	end

	buildStart = startTime
	buildDuration = duration
	shaking = true

	if conn then
		conn:Disconnect()
	end

	conn = RunService.RenderStepped:Connect(function()
		if not shaking then
			return
		end

		camera = workspace.CurrentCamera
		if not camera then
			return
		end

		local elapsed = workspace:GetServerTimeNow() - buildStart
		local alpha = math.clamp(elapsed / buildDuration, 0, 1)

		local posAmount = 0.015 + (alpha ^ 2.2) * 0.6
		local rotAmount = 0.15 + (alpha ^ 2.2) * 2.8
		local t = tick() * (3 + alpha * 18)

		local offset = Vector3.new(
			noise(t, 1.13) * posAmount,
			noise(t, 2.37) * posAmount,
			0
		)

		local rx = math.rad(noise(t, 3.91) * rotAmount)
		local ry = math.rad(noise(t, 5.27) * rotAmount)
		local rz = math.rad(noise(t, 7.41) * (rotAmount * 1.4))

		camera.CFrame = camera.CFrame * CFrame.new(offset) * CFrame.Angles(rx, ry, rz)

		if alpha >= 1 then
			shaking = false
			if conn then
				conn:Disconnect()
			end
		end
	end)
end)
]]
	localScript.Parent = playerGui
end

local function flickerPhase()
	local startTime = tick()

	while tick() - startTime < FLICKER_TIME do
		local on = math.random() > 0.45

		if on then
			Lighting.Brightness = math.random(0, 5) / 10
			Lighting.Ambient = Color3.fromRGB(math.random(0, 40), 0, 0)
			Lighting.OutdoorAmbient = Color3.fromRGB(math.random(0, 25), 0, 0)

			colorCorrection.Brightness = -0.1 - math.random() * 0.25
			colorCorrection.Contrast = 0.2 + math.random() * 0.5
			colorCorrection.Saturation = -0.2 - math.random() * 0.8
			colorCorrection.TintColor = Color3.fromRGB(255, math.random(0, 35), math.random(0, 35))
		else
			Lighting.Brightness = originalBrightness
			Lighting.Ambient = originalAmbient
			Lighting.OutdoorAmbient = originalOutdoorAmbient

			colorCorrection.Brightness = 0
			colorCorrection.Contrast = 0
			colorCorrection.Saturation = 0
			colorCorrection.TintColor = Color3.new(1, 1, 1)
		end

		task.wait(math.random(4, 12) / 100)
	end
end

local function occasionalBlur(stopAt)
	task.spawn(function()
		while tick() < stopAt do
			task.wait(math.random(12, 28) / 10)

			if tick() >= stopAt then
				break
			end

			local blurIn = TweenService:Create(blur, TweenInfo.new(0.15), {
				Size = math.random(18, 32)
			})
			blurIn:Play()
			blurIn.Completed:Wait()

			task.wait(math.random(10, 30) / 100)

			local blurOut = TweenService:Create(blur, TweenInfo.new(0.2), {
				Size = 2
			})
			blurOut:Play()
		end
	end)
end

local function lockInFinalLook()
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)

	local tween = TweenService:Create(
		colorCorrection,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Brightness = -0.7,
			Contrast = 1,
			Saturation = -1,
			TintColor = Color3.fromRGB(180, 0, 0)
		}
	)

	tween:Play()
	blur.Size = 2
	enableGlobalDistortion()
end

local function beginShake(buildStartTime)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerCameraShake(player)
		remote:FireClient(player, "StartShake", buildStartTime, BUILDUP_TIME)
	end
end

local function spinSkyAndKick()
	local startTime = workspace:GetServerTimeNow()
	local stopAt = tick() + BUILDUP_TIME

	occasionalBlur(stopAt)
	beginShake(startTime)

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local elapsed = workspace:GetServerTimeNow() - startTime
		local alpha = math.clamp(elapsed / BUILDUP_TIME, 0, 1)

		local speed = 0.08 + (alpha ^ 2.2) * 9
		Lighting.ClockTime = (Lighting.ClockTime + speed * dt) % 24

		if elapsed >= BUILDUP_TIME then
			connection:Disconnect()

			if soundAddedConnection then
				soundAddedConnection:Disconnect()
			end

			for _, player in ipairs(Players:GetPlayers()) do
				player:Kick(KICK_MESSAGE)
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	setupPlayerCameraShake(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayerCameraShake(player)
end

flickerPhase()
lockInFinalLook()
spinSkyAndKick()

