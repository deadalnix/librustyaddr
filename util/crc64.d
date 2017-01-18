module util.crc64;

private T[256][8] genTables(T)(T polynomial) {
    T[256][8] res = void;

    foreach (i; 0 .. 0x100) {
        T crc = i;
        foreach (_; 0 .. 8)
            crc = (crc >> 1) ^ (-T(crc & 1) & polynomial);
        res[0][i] = crc;
    }

    foreach (i; 0 .. 0x100)
    {
        T crc = res[0][i];
        foreach (j; 1 .. 8)
        {
            crc = (crc >> 8) ^ res[0][crc & 0xff];
            res[j][i] = crc;
        }
    }

    return res;
}

private static immutable ulong[256][8] crc64Tables = genTables(0xC96C5795D7870F42);

struct CRC64
{
    private:
        // magic initialization constants
        ulong _state = ulong.max;

    public:
        /**
         * Use this to feed the digest with data.
         * Also implements the $(REF isOutputRange, std,range,primitives)
         * interface for $(D ubyte) and $(D const(ubyte)[]).
         */
        void put(scope const(ubyte)[] data...) @trusted pure nothrow @nogc
        {
            ulong crc = _state;
            // process eight bytes at once
            while (data.length >= 16)
            {
                // Use byte-wise reads to support architectures without HW support
                // for unaligned reads. This can be optimized by compilers to a single
                // 32-bit read if unaligned reads are supported.
                // DMD is not able to do this optimization though, so explicitly
                // do unaligned reads for DMD's architectures.
                version (X86)
                    enum hasLittleEndianUnalignedReads = true;
                else version (X86_64)
                    enum hasLittleEndianUnalignedReads = true;
                else
                    enum hasLittleEndianUnalignedReads = false; // leave decision to optimizer
                static if (hasLittleEndianUnalignedReads)
                {
                    uint one = (cast(uint*) data.ptr)[0];
                    uint two = (cast(uint*) data.ptr)[1];
                }
                else
                {
                    uint one = (data.ptr[3] << 24 | data.ptr[2] << 16 | data.ptr[1] << 8 | data.ptr[0]);
                    uint two = (data.ptr[7] << 24 | data.ptr[6] << 16 | data.ptr[5] << 8 | data.ptr[4]);
                }

                one ^= cast(uint) crc;
                two ^= cast(uint) (crc >> 32);

                crc =
                    crc64Tables[0][two >> 24] ^
                    crc64Tables[1][(two >> 16) & 0xFF] ^
                    crc64Tables[2][(two >>  8) & 0xFF] ^
                    crc64Tables[3][two & 0xFF] ^
                    crc64Tables[4][one >> 24] ^
                    crc64Tables[5][(one >> 16) & 0xFF] ^
                    crc64Tables[6][(one >>  8) & 0xFF] ^
                    crc64Tables[7][one & 0xFF];

                data = data[8 .. $];
            }
            // remaining 1 to 7 bytes
            foreach (d; data)
                crc = (crc >> 8) ^ crc64Tables[0][(crc ^ d) & 0xFF];
            _state = crc;
        }
        ///
        unittest
        {
            CRC64 dig;
            dig.put(cast(ubyte)0); //single ubyte
            dig.put(cast(ubyte)0, cast(ubyte)0); //variadic
            ubyte[10] buf;
            dig.put(buf); //buffer
        }

        /**
         * Used to initialize the CRC64 digest.
         *
         * Note:
         * For this CRC64 Digest implementation calling start after default construction
         * is not necessary. Calling start is only necessary to reset the Digest.
         *
         * Generic code which deals with different Digest types should always call start though.
         */
        void start() @safe pure nothrow @nogc
        {
            this = CRC64.init;
        }
        ///
        unittest
        {
            CRC64 digest;
            //digest.start(); //Not necessary
            digest.put(0);
        }

        /**
         * Returns the finished CRC64 hash. This also calls $(LREF start) to
         * reset the internal state.
         */
        ubyte[8] finish() @safe pure nothrow @nogc
        {
            auto tmp = peek();
            start();
            return tmp;
        }
        ///
        unittest
        {
            //Simple example
            CRC64 hash;
            hash.put(cast(ubyte)0);
            ubyte[8] result = hash.finish();
        }

        /**
         * Works like $(D finish) but does not reset the internal state, so it's possible
         * to continue putting data into this CRC64 after a call to peek.
         */
        ubyte[8] peek() const @safe pure nothrow @nogc
        {
            import std.bitmanip : nativeToLittleEndian;
            //Complement, LSB first / Little Endian, see http://rosettacode.org/wiki/CRC-32
            return nativeToLittleEndian(~_state);
        }
}

import std.digest.digest;

//simple alias doesn't work here, hope this gets inlined...
ubyte[8] crc64Of(T...)(T data)
{
    return digest!(CRC64, T)(data);
}

alias crcHexString = toHexString!(Order.decreasing);
///ditto
alias crcHexString = toHexString!(Order.decreasing, 16);
