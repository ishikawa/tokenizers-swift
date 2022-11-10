use crate::error::TokenizersError;
use crate::UniffiCustomTypeConverter;
pub use tk::models::bpe::Merges as RustMerges;
pub use tk::Offsets as RustOffsets;
use tokenizers as tk;

impl UniffiCustomTypeConverter for RustMerges {
    type Builtin = Vec<Vec<String>>;

    fn into_custom(v_merges: Self::Builtin) -> uniffi::Result<Self>
    where
        Self: Sized,
    {
        let mut merges: tk::models::bpe::Merges = vec![];

        for (i, m) in v_merges.iter().enumerate() {
            if m.len() != 2 {
                return Err(TokenizersError::ValueError(format!(
                    "The element #{} in `merges` must be a list containing 2 elements but was {}",
                    i,
                    m.len()
                ))
                .into());
            }

            merges.push((m[0].clone(), m[1].clone()));
        }

        Ok(merges)
    }

    fn from_custom(obj: Self) -> Self::Builtin {
        obj.iter().map(|m| vec![m.0.clone(), m.1.clone()]).collect()
    }
}

impl UniffiCustomTypeConverter for tk::Offsets {
    type Builtin = Vec<u64>;

    fn into_custom(value: Self::Builtin) -> uniffi::Result<Self>
    where
        Self: Sized,
    {
        if value.len() != 2 {
            return Err(TokenizersError::ValueError(format!(
                "The length of value must be 2 but was {}",
                value.len()
            ))
            .into());
        }

        let start = usize::try_from(value[0])
            .map_err(|e| TokenizersError::ValueError(format!("start offset: {}", e)))?;
        let end = usize::try_from(value[1])
            .map_err(|e| TokenizersError::ValueError(format!("end offset: {}", e)))?;

        Ok((start, end))
    }

    fn from_custom(obj: Self) -> Self::Builtin {
        vec![obj.0 as u64, obj.1 as u64]
    }
}
