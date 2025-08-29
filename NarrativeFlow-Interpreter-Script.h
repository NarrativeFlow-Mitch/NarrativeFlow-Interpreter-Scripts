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

#pragma once

#include <string>
#include <vector>
#include <optional>
#include <iostream>
#include <regex>
#include <algorithm>
#include <random>
#include "json.hpp"

using json = nlohmann::json;

namespace nlohmann {
    template<typename T>
    struct adl_serializer<std::optional<T>> {
        static void to_json(json& j, const std::optional<T>& opt) {
            if (opt.has_value()) {
                j = *opt;
            } else {
                j = nullptr;
            }
        }

        static void from_json(const json& j, std::optional<T>& opt) {
            if (j.is_null()) {
                opt = std::nullopt;
            } else {
                opt = j.get<T>();
            }
        }
    };
}

namespace NarrativeFlow {

    struct Variable {
        std::string Name;
        std::string Value;
    };

    struct DataTableItem {
        std::string Name;
        std::string Value;
    };

    struct Choice {
        std::string ChoiceString;
        int LinksTo;
    };

    struct Assignment {
        std::string Variable;
        std::string Operator;
        std::string Value;
    };

    struct Comparison {
        std::string Variable;
        std::string Operator;
        std::string Value;
    };

    struct Route {
        std::optional<std::vector<Comparison>> Comparisons;
        std::optional<std::string> Mode;
        std::optional<std::string> Weight;
        int LinksTo;
    };

    struct Property {
        std::string Name;
        std::string Value;
    };

    struct Node {
        int Id;
        std::string Type;
        std::optional<int> LinksTo;
        std::optional<std::vector<Property>> Properties;
        std::optional<std::string> DialogSource;
        std::optional<std::string> DialogString;
        std::optional<std::vector<Choice>> Choices;
        std::optional<std::string> Name;
        std::optional<std::vector<Assignment>> Assignments;
        std::optional<std::vector<Route>> Routes;
        std::optional<int> DefaultRouteLinksTo;
        std::optional<std::string> Statement;
        std::optional<std::string> DestinationExperience;
        std::optional<std::string> DestinationStartNode;
    };

    struct ExperienceData {
        std::string Name;
        std::vector<Node> NodeList;
    };

    struct ProjectData {
        std::vector<ExperienceData> Experiences;
        std::vector<Variable> Variables;
        std::vector<DataTableItem> DataTable;
    };

    void from_json(const json& j, Variable& v) {
        j.at("name").get_to(v.Name);
        j.at("value").get_to(v.Value);
    }

    void from_json(const json& j, DataTableItem& dti) {
        j.at("name").get_to(dti.Name);
        j.at("value").get_to(dti.Value);
    }

    void from_json(const json& j, Choice& c) {
        j.at("choiceString").get_to(c.ChoiceString);
        j.at("linksTo").get_to(c.LinksTo);
    }

    void from_json(const json& j, Assignment& a) {
        j.at("variable").get_to(a.Variable);
        j.at("operator").get_to(a.Operator);
        j.at("value").get_to(a.Value);
    }

    void from_json(const json& j, Comparison& c) {
        j.at("variable").get_to(c.Variable);
        j.at("operator").get_to(c.Operator);
        j.at("value").get_to(c.Value);
    }

    void from_json(const json& j, Route& r) {
        if (j.contains("comparisons")) j.at("comparisons").get_to(r.Comparisons);
        if (j.contains("mode")) j.at("mode").get_to(r.Mode);
        if (j.contains("weight")) j.at("weight").get_to(r.Weight);
        j.at("linksTo").get_to(r.LinksTo);
    }

    void from_json(const json& j, Property& p) {
        j.at("name").get_to(p.Name);
        j.at("value").get_to(p.Value);
    }

