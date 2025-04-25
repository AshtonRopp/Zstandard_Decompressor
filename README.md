# Setup
To install/make zstd, generate the test file, and compress the test file, source the below script.

```
source setup.sh
```

# Header Parser
zstd defines a frame (compressed file) as shown below. This table, and other key information, can be found [here](https://github.com/facebook/zstd/blob/dev/doc/zstd_compression_format.md#zstandard-frames).

| `Magic_Number` | `Frame_Header` |`Data_Block`|  More Blocks   |  `Content_Checksum`  |
|:--------------:|:--------------:|:----------:| ---------------|:--------------------:|
|  4 bytes       |  2-14 bytes    |  n bytes   |                |     0-4 bytes        |

To define an RTL structure capable of processing this data, we need to dissect the `Magic_Number` and `Frame_Header` fields. The `Magic_Number` is just a constant added to the beginning of the file which indicates that it is a zstd compressed file. This can be ignored for the implementation. The `Frame_Header` field is the one that must be processed. To view these bytes in the compressed test file, we can run the below command

```
>>> head -c 32 input.zst | hexdump -C
00000000  28 b5 2f fd 84 58 00 00  80 00 8c 07 05 9a 82 a9  |(./..X..........|
00000010  38 26 50 45 93 36 07 e0  e5 ca b6 df ed 2d f9 5f  |8&PE.6.......-._|
00000020
```

These values are in hex, so each set of 2 digits is one byte. The values on the left are the byte offsets (in hex) and the values on the right are ASCII.

## `Frame_Header` Structure
The reader is highly encouraged to read [this](https://github.com/facebook/zstd/blob/dev/doc/zstd_compression_format.md#frame_header) section of the documentation, which provides an in-depth description of the `Frame_Header` structure and each of its components. We can again copy over a table from the documentation as shown below.

| `Frame_Header_Descriptor` | `Window_Descriptor`   | `Dictionary_ID`   | `Frame_Content_Size`   |
| :-----------------------: | :-------------------: | :---------------: | :--------------------: |
| 1 byte                    | 0-1 byte              | 0-4 bytes         | 0-8 bytes              |

## `Frame_Header_Descriptor` Structure
From the above output, we can see that the `Frame_Header_Descriptor` byte = 0x84 = 0b10000100. By analyzing this byte alone, we know exactly how much space to allocate for each component of the header, and thus can implement the header parser.

| Bit Number | Field Name                | Description                                        | input.zst Value     |
| :--------: | :-----------------------: | :-----------------------------------------------:  | :-----------------: |
| 7-6        | `Frame_Content_Size_flag` |  Determines # bytes for `Frame_Content_Size` *     | 10                  |
| 5          | `Single_Segment_flag`     |  Refer to docs - if high, skip `Window_Descriptor` | 0                   |
| 4          | `Unused_bit`              |  Unused, value doesn't matter                      | 0                   |
| 3          | `Reserved_bit`            |  Reserved, value must be 0                         | 0                   |
| 2          | `Content_Checksum_flag`   |  Indicates that a checksum follows end of frame    | 1                   |
| 1-0        | `Dictionary_ID_flag`      |  Indicates presence and size of `Dictionary_ID` *  | 00                  |

\* Refer to zstd compression format page to determine number of bytes allocated based on flag



## Test Vector Setup
To process this input via a System Verilog simulation, it must be converted to a test vector. This can be done via the below command.

```
head -c 32 input.zst | xxd -p -c 2 > input.data
```




We can use xxd to print two bytes (4 hex digits) per line. This can then easily be read into a test bench or instruction memory module. For this part of the project, to confirm functionality we only print the first 32 bytes. This is guaranteed to contain the entire header, but obviously not the rest of the compressed data.

| `Frame_Header_Descriptor` | `Window_Descriptor`   | `Dictionary_ID`         | `Frame_Content_Size`    |
| :-----------------------: | :-------------------: | :---------------------: | :---------------------: |
| 1 byte                    | 1 byte                | 0 bytes (little-endian) | 4 bytes (little-endian) |
| 0x84                      | 0x58                  | 0 bytes                 | 0x80000000              |


Notes:
- Bottom part of output vectors are empty if unused
- If FCS_Field_Size == 2, receiver of data is responsible for adding the [offset](https://github.com/facebook/zstd/blob/dev/doc/zstd_compression_format.md#frame_content_size).