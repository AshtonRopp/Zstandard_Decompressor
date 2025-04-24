git clone https://github.com/facebook/zstd.git
cd zstd
make
cd tests
make datagen
cd ..
cd ..
./zstd/tests/datagen -g8M > input.txt
./zstd/zstd -f input.txt -o input.zst