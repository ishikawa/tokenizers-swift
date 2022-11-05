use std::sync::Arc;

use tokenizers as tk;
use uniffi_macros;

uniffi_macros::include_scaffolding!("lib");

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

fn add(a: u32, b: u32) -> u32 {
    a + b
}

pub struct Tokenizer {
    tokenizer: Arc<tk::tokenizer::Tokenizer>,
}

impl Tokenizer {
    pub fn from_pretrained(identifier: &str, revision: String, auth_token: Option<String>) -> Self {
        let params = tk::FromPretrainedParameters {
            revision,
            auth_token,
            user_agent: [("bindings", "Swift"), ("version", crate::VERSION)]
                .iter()
                .map(|(k, v)| (k.to_string(), v.to_string()))
                .collect(),
        };
        let tokenizer =
            tk::tokenizer::Tokenizer::from_pretrained(identifier, Some(params)).unwrap();

        Self {
            tokenizer: Arc::new(tokenizer),
        }
    }

    pub fn encode(&self, input: &str, add_special_tokens: bool) -> Arc<Encoding> {
        let encoding = self
            .tokenizer
            .encode_char_offsets(input, add_special_tokens)
            .unwrap();

        Arc::new(Encoding::new(Arc::new(encoding)))
    }
}

pub struct Encoding {
    encoding: Arc<tk::tokenizer::Encoding>,
}

impl Encoding {
    pub fn new(encoding: Arc<tk::tokenizer::Encoding>) -> Self {
        Self { encoding }
    }

    pub fn get_tokens(&self) -> Vec<String> {
        self.encoding.get_tokens().to_vec()
    }
}
