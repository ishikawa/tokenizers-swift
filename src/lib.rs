mod error;
mod models;
mod tokenizer;
use crate::error::TokenizersError;
use crate::tokenizer::{RustEncoding, RustTokenizer};
use uniffi_macros;

uniffi_macros::include_scaffolding!("lib");

pub const VERSION: &str = env!("CARGO_PKG_VERSION");
