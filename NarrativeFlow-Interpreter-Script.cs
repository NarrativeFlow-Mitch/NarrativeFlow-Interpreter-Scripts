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

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;

namespace NarrativeFlow {
    public class Variable {
        public string Name { get; set; }
        public string Value { get; set; }
    }

    public class DataTableItem {
        public string Name { get; set; }
        public string Value { get; set; }
    }

    public class Choice {
        public string ChoiceString { get; set; }
        public int LinksTo { get; set; }
    }

    public class Assignment {
        public string Variable { get; set; }
        public string Operator { get; set; }
        public string Value { get; set; }
    }

    public class Comparison {
        public string Variable { get; set; }
        public string Operator { get; set; }
        public string Value { get; set; }
    }

    public class Route {
        public List<Comparison> Comparisons { get; set; }
        public string Mode { get; set; }
        public string Weight { get; set; }
        public int LinksTo { get; set; }
    }

    public class Property {
        public string Name { get; set; }
        public string Value { get; set; }
    }

    public class Node {
        public int Id { get; set; }
        public string Type { get; set; }
        public int? LinksTo { get; set; }
        public List<Property> Properties { get; set; }

        public string DialogSource { get; set; }
        public string DialogString { get; set; }
        public List<Choice> Choices { get; set; }
        public string Name { get; set; }
        public List<Assignment> Assignments { get; set; }
        public List<Route> Routes { get; set; }
        public int? DefaultRouteLinksTo { get; set; }
        public string Statement { get; set; }
        public string DestinationExperience { get; set; }
        public string DestinationStartNode { get; set; }
    }

    public class ExperienceData {
        public string Name { get; set; }
        public List<Node> NodeList { get; set; }
    }

    public class ProjectData {
        public List<ExperienceData> Experiences { get; set; }
        public List<Variable> Variables { get; set; }
        public List<DataTableItem> DataTable { get; set; }
    }

    public class Project {
        private readonly List<ExperienceData> Experiences;
        public readonly List<Variable> Variables;
        private readonly List<DataTableItem> DataTable;

        public Project(string compiledProjectFileJSONString) {
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var DeserializedProject = JsonSerializer.Deserialize<ProjectData>(compiledProjectFileJSONString, options);
            Experiences = DeserializedProject.Experiences;
            Variables = DeserializedProject.Variables;
            DataTable = DeserializedProject.DataTable;
        }

        public ExperienceData GetExperience(string experienceName) {
            return Experiences.FirstOrDefault(experience => experience.Name == experienceName);
        }

        public string GetVariableValue(string variableName) {
            var variable = Variables.FirstOrDefault(v => v.Name == variableName);
            if (variable != null) {
                return variable.Value;
            }
            else {
                Console.Error.WriteLine($"Error: Variable with the name '{variableName}' not found.");
                return null;
            }
        }

        public bool SetVariableValue(string variableName, string newValue) {
            var variable = Variables.FirstOrDefault(v => v.Name == variableName);
            if (variable != null) {
                variable.Value = newValue;
                return true;
            }
            else {
                Console.Error.WriteLine($"Error: Variable with the name '{variableName}' not found.");
                return false;
            }
        }

        public string GetVariableParsedString(string str) {
            foreach (var variable in Variables) {
                string escapedName = System.Text.RegularExpressions.Regex.Escape(variable.Name);
                str = System.Text.RegularExpressions.Regex.Replace(str, escapedName, variable.Value);
            }
            return str;
        }

        public string GetDataTableItemValue(string itemName) {
            var item = DataTable.FirstOrDefault(i => i.Name == itemName);
            if (item != null) {
                return GetVariableParsedString(item.Value);
            }
            else {
                Console.Error.WriteLine($"Error: Data Table item with the name '{itemName}' not found.");
                return null;
            }
        }

