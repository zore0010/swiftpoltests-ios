import Foundation

/// One axis of the 12 Axes quiz.
struct AxisSpec {
    /// The key used in the result page's query string.
    let letter: String
    let name: String
    /// The pole the score measures toward (the score itself).
    let left: String
    /// The opposite pole (100 minus the score).
    let right: String
    /// Score bands, from the most extreme left (index 0) to the most extreme right (index 6).
    let bands: [String]
}

/// The twelve axes, in the order the source's results page shows them.
/// Names, poles, and bands come from the results page of the MIT-licensed 12Axes source
/// (politicaltests, folder 12axes, results.html).
enum AxesSpec {
    static let axes: [AxisSpec] = [
        AxisSpec(letter: "a", name: "Structure", left: "Federal", right: "Unitary",
                 bands: ["Confederal", "Federational", "Federal", "Centrist", "Unitary", "Centralized", "Extremely Centralized"]),
        AxisSpec(letter: "b", name: "Representation", left: "Democracy", right: "Authority",
                 bands: ["Liquid Democracy", "Direct Democracy", "Representative Democracy", "Centrist", "Bicameral", "Oligarchy", "Autocracy"]),
        AxisSpec(letter: "e", name: "Power", left: "Security", right: "Freedom",
                 bands: ["Totalitarian", "Authoritarian", "Statist", "Centrist", "Liberal", "Libertarian", "Anarchist"]),
        AxisSpec(letter: "c", name: "Intervention", left: "Internationalism", right: "Nationalism",
                 bands: ["World Government", "Internationalism", "Cooperation", "Non-Interventionist", "Anti-Interventionist", "Nationalist", "Ultranationalist"]),
        AxisSpec(letter: "d", name: "Diplomacy", left: "Militarist", right: "Pacifist",
                 bands: ["Expansionist", "Militarist", "Military-Focused", "Neutral", "Non-Aggressive", "Pacifist", "Anti-War"]),
        AxisSpec(letter: "i", name: "Immigration", left: "Assimilationist", right: "Multiculturalist",
                 bands: ["Ethnonationalist", "Monoculturalist", "Assimilationist", "Centrist", "Polyculturalist", "Multiculturalist", "Racially Colorblind"]),
        AxisSpec(letter: "f", name: "Economy", left: "Equality", right: "Private",
                 bands: ["Communist", "Socialist", "Social Democratic", "Mixed Economic", "Economic Liberal", "Capitalist", "Extreme Capitalist"]),
        AxisSpec(letter: "j", name: "Control", left: "Planned", right: "Markets",
                 bands: ["Planned Economy", "Interventionism", "Regulationism", "Balanced", "Markets", "Free Market", "Laissez-Faire"]),
        AxisSpec(letter: "k", name: "Trade", left: "Protectionism", right: "Globalist",
                 bands: ["Isolationist", "Protectionist", "Limited Trade", "Moderate", "Free Trade", "Globalist", "Global Economy"]),
        AxisSpec(letter: "g", name: "Religion", left: "Secular", right: "Religious",
                 bands: ["Antitheist", "Atheist", "Agnostic", "Moderate", "Spiritual", "Religious", "Ultra-religious"]),
        AxisSpec(letter: "h", name: "Culture", left: "Progress", right: "Tradition",
                 bands: ["Revolutionary", "Culturally Left", "Progressive", "Moderate", "Conservative", "Traditionalist", "Reactionary"]),
        AxisSpec(letter: "l", name: "Technology", left: "Technology", right: "Bioconservative",
                 bands: ["Transhumanist", "Accelerationist", "Technological", "Neutral", "Bioconservative", "Decelerationist", "Primitive"]),
    ]

    /// The same bands as the source: above 90 is band 0, down to band 6 for 0 to 9.9.
    static func band(for score: Double, bands: [String]) -> String {
        if score > 100 { return "" }
        if score > 90 { return bands[0] }
        if score > 75 { return bands[1] }
        if score > 60 { return bands[2] }
        if score >= 40 { return bands[3] }
        if score >= 25 { return bands[4] }
        if score >= 10 { return bands[5] }
        if score >= 0 { return bands[6] }
        return ""
    }
}
