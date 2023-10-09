# ECS-Brazuca

## _A plugin for Godot 4.0 based on the [ECS] and [ED] arquitecture_

#### This plugin is an attempt for mixing some concepts from both architectures, in a way this can be applied to Godot, and it node's structure.

**Some concepts based on the [ECS] Architecture:**

- The presence of systems who can operate over entities's components.
- The existence of components who can belongs to an entity.
- Entities who are recognized by the system according with its components.
- Entities does not need to be aware of it's components.
- Focus on the composition over inheritance, for systems, the component rules the aspects of the entities.

**Some concepts based on the [ED] Architecture**

- System-Component comunication occur when an event happen, it does not interate over entities or components checking for changes.
- 

## Systems

Each system inherits from BaseSystem, who provides a way to track, access and modify components, and knows what components a entity may hold. This interface are possible due an [Observer Pattern], where the systems provide a way for the component communicate when it enters in the tree.

~~Continuar o texto~~

[ECS]: <https://en.wikipedia.org/wiki/Entity_component_system>
[ED]: <https://en.wikipedia.org/wiki/Event-driven_architecture>
[Observer Pattern]: <https://en.wikipedia.org/wiki/Observer_pattern>
