module util.base32;

/*********************
 * Encoding routines.
 ********************/

/**
 * Find out the size of the string in base32 given the size
 * of the data to encode.
 */
size_t getBase32Size(size_t length) {
	return ((length * 8  - 1) / 5) + 1;
}

size_t encode(
	alias encodeChar,
	bool discardPartial = false,
)(const(ubyte)[] data, char[] buffer) in {
	assert(buffer.length >= getBase32Size(data.length));
} body {
	size_t i;
	
	void putChar(uint n) {
		buffer[i++] = encodeChar(n & 0x1f);
	}
	
	while(data.length >= 5) {
		scope(success) data = data[5 .. $];
		
		uint b0 = *(cast(uint*) data.ptr);
		uint b1 = *(cast(uint*) (data.ptr + 1));
		
		// Only required on little endian.
		import core.bitop;
		b0 = bswap(b0);
		b1 = bswap(b1);
		
		putChar(b0 >> 27);
		putChar(b0 >> 22);
		putChar(b0 >> 17);
		putChar(b0 >> 12);
		putChar(b1 >> 15);
		putChar(b1 >> 10);
		putChar(b1 >> 5);
		putChar(b1);
	}
	
	// We got a multiple of 5 number of bits to encode, bail early.
	if (data.length == 0) {
		return i;
	}
	
	ubyte[7] suffixBuffer;
	ubyte[] suffix;
	switch(data.length) {
		case 1:
			suffix = suffixBuffer[0 .. 2];
			suffix[1] = cast(ubyte) (data[0] << 2);
			goto Next1;
		
		case 2:
			suffix = suffixBuffer[0 .. 4];
			suffix[3] = cast(ubyte) (data[1] << 4);
			goto Next2;
		
		case 3:
			suffix = suffixBuffer[0 .. 5];
			suffix[4] = cast(ubyte) (data[2] << 1);
			goto Next3;
		
		case 4:
			suffix = suffixBuffer[0 .. 7];
			suffix[6] = cast(ubyte) (data[3] << 3);
			suffix[5] = cast(ubyte) (data[3] >> 2);
			suffix[4] = cast(ubyte) (data[2] << 1 | data[3] >> 7);
			goto Next3;
		
		Next3:
			suffix[3] = cast(ubyte) (data[1] << 4 | data[2] >> 4);
			goto Next2;
		
		Next2:
			suffix[2] = cast(ubyte) (data[1] >> 1);
			suffix[1] = cast(ubyte) (data[0] << 2 | data[1] >> 6);
			goto Next1;
		
		Next1:
			suffix[0] = cast(ubyte) (data[0] >> 3);
			break;
		
		default:
			assert(0);
	}
	
	static if (discardPartial) {
		suffix = suffix[0 .. $ - 1];
	}
	
	/**
	 * We run the actual encoding at the end to make sure
	 * getChar calls are made in order. This allow various
	 * checksum computation to be backed in getChar.
	 */
	foreach(s; suffix) {
		putChar(s);
	}
	
	return i;
}

/**
 * Support for RFC4648 base32
 *
 * https://tools.ietf.org/html/rfc4648#section-6
 */
char getBase32(uint n) in {
	assert(n == (n & 0x1f));
} body {
	// As '2' == 26, this should simplify :)
	auto r = (n < 26)
		? 'A' + n
		: '2' + n - 26;
	
	return cast(char) r;
}

/**
 * Support for RFC4648 base32hex
 *
 * https://tools.ietf.org/html/rfc4648#section-7
 */
char getBase32Hex(uint n) in {
	assert(n == (n & 0x1f));
} body {
	auto r = (n < 10)
		? '0' + n
		: 'A' + n - 10;
	
	return cast(char) r;
}

/**
 * Support for zbase32
 *
 * http://philzimmermann.com/docs/human-oriented-base-32-encoding.txt
 */
char getZBase32(uint n) in {
	assert(n == (n & 0x1f));
} body {
	enum Alphabet = "ybndrfg8ejkmcpqxot1uwisza345h769";
	return Alphabet.ptr[n];
}
