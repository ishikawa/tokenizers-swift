use super::error::Result;
use std::sync::Arc;
use tokenizers as tk;

pub struct RustTokenizer {
    tokenizer: Arc<tk::tokenizer::Tokenizer>,
}

impl RustTokenizer {
    pub fn from_pretrained(
        identifier: &str,
        revision: String,
        auth_token: Option<String>,
    ) -> Result<Self> {
        let params = tk::FromPretrainedParameters {
            revision,
            auth_token,
            user_agent: [("bindings", "Swift"), ("version", crate::VERSION)]
                .iter()
                .map(|(k, v)| (k.to_string(), v.to_string()))
                .collect(),
        };
        let tokenizer = tk::tokenizer::Tokenizer::from_pretrained(identifier, Some(params))?;

        Ok(Self {
            tokenizer: Arc::new(tokenizer),
        })
    }

    pub fn encode(&self, input: &str, add_special_tokens: bool) -> Result<Arc<RustEncoding>> {
        let encoding = self
            .tokenizer
            .encode_char_offsets(input, add_special_tokens)?;

        Ok(Arc::new(RustEncoding::new(Arc::new(encoding))))
    }
}

//MARK: Encoding

pub struct RustEncoding {
    encoding: Arc<tk::tokenizer::Encoding>,
}

impl RustEncoding {
    pub fn new(encoding: Arc<tk::tokenizer::Encoding>) -> Self {
        Self { encoding }
    }

    pub fn get_tokens(&self) -> Vec<String> {
        self.encoding.get_tokens().to_vec()
    }
}
