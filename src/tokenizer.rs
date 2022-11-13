use super::error::Result;
use crate::utils::RustVocab;
use crate::{RustBpe, RustBpeTrainer, RustWhitespace};
use std::sync::{Arc, RwLock};
use tk::{
    AddedToken, DecoderWrapper, EncodeInput, InputSequence, Model, NormalizerWrapper,
    PostProcessorWrapper, TokenizerImpl,
};
use tokenizers as tk;

type Tokenizer =
    TokenizerImpl<RustBpe, NormalizerWrapper, RustWhitespace, PostProcessorWrapper, DecoderWrapper>;

pub enum RustInputSequence {
    Raw { raw_value: String },
    PreTokenized { tokens: Vec<String> },
}

impl From<RustInputSequence> for InputSequence<'_> {
    fn from(seq: RustInputSequence) -> Self {
        match seq {
            RustInputSequence::Raw { raw_value } => raw_value.into(),
            RustInputSequence::PreTokenized { tokens } => tokens.into(),
        }
    }
}

pub struct RustTokenizer {
    tokenizer: Arc<RwLock<Tokenizer>>,
}

impl RustTokenizer {
    pub fn new(model: Arc<RustBpe>) -> Self {
        let tokenizer = Tokenizer::new(model.as_ref().clone());

        Self {
            tokenizer: Arc::new(RwLock::new(tokenizer)),
        }
    }

    pub fn from_file(path: &str) -> Result<Self> {
        let tokenizer = Tokenizer::from_file(path)?;

        Ok(Self {
            tokenizer: Arc::new(RwLock::new(tokenizer)),
        })
    }

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

        let tokenizer = Tokenizer::from_pretrained(identifier, Some(params))?;

        Ok(Self {
            tokenizer: Arc::new(RwLock::new(tokenizer)),
        })
    }

    pub fn encode(
        &self,
        input: RustInputSequence,
        pair: Option<RustInputSequence>,
        add_special_tokens: bool,
    ) -> Result<Arc<RustEncoding>> {
        let input: InputSequence = match input {
            RustInputSequence::Raw { raw_value } => raw_value.into(),
            RustInputSequence::PreTokenized { tokens } => tokens.into(),
        };

        let input: EncodeInput = if let Some(pair) = pair {
            EncodeInput::Dual(input, pair.into())
        } else {
            EncodeInput::Single(input)
        };

        let encoding = self
            .tokenizer
            .read()
            .unwrap()
            .encode_char_offsets(input, add_special_tokens)?;

        Ok(Arc::new(RustEncoding::new(Arc::new(encoding))))
    }

    pub fn decode(&self, ids: Vec<u32>, skip_special_tokens: bool) -> Result<String> {
        Ok(self
            .tokenizer
            .read()
            .unwrap()
            .decode(ids, skip_special_tokens)?)
    }

    pub fn train(&self, files: Vec<String>, trainer: Option<Arc<RustBpeTrainer>>) -> Result<()> {
        let mut trainer = trainer.map_or_else(
            || self.tokenizer.read().unwrap().get_model().get_trainer(),
            |t| t.as_ref().clone(),
        );

        Ok(self
            .tokenizer
            .write()
            .unwrap()
            .train_from_files(&mut trainer, files)
            .map(|_| {})?)
    }

    pub fn save(&self, path: &str, pretty: bool) -> Result<()> {
        Ok(self.tokenizer.read().unwrap().save(path, pretty)?)
    }

    pub fn get_vocab(&self, with_added_tokens: bool) -> RustVocab {
        self.tokenizer.read().unwrap().get_vocab(with_added_tokens)
    }

    pub fn add_tokens(&self, tokens: Vec<Arc<RustAddedToken>>) -> usize {
        let tokens: Vec<AddedToken> = tokens.iter().map(|t| t.as_ref().into()).collect();
        self.tokenizer.write().unwrap().add_tokens(&tokens)
    }

    pub fn add_special_tokens(&self, tokens: Vec<Arc<RustAddedToken>>) -> usize {
        let tokens: Vec<AddedToken> = tokens.iter().map(|t| t.as_ref().into()).collect();
        self.tokenizer.write().unwrap().add_special_tokens(&tokens)
    }

    pub fn get_model(&self) -> Arc<RustBpe> {
        Arc::new(self.tokenizer.read().unwrap().get_model().clone())
    }

    pub fn set_model(&self, model: Arc<RustBpe>) {
        self.tokenizer
            .write()
            .unwrap()
            .with_model(model.as_ref().clone());
    }

    pub fn get_pre_tokenizer(&self) -> Option<Arc<RustWhitespace>> {
        self.tokenizer
            .read()
            .unwrap()
            .get_pre_tokenizer()
            .map(|pt| Arc::new(pt.clone()))
    }

    pub fn set_pre_tokenizer(&self, pre_tokenizer: Arc<RustWhitespace>) {
        self.tokenizer
            .write()
            .unwrap()
            .with_pre_tokenizer(pre_tokenizer.as_ref().clone());
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

    pub fn get_ids(&self) -> Vec<u32> {
        self.encoding.get_ids().to_vec()
    }

    pub fn get_type_ids(&self) -> Vec<u32> {
        self.encoding.get_type_ids().to_vec()
    }

    pub fn get_attention_mask(&self) -> Vec<u32> {
        self.encoding.get_attention_mask().to_vec()
    }
}

//MARK: Added Tokens
pub struct RustAddedToken {
    token: Arc<RwLock<AddedToken>>,
}

impl From<tk::AddedToken> for RustAddedToken {
    fn from(token: tk::AddedToken) -> Self {
        Self {
            token: Arc::new(RwLock::new(token)),
        }
    }
}

impl From<&RustAddedToken> for tk::AddedToken {
    fn from(token: &RustAddedToken) -> Self {
        token.token.read().unwrap().clone()
    }
}

// Export
impl RustAddedToken {
    pub fn new(
        content: &str,
        single_word: Option<bool>,
        lstrip: Option<bool>,
        rstrip: Option<bool>,
        normalized: Option<bool>,
        special: Option<bool>,
    ) -> Self {
        let mut token = AddedToken::from(content, special.unwrap_or(false));

        if let Some(single_word) = single_word {
            token.single_word = single_word;
        }
        if let Some(lstrip) = lstrip {
            token.lstrip = lstrip;
        }
        if let Some(rstrip) = rstrip {
            token.rstrip = rstrip;
        }
        if let Some(normalized) = normalized {
            token.normalized = normalized;
        }

        Self {
            token: Arc::new(RwLock::new(token)),
        }
    }

    pub fn get_content(&self) -> String {
        self.token.read().unwrap().content.clone()
    }

    pub fn get_lstrip(&self) -> bool {
        self.token.read().unwrap().lstrip
    }

    pub fn get_rstrip(&self) -> bool {
        self.token.read().unwrap().rstrip
    }

    pub fn get_normalized(&self) -> bool {
        self.token.read().unwrap().normalized
    }

    pub fn get_single_word(&self) -> bool {
        self.token.read().unwrap().single_word
    }

    pub fn get_special(&self) -> bool {
        self.token.read().unwrap().special
    }
}
