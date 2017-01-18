module util.damm;

uint computeDamm(const(ubyte)[] data) {
	uint x;
	foreach (y; data) {
		x = getNext(x, y);
	}
	
	return x;
}

private:
/**
 * This compute the next value for the dammn alogorithm
 * using GF(2^5) and a x^5 + x^2 + 1 as primitive polynomial.
 *
 * The value is computed such as n = 2*x + y .
 */
uint getNext(uint x, uint y) in {
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
