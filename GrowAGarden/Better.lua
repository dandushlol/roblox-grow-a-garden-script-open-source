local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmsFolder = Workspace.Farm
local Players = game:GetService("Players")
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local Plant = ReplicatedStorage.GameEvents.Plant_RE
local Backpack = Players.LocalPlayer.Backpack
local Character = Players.LocalPlayer.Character
local sellAllRemote = ReplicatedStorage.GameEvents.Sell_Inventory
local Steven = Workspace.NPCS.Steven
local Sam = Workspace.NPCS.Sam
local HRP = Players.LocalPlayer.Character.HumanoidRootPart
local CropsListAndStocks = {}
local SeedShopGUI = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame.ScrollingFrame
local shopTimer = Players.LocalPlayer.PlayerGui.Seed_Shop.Frame.Frame.Timer
local shopTime = 0
local Humanoid = Character:WaitForChild("Humanoid")
wantedFruits = {}
local plantAura = false
local AutoSellItems = 70
local shouldSell = false
local removeItem = ReplicatedStorage.GameEvents.Remove_Item
local plantToRemove
local shouldAutoPlant = false
local isSelling = false
local byteNetReliable = ReplicatedStorage:FindFirstChild("ByteNetReliable")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "Grow A Garden",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Rayfield Interface Suite",
   LoadingSubtitle = "by Sirius",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "GAGscript"
   },

})

local function findPlayerFarm()
    for i,v in pairs(FarmsFolder:GetChildren()) do
        if v.Important.Data.Owner.Value == Players.LocalPlayer.Name then
            return v
        end
    end
return nil
end

local function removePlantsOfKind(kind)
    print("Kind: "..kind[1])
    local Shovel = Backpack:FindFirstChild("Shovel [Destroy Plants]")
    Shovel.Parent = Character
    for _,plant in pairs(findPlayerFarm().Important.Plants_Physical:GetChildren()) do
        if plant.Name == kind[1] then
            if plant:FindFirstChild("Fruit_Spawn") then
                local spawnPoint = plant.Fruit_Spawn
                HRP.CFrame = plant.PrimaryPart.CFrame
                wait(0.2)
                removeItem:FireServer(spawnPoint)
            end
        end
    end 
end

local function getAllIFromDict(Dict)
    local newList = {}
    for i,_ in Dict do
        table.insert(newList, i)
    end
    return newList
end

local function isInTable(table,value)
    for _,i in pairs(table) do
        if i==value then
            return true
        end
    end
    return false
end

local function getPlantedFruitTypes()
local list = {}
    for _,plant in pairs(findPlayerFarm().Important.Plants_Physical:GetChildren()) do
        if not(isInTable(list, plant.Name)) then
            table.insert(list, plant.Name)
        end
    end
    return list
end

local Tab = Window:CreateTab("Plants", "rewind")
Tab:CreateSection("Remove Plants")
local PlantToRemoveDropdown = Tab:CreateDropdown({
   Name = "Choose A Plant To Remove",
   Options = getPlantedFruitTypes(),
   CurrentOption = {"None Selected"},
   MultipleOptions = false,
   Flag = "Dropdown1", 
   Callback = function(Options)
    plantToRemove = Options
   end,
})

Tab:CreateButton({
    Name = "Refresh Selection",
    Callback = function()
        PlantToRemoveDropdown:Refresh(getPlantedFruitTypes())
    end,
})

Tab:CreateButton({
    Name = "Remove Selected Plant",
    Callback = function()
        removePlantsOfKind(plantToRemove)
    end,
})

Tab:CreateSection("Harvesting Plants")





local function printCropStocks()
    for i,v in pairs(CropsListAndStocks) do
        print(i.."'s Stock Is:", v)
    end
end

local function StripPlantStock(UnstrippedStock)
    -- takes for example X0 stock and returns 0, basically returns the plain string number
local num = string.match(UnstrippedStock, "%d+")
return num
end

function getCropsListAndStock()
    for _,Plant in pairs(SeedShopGUI:GetChildren()) do
        if Plant:FindFirstChild("Main_Frame") then
            local PlantName = Plant.Name
            local PlantStock = StripPlantStock(Plant.Main_Frame.Stock_Text.Text)
            CropsListAndStocks[PlantName] = PlantStock
        end
    end
end

playerFarm = findPlayerFarm()
getCropsListAndStock()

local function getPlantingBoundaries(farm)
    local offset = Vector3.new(15.2844,0,28.356)
    local edges = {}
    local PlantingLocations = farm.Important.Plant_Locations:GetChildren()
    local rect1Center = PlantingLocations[1].Position
    local rect2Center = PlantingLocations[2].Position
    edges["1TopLeft"] = rect1Center + offset
    edges["1BottomRight"] = rect1Center - offset
    edges["2TopLeft"] = rect2Center + offset
    edges["2BottomRight"] = rect2Center - offset
    return edges
end



