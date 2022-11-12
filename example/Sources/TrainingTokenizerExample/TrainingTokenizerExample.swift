import Tokenizers

@main
public struct TrainingTokenizerExample {
    public static func main() throws {
        let tokenizer = try Tokenizer(model: BPE(unkToken: "[UNK]"))
        let trainer = try BPETrainer(specialTokens: [
            "[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]",
        ])

        tokenizer.preTokenizer = Whitespace()

        // Train the tokenizer.
        let files = ["test", "train", "valid"].map { "../data/wikitext-103-raw/wiki.\($0).raw" }
        try tokenizer.train(files: files, trainer: trainer)

        // Save the tokenizer in one file.
        try tokenizer.save(to: "../data/tokenizer-wiki.json")

        // Reload the tokenizer
        print("Reload the trained tokenizer...")
        let savedTokenizer = try Tokenizer(contentsOfFile: "../data/tokenizer-wiki.json")

        // Using the tokenizer
        let output = try savedTokenizer.encode("Hello, y'all! How are you 😁 ?")

        print(output.tokens)
        // => ["Hello", ",", "y", "\'", "all", "!", "How", "are", "you", "[UNK]", "?"]
    }
}
