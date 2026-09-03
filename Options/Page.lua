local AMT = select(2, ...)

local Options = AMT.Options

---@class AMTOptionsPageView
---@field definition AMTOptionsPage
---@field container AMTOptionsContainer
---@field header AMTOptionsPageHeader?
local PageView = {}
PageView.__index = PageView
Options.PageView = PageView

---@type table<string, AMTOptionsPageView>
local views = {}

---@type AMTOptionsPageView?
local current

---@param config AMTOptionsPageHeaderConfig
---@return AMTOptionsPageHeader?
function PageView:SetHeader(config)
	if self.header then
		AMT.Util.Warn("page %q set its header twice; ignoring the second.", self.definition.id)

		return self.header
	end

	config.title = config.title or self.definition.name

	self.header = Options.NewPageHeader(self.container.frame, config)

	self.container:AddContainer(self.header)

	return self.header
end

---@param info AMTOptionInfo
---@return AMTOptionWidget?
function PageView:AddWidget(info)
	return self.container:AddWidget(info)
end

---@param list AMTOptionInfo[]
---@return AMTOptionWidget[]
function PageView:AddWidgets(list)
	return self.container:AddWidgets(list)
end

---@param config AMTOptionsGroupConfig
---@return AMTOptionsGroup
function PageView:AddGroup(config)
	local group = Options.NewGroup(self.container.frame, config)

	self.container:AddContainer(group)

	return group
end

---@param style string? "thin" or "accent"
---@return Frame
function PageView:AddDivider(style)
	return self.container:AddChild(Options.NewDivider(self.container.frame, style))
end

function PageView:Refresh()
	self.container:Refresh()
end

---@param definition AMTOptionsPage
---@param host AMTOptionsContainer
---@return AMTOptionsPageView
local function NewPageView(definition, host)
	local view = setmetatable({ definition = definition }, PageView)

	view.container = Options.NewContainer(host.frame)

	host:AddContainer(view.container)

	view.container.frame:Hide()

	definition.Build(view)
	definition.built = true

	return view
end

---@param page AMTOptionsPage
function Options.OnPageSelected(page)
	local chrome = Options.GetChrome()
	local view = views[page.id]

	if not view then
		view = NewPageView(page, chrome.content)
		views[page.id] = view
	end

	if current and current ~= view then
		current.container.frame:Hide()
	end

	current = view

	view.container.frame:Show()
	view:Refresh()

	chrome.content:Layout()

	chrome.scroll:SetVerticalScroll(0)
end

function Options.NotifyValueChanged()
	if current then
		current:Refresh()
	end
end

---@return AMTOptionsPageView?
function Options.GetCurrentPage()
	return current
end
