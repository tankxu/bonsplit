import AppKit
import SwiftUI

/// Marks a strip of interactive chrome — a pane's tab bar, a host toolbar — so
/// overlays that sit above it can decline the pointer there.
///
/// Hosts can float AppKit views over panes that take hit testing for their own
/// reasons, such as a resize handle that must own the cursor. Where such an
/// overlay overhangs a tab bar it swallows clicks on the tabs and buttons
/// beneath. Chrome can sit anywhere in a pane tree, so a fixed exclusion inset
/// cannot describe it; the overlay instead asks ``contains(windowPoint:in:)``
/// at hit-test time, which reads each marked view's live frame.
///
/// Apply with `.background(ChromeHitRegion.Marker())`. The marker draws nothing
/// and never takes hits itself.
public enum ChromeHitRegion {
    @MainActor private static let views = NSHashTable<MarkerView>.weakObjects()

    /// Whether a point in `window`'s base coordinates falls on marked chrome.
    @MainActor
    public static func contains(windowPoint: NSPoint, in window: NSWindow) -> Bool {
        views.allObjects.contains { view in
            view.window === window
                && !view.isHiddenOrHasHiddenAncestor
                && view.convert(view.bounds, to: nil).contains(windowPoint)
        }
    }

    public struct Marker: NSViewRepresentable {
        public init() {}

        public func makeNSView(context: Context) -> NSView {
            MarkerView()
        }

        public func updateNSView(_ nsView: NSView, context: Context) {}
    }

    final class MarkerView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window == nil {
                ChromeHitRegion.views.remove(self)
            } else {
                ChromeHitRegion.views.add(self)
            }
        }
    }
}
