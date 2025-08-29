--[[ -----
NarrativeFlow Interpreter Script V1.0

NarrativeFlow Interpreter Script Code License – Modified MIT License

Copyright (c) 2025 NarrativeFlow LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to use, copy, modify, merge, publish, and distribute the Software, subject to the following conditions:

1. The Software may be used in personal and commercial projects, including but not limited to, games, applications, educational content, and interactive experiences.

2. The Software may be included in commercial products, provided that it is not the primary value of the product (e.g., inclusion in a game or educational course is allowed and encouraged, but selling the code itself as a standalone template or package is not).

3. You may not sell, sublicense, or redistribute the Software on its own, or as part of a product where the main offering is access to the source code or derivative works of the Software, whether free or paid.

4. This copyright notice and permission notice must be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
----- --]]

local json = require("dkjson")

NarrativeFlowProject = {}
NarrativeFlowProject.__index = NarrativeFlowProject

function NarrativeFlowProject.new(compiled_project_file_contents)
    local project_data, _, err = json.decode(compiled_project_file_contents, 1, nil)
    if err or not project_data then
        error("Failed to decode project JSON: " .. err)
    end

    local self = setmetatable({}, NarrativeFlowProject)
    self.experiences = project_data.experiences or {}
    self.variables = project_data.variables or {}
    self.data_table = project_data.dataTable or {}
    return self
end

function NarrativeFlowProject:get_experience(experience_name)
    for _, experience in ipairs(self.experiences) do
        if experience.name == experience_name then
            return experience
        end
    end
    return nil
end

function NarrativeFlowProject:get_variable_value(variable_name)
    for _, variable in ipairs(self.variables) do
        if variable.name == variable_name then
            return variable.value
        end
    end
    io.stderr:write("Error: Variable with the name '" .. variable_name .. "' not found.\n")
    return nil
end

function NarrativeFlowProject:set_variable_value(variable_name, new_value)
    for _, variable in ipairs(self.variables) do
        if variable.name == variable_name then
            variable.value = new_value
            return true
        end
    end
    io.stderr:write("Error: Variable with the name '" .. variable_name .. "' not found.\n")
    return false
end

function NarrativeFlowProject:get_variable_parsed_string(str)
    local function escape_lua_pattern(s)
        return s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    end

    for _, variable in ipairs(self.variables) do
        local pattern = escape_lua_pattern(variable.name)
        str = string.gsub(str, pattern, variable.value)
    end

    return str
end

function NarrativeFlowProject:get_data_table_item_value(item_name)
    for _, item in ipairs(self.dataTable) do
        if item.name == item_name then
            return self:get_variable_parsed_string(item.value)
        end
    end
    io.stderr:write("Error: Data Table item with the name '" .. item_name .. "' not found.\n")
    return nil
end

function NarrativeFlowProject:process_assignment(assign)
    local variable_value = self:get_variable_value(assign.variable)
    local parsed_value = self:get_variable_parsed_string(assign.value)

    local var_num = tonumber(variable_value)
    local val_num = tonumber(parsed_value)

    if not var_num or not val_num then
        -- Treat as strings
        if assign.operator == "=" then
            self:set_variable_value(assign.variable, parsed_value)
        elseif assign.operator == "+" then
            self:set_variable_value(assign.variable, variable_value .. parsed_value)
        else
            io.stderr:write("Error: Operator '" .. assign.operator .. "' can't be used on strings.\n")
        end
    else
        -- Treat as numbers
        if assign.operator == "=" then
            self:set_variable_value(assign.variable, parsed_value)
        elseif assign.operator == "+" then
            self:set_variable_value(assign.variable, tostring(var_num + val_num))
        elseif assign.operator == "-" then
            self:set_variable_value(assign.variable, tostring(var_num - val_num))
        elseif assign.operator == "×" then
            self:set_variable_value(assign.variable, tostring(var_num * val_num))
        elseif assign.operator == "÷" then
            self:set_variable_value(assign.variable, tostring(var_num / val_num))
        else
            io.stderr:write("Error: Assignment operator '" .. assign.operator .. "' is invalid.\n")
        end
    end
end

function NarrativeFlowProject:does_comparison_equate_to_true(comp)
    local variable_value = self:get_variable_value(comp.variable)
    local parsed_value = self:get_variable_parsed_string(comp.value)

    if not variable_value then
        return false
    end

    if comp.operator == "=" then
        return variable_value == parsed_value
    elseif comp.operator == "≠" then
        return variable_value ~= parsed_value
    elseif comp.operator == "<" then
        return tonumber(variable_value) < tonumber(parsed_value)
    elseif comp.operator == "≤" then
        return tonumber(variable_value) <= tonumber(parsed_value)
    elseif comp.operator == ">" then
        return tonumber(variable_value) > tonumber(parsed_value)
    elseif comp.operator == "≥" then
        return tonumber(variable_value) >= tonumber(parsed_value)
    elseif comp.operator == "⊇" then
        return string.find(variable_value, parsed_value, 1, true) ~= nil
    elseif comp.operator == "⊉" then
        return string.find(variable_value, parsed_value, 1, true) == nil
    elseif comp.operator == "∈" then
        return string.find(parsed_value, variable_value, 1, true) ~= nil
    elseif comp.operator == "∉" then
        return string.find(parsed_value, variable_value, 1, true) == nil
    else
        io.stderr:write("Error: Comparison operator '" .. comp.operator .. "' is invalid.\n")
        return false
    end
end

