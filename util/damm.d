module util.damm;

/**
 * This compute the next value for the dammn alogorithm
 * using GF(2^5) and a x^5 + x^2 + 1 as primitive polynomial.
 *
 * The value is computed such as n = 2*x + y .
 */
uint getNextDamm(uint x, uint y) in {
	assert(x == (x & 0x1f));
	assert(y == (y & 0x1f));
} out(r) {
	assert(r == (r & 0x1f));
} body {
	auto n = y ^ (x << 1);
	return (x & 0x10)
		? n ^ 0x25
		: n;
}

unittest {
	// Check some cherry picked entries
	assert(getNextDamm(0, 0) == 0);
	assert(getNextDamm(0, 6) == 6);
	assert(getNextDamm(0, 19) == 19);
	assert(getNextDamm(0, 31) == 31);
	assert(getNextDamm(6, 0) == 12);
	assert(getNextDamm(16, 0) == 5);
	assert(getNextDamm(23, 0) == 11);
	assert(getNextDamm(31, 0) == 27);

	assert(getNextDamm(23, 17) == 26);
	assert(getNextDamm(15, 22) == 8);
	assert(getNextDamm(7, 8) == 6);
	assert(getNextDamm(3, 30) == 24);
	assert(getNextDamm(30, 3) == 26);
	assert(getNextDamm(8, 12) == 28);
	assert(getNextDamm(14, 5) == 25);
	assert(getNextDamm(26, 29) == 12);
	
	foreach(i; 0 .. 32) {
		uint row, col;
		foreach(j; 0 .. 32) {
			row = row | (1 << getNextDamm(i, j));
			col = col | (1 << getNextDamm(j, i));
		}
		
		assert(row == -1);
		assert(col == -1);
	}
}

void dumpTransitionTable() {
	import std.stdio;
	foreach(uint y; 0 .. 32) {
		write("\t", y);
	}
	
	foreach(uint x; 0 .. 32) {
		write("\n", x);
		foreach(uint y; 0 .. 32) {
			write("\t", getNextDamm(x, y));
		}
	}
	
	writeln();
}
