fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
### test_framework
```
fastlane test_framework
```
Runs all tests for the given environment

Set `scan` action environment variables to control test configuration

####Example:

```
fastlane test_framework configuration:Debug --env ios91
```

####Options

 * **`configuration`**: The build configuration to use.


### code_coverage
```
fastlane code_coverage
```
Produces code coverage information

Set `scan` action environment variables to control test configuration

####Example:

```
fastlane code_coverage configuration:Debug
```

####Options

 * **`configuration`**: The build configuration to use. The only supported configuration is the `Debug` configuration.



----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
