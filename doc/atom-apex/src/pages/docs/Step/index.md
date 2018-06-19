---
title: "Step"
description: "Step"
layout: "guide"
icon: "code-file"
weight: 2
---

###### {$page.description}

<article id="1">

## What is a Step?

A step is the basic component of an Atom.

Atom.apex supports many types of steps.

- Simple Step
- Composite Step
- ForEach Step
- Range Step
- Repeat Step

</article>

<article id="2">

## Simple Step

A simple step is one that contains a compute. The only job for a simple step is to execute that compute.

```javascript
new Atom()
    .then(new Atom.SimpleStep(new CustomCompute()))
    .then(new CustomCompute()) // equivalent to above
    .fork();
```

| Constructor | Description |
| ----------- | ----------- |
| SimpleStep(Atom.Compute) | Create a simple step from the compute |

</article>

<article id="3">

## Composite Step

A composite step is one that can contain multiple steps. It executes the children steps one by one.

```javascript
new Atom()
    .then(
        new Atom.CompositeStep()
            .then(...)
    )
    .fork();
```

| Constructor | Description |
| ----------- | ----------- |
| CompositeStep() | Create an empty composite step |

| Method | Description |
| ------ | ----------- |
| CompositeStep then(Atom.Step) | Chain the next step |
| CompositeStep then(Atom.Compute) | Chain the next compute as the step |
| CompositeStep then(Func) | Chain the next Func as the step |

</article>

<article id="4">

## ForEach Step

A ForEachStep is one that executes the 'for-each' loop with the given step. It looks up for the collection data with the given name from the Atom state, and creates a new looping item before invoking the looping step.


```javascript
Map<String, Object> initialData = new Map<String, Object>{ 'items' => new List<Object>{ ... } };
new Atom(initialData)
    .then(new Atom.ForEachStep('item', 'items', new CustomStep()))
    .fork();
```

| Constructor | Description |
| ----------- | ----------- |
| ForEachStep(String, String, List&lt;Object&gt;, Atom.Step) | Create a ForEachStep with item key, values key, values and the next step |
| ForEachStep(String, String, Atom.Step) | Create a ForEachStep with item key, values key and the next step |
| ForEachStep(String, List&lt;Object&gt;, Atom.Step) | Create a ForEachStep with item key, values and the next step |
| ForEachStep(String, String, Atom.Compute) | Create a ForEachStep with item key, values key and compute as the next step |
| ForEachStep(String, List&lt;Object&gt;, Atom.Compute) | Create a ForEachStep with item key, values and compute as the next step |
| ForEachStep(String, String, Func) | Create a ForEachStep with item key, values key and Func as the next step |
| ForEachStep(String, List&lt;Object&gt;, Func) | Create a ForEachStep with item key, values and Func as the next step |


</article>

<article id="5">

## Range Step

A RangeStep is one that executes the given step with a range of numbers.


```javascript
new Atom()
    .then(new Atom.RangeStep('n', 1, 10, new CustomStep()))
    .fork();
```

| Constructor | Description |
| ----------- | ----------- |
| RangeStep(String, Integer, Intger, Atom.Step) | Create a RangeStep with the item key, min value, max value and the next step |
| RangeStep(String, Integer, Intger, Atom.Compute) | Create a RangeStep with the item key, min value, max value and compute as the  next step |
| RangeStep(String, Integer, Intger, Func) | Create a RangeStep with the item key, min value, max value and Func as the  next step |

</article>

<article id="6">

## Repeat Step

A RepeatStep is one that repeats the given step until N times.


```javascript
new Atom()
    .then(new Atom.RepeatStep(10, new CustomStep()))
    .fork();
```

| Constructor | Description |
| ----------- | ----------- |
| RepeatStep(String, Integer, Atom.Step) | Create a RepeatStep with the item key, count and the next step |
| RepeatStep(String, Integer, Atom.Compute) | Create a RepeatStep with the item key, count and compute as the next step |
| RepeatStep(String, Integer, Func) | Create a RepeatStep with the item key, count and Func as the next step |
| RepeatStep(Integer, Atom.Step) | Create a RepeatStep with count and the next step |
| RepeatStep(Integer, Atom.Compute) | Create a RepeatStep with count and compute as the next step |
| RepeatStep(Integer, Func) | Create a RepeatStep with count and Func as the next step |

</article>