        public void ProcessAssignment(Assignment Assignment) {
            var VariableValue = GetVariableValue(Assignment.Variable);
            double? VariableNumber = double.TryParse(GetVariableValue(Assignment.Variable), out double varNum) ? varNum : null;
            double? ValueNumber = double.TryParse(GetVariableParsedString(Assignment.Value), out double valNum) ? valNum : null;

            if (VariableNumber == null || ValueNumber == null) {
                switch (Assignment.Operator) {
                    case "=":
                        SetVariableValue(Assignment.Variable, Assignment.Value);
                        break;
                    case "+":
                        SetVariableValue(Assignment.Variable, VariableValue + Assignment.Value);
                        break;
                    case "-":
                    case "×":
                    case "÷":
                        Console.Error.WriteLine($"Error: '{Assignment.Operator}' can't be used on strings.");
                        break;
                    default:
                        Console.Error.WriteLine($"Error: Assignment operator '{Assignment.Operator}' is invalid.");
                        break;
                }
            }
            else { // VariableNumber and ValueNumber both successfully parsed numbers
                switch (Assignment.Operator) {
                    case "=":
                        SetVariableValue(Assignment.Variable, Assignment.Value);
                        break;
                    case "+":
                        SetVariableValue(Assignment.Variable, (VariableNumber + ValueNumber).ToString());
                        break;
                    case "-":
                        SetVariableValue(Assignment.Variable, (VariableNumber - ValueNumber).ToString());
                        break;
                    case "×":
                        SetVariableValue(Assignment.Variable, (VariableNumber * ValueNumber).ToString());
                        break;
                    case "÷":
                        SetVariableValue(Assignment.Variable, (VariableNumber / ValueNumber).ToString());
                        break;
                    default:
                        Console.Error.WriteLine($"Error: Assignment operator '{Assignment.Operator}' is invalid.");
                        break;
                }
            }
        }

        public bool DoesComparisonEquateToTrue(Comparison comparison) {
            var variableValue = GetVariableValue(comparison.Variable);
            var parsedValue = GetVariableParsedString(comparison.Value);

            if (variableValue == null) {
                return false;
            }

            switch (comparison.Operator) {
                case "=":
                    return variableValue.ToString() == parsedValue;
                case "≠":
                    return variableValue.ToString() != parsedValue;
                case "<":
                    return Convert.ToDouble(variableValue) < Convert.ToDouble(parsedValue);
                case "≤":
                    return Convert.ToDouble(variableValue) <= Convert.ToDouble(parsedValue);
                case ">":
                    return Convert.ToDouble(variableValue) > Convert.ToDouble(parsedValue);
                case "≥":
                    return Convert.ToDouble(variableValue) >= Convert.ToDouble(parsedValue);
                case "⊇":
                    return variableValue.ToString().Contains(parsedValue);
                case "⊉":
                    return !variableValue.ToString().Contains(parsedValue);
                case "∈":
                    return parsedValue.Contains(variableValue.ToString());
                case "∉":
                    return !parsedValue.Contains(variableValue.ToString());
                default:
                    Console.Error.WriteLine($"Error: Comparison operator '{comparison.Operator}' is invalid.");
                    return false;
            }
        }

        public int? GetProbabilityRouteToTake(List<Route> routes) {
            var validWeightsWithIndices = new List<(double weight, int linksTo, int index)>();

            for (int i = 0; i < routes.Count; i++) {
                var route = routes[i];
                var parsedWeight = GetVariableParsedString(route.Weight);
                if (double.TryParse(parsedWeight, out double weight)) {
                    validWeightsWithIndices.Add((weight, route.LinksTo, i));
                }
                else {
                    Console.Error.WriteLine($"Error: Could not parse weight '{route.Weight}' for route at index {i} linking to {route.LinksTo}.");
                }
            }

            if (!validWeightsWithIndices.Any()) {
                Console.Error.WriteLine("No valid routes available.");
                return null;
            }

            var totalWeight = validWeightsWithIndices.Sum(r => r.weight);
            var random = new Random().NextDouble() * totalWeight;

            double sum = 0;
            foreach (var route in validWeightsWithIndices) {
                sum += route.weight;
                if (random < sum) {
                    return route.linksTo;
                }
            }

            return validWeightsWithIndices.Last().linksTo;
        }
    }

    public class Experience {
        private readonly Project Project;
        private ExperienceData ExperienceData;
        private Node CurrentNode;

        public Experience(Project project, string experienceName) {
            Project = project;
            ExperienceData = Project.GetExperience(experienceName);
            CurrentNode = null;
        }

        public Node GetNode(int? nodeId) {
            if (nodeId == null) {
                Console.Error.WriteLine("Error: GetNode() received a null node ID.");
                return null;
            }
            Node node = ExperienceData.NodeList.FirstOrDefault(n => n.Id == nodeId);
            switch (node.Type) {
                case "dialog":
                    node.DialogSource = Project.GetVariableParsedString(node.DialogSource);
                    node.DialogString = Project.GetVariableParsedString(node.DialogString);
                    node.Properties?.ForEach(property => property.Value = Project.GetVariableParsedString(property.Value));
                    break;
                case "choice":
                    node.Choices?.ForEach(choice => choice.ChoiceString = Project.GetVariableParsedString(choice.ChoiceString));
                    node.Properties?.ForEach(property => property.Value = Project.GetVariableParsedString(property.Value));
                    break;
                case "start":
                case "end":
                    node.Properties?.ForEach(property => property.Value = Project.GetVariableParsedString(property.Value));
                    break;
                case "function":
                    node.Statement = Project.GetVariableParsedString(node.Statement);
                    break;
            }
            return node;
        }