    inline void from_json(const json& j, Node& n) {
        j.at("id").get_to(n.Id);
        j.at("type").get_to(n.Type);
        if (j.contains("linksTo")) j.at("linksTo").get_to(n.LinksTo);
        if (j.contains("properties")) j.at("properties").get_to(n.Properties);
        if (j.contains("dialogSource")) j.at("dialogSource").get_to(n.DialogSource);
        if (j.contains("dialogString")) j.at("dialogString").get_to(n.DialogString);
        if (j.contains("choices")) j.at("choices").get_to(n.Choices);
        if (j.contains("name")) j.at("name").get_to(n.Name);
        if (j.contains("assignments")) j.at("assignments").get_to(n.Assignments);
        if (j.contains("routes")) j.at("routes").get_to(n.Routes);
        if (j.contains("defaultRouteLinksTo")) j.at("defaultRouteLinksTo").get_to(n.DefaultRouteLinksTo);
        if (j.contains("statement")) j.at("statement").get_to(n.Statement);
        if (j.contains("destinationExperience")) j.at("destinationExperience").get_to(n.DestinationExperience);
        if (j.contains("destinationStartNode")) j.at("destinationStartNode").get_to(n.DestinationStartNode);
    }

    void from_json(const json& j, ExperienceData& e) {
        j.at("name").get_to(e.Name);
        j.at("nodeList").get_to(e.NodeList);
    }

    void from_json(const json& j, ProjectData& p) {
        j.at("experiences").get_to(p.Experiences);
        j.at("variables").get_to(p.Variables);
        j.at("dataTable").get_to(p.DataTable);
    }

    class Project {
    private:
        std::vector<ExperienceData> Experiences;
        std::vector<Variable> Variables;
        std::vector<DataTableItem> DataTable;

    public:
        Project(const std::string& compiledProjectFileJSONString) {
            auto deserialized = json::parse(compiledProjectFileJSONString);
            ProjectData data = deserialized.template get<NarrativeFlow::ProjectData>();
            Experiences = data.Experiences;
            Variables = data.Variables;
            DataTable = data.DataTable;
        }

        ExperienceData* GetExperience(const std::string& experienceName) {
            for (auto& experience : Experiences) {
                if (experience.Name == experienceName) {
                    return &experience;
                }
            }
            return nullptr;
        }

        std::optional<std::string> GetVariableValue(const std::string& variableName) {
            for (auto& variable : Variables) {
                if (variable.Name == variableName) {
                    return variable.Value;
                }
            }
            std::cerr << "Error: Variable with the name '" << variableName << "' not found." << std::endl;
            return std::nullopt;
        }

        bool SetVariableValue(const std::string& variableName, const std::string& newValue) {
            for (auto& variable : Variables) {
                if (variable.Name == variableName) {
                    variable.Value = newValue;
                    return true;
                }
            }
            std::cerr << "Error: Variable with the name '" << variableName << "' not found." << std::endl;
            return false;
        }

        std::string GetVariableParsedString(const std::string& str) {
            std::string result = str;
            static const std::regex special_chars(R"([.^$|()\\[*+?{}\]])");
            for (const auto& variable : Variables) {
                std::string escapedName = std::regex_replace(variable.Name, special_chars, R"(\$&)");
                std::regex pattern(escapedName);
                result = std::regex_replace(result, pattern, variable.Value);
            }
            return result;
        }

        std::optional<std::string> GetDataTableItemValue(const std::string& itemName) {
            for (const auto& item : DataTable) {
                if (item.Name == itemName) {
                    return GetVariableParsedString(item.Value);
                }
            }
            std::cerr << "Error: Data Table item with the name '" << itemName << "' not found." << std::endl;
            return std::nullopt;
        }

        void ProcessAssignment(const Assignment& assignment) {
            auto variableOpt = GetVariableValue(assignment.Variable);
            if (!variableOpt.has_value()) return;
            std::string variableValue = variableOpt.value();

            double varNum, valNum;
            bool varIsNum = std::sscanf(variableValue.c_str(), "%lf", &varNum) == 1;
            bool valIsNum = std::sscanf(GetVariableParsedString(assignment.Value).c_str(), "%lf", &valNum) == 1;

            if (!varIsNum || !valIsNum) {
                if (assignment.Operator == "=") {
                    SetVariableValue(assignment.Variable, assignment.Value);
                }
                else if (assignment.Operator == "+") {
                    SetVariableValue(assignment.Variable, variableValue + assignment.Value);
                }
                else {
                    std::cerr << "Error: '" << assignment.Operator << "' can't be used on strings." << std::endl;
                }
            } else {
                double result = 0;
                if (assignment.Operator == "=") {
                    SetVariableValue(assignment.Variable, assignment.Value);
                    return;
                }
                else if (assignment.Operator == "+") result = varNum + valNum;
                else if (assignment.Operator == "-") result = varNum - valNum;
                else if (assignment.Operator == "×") result = varNum * valNum;
                else if (assignment.Operator == "÷") result = varNum / valNum;
                else {
                    std::cerr << "Error: Assignment operator '" << assignment.Operator << "' is invalid." << std::endl;
                    return;
                }
                SetVariableValue(assignment.Variable, std::to_string(result));
            }
        }

