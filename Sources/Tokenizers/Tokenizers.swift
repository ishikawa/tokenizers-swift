/// A `Tokenizer` works as a pipeline. It processes some raw text as input
/// and outputs an `Encoding`.
public class Tokenizer {
    let tokenizer: RustTokenizer

    /// Instantiate a new ``Tokenizer`` from an existing file on the
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
    /// ```
    /// encode("A single sequence")`
    /// encode("A sequence", "And its pair")`
    /// encode([ "A", "pre", "tokenized", "sequence" ], is_pretokenized=True)`
    /// encode(
    ///   [ "A", "pre", "tokenized", "sequence" ], [ "And", "its", "pair" ],
    ///   is_pretokenized=True
    /// )
    /// ```
    ///
    /// - Parameters:
    ///
    ///   - sequence: The main input sequence we want to encode. This sequence can be either raw
    ///               text or pre-tokenized, according to the `is_pretokenized` argument:
    ///               If `is_pretokenized=False`: ``TextInputSequence``.
    ///               If ``is_pretokenized=True``: `~tokenizers.PreTokenizedInputSequence`
    ///
    ///   - pair:
    ///         An optional input sequence. The expected format is the same that for `sequence`.
    ///
    ///   - is_pretokenized:
    ///         Whether the input is already pre-tokenized
    ///
    ///   - add_special_tokens:
    ///         Whether to add the special tokens
    ///
    /// - Returns:
    ///     The encoded result
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

//MARK:- Models
public typealias Vocab = [String: UInt32]

public typealias Merges = [(String, String)]

/// A [Byte-Pair Encoding (BPE)](https://aclanthology.org/P16-1162/) model.
public class BPE {
    let model: RustBpe

    /// Read a `vocab.json` and a `merges.txt` files.
    ///
    /// This method provides a way to read and parse the content of these files,
    /// returning the relevant data structures. If you want to instantiate some BPE models
    /// from memory, this method gives you the expected input from the standard files.
    ///
    /// - Parameters:
    ///     - vocabPath:
    ///         The path to a `vocab.json` file
    ///
    ///     - mergesPath:
    ///         The path to a `merges.txt` file
    ///
    /// - Returns:
    ///     A `Tuple` with the vocab and the merges:
    ///     The vocabulary and merges loaded into memory
    public static func read_file(
        vocabFileWithPath vocabPath: String, mergesFileWithPath mergesPath: String
    ) throws -> (Vocab, Merges) {
        let v = try modelsBpeBpeReadFile(vocab: vocabPath, merges: mergesPath)
        let m = v.merges.map { ($0[0], $0[1]) }
        return (v.vocab, m)
    }

    public init(
        vocab: Vocab? = nil,
        merges: Merges? = nil,
        cacheCapacity: UInt64? = nil,
        dropout: Float? = nil,
        unkToken: String? = nil,
        continuingSubwordPrefix: String? = nil,
        endOfWordSuffix: String? = nil,
        fuseUnk: Bool = false
    ) throws {
        let merges = merges?.map { [$0.0, $0.1] }

        self.model = try RustBpe(
            vocab: vocab, merges: merges, vocabFile: nil, mergesFile: nil,
            cacheCapacity: cacheCapacity,
            dropout: dropout, unkToken: unkToken, continuingSubwordPrefix: continuingSubwordPrefix,
            endOfWordSuffix: endOfWordSuffix, fuseUnk: fuseUnk)
    }

    /// Instantiate a BPE model from the given files.
    ///
    /// This method is roughly equivalent to doing:
    ///
    /// ```
    /// let (vocab, merges) = BPE.read_file(vocabFileWithPath: vocab_filename, mergesFileWithPath: merges_filename)
    /// let bpe = BPE(vocab: vocab, merges: merges)
    /// ```
    ///
    /// If you don't need to keep the `vocab, merges` values lying around,
    /// this method is more optimized than manually calling
    /// ``read_file(vocabFileWithPath:mergesFileWithPath:)`` to initialize a ``BPE``.
    ///
    /// - Parameters:
    ///     - vocabFile:
    ///         The path to a `vocab.json` file
    ///
    ///     - mergesFile:
    ///         The path to a `merges.txt` file
    ///
    /// - Returns:
    ///     An instance of BPE loaded from these files
    public init(
        vocabFileWithPath vocabFile: String,
        mergesFileWithPath mergesFile: String,
        cacheCapacity: UInt64? = nil,
        dropout: Float? = nil,
        unkToken: String? = nil,
        continuingSubwordPrefix: String? = nil,
        endOfWordSuffix: String? = nil,
        fuseUnk: Bool = false
    ) throws {
        self.model = try RustBpe(
            vocab: nil, merges: nil, vocabFile: vocabFile, mergesFile: mergesFile,
            cacheCapacity: cacheCapacity,
            dropout: dropout, unkToken: unkToken, continuingSubwordPrefix: continuingSubwordPrefix,
            endOfWordSuffix: endOfWordSuffix, fuseUnk: fuseUnk)
    }

    public var unkToken: String? {
        self.model.getUnkToken()
    }
}
