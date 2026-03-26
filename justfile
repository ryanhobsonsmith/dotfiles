image := "dotfiles-test"

# Build the test Docker image
build:
    docker build -t {{image}} .

# Run tests in a clean container
test: build
    docker run --rm {{image}}

# Launch an interactive shell in a clean container
shell: build
    docker run --rm -it {{image}} /bin/bash
