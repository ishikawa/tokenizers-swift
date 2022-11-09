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

/// Represents a token that can be be added to a ``Tokenizer``.
/// It can have special options that defines the way it should behave.
public struct AddedToken {
    let token: RustAddedToken

    /// Initialize an AddedToken instance.
    ///
    /// - Parameters:
    ///     - content: The content of the token
    ///
    ///     - single_word:
    ///         Defines whether this token should only match single words. If `true`, this
    ///         token will never match inside of a word. For example the token `ing` would match
    ///         on `tokenizing` if this option is `false`, but not if it is `true`.
    ///         The notion of "`inside of a word`" is defined by the word boundaries pattern in
    ///         regular expressions (ie. the token should start and end with word boundaries).
    ///
    ///     - lstrip:
    ///         Defines whether this token should strip all potential whitespaces on its left side.
    ///         If `True`, this token will greedily match any whitespace on its left. For
    ///         example if we try to match the token `[MASK]` with `lstrip=true`, in the text
    ///         `"I saw a [MASK]"`, we would match on `" [MASK]"`. (Note the space on the left).
    ///
    ///     - rstrip:
    ///         Defines whether this token should strip all potential whitespaces on its right
    ///         side. If `true`, this token will greedily match any whitespace on its right.
    ///         It works just like `lstrip` but on the right.
    ///
    ///     - normalized:
    ///         Defines whether this token should match against the normalized version of the input
    ///         text. For example, with the added token `"yesterday"`, and a normalizer in charge of
    ///         lowercasing the text, the token could be extract from the input `"I saw a lion
    ///         Yesterday"`.
    ///
    init(
        _ content: String,
        singleWord: Bool = false,
        stripHeading lstrip: Bool = false,
        stripTrailing rstrip: Bool = false,
        normalized: Bool = true
    ) {
        self.token = RustAddedToken(
            content: content, singleWord: singleWord, lstrip: lstrip, rstrip: rstrip,
            normalized: normalized, special: false)
    }

    public var content: String {
        self.token.getContent()
    }

    public var stripHeading: Bool {
        self.token.getLstrip()
    }

    public var stripTrailing: Bool {
        self.token.getRstrip()
    }

    public var normalized: Bool {
        self.token.getNormalized()
    }

    public var special: Bool {
        self.token.getSpecial()
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
