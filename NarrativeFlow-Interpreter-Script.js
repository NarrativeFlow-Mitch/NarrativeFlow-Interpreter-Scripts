/* -----
NarrativeFlow Interpreter Script V1.0

NarrativeFlow Interpreter Script Code License – Modified MIT License

Copyright (c) 2025 NarrativeFlow LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to use, copy, modify, merge, publish, and distribute the Software, subject to the following conditions:

1. The Software may be used in personal and commercial projects, including but not limited to, games, applications, educational content, and interactive experiences.

2. The Software may be included in commercial products, provided that it is not the primary value of the product (e.g., inclusion in a game or educational course is allowed and encouraged, but selling the code itself as a standalone template or package is not).

3. You may not sell, sublicense, or redistribute the Software on its own, or as part of a product where the main offering is access to the source code or derivative works of the Software, whether free or paid.

4. This copyright notice and permission notice must be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
----- */

class Variable {
  constructor(name, value) {
    this.name = name;
    this.value = value;
  }
}

class DataTableItem {
  constructor(name, value) {
    this.name = name;
    this.value = value;
  }
}

class Choice {
  constructor(choiceString, linksTo) {
    this.choiceString = choiceString;
    this.linksTo = linksTo;
  }
}

class Assignment {
  constructor(variable, operator, value) {
    this.variable = variable;
    this.operator = operator;
    this.value = value;
  }
}

class Comparison {
  constructor(variable, operator, value) {
    this.variable = variable;
    this.operator = operator;
    this.value = value;
  }
}

class Route {
  constructor(comparisons, mode, weight, linksTo) {
    this.comparisons = comparisons;
    this.mode = mode;
    this.weight = weight;
    this.linksTo = linksTo;
  }
}

class Property {
  constructor(name, value) {
    this.name = name;
    this.value = value;
  }
}

class Node {
  constructor() {
    this.id = null;
    this.type = null;
    this.linksTo = null;
    this.properties = [];
    this.dialogSource = null;
    this.dialogString = null;
    this.choices = [];
    this.name = null;
    this.assignments = [];
    this.routes = [];
    this.defaultRouteLinksTo = null;
    this.statement = null;
    this.destinationExperience = null;
    this.destinationStartNode = null;
  }
}

class ExperienceData {
  constructor(name, nodeList) {
    this.name = name;
    this.nodeList = nodeList;
  }
}

class Project {
  constructor(compiledProjectJSONString) {
    const data = JSON.parse(compiledProjectJSONString);
    this.experiences = data.experiences;
    this.variables = data.variables;
    this.dataTable = data.dataTable;
  }

  getExperience(name) {
    return this.experiences.find(exp => exp.name === name);
  }

  getVariableValue(name) {
    const v = this.variables.find(v => v.name === name);
    if (v) return v.value;
    console.error(`Error: Variable with the name '${name}' not found.`);
    return null;
  }

  setVariableValue(name, value) {
    const v = this.variables.find(v => v.name === name);
    if (v) {
      v.value = value;
      return true;
    }
    console.error(`Error: Variable with the name '${name}' not found.`);
    return false;
  }

  getVariableParsedString(str) {
    let result = str;
    for (const variable of this.variables) {
      const regex = new RegExp(variable.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
      result = result.replace(regex, variable.value);
    }
    return result;
  }

  getDataTableItemValue(name) {
    const item = this.dataTable.find(i => i.name === name);
    if (item) {
      return this.getVariableParsedString(item.value);
    }
    console.error(`Error: Data Table item with the name '${name}' not found.`);
    return null;
  }

  processAssignment(assignment) {
    const variableValue = this.getVariableValue(assignment.variable);
    const variableNumber = parseFloat(variableValue);
    const valueNumber = parseFloat(this.getVariableParsedString(assignment.value));

    if (isNaN(variableNumber) || isNaN(valueNumber)) {
      switch (assignment.operator) {
        case '=':
          this.setVariableValue(assignment.variable, assignment.value);
          break;
        case '+':
          this.setVariableValue(assignment.variable, variableValue + assignment.value);
          break;
        case '-':
        case '×':
        case '÷':
          console.error(`Error: '${assignment.operator}' can't be used on strings.`);
          break;
        default:
          console.error(`Error: Assignment operator '${assignment.operator}' is invalid.`);
      }
    } else {
      let result;
      switch (assignment.operator) {
        case '=':
          result = valueNumber;
          break;
        case '+':
          result = variableNumber + valueNumber;
          break;
        case '-':
          result = variableNumber - valueNumber;
          break;
        case '×':
          result = variableNumber * valueNumber;
          break;
        case '÷':
          result = variableNumber / valueNumber;
          break;
        default:
          console.error(`Error: Assignment operator '${assignment.operator}' is invalid.`);
          return;
      }
      this.setVariableValue(assignment.variable, result.toString());
    }
  }

  doesComparisonEquateToTrue(comparison) {
    const variableValue = this.getVariableValue(comparison.variable);
    const parsedValue = this.getVariableParsedString(comparison.value);
    if (variableValue == null) return false;

    switch (comparison.operator) {
      case '=': return variableValue === parsedValue;
      case '≠': return variableValue !== parsedValue;
      case '<': return parseFloat(variableValue) < parseFloat(parsedValue);
      case '≤': return parseFloat(variableValue) <= parseFloat(parsedValue);
      case '>': return parseFloat(variableValue) > parseFloat(parsedValue);
      case '≥': return parseFloat(variableValue) >= parseFloat(parsedValue);
      case '⊇': return variableValue.includes(parsedValue);
      case '⊉': return !variableValue.includes(parsedValue);
      case '∈': return parsedValue.includes(variableValue);
      case '∉': return !parsedValue.includes(variableValue);
      default:
        console.error(`Error: Comparison operator '${comparison.operator}' is invalid.`);
        return false;
    }
  }

  getProbabilityRouteToTake(routes) {
    const valid = [];
    routes.forEach((route, i) => {
      const w = parseFloat(this.getVariableParsedString(route.weight));
      if (!isNaN(w)) valid.push({ weight: w, linksTo: route.linksTo });
      else console.error(`Error: Could not parse weight '${route.weight}' for route at index ${i}.`);
    });

    if (valid.length === 0) {
      console.error('No valid routes available.');
      return null;
    }

    const totalWeight = valid.reduce((sum, r) => sum + r.weight, 0);
    const rand = Math.random() * totalWeight;
    let cumulative = 0;

    for (const route of valid) {
      cumulative += route.weight;
      if (rand < cumulative) return route.linksTo;
    }

    return valid[valid.length - 1].linksTo;
  }
}

class Experience {
  constructor(project, experienceName) {
    this.project = project;
    this.experienceData = this.project.getExperience(experienceName);
    this.currentNode = null;
  }

