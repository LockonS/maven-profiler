# Maven Profiler

Maven Profiler runs Maven with a named `settings.xml` file. It is useful when you regularly switch between repositories,
mirrors, credentials, or other Maven settings.

The project can be used as either:

- an [Oh-My-Zsh](https://github.com/ohmyzsh/ohmyzsh) plugin, with commands for switching and inspecting profiles; 
- or a standalone Bash entry point, usable from Bash or Zsh without Oh-My-Zsh.

## How profiles work

Profiles are files in `$MAVEN_HOME/conf`:

| Profile   | Settings file                          |
|-----------|----------------------------------------|
| `default` | `$MAVEN_HOME/conf/settings.xml`        |
| `<name>`  | `$MAVEN_HOME/conf/settings-<name>.xml` |

For example, the `work` profile uses
`$MAVEN_HOME/conf/settings-work.xml`.

When Maven Profiler runs, it executes:

```text
$MAVEN_HOME/bin/mvn -s <profile-settings-file> <arguments>
```

Before Maven starts, it prints the selected profile, Maven executable, settings file, and JDK version.

## Requirements

- A JDK with `java` available on `PATH`
- A Maven installation
- `MAVEN_HOME` set to that Maven installation (essential for both the plugin and standalone entry point)

```shell
export MAVEN_HOME=/path/to/apache-maven
```

Maven Profiler invokes `$MAVEN_HOME/bin/mvn` directly; it does not discover
`MAVEN_HOME` from the `mvn` command on `PATH`.

## Create a profile

The Maven installation already provides the `default` profile at
`$MAVEN_HOME/conf/settings.xml`. To add a profile, copy that file and append a profile name:

```shell
cp "$MAVEN_HOME/conf/settings.xml" \
  "$MAVEN_HOME/conf/settings-work.xml"
```

Edit the copied file with the repositories, mirrors, servers, and credentials needed for that environment.

## Oh My Zsh installation

1. Clone the repository into the Oh My Zsh custom plugins directory:

   ```shell
   git clone https://github.com/LockonS/maven-profiler.git "${ZSH_CUSTOM:-$ZSH/custom}/plugins/maven-profiler"
   ```

2. Set `MAVEN_HOME` and add `maven-profiler` to the plugin list in `~/.zshrc`:

   ```shell
   plugins=(git maven-profiler)
   export MAVEN_HOME=/path/to/apache-maven
   
   # override alias if you want to route normal `mvn` commands through Maven Profiler
   alias mvn=mvnp
   ```

3. Restart the shell or reload the configuration:

   ```shell
   source ~/.zshrc
   ```

### Plugin commands

| Command              | Description                            |
|----------------------|----------------------------------------|
| `mvnp <args>`        | Run Maven with the active profile      |
| `mvnp-switch <name>` | Select a profile for the current shell |
| `mvnp-show`          | Show the current profile               |

```shell
mvnp-switch work
mvnp clean install

mvnp-switch default
mvnp test
```

`mvnp-switch` validates that the corresponding settings file exists. The selection lasts for the current shell session
and can be overridden by a project-level `.mvn-profile` file.

You can also select a profile by setting the environment variable after the plugin has loaded:

```shell
export MAVEN_PROFILE=work
```

## Standalone installation

The standalone entry point is processed by Bash but can be called from either Bash or Zsh. It does not require Oh My Zsh
or a Zsh installation.

1. Clone the repository and make the entry point executable:

   ```shell
   git clone https://github.com/LockonS/maven-profiler.git
   cd maven-profiler
   chmod +x maven-profiler.entry.sh
   ```

2. Expose it as `mvnp` using either a symlink on `PATH`:

   ```shell
   mkdir -p "$HOME/.local/bin"
   ln -s "$(pwd)/maven-profiler.entry.sh" "$HOME/.local/bin/mvnp"
   export PATH="$HOME/.local/bin:$PATH"
   ```

   Or add an alias to `~/.bashrc` or `~/.zshrc`:

   ```shell
   alias mvnp="/path/to/maven-profiler/maven-profiler.entry.sh"
   ```

3. Run Maven through the entry point:

   ```shell
   mvnp clean install
   ```

Use a `.mvn-profile` file to select a non-default profile in standalone mode. The `mvnp-switch` and `mvnp-show` aliases
are provided only by the Oh My Zsh plugin because a standalone process cannot update its parent shell.

## Project-specific profiles

Add a `.mvn-profile` file to a project to select its profile automatically:

```shell
MAVEN_PROFILE=work
```

`export MAVEN_PROFILE=work` and quoted values are also accepted. On every run, Maven Profiler searches from the current
directory toward the filesystem root and uses the first readable `.mvn-profile` it finds. This allows one file at a
repository root to apply to all of its subdirectories.

For the Oh My Zsh plugin, the effective selection order is:

1. The nearest `.mvn-profile`
2. The current shell's `MAVEN_PROFILE`, typically set by `mvnp-switch`, an explicit `export`, or an environment manager
   such as
   [direnv](https://direnv.net/)
3. The `default` profile

The standalone entry point uses the nearest `.mvn-profile`, then falls back to
`default`.

## Optional `mvn` alias

To route normal `mvn` commands through Maven Profiler, add this after the plugin or standalone setup:

```shell
alias mvn=mvnp
```

The original Maven command remains available as `command mvn` or `\mvn` when needed.

## Project structure

- `mvnp-core.sh` contains the shared Bash/Zsh-compatible logic.
- `maven-profiler.plugin.zsh` loads the core and defines the Oh My Zsh aliases.
- `maven-profiler.entry.sh` loads the core and runs it as a standalone command.

