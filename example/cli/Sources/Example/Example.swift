import Tokenizers

@main
public struct Example {
    public private(set) var text = "Hello, World!"

    public static func main() {
        let tokenizer = try! Tokenizer(pretrained: "bert-base-cased")
        let encoding = try! tokenizer.encode("Hey there!")

        print("tokens = \(encoding.tokens)")
    }
}
