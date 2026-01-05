import Foundation
import CoreGraphics
import Spatial

public protocol GraphicsContext : AnyObject {
    var bounds: CGRect { get }
    func move(to point: CGPoint)
    func addLine(to point: CGPoint)
}

/// A class that adapts the Turtle drawing protocol of Seymour Papert (as
/// elaborated in Gary Flake's "The Computational Beauty of Nature") for
/// drawing into an arbitrary drawing context (e.g., a bitmap context or PDF
/// renderer).
// The "turtle" is initially positioned at the origin of the canvas, facing "up"
// (along +Y).
public class Turtle {
    public enum PenState {
        case up
        case down
    }

    public var context: GraphicsContext
    public var depthScale: CGFloat = 1.0

    private var currentAngle: Angle2D = .zero
    private var currentPosition: CGPoint = .zero
    private var penState: PenState = .down
    private var stateStack: [(CGPoint, Angle2D)] = []
    private var depth: Int = 0

    public init(context: GraphicsContext) {
        self.context = context
    }

    /// Set forward angle immediately. Mostly useful for setting up for a new drawing.
    /// Zero degrees points up (toward 12 o'clock).
    public func setAngle(_ angle: Angle2D) {
        currentAngle = angle
    }

    public func setDepthScale(_ scale: CGFloat) {
        depthScale = scale
    }

    public func goForward(distance: CGFloat) {
        let effectiveDistance = distance * pow(depthScale, CGFloat(depth))

        let deltaX = effectiveDistance * sin(currentAngle.radians)
        let deltaY = effectiveDistance * cos(currentAngle.radians)
        let nextPoint = CGPoint(x: currentPosition.x + deltaX,
                                y: currentPosition.y + deltaY)
        switch penState {
        case .up:
            context.move(to: nextPoint)
        case .down:
            context.addLine(to: nextPoint)
        }
        currentPosition = nextPoint
    }

    public func turn(angle: Angle2D) {
        currentAngle += angle
    }

    public func penUp() {
        penState = .up
    }

    public func penDown() {
        penState = .down
    }

    public func saveState() {
        stateStack.append((currentPosition, currentAngle))
    }

    public func restoreState() {
        //precondition(!stateStack.isEmpty)
        if let last = stateStack.last {
            currentPosition = last.0
            currentAngle = last.1
            stateStack.removeLast()
            context.move(to: currentPosition)
        }
    }

    public func pushDepth() {
        depth += 1
    }

    public func popDepth() {
        depth -= 1
    }

}

public nonisolated class BitmapContextAdapter : FractalGraphics.GraphicsContext {
    public let bounds: CGRect
    public let cgContext: CGContext

    public init(width: Int, height: Int) {
        bounds = CGRect(x: 0, y: 0, width: width, height: height)

        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue
        let bytesPerRow = width * 4
        cgContext = CGContext(data: nil,
                              width: width, height: height,
                              bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                              space: space,
                              bitmapInfo: info)!
        cgContext.setFillColor(CGColor.init(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        cgContext.fill([CGRect(x: 0, y: 0, width: width, height: height)])
    }

    public func move(to point: CGPoint) {
        cgContext.move(to: point)
    }

    public func addLine(to point: CGPoint) {
        cgContext.addLine(to: point)
    }

    public func makeCGImage() -> CGImage {
        cgContext.strokePath()
        return cgContext.makeImage()!
    }
}
