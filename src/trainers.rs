use std::sync::{Arc, RwLock};

use crate::{
    error::{Result, TokenizersError},
    RustAddedToken, RustBpe,
};
use serde::{Deserialize, Serialize};
use tk::{
    models::{bpe::BpeTrainer, TrainerWrapper},
    ModelWrapper, Trainer,
};
use tokenizers as tk;

#[derive(Clone, Serialize, Deserialize)]
pub struct RustBpeTrainer {
    trainer: Arc<RwLock<BpeTrainer>>,
}

impl From<BpeTrainer> for RustBpeTrainer {
    fn from(trainer: BpeTrainer) -> Self {
        Self {
            trainer: Arc::new(RwLock::new(trainer)),
        }
    }
}

impl From<TrainerWrapper> for RustBpeTrainer {
    fn from(trainer: TrainerWrapper) -> Self {
        if let TrainerWrapper::BpeTrainer(bpe_trainer) = trainer {
            bpe_trainer.into()
        } else {
            panic!("trainer must be BpeTrainer")
        }
    }
}

impl Trainer for RustBpeTrainer {
    type Model = RustBpe;

    fn should_show_progress(&self) -> bool {
        self.trainer.read().unwrap().should_show_progress()
    }

    fn train(&self, model: &mut Self::Model) -> tk::Result<Vec<tk::AddedToken>> {
        model.with_bpe_mut(|bpe| self.trainer.read().unwrap().train(bpe))
    }

    fn feed<I, S, F>(&mut self, iterator: I, process: F) -> tk::Result<()>
    where
        I: Iterator<Item = S> + Send,
        S: AsRef<str> + Send,
        F: Fn(&str) -> tk::Result<Vec<String>> + Sync,
    {
        self.trainer.write().unwrap().feed(iterator, process)
    }
}

impl RustBpeTrainer {
    pub fn new(
        vocab_size: Option<u64>,
        min_frequency: Option<u32>,
        show_progress: Option<bool>,
        special_tokens: Option<Vec<Arc<RustAddedToken>>>,
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
            let special_tokens = special_tokens.iter().map(|t| t.clone_token()).collect();
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
            trainer: Arc::new(RwLock::new(builder.build())),
        })
    }

    pub fn get_special_tokens(&self) -> Vec<Arc<RustAddedToken>> {
        self.trainer
            .read()
            .unwrap()
            .special_tokens
            .iter()
            .map(|t| Arc::new(t.clone().into()))
            .collect()
    }
}
