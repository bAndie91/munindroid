
TARGET=/data/system/munin/

install:
	@uname -m | grep -iq arm || ( echo "Run make install on Android."; exit 1; )
	test -d $(TARGET) || mkdir -p $(TARGET)
	test -d $(TARGET)
	cp munin-node.sh $(TARGET)
	cp server.sh $(TARGET)
