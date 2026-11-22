import Foundation

struct NeoValuesScore: Equatable {
    let name: String
    let matchPercentage: Int
    let identicalCount: Int
    let broaderCount: Int
    let totalRequired: Int
}

struct NeoValuesMatch {
    /// The ideology whose requirements all match. Among several, the one with the most requirements.
    let exact: NeoValuesIdeology?
    /// Every other ideology with a positive score, best first.
    let closest: [NeoValuesScore]

    /// The runner-up the original results page shows, if it has a positive match.
    var nextClosest: NeoValuesScore? {
        if let first = closest.first, first.matchPercentage > 0 {
            return first
        }
        return nil
    }
}

/// A port of the matching code in NeoValues' results.html. The reference tests compare it with the original.
struct NeoValuesMatcher {
    private let ideologies: [NeoValuesIdeology]
    private let matching: NeoValuesMatching

    init(data: NeoValuesData) {
        self.ideologies = data.ideologies
        self.matching = data.matching
    }

    init(ideologies: [NeoValuesIdeology], matching: NeoValuesMatching) {
        self.ideologies = ideologies
        self.matching = matching
    }

    func match(_ answers: [String: String]) -> NeoValuesMatch {
        // 1. Exact matching. The first ideology with the most requirements wins a tie.
        var exact: NeoValuesIdeology?
        for ideology in ideologies {
            let isFullMatch = ideology.requirements.allSatisfy { requirement in
                guard let user = answers[requirement.category] else { return false }
                return requirement.allowed.contains(user)
            }
            if isFullMatch {
                if let current = exact {
                    if ideology.requirements.count > current.requirements.count {
                        exact = ideology
                    }
                } else {
                    exact = ideology
                }
            }
        }

        // 2. Next closest matches.
        var scored: [(index: Int, score: NeoValuesScore)] = []
        for (index, ideology) in ideologies.enumerated() {
            if let exact, exact.name == ideology.name { continue }
            let result = score(ideology, answers)
            if result.total > 0 {
                scored.append((index, result.entry))
            }
        }
        scored.sort { left, right in
            let a = left.score
            let b = right.score
            if a.matchPercentage != b.matchPercentage { return a.matchPercentage > b.matchPercentage }
            if a.identicalCount != b.identicalCount { return a.identicalCount > b.identicalCount }
            if a.totalRequired != b.totalRequired { return a.totalRequired > b.totalRequired }
            return left.index < right.index
        }
        return NeoValuesMatch(exact: exact, closest: scored.map { $0.score })
    }

    /// `total` is the original's score plus penalty, which must be above zero to be listed.
    private func score(_ ideology: NeoValuesIdeology, _ answers: [String: String]) -> (total: Double, entry: NeoValuesScore) {
        let totalRequired = ideology.requirements.count
        var score = 0.0
        var penalty = 0.0
        var identicalCount = 0
        var broaderCount = 0

        for requirement in ideology.requirements {
            let category = requirement.category
            guard let user = answers[category], !user.isEmpty else { continue }

            if requirement.allowed.contains(user) {
                score += 1.0
                identicalCount += 1
                continue
            }

            guard let userGroup = group(of: user, in: category) else { continue }

            let sharesSubCategory = requirement.allowed.contains { group(of: $0, in: category) == userGroup }
            if sharesSubCategory {
                score += 0.35
                broaderCount += 1
            }

            let allowedGroups = requirement.allowed.compactMap { group(of: $0, in: category) }
            let userIncompatible = matching.incompatible[userGroup] ?? []
            let isAllIncompatible = !allowedGroups.isEmpty && allowedGroups.allSatisfy { requiredGroup in
                let requiredIncompatible = matching.incompatible[requiredGroup] ?? []
                return userIncompatible.contains(requiredGroup) || requiredIncompatible.contains(userGroup)
            }
            if isAllIncompatible {
                penalty = -100
            }
        }

        let percentage: Double = (totalRequired > 0 && penalty == 0)
            ? (score / Double(totalRequired)) * 100
            : -100
        // JavaScript's Math.round: halves round up.
        let rounded = Int((percentage + 0.5).rounded(.down))
        let entry = NeoValuesScore(
            name: ideology.name,
            matchPercentage: rounded,
            identicalCount: identicalCount,
            broaderCount: broaderCount,
            totalRequired: totalRequired
        )
        return (score + penalty, entry)
    }

    /// The first group of the category that lists the value.
    private func group(of value: String, in category: String) -> String? {
        guard let groups = matching.subCategories[category] else { return nil }
        for group in groups where group.values.contains(value) {
            return group.group
        }
        return nil
    }
}

/// The lines saved in a finished result file.
enum NeoValuesSummary {
    static func lines(data: NeoValuesData, answers: [String: String], match: NeoValuesMatch) -> [String] {
        var lines: [String] = []
        for category in data.categories {
            if let value = answers[category] {
                lines.append(data.categoryTitle(category) + ": " + data.valueName(category, value))
            }
        }
        if let exact = match.exact {
            lines.append("Ideology: " + exact.name)
        } else {
            lines.append("Ideology: no exact match")
        }
        if let next = match.nextClosest {
            lines.append("Next closest match: " + next.name + " (" + String(next.identicalCount) + "/" + String(next.totalRequired) + ")")
        }
        return lines
    }
}
