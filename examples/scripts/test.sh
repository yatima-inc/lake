set -ex
${LAKE:-../../build/bin/lake} run greet
${LAKE:-../../build/bin/lake} run greet -- me
${LAKE:-../../build/bin/lake} run greet -h
${LAKE:-../../build/bin/lake} run nonexistant && false || true
