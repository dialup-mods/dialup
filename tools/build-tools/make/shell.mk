check-shell:
	@if [ "$(PROBABLYMICROSOFT)" = "1" ]; then \
		cat "$(EXCEPTION_FILE)"; \
		exit 1; \
	fi
