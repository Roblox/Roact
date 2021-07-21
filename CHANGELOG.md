# Roact Changelog

## Unreleased Changes
* Fixed forwardRef description ([#312](https://github.com/Roblox/roact/pull/312)).
* Silenced indentation warning in script analysis

## [1.4.0](https://github.com/Roblox/roact/releases/tag/v1.4.0) (November 19th, 2020)
* Introduce forwardRef ([#307](https://github.com/Roblox/roact/pull/307)).
* Fixed a bug where the Roact tree could get into a broken state when processing changes to child instances outside the standard lifecycle.
  * This change is behind the config value tempFixUpdateChildrenReEntrancy ([#301](https://github.com/Roblox/roact/pull/301))
* Added color schemes for documentation based on user preference ([#290](https://github.com/Roblox/roact/pull/290)).
* Fixed stack trace level when throwing an error in `createReconciler` ([#297](https://github.com/Roblox/roact/pull/297)).
* Optimized the memory usage of 'createSignal' implementation. ([#304](https://github.com/Roblox/roact/pull/304))

## [1.3.1](https://github.com/Roblox/roact/releases/tag/v1.3.1) (November 19th, 2020)
* Added component name to property validation error message ([#275](https://github.com/Roblox/roact/pull/275))

## [1.3.0](https://github.com/Roblox/roact/releases/tag/v1.3.0) (May 5th, 2020)
* Added Contexts, which enables easy handling of items that are provided and consumed throughout the tree.

## [1.2.0](https://github.com/Roblox/roact/releases/tag/v1.2.0) (September 6th, 2019)
* Fixed a bug where derived state was lost when assigning directly to state in init ([#232](https://github.com/Roblox/roact/pull/232/))
* Improved the error message when an invalid changed hook name is used. ([#216](https://github.com/Roblox/roact/pull/216))
* Fixed a bug where fragments could not be used as children of an element or another fragment. ([#214](https://github.com/Roblox/roact/pull/214))

## [1.1.0](https://github.com/Roblox/roact/releases/tag/v1.1.0) (June 3rd, 2019)
* Fixed an issue where updating a host element with children to an element with `nil` children caused the old children to not be unmounted. ([#210](https://github.com/Roblox/roact/pull/210))
* Added `Roact.joinBindings`, which allows combining multiple bindings into a single binding that can be mapped. ([#208](https://github.com/Roblox/roact/pull/208))

## [1.0.0](https://github.com/Roblox/roact/releases/tag/v1.0.0)
This release significantly reworks Roact internals to enable new features and optimizations.

* Added Fragments, which reduces the need for many container instances. ([#172](https://github.com/Roblox/roact/pull/172))
* Added Bindings, which enables easy surgical updates to instances without using refs. ([#159](https://github.com/Roblox/roact/pull/159))
* Added opt-in runtime type checking across the entire Roact API. ([#188](https://github.com/Roblox/roact/pull/188))
* Added support for prop validation akin to React's `propTypes`.
* Changed `Component:setState` to be deferred if it's called while Roact is updating a component. ([#183](https://github.com/Roblox/roact/pull/183))
* Changed events connected via `Roact.Event` and `Roact.Change` triggered by a Roact update to be deferred until Roact is done updating the instance.
* Improved and consolidated terminology across the board.
* Improved errors to be much more informative and clear.

## [0.2.0](https://github.com/Roblox/roact/releases/tag/v0.2.0)
* Deprecated `Roact.reconcile` in favor of `Roact.update` ([#194](https://github.com/Roblox/roact/pull/194))
* Removed some undocumented APIs:
	* `Roact.getGlobalConfigValue`, which let users read the current internal configuration.
	* `Roact.Element`, which let users figure out whether something is a Roact element. We'll introduce a proper type-checking API at a later date.

## April 15th, 2019 Prerelease
* Renamed `Roact.reify` to `Roact.mount` and `Roact.teardown` to `Roact.unmount` ([#82](https://github.com/Roblox/roact/issues/82))
	* The old methods are still present as aliases, but will output a warning when used.
* Added `Roact.Change` for subscribing to `GetPropertyChangedSignal` ([#51](https://github.com/Roblox/roact/pull/51))
* Added the static lifecycle method `getDerivedStateFromProps` ([#57](https://github.com/Roblox/roact/pull/57))
* Allow canceling render by returning nil from setState callback ([#64](https://github.com/Roblox/roact/pull/64))
* Added `defaultProps` value on stateful components to define values for props that aren't specified ([#79](https://github.com/Roblox/roact/pull/79))
* Added `getElementTraceback` ([#81](https://github.com/Roblox/roact/issues/81), [#93](https://github.com/Roblox/roact/pull/93))
* Added `createRef` ([#70](https://github.com/Roblox/roact/issues/70), [#92](https://github.com/Roblox/roact/pull/92))
* Added a warning when an element changes type during reconciliation ([#88](https://github.com/Roblox/roact/issues/88), [#137](https://github.com/Roblox/roact/pull/137))
* Ref switching now occurs in one pass, which should fix edge cases where the result of a ref is `nil`, especially in property changed events ([#98](https://github.com/Roblox/roact/pull/98))
* `setState` can now be called inside `init` and `willUpdate`. Instead of triggering a new render, it will affect the currently scheduled one. ([#139](https://github.com/Roblox/roact/pull/139))
* Roll back changes that allowed `setState` to be called inside `willUpdate`, which created state update scenarios with difficult-to-determine behavior. ([#157](https://github.com/Roblox/roact/pull/157))
* By default, disable the warning for an element changing types during reconciliation ([#168](https://github.com/Roblox/roact/pull/168))

## March 22, 2018 Prerelease
* Removed `is*Element` methods, this is unlikely to affect anyone ([#50](https://github.com/Roblox/roact/pull/50))
* Added new global configuration API for debug settings ([#46](https://github.com/Roblox/roact/pull/46))
* Added `Roact.reconcile`, which will be in the guide soon. It's useful for embedding Roact into existing projects! ([#44](https://github.com/Roblox/roact/pull/44))
* Added function variant of `setState` in preparation for async rendering ([#39](https://github.com/Roblox/roact/pull/39))
* Added `Roact.None` to allow removing values from state using `setState` ([#38](https://github.com/Roblox/roact/pull/38))
* `setState` will now throw errors if called at the wrong time ([#23](https://github.com/Roblox/roact/pull/23))
* Throw a nicer error when failing to set primitive properties ([#21](https://github.com/Roblox/roact/pull/21))
* If a bool is detected as a child of a component, it will be ignored, allowing for a shorter conditional rendering syntax! ([#15](https://github.com/Roblox/roact/pull/15))
* Error messages should make more sense in general
* Got rid of installer scripts in favor of regular model files

## December 1, 2017 Prerelease
* Initial pre-release build
