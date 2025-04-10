#!/bin/bash

BUCKET_URL="$1"

if [ -z "$BUCKET_URL" ]; then
    echo "Usage: ./ascii_tree_index.sh s3://your-bucket-name/path"
    exit 1
fi

BUCKET=$(echo "$BUCKET_URL" | cut -d'/' -f3)
PREFIX=$(echo "$BUCKET_URL" | cut -d'/' -f4-)
BASE_URL="https://$BUCKET.s3.amazonaws.com"

# Use a temp file in current working directory
ALL_FILES="./all_files.txt"
OUTPUT="./index.html"

# Run AWS S3 list command and process the output
echo "Listing files from S3 bucket $BUCKET_URL..."
aws s3api list-objects-v2 \
    --bucket "$BUCKET" \
    --prefix "$PREFIX" \
    --query "Contents[].Key" \
    --output text | tr '\t' '\n' | sort > "$ALL_FILES"

# Start HTML
cat > "$OUTPUT" << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Benchmark Results</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 1rem;
      max-width: 1200px;
      margin: 0 auto;
      line-height: 1.5;
    }
    h1 {
      color: #2c3e50;
      border-bottom: 1px solid #eee;
      padding-bottom: 10px;
    }
    ul {
      list-style-type: none;
      padding-left: 1.5em;
      margin: 0;
    }
    li.folder > span {
      cursor: pointer;
      font-weight: bold;
      color: #2c3e50;
      display: block;
      padding: 5px;
      margin: 2px 0;
      background: #f4f4f4;
      border-radius: 3px;
      user-select: none;
    }
    li.folder > span:hover {
      background: #e4e4e4;
    }
    li.file > a {
      text-decoration: none;
      color: #3498db;
      display: block;
      padding: 5px;
      margin: 2px 0;
      background: #f8f9fa;
      border-radius: 3px;
    }
    li.file > a:hover {
      text-decoration: underline;
      background: #edf2f7;
    }
    .hidden { display: none; }
    .controls {
      margin: 15px 0;
      display: flex;
      gap: 10px;
    }
    button {
      padding: 8px 16px;
      background-color: #3498db;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      transition: background-color 0.2s;
    }
    button:hover {
      background-color: #2980b9;
    }
    .folder-icon, .file-icon {
      display: inline-block;
      width: 20px;
      text-align: center;
      margin-right: 5px;
    }
    .folder-icon {
      color: #f39c12;
    }
    .file-icon {
      color: #3498db;
    }
    .path-display {
      color: #7f8c8d;
      font-size: 0.8em;
      margin-left: 25px;
    }
    .search-container {
      margin-bottom: 15px;
    }
    #searchInput {
      padding: 8px;
      width: 300px;
      border: 1px solid #ddd;
      border-radius: 4px;
    }
  </style>
  <script>
    function toggleFolder(element) {
      const ul = element.nextElementSibling;
      if (ul) {
        ul.classList.toggle('hidden');
      }
    }

    function toggleAll(expand = true) {
      document.querySelectorAll('li.folder > span + ul').forEach(ul => {
        ul.classList.toggle('hidden', !expand);
      });
    }

    function downloadFile(url) {
      const link = document.createElement('a');
      link.href = url;
      // Extract filename from URL for better download experience
      const filename = url.substring(url.lastIndexOf('/') + 1);
      link.setAttribute('download', filename);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      return false;
    }

    function searchFiles() {
      const searchTerm = document.getElementById('searchInput').value.toLowerCase();
      const allFiles = document.querySelectorAll('li.file');
      const allFolders = document.querySelectorAll('li.folder');

      // Reset visibility
      allFiles.forEach(file => file.style.display = '');
      allFolders.forEach(folder => folder.style.display = '');

      if (searchTerm.length < 2) {
        return; // Don't search for very short terms
      }

      // Hide non-matching files
      allFiles.forEach(file => {
        const fileName = file.textContent.toLowerCase();
        if (!fileName.includes(searchTerm)) {
          file.style.display = 'none';
        }
      });

      // Hide empty folders (no visible children)
      allFolders.forEach(folder => {
        const visibleChildren = Array.from(folder.querySelectorAll('li'))
          .filter(child => child.style.display !== 'none').length;

        if (visibleChildren === 0) {
          folder.style.display = 'none';
        } else {
          // Expand folders with matching content
          const ul = folder.querySelector('ul');
          if (ul) {
            ul.classList.remove('hidden');
          }
        }
      });
    }

    document.addEventListener('DOMContentLoaded', function() {
      // Initially collapse all folders except the first level
      document.querySelectorAll('li.folder > span + ul').forEach((ul, index, parent) => {
        if (ul.parentElement.parentElement.id !== 'tree') {
          ul.classList.add('hidden');
        }
      });
    });
  </script>
