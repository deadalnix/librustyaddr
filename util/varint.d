module util.varint;

uint encode(ulong n, ubyte[] buffer) {
	if (n < 0x80) {
		if (buffer.length < 1) {
			throw new Exception("not enough space in the buffer");
		}
		
		buffer[0] = n & 0xff;
		return 1;
	}
	
	import core.bitop;
	auto bsr = bsr(n);
	
	auto offset = 0x0102040810204080 & ((2UL << bsr) - 1);
	
	// This is some black magic. We whant to divide by 7
	// but still get 8 for bsr == 63. We can aproxiamate
	// this result via a linear function and let truncate
	// do the rest.
	auto byteCount = ((bsr * 36) + 35) >> 8;
	auto e = n - offset;
	
	// If we underflow, we need to go one class down.
	if (e > n) {
		offset -= 1UL << bsr;
		byteCount--;
		e = n - offset;
	}
	
	// For some obscure reason, DMD doesn't have bswap for 16 bits integrals.
	// so we do everything with 32bits and 64bits ones.
	import core.bitop;
	
	// This is a fast path that is usable if we have extra buffer space.
	if (buffer.length >= 8 && byteCount < 8) {
		auto h = -(1 << (8 - byteCount)) & 0xff;
		auto v = bswap(e) >> ((7 - byteCount) * 8);
		*(cast(ulong*) buffer.ptr) = (h | v);
		return byteCount + 1;
	}
	
	if (buffer.length <= byteCount) {
		throw new Exception("not enough space in the buffer");
	}
	
	switch(byteCount) {
		case 1:
			*(cast(ushort*) buffer.ptr) = 0x80 | (bswap(cast(uint) e) >> 16);
			break;
		
		case 2:
			buffer[0] = (0xc0 | (e >> 16)) & 0xff;
			*(cast(ushort*) (buffer.ptr + 1)) = (bswap(cast(uint) e) >> 16) & 0xffff;
			break;
		
		case 3:
			*(cast(uint*) buffer.ptr) = 0xe0 | bswap(cast(uint) e);
			break;
		
		case 4:
			buffer[0] = (0xf0 | (e >> 32)) & 0xff;
			*(cast(uint*) (buffer.ptr + 1)) = bswap(cast(uint) e);
			break;
		
		case 5:
			*(cast(uint*) buffer.ptr) = 0xf8 | bswap(cast(uint) (e >> 16));
			*(cast(ushort*) (buffer.ptr + 4)) = bswap(cast(uint) e) >> 16;
			break;
		
		case 6:
			buffer[0] = (0xfc | (e >> 48)) & 0xff;
			*(cast(ushort*) (buffer.ptr + 1)) = bswap(cast(uint) (e >> 16)) & 0xffff;
			*(cast(uint*) (buffer.ptr + 3)) = bswap(cast(uint) e);
			break;
		
		case 7:
			*(cast(ulong*) buffer.ptr) = 0xfe | bswap(e);
			break;
		
		case 8:
			buffer[0] = 0xff;
			*(cast(ulong*) (buffer.ptr + 1)) = bswap(e);
			break;
		
		default:
			assert(0);
	}
	
	return byteCount + 1;
}

unittest {
	void testEncode(ulong n, ubyte[] expected) {
		ubyte[9] buffer;
		auto l = expected.length;
		auto sbuf = buffer[0 .. l];
		
		// Test fast path.
		assert(encode(n, buffer) == l);
		assert(sbuf == expected);
		
		// Test contrained path.
		assert(encode(n, sbuf) == l);
		assert(sbuf == expected);
	}
	
	testEncode(0, [0]);
	testEncode(1, [1]);
	testEncode(42, [42]);
	testEncode(127, [127]);
	
	testEncode(128, [0x80, 0x00]);
	testEncode(129, [0x80, 0x01]);
	testEncode(0x3fff, [0xbf, 0x7f]);
	testEncode(0x407f, [0xbf, 0xff]);
	
	testEncode(0x4080, [0xc0, 0x00, 0x00]);
	testEncode(0x25052, [0xc2, 0x0f, 0xd2]);
	testEncode(0x20407f, [0xdf, 0xff, 0xff]);
	
	testEncode(0x204080, [0xe0, 0x00, 0x00, 0x00]);
	testEncode(0x1234567, [0xe1, 0x03, 0x04, 0xe7]);
	testEncode(0x1020407f, [0xef, 0xff, 0xff, 0xff]);
	
	testEncode(0x10204080, [0xf0, 0x00, 0x00, 0x00, 0x00]);
	testEncode(0x312345678, [0xf3, 0x02, 0x14, 0x15, 0xf8]);
	testEncode(0x081020407f, [0xf7, 0xff, 0xff, 0xff, 0xff]);
	
	testEncode(0x0810204080, [0xf8, 0x00, 0x00, 0x00, 0x00, 0x00]);
	testEncode(0x032101234567, [0xfb, 0x18, 0xf1, 0x03, 0x04, 0xe7]);
	testEncode(0x04081020407f, [0xfb, 0xff, 0xff, 0xff, 0xff, 0xff]);
	
	testEncode(0x040810204080, [0xfc, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
	testEncode(0x0123456789abcd, [0xfd, 0x1f, 0x3d, 0x57, 0x69, 0x6b, 0x4d]);
	testEncode(0x0204081020407f, [0xfd, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
	
	testEncode(
		0x02040810204080,
		[0xfe, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
	);
	testEncode(
		0xfedcba98765432,
		[0xfe, 0xfc, 0xd8, 0xb2, 0x88, 0x56, 0x13, 0xb2],
	);
	testEncode(
		0x010204081020407f,
		[0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff],
	);
	
	testEncode(
		0x0102040810204080,
		[0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
	);
	testEncode(
		0xffffffffffffffff,
		[0xff, 0xfe, 0xfd, 0xfb, 0xf7, 0xef, 0xdf, 0xbf, 0x7f],
	);
}
