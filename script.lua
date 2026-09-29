local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

local selection = {}
local selected = nil
local tool = "Move"
local transformMode = "World"
local dragging = false
local dragMode = nil
local dragData = {}
local history = {}
local historyIndex = 0
local clipboard = {}

local MOVE_SNAP = 1
local SCALE_SNAP = 0.25
local ROTATE_SNAP = 15
local MAX_HISTORY = 50

local function makeColor(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local COLORS = {
	background = makeColor(31, 33, 36),
	panel = makeColor(38, 40, 43),
	button = makeColor(48, 51, 55),
	buttonHover = makeColor(60, 64, 69),
	active = makeColor(66, 105, 163),
	activeHover = makeColor(78, 119, 181),
	text = makeColor(235, 235, 235),
	subText = makeColor(165, 169, 175),
	border = makeColor(70, 73, 78),
	blue = makeColor(0, 170, 255),
	hover = makeColor(255, 255, 255),
	green = makeColor(72, 133, 82),
	yellow = makeColor(145, 119, 58)
}

local hoverBox = Instance.new("SelectionBox")
hoverBox.Name = "StudioHover"
hoverBox.LineThickness = 0.025
hoverBox.Color3 = COLORS.hover
hoverBox.SurfaceTransparency = 1
hoverBox.Parent = workspace

local selectionFolder = Instance.new("Folder")
selectionFolder.Name = "StudioSelection"
selectionFolder.Parent = workspace

local handles = Instance.new("Handles")
handles.Name = "StudioHandles"
handles.Color3 = Color3.fromRGB(255, 255, 255)
handles.Transparency = 0
handles.Parent = playerGui

local rotateHandles = Instance.new("ArcHandles")
rotateHandles.Name = "StudioRotateHandles"
rotateHandles.Color3 = Color3.fromRGB(255, 255, 255)
rotateHandles.Transparency = 0
rotateHandles.Parent = playerGui

local proxy = Instance.new("Part")
proxy.Name = "StudioGizmoProxy"
proxy.Size = Vector3.new(1, 1, 1)
proxy.Transparency = 1
proxy.Anchored = true
proxy.CanCollide = false
proxy.CanTouch = false
proxy.CanQuery = false
proxy.CastShadow = false
proxy.Locked = true
proxy.Parent = workspace

local gui = Instance.new("ScreenGui")
gui.Name = "StudioEditor"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.Parent = playerGui

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 48)
topBar.Position = UDim2.fromOffset(0, 0)
topBar.BackgroundColor3 = COLORS.panel
topBar.BorderSizePixel = 0
topBar.Parent = gui

local topStroke = Instance.new("UIStroke")
topStroke.Color = COLORS.border
topStroke.Thickness = 1
topStroke.Parent = topBar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.fromOffset(130, 48)
title.Position = UDim2.fromOffset(12, 0)
title.BackgroundTransparency = 1
title.Text = "BUILD MODE"
title.TextColor3 = COLORS.text
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local topLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topLayout.Padding = UDim.new(0, 4)
topLayout.Parent = topBar

local topPadding = Instance.new("UIPadding")
topPadding.PaddingLeft = UDim.new(0, 150)
topPadding.PaddingRight = UDim.new(0, 10)
topPadding.Parent = topBar

local function createTopButton(name, text, width)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(width or 42, 36)
	button.BackgroundColor3 = COLORS.button
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = COLORS.text
	button.TextSize = 14
	button.Font = Enum.Font.GothamMedium
	button.AutoButtonColor = false
	button.Parent = topBar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = button

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = COLORS.buttonHover
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = COLORS.button
	end)

	return button
end

local undoButton = createTopButton("Undo", "↶", 40)
local redoButton = createTopButton("Redo", "↷", 40)
local separator1 = Instance.new("Frame")
separator1.Size = UDim2.fromOffset(1, 26)
separator1.BackgroundColor3 = COLORS.border
separator1.BorderSizePixel = 0
separator1.Parent = topBar

