import SwiftUI

public struct MergableContainer<Content: View>: View {
    
    @State
    private var itemFrames: [AnyHashable: CGRect] = [:]
    @State
    private var dragSelection = MergeDragSelection<AnyHashable>()

    @Namespace
    private var namespace

    let content: () -> Content
    
    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        GlassEffectContainer(content: content)
            .environment(\.mergeableNamespace, namespace)
            .environment(\.mergeDragEnded) { startLocation, currentLocation, action, candidateAllows in
                updateDragSelection(
                    startLocation: startLocation,
                    currentLocation: currentLocation,
                    candidateAllows: candidateAllows
                )
                mergeSelectedItems(perform: action)
            }
            .environment(\.mergeableItemFrameChanged) { id, frame in
                itemFrames[id] = frame
            }
            .coordinateSpace(name: MergeableItemLayout.coordinateSpace)
    }
    
    private func updateDragSelection(
        startLocation: CGPoint,
        currentLocation: CGPoint,
        candidateAllows: EnvironmentValues.MergeCandidateAllows?
    ) {
        dragSelection.startItemID = itemID(at: startLocation)
        dragSelection.currentItemID = nearestItemID(
            from: startLocation,
            toward: currentLocation,
            candidateAllows: candidateAllows
        )
    }

    private func itemID(at location: CGPoint) -> AnyHashable? {
        itemFrames
            .first { itemFrame in itemFrame.value.contains(location) }?
            .key
    }

    private func nearestItemID(
        from startLocation: CGPoint,
        toward currentLocation: CGPoint,
        candidateAllows: EnvironmentValues.MergeCandidateAllows?
    ) -> AnyHashable? {
        guard
            let sourceID = itemID(at: startLocation),
            let sourceFrame = itemFrames[sourceID]
        else {
            return nil
        }

        let direction = CGVector(
            dx: currentLocation.x - startLocation.x,
            dy: currentLocation.y - startLocation.y
        )

        guard direction.length > 0 else {
            return nil
        }

        let sourceCenter = sourceFrame.center
        let dragSegment = (sourceCenter, currentLocation)
        return itemFrames
            .filter { id, frame in
                guard id != sourceID else {
                    return false
                }

                if let candidateAllows, !candidateAllows(sourceID, id) {
                    return false
                }

                guard frame.intersectsLineSegment(from: dragSegment.0, to: dragSegment.1) else {
                    return false
                }

                let candidateDirection = CGVector(
                    dx: frame.center.x - sourceCenter.x,
                    dy: frame.center.y - sourceCenter.y
                )
                return direction.dot(candidateDirection) > 0
            }
            .min { lhs, rhs in
                sourceCenter.distance(to: lhs.value.center) < sourceCenter.distance(to: rhs.value.center)
            }?
            .key
    }

    private func mergeSelectedItems(
        perform action: (@MainActor @Sendable (AnyHashable, AnyHashable) -> Void)?
    ) {
        guard
            let sourceID = dragSelection.startItemID,
            let destinationID = dragSelection.currentItemID
        else {
            return
        }

        action?(sourceID, destinationID)
        dragSelection = MergeDragSelection<AnyHashable>()
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        hypot(x - point.x, y - point.y)
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    func intersectsLineSegment(from start: CGPoint, to end: CGPoint) -> Bool {
        contains(start) || contains(end)
            || edges.contains { edgeStart, edgeEnd in
                lineSegmentsIntersect(start, end, edgeStart, edgeEnd)
            }
    }

    private var edges: [(CGPoint, CGPoint)] {
        [
            (CGPoint(x: minX, y: minY), CGPoint(x: maxX, y: minY)),
            (CGPoint(x: maxX, y: minY), CGPoint(x: maxX, y: maxY)),
            (CGPoint(x: maxX, y: maxY), CGPoint(x: minX, y: maxY)),
            (CGPoint(x: minX, y: maxY), CGPoint(x: minX, y: minY))
        ]
    }
}

private func lineSegmentsIntersect(
    _ firstStart: CGPoint,
    _ firstEnd: CGPoint,
    _ secondStart: CGPoint,
    _ secondEnd: CGPoint
) -> Bool {
    let firstToSecondStart = orientation(firstStart, firstEnd, secondStart)
    let firstToSecondEnd = orientation(firstStart, firstEnd, secondEnd)
    let secondToFirstStart = orientation(secondStart, secondEnd, firstStart)
    let secondToFirstEnd = orientation(secondStart, secondEnd, firstEnd)

    if firstToSecondStart == 0, point(secondStart, isOnSegmentFrom: firstStart, to: firstEnd) {
        return true
    }
    if firstToSecondEnd == 0, point(secondEnd, isOnSegmentFrom: firstStart, to: firstEnd) {
        return true
    }
    if secondToFirstStart == 0, point(firstStart, isOnSegmentFrom: secondStart, to: secondEnd) {
        return true
    }
    if secondToFirstEnd == 0, point(firstEnd, isOnSegmentFrom: secondStart, to: secondEnd) {
        return true
    }

    return firstToSecondStart != firstToSecondEnd && secondToFirstStart != secondToFirstEnd
}

private func orientation(_ first: CGPoint, _ second: CGPoint, _ third: CGPoint) -> CGFloat {
    let value = (second.y - first.y) * (third.x - second.x)
        - (second.x - first.x) * (third.y - second.y)

    if abs(value) < .ulpOfOne {
        return 0
    }

    return value > 0 ? 1 : -1
}

private func point(_ point: CGPoint, isOnSegmentFrom start: CGPoint, to end: CGPoint) -> Bool {
    point.x >= min(start.x, end.x)
        && point.x <= max(start.x, end.x)
        && point.y >= min(start.y, end.y)
        && point.y <= max(start.y, end.y)
}

private extension CGVector {
    var length: CGFloat {
        hypot(dx, dy)
    }

    func dot(_ vector: CGVector) -> CGFloat {
        dx * vector.dx + dy * vector.dy
    }
}
