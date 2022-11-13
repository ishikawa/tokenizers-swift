use crate::error::{Result, TokenizersError};
use crate::utils::{RustMerges, RustVocab};
use crate::RustBpeTrainer;
use serde::{Deserialize, Serialize};
use std::sync::{Arc, RwLock};
use tk::models::bpe::BPE;
use tk::ModelWrapper;
use tokenizers as tk;

#[derive(Clone, Serialize, Deserialize)]
pub struct RustBpe {
    #[serde(flatten)]
    pub(crate) model: Arc<RwLock<ModelWrapper>>,
}

impl RustBpe {
    pub(crate) fn with_subtype<F, R>(&self, callback: F) -> R
    where
        F: FnOnce(&BPE) -> R,
    {
        if let ModelWrapper::BPE(bpe) = self.model.read().as_deref().unwrap() {
            callback(bpe)
        } else {
            panic!()
        }
    }

    pub(crate) fn with_subtype_mut<F, R>(&self, callback: F) -> R
    where
        F: FnOnce(&mut BPE) -> R,
    {
        let mut m = self.model.write().unwrap();

        if let ModelWrapper::BPE(b) = &mut *m {
            callback(b)
        } else {
            panic!()
        }
    }
}

impl tk::Model for RustBpe {
    type Trainer = RustBpeTrainer;

    fn tokenize(&self, sequence: &str) -> tk::Result<Vec<tk::Token>> {
        self.model.read().unwrap().tokenize(sequence)
    }

    fn token_to_id(&self, token: &str) -> Option<u32> {
        self.model.read().unwrap().token_to_id(token)
    }

    fn id_to_token(&self, id: u32) -> Option<String> {
        self.model.read().unwrap().id_to_token(id)
    }

    fn get_vocab(&self) -> std::collections::HashMap<String, u32> {
        self.model.read().unwrap().get_vocab()
    }

    fn get_vocab_size(&self) -> usize {
        self.model.read().unwrap().get_vocab_size()
    }

    fn save(
        &self,
        folder: &std::path::Path,
        prefix: Option<&str>,
    ) -> tk::Result<Vec<std::path::PathBuf>> {
        self.model.read().unwrap().save(folder, prefix)
    }

    fn get_trainer(&self) -> <Self as tk::Model>::Trainer {
        self.model.read().unwrap().get_trainer().into()
    }
}

impl RustBpe {
    pub fn new(
        vocab: Option<RustVocab>,
        merges: Option<RustMerges>,
        vocab_file: Option<String>,
        merges_file: Option<String>,
        cache_capacity: Option<usize>,
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
        let wrapper = ModelWrapper::BPE(bpe);

        Ok(Self {
            model: Arc::new(RwLock::new(wrapper)),
        })
    }

    pub fn get_unk_token(&self) -> Option<String> {
        self.with_subtype(|bpe| bpe.get_unk_token().clone())
    }
}

// Associated functions
#[derive(Debug)]
pub struct RustBpeReadFileReturn {
    pub vocab: RustVocab,
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
