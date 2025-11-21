#Project Configuration
TARGET        = c_template
CC            = clang
SRC_DIR       = ./src
INC_DIR       = ./inc
OBJ_DIR       = ./obj
BIN_DIR       = ./bin
BUILD         := $(if $(MAKECMDGOALS),$(firstword $(MAKECMDGOALS)),debug)

#File Discovery
SRCS          = $(wildcard $(SRC_DIR)/*.c)
OBJS          = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/$(BUILD)/%.o,$(SRCS))
DEPS          = $(wildcard $(INC_DIR)/*.h)

#Compiler Flags
COMMON_FLAGS  = -I$(INC_DIR) -Wall -Wextra -Wpedantic -fdiagnostics-color=always
RELEASE_FLAGS = -O3 -flto
NATIVE_FLAGS  = -O3 -flto -march=native
DEBUG_FLAGS   = -Og -ggdb3

#Release build
release: CFLAGS = $(COMMON_FLAGS) $(RELEASE_FLAGS)
release: setup $(BIN_DIR)/$(TARGET)-$(BUILD)

#Native build
native: CFLAGS = $(COMMON_FLAGS) $(NATIVE_FLAGS)
native: setup $(BIN_DIR)/$(TARGET)-$(BUILD)

#Debug build
debug: CFLAGS = $(COMMON_FLAGS) $(DEBUG_FLAGS)
debug: setup $(BIN_DIR)/$(TARGET)-$(BUILD)

#Create directories
setup:
	@mkdir -p $(OBJ_DIR)/$(BUILD) $(BIN_DIR)

#Compile objects
$(OBJ_DIR)/$(BUILD)/%.o: $(SRC_DIR)/%.c $(DEPS)
	$(CC) $(CFLAGS) -c $< -o $@

#Main targets
$(BIN_DIR)/$(TARGET)-$(BUILD): $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

	@if [ -f "$(BIN_DIR)/$(TARGET)-release" ]; then \
		mv "$(BIN_DIR)/$(TARGET)-release" "$(BIN_DIR)/$(TARGET)"; \
	fi

#Clean build artifacts
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)

#Help message
help:
	@echo "Available targets:"
	@echo "  release  : Build release version"
	@echo "  native   : Build with native CPU optimizations"
	@echo "  debug    : Build debug version"
	@echo "  clean    : Remove all build artifacts"
	@echo "  help     : Show this help message"
	@echo ""
	@echo "Binaries output to: $(BIN_DIR)"
	@echo "Objects output to: $(OBJ_DIR)"

.PHONY: release native debug clean help
