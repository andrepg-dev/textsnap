import CoreGraphics
import TextSnapCore
import Vision

struct VisionTextRecognizer: TextRecognizing {
    @concurrent
    func recognizeLines(in image: CGImage) async throws -> [TextLine] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let observations = try await request.perform(on: image)
        let imageSize = CGSize(width: image.width, height: image.height)

        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let frame = observation.boundingBox.toImageCoordinates(imageSize, origin: .upperLeft)
            return TextLine(text: candidate.string, frame: frame)
        }
    }
}
