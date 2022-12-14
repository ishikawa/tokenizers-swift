public typealias Vocab = [String: UInt32]

public typealias Merges = [(String, String)]

/// `InputSequence` represent all the different kinds of sequence that can be used as
/// input of a Tokenizer. Globally, any sequence can be either a string or a list of strings,
/// according to the operating mode of the tokenizer: raw text vs pre-tokenized.
public enum InputSequence: ExpressibleByStringLiteral, CustomStringConvertible {
    public var description: String {
        switch self {
        case .raw(let value):
            return value
        case .preTokenized(let tokens):
            return tokens.description
        }
    }

    case raw(String)
    case preTokenized([String])

    public init(stringLiteral value: String) {
        self = .raw(value)
    }

    func toRustInputSequence() -> RustInputSequence {

        switch self {
        case .raw(let value):
            return RustInputSequence.raw(rawValue: value)
        case .preTokenized(let tokens):
            return RustInputSequence.preTokenized(tokens: tokens)
        }
    }
}

/// A `Tokenizer` works as a pipeline. It processes some raw text as input
/// and outputs an `Encoding`.
public class Tokenizer {
    let tokenizer: RustTokenizer

    public var model: BPE {
        get {
            return BPE(model: self.tokenizer.getModel())
        }
        set(model) {
            self.tokenizer.setModel(model: model.model)
        }
    }

    public var preTokenizer: Whitespace? {
        get {
            guard let unwrapped = self.tokenizer.getPreTokenizer() else { return nil }
            return Whitespace(preTokenizer: unwrapped)
        }
        set(value) {
            if let tok = value {
                self.tokenizer.setPreTokenizer(preTokenizer: tok.preTokenizer)
            } else {
                fatalError("You cannot set preTokenizer to nil")
            }
        }
    }

    public init(model: BPE) {
        self.tokenizer = RustTokenizer(model: model.model)
    }

    /// - Instantiate `Tokenizer` from the file at the given path.
    ///
    /// - Parameters:
    ///     - path:
    ///         A path to a local JSON file representing a previously serialized
    ///         `Tokenizer`
    ///
    /// - Return:
    ///     The new tokenizer
    public init(contentsOfFile path: String) throws {
        self.tokenizer = try RustTokenizer.fromFile(path: path)
    }

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
    /// encode("A single sequence")
    /// encode("A sequence", pair: "And its pair")
    /// encode(.preTokenized([ "A", "pre", "tokenized", "sequence" ]))
    /// encode(
    ///   .preTokenized([ "A", "pre", "tokenized", "sequence" ]),
    ///   pair: .preTokenized([ "And", "its", "pair" ])
    /// )
    /// ```
    ///
    /// - Parameters:
    ///
    ///   - input: The main input sequence we want to encode. This sequence can be either raw
    ///            text or pre-tokenized.
    ///
    ///   - pair:
    ///         An optional input sequence. The expected format is the same that for `sequence`.
    ///
    ///   - addSpecialTokens:
    ///         Whether to add the special tokens
    ///
    /// - Returns:
    ///     The encoded result
    ///
    public func encode(
        _ input: InputSequence, pair: InputSequence? = nil, addSpecialTokens: Bool = true
    ) throws -> Encoding {
        let encoding = try self.tokenizer.encode(
            input: input.toRustInputSequence(),
            pair: pair?.toRustInputSequence(),
            addSpecialTokens: addSpecialTokens)
        return Encoding(encoding)
    }

    /// Decode the given list of ids back to a string
    ///
    /// This is used to decode anything coming back from a Language Model
    ///
    /// - Parameters:
    ///     - ids:
    ///         The list of ids that we want to decode
    ///
    ///     - skipSpecialTokens:
    ///         Whether the special tokens should be removed from the decoded string
    ///
    /// - Returns:
    ///      The decoded string
    public func decode(_ ids: [UInt32], skipSpecialTokens: Bool) throws -> String {
        return try self.tokenizer.decode(ids: ids, skipSpecialTokens: skipSpecialTokens)
    }

    /// Train the Tokenizer using the given files.
    ///
    /// Reads the files line by line, while keeping all the whitespace, even new lines.
    /// If you want to train from data store in-memory, you can check
    /// ``train_from_iterator``
    ///
    /// - Parameters:
    ///     - files:
    ///         A list of path to the files that we should use for training
    ///
    ///     - trainer:
    ///         An optional trainer that should be used to train our Model
    public func train(files: [String], trainer: BPETrainer? = nil) throws {
        try self.tokenizer.train(files: files, trainer: trainer?.trainer)
    }

