import CoreGraphics

/// A run of recognized text and where it sits in the source image.
///
/// `frame` is expressed in image pixels with the origin at the top-left corner,
/// so `minY` grows downwards in reading order.
public struct TextLine: Sendable, Equatable {
    public var text: String
    public var frame: CGRect

    public init(text: String, frame: CGRect) {
        self.text = text
        self.frame = frame
    }
}
