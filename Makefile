.PHONY: all clean build rustlib swiftmodule

SRC_DIR = src

SRC = ${SRC_DIR}/lib.rs ${SRC_DIR}/lib.udl

BUILD_DIR = .build

LIB_NAME = tokenizers

all: build

rustlib: Cargo.toml ${SRC}
	mkdir -p ${BUILD_DIR}
	pkg=$$(cargo metadata --no-deps --format-version 1 | jq -r ".packages[0].name"); \
	cargo build --message-format json | \
	jq -r "if .reason == \"build-script-executed\" and \
		(.package_id | contains(\"$${pkg}\")) then .out_dir else empty end" > ${BUILD_DIR}/out_dir.txt
	cp $$(cat ${BUILD_DIR}/out_dir.txt)/*.{h,swift,modulemap} ${SRC_DIR}/

swiftmodule:
	pkg=$$(cargo metadata --no-deps --format-version 1 | jq -r ".packages[0].name"); \
	swiftc -parse-as-library \
		-emit-module -emit-module-path ${BUILD_DIR} -module-name ${LIB_NAME} -module-link-name ${LIB_NAME} \
		-emit-library -o ${BUILD_DIR}/lib${LIB_NAME}.dylib \
		-L ./target/debug -l$${pkg//-/_} \
  		-I ${BUILD_DIR} \
		-Xcc -fmodule-map-file=${SRC_DIR}/${LIB_NAME}FFI.modulemap \
		${SRC_DIR}/*.swift

build: rustlib swiftmodule

clean:
	cargo clean