"""
NarrativeFlow Interpreter Script V1.0

NarrativeFlow Interpreter Script Code License - Modified MIT License

Copyright (c) 2025 NarrativeFlow LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to use, copy, modify, merge, publish, and distribute the Software, subject to the following conditions:

1. The Software may be used in personal and commercial projects, including but not limited to, games, applications, educational content, and interactive experiences.

2. The Software may be included in commercial products, provided that it is not the primary value of the product (e.g., inclusion in a game or educational course is allowed and encouraged, but selling the code itself as a standalone template or package is not).

3. You may not sell, sublicense, or redistribute the Software on its own, or as part of a product where the main offering is access to the source code or derivative works of the Software, whether free or paid.

4. This copyright notice and permission notice must be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""

import json
import random
import re


class Variable:
    def __init__(self, name, value):
        self.name = name
        self.value = value


class DataTableItem:
    def __init__(self, name, value):
        self.name = name
        self.value = value


class Choice:
    def __init__(self, choiceString, linksTo):
        self.choiceString = choiceString
        self.linksTo = linksTo


class Assignment:
    def __init__(self, variable, operator, value):
        self.variable = variable
        self.operator = operator
        self.value = value


class Comparison:
    def __init__(self, variable, operator, value):
        self.variable = variable
        self.operator = operator
        self.value = value


class Route:
    def __init__(self, comparisons, mode, weight, linksTo):
        self.comparisons = comparisons
        self.mode = mode
        self.weight = weight
        self.linksTo = linksTo


class Property:
    def __init__(self, name, value):
        self.name = name
        self.value = value


class Node:
    def __init__(self):
        self.id = None
        self.type = None
        self.linksTo = None
        self.properties = []
        self.dialogSource = None
        self.dialogString = None
        self.choices = []
        self.name = None
        self.assignments = []
        self.routes = []
        self.defaultRouteLinksTo = None
        self.statement = None
        self.destinationExperience = None
        self.destinationStartNode = None


class ExperienceData:
    def __init__(self, name, nodeList):
        self.name = name
        self.nodeList = nodeList


class Project:
    def __init__(self, compiledProjectJSONString):
        data = json.loads(compiledProjectJSONString)
        self.experiences = data['experiences']
        self.variables = data['variables']
        self.dataTable = data['dataTable']

    def getExperience(self, name):
        return next((exp for exp in self.experiences if exp['name'] == name), None)

    def getVariableValue(self, name):
        variable = next((v for v in self.variables if v['name'] == name), None)
        if variable:
            return variable['value']
        print(f"Error: Variable with the name '{name}' not found.")
        return None

    def setVariableValue(self, name, value):
        variable = next((v for v in self.variables if v['name'] == name), None)
        if variable:
            variable['value'] = value
            return True
        print(f"Error: Variable with the name '{name}' not found.")
        return False

    def getVariableParsedString(self, str_val):
        result = str_val
        for variable in self.variables:
            # Escape regex special characters
            escaped_name = re.escape(variable['name'])
            result = re.sub(escaped_name, str(variable['value']), result)
        return result

    def getDataTableItemValue(self, name):
        item = next((i for i in self.dataTable if i['name'] == name), None)
        if item:
            return self.getVariableParsedString(item['value'])
        print(f"Error: Data Table item with the name '{name}' not found.")
        return None

    def processAssignment(self, assignment):
        variable_value = self.getVariableValue(assignment['variable'])
        try:
            variable_number = float(variable_value)
            value_number = float(self.getVariableParsedString(assignment['value']))
            is_numeric = True
        except (ValueError, TypeError):
            is_numeric = False

        if not is_numeric:
            if assignment['operator'] == '=':
                self.setVariableValue(assignment['variable'], assignment['value'])
            elif assignment['operator'] == '+':
                self.setVariableValue(assignment['variable'], str(variable_value) + str(assignment['value']))
            elif assignment['operator'] in ['-', '×', '÷']:
                print(f"Error: '{assignment['operator']}' can't be used on strings.")
            else:
                print(f"Error: Assignment operator '{assignment['operator']}' is invalid.")
        else:
            if assignment['operator'] == '=':
                result = value_number
            elif assignment['operator'] == '+':
                result = variable_number + value_number
            elif assignment['operator'] == '-':
                result = variable_number - value_number
            elif assignment['operator'] == '×':
                result = variable_number * value_number
            elif assignment['operator'] == '÷':
                result = variable_number / value_number
            else:
                print(f"Error: Assignment operator '{assignment['operator']}' is invalid.")
                return
            self.setVariableValue(assignment['variable'], str(result))

    def doesComparisonEquateToTrue(self, comparison):
        variable_value = self.getVariableValue(comparison['variable'])
        parsed_value = self.getVariableParsedString(comparison['value'])
        if variable_value is None:
            return False

        if comparison['operator'] == '=':
            return variable_value == parsed_value
        elif comparison['operator'] == '≠':
            return variable_value != parsed_value
        elif comparison['operator'] == '<':
            try:
                return float(variable_value) < float(parsed_value)
            except ValueError:
                return False
        elif comparison['operator'] == '≤':
            try:
                return float(variable_value) <= float(parsed_value)
            except ValueError:
                return False
        elif comparison['operator'] == '>':
            try:
                return float(variable_value) > float(parsed_value)
            except ValueError:
                return False
        elif comparison['operator'] == '≥':
            try:
                return float(variable_value) >= float(parsed_value)
            except ValueError:
                return False
        elif comparison['operator'] == '⊇':
            return str(parsed_value) in str(variable_value)
        elif comparison['operator'] == '⊉':
            return str(parsed_value) not in str(variable_value)
        elif comparison['operator'] == '∈':
            return str(variable_value) in str(parsed_value)
        elif comparison['operator'] == '∉':
            return str(variable_value) not in str(parsed_value)
        else:
            print(f"Error: Comparison operator '{comparison['operator']}' is invalid.")
            return False

    def getProbabilityRouteToTake(self, routes):
        valid = []
        for i, route in enumerate(routes):
            try:
                w = float(self.getVariableParsedString(route['weight']))
                valid.append({'weight': w, 'linksTo': route['linksTo']})
            except ValueError:
                print(f"Error: Could not parse weight '{route['weight']}' for route at index {i}.")

        if not valid:
            print('No valid routes available.')
            return None

        total_weight = sum(r['weight'] for r in valid)
        rand = random.random() * total_weight
        cumulative = 0

        for route in valid:
            cumulative += route['weight']
            if rand < cumulative:
                return route['linksTo']

        return valid[-1]['linksTo']


class Experience:
    def __init__(self, project, experienceName):
        self.project = project
        self.experienceData = self.project.getExperience(experienceName)
        self.currentNode = None

    def getNode(self, nodeId):
        if nodeId is None:
            print('Error: getNode() received a null node ID.')
            return None
        
        node = next((n for n in self.experienceData['nodeList'] if n['id'] == nodeId), None)
        
        if not node:
            return None

        def parse(val):
            return self.project.getVariableParsedString(val)

        def parse_props(props):
            if props:
                for p in props:
                    p['value'] = parse(p['value'])

        if node['type'] == 'dialog':
            node['dialogSource'] = parse(node['dialogSource'])
            node['dialogString'] = parse(node['dialogString'])
            parse_props(node['properties'])
        elif node['type'] == 'choice':
            if node['choices']:
                for choice in node['choices']:
                    choice['choiceString'] = parse(choice['choiceString'])
            parse_props(node['properties'])
        elif node['type'] in ['start', 'end']:
            parse_props(node['properties'])
        elif node['type'] == 'function':
            node['statement'] = parse(node['statement'])

        return node

    def getStartNode(self, startNodeName):
        start_node = next((n for n in self.experienceData['nodeList'] 
                          if n['type'] == 'start' and n['name'] == startNodeName), None)
        
        if not start_node:
            print(f"Error: No Start Node with the name '{startNodeName}' was found.")
            return None
        
        self.currentNode = start_node
        return start_node

    def getNextNode(self, choiceIndex=None):
        next_node = self.currentNode
        if not next_node:
            print('Error: No current node.')
            return None

        if next_node['type'] in ['dialog', 'start', 'function']:
            next_node = self.getNode(next_node['linksTo'])
        elif next_node['type'] == 'choice':
            if (choiceIndex is None or not next_node['choices'] or 
                choiceIndex < 0 or choiceIndex >= len(next_node['choices'])):
                print(f"Error: Invalid or missing choice index '{choiceIndex}'.")
                return None
            next_node = self.getNode(next_node['choices'][choiceIndex]['linksTo'])
        elif next_node['type'] in ['end', 'teleport']:
            print(f"Error: '{next_node['type']}' Nodes don't link to anything.")
            return None
        else:
            print(f"Error: Node type '{next_node['type']}' is invalid.")
            return None

        while next_node and next_node['type'] not in ['dialog', 'choice', 'start', 'end', 'function']:
            if next_node['type'] == 'variable':
                if next_node['assignments']:
                    for a in next_node['assignments']:
                        self.project.processAssignment(a)
                next_node = self.getNode(next_node['linksTo'])
            elif next_node['type'] == 'conditional':
                route_to_take = -1
                for i, route in enumerate(next_node['routes']):
                    all_true = all(self.project.doesComparisonEquateToTrue(c) for c in route['comparisons'])
                    any_true = any(self.project.doesComparisonEquateToTrue(c) for c in route['comparisons'])
                    
                    if route['mode'] == 'all' and all_true:
                        route_to_take = i
                    elif route['mode'] == 'any' and any_true:
                        route_to_take = i
                    elif route['mode'] == 'none' and not any_true:
                        route_to_take = i
                    else:
                        print(f"Error: Invalid comparison mode '{route['mode']}'.")
                
                if route_to_take == -1:
                    next_node = self.getNode(next_node['defaultRouteLinksTo'])
                else:
                    next_node = self.getNode(next_node['routes'][route_to_take]['linksTo'])
            elif next_node['type'] == 'probability':
                next_node = self.getNode(self.project.getProbabilityRouteToTake(next_node['routes']))
            elif next_node['type'] == 'teleport':
                self.experienceData = self.project.getExperience(next_node['destinationExperience'])
                next_node = self.getStartNode(next_node['destinationStartNode'])
            else:
                print(f"Error: Node type '{next_node['type']}' is invalid.")
                return None

        self.currentNode = next_node
        if not next_node:
            print('The chain terminated with no valid node.')
            return None
        return next_node
