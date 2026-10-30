# Tergo online plugin: Java workflow.

_tergo_java_root() {
  local root
  if [ -n "${TERGO_PROJECT_ROOT:-}" ] && [ -d "${TERGO_PROJECT_ROOT}" ]; then root=$TERGO_PROJECT_ROOT
  elif root=$(command git rev-parse --show-toplevel 2>/dev/null); then :
  else root=$PWD; fi
  CDPATH= cd -- "$root" 2>/dev/null && pwd -P
}
_tergo_java_project() { local root; root=$(_tergo_java_root); if [ -f "$root/pom.xml" ] || [ -f "$root/build.gradle" ] || [ -f "$root/build.gradle.kts" ]; then printf '%s\n' "$root"; return 0; fi; printf '当前项目未发现 pom.xml 或 Gradle 构建文件：%s\n' "$root" >&2; return 1; }
_tergo_java_kind() { local root=$1; if [ -f "$root/pom.xml" ]; then printf '%s\n' maven; elif [ -f "$root/build.gradle" ] || [ -f "$root/build.gradle.kts" ]; then printf '%s\n' gradle; else return 1; fi; }
_tergo_java_tool() { local tool=$1; if command -v "$tool" >/dev/null 2>&1; then printf '%s：%s\n' "$tool" "$(command "$tool" --version 2>&1 | sed -n '1p')"; else printf '%s：未安装\n' "$tool"; fi; }
_tergo_java_runner() {
  local root=$1 kind=$2
  if [ "$kind" = maven ]; then
    if [ -x "$root/mvnw" ]; then printf '%s\n' ./mvnw
    elif command -v mvn >/dev/null 2>&1; then printf '%s\n' mvn
    else printf '%s\n' '未找到 mvnw 或 mvn' >&2; return 127; fi
  else
    if [ -x "$root/gradlew" ]; then printf '%s\n' ./gradlew
    elif command -v gradle >/dev/null 2>&1; then printf '%s\n' gradle
    else printf '%s\n' '未找到 gradlew 或 gradle' >&2; return 127; fi
  fi
}
_tergo_java_exec() { local runner=$1; shift; case "$runner" in ./mvnw) command ./mvnw "$@";; mvn) command mvn "$@";; ./gradlew) command ./gradlew "$@";; gradle) command gradle "$@";; *) return 127;; esac; }

tergo-java-report() {
  local root kind
  root=$(_tergo_java_root); printf '项目根目录：%s\n' "$root"
  _tergo_java_tool java; _tergo_java_tool javac; _tergo_java_tool mvn; _tergo_java_tool gradle
  if kind=$(_tergo_java_kind "$root" 2>/dev/null); then
    printf '构建系统：%s\n' "$kind"
    [ -x "$root/mvnw" ] && printf '%s\n' 'Maven Wrapper：发现' || true
    [ -x "$root/gradlew" ] && printf '%s\n' 'Gradle Wrapper：发现' || true
  else
    printf '%s\n' '构建系统：未识别（支持 Maven 或 Gradle）'
  fi
  printf '%s\n' '命令不会自动下载 JDK、依赖或发布构件。'
}
tergo-java-files() { local root; root=$(_tergo_java_root); find "$root" -type f \( -name 'pom.xml' -o -name 'build.gradle' -o -name 'build.gradle.kts' -o -name 'settings.gradle' -o -name 'settings.gradle.kts' -o -name '*.java' \) -not -path '*/.git/*' -not -path '*/target/*' -not -path '*/build/*' -print 2>/dev/null | sort; }
tergo-java-dependencies() { local root kind runner; root=$(_tergo_java_project) || return; kind=$(_tergo_java_kind "$root") || return; runner=$(_tergo_java_runner "$root" "$kind") || return; if [ "$kind" = maven ]; then (cd "$root" && _tergo_java_exec "$runner" -DskipTests dependency:tree -DoutputType=text); else (cd "$root" && _tergo_java_exec "$runner" dependencies --configuration runtimeClasspath); fi; }
tergo-java-test() { local root kind runner; root=$(_tergo_java_project) || return; kind=$(_tergo_java_kind "$root") || return; runner=$(_tergo_java_runner "$root" "$kind") || return; if [ "$kind" = maven ]; then (cd "$root" && _tergo_java_exec "$runner" test); else (cd "$root" && _tergo_java_exec "$runner" test); fi; }
tergo-java-check() { local root kind runner; root=$(_tergo_java_project) || return; kind=$(_tergo_java_kind "$root") || return; runner=$(_tergo_java_runner "$root" "$kind") || return; if [ "$kind" = maven ]; then (cd "$root" && _tergo_java_exec "$runner" -DskipTests compile); else (cd "$root" && _tergo_java_exec "$runner" check -x test); fi; }
tergo-java-updates() { local root kind runner; root=$(_tergo_java_project) || return; kind=$(_tergo_java_kind "$root") || return; runner=$(_tergo_java_runner "$root" "$kind") || return; printf '%s\n' '只查询依赖更新，不修改构建文件。' >&2; if [ "$kind" = maven ]; then (cd "$root" && _tergo_java_exec "$runner" versions:display-dependency-updates); else (cd "$root" && _tergo_java_exec "$runner" dependencyUpdates); fi; }
tergo-java-build-preview() { local root kind; root=$(_tergo_java_project) || return; kind=$(_tergo_java_kind "$root") || return; printf '项目：%s\n' "$root"; if [ "$kind" = maven ]; then printf '%s\n' '预览命令：mvn -DskipTests package'; else printf '%s\n' '预览命令：gradle build -x test'; fi; printf '%s\n' '当前仅预览，不编译、不发布构件。'; }

_tergo_java_alias() { local alias_name=$1 function_name=$2; if ! command -v "$alias_name" >/dev/null 2>&1; then alias "$alias_name=$function_name"; fi; }
_tergo_java_alias javareport tergo-java-report; _tergo_java_alias javafiles tergo-java-files; _tergo_java_alias javatest tergo-java-test; _tergo_java_alias javacheck tergo-java-check
unset -f _tergo_java_alias
