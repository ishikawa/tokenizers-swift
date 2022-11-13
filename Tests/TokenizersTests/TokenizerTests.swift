import Tokenizers
import XCTest

@testable import Tokenizers

final class TokenizerTests: XCTestCase {
    func testModelProperty() throws {
        let model = try BPE(unkToken: "[UNK]")
        let tokenizer = Tokenizer(model: model)

        XCTAssertNotNil(tokenizer.model)
    }

    func testAddSpecialTokens() throws {
        let model = try BPE(unkToken: "[UNK]")
        let tokenizer = Tokenizer(model: model)
        let tokens: [AddedTokenOrString] = ["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"]

        let n = tokenizer.addSpecialTokens(tokens)
        XCTAssertEqual(n, tokens.count)

        let vocab = tokenizer.getVocab(includeAddedTokens: false)
        XCTAssert(vocab.isEmpty)

        let addedVocab = tokenizer.getVocab(includeAddedTokens: true)
        XCTAssertEqual(addedVocab.count, tokens.count)

        for (i, t) in tokens.enumerated() {
            XCTAssertEqual(addedVocab[t.description], UInt32(i))
        }
    }

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

    func testEncodeWithPreTokenized() throws {
        let filePath = Bundle.module.path(
            forResource: "tokenizer-wiki", ofType: "json", inDirectory: "Files")!
        let tokenizer = try Tokenizer(contentsOfFile: filePath)
        let output = try tokenizer.encode(
            .preTokenized([
                "Hello,",
                "y'all!",
                "How",
                "are",
                "you",
                "😁",
                "?",
            ]))

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
