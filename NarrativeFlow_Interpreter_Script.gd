# NarrativeFlow Interpreter Script V1.0
#
# NarrativeFlow Interpreter Script Code License - Modified MIT License
#
# Copyright (c) 2025 NarrativeFlow LLC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, merge, publish, and distribute the Software, subject to the following conditions:
#
# 1. The Software may be used in personal and commercial projects, including but not limited to, games, applications, educational content, and interactive experiences.
#
# 2. The Software may be included in commercial products, provided that it is not the primary value of the product (e.g., inclusion in a game or educational course is allowed and encouraged, but selling the code itself as a standalone template or package is not).
#
# 3. You may not sell, sublicense, or redistribute the Software on its own, or as part of a product where the main offering is access to the source code or derivative works of the Software, whether free or paid.
#
# 4. This copyright notice and permission notice must be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class Project:
	extends RefCounted
	var experiences: Array
	var variables: Array
	var dataTable: Array
	func _init(compiled_project_json_string: String):
		var data = JSON.parse_string(compiled_project_json_string)
		experiences = data.experiences
		variables = data.variables
		dataTable = data.dataTable

	func get_experience(name: String) -> Dictionary:
		for experience in experiences:
			if experience.name == name:
				return experience
		return {}

	func get_variable_value(name: String) -> Variant:
		for v in variables:
			if v.name == name:
				return v.value
		print("Error: Variable with the name '%s' not found." % name)
		return null

	func set_variable_value(name: String, value: Variant) -> bool:
		for v in variables:
			if v.name == name:
				v.value = value
				return true
		print("Error: Variable with the name '%s' not found." % name)
		return false
	
	func regex_escape(text: String) -> String:
		# List of regex special characters to escape
		var specials = ['\\', '.', '+', '*', '?', '^', '$', '(', ')', '[', ']', '{', '}', '|']
		for character in specials:
			text = text.replace(character, '\\' + character)
		return text

	func get_variable_parsed_string(str_val: String) -> String:
		var result = str_val
		for variable in variables:
			# Escape regex special characters
			var escaped_name = regex_escape(variable.name)
			var regex = RegEx.new()
			regex.compile(escaped_name)
			result = regex.sub(result, str(variable.value), true)
		return result

	func get_data_table_item_value(name: String) -> Variant:
		for item in dataTable:
			if item.name == name:
				return get_variable_parsed_string(item.value)
		print("Error: Data Table item with the name '%s' not found." % name)
		return null

	func process_assignment(assignment: Dictionary):
		var variable_value = get_variable_value(assignment.variable)
		var is_numeric = false
		
		# Check if values are numeric
		is_numeric = variable_value.is_valid_float() and get_variable_parsed_string(assignment.value).is_valid_float()

		if not is_numeric:
			match assignment.operator:
				"=":
					set_variable_value(assignment.variable, assignment.value)
				"+":
					set_variable_value(assignment.variable, str(variable_value) + str(assignment.value))
				"-", "×", "÷":
					print("Error: '%s' can't be used on strings." % assignment.operator)
				_:
					print("Error: Assignment operator '%s' is invalid." % assignment.operator)
		else:
			var variable_number = variable_value.to_float()
			var value_number = get_variable_parsed_string(assignment.value).to_float()
			var result: float
			match assignment.operator:
				"=":
					result = value_number
				"+":
					result = variable_number + value_number
				"-":
					result = variable_number - value_number
				"×":
					result = variable_number * value_number
				"÷":
					result = variable_number / value_number
				_:
					print("Error: Assignment operator '%s' is invalid." % assignment.operator)
					return
			set_variable_value(assignment.variable, str(result))

	func does_comparison_equate_to_true(comparison: Dictionary) -> bool:
		var variable_value = get_variable_value(comparison.variable)
		var parsed_value = get_variable_parsed_string(comparison.value)
		if variable_value == null:
			return false

		match comparison.operator:
			"=":
				return variable_value == parsed_value
			"≠":
				return variable_value != parsed_value
			"<":
				if variable_value is String:
					return variable_value.to_float() < parsed_value.to_float()
				return float(variable_value) < float(parsed_value)
			"≤":
				if variable_value is String:
					return variable_value.to_float() <= parsed_value.to_float()
				return float(variable_value) <= float(parsed_value)
			">":
				if variable_value is String:
					return variable_value.to_float() > parsed_value.to_float()
				return float(variable_value) > float(parsed_value)
			"≥":
				if variable_value is String:
					return variable_value.to_float() >= parsed_value.to_float()
				return float(variable_value) >= float(parsed_value)
			"⊇":
				return str(parsed_value) in str(variable_value)
			"⊉":
				return str(parsed_value) not in str(variable_value)
			"∈":
				return str(variable_value) in str(parsed_value)
			"∉":
				return str(variable_value) not in str(parsed_value)
			_:
				print("Error: Comparison operator '%s' is invalid." % comparison.operator)
				return false

	func get_probability_route_to_take(routes: Array) -> Variant:
		var valid: Array = []
		for i in range(routes.size()):
			var route = routes[i]
			var w = get_variable_parsed_string(route.weight).to_float()
			if !is_nan(w):
				valid.append({"weight": w, "linksTo": route.linksTo})
			else:
				print("Error: Could not parse weight '%s' for route at index %d." % [route.weight, i])

		if valid.is_empty():
			print("No valid routes available.")
			return null

		var total_weight: float = 0
		for r in valid:
			total_weight += r.weight
		
		var rand = randf() * total_weight
		var cumulative: float = 0

		for route in valid:
			cumulative += route.weight
			if rand < cumulative:
				return route.linksTo

		return valid[-1].linksTo


