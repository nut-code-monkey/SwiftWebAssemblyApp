#!/bin/zsh

# ==============================================================================
# Automates Swift -> WASM compilation & JS Bundling
# Usage: ./bundle_wasm.sh [TargetName] [options]
# ==============================================================================

show_help() {
  echo "Usage: ./bundle_wasm.sh [TargetName] [options]"
  echo "Example: ./bundle_wasm.sh TargetName -c release"
}

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [[ -z "$1" ]]; then
  show_help
  exit 0
fi

TARGET_NAME=$1
shift 

START_TIME=$(date +%s)
set -e

# 1. Корінь проекту
if [ -n "$WORKSPACE_PATH" ]; then
  PROJECT_ROOT="${WORKSPACE_PATH%/.swiftpm/xcode/package.xcworkspace}"
  cd "$PROJECT_ROOT"
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# 2. Перевірка Node.js та esbuild
ESBUILD="./node_modules/.bin/esbuild"
if [ ! -f "$ESBUILD" ]; then
  if ! command -v npm &> /dev/null; then
    echo "❌ Error: 'npm' not found. Please install Node.js."
    exit 1
  fi
  echo "📦 Installing dependencies..."
  [ ! -f "package.json" ] && npm init -y > /dev/null
  npm install --save-dev esbuild
fi

# 3. Динамічні шляхи
ROOT_DIR=$(pwd)
WASM_SRC="${ROOT_DIR}/.build/plugins/PackageToJS/outputs/Package/${TARGET_NAME}.wasm"
DEST_DIR="${ROOT_DIR}/Public/${TARGET_NAME}"
PUBLIC_WASM="${DEST_DIR}/app.wasm"
LAST_MODE_FILE="${ROOT_DIR}/.build/last_build_mode_${TARGET_NAME}.txt"
SOURCE_DIR="${ROOT_DIR}/Sources/${TARGET_NAME}"

# Створюємо папку і відразу перевіряємо
echo "📁 Target directory: $DEST_DIR"
mkdir -p "$DEST_DIR"

if [ ! -d "$DEST_DIR" ]; then
  echo "❌ Error: Could not create directory $DEST_DIR"
  exit 1
fi


# Визначаємо режим
BUILD_MODE="debug"
if [[ "$*" == *"-c release"* ]] || [[ "$CONFIGURATION" == "Release" ]]; then
  BUILD_MODE="release"
fi

echo "🛠  Target: $TARGET_NAME ($BUILD_MODE)"

# 4. Smart Build Check
LAST_MODE=$(cat "$LAST_MODE_FILE" 2>/dev/null || echo "")
SKIP_SWIFT=0

if [ -f "$WASM_SRC" ] && [ "$LAST_MODE" = "$BUILD_MODE" ]; then
  NEWEST_SOURCE_TIME=$(find "$SOURCE_DIR" -type f -exec stat -f "%m" {} + | sort -rn | head -1)
  WASM_TIME=$(stat -f "%m" "$WASM_SRC")

  if [ "$WASM_TIME" -gt "$NEWEST_SOURCE_TIME" ]; then
    echo "⏩ Swift sources unchanged, skipping build."
    SKIP_SWIFT=1
  fi
fi

# 5. Swift Compilation
if [ "$SKIP_SWIFT" -eq 0 ]; then
  echo "🚀 Compiling $TARGET_NAME..."
  swift package --swift-sdk swift-6.3.1-RELEASE_wasm js --product "$TARGET_NAME" -c $BUILD_MODE
  echo "$BUILD_MODE" > "$LAST_MODE_FILE"
fi

# 6. WASM Processing (виправлена логіка)
if [ ! -f "$WASM_SRC" ]; then
  echo "⚠️ Warning: Source WASM not found at $WASM_SRC"
  echo "Trying to find it..."
  # Спроба знайти файл, якщо плагін поклав його в інше місце
  WASM_SRC=$(find .build -name "${TARGET_NAME}.wasm" | head -n 1)
fi

if [ -f "$WASM_SRC" ]; then
  # Копіюємо/Оптимізуємо, якщо файлу в Public немає АБО вихідний файл новіший
  if [ ! -f "$PUBLIC_WASM" ] || [ "$WASM_SRC" -nt "$PUBLIC_WASM" ]; then
    if [ "$BUILD_MODE" = "release" ]; then
      echo "🪄 Optimizing WASM -> $PUBLIC_WASM"
      wasm-opt "$WASM_SRC" -Os --strip-debug -o "$PUBLIC_WASM"
    else
      echo "📂 Copying WASM -> $PUBLIC_WASM"
      cp -f "$WASM_SRC" "$PUBLIC_WASM"
    fi
  else
    echo "⏩ $TARGET_NAME.wasm is already in Public and up to date."
  fi
else
  echo "❌ Error: WASM source file not found. Check if Swift build succeeded."
  exit 1
fi

# 7. JS Bundling
ENTRY_JS="${SOURCE_DIR}/entry.js"
if [ -f "$ENTRY_JS" ]; then
  echo "📦 Bundling JS..."
  $ESBUILD "$ENTRY_JS" \
    --bundle \
    --format=esm \
    $([ "$BUILD_MODE" = "release" ] && echo "--minify") \
    --outfile="${DEST_DIR}/app.js" \
    --loader:.wasm=file \
    --log-level=error
else
  echo "⚠️ Warning: No entry.js found at $ENTRY_JS"
fi

echo "📄 HTML loader..."
swift run AppLoader $TARGET_NAME "${DEST_DIR}/index.html"

END_TIME=$(date +%s)
echo "✅ Done in $((END_TIME - START_TIME))s!"
