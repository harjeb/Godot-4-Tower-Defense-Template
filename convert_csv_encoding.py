import chardet

def convert_encoding(input_file, output_file, target_encoding='utf-8-sig'):
    # Detect encoding
    with open(input_file, 'rb') as f:
        raw_data = f.read()
        encoding_info = chardet.detect(raw_data)
        source_encoding = encoding_info['encoding']
        print(f"Detected encoding: {source_encoding}")
    
    # Read with detected encoding and write with target encoding
    with open(input_file, 'r', encoding=source_encoding) as f:
        content = f.read()
        
    with open(output_file, 'w', encoding=target_encoding) as f:
        f.write(content)
    print(f"File converted to {target_encoding} and saved as {output_file}")

if __name__ == '__main__':
    convert_encoding('allstones.csv', 'allstones_converted.csv')