        public Node GetStartNode(string startNodeName) {
            var startNode = ExperienceData.NodeList.FirstOrDefault(node => node.Type == "start" && node.Name == startNodeName);
            if (startNode == null) {
                Console.Error.WriteLine($"Error: No Start Node with the name '{startNodeName}' was found.");
            }
            CurrentNode = startNode;
            return startNode;
        }

        public Node GetNextNode(int? choiceIndex = null) {
            Node nextNode = CurrentNode;
            if (nextNode == null) {
                Console.Error.WriteLine("Error: No current node.");
                return null;
            }

            switch (CurrentNode.Type) {
                case "dialog":
                case "start":
                case "function":
                    nextNode = GetNode(nextNode.LinksTo);
                    break;
                case "choice":
                    if (!choiceIndex.HasValue || nextNode.Choices == null || choiceIndex.Value < 0 || choiceIndex.Value >= nextNode.Choices.Count) {
                        Console.Error.WriteLine($"Error: Invalid or missing choice index '{choiceIndex}' for node with {nextNode.Choices?.Count ?? 0} choices.");
                        return null;
                    }
                    nextNode = GetNode(nextNode.Choices[choiceIndex.Value].LinksTo);
                    break;
                case "end":
                case "teleport":
                    Console.Error.WriteLine($"Error: '{nextNode.Type}' Nodes don't link to anything.");
                    return null;
                default:
                    Console.Error.WriteLine($"Error: Node type '{nextNode.Type}' is invalid.");
                    return null;
            }

            do {
                switch (nextNode.Type) {
                    case "variable":
                        nextNode.Assignments?.ForEach(assignment => Project.ProcessAssignment(assignment));
                        nextNode = GetNode(nextNode.LinksTo);
                        break;
                    case "conditional":
                        int routeToTake = -1;
                        for (int routeIndex = 0; routeIndex < nextNode.Routes.Count; routeIndex++) {
                            bool doAllComparisonsEquateToTrue = true;
                            bool doesAnyComparisonEquateToTrue = false;
                            for (int comparisonIndex = 0; comparisonIndex < nextNode.Routes[routeIndex].Comparisons.Count; comparisonIndex++) {
                                var comparison = nextNode.Routes[routeIndex].Comparisons[comparisonIndex];
                                if (!Project.DoesComparisonEquateToTrue(comparison)) {
                                    doAllComparisonsEquateToTrue = false;
                                }
                                else {
                                    doesAnyComparisonEquateToTrue = true;
                                }
                            }
                            switch (nextNode.Routes[routeIndex].Mode) {
                                case "all":
                                    if (doAllComparisonsEquateToTrue) {
                                        routeToTake = routeIndex;
                                    }
                                    break;
                                case "any":
                                    if (doesAnyComparisonEquateToTrue) {
                                        routeToTake = routeIndex;
                                    }
                                    break;
                                case "none":
                                    if (!doesAnyComparisonEquateToTrue) {
                                        routeToTake = routeIndex;
                                    }
                                    break;
                                default:
                                    Console.Error.WriteLine($"Error: Invalid comparison mode '{nextNode.Routes[routeIndex].Mode}'.");
                                    break;
                            }
                        }
                        nextNode = routeToTake == -1
                            ? GetNode(nextNode.DefaultRouteLinksTo)
                            : GetNode(nextNode.Routes[routeToTake].LinksTo);
                        break;
                    case "probability":
                        nextNode = GetNode(Project.GetProbabilityRouteToTake(nextNode.Routes));
                        break;
                    case "teleport":
                        ExperienceData = Project.GetExperience(nextNode.DestinationExperience);
                        nextNode = GetStartNode(nextNode.DestinationStartNode);
                        break;
                    default:
                        if (nextNode == null) {
                            Console.Error.WriteLine("Error: nextNode is undefined.");
                        }
                        else {
                            Console.Error.WriteLine($"Error: Node type '{nextNode.Type}' is invalid.");
                        }
                        break;
                }
            }
            while (nextNode != null && !new[] { "dialog", "choice", "start", "end", "function" }.Contains(nextNode.Type));

            CurrentNode = nextNode;
            if (nextNode == null) {
                Console.Error.WriteLine("The chain either contained no Dialog, Choice, Start, End, or Function Nodes or contained an invalid property/value.");
                return null;
            }
            return nextNode;
        }
    }
}