local moveButton = createTopButton("Move", "Move", 65)
local scaleButton = createTopButton("Scale", "Scale", 65)
local rotateButton = createTopButton("Rotate", "Rotate", 72)

local separator2 = Instance.new("Frame")
separator2.Size = UDim2.fromOffset(1, 26)
separator2.BackgroundColor3 = COLORS.border
separator2.BorderSizePixel = 0
separator2.Parent = topBar

local worldButton = createTopButton("WorldMode", "World", 68)
local localButton = createTopButton("LocalMode", "Local", 68)

local separator3 = Instance.new("Frame")
separator3.Size = UDim2.fromOffset(1, 26)
separator3.BackgroundColor3 = COLORS.border
separator3.BorderSizePixel = 0
separator3.Parent = topBar

local anchorButton = createTopButton("Anchor", "Anchor", 72)
local duplicateButton = createTopButton("Duplicate", "Duplicate", 85)
local deleteButton = createTopButton("Delete", "Delete", 65)

local statusBar = Instance.new("Frame")
statusBar.Name = "StatusBar"
statusBar.Size = UDim2.new(1, 0, 0, 30)
statusBar.Position = UDim2.new(0, 0, 1, -30)
statusBar.BackgroundColor3 = COLORS.panel
statusBar.BorderSizePixel = 0
statusBar.Parent = gui

