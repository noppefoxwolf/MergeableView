import SwiftUI

extension EnvironmentValues {
    @Entry
    var mergeableNamespace: Namespace.ID? = nil

    typealias MergeAction = @MainActor @Sendable (AnyHashable, AnyHashable) -> Void
    
    @Entry
    var mergeDragEnded:
        (
            @MainActor @Sendable (
                CGPoint, CGPoint, MergeAction?
            ) -> Void
        )? = nil

    @Entry
    var mergeAction: MergeAction? = nil

    @Entry
    var mergeableItemFrameChanged:
        (@MainActor @Sendable (AnyHashable, CGRect?) -> Void)? = nil
}
