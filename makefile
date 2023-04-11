all:
	rm -rf sqlite
	git clone --depth=1 https://github.com/sqlite/sqlite
	cp makefile-lsm sqlite/makefile-lsm
	cd sqlite && make -j$(nproc) -f makefile-lsm lsm.so
	cp sqlite/lsm.so .