        bool DoesComparisonEquateToTrue(const Comparison& comparison) {
            auto varOpt = GetVariableValue(comparison.Variable);
            if (!varOpt.has_value()) return false;

            std::string variableValue = varOpt.value();
            std::string parsedValue = GetVariableParsedString(comparison.Value);

            if (comparison.Operator == "=") return variableValue == parsedValue;
            if (comparison.Operator == "≠") return variableValue != parsedValue;

            double varNum, parsedNum;
            if (std::sscanf(variableValue.c_str(), "%lf", &varNum) != 1 || std::sscanf(parsedValue.c_str(), "%lf", &parsedNum) != 1) {
                std::cerr << "Error: Non-numeric comparison attempted." << std::endl;
                return false;
            }

            if (comparison.Operator == "<") return varNum < parsedNum;
            if (comparison.Operator == "≤") return varNum <= parsedNum;
            if (comparison.Operator == ">") return varNum > parsedNum;
            if (comparison.Operator == "≥") return varNum >= parsedNum;
            if (comparison.Operator == "⊇") return variableValue.find(parsedValue) != std::string::npos;
            if (comparison.Operator == "⊉") return variableValue.find(parsedValue) == std::string::npos;
            if (comparison.Operator == "∈") return parsedValue.find(variableValue) != std::string::npos;
            if (comparison.Operator == "∉") return parsedValue.find(variableValue) == std::string::npos;

            std::cerr << "Error: Comparison operator '" << comparison.Operator << "' is invalid." << std::endl;
            return false;
        }

        std::optional<int> GetProbabilityRouteToTake(const std::vector<Route>& routes) {
            std::vector<std::pair<double, int>> weightedRoutes;
            for (const auto& route : routes) {
                double w;
                std::string parsedWeight = GetVariableParsedString(route.Weight.value());
                if (std::sscanf(parsedWeight.c_str(), "%lf", &w) == 1) {
                    weightedRoutes.emplace_back(w, route.LinksTo);
                }
                else {
                    std::cerr << "Invalid weight: '" << parsedWeight << "' for route linking to " << route.LinksTo << std::endl;
                }
            }

            if (weightedRoutes.empty()) {
                std::cerr << "No valid routes available." << std::endl;
                return std::nullopt;
            }

            double totalWeight = 0;
            for (const auto& [w, _] : weightedRoutes) totalWeight += w;

            std::random_device rd;
            std::mt19937 gen(rd());
            std::uniform_real_distribution<> dis(0.0, totalWeight);
            double rand = dis(gen);

            double cumulative = 0;
            for (const auto& [w, link] : weightedRoutes) {
                cumulative += w;
                if (rand < cumulative) {
                    return link;
                }
            }

            return weightedRoutes.back().second;
        }
    };

    class Experience {
    private:
        Project& project;
        ExperienceData* experienceData;
        Node* currentNode = nullptr;

    public:
        Experience(Project& proj, const std::string& experienceName)
        : project(proj) {
            experienceData = project.GetExperience(experienceName);
        }

        Node* GetNode(std::optional<int> nodeId) {
            if (!nodeId.has_value()) {
                std::cerr << "Error: GetNode() received a null node ID." << std::endl;
                return nullptr;
            }
            for (auto& node : experienceData->NodeList) {
                if (node.Id == nodeId.value()) {
                    if (node.Type == "dialog") {
                        node.DialogSource = project.GetVariableParsedString(node.DialogSource.value());
                        node.DialogString = project.GetVariableParsedString(node.DialogString.value());
                    }
                    else if (node.Type == "choice") {
                        for (auto& choice : node.Choices.value()) {
                            choice.ChoiceString = project.GetVariableParsedString(choice.ChoiceString);
                        }
                    }
                    else if (node.Type == "function") {
                        node.Statement = project.GetVariableParsedString(node.Statement.value());
                    }
                    if (node.Properties) {
                        for (auto& prop : node.Properties.value()) {
                            prop.Value = project.GetVariableParsedString(prop.Value);
                        }
                    }
                    return &node;
                }
            }
            return nullptr;
        }

