import AppKit

/// A borderless, fully transparent, click-through window that covers one screen.
/// It never takes focus and never intercepts any mouse or keyboard input.
final class OverlayWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        animationBehavior = .none
        displaysWhenScreenProfileChanges = true

        // Above normal app windows, below system alerts; combined with the
        // collection behavior this keeps the overlay visible across Spaces
        // and over fullscreen apps.
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
