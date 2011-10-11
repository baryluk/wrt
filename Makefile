.PHONY: all
all:
	$(MAKE) -C ./wrt/

.PHONY: run
run: all
	./wrt/main
