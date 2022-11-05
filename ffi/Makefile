.PHONY: all clean build

SRC_DIR = src

SRC = ${SRC_DIR}/lib.rs ${SRC_DIR}/lib.udl

BUILD_DIR = .build

LIB_NAME = tokenizers

all: build

${BUILD_DIR}/out_dir.txt: Cargo.toml
	mkdir -p ${BUILD_DIR}
	pkg=$$(cargo metadata --no-deps --format-version 1 | jq -r ".packages[0].name"); \
	cargo check --message-format json | \
	jq -r "if .reason == \"build-script-executed\" and \
		(.package_id | contains(\"$${pkg}\")) then .out_dir else empty end" > $@

rustlib: ${BUILD_DIR}/out_dir.txt ${SRC}
	cargo build
	cp -r $$(cat ${BUILD_DIR}/out_dir.txt)/*.{h,swift,modulemap} ${BUILD_DIR}/

swiftmodule:
	pkg=$$(cargo metadata --no-deps --format-version 1 | jq -r ".packages[0].name"); \
	swiftc -parse-as-library \
		-emit-module -emit-module-path ${BUILD_DIR} -module-name ${LIB_NAME} -module-link-name ${LIB_NAME} \
		-emit-library -o ${BUILD_DIR}/lib${LIB_NAME}.dylib \
		-L ./target/debug -l$${pkg//-/_} \
  		-I ${BUILD_DIR} \
		-Xcc -fmodule-map-file=${BUILD_DIR}/${LIB_NAME}FFI.modulemap \
		${BUILD_DIR}/${LIB_NAME}.swift

build: rustlib swiftmodule

clean:
	cargo clean