    /// - Save`Tokenizer` to the file at the given path.
    ///
    /// - Parameters:
    ///     - path:
    ///         A path to a file in which to save the serialized tokenizer.
    ///
    ///     - pretty:
    ///         Whether the JSON file should be pretty formatted.
    public func save(to path: String, pretty: Bool = true) throws {
        try self.tokenizer.save(path: path, pretty: pretty)
    }

    /// Get the underlying vocabulary
    ///
    /// - Parameters:
    ///     - includeAddedTokens:
    ///         Whether to include the added tokens
    ///
    /// - Return:
    ///     The vocabulary
    public func getVocab(includeAddedTokens: Bool) -> Vocab {
        self.tokenizer.getVocab(withAddedTokens: includeAddedTokens)
    }

    /// Add the given tokens to the vocabulary
    ///
    /// The given tokens are added only if they don't already exist in the vocabulary.
    /// Each token then gets a new attributed id.
    ///
    /// - Parameters:
    ///     - tokens:
    ///         The list of tokens we want to add to the vocabulary. Each token can be either a
    ///         string or ``AddedToken`` for more customization.
    ///
    /// - Return:
    ///     The number of tokens that were created in the vocabulary
    public func addTokens(_ tokens: [AddedTokenOrString]) -> Int {
        let tokens = AddedTokenOrString.toRustAddedTokens(tokens, special: false)
        let n = self.tokenizer.addTokens(tokens: tokens)

        return Int(n)
    }

