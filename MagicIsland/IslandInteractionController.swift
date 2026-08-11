import Foundation

enum IslandInteractionState: Equatable {
    case passive
    case peeking
    case expanded
    case interacting
    case dragTarget
    case collapsing
}

enum IslandExpansionAnchor: Equatable {
    case currentActivity(CurrentActivity)
    case idlePlaceholder
}

enum IslandPresentation: Equatable {
    case passive
    case peek
    case dragTarget
    case expanded(anchor: IslandExpansionAnchor)
    case collapsing
}

enum IslandFocusBehavior: Equatable {
    case passive
    case inputAllowed
}

struct IslandTransition: Equatable {
    let presentation: IslandPresentation
    let focusBehavior: IslandFocusBehavior
}

struct IslandInteractionController {
    private(set) var state: IslandInteractionState = .passive
    private var expandedAnchor: IslandExpansionAnchor = .idlePlaceholder

    mutating func hoverEntered() -> IslandTransition {
        guard state == .passive else {
            return transition(for: state)
        }

        state = .peeking
        return transition(for: state)
    }

    mutating func hoverExited() -> IslandTransition {
        guard state == .peeking else {
            return transition(for: state)
        }

        state = .passive
        return transition(for: state)
    }

    mutating func dragEntered() -> IslandTransition {
        guard state == .passive || state == .peeking else {
            return transition(for: state)
        }

        state = .dragTarget
        return transition(for: state)
    }

    mutating func dragExited() -> IslandTransition {
        guard state == .dragTarget else {
            return transition(for: state)
        }

        state = .passive
        return transition(for: state)
    }

    mutating func click(currentActivity: CurrentActivity?) -> IslandTransition {
        expand(around: currentActivity)
    }

    mutating func shortcutPressed(currentActivity: CurrentActivity?) -> IslandTransition {
        expand(around: currentActivity)
    }

    private mutating func expand(around currentActivity: CurrentActivity?) -> IslandTransition {
        expandedAnchor = currentActivity.map(IslandExpansionAnchor.currentActivity) ?? .idlePlaceholder
        state = .expanded
        return transition(for: state)
    }

    mutating func beginInteracting() -> IslandTransition {
        guard state == .expanded || state == .interacting else {
            return transition(for: state)
        }

        state = .interacting
        return transition(for: state)
    }

    mutating func collapse() -> IslandTransition {
        guard state != .passive else {
            return transition(for: state)
        }

        state = .collapsing
        return transition(for: state)
    }

    mutating func finishCollapse() -> IslandTransition {
        guard state == .collapsing else {
            return transition(for: state)
        }

        expandedAnchor = .idlePlaceholder
        state = .passive
        return transition(for: state)
    }

    private func transition(for state: IslandInteractionState) -> IslandTransition {
        switch state {
        case .passive:
            return IslandTransition(presentation: .passive, focusBehavior: .passive)
        case .peeking:
            return IslandTransition(presentation: .peek, focusBehavior: .passive)
        case .dragTarget:
            return IslandTransition(presentation: .dragTarget, focusBehavior: .passive)
        case .expanded:
            return IslandTransition(
                presentation: .expanded(anchor: expandedAnchor),
                focusBehavior: .passive
            )
        case .interacting:
            return IslandTransition(
                presentation: .expanded(anchor: expandedAnchor),
                focusBehavior: .inputAllowed
            )
        case .collapsing:
            return IslandTransition(presentation: .collapsing, focusBehavior: .passive)
        }
    }
}