  getNode(nodeId) {
    if (nodeId == null) {
      console.error('Error: getNode() received a null node ID.');
      return null;
    }
    const node = this.experienceData.nodeList.find(n => n.id === nodeId);
    if (!node) return null;

    const parse = (val) => this.project.getVariableParsedString(val);
    const parseProps = (props) => props?.forEach(p => p.value = parse(p.value));

    switch (node.type) {
      case 'dialog':
        node.dialogSource = parse(node.dialogSource);
        node.dialogString = parse(node.dialogString);
        parseProps(node.properties);
        break;
      case 'choice':
        node.choices?.forEach(choice => choice.choiceString = parse(choice.choiceString));
        parseProps(node.properties);
        break;
      case 'start':
      case 'end':
        parseProps(node.properties);
        break;
      case 'function':
        node.statement = parse(node.statement);
        break;
    }

    return node;
  }

  getStartNode(startNodeName) {
    const startNode = this.experienceData.nodeList.find(n => n.type === 'start' && n.name === startNodeName);
    if (!startNode) {
      console.error(`Error: No Start Node with the name '${startNodeName}' was found.`);
    }
    this.currentNode = startNode;
    return startNode;
  }

  getNextNode(choiceIndex = null) {
    let nextNode = this.currentNode;
    if (!nextNode) {
      console.error('Error: No current node.');
      return null;
    }

    switch (nextNode.type) {
      case 'dialog':
      case 'start':
      case 'function':
        nextNode = this.getNode(nextNode.linksTo);
        break;
      case 'choice':
        if (choiceIndex == null || !nextNode.choices || choiceIndex < 0 || choiceIndex >= nextNode.choices.length) {
          console.error(`Error: Invalid or missing choice index '${choiceIndex}'.`);
          return null;
        }
        nextNode = this.getNode(nextNode.choices[choiceIndex].linksTo);
        break;
      case 'end':
      case 'teleport':
        console.error(`Error: '${nextNode.type}' Nodes don't link to anything.`);
        return null;
      default:
        console.error(`Error: Node type '${nextNode.type}' is invalid.`);
        return null;
    }

    while (nextNode && !['dialog', 'choice', 'start', 'end', 'function'].includes(nextNode.type)) {
      switch (nextNode.type) {
        case 'variable':
          nextNode.assignments?.forEach(a => this.project.processAssignment(a));
          nextNode = this.getNode(nextNode.linksTo);
          break;
        case 'conditional': {
          let routeToTake = -1;
          for (let i = 0; i < nextNode.routes.length; i++) {
            const route = nextNode.routes[i];
            const allTrue = route.comparisons.every(c => this.project.doesComparisonEquateToTrue(c));
            const anyTrue = route.comparisons.some(c => this.project.doesComparisonEquateToTrue(c));
            switch (route.mode) {
              case 'all': if (allTrue) routeToTake = i; break;
              case 'any': if (anyTrue) routeToTake = i; break;
              case 'none': if (!anyTrue) routeToTake = i; break;
              default: console.error(`Error: Invalid comparison mode '${route.mode}'.`);
            }
          }
          nextNode = this.getNode(routeToTake === -1 ? nextNode.defaultRouteLinksTo : nextNode.routes[routeToTake].linksTo);
          break;
        }
        case 'probability':
          nextNode = this.getNode(this.project.getProbabilityRouteToTake(nextNode.routes));
          break;
        case 'teleport':
          this.experienceData = this.project.getExperience(nextNode.destinationExperience);
          nextNode = this.getStartNode(nextNode.destinationStartNode);
          break;
        default:
          console.error(`Error: Node type '${nextNode.type}' is invalid.`);
          return null;
      }
    }

    this.currentNode = nextNode;
    if (!nextNode) {
      console.error('The chain terminated with no valid node.');
      return null;
    }
    return nextNode;
  }
}

