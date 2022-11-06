import Tokenizers

@main
public struct Example {
    public private(set) var text = "Hello, World!"

    public static func main() {
        let tokenizer = try! Tokenizer.fromPretrained("bert-base-cased")
        let encoding = try! tokenizer.encode("Hey there!")
        let tokens = encoding.getTokens()

        print("tokens = \(tokens)")
    }
}
