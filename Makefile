all:
	@echo "Building cl-styles..."
	@# Add build commands here

test:
	@echo "Running tests..."
	@ros --quiet run -- --load ~/.sbclrc --load ~/.cl-repl --load run.lisp

clean:
	@echo "Cleaning up..."
	@# Add clean commands here
