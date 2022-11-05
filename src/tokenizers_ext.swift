extension Tokenizer {
    public static func fromPretrained(
        _ identifier: String, revision: String = "main", authToken: String? = nil
    ) throws -> Tokenizer {
        return try Tokenizer.fromPretrained(
            identifier: identifier, revision: revision, authToken: authToken)
    }

    public func encode(_ input: String, addSpecialTokens: Bool = true) throws -> Encoding {
        return try self.encode(input: input, addSpecialTokens: addSpecialTokens)
    }
}
