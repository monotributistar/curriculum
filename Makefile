.PHONY: build clean validate

build:
	./scripts/build.sh

clean:
	./scripts/clean.sh

validate:
	@for f in cv/CV.md cv/CV-ES.md cv/CV-EN.md; do \
		if [ -f "$$f" ]; then ./scripts/validate.sh "$$f"; fi; \
	done

