import CoreGraphics

struct MergeTargetResolver<ID: Hashable> {
    var itemFrames: [ID: CGRect]

    func itemID(at location: CGPoint) -> ID? {
        itemFrames
            .first { itemFrame in itemFrame.value.contains(location) }?
            .key
    }

    func nearestTarget(
        from startLocation: CGPoint,
        toward currentLocation: CGPoint,
        candidateAllows: (ID, ID) -> Bool = { _, _ in true }
    ) -> MergeTarget<ID>? {
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

        let sourceCenter = MergeGeometry.center(of: sourceFrame)
        let destination = itemFrames
            .filter { id, frame in
                guard id != sourceID else {
                    return false
                }

                guard candidateAllows(sourceID, id) else {
                    return false
                }

                guard MergeGeometry.rect(frame, intersectsLineSegmentFrom: sourceCenter, to: currentLocation) else {
                    return false
                }

                let destinationCenter = MergeGeometry.center(of: frame)
                let candidateDirection = CGVector(
                    dx: destinationCenter.x - sourceCenter.x,
                    dy: destinationCenter.y - sourceCenter.y
                )
                return direction.dot(candidateDirection) > 0
            }
            .min { lhs, rhs in
                MergeGeometry.distance(from: sourceCenter, to: MergeGeometry.center(of: lhs.value))
                    < MergeGeometry.distance(from: sourceCenter, to: MergeGeometry.center(of: rhs.value))
            }

        guard let destination else {
            return nil
        }

        return MergeTarget(
            sourceID: sourceID,
            destinationID: destination.key,
            sourceFrame: sourceFrame,
            destinationFrame: destination.value
        )
    }
}

struct MergeTarget<ID: Hashable> {
    var sourceID: ID
    var destinationID: ID
    var sourceFrame: CGRect
    var destinationFrame: CGRect
}

enum MergeGeometry {
    static func center(of rect: CGRect) -> CGPoint {
        CGPoint(x: rect.midX, y: rect.midY)
    }

    static func distance(from start: CGPoint, to end: CGPoint) -> CGFloat {
        hypot(start.x - end.x, start.y - end.y)
    }

    static func rect(_ rect: CGRect, intersectsLineSegmentFrom start: CGPoint, to end: CGPoint) -> Bool {
        rect.contains(start) || rect.contains(end)
            || edges(of: rect).contains { edgeStart, edgeEnd in
                lineSegmentsIntersect(start, end, edgeStart, edgeEnd)
            }
    }

    static func lineSegmentsIntersect(
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

    private static func edges(of rect: CGRect) -> [(CGPoint, CGPoint)] {
        [
            (CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY)),
            (CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.maxY)),
            (CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY)),
            (CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.minY))
        ]
    }

    private static func orientation(_ first: CGPoint, _ second: CGPoint, _ third: CGPoint) -> CGFloat {
        let value = (second.y - first.y) * (third.x - second.x)
            - (second.x - first.x) * (third.y - second.y)

        if abs(value) < .ulpOfOne {
            return 0
        }

        return value > 0 ? 1 : -1
    }

    private static func point(_ point: CGPoint, isOnSegmentFrom start: CGPoint, to end: CGPoint) -> Bool {
        point.x >= min(start.x, end.x)
            && point.x <= max(start.x, end.x)
            && point.y >= min(start.y, end.y)
            && point.y <= max(start.y, end.y)
    }
}

private extension CGVector {
    var length: CGFloat {
        hypot(dx, dy)
    }

    func dot(_ vector: CGVector) -> CGFloat {
        dx * vector.dx + dy * vector.dy
    }
}
