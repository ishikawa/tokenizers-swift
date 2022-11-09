use std::sync::Arc;

use crate::error::{Result, TokenizersError};
use tk::{models::bpe::BpeTrainer, AddedToken};
use tokenizers as tk;

pub struct RustBpeTrainer {
    trainer: Arc<BpeTrainer>,
}

impl RustBpeTrainer {
    pub fn new(
        vocab_size: Option<u64>,
        min_frequency: Option<u32>,
        show_progress: Option<bool>,
        // TODO: Vec<AddedToken | String>
        special_tokens: Option<Vec<String>>,
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
            builder = builder.special_tokens(
                special_tokens
                    .iter()
                    .map(|s| AddedToken::from(s, true))
                    .collect(),
            );
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
}
