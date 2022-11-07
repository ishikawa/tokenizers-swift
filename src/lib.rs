pub mod error;
pub mod models;
pub mod tokenizer;
pub use crate::error::TokenizersError;
pub use crate::models::bpe::RustBPE;
pub use crate::tokenizer::{RustEncoding, RustTokenizer};
use uniffi_macros;

uniffi_macros::include_scaffolding!("lib");

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
