use std::sync::Arc;

use crate::{
    error::{Result, TokenizersError},
    RustAddedToken,
};
use tk::{models::bpe::BpeTrainer, AddedToken};
use tokenizers as tk;

pub struct RustBPETrainer {
    trainer: Arc<BpeTrainer>,
}

// UniFFI doesn't support the Union type nor Enum variant with an object,
// so we represent a union type as a struct whose fields are optional.
pub struct RustSpecialToken {
    pub token: Option<Arc<RustAddedToken>>,
    pub string: Option<String>,
}

impl RustBPETrainer {
    pub fn new(
        vocab_size: Option<u64>,
        min_frequency: Option<u32>,
        show_progress: Option<bool>,
        special_tokens: Option<Vec<RustSpecialToken>>,
        limit_alphabet: Option<u64>,
        initial_alphabet: Option<Vec<String>>,
        continuing_subword_prefix: Option<String>,
        end_of_word_suffix: Option<String>,
    ) -> Result<Self> {
        let mut builder = tk::models::bpe::BpeTrainer::builder();

        if let Some(vocab_size) = vocab_size {
            let vocab_size = usize::try_from(vocab_size)
                .map_err(|e| TokenizersError::ValueError(format!("vocab_size: {}", e)))?;
            builder = builder.vocab_size(vocab_size);
        }
        if let Some(min_frequency) = min_frequency {
            builder = builder.min_frequency(min_frequency);
        }
        if let Some(show_progress) = show_progress {
            builder = builder.show_progress(show_progress);
        }
        if let Some(special_tokens) = special_tokens {
            let special_tokens = special_tokens
                .iter()
                .map(|s| match s {
                    RustSpecialToken {
                        token: Some(token), ..
                    } => token.clone_token(),
                    RustSpecialToken {
                        string: Some(content),
                        ..
                    } => AddedToken::from(content, true),
                    _ => panic!("BUG: special_token must have token or string."),
                })
                .collect();

            builder = builder.special_tokens(special_tokens);
        }
        if let Some(limit_alphabet) = limit_alphabet {
            let limit_alphabet = usize::try_from(limit_alphabet)
                .map_err(|e| TokenizersError::ValueError(format!("limit_alphabet: {}", e)))?;
            builder = builder.limit_alphabet(limit_alphabet);
        }
        if let Some(initial_alphabet) = initial_alphabet {
            builder = builder.initial_alphabet(
                initial_alphabet
                    .into_iter()
                    .filter_map(|s| s.chars().next())
                    .collect(),
            );
        }
        if let Some(continuing_subword_prefix) = continuing_subword_prefix {
            builder = builder.continuing_subword_prefix(continuing_subword_prefix);
        }
        if let Some(end_of_word_suffix) = end_of_word_suffix {
            builder = builder.end_of_word_suffix(end_of_word_suffix);
        }

        Ok(Self {
            trainer: Arc::new(builder.build()),
        })
    }

    pub fn get_special_tokens(&self) -> Vec<Arc<RustAddedToken>> {
        self.trainer
            .special_tokens
            .iter()
            .map(|t| Arc::new(t.clone().into()))
            .collect()
    }
}
