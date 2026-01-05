import Foundation
import CoreGraphics
import Spatial

public struct LSystem {
    /// The base "rule" of the system: the commands to execute at depth 0.
    public var axiom: String = "F"
    /// The production rules of the system: these are applied at each iteration
    /// to replace their respective symbols in order to create fractal patterns.
    public var rules: [String : String] = [:]
    /// The angle with which the first segment in the system will be oriented,
    /// prior to any turning commands.
    public var initialAngle: Angle2D = .zero
    /// The base step length. When the distance of a draw/go command is implicit,
    /// this value determines how far to move. When the distance contains units,
    /// they override this value and specify the distance explicitly. When
    /// the distance is depth-based, this length is multiplied by a factor based
    /// on the depth of the state stack, allowing for scale-invariant figures.
    public var stepLength: CGFloat = 10
    /// The base turn angle. When a turn command is issued, its multiplier is
    /// multiplied by this base value to get the effective turn angle. Positive
    /// effective turn angles turn to the right; negative values to the left.
    public var turnAngle: Angle2D = .degrees(90)
    /// The depth scale factor for "depth-based" drawing, which alters the
    /// effective distance of draw/go commands. This should always be <= 1.0.
    public var depthScale: CGFloat = 1.0
    /// The number of iterations to apply when rendering the system. Large values
    /// can cause explosive growth in evaluated rule complexity, so limit this
    /// to `<=` 6 for complex patterns, or `<` 15 for simpler patterns.
    public var evaluationDepth: Int = 4

    public init() {}
}

extension LSystem: Sendable {}
extension LSystem: Codable {}
extension LSystem: Equatable {}

public extension LSystem {
    func produce(depth: Int) -> String {
        var rule = axiom
        for _ in 0..<depth {
            var next = ""
            var multiplier: Int = 0
            for char in rule {
                if(!char.isASCII) { continue }
                if char.isLetter {
                    if let replacement = rules[String(char)] {
                        next.append("<\(replacement)>")
                    } else if char.uppercased() == "F" {
                        next.append("F")
                    } else if char.uppercased() == "G" {
                        next.append("G")
                    } else {
                        next.append(String(char))
                    }
                } else if char == "+" {
                    if multiplier != 0 {
                        next.append("\(multiplier)")
                    }
                    next.append("+")
                    multiplier = 0
                } else if char == "-" {
                    if multiplier != 0 {
                        next.append("\(multiplier)")
                    }
                    next.append("-")
                    multiplier = 0
                } else if char == "[" || char == "]" || char == "<" || char == ">" || char == "|" {
                    next.append(String(char))
                } else if let digitValue = char.wholeNumberValue {
                    multiplier = multiplier * 10 + digitValue
                }
            }
            rule = next
        }
        return rule
    }
}

fileprivate extension Angle2D {
    static func * (_ angle: Angle2D, _ scalar: Double) -> Angle2D {
        Angle2D(radians: angle.radians * scalar)
    }
}

public extension LSystem {
    func render(in context: GraphicsContext) async {
        let turtle = Turtle(context: context)
        turtle.setAngle(initialAngle)
        turtle.setDepthScale(depthScale)
        context.move(to: .zero)

        // Replace the line below with these line to perform full rule expansion prior to rendering.
        // let rule = produce(depth: evaluationDepth)
        // render(rule: rule, with: turtle, evaluationDepth: 0)

        render(rule: axiom, with: turtle, evaluationDepth: evaluationDepth)
    }

    private func render(rule: String, with turtle: Turtle, evaluationDepth: Int, depth: Int = 0) {
        var multiplier: Int = 0
        for char in rule {
            if(!char.isASCII) { continue }
            if char.isLetter {
                if depth < evaluationDepth, let replacement = rules[String(char)] {
                    turtle.pushDepth()
                    render(rule: replacement, with: turtle, evaluationDepth: evaluationDepth, depth: depth + 1)
                    turtle.popDepth()
                } else if char.uppercased() == "F" {
                    turtle.penDown()
                    turtle.goForward(distance: stepLength)
                } else if char.uppercased() == "G" {
                    turtle.penUp()
                    turtle.goForward(distance: stepLength)
                }/* else */
                // Other letters are valid as rules but have no effect on drawing
            } else if char == "+" {
                let angleMultiplier = multiplier != 0 ? CGFloat(multiplier) : 1.0
                turtle.turn(angle: turnAngle * angleMultiplier)
                multiplier = 0
            } else if char == "-" {
                let angleMultiplier = multiplier != 0 ? -CGFloat(multiplier) : -1.0
                turtle.turn(angle: turnAngle * angleMultiplier)
                multiplier = 0
            } else if char == "[" {
                turtle.saveState()
            } else if char == "]" {
                turtle.restoreState()
            } else if char == "<" {
                turtle.pushDepth()
            } else if char == ">" {
                turtle.popDepth()
            } else if char == "|" {
                turtle.penDown()
                turtle.goForward(distance: stepLength)
            } else if let digitValue = char.wholeNumberValue {
                multiplier = multiplier * 10 + digitValue
            }
        }
    }
}
