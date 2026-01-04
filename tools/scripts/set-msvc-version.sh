#!/usr/bin/env bash
# replace MSVC version placeholder in all relevant files

set -euo pipefail

root="$(dirname "$0")/.."
version="$(< "$root/.vsversion")"

verbose=0
had_error=0

if [[ "${1:-}" == "--verbose" ]]; then
  verbose=1
fi

[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "🤬 invalid .vsversion"; exit 1; }

if (( verbose )); then
  echo -e "\n\n🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈"
  echo "🎉     INITIATING ULTRA PATCH MODE    🎉"
  echo -e "🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈🌈\n"

  echo "📂 Root: $root"
  echo -e "📦 Version: $version\n"
fi

i=0
for file in "$root/CMakePresets.json" "$root/cmake/Toolchain.cmake.in"; do
  if (( verbose )); then
    if (( i % 2 )); then
      echo -e "🥰 🌺 🥰 🌺 🥰 🌺 🥰 🌺 🥰 🌺 🥰 🌺 🥰 🌺\n"
    else
      echo -e "🌟 🌟 🌟 🌟 🌟 ✨ ✨ ✨ ✨ 🌟 🌟 🌟 🌟 🌟 \n"
    fi
    echo "📁 File: $file"
    echo "🛠️ Replacing placeholder... ✅"
  fi

  [[ -f $file ]] || {
    if (( verbose )); then
      echo -e "\n👎😱 The file does not exist! 😡😡\n"
    else
      echo "👎 $file does not exist or is not a file";
    fi
    had_error=1
    continue
  }

  if (( verbose )); then
    echo "🥳🥳 The file exists! 🤝😎"
  fi

  if (( !verbose )); then
    echo "🛠️ updating MSVC version in $file"
  fi

  outfile="${file%.in}"
  if [[ "$file" != "$outfile" ]]; then
    cp "$file" "$outfile" || {
      if (( verbose )); then
        echo "🤐😵 failed to copy file! 🤢🤢"
      else
        echo "👎 failed to copy $file to $outfile"
      fi
      had_error=1
      continue
    }
  fi

  sed -E -i "s|/MSVC/.*/bin|/MSVC/$version/bin|g" "$outfile" || {
    if (( verbose )); then
      echo "🙅🤬 failed to update! 🚫🙊"
    else
      echo "👎 failed to update $outfile"
    fi
    had_error=1
    continue
  }

  if (( verbose )); then
    echo -e "\n🥂 File processed without errors! 🙌🥂\n"
  fi

  ((i=i+1))
done

if (( had_error )); then
  if (( verbose )); then
    echo "💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀"
    echo " 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀"
    echo -e "\n😱🙊😨 FATAL ERROR 😭💔😿\n\n"
  else
    echo "💀 some files failed to process"
  fi
  exit 1
fi

if (( verbose )); then
  echo -e "🌟 🌟 🌟 🌟 🌟 ✨ ✨ ✨ ✨ 🌟 🌟 🌟 🌟 🌟"
  echo -e " 👏 👏 👏 👏 👏 👏 👏 👏 👏 👏 👏 👏 👏"
  echo -e "💅 💅 💅 💅 💅 💅 💅 💅 💅 💅 💅 💅 💅 💅\n\n"
  echo -e "😎😎 MISSION ACCOMPLISHED 😎😎\n\n"
else
  echo "😎 done"
fi
exit 0
