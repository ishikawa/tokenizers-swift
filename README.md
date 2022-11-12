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
