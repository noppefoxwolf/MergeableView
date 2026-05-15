import SwiftUI

struct OnMerge<ID: Hashable & Sendable>: ViewModifier {
    private let action: @MainActor (ID, ID) -> Void
    private let candidateAllows: @MainActor (ID, ID) -> Bool

    init(
        action: @escaping @MainActor (ID, ID) -> Void,
        candidateAllows: @escaping @MainActor (ID, ID) -> Bool = { _, _ in true }
    ) {
        self.action = action
        self.candidateAllows = candidateAllows
    }

    func body(content: Content) -> some View {
        content
            .environment(\.mergeAction) { sourceID, destinationID in
                guard
                    let sourceID = sourceID.base as? ID,
                    let destinationID = destinationID.base as? ID
                else {
                    return
                }

                action(sourceID, destinationID)
            }
            .environment(\.mergeCandidateAllows) { sourceID, destinationID in
                guard
                    let sourceID = sourceID.base as? ID,
                    let destinationID = destinationID.base as? ID
                else {
                    return false
                }

                return candidateAllows(sourceID, destinationID)
            }
    }
}