local statusStroke = Instance.new("UIStroke")
statusStroke.Color = COLORS.border
statusStroke.Thickness = 1
statusStroke.Parent = statusBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.fromOffset(220, 30)
statusLabel.Position = UDim2.fromOffset(12, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "0 selected"
statusLabel.TextColor3 = COLORS.subText
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusBar

local helpLabel = Instance.new("TextLabel")
helpLabel.Name = "Help"
helpLabel.Size = UDim2.fromOffset(500, 30)
helpLabel.Position = UDim2.new(1, -510, 0, 0)
helpLabel.BackgroundTransparency = 1
helpLabel.Text = "1 Move   2 Scale   3 Rotate   F Focus   Ctrl+D Duplicate"
helpLabel.TextColor3 = COLORS.subText
helpLabel.TextSize = 12
helpLabel.Font = Enum.Font.Gotham
helpLabel.TextXAlignment = Enum.TextXAlignment.Right
helpLabel.Parent = statusBar

local function updateToolButtons()
	moveButton.BackgroundColor3 =
		tool == "Move" and COLORS.active or COLORS.button

	scaleButton.BackgroundColor3 =
		tool == "Scale" and COLORS.active or COLORS.button

	rotateButton.BackgroundColor3 =
		tool == "Rotate" and COLORS.active or COLORS.button

	worldButton.BackgroundColor3 =
		transformMode == "World" and COLORS.active or COLORS.button

	localButton.BackgroundColor3 =
		transformMode == "Local" and COLORS.active or COLORS.button
end

local function validTarget(part)
	if not part then
		return false
	end

	if not part:IsA("BasePart") then
		return false
	end

	if part == proxy then
		return false
	end

	if part:IsDescendantOf(selectionFolder) then
		return false
	end

	if player.Character and part:IsDescendantOf(player.Character) then
		return false
	end

	return true
end

local function isSelected(part)
	for _, object in ipairs(selection) do
		if object == part then
			return true
		end
	end

	return false
end

local function clearSelectionVisuals()
	for _, object in ipairs(selectionFolder:GetChildren()) do
		object:Destroy()
	end
end

local function updateSelectionVisuals()
	clearSelectionVisuals()

	for _, part in ipairs(selection) do
		if part and part.Parent then
			local box = Instance.new("SelectionBox")
			box.Name = "SelectedPart"
			box.Adornee = part
			box.LineThickness = part == selected and 0.075 or 0.045
			box.Color3 =
				part == selected
				and COLORS.blue
				or makeColor(70, 130, 230)
			box.SurfaceTransparency = 1
			box.Parent = selectionFolder
		end
	end
end

local function updateStatus()
	local count = #selection

	if count == 0 then
		statusLabel.Text = "0 selected"
		anchorButton.Text = "Anchor"
		anchorButton.BackgroundColor3 = COLORS.button
		return
	end

	statusLabel.Text = tostring(count) .. " selected"

	local anchored = 0

	for _, part in ipairs(selection) do
		if part and part.Parent and part.Anchored then
			anchored += 1
		end
	end

	if anchored == count then
		anchorButton.Text = "Anchored"
		anchorButton.BackgroundColor3 = COLORS.green
	elseif anchored == 0 then
		anchorButton.Text = "Anchor"
		anchorButton.BackgroundColor3 = COLORS.button
	else
		anchorButton.Text = "Mixed"
		anchorButton.BackgroundColor3 = COLORS.yellow
	end
end

local function getSelectionBounds()
	if #selection == 0 then
		return nil
	end

	local minX = math.huge
	local minY = math.huge
	local minZ = math.huge

	local maxX = -math.huge
	local maxY = -math.huge
	local maxZ = -math.huge

	local found = false

	for _, part in ipairs(selection) do
		if part and part.Parent then
			found = true

			local cf = part.CFrame
			local half = part.Size * 0.5

			local x = cf.RightVector * half.X
			local y = cf.UpVector * half.Y
			local z = cf.LookVector * half.Z

			local extents = Vector3.new(
				math.abs(x.X) + math.abs(y.X) + math.abs(z.X),
				math.abs(x.Y) + math.abs(y.Y) + math.abs(z.Y),
				math.abs(x.Z) + math.abs(y.Z) + math.abs(z.Z)
			)

			local p = part.Position

			minX = math.min(minX, p.X - extents.X)
			minY = math.min(minY, p.Y - extents.Y)
			minZ = math.min(minZ, p.Z - extents.Z)

			maxX = math.max(maxX, p.X + extents.X)
			maxY = math.max(maxY, p.Y + extents.Y)
			maxZ = math.max(maxZ, p.Z + extents.Z)
		end
	end

	if not found then
		return nil
	end

	local minVector = Vector3.new(minX, minY, minZ)
	local maxVector = Vector3.new(maxX, maxY, maxZ)

	return (minVector + maxVector) * 0.5, maxVector - minVector
end

local function getGizmoRotation()
	if transformMode == "Local" and selected and selected.Parent then
		return selected.CFrame.Rotation
	end

	return CFrame.identity
end

local function updateProxy()
	local center, size = getSelectionBounds()

	if not center then
		proxy.CFrame = CFrame.new()
		proxy.Size = Vector3.one
		return
	end

	proxy.CFrame =
		CFrame.new(center)
		* getGizmoRotation()

	proxy.Size = Vector3.new(
		math.max(size.X, 0.1),
		math.max(size.Y, 0.1),
		math.max(size.Z, 0.1)
	)
end

local function updateHandles()
	if #selection == 0 then
		handles.Adornee = nil
		rotateHandles.Adornee = nil
		return
	end

	if tool == "Rotate" then
		handles.Adornee = nil
		rotateHandles.Adornee = proxy
	else
		rotateHandles.Adornee = nil
		handles.Adornee = proxy

		if tool == "Move" then
			handles.Style = Enum.HandlesStyle.Movement
		else
			handles.Style = Enum.HandlesStyle.Resize
			handles.Faces = Faces.new(
				Enum.NormalId.Top,
				Enum.NormalId.Bottom,
				Enum.NormalId.Front,
				Enum.NormalId.Back,
				Enum.NormalId.Left,
				Enum.NormalId.Right
			)
		end
	end
end

local function refresh()
	updateSelectionVisuals()
	updateStatus()
	updateProxy()
	updateHandles()
	updateToolButtons()
end

local function setTool(newTool)
	if dragging then
		return
	end

	tool = newTool
	updateToolButtons()
	updateHandles()
end

local function setTransformMode(mode)
	if dragging then
		return
	end

	transformMode = mode
	updateProxy()
	updateHandles()
	updateToolButtons()
end

local function selectOnly(part)
	if not validTarget(part) then
		selection = {}
		selected = nil
		refresh()
		return
	end

	selection = {part}
	selected = part

	refresh()
end

local function toggleSelection(part)
	if not validTarget(part) then
		return
	end

	for i, object in ipairs(selection) do
		if object == part then
			table.remove(selection, i)

			if selected == part then
				selected = selection[#selection]
			end

			refresh()
			return
		end
	end

	table.insert(selection, part)
	selected = part

	refresh()
end

local function clearSelection()
	selection = {}
	selected = nil
	dragging = false
	dragMode = nil
	dragData = {}

	hoverBox.Adornee = nil
	handles.Adornee = nil
	rotateHandles.Adornee = nil

	refresh()
end

local function getEditableParts()
	local parts = {}

	for _, object in ipairs(workspace:GetDescendants()) do
		if validTarget(object) then
			table.insert(parts, object)
		end
	end

	return parts
end

local function selectAll()
	local parts = getEditableParts()

	if #parts == 0 then
		return
	end

	selection = parts
	selected = parts[#parts]

	refresh()
end

local function createSnapshot(parts)
	local snapshot = {}

	for _, part in ipairs(parts) do
		if part and part.Parent then
			table.insert(snapshot, {
				part = part,
				cframe = part.CFrame,
				size = part.Size,
				anchored = part.Anchored
			})
		end
	end

	return snapshot
end

local function pushHistory()
	if #selection == 0 then
		return
	end

	local snapshot = createSnapshot(selection)

	while #history > historyIndex do
		table.remove(history)
	end

	table.insert(history, snapshot)

	if #history > MAX_HISTORY then
		table.remove(history, 1)
	end

	historyIndex = #history
end

local function restoreSnapshot(snapshot)
	for _, data in ipairs(snapshot) do
		if data.part and data.part.Parent then
			data.part.CFrame = data.cframe
			data.part.Size = data.size
			data.part.Anchored = data.anchored
		end
	end

	refresh()
end

local function undo()
	if dragging then
		return
	end

	if historyIndex <= 0 then
		return
	end

	local current = createSnapshot(selection)

	local target = history[historyIndex]

	if target then
		historyIndex -= 1
		restoreSnapshot(target)
	end
end

local function redo()
	if dragging then
		return
	end

	if historyIndex >= #history then
		return
	end

	historyIndex += 1

	local target = history[historyIndex]

	if target then
		restoreSnapshot(target)
	end
end

local function duplicateSelection()
	if #selection == 0 then
		return
	end

	pushHistory()

	local newSelection = {}

	for _, part in ipairs(selection) do
		if part and part.Parent then
			local clone = part:Clone()
			clone.CFrame = part.CFrame + Vector3.new(2, 0, 2)
			clone.Parent = part.Parent
			table.insert(newSelection, clone)
		end
	end

	selection = newSelection
	selected = newSelection[#newSelection]

	refresh()
end

local function copySelection()
	clipboard = {}

	for _, part in ipairs(selection) do
		if part and part.Parent then
			table.insert(clipboard, {
				name = part.Name,
				size = part.Size,
				cframe = part.CFrame,
				color = part.Color,
				material = part.Material,
				transparency = part.Transparency,
				reflectance = part.Reflectance,
				anchored = part.Anchored,
				canCollide = part.CanCollide,
				canTouch = part.CanTouch,
				canQuery = part.CanQuery,
				shape = part:IsA("Part") and part.Shape or nil
			})
		end
	end
end

local function pasteSelection()
	if #clipboard == 0 then
		return
	end

	pushHistory()

	local newSelection = {}

	for _, data in ipairs(clipboard) do
		local part = Instance.new("Part")

		part.Name = data.name
		part.Size = data.size
		part.CFrame = data.cframe + Vector3.new(2, 0, 2)
		part.Color = data.color
		part.Material = data.material
		part.Transparency = data.transparency
		part.Reflectance = data.reflectance
		part.Anchored = data.anchored
		part.CanCollide = data.canCollide
		part.CanTouch = data.canTouch
		part.CanQuery = data.canQuery

		if data.shape then
			part.Shape = data.shape
		end

		part.Parent = workspace

		table.insert(newSelection, part)
	end

	selection = newSelection
	selected = newSelection[#newSelection]

	refresh()
end

local function deleteSelected()
	if #selection == 0 then
		return
	end

	pushHistory()

	local objects = table.clone(selection)

	selection = {}
	selected = nil

	for _, part in ipairs(objects) do
		if part and part.Parent then
			part:Destroy()
		end
	end

	refresh()
end

local function toggleAnchor()
	if #selection == 0 then
		return
	end

	pushHistory()

	local shouldAnchor = false

	for _, part in ipairs(selection) do
		if part and part.Parent and not part.Anchored then
			shouldAnchor = true
			break
		end
	end

	for _, part in ipairs(selection) do
		if part and part.Parent then
			part.Anchored = shouldAnchor
		end
	end

	updateStatus()
end

local function snap(value, increment)
	return math.round(value / increment) * increment
end

local function captureDragData()
	dragData = {}

	local center, size = getSelectionBounds()

	if not center then
		return
	end

	for _, part in ipairs(selection) do
		if part and part.Parent then
			table.insert(dragData, {
				part = part,
				cframe = part.CFrame,
				size = part.Size,
				position = part.Position
			})
		end
	end

	dragData.center = center
	dragData.size = size
	dragData.proxyCFrame = proxy.CFrame
end

local function moveSelection(face, distance)
	local snapped = snap(distance, MOVE_SNAP)

	local localDirection = Vector3.FromNormalId(face)

	local worldDirection =
		dragData.proxyCFrame:VectorToWorldSpace(localDirection)

	local offset = worldDirection * snapped

	for _, data in ipairs(dragData) do
		if data.part and data.part.Parent then
			data.part.CFrame = data.cframe + offset
		end
	end
end

local function scaleSelection(face, distance)
	local snapped = snap(distance, SCALE_SNAP)

	local localDirection = Vector3.FromNormalId(face)

	local worldDirection =
		dragData.proxyCFrame:VectorToWorldSpace(localDirection)

	local axisSize

	if math.abs(localDirection.X) > 0 then
		axisSize = dragData.size.X
	elseif math.abs(localDirection.Y) > 0 then
		axisSize = dragData.size.Y
	else
		axisSize = dragData.size.Z
	end

	if axisSize <= 0.001 then
		return
	end

	local newAxisSize = math.max(0.05, axisSize + snapped)
	local factor = newAxisSize / axisSize

	for _, data in ipairs(dragData) do
		if data.part and data.part.Parent then
			local relative =
				data.position - dragData.center

			local projected =
				relative:Dot(worldDirection)

			local perpendicular =
				relative - worldDirection * projected

			local newProjected =
				projected * factor

			local newPosition =
				dragData.center
				+ perpendicular
				+ worldDirection * newProjected

			local oldSize = data.size
			local newSize

			if math.abs(localDirection.X) > 0 then
				newSize = Vector3.new(
					math.max(0.05, oldSize.X * factor),
					oldSize.Y,
					oldSize.Z
				)
			elseif math.abs(localDirection.Y) > 0 then
				newSize = Vector3.new(
					oldSize.X,
					math.max(0.05, oldSize.Y * factor),
					oldSize.Z
				)
			else
				newSize = Vector3.new(
					oldSize.X,
					oldSize.Y,
					math.max(0.05, oldSize.Z * factor)
				)
			end

			data.part.Size = newSize

			data.part.CFrame =
				CFrame.new(newPosition)
				* data.cframe.Rotation
		end
	end
end

local function rotateSelection(axis, angle)
	local snappedDegrees =
		snap(math.deg(angle), ROTATE_SNAP)

	local radians = math.rad(snappedDegrees)

	local localAxis

	if axis == Enum.Axis.X then
		localAxis = Vector3.new(1, 0, 0)
	elseif axis == Enum.Axis.Y then
		localAxis = Vector3.new(0, 1, 0)
	else
		localAxis = Vector3.new(0, 0, 1)
	end

	local worldAxis =
		dragData.proxyCFrame:VectorToWorldSpace(localAxis)

	local rotation =
		CFrame.fromAxisAngle(worldAxis, radians)

	for _, data in ipairs(dragData) do
		if data.part and data.part.Parent then
			local relative =
				data.position - dragData.center

			local newPosition =
				dragData.center
				+ rotation:VectorToWorldSpace(relative)

			data.part.CFrame =
				CFrame.new(newPosition)
				* rotation
				* data.cframe.Rotation
		end
	end
end

local function focusSelection()
	if #selection == 0 then
		return
	end

	local center, size = getSelectionBounds()

	if not center then
		return
	end

	local distance =
		math.max(size.X, size.Y, size.Z) * 2.5

	local direction =
		camera.CFrame.LookVector

	camera.CFrame =
		CFrame.lookAt(
			center - direction * distance,
			center
		)
end

local function mouseOverGui()
	local position = UserInputService:GetMouseLocation()

	for _, object in ipairs(
		playerGui:GetGuiObjectsAtPosition(
			position.X,
			position.Y
		)
		) do
		if object:IsDescendantOf(gui) then
			return true
		end
	end

	return false
end

moveButton.MouseButton1Click:Connect(function()
	setTool("Move")
end)

scaleButton.MouseButton1Click:Connect(function()
	setTool("Scale")
end)

rotateButton.MouseButton1Click:Connect(function()
	setTool("Rotate")
end)

worldButton.MouseButton1Click:Connect(function()
	setTransformMode("World")
end)

localButton.MouseButton1Click:Connect(function()
	setTransformMode("Local")
end)

anchorButton.MouseButton1Click:Connect(function()
	toggleAnchor()
end)

duplicateButton.MouseButton1Click:Connect(function()
	duplicateSelection()
end)

deleteButton.MouseButton1Click:Connect(function()
	deleteSelected()
end)

undoButton.MouseButton1Click:Connect(function()
	undo()
end)

redoButton.MouseButton1Click:Connect(function()
	redo()
end)

mouse.Button1Down:Connect(function()
	if dragging then
		return
	end

	if mouseOverGui() then
		return
	end

	local target = mouse.Target

	local shift =
		UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

	if validTarget(target) then
		if shift then
			toggleSelection(target)
		else
			selectOnly(target)
		end
	elseif not shift then
		clearSelection()
	end
end)

handles.MouseButton1Down:Connect(function(face)
	if #selection == 0 then
		return
	end

	pushHistory()

	dragging = true
	dragMode = tool

	captureDragData()

	hoverBox.Adornee = nil
end)

handles.MouseDrag:Connect(function(face, distance)
	if not dragging then
		return
	end

	if #selection == 0 then
		return
	end

	if dragMode == "Move" then
		moveSelection(face, distance)
	elseif dragMode == "Scale" then
		scaleSelection(face, distance)
	end

	updateProxy()
end)

handles.MouseButton1Up:Connect(function()
	dragging = false
	dragMode = nil
	dragData = {}

	updateProxy()
	updateHandles()
end)

rotateHandles.MouseButton1Down:Connect(function(axis)
	if #selection == 0 then
		return
	end

	pushHistory()

	dragging = true
	dragMode = "Rotate"

	captureDragData()

	hoverBox.Adornee = nil
end)

rotateHandles.MouseDrag:Connect(function(axis, relativeAngle, deltaRadius)
	if not dragging then
		return
	end

	if #selection == 0 then
		return
	end

	rotateSelection(axis, relativeAngle)
	updateProxy()
end)

rotateHandles.MouseButton1Up:Connect(function()
	dragging = false
	dragMode = nil
	dragData = {}

	updateProxy()
	updateHandles()
end)

local function keyboardAction(actionName, inputState, inputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end

	local key = inputObject.KeyCode
	local ctrl =
		UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

	if key == Enum.KeyCode.One then
		setTool("Move")
		return Enum.ContextActionResult.Sink
	end

	if key == Enum.KeyCode.Two then
		setTool("Scale")
		return Enum.ContextActionResult.Sink
	end

	if key == Enum.KeyCode.Three then
		setTool("Rotate")
		return Enum.ContextActionResult.Sink
	end

	if key == Enum.KeyCode.F then
		focusSelection()
		return Enum.ContextActionResult.Sink
	end

	if ctrl and key == Enum.KeyCode.A then
		selectAll()
		return Enum.ContextActionResult.Sink
	end

	if ctrl and key == Enum.KeyCode.D then
		duplicateSelection()
		return Enum.ContextActionResult.Sink
	end

	if ctrl and key == Enum.KeyCode.C then
		copySelection()
		return Enum.ContextActionResult.Sink
	end

	if ctrl and key == Enum.KeyCode.V then
		pasteSelection()
		return Enum.ContextActionResult.Sink
	end

	if ctrl and key == Enum.KeyCode.Z then
		undo()
		return Enum.ContextActionResult.Sink
	end

	if ctrl and key == Enum.KeyCode.Y then
		redo()
		return Enum.ContextActionResult.Sink
	end

	if key == Enum.KeyCode.Delete
		or key == Enum.KeyCode.Backspace then
		deleteSelected()
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority(
	"StudioEditorKeyboard",
	keyboardAction,
	false,
	3000,
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.F,
	Enum.KeyCode.A,
	Enum.KeyCode.D,
	Enum.KeyCode.C,
	Enum.KeyCode.V,
	Enum.KeyCode.Z,
	Enum.KeyCode.Y,
	Enum.KeyCode.Delete,
	Enum.KeyCode.Backspace
)

RunService.RenderStepped:Connect(function()
	if dragging then
		hoverBox.Adornee = nil
		return
	end

	local target = mouse.Target

	if validTarget(target) and not isSelected(target) then
		if hoverBox.Adornee ~= target then
			hoverBox.Adornee = target
		end
	else
		if hoverBox.Adornee then
			hoverBox.Adornee = nil
		end
	end
end)

local lastSelectionCount = -1
local lastSelected = nil
local lastTool = nil
local lastMode = nil

RunService.Heartbeat:Connect(function()
	local changed = false

	for i = #selection, 1, -1 do
		local part = selection[i]

		if not part or not part.Parent then
			table.remove(selection, i)
			changed = true
		end
	end

	if selected and not selected.Parent then
		selected = selection[#selection]
		changed = true
	end

	if #selection ~= lastSelectionCount then
		changed = true
	end

	if selected ~= lastSelected then
		changed = true
	end

	if tool ~= lastTool then
		changed = true
	end

	if transformMode ~= lastMode then
		changed = true
	end

	if changed then
		lastSelectionCount = #selection
		lastSelected = selected
		lastTool = tool
		lastMode = transformMode

		updateSelectionVisuals()
		updateStatus()
		updateProxy()
		updateHandles()
		updateToolButtons()
	end

	if not dragging and #selection > 0 then
		updateProxy()
	end
end)

setTool("Move")
setTransformMode("World")
refresh()
