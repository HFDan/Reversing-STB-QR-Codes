# Reversing the STB QR codes

I was bored one day, and decided to attempt to see what the QR codes used for public transport subscription validation actually contain. Contributions/ideas are more than welcome!

- The public transport company -> <https://stbsa.ro/>

Until i figure out if the QR code contains sensitive information, i will not be uploading hex dumps.

## Terminology, notation and others

The QR code, in its raw form, is to be treated as a simple array of bytes.
We can later re-interpret it as a struct in memory, but it is ultimately **just** an array of bytes.

@`0x**` -> A location in the QR code's byte array. Equivalent to a subscript operator on the array.
`arr[0x**]`.

All C/C++ code assumes the following is defined:

```c++
#ifdef __cplusplus
#include <cstdint>
#else
#include <stdint.h>
#endif

using byte = uint8_t;
```

All `struct`s are not padded and not memory aligned, unless stated otherwise.
Therefore, assume all structs actually look like this:

```c++
#pragma pack(push, 1)
struct someawesomestruct {
    // Code goes here
};
#pragma pack(pop)
```

## Format

```c++
struct stbQR {
    byte magic_value[6]; // This always seems to start with 0x02, followed by 0x50 or 0x51 or 0x52, followed by 0x01 and then a seemingly completely arbitrary value
    byte alot_of_0x00[16];
    uint64_t some_data;
    byte three_null_bytes[3];
    byte variable_amount_of_data[???]; // From what i've seen, around 25, 26, 27 bytes
    char subscription_type[]; // Is read until footer is encountered? maybe?
    byte variable_length_footer[???]; // Always starts with 0x01
};
```

## Theories

### Theory 1: Chunked format

Considering that the header always starts with `0x02`, the byte @`0x21` is always `0x18`, and the footer always starts with `0x01`, we could assume this is a format where the data is split into chunks. This could also explain all the null bytes, as they could be padding the chunks to a set size.

Therefore, a chunk could look like this:

```c++
struct Chunk {
    ChunkId id;
    byte data[];
    byte padding[];
};
```

where `ChunkId` would be the following:

```c++
enum struct ChunkId: byte {
    ID_HEADER = 0x02,
    ID_FOOTER = 0x01,
    ID_UNKNOWN = 0x18, // This is the value that is always present @0x21
};
```

### Theory 2: The text is padded with completely useless data

Considering the format does not have any clear guidelines (the `subscription_type` string has no null terminator and it's starting address is not constant, the footer has a variable length, meaning there is actual data in there (as opposed to *meta*data)), it could be assumed that the QR code is filled of junk information. Maybe in order to obfuscate a simple UUID, which can later be used to search a given person in the database.
