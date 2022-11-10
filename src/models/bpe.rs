use crate::error::{Result, TokenizersError};
use crate::utils::RustMerges;
use crate::RustBpeTrainer;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tk::models::bpe::{BpeTrainer, Vocab, BPE};
use tokenizers as tk;

#[derive(Clone, Serialize, Deserialize)]
pub struct RustBpe {
    model: Arc<tk::models::bpe::BPE>,
}

impl tk::Model for RustBpe {
    type Trainer = RustBpeTrainer;

    fn tokenize(&self, sequence: &str) -> tk::Result<Vec<tk::Token>> {
        self.model.tokenize(sequence)
    }

    fn token_to_id(&self, token: &str) -> Option<u32> {
        self.model.token_to_id(token)
    }

    fn id_to_token(&self, id: u32) -> Option<String> {
        self.model.id_to_token(id)
    }

    fn get_vocab(&self) -> std::collections::HashMap<String, u32> {
        self.model.get_vocab()
    }

    fn get_vocab_size(&self) -> usize {
        self.model.get_vocab_size()
    }

    fn save(
        &self,
        folder: &std::path::Path,
        prefix: Option<&str>,
    ) -> tk::Result<Vec<std::path::PathBuf>> {
        self.model.save(folder, prefix)
    }

    fn get_trainer(&self) -> <Self as tk::Model>::Trainer {
        self.model.get_trainer()
    }
}

impl RustBpe {
    pub fn new(
        vocab: Option<tk::models::bpe::Vocab>,
        merges: Option<RustMerges>,
        vocab_file: Option<String>,
        merges_file: Option<String>,
        // UniFFI doesn't support usize type.
        cache_capacity: Option<u64>,
        dropout: Option<f32>,
        unk_token: Option<String>,
        continuing_subword_prefix: Option<String>,
        end_of_word_suffix: Option<String>,
        fuse_unk: Option<bool>,
    ) -> Result<Self> {
        if !((vocab.is_none() && merges.is_none() && vocab_file.is_none() && merges_file.is_none())
            || (vocab.is_some() && merges.is_some())
            || (vocab_file.is_some() && merges_file.is_some()))
        {
            return Err(TokenizersError::ValueError(
                "`vocab` and `merges` must be both specified".into(),
            ));
        }

        let mut builder = tk::models::bpe::BPE::builder();

        if let (Some(vocab), Some(merges)) = (vocab, merges) {
            builder = builder.vocab_and_merges(vocab, merges);
        }
        if let (Some(vocab_file), Some(merges_file)) = (vocab_file, merges_file) {
            builder = builder.files(vocab_file.into(), merges_file.into());
        }
        if let Some(cache_capacity) = cache_capacity {
            let cache_capacity = usize::try_from(cache_capacity)
                .map_err(|e| TokenizersError::ValueError(format!("cache_capacity: {}", e)))?;
            builder = builder.cache_capacity(cache_capacity);
        }
        if let Some(dropout) = dropout {
            builder = builder.dropout(dropout);
        }
        if let Some(unk_token) = unk_token {
            builder = builder.unk_token(unk_token);
        }
        if let Some(continuing_subword_prefix) = continuing_subword_prefix {
            builder = builder.continuing_subword_prefix(continuing_subword_prefix);
        }
        if let Some(end_of_word_suffix) = end_of_word_suffix {
            builder = builder.end_of_word_suffix(end_of_word_suffix);
        }
        if let Some(fuse_unk) = fuse_unk {
            builder = builder.fuse_unk(fuse_unk);
        }

        let bpe = builder.build()?;

        Ok(Self {
            model: Arc::new(bpe),
        })
    }

    pub fn get_unk_token(&self) -> Option<String> {
        self.model.get_unk_token().clone()
    }
}

// Associated functions
#[derive(Debug)]
pub struct RustBpeReadFileReturn {
    pub vocab: Vocab,
    pub merges: tk::models::bpe::Merges,
}

pub fn bpe_read_file(vocab: &str, merges: &str) -> Result<RustBpeReadFileReturn> {
    let vocab_and_merges = BPE::read_file(vocab, merges).map_err(|e| {
        TokenizersError::Exception(format!("Error while reading vocab & merges files: {}", e))
    })?;

    return Ok(RustBpeReadFileReturn {
        vocab: vocab_and_merges.0,
        merges: vocab_and_merges.1,
    });
}
