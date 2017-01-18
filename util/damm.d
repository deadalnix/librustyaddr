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