spawn(function()
    while true do
        if plantAura then
            print("Attempting to pickup plants")
            for _, Plant in pairs(playerFarm.Important.Plants_Physical:GetChildren()) do

                if Plant:FindFirstChild("Fruits") then

                    for _, miniPlant in pairs(Plant.Fruits:GetChildren()) do

                        for _, child in pairs(miniPlant:GetChildren()) do

                            if child:FindFirstChild("ProximityPrompt") then
                                fireproximityprompt(child.ProximityPrompt)
                            end
                        end
                        task.wait(0.01)
                    end
                else

                    for _, child in pairs(Plant:GetChildren()) do

                        if child:FindFirstChild("ProximityPrompt") then
                            fireproximityprompt(child.ProximityPrompt)
                        end
                        task.wait(0.01) -- brb i go make me some food alright
                    end
                end
            end
            task.wait(0.1)
        end

        task.wait(0.1)
    end
end)

local function collectPlant(plant : Model)
    byteNetReliable:FireServer(buffer.fromstring("\001\001\000\001"),{ plant }) -- this one
    print("Collecting: "..plant.Name)
end

local function GetAllPlants()
    local plantsTable = {}
    for _, Plant in pairs(playerFarm.Important.Plants_Physical:GetChildren()) do
        if Plant:FindFirstChild("Fruits") then
            for _, miniPlant in pairs(Plant.Fruits:GetChildren()) do
                table.insert(plantsTable,miniPlant)
            end
        else
            table.insert(plantsTable,Plant)
        end
    end
    return plantsTable
