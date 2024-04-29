## maven-profiler
An oh-my-zsh plugin to switch between different maven configurations. This could come in handy while having to work with several separate maven registry at a regular basis.

### Install

1. Clone this repository in oh-my-zsh's plugins directory
	
	```shell
	$ git clone https://github.com/LockonS/maven-profiler.git $ZSH/custom/plugins/maven-profiler
	```
	
2. Enable the plugin by adding `maven-profiler` in `plugins` in your `~/.zshrc`
         
	```shell
	plugins=( [plugins...] maven-profiler)
	```
	
3. Prerequisite
	
  - JDK and maven need to be installed first (able to find in PATH)
  - Optional, setup `MAVEN_HOME` to use a specific maven installation. Otherwiset this plugin will find and use the maven installation in PATH, plus set the `MAVEN_HOME` environment variable.

4. Add a new profile

  - Default maven configuration file is `$MAVEN_HOME/conf/settings.xml`
  - Copy default maven configuration file and rename it to `$MAVEN_HOME/conf/settings-custom.xml`, in this case, `custom` is the profile name
  - Optional, if a configuration file need to be set as default, add `MAVEN_PROFILE_DEFAULT_OVERRIDE=$TARGET_FILE` in `~/.zshrc`

5. Usage

  ```shell
  # switch to a maven profile
  $ mvnp-switch custom
  # or
  $ export MAVEN_PROFILE=custom
  # restore default profile
  # mvnp-switch default
  
  # start to use maven
  $ mvn test
  ```

  - Override default profile
  
  ```shell
  # add this line to ~/.zshrc
  MAVEN_PROFILE_DEFAULT_OVERRIDE="target-profile-name"
  ```

5. Recommandation
  
  - Consider use this plugin with [direnv](https://direnv.net/) or other tools with automatic environment variable manipulate utilities. 
