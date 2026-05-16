import SwiftUI

extension EnvironmentValues {
    @Entry
    var mergeableNamespace: Namespace.ID? = nil

    typealias MergeAction = @MainActor (MergeableItemID, MergeableItemID) -> Void
    typealias MergeCandidateAllows = @MainActor (MergeableItemID, MergeableItemID) -> Bool
    
    @Entry
    var mergeDragEnded: (@MainActor (MergeDragContext) -> Void)? = nil

    @Entry
    var mergeAction: MergeAction? = nil

    @Entry
    var mergeCandidateAllows: MergeCandidateAllows? = nil

    @Entry
    var mergeableItemFrameUpdated:
        (@MainActor (MergeableItemFrameUpdate) -> Void)? = nil
}

struct MergeDragContext {
    var startLocation: CGPoint
    var currentLocation: CGPoint
    var action: EnvironmentValues.MergeAction?
    var candidateAllows: EnvironmentValues.MergeCandidateAllows?

    var dragVector: CGVector {
        CGVector(
            dx: currentLocation.x - startLocation.x,
            dy: currentLocation.y - startLocation.y
        )
    }

    var isStationary: Bool {
        dragVector.dx == 0 && dragVector.dy == 0
    }
}

enum MergeableItemFrameUpdate {
    case changed(MergeableItemID, CGRect)
    case removed(MergeableItemID)
}
