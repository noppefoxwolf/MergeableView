import SwiftUI

extension EnvironmentValues {
    @Entry
    var mergeableNamespace: Namespace.ID? = nil

    typealias MergeAction = @MainActor @Sendable (AnyHashable, AnyHashable) -> Void
    typealias MergeCandidateAllows = @MainActor @Sendable (AnyHashable, AnyHashable) -> Bool
    
    @Entry
    var mergeDragEnded: (@MainActor @Sendable (MergeDragContext) -> Void)? = nil

    @Entry
    var mergeAction: MergeAction? = nil

    @Entry
    var mergeCandidateAllows: MergeCandidateAllows? = nil

    @Entry
    var mergeableItemFrameChanged:
        (@MainActor @Sendable (AnyHashable, CGRect?) -> Void)? = nil
}

struct MergeDragContext {
    var startLocation: CGPoint
    var currentLocation: CGPoint
    var action: EnvironmentValues.MergeAction?
    var candidateAllows: EnvironmentValues.MergeCandidateAllows?
}
