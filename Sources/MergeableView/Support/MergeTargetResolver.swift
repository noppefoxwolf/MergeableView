import CoreGraphics

struct MergeTargetResolver<ID: Hashable> {
    var itemFrames: [ID: CGRect]

    func itemID(at location: CGPoint) -> ID? {
        itemFrames
            .first { itemFrame in itemFrame.value.contains(location) }?
            .key
    }

    func nearestItemID(
        from startLocation: CGPoint,
        toward currentLocation: CGPoint,
        candidateAllows: (ID, ID) -> Bool = { _, _ in true }
    ) -> ID? {
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
        return itemFrames
            .filter { id, frame in
                guard id != sourceID else {
                    return false
                }

                guard candidateAllows(sourceID, id) else {
                    return false
                }

                guard frame.intersectsLineSegment(from: sourceCenter, to: currentLocation) else {
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
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        hypot(x - point.x, y - point.y)
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    func intersectsLineSegment(from start: CGPoint, to end: CGPoint) -> Bool {
        contains(start) || contains(end)
            || edges.contains { edgeStart, edgeEnd in
                MergeLineSegment.intersects(start, end, edgeStart, edgeEnd)
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

enum MergeLineSegment {
    static func intersects(
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
