.PHONY: build clean validate format

build:
	./scripts/build.sh

clean:
	./scripts/clean.sh

validate:
	@for f in cv/CV.md cv/CV-DEV.md cv/CV-XP.md cv/CV-HUMAN.md cv/CV-ES.md cv/CV-EN.md; do \
		if [ -f "$$f" ]; then ./scripts/validate.sh "$$f"; fi; \
	done

format:
	./scripts/format.sh
