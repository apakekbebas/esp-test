local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local maxDistance = 1000

_G.Settings = _G.Settings or { ShowNames = false, ShowDistance = true }

local highlights = {}

local function createBillboard(player)
    local billboard = Instance.new("BillboardGui")
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Parent = billboard
    distanceLabel.Size = UDim2.new(1, 0, 1, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextScaled = true
    distanceLabel.Name = "DistanceLabel"

    return billboard
end

local function createHighlight(player)
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red fill color
    highlight.OutlineColor = Color3.fromRGB(0, 0, 255) -- Blue outline color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Ensures highlight is always visible through walls
    highlight.Parent = game:GetService("CoreGui")
    highlight.Adornee = player.Character -- Associate the highlight with the player's character

    if _G.Settings.ShowDistance then
        local billboard = createBillboard(player)
        billboard.Parent = player.Character:FindFirstChild("HumanoidRootPart")
        highlights[player] = { highlight = highlight, billboard = billboard }
    else
        highlights[player] = { highlight = highlight, billboard = nil }
    end

    print("Highlight created for player:", player.Name)
end

local function isTeammate(player)
    if LocalPlayer.Team then
        return player.Team == LocalPlayer.Team
    else
        return false
    end
end

local function updateESP()
    for player, data in pairs(highlights) do
        if player and player:IsDescendantOf(game) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if rootPart and humanoid and humanoid.Health > 0 then
                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                if distance < maxDistance then
                    data.highlight.Enabled = true

                    if data.billboard then
                        data.billboard.Enabled = true
                        local distanceLabel = data.billboard:FindFirstChild("DistanceLabel")
                        distanceLabel.Text = string.format("%.1f meters", distance / 5) -- Convert studs to meters
                    end
                else
                    data.highlight.Enabled = false
                    if data.billboard then
                        data.billboard.Enabled = false
                    end
                end
            else
                data.highlight.Enabled = false
                if data.billboard then
                    data.billboard.Enabled = false
                end
            end
        else
            data.highlight.Adornee = nil
            data.highlight.Enabled = false
            if data.billboard then
                data.billboard.Enabled = false
            end
        end
    end
end

local function addPlayer(player)
    if player ~= LocalPlayer and not isTeammate(player) then
        createHighlight(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    addPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if highlights[player] then
        highlights[player].highlight:Destroy()
        if highlights[player].billboard then
            highlights[player].billboard:Destroy()
        end
        highlights[player] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    updateESP()
end)

for _, player in ipairs(Players:GetPlayers()) do
    addPlayer(player)
end