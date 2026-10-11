import CoreGraphics
import TextSnapCore

protocol TextRecognizing: Sendable {
    /// Recognized lines in image pixel coordinates, top-left origin.
    func recognizeLines(in image: CGImage) async throws -> [TextLine]
}
