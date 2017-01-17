module util.zbase32;

char getChar(uint n) {
	enum Alphabet = "ybndrfg8ejkmcpqxot1uwisza345h769";
	return Alphabet[n & 0x1f];
}

char[] encode(const(ubyte)[] data) {
	char[] buffer;
	buffer.length = ((data.length * 8  - 1) / 5) + 1;
	
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
	
	auto end = buffer[i .. $];
	switch(data.length) {
		case 0:
			goto Next0;
		
		case 1:
			end[1] = getChar(data[0] << 2);
			goto Next1;
		
		case 2:
			end[3] = getChar(data[1] << 4);
			goto Next2;
		
		case 3:
			end[4] = getChar(data[2] << 1);
			goto Next3;
		
		case 4:
			end[4] = getChar(data[2] << 1 | data[3] >> 7);
			end[5] = getChar(data[3] >> 2);
			end[6] = getChar(data[3] << 3);
			goto Next3;
		
		Next3:
			end[3] = getChar(data[1] << 4 | data[2] >> 4);
			goto Next2;
		
		Next2:
			end[2] = getChar(data[1] >> 1);
			end[1] = getChar(data[0] << 2 | data[1] >> 6);
			goto Next1;
		
		Next1:
			end[0] = getChar(data[0] >> 3);
			goto Next0;
		
		Next0:
			return buffer;
		
		default:
			assert(0);		
	}
}
