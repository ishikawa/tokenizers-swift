use std::sync::Arc;

use crate::error::{Result, TokenizersError};
use crate::utils::RustOffsets;
use serde::{Deserialize, Serialize};
use tk::{pre_tokenizers::whitespace::Whitespace, PreTokenizedString, PreTokenizer};
use tokenizers as tk;

/// PreTokenizedString
///
/// Wrapper over a string, that provides a way to normalize, pre-tokenize, tokenize the
/// underlying string, while keeping track of the alignment information (offsets).
///
/// The PreTokenizedString manages what we call `splits`. Each split represents a substring
/// which is a subpart of the original string, with the relevant offsets and tokens.
///
/// When calling one of the methods used to modify the PreTokenizedString (namely one of
/// `split`, `normalize` or `tokenize), only the `splits` that don't have any associated
/// tokens will get modified.
///
/// - Parameters:
///     - sequence:
///         The string sequence used to initialize this PreTokenizedString
pub struct RustPreTokenizedString {
    string: tk::PreTokenizedString,
}

impl From<PreTokenizedString> for RustPreTokenizedString {
    fn from(string: PreTokenizedString) -> Self {
        Self { string }
    }
}

impl From<RustPreTokenizedString> for PreTokenizedString {
    fn from(pre_tok: RustPreTokenizedString) -> Self {
        pre_tok.string
    }
}

impl RustPreTokenizedString {
    pub fn new(s: &str) -> Self {
        PreTokenizedString::from(s).into()
    }
}

/// This pre-tokenizer simply splits using the following regex: `\w+|[^\w\s]+`
#[derive(Clone, Serialize, Deserialize)]
pub struct RustWhitespace {
    #[serde(flatten)]
    pre_tokenizer: Arc<Whitespace>,
}

impl PreTokenizer for RustWhitespace {
    fn pre_tokenize(&self, normalized: &mut PreTokenizedString) -> tk::Result<()> {
        self.pre_tokenizer.pre_tokenize(normalized)
    }
}

impl RustWhitespace {
    pub fn new() -> Self {
        Self {
            pre_tokenizer: Arc::new(Whitespace::default()),
        }
    }

    pub fn pre_tokenize_str(&self, s: &str) -> Result<Vec<(String, RustOffsets)>> {
        let mut pretokenized = tk::tokenizer::PreTokenizedString::from(s);

        self.pre_tokenizer
            .pre_tokenize(&mut pretokenized)
            .map_err(|e| {
                TokenizersError::Exception(format!("Error while pre-tokenizing: {}", e))
            })?;

        Ok(pretokenized
            .get_splits(tk::OffsetReferential::Original, tk::OffsetType::Char)
            .into_iter()
            .map(|(s, o, _)| (s.to_owned(), o))
            .collect())
    }
}
