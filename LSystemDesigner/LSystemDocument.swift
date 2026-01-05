import SwiftUI
import UniformTypeIdentifiers
import Spatial
import FractalGraphics

nonisolated struct LSystemDocument: FileDocument {
    var system: LSystem = LSystem()

    init() {
        // Sierpinski gasket
        system.initialAngle = .degrees(90)
        system.turnAngle = .degrees(60)
        system.depthScale = 1.0
        system.axiom = "F--F--F"
        system.rules = [ "F" : "F--F--F--GG", "G" : "GG" ]
        system.evaluationDepth = 4

        // Koch island
        //system.initialAngle = .degrees(30)
        //system.turnAngle = .degrees(60)
        //system.depthScale = 1.0
        //system.axiom = "F++F++F"
        //system.rules = [ "F" : "F-F++F-F" ]

        // Bent Big H
        //system.turnAngle = .degrees(80)
        //system.depthScale = 0.65
        //system.axiom = "[F]--F"
        //system.rules = [ "F" : "|[+F][-F]" ]

        // Dragon curve
        //system.initialAngle = .degrees(90)
        //system.turnAngle = .degrees(45)
        //system.depthScale = 1.0
        //system.axiom = "F"
        //system.rules = [ "F" : "[+F][+G--G4-F]", "G" : "-G++G-" ]
        //system.evaluationDepth = 12

        // Sierpinski maze
        //system.initialAngle = .degrees(30)
        //system.turnAngle = .degrees(60)
        //system.depthScale = 1.0
        //system.axiom = "F"
        //system.rules = [
        //    "F" : "[GF][+G3-F][G+G+F]",
        //    "G" : "GG",
        //]

        // Sierpinski snowflake
        //system.initialAngle = .degrees(18)
        //system.turnAngle = .degrees(18)
        //system.depthScale = 1.0
        //system.axiom = "F4-F4-F4-F4-F"
        //system.rules = [
        //    "F" : "F4-F4-F10-F++F4-F",
        //]

        // Penrose tile
        //system.initialAngle = .degrees(0)
        //system.turnAngle = .degrees(36)
        //system.depthScale = 1.0
        //system.axiom = "[X]++[X]++[X]++[X]++[X]"
        //system.rules = [
        //    "W" : "YF++ZF4-XF[-YF4-WF]++",
        //    "X" : "+YF--ZF[3-WF--XF]+",
        //    "Y" : "-WF++XF[+++YF++ZF]-",
        //    "Z" : "--YF++++WF[+ZF++++XF]--XF",
        //    "F" : ""
        //]

        // Quadric Koch island
        //system.initialAngle = .degrees(0)
        //system.turnAngle = .degrees(90)
        //system.depthScale = 1.0
        //system.axiom = "F-F-F-F"
        //system.rules = [
        //    "F" : "F-F+F+FF-F-F+F",
        //]

        // "Tree-2"
        //system.initialAngle = .degrees(0)
        //system.turnAngle = .degrees(8)
        //system.depthScale = 0.4
        //system.axiom = "F"
        //system.rules = [
        //    "F" : "|[5+F][7-F]-|[4+F][6-F]-|[3+F][5-F]-|F",
        //]
    }

    static let readableContentTypes = [
        UTType(importedAs: "com.metalbyexample.fractal-explorer")
    ]

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        self.system = try decoder.decode(LSystem.self, from: data)
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        let data = try encoder.encode(system)
        return .init(regularFileWithContents: data)
    }
}
