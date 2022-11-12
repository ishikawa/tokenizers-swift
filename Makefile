.PHONY: all clean test build release

BUILD_DIR = .build

GENERATED_SRC = Sources/Tokenizers/RustTokenizers.swift \
				Sources/RustTokenizersFFI/include/RustTokenizersFFI.h

CARGO_BUILD_OPTS =

all: build

release: CARGO_BUILD_OPTS = --release
release: build

# 1. Detect package name
# 2. Detect cargo's `OUT_DIR`
# 3. Build
# 4. Copy artifacts into Sources directory
build:
	mkdir -p ${BUILD_DIR}
	cargo metadata --no-deps --format-version 1 | jq -r ".packages[0].name" > ${BUILD_DIR}/pkg_name.txt
	echo "Package name = $$(cat ${BUILD_DIR}/pkg_name.txt)"
	cargo build ${CARGO_BUILD_OPTS} --message-format json | \
	jq -r "if .reason == \"build-script-executed\" and \
		(.package_id | contains(\"$$(cat ${BUILD_DIR}/pkg_name.txt)\")) then .out_dir else empty end" > ${BUILD_DIR}/out_dir.txt
	echo "Output dir = $$(cat ${BUILD_DIR}/out_dir.txt)"
	cp $$(cat ${BUILD_DIR}/out_dir.txt)/*.h ${BUILD_DIR}/
	cp $$(cat ${BUILD_DIR}/out_dir.txt)/*.swift ${BUILD_DIR}/
	cp ${BUILD_DIR}/RustTokenizers.swift Sources/Tokenizers/
	cp ${BUILD_DIR}/RustTokenizersFFI.h Sources/RustTokenizersFFI/include/

test: build
	ls -la ./target/debug
	swift test -Xlinker="-L./target/debug"

clean:
	cargo clean
	rm -rf ${BUILD_DIR} ${GENERATED_SRC}