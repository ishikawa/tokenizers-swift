.PHONY: all clean outdir build

BUILD_DIR = .build

LIB_NAME = Tokenizers

GENERATED_SRC = Sources/Tokenizers/${LIB_NAME}.swift Sources/TokenizersFFI/include/${LIB_NAME}FFI.h

all: build

# Detect cargo's `OUT_DIR`
outdir:
	mkdir -p ${BUILD_DIR}
	pkg=$$(cargo metadata --no-deps --format-version 1 | jq -r ".packages[0].name"); \
	cargo check --message-format json | \
	jq -r "if .reason == \"build-script-executed\" and \
		(.package_id | contains(\"$${pkg}\")) then .out_dir else empty end" > ${BUILD_DIR}/out_dir.txt

build: outdir
	cargo build
	cp $$(cat ${BUILD_DIR}/out_dir.txt)/*.{h,swift} ${BUILD_DIR}/
	cp ${BUILD_DIR}/${LIB_NAME}.swift Sources/Tokenizers/
	cp ${BUILD_DIR}/${LIB_NAME}FFI.h Sources/TokenizersFFI/include/

clean:
	cargo clean
	rm -rf ${BUILD_DIR} ${GENERATED_SRC}