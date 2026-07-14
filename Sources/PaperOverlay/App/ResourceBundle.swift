import Foundation

extension Bundle {
    /// SwiftPM's generated `Bundle.module` for *executable* targets only
    /// checks next to the executable (app bundle ROOT, not
    /// Contents/Resources) and then a hardcoded absolute path into the dev
    /// machine's .build directory — so it fatalErrors inside a distributed
    /// .app on any other machine. This accessor checks the locations that
    /// actually exist, and falls back to Bundle.main (strings render as
    /// their English keys) rather than crashing.
    static let appModule: Bundle = {
        let name = "PaperOverlay_PaperOverlay.bundle"
        let candidates = [
            Bundle.main.resourceURL, // bundled .app: Contents/Resources
            Bundle.main.bundleURL,   // bare executable (`swift run`): next to the binary
        ]
        for candidate in candidates {
            if let url = candidate?.appendingPathComponent(name),
               let bundle = Bundle(url: url) {
                return bundle
            }
        }
        NSLog("PaperOverlay: WARNING resource bundle not found, using Bundle.main")
        return .main
    }()
}
