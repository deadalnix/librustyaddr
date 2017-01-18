module util.varint;

uint encode(ulong n, ubyte[] buffer) {
	if (n < 0x80) {
		buffer[0] = n & 0xff;
		return 1;
	}
	
	import core.bitop;
	auto bits = bsr(n) + 1;
	
	auto offset = 0x0102040810204080 & ((1UL << bits) - 1);
	
	// This does divide by 7 on the 0 - 64 range.
	auto byteCount = (bits - 1) * 37 >> 8;
	auto e = n - offset;
	
	// If we underflow, we need to go one class down.
	if (e > n) {
		offset -= 1UL << (bits - 1);
		byteCount--;
		e = n - offset;
	}
	
	switch(byteCount) {
		case 1:
			buffer[0] = (0x80 | (e >> 8)) & 0xff;
			buffer[1] = e & 0xff;
			break;
		
		case 2:
			buffer[0] = (0xc0 | (e >> 16)) & 0xff;
			buffer[1] = (e >> 8) & 0xff;
			buffer[2] = e & 0xff;
			break;
		
		case 3:
			buffer[0] = (0xe0 | (e >> 32)) & 0xff;
			buffer[1] = (e >> 16) & 0xff;
			buffer[2] = (e >> 8) & 0xff;
			buffer[3] = e & 0xff;
			break;
		
		case 4:
			buffer[0] = (0xf0 | (e >> 40)) & 0xff;
			buffer[1] = (e >> 24) & 0xff;
			buffer[2] = (e >> 16) & 0xff;
			buffer[3] = (e >> 8) & 0xff;
			buffer[4] = e & 0xff;
			break;
		
		default:
			assert(0);
	}
	
	return byteCount + 1;
}

unittest {
	ubyte[9] buffer;
	assert(encode(0, buffer) == 1);
	assert(buffer[0] == 0);
	assert(encode(1, buffer) == 1);
	assert(buffer[0] == 1);
	assert(encode(42, buffer) == 1);
	assert(buffer[0] == 42);
	assert(encode(127, buffer) == 1);
	assert(buffer[0] == 127);
	assert(encode(128, buffer) == 2);
	assert(buffer[0 .. 2] == [0x80, 0]);
	assert(encode(129, buffer) == 2);
	assert(buffer[0 .. 2] == [0x80, 1]);
	assert(encode(0x3fff, buffer) == 2);
	assert(buffer[0 .. 2] == [0xbf, 0x7f]);
	assert(encode(0x407f, buffer) == 2);
	assert(buffer[0 .. 2] == [0xbf, 0xff]);
	assert(encode(0x4080, buffer) == 3);
	assert(buffer[0 .. 3] == [0xc0, 0x00, 0x00]);
	assert(encode(0x5002, buffer) == 3);
	assert(buffer[0 .. 3] == [0xc0, 0x00, 0x22]);
	assert(encode(0x20407f, buffer) == 3);
	assert(buffer[0 .. 3] == [0xdf, 0xff, 0xff]);
	assert(encode(0x204080, buffer) == 4);
	assert(buffer[0 .. 4] == [0xe0, 0x00, 0x00, 0x00]);
}
