lib			:=	lib

modules		:=	$(lib)

test		:=	test

SUBDIRS		:=	$(test) $(modules)

.PHONY: all $(test) $(modules)
all: $(test)
	@echo "$(test)"
	@echo "$(modules)"
	@echo "$(shell pwd)"

$(test) $(modules):
	$(MAKE) --directory=$@

$(test): $(modules)

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
