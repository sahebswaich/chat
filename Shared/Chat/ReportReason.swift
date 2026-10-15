import Foundation

/// Why someone reports an answer (`POST /v1/report` `reason`). Reports are reviewed within 24 hours.
nonisolated enum ReportReason: String, CaseIterable, Identifiable, Codable, Sendable {
    case offensive
    case harmful
    case wrong
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .offensive: return "Offensive or abusive"
        case .harmful: return "Harmful or dangerous"
        case .wrong: return "Wrong or misleading"
        case .other: return "Something else"
        }
    }

    /// SF Symbol name.
    var systemImage: String {
        switch self {
        case .offensive: return "hand.raised"
        case .harmful: return "exclamationmark.triangle"
        case .wrong: return "xmark.seal"
        case .other: return "ellipsis.bubble"
        }
    }
}
