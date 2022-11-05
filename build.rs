use camino::Utf8Path;
use std::env;
use std::path::Path;

fn main() {
    let out_dir = env::var_os("OUT_DIR").unwrap();

    uniffi_build::generate_scaffolding("./src/lib.udl").unwrap();
    uniffi_bindgen::generate_bindings(
        Utf8Path::new("./src/lib.udl"),
        Some(Utf8Path::new("./uniffi.toml")),
        vec!["swift"],
        Utf8Path::from_path(Path::new(&out_dir)),
        None,
        false,
    )
    .unwrap();
}
