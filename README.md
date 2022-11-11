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

## Example

```swift
$ swift run --repl -Xlinker="-Ltarget/release"
  > import Tokenizers
  > let tokenizer = Tokenizer(model: BPE(unkToken: "[UNK]"))
  > let trainer = BPETrainer(specialTokens: ["[UNK]", "[CLS]", "[SEP]", "[PAD]", "[MASK]"])
  > tokenizer.preTokenizer = Whitespace()
  > let files = ["test", "train", "valid"].map { "data/wikitext-103-raw/wiki.\($0).raw" }
  > tokenizer.train(files: files, trainer: trainer)
  > tokenizer.save(to: "data/tokenizer-wiki.json")
...
  > let tokenizer = Tokenizer(contentsOfFile: "data/tokenizer-wiki.json")
  > let output = tokenizer.encode("Hello, y'all! How are you 😁 ?")
  > output.tokens
$R1: [String] = 11 values {
  [0] = "Hello"
  [1] = ","
  [2] = "y"
  [3] = "\'"
  [4] = "all"
  [5] = "!"
  [6] = "How"
  [7] = "are"
  [8] = "you"
  [9] = "[UNK]"
  [10] = "?"
}
```