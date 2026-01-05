import SwiftUI
import FractalGraphics
import Spatial

nonisolated class PathContextAdapter : FractalGraphics.GraphicsContext {
    var path = SwiftUI.Path()

    var bounds: CGRect {
        return path.boundingRect
    }

    func move(to point: CGPoint) {
        path.move(to: point)
    }

    func addLine(to point: CGPoint) {
        path.addLine(to: point)
    }
}

struct LSystemSettingsView : View {
    @Binding var system: LSystem

    let ruleNames = [
        "F", "G", "X", "Y", "Z", "W",
        "A", "B", "C", "D", "E", "H",
        "I", "J", "K", "L", "M", "N",
        "O", "P", "Q", "R", "S", "T",
        "U", "V"
    ]

    var turnAngleBinding: Binding<CGFloat> {
        Binding(
            get: { round(system.turnAngle.degrees) },
            set: { system.turnAngle = .degrees(round($0)) }
        )
    }

    var depthScaleBinding: Binding<CGFloat> {
        Binding(
            get: { system.depthScale },
            set: { system.depthScale = round($0 * 100) * 0.01 }
        )
    }

    var evaluationDepthBinding: Binding<CGFloat> {
        Binding(
            get: { CGFloat(system.evaluationDepth) },
            set: { system.evaluationDepth = Int($0) }
        )
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                Text("Axiom")
                    .font(.headline)
                TextField("Axiom", text: $system.axiom)
                    .font(.body.monospaced())
            }
            .padding(.horizontal, 10)
            VStack(alignment: .leading) {
                HStack {
                    Text("Rules")
                        .font(.headline)
                    Spacer()
                    Button {
                        if let newRuleName = ruleNames.first(where: {
                            candidate in !system.rules.keys.contains(candidate)
                        })
                        {
                            system.rules[newRuleName] = ""
                        }
                    } label: {
                        Text("Add")
                    }
                    .disabled(system.rules.count >= 26)
                }
                ScrollView(.vertical) {
                    ForEach(system.rules.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text("\(key) = ")
                                .frame(width: 32.0, alignment: .trailing)
                            TextField(
                                text: Binding<String>(get: {
                                    system.rules[key]!
                                }, set: { newValue in
                                    system.rules[key] = newValue
                                }),
                                label: {
                                    Text("Empty")
                                }
                            )
                            Button {
                                system.rules.removeValue(forKey: key)
                            } label: {
                                Label("Delete Rule", systemImage: "x.circle.fill")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                            .foregroundStyle(.red)
                        }
                        .font(.body.monospaced())
                    }
                }
                .frame(height: CGFloat(max(1, min(system.rules.count, 6))) * 36.0)
            }
            .padding(.horizontal, 10)
            VStack(alignment: .leading) {
                HStack {
                    Text("Angle")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(turnAngleBinding.wrappedValue))°")
                        .font(.body.monospacedDigit())
                        .frame(minWidth: 28.0, alignment: .trailing)
                    Slider(value: turnAngleBinding, in: 0...90)
                }
                HStack {
                    Text("Depth")
                        .font(.headline)
                    Spacer()
                    Text("\(system.evaluationDepth)")
                        .font(.body.monospacedDigit())
                        .frame(minWidth: 28.0, alignment: .trailing)
                    Slider(value: evaluationDepthBinding, in: 0...12)
                }
                HStack {
                    Text("Scale")
                        .font(.headline)
                    Spacer()
                    Text(String(format: "%0.2f", depthScaleBinding.wrappedValue))
                        .font(.body.monospacedDigit())
                        .frame(minWidth: 28.0, alignment: .trailing)
                    Slider(value: depthScaleBinding, in: 0...1)
                }
            }
            .padding(.horizontal, 10)
            Spacer()
        }
        .frame(maxWidth: 440)
    }
}

struct PathCanvasView : View {
    let strokeWidth = 2.0

    @Binding var path: SwiftUI.Path

    var body: some View {
        Canvas { context, size in
            let pathBounds = path.boundingRect.insetBy(dx: -strokeWidth,
                                                       dy: -strokeWidth)

            let xFitScale = size.width / pathBounds.width
            let yFitScale = size.height / pathBounds.height
            let scale = min(xFitScale, yFitScale)

            context.translateBy(x: size.width * 0.5, y: size.height * 0.5)
            context.scaleBy(x: scale, y: -scale)
            context.translateBy(x: -pathBounds.midX, y: -pathBounds.midY)

            context.stroke(path,
                           with: .color(.primary),
                           style: .init(lineWidth: strokeWidth / scale,
                                        lineJoin: .miter,
                                        miterLimit: 0.25))
        }
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding var document: LSystemDocument
    @State var path: SwiftUI.Path

    init(document: Binding<LSystemDocument>) {
        self._document = document
        self.path = .init()
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(spacing: 10) {
                    PathCanvasView(path: $path)
                    LSystemSettingsView(system: $document.system)
                }
            } else {
                HStack() {
                    PathCanvasView(path: $path)
                    LSystemSettingsView(system: $document.system)
                }
            }
        }
        .padding()
        .task(id: document.system) {
            let adapter = PathContextAdapter()
            await document.system.render(in: adapter)
            path = adapter.path
        }
    }
}

#Preview {
    ContentView(document: .constant(LSystemDocument()))
}
