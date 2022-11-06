/// A `Tokenizer` works as a pipeline. It processes some raw text as input
/// and outputs an `Encoding`.
public class Tokenizer {
    let tokenizer: RustTokenizer

    /// Instantiate a new `Tokenizer` from an existing file on the
    /// Hugging Face Hub.
    ///
    /// - Parameters:
    ///     - identifier:
    ///         The identifier of a Model on the Hugging Face Hub, that contains
    ///         a tokenizer.json file
    ///     - revision:
    ///         A branch or commit id
    ///     - auth_token:
    ///         An optional auth token used to access private repositories on the
    ///         Hugging Face Hub
    ///
    /// - Returns: The new tokenizer
    public init(pretrained identifier: String, revision: String = "main", authToken: String? = nil)
        throws
    {
        self.tokenizer = try RustTokenizer.fromPretrained(
            identifier: identifier, revision: revision, authToken: authToken)
    }

    /// Encode the given sequence and pair. This method can process raw text sequences
    /// as well as already pre-tokenized sequences.
    ///
    /// Here are some examples of the inputs that are accepted
    ///
    ///     encode("A single sequence")`
    ///     encode("A sequence", "And its pair")`
    ///     encode([ "A", "pre", "tokenized", "sequence" ], is_pretokenized=True)`
    ///     encode(
    ///       [ "A", "pre", "tokenized", "sequence" ], [ "And", "its", "pair" ],
    ///       is_pretokenized=True
    ///     )
    ///
    /// - Parameters:
    ///
    ///   - sequence: The main input sequence we want to encode. This sequence can be either raw
    ///               text or pre-tokenized, according to the `is_pretokenized` argument:
    ///               If `is_pretokenized=False`: ``TextInputSequence``.
    ///               If ``is_pretokenized=True``: `~tokenizers.PreTokenizedInputSequence`
    ///
    ///   - pair (:obj:`~tokenizers.InputSequence`, `optional`):
    ///         An optional input sequence. The expected format is the same that for ``sequence``.
    ///
    ///   - is_pretokenized (:obj:`bool`, defaults to :obj:`False`):
    ///         Whether the input is already pre-tokenized
    ///
    ///   - add_special_tokens (:obj:`bool`, defaults to :obj:`True`):
    ///         Whether to add the special tokens
    ///
    /// - Returns:
    ///     :class:`~tokenizers.Encoding`: The encoded result
    ///
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