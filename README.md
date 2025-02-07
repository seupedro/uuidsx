# UUIDSX - GPU-Accelerated Prefixed UUID Generator

UUIDSX is a specialized UUID (Universally Unique Identifier) generator that allows you to create UUIDs with custom prefixes while maintaining uniqueness. By leveraging Apple's Metal framework for GPU acceleration, it can efficiently generate large quantities of UUIDs that start with your specified hexadecimal prefix.

For example, if you need UUIDs that all start with "abc123", UUIDSX will generate unique identifiers like:
```
abc12301-e589-4c12-8741-9a1b2c3d4e5f
abc12302-7f12-9e34-b567-8901c2d3e4f5
```
This is particularly useful for systems that use UUID prefixes for sharding, routing, or categorization purposes.

## Features

- 🎯 Generate UUIDs with custom hex prefixes (up to 8 characters)
- 🔒 Maintain UUID uniqueness while enforcing prefix requirements
- 🚀 GPU-accelerated generation for high performance
- 📦 Batch generation of multiple UUIDs
- ⚡️ Parallel processing using Metal compute shaders

## Requirements

- macOS operating system
- GPU supporting Metal framework
- Xcode Command Line Tools (for building)

## Installation

1. Clone the repository
2. Build the project using the provided build script:
   ```bash
   ./build.sh
   ```
   This will:
   - Compile the Metal shader to metallib
   - Build the Swift executable

## Usage

Basic command syntax:
```bash
uuidx --quantity <number> --prefix <hex_prefix>
```

Examples:
```bash
# Generate 100 UUIDs with prefix 'fff'
uuidx --quantity 100 --prefix fff

# Generate 1000 UUIDs with prefix 'abc123'
uuidx --quantity 1000 --prefix abc123
```

### Prefix Specification
The prefix is a crucial part of UUIDSX's functionality:

- Length: Up to 8 hexadecimal characters (0-9, a-f, A-F)
- Position: Always applied to the start of the UUID
- Format: Case insensitive (both "abc" and "ABC" work the same)
- Validation: Automatically validates and trims whitespace
- Uniqueness: Remaining bits after the prefix are randomized to ensure uniqueness

For example:
```bash
# 3-character prefix
uuidx --quantity 1 --prefix fff
> fff12345-6789-4abc-8def-0123456789ab

# 6-character prefix
uuidx --quantity 1 --prefix abc123
> abc12345-6789-4abc-8def-0123456789ab

# 8-character prefix (maximum)
uuidx --quantity 1 --prefix deadbeef
> deadbeef-6789-4abc-8def-0123456789ab
```

## How It Works

UUIDSX uses Metal compute shaders to generate UUIDs in parallel on the GPU:

1. The prefix is validated and converted to the proper format
2. A Metal compute pipeline is created with the shader
3. Memory buffers are allocated for the output
4. The GPU generates random values using Wang hash function
5. The prefix is combined with random bits to create valid UUIDs
6. Results are formatted in standard UUID format

### UUID Format
The generated UUIDs follow the standard format:
```
XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```
Where X represents hexadecimal digits (0-9, a-f)

## Performance

The generator processes UUIDs in parallel using GPU compute shaders:
- 256 threads per threadgroup
- Multiple threadgroups for large quantities
- Direct memory access through Metal buffers
- Efficient random number generation using Wang hash

## Technical Details

- Written in Swift and Metal Shading Language
- Uses Metal framework for GPU computation
- Implements Wang hash for random number generation
- Thread-safe parallel processing
- Zero-copy buffer access for optimal performance

## License

This project is open source and available under the MIT License.