    /// Add the given special tokens to the Tokenizer.
    ///
    /// If these tokens are already part of the vocabulary, it just let the Tokenizer know about
    /// them. If they don't exist, the Tokenizer creates them, giving them a new id.
    ///
    /// These special tokens will never be processed by the model (ie won't be split into
    /// multiple tokens), and they can be removed from the output when decoding.
    ///
    /// - Parameters:
    ///     - tokens:
    ///         The list of special tokens we want to add to the vocabulary. Each token can either
    ///         a string or ``AddedToken`` for more
    ///         customization.
    ///
    /// - Returns:
    ///     The number of tokens that were created in the vocabulary
    public func addSpecialTokens(_ tokens: [AddedTokenOrString]) -> Int {
        let tokens = AddedTokenOrString.toRustAddedTokens(tokens, special: true)
        let n = self.tokenizer.addSpecialTokens(tokens: tokens)

        return Int(n)
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

    public var ids: [UInt32] {
        self.encoding.getIds()
    }

    public var typeIds: [UInt32] {
        self.encoding.getTypeIds()
    }

    public var attentionMask: [UInt32] {
        self.encoding.getAttentionMask()
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
    ///     - cacheCapacity:
    ///         The number of words that the BPE cache can contain. The cache allows
    ///         to speed-up the process by keeping the result of the merge operations
    ///         for a number of words.
    ///
    ///     - dropout:
    ///         A float between 0 and 1 that represents the BPE dropout to use.
    ///
    ///     - unkToken:
    ///         The unknown token to be used by the model.
    ///
    ///     - continuingSubwordPrefix:
    ///         The prefix to attach to subword units that don't represent a beginning of word.
    ///
    ///     - endOfWordSuffix:
    ///         The suffix to attach to subword units that represent an end of word.
    ///
    ///     - fuseUnk:
    ///         Whether to fuse any subsequent unknown tokens into a single one
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

    public convenience init(
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
        let model = try RustBpe(
            vocab: vocab, merges: merges, vocabFile: nil, mergesFile: nil,
            cacheCapacity: cacheCapacity,
            dropout: dropout, unkToken: unkToken, continuingSubwordPrefix: continuingSubwordPrefix,
            endOfWordSuffix: endOfWordSuffix, fuseUnk: fuseUnk)

        self.init(model: model)
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
    ///     - vocabFileWithPath:
    ///         The path to a `vocab.json` file
    ///
    ///     - mergesFileWithPath:
    ///         The path to a `merges.txt` file
    ///
    ///     - cacheCapacity:
    ///         The number of words that the BPE cache can contain. The cache allows
    ///         to speed-up the process by keeping the result of the merge operations
    ///         for a number of words.
    ///
    ///     - dropout:
    ///         A float between 0 and 1 that represents the BPE dropout to use.
    ///
    ///     - unkToken:
    ///         The unknown token to be used by the model.
    ///
    ///     - continuingSubwordPrefix:
    ///         The prefix to attach to subword units that don't represent a beginning of word.
    ///
    ///     - endOfWordSuffix:
    ///         The suffix to attach to subword units that represent an end of word.
    ///
    ///     - fuseUnk:
    ///         Whether to fuse any subsequent unknown tokens into a single one
    ///
    /// - Returns:
    ///     An instance of BPE loaded from these files
    public convenience init(
        vocabFileWithPath vocabFile: String,
        mergesFileWithPath mergesFile: String,
        cacheCapacity: UInt64? = nil,
        dropout: Float? = nil,
        unkToken: String? = nil,
        continuingSubwordPrefix: String? = nil,
        endOfWordSuffix: String? = nil,
        fuseUnk: Bool = false
    ) throws {
        let model = try RustBpe(
            vocab: nil, merges: nil, vocabFile: vocabFile, mergesFile: mergesFile,
            cacheCapacity: cacheCapacity,
            dropout: dropout, unkToken: unkToken, continuingSubwordPrefix: continuingSubwordPrefix,
            endOfWordSuffix: endOfWordSuffix, fuseUnk: fuseUnk)
        self.init(model: model)
    }

    init(model: RustBpe) {
        self.model = model
    }

    public var unkToken: String? {
        self.model.getUnkToken()
    }
}

//MARK:- Trainers
public enum AddedTokenOrString: ExpressibleByStringLiteral, CustomStringConvertible {
    public var description: String {
        switch self {
        case .token(let token):
            return token.content
        case .string(let value):
            return value
        }
    }

    case token(AddedToken)
    case string(String)

    public init(stringLiteral value: String) {
        self = .string(value)
    }

    static func toRustAddedTokens(_ tokens: [Self], special: Bool = false) -> [RustAddedToken] {
        return tokens.map({
            switch $0 {
            case .token(let token):
                return token.token
            case .string(let value):
                return RustAddedToken(
                    content: value,
                    singleWord: nil,
                    lstrip: nil,
                    rstrip: nil,
                    normalized: nil,
                    special: special)
            }
        })
    }
}

/// Trainer capable of training a BPE model
public class BPETrainer {
    let trainer: RustBpeTrainer

    /// Instantiate a trainer.
    ///
    /// - Parameters:
    ///     - vocabSize:
    ///         The size of the final vocabulary, including all tokens and alphabet.
    ///
    ///     - minFrequency:
    ///         The minimum frequency a pair should have in order to be merged.
    ///
    ///     - showProgress:
    ///         Whether to show progress bars while training.
    ///
    ///     - specialTokens:
    ///         A list of special tokens the model should know of.
    ///
    ///     - limitAlphabet:
    ///         The maximum different characters to keep in the alphabet.
    ///
    ///     - initialAlphabet:
    ///         A list of characters to include in the initial alphabet, even
    ///         if not seen in the training dataset.
    ///         If the strings contain more than one character, only the first one
    ///         is kept.
    ///
    ///     - continuingSubwordPrefix:
    ///         A prefix to be used for every subword that is not a beginning-of-word.
    ///
    ///     - endOfWordSuffix:
    ///         A suffix to be used for every subword that is a end-of-word.
    public init(
        vocabSize: UInt64? = nil,
        minFrequency: UInt32? = nil,
        showProgress: Bool? = nil,
        specialTokens: [AddedTokenOrString]? = nil,
        limitAlphabet: UInt64? = nil,
        initialAlphabet: [String]? = nil,
        continuingSubwordPrefix: String? = nil,
        endOfWordSuffix: String? = nil
    ) throws {
        let specialTokens = specialTokens.map({
            AddedTokenOrString.toRustAddedTokens($0, special: true)
        })

        self.trainer = try RustBpeTrainer(
            vocabSize: vocabSize, minFrequency: minFrequency,
            showProgress: showProgress, specialTokens: specialTokens, limitAlphabet: limitAlphabet,
            initialAlphabet: initialAlphabet, continuingSubwordPrefix: continuingSubwordPrefix,
            endOfWordSuffix: endOfWordSuffix)
    }
}

//MARK:- Pre-Tokenizers

/// This pre-tokenizer simply splits using the following regex: `\w+|[^\w\s]+`
public class Whitespace {
    let preTokenizer: RustWhitespace

    public convenience init() {
        self.init(preTokenizer: RustWhitespace())
    }

    init(preTokenizer: RustWhitespace) {
        self.preTokenizer = preTokenizer
    }
}