function NarrativeFlowProject:get_probability_route_to_take(routes)
    local valid_routes = {}

    for i, route in ipairs(routes) do
        local parsed_weight = self:get_variable_parsed_string(route.weight)
        local weight = tonumber(parsed_weight)

        if weight then
            table.insert(valid_routes, { index = i, weight = weight, links_to = route.linksTo })
        else
            print("Error: Could not parse weight '" .. tostring(parsed_weight) .. "' for route linking to " .. tostring(route.linksTo))
        end
    end

    if #valid_routes == 0 then
        io.stderr:write("No valid routes available.\n")
        return nil
    end

    local total_weight = 0
    for _, r in ipairs(valid_routes) do
        total_weight = total_weight + r.weight
    end

    local rand = math.random() * total_weight
    local cumulative = 0

    for _, r in ipairs(valid_routes) do
        cumulative = cumulative + r.weight
        if rand < cumulative then
            return r.links_to
        end
    end

    return valid_routes[#valid_routes].links_to
end

NarrativeFlowExperience = {}
NarrativeFlowExperience.__index = NarrativeFlowExperience

function NarrativeFlowExperience.new(project, experience_name)
    local self = setmetatable({}, NarrativeFlowExperience)
    self.project = project
    self.experience_data = project:get_experience(experience_name)
    self.current_node = nil
    return self
end

function NarrativeFlowExperience:get_node(node_id)
    if not node_id then
        io.stderr:write("Error: get_node() received a nil node ID.\n")
        return nil
    end

    local node = nil
    for _, n in ipairs(self.experience_data.nodeList) do
        if n.id == node_id then
            node = n
            break
        end
    end

    if not node then return nil end

    -- Handle dynamic string substitution for relevant node fields
    if node.type == "dialog" then
        node.dialogSource = self.project:get_variable_parsed_string(node.dialogSource or "")
        node.dialogString = self.project:get_variable_parsed_string(node.dialogString or "")
        for _, prop in ipairs(node.properties or {}) do
            prop.value = self.project:get_variable_parsed_string(prop.value or "")
        end
    elseif node.type == "choice" then
        for _, choice in ipairs(node.choices or {}) do
            choice.choiceString = self.project:get_variable_parsed_string(choice.choiceString or "")
        end
        for _, prop in ipairs(node.properties or {}) do
            prop.value = self.project:get_variable_parsed_string(prop.value or "")
        end
    elseif node.type == "start" or node.type == "end" then
        for _, prop in ipairs(node.properties or {}) do
            prop.value = self.project:get_variable_parsed_string(prop.value or "")
        end
    elseif node.type == "function" then
        node.statement = self.project:get_variable_parsed_string(node.statement or "")
    end

    return node
end

function NarrativeFlowExperience:get_start_node(start_node_name)
    for _, node in ipairs(self.experience_data.nodeList) do
        if node.type == "start" and node.name == start_node_name then
            self.current_node = node
            return node
        end
    end
    io.stderr:write("Error: No start node with name '" .. start_node_name .. "' found.\n")
    return nil
end

function NarrativeFlowExperience:get_next_node(choice_index)
    local next_node = self.current_node

    if not next_node then
        io.stderr:write("Error: No current node.\n")
        return nil
    end

    -- Initial transition based on node type
    if next_node.type == "dialog" or next_node.type == "start" or next_node.type == "function" then
        next_node = self:get_node(next_node.linksTo)
    elseif next_node.type == "choice" then
        if not choice_index or choice_index < 0 or not next_node.choices or not next_node.choices[choice_index + 1] then
            io.stderr:write("Error: Invalid choice index '" .. tostring(choice_index) .. "' for node with " .. tostring(#(next_node.choices or {})) .. " choices.\n")
            return nil
        end
        next_node = self:get_node(next_node.choices[choice_index + 1].linksTo)
    elseif next_node.type == "end" or next_node.type == "teleport" then
        io.stderr:write("Error: Node type '" .. next_node.type .. "' does not link to another node.\n")
        return nil
    else
        io.stderr:write("Error: Invalid node type '" .. tostring(next_node.type) .. "'.\n")
        return nil
    end

    -- Handle mid-chain transitions (variable, conditional, probability, etc.)
    while next_node and not (
        next_node.type == "dialog" or
        next_node.type == "choice" or
        next_node.type == "start" or
        next_node.type == "end" or
        next_node.type == "function"
    ) do
        if next_node.type == "variable" then
            for _, a in ipairs(next_node.assignments or {}) do
                self.project:process_assignment(a)
            end
            next_node = self:get_node(next_node.linksTo)

        elseif next_node.type == "conditional" then
            local route_to_take = -1
            for route_index, route in ipairs(next_node.routes or {}) do
                local all_true = true
                local any_true = false

                for _, comp in ipairs(route.comparisons or {}) do
                    if not self.project:does_comparison_equate_to_true(comp) then
                        all_true = false
                    else
                        any_true = true
                    end
                end

                if route.mode == "all" and all_true then
                    route_to_take = route_index
                elseif route.mode == "any" and any_true then
                    route_to_take = route_index
                elseif route.mode == "none" and not any_true then
                    route_to_take = route_index
                end
            end

            if route_to_take == -1 then
                next_node = self:get_node(next_node.defaultRouteLinksTo)
            else
                next_node = self:get_node(next_node.routes[route_to_take].linksTo)
            end

        elseif next_node.type == "probability" then
            local links_to = self.project:get_probability_route_to_take(next_node.routes)
            next_node = self:get_node(links_to)

        elseif next_node.type == "teleport" then
            self.experience_data = self.project:get_experience(next_node.destinationExperience)
            next_node = self:get_start_node(next_node.destinationStartNode)

        else
            io.stderr:write("Error: Node type '" .. tostring(next_node.type) .. "' is not recognized in transition.\n")
            return nil
        end
    end

    self.current_node = next_node

    if not next_node then
        io.stderr:write("The chain ended with no valid output node.\n")
    end

    return next_node
end

