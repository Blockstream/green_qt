#!/usr/bin/env bash
# Run qmllint on all QML/JS under qml/. Uses .qmllint.ini at repo root.
# Same idea as the earlier branch: no CMake, no Docker build image, no import stubs.

set +e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if ! command -v qmllint >/dev/null 2>&1; then
  echo -e "${RED}Error: qmllint not found (install Qt 6.11 and add it to PATH).${NC}" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "${script_dir}/../.." && pwd)"
cd "${root}"

if [[ ! -f .qmllint.ini ]]; then
  echo -e "${YELLOW}Warning: .qmllint.ini not found, using qmllint defaults.${NC}"
fi

qml_dir="${root}/qml"
total_files=$(find "${qml_dir}" \( -name '*.qml' -o -name '*.js' \) -type f | wc -l | tr -d ' ')
if [[ "${total_files}" -eq 0 ]]; then
  echo -e "${YELLOW}Warning: no QML/JS files under ${qml_dir}${NC}"
  exit 0
fi

echo -e "${GREEN}Running qmllint on ${total_files} file(s)...${NC}"
echo ""

temp_out="$(mktemp)"
trap 'rm -f "${temp_out}"' EXIT
# -I qml: enough for relative imports; Blockstream.* modules are C++/CMake at runtime.
find "${qml_dir}" \( -name '*.qml' -o -name '*.js' \) -type f -print0 \
  | xargs -0 qmllint -I "${qml_dir}" >"${temp_out}" 2>&1
qmllint_rc=$?

if [[ -s "${temp_out}" ]]; then
  cat "${temp_out}"
fi

error_count=$(grep -c 'Error:' "${temp_out}" 2>/dev/null || true)
warning_count=$(grep -c 'Warning:' "${temp_out}" 2>/dev/null || true)

echo ""
echo "========================================="
if [[ "${error_count}" -gt 0 || "${warning_count}" -gt 0 ]]; then
  echo -e "${YELLOW}Summary:${NC}"
  [[ "${error_count}" -gt 0 ]] && echo -e "  ${RED}Errors: ${error_count}${NC}"
  [[ "${warning_count}" -gt 0 ]] && echo -e "  ${YELLOW}Warnings: ${warning_count}${NC}"
  if [[ "${error_count}" -gt 0 ]]; then
    echo ""
    echo -e "${RED}qmllint found errors.${NC}"
    exit 1
  fi
  echo ""
  echo -e "${YELLOW}qmllint found warnings.${NC}"
  exit 0
fi

if [[ "${qmllint_rc}" -ne 0 ]]; then
  echo -e "${RED}qmllint exited with status ${qmllint_rc}.${NC}"
  exit "${qmllint_rc}"
fi

echo -e "${GREEN}qmllint passed with no errors or warnings.${NC}"
exit 0
