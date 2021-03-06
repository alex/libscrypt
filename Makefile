PREFIX       ?= /usr/local
LIBDIR       ?= $(PREFIX)/lib
INCLUDEDIR   ?= $(PREFIX)/include
MAKE_DIR     ?= install -d
INSTALL_DATA ?= install

CC?=gcc
CFLAGS?=-O2 -Wall -g -D_FORTIFY_SOURCE=2 -fstack-protector -fPIC
LDFLAGS?=-Wl,-z,now -Wl,-z,relro -Wl,-soname,libscrypt.so.0 -Wl,--version-script=libscrypt.version
CFLAGS_EXTRA?=-Wl,-rpath=.

all: reference

OBJS= crypto_scrypt-nosse.o sha256.o crypto_scrypt-hexconvert.o crypto-mcf.o b64.o crypto-scrypt-saltgen.o crypto_scrypt-check.o crypto_scrypt-hash.o

libscrypt.so.0: $(OBJS) 
	$(CC)  $(LDFLAGS) -shared -o libscrypt.so.0 -lc -lm  $(OBJS)
	ar rcs libscrypt.a  $(OBJS)

reference: libscrypt.so.0 main.o b64.o
	ln -s -f libscrypt.so.0 libscrypt.so
	$(CC) -Wall -o reference main.o  b64.o $(CFLAGS_EXTRA) -L.  -lscrypt

clean:
	rm -f *.o reference libscrypt.so* libscrypt.a endian.h

check: all
	./reference

devtest:
	splint crypto_scrypt-hexconvert.c 
	splint crypto-mcf.c crypto_scrypt-check.c crypto_scrypt-hash.c
	splint crypto-scrypt-saltgen.c +posixlib
	valgrind ./reference

install: library
	$(MAKE_DIR) $(DESTDIR) $(DESTDIR)$(PREFIX) $(DESTDIR)$(LIBDIR) $(DESTDIR)$(INCLUDEDIR)
	$(INSTALL_DATA) -pm 0755 libscrypt.so.0 $(DESTDIR)$(LIBDIR)
	cd $(DESTDIR)$(LIBDIR) && ln -s -f libscrypt.so.0 $(DESTDIR)$(LIBDIR)/libscrypt.so
	$(INSTALL_DATA) -pm 0644 libscrypt.h  $(DESTDIR)$(INCLUDEDIR)

install-static: libscrypt.a
	$(INSTALL_DATA) -pm 0644 libscrypt.a $(DESTDIR)$(LIBDIR)