end
local function CollectAllPlants()
    local plants = GetAllPlants()
    print("Got "..#plants.."Plants")

    for _,plant in pairs(plants) do
        collectPlant(plant)
        task.wait(0.01)
    end
end

Tab:CreateButton(
{
    Name = "Collect All Plants",
    Callback = function()
        CollectAllPlants()
        print("Collecting All Plants")
    end,
})


local function getRandomPlantingLocation(edges)
    -- Define rectangle corner pairs from the dictionary
    local rectangles = {
        {edges["1TopLeft"], edges["1BottomRight"]},
        {edges["2TopLeft"], edges["2BottomRight"]}
    }

    -- Choose a rectangle randomly
    local chosen = rectangles[math.random(1, #rectangles)]
    local a = chosen[1]
    local b = chosen[2]

    -- Get min/max bounds
    local minX, maxX = math.min(a.X, b.X), math.max(a.X, b.X)
    local minZ, maxZ = math.min(a.Z, b.Z), math.max(a.Z, b.Z)
    local Y = 0.13552704453468323

    -- Generate random point in bounds
    local randX = math.random() * (maxX - minX) + minX
    local randZ = math.random() * (maxZ - minZ) + minZ

    return CFrame.new(randX, Y, randZ)
end
local function areThereSeeds()
for _,Item in pairs(Backpack:GetChildren()) do
    if Item:FindFirstChild("Seed Local Script") then
        return true
    end
end
print("Seeds Not Found!")
return false
end

local function plantAllSeeds()
    print("Planting All Seeds...")
    task.wait(1)
    while areThereSeeds() do
        print("There Are Seeds!")
        for _,Item in pairs(Backpack:GetChildren()) do
            if Item:FindFirstChild("Seed Local Script") then
                Item.Parent = Character
                wait(0.1)
                local location = getRandomPlantingLocation(getPlantingBoundaries(playerFarm))
                local args = {
                    [1] = location.Position,
                    [2] = Item:GetAttribute("Seed")
                }
                Plant:FireServer(unpack(args))
                wait()
                if Item and Item:IsDescendantOf(game) and Item.Parent ~= Backpack then
                    pcall(function()
                        Item.Parent = Backpack
                    end)
                end
            end
        end
    end
end

Tab:CreateToggle({
   Name = "Harvest Plants Aura",
   CurrentValue = false,
   Flag = "Toggle1",
   Callback = function(Value)
    plantAura = Value
    print("Plant Aura Set To: ".. tostring(Value))
   end,
})
local testingTab = Window:CreateTab("Testing","rewind")
testingTab:CreateSection("List Crops Names And Prices")
testingTab:CreateButton(
{
    Name = "Print Out All Crops Names And Stocks",
    Callback = function()
        printCropStocks()
        print("Printed")
    end,
})
Tab:CreateSection("Plant")
Tab:CreateButton(
{
    Name = "Plant all Seeds",
    Callback = function()
        plantAllSeeds()
    end,
})
Tab:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    flag = "ToggleAutoPlant",
    Callback = function(Value)
        shouldAutoPlant = Value
    end,
})
testingTab:CreateSection("Shop")
local RayFieldShopTimer = testingTab:CreateParagraph({Title = "Shop Timer", Content = "Waiting..."})

testingTab:CreateSection("Plot Corners")
testingTab:CreateButton(
{
    Name = "Teleport edges",
    Callback = function()
        local edges = getPlantingBoundaries(playerFarm)
        for i,v in edges do
            HRP.CFrame = CFrame.new(v)
            wait(2)
        end
    end,
})

testingTab:CreateButton(
{
    Name = "Teleport random plantable position",
    Callback = function()
        HRP.CFrame = getRandomPlantingLocation(getPlantingBoundaries(playerFarm))
    end,
})

local function buyCropSeeds(cropName)

local args = 
{
[1] = cropName
}

BuySeedStock:FireServer(unpack(args))

end



function buyWantedCropSeeds()
    local beforePos = HRP.CFrame
    wait()
    HRP.CFrame = Sam.HumanoidRootPart.CFrame
    wait(0.1)
    for i in wantedFruits do
        for j = 0,CropsListAndStocks[wantedFruits[i]] do
            buyCropSeeds(wantedFruits[i])
        end
    end
    wait()
    HRP.CFrame = beforePos
    print("Should Auto Plant: "..tostring(shouldAutoPlant))
    if shouldAutoPlant then
        print("Entered Auto Plant Function")
        plantAllSeeds()
    end
end

local function onShopRefresh()
    print("Shop Refreshed")
    getCropsListAndStock()
    if wantedFruits ~= "None Selected" then
        buyWantedCropSeeds()
    end
end

local function getTimeInSeconds(input)
    local minutes = tonumber(input:match("(%d+)m")) or 0
    local seconds = tonumber(input:match("(%d+)s")) or 0
    return minutes * 60 + seconds
end

local function sellAll()
    local OrgPos = HRP.CFrame
    HRP.CFrame = Steven.HumanoidRootPart.CFrame
    wait(0.3)
    sellAllRemote:FireServer()
    repeat task.wait();sellAllRemote:FireServer() until #Backpack:GetChildren() < AutoSellItems -- waits until its sold(until the current items in the inventory are less than the required items for)
    HRP.CFrame = OrgPos
    task.wait(1)
    isSelling = false
end

spawn(function() 
    while true do
        shopTime = getTimeInSeconds(shopTimer.Text)
        local shopTimeText = "Shop Resets in " .. shopTime .. "s"
        RayFieldShopTimer:Set({Title = "Shop Timer", Content = shopTimeText})
        if shopTime == 298 then -- i did 298 just in case, tests every 0.2 seconds so just making sure
            onShopRefresh()
            wait(5)
        end
        if #(Backpack:GetChildren()) > AutoSellItems and shouldSell then
            isSelling = true
            sellAll()
            repeat task.wait() until isSelling == false
        end
        wait(0.1)
    end
end)

localPlayerTab = Window:CreateTab("LocalPlayer")
localPlayerTab:CreateButton(
    {
        Name = "TP Wand",
        Callback = function()
            local mouse = Players.LocalPlayer:GetMouse()
            local TPWand = Instance.new("Tool", Backpack)
            TPWand.Name = "TP Wand"
            mouse.Button1Down:Connect(function()
                if Character:FindFirstChild("TP Wand") then
                    HRP.CFrame = mouse.Hit
                end
            end)
        end,    
    })
    localPlayerTab:CreateButton(
    {
        Name = "Destroy TP Wand",
        Callback = function()
            if Backpack:FindFirstChild("TP Wand") then
                Backpack:FindFirstChild("TP Wand"):Destroy()
            end
            if Character:FindFirstChild("TP Wand") then
                Character:FindFirstChild("TP Wand"):Destroy()
            end
        end,    
    })
local speedSlider = localPlayerTab:CreateSlider({
   Name = "Speed",
   Range = {1, 500},
   Increment = 5,
   Suffix = "Speed",
   CurrentValue = 20,
   Flag = "Slider1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
   Humanoid.WalkSpeed = Value
   end,
})
localPlayerTab:CreateButton({
    Name = "Default Speed",
    Callback = function()
        speedSlider:Set(20)
    end,
    })
local jumpSlider = localPlayerTab:CreateSlider({
   Name = "Jump Power",
   Range = {1, 500},
   Increment = 5,
   Suffix = "Jump Power",
   CurrentValue = 50,
   Flag = "Slider2", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
   Humanoid.JumpPower = Value
   end,
})
localPlayerTab:CreateButton({
    Name = "Default Jump Power",
    Callback = function()
        jumpSlider:Set(50)
    end,
    })
local seedsTab = Window:CreateTab("Seeds")
seedsTab:CreateDropdown({
   Name = "Fruits To Buy",
   Options = getAllIFromDict(CropsListAndStocks),
   CurrentOption = {"None Selected"},
   MultipleOptions = true,
   Flag = "Dropdown1", 
   Callback = function(Options)
      
    local filtered = {}
    for _, fruit in ipairs(Options) do
        if fruit ~= "None Selected" then
            table.insert(filtered, fruit)
        end
    end
    print("Selected:", table.concat(filtered, ", "))
    wantedFruits = filtered
    print("Updated!")
    buyWantedCropSeeds()
    end,
})
local sellTab = Window:CreateTab("Sell")
sellTab:CreateToggle({
    Name = "Should Sell?",
    CurrentValue = false,
    flag = "Toggle2",
    Callback = function(Value)
        print("set shouldSell to: "..tostring(Value))
        shouldSell = Value
    end,
})
sellTab:CreateSlider({
   Name = "Minimum Items to auto sell",
   Range = {1, 200},
   Increment = 1,
   Suffix = "Items",
   CurrentValue = 70,
   Flag = "Slider2", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
    print("AutoSellItems updated to: "..Value)
    AutoSellItems = Value
   end,
})