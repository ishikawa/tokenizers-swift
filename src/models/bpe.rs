use crate::error::{Result, TokenizersError};
use std::sync::Arc;
use tk::models::bpe::{Merges, Vocab, BPE};
use tokenizers as tk;

pub struct RustBPE {
    model: Arc<tk::models::bpe::BPE>,
}

impl RustBPE {
    pub fn new(
        vocab: Option<tk::models::bpe::Vocab>,
        // UniFFI doesn't support tuple type.
        merges: Option<Vec<Vec<String>>>,
        vocab_file: Option<String>,
        merges_file: Option<String>,
        // UniFFI doesn't support u32 type.
        cache_capacity: Option<u32>,
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

        if let (Some(vocab), Some(v_merges)) = (vocab, merges) {
            let mut merges: tk::models::bpe::Merges = vec![];

            for (i, m) in v_merges.iter().enumerate() {
                if m.len() != 2 {
                    return Err(TokenizersError::ValueError(
                        format!("The element #{} in `merges` must be a list containing 2 elements but was {}", i, m.len())
                    ));
                }

                merges.push((m[0].clone(), m[1].clone()));
            }

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

    pub fn read_file(vocab: &str, merges: &str) -> Result<(Vocab, Merges)> {
        let vocab_and_merges = BPE::read_file(vocab, merges).map_err(|e| {
            TokenizersError::Exception(format!("Error while reading vocab & merges files: {}", e))
        })?;
        return Ok(vocab_and_merges);
    }

    pub fn get_unk_token(&self) -> Option<String> {
        self.model.get_unk_token().clone()
    }
}
