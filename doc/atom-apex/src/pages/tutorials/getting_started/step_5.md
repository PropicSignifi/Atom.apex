---
title: "Step"
description: "Step"
buttonTitle: "Done"
parentId: "getting_started"
layout: "tutorial"
time: 90
weight: 5
---

## {$page.title}

A **step** is the basic component of an **Atom**. Here is how we chain the steps into an Atom.

```javascript
new Atom()
    .then(step1)
    .then(step2)
    .fork();
```

We have different kinds of steps in Atom.apex.

- Simple Step

A simple step is one that contains a compute. The only job for a simple step is to execute that compute.

```javascript
new Atom()
    .then(new Atom.SimpleStep(new CustomCompute()))
    .then(new CustomCompute()) // equivalent to above
    .fork();
```

- Composite Step

A composite step is one that can contain multiple steps. It executes the children steps one by one.

```javascript
new Atom()
    .then(
        new Atom.CompositeStep()
            .then(...)
    )
    .fork();
```

- ForEach Step

A ForEachStep is one that executes the 'for-each' loop with the given step. It looks up for the collection data with the given name from the Atom state, and creates a new looping item before invoking the looping step.

```javascript
Map<String, Object> initialData = new Map<String, Object>{ 'items' => new List<Object>{ ... } };
new Atom(initialData)
    .then(new Atom.ForEachStep('item', 'items', new CustomStep()))
    .fork();
```

- Range Step

A RangeStep is one that executes the given step with a range of numbers.


```javascript
new Atom()
    .then(new Atom.RangeStep('n', 1, 10, new CustomStep()))
    .fork();
```

- Repeat Step

A RepeatStep is one that repeats the given step until N times.

```javascript
new Atom()
    .then(new Atom.RepeatStep(10, new CustomStep()))
    .fork();
```
