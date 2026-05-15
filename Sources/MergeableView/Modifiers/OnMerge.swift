import SwiftUI

struct OnMerge<ID: Hashable & Sendable>: ViewModifier {
    private let action: @MainActor (ID, ID) -> Void

    init(action: @escaping @MainActor (ID, ID) -> Void) {
        self.action = action
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
    }
}
