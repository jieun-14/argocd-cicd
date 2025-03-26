#!/bin/bash

# 입력 파일
INPUT_FILE="install.yaml"
OUTPUT_DIR="parsed_manifests"

# 입력 파일 존재 여부 확인
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: $INPUT_FILE not found"
    exit 1
fi

# 출력 디렉토리 생성
mkdir -p "$OUTPUT_DIR"

echo "Parsing $INPUT_FILE..."

# 임시 디렉토리 생성
TEMP_DIR=$(mktemp -d)

# YAML 파일을 준비 (빈 줄 제거 및 --- 정규화)
awk 'NF > 0 {print} /^---/ {if (NR!=1) print "---"}' "$INPUT_FILE" > "$TEMP_DIR/full.yaml"

# 모든 kind 값 추출
kinds=$(grep -i "^kind:" "$INPUT_FILE" | awk '{print tolower($2)}' | sort -u)

# 각 kind에 대해 파싱 및 저장
for kind in $kinds; do
    output_file="$OUTPUT_DIR/$kind.yaml"
    temp_file="$TEMP_DIR/$kind.yaml"
    
    # kind에 해당하는 매니페스트만 추출
    awk -v k="$kind" '
        BEGIN {block=""; print_block=0}
        /^---/ {
            if (print_block && block != "") {
                print block
            }
            block=""
            print_block=0
        }
        {
            block=block $0 "\n"
            if (tolower($1) == "kind:" && tolower($2) == k) {
                print_block=1
            }
        }
        END {
            if (print_block && block != "") {
                print block
            }
        }
    ' "$TEMP_DIR/full.yaml" > "$temp_file"
    
    # 파싱된 결과가 있으면 파일로 저장
    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$output_file"
        count=$(grep -c "^---" "$output_file" || echo 0)
        echo "Parsed $count $kind resources to $output_file"
    else
        rm -f "$temp_file"
    fi
done

# 임시 디렉토리 정리
rm -rf "$TEMP_DIR"

echo "Done. Parsed manifests are in $OUTPUT_DIR/"
