#!/bin/bash
# Optimize click-pics images for web use
# Run from project root: ./click-pics/optimize-for-web.sh

set -e
cd "$(dirname "$0")"

OUTPUT_DIR="web-ready"
MAX_WIDTH=1200
JPEG_QUALITY=high

mkdir -p "$OUTPUT_DIR"
echo "Optimizing images for web (max ${MAX_WIDTH}px, quality: ${JPEG_QUALITY})..."
echo "Output: $OUTPUT_DIR/"
echo ""

count=0
for src in *.jpeg *.jpg *.png *.JPG *.JPEG *.PNG; do
    [ -f "$src" ] || continue
    [ "$src" = ".DS_Store" ] && continue
    
    # Create safe filename: lowercase, replace spaces with hyphens
    base=$(basename "$src" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/\.[^.]*$//')
    dest="${OUTPUT_DIR}/${base}.jpg"
    
    # Skip if output exists and is newer
    if [ -f "$dest" ] && [ "$dest" -nt "$src" ]; then
        echo "  Skip (up to date): $src"
        count=$((count + 1))
        continue
    fi
    
    # Resize and convert to JPEG (sips -Z keeps aspect ratio, fits within MAX_WIDTH)
    if sips -Z $MAX_WIDTH -s format jpeg -s formatOptions $JPEG_QUALITY "$src" --out "$dest" 2>/dev/null; then
        orig=$(ls -lh "$src" | awk '{print $5}')
        new=$(ls -lh "$dest" | awk '{print $5}')
        echo "  OK $src -> $base.jpg ($orig -> $new)"
        count=$((count + 1))
    else
        echo "  FAILED: $src"
    fi
done

# Write gallery manifest for dynamic loading
manifest="${OUTPUT_DIR}/gallery-images.json"
images=$(ls -1 "$OUTPUT_DIR"/*.jpg 2>/dev/null | xargs -I {} basename {} | grep -v '^\.' | sort)
if [ -n "$images" ]; then
    json="["
    first=1
    for f in $images; do
        [ $first -eq 1 ] && first=0 || json="$json,"
        json="$json\"$f\""
    done
    json="$json]"
    echo "$json" > "$manifest"
    echo "Wrote gallery manifest: $manifest"
fi

echo ""
echo "Done! $count images optimized in $OUTPUT_DIR/"
echo ""
echo "Use these in your HTML: <img src=\"click-pics/web-ready/filename.jpg\" alt=\"...\">"
