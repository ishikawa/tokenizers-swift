use thiserror::Error;
use tokenizers as tk;

#[derive(Error, Debug)]
pub enum TokenizersError {
    #[error("Tokenizer error: {source}")]
    Tokenizer {
        #[from]
        source: tk::tokenizer::Error,
    },
    #[error("Value error: {message}")]
    ValueError { message: String },
}

pub type Result<T> = std::result::Result<T, TokenizersError>;
