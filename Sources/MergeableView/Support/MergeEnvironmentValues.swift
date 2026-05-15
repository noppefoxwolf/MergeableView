import SwiftUI

extension EnvironmentValues {
    @Entry
    var mergeableNamespace: Namespace.ID? = nil

    typealias MergeAction = @MainActor @Sendable (AnyHashable, AnyHashable) -> Void
    typealias MergeCandidateAllows = @MainActor @Sendable (AnyHashable, AnyHashable) -> Bool
    
    @Entry
    var mergeDragEnded:
        (
            @MainActor @Sendable (
                CGPoint, CGPoint, MergeAction?, MergeCandidateAllows?
            ) -> Void
        )? = nil

    @Entry
    var mergeAction: MergeAction? = nil

    @Entry
    var mergeCandidateAllows: MergeCandidateAllows? = nil

    @Entry
    var mergeableItemFrameChanged:
        (@MainActor @Sendable (AnyHashable, CGRect?) -> Void)? = nil
}
