#Project Configuration
TARGET        = c_project
CC            = gcc
SRC_DIR       = ./src
INC_DIR       = ./inc
OBJ_DIR       = ./obj
BIN_DIR       = ./bin

#Parallel jobs: try nproc, then getconf, then /dev/cpu count (Linux), then default to 1
NPROC         := $(shell nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || ls /dev/cpu/[0-9]* 2>/dev/null | wc -l | grep -v '^0$$' || echo 1)
MAKEFLAGS     += -j$(NPROC)

#File Discovery
SRCS          = $(wildcard $(SRC_DIR)/*.c)

#Per-build object lists (each build has its own subdirectory)
RELEASE_OBJS  = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/release/%.o,$(SRCS))
NATIVE_OBJS   = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/native/%.o,$(SRCS))
DEBUG_OBJS    = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/debug/%.o,$(SRCS))

#Compiler Flags
COMMON_FLAGS  = -I$(INC_DIR) -Wall -Wextra -Wpedantic -fdiagnostics-color=always
RELEASE_FLAGS = -O3 -flto -march=generic -static
NATIVE_FLAGS  = -O3 -flto -march=native
DEBUG_FLAGS   = -Og -ggdb3

#Release build
release: CFLAGS = $(COMMON_FLAGS) $(RELEASE_FLAGS)
release: $(BIN_DIR)/$(TARGET)-release

#Native build
native: CFLAGS = $(COMMON_FLAGS) $(NATIVE_FLAGS)
native: $(BIN_DIR)/$(TARGET)-native

#Debug build
debug: CFLAGS = $(COMMON_FLAGS) $(DEBUG_FLAGS)
debug: $(BIN_DIR)/$(TARGET)-debug

#Create directories (order-only prerequisites prevent race conditions under -j)
$(OBJ_DIR)/release $(OBJ_DIR)/native $(OBJ_DIR)/debug $(BIN_DIR):
	mkdir -p $@

#Compile objects — auto-generate dependency files with -MMD -MP
$(OBJ_DIR)/release/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)/release
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

$(OBJ_DIR)/native/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)/native
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

$(OBJ_DIR)/debug/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)/debug
	$(CC) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

#Main targets
$(BIN_DIR)/$(TARGET)-release: $(RELEASE_OBJS) | $(BIN_DIR)
	$(CC) $(CFLAGS) $^ -o $@
	@cp $@ $(BIN_DIR)/$(TARGET)  #also install as the default binary

$(BIN_DIR)/$(TARGET)-native: $(NATIVE_OBJS) | $(BIN_DIR)
	$(CC) $(CFLAGS) $^ -o $@

$(BIN_DIR)/$(TARGET)-debug: $(DEBUG_OBJS) | $(BIN_DIR)
	$(CC) $(CFLAGS) $^ -o $@

#Include auto-generated header dependency files
-include $(RELEASE_OBJS:.o=.d)
-include $(NATIVE_OBJS:.o=.d)
-include $(DEBUG_OBJS:.o=.d)

init:
	mkdir -p $(SRC_DIR) $(INC_DIR)

#Clean build artifacts
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)

#Help message
help:
	@echo "Available targets:"
	@echo "  init     : Initialises Source and Include directories"
	@echo "  release  : Build release version"
	@echo "  native   : Build with native CPU optimizations"
	@echo "  debug    : Build debug version"
	@echo "  clean    : Remove all build artifacts"
	@echo "  help     : Show this help message"
	@echo ""
	@echo "Binaries output to: $(BIN_DIR)"
	@echo "Objects output to: $(OBJ_DIR)"

.PHONY: init release native debug clean help