</head>
<body>
  <h1>S3 Bucket: Benchmark Results</h1>

  <div class="search-container">
    <input type="text" id="searchInput" placeholder="Search files..." onkeyup="searchFiles()">
  </div>

  <div class="controls">
    <button onclick="toggleAll(true)">Expand All</button>
    <button onclick="toggleAll(false)">Collapse All</button>
  </div>

  <ul id="tree">
EOF

# Python script to generate tree structure - WITHOUT ANY UNICODE CHARACTERS
cat > ./ascii_tree_generator.py << 'PYEOF'
import sys
import os

def build_tree(file_list):
    tree = {}

    for path in file_list:
        path = path.strip()
        if not path:
            continue

        parts = path.split('/')
        current = tree

        for i, part in enumerate(parts):
            if not part:  # Skip empty parts
                continue

            if i == len(parts) - 1:  # Last part (file)
                current.setdefault('__files__', []).append((part, path))
            else:  # Directory
                if part not in current:
                    current[part] = {}
                current = current[part]

    return tree

def print_tree(tree, base_url, indent=0):
    html = []

    # First process directories (sorted alphabetically)
    dirs = sorted([k for k in tree.keys() if k != '__files__'])
    for dir_name in dirs:
        html.append(f'''
        <li class="folder">
            <span onclick="toggleFolder(this)">
                <span class="folder-icon">[+]</span> {dir_name}
            </span>
            <ul>
                {print_tree(tree[dir_name], base_url, indent + 1)}
            </ul>
        </li>''')

    # Then process files (sorted alphabetically)
    if '__files__' in tree:
        for file_name, file_path in sorted(tree['__files__'], key=lambda x: x[0].lower()):
            file_url = f"{base_url}/{file_path}"
            html.append(f'''
            <li class="file">
                <a href="{file_url}" onclick="return downloadFile('{file_url}')">
                    <span class="file-icon">[f]</span> {file_name}
                </a>
                <div class="path-display">{file_path}</div>
            </li>''')

    return ''.join(html)

try:
    base_url = sys.argv[1]
    file_path = sys.argv[2]

    with open(file_path, 'r') as f:
        file_list = f.readlines()

    tree = build_tree(file_list)
    print(print_tree(tree, base_url))
except Exception as e:
    print(f"<li>Error generating tree: {str(e)}</li>")
    print("<li>Falling back to simple list...</li>")

    try:
        with open(file_path, 'r') as f:
            print("<ul>")
            for line in sorted(f.readlines()):
                line = line.strip()
                if line:
                    filename = line.split('/')[-1]
                    url = f"{base_url}/{line}"
                    print(f'<li class="file"><a href="{url}" onclick="return downloadFile(\'{url}\')">[f] {filename}</a> <div class="path-display">{line}</div></li>')
            print("</ul>")
    except:
        print("<li>Could not generate file list</li>")
PYEOF

# Execute the Python script to generate the tree - try python3 first, then python
python3 ./ascii_tree_generator.py "$BASE_URL" "$ALL_FILES" >> "$OUTPUT" 2>/dev/null || \
python ./ascii_tree_generator.py "$BASE_URL" "$ALL_FILES" >> "$OUTPUT" 2>/dev/null || \
echo "<li>Unable to generate tree structure. Please ensure Python is installed.</li>" >> "$OUTPUT"

# Close HTML
cat >> "$OUTPUT" << 'EOF'
  </ul>

  <footer style="margin-top: 30px; border-top: 1px solid #eee; padding-top: 10px; color: #7f8c8d;">
    <p>Generated on: <script>document.write(new Date().toLocaleString());</script></p>
  </footer>
</body>
</html>
EOF

# Clean up the temporary Python file
rm -f ./ascii_tree_generator.py

echo "Successful: ASCII tree index.html generated at: $OUTPUT"
echo "Open this file in your browser to navigate the S3 bucket structure"
