import SwiftUI

@main
struct LSystemApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: LSystemDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
