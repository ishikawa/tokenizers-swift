# Tokenizers

**Under heavily development now**: A Swift binding for [HuggingFace Tokenizers library](https://github.com/huggingface/tokenizers).

>Provides an implementation of today's most used tokenizers, with a focus on performance and versatility.

---

## How to run

> We don't publish this package yet. You can try it with `swift repl`.

First, you have to build the FFI library and generate scaffolding Swift files.

```bash
$ make release
```

You can also build `debug` target by running `make build`, but the performance of the library is too slow to train a model.

Then, running `swift repl` with linker option to link with the library.

```bash
$ swift run --repl -Xlinker="-Ltarget/release"
```

## Quick Example

Examples can be found under the [example](example/) directory. You can run each example with `swift run` command:

```
$ make release
$ cd example 
$ swift run -Xlinker -L../target/release PretrainedTokenizerExample
Building for debugging...
[2/2] Compiling PretrainedTokenizerExample Example.swift
Build complete! (0.36s)
tokens = ["[CLS]", "Hey", "there", "!", "[SEP]"]
```

### Loading a pretrained tokenizer from the Hub

```swift
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
```

### Training and serialization

Like [the original quick tour](https://huggingface.co/docs/tokenizers/quicktour), we'll show you how to build a tokenizer from scratch by using `tokenizer-swift`.

In this example, you can train a new tokenizer on [wikitext-103](https://blog.einstein.ai/the-wikitext-long-term-dependency-language-modeling-dataset/) in just a few seconds (*hopefully*). First things first, you will need to download this dataset and unzip it with:

```
mkdir data
cd data
wget https://s3.amazonaws.com/research.metamind.io/wikitext/wikitext-103-raw-v1.zip
unzip wikitext-103-raw-v1.zip
cd ../example
```

Now you can train the tokenizer:

```
$ swift run -Xlinker -L../target/release TrainingTokenizerExample
[00:00:09] Pre-processing files (543 Mo)            ██████████████████████████████████████████████████████████████████████████████████████████████████████████                100%
[00:00:00] Tokenize words                           ██████████████████████████████████████████████████████████████████████████████████████████████████████████ 610142   /   610142
[00:00:03] Count pairs                              ██████████████████████████████████████████████████████████████████████████████████████████████████████████ 610142   /   610142
[00:00:02] Compute merges                           ██████████████████████████████████████████████████████████████████████████████████████████████████████████ 24989    /    24989

Reload the trained tokenizer...
["Hello", ",", "y", "\'", "all", "!", "How", "are", "you", "[UNK]", "?"]
```

The source code is [here](example/Sources/TrainingTokenizerExample/TrainingTokenizerExample.swift).

```swift
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
```

