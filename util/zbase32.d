module util.zbase32;

char getChar(uint n) {
	enum Alphabet = "ybndrfg8ejkmcpqxot1uwisza345h769";
	return Alphabet[n & 0x1f];
}

size_t encode(const(ubyte)[] data, char[] buffer) in {
	assert(buffer.length >= ((data.length * 8  - 1) / 5) + 1);
} body {
	size_t i;
	while(data.length >= 5) {
		scope(success) data = data[5 .. $];
		
		uint bits = *(cast(uint*) data.ptr);
		
		// Only required on little endian.
		import core.bitop;
		bits = bswap(bits);
		
		buffer[i++] = getChar(bits >> 27);
		buffer[i++] = getChar(bits >> 22);
		buffer[i++] = getChar(bits >> 17);
		buffer[i++] = getChar(bits >> 12);
		buffer[i++] = getChar(bits >> 7);
		buffer[i++] = getChar(bits >> 2);
		buffer[i++] = getChar((bits << 3) | (data[4] >> 5));
		buffer[i++] = getChar(data[4]);
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
			suffix[1] = data[0] << 2;
			goto Next1;
		
		case 2:
			suffix = suffixBuffer[0 .. 4];
			suffix[3] = data[1] << 4;
			goto Next2;
		
		case 3:
			suffix = suffixBuffer[0 .. 5];
			suffix[4] = data[2] << 1;
			goto Next3;
		
		case 4:
			suffix = suffixBuffer[0 .. 7];
			suffix[4] = data[2] << 1 | data[3] >> 7;
			suffix[5] = data[3] >> 2;
			suffix[6] = data[3] << 3;
			goto Next3;
		
		Next3:
			suffix[3] = data[1] << 4 | data[2] >> 4;
			goto Next2;
		
		Next2:
			suffix[2] = data[1] >> 1;
			suffix[1] = data[0] << 2 | data[1] >> 6;
			goto Next1;
		
		Next1:
			suffix[0] = data[0] >> 3;
			break;
		
		default:
			assert(0);
	}
	
	/**
	 * We run the actual encoding at the end to make sure
	 * getChar calls are made in order. This allow various
	 * checksum computation to be backed in getChar.
	 */
	foreach(s; suffix) {
		buffer[i++] = getChar(s);
	}
	
	return i;
}
