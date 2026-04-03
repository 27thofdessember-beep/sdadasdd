local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local FLICKER_TIME = 2
local BUILDUP_TIME = 30
local KICK_MESSAGE = "Everything goes red."

local colorCorrection = Lighting:FindFirstChild("BloodRedFX") or Instance.new("ColorCorrectionEffect")
colorCorrection.Name = "BloodRedFX"
colorCorrection.Parent = Lighting

local blur = Lighting:FindFirstChild("BloodBlurFX") or Instance.new("BlurEffect")
blur.Name = "BloodBlurFX"
blur.Parent = Lighting

local originalBrightness = Lighting.Brightness
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalClockTime = Lighting.ClockTime

colorCorrection.Brightness = 0
colorCorrection.Contrast = 0
colorCorrection.Saturation = 0
colorCorrection.TintColor = Color3.new(1, 1, 1)

blur.Size = 0

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
end

local function spinSkyAndKick()
	local startTime = tick()
	local stopAt = startTime + BUILDUP_TIME

	occasionalBlur(stopAt)

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local elapsed = tick() - startTime
		local alpha = math.clamp(elapsed / BUILDUP_TIME, 0, 1)

		local speed = 0.08 + (alpha ^ 2.2) * 9
		Lighting.ClockTime = (Lighting.ClockTime + speed * dt) % 24

		if elapsed >= BUILDUP_TIME then
			connection:Disconnect()

			for _, player in ipairs(Players:GetPlayers()) do
				player:Kick(KICK_MESSAGE)
			end
		end
	end)
end

flickerPhase()
lockInFinalLook()
spinSkyAndKick()