        Node* GetStartNode(const std::string& startNodeName) {
            for (auto& node : experienceData->NodeList) {
                if (node.Type == "start" && node.Name == startNodeName) {
                    currentNode = &node;
                    return currentNode;
                }
            }
            std::cerr << "Error: No Start Node with the name '" << startNodeName << "' was found." << std::endl;
            return nullptr;
        }

        Node* GetNextNode(std::optional<int> choiceIndex = std::nullopt) {
            Node* nextNode = currentNode;
            if (!nextNode) {
                std::cerr << "Error: No current node." << std::endl;
                return nullptr;
            }

            if (nextNode->Type == "dialog" || nextNode->Type == "start" || nextNode->Type == "function") {
                nextNode = GetNode(nextNode->LinksTo);
            }
            else if (nextNode->Type == "choice") {
                if (!choiceIndex.has_value() || choiceIndex.value() < 0 || choiceIndex.value() >= static_cast<int>(nextNode->Choices.value().size())) {
                    std::cerr << "Invalid choiceIndex: " << (choiceIndex.has_value() ? std::to_string(choiceIndex.value()) : "none")
                              << " for node with " << nextNode->Choices.value().size() << " choices." << std::endl;
                }
                nextNode = GetNode(nextNode->Choices.value()[choiceIndex.value()].LinksTo);
            }
            else if (nextNode->Type == "end" || nextNode->Type == "teleport") {
                std::cerr << "Error: '" << nextNode->Type << "' Nodes don't link to anything." << std::endl;
                return nullptr;
            }
            else {
                std::cerr << "Error: Node type '" << nextNode->Type << "' is invalid." << std::endl;
                return nullptr;
            }

            while (nextNode && nextNode->Type != "dialog" && nextNode->Type != "choice" && nextNode->Type != "start" && nextNode->Type != "end" && nextNode->Type != "function") {
                if (nextNode->Type == "variable") {
                    for (const auto& assignment : nextNode->Assignments.value()) {
                        project.ProcessAssignment(assignment);
                    }
                    nextNode = GetNode(nextNode->LinksTo);
                }
                else if (nextNode->Type == "conditional") {
                    int routeToTake = -1;
                    for (size_t i = 0; i < nextNode->Routes.value().size(); ++i) {
                        bool allTrue = true;
                        bool anyTrue = false;
                        for (const auto& cmp : nextNode->Routes.value()[i].Comparisons.value()) {
                            bool result = project.DoesComparisonEquateToTrue(cmp);
                            allTrue &= result;
                            anyTrue |= result;
                        }
                        const std::string& mode = nextNode->Routes.value()[i].Mode.value();
                        if ((mode == "all" && allTrue) ||
                            (mode == "any" && anyTrue) ||
                            (mode == "none" && !anyTrue)) {
                            routeToTake = static_cast<int>(i);
                            }
                    }
                    nextNode = (routeToTake == -1) ? GetNode(nextNode->DefaultRouteLinksTo) : GetNode(nextNode->Routes.value()[routeToTake].LinksTo);
                }
                else if (nextNode->Type == "probability") {
                    auto chosen = project.GetProbabilityRouteToTake(nextNode->Routes.value());
                    nextNode = GetNode(chosen);
                }
                else if (nextNode->Type == "teleport") {
                    experienceData = project.GetExperience(nextNode->DestinationExperience.value());
                    nextNode = GetStartNode(nextNode->DestinationStartNode.value());
                }
                else {
                    std::cerr << "Error: Node type '" << nextNode->Type << "' is invalid." << std::endl;
                    break;
                }
            }

            currentNode = nextNode;
            if (!nextNode) {
                std::cerr << "The chain contained no valid displayable node or ended improperly." << std::endl;
            }
            return nextNode;
        }
    };

} // namespace NarrativeFlow

