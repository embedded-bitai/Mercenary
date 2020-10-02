ds			:=	ds

modules		:=	$(ds)

app			:=	app

SUBDIRS		:=	$(app) $(modules)

.PHONY: all $(app) $(modules)
all: $(app)
	@echo "$(app)"
	@echo "$(modules)"
	@echo "$(shell pwd)"

$(app) $(modules):
	$(MAKE) --directory=$@

$(app): $(modules)

clean:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done
