public class Tokenizer {
    let tokenizer: RustTokenizer

    public init(pretrained identifier: String, revision: String = "main", authToken: String? = nil)
        throws
    {
        self.tokenizer = try RustTokenizer.fromPretrained(
            identifier: identifier, revision: revision, authToken: authToken)
    }

    public func encode(_ input: String, addSpecialTokens: Bool = true) throws -> Encoding {
        let encoding = try self.tokenizer.encode(input: input, addSpecialTokens: addSpecialTokens)
        return Encoding(encoding)
    }

}

public struct Encoding {
    let encoding: RustEncoding

    init(_ encoding: RustEncoding) {
        self.encoding = encoding
    }

    public var tokens: [String] {
        self.encoding.getTokens()
    }
}
