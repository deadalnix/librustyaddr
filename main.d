module main;

void main() {
	auto hash = cast(ubyte[])x"0000000000000000000000000000000000000000";
	
	import std.stdio;
	writeln(encode("btc:", 0, hash));
}

char[] encode(string prefix, ulong ver, ubyte[] hash) {
	auto hSize = 20 + 4 * (ver & 0x03);
	if (ver & 0x04) {
		hSize *= 2;
	}
	
	if (hash.length != hSize) {
		throw new Exception("Invalid hash size");
	}
	
	size_t size = 0;
	ubyte[9 + 512 + 6] binBuf;
	
	import util.varint;
	size += util.varint.encode(ver, binBuf);
	
	import core.stdc.string;
	memcpy(binBuf.ptr + size, hash.ptr, hash.length);
	
	size += hash.length;
	
	import util.crc64;
	CRC64 hasher;
	hasher.put(cast(const(ubyte)[])prefix);
	hasher.put(binBuf[0 .. size]);
	
	auto crc = hasher.finish();
	memcpy(binBuf.ptr + size, crc.ptr, 5);
	
	import util.base32;
	auto addrSize = prefix.length + getBase32Size(size) + 8;
	
	import std.array;
	char[] addr = uninitializedArray!(char[])(addrSize);
	
	import core.stdc.string;
	memcpy(addr.ptr, prefix.ptr, prefix.length);
	
	import util.damm;
	Damm damm;
	char getChar(uint n) in {
		assert(n == (n & 0x1f));
	} body {
		import util.damm;
		damm = damm.getNext(n);
		
		import util.base32;
		return getZBase32(n);
	}
	
	// We discard the last character as it contains only extra CRC bits we don't want.
	util.base32.encode!(getChar, true)(binBuf[0 .. size + 5], addr[prefix.length .. $]);
	
	// Set the Damm result as last char.
	addr[$ - 1] = getZBase32(damm);
	return addr;
}
