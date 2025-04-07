#!/bin/bash

BUCKET_URL="$1"

if [ -z "$BUCKET_URL" ]; then
    echo "Usage: ./generate_index.sh s3://your-bucket-name/path"
    exit 1
fi

BUCKET=$(echo "$BUCKET_URL" | cut -d'/' -f3)
PREFIX=$(echo "$BUCKET_URL" | cut -d'/' -f4-)
BASE_URL="https://$BUCKET.s3.amazonaws.com"

# Use a temp file in current working directory
ALL_FILES="./all_files.txt"
OUTPUT="./index.html"

# Start HTML
cat <<EOF > "$OUTPUT"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Benchmark Results</title>
  <style>
    body { font-family: Arial, sans-serif; padding: 1rem; }
    ul { list-style-type: none; padding-left: 1em; }
    li.folder > span { cursor: pointer; font-weight: bold; color: #2c3e50; }
    li.file > a { text-decoration: none; color: #2980b9; }
    li.file > a:hover { text-decoration: underline; }
    .hidden { display: none; }
  </style>
  <script>
    function toggleAll(expand = true) {
      document.querySelectorAll('li.folder > span + ul').forEach(ul => {
        ul.classList.toggle('hidden', !expand);
      });
    }
  </script>
</head>
<body>
  <h1>Benchmark Results</h1>
  <button onclick="toggleAll(true)">📂 Expand All</button>
  <button onclick="toggleAll(false)">📁 Collapse All</button>
  <ul id="tree">
EOF

# Fetch file list from S3
aws s3api list-objects-v2 --bucket "$BUCKET" --prefix "$PREFIX" --query "Contents[].Key" --output text | sort > "$ALL_FILES"

# Generate the file tree using Python with UTF-8 support
python3 - <<EOF >> "$OUTPUT"
import os
from collections import defaultdict

class FileTree:
    def __init__(self):
        self.tree = {}

    def add_file(self, path):
        parts = path.split('/')
        current = self.tree
        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            current = current[part]
        current[parts[-1]] = None

    def render(self, base_url):
        def render_node(node, path=""):
            html = "<ul>"
            for key in sorted(node.keys()):
                full_path = f"{path}/{key}" if path else key
                if node[key] is None:
                    # This is a file
                    url = f"{base_url}/{full_path}"
                    html += f'<li class="file"><a href="{url}" target="_blank" download>📄 {key}</a></li>'
                else:
                    # This is a folder
                    html += f'<li class="folder"><span onclick="this.nextElementSibling.classList.toggle(\'hidden\')">📁 {key}</span>'
                    html += render_node(node[key], full_path)
                    html += '</li>'
            html += "</ul>"
            return html

        return render_node(self.tree)

# Read files from input
tree = FileTree()
with open("$ALL_FILES", "r", encoding="utf-8") as f:
    for line in f:
        key = line.strip()
        if not key.endswith('/'):  # Ignore directory placeholders
            tree.add_file(key)

# Print the rendered tree
print(tree.render("$BASE_URL"))
EOF

# End HTML
cat <<EOF >> "$OUTPUT"
  </ul>
</body>
</html>
EOF

# Clean up
rm "$ALL_FILES"

echo "✅ Pretty index.html with downloadable links generated at: $OUTPUT"
