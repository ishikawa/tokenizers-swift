import Tokenizers
import XCTest

@testable import Tokenizers

final class TokenizerTests: XCTestCase {
    func testEncodeWithString() throws {
        let filePath = Bundle.module.path(
            forResource: "tokenizer-wiki", ofType: "json", inDirectory: "Files")!
        let tokenizer = try Tokenizer(contentsOfFile: filePath)
        let output = try tokenizer.encode("Hello, y'all! How are you 😁 ?")

        XCTAssertEqual(
            output.tokens,
            [
                "Hello",
                ",",
                "y",
                "\'",
                "all",
                "!",
                "How",
                "are",
                "you",
                "[UNK]",
                "?",
            ])
    }
}
