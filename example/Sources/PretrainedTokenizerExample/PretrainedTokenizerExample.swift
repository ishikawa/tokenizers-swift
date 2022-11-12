import Tokenizers

@main
public struct PretrainedTokenizerExample {
    public static func main() {
        let tokenizer = try! Tokenizer(pretrained: "bert-base-cased")
        let encoding = try! tokenizer.encode("Hey there!")

        print("tokens = \(encoding.tokens)")
    }
}
