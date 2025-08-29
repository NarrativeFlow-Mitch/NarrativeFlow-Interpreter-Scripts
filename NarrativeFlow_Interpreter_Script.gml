/*
NarrativeFlow Interpreter Script V1.0

NarrativeFlow Interpreter Script Code License - Modified MIT License

Copyright (c) 2025 NarrativeFlow LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, merge, publish, and distribute the Software, subject to the following conditions:

1. The Software may be used in personal and commercial projects, including but not limited to, games, applications, educational content, and interactive experiences.

2. The Software may be included in commercial products, provided that it is not the primary value of the product (e.g., inclusion in a game or educational course is allowed and encouraged, but selling the code itself as a standalone template or package is not).

3. You may not sell, sublicense, or redistribute the Software on its own, or as part of a product where the main offering is access to the source code or derivative works of the Software, whether free or paid.

4. This copyright notice and permission notice must be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

function Variable(var_name, var_value) constructor {
    name = var_name;
    value = var_value;
}

function DataTableItem(item_name, item_value) constructor {
    name = item_name;
    value = item_value;
}

function Choice(choice_str, links) constructor {
    choiceString = choice_str;
    linksTo = links;
}

function Assignment(var_name, op, val) constructor {
    variable = var_name;
    operator = op;
    value = val;
}

function Comparison(var_name, op, val) constructor {
    variable = var_name;
    operator = op;
    value = val;
}

function Route(comps, route_mode, route_weight, links) constructor {
    comparisons = comps;
    mode = route_mode;
    weight = route_weight;
    linksTo = links;
}

function Property(prop_name, prop_value) constructor {
    name = prop_name;
    value = prop_value;
}

function Node() constructor {
    id = noone;
    type = "";
    linksTo = noone;
    properties = [];
    dialogSource = "";
    dialogString = "";
    choices = [];
    name = "";
    assignments = [];
    routes = [];
    defaultRouteLinksTo = noone;
    statement = "";
    destinationExperience = "";
    destinationStartNode = "";
}

function ExperienceData(exp_name, nodes) constructor {
    name = exp_name;
    nodeList = nodes;
}

function Project(compiled_project_json_string) constructor {
    var data = json_parse(compiled_project_json_string);
    experiences = data.experiences;
    variables = data.variables;
    dataTable = data.dataTable;
    
    static get_experience = function(name) {
        for (var i = 0; i < array_length(experiences); i++) {
            if (experiences[i][$ "name"] == name) {
                return experiences[i];
            }
        }
        return noone;
    }
    
    static get_variable_value = function(name) {
        for (var i = 0; i < array_length(variables); i++) {
            if (variables[i][$ "name"] == name) {
                return variables[i][$ "value"];
            }
        }
        show_error("Error: Variable with the name '" + name + "' not found.", true);
        return noone;
    }
    
    static set_variable_value = function(name, value) {
        for (var i = 0; i < array_length(variables); i++) {
            if (variables[i][$ "name"] == name) {
                variables[i][$ "value"] = value;
                return true;
            }
        }
        show_error("Error: Variable with the name '" + name + "' not found.", true);
        return false;
    }
    
    static get_variable_parsed_string = function(str_val) {
        var result = str_val;
        for (var i = 0; i < array_length(variables); i++) {
            var variable = variables[i];
            // Simple string replacement (GML doesn't have built-in regex)
            result = string_replace_all(result, variable.name, variable.value);
        }
        return result;
    }
    
    static get_data_table_item_value = function(name) {
        for (var i = 0; i < array_length(dataTable); i++) {
            var item = dataTable[i];
            if (item.name == name) {
                return get_variable_parsed_string(item.value);
            }
        }
        show_error("Error: Data Table item with the name '" + name + "' not found.", true);
        return noone;
    }
	
	static can_string_convert_to_number = function(string_to_convert) {
		var letters = string_letters(string_to_convert);
		if (string_length(letters) > 0) return false;
		else return true;
	}
    
    static process_assignment = function(assignment) {
        var variable_value = get_variable_value(assignment.variable);
        var is_number = can_string_convert_to_number(variable_value) && can_string_convert_to_number(assignment.value);
        
        if (!is_number) {
            switch (assignment.operator) {
                case "=":
                    set_variable_value(assignment.variable, assignment.value);
                    break;
                case "+":
                    set_variable_value(assignment.variable, string(variable_value) + string(assignment.value));
                    break;
                case "-":
				case "×":
				case "÷":
                    show_error("Error: '" + assignment.operator + "' can't be used on strings.", true);
                    break;
                default:
                    show_error("Error: Assignment operator '" + assignment.operator + "' is invalid.", true);
                    break;
            }
        } else {
            var variable_number = 0;
		    var value_number = 0;
            var result = 0;
            switch (assignment.operator) {
                case "=":
                    result = value_number;
                    break;
                case "+":
                    result = variable_number + value_number;
                    break;
                case "-":
                    result = variable_number - value_number;
                    break;
                case "×":
                    result = variable_number * value_number;
                    break;
                case "÷":
                    result = variable_number / value_number;
                    break;
                default:
                    show_error("Error: Assignment operator '" + assignment.operator + "' is invalid.", true);
                    return;
            }
            set_variable_value(assignment.variable, string(result));
        }
    }
    
    static does_comparison_equate_to_true = function(comparison) {
        var variable_value = get_variable_value(comparison.variable);
        var parsed_value = get_variable_parsed_string(comparison.value);
        
        if (variable_value == noone) {
            return false;
        }
		
		var is_number = can_string_convert_to_number(variable_value) && can_string_convert_to_number(parsed_value);
        
        switch (comparison.operator) {
            case "=":
                return variable_value == parsed_value;
            case "≠":
                return variable_value != parsed_value;
            case "<":
                if (is_number) {
                    return real(variable_value) < real(parsed_value);
                }
                return variable_value < parsed_value;
            case "≤":
                if (is_number) {
                    return real(variable_value) <= real(parsed_value);
                }
                return variable_value <= parsed_value;
            case ">":
                if (is_number) {
                    return real(variable_value) > real(parsed_value);
                }
                return variable_value > parsed_value;
            case "≥":
                if (is_number) {
                    return real(variable_value) >= real(parsed_value);
                }
                return variable_value >= parsed_value;
            case "⊇":
                return string_pos(string(parsed_value), string(variable_value)) > 0;
            case "⊉":
                return string_pos(string(parsed_value), string(variable_value)) == 0;
            case "∈":
                return string_pos(string(variable_value), string(parsed_value)) > 0;
            case "∉":
                return string_pos(string(variable_value), string(parsed_value)) == 0;
            default:
                show_error("Error: Comparison operator '" + comparison.operator + "' is invalid.", true);
                return false;
        }
    }
    
    static get_probability_route_to_take = function(routes) {
        var valid = [];
        
        for (var i = 0; i < array_length(routes); i++) {
            var route = routes[i];
            var w = get_variable_parsed_string(route.weight);
            if (can_string_convert_to_number(w)) {
                array_push(valid, {weight: real(w), linksTo: route.linksTo});
            } else {
                show_error("Error: Could not parse weight '" + route.weight + "' for route at index " + string(i) + ".", true);
            }
        }
        
        if (array_length(valid) == 0) {
            show_error("No valid routes available.", true);
            return noone;
        }
        
        var total_weight = 0;
        for (var i = 0; i < array_length(valid); i++) {
            total_weight += valid[i].weight;
        }
        
        var rand = random(total_weight);
        var cumulative = 0;
        
        for (var i = 0; i < array_length(valid); i++) {
            var route = valid[i];
            cumulative += route.weight;
            if (rand < cumulative) {
                return route.linksTo;
            }
        }
        
        return valid[array_length(valid) - 1].linksTo;
    }
}

function Experience(proj, experience_name) constructor {
    project = proj;
    experience_data = project.get_experience(experience_name);
    current_node = noone;
    
    static get_node = function(node_id) {
        if (node_id == noone) {
            show_error("Error: get_node() received a null node ID.", true);
            return noone;
        }
        
        var node = noone;
        for (var i = 0; i < array_length(experience_data.nodeList); i++) {
            var n = experience_data.nodeList[i];
            if (n.id == node_id) {
                node = n;
                break;
            }
        }
        
        if (node == noone) {
            return noone;
        }
        
        // Helper functions
        var parse = function(val) {
            return project.get_variable_parsed_string(val);
        }
        
        var parse_props = function(props) {
            if (array_length(props) > 0) {
                for (var j = 0; j < array_length(props); j++) {
                    props[j].value = project.get_variable_parsed_string(props[j].value);
                }
            }
        }
        
        switch (node.type) {
            case "dialog":
                node.dialogSource = parse(node.dialogSource);
                node.dialogString = parse(node.dialogString);
                parse_props(node.properties);
                break;
            case "choice":
                if (array_length(node.choices) > 0) {
                    for (var j = 0; j < array_length(node.choices); j++) {
                        node.choices[j].choiceString = parse(node.choices[j].choiceString);
                    }
                }
                parse_props(node.properties);
                break;
            case "start":
			case "end":
                parse_props(node.properties);
                break;
            case "function":
                node.statement = parse(node.statement);
                break;
        }
        
        return node;
    }
    
    static get_start_node = function(start_node_name) {
        var start_node = noone;
        for (var i = 0; i < array_length(experience_data.nodeList); i++) {
            var n = experience_data.nodeList[i];
            if (n.type == "start" && n.name == start_node_name) {
                start_node = n;
                break;
            }
        }
        
        if (start_node == noone) {
            show_error("Error: No Start Node with the name '" + start_node_name + "' was found.", true);
            return noone;
        }
        
        current_node = start_node;
        return start_node;
    }
    
    static get_next_node = function(choice_index = noone) {
		var next_node = current_node;
        if (next_node == noone) {
            show_error("Error: No current node.", true);
            return noone;
        }
        
        if (next_node.type == "dialog" || next_node.type == "start" || next_node.type == "function") {
            next_node = get_node(next_node.linksTo);
        } else if (next_node.type == "choice") {
			if (string_length(string_letters(choice_index)) == 0) {
				choice_index = real(choice_index);
			}
            if (choice_index == noone || array_length(next_node.choices) == 0 || 
                choice_index < 0 || choice_index >= array_length(next_node.choices) ||
				!is_numeric(choice_index)) {
                show_error("Error: Invalid or missing choice index '" + string(choice_index) + "'.", true);
                return noone;
            }
            next_node = get_node(next_node.choices[choice_index].linksTo);
        } else if (next_node.type == "end" || next_node.type == "teleport") {
            show_error("Error: '" + next_node.type + "' Nodes don't link to anything.", true);
            return noone;
        } else {
            show_error("Error: Node type '" + next_node.type + "' is invalid.", true);
            return noone;
        }
        
        while (next_node != noone && 
               next_node.type != "dialog" && next_node.type != "choice" && 
               next_node.type != "start" && next_node.type != "end" && next_node.type != "function") {
            
            switch (next_node.type) {
                case "variable":
                    if (array_length(next_node.assignments) > 0) {
                        for (var i = 0; i < array_length(next_node.assignments); i++) {
                            project.process_assignment(next_node.assignments[i]);
                        }
                    }
                    next_node = get_node(next_node.linksTo);
                    break;
                case "conditional":
                    var route_to_take = -1;
                    for (var i = 0; i < array_length(next_node.routes); i++) {
                        var route = next_node.routes[i];
                        var all_true = true;
                        var any_true = false;
                        
                        for (var j = 0; j < array_length(route.comparisons); j++) {
                            var c = route.comparisons[j];
                            if (project.does_comparison_equate_to_true(c)) {
                                any_true = true;
                            } else {
                                all_true = false;
                            }
                        }
                        
                        switch (route.mode) {
                            case "all":
                                if (all_true) route_to_take = i;
                                break;
                            case "any":
                                if (any_true) route_to_take = i;
                                break;
                            case "none":
                                if (!any_true) route_to_take = i;
                                break;
                            default:
                                show_error("Error: Invalid comparison mode '" + route.mode + "'.", true);
                                break;
                        }
                    }
                    
                    if (route_to_take == -1) {
                        next_node = get_node(next_node.defaultRouteLinksTo);
                    } else {
                        next_node = get_node(next_node.routes[route_to_take].linksTo);
                    }
                    break;
                case "probability":
                    next_node = get_node(project.get_probability_route_to_take(next_node.routes));
                    break;
                case "teleport":
                    experience_data = project.get_experience(next_node.destinationExperience);
                    next_node = get_start_node(next_node.destinationStartNode);
                    break;
                default:
                    show_error("Error: Node type '" + next_node.type + "' is invalid.", true);
                    return noone;
            }
        }
        
        current_node = next_node;
        if (next_node == noone) {
            show_error("The chain terminated with no valid node.", true);
            return noone;
        }
        return next_node;
    }
}
