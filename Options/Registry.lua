local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

local ORPHAN_ORDER = 9000

---@class AMTOptionsCategory
---@field id string dotted, stable, never localised
---@field order integer
---@field name string display only

---@class AMTOptionsPage
---@field id string
---@field parent string category ID
---@field order integer
---@field name string
---@field icon string?
---@field Build fun(page: AMTOptionsPageView)
---@field frame Frame?
---@field built boolean?

---@type table<string, AMTOptionsCategory>
local categories = {}

---@type table<string, AMTOptionsPage>
local pages = {}

---@type AMTOptionsCategory[]
local categoryList = {}

---@type table<string, AMTOptionsPage[]>
local pagesByCategory = {}

local sorted = false

---@param a { order: integer, id: string }
---@param b { order: integer, id: string }
---@return boolean
local function ByOrder(a, b)
	if a.order == b.order then
		return a.id < b.id
	end

	return a.order < b.order
end

local function Sort()
	if sorted then
		return
	end

	table.sort(categoryList, ByOrder)

	for _, list in pairs(pagesByCategory) do
		table.sort(list, ByOrder)
	end

	sorted = true
end

---@param definition AMTOptionsCategory
function Options.RegisterCategory(definition)
	if not definition.id or definition.id == "" then
		AMT.Util.Warn("a category was registered without an id; ignoring it.")

		return
	end

	local existing = categories[definition.id]

	if existing then
		if existing.order ~= ORPHAN_ORDER then
			AMT.Util.Warn("category %q is already registered; ignoring the duplicate.", definition.id)

			return
		end

		existing.order = definition.order or ORPHAN_ORDER
		existing.name = definition.name or existing.name
		sorted = false

		return
	end

	categories[definition.id] = definition
	categoryList[#categoryList + 1] = definition
	pagesByCategory[definition.id] = pagesByCategory[definition.id] or {}
	sorted = false
end

---@param definition AMTOptionsPage
function Options.RegisterPage(definition)
	if not definition.id or definition.id == "" then
		AMT.Util.Warn("a page was registered without an id; ignoring it.")

		return
	end

	if pages[definition.id] then
		AMT.Util.Warn("page %q is already registered; ignoring the duplicate.", definition.id)

		return
	end

	if not definition.Build then
		AMT.Util.Warn("page %q has no Build function; ignoring it.", definition.id)

		return
	end

	if not categories[definition.parent] then
		AMT.Util.Warn("page %q names unregistered category %q.", definition.id, tostring(definition.parent))

		Options.RegisterCategory({
			id = definition.parent,
			order = ORPHAN_ORDER,
			name = definition.parent,
		})
	end

	pages[definition.id] = definition

	local list = pagesByCategory[definition.parent]
	list[#list + 1] = definition

	sorted = false
end

---@return AMTOptionsCategory[]
function Options.GetCategories()
	Sort()

	return categoryList
end

---@param categoryID string
---@return AMTOptionsPage[]
function Options.GetPages(categoryID)
	Sort()

	return pagesByCategory[categoryID] or {}
end

---@param id string
---@return AMTOptionsPage?
function Options.GetPage(id)
	return pages[id]
end

---The first page of the first category, for the window's initial selection.
---@return AMTOptionsPage?
function Options.GetFirstPage()
	for _, category in ipairs(Options.GetCategories()) do
		local list = Options.GetPages(category.id)

		if list[1] then
			return list[1]
		end
	end

	return nil
end

Options.RegisterCategory({ id = "settings", order = 10, name = L["Settings"] })
Options.RegisterCategory({ id = "timer", order = 20, name = L["Timer"] })
Options.RegisterCategory({ id = "profiles", order = 30, name = L["Profiles"] })
