# Makefile for Love2D game

# Variables
GAME_NAME = game
ZIP_NAME = $(GAME_NAME).love
LOVE2D = love
SRC_DIR = src

# Default target
all: zip

# Create the .love file by zipping the game directory
zip:
	cd $(SRC_DIR) && zip -r ../$(ZIP_NAME) . -x "*.love" "Makefile" ".git/*" "*.md"

# Run the game
run: zip
	$(LOVE2D) $(ZIP_NAME)

# Run without creating zip (if love2d can run from directory)
dev:
	$(LOVE2D) $(SRC_DIR)

# Clean up generated files
clean:
	rm -f $(ZIP_NAME)

# Install dependencies (if needed)
install:
	@echo "Make sure Love2D is installed on your system"

.PHONY: all zip run dev clean install