class Experience:
	extends RefCounted
	var project: Project
	var experience_data: Dictionary
	var current_node: Dictionary
	func _init(proj: Project, experience_name: String):
		project = proj
		experience_data = project.get_experience(experience_name)
		current_node = {}

	func get_node(node_id: Variant) -> Dictionary:
		if node_id == null:
			print("Error: getNode() received a null node ID.")
			return {}
		
		var node: Dictionary
		for n in experience_data.nodeList:
			if n.id == node_id:
				node = n
				break
		
		if node.is_empty():
			return {}

		var parse = func parse(val: Variant) -> Variant:
			return project.get_variable_parsed_string(val)

		var parse_props = func parse_props(props: Array):
			if props:
				for p in props:
					p.value = parse.call(p.value)

		match node.type:
			"dialog":
				node.dialogSource = parse.call(node.dialogSource)
				node.dialogString = parse.call(node.dialogString)
				parse_props.call(node.properties)
			"choice":
				if node.choices:
					for choice in node.choices:
						choice.choiceString = parse.call(choice.choiceString)
				parse_props.call(node.properties)
			"start", "end":
				parse_props.call(node.properties)
			"function":
				node.statement = parse.call(node.statement)

		return node

	func get_start_node(start_node_name: String) -> Dictionary:
		var start_node: Dictionary
		for n in experience_data.nodeList:
			if n.type == "start" and n.name == start_node_name:
				start_node = n
				break
		
		if start_node.is_empty():
			print("Error: No Start Node with the name '%s' was found." % start_node_name)
			return {}
		
		current_node = start_node
		return start_node

	func get_next_node(choice_index: Variant = null) -> Dictionary:
		var next_node = current_node
		if next_node.is_empty():
			print("Error: No current node.")
			return {}

		if next_node.type in ["dialog", "start", "function"]:
			next_node = get_node(next_node.linksTo)
		elif next_node.type == "choice":
			if (choice_index == null or not next_node.choices or 
				choice_index < 0 or choice_index >= next_node.choices.size()):
				print("Error: Invalid or missing choice index '%s'." % choice_index)
				return {}
			next_node = get_node(next_node.choices[choice_index].linksTo)
		elif next_node.type in ["end", "teleport"]:
			print("Error: '%s' Nodes don't link to anything." % next_node.type)
			return {}
		else:
			print("Error: Node type '%s' is invalid." % next_node.type)
			return {}

		while next_node and next_node.type not in ["dialog", "choice", "start", "end", "function"]:
			match next_node.type:
				"variable":
					if next_node.assignments:
						for a in next_node.assignments:
							project.process_assignment(a)
					next_node = get_node(next_node.linksTo)
				"conditional":
					var route_to_take: int = -1
					for i in range(next_node.routes.size()):
						var route = next_node.routes[i]
						var all_true = true
						var any_true = false
						
						for c in route.comparisons:
							if project.does_comparison_equate_to_true(c):
								any_true = true
							else:
								all_true = false
						
						match route.mode:
							"all":
								if all_true:
									route_to_take = i
							"any":
								if any_true:
									route_to_take = i
							"none":
								if not any_true:
									route_to_take = i
							_:
								print("Error: Invalid comparison mode '%s'." % route.mode)
					
					if route_to_take == -1:
						next_node = get_node(next_node.defaultRouteLinksTo)
					else:
						next_node = get_node(next_node.routes[route_to_take].linksTo)
				"probability":
					next_node = get_node(project.get_probability_route_to_take(next_node.routes))
				"teleport":
					experience_data = project.get_experience(next_node.destinationExperience)
					next_node = get_start_node(next_node.destinationStartNode)
				_:
					print("Error: Node type '%s' is invalid." % next_node.type)
					return {}

		current_node = next_node
		if next_node.is_empty():
			print("The chain terminated with no valid node.")
			return {}
		return next_node
