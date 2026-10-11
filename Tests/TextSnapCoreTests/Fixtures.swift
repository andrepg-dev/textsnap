import CoreGraphics
@testable import TextSnapCore

enum Fixtures {
    /// Builds a line from Vision-style normalized coordinates (origin bottom-left),
    /// converted to top-left pixels like the app does.
    static func visionLine(
        _ text: String,
        x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
        imageSize: CGSize = CGSize(width: 1794, height: 936)
    ) -> TextLine {
        TextLine(
            text: text,
            frame: CGRect(
                x: x * imageSize.width,
                y: (1 - y - h) * imageSize.height,
                width: w * imageSize.width,
                height: h * imageSize.height
            )
        )
    }

    /// Simple top-left pixel layout helper: one body line is 20pt tall.
    static func line(_ text: String, x: CGFloat = 0, row: CGFloat, height: CGFloat = 20, width: CGFloat? = nil) -> TextLine {
        TextLine(
            text: text,
            frame: CGRect(x: x, y: row * 30, width: width ?? CGFloat(text.count) * 10, height: height)
        )
    }

    /// Real Vision output for a slide titled "R/W Capacity Modes - On-Demand".
    static let capacitySlide: [TextLine] = [
        visionLine("R/W Capacity Modes - On-Demand", x: 0.032, y: 0.830, w: 0.824, h: 0.109),
        visionLine("• Read/writes automatically scale up/down with your workloads", x: 0.031, y: 0.702, w: 0.849, h: 0.059),
        visionLine("• No capacity planning needed (WCU / RCU)", x: 0.029, y: 0.615, w: 0.613, h: 0.059),
        visionLine("• Unlimited WCU & RCU, no throttle, more expensive", x: 0.028, y: 0.526, w: 0.721, h: 0.073),
        visionLine("• You're charged for reads/writes that you use in terms of RRU and", x: 0.029, y: 0.448, w: 0.904, h: 0.056),
        visionLine("WRU", x: 0.054, y: 0.393, w: 0.073, h: 0.047),
        visionLine("• Read Request Units (RRU) - throughput for reads (same as RCU)", x: 0.028, y: 0.298, w: 0.939, h: 0.061),
        visionLine("• Write Request Units (WRU) - throughput for writes (same as WCU)", x: 0.028, y: 0.212, w: 0.958, h: 0.059),
        visionLine("• 2.5x more expensive than provisioned capacity (use with care)", x: 0.031, y: 0.128, w: 0.866, h: 0.056),
        visionLine("• Use cases: unknown workloads, unpredictable application traffic, ...", x: 0.029, y: 0.039, w: 0.935, h: 0.061),
    ]
}
