pub mod error;
pub mod models;
pub mod tokenizer;
pub mod trainers;
pub use crate::error::TokenizersError;
pub use crate::models::bpe::{
    bpe_read_file as models_bpe_bpe_read_file, RustBPE, RustBPEReadFileReturn,
};
pub use crate::tokenizer::{RustAddedToken, RustEncoding, RustTokenizer};
pub use tokenizers::models::bpe::Merges as RustMerges;
use uniffi_macros;

uniffi_macros::include_scaffolding!("lib");

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
