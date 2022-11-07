use thiserror::Error;
use tokenizers as tk;

#[derive(Error, Debug)]
pub enum TokenizersError {
    #[error("Tokenizer error: {source}")]
    Tokenizer {
        #[from]
        source: tk::tokenizer::Error,
    },

    // From python bindings
    #[error("Exception: {0}")]
    Exception(String),

    #[error("Value error: {0}")]
    ValueError(String),
}

pub type Result<T> = std::result::Result<T, TokenizersError>;
