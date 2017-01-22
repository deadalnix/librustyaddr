module util.damm;

struct Damm {
private:
	uint damm;
	
	this(uint n) in {
		assert(n == (n & 0x1f));
	} body {
		damm = n;
	}
	
public:
	alias value this;
	
	@property value() const {
		return damm;
	}
	
	invariant() {
		assert(damm == (damm & 0x1f));
	}
	
	/**
	 * This compute the next value for the dammn alogorithm
	 * using GF(2^5) and a x^5 + x^2 + 1 as primitive polynomial.
	 *
	 * The value is computed such as n = 2*x + y .
	 */
	Damm getNext(uint x) const in {
		assert(x == (x & 0x1f));
	} out(r) {
		assert(r.damm == (r.damm & 0x1f));
	} body {
		auto n = x ^ (damm << 1);
		auto r = (damm & 0x10) ? n ^ 0x25 : n;
		return Damm(r);
	}
}

unittest {
	// Check some cherry picked entries
	assert(Damm(0).getNext(0) == 0);
	assert(Damm(0).getNext(6) == 6);
	assert(Damm(0).getNext(19) == 19);
	assert(Damm(0).getNext(31) == 31);
	assert(Damm(6).getNext(0) == 12);
	assert(Damm(16).getNext(0) == 5);
	assert(Damm(23).getNext(0) == 11);
	assert(Damm(31).getNext(0) == 27);
	
	assert(Damm(23).getNext(17) == 26);
	assert(Damm(15).getNext(22) == 8);
	assert(Damm(7).getNext(8) == 6);
	assert(Damm(3).getNext(30) == 24);
	assert(Damm(30).getNext(3) == 26);
	assert(Damm(8).getNext(12) == 28);
	assert(Damm(14).getNext(5) == 25);
	assert(Damm(26).getNext(29) == 12);
	
	foreach(i; 0 .. 32) {
		uint row, col;
		foreach(j; 0 .. 32) {
			auto x = Damm(i).getNext(j);
			auto y = Damm(j).getNext(i);
			row = row | (1 << x);
			col = col | (1 << y);
			
			// Checks that the quasigroup is antisymetric.
			assert(x != y || i == j);
			
			// Checks that the quasigroup is weakly totaly antisymetric.
			foreach(c; 0 .. 32) {
				auto a = Damm(c).getNext(i).getNext(j);
				auto b = Damm(c).getNext(j).getNext(i);
				
				assert(a != b || i == j);
			}
		}
		
		// Check that it is a magic square.
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
			write("\t", Damm(y).getNext(x).value);
		}
	}
	
	writeln();
}
