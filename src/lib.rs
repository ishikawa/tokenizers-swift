pub mod error;
pub mod models;
pub mod pre_tokenizers;
pub mod tokenizer;
pub mod trainers;
mod utils;
pub use crate::error::TokenizersError;
pub use crate::models::bpe::{
    bpe_read_file as models_bpe_bpe_read_file, RustBpe, RustBpeReadFileReturn,
};
pub use crate::pre_tokenizers::{RustPreTokenizedString, RustWhitespace};
pub use crate::tokenizer::{RustAddedToken, RustEncoding, RustInputSequence, RustTokenizer};
pub use crate::trainers::RustBpeTrainer;
pub use crate::utils::{RustMerges, RustOffsets, RustUSize, RustVocab};
use uniffi_macros;

uniffi_macros::include_scaffolding!("lib");

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
