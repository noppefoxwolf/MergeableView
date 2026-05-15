import SwiftUI

struct MergeableItem<ID: Hashable & Sendable>: ViewModifier {
    @Environment(\.mergeableNamespace)
    private var namespace

    @Environment(\.mergeDragEnded)
    private var mergeDragEnded

    @Environment(\.mergeAction)
    private var mergeAction

    @Environment(\.mergeCandidateAllows)
    private var mergeCandidateAllows

    @Environment(\.mergeableItemFrameChanged)
    private var mergeableItemFrameChanged

    let id: ID

    init(id: ID) {
        self.id = id
    }

    func body(content: Content) -> some View {
        if let namespace {
            itemContent(content)
                .glassEffectID(id, in: namespace)
                .glassEffectTransition(.matchedGeometry)
        } else {
            itemContent(content)
        }
    }

    private func itemContent(_ content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named(MergeableItemLayout.coordinateSpace))
            } action: { frame in
                mergeableItemFrameChanged?(AnyHashable(id), frame)
            }
            .highPriorityGesture(mergeGesture)
            .onDisappear {
                mergeableItemFrameChanged?(AnyHashable(id), nil)
            }
    }

    private var mergeGesture: some Gesture {
        DragGesture(coordinateSpace: .named(MergeableItemLayout.coordinateSpace))
            .onEnded { value in
                mergeDragEnded?(
                    value.startLocation,
                    value.location,
                    mergeAction,
                    mergeCandidateAllows
                )
            }
    }